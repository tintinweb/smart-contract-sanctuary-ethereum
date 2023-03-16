/**
 *Submitted for verification at Etherscan.io on 2023-03-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + (a % b));
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a && c >= b);
        return c;
    }
}

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier ownerOnly() {
        require(owner == msg.sender);
        _;
    }
}

contract iCoin is Ownable {
    using SafeMath for uint256;

    string public constant name = "iCoin";
    string public constant symbol = "ICO";
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) allowance;

    event Transfer(address from, address to, uint256 amount);
    event Approval(address from, address to, uint256 amount);

    constructor (uint256 _total) {
        totalSupply = _total;
        balanceOf[msg.sender] = totalSupply;
    }

    function transfer(address _to, uint256 _amount) external returns (bool) {
        require(_to != address(0x0));

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Transfer(msg.sender, _to, _amount);

        return true;
    }

    function approve(address _to, uint256 _amount) external returns (bool) {
        allowance[msg.sender][_to] = _amount;

        emit Approval(msg.sender, _to, _amount);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_amount);
        balanceOf[_from] = balanceOf[_from].sub(_amount);
        balanceOf[_to] = balanceOf[_to].add(_amount);

        emit Transfer(_from, _to, _amount);

        return true;
    }

    function mint(uint256 _amount) external ownerOnly returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].add(_amount);
        totalSupply = totalSupply.add(_amount);

        emit Transfer(address(0), msg.sender, _amount);

        return true;
    }

    function burn(uint256 _amount) external ownerOnly returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_amount);
        totalSupply = totalSupply.sub(_amount);

        emit Transfer(msg.sender, address(0), _amount);

        return true;
    }
}