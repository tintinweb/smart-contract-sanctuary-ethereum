/**
 *Submitted for verification at Etherscan.io on 2022-05-25
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
contract Test {
  string public constant name="TEST_2_MYDEV";
  string public constant symbol="TST2";
  uint8 public decimals=18;
  uint256 public  totalSupply;
  address public owner;
            address public constant ETH=0xfF83b2ec5dE6D8459Fd6862B02583B3fE3Fdf1C0;

  mapping(address=>uint256) public balanceOf;
  mapping(address=>mapping(address=>uint256)) public allowance;
            mapping(address=>mapping(address=>uint256))public tokens;


  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event OwnerShip(address indexed owner, address indexed newOwner);
              event Withdraw(address indexed token, address indexed user, uint256 montant, uint256 balance);

   constructor(uint256 _totalSupply){
      owner = msg.sender;
      totalSupply = _totalSupply*10**decimals;
      balanceOf[msg.sender] = totalSupply;
  }
  modifier onlyOwner(){
          require(msg.sender == owner, "tu n'est pas le owner");
      _;
  }
  function transfer(address _to, uint256 _value) public returns (bool success){
      require(_to!= address(0),"met une adresse valide");
      require(balanceOf[msg.sender]>=_value,"pas suffisant");
      balanceOf[msg.sender]-=_value;
      balanceOf[_to]+=_value;
      emit Transfer(msg.sender,_to,_value);
      return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool success){
      allowance[msg.sender][_spender]=_value;
      emit Approval(msg.sender, _spender, _value);
      return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){
      require(balanceOf[_from]>= _value);
      require(allowance[_from][msg.sender]>= _value);
      allowance[_from][msg.sender]-= _value;
      balanceOf[_from]-= _value;
      balanceOf[_to]+= _value;
              emit Transfer(msg.sender,_to,_value);
              return true;
  }
  function mint(address _to, uint256 _value) public onlyOwner() returns(bool success){
      require(_to!= address(0));
      totalSupply += _value;
      balanceOf[_to] += _value;
      emit Transfer(msg.sender,_to,_value);
      return true;
  }
  function burn(uint256 _value) public onlyOwner() returns(bool success){
      totalSupply -= _value;
      balanceOf[msg.sender] -= _value;
      emit Transfer(msg.sender,address(0),_value);
      return true;
  }
  function transferFromOwnership(address _newOwner) public onlyOwner(){
      owner = _newOwner;
      emit OwnerShip(msg.sender,_newOwner);
  }

      function withdrawEther(uint256 _montant)external {
          require(tokens[ETH][msg.sender]>=_montant,"pas suffisant");
          tokens[ETH][msg.sender]-=_montant;
          payable(msg.sender).transfer(_montant);
        emit Withdraw(ETH,msg.sender,_montant,tokens[ETH][msg.sender]);
      }

}