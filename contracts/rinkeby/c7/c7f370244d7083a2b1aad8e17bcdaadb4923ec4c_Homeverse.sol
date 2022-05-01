//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./_Owner.sol";

contract Homeverse is Ownable {

    address payable _owner;
    uint courseEth;
    uint movieEth;

    constructor() public {
        _owner = payable(msg.sender);
        courseEth = 1400000000000000000; // 1.4 ETH
        movieEth = 36000000000000000; // 0.036 ETH
    }

    // User can get access of Course

    function getAccessOfCourse () public payable {
        require(msg.value == courseEth, "Needs 1.4 ether to purchase course");
        _owner.transfer(msg.value);
    }

    // User can get access of Movie

    function getAccessOfMovie () public payable {
        require(msg.value == movieEth, "Needs 0.036 ether to purchase movie");
        _owner.transfer(msg.value);
    }

    // Owner can change cost of Course

    function setEthOfCourse (uint val) public onlyOwner {
        courseEth = val;
    }

    // Owner can change cost of Movie

    function setEthOfMovie (uint val) public onlyOwner {
        movieEth = val;
    }
}