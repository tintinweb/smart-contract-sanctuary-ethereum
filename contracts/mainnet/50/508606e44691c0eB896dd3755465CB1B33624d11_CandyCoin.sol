pragma solidity ^0.8.0;

import "./ERC20.sol";

contract CandyCoin is ERC20 {
    constructor(uint256 initialSupply) ERC20("Candy Coin", "CND") {
        _mint(msg.sender, initialSupply);
    }
}