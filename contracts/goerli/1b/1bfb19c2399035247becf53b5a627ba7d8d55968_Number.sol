/**
 *Submitted for verification at Etherscan.io on 2022-07-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract Number {
    uint256 public number;

    //构建函数 合约部署时执行一次 传入初始num值
    constructor(uint256 initNum){
        number = initNum;
    }

    
    function add(uint256 x) public {
        require(x>0,"add value must be positive");
        number = number + x;
    }

    function minus(uint256 x) public {
        require(x>0,"minus value must be positive");
        number = number - x;
    }

    function set(uint256 x) public{
        number = x;
    }

    function get() public view returns(uint256){
        return number;
    }
}