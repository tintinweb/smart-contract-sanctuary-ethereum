// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Auction {
    uint256 public time;
    address payable public owner;
    mapping(address => uint256) public fundersListAmount;
    address[] public fundersList;
    address payable public highestFunder;

    constructor() {
        owner = payable(msg.sender);
    }

    function start() public {
        time = uint32(block.timestamp + 80);
    }

    function pay(uint256 _amount) public payable {
        require(block.timestamp < time, "TIME UP!!");
        payable(address(this)).transfer(_amount);
        fundersListAmount[msg.sender] = _amount;
        fundersList.push(msg.sender);
    }

    function withdraw() public {
        highestFunder.transfer(address(this).balance);
    }

    function HighestBidder() public {
        uint256 max = 0;
        for (uint256 Index; Index < fundersList.length; Index++) {
            if (fundersListAmount[fundersList[Index]] > max) {
                max = fundersListAmount[fundersList[Index]];
                highestFunder = payable(fundersList[Index]);
            }
        }
    }
}