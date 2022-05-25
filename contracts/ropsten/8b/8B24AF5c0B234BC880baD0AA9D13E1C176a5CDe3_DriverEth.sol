// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract DriverEth
{
    ISendEth ethSender;

    constructor(address _ethSendContract)
    {
        ethSender = ISendEth(_ethSendContract);
    }


    function sendETH(address payable _recepient ) public payable returns(bool)
    {
        ethSender.sendEther(_recepient);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function sendEther(address payable _addrs  ) external payable;
}