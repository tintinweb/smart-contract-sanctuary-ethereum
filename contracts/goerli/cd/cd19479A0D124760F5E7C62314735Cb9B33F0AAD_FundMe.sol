// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
    Oracle is any device that interacts with the world outside the blockchain
    so that it can provide external data or computation to smart contracts.
    If oracle is centralized, using it in smart contract implies
    some centralization in smart contract.
    Chainlink is designed as a hybridization between off-chain and on-chain,
    decentralized oracle network (3:46:20).
    docs.chain.link -> EVM Chains -> Using Data Feeds -> Solidity (3:50:00 - 4:00:29 사이 실습 참고)
    GitHub Chainlink repo -> contracts -> ...
*/
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

// 3. Interfaces, Libraries, Contracts
error FundMe__NotOwner();

/**@title A sample Funding Contract
 * @author Patrick Collins
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
contract FundMe {
    using PriceConverter for uint256;
    uint256 public constant MINIMUM_USD = 50 * 10**18;

    // Could we make this constant?  /* hint: no! We should make it immutable! */
    address private immutable i_owner;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    event DemoEvent (
        address caller,
        uint256 sentValue,
        uint256 fundAmount
    );

    // Modifiers
    modifier onlyOwner() {
        // require(msg.sender == i_owner);

        // msg.sender is also a global keyword in solidity
        // which is an address of a protocol that calls this transaction
        if (msg.sender != i_owner) revert FundMe__NotOwner();
        _; // this represents "execute the function that this modifier is decorating"
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

    // conctructor is called immediately when this contract is deployed
    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    /*
        @notice Funds our contract based on the ETH/USD price

        `msg.value` (global keyword) is automatically set to the amount of `wei` sent to a `payable` function.
        If "require" fails, any preceding commands in the function are reverted.
    */
    function fund() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        // reset an array
        s_funders = new address[](0);

        /*
            Transfer vs call vs Send (solidity-by-example.org)
            
                transfer (the output is throwing error or not)
                    type of "msg.sender": address
                    type of "payable(msg.sender)": payable address
            In solidity, in order to send native blockchain token like ETH, 
            we require payable addresses.
                payable(msg.sender).transfer(address(this).balance);

            send (unlike transfer, the output is boolean)
                bool sendSuccess = payable(msg.sender).send(address(this).balance);
                require(sendSuccess, "Send failed");
        */

        /*
            `this` refers to an instance (realization) of a contract source code.
            `<address>.balance refers to the balance of the <address> in Wei.

            The following three lines are equivalent.
                payable(msg.sender).transfer(address(this).balance);
                (bool success, bytes memory dataReturned) = payable(msg.sender).call{value: address(this).balance}("");
                (bool success, ) = i_owner.call{value: address(this).balance}("");
        */
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        // require(callSuccess, "Call failed");
        require(success);
    }

    function cheaperWithdraw() public onlyOwner {
        address[] memory funders = s_funders;
        // mappings can't be in memory, sorry!
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        // payable(msg.sender).transfer(address(this).balance);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    /** @notice Gets the amount that an address has funded
     *  @param fundingAddress the address of the funder
     *  @return the amount funded
     */
    function getAddressToAmountFunded(address fundingAddress)
        public
        view
        returns (uint256)
    {   
        return s_addressToAmountFunded[fundingAddress];
    }

    function getAddressToAmountFundedv2(address fundingAddress)
        public
        payable
    {   
        uint256 fundedAmount = s_addressToAmountFunded[fundingAddress];
        emit DemoEvent(msg.sender, msg.value, fundedAmount);
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

    /*
    `receive` and `fallback` without `function` keyword are speical functions
    Explainer from: https://solidity-by-example.org/fallback/
    Ether is sent to a deployed contract without calling a function.
            is msg.data empty? (any data in addition to currency is transferred ?)
                /   \ 
                yes  no
                /     \
        receive()?  fallback() 
            /   \ 
        yes   no
        /        \
    receive()  fallback()
    */

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// GitHub Chainlink repo -> contracts -> ...
// @ refers to pacakges in NPM
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*
  Lesson 4:
  Why is this a library and not abstract?
  Why not an interface?
*/
library PriceConverter {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        /*
            `answer` would be like 300000000000
            if priceFeed.decimals() = 8, then the actual number that the "answer" means is 3000.00000000
        */
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        
        uint8 decimalsInUSDperETH = priceFeed.decimals();

        // 1 ETH = 1e18 wei, if we send 1 ETH, then we get "value = 1e18"
        uint8 digitMatching = 18 - decimalsInUSDperETH; 
        int256 digitMatching_10 = int256(10 ** digitMatching);

        // ETH in terms of USD in 18 digit
        return uint256(answer * digitMatching_10);
    }

    /*
        The first argument of a library function
        is automatically msg.value if called as msg.value.getConversionRate()
        See, `FundMe.sol`.
        
        This function assumes something about decimals (1000000000000000000).
        It wouldn't work for every aggregator
    */
    function getConversionRate(
        uint256 ethAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {

        uint256 ethPrice = getPrice(priceFeed);

        // Both ethPrice and ethAmount have 18 decimals! 
        // So we have to divide by 1e18 so that ethAmountInUsd has 18 decimals.
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;

        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
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