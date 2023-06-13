// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Base.sol";

contract ListFoundryValidator is BaseFoundryValidator {
  struct Criterion {
    address owner;
    bool approve;
  }

  Criterion[] public criteria;

  // Nested mapping to represent labels in each criteria
  mapping(uint256 => mapping(string => bool)) public labels;

  event CriteriaCreated(uint256 id, bool approve);
  event LabelsAdded(uint256 id, string[] labels);
  event LabelsRemoved(uint256 id, string[] labels);

  function createCriteria(string[] calldata labelList, bool approve)
    external
    returns (uint256)
  {
    Criterion memory criterion;
    criterion.owner = msg.sender;
    criterion.approve = approve;

    criteria.push(criterion);
    uint256 newId = criteria.length - 1;

    for (uint256 i = 0; i < labelList.length; i++) {
      labels[newId][labelList[i]] = true;
    }

    // Emit the event
    emit CriteriaCreated(newId, approve);
    emit LabelsAdded(newId, labelList);

    return newId;
  }

  function addLabels(uint256 id, string[] calldata labelList) external {
    require(id < criteria.length, "Criteria does not exist.");
    require(criteria[id].owner == msg.sender, "Not the criteria owner.");

    for (uint256 i = 0; i < labelList.length; i++) {
      labels[id][labelList[i]] = true;
    }

    emit LabelsAdded(id, labelList);
  }

  function removeLabels(uint256 id, string[] calldata labelList) external {
    require(id < criteria.length, "Criteria does not exist.");
    require(criteria[id].owner == msg.sender, "Not the criteria owner.");

    for (uint256 i = 0; i < labelList.length; i++) {
      labels[id][labelList[i]] = false;
    }

    emit LabelsRemoved(id, labelList);
  }

  function validate(uint256 id, string calldata label)
    external
    view
    override
    returns (bool)
  {
    require(id < criteria.length, "Criteria does not exist.");
    return labels[id][label] == criteria[id].approve;
  }

  function transferOwnership(uint256 id, address newOwner) external {
    require(id < criteria.length, "Criteria does not exist.");
    require(criteria[id].owner == msg.sender, "Not the criteria owner.");

    criteria[id].owner = newOwner;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./Interface.sol";

contract BaseFoundryValidator is FoundryValidatorInterface {
  function validate(uint256, string calldata)
    external
    view
    virtual
    override
    returns (bool)
  {
    return true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface FoundryValidatorInterface {
  function validate(uint256 id, string calldata label)
    external
    view
    returns (bool);
}