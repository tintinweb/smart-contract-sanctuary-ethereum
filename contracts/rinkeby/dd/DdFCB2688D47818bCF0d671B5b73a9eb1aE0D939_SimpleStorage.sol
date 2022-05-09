/**
 *Submitted for verification at Etherscan.io on 2022-05-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Store a single data point and allow fetching/updating of that datapoint
contract SimpleStorage {
    
    // data point
    string storedData;
    address payable owner;

    event myEventTest(string eventOutput);

    constructor() payable  {
        owner = payable(msg.sender);
    }
    
    function set(string memory myText) public {
        storedData = myText;
        emit myEventTest(myText);
    }
    
    function get() public view returns (string memory) {
        return storedData;
    }

    function deposit() public payable {}
    
    function withdraw() public  {
        uint amount = address(this).balance;

        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function get_balance() public view returns(uint balance){
        return address(this).balance;
    }

    function transfer(address payable _to, uint _amount) public {
        // Note that "to" is declared as payable
        (bool success, ) = _to.call{value: _amount}("");
        require(success, "Failed to send Ether");
    }
    
}