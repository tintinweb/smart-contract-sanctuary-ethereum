/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @dev Store & retrieve value
 */
contract Ruhrkraft3 {

struct Object {
     string   clientId;
     string   storeId;
     string   deviceId;
     string   deviceLocation;
     uint     attentionTime;
     string   detectedAt;
     string   source;
     string   fileId;
     string   fileName;
}

     Object object; 

    function set(string memory _clientId, string memory _storeId, string memory _deviceId, string memory _deviceLocation, uint _attentionTime, string memory _detectedAt, string memory _source, string memory _fileId, string memory _fileName) public {
        object = Object( {clientId:_clientId, storeId:_storeId, deviceId:_deviceId, deviceLocation:_deviceLocation, attentionTime:_attentionTime, detectedAt:_detectedAt, source:_source, fileId:_fileId, fileName:_fileName});
    }

    function get() external view returns (string memory, string memory, string memory, string memory, uint, string memory, string memory, string memory, string memory) {
        return (object.clientId, object.storeId, object.deviceId, object.deviceLocation, object.attentionTime, object.detectedAt, object.source, object.fileId, object.fileName);
    }
}