/**
 *Submitted for verification at Etherscan.io on 2022-07-09
*/

pragma solidity ^0.8.0;


/*
    第四课 1:35:00

    能够接受所有人写数据到这个合约
    谁写的数据他自己能查
    只有合约创建者能查其他人的数据

*/

contract test_contract{
    mapping(address => string) internal data;
    address public owner;

    constructor(){
        owner = msg.sender;
    }
    modifier onlyowner(){
        require(msg.sender == owner,"only owner!!!!!!");
        _;

    }

    //写函数
    function write_data(string memory write_data_) public {
        data[msg.sender] = write_data_;
    }

    //差函数                
    function get_data() public view returns (string memory) {
        return data[msg.sender];
    }

    //只有合约创建者可以用这个函数查询其他人的地址数据
    function get_data_owner(address addr) public view onlyowner returns (string memory){
        return data[addr];
    }
}