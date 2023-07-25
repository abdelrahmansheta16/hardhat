//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed sender, uint256 value);
    string public name;
    string public symbol;
    uint8 public immutable decimals;
    ERC20 public myERC;
    address constant feeCollectingAddress =
        0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    function calculateFee(
        uint256 value,
        uint256 percent
    ) internal view returns (uint256) {
        // Shift the numerator to the left to account for decimals
        uint256 denominator = 100;
        uint256 fixedPointValue = (percent * (10 ** uint256(decimals))) /
            denominator;
        return (value * fixedPointValue) / (10 ** uint256(decimals));
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function _mint(address to, uint256 value) internal {
        balanceOf[to] += value;
        totalSupply += value;

        emit Transfer(address(0), to, value);
    }

    function _burn(address to, uint256 value) private {
        balanceOf[to] -= value;
        totalSupply -= value;

        emit Transfer(address(0), to, value);
    }

    function burn(address to, uint256 value) external {
        _burn(to, value);
    }

    function Deposit() external payable {
        balanceOf[msg.sender] += msg.value;
        totalSupply -= msg.value;

        emit Transfer(address(0), msg.sender, msg.value);
    }

    function Redeem(uint256 value) external {
        transferFrom(msg.sender, address(this), value);
        totalSupply -= value;
        myERC.transfer(msg.sender, value);
    }

    function giveMeOneToken() external {
        balanceOf[msg.sender] += 1e18;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {
        require(allowance[from][msg.sender] >= value, "insufficient allowance");

        allowance[from][msg.sender] -= value;

        return _transfer(from, to, value);
    }

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal virtual returns (bool) {
        require(balanceOf[from] >= value, "insufficient balance");
        emit Transfer(from, to, value);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        return true;
    }

    function approve(address sender, uint256 value) external returns (bool) {
        allowance[msg.sender][sender] += value;
        emit Approval(sender, value);
        return true;
    }
}

contract feeTaker is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol, _decimals) {}

    function _transfer(
        address from,
        address to,
        uint256 value
    ) internal override returns (bool) {
        require(balanceOf[from] >= value, "insufficient balance");
        emit Transfer(from, to, value);
        uint256 fee = calculateFee(value, 1);
        uint256 afterFee = value - fee;
        balanceOf[feeCollectingAddress] += fee;
        balanceOf[from] -= afterFee;
        balanceOf[to] += afterFee;
        return true;
    }
}
