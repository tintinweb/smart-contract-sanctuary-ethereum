/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Cagnotte {
    address private owner;

    uint256 public balance;

    uint256 public deadline;

    constructor(uint256 _deadline) {
        owner = msg.sender;
        deadline = _deadline;
    }

    function expired() view public returns(bool) {
        if(block.timestamp > deadline){
            return true;
        } else {
            return false;
        }
    }

    function contribute() public payable {
        bool is_expired = expired();
        if (!is_expired) {
            balance += msg.value;
        }
        
    }

    function transfer(address payable _to, uint256 _value) public {
        
        require(msg.sender == owner);
        require(_value <= balance);
        bool is_expired = expired();

        if (is_expired){
            balance -= _value;
            _to.transfer(_value);
        }

    }
}