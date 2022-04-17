/**
 *Submitted for verification at Etherscan.io on 2022-04-17
*/

pragma solidity ^0.8.10;
// SPDX-License-Identifier: MIT

contract lotto {

    struct Stake {
        address bidder;
        uint256 bid;
        uint256 guess;
    }

    Stake[] public stakes;

    function getContractBalance() public view returns (uint256) { //view amount of ETH the contract contains
    return address(this).balance;
    }
    function deposit(uint256 _guess) payable public {
       stakes.push(Stake(msg.sender, msg.value, _guess));

    }
    function getarrayfortest(uint _index) public view returns (address bidder, uint256 bid, uint256 guess) {
    Stake storage test = stakes[_index];
    return (test.bidder, test.bid, test.guess);
    }
        

    function settle(address to) public {
        address payable receiver = payable(to);
        receiver.transfer(address(this).balance);
        delete stakes;

    }
}