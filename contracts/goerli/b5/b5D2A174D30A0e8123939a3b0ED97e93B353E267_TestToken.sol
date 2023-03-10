// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ERC20.sol";

contract TestToken is ERC20 {
	uint256 public constant INITIAL_SUPPLY = 1000000000 * 10**18;

	/**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor() ERC20("TEST", "TEST") {
        _mint(msg.sender, INITIAL_SUPPLY);
    }
}