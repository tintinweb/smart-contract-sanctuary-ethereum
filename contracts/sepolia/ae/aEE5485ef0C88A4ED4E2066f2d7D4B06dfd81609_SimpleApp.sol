//SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.8.9 < 0.9.0;

contract SimpleApp {
  string private message = 'The app seems to be working';

  /**
    'view' means that the function does not modify anything
    in the blockchain. All it does is to view data on the
    blockchain.
   */
  function getMessage() public view returns(string memory) {
    return message;
  }

  /**
    Setter Function: Sets the value of the local variable

    Will require Gas fee for it's execution
   */
  function setMessage(string memory _message) public returns(bool) {
    message = _message;
    return true;
  }
}