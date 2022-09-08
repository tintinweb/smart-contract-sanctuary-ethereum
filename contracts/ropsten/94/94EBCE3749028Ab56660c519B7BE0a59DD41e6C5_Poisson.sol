/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

interface Data{
    function getData1() external view returns(string memory);
    function getData2() external view returns(string memory);
    function getData3() external view returns(string memory);
}

//逻辑验证合约
contract Poisson {

    address private owner;
    mapping(address => bool) private admin;
    address private dataAddress;
    string private data1;
    string private data2;
    string private data3;

    //构造函数
    constructor (){
        owner = msg.sender;
    }

    //修饰函数实现会员权限
    modifier onlyAdmin() {
        require(admin[msg.sender], "not admin");
        _;
    }

    //修饰函数实现合约拥有者权限
    modifier onlyOwner() {
        require(owner == msg.sender, "not owner");
        _;
    }

    //比较字符串是否一致
    function compareString(string memory a, string memory b) private pure returns (bool){
        if(bytes(a).length != bytes(b).length){
            return false;
        }else{
            return  keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
        }
    }

    //设置数据合约地址
    function setDataAddress(address _dataAddress) onlyOwner external{
        dataAddress = _dataAddress;
    }

    //初始化获取数据
    function initData()onlyOwner external{
        require(dataAddress != address(0),"set dataAddress first");
        data1 = Data(dataAddress).getData1();
        data2 = Data(dataAddress).getData2();
        data3 = Data(dataAddress).getData3();
    }

    //设置权限函数
    function setAdmin(address account, bool enable) private{
        admin[account] = enable;
    }

    //公共view函数实现所有用户可访问
    function viewData1() public view returns(string memory){    
        return data1;
    }

    //验证数据函数
    function verifyData(string memory _verifydata) external returns(string memory,string memory) {
        require(compareString(data2, _verifydata), "wrong answer");//require方法来判断数据是否一致
        setAdmin(msg.sender,true);//授访问权限给用户
        return (data2,data3);
    }

    //只允许数据验证通过的用户访问
    function viewData2() onlyAdmin external view returns(string memory){
        return data2;
    }

    //只允许数据验证通过的用户访问
    function viewData3() onlyAdmin external view returns(string memory){
        return data3;
    }


}