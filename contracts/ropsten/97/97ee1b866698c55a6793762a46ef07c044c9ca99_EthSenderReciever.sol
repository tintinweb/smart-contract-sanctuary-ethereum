/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


// import './IsendEth.sol';
// import "hardhat/console.sol";


contract EthSenderReciever
{

    function transferEth(address payable _recpient) external payable{
        _recpient.transfer(msg.value);
    }

}