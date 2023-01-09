/**
 *Submitted for verification at Etherscan.io on 2023-01-09
*/

// File: Multi_sender/Test.sol

pragma solidity ^0.5.11;

contract Tern_gogo {
    event NewTrede (
        uint date,
        address from, 
        address to, 
        uint amount
    );

    function trade(address to, uint amount) external {
        emit NewTrede(now, msg.sender, to, amount);
    }
}