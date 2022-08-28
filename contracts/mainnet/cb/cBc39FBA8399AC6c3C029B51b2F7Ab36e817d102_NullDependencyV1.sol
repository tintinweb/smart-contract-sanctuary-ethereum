// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

import "./interfaces/IVersion.sol";

contract NullDependencyV1 is IVersion {
  string constant private IDENTIFIER = "NullDependency";
  uint constant private VERSION = 1;

  address private immutable _deployer;
  Dependency[] _dependencies;

  constructor() {
    _deployer = msg.sender;
  }

  modifier onlyDeployer() {
    require(msg.sender == _deployer, "NullDependency: caller must be the deployer");
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

  function initialize(bytes calldata data) external onlyDeployer {}
}

// SPDX-License-Identifier: CC-BY-NC-4.0
// Copyright (Ⓒ) 2022 Deathwing (https://github.com/Deathwing). All rights reserved
pragma solidity 0.8.16;

struct Dependency {
  string identifier;
  uint version;
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