// SPDX-License-Identifier: BSD-3
pragma solidity ^0.8.9;

contract EventTest{
  error YouSuck();
  error YouSuckToo(string);
  event YouSuckMore();

  function testError() external {
    emit YouSuckMore();
    revert YouSuck();
  }

  function testEvent1() external {
    testRevert(bytes.concat(YouSuck.selector));
  }

  function testEvent2(string memory insult) external pure {
    revert YouSuckToo( insult );
  }

  function testRevert(bytes memory err) public {
    emit YouSuckMore();
    revert( string(err) );
  }
}