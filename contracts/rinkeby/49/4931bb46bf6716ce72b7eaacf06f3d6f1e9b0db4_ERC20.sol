/**
 *Submitted for verification at Etherscan.io on 2022-05-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IERC20{

         function totalSupply() external view returns (uint);
     
         function balanceOf(address account) external view returns (uint);

          function transfer(address to,uint value)external returns(bool);

          function transferfrom(address From, address to, uint value) external returns(bool);

          function approve(address spender, uint value)external returns(bool);

          function allowance(address owner, address spender)external view returns(uint);

          function name() external view returns (string memory);

          function symbol() external view returns (string memory);

          function decimals() external view returns (uint8);

          event approval(address indexed owner,address indexed spender,uint ammount);

          event Transfer(address indexed From, address indexed to,uint amount);

 }


contract ERC20 is IERC20 {
    uint private TOTALSUPPLY;
    mapping(address=>uint)public balance;
    mapping(address=>mapping(address=>uint))public allowances;
    string private NAME= "Hassam Ali";
    string private SYMBOL="SOLBYME";

    function transfer(address _to , uint _value)external virtual override returns(bool){
        balance[msg.sender] -= _value;
        balance[_to] += _value;
        emit Transfer(msg.sender , _to , _value);
        return true;
    }

    function approve(address _spender, uint _value)external virtual override returns(bool){
        allowances[msg.sender][_spender]=_value;
        emit approval(_spender,msg.sender, _value);
        return true;
    }

    function transferfrom(
        address _From,
         address _to,
          uint _value)external virtual override returns(bool){
            
              require(_value<=allowances[_From][msg.sender],"value shouled be not allowed");
        allowances[_From][msg.sender]-=_value;
        balance[_From]-=_value;
        balance[_to]+=_value;
        emit Transfer(_From , _to , _value);
        return true;
    }

    function balanceOf(address _account) external view virtual override returns(uint) {
        return balance[_account];
    }

    function allowance(address owner, address spender) external view virtual override returns (uint) {
        return allowances[owner][spender];
    }

    function name() external view virtual override returns (string memory) {
        return NAME;
    }

    function symbol() external view virtual override returns (string memory) {
        return SYMBOL;
    }

    function decimals() external view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() external view virtual override returns (uint) {
        return TOTALSUPPLY;
    }

    function mint(uint _value)external{
    
        balance[msg.sender]+=_value;
        TOTALSUPPLY+=_value;
        emit Transfer(address(0),msg.sender,_value);


    }
    function burn(uint _value)external{
        balance[msg.sender]-=_value;
        TOTALSUPPLY-=_value;
        emit Transfer(msg.sender,address(0),_value);

    }

}