// SPDX-License-Identifier: MIT

import "./Token.sol";

pragma solidity ^0.8.0;

contract Waifu is TokenMintable {
	constructor(address c, address i) TokenMintable(c, i, 'Smart%20Waifu', 'Smart Waifu', 'Waifu') {
	}
}