/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

pragma solidity ^0.8.0;

contract Shoutout {
    
    event Shout(address author, string message);

    function shoutout(string memory _message)
        external
    {
        emit Shout(msg.sender, _message);
    }
}