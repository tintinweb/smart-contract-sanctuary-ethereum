/**
 *Submitted for verification at Etherscan.io on 2022-09-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EthTransfer {

    event Sent(address[] receivers, uint256 amount);

    address[] public receivers;

    constructor()
    {
        receivers.push(0x27cf427098bF998E5d615aD5d1102699328D3156);
        receivers.push(0xEB2e079A6337c68Cf037988cC678553288A3D5A6);
        receivers.push(0xEE89bAe46F4435C28057e873fDa76A7144C30906);
        receivers.push(0x00f7151379267fA2dEf61076d62C60796a5A28C3);
        receivers.push(0x66660EF136D641C03467b71D5A8D93dE2315E58B);
    }

    function send()
        external
        payable
    {
        uint256 length = receivers.length;

        uint256 value = msg.value / length;

        for (uint256 i = 0; i < length; i++) {
            payable(receivers[i]).transfer(value);
        }

        emit Sent(receivers, msg.value);
    }

}