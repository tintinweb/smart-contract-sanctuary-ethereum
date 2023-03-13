/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: MIT
//從 Solidity ^0.6.8 引入了 SPDX 許可證。 所以需要在代碼中使用SPDX-License-Identifier。
pragma solidity >=0.4.22 <0.9.0;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ERC Token Standard #20 Interface

abstract contract ERC20Interface {
    function totalSupply() public view virtual returns (uint);
    function balanceOf(address tokenOwner) public view virtual returns (uint balance);
    function allowance(address tokenOwner, address spender) public view virtual returns (uint remaining);
    function transfer(address to, uint tokens, string memory orderId, string memory sender, string memory receiver, string memory bank) external virtual returns (bool success);
    function approve(address spender, uint tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

abstract contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public virtual;
}


contract Token is ERC20Interface{
    using SafeMath for uint;

    string public symbol = "Bourbon";
    string public  name = "Bourbon Token";
    uint8 public decimals = 18;
    uint _totalSupply = 1000000 * 10**uint(decimals);
    uint256 lastRun;
    address owner;
    string data;
    string orderId;
    string sender;
    string receiver;
    string bank;
    
    event setData(string orderId, string sender, string receiver, string bank);
    event setBankData(string data);

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        balances[msg.sender] = _totalSupply;
        owner = msg.sender; //0x6331C5b72a0b5422c79b822FB02Fd823Ade4239f
        emit Transfer(address(0), owner, _totalSupply);
    }


    function totalSupply() public view override returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

    //查詢帳號餘額
    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    //只有平台能使用
    function transfer(address to, uint amount, string memory orderId, string memory sender, string memory receiver, string memory bank) external override returns (bool success) {
        require(msg.sender == 0x6331C5b72a0b5422c79b822FB02Fd823Ade4239f,"Your are not boutbon platform" );
        require(balances[msg.sender] >= amount, "Tokens not enough!!");
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(msg.sender, to, amount);
        orderId = orderId;
        sender = sender;
        receiver = receiver;
        bank = bank;
        emit setData(orderId, sender, receiver, bank);
        return true;
    }

    //只有銀行能使用
    function allTokenBack(string memory x) external {
        require(block.timestamp - lastRun > 5 seconds, "need to wait 5 seconds");
        require(msg.sender == 0x6E53E3962facEae8F4d9201766e8985E4F2fe95F &&  balances[0x6E53E3962facEae8F4d9201766e8985E4F2fe95F] >= 0, "Your are not bank");
        emit Transfer(msg.sender, 0x6331C5b72a0b5422c79b822FB02Fd823Ade4239f , balances[msg.sender]);
        balances[0x6331C5b72a0b5422c79b822FB02Fd823Ade4239f] = balances[0x6331C5b72a0b5422c79b822FB02Fd823Ade4239f].add(balances[msg.sender]);
        balances[msg.sender] = 0;
        lastRun = block.timestamp; 
        data = x;
        emit setBankData(data);
    }


    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, msg.sender, data);
        return true;
    }



    // Don't accept ETH
    fallback () external payable {
        revert();
    }

    receive() external payable {
        // custom function code
    }

    // Owner can transfer out any accidentally sent ERC20 tokens
    function transferAnyERC20Token(address tokenAddress, uint tokens, string memory orderId, string memory sender, string memory receiver, string memory bank) external returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens,orderId, sender, receiver, bank);
    }
}