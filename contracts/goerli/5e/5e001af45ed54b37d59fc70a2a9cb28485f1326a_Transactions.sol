/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Transactions {
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    address private owner;

    struct TransferStruct {
        address owner; //address du payeur
        string projectName; //nom du projet
        string package; //forfait choisi
        uint256 timestamp; //date
    }
    TransferStruct[] private transactions;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }


    function addToBlockchain( address sender, string memory projectName, string memory package) public {
        transactions.push(
            TransferStruct(
                sender,
                projectName,
                package,
                block.timestamp
            )
        );
    }

    function getAllTransactions() view public isOwner returns (TransferStruct[] memory)
    {
        return transactions;
    }
}