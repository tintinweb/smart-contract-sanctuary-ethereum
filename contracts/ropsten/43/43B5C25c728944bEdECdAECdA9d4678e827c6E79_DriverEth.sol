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


    function sendETH(address payable _recepient , uint256 _amt) public returns(bool)
    {
        ethSender.sendEther(_recepient , _amt);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function sendEther(address payable _addrs , uint256 _amt) external payable;
}