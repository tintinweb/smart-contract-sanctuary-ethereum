/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;
  
contract MyContract{

    uint balance;
    uint public counter;
    address payable owner;
    address payable[] public players;

    
    constructor(){
        owner = payable(msg.sender);
        counter = 0;
    }

    modifier ownerRequired(){
        require(owner == msg.sender, "only owner!");
        _;
    }
   
    function allplayers() public view returns(address payable[] memory){
        return players;
    } 

    receive() external payable{}

    // transer ownership of smart contract
    function transferOwnership(address payable _newOwner) public ownerRequired{
        owner = _newOwner;  
    }


    function addPlayer(address payable _newplayer) public{
        players.push(_newplayer);
        counter++;

    }

    // Use to Destroy contract
    function destroy() public ownerRequired {
        selfdestruct(owner);
    }


    function payWinner(address payable winner) payable public {
        // 35961 gas
        winner.transfer(address(this).balance);

    }

    function payFromContract() payable public ownerRequired {
        owner.transfer(address(this).balance);
   }
    
}