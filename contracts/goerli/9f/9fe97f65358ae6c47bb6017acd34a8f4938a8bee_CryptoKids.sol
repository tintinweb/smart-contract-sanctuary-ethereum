/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

//SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.7;

contract CryptoKids {
    address owner;

    constructor() {
        owner = msg.sender;
    }

    struct Kid {
        address payable walletAddress;
        string firstName;
        string lastName;
        uint256 releaseTime;
        uint256 amount;
        bool canWithdraw;
    }

    Kid[] public kids;

    event LogKidFundingReceived(
        address addr,
        uint256 amount,
        uint256 contractBalance
    );

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can add Kids!");
        _;
    }

    function addKid(
        address payable walletAddress,
        string memory firstName,
        string memory lastName,
        uint256 releaseTime,
        uint256 amount,
        bool canWithdraw
    ) public onlyOwner {
        kids.push(
            Kid(
                walletAddress,
                firstName,
                lastName,
                releaseTime,
                amount,
                canWithdraw
            )
        );
    }

    function balanceOf() public view returns (uint256) {
        //returns the balance of the current contract(the contract from which the function is being called)
        return address(this).balance;
    }

    function deposit(address walletAddress) public payable {
        addToKidsBalance(walletAddress);
    }

    function addToKidsBalance(address walletAddress) private {
        for (uint256 i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == walletAddress) {
                kids[i].amount += msg.value;

                emit LogKidFundingReceived(
                    walletAddress,
                    msg.value,
                    balanceOf()
                );
            }
        }
    }

    function getIndex(address walletAddress) public view returns (uint256) {
        for (uint256 i = 0; i < kids.length; i++) {
            if (kids[i].walletAddress == walletAddress) {
                return i;
            }
        }

        return 999;
    }

    function availableToWithdraw(address walletAddress) public returns (bool) {
        uint256 index = getIndex(walletAddress);

        require(
            kids[index].releaseTime < block.timestamp,
            "You cannot withdraw yet!"
        );
        if (kids[index].releaseTime < block.timestamp) {
            kids[index].canWithdraw = true;
            return true;
        } else {
            return false;
        }
    }

    function withdraw(address payable walletAddress) public payable {
        uint256 index = getIndex(walletAddress);
        require(
            msg.sender == kids[index].walletAddress,
            "You must be the kid to withdraw"
        );
        require(
            kids[index].canWithdraw == false,
            "You are not able to withdraw at this time"
        );
        kids[index].walletAddress.transfer(kids[index].amount);
    }
}