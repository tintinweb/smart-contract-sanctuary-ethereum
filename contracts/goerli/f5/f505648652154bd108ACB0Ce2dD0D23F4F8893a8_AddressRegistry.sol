// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "./IAddressRegistry.sol";

contract AddressRegistry is IAddressRegistry {
  mapping(bytes32 => address) public addresses;
  address public controller;

  event ControllerSet(address _newController);
  event ContractRegistered(string _name, address _address);

  modifier onlyController() {
    require(msg.sender == controller, "AddressRegistry: not controller");
    _;
  }

  constructor() {
    controller = msg.sender;
  }

  function register(string calldata _name, address _address) external override onlyController {
    addresses[keccak256(abi.encode(_name))] = _address;
    emit ContractRegistered(_name, _address);
  }

  function updateController(address _newController) external override onlyController {
    controller = _newController;
    emit ControllerSet(_newController);
  }

  function get(string calldata _contract) external view override returns (address) {
    address contractAddress = addresses[keccak256((abi.encode((_contract))))];
    require(contractAddress != address(0), "AddressRegistry: found zero address");
    return contractAddress;
  }

  function getController() external view override returns (address) {
    return controller;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAddressRegistry {
  function register(string calldata _name, address _address) external;

  function updateController(address _newController) external;

  function get(string calldata _name) external view returns (address);

  function getController() external view returns (address);
}