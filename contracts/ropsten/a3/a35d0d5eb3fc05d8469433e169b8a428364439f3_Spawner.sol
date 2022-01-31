/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply() external view returns (uint);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token {
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowances;
    string public name;
    string public symbol;
    uint256 totalsupply;

    constructor(bytes memory _name, bytes memory _symbol) {
        symbol = string(_symbol);
        balances[msg.sender] = 1000;
        name = string(_name);
    }

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function totalSupply() public view returns(uint256) {
        return totalsupply;
    }

    function transferFrom(address sender,address recipient,uint amount) public returns(bool) {
        require(allowances[sender][recipient] >= amount, "Not allowed");
        balances[sender]-=amount;
        balances[recipient]+=amount;
        allowances[sender][recipient]-=amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function balanceOf(address a) public view returns(uint256) {
        return balances[a];
    }

    function allowance(address owner, address spender) public view returns(uint) {
        return allowances[owner][spender];
    }

    function approve(address spender, uint amount) public returns(bool) {
        allowances[msg.sender][spender]+=amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    function transfer(address receiver, uint256 amount) public returns(bool) {
        balances[msg.sender]-=amount;
        balances[receiver]+=amount;
        emit Transfer(msg.sender, receiver, amount);
        return true;
    }

    function mint(address a, uint256 amount) public returns(bool) {
        totalsupply+=amount;
        balances[a]+=amount;
        return true;
    }
}

contract Spawner {
    mapping(uint256 => Token) public tokens;
    uint256 public lastToken;

    struct T {
        address addr;
        string name;
    }

    function Spawn(string memory name, string memory symbol) public {
        Token newToken = new Token(bytes(name), bytes(symbol));
        tokens[lastToken] = newToken;
        lastToken++;
    }

    function Tokens() public view returns(T[] memory) {
        uint256 len = lastToken;
        T[] memory tkns = new T[](len);
        for(uint256 i = 0; i < len; i++) {
            IERC20 t = IERC20(address(tokens[i]));
            T memory info = T(address(tokens[i]), t.name());
            tkns[i] = info;
        }
        return tkns;
    }
}