/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// File: contracts/test4.sol


pragma solidity ^0.8.0;

contract C {
  uint256 a; //值类型
  function setA(uint256 _a) public {
    a = _a;
  }
  function getA() public view returns(uint256) {
    return a;
  }

    uint[] b;//数组 引用类型

     function setB(uint256[] memory _b) public {
    b = _b;
  }
  function getB() public view returns(uint256[] memory) {
    return b;
  }

    bool c;//布尔型 值类型
    function setC(bool  _c) public {
     c = _c;
  }
  function getC() public view returns(bool ) {
    return c;
  }

    struct Proposal {//结构体 引用类型
        string name10 ;   
        uint voteCount; 
    }
    Proposal pro;
    function initProposal() external{//自动赋值
        pro.name10 = "lkw";
        pro.voteCount = 80;
    }

    function initProposal2(string memory name, uint count) external{//自动赋值
        pro.name10 = name;
        pro.voteCount = count;
    }

    function getProposal() public view returns(Proposal memory){
        return pro;
    }
    address add;//地址类型 值类型 20字节 要写全 他不会自己补充 0x0000000000000000000000000000000000000015

    function setAdd(address  _c) public {
     add = _c;
  }
  function getAdd() public view returns(address ) {
    return add;
  }

    bytes1 b57;//定长数组 数组的 长度是1
    bytes2  b58;// 数组的长度是2
    function setByte(bytes1  _c) public {
     b57 = _c;
    }

    function getByte() public view returns (bytes1 ,uint){
           uint length= b57.length;
        return (b57,length);
    }

    function setByte2(bytes2  _c) public {
     b58 = _c;
    }

    function getByte2() public view returns (bytes2 ,uint){
           uint length= b58.length;
        return (b58,length);
    }

    mapping(uint => address) public idToAddress; // id映射到地址


    function writeMap (uint _Key, address _Value) public{
        idToAddress[_Key] = _Value;
    }
}