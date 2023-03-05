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

//SPDX-License-Identifier:MIT
//1.pragma
pragma solidity ^0.8.7;
//2.imports
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";
// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

//the below syntex helps in creating documentation of contract,
//we can use the same to describe the functions of contract
/** @title A contract for crowd funding
 * @author Vivek Singh
 * @notice This is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    //type declarations
    using PriceConverter for uint256;

    //static variables
    uint256 public constant MINIMUM_USD = 50 * 1 ** 18; //constant<=efficient way to save the gas
    address private immutable i_owner; //immutable<=efficient way to save the gas
    address[] private s_funders;
    mapping(address => uint256) public s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    //events

    //modifier
    modifier onlyOwner() {
        // require(msg.sender==i_owner,"You Are Not the Owner");
        //alternative and efficient way to save gas
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _; //this means execution of other lines in the funcion where this modifier is declared
    }

    // Functions Order:
    //// constructor
    //// receive
    //// fallback
    //// external
    //// public
    //// internal
    //// private
    //// view / pure
    //same as other language constructor
    constructor(address priceFeed) {
        i_owner = msg.sender; //msg.sender<=global function which returns the address of sender who is doing transaction
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // receive() external payable {
    //     fund();
    // }

    // fallback() external payable {
    //     fund();
    // }

    function fund()
        public
        payable
    //<=payable is used to do transactions in ether
    {
        //want to be able to set a minimum fund amount in USD
        //1.How do we send ETH to this contract?
        //required is used to set the minimum ether needed for transaction
        //msg.value tells that how much ether is requested to send my user
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD,
            "You need to spend more ETH!"
        ); //etherium is sent in wei 1e18 wei==1 eth and mssg is generated when less than the checked eth is tried to send(reverting)
        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] += msg.value;
        //what is revrting
        //undo any action before,and send the remaining gas back
    }

    function withdraw() public onlyOwner {
        //resetting the funders amount to 0
        for (
            uint256 fundersIndex = 0;
            fundersIndex < s_funders.length;
            fundersIndex++
        ) {
            address funder = s_funders[fundersIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //reset the funders
        s_funders = new address[](0);
        /*
        3 ways to send the money
        1.transfer
        2.send
        3.call
        */
        //transfer:-this throws the error if not executed successfully and automatically revert back the transaction,which can be used in try catch block
        // payable(msg.sender).transfer(address(this).balance);

        //send:-if not successfully executed ,this returns a boolean value which can be used to revert the transaction
        // bool sendSuccess=payable(msg.sender).send(address(this).balance);
        // require(sendSuccess,"Transaction failed");

        //call:-this return 2  values ,one is boolean value which tells if the transaction is successfull or not,another is byte data which is returned along with transaction
        (bool success, ) = payable(i_owner).call{value: address(this).balance}(
            ""
        );
        require(success);
        //modifier:-modifier are used to execute something in the starting or ending of multiple functions
    }

    // google evm-opcodes:gas used for every events
    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        //mappings can't be in memory
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /*
     * @notice Gets the amount that an address has funded
     * @param fundingAddress the address of the funders
     * @return the amount funded
     */
    function getAddressToAmountFunded(
        address fundingAddress
    ) public view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}

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

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getprice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int price, , , ) = priceFeed.latestRoundData();
        return uint256(price * 10000000000); //1e10
    }

    // 1000000000
    // call it get fiatConversionRate, since it assumes something about decimals
    // It wouldn't work for every aggregator
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getprice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000; //1e18
        return ethAmountInUsd;
    }
}