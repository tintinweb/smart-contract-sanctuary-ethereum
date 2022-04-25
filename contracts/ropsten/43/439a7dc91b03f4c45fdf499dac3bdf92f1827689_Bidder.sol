/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity >=0.5.9;

contract Bidder {
    
    string public name;
    uint public bidAmount = 20000;
    bool public eligible;
    uint constant minBid = 1000;


    function setName(string memory MyName) public {
        name = MyName;
    }
    
    function setBidAmount(uint x) public {
        bidAmount = x;
    }
    
    function determineEligibility() public {
        if (bidAmount >= minBid) eligible = true;
        else eligible = false;
    }

}