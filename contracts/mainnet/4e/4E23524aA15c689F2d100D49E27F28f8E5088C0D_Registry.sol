// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface IRegistry
{
  function get (string calldata name) external view returns (address);


  function provisioner () external view returns (address);

  function frontender () external view returns (address);

  function collector () external view returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import { IRegistry } from "./interfaces/IRegistry.sol";


contract Registry is IRegistry
{
  bytes32 private constant _PROVISIONER = keccak256("Provisioner");
  bytes32 private constant _FRONTENDER = keccak256("Frontender");
  bytes32 private constant _COLLECTOR = keccak256("Collector");


  address private _registrar;

  mapping(bytes32 => address) private _implementation;


  event Register(bytes32[] keys, address[] implementations);


  constructor ()
  {
    _registrar = msg.sender;
  }


  function _isOpen () internal view
  {
    require(_registrar != address(0), "closed");
    require(msg.sender == _registrar, "!registrar");
  }

  function register (bytes32[] calldata keys, address[] calldata implementations) external
  {
    _isOpen();
    require(keys.length == implementations.length, "!=");


    bytes32 key;
    address implementation;

    for (uint256 i; i < keys.length;)
    {
      key = keys[i];
      implementation = implementations[i];

      require(key != bytes32(0), "!valid key");
      require(implementation != address(0), "!valid impl");
      require(_implementation[key] != implementation, "registered");


      _implementation[key] = implementation;


      unchecked { i++; }
    }


    emit Register(keys, implementations);
  }

  function close () external
  {
    _isOpen();


    _registrar = address(0);
  }


  function closed () external view returns (bool)
  {
    return _registrar == address(0);
  }


  function exists (string calldata name) external view returns (bool)
  {
    return _implementation[keccak256(bytes(name))] != address(0);
  }

  function get (string calldata name) external view returns (address)
  {
    address implementation = _implementation[keccak256(bytes(name))];

    require(implementation != address(0), "!exist");


    return implementation;
  }

  function provisioner () external view returns (address)
  {
    return _implementation[_PROVISIONER];
  }

  function frontender () external view returns (address)
  {
    return _implementation[_FRONTENDER];
  }

  function collector () external view returns (address)
  {
    return _implementation[_COLLECTOR];
  }
}