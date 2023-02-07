// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract CommentTest {
  /**
   *
   * @dev doSomething: Set the chainlink number of words.
   * @param something_ - blah
   * @return aThing_ - oh yes
   */
  function doSomething(uint32 something_) pure external returns(bool aThing_) {
    something_ = something_;
    return(true);
  }
}