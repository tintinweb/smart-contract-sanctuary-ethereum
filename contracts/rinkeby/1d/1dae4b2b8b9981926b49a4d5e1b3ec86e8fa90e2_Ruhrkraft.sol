/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.4;

/**
 * @dev Store & retrieve value
 */
contract Ruhrkraft {

     string  private clientId;
     string  private storeId;
     string  private deviceId;
     string  private deviceLocation;
     uint    private attentionTime;
     string  private detectedAt;
     string  private source;
     string  private fileId;
     string  private fileName;

    function setClientId(string calldata _clientId) external {
        clientId = _clientId;
    }
    
    function getClientId() external view returns (string memory) {
        return clientId;
    }

    function setStoreId(string calldata _storeId) external {
        storeId = _storeId;
    }
    
    function getStoreId() external view returns (string memory) {
        return storeId;
    }

    function setDeviceId(string calldata _deviceId) external {
        deviceId = _deviceId;
    }
    
    function getDeviceId() external view returns (string memory) {
        return deviceId;
    }

    function setDeviceLocation(string calldata _deviceLocation) external {
        deviceLocation = _deviceLocation;
    }
    
    function getDeviceLocation() external view returns (string memory) {
        return deviceLocation;
    }

    function setAttentionTime(uint _attentionTime) external {
        attentionTime = _attentionTime;
    }
    
    function getAttentionTime() external view returns (uint) {
        return attentionTime;
    }

    function setDetectedAt(string calldata _detectedAt) external {
        detectedAt = _detectedAt;
    }
    
    function getDetectedAt() external view returns (string memory) {
        return detectedAt;
    }

    function setSource(string calldata _source) external {
        source = _source;
    }
    
    function getSource() external view returns (string memory) {
        return source;
    }

    function setFileId(string calldata _fileId) external {
        fileId = _fileId;
    }
    
    function getFileId() external view returns (string memory) {
        return fileId;
    }

    function setFileName(string calldata _fileName) external {
        fileName = _fileName;
    }
    
    function getFileName() external view returns (string memory) {
        return fileName;
    }
}