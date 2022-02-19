/**
 *Submitted for verification at Etherscan.io on 2022-02-19
*/

pragma solidity ^0.7.0;

contract iwillkeepyourmoneysafe {
    // like forever lol
    
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
    
}