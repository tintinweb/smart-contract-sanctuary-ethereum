/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IToken {
  function mint(address to, uint amount) external;
  function burn(uint amount) external;
}

contract LimeBridge {
  address public owner;
  IToken public token;
  uint public nonce;
  bool public status;
  mapping(uint => bool) public processedNonces;

  enum Step { Burn, Mint }
  event Transfer(
    address from,
    uint amount,
    uint date,
    uint nonce,
    Step indexed step
  );

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner');
    _;
  }

  modifier notPaused() {
    require(status == true, 'Sorry, bridge is not working now');
    _;
  }

  constructor(address _token) {
    owner = msg.sender;
    token = IToken(_token);
    status = true;
  }

  function burn(uint amount) external notPaused {
    token.burn(amount);
    emit Transfer(
      msg.sender,
      amount,
      block.timestamp,
      nonce,
      Step.Burn
    );
    nonce++;
  }

  function mint(address to, uint amount, uint otherChainNonce) external onlyOwner notPaused {
    require(processedNonces[otherChainNonce] == false, 'This transfer already processed');
    processedNonces[otherChainNonce] = true;
    token.mint(to, amount);
    emit Transfer(
      msg.sender,
      amount,
      block.timestamp,
      otherChainNonce,
      Step.Mint
    );
  }

  function pause(bool _status) external onlyOwner {
    status = _status;
  }
}