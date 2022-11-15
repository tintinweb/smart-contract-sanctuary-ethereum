// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract TheChained is ERC20 {
    using SafeMath for uint256;
    // TheChained token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the TheChained token = 1000M
    uint256 private _totalSupply = 1000000000 * (10 ** uint256(_decimals));
    // Token TheChained deployer
    address private _TheChainedDeployer;

    constructor(address _deployer) ERC20("TheChained", "TCDAO", _decimals) {
        _TheChainedDeployer = _deployer;
        _mint(_TheChainedDeployer, _totalSupply);
    }

    // Allow to burn own wallet funds (which should be the amount from depositor contract)
    function burnFuel(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}