/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// File contracts/MockUSDT.sol

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract MockUSDT
{
//state variables
 string private name;
 string private symbol;
 address private owner;
 uint256 public totalSupply;
 uint256 public buyPrice;
//map address to balance
 mapping (address=>uint256) public balances;
 mapping (address=>mapping(address=>uint256))public allowance;

//evm record
 event Trans(address _from, address _to, uint256 _amount );
 event Approv(address _from, address _to, uint256 _amount);
     //initialize contract supply, owner, name and symbol
     constructor()
     {
         name = "MockUSDT";
         symbol ="MUSDT";
         totalSupply = 1000*10**18;
         balances[msg.sender] = totalSupply;
         owner = msg.sender;
         buyPrice = 2000;

     }

     function transfer(address _to, uint256 _amount)public returns(bool)
     {
         //sender must have sufficient balance
         require (balances[msg.sender] >= (_amount*10**18),"Insufficient balance");
         uint256 amount = (_amount*10**18);
       //debit sender credit reciever
         balances[msg.sender] -= amount ;
         balances[_to]+= amount;
         emit Trans (msg.sender, _to, _amount);
         return true;
     }

     function approve(address _spender, uint256 _amount)public returns(bool)
     {
         //allow a spender spend from your balance
         allowance[msg.sender][_spender]= _amount;
         //evm log
         emit Approv(msg.sender,_spender,_amount);
         return true;
     }
     function transferFrom(address _from, address _to, uint256 _amount)public returns(bool)
     {
         //ensure sufficient balance of owner and spender is allowed to spend inputed amount
         require(balanceOf(_from)>= (_amount*10**18), "insufficient balance");
         require(_amount<= allowance[_from][msg.sender],"amount not allowed,use the aprove function to approve an address and spending amount");
         //debit spender allowance and owner balance, credit reciever
         balances[_from] -= _amount*10**18;
         allowance[_from][msg.sender] -=_amount*10**18;
         balances[_to] += _amount*10*18;
         //evm log
         emit Trans(_from, _to, _amount);
         return true;

     }

     function balanceOf(address _addr) public view returns(uint256)
     {
        // consol.log("This address has ", balances[_addr]);
         return balances[_addr];
     }
     function mintMUSDT(uint256 _amount)public returns(bool)
     {
         //ensure only owner of contract can use this function
         require(msg.sender ==  owner, "You are not authorized to use this function");
         uint256 amount = _amount*10**18;
         //increment supply
         totalSupply += amount;
         //mint tokens to owners address
         balances[msg.sender]+= amount*10**18;
         return true;
     }

      function buyMUSDT()public payable returns(string memory)
      {
          //return "send eth to recieve MUSDT, 1 eth costs 2000Musdt";
          uint256 bought;
          balances[msg.sender] += bought = ((msg.value)*buyPrice);
          totalSupply += bought;
          //add supply increment
          return "Recieved";
      }

      function modifyTokenBuyPrice(uint256 _price)public returns(string memory, uint256, string memory)
      {
          //ensure only owner can peform function
          require(msg.sender== owner," only owner can use this function");
          //change price state variable
          buyPrice = _price;
          return("Buy price has been changed to ", _price, " per Ether");
      }
}


// File contracts/DitoUSD.sol

pragma solidity ^0.8.0;

contract DitoUSD{

    string public Name = "DitoUSD";
    string public Symbol ="DUSD";
    address private Owner;
    uint256 public DtotalSupply;
    //mapp address and their balance
    mapping (address=>uint256) Dbalances;

    //initiallize variables and assign supply to owner
     constructor ()
     {
         DtotalSupply = (1000000*10**18);
         Dbalances[msg.sender] = DtotalSupply;
         Owner = msg.sender;


     }

     function mintDUSD(address _addr,uint _amount)public
     {
         uint256 amount = (_amount*10**18);
         require (msg.sender == Owner, "No Permission to use this function");
         DtotalSupply += amount;
         Dbalances[_addr]+= amount;
     }

     //can only be called by DitoFarm to pay rewards
     function reward(address _to, uint256 _amount)internal
     {
         uint256 amount = (_amount*10**18);
         Dbalances[_to] += amount;
     }

     function Dtransfer(address _addr, uint _amount )public returns(bool)
     {
         //check for sufficient balance of user
         require (Dbalances[msg.sender] >= (_amount*10**18), "Insufficient Balance");
         uint256 amount = (_amount*10**18);
         //debit sender and credit reciever
         Dbalances[ msg.sender ]-= amount ;
         Dbalances[ _addr ]+= amount ;
         return true;

     }

     function DbalanceOf(address _addr)public view returns(uint256)
     {
         //show balance of address
         return Dbalances[_addr];
     }

}


// File contracts/DitoFarm.sol

pragma solidity ^0.8.0;
contract DitoFarm is MockUSDT, DitoUSD

{

  address public owner;
  //dynamic array to store people that have staked
  address [] public staker;
  //map user to amount staked
  mapping (address => uint256) public stakedToken;
  //map user stacking status
  mapping (address => bool) public hasStaked;
  //map user to his reward
  mapping (address => uint256) public reward;
  //map user to block time
  mapping (address => uint256) private timestamp;

  //initiallize contract owner

    constructor ()
    {
        owner = msg.sender;

    }

    function Stake(uint256 _amount)public returns(string memory)
    {
        //must have balance to stake
        require( MockUSDT.balances[msg.sender] >= (_amount*10**18), "Insufficient MUSDT");
        //call MockUSDT contract to peform transfer
         MockUSDT.transferFrom(msg.sender, address(this), _amount);
         //record users timestamp add 7 days
         timestamp[msg.sender] = block.timestamp + 7 days;
         //record staked tokens
         stakedToken[msg.sender] += _amount*10**18;
         //record rewards, 1%
         reward[msg.sender] += (_amount/100);

         //if havent staked before add user to staker array
         if (!hasStaked[msg.sender])
         {
             staker.push(msg.sender);
         }

         hasStaked[msg.sender]=true;
         return "staked";

    }

    function unstake()public returns(string memory)
    {
        //ensure user has a stake
        require(stakedToken[msg.sender] > 0,"you dont have a stake");
        //require that the user staking status is true
        require(hasStaked[msg.sender]==true,"you dont have a stake");
        //change staking state to false
        hasStaked[msg.sender] = false;
        //return stake
        MockUSDT.transfer( msg.sender, stakedToken[msg.sender]);

        //reset staked balance to 0
        stakedToken[msg.sender] = 0;
        return "unstaked";

    }

    function collectReward()public returns(string memory, uint256, string memory)
    {
        //ensure 7 days has elapsed since last staking day
        require(block.timestamp >= timestamp[msg.sender],"Vesting period has not ended");
        //ensure they have staking reward
        require(reward[msg.sender] >= 0,"you dont have any rewards");
        uint256 dito = reward[msg.sender];
        //reset reward to 0
        reward[msg.sender]=0;
        //transfer reward to user
        DitoUSD.reward(msg.sender,dito);
        return ("you have Claimed ", dito , "DUSD");
    }

}