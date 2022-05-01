//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./_Owner.sol";

contract Homeverse is Ownable {

    address payable _owner;
    uint courseEth;
    uint movieEth;

    constructor() public {
        _owner = payable(msg.sender);
        courseEth = 1400000000000000000;
        movieEth = 36000000000000000;
    }

    function getAccessOfCourse () public payable {
        require(msg.value == courseEth, "Needs 1.4 ether to purchase course");
        _owner.transfer(msg.value);
    }

    function getAccessOfMovie () public payable {
        require(msg.value == movieEth, "Needs 0.0025 ether to purchase movie");
        _owner.transfer(msg.value);
    }

    function setEthOfCourse (uint val) public onlyOwner {
        courseEth = val;
    }
    function setEthOfMovie (uint val) public onlyOwner {
        movieEth = val;
    }
}