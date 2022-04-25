// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import './AbstractFeatureProjectInfo.sol';
contract FeatureProjectInfo is AbstractFeatureProjectInfo {
  function initialize(address _factory) external  {
    require(factory == address(0), 'F:init');
    factory = _factory;
  }

  function getAllProjects() external view returns (Projects[] memory) {
    return projects;
  }

  // it must be id - 1
  function getProjectsByIndex(uint _index) external view returns (Projects memory) {
    return projects[_index];
  }

  function addProject(
    uint _projId,
    address _project,
    address _judger,
    uint _lockTime,
    uint _feeRate,
    uint _createBlockNumber,

    Info calldata _projInfo,
    Judger calldata _judgerInfo
  ) external {
    require(msg.sender == factory, 'F:factory');
    Projects memory proj = Projects({
      projId: _projId,
      project: _project,
      judger: _judger,

      lockTime: _lockTime,

      feeRate: _feeRate,
      createBlockNumber: _createBlockNumber,

      projInfo: _projInfo,
      judgerInfo: _judgerInfo
    });

    projects.push(proj);

    emit ProjectCreated(proj);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

abstract contract AbstractFeatureProjectInfo {
  struct Judger {
    string name;
    string description;
    string twitter;
  }

  struct Info {
    string name;
    string logoUri;
    string description;
    string moreInfo;
  }

  struct Projects {
    uint projId;
    address project;
    address judger;

    uint lockTime;

    uint feeRate;
    uint createBlockNumber;

    Info projInfo;
    Judger judgerInfo;
  }

  event ProjectCreated(Projects);

  Projects[] public projects;
  address factory;
}