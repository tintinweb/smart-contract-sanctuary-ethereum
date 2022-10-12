// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;
//importing all library belong to the project:
//chainlink library to get the dynamic data from off-chain world to make this contract  connected with outside world
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
//library priceConverter contract to convert funded ETH to most recent USD value.
import "./PriceConverter.sol";
// error function 
error NotOwner();

/**@title a sample fundraising contract 
 * @author Md Istiak Hussain
 * @notice this contract is for creating a sample funding contract which is directed by patrick kolins in freeCodeCamp Blockchain tutorial
 */

contract FundMe {
    //using the imported "priceConverter" library inside the "FundMe" contract which returs unsigned256 bytes integer value 
    using PriceConverter for uint256;
    // storage variable 
    mapping(address => uint256) private s_addressToAmountFunded;
    address[] private s_funders;
    //global variable
    address private /* immutable */ i_Owner;
    //setup minimum fund to be funded 
    uint256 public constant/** constant variable for gas consumption */ MINIMUM_USD = 50 * 10 ** 18;
    // for getting dynamic dataFeed via chainlink
    AggregatorV3Interface private s_PriceFeed;
    
    //initializing the owner and important dataFeed for contract 
    constructor(address priceFeedAddress) {
        i_Owner = msg.sender; // deployer will be the owner of the contract
        s_PriceFeed = AggregatorV3Interface(priceFeedAddress); //get the priceFeed data base from chainlink
        
    }      

   // funding function to fund the contract and add the funder accounts in the funders array
    
    function fund() public payable {
        //checking the funded value is fulfilled the minimum USD requirement or not? otherwise it will return the following string as error.
        require(msg.value.getConversionRate(s_PriceFeed) >= MINIMUM_USD, "You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!"); //also you can check with  this
        
        //add the funders account and funded value in "addressToAmountFunded"  map
        s_addressToAmountFunded[msg.sender] += msg.value;
        //adding the funder in funders array
        s_funders.push(msg.sender);
    }
    
    // modifier to check the owner before calling withdraw every time for security purpose
    modifier onlyOwner {
        // require(msg.sender == owner);
        if (msg.sender != i_Owner) revert NotOwner();
        _;
    }

    /** @notice withdraw function to collecting the funded value
     */
    function withdraw() public onlyOwner {
        //looping through whoole array of funders account 
        for (uint256 funderIndex=0; funderIndex < s_funders.length; funderIndex++){
            address funder = s_funders[funderIndex];
            //null the funder's funded balance
            s_addressToAmountFunded[funder] = 0;
        }
        //nulll the whole funders array
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }
    
    /** @notice cheaper withdraw function to consumption gas cost in using contract
     */
    function cheapWithdraw() public onlyOwner {
        //looping through whoole array of funders account 
        //creating a instance of funders array (storage variable)
         address[] memory funders = s_funders;
        for (uint256 funderIndex=0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];
            //null the funder's funded balance
            s_addressToAmountFunded[funder] = 0;
        }
        //nulll the whole funders array
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }


    
    // Explainer from: https://solidity-by-example.org/fallback/
    // Ether is sent to contract
    //      is msg.data empty?
    //          /   \ 
    //         yes  no
    //         /     \
    //    receive()?  fallback() 
    //     /   \ 
    //   yes   no
    //  /        \
    //receive()  fallback()

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
    
    // get function list of storage variable to make it public when need these from outside
    function getAddressToAmountFunded(address funderAddress)public view returns(uint256){
            return s_addressToAmountFunded[funderAddress];
    }
    
     function getFunders(uint index)public view returns(address){
            return s_funders[index];
    }
    function getOwner()public view returns(address){
            return i_Owner;
    }
    function getPriceFeed()public view returns(AggregatorV3Interface){
            return s_PriceFeed;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    //passing the priceFeed address as parameter of getPrice function
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Goerli ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        //it is the manual way to defined priceFeed address for definite network
        // AggregatorV3Interface priceFeed = AggregatorV3Interface("priceFeedAdress for this network")
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    /**@notice getConversionRate function to compare ETH with USD using dynamic data feed of chainlink
     * @param ethAmount (funded eth amount) & priceFeed (priceFeed address to get latest ETH price in USD)
     * @return ethAmountInUSD get the funded ETH amount in USD
     */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUSD = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUSD;
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