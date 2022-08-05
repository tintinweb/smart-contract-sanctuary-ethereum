/**
 *Submitted for verification at Etherscan.io on 2022-08-05
*/

pragma solidity 0.6.4;

contract Proxy {
    mapping(address => bool) whitelist;

    function send(address recipient) external payable  {
        (bool sent, bytes memory data) = recipient.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
    }
}