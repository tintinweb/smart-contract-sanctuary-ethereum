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
import "./PriceConverter.sol";
pragma solidity ^0.8.0;
error FundMe__notOwner();

//the below syntex helps in creating documentation of contract,
//we can use the same to describe the functions of contract
/** @title A contract for crowd funding
 * @author Vivek Singh
 * @notice This is to demo a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 1e18; //constant<=efficient way to save the gas
    address[] public funders;
    mapping(address => uint256) public funderstoprice;
    address public immutable i_owner; //immutable<=efficient way to save the gas
    AggregatorV3Interface priceFeed;

    //same as other language constructor
    constructor(address priceFeedAddress) {
        i_owner = msg.sender; //msg.sender<=global function which returns the address of sender who is doing transaction
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

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
            msg.value.getConversionRate(priceFeed) > MINIMUM_USD,
            "Didn't send Enough"
        ); //etherium is sent in wei 1e18 wei==1 eth and mssg is generated when less than the checked eth is tried to send(reverting)
        funders.push(msg.sender);
        funderstoprice[msg.sender] = msg.value;
        //what is revrting
        //undo any action before,and send the remaining gas back
    }

    function withdraw() public onlyByOwner {
        //resetting the funders amount to 0
        for (
            uint256 fundersIndex = 0;
            fundersIndex < funders.length;
            fundersIndex++
        ) {
            funderstoprice[funders[fundersIndex]] = 0;
        }
        //reset the funders
        funders = new address[](0);
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
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Transaction failed");
        //modifier:-modifier are used to execute something in the starting or ending of multiple functions
    }

    modifier onlyByOwner() {
        // require(msg.sender==i_owner,"You Are Not the Owner");
        //alternative and efficient way to save gas
        if (msg.sender != i_owner) {
            revert FundMe__notOwner();
        }
        _; //this means execution of other lines in the funcion where this modifier is declared
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
    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getprice(
        AggregatorV3Interface pricefeed
    ) internal view returns (uint256) {
        (, int price, , , ) = pricefeed.latestRoundData();
        return uint256(price * 1e10);
    }

    function getVersion() public view returns (uint256) {
        return
            AggregatorV3Interface(0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e)
                .version();
    }

    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 ethPrice = getprice(priceFeed);
        return (ethPrice * ethAmount) / 1e18;
    }
}