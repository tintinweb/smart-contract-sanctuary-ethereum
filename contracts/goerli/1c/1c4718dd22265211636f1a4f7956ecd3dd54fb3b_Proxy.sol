/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

pragma solidity 0.6.4;

contract Proxy {
    function send(address recipient) external payable  {
        (bool sent, bytes memory data) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}