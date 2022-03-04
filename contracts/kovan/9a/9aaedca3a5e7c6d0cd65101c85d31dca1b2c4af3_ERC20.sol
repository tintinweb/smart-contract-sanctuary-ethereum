/**
 *Submitted for verification at Etherscan.io on 2022-03-04
*/

// SPDX-License-Identifier: MIT
interface IERC20 {

    event log(address,address, int);

    function mint( int amount) external returns (bool);

    function transfer(address reciver,int amount) external returns (bool);

    function tranferfrom(address sender , address reciver , int amount) external returns(bool);

    function approve(address spender , int amount ) external returns(bool);

    function getAllowance(address owner , address spender ) external returns(int);
}


contract ERC20  is IERC20{
    int public totalAmount;
    mapping(address => int ) public balance;
    mapping(address => mapping(address => int)) public allowance;
    string public name = "JToken";
    address public immutable owner;
    constructor() public{
        owner = msg.sender;
    }
    
    // mint function
    function mint( int amount) public override returns(bool){
        if(msg.sender == owner){
            totalAmount += amount;
            balance[owner] += amount;
            return true;
        }else{
            return false;
        }
    }
    // check balance 
    function balanceOf(address sender) public  returns(int){
        return balance[sender];
    }
    // transfer function for owner 
    function transfer(address reciver,int amount) public override returns(bool){
        require( msg.sender == owner , "not owner");
        if(amount > balance[owner]) return false;
        balance[owner] -= amount;
        balance[reciver] += amount;
        emit log(owner,reciver, amount );
        return true;
        }
    // tranfer funds without owner 
    function tranferfrom(address sender , address reciver , int amount) public override returns(bool){
      if(balance[sender] >= amount && allowance[sender][msg.sender] >= amount){
        allowance[sender][msg.sender] -= amount;
        balance[sender] -= amount ;
        balance[reciver] += amount;
        emit log(sender,reciver, amount);
        return true;
      }else{
          return false;
      }
     
    }
    // approve function for spending 
    function approve(address spender , int amount ) public override returns(bool){
        
        allowance[msg.sender][spender] = amount;
        return true ;
    }
    // get the allownace 
    function getAllowance(address owner , address spender ) public override returns(int){
        return allowance[owner][spender] ;
    }
    //
}