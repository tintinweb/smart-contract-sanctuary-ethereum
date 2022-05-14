/**
 *Submitted for verification at Etherscan.io on 2022-05-14
*/

// SPDX-License-Identifier: UNLICENSED
// <JOSHUA P. EDMOND> 
// ALIAS; IGNOTUS わからない
//SOCIALS : INSTAGRAM: @IGNOTUSPY TWITTER: @IGNOTUSCODE GITHUB: @IGNOTUSCODE
// CONTACT: Phone +17867121197 Personal: [email protected] Business: [email protected]
// EDUCATION: MIAMI DADE COLLEGE NORTH CAMPUS <MAJOR> -> CYBERSECURITY/IT <MINOR> COMPUTER SCI
// CERTIFICATION: MOS_CERTIFIED :77-883: MOS: Microsoft Office PowerPoint 2010, Microsoft Word (Office 2016), Microsoft Excel (Office 2016)
// <Cont.> 98-349:MTA: Windows® Operating System Fundamentals,
// <Graphic Design and Illustration using Adobe Illustrator CC 2015>
// Web3 PROJECTS; IGNOSHA (ERC721TOKEN), IGNOTUS: BLOCKCHAIN, IGNOSPY (ERC20TOKEN)
// Copyright IGNOTUS わからない  
// EXPERIENCE: SMART CONTRACT BUILDING, BLOCKCHAIN DEVELOPMENT, 
// Web Site: http://www.Ignotuscode.com

pragma solidity ^0.5.0;

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
// Safe Math Library
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract IgnoshaERC is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


    constructor() public {
        name = "IgnoshaERC";
        symbol = "NERC";
        decimals = 18;
        _totalSupply = 20000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}