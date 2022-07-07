/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @dev Store & retrieve value
   Version 2 storing each parameter in a struct and retrieving it separately 
 */
contract Ruhrkraft2 {

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

    function getClientId() external view returns (string memory) {
        return object.clientId;
    }

    
    function getStoreId() external view returns (string memory) {
        return object.storeId;
    }

    
    function getDeviceId() external view returns (string memory) {
        return object.deviceId;
    }

   
    
    function getDeviceLocation() external view returns (string memory) {
        return object.deviceLocation;
    }

    
    function getAttentionTime() external view returns (uint) {
        return object.attentionTime;
    }

    
    function getDetectedAt() external view returns (string memory) {
        return object.detectedAt;
    }

    
    function getSource() external view returns (string memory) {
        return object.source;
    }

    
    function getFileId() external view returns (string memory) {
        return object.fileId;
    }

    
    function getFileName() external view returns (string memory) {
        return object.fileName;
    }
}