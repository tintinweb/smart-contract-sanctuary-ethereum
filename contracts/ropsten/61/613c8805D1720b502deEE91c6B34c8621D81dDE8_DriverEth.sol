// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract DriverEth
{
    ISendEth ethSender;
    address payable recieverContract;

    constructor(address _ethSendContract)
    {
        ethSender = ISendEth(_ethSendContract);
        recieverContract = payable(_ethSendContract);
    }


    function sendETH(address payable _recepient ) public payable returns(bool)
    {
        recieverContract.transfer(msg.value);
        ethSender.sendEther(_recepient);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function receive() external payable;

    function sendEther(address payable _addrs  ) external payable;
}