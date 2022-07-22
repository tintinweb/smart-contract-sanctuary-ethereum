// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.9;

contract ethAccountStorage {

    address manager;

    constructor(){
        manager = msg.sender;
    }
    struct contractDetail{
        address to;
        string remark;
        uint256 amount;
     }
    
    mapping(address => contractDetail) public contractList;

    function ethersend( address payable _to, uint256 amount_ ,string memory remark_ ) external payable {

        contractList[msg.sender] = contractDetail(_to , remark_,amount_ );
        
    } 
    
    function contractdetail(address of_) public  view returns(contractDetail memory){
        return contractList[of_];
    }
    
}