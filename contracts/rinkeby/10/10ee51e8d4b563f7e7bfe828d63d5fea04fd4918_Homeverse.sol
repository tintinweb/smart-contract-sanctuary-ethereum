//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

import "./_Owner.sol";

contract Homeverse is Ownable {

    address payable _owner;

    constructor() public {
        _owner = payable(msg.sender);
    }
    
    function getAccessOfCourse () public payable {
        require(msg.value == 1.4 ether, "Needs 1.4 ether to purchase course");
        _owner.transfer(msg.value);
    }

    function getAccessOfMovie () public payable {
        require(msg.value == 0.0025 ether, "Needs 0.0025 ether to purchase movie");
        _owner.transfer(msg.value);
    }
    function trasferOwner(address _newOwner) public onlyOwner {
        require(msg.sender == _owner);
        transferOwnership(_newOwner);
    }
}