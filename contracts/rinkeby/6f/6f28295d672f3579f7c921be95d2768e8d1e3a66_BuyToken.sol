/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

pragma solidity ^0.5.1;

contract BuyToken {
    mapping(address => uint256) public balanceOf;
    address payable wallet_address;
    event Purchase(
        address indexed _buyer,
        uint256 _amount
    );

    constructor(address payable _walletadd) public{
        wallet_address = _walletadd;
    }

    function tokenBuy(uint256 _numberOfTokens) public payable {
        balanceOf[msg.sender] += _numberOfTokens;
        wallet_address.transfer(msg.value);
        emit Purchase(msg.sender, _numberOfTokens);
    }
}