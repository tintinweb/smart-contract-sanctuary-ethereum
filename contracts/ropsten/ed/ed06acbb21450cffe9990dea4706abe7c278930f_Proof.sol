/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract Proof {    
    struct FileDetail{
        uint256 timestamp;
        string ownerName;
    }
    
    // proof FileDetail by account address
    mapping(address => FileDetail) files;
    
    // log added FileDetail and status
    event logFileAddedStatus(bool status, uint256 timestamp, string ownerName, address accountAddress);
    
    // set FileDetail(ownerName and timestamp)
    function set(string memory _ownerName, address _accountAddress) public {
        bool isFileDetailExist = files[_accountAddress].timestamp != 0;
        if(!isFileDetailExist) {
            files[_accountAddress] = FileDetail({timestamp: block.timestamp, ownerName: _ownerName});
        }
        emit logFileAddedStatus(isFileDetailExist, block.timestamp, _ownerName, _accountAddress);
    }
    
    // get FileDetail by accountAddress
    function get(address _accountAddress) public view returns (uint256 timestamp, string memory ownerName) {
        return (files[_accountAddress].timestamp, files[_accountAddress].ownerName);
    }
}