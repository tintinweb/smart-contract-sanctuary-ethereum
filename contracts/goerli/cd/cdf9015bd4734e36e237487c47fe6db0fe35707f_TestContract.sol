/**
 *Submitted for verification at Etherscan.io on 2022-10-24
*/

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.8.0;

contract TestContract {
  event Receive();
  event ReceiveFallback(uint256 amount);
  event ReceiveEthAndDoNothing(uint256 amount);
  event Mint(address to, uint256 amount);
  event TestDynamic(
    string test,
    uint256 test2,
    string test3,
    bool test4,
    uint8 test5,
    string test6,
    string test7
  );
  event DoNothing();
  event DoEvenLess();
  event FnWithSingleParam(uint256);
  event FnWithTwoParams(uint256, uint256);
  event FnWithThreeParams(uint256, uint256, uint256);
  event FnWithTwoMixedParams(bool, string);
  event EmitTheSender(address);
  event DynamicDynamic32(string, bytes2[]);

  event Dynamic(bytes);
  event Dynamic32(bytes8[]);

  error AnError();

  receive() external payable {
    emit Receive();
    emit ReceiveFallback(msg.value);
  }

  function receiveEthAndDoNothing() public payable {
    emit ReceiveEthAndDoNothing(msg.value);
  }

  function mint(address to, uint256 amount) public returns (uint256) {
    emit Mint(to, amount);
    return amount;
  }

  function testDynamic(
    string memory test,
    uint256 test2,
    string memory test3,
    bool test4,
    uint8 test5,
    string memory test6,
    string memory test7
  ) public returns (bool) {
    emit TestDynamic(test, test2, test3, test4, test5, test6, test7);
    return true;
  }

  function doNothing() public {
    emit DoNothing();
  }

  function doEvenLess() public {
    emit DoEvenLess();
  }

  function fnWithSingleParam(uint256 p) public {
    emit FnWithSingleParam(p);
  }

  function fnWithTwoParams(uint256 a, uint256 b) public {
    emit FnWithTwoParams(a, b);
  }

  function fnWithTwoMixedParams(bool a, string calldata s) public {
    emit FnWithTwoMixedParams(a, s);
  }

  function fnWithThreeParams(
    uint256 a,
    uint256 b,
    uint256 c
  ) public {
    emit FnWithThreeParams(a, b, c);
  }

  function fnThatReverts() public pure {
    revert AnError();
  }

  function emitTheSender() public {
    emit EmitTheSender(msg.sender);
  }

  function dynamicDynamic32(string calldata first, bytes2[] calldata second)
    public
  {
    emit DynamicDynamic32(first, second);
  }

  function dynamic(bytes calldata first) public {
    emit Dynamic(first);
  }

  function dynamic32(bytes8[] calldata first) public {
    emit Dynamic32(first);
  }
}