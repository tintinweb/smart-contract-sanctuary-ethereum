/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "hardhat/console.sol";


interface IYugKYC {
    function isApproved(address addr) external view returns (bool);
}

contract YugAccessControl {

    event AccessEvent(address indexed from, address indexed to, uint64 expiry, bool allowed);

    mapping(address => mapping(address => Access)) _from_to_access;
    mapping(address => address[]) _user_requests;
    mapping(address => address[]) _user_rejects;
    mapping(address => mapping(address => uint256)) public _user_request_index;
    mapping(address => mapping(address => uint256)) public _user_rejects_index;

    struct Access {
        string key;
        string url;
        uint64 expiry;
    }

    address _yugKYC;

    constructor(address yugKYC) {
        _yugKYC = yugKYC;
    }

    // function reqAccess(address from) public {
    //     uint256 index = _user_request_index[from][msg.sender];
    //     require(_user_requests[from][index] != msg.sender, "Request exists");
    //     _user_requests[from].push(msg.sender);
    //     _user_request_index[from][msg.sender] = _user_requests[from].length -1;
    // }

    // function rejectRequest(address to) public {
    //     uint256 index = _user_request_index[from][msg.sender];
    //     require(_user_requests[from][index] == msg.sender, "not available");

    //     _user_rejects[msg.sender].push() 

    //     _user_requests[from].push(msg.sender);
    //     _user_request_index[from][msg.sender] = _user_requests[from].length -1;


    //     require(_user_request_pending[msg.sender][to] == 1, "Request not available");
    //     _user_request_rejects[msg.sender][to] = 1;
    //     _user_requests[to].push(msg.sender);
    // }



    function addAccess(address to, string memory key, string memory url, uint64 expiry) public {
        require(expiry > block.timestamp, "Incorrect expiry");
        require(IYugKYC(_yugKYC).isApproved(msg.sender), "Sender KYC not done");

        Access storage access = _from_to_access[msg.sender][to];
        access.key = key;
        access.expiry = expiry;
        access.url = url;
        emit AccessEvent(msg.sender, to, expiry, true);
    }

    function revokeAccess(address to) public {
        delete _from_to_access[msg.sender][to];
        emit AccessEvent(msg.sender, to, 0, false);
    }

    function getKycInfo(address user) public view returns(string memory, string memory) {
        Access storage access = _from_to_access[user][msg.sender];
        require(access.expiry > block.timestamp , "KYC not available");
        return (access.key, access.url);
    }
}