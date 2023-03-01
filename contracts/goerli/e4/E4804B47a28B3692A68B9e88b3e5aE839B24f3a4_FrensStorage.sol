pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

/// @title The primary persistent storage for Frens Staking Pools
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketStorage contract all "Rocket" replaced with "Frens" - everything not used by frens has beed removed.

import "./interfaces/IFrensStorage.sol";

contract FrensStorage is IFrensStorage{

    // Events
    event GuardianChanged(address oldGuardian, address newGuardian);

     // Storage maps
    
    mapping(bytes32 => uint256)    private uintStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bool)       private booleanStorage;
    
    
    // Guardian address
    address guardian;
    address newGuardian;

    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == guardian, "Account is not a guardian");
        _;
    }


    /// @dev Construct FrensStorage
    constructor() {
        // Set the guardian upon deployment
        guardian = msg.sender;
    }

    // Get guardian address
    function getGuardian() external override view returns (address) {
        return guardian;
    }

    // Transfers guardianship to a new address
    function setGuardian(address _newAddress) external override onlyGuardian{
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    // Confirms change of guardian
    function confirmGuardian() external override {
        // Check tx came from new guardian address
        require(msg.sender == newGuardian, "Confirmation must come from new guardian address");
        // Store old guardian for event
        address oldGuardian = guardian;
        // Update guardian and clear storage
        guardian = newGuardian;
        delete newGuardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }


    /// @param _key The key for the record
    function getAddress(bytes32 _key) override external view returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) override external view returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) override external view returns (bool r) {
        return booleanStorage[_key];
    }


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyGuardian override external {
        addressStorage[_key] = _value;
    }
/*
    /// @param _key The key for the record
    function setAddress(string memory _key, address _value) external {
        bytes32 key = keccak256(abi.encodePacked(_key, msg.sender));
        addressStorage[key] = _value;
    }
*/
    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyGuardian override external {
        uintStorage[_key] = _value;
    }

   
    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyGuardian override external {
        booleanStorage[_key] = _value;
    }



    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyGuardian override external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record - added for Frens ~ 0xWildhare
    function deleteUint(bytes32 _key) onlyGuardian override external {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyGuardian override external {
        delete booleanStorage[_key];
    }

   

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value  - 0xWildhare removed safeMath
    function addUint(bytes32 _key, uint256 _amount) onlyGuardian override external {
        uintStorage[_key] += _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value - 0xWildhare removed safeMath
    function subUint(bytes32 _key, uint256 _amount) onlyGuardian override external {
        uintStorage[_key] -= _amount;
    }

}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

   
    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getBool(bytes32 _key) external view returns (bool);   

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setBool(bytes32 _key, bool _value) external;    

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;    

    // Arithmetic 
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    
}