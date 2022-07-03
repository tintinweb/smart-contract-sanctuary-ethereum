// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// get funds from users
// withdraw funds 
// set a minimum fund values in USD

// importing libraries 
import "./PriceConverter.sol";

error NotOwner();

contract FundMe{   
    // the .sol works for uint256 input data -> msg.value is uint256 so it can be called into the PriceConverter.sol library
    using PriceConverter for uint256; 
    // setting up global variables 
    // -> works but not very gas efficient => uint256 public minimumUSD = 1 * 1e18; // 18 after the number
    // AIM: reduce gas cost
    // -- using constants --> makes a huge difference in gas cost
    uint256 public constant MINIMUM_USD = 1 * 1e18; // with constant we reduce 19e+3 wei gas 
    
    // tracking addresses that fund the project 
    address[] public funders; 
    mapping(address => uint256) public addressToAmounFunded;

    // setting up owner address variable 
    address public immutable i_owner; // immutable saves gas and it allows to set the value of a variable just once
    // usually immutable variables are called with i_* -> this because solidity stores directly in the code of the contract and not in a byte allocation

    AggregatorV3Interface public priceFeed;

    // constructor in solidity -> function that is called when i deploy a contract 
    // tells in this case who the owenr actually is 
    constructor(address priceFeedAddress){
        i_owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // public allows everyone to call this function
    function fund() public payable {
        // payable -> allows transfering eth
        
        // require is a condition
        // msg stands for message 
        require(msg.value.getConversionRate(priceFeed) >= MINIMUM_USD, "The value is not enough!"); 
        // reverts -> stops the operation and from now on, if the require is not fullfilled -> sends ther remaining value bac
        funders.push(msg.sender); // stores the address of the sender to the funders array
        addressToAmounFunded[msg.sender] = msg.value; // maps the amount from each sender to a mapping array
    }

    function withdraw() public onlyOwner {
        // requiring the the address that is withdrawing the funds is the actuall owner of the contract -> set up at the deployment of the contract 
        // 1 option -> require(msg.sender == owner, "The calling address is not the owner");

        // loop generation
        // for starting index -> ending index -> step amount 
        for(uint256 funderIndex = 0; funderIndex < funders.length; funderIndex = funderIndex + 1){
            address funder = funders[funderIndex];
            addressToAmounFunded[funder] = 0;
        }    

        // reset the array 
        funders = new address[](0); // completely blank new array with 1 element (0+1)

        // withdraw the funds -> 3 ways 
        // 1) transfer 
        // msg.sender = address 
        // payable(msg.sender) = payable address 
        //payable(msg.sender).transfer(address(this).balance); // -> returns error if the transfer is not alright
        
        // 2) send 
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "Error in sending"); // it only reverts the transcaction if require command is called -> need to test the send command 

        // 3) call 
        // call("") means that we want to call this function but with no name
        (bool callSuccess, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(callSuccess, "Call failed");
    }

    modifier onlyOwner {
        // !!! the strings in solidity have a cost 
        // require(msg.sender == i_owner, "The calling address does not match the contract deployer");
        if(msg.sender != i_owner) // more gas efficient with an if statement -> not saving the string in the solidity code  
            {revert NotOwner();} 
        _; // _; represents the rest of the code when onlyOwner is called 
    }

    // what happends if someone sends this contract eth without calling the fund function
    // function to prevent this 
    // 1) reveive 
    // 2) fallback 
    
    // try to:
    // if someone sends to us money, we'll keep transaction and elaborate it --> this happens if the user does not interact correctly with the fund() function
    receive() external payable{ // if someone doesn't call the fund() function but sends money -> receive calls automatically the fund() function 
        fund();
    }   

    fallback() external payable{// if someone doesn't call the fund() function but sends money with calldata -> receive calls automatically the fund() function 
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// getting ABI for the chainlink interaction
// @chainlink automatically points to the npm package manager
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol"; // = to point to a code in github.com

library PriceConverter {
    // we need to convert the input value to USD
    // conversion of eth to USD -> we need to check the crypto market
    // contact an oracle -> chainlink
    // interact with the real world
    // calling https is not allowable because it's decentralized network -> need to rely on a decentralized new system
    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // eth price in terms of USD -> decimals places = 8 by default check source code at @chainlink/contracts
        // conver
        return uint256(price * 1e10);
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // conversion of eht in USD
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        return ethAmountInUsd;
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