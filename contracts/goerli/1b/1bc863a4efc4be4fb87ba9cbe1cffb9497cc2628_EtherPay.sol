/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface Ether {
    function resolveAddress(string calldata ether_name) external view returns (address);
}

contract EtherPay {
    address ether_contract=0xDC7dBb61E31D7a79376063791183A6488E16C9ce;
    address transfer_address;
    string ether_name;
    uint cost;
function Payment(string memory _ether_name) public payable
    {   
    payable(Ether(ether_contract).resolveAddress(_ether_name)).transfer(msg.value);
    }
}