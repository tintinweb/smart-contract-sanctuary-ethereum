/**
 *Submitted for verification at Etherscan.io on 2023-03-06
*/

pragma solidity ^0.6.1;

contract diceBet{
    //execution costs are written on top of the functions.
    //gas value of constructing this contract is: 950082  

    /*mapping is safer since you need an address to get the data, 
    also it should be private since we don't want anyone to use it 
    even the other contracts, to be safe.
    */
    mapping(address=>player)private Players;

    /* we are going to use contract's address to be able to withdraw 
    and deposit money whenever asked
    */
    address nftAddress = address(this);
    address payable _wallet = address(uint160(nftAddress));
    
    constructor() public payable{
    //constructor only initaliazises
        House=house(_wallet,_wallet.balance,msg.sender);
    }
    
    struct player{
        /*player have bet( can change the amount if asked),
        age and name as it is desired,
        balance need to be safe as much as we can,
        isLogged decides if player is logged before.
        */
        uint bet;
        string name;
        uint256 balance;
        uint8 age;
        bool isLogged;
    }
    
    struct house{
        /*house hass contract's address,
        it's own address ,to decide if it is house
        and balance of the contract.
        */
        address payable wallet;
        uint256 balance;
        address payable  HouseAddress;
    }
    
    /*timeRestriction is implemented to prevent DDos attacks, such as Reentrancy.
    every process need to be 2 second separeted
    we are gonna use it on every payable function.
    Note that: in payable functions this requirment has priorty to reduce gas cleverly, for mistaken usages or even spamming.
    */
    uint256 timeRestriction=block.timestamp+2;
    
    //House is contract's constructor/owner
    house House;
    
    //event informs the chain about transactions 
    event LogDepositMade(address indexed accountAddress, uint amount);

    
    function isWin() private view returns (bool) {
        /*gets random number from block's identifiers and timeRestriction as private identifier 
        and hash it with keccak256, then divides it to 6.
        this function can be effected by miner but it is as random as possible to have secured game.
        */
        return ((uint256(keccak256(abi.encodePacked(block.timestamp*block.difficulty*block.number*timeRestriction+1)))%6+1)>=4);
    }

    //gas for user :49113 
    //note that: user can access this function once and house can not
    function login(string memory  _name, uint8 _age) public {
        /*
        this function get's player's desired properties and creates account.
        If user doesn't have an account; can not deposit/withdraw Money or Roll Dice.
        House can not use this function to prevent unrequired gas usage.
        can not submit a name more then 32 chars to prevent gas usage spam for user.
        can not submit a name with 0 chars to prevent mistakenly created accounts, since name and age is not changable.
        */
    require(Players[msg.sender].isLogged==false && msg.sender!=House.HouseAddress) ;//infinite gas
    require(bytes(_name).length<=32 && bytes(_name).length>0);
         Players[msg.sender]=player(
            {
                /*create player with mesage's properties.
                bet is 0 as initial and it needs user to deposit money.
                isLogged is true since we are sure we are with 
                */
                bet:0,
                balance:Players[msg.sender].balance,
                age: _age,
                name: _name,
                isLogged: true
            }
        );
    }
    
    //cost as gas: 26137 
    function RollDice()public {
        /*
        to roll a dice player need to be logged.
        House can not roll a dice as it is unreasonable and can be caused by mistake.
        bet  need to be >0 to prevent overflows, but we checked it via putBet.
        player and house need that money to play the game.
        */
        require(timeRestriction<=block.timestamp);
        timeRestriction=block.timestamp+2;
        require(Players[msg.sender].isLogged==true && msg.sender!=House.HouseAddress);
        require(Players[msg.sender].balance>=Players[msg.sender].bet && House.balance>=Players[msg.sender].bet) ;

        if(isWin()){
                Players[msg.sender].balance+=Players[msg.sender].bet;
                House.balance-=Players[msg.sender].bet;
            }
        else{
                Players[msg.sender].balance-=Players[msg.sender].bet;
                House.balance+=Players[msg.sender].bet;
        }
    }
    
    //cost as gas: first->24919 change->5719;
    function putBet(uint  _betAsWei) public {
        /*
        player need to be logged in of course,
        and house can not reach this function to prevent unreasonable mistakes.
        bet can be max 0.1 ether
        bet needs to be more than 0 : to prevent overflows! :
        if user inputs -1 we can give him all of our money! We dont want this.
        timeRestriction is necessary to prevent DDos attacks.
         */
        require(Players[msg.sender].isLogged==true && msg.sender!=House.HouseAddress);
        require(_betAsWei<=100000000000000000) ;
        require(_betAsWei>0);
        require(Players[msg.sender].balance>=_betAsWei && House.balance>=_betAsWei) ;
        require(timeRestriction<=block.timestamp);
        Players[msg.sender].bet=_betAsWei;
    }
    
    //for house first->31060  , then-> 16060  ; for player first-> 30275  , then->15275 
    function depositMoney() public payable{
        /*
        player need to be logged in of course or can be house.
        timeRestriction is necessary to prevent DDos attacks.
        firstly: if mesage is 0 prevent extra gas consumptions.
        */
        require(timeRestriction<=block.timestamp);
        timeRestriction=block.timestamp+2;
        require(msg.value>0);
        require(Players[msg.sender].isLogged==true || msg.sender==House.HouseAddress);
        // informing the chain about transfer. and waiting for it to raise balance.
        
        emit LogDepositMade(msg.sender,msg.value);
        // if house gives money it goes contract's wallet.
        if(msg.sender==House.HouseAddress){
            House.balance+=msg.value;
        }
        // if player gives money it goes player's wallet.
        else{ 
            Players[msg.sender].balance+= msg.value;
        }
    }

    //cost as gas: for house->26255; for player-> 24716  .
    function withdrawMoney(uint _wei)public payable{
        /*
        money gets as wei.
        user can be player or house.
        timeRestriction is necessary.
        firstly: if mesage is 0 prevent extra gas consumptions.
        */
        require(timeRestriction<=block.timestamp);
        timeRestriction=block.timestamp+2;
        require(_wei>0);
        require(Players[msg.sender].isLogged==true || msg.sender==House.HouseAddress);

        if(msg.sender==House.HouseAddress){
            /*
            first check if house have that money in our contract, 
            then reduce balance: mistakes are not our problem in this case
            since any bug can happen, but we need to secure our contract.
            */
            require(_wei<=House.balance);
            House.balance-=_wei;
            //inform the chain about transaction, then transfer.
            emit LogDepositMade(House.wallet,msg.value);
            House.HouseAddress.transfer(_wei);
        }
        else{
            /*
            first check if player have that money in our contract, 
            then reduce balance: mistakes are not our problem in this case
            since any bug can happen; but we need to secure our contract.
            */
            require(_wei<=Players[msg.sender].balance);
            Players[msg.sender].balance-=_wei;
            emit LogDepositMade(House.wallet,msg.value);
            msg.sender.transfer(_wei);
        }
    }
    
    //gas: 0 since it is view but cost is :: 1887 :: if called by contract.
    function getBalance() public view returns(uint256) {
        /*
        useful function to just see our money in the contract
        */
        
        if(msg.sender==House.HouseAddress){ 
            return House.balance;
        }
        else{return Players[msg.sender].balance;}
    }
}