//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";
import {Oracle} from "./Oracle.sol";
import {FixedPoint,fromFraction,mulFixedPoint,divFixedPoint} from "./FixedPoint.sol";

contract StableCoin is ERC20 {
    DepositorCoin public depositorCoin;
    Oracle public oracle;
    uint256 public feeRatePercentage;
    uint256 public initialCollateralPercentage;
    uint256 public depositorCoinLocktime;

    error InitialCollateralRatioError(string message, uint256 minimumDepositAmount);
    constructor(
        string memory _name,
        string memory _symbol,
        Oracle _oracle,
        uint256 _feeRatePercentage,
        uint256 _initialCollateralPercentage,
        uint256 _depositorCoinLocktime
    ) ERC20(_name, _symbol, 18) {
        oracle = _oracle;
        feeRatePercentage = _feeRatePercentage;
        initialCollateralPercentage = _initialCollateralPercentage;
        depositorCoinLocktime = _depositorCoinLocktime;
    }

    function mint() external payable {
        uint256 fee = _getFee(msg.value);
        uint256 mintStablecoinAmount = (msg.value - fee) * oracle.getPrice();
        _mint(msg.sender, mintStablecoinAmount);
    }

    function burn(uint256 burnStablecoinAmount) external payable {
        _burn(msg.sender, burnStablecoinAmount);
        uint256 refundingEth = burnStablecoinAmount / oracle.getPrice();
        uint256 fee = _getFee(refundigEth)
        (success, ) = msg.sender.call{value: refundigEth - fee}("");
        require(success, "STC: Burn fund transaction failed");
    }

    function _getFee(uint256 ethAmount) private view returns (uint256) {
        return (ethAmount*feeRatePercentage) / 100;
    }

    function depositCollateralBuffer() external payable {
        //deposit collateral buffer to the contract address of stable coin and transfer it into USDT token
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractUSD();
        if(deficitOrSurplusInUsd <= 0) {
            uint256 deficitInUsd = uint256(deficitOrSurplusInUsd * -1);
            uint256 deficitInEth = deficitInUsd/oracle.getPrice();

            uint256 addedSurplusInEth = msg.value - deficitInEth;
            uint256 requiredInitialSurplusinEth = ((initialCollateralPercentage*totalSupply)/100)/oracle.getPrice();
            if(addedSurplusInEth < requiredInitialSurplusinEth){
                uint256 minimumDeposit = deficitInEth + requiredInitialSurplusinEth;
                revert InitialCollateralRatioError("STC: Initial collateral ratio not met, minimum is ",minimumDeposit)
            }
            uint256 initialSupplyAmount = addedSurplusInEth * oracle.getPrice();
            depositorCoin = new DepositorCoin("Depositor Coin","DPC",depositorCoinLocktime,msg.sender,initialSupplyAmount);
            return;
        }
        uint256 usdInDpcPrice = fromFraction(depositorCoin.totalSupply(), uint256(deficitOrSurplusInUsd));
        uint256 mintDepositorCoinAmount = mulFixedPoint(msg.value * oracle.getPrice(), usdInDpcPrice);
        depositorCoin.mint(msg.sender,mintDepositorCoinAmount);
    }

    function withdrawCollateralBuffer(uint256 burnDepositocoinAmount) external {
        int256 deficitOrSurplusInUsd = _getDeficitOrSurplusInContractUSD();
        require(deficitOrSurplusInUsd > 0,"STC: No depositor funds to withdraw");
        uint256 surplusInUsd = uint256(deficitOrSurplusInUsd);
        depositorCoin.burn(msg.sender, burnDepositocoinAmount);
        FixedPoint usdInDpcPrice = fromFraction(depositorCoin.totalSupply() , surplusInUsd);
        uint256 refundingUsd = divFixedPoint(burnDepositorCoinAmount , usdInDpcPrice);
        uint256 refundigEth = refundingUsd / oracle.getPrice();
        (success, ) = msg.sender.call{value: msg.value}("");
        require(success, "STC: Withdraw Collateral buffer transaction failed");
    }

    function _getDeficitOrSurplusInContractUSD() private view returns (int256) {
        uint256 ethContractBalanceUSD = (address(this).balance-msg.value) * oracle.getPrice();
        int256 surplusOrDeficit = int256(ethContractBalanceUSD) - int256(totalSupply);
        return surplusOrDeficit;
    }
}
