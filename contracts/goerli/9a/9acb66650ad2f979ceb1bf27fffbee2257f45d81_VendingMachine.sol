/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract VendingMachine {

    address payable public owner;
    uint public numSodas;
    uint public votesForAnarchy;

    mapping(address => uint) public sodasOwned;
    mapping(address => bool) public hasVoted;

    constructor(uint _numSodas) {
        owner = payable(msg.sender);
        numSodas = _numSodas;
    }

    function purchase() public payable {
        require(msg.value >= 1000 wei, "Minimum deposit is 1000 wei!");
        require(numSodas > 0, "No more sodas available!");
        numSodas--;
        sodasOwned[msg.sender] += 1;
    }

    function withdrawEarnings() public {
        require(msg.sender == owner, "Only the owner can withdraw!");
        owner.transfer(address(this).balance);
    }

    function changeOwner(address payable _newOwner) public {
        require(msg.sender == owner, "Only current owner can change owner!");
        owner = _newOwner;
    }

    function voteToDestroy() public {
        require(sodasOwned[msg.sender] >= 1, "You need at least one soda to vote!");
        require(!hasVoted[msg.sender], "You have already voted!");
        hasVoted[msg.sender] = true;
        votesForAnarchy++;

    }

    function destroyVendingMachine() public {
        require(msg.sender == owner, "Only the owner can destroy!");
        selfdestruct(payable(msg.sender));
    }

    function anarchy() payable public {
        require(msg.value == 1000 wei);
        if (votesForAnarchy >= 10) {
            owner = payable(msg.sender);
            votesForAnarchy = 0;
        }
    }
}