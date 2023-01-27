/**
 *Submitted for verification at Etherscan.io on 2023-01-27
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Transactions {
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    address payable private owner;

    struct TransferStruct {
        address owner; //address du payeur
        string projectName; //nom du projet
        uint packageType; //forfait choisi
        uint256 timestamp; //date
    }
    TransferStruct[] private transactions;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    constructor() {
        owner = payable(msg.sender);
        emit OwnerSet(address(0), owner);
    }


    function addToBlockchain( string memory projectName, uint package) public payable {
        require(package >= 0 && package <= 2, "PackageError.");
        transactions.push(
            TransferStruct(
                msg.sender,
                projectName,
                package,
                block.timestamp
            )
        );
        owner.transfer(msg.value);
    }

    function getAllTransactions() view public isOwner returns (TransferStruct[] memory)
    {
        return transactions;
    }
}