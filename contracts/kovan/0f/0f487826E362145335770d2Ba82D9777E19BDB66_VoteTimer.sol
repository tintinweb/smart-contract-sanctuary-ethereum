// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "prettier-plugin-solidity/tests/format/Ownable/Ownable.sol";

contract VoteTimer is Ownable {
    uint256 public start; //  = 1654646400; // 8 Jun 2022 0:00:00 GMT
    uint256 public timeSpan; // = 2 weeks;
    uint256 public executionWindow; // = 1 days;

    constructor(
        uint256 _start,
        uint256 _timeSpan,
        uint256 _executionWindow
    ) {
        start = _start;
        timeSpan = _timeSpan;
        executionWindow = _executionWindow;
    }

    function changeParams(
        uint256 _start,
        uint256 _timeSpan,
        uint256 _executionWindow
    ) external onlyOwner {
        start = _start;
        timeSpan = _timeSpan;
        executionWindow = _executionWindow;
    }

    function canExecute2WeekVote() public view returns (bool) {
        // ---|------------------------- timeSpan -------------------------|---
        //    |--- executionWindow ---|
        //               true                          false
        return (block.timestamp - start) % timeSpan >= executionWindow;
    }
}

pragma solidity 0.8.11;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address private _owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    _owner = msg.sender;
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(_owner);
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}