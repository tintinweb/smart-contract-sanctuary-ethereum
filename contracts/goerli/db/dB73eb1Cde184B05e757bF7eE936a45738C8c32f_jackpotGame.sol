// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.7;

/*This is a Jackpot game.
To start with, send 0.005 eth into this contract. Every time you send 0.005 eth, you have a certain chance to win all the eth
in the pool. Check the balance in your own wallet or this contract to see if you won the prize!*/

contract jackpotGame{

    uint nonce;

    function random() public returns (uint) { //Public allows to call internally
        uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, nonce))) % 100;
        nonce++;  
        return randomnumber;
        //Blockchain is deterministic, so cannot have a true random number. 
        //Can only hash 3 factors then mod 100. This number is not a true random nuumber as it is predictable.
        //Possible results of xxx mod 10 are 0,1,2,3,4,5,6,7,8,9.
    }

    receive () external payable{
        require(msg.value == 5000000000000000, "Please input 0.005 eth");
        uint output = random();
        if (output <10) {
            payable(msg.sender).transfer(address(this).balance);
        }
    }
}