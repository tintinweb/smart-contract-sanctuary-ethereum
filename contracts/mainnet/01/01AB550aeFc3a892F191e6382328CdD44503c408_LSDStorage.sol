// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interface/ILSDStorage.sol";

/// @title The primary persistent storage for LSD

contract LSDStorage is ILSDStorage {
    // Events
    event GuardianChanged(address oldGuardian, address newGuardian);

    // Storage maps
    mapping(bytes32 => string) private stringStorage;
    mapping(bytes32 => bytes) private bytesStorage;
    mapping(bytes32 => uint256) private uintStorage;
    mapping(bytes32 => int256) private intStorage;
    mapping(bytes32 => address) private addressStorage;
    mapping(bytes32 => bool) private booleanStorage;
    mapping(bytes32 => bytes32) private bytes32Storage;

    // Guardian address
    address guardian;
    address newGuardian;

    // Flag storage has been initialised
    bool storageInit = false;

    /// @dev Only allow access from the LSD Contract after deployment
    modifier onlyLSDNetworkContract() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            require(
                booleanStorage[
                    keccak256(abi.encodePacked("contract.exists", msg.sender))
                ],
                "Invalid or outdated network contract"
            );
        } else {
            // Only Dapp and the guardian account are allowed access during initialisation.
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            require(
                (booleanStorage[
                    keccak256(abi.encodePacked("contract.exists", msg.sender))
                ] || tx.origin == guardian),
                "Invalid or outdated network contract attempting access during deployment"
            );
        }
        _;
    }

    /// @dev Construct RocketStorage
    constructor() {
        // Set the guardian upon deployment
        guardian = msg.sender;
    }

    // Get guardian address
    function getGuardian() external view override returns (address) {
        return guardian;
    }

    // Transfers guardianship to a new address
    function setGuardian(address _newAddress) external override {
        // Check tx comes from current guardian
        require(msg.sender == guardian, "Is not guardian account");
        // Store new address awaiting confirmation
        newGuardian = _newAddress;
    }

    // Confirms change of guardian
    function confirmGuardian() external override {
        // Check tx came from new guardian address
        require(
            msg.sender == newGuardian,
            "Confirmation must come from new guardian address"
        );
        // Store old guardian for event
        address oldGuardian = guardian;
        // Update guardian and clear storage
        guardian = newGuardian;
        delete newGuardian;
        // Emit event
        emit GuardianChanged(oldGuardian, guardian);
    }

    // Set this as being deployed now
    function getDeployedStatus() external view override returns (bool) {
        return storageInit;
    }

    // Set this as being deployed now
    function setDeployedStatus() external {
        // Only guardian can lock this down
        require(msg.sender == guardian, "Is not guardian account");
        // Set it now
        storageInit = true;
    }

    /// @param _key The key for the record
    function getAddress(bytes32 _key)
        external
        view
        override
        returns (address r)
    {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) external view override returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key)
        external
        view
        override
        returns (string memory)
    {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key)
        external
        view
        override
        returns (bytes memory)
    {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) external view override returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) external view override returns (int256 r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key)
        external
        view
        override
        returns (bytes32 r)
    {
        return bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value)
        external
        override
        onlyLSDNetworkContract
    {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint256 _value)
        external
        override
        onlyLSDNetworkContract
    {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value)
        external
        override
        onlyLSDNetworkContract
    {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value)
        external
        override
        onlyLSDNetworkContract
    {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value)
        external
        override
        onlyLSDNetworkContract
    {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int256 _value)
        external
        override
        onlyLSDNetworkContract
    {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value)
        external
        override
        onlyLSDNetworkContract
    {
        bytes32Storage[_key] = _value;
    }

    /// @param _key The key for the record
    function deleteAddress(bytes32 _key)
        external
        override
        onlyLSDNetworkContract
    {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record
    function deleteUint(bytes32 _key) external override onlyLSDNetworkContract {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key)
        external
        override
        onlyLSDNetworkContract
    {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key)
        external
        override
        onlyLSDNetworkContract
    {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) external override onlyLSDNetworkContract {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) external override onlyLSDNetworkContract {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key)
        external
        override
        onlyLSDNetworkContract
    {
        delete bytes32Storage[_key];
    }

    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value
    function addUint(bytes32 _key, uint256 _amount)
        external
        override
        onlyLSDNetworkContract
    {
        uintStorage[_key] = uintStorage[_key] + _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value
    function subUint(bytes32 _key, uint256 _amount)
        external
        override
        onlyLSDNetworkContract
    {
        uintStorage[_key] = uintStorage[_key] - _amount;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface ILSDStorage {
    // Depoly status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns (address);

    function setGuardian(address _newAddress) external;

    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);

    function getUint(bytes32 _key) external view returns (uint256);

    function getString(bytes32 _key) external view returns (string memory);

    function getBytes(bytes32 _key) external view returns (bytes memory);

    function getBool(bytes32 _key) external view returns (bool);

    function getInt(bytes32 _key) external view returns (int256);

    function getBytes32(bytes32 _key) external view returns (bytes32);

    // Setters
    function setAddress(bytes32 _key, address _value) external;

    function setUint(bytes32 _key, uint256 _value) external;

    function setString(bytes32 _key, string calldata _value) external;

    function setBytes(bytes32 _key, bytes calldata _value) external;

    function setBool(bytes32 _key, bool _value) external;

    function setInt(bytes32 _key, int256 _value) external;

    function setBytes32(bytes32 _key, bytes32 _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;

    function deleteUint(bytes32 _key) external;

    function deleteString(bytes32 _key) external;

    function deleteBytes(bytes32 _key) external;

    function deleteBool(bytes32 _key) external;

    function deleteInt(bytes32 _key) external;

    function deleteBytes32(bytes32 _key) external;

    // Arithmetic
    function addUint(bytes32 _key, uint256 _amount) external;

    function subUint(bytes32 _key, uint256 _amount) external;
}