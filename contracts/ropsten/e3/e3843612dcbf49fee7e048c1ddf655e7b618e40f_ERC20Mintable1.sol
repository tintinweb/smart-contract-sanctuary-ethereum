/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ERC20Mintable1{

    string internal tName;
    string internal tSymbol;
    uint internal tDecimal;
    uint internal t_Supply;
    address internal Owner;
    mapping(address=> uint) internal balances;
    mapping(address=>mapping(address=>uint))internal allowed;
    event Transfer(address indexed _from,address indexed _to, uint _tAmount);
    event Approval( address indexed _Owner, address indexed  spender, uint _tAmount);
    constructor(){
        tName="My Silver Token";
        tSymbol="MST";
        tDecimal=10;
        t_Supply=10000* 10**uint(tDecimal);
        Owner=msg.sender;
        balances[Owner]= t_Supply;
    }
    modifier onlyOwner(){
        require(msg.sender==Owner,"Only Owner can access This Function");
        _;
    }

    function tokenName() external view returns(string memory){
        return tName;
    }
    function tokenSymbol() external view returns(string memory){
        return tSymbol;
    }
    function tokenDecimal() external view returns(uint){
        return tDecimal;
    }
    function tokenSupply() external view returns(uint){
        return t_Supply;
    }
    function balanceOf(address _Owner) public view returns(uint){
        return  balances[_Owner];
    }
    function allowance(address _Owner,address _spender) public view returns(uint){
        return allowed[_Owner][_spender];
    }
    function mintTokens(uint _tokens) public onlyOwner returns(bool){
        t_Supply=t_Supply+ _tokens*(10**uint(tDecimal));
        balances[msg.sender] += _tokens;
        emit Transfer(address(0), msg.sender, _tokens);
        return true;
          
    }
    function burnTokens(uint _tokens) public onlyOwner returns(bool){
        t_Supply=t_Supply- _tokens*(10**uint(tDecimal));
        balances[msg.sender] -= _tokens;
        emit Transfer(msg.sender, address(0), _tokens);
        return true;
          
    }
    function transfer(address _to,uint _tokens) public returns (bool){
        require(balances[msg.sender]>= _tokens,"You have not sufficent tokens");
        require(_to != address(0),"Can't send tokens to Zero Address");
        balances[msg.sender] -= _tokens;
        balances[_to] += _tokens;
        emit Transfer(msg.sender, _to , _tokens);
        return true;
    }
    function approve(address _spender, uint _tokens) public returns (bool){
        require(_spender != address(0),"Can't send tokens to Zero Address");
        require(balances[msg.sender]>= _tokens,"You have not sufficent tokens");
        allowed[msg.sender][_spender] += _tokens;
        emit Approval(msg.sender, _spender, _tokens);
        return true;
    }
    function transferFrom(address _Owner, address _to, uint _tokens) public returns (bool){
        require(balances[_Owner]>= _tokens,"You have not sufficent tokens");
        require(allowed[_Owner][msg.sender]>= _tokens,"You have not sufficent tokens");
        require(_to != address(0),"Can't send tokens to Zero Address");
        balances[_Owner] -= _tokens;
        balances[_to] += _tokens;
        allowed[_Owner][msg.sender] -= _tokens;
       emit Transfer(_Owner, _to, _tokens);
        return true;
    }
}