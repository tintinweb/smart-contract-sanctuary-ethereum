pragma solidity ^0.8.3;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./ERC20.sol";
import "./ERC20MintAble.sol";
import "./ERC20BurnAble.sol";

contract Boti is ERC20, Ownable, ERC20BurnAble, ERC20MintAble {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}
}