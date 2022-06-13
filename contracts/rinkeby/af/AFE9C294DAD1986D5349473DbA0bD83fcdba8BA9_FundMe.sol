// SPDX-License-Identifier: MIT

//use solhint for linting(running code for potential errors) solidity, eg run- yarn solhint contract/*.sol to lint it.
//eg, defining a variable w/o mentioning its view type will pose error on solhinting it

//follow solidity style guide for increasing solidity readability

pragma solidity ^0.8.8;

//need to import @chainlink/contracts library of npm using yarn add --dev @chainlink/contracts to be able to import from it
//do yarn hardhat compile

//use yarn add --dev hardhat-deploy for hardhat-deploy plugin which makes deploying contracts easier
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

//u cud also replace all requires to revert as require has an error msg attached that it stored on chain, so save gas there too if u wish
//learn about natspec and doxygen as a part of solidity styling
//solc --userdoc --devdoc contract_name.sol can form a documentation automatically using natspec using these @
//may need to download solc first
/**
 * @title A contract for crowd funding
 * @author Yukta
 * @notice This contract is a demo
 * @dev This implements price feeds as our library
 */

contract FundMe {
    //for gas optimization, read layout of state variable in storage doc
    //anything stored in Storage, costs a lot more, all global variables of contract are stored in storage
    //global bool, uint etc have their hex stores in a storage spot, storage is like an array
    //things made in function are temporary and so are in memory not storage
    //memory keyword is necessary for strings as it is essentially an array, and array takes a lot of space so just to be sure
    //memory keyword needs to be explicitly mentioned
    //constant and immutable variables do not get stored in storage
    //for a global array, length of array has its hex stored in storage, and value is added by hashing it
    //for a global map, empty space is stored in storage to identify it as map
    //in bytecode for the code we have opcodes, these are small command-like things that actually are parts of the bytecode
    //these are the things that cost gas, a list for opcodes to gas is given at github repo->cryptic->evm-opcodes
    //the opcode SLOAD and SSTORE i.e. storage load and storage store cost way too much gas, so to monitor them
    //put their names as s_blablabla to track where they are worked with, i_blababla for immutable and so on
    //withdraw function reads from storage and sets from storage in a loop, tooo expensive, so make a cheaper withdraw
    //check in github repo for this course-> contracts->examplecontract->fundmestorage u can play with storage
    //check in deploy->deploystoragefun for storage funzies->activity too for u to try
    //artifacts->build info->secondone->search opcode to get opcodes for this course

    using PriceConverter for uint256;

    mapping(address => uint256) private s_addressToAmountFunded;
    // address[] private s_funders; but s_funders is tough to read, in case we wanna publish api, so not for now, only for monitoring gas as a dev u can do this
    //private and internal cost less gas overall, so beneficial as well
    address[] private s_funders;
    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner; //as not imp info for others working with our contract, set pvt and therefore make a getter fn for it
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        // require(msg.sender == i_owner);
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _;
    }

    constructor(address priceFeedAddress) {
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
        i_owner = msg.sender;
    }

    //not imp
    /*
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }*/

    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    //can do natspec for functions also eg @notice, @dev, @param, @return etc
    function withdraw() public payable onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length; //longer the s_array, more reading more gas
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // // transfer
        // payable(msg.sender).transfer(address(this).balance);
        // // send
        // bool sendSuccess = payable(msg.sender).send(address(this).balance);
        // require(sendSuccess, "Send failed");
        // call
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
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

    function cheaperWithdraw() public payable onlyOwner {
        //we copy storage array to memory array and work on it rather
        address[] memory funders = s_funders;
        //mappings cant be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0; //no other way sadly
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    //u can run a test on this one and compare gas to withdraw normal, u observe using coinmarket that u would same some cents

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

// Concepts we didn't cover yet (will cover in later sections)
// 1. Enum
// 2. Events
// 3. Try / Catch
// 4. Function Selector
// 5. abi.encode / decode
// 6. Hash with keccak256
// 7. Yul / Assembly

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
        /* not needed anymore as we passing pricefeed address as parameter taken from fundme
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            0x8A753747A1Fa494EC906cE90E9f37563A8AF630e
        );
        */
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversion rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }
}