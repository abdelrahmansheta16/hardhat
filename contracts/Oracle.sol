//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "./ERC20.sol";
import {DepositorCoin} from "./DepositorCoin.sol";

contract Oracle {
    address public owner;
    uint256 private price;

    constructor() {
        owner = msg.sender;
    }
    function getPrice() external view returns (uint256) {
        return price;
    }
    function setPrice(uint256 newPrice) external {
        require(msg.sender == owner,"ETHUSDPrice: Only owner can set price");
        price = newPrice;
    }
}