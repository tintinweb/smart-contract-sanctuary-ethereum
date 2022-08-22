/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// import "hardhat/console.sol";


interface IYugKYC {
    function isApproved(address addr) external view returns (bool);
}

contract YugAccessControl {

    event AccessEvent(address indexed from, address indexed to, uint64 expiry, uint8 status);

    mapping(address => mapping(address => Access)) public _from_to_access;
    mapping(address => AccessRequest[]) public _user_requests;
    mapping(address => mapping(address => uint256)) public _user_requestor_index;

    mapping(address => address[]) public _my_requests;

    struct Access {
        string key;
        string url;
        uint64 expiry;
    }

    struct AccessRequest {
        address user;
        address requestor;
        //0: requested
        //1: accepted
        //2: rejected 
        uint8 status;
        uint256 at;
        uint256 expiry;
    }

    address _yugKYC;

    constructor(address yugKYC) {
        _yugKYC = yugKYC;
    }

    function getAllMyRequesties() public view returns (AccessRequest[] memory){
        return _user_requests[msg.sender];
    }

    function getRequestAccess(address from) public view returns (AccessRequest memory){
        return _user_requests[from][_user_requestor_index[from][msg.sender]];
    }

    function getMyRequests() public view returns (address[] memory){
        return _my_requests[msg.sender];
    }

    function acceptRequest(address to, uint256 expiry) private {
        if(_user_requests[msg.sender].length == 0) {
            _user_requests[msg.sender].push(AccessRequest(address(0), address(0), 0, 0, 0)); // add empty
        }

        uint256 idx = _user_requestor_index[msg.sender][to];
        if(idx == 0) {
            _user_requests[msg.sender].push(AccessRequest(address(0), address(0), 0, 0, 0));
            idx = _user_requests[msg.sender].length - 1;
            _user_requestor_index[msg.sender][to] = idx;
        }
        AccessRequest storage accessRequest = _user_requests[msg.sender][idx];
        // require(accessRequest.expiry > block.timestamp, "Request not exists");
        require(expiry > block.timestamp, "Invalid expiry");

        accessRequest.user = msg.sender;
        accessRequest.requestor = to;
        accessRequest.status = 1;
        accessRequest.expiry = expiry;
    }

    function rejectRequest(address to) public {
        AccessRequest storage accessRequest = _user_requests[msg.sender][_user_requestor_index[msg.sender][to]];
        require(accessRequest.expiry > block.timestamp, "Request not present");

        accessRequest.user = msg.sender;
        accessRequest.requestor = to;
        accessRequest.status = 2;
    }

    function requestAccess(address from) public {
        if(_user_requests[from].length == 0) {
            _user_requests[from].push(AccessRequest(address(0), address(0), 0, 0, 0)); // add empty
        }
        
        uint256 index = _user_requestor_index[from][msg.sender];
        if(index == 0) {
            _user_requests[from].push(AccessRequest(address(0), address(0), 0, 0, 0));
            index = _user_requests[from].length - 1;
            _user_requestor_index[from][msg.sender] = index;
        }
        AccessRequest storage accessRequest = _user_requests[from][index];

        require(accessRequest.expiry < block.timestamp, "Request exists");
        accessRequest.user = from;
        accessRequest.requestor = msg.sender;
        accessRequest.status = 0;
        accessRequest.expiry = block.timestamp + (86400 * 90);
        accessRequest.at = block.timestamp;


        _my_requests[msg.sender].push(from);

        emit AccessEvent(from, msg.sender, 0, 0);
    }


    function addAccess(address to, string memory key, string memory url, uint64 expiry) public {
        require(expiry > block.timestamp, "Incorrect expiry");
        require(IYugKYC(_yugKYC).isApproved(msg.sender), "Sender KYC not done");

        Access storage access = _from_to_access[msg.sender][to];
        access.key = key;
        access.expiry = expiry;
        access.url = url;

        acceptRequest(to, expiry);

        emit AccessEvent(msg.sender, to, expiry, 1);
    }

    function revokeAccess(address to) public {
        delete _from_to_access[msg.sender][to];
        rejectRequest(to);
        emit AccessEvent(msg.sender, to, 0, 2);
    }

    function getKycInfo(address user) public view returns(string memory, string memory) {
        Access storage access = _from_to_access[user][msg.sender];
        require(access.expiry > block.timestamp , "KYC not available");
        return (access.key, access.url);
    }
}