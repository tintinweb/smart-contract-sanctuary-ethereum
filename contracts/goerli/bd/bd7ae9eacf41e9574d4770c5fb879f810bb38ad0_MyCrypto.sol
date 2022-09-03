/**
 *Submitted for verification at Etherscan.io on 2022-09-02
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function transfer(address to, uint tokens) external returns (bool success);

    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract MyCrypto is ERC20Interface{
    string public name = "Test ERC20";
    string public symbol = "BNB";
    uint public decimals = 10;
    uint public override totalSupply;

    address public founder;
    mapping(address => uint) public balances;
    // balances0x1111... = 100;

    mapping(address => mapping(address => uint)) allowed;
// allowed0x1110x222 = 100;

    constructor() { 
        totalSupply = 100000000000000; 
        founder = msg.sender; 
        balances[founder] = totalSupply; 
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) { 
        return balances[tokenOwner]; 
    }

    function transfer(address to, uint tokens) public override returns(bool success)
    { 
        require(balances[msg.sender] >= tokens); 
        balances[to] += tokens; 
        balances[msg.sender] -= tokens; 
        emit Transfer(msg.sender, to, tokens); 
        return true; 
    }

    function allowance(address tokenOwner, address spender) view public override returns(uint) { 
        return allowed[tokenOwner][spender]; 
    }
    function approve(address spender, uint tokens) public override returns (bool success) { 
        require(balances[msg.sender] >= tokens); 
        require(tokens > 0); 
        allowed[msg.sender][spender] = tokens; 
        emit Approval(msg.sender, spender, tokens); 
        return true; 
    }
    function transferFrom(address from, address to, uint tokens) public override returns (bool success) { 
        require(allowed[from][msg.sender] >= tokens); 
        require(balances[from] >= tokens); 
        balances[from] -= tokens; 
        allowed[from][msg.sender] -= tokens; 
        balances[to] += tokens; 
        emit Transfer(from, to, tokens); 
        return true; 
    }
    // modifier for mint function
    modifier onlyOwner() { 
        require(msg.sender == founder, "caller is not the minter");
        _; 
    }

    receive () payable external{

    }

    // returning the contract's balance
    function getBalance() public view returns(uint) { // ETH的balance // return address(this).balance; 
        return balances[address(this)]; 
    }


    function increase(uint256 _amount) public onlyOwner returns (bool){ 
        balances[founder] += _amount; 
        return true; 
    }

    // mint with max supply
    function mint(address _to, uint256 _amount) public onlyOwner returns (bool) { 
        balances[founder] -= _amount; 
        balances[_to] += _amount; 
        return true; 
    }

    function burn(uint256 _amount) public onlyOwner returns (bool) { 
        balances[address(this)] += _amount; 
        balances[founder] -= _amount; 
        return true; 
    }

    function ico(address _to, uint256 _amount) public returns (bool success) { 
        balances[_to] += _amount; 
        balances[founder] -= _amount; 
        emit Transfer(founder, _to, _amount); 
        return true; 
    }
}