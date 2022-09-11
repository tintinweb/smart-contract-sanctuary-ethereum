/**
 *Submitted for verification at Etherscan.io on 2022-09-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract OwnerReward {



struct Product{
    uint256 price;
    bool enabled;
}

struct Person{
    address senderAddress;
    uint256 amount;
    address recipentAddress;
}

struct NFT {
    uint256 chainId;
    address tokenAddress;
    uint256 tokenId;
}

struct NFTCollection {
    uint256 chainId;
    address tokenAddress;
    address owner;
}

    mapping (address => Person[]) funders;
    address payable public _ownerReward;
    uint _balance;

    //event ReceiveOwnerAward(address sender, uint amount, uint balance);
    event Received(address, uint);
    event WithDrawFromOwnerAward(uint amount, uint balance);
    event TransferFromOwnerReward(address recipent, uint amount, uint balance);

    constructor(){
        _ownerReward = payable(tx.origin);
        _balance = 0;
    }

    receive() payable external{
        _balance += msg.value;
        emit Received(msg.sender, msg.value);
    }

    function getBalance() public view returns (uint256){
        return _balance;
    }

    modifier onlyOwner(){
        require(msg.sender == _ownerReward, "Only Owner can withdraw");
        _;
    }

    function withDrawFromOwnerAward(uint _amount) public onlyOwner{
        _ownerReward.transfer(_amount);
        emit WithDrawFromOwnerAward(_amount, _ownerReward.balance);
    }

    function transferFromOwnerReward(address payable _recipent, uint _amount) public onlyOwner{
        _recipent.transfer(_amount);
        emit TransferFromOwnerReward(_recipent, _amount, _ownerReward.balance);
    }

}