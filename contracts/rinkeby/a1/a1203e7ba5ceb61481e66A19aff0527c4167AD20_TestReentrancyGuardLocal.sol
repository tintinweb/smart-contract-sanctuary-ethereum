pragma solidity 0.5.15;

import "./ReentrancyGuard.sol";

contract TestReentrancyGuardLocal is ReentrancyGuard {
  string message = "0x9AE4593c09ec384FC7B8519903be8A94801cBfe6";

  function foo() public nonReentrant returns(uint) {
    return 1;
  }
}

pragma solidity 0.5.15;

contract ReentrancyGuard {
    uint256 public guardCounter;

    constructor() internal {
        guardCounter = 1;
    }

    modifier nonReentrant() {
        guardCounter += 1;
        uint256 localCounter = guardCounter;
        _;
        require(localCounter == guardCounter, "re-entered");
    }
}