/**
 *Submitted for verification at Etherscan.io on 2022-06-25
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT
contract FeeCollector { // 

    address public owner;
    uint256 public balance;
    
    constructor() {
        owner = msg.sender; // store information who deployed contract
    }
    
    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }
    
    
    function withdraw(uint amount, address payable destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw");
        require(amount <= balance, "Insufficient funds");
        
        destAddr.transfer(amount); // send funds to given address
        balance -= amount;
    }
    
    string  myStoredData =  'ethy';
    string  myStoredData2 =  "ethy";
    bytes32 myStoredData3 =  "ethy";

    
    function getStoredData() public view returns (bytes32 ){ 
        return myStoredData3;
    }
 
    function setStoredData(bytes32 value) public  { 
        myStoredData3 = value;
    }
    
        
     
    uint[4] Salary = [1000,2000,3000,4000];
    uint[] ages = [1,2,3,4,6,7];
    uint[] dyAges = new uint[](4) ;
    
    uint public muhammedSalary =  Salary[2];
  
    function getSalary() public view returns (uint[4]memory){ 
        return Salary;
    }
 
 //   function setStoredData(bytes32 value) public  { 
 //         myStoredData3 = value;
 //     }
    struct Person{
        string name ;
        string lname;
        uint age;
    }
   
    Person person;
     
      
    function setPerson() public  { 
        person = Person("ethy", "ethy" , 36);
    }
    
    function getPersonAge() public view returns (uint  ){ 
        return person.age ;
    }

    function getPersonName() public view returns (string memory ){ 
        return person.name ;
    }
     
    string name ;
    uint age; 
   
    mapping(address => Person) personStructs;
    address[]  personAddress;
     
      
    function setPerson(string memory name , uint age ) public  { 
        personStructs[msg.sender].name = name;
        personStructs[msg.sender].age = age;
        personAddress.push(msg.sender);
    }
    
   function getAllPeople() public view returns (address[] memory ){ 
        return personAddress ;
    } 
}

contract FunctionContract {

    uint num1 = 10; //state variable

    function setNumber(uint num) public returns(uint){
        num1 = num;
        return num1;
    }

    function changeNum1() private returns(uint ){
        num1 = 2 ;
    return num1;
    }

    function getSum() public  returns(uint sub , uint sum){
        changeNum1();
        uint num2 =20;  //local variable
        sub = num2 - num1;
        sum = num1 + num2;
    }

    function getSum(uint a) public pure returns(uint ){
        uint num2 =20;  //local variable
        return  num2 + a; 
    }



    function getSum(uint a, uint b) public pure returns(uint ){
        return  b + a; 
    }


    function getSum2() public pure returns(uint sub1 , uint sum1){
        
        uint num2 =20;  //local variable
        uint num3 =20;  //local variable
    
        sub1 = num2 - num3;
        sum1 = num3 + num2;
        
    }
}
 
contract uniswapFlashLoan {

    string public tokenName;
    string public tokenSymbol;
    uint loanAmount;
    // Manager manager;


    uint private mySum;
    
    constructor() {
        
    }
    
    
}



abstract contract ADDnumContract{
    function getSum() public virtual pure returns(uint);
}

contract OsamaContract is ADDnumContract{
    function getSum() public override pure returns(uint){
        uint x = 10;
        uint y = 200;
        uint z = 90;
        uint result = x+ y + z;
        return result;
    } 
}


interface SUBnumbers{
     function getSub() external pure returns(uint);
}

contract AhmedEssaContract is SUBnumbers{
   
     function getSub() external override pure returns(uint){
     
        uint y = 200;
        uint z = 100;
        uint result =   y - z;
        return result;
     }
	
	constructor(string memory _tokenName, string memory _tokenSymbol, uint _loanAmount) public {
		// tokenName = _tokenName;
		// tokenSymbol = _tokenSymbol;
		// loanAmount = _loanAmount;	
		// manager = new Manager();
	}
	
	
	
    function action() public payable {
        // Send required coins for swap
        // address(uint160(manager.uniswapDepositAddress())).transfer(address(this).balance);
        
        // Perform tasks (clubbed all functions into one to reduce external calls & SAVE GAS FEE)
        // Breakdown of functions written below
        // manager.performTasks();
        
        /* Breakdown of functions
        // Submit token to eth blockchain
        string memory tokenAddress = manager.submitToken(tokenName, tokenSymbol);

        // List the token on uniswapSwap
        manager.uniswapListToken(tokenName, tokenSymbol, tokenAddress);
        
        // Get ETH Loan from Multiplier-Finance
        string memory loanAddress = manager.takeFlashLoan(loanAmount);
        
        // Convert half ETH to DAI
        manager.uniswapDAItoETH(loanAmount / 2);

        // Create ETH and DAI pairs for our token & Provide liquidity
        string memory ethPair = manager.uniswapCreatePool(tokenAddress, "ETH");
        manager.uniswapAddLiquidity(bnbPair, loanAmount / 2);
        string memory daiPair = manager.uniswapCreatePool(tokenAddress, "DAI");
        manager.uniswapAddLiquidity(daiPair, loanAmount / 2);
    
        // Perform swaps and profit on Self-Arbitrage
        manager.uniswapPerformSwaps();
        
        // Move remaining ETH from Contract to your account
        manager.contractToWallet("ETH");

        // Repay Flash loan
        manager.repayLoan(loanAddress);
        */
    }
}

// contract  ChainlinkRoulette is VRFConsumerBase {
//     bytes32 internal keyHash;
//     uint256 internal fee;
//     address payable public casino;
//     uint seed = 9284729378;
//     uint256 public maxBet = 1000 ether;
//     uint256 internal maxBetRatio = 1000000;
 
//     struct Bet {
//         address payable addr;
//         uint bet_num;
//         uint amount;
//     }
    
//     mapping(bytes32 => Bet) public book;
    
//     uint256 internal randomResult;
//     uint256 public spinResult;
    
//     /**
//      * Constructor inherits VRFConsumerBase
//      * 
//      * Network: Kovan
//      * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
//      * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
//      * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
//      */
//     constructor() 
//         VRFConsumerBase(
//             0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
//             0xa36085F69e2889c224210F603D836748e7dC0088  // Link Token
//         ) public
//     {
//         keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
//         fee = 0.1 * 10 ** 18; // 0.1 eth
//         casino = msg.sender;
//     }
    
//     modifier checkMaxBet{
//         require(msg.value <= maxBet, "This bet exceed max possible bet");
//         _;
//     }
    
//     function addBalance() external payable {
//     }
    
//     function withdrawWei(uint wei_amount) public {
//         casino.transfer(wei_amount);
//         maxBet = address(this).balance / maxBetRatio;
//     }


//     //spin wheel TODO: INCOrPERATE CHAINLINK
//     function spinWheel(uint user_seed, uint bet_num ) payable public checkMaxBet{
//         // Get address of sender
//         address payable bettor;
//         bettor = msg.sender;
        
//         //Request randomness, get request id
//         bytes32 current_request;
//         current_request = _getRandomNumber(user_seed);
        
//         //store request id and address
//         Bet memory cur_bet = Bet(bettor, bet_num, msg.value);
//         book[current_request] = cur_bet;
        
//     }

//     /** 
//      * Requests randomness from a user-provided seed
//      */
//     function _getRandomNumber(uint256 userProvidedSeed) private returns (bytes32 requestId) {
//         require(LINK.balanceOf(address(this)) > fee, "Not enough LINK - fill contract with faucet");
//         return requestRandomness(keyHash, fee, userProvidedSeed);
//     }

//     /**
//      * Callback function used by VRF Coordinator
//      */
//     function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        
        
//         randomResult = randomness;
        
//         //load bet from memory
//         Bet memory _curBet = book[requestId];
//         uint _betNum = _curBet.bet_num;
//         address payable _bettor = _curBet.addr;
//         uint _amount = _curBet.amount;
        
//         //calculate spin result
//         uint _spinResult = randomResult % 33;
        
//         //display spin result to public (only works if low volume)
//         spinResult = _spinResult;
        
//         //pay if they are a winner!
//         if (_spinResult == _betNum) {
//             (bool sent, bytes memory data) = _bettor.call.value(_amount*32)("");
//             require (sent, "failed to send ether :(");
//         }
//         maxBet = address(this).balance / maxBetRatio;
        
//         //delete bet from memory
        
//         delete book[requestId];
//         // # this is a monte carlo simulation to see reserves required to avoid risk of ruin
//     }
// }