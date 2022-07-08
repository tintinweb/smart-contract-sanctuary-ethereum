/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

pragma solidity ^0.8.0;

// 能接受所有人写数据的合约
// 谁写数据他自己能查
// 只有合约创建者开源查看合约
contract test_contract {
    mapping(address => string) internal data;
    address public owner;
    
    constructor(){ //构造函数
        owner= msg.sender;
    }


    modifier onlyOwner(){ //装饰器
        require(msg.sender == owner,"only owner can use this func!"); //警告
        _; // 此处代表先运行装饰器内容,'_'代表再运行之后的代码..如果'_'写在前面则代表先运行代码再跑装饰器内容
    }

    function write_data(string memory write_data_) public {
        data[msg.sender] = write_data_;
    }

    function get_data() public view returns(string memory ){
        return data[msg.sender];
    }

    // 通过装饰器来限制owner 查看
    function get_data_ownerOnly(address addr) public view onlyOwner returns(string memory){
        return data[addr]; 
    }

}