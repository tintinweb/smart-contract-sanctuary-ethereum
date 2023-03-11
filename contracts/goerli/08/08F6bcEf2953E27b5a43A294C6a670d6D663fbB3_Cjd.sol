/**
 *Submitted for verification at Etherscan.io on 2023-03-11
*/

/**
 *Submitted for verification at BscScan.com on 2023-1-14
*/

pragma solidity ^0.4.26; // solhint-disable-line


contract Cjd {
    address  gly;
    uint256 gjq;
    mapping (address => mapping (uint256 => mapping (uint256 =>string)))  kjsj;
    mapping (uint256 => mapping (uint256 => uint256)) qsd;
    mapping (uint256 => bytes[]) cs;
    constructor() public{
        gly = msg.sender;
    }
    
    function kjjg(uint256 qs,uint256 lx,string sj)public{
        require(msg.sender==gly,"Incorrect administrator"); 
        require(qsd[qs][lx]==0,"Incorrect administrator");
        qsd[qs][lx] = qs;
        kjsj[gly][qs][lx]=sj; 
        gjq++;
    }
    /**
    查询抽奖参数 期数-类型(1高倍率2低倍率)得出抽奖结果与排序的高低排列中奖等级
    Query the lottery parameter number of periods - type (1 high magnification and 2 low magnification) to get the lottery results and rank the winning grades
    **/
    function getjg(uint256 qs,uint256 lx) public view returns(string){
         return kjsj[gly][qs][lx];
    }
    function getjq() public view returns(uint256){
       return gjq;
    }
    //修改管理员|
    function xggly(address zg){
        require(msg.sender==gly,"Incorrect administrator"); 
        gly = zg;
    }
    /*function tj(bytes[]  sjd,uint qs) public{
        cs[qs] = sjd;
    }

    function csd(uint256 qs)public view returns(bytes[]){
        return cs[qs];
    }*/


}