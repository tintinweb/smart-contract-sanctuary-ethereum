// codes convention of solidity style
// pragma
// import
// error codes
// Interfaces, Libraries, Contracts
// Doxygen format = to document solidity code
//   /** information */

// Get funds from users
// withdraw funds
// set a minimum fundings

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// let's import the library that does the math
import "./PriceConverter.sol";

// error definition can be defined outside contract
// it helps reducing the gas cost in case of error
// as in case of error, string are called to be displayed
// and string are expensive data (because they are array)
error FundMe__NotOwner(); // convetion to use contractname__error

/** @title A contract for crowd funding
 *   @author MyName :)
 *   @notice This contract is to demo a sample funding contract
 *   @dev This implements price feeds as our library
 */
contract FundMe {
    // convention inside contract
    // Type Declarations
    // State Variables - name of variables
    // Events
    // Modifiers
    // functions
    /// constructor
    /// receive
    /// fallbacks
    /// external
    /// public
    /// internal
    /// private
    /// view / pure

    // use the library for uint data
    using PriceConverter for uint256;

    // defining a variable which is not supposd to be changed
    // as constant, help to reduce gas cost
    // contanst should be in capital
    uint256 public constant MINIMUM_USD = 50 * 1e18; // 1*10**18 due to the way that values are given in integer, so it takes into account decimals

    // array to keep a view on the funding done by different address
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded; // to map wach address to the fund given

    // variable which is not supposed to changed but not set a the time of its delaration
    // can be defined as immutable to save gas cost too
    // i_variable convention to be used
    address private immutable i_owner;

    // price feed address can be modularized in case
    // we deploy the contract on different blockchain
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == i_owner, "sender is not owner");
        // below means can proceed with the rest of the code (if require is not failing)
        // it represents basically the function code

        // below error handling allowed to not store any string (expensive to store as they are array)
        // and instead only a point to error code
        // error code to be called only in case of error
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }

        // require(msg.sender == i_owner, NotOwner()) can be used too
        _;
    }

    // contructor are functions that are called immediatly when the contract is deployed
    constructor(address priceFeedAddress) {
        /* below example, even if we set default value of minimumUsd to 50
         because the constructor is then called, minimumUsd will be 2 when we deploy the contract
        mimimunUsd = 2;
        */

        // below we force the owner of the contract to be the one who deploys it
        i_owner = msg.sender; // first and last definition

        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    // with below, if somoene send fund by mistake
    // without using the fund function
    // will still triggered fund function
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    // payable indicate the contracts holds funds, send eth, etc..
    //and get data like gas limit or value or waller address

    /**
     *  @notice This function funds the contract
     *  @dev This implements price feeds as our library
     */
    function fund() public payable {
        // as we use library PriceConverter for uint, we can then use it on value data
        // below example, value will be passed as parameter of getConversionRate for the first parameter
        //msg.value.getConversionRate() => value is the first paramater

        // we require that value is more than 1 ETH otherwise we reverse the transaction and gas fee spent for computation until now is loss
        // So it is better to put the "require" as soon as possible to limit the gas fee loss
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "Didn't send enough!"
        ); //1e18 = 1*10**18  value in wei of 1 ETH
        // add the wallet address in our array to keep track of funding
        // msg.sender is the address calling the function
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value; // add amount of value sent by sender
        //msg is a globally available viariable withing solidity
    }

    // below onlyOwner, execute first the modifier onlyOwner.
    // if failed, it will not execute the withdraw function
    function withdraw() public onlyOwner {
        // example where we require that the wallet doing the withdraw is the owner of the wallet
        // require(msg.sender == owner);

        // use for loop to lookthrough a array
        // start index, end index, step amount to add for each loop
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            // get address of each index
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset the funders to 0
        s_funders = new address[](0);
        // withdraw the funds
        // 3 ways to do it :
        // transfer
        // send
        // call

        /*
        // transfer
        // have to cast the transder as payable address, as it needs transfer funds
        // address(this).balance will send the amount to all addresses
        payable msg.sender.transfer(address(this).balance);
        // limitation of transfer is that is is limited to 2300 gas, above it throws an error
        // in that case of error, fund can be lost!!!!
*/

        /*
        // send
        bool sendSuccess = payable msg.sender.send(ddress(this).balance);
         send is limited to 2300 gas too, but returns a boolean. Can use this boolean to revert the transaction then and fund returns to sender
        require(sendSuccess, "Send failed");
*/
        // call
        // it is the first lower level of function seen.
        // does not have capped gas
        // call return 2 variables
        // (bool callSuccess, bytes memory dataReturned) = payable msg.sender.call{value.address(this).balance}("")
        // but we don't need dataReturned
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call Failed");
        // call is the recommended way
    }

    function cheaperWithdraw() public payable onlyOwner {
        // below is the way to transder storage array to a memory array
        // readin array in memory is much cheaper
        address[] memory funders = s_funders;
        // but mappings can't be in memory

        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool Success, ) = i_owner.call{value: address(this).balance}("");
        require(Success, "Call Failed");
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(address funder)
        public
        view
        returns (uint256)
    {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// here is a way to import another contract via package management (NPM)
// it will actually download the AggregatorV3Interface from the corresponding github repo
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// this is to create a library, collection of function that can you can use in different contract (make the sol file less messy)
library PriceConverter {
    // to get price data, we usually take date from an oracle. The most famous oracle is ChainLink
    // for oracle, we need to pay gas fees even for reading, as even reading is based on consensus of oracle network
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // need ABI of the oracle contract
        // address of ETH / USD is 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        /*        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419 
        );*/
        // latestRoundData() returns a bunch of data, here we select which data we really want and leave empty the others
        (, int256 price, , , ) = priceFeed.latestRoundData(); // returns ETH (wei) in terms of USD
        return uint256(price * 1e10); // this will convert from wei format to readable one (to put decimals in right place)
    }

    /*
    // simple function to check if the connection to oracle works
    function getVersion() internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
        return priceFeed.version();
    }
*/

    // function that return the eth amount in parameters in terms of USD
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        // when doing math in solidity, do multiplication first before division, otherwise
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