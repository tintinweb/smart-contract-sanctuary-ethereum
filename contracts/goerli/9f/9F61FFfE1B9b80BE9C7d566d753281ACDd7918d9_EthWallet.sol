/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

contract EthWallet{

    //make a contract which can store eth for an owner
    address payable owner;
    string name;

    constructor(string memory _name){
        owner = payable(msg.sender);
        name = _name;
    } 

    function withdraw() external{
        uint bal = address(this).balance;
        owner.transfer(bal);
    }

    function getBalance() external view returns(uint256){
        return address(this).balance;
    }

    function editName(string memory _newName) external{
        name = _newName;
    }

    function getName() external view returns(string memory){
        return(name);
    }

    event Receipt(uint256 value);
    receive() external payable{
        emit Receipt(msg.value);
    }

}