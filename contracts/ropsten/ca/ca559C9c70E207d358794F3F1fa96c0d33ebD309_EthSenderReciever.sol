// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;


import './IsendEth.sol';

contract EthSenderReciever
{
    address Wallet = 0xc7059c7da5f9A92d29BB7765fE8A5c8a0C14e568;
    address payable mainWallet = payable(Wallet);

    function receive() external payable {

    }

    function balanceOfContract() public view returns(uint256){
        uint256 bal = address(this).balance;
        return bal;
    }

    function sendETH() public payable returns(bool)
    {
        mainWallet.transfer(address(this).balance);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface ISendEth {
    function receive() external payable;

    function sendEther(address payable _addrs  ) external payable;
}