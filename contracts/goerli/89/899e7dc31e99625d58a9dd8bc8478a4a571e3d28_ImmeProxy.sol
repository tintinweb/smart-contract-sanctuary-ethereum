/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IERC20 {
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ImmeProxy {

    address owner;
    address payable taxWallet;

    event ImmeProxySend(address indexed from, address indexed to, uint256 value);

    constructor(address payable _taxWallet) {
        owner = msg.sender;
        taxWallet = _taxWallet;
    }

    function secureSendEther(address payable _to, uint256 _amount, uint256 _fee) external payable {

        (bool success,) = _to.call{value: _amount}("");
        if (success) {
            (bool successFee,) = taxWallet.call{value: _fee}("");
            require(successFee, "Failed to send Ether");
        }
        require(success, "Failed to send Ether");
        emit ImmeProxySend(msg.sender, _to, _amount);
    }

    function secureSendToken(address tokenAddress, address payable _to, uint256 _value) external payable{
        
        (bool successFee,) = taxWallet.call{value: msg.value}("");
        require(successFee, "Failed to send Ether");

        IERC20 token = IERC20(tokenAddress);
        require(token.balanceOf(msg.sender) >= _value, "Address: insufficient token balance for call");
        require(token.transferFrom(msg.sender, address(this), _value));
        require(token.transfer(_to, _value));
    }
}