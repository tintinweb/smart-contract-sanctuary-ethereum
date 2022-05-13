pragma solidity ^0.4.24;

import 'StandardToken.sol';

contract TutorialToken is StandardToken {
    string public name = "IMC GENE";
    string public symbol = 'IMC';
    uint8 public decimals = 18;
    uint256 public constant INITIAL_SUPPLY = 7579185859000000000000000000;


    constructor() public {
        totalSupply_ = INITIAL_SUPPLY;
        balances[msg.sender] = INITIAL_SUPPLY;
        emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    }
}