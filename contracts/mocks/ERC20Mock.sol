//SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "../ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol, decimals) {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }
}
