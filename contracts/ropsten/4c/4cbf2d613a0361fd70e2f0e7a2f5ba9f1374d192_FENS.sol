/**
 *Submitted for verification at Etherscan.io on 2022-09-24
*/

// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20
pragma solidity ^0.4.2;

contract Token {

    uint256 public totalSupply;  // 供给总量
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath { // 安全计算函数
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    //assert(c>=a && c>=b);
    return c;
  }
}
// 省略

contract FENS {//is StandardToken { 

    function () public {
      //  revert();
    }

    using SafeMath for uint256;
    string public name = "fens.me Token";  
    uint8 public decimals = 18;
    string public symbol = "FENS";
}
// 省略