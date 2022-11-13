// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract ConsensusNetwork {
    address public owner;
    address[] public users;
    string public networkName;

    mapping(address => bool) public userInUsers;

    struct Proposal {
        string proposal;
        string response;
        uint256 datePoster;
        uint256 deadline;
        uint256 reward;
        uint256 nVotes;
    }

    struct Vote {
        string response;
    }

    constructor(string memory _networkName) {
        owner = msg.sender;
        networkName = _networkName;
    }

    function addUser(address _user) public {
        require(msg.sender == owner);
        // users.push(_user);
        // userInUsers[_user] = true;
    }

    function removeUser(address _user) public {
        require(msg.sender == owner);
        require(contains(_user) == true);
    }

    function postProposal(Proposal memory proposal) public {
        require(msg.sender == owner);
    }

    function vote() public {
        require(msg.sender != owner);
    }

    function contains(address _user) public returns (bool) {
        return userInUsers[_user];
    }
}