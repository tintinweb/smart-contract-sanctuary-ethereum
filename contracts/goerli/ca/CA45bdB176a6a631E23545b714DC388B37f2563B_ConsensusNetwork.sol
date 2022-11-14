// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ConsensusNetwork {
    address public owner;
    address[] public users;
    string public networkName;
    Proposal[] public proposals;

    struct Proposal {
        string proposal;
        string response;
        uint256 date;
        uint256 deadline;
        uint256 reward;
        uint256 votesRequired;
    }

    struct User {
        uint256 id;
        address ethAddress;
        string username;
        string name;
        string profileImgHash;
        string profileCoverImgHash;
        string bio;
        // accountStatus status; // Account Banned or Not
    }

    struct Vote {
        string response;
    }

    constructor(string memory _networkName) {
        owner = msg.sender;
        networkName = _networkName;
    }

    function addUser(address _user) public onlyOwner {}

    function removeUser(address _user) public onlyOwner {
        // require(contains(_user) == true);
    }

    function postProposal(Proposal memory proposal) public onlyOwner {}

    function vote() public {}

    function payout() public payable {}

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}