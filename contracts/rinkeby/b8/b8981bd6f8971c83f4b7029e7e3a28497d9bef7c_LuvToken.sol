/**
 *Submitted for verification at Etherscan.io on 2022-03-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.5.00;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// 'LuvToken' token contract
//
// Deployed to : 0x4F8785f7431461Ca24A2ddE91Bb677aD77525204
// Symbol      : LUV
// Name        : Love token
// Total supply: 100000000000000000000000000
// Decimals    : 18
// ----------------------------------------------------------------------------


// ----------------------------------------------------------------------------
// Chertam
// ----------------------------------------------------------------------------
contract Chertam {
    struct Couple {
        bytes16 id;
        address partner1;
        address partner2;
        Status status;
    }

    mapping(bytes16 => Couple) public couples;

    enum Status { DATING, BREAKUP, ENGAGED, MARRIED, DIVORCED, SEPARATED }
    Status private coupleStatus;

    function setStatus(bytes16 id, address partner1, address partner2, Status status) public {
        Couple memory couple;
        couple.id = id;
        couple.partner1 = partner1;
        couple.partner2 = partner2;
        couple.status = status;

        couples[id] = couple;
    }

    function getStatus(bytes16 id) public view returns (Couple memory){
        return couples[id];
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
// contract Owned {
//     address public owner;
//     address public newOwner;

//     event OwnershipTransferred(address indexed _from, address indexed _to);

//     constructor() public {
//         owner = msg.sender;
//     }

//     modifier onlyOwner {
//         require(msg.sender == owner);
//         _;
//     }

//     function transferOwnership(address _newOwner) public onlyOwner {
//         newOwner = _newOwner;
//     }
//     function acceptOwnership() public {
//         require(msg.sender == newOwner);
//         emit OwnershipTransferred(owner, newOwner);
//         owner = newOwner;
//         newOwner = address(0);
//     }
// }


// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and assisted
// token transfers
// ----------------------------------------------------------------------------
contract LuvToken is ERC20Interface, Chertam {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    address WALLET_ADDRESS;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor() public {
        symbol = "LUV";
        name = "Love Token";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;
        WALLET_ADDRESS = 0x4F8785f7431461Ca24A2ddE91Bb677aD77525204;
        balances[WALLET_ADDRESS] = _totalSupply;
        emit Transfer(address(0), WALLET_ADDRESS, _totalSupply);
    }


    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to to account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender] - tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Transfer tokens from the from account to the to account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the from account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from] - tokens;
        allowed[from][msg.sender] = allowed[from][msg.sender] + tokens;
        balances[to] = balances[to] + tokens;
        emit Transfer(from, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account. The spender contract function
    // receiveApproval(...) is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    function () external payable {
        revert();
    }


    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    // function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    //     return ERC20Interface(tokenAddress).transfer(owner, tokens);
    // }
}