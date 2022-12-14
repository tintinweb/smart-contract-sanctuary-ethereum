// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

import "./interface/IController.sol";

contract Controller is IController {

  address public governance;
  address public pendingGovernance;

  address public veDist;
  address public voter;

  event SetGovernance(address value);
  event SetVeDist(address value);
  event SetVoter(address value);

  constructor() {
    governance = msg.sender;
  }

  modifier onlyGov() {
    require(msg.sender == governance, "Not gov");
    _;
  }

  function setGovernance(address _value) external onlyGov {
    pendingGovernance = _value;
    emit SetGovernance(_value);
  }

  function acceptGovernance() external {
    require(msg.sender == pendingGovernance, "Not pending gov");
    governance = pendingGovernance;
  }

  function setVeDist(address _value) external onlyGov {
    veDist = _value;
    emit SetVeDist(_value);
  }

  function setVoter(address _value) external onlyGov {
    voter = _value;
    emit SetVoter(_value);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;

interface IController {

  function veDist() external view returns (address);

  function voter() external view returns (address);

}