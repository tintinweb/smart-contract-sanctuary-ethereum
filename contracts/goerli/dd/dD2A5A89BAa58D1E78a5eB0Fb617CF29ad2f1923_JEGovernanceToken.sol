// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract JEGovernanceToken is ERC20{
    constructor(address shop) ERC20("JEGovernance", "JEG", 100, shop){

    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20{
    uint totalTokens;
    address _owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name;
    string _symbol;
    
    function name() external view returns(string memory){
        return _name;
    }
    function symbol() external view returns(string memory){
        return _symbol;
    }
    function decimals() external pure returns (uint){
        return 18;
    }

    function totalSupplu() external view returns (uint){
        return totalTokens;
    }
    function balanceOf(address account) public view returns (uint){
        return balances[account];
    }
    function transfer(address to, uint amount) external 
    enoughTokens(msg.sender, amount)
    {
        _beforTokenTransfer(msg.sender, to, amount);
        balances[msg.sender]-=amount;
        balances[to]+=amount;
        emit Transfer(msg.sender, to, amount);
    }
    function allowance(address owner, address spender) public view returns (uint){
        return allowances[owner][spender];
    }
    function approve(address spender, uint amount) public{
        _approve(msg.sender, spender,amount);
        allowances[msg.sender][spender] = amount;
        emit Approve(msg.sender, spender, amount);
    }
    function transferFrom(address sender, address recipient, uint amount) external 
    enoughTokens(sender, amount)
    {
        _beforTokenTransfer(sender, recipient, amount);
        allowances[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        
        emit Transfer(sender, recipient, amount);
    }


    modifier enoughTokens(address _from, uint _amount){
        require(balanceOf(_from) >= _amount, "Not enough tokens");
        _;
    }
    
    modifier onlyOwner(){
        require(msg.sender == _owner, "Not an owner");
        _;
    }
    
    constructor (string memory name_ ,string memory symbol_, uint initialSupply, address shop){
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
        mint(initialSupply, shop);
    }
    
    function mint(uint amount, address shop) public onlyOwner{
        _beforTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }
    
    function burn(address from, uint amount) public onlyOwner{
        _beforTokenTransfer(from, address(0), amount);
        balances[from] -= amount;
        totalTokens -= amount;
    }
    
    function _approve(address sender, address spender, uint amount) internal virtual{}
    function _beforTokenTransfer(address from, address to, uint amount) internal virtual{}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20{
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external pure returns (uint);
    
    function totalSupplu() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address to, uint amount) external;
    function allowance(address owner, address spender) external returns (uint);
    function approve(address spender, uint amount) external;
    function transferFrom(address sender, address recipient, uint amount) external;
    
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed owner, address indexed to, uint amount);
    
}