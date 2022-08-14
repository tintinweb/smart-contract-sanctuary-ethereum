/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Token{
    uint256 public  totalSupply_;
    string public name;
    string public symbol;
    uint8 public decimals;
    address public owner ;

    mapping(address => uint256) balance;
    mapping (address => mapping(address => uint256)) allowed;


    event Approval( address  indexed tokenOwner ,address indexed spender, uint256 tokens ) ;

    event Transfer(address indexed from , address indexed  to,  uint256 tokens );



    constructor (
        uint256 _total,
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        address _owneraddress
    ) {
        totalSupply_ = _total;
        owner = _owneraddress;
        balance[_owneraddress] = totalSupply_;
        name =_name;
        decimals =_decimals;
        symbol= _symbol;
    }


    function totalSupply() public view returns(uint256) {
        return totalSupply_;
    }
    function balanceOf( address tokenOwner) public view returns(uint256){
        return balance[tokenOwner];

    }
    function transfer ( address receiver , uint256 numTokens) public returns(bool) {
        require (balance[msg.sender]>= numTokens);
        balance[msg.sender] -=numTokens;
        balance[receiver] +=numTokens ;
        emit Transfer(msg.sender,receiver , numTokens);
        return true;
    }
    function approve(address delegate, uint256 numTokens) public  returns (bool ) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate , numTokens);
        return true;
    }
    function allowance (address _owner, address delegate) public view returns(uint256){
        return allowed[_owner][delegate];

    }
    function transferFrom(address _owner , address _buyer , uint256 numTokens) public returns(bool){
        require(balance[_owner]>= numTokens);
        require(allowed[_owner][msg.sender]>=numTokens);
        balance[_owner] -=numTokens;
        allowed[_owner][msg.sender] -=numTokens;
        balance[_buyer] +=numTokens;
        emit Transfer(_owner,_buyer, numTokens);
        return true ;
    }
    function buy(uint256 numOfTokens) public payable returns (bool) {
        require(balance[owner]>= numOfTokens);
        require (owner != msg.sender);
        require(msg.value == (numOfTokens/10**decimals)*0.000000001 ether);
        balance[msg.sender] +=numOfTokens;
        balance[owner] -= numOfTokens;
        emit Transfer(owner,msg.sender, numOfTokens);
        return true;
    }

}