// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

/// @title DataStorage, Data Storage Contract,
/// @author liorabadi
/// @notice Base and hub where all variables are stored and handled.

import "./interfaces/DataStorageInterface.sol";

contract DataStorage is DataStorageInterface{

    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => bool)    private boolStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    // Initialization flag
    bool storageLive = false;

    // Address of the Storage Guardian
    address currentGuardian;
    address newGuardian;

    event GuardChange(address indexed _lastGuardian, address _newGuardian);


    constructor() {
        currentGuardian = msg.sender;
        _setDataStorageAddress();
    }

    /// @notice The guardian needs to store the other Pool contracts within the Bool State tracker before setting the DataStorage contract as live.
    /// @notice tx.origin is checked only in deployment and pool implementation status. Not operative.
    modifier onlyByPoolContract {
            if(!storageLive){
                require(tx.origin == currentGuardian || boolStorage[keccak256(abi.encodePacked("contract_exists", msg.sender))], "The contract address is invalid or the caller is not allowed.");
            } else {
                require(boolStorage[keccak256(abi.encodePacked("contract_exists", msg.sender))], "The contract address or sender is invalid.");
            }
        _;
    }

    // ====== Storage Contract Control ======
    /// @dev Store this contract address and existance on the main storage.
    /// @notice Called while deploying the contract. 
    function _setDataStorageAddress() private {
        bytes32 dsBoolTag = keccak256(abi.encodePacked("contract_exists", address(this)));
        bytes32 dsAddressTag = keccak256(abi.encodePacked("contract_address", "DataStorage"));

        boolStorage[dsBoolTag] = true;
        addressStorage[dsAddressTag] = address(this);
    }

    function getStorageStatus() external view returns(bool){
        return storageLive;
    }    

    function getCurrentGuardian() external view returns(address){
        return currentGuardian;
    }

    function setNewGuardian(address _newGuardian) external {
        require(msg.sender == currentGuardian, "Only callable by current storage guardian.");
        newGuardian = _newGuardian;
    }

    function confirmGuard() external {
        require(msg.sender == newGuardian, "Only callable by the new storage guardian.");
        address oldGuardian = currentGuardian;
        currentGuardian = newGuardian;
        delete newGuardian;
        emit GuardChange(oldGuardian, currentGuardian);
    } 

    /// @notice Irreversible. Once the storage hub is live, stays that way.
    function setStorageLive() external {
        require(msg.sender == currentGuardian, "Only callable by current guardian.");
        storageLive = true;
    }   

    // ====== Storage Mappings Getters ======
    function getUintStorage(bytes32 _id) external view returns(uint256){
        return uintStorage[_id];
    }

    function getBoolStorage(bytes32 _id) external view returns(bool){
        return boolStorage[_id];
    }

    function getAddressStorage(bytes32 _id) external view returns(address){
        return addressStorage[_id];
    }

    function getDataStorageAddress() external view returns(address){
        bytes32 dsAddressTag = keccak256(abi.encodePacked("contract_address", "DataStorage"));
        return addressStorage[dsAddressTag];
    }          
    
   
    // ====== Storage Mappings Setters ======
    function setUintStorage(bytes32 _id, uint256 _value) external onlyByPoolContract{
        uintStorage[_id] = _value;
    }

    function increaseUintStorage(bytes32 _id, uint256 _increment) external onlyByPoolContract{
        uintStorage[_id] += _increment;
    }
    
    function decreaseUintStorage(bytes32 _id, uint256 _decrement) external onlyByPoolContract{
        uintStorage[_id] -= _decrement;
    }          

    function setBoolStorage(bytes32 _id, bool _value) external onlyByPoolContract{
        boolStorage[_id] = _value;
    }    

    function setAddressStorage(bytes32 _id, address _value) external onlyByPoolContract{
        addressStorage[_id] = _value;
    } 


    // ====== Storage Mappings Deleters ======
    function deleteUintStorage(bytes32 _id) external onlyByPoolContract{
        delete uintStorage[_id];
    }    
    
    function deleteBoolStorage(bytes32 _id) external onlyByPoolContract{
        delete boolStorage[_id];
    }    

    function deleteAddressStorage(bytes32 _id) external onlyByPoolContract{
        delete addressStorage[_id];
    } 

    
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface DataStorageInterface {

    // ====== Storage Contract Control ======
    function getStorageStatus() external view returns(bool);
    function getCurrentGuardian() external view returns(address);
    function setNewGuardian(address _newGuardian) external;
    function confirmGuard() external;
    function setStorageLive() external;

    // ====== Storage Mappings Getters ======
    function getUintStorage(bytes32 _id) external view returns(uint256);
    function getBoolStorage(bytes32 _id) external view returns(bool);
    function getAddressStorage(bytes32 _id) external view returns(address);
    function getDataStorageAddress() external view returns(address);

    // ====== Storage Mappings Setters ======
    function setUintStorage(bytes32 _id, uint256 _value) external;
    function setBoolStorage(bytes32 _id, bool _value) external;
    function setAddressStorage(bytes32 _id, address _value) external; 
    function increaseUintStorage(bytes32 _id, uint256 _increment) external;
    function decreaseUintStorage(bytes32 _id, uint256 _decrement) external;        

    // ====== Storage Mappings Deleters ======
    function deleteUintStorage(bytes32 _id) external;
    function deleteBoolStorage(bytes32 _id) external;
    function deleteAddressStorage(bytes32 _id) external;

}