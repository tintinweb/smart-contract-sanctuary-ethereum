// SPDX-License-Identifier: MIT
//Style Guide for Solidiyt
//Pragma
//Import
//Error Codes
//contracts
//modifiers
//revcieve and fallback
//functions



pragma solidity >=0.7.0 <0.9.0;

//Send Eth or blockchain native token to this contract 
//Get funds from users
//Withdraw funds
//set mim value in USD 
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

//best practice to put contractName + error code
error FunMe_Owner();


/**@title A contract for crowd funding 
 *@author Sydney Sanders
 @notice This contract is to demo a funding contract 
 @dev ths implements price feeds as our library 


 */


contract Fundme { 
    //Type declerations
    using PriceConverter for uint256;


    //State variables
    mapping(address => uint256) private s_addressToAmountFunded; 
    //Keep track of who is funding the contract:  
    address[]private s_funders; 
    uint256 public constant  MIN_USD = 50 * 10 ** 18;
    //owner doesnt have to be public 
    address private immutable i_owner; 
    AggregatorV3Interface private s_priceFeed;

    event Funded(address indexed from, uint256 amount); 

     modifier onlyOwner { 
        // require(msg.sender == i_owner, "Sender is not owner!");
         if(msg.sender != i_owner) {revert FunMe_Owner();}
        _;
    }
    //Function that gets called, Immeditaley when you call an contract 
    constructor(address priceFeedAdderss) { 
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAdderss); //s_ == we are spending lots of gas to store this
    }


    receive() external payable{}
    fallback() external payable{}


    function fund() public payable { 
        require(msg.value.getConverstionRate(s_priceFeed) >= MIN_USD,"Didn't send enough" );
        //Keep track of donators to contract address
        s_funders.push(msg.sender); 
        s_addressToAmountFunded[msg.sender] += msg.value;
        emit Funded(msg.sender, msg.value);
    }


    function withdraw()  public onlyOwner {
        //very expensive function -> reading from storage and updating from storage
        for(uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) { 
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the array 
         s_funders = new address[](0);
        //actually withdraw the funds
        
        //3 different ways to send ETH
        //transfer send call 
        
        //cast it to an payable address 
        //Auto reverts if transfer failes
        payable(msg.sender).transfer(address(this).balance); //Natie blockchain currency 

        //send only revert if we add the sendSuccess require
        bool sendSuccess = payable(msg.sender).send(address(this).balance);
        require(sendSuccess, "Send failed");

        //call most common way of sending 
        (bool callSuccess,) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");

    }

    function cheaperWithdraw() public payable onlyOwner  { 
        //saved our storage var into a memory var -> get much much cheaper 
        address[] memory funders = s_funders; 
        //mappings can't be in memory!
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++) { 
            address funder = funders[funderIndex]; //we are using the memory array
            s_addressToAmountFunded[funder] = 0;

        }

        s_funders = new address[](0);
        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);




    }



    //Be carefully how to interact with storage variables + chaging visiblity improves gas
    function getOwner() public view returns(address) { 
        return i_owner;
    }
    function getFunders(uint256 index) public view returns(address) { 
       return s_funders[index];
   }

    function getAddressToAmountFunded(address funder) public view returns(uint256) { 
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) { 
        return s_priceFeed;
    }




}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter { 
    //Can't have state vars
    //Can't send ether 

     //get the converion rate of ETH in terms of USD 
    function getPrice(AggregatorV3Interface priceFeed)   internal view returns(uint256) { 
         //call the latestround data on the price feed
         //All we want is the latest price
         (, int256 price, , , ) = priceFeed.latestRoundData();    
         //Eth in terms of USD
         return uint256(price * 1e10); //1*10 = 1000000000
    }

    function getVersion()   internal view returns(uint256) { 
        //ABI
        //ADDRESS 	0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version(); 
    }

    function getConverstionRate(uint256 ethAmount, AggregatorV3Interface priceFeed )  internal view returns (uint256) { 
        uint256 ethPrice = getPrice(priceFeed); //call get price for price of ETH 
        uint256 ethAmountinUSD = (ethPrice * ethAmount) / 10**18;  //Math in solidity always multiply then divide
        return ethAmountinUSD;

    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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