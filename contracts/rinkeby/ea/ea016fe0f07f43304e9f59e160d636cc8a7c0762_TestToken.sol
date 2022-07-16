/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.2 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TestToken is IERC20{
    using SafeMath for uint256;

    string public name;
    string public symbol;
    uint8 public decimal;
    uint256 public totalSupply_;

    mapping(address => uint256) balance;
    mapping(address => mapping(address => uint256)) allowed;

    constructor(){
        name = "TestToken";
        symbol = "TsT";
        decimal= 5;
        totalSupply_ = 100 * (10 ** 5);
        balance[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns(uint256){
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns(uint256){
        return balance[tokenOwner];
    }

    function transfer(address receiver,uint256 numToken) public override returns(bool){
        require(numToken <= balance[msg.sender]);
        balance[msg.sender] = balance[msg.sender].sub(numToken);
        balance[receiver] = balance[receiver].add(numToken);
        emit Transfer(msg.sender, receiver, numToken);
        return true;
    }

    function approve(address delegate, uint256 numToken) public override returns(bool){
        allowed[msg.sender][delegate] = numToken;
        emit Approval(msg.sender , delegate , numToken);
        return true;
    }

    function allowance(address owner , address delegate) public override view returns(uint){
        return allowed[owner][delegate];
    }

    function transferFrom(address owner , address buyer,uint256 numToken) public override returns(bool){
        require(numToken <= balance[owner]);
        require(numToken <= allowed[owner][msg.sender]);
        balance[owner] = balance[owner].sub(numToken);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numToken);
        balance[buyer] = balance[buyer].add(numToken);
        emit Transfer(owner, buyer, numToken);
        return true;
    }


}

library SafeMath{
    function sub(uint256 a , uint256 b) internal pure returns(uint256){
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a  , uint256 b)internal pure returns(uint256){
        uint256 c = a+b;
        assert(c >= a );
        return c;
    }
}