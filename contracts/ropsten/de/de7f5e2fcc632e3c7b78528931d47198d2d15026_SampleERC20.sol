// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "./ERC20.sol";

/**
 * @title SampleERC20
 * @dev Create a sample ERC20 standard token
 */
contract SampleERC20 is ERC20 {

    constructor(string memory tokenName, string memory tokenSymbol,uint256  tokenSupply,uint8  tokenDecimals) ERC20(tokenName, tokenSymbol,tokenSupply,tokenDecimals) {}
}