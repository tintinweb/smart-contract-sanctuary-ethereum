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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// This contract is modification of FundMe.sol file and its contract, so all the details are given in that file.
// In this file only the things which are getting updated are explained here.
// These updates are to reducce the gas fee.
// Intially gas fee of the contract was 868043

import "./PriceConverter.sol";
// For using custom error, declaring the error.
// For using error it is for convient to add contract name with error and it is a standard which is followed usually so command will become: error fund_project_v2__NotOwner();
error NotOwner();

// Solidity Style Guide
// This is not must to follow, but is usually convention and if violated, it will not result in anything.
// So, this is just for knowledge
// Order of layout of a solidity file
// 1.Pragma Statment 2.Import Statement and errors 3.Interface 4.Libraries 5.Contracts
// Inside each contract or interface use this order
// 1.Type decleration 2.State variable 3.Events 4.Modifiers 5.Functions
// Functions order is
// 1.constructor 2.recieve 3.fallback 4.external 5.public 6.internal 7.private 8.view/pure
// Another important styling guide is how to comment, which is followed by the natspec guide by dyoxygen and it is super useful to automatically make documentation by using command: solc --userdoc --devdoc FundMe.sol
// If we want to use comments to explain somthing use comments in this format, lets say we are commenting for our contract
/** @title A crowd funding contract
*   @author Lux Acardia(NS)
*   @notice This contract is a sample contract and may be lacking somethings, so don't use for real life project.
    @dev This implements price feed as library.
*/


// Updated gas fee of the contract is 848507
// To bring the gas cost down, two keywords are introduced which are constant keyword and immutable keyword
// constant and immutable keywords both make so that the variable can not change its value.
// constant keyword is used when you are intialzing the value, where you are declaring the variable.
// immutable keyword is used when you are only declaring the variable and intializing it at a later time.
contract fund_project_v2{
    // using library pri_con in file PriceConverter.sol
    using pri_con for uint;

    // constant keyword is used when you are intialzing the value, where you are declaring the variable.
    uint public constant min_pay = 50 * 1e18;
    // 21,415 gas - constant
    // 23,515 gas - non constant
    // 21,415 * 141000000000 = $9.058545 (At ether 3000 dollars)
    // 23,515 * 141000000000 = $9.946845 (At ether 3000 dollars)

    // Un-comment this statement to show etherium price.
    // uint public eth_curr_price = msg.value.show_pri();
    // Un-comment this statement to get converted amount from eth to unitify
    // function un_show(uint eth_amo) public view returns(uint) {
    //     uint eth_amo_usd = ((eth_curr_price * eth_amo) / 1e20);
    //     return eth_amo_usd;
    // }


    address[] public funders_address;
    mapping (address => uint) public funders_address_amount;

    // immutable keyword is used when you are only declaring the variable and intializing it at a later time.
    address public immutable owner;
    // 21,508 gas - immutable
    // 23,644 gas - non immutable

    AggregatorV3Interface public priceFeed;

    //Special function more details below
    constructor (address priceFeedAddress){
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable{
        require(msg.value.get_con_rate(priceFeed) >= min_pay, "Insufficient Value");

        funders_address.push(msg.sender);
        funders_address_amount[msg.sender] += msg.value;
    }

    function withdraw() public Owner_checker {
        //Looping
        for (uint funders_address_i; funders_address_i < funders_address.length; funders_address_i++){
            address fun_cur = funders_address[funders_address_i];
            funders_address_amount[fun_cur] = 0;
        }
        
        // Resetting the Array
        funders_address = new address[](0);

        (bool wtd_c_res,) = payable(msg.sender).call{value: address(this).balance}("");
        require(wtd_c_res, "WITHDRAW FUNDS REQUEST FAILED.");
            
    }

    // As string in require keyword takes more gas, as each character takes gas, so we are using error custom error
     modifier Owner_checker{
        // require(msg.sender == owner, "ONLY OWNER OF THIS CONTRACT CAN WITHDRAW");
        // Using custom error in require command.
        // require(msg.sender == owner, NotOwner());
        if (msg.sender != owner){
            revert NotOwner();
        }
        _;
    }

    // What happens when someone tries to send ETH to this contract without fund function.
    // To keep track of those people and also if someone calls a function, that does not exist, we use two methods.
    // recive()
    // fallback()
    // These are called special functions, and there are a number of them in solidity for example constructor is also a special function.
    // Special function don't need to have function writen with them, as solidity already know, that they are a specail function.
    // Further explanation on these two special functions is in file Rec_and_Fall_Example.sol.
    receive() external payable{
        fund();
    }

    fallback() external payable{
        fund();
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// This is a library.
// Libraries are similar to contracts, but you can't declare any state variable and you can't send ether.
// Libraries in solidity are similar to contracts that contain reusable codes. A library has functions that can be called by other contracts. Deploying a common code by creating a library reduces the gas cost.
// A library is embedded into the contract if all library functions are internal.
// Otherwise the library must be deployed and then linked before the contract is deployed.


// Importing AggregatorV3Interface
// Interfaces are often found at the top of a smart contract. They are identified using the “interface” keyword. The interface contains function signatures without the function definition implementation (implementation details are less important). You can use an interface in your contract to call functions in another contract.
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


library pri_con {

    // For details about functions see FundMe.sol file, as all the details have been commented there, regarding these functions.
    // In library all functions must be internal


    function get_pri(AggregatorV3Interface pri_feed) internal view returns (uint) {
        // AggregatorV3Interface pri_feed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        (, int price,,,) = pri_feed.latestRoundData();
        return uint(price * 1e10); // same as price 1 * 10 **10;

    }

    function get_ver() internal view returns (uint) {
        AggregatorV3Interface pri_feed = AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e);
        return pri_feed.version();
    }

    function get_con_rate(uint eth_amo, AggregatorV3Interface pri_feed) internal view returns (uint) {
        uint eth_curr_pri = get_pri(pri_feed);
        uint eth_amo_usd = (eth_curr_pri * eth_amo) / 1e18;
        return eth_amo_usd;
    }

    function show_pri(uint eth_amo, AggregatorV3Interface pri_feed) internal view returns (uint) {
        uint eth_show = get_pri(pri_feed);
        eth_amo=1;
        return eth_show;
    }

}