/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// File: contracts/erc20 first token.sol





pragma solidity ^0.8.7 ;

/*import"https://github.com/OpenZeppelin/openzeppelin-contracts/blob/d59306bd06a241083841c2e4a39db08e1f3722cc/contracts/token/ERC20/ERC20.sol";

contract firsttoken is ERC20("firsttoken","hafiz"){

}*/

abstract  contract ERC20_STD{



   function name() public view virtual returns (string memory);

   function symbol() public view virtual returns (string memory);

  function decimals() public view  virtual returns (uint8);





   function totalSupply() public view virtual returns (uint256);

   function balanceOf(address _owner) public view  virtual returns (uint256 balance);

   function transfer(address _to, uint256 _value) public virtual  returns (bool success);

   function transferFrom(address _from, address _to, uint256 _value) public virtual  returns (bool success);

   function approve(address _spender, uint256 _value) public virtual  returns (bool success);

   function allowance(address _owner, address _spender) public view virtual returns (uint256 remaining);

 

 event Transfer(address indexed _from, address indexed _to, uint256 _value);

 event Approval(address indexed _owner, address indexed _spender, uint256 _value);



}



contract ownership{

    address public contractOwner;

    address public newOwner;



    event TransferOwnership(address indexed _from, address indexed _to);

    constructor ()

    {



        contractOwner=msg.sender;

    }

    function  changeOwner  (address _to) public

    {

     require(msg.sender==contractOwner,'only contract owner can execute it');

      newOwner = _to;



    }

   function  acceptOwner () public 

   {

       require(msg.sender==newOwner,'only new assigned owner can call it' );

       emit TransferOwnership(contractOwner,newOwner);

       contractOwner=newOwner;

       newOwner=address(0);

   }

}

contract MyContract_ERC20 is ERC20_STD,ownership

{



   string public  _name;

   string public _symbol;

   uint8 public _decimals;

   uint256 public _totalSupply;







   address public  _minter ;



   mapping(address=>uint256 )tokenBalances;

   mapping(address=> mapping(address=>uint256 ))allowed;

   constructor(address minter_)

   {

        _name='Hafiz Mubashar';

        _symbol='HM';

        _totalSupply=200000;

        _minter = minter_;

        tokenBalances[_minter]= _totalSupply;



   }

    function name() public view override returns (string memory){

        return _name;

    }

   function symbol() public view override returns (string memory){

       return _symbol;

   }

   function decimals() public view override returns (uint8){

       return _decimals;

   }





   function totalSupply() public view override returns (uint256){

       return _totalSupply;

   }



    function balanceOf(address _owner) public view  override returns (uint256 balance){

return tokenBalances[_owner];



    }

   function transfer(address _to, uint256 _value) public override  returns (bool success)

{

require(tokenBalances[msg.sender] >=_value,'insufficient token');

tokenBalances[msg.sender]-=_value;

tokenBalances[_to]+=_value;

emit Transfer (msg.sender,_to,_value);

return true;





}

   function transferFrom(address _from, address _to, uint256 _value) public override  returns (bool success)

   {

        uint256 allowedBal=allowed[_from][msg.sender];

        require(allowedBal>=_value,'insufficient balance');

        tokenBalances[_from]-=_value;

        tokenBalances[_to]+=_value;

        emit Transfer(_from,_to,_value);

        return true;







   }

   function approve(address _spender, uint256 _value) public override returns (bool success){

       require(tokenBalances[msg.sender]>=_value,'insufficient token');

       allowed[msg.sender][_spender]=_value;

       emit Approval (msg.sender,_spender,_value);

       return true;

   }

    function allowance(address _owner, address _spender) public view override returns (uint256 remaining)

{

    return allowed[_owner][_spender];

}

}