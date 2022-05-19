/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract wallet {
    uint256 id = 0;
    uint256 transID = 0;
    struct walletInfo {
        string name;
        uint256 balance;
        address owner;
        address[] partners;
        uint256 id;
    }
    struct transactionInfo {
        uint256 id;
        uint256 walletID;
        address reciever;
        uint256 funds;
        uint256 numOfVotes;
        uint256 numOfVotesAgainst;
        uint256 numOfVotesFor;
        bool transactionStatus;
    }
    mapping(uint256 => transactionInfo) public transactionDetails;
    mapping(uint256 => walletInfo) public walletDetails;
    mapping(uint256 => mapping(address => bool)) votersDetails;
    mapping(uint256 => mapping(address => bool)) isPartner;

    modifier checkOwner(uint256 _id) {
        require(walletDetails[_id].owner == msg.sender, "wallet : Not a User");
        _;
    }

    function createWallet(string memory _name) public payable {
        walletDetails[id].name = _name;
        walletDetails[id].balance = msg.value;
        walletDetails[id].owner = msg.sender;
        walletDetails[id].partners = new address[](0);
        walletDetails[id].id = id;
        id += 1;
    }

    function toAddPartners(address _partner, uint256 _walletId)
        public
        checkOwner(_walletId)
    {
        require(isPartner[_walletId][_partner] == false, "Already a Partner");
        walletDetails[_walletId].partners.push(_partner);
        isPartner[_walletId][_partner] = true;
    }

    function toRemovePartners(address _partner, uint256 _walletId)
        public
        checkOwner(_walletId)
    {
        require(
            isPartner[_walletId][_partner] == true,
            "Not a Existing Partner"
        );
        uint256 len = walletDetails[_walletId].partners.length;
        uint256 index;
        for (uint256 i = 0; i < len; i += 1) {
            if (_partner == walletDetails[_walletId].partners[i]) {
                index = i;
                break;
            }
        }
        walletDetails[_walletId].partners[index] = walletDetails[_walletId]
            .partners[len - 1];
        walletDetails[_walletId].partners.pop();
        delete isPartner[_walletId][_partner];
    }

    function addFunds(uint256 _id) public payable {
        walletDetails[_id].balance += msg.value;
    }

    function requestFunds(uint256 _walletId, uint256 _funds) public {
        require(_funds <= walletDetails[_walletId].balance, "Not enough Funds");
        uint256 len = walletDetails[_walletId].partners.length;
        if (
            msg.sender != walletDetails[_walletId].owner &&
            !isPartner[_walletId][msg.sender]
        ) {
            len += 1;
        }
        transactionDetails[transID] = transactionInfo(
            transID,
            _walletId,
            msg.sender,
            _funds,
            len,
            0,
            0,
            false
        );
        transID += 1;
    }

    function voting(
        uint256 _transID,
        uint256 _walletID,
        bool _vote
    ) public {
        require(
            msg.sender == walletDetails[_walletID].owner ||
                isPartner[_walletID][msg.sender],
            "Not Authorized To Vote"
        );
        require(
            msg.sender != transactionDetails[transID].reciever,
            "You cannot Vote For this Transaction"
        );
        require(
            !votersDetails[_transID][msg.sender],
            "Already Voted For this Transaction"
        );
        votersDetails[_transID][msg.sender] = true;

        if (_vote) {
            transactionDetails[_transID].numOfVotesFor += 1;
        } else {
            transactionDetails[_transID].numOfVotesAgainst += 1;
        }
    }

    function recieveFunds(uint256 _transID) public {
        require(
            !transactionDetails[_transID].transactionStatus,
            "Already Transacted"
        );
        require(
            msg.sender == transactionDetails[_transID].reciever,
            "Invalid Request : receiver is not same"
        );
        if (
            transactionDetails[_transID].numOfVotesFor == transactionDetails[_transID].numOfVotes
        ) {
            payable(msg.sender).call{value: transactionDetails[_transID].funds};
            transactionDetails[_transID].transactionStatus = true;
            walletDetails[transactionDetails[_transID].walletID].balance -= transactionDetails[_transID].funds;
        } else {
            revert("Transaction Denined By Authorities");
        }
    }

    function isTransacted(uint256 _transID) public view returns (bool) {
        return transactionDetails[_transID].transactionStatus;
    }
}