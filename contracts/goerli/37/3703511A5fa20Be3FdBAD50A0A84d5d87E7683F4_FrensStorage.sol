pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

/// @title The primary persistent storage for Frens Staking Pools
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketStorage contract all "Rocket" replaced with "Frens"

import "./interfaces/IFrensStorage.sol";

contract FrensStorage is IFrensStorage{

    // Events
    event NodeWithdrawalAddressSet(address indexed node, address indexed withdrawalAddress, uint256 time);
    event GuardianChanged(address oldGuardian, address newGuardian);

      // Storage maps
    mapping(bytes32 => string)     private stringStorage;
    mapping(bytes32 => bytes)      private bytesStorage;
    mapping(bytes32 => uint256)    private uintStorage;
    mapping(bytes32 => int256)     private intStorage;
    mapping(bytes32 => address)    private addressStorage;
    mapping(bytes32 => bool)       private booleanStorage;
    mapping(bytes32 => bytes32)    private bytes32Storage;
    mapping(bytes32 => uint[])     private arrayStorage; //added for Frens Pool

    // Protected storage (not accessible by network contracts) not used in Frens so this is removed ~ 0xWildhare
    //mapping(address => address)    private withdrawalAddresses;
    //mapping(address => address)    private pendingWithdrawalAddresses;

    // Guardian address
    address guardian;
    address newGuardian;

    // Flag storage has been initialised
    bool storageInit = false;

    /// @dev Only allow access from the latest version of a contract in the Frens Pool network after deployment
    modifier onlyLatestFrensNetworkContract() {
        if (storageInit == true) {
            // Make sure the access is permitted to only contracts in our Dapp
            require(booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))], "Invalid or outdated network contract");
        } else {
            // Only Dapp and the guardian account are allowed access during initialisation.
            // tx.origin is only safe to use in this case for deployment since no external contracts are interacted with
            require((
                booleanStorage[keccak256(abi.encodePacked("contract.exists", msg.sender))] || tx.origin == guardian
            ), "Invalid or outdated network contract attempting access during deployment");
        }
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
    function setGuardian(address _newAddress) external override {
        // Check tx comes from current guardian
        require(msg.sender == guardian, "Is not guardian account");
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

    // Set this as being deployed now
    function getDeployedStatus() external override view returns (bool) {
        return storageInit;
    }

    // Set this as being deployed now
    function setDeployedStatus() external {
        // Only guardian can lock this down
        require(msg.sender == guardian, "Is not guardian account");
        // Set it now
        storageInit = true;
    }

    // Protected storage node withdrawal address is not applicable to Frens Pools this section removed ~ 0xWildhare
/*
    // Get a node's withdrawal address
    function getNodeWithdrawalAddress(address _nodeAddress) public override view returns (address) {
        // If no withdrawal address has been set, return the nodes address
        address withdrawalAddress = withdrawalAddresses[_nodeAddress];
        if (withdrawalAddress == address(0)) {
            return _nodeAddress;
        }
        return withdrawalAddress;
    }

    // Get a node's pending withdrawal address
    function getNodePendingWithdrawalAddress(address _nodeAddress) external override view returns (address) {
        return pendingWithdrawalAddresses[_nodeAddress];
    }

    // Set a node's withdrawal address
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external override {
        // Check new withdrawal address
        require(_newWithdrawalAddress != address(0x0), "Invalid withdrawal address");
        // Confirm the transaction is from the node's current withdrawal address
        address withdrawalAddress = getNodeWithdrawalAddress(_nodeAddress);
        require(withdrawalAddress == msg.sender, "Only a tx from a node's withdrawal address can update it");
        // Update immediately if confirmed
        if (_confirm) {
            updateWithdrawalAddress(_nodeAddress, _newWithdrawalAddress);
        }
        // Set pending withdrawal address if not confirmed
        else {
            pendingWithdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;
        }
    }

    // Confirm a node's new withdrawal address
    function confirmWithdrawalAddress(address _nodeAddress) external override {
        // Get node by pending withdrawal address
        require(pendingWithdrawalAddresses[_nodeAddress] == msg.sender, "Confirmation must come from the pending withdrawal address");
        delete pendingWithdrawalAddresses[_nodeAddress];
        // Update withdrawal address
        updateWithdrawalAddress(_nodeAddress, msg.sender);
    }

    // Update a node's withdrawal address
    function updateWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress) private {
        // Set new withdrawal address
        withdrawalAddresses[_nodeAddress] = _newWithdrawalAddress;
        // Emit withdrawal address set event
        emit NodeWithdrawalAddressSet(_nodeAddress, _newWithdrawalAddress, block.timestamp);
    }
*/

    /// @param _key The key for the record
    function getAddress(bytes32 _key) override external view returns (address r) {
        return addressStorage[_key];
    }

    /// @param _key The key for the record
    function getUint(bytes32 _key) override external view returns (uint256 r) {
        return uintStorage[_key];
    }

    /// @param _key The key for the record
    function getString(bytes32 _key) override external view returns (string memory) {
        return stringStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes(bytes32 _key) override external view returns (bytes memory) {
        return bytesStorage[_key];
    }

    /// @param _key The key for the record
    function getBool(bytes32 _key) override external view returns (bool r) {
        return booleanStorage[_key];
    }

    /// @param _key The key for the record
    function getInt(bytes32 _key) override external view returns (int r) {
        return intStorage[_key];
    }

    /// @param _key The key for the record
    function getBytes32(bytes32 _key) override external view returns (bytes32 r) {
        return bytes32Storage[_key];
    }

    /// @param _key The key for the record - added for Frens ~ 0xWildhare
    function getArray(bytes32 _key) override external view returns (uint[] memory) {
        return arrayStorage[_key];
    }


    /// @param _key The key for the record
    function setAddress(bytes32 _key, address _value) onlyLatestFrensNetworkContract override external {
        addressStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setUint(bytes32 _key, uint _value) onlyLatestFrensNetworkContract override external {
        uintStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setString(bytes32 _key, string calldata _value) onlyLatestFrensNetworkContract override external {
        stringStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes(bytes32 _key, bytes calldata _value) onlyLatestFrensNetworkContract override external {
        bytesStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBool(bytes32 _key, bool _value) onlyLatestFrensNetworkContract override external {
        booleanStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setInt(bytes32 _key, int _value) onlyLatestFrensNetworkContract override external {
        intStorage[_key] = _value;
    }

    /// @param _key The key for the record
    function setBytes32(bytes32 _key, bytes32 _value) onlyLatestFrensNetworkContract override external {
        bytes32Storage[_key] = _value;
    }

    /// @param _key The key for the record
    function setArray(bytes32 _key, uint[] calldata _value) onlyLatestFrensNetworkContract override external {
        arrayStorage[_key] = _value;
    }


    /// @param _key The key for the record
    function deleteAddress(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete addressStorage[_key];
    }

    /// @param _key The key for the record - added for Frens ~ 0xWildhare
    function deleteUint(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete uintStorage[_key];
    }

    /// @param _key The key for the record
    function deleteString(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete stringStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete bytesStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBool(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete booleanStorage[_key];
    }

    /// @param _key The key for the record
    function deleteInt(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete intStorage[_key];
    }

    /// @param _key The key for the record
    function deleteBytes32(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete bytes32Storage[_key];
    }

    /// @param _key The key for the record
    function deleteArray(bytes32 _key) onlyLatestFrensNetworkContract override external {
        delete arrayStorage[_key];
    }


    /// @param _key The key for the record
    /// @param _amount An amount to add to the record's value  - 0xWildhare removed safeMath
    function addUint(bytes32 _key, uint256 _amount) onlyLatestFrensNetworkContract override external {
        uintStorage[_key] += _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An amount to subtract from the record's value - 0xWildhare removed safeMath
    function subUint(bytes32 _key, uint256 _amount) onlyLatestFrensNetworkContract override external {
        uintStorage[_key] -= _amount;
    }

    /// @param _key The key for the record
    /// @param _amount An uint to push into the record's array - added by 0xWildhare
    function pushUint(bytes32 _key, uint256 _amount) onlyLatestFrensNetworkContract override external {
        arrayStorage[_key].push(_amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;


// SPDX-License-Identifier: GPL-3.0-only
//modified from IRocketStorage on 03/12/2022 by 0xWildhare

interface IFrensStorage {

    // Deploy status
    function getDeployedStatus() external view returns (bool);

    // Guardian
    function getGuardian() external view returns(address);
    function setGuardian(address _newAddress) external;
    function confirmGuardian() external;

    // Getters
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string memory);
    function getBytes(bytes32 _key) external view returns (bytes memory);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
    function getBytes32(bytes32 _key) external view returns (bytes32);
    function getArray(bytes32 _key) external view returns (uint[] memory);

    // Setters
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string calldata _value) external;
    function setBytes(bytes32 _key, bytes calldata _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
    function setBytes32(bytes32 _key, bytes32 _value) external;
    function setArray(bytes32 _key, uint[] calldata _value) external;

    // Deleters
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;
    function deleteBytes32(bytes32 _key) external;
    function deleteArray(bytes32 _key) external;

    // Arithmetic (and stuff) - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) external;
    function subUint(bytes32 _key, uint256 _amount) external;
    function pushUint(bytes32 _key, uint256 _amount) external;

    // Protected storage removed ~ 0xWildhare
    /*
    function getNodeWithdrawalAddress(address _nodeAddress) external view returns (address);
    function getNodePendingWithdrawalAddress(address _nodeAddress) external view returns (address);
    function setWithdrawalAddress(address _nodeAddress, address _newWithdrawalAddress, bool _confirm) external;
    function confirmWithdrawalAddress(address _nodeAddress) external;
    */
}