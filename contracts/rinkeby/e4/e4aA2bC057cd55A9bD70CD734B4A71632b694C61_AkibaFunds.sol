// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AkibaHalisi.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./priceConverter.sol";

// 3. Interfaces, Libraries, Contracts

contract AkibaFunds is AkibaHalisi {
    using priceInterface for uint256;

    uint256 public constant premiumInUSD = 50 * 10**18;
    address[] private Insureds;
    mapping(address => uint256) public addressToPremiumDeposited;
    AggregatorV3Interface public s_priceFeed;

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_Owner = msg.sender;
    }

    /*
    The functions needs:
    - abi of the price conversaton rate contract
    - address- from the chainlink data feeds ehtereum testnet (0x8A753747A1Fa494EC906cE90E9f37563A8AF630e)
    - choose a network to work with from the data.chain.link (rinkeyby)
    */

    function Deposit() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) >= premiumInUSD,
            "insuffient Amount"
        );

        // we are not passing a variable even though it is expected (uint256 ethAmount) this is because msg.value is the first variable recognised.
        addressToPremiumDeposited[msg.sender] += msg.value;
        Insureds.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    // creating a loop for withdraw function such that anytime premiums are send to th account it is withdrawn and reset to the initial default number of the address.
    function withdraw() public onlyOwner {
        for (
            uint256 insuredIndex = 0;
            insuredIndex < Insureds.length;
            insuredIndex++
        ) {
            address insured = Insureds[insuredIndex];
            addressToPremiumDeposited[insured] = 0;
        }

        //resetting the array
        Insureds = new address[](0);

        //call
        (bool callSuccessful, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccessful, "call failed");
    }
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

/**@title A sample Funding Contract
 * @author Michael Diviter
 * @notice This contract is for creating a sample funding contract
 * @dev This implements price feeds as our library
 */
//create a smart contract by the name akibaHalisi
//the contract should be able to create and store usersaccount
//users should be able to deposit and withdraw funds(after a required time stamp is reached

contract AkibaHalisi {
    address public i_Owner;

    uint256 accountNumber;

    modifier onlyOwner() {
        require(i_Owner == msg.sender);
        _;
    }

    struct UserAccount {
        string userName;
        uint256 userId;
        uint256 phoneNumber;
    }

    UserAccount[] useraccount;
    mapping(string => uint256) public userNameToUserId;

    function storeAccount(uint256 _accountNumber) public {
        accountNumber = _accountNumber;
    }

    function retrieve() public view returns (uint256) {
        return accountNumber;
    }

    function createUserAccount(
        string memory _userName,
        uint256 _userId,
        uint256 _phoneNumber
    ) public onlyOwner {
        useraccount.push(UserAccount(_userName, _userId, _phoneNumber));
        userNameToUserId[_userName] = _userId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Why is this a library and not abstract?
// Why not an interface?

library priceInterface {
    // We could make this public, but then we'd have to deploy it
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        // Rinkeby ETH / USD Address
        // https://docs.chain.link/docs/ethereum-addresses/
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