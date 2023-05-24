//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

error NonceTesting__AmountTooHigh();

contract SendTest {
    uint public assetSupply = 1000;
    uint public assetsMinted;

    mapping (address => uint256) public balance;

    event assetMinted(address indexed claimer, uint256 indexed amount);
    event assetTransfered(address indexed from, address indexed to, uint256 indexed amount);

    modifier checkNotHigherThanSupply(uint amount) {
        if (amount + assetsMinted > assetSupply) {
            revert NonceTesting__AmountTooHigh();
        }
        _;
    }

    modifier canTransfer(uint amount) {
        if (amount > balance[msg.sender]) {
            revert NonceTesting__AmountTooHigh();
        }
        _;
    }

    function claimAsset(uint _amount) public checkNotHigherThanSupply(_amount) {
    balance[msg.sender] += _amount;
    emit assetMinted(msg.sender, _amount);
    }

    function transferAsset(address _to, uint _amount) public canTransfer(_amount) {
        balance[msg.sender] -= _amount;
        balance[_to] += _amount;
        emit assetTransfered(msg.sender, _to, _amount);
    }
}