/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract WishOfDay{

    // state variables
    struct Wish{
        uint date;
        string message;
    }
    mapping(address => Wish) public wishFeed;
    address last;
  

    function getOneWish(address _from) public view returns (Wish memory) {
        require(wishFeed[_from].date != 0, "No whish of the day from this address yet");
        return (wishFeed[_from]);
    }

    function getLastWish() public view returns (Wish memory) {
        require(last != address(0), "No wish of the day written yet");
        return (wishFeed[last]);
    }


    function setWish(string memory _message) public {
        wishFeed[msg.sender] = Wish(block.timestamp, _message);
        last = msg.sender;
    }

}