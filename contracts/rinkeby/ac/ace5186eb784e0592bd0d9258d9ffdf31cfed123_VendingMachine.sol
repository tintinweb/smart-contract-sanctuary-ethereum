/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract VendingMachine {
    address payable owner;
    uint numSodas;
    uint votesForAnarchy;
    bool ownerApproval;

    mapping(address => uint) sodasOwned;
    mapping(address => bool) hasVoted;

    constructor(uint _numSodas) {
        // whoever deploys this contract = owner
        owner = payable(msg.sender);
        numSodas = _numSodas;
    }

    function purchase() public payable {
        require(msg.value >= 1000 wei, "You must deposit at least 1000 wei!");
        require(numSodas > 0, "No more sodas left!");
        numSodas--;
        sodasOwned[msg.sender] += 1;
    }

    function withdrawEarnings() public {
        require(msg.sender == owner, "Only the owner can withdraw earnings!");
        owner.transfer(address(this).balance);
    }

    function changeOwner(address payable _newOwner) public {
        require(msg.sender == owner, "Only the owner can change the owner!");
        owner = _newOwner;
    }

    function voteToDestroy() public {
        require(sodasOwned[msg.sender] >= 1);
        require(!hasVoted[msg.sender]);
        votesForAnarchy++;
        hasVoted[msg.sender] = true;
    }

    function destroyVendingMachine() public {
        require(owner == msg.sender);
        selfdestruct(payable(msg.sender));
    }

    function anarchy() public {
        if(votesForAnarchy >= 10) {
            owner = payable(msg.sender);
            votesForAnarchy = 0;
        }
    }
}