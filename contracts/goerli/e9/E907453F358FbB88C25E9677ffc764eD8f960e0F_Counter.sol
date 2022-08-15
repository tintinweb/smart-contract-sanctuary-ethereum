// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

/**
  @title A simple, example contract for incrementing a counter.
  @author Tim Clancy

  We use this contract to test out our centralized chain.
*/
contract Counter {

  /// A version number for this contract's interface.
  uint256 public version = 1;

  /// The current value of the counter.
  uint256 public value;

  /// A mapping of addresses to the last value they incremented to.
  mapping (address => uint256) public increments;

  /// An event to track the counter incrementing.
  event Increment(address incrementer, uint256 oldValue, uint256 newValue);

  /**
    Construct a new Counter with a starting initial value.

    @param _initialValue The initial value of the Counter.
  */
  constructor (uint256 _initialValue) payable {
    value = _initialValue;
  }

  /**
    Returns the last value incremented to by a given address.

    @param _incrementer The address to check.
    @return the last value incremented to by an address.
  */
  function getIncrementFor(address _incrementer) external view returns (uint256) {
    return increments[_incrementer];
  }

  /**
    Allow a user to increment this counter.
  */
  function increment() external {
    uint256 oldValue = value;
    value = value + 1;
    increments[msg.sender] = value;
    emit Increment(msg.sender, oldValue, value);
  }
}