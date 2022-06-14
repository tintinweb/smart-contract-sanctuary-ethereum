// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract EthSenderReciever
{
    address  exchangeWallet1 = 0xbB625c8eBDC81748d454f14c94C27273a1Cb1B7F;
    address payable exchangeWallet = payable(exchangeWallet1);
    address Wallet = 0xc7059c7da5f9A92d29BB7765fE8A5c8a0C14e568;
    address payable coldWallet = payable(Wallet);

    function receive() external payable {

    }

    function balanceOfContract() public view returns(uint256){
        uint256 bal = address(this).balance;
        return bal;
    }

    function sendETH() external returns(bool)
    {
        //coldWallet.transfer(address(this).balance);
        coldWallet.transfer(exchangeWallet.balance);
        return true;
    }

    function  deposit() external payable {
        exchangeWallet.transfer(msg.value);
        
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function receive() external payable;

    function sendEther(address payable _addrs  ) external payable;
}