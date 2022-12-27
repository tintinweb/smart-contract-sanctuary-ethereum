/**
 *Submitted for verification at Etherscan.io on 2022-12-27
*/

pragma solidity 0.8.14;

//SPDX-License-Identifier: UNLICENSED

contract myEth{
    
    address private minter;
    mapping (address=>uint) Balance;

    constructor() {
        minter = msg.sender;
    }

    modifier onlyMinter() {
        require(msg.sender == minter);
        _;
    }

    modifier checkBal(uint _amount){
        require(Balance[msg.sender] >= _amount);
        _;
    }   

    function mint(uint _amount) external onlyMinter(){
        Balance[minter] += _amount;
    }

    function transfer(address _reciever,uint _amount) external checkBal(_amount){
        Balance[_reciever] += _amount;
        Balance[msg.sender] -= _amount;
    }

    function balance(address addr) external view returns(uint) {   
        return Balance[addr];
    }
}