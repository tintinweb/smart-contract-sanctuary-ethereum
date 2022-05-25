/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    //returns the total amount of this token available
    function totalSupply() external view returns (uint256);

    //returns the amount of this token that the specific count has
    function balanceOf(address account) external view returns (uint256 balance);

    //holder of the token can call this function to transfer token directly
    function transfer(address to, uint256 amount) external returns (bool success);

    //allows holder of this token to approve someone else to spend his token
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool success);

    //specifies how much a spender can spend from a holder
    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    //holder of the token calls approve to allow spender to spend his money
    function approve(address spender, uint256 amount) external returns (bool success);

    //ERC20 standards
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 amount
    );
}

contract SafeMath {
    function add(uint a, uint b) public pure returns (uint c){
        c = a + b;
        require(c >= a);
    }
    
    function sub(uint a, uint b) public pure returns (uint c){
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) public pure returns (uint c){
        c = a * b;
        require(a == 0 || c/a == b);
    }

    function div(uint a, uint b) public pure returns (uint c){
        require(b >= a);
        c = a / b;
    }
}

contract SheerToken is IERC20, SafeMath{
    //token metadata - decimals = 18 (10^18) - default
    string public name;
    string public symbol;
    uint8 public decimals;

    //store total supply of this token
    uint public _totalSupply;

    //keep track of all user balances
    mapping(address => uint) public balances;

    //keep track of which user is allowed to spend how much of another user's token
    //can only spend if approved by the tokenOwner
    //tokenOwner -> spender -> amount
    mapping(address => mapping(address => uint)) allowed;

    //init token details
    constructor(){
        name = "SheerToken";
        symbol = "SHT";
        decimals = 18;

        //1 billion tokens (remove the last 18 zeros)
        _totalSupply = 100000000000000000000000000;

        //all initial supply given to the creator of the token
        balances[msg.sender] == _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    //returns total supply of the token
    function totalSupply() override external view returns (uint){
        return _totalSupply - balances[address(0)];
    }

    //returns balance of the given account address
    function balanceOf(address account) override external view returns (uint balance){  
        return balances[account];
    }

    //return allowed amount of tokens for a specified spender of a token of a token owner
    function allowance(address tokenOwner, address spender) override external view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    //allowed to approve a spender to spend the tokenOwner's token
    //called by the tokenOwner
    function approve(address spender, uint amount) override external returns(bool success){
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    //function called by the tokenOwner to transfer his owned token
    function transfer(address to, uint amount) override external returns (bool success){
        balances[msg.sender] = sub(balances[msg.sender], amount);
        balances[to] = add(balances[to], amount);

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    //function to transfer another tokenOwner's tokens on his behalf
    //this function is called by the spender
    function transferFrom(address from, address to, uint amount) override external returns (bool success){
        //will only subtract if the spender is listed under the tokenOwner's allowance key
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], amount);

        balances[from] = sub(balances[from], amount);
        balances[to] = add(balances[to], amount);
        
        emit Transfer(msg.sender, to, amount);
        return true;    
    }
}