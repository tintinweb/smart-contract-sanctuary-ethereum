// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.0;

import "./ERC20.sol";
import "./SafeMath.sol";

contract Polymorphism is ERC20 {
    using SafeMath for uint256;
    // Polymorphism token decimal
    uint8 public constant _decimals = 18;
    // Total supply for the Polymorphism token = 1000M
    uint256 private _totalSupply = 1000000000 * (10 ** uint256(_decimals));
    // Token Polymorphism deployer
    address private _polymorphismDeployer;

    constructor(address _deployer) ERC20("Polymorphism", "PMF", _decimals) {
        _polymorphismDeployer = _deployer;
        _mint(_polymorphismDeployer, _totalSupply);
    }

    // Allow to burn own wallet funds (which should be the amount from depositor contract)
    function burnFuel(uint256 amount) public {
        _burn(msg.sender, amount);
    }
}