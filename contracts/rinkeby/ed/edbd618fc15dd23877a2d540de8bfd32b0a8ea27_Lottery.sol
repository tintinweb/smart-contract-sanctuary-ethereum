/**
 *Submitted for verification at Etherscan.io on 2022-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

contract Lottery {
    uint public bidPrice;

    uint public fee;

    address payable public master;

    mapping(uint8 => address) public bids;
    uint8[] public bidList;

    constructor(uint bp, uint f, address payable m) {
        bidPrice = bp;
        fee = f;
        master = m;
    }

    function bid(uint8 number) external payable {
        require(msg.value == bidPrice, "");
        require(bids[number] == address(0));
        require(0 <= number && number < 5);
        bids[number] = msg.sender;
        bidList.push(number);

        if (bidList.length == 5) {
            uint8 winnerIndex = 4;
            address winner = bids[winnerIndex];
            payable(winner).transfer(bidPrice * 5 - fee);

            for (uint8 i=0; i < 5; i++) {
                bids[i] = address(0);
            }
            delete bidList;
        }
    }
}