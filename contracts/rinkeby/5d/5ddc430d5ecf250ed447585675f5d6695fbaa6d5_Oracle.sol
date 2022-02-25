/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity =0.8.0;

contract Oracle {

    address oracleAddress;
    uint currentId;

    struct Request {
        uint id;
        address collectionOwner;
        address collectionAddress;
        bool isMatch;
        bool isRegistered;
    }

    mapping(uint => Request) private requestList;

    constructor() {
        oracleAddress = msg.sender; // Apexgo EOA address
    }

    event NewRequest (uint id, address _collectionOwner, address _collectionAddress);
    event UpdatedRequest (uint id, address _collectionOwner, address _collectionAddress, bool _isMatch, bool _isRegistered);

    function createRequest (address _collectionOwner, address _collectionAddress) public {
        require(msg.sender == oracleAddress, 'Not Apexgo address.');
        requestList[currentId] = Request(currentId, _collectionOwner, _collectionAddress, false, false);
        emit NewRequest(currentId, _collectionOwner, _collectionAddress);
        currentId++;
    }

    function verifyCurrentRequestId(uint _id) public view returns(Request memory) {
        return requestList[_id];
    }

    function updateRequest (uint _currentId, address _collectionOwner, address _collectionAddress, bool _match, bool _isRegistered) public {
        require(msg.sender == oracleAddress, 'Not Apexgo address.');
        requestList[currentId] = Request(currentId, _collectionOwner, _collectionAddress, _match, _isRegistered);
        emit UpdatedRequest (_currentId, _collectionOwner, _collectionAddress, _match, _isRegistered);
    }

}