/**
 *Submitted for verification at Etherscan.io on 2022-04-09
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

//import "../ownership/Ownable.sol";

/**
 * @title ShariaHubStorage
 * @dev This contract holds all the necessary state variables to carry out the storage of any contract.
 */
contract ShariaHubStorage {

	mapping(bytes32 => uint256) internal uintStorage;
	mapping(bytes32 => string) internal stringStorage;
	mapping(bytes32 => address) internal addressStorage;
	mapping(bytes32 => bytes) internal bytesStorage;
	mapping(bytes32 => bool) internal boolStorage;
	mapping(bytes32 => int256) internal intStorage;



    /*** Modifiers ************/

    /// @dev Only allow access from the latest version of a contract in the Rocket Pool network after deployment
    modifier onlyShariaHubContracts() {
        // Maje sure the access is permitted to only contracts in our Dapp
        require(addressStorage[keccak256(abi.encodePacked("contract.address", msg.sender))] != address(0x0));
        _;
    }

    constructor()  {
		addressStorage[keccak256(abi.encodePacked("contract.address", msg.sender))] = msg.sender;
    }

	/**** Get Methods ***********/

	/// @param _key The key for the record
	function getAddress(bytes32 _key) external view returns (address) {
		return addressStorage[_key];
	}

	/// @param _key The key for the record
	function getUint(bytes32 _key) external view returns (uint) {
		return uintStorage[_key];
	}

	/// @param _key The key for the record
	function getString(bytes32 _key) external view returns (string memory) {
		return stringStorage[_key];
	}

	/// @param _key The key for the record
	function getBytes(bytes32 _key) external view returns (bytes memory) {
		return bytesStorage[_key];
	}

	/// @param _key The key for the record
	function getBool(bytes32 _key) external view returns (bool) {
		return boolStorage[_key];
	}

	/// @param _key The key for the record
	function getInt(bytes32 _key) external view returns (int) {
		return intStorage[_key];
	}

	/**** Set Methods ***********/

	/// @param _key The key for the record
	function setAddress(bytes32 _key, address _value) onlyShariaHubContracts external {
		addressStorage[_key] = _value;
	}

	/// @param _key The key for the record
	function setUint(bytes32 _key, uint _value) onlyShariaHubContracts external {
		uintStorage[_key] = _value;
	}

	/// @param _key The key for the record
	function setString(bytes32 _key, string memory _value) onlyShariaHubContracts external {
		stringStorage[_key] = _value;
	}

	/// @param _key The key for the record
	function setBytes(bytes32 _key, bytes memory _value) onlyShariaHubContracts external {
		bytesStorage[_key] = _value;
	}

	/// @param _key The key for the record
	function setBool(bytes32 _key, bool _value) onlyShariaHubContracts external {
		boolStorage[_key] = _value;
	}

	/// @param _key The key for the record
	function setInt(bytes32 _key, int _value) onlyShariaHubContracts external {
		intStorage[_key] = _value;
	}

	/**** Delete Methods ***********/

	/// @param _key The key for the record
	function deleteAddress(bytes32 _key) onlyShariaHubContracts external {
		delete addressStorage[_key];
	}

	/// @param _key The key for the record
	function deleteUint(bytes32 _key) onlyShariaHubContracts external {
		delete uintStorage[_key];
	}

	/// @param _key The key for the record
	function deleteString(bytes32 _key) onlyShariaHubContracts external {
		delete stringStorage[_key];
	}

	/// @param _key The key for the record
	function deleteBytes(bytes32 _key) onlyShariaHubContracts external {
		delete bytesStorage[_key];
	}

	/// @param _key The key for the record
	function deleteBool(bytes32 _key) onlyShariaHubContracts external {
		delete boolStorage[_key];
	}

	/// @param _key The key for the record
	function deleteInt(bytes32 _key) onlyShariaHubContracts external {
		delete intStorage[_key];
	}

}