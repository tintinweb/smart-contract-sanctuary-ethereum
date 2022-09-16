/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity ^0.4.17;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    //function allowance(address owner, address spender) external view returns (uint);

    //function approve(address spender, uint amount) external returns (bool);

    /*function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);*/

    event Transfer(address indexed from, address indexed to, uint value);
    event Burn(address indexed from, address indexed to ,uint value);
    event Mint(address indexed from, uint value);
}

contract ERC20 is IERC20{

    address owner;
    uint256 totalSupply_;
    string public constant name = "ACER TOKEN";
    string public constant symbol = "ACR";
    uint8 public constant decimal = 18;

    mapping(address => uint256) balances;

    constructor() public{
        totalSupply_ = 15000;
        balances[msg.sender] = totalSupply_;
        owner = msg.sender;
    }

    function transfer(address recipient, uint value) external returns(bool){
        require(balances[msg.sender] >= value);
        balances[msg.sender] -= value;
        balances[recipient] += value;
        emit Transfer(msg.sender, recipient, value);
        return true;
    }

    function balanceOf(address account) external view returns(uint){
        return balances[account];
    }

    function totalSupply() external view returns(uint256){
        return totalSupply_;
    } 

    function mint(uint value) external {
        balances[msg.sender] += value;
        totalSupply_ += value;
        emit Mint(msg.sender, value);
    }

    function burn(uint value) external{
        require(owner == msg.sender);
        balances[msg.sender] -= value;
        totalSupply_ -= value;
        emit Burn(msg.sender, address(0) ,value);
        
    }
}