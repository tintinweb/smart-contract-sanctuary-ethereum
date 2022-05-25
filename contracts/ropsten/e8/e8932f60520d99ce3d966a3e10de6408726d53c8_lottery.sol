/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract lottery{
    address public manager;
    address payable[]public Participants;

    constructor()
    {
        manager=msg.sender;

    }
    receive () external payable{
        require(msg.value==1 ether);
        Participants.push(payable(msg.sender));
    }

    function getbalance()public view returns(uint)
    {
        require(msg.sender==manager);
        return address(this).balance;
    }
    function random()public view returns(uint)
    {
        return uint (keccak256(abi.encodePacked(block.difficulty,block.timestamp,Participants.length)));
    }
    function selectwinner() public //view returns(address)
    {
        require (msg.sender==manager);
        require(Participants.length>=3);
        uint r=random();
        address payable winner;
        uint index=r%Participants.length;
        winner=Participants[index];
        winner.transfer(getbalance());
       // return winner;
       Participants=new address payable[](0);

    }
}