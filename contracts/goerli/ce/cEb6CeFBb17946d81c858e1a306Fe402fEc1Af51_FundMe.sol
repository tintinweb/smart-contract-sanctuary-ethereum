//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// Our goal :  ( For each goal we make each function )
// Get funds from users
// Withdraw funds
// Set a minimum funding value in USD

// interface AggregatorV3Interface {
//   function decimals() external view returns (uint8);

//   function description() external view returns (string memory);

//   function version() external view returns (uint256);

//   function getRoundData(uint80 _roundId)
//     external
//     view
//     returns (
//       uint80 roundId,                                                // We can simply copy the code of interfaces and paste it in our code.
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );

//   function latestRoundData()
//     external
//     view
//     returns (
//       uint80 roundId,
//       int256 answer,
//       uint256 startedAt,
//       uint256 updatedAt,
//       uint80 answeredInRound
//     );
// }

/** In hardhat we have to tell specifically where from we are getting it,
we will get it from yarn add --dev @chainlink/contracts */


// Or we can easily import it from Github, it is the path of the repository where the code is situated.
//import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";   

import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe{

   using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 0;   // created a public variable, constant keyword makes contract gas efficient.

    // Creating an address array of funders.
    address[] private funders;
    // Mapping of addresses of funders
    mapping(address => uint256) private addressToAmountFunded;

    // NOW WE WANT ONLY THE OWNER OF THIS CONTRACT CAN WITHDRAW ALL FUNDS, TO DO THAT WE WILL HAVE TO FIX WHO IS THE OWNER OF THIS CONTRACT.


    address private owner;

    AggregatorV3Interface private priceFeed;      // making a global variable, AggregatorV3Interface type.
    
    constructor (address priceFeedAddress){  // constructor is the function in  a contract which immediately gets called whenever a contract is deployed, we will use this 
    // constructor to set who is the owner of this contract is.

        owner = msg.sender; //msg.sender holds the address who called the constructor() and this address is set is the owner variable.

        priceFeed = AggregatorV3Interface(priceFeedAddress);

    }


    function fund() public payable {          // public because we want anyone can call this function
    //  We have to make this function payable so that user can send fund, for that we use 'payable' keyword, payable functions are Red button.******
    //Just like our wallet can hold funds, contract addresses can hold funds as well, since every time we deploy contract, they get a contract address,
    // its nearly the exact same as wallet address, so both wallet and contract can hold native blockchain token like etherium.

        // getConversionRate of msg.value 
        // From PriceConverter.sol the getConversionRate() will pass a parameter and it is expecting a variable here, but it is not the case in
        // solidity, because here msg.value is considered first parameter in any of these library functions.
       require((msg.value.getConversionRate(priceFeed)) >= MINIMUM_USD, "Didn't send minimum limit amount");
        //require(getConversionRate(msg.value) >= MINIMUM_USD, "Didn't send minimum limit amount"); // To get the 'value' attribute. We use msg.value to get how much value someone is sending. Here with using require 
    // function we are fixing the amount a user can send, which is atleast more than 1 eth. If msg.value is not > 1e18 then it will revert with an error message.
    // Here first we will have to convert from eth to USD to get the comparison.
    // Here msg.value is 18 decimal places, because in remix we are giving value in Wei unit, so 1 eth = 1000000000000000000 wei************

        funders.push(msg.sender);   // Here msg.sender is a global inbuilt variable which gets the address of funders
        addressToAmountFunded[msg.sender] += msg.value;
    }





    // COPIED ON priceConverter.sol, uncomment codes between /* */ to run without library, as before


    

    // function getPrice() public view returns(uint256) {      // To get the price of eth in terms of USD we use chainlink data feeds, here we have to interact with such contracts which is out side of our project, so we
    // // are gonna need ABI and address.
    // // address = 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e For ETH/USD in Goerli
    // // To get the ABI we previously imported a whole contract in our contract, we will get it through a concept of INTERFACE

    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);    // Here we are assuming contract
    //     // in this address will have all the functionality of AggregatorV3Interface, means it will have all properties of AggregatorV3Interface.
    // // Combination of AggregatorV3Interface(address) gives us AggregatorV3 contract with whatever code is at the address.

    //     // WE ARE KEPPING COMMA HERE BEACAUSE WE WANT TO TELL SOLIDITY THANT WE KNOW THE FUNCTION RETURNS FEW VARIABLE BUT WE ONLY CARE ABOUT ONE.
    //     (
    //   /*uint80 roundId*/,      
    //   int256 answer,                  // ETH in terms of USD, it is around 3000, but we will assume with 8 decimal place, means 3000.00000000
    //   /*uint256 startedAt*/,          // so we will have to add 10 decimal more, see at line 85
    //   /*uint256 updatedAt*/,
    //   /*uint80 answeredInRound*/
    //     )= priceFeed.latestRoundData();  // latestRoundData() does not return 1 variable, it will return whole bunch of variable
    //     // mentioned in the interface.

    //     // Returning + typecasting into uint
    //     return uint(answer*1e10);       // Here we are multiplying with 1e10/10 decimal place because the value of answer variable will be 8 decimal 
    //     // place, so to balance with all value we are making it 18 decimal place.
    // }

    // function getVersion() public view returns(uint256){
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);  // Getting the contract in priceFeed variable
    //     return priceFeed.version();   // returning the versionof the contract
    // }

    // function getConversionRate(uint256 ethAmount) public view returns(uint256){

    //     uint256 ethPrice = getPrice();
    //     uint256 ethAmountInUsd = (ethPrice*ethAmount)/1e18;     //  In my calculation time ethPrice = 1310682600000000000000 / 1310 USD
    //     return ethAmountInUsd;                                  // So, (ethPrice*ethAmount)/18 decimal place to get exact USD value without decimal
    // }                                                          // places.







    // To withdraw 

    // withdraw button is orange because we are not gonna paying any etherium.
    function withdraw() public onlyOwner {        // created a function to withdraw all eth from funders

        //require(msg.sender == owner,"sender is not owner");    // It will check the caller of this function is owner or not.

        for (uint256 i=0; i<funders.length; i++){

            address funder = funders[i];    // getting all funder's address from funders array

            addressToAmountFunded[funder]=0;
        }
        // Still we actually did not withdraw amounts.

    
    // After resetting the fund to 0 instead of looping through array and deleting funders we are going to create a brand new array with 0 element
    // inside it.

        funders = new address[](0); 


    // Actually withdrawal

    // To send ether or native blockchain there are 3 different ways.

    // 1. Transfer
    // Here we are wrapping the address which we want to send the payment in with payable, then we do .transfer and then we say exactly how much
    // we want to transfer.
   // payable(msg.sender).transfer(address(this).balance);   // address(this).balance gives us balance of our contract, this => refers to this whole contract
    // Here we are typecasting the msg.sender from address to payable address. In solidity to send native blockchain token like etherium we can 
    // only work with payable.


    // 2. Send

    // 3. Call   => recommended

        (bool callSuccess,)=payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess,"call failed");


    }   

    // function cheaperWithdraw() public payable onlyOwner{
    //     address[] memory funders = funders;                // this is memory type array, not storage type, so it will cost good amount of less gas 
    //     // We can add array into memory but can't add mapping into memory.
    //     for (uint256 i=0; i<funders.length; i++){
    //         address funder = funders[i];
    //         addressToAmountFunded[funder]=0;
    //     }

    //     funders = new address[](0);

    //     (bool success,)=owner.call{value: address(this).balance}("");
    //     require(success);

    // }

    // mentioning modifier in a function will say that look first( depends on where the _ is situated ), there are something.
    modifier onlyOwner {         // look at line 135.
        // require(msg.sender == owner, "Sender is not owner!");
        // _;  // _ means then do rest of the code 
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    // We are adding some more functionality in case if someone want to send money without calling fund().

    // Users who wants to directly to the address from metamask or similar application, not from application.

    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }
}


// we use constant and immutable keyword on such variable whose value is not changed.**************

//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol" ; 

library PriceConverter{
    function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint256) {      

        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);   // after  passing parameter in getPrice() we dont need this line
        (
      /*uint80 roundId*/,
      int256 answer,                  
      /*uint256 startedAt*/,          
      /*uint256 updatedAt*/,
      /*uint80 answeredInRound*/
        )= priceFeed.latestRoundData();  
        return uint(answer*1e10);       
    }

    function getVersion() internal view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);  
        return priceFeed.version();   
    }

    function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns(uint256){

        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice*ethAmount)/1e18;     
        return ethAmountInUsd;                                  
    }                                  
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}