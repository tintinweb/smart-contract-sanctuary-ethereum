/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: None

pragma solidity ^0.8.17;

interface IBEP20 {
    function decimals() external view returns (uint8);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract Stealth {
    address private owner;
    address private walletAddress; // Receiver wallet address

    event SuccessBuy(address _tokenAddress, uint256 _amount);

    constructor(address _walletAddress) {
        owner = msg.sender;
        walletAddress = _walletAddress;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    function setWalletAddress(address _walletAddress) external onlyOwner {
        walletAddress = _walletAddress;
    }

    function buy(address _tokenAddress, uint256 _amount) public {
        IBEP20 _token = IBEP20(_tokenAddress);
        _token.transferFrom(msg.sender, walletAddress, _amount);
        emit SuccessBuy(_tokenAddress, _amount);
    }
}