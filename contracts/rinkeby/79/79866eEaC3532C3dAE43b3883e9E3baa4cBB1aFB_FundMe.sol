// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

//Import is commented out because the code was copied into this file
import "AggregatorV3Interface.sol";

//From "https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"


//Interfaces are a minimalistic view into another contract

contract FundMe{

    //A constructor is a function that is called immedtiately when you're contract is deployed
    //The most important part of this is to be able to assign the owner of the contract to that who
    //Deployed it 
   
    address public owner;

    address[] public funders;

    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public{
        priceFeed = AggregatorV3Interface(_priceFeed);

        //The msg.sender will automatically be the address that deploys the contract
        owner = msg.sender;
    } 

    mapping(address => uint256) public addressToAmountFunded;    

    //Now we have a method to fund our smart contracts
    function fund() public payable{

        //In gwei terms $50 minimum

        uint256 minimumUSD = 50 * 10 * 18;

        require(getConversionRate(msg.value) >= minimumUSD,"You need to spend more ETH!");


        //msg.sender is the sender of the function call 
        addressToAmountFunded[msg.sender] += msg.value;

        funders.push(msg.sender);

    }

    function getVersion() public view returns(uint256){

        //Again we're utilizing methods from the AggregatorV3Interface defined as an interface above 
        //Inside the AggregatorV3Interface we pass in the parameter which is the address of the 
        //This line is saying we have a contract that has all of the functions described in the interface AgV3
        //Located at the address passed into the function, this allows us to pull this data out from the contract
        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){

        //AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        
        // latestRoundData Returns 5 seperate variables but we only need 1 so we leave the other variables blank

        //(uint80 roundId,  int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound)

        (,int256 answer,,,) = priceFeed.latestRoundData();

        return uint256(answer);
    }

    function getEntranceFee() public view returns (uint256){
        //minimum usd
        uint minimumUSD = 50 * 10**18;
        uint price = getPrice();
        uint256 precision = 1* 10**18;
        return (minimumUSD * precision)/price;
    }

    function getConversionRate(uint256 ethAmount) public view returns(uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUSD = (ethPrice * ethAmount)/1000000000000000000;
        return ethAmountInUSD;
    }

    function getbalance() payable public returns(uint256){ 
        return address(this).balance;

    }

    //This function returns all of the money  in the contract 
    //From the contract to the address of the person using the function 
    function withdrawl() payable onlyOwner public{
        //msg.sender.transfer() is a built in function that allows the address interacting with the contract
        //to be transferred money
        //this: the contract that you're currently in 
        //balance: the amount of eth in the contract    

        //We don't want just anybody to be able to withdrawl funds from the contract, only the owner should be
        //Allowed to do so, so we can create a require statement.

            //require(msg.sender == owner,"Only the owner can withdrawl from the contract");

        payable(msg.sender).transfer(getbalance());

        //When we withdrawl we want to make sure the funders array is updated and all balances are 0

        for (uint256 funderIndex = 0; funderIndex < funders.length; funderIndex++){
            address funder = funders[funderIndex];

            //mapping
            addressToAmountFunded[funder] = 0;
        }

        //Now we set the funders array to a new/empty one
        funders = new address[](0);

    }

    //For a modifier always remember to add the _; on the next line to let solidity know
    modifier onlyOwner{
        require(msg.sender == owner,"Onle the owner/creator can withdrawl from the contract");
        _;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

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