pragma solidity >=0.8.0 <0.9.0;
//SPDX-License-Identifier: MIT

import "./FrensBase.sol";

contract FrensPoolSetter is FrensBase {

    constructor(IFrensStorage _frensStorage) FrensBase(_frensStorage){
        version = 0;
    }

    function create(address stakingPool, bool validatorLocked/*, bool frensLocked, uint poolMin, uint poolMax*/) external returns(bool) {
        string memory callingContract = getString(keccak256(abi.encodePacked("contract.name", msg.sender)));
        require(keccak256(abi.encodePacked(callingContract)) == keccak256(abi.encodePacked("StakingPoolFactory")), "only factory can call");
        setBool(keccak256(abi.encodePacked("pool.exists", stakingPool)), true);
        setBool(keccak256(abi.encodePacked("validator.locked", stakingPool)), validatorLocked);
        //setBool(keccak256(abi.encodePacked("frens.locked", stakingPool)), frensLocked);
        //setUint(keccak256(abi.encodePacked("pool.min", stakingPool)), poolMin);
        //setUint(keccak256(abi.encodePacked("pool.max", stakingPool)), poolMax);
        return true;
    }

    function depositToPool(uint depositAmount) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("token.id")), 1); //increment token id
        uint id = getUint(keccak256(abi.encodePacked("token.id"))); //retrieve token id
        setUint(keccak256(abi.encodePacked("deposit.amount", id)), depositAmount); //assign msg.value to the deposit.amount of token id
        addUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), depositAmount); //increase total.deposits of this pool by msg.value
        pushUint(keccak256(abi.encodePacked("ids.in.pool", msg.sender)), id); //add id to list of ids in pool
        setAddress(keccak256(abi.encodePacked("pool.for.id", id)), msg.sender); //set this as the pool for id
        bool transferLocked = getBool(keccak256(abi.encodePacked("frens.locked", msg.sender)));
        setBool(keccak256(abi.encodePacked("transfer.locked", id)), transferLocked); //set transfer lock if  pool is locked (use rageQuit if locked)
        return true;
    }

    function addToDeposit(uint id, uint amount) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("deposit.amount", id)), amount); //add msg.value to deposit.amount for id
        addUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), amount); //add msg.value to total.deposits for pool
        return true;
    }

    function setPubKey(
    bytes calldata pubKey,
    bytes calldata withdrawal_credentials,
    bytes calldata signature,
    bytes32 deposit_data_root
    ) external onlyStakingPool(msg.sender) returns(bool) {
        setBytes(keccak256(abi.encodePacked("pubKey", msg.sender)), pubKey);
        setBytes(keccak256(abi.encodePacked("withdrawal_credentials", msg.sender)), withdrawal_credentials);
        setBytes(keccak256(abi.encodePacked("signature", msg.sender)), signature);
        setBytes32(keccak256(abi.encodePacked("deposit_data_root", msg.sender)), deposit_data_root);
        setBool(keccak256(abi.encodePacked("validator.set", msg.sender)), true);
        return true;
    }

    function withdraw(uint _id, uint _amount) external onlyStakingPool(msg.sender) returns(bool) {
        subUint(keccak256(abi.encodePacked("deposit.amount", _id)), _amount);
        subUint(keccak256(abi.encodePacked("total.deposits", msg.sender)), _amount);
        return true;
    }

    function distribute(address tokenOwner, uint share) external onlyStakingPool(msg.sender) returns(bool) {
        addUint(keccak256(abi.encodePacked("claimable.amount", tokenOwner)), share);
        return true;
    }

    function setArt(address newArtContract) external onlyStakingPool(msg.sender) returns(bool) { 
        setAddress(keccak256(abi.encodePacked("pool.specific.art.address", msg.sender)), newArtContract);
        return true;
    }

    function rageQuit(uint id, uint price) external onlyStakingPool(msg.sender) returns(bool) {
        setBool(keccak256(abi.encodePacked("rage.quitting", id)), true);
        setUint(keccak256(abi.encodePacked("rage.time", id)), block.timestamp);
        setUint(keccak256(abi.encodePacked("rage.price", id)), price);
        return true;
    }

    function unlockTransfer(uint id) external onlyStakingPool(msg.sender) returns(bool) {
        setBool(keccak256(abi.encodePacked("transfer.locked", id)), false);
        return true;
    }
}

pragma solidity >=0.8.0 <0.9.0;

// SPDX-License-Identifier: GPL-3.0-only

import "./interfaces/IFrensStorage.sol";

/// @title Base settings / modifiers for each contract in Frens Pool
/// @author modified 04-Dec-2022 by 0xWildhare originally by David Rugendyke (h/t David and Rocket Pool!)
/// this code is modified from the Rocket Pool RocketBase contract all "Rocket" replaced with "Frens"

abstract contract FrensBase {

    // Calculate using this as the base
    uint256 constant calcBase = 1 ether;

    // Version of the contract
    uint8 public version;

    // The main storage contract where primary persistant storage is maintained
    IFrensStorage frensStorage;


    /*** Modifiers **********************************************************/

    /**
    * @dev Throws if called by any sender that doesn't match a Frens Pool network contract
    */
    modifier onlyLatestNetworkContract() {
        require(getBool(keccak256(abi.encodePacked("contract.exists", msg.sender))), "Invalid or outdated network contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that doesn't match one of the supplied contract or is the latest version of that contract
    */
    modifier onlyLatestContract(string memory _contractName, address _contractAddress) {
        require(_contractAddress == getAddress(keccak256(abi.encodePacked("contract.address", _contractName))), "Invalid or outdated contract");
        _;
    }

    /**
    * @dev Throws if called by any sender that isn't a registered node
    */
    //removed  0xWildhare
    /*
    modifier onlyRegisteredNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("node.exists", _nodeAddress))), "Invalid node");
        _;
    }
    */
    /**
    * @dev Throws if called by any sender that isn't a trusted node DAO member
    */
    //removed  0xWildhare
    /*
    modifier onlyTrustedNode(address _nodeAddress) {
        require(getBool(keccak256(abi.encodePacked("dao.trustednodes.", "member", _nodeAddress))), "Invalid trusted node");
        _;
    }
    */

    /**
    * @dev Throws if called by any sender that isn't a registered Frens StakingPool
    */
    modifier onlyStakingPool(address _stakingPoolAddress) {
        require(getBool(keccak256(abi.encodePacked("pool.exists", _stakingPoolAddress))), "Invalid Pool");
        _;
    }


    /**
    * @dev Throws if called by any account other than a guardian account (temporary account allowed access to settings before DAO is fully enabled)
    */
    modifier onlyGuardian() {
        require(msg.sender == frensStorage.getGuardian(), "Account is not a temporary guardian");
        _;
    }


    





    /*** Methods **********************************************************/

    /// @dev Set the main Frens Storage address
    constructor(IFrensStorage _frensStorage) {
        // Update the contract address
        frensStorage = IFrensStorage(_frensStorage);
    }


    /// @dev Get the address of a network contract by name
    function getContractAddress(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Check it
        require(contractAddress != address(0x0), "Contract not found");
        // Return
        return contractAddress;
    }


    /// @dev Get the address of a network contract by name (returns address(0x0) instead of reverting if contract does not exist)
    function getContractAddressUnsafe(string memory _contractName) internal view returns (address) {
        // Get the current contract address
        address contractAddress = getAddress(keccak256(abi.encodePacked("contract.address", _contractName)));
        // Return
        return contractAddress;
    }


    /// @dev Get the name of a network contract by address
    function getContractName(address _contractAddress) internal view returns (string memory) {
        // Get the contract name
        string memory contractName = getString(keccak256(abi.encodePacked("contract.name", _contractAddress)));
        // Check it
        require(bytes(contractName).length > 0, "Contract not found");
        // Return
        return contractName;
    }

    /// @dev Get revert error message from a .call method
    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";
        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }



    /*** Frens Storage Methods ****************************************/

    // Note: Unused helpers have been removed to keep contract sizes down

    /// @dev Storage get methods
    function getAddress(bytes32 _key) internal view returns (address) { return frensStorage.getAddress(_key); }
    function getUint(bytes32 _key) internal view returns (uint) { return frensStorage.getUint(_key); }
    function getString(bytes32 _key) internal view returns (string memory) { return frensStorage.getString(_key); }
    function getBytes(bytes32 _key) internal view returns (bytes memory) { return frensStorage.getBytes(_key); }
    function getBool(bytes32 _key) internal view returns (bool) { return frensStorage.getBool(_key); }
    function getInt(bytes32 _key) internal view returns (int) { return frensStorage.getInt(_key); }
    function getBytes32(bytes32 _key) internal view returns (bytes32) { return frensStorage.getBytes32(_key); }
    function getArray(bytes32 _key) internal view returns (uint[] memory) { return frensStorage.getArray(_key); }

    /// @dev Storage set methods
    function setAddress(bytes32 _key, address _value) internal { frensStorage.setAddress(_key, _value); }
    function setUint(bytes32 _key, uint _value) internal { frensStorage.setUint(_key, _value); }
    function setString(bytes32 _key, string memory _value) internal { frensStorage.setString(_key, _value); }
    function setBytes(bytes32 _key, bytes memory _value) internal { frensStorage.setBytes(_key, _value); }
    function setBool(bytes32 _key, bool _value) internal { frensStorage.setBool(_key, _value); }
    function setInt(bytes32 _key, int _value) internal { frensStorage.setInt(_key, _value); }
    function setBytes32(bytes32 _key, bytes32 _value) internal { frensStorage.setBytes32(_key, _value); }
    function setArray(bytes32 _key, uint[] memory _value) internal { frensStorage.setArray(_key, _value); }

    /// @dev Storage delete methods
    function deleteAddress(bytes32 _key) internal { frensStorage.deleteAddress(_key); }
    function deleteUint(bytes32 _key) internal { frensStorage.deleteUint(_key); }
    function deleteString(bytes32 _key) internal { frensStorage.deleteString(_key); }
    function deleteBytes(bytes32 _key) internal { frensStorage.deleteBytes(_key); }
    function deleteBool(bytes32 _key) internal { frensStorage.deleteBool(_key); }
    function deleteInt(bytes32 _key) internal { frensStorage.deleteInt(_key); }
    function deleteBytes32(bytes32 _key) internal { frensStorage.deleteBytes32(_key); }
    function deleteArray(bytes32 _key) internal { frensStorage.deleteArray(_key); }

    /// @dev Storage arithmetic methods - push added by 0xWildhare
    function addUint(bytes32 _key, uint256 _amount) internal { frensStorage.addUint(_key, _amount); }
    function subUint(bytes32 _key, uint256 _amount) internal { frensStorage.subUint(_key, _amount); }
    function pushUint(bytes32 _key, uint256 _amount) internal { frensStorage.pushUint(_key, _amount); }
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