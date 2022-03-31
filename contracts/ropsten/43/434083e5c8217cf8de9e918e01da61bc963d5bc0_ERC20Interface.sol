/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

pragma solidity 0.7.6;
// SPDX-License-Identifier: MIT

contract ERC20Interface {
   }
// ----------------------------------------------------------------------------
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        assert(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; 
    } 
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    
 
}
contract ONELOVE is ERC20Interface, SafeMath {
    
    bytes32 public name= "ONELOVE";
    bytes32 public symbol = "ONE";
    uint8 public decimals = 2; 
    uint256 public _totalSupply = 100000000000;
    
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor() {
    balances[0xCC7aeCE40EE7B74Be4F300260fb9Bd1f59b8F78A] = _totalSupply;
    emit Transfer(address(0), 0xCC7aeCE40EE7B74Be4F300260fb9Bd1f59b8F78A, _totalSupply);
    }
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    function getPrice() public pure returns(uint256) {
     uint256 result = uint256(231481480000000) * 10**18;
     uint256 totalTokens = result / 1 ether;
    //  _totalEther =  totalEther;
     return totalTokens;
     } }