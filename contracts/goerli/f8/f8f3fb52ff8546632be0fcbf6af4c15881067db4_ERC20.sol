/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

//token is digital asset
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface IERC20
{
    // function name() external view  return(string memory);
    //function symbol() external view  return(string memory);
    //function decimal() external view  return(uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value)  external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

}
contract ERC20 is IERC20
{

    constructor(string memory _name,string memory _symbol,uint8 _decimal,uint256 _tsupply)
    {
        nameToken=_name;
        symbolToken=_symbol;
        decimalToken=_decimal;
        tsupply=_tsupply*(10**_decimal);
        //balances[msg.sender]=tsupply;


      balances[msg.sender]=tsupply;
    }
    string nameToken="LTTS";
    string symbolToken="LTTS2";
    uint8 decimalToken=2;
    address owner;
    uint256 tsupply=1000*(10**decimalToken);
    mapping(address => uint256) balances;
     mapping(address => mapping(address=>uint256)) allowed;//owner is allowing to the spender 
    event Transfer(address indexed _from, address indexed _to, uint256 _value);


function name() public view returns (string memory)
{
    return nameToken;
}
function symbol() public view returns (string memory)
{
    return symbolToken;
}
function decimals() public view returns (uint8)
{
    return decimalToken;
}
function totalSupply() public view returns (uint256)
{
    return tsupply;
}
function balanceOf(address _owner) public view returns (uint256 balance)
{
    return balances[_owner];
}
function transfer(address _to, uint256 _value) public returns (bool success)
{

     require(balances[msg.sender]>=_value,"[email protected]):Insufficient balance");
      balances[msg.sender]-=_value;
      balances[_to]+=_value;
      
      emit Transfer(msg.sender,_to,_value);
      return true;
}


  //spender

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success)

  {



      require(balances[_from]>=_value,"[email protected]):Insufficient balance");
      require(allowed[_from][msg.sender]>=_value,"ERC20:not enough allowance");
      balances[_from]-=_value;
      balances[_to]+=_value;
      allowed[_from][msg.sender]-=_value;
      emit Transfer(_from,_to,_value);
      return true;
  }


  //owner
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  function approve(address _spender, uint256 _value) public returns (bool success)
  {
         allowed[msg.sender][_spender]=_value;
          emit Approval(msg.sender,_spender,_value);
          return true;


  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining)
  {


      return allowed[_owner][_spender];
  }


  //mint &Burn
  function mint(address _to,uint256 _qty) public{
      tsupply+=_qty;
     balances[_to]+=_qty;


  }

  function burn(uint256 _qty)public{

      require(balances[msg.sender]>=_qty,"error not enough token to burn");
      tsupply-=_qty;
      balances[msg.sender]-=_qty;
  }

}
  contract TATAToken is ERC20
  {


      constructor(uint256 _tsupply) ERC20("TATAToken","TATA",18,_tsupply)
      {

           mint(msg.sender,_tsupply*(10**decimals()));

      }
      function buyToken(uint256 _amount)public payable{

         uint amountIn=_amount/1000;
         require(msg.value==amountIn,"Incorrect wei transfer");
         //owner needs  to approve this contract
         transferFrom(owner,msg.sender,_amount);




      }
      

      
  }



//owner-0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//spender--0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
//benificial--0x17F6AD8Ef982297579C203069C1DbfFE4348c372