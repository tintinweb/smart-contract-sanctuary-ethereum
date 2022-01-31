/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// SPDX-License-Identifier: MIT   
// Solidity files generally have a license identifer. 

// Specify the minimum Solidity version required for this contract 
pragma solidity ^0.4.16;
 

 
// Here is the Interface for the ERC20 Token Standard  
contract IERC20{
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    // these event is emitted when the state of the ERC20 contracted changes 
    event Transfer(address indexed from, address indexed to, uint tokens);  
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens); 
}
 


//Safe Math Interface to perform math without overflows 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
 
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
 
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
 
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// Owned contract used by the transferAnyERC20Token function to transfer out any accidently sent ERC20 tokens! 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);   // trigger the OwnershipTransferred event 
        owner = newOwner;  
        newOwner = address(0);
    }
}

 
//Contract function to receive approval and execute function in one call. 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
 
//Actual token contract
contract TaffyCoin is IERC20, SafeMath, Owned {
    string public symbol;
    string public  name;
    uint8 public decimals;  // Ethereum does not have floating points or fractional variables. 
    uint public totalSupply;
 
    // Balance for each account
    mapping(address => uint) balances;
    // Track owners of account approving the transfer of an amount to another account
    mapping(address => mapping(address => uint)) allowed;
 

    // Constructor of TaffyToken contract 
    constructor() public {
        symbol = "TAFFY";
        name = "Taffy Coin";
        decimals = 18;   // same standard as ETH  
        totalSupply = 10**27; // total supply amount 

        // transfer all tokens to the owners address
        address owner = 0xc342F2381c802Ac8803422ea62bD596dceBc586d;       // Owner of this contract
        balances[owner] = totalSupply;  // Transfer total supply to owner 
        emit Transfer(address(0), owner, totalSupply);  // trigger the transfer event 
    }
 
    // return total supply of tokens available 
    function totalSupply() public constant returns (uint) {
        return totalSupply  - balances[address(0)];
    }

    // return token balance of a particular account 
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }
 
    // Transfer the balance from owner's account to another account
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);   // reduce the senders balance by the given token amount
        balances[to] = safeAdd(balances[to], tokens);  // add the new token amount to the recepients balance 
        emit Transfer(msg.sender, to, tokens); // emit a transfer event
        return true;  // return true
    }
 
   
 

  // Allow spender to withdraw from sender account, multiple times, up to the tokens amount.
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;  // allow certain amount token to be sent to spender
        emit Approval(msg.sender, spender, tokens);   // emit an approval event
        return true;
    }



    // Move amount of tokens from sender address to receiver address.
    // This function is called by a speneder to spend an amount that was already approved by approve function
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);    // emit a transfer event
        return true;
    }
 

    //  Return what is the allowance amount given by tokenOwner to spender 
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    // Allow spender to transfer from sender account, and the spender's receiveApproval contract function is then called. 
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;   // allow certain amount token to be sent to spender
        emit Approval(msg.sender, spender, tokens);  // emit an approval event
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
 
    // Owner can transfer out any accidentally sent ERC20 tokens. 
    // This addresses the human error where token holders accidently send their tokens to the contract address itself.
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return IERC20(tokenAddress).transfer(owner, tokens);  
    }

    // don't accept ETH 
    function () public payable {
        revert();
    }


    // return name of the token
    function name() public view returns (string memory) {
        return name;
    }

    // return symbol of the token
    function symbol() public view returns (string memory) {
        return symbol;
    }

    // return the decimal value of the token
    function decimals() public view returns (uint8) {
        return decimals;
    }

}