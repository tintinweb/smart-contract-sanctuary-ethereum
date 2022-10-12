// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import {TestPack} from "./TestPack.sol";

contract TestFactory {
  event TestPackCreated(address indexed childAddress, address indexed parentAddress, string indexed params);

  TestPack public testPack;

  function createTestPack(string[] memory params) public returns (TestPack) {
    testPack = new TestPack(params[0], params[1], params[2]); // creating new contract inside another parent contract
    emit TestPackCreated(address(testPack), msg.sender, params[1]);

    return testPack;
  }

  function getTestPack() external view returns (TestPack) {
    return testPack;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract TestPack {
  string private s_name;
  string private s_description;
  string private s_randomAttribute;

  constructor(
    string memory _description,
    string memory _name,
    string memory _randomAttribute
  ) {
    s_description = _description; //params[0];
    s_name = _name; //params[1];
    s_randomAttribute = _randomAttribute; //Math.round(Math.random() * 65535);
  }

  function name() public view returns (string memory) {
    return s_name;
  }

  function getDescription() public view returns (string memory) {
    return s_description;
  }

  function randomAttribute() public view returns (string memory) {
    return s_randomAttribute;
  }
}