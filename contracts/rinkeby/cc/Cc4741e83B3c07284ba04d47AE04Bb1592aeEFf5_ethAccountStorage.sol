// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

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

    function ethersend(address from_ , address  _to,uint256 amount_ ,string memory remark_ ) external {

        contractList[from_] = contractDetail(_to , remark_,amount_ );
    } 
    
    function contractdetail(address of_) public  view returns(contractDetail memory){
        return contractList[of_];
    }
    
}