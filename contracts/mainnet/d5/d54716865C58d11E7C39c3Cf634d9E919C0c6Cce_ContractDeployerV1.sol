// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/IContractDeployerV1.sol";
import "./library/StringHelper.sol";
import "./library/TransferHelper.sol";
import "./structs/DeployInfo.sol";

contract ContractDeployerV1 is IContractDeployerV1 {
  using StringHelper for string;

  bytes32 constant private SALT = keccak256(abi.encodePacked("NgdD9MyZbubJ9kZ oxd9BUZqg01Vz0z"));
  string constant private IDENTIFIER = "ContractDeployer";
  uint constant private VERSION = 1;

  address private immutable _deployer;
  Dependency[] _dependencies;

  address private _router;
  address private _feeSetter;

  mapping(string => DeployInfo) _register;

  bool private _locked;

  constructor() {
    _deployer = msg.sender;
    _dependencies.push(Dependency("Router", 1));
    _dependencies.push(Dependency("FeeSetter", 1));
  }

  receive() external payable { TransferHelper.safeTransferETH(_feeSetter, msg.value); }
  fallback() external payable { TransferHelper.safeTransferETH(_feeSetter, msg.value); }

  modifier lock() {
    require(!_locked, "ContractDeployer: reentrancy");
    _locked = true;
    _;
    _locked = false;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "ContractDeployer: caller must be the deployer");
    _;
  }

  function identifier() external pure returns (string memory) {
    return IDENTIFIER;
  }

  function version() external pure returns (uint) {
    return VERSION;
  }

  function dependencies() external view returns (Dependency[] memory) {
    return _dependencies;
  }

  function updateDependencies(Dependency[] calldata dependencies_) external onlyDeployer {
    delete _dependencies;
    for (uint index = 0; index < dependencies_.length; index++)
      _dependencies.push(dependencies_[index]);
  }

  function deployer() external view returns (address) {
    return _deployer;
  }

  function initialize(bytes calldata data) external onlyDeployer {
    address[] memory addresses = abi.decode(data, (address[]));
    address router_ = addresses[0];
    address feeSetter_ = addresses[1];

    _router = router_;
    _feeSetter = feeSetter_;
    _tryUpdateRegister(IDENTIFIER, VERSION, address(this));
  }

  function router() external view returns (address) {
    return _router;
  }

  function feeSetter() external view returns (address) {
    return _feeSetter;
  }

  function addressOf(string memory identifier_, uint version_) external view returns (address) {
    return _addressOf(identifier_, version_);
  }

  function deploy(string memory identifier_, uint version_, bytes memory bytecode) external lock {
    address payable deployedAddress;
    bytes32 salt = keccak256(abi.encodePacked("ContractDeployerSalt", SALT, "ContractDeployerVersion", VERSION, "Identifier", identifier_, "Version", version_));
    assembly {
      deployedAddress := create2(0, add(bytecode, 32), mload(bytecode), salt)
    }

    require(identifier_.equals(IVersion(deployedAddress).identifier()), "ContractDeployer: identifier mismatch");
    require(version_ == IVersion(deployedAddress).version(), "ContractDeployer: version mismatch");
    require(_tryUpdateRegister(identifier_, version_, deployedAddress), "ContractDeployer: update register failed");

    _tryInitialize(deployedAddress);
  }

  function update(string memory identifier_, uint version_, Dependency[] calldata dependencies_) external lock {
    address deployedAddress = _addressOf(identifier_, version_);
    require(deployedAddress != address(0), "ContractDeployer: no contract deployed");
    require(_deployerOf(identifier_, version_) == msg.sender, "ContractDeployer: caller is not the deployer");
    IVersion(deployedAddress).updateDependencies(dependencies_);
    require(_tryInitialize(_addressOf(identifier_, version_)), "ContractDeployer: update failed");
  }

  function initialize(string memory identifier_, uint version_) external lock {
    require(_tryInitialize(_addressOf(identifier_, version_)), "ContractDeployer: initialization failed");
  }

  function _addressOf(string memory identifier_, uint version_) private view returns (address) {
    return _register[identifier_].addressByVersion[version_];
  }

  function _deployerOf(string memory identifier_, uint version_) private view returns (address) {
    return _register[identifier_].deployerByVersion[version_];
  }

  function _tryUpdateRegister(string memory identifier_, uint version_, address deployedAddress) private returns (bool) {
    if (_addressOf(identifier_, version_) == address(0)) {
      _register[identifier_].addressByVersion[version_] = deployedAddress;
      _register[identifier_].deployerByVersion[version_] = msg.sender;
      _register[identifier_].addresses.push(deployedAddress);
      _register[identifier_].deployers.push(msg.sender);
      _register[identifier_].versions.push(version_);
      return true;
    }

    return false;
  }

  function _tryInitialize(address deployedAddress) private returns (bool) {
    Dependency[] memory dependencies_ = IVersion(deployedAddress).dependencies();

    address[] memory addresses = new address[](dependencies_.length);
    for (uint index = 0; index < dependencies_.length; index++) {
      addresses[index] = _register[dependencies_[index].identifier].addressByVersion[dependencies_[index].version];
      if (addresses[index] == address(0))
        return false;
    }

    IVersion(deployedAddress).initialize(abi.encode(addresses));
    return true;
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct DeployInfo {
  mapping(uint => address) addressByVersion;
  mapping(uint => address) deployerByVersion;
  address[] addresses;
  address[] deployers;
  uint[] versions;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Dependency {
  string identifier;
  uint version;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

library TransferHelper {
  function safeApprove(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: APPROVE_FAILED");
  }

  function safeTransfer(address token, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FAILED");
  }

  function safeTransferFrom(address token, address from, address to, uint value) internal {
    (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
    require(success && (data.length == 0 || abi.decode(data, (bool))), "TransferHelper: TRANSFER_FROM_FAILED");
  }

  function safeTransferETH(address to, uint value) internal {
    (bool success,) = to.call{value:value}(new bytes(0));
    require(success, "TransferHelper: TRANSFER_ETH_FAILED");
  }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0;

library StringHelper {
  function equals(string memory a, string memory b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "../structs/Dependency.sol";

interface IVersion {
  function identifier() external pure returns (string memory);
  function version() external pure returns (uint);

  function dependencies() external view returns (Dependency[] memory);
  function updateDependencies(Dependency[] calldata dependencies_) external;

  function deployer() external view returns (address);

  function initialize(bytes calldata data) external;
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./IVersion.sol";

interface IContractDeployerV1 is IVersion {
  function router() external view returns (address);
  function feeSetter() external view returns (address);

  function addressOf(string memory identifier_, uint version_) external view returns (address);
  function deploy(string memory identifier_, uint version_, bytes memory bytecode) external;
  function initialize(string memory identifier_, uint version_) external;
}