/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// Sources flattened with hardhat v2.10.1 https://hardhat.org

// File contracts/interfaces/DeCashStorageInterface.sol

pragma solidity 0.8.15;

// SPDX-License-Identifier: MIT
// Source code: https://github.com/DeCash-Official/smart-contracts

interface DeCashStorageInterface {
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
}

// File contracts/contract/DeCashStorage.sol

pragma solidity 0.8.15;

// Source code: https://github.com/DeCash-Official/smart-contracts

/// @title The primary persistent storage for DeCash Token (Credits David Rugendyke/Rocket Pool)
/// @author Shadowy Coders

contract DeCashStorage is DeCashStorageInterface {
  // Storage types
  mapping(bytes32 => uint256) private _uIntStorage;
  mapping(bytes32 => string) private _stringStorage;
  mapping(bytes32 => address) private _addressStorage;
  mapping(bytes32 => bytes) private _bytesStorage;
  mapping(bytes32 => bool) private _boolStorage;
  mapping(bytes32 => int256) private _intStorage;
  mapping(bytes32 => bytes32) private _bytes32Storage;

  /// @dev Only allow access from the latest version of a DeCash token contract after deployment
  modifier onlyLatestDeCashNetworkContract() {
    // The owner and other contracts are only allowed to set the storage upon deployment to register the initial contracts/settings, afterwards their direct access is disabled
    if (
      _boolStorage[
        keccak256(abi.encodePacked("contract.storage.initialised"))
      ] == true
    ) {
      // Make sure the access is permitted to only contracts in our Dapp
      require(
        _boolStorage[
          keccak256(abi.encodePacked("contract.exists", msg.sender))
        ],
        "Invalid or outdated network contract"
      );
    }
    _;
  }

  /// @dev Construct DeCashStorage
  constructor() {
    // Set the main owner upon deployment
    _boolStorage[
      keccak256(abi.encodePacked("access.role", "owner", msg.sender))
    ] = true;
  }

  function getAddress(bytes32 _key) external view override returns (address) {
    return _addressStorage[_key];
  }

  function getUint(bytes32 _key) external view override returns (uint256) {
    return _uIntStorage[_key];
  }

  function getString(bytes32 _key)
    external
    view
    override
    returns (string memory)
  {
    return _stringStorage[_key];
  }

  function getBytes(bytes32 _key)
    external
    view
    override
    returns (bytes memory)
  {
    return _bytesStorage[_key];
  }

  function getBool(bytes32 _key) external view override returns (bool) {
    return _boolStorage[_key];
  }

  function getInt(bytes32 _key) external view override returns (int256) {
    return _intStorage[_key];
  }

  function getBytes32(bytes32 _key) external view override returns (bytes32) {
    return _bytes32Storage[_key];
  }

  function setAddress(bytes32 _key, address _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _addressStorage[_key] = _value;
  }

  function setUint(bytes32 _key, uint256 _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _uIntStorage[_key] = _value;
  }

  function setString(bytes32 _key, string calldata _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _stringStorage[_key] = _value;
  }

  function setBytes(bytes32 _key, bytes calldata _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _bytesStorage[_key] = _value;
  }

  function setBool(bytes32 _key, bool _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _boolStorage[_key] = _value;
  }

  function setInt(bytes32 _key, int256 _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _intStorage[_key] = _value;
  }

  function setBytes32(bytes32 _key, bytes32 _value)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    _bytes32Storage[_key] = _value;
  }

  function deleteAddress(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _addressStorage[_key];
  }

  function deleteUint(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _uIntStorage[_key];
  }

  function deleteString(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _stringStorage[_key];
  }

  function deleteBytes(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _bytesStorage[_key];
  }

  function deleteBool(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _boolStorage[_key];
  }

  function deleteInt(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _intStorage[_key];
  }

  function deleteBytes32(bytes32 _key)
    external
    override
    onlyLatestDeCashNetworkContract
  {
    delete _bytes32Storage[_key];
  }
}

// File contracts/currencies/EURD/EURDStorage.sol

pragma solidity 0.8.15;

// Source code: https://github.com/DeCash-Official/smart-contracts

contract USDDStorage is DeCashStorage {

}