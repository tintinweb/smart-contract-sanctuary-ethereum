/**
 *Submitted for verification at Etherscan.io on 2022-11-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

            //-->declaration of a contract named my token.
contract MyToken { 
  // total supply of token
 
            //--> declares the fixed total supply of 1milion for the sake of example
  uint256 constant supply = 1000000; 

  // event to be emitted on transfer

              //--> in the event of transfer we ask for the address of the the account which money will be withdrawn, 
              //-->the address of the receiver which money will be sent to 
              //-->and finally specifies the amount of tokens that we are going to transfer.
  event Transfer(address indexed _from, address indexed _to, uint256 _value); 


  // event to be emitted on approval
  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );

  // TODO: create mapping for balances
         //-->by me: it is public bcs wee need it to be seen by everyone
         //--> mapping acts like a dictionary where you store data in terms of key value pairs.
         //-->mapping(key => value) <access specifier> <name>; ---> fadazome ine address kai amount pou exi mesa to address
  mapping(address => uint256) public balances;


  // TODO: create mapping for allowances
            //-->allow people spend on your behalf from your address, to other people.
            //-->why do we have the nesteed map? 

            //-->in the allownces case you have three participents one who owns, receiver,msg sender.
            //--> msg sender trasfrers the money on behald of the owner to the receiver
            //-->the allowance will come afterwords, there is a function called the approval.

            //-->first address is the address of the asset owner.

            //imagine you spending your parenrs money and sending it to selfridges. parents owner, you msg sender, selfridges receiver.
            
            
            //who evver is broadcasting the message will need gas. 
  mapping(address => mapping (address=>uint256)) public allowances;
          //--> nomizo ine les kai kani map kai lei: apo ton tade owner o tade spender mpori na axiiopiisi tosa lefta.

  constructor() {
    // TODO: set sender's balance to total supply
    // epidi ine aftos pou dimiourgi ta tokens ipo kanonikes sinthikes stin arxi exi ollo to supply. 
    //kanis set sto address to message sender na exi olo to initial supply.
    balances[msg.sender]= supply;
  }

  function totalSupply() public pure returns (uint256) {
    // TODO: return total supply
    return supply;
  }

        //--> epistrefi to amount p exi o owner mesa sto logariasmo tou.
  function balanceOf(address _owner) public view returns (uint256) {
    // TODO: return the balance of _owner
    return balances[_owner];
  }



    //--> epistrefi to poso pou dikeoute na kani spend o spender(middleman) apo ton logariasmo tou owner.

  function allowance(address _owner, address _spender)
    public
    view
    returns (uint256 remaining)
  {
    // TODO: return how much `_spender` is allowed to spend on behalf of `_owner`
    return allowances[_owner][_spender];
  }



    //--> kathorizi to poso pou mpori o spender (middleman) na axiopiisi apo ton logariasmo tou owner.
    //-->
  function approve(address _spender, uint256 _value) public returns (bool) {
    // TODO: allow `_spender` to spend `_value` on sender's behalf
    // NOTE: if an allowance already exists, it should be overwritten

        allowances[msg.sender][_spender]=_value;
        emit Approval(msg.sender, _spender, _value);// emit creates a lock into the blockchain. 
        return true; //when the function goes through it will return true, but if it does not go through it will return false
  }




//--> auto ine to transfer otan fevgoun lefta apo ton owner kai pane ston sender (NO MIIDDLE MAN ENVOLVED)

  function transfer(address _to, uint256 _value) public returns (bool) {
    // TODO: transfer `_value` tokens from sender to `_to`
    // NOTE: sender needs to have enough tokens


    //require works like the if in python . if you have the baalnce which is larger than the money you want to send.
    require(balances[msg.sender]>=_value); //-->elegxi oti to poso pou theloume na kanoume transfer iparxi mesa sto account tou sender.
    balances[msg.sender]-=_value;//--> aferi to poso tou sender apo ton sender
    balances[_to]+=_value;//--> prostheti to poso pou tha pari o receiver ston receiver
    //-->afou elegxi oti ola ine ok me ta trasfers tote kani emit:
    emit Transfer(msg.sender, _to, _value); //-->kani publish to transfer pou theloume na kanoume.
    //-->Ethereum clients (wallets or decentralized apps on the web)
    //--> can listen to these events emitted on the blockchain without much cost.
    //--> As soon as the event is emitted, the listener receives the arguments from, to, and amount, which makes it possible to track transactions.
    return true;

  }
//in the previous you only have two parties,,, transfer money to an other person
// in this function there are three parties... you transfer moeny from someone else to an other person.
//from asset owner
//to is the one who receives moeny
//msg sedner is you who is making the transfer on behalf of someone eles
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  ) public returns (bool) {
    // TODO: transfer `_value` tokens from `_from` to `_to`
    // NOTE: `_from` needs to have enough tokens and to have allowed sender to spend on his behalf

    require(balances[_from]>=_value);//--> elegxi oti ta lefta pou tha stalthoun iparxoun mesa ston logariasmo tou account holder.
    require(allowances[_from][msg.sender]>=_value); //--> Elegxoi na di oti to amoun p ginete transfer epitrepete na to kani trasnfer o middle man apo ton owner.
    balances[_from]-=_value; //-->aferounte ta lefta apo ton owner man.
    balances[_to]+=_value;//-->steli ta lefta pou aferethikan apo ton owner ston receiver
    allowances[_from][msg.sender]-=_value;//aferounte ta lefta apo to allowence tou middle man.
    emit Transfer(_from, _to, _value);
    return true;

  }





}



//to run shoud use; open terminal and write truffle test.... make sure there are no errors.