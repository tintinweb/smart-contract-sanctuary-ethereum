// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract BloomTreasure {
    uint256 private balance;
    string[] private tokens = ["ETH", "DAI", "USDC", "USDT"];
    address[] private owners;
    uint256 private percentage = 10000000000000000;
    mapping(address => uint256) private payersFees;

    constructor(address[] memory _owners) {
        //Set an array of owners that can withdraw the balance
        owners = _owners;
    }

    function amIAnOwner() public view returns (bool) {
        //Check if the caller is an owner
        bool isOwner = false;
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == msg.sender) {
                isOwner = true;
            }
        }
        return isOwner;
    }

    function calculateFee(uint256 amount) public view returns (uint256) {
        return (amount * percentage) / 100000000000000000000;
    }

    function fundTreasure(address sender) external payable {
        payersFees[sender] += msg.value;
        balance += msg.value;
    }

    function getPublicBalance() public view returns (uint256) {
        return balance;
    }

    function retrieveBalance(string[] memory tokenToRetrieve) public {
        bool isOwner = false;
        isOwner = checkOwnership(owners, msg.sender);
        require(isOwner, "You are not an owner");
        //Eths
        for (uint256 i = 0; i < tokenToRetrieve.length; i++) {
            if (compareStrings(tokenToRetrieve[i], tokens[0])) {
                payable(msg.sender).transfer(balance);
            }
        }
    }

    function checkOwnership(address[] memory _owners, address sender)
        internal
        pure
        returns (bool)
    {
        bool isOwner = false;
        for (uint256 j = 0; j < _owners.length; j++) {
            if (_owners[j] == sender) {
                isOwner = true;
            }
        }
        return isOwner;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }
}