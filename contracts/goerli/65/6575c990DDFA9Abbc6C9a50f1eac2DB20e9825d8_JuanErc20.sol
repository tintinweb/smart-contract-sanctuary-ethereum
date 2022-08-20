// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./ERC20.sol";

/**
 * @title Project
 * @author capo
 */
contract JuanErc20 is ERC20{

    uint256 public override totalSupply;
    address public founder;
    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint)) private allowed;
    string public name;
    string public symbol;
    uint8 public decimals = 18;

    constructor(uint256 _totalSupply, string memory _name, string memory _symbol){
        totalSupply = _totalSupply;
        founder = msg.sender;
        name = _name;
        symbol = _symbol;
        balances[founder] = _totalSupply * 10**uint(decimals);
    }
    
    receive() external payable{
        
    } 

    function mandar() external payable{

    }
    /*
    fallback() external payable{
    // your code here…
    } 
    */
    function contractBalance() external view returns(uint){
        return address(this).balance;
    }


    function balanceOf(address account) external override view returns (uint){
        return  balances[account];
    }

    function transfer(address recipient, uint amount) external override returns (bool){
        require(balances[msg.sender] >= amount, "no tenes con que");
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint){
        return  allowed[owner][spender];
    }

    function approve(address spender, uint amount) external override returns (bool){
        allowed[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool){
        require(allowed[sender][recipient] > amount, "no se puede");
        allowed[sender][recipient] -= amount;
        balances[sender] -= amount;
        balances[recipient] += amount;
        return true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

abstract contract ERC20 {

    function totalSupply() external virtual view returns (uint);

    function balanceOf(address account) external virtual view returns (uint);

    function transfer(address recipient, uint amount) external virtual returns (bool);
    
    function allowance(address owner, address spender) external virtual view returns (uint);

    function approve(address spender, uint amount) external virtual returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external virtual returns (bool);


    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    
}