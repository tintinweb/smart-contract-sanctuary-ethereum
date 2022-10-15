// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "./PriceConverter.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceConverter for uint256;

    uint256 public s_userCounter;
    uint256 public s_userId;
    uint256 public constant MINIMUM_BALANCE_TO_WITHDRAW = 50 * 10**18;
    uint256 public constant MINIMUM_BALANCE_TO_DEPOSIT = 50 * 10**18;
    uint256 public constant MINIMUM_BALANCE_TO_TRANSFER = 50 * 10**18;

    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeed) {
        s_userCounter = 0;
        s_userId = 1;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    enum UserCategories {
        UNCATEGORIZE,
        VIDEO_CREATOR,
        ARTIST,
        WRITER,
        MUSICIAN,
        GAMING,
        PODCAST,
        COMMUNITY
    }

    enum UserRoles {
        FUNDER,
        RECIPIENT
    }

    struct User {
        uint256 id;
        string username;
        string firstName;
        string lastName;
        uint256 balance;
        UserCategories category;
        UserRoles role;
    }

    mapping(address => User) public s_addressToUser;
    string[] public s_listOfUsernames;

    function registerUser(
        string memory _username,
        string memory _firstName,
        string memory _lastName,
        UserCategories _category,
        UserRoles _role
    ) public payable {
        s_addressToUser[msg.sender] = User(
            s_userId,
            _username,
            _firstName,
            _lastName,
            msg.value,
            _category,
            _role
        );
        s_listOfUsernames.push(_username);
        s_userId = s_userId + 1;
        s_userCounter = s_userCounter + 1;
    }

    function getUserData(address _address) public view returns (User memory) {
        return s_addressToUser[_address];
    }

    function getUsername(address _address) public view returns (string memory) {
        User memory user = s_addressToUser[_address];
        return user.username;
    }

    function getFirstName(address _address) public view returns (string memory) {
        User memory user = s_addressToUser[_address];
        return user.firstName;
    }

    function getLastName(address _address) public view returns (string memory) {
        User memory user = s_addressToUser[_address];
        return user.lastName;
    }

    function getBalance(address _address) public view returns (uint256) {
        User memory user = s_addressToUser[_address];
        return user.balance;
    }

    function getRole(address _address) public view returns (UserRoles) {
        User memory user = s_addressToUser[_address];
        return user.role;
    }

    function getCategory(address _address) public view returns (UserCategories) {
        User memory user = s_addressToUser[_address];
        return user.category;
    }

    function getuserIdIndex() public view returns (uint256) {
        return s_userId;
    }

    function getNoOfUsers() public view returns (uint256) {
        return s_userCounter;
    }

    function updateFirstName(address _address, string memory _newFirstName) public {
        User storage user = s_addressToUser[_address];
        user.firstName = _newFirstName;
    }

    function updateLastName(address _address, string memory _newLastName) public {
        User storage user = s_addressToUser[_address];
        user.lastName = _newLastName;
    }

    function updateUsername(address _address, string memory _newUsername) public {
        User storage user = s_addressToUser[_address];
        user.username = _newUsername;
    }

    function updateCategory(address _address, UserCategories _newCategory) public {
        User storage user = s_addressToUser[_address];
        user.category = _newCategory;
    }

    function updateRole(address _address, UserRoles _newRole) public {
        User storage user = s_addressToUser[_address];
        user.role = _newRole;
    }

    function depositBalance() public payable {
        require(
            msg.value.getConversionRate(s_priceFeed) > MINIMUM_BALANCE_TO_DEPOSIT,
            "You need to spend more ETH!"
        );
        User storage user = s_addressToUser[msg.sender];
        user.balance = user.balance + msg.value;
    }

    function transferFunds(address _to, uint256 _amount) public payable {
        User storage fromUser = s_addressToUser[msg.sender];
        User storage toUser = s_addressToUser[_to];
        fromUser.balance = fromUser.balance - _amount;
        toUser.balance = toUser.balance + _amount;

        (bool transferSuccess, ) = payable(_to).call{value: _amount}("");
    }

    function withdrawFunds() public payable {
        User storage user = s_addressToUser[msg.sender];
        uint256 balance = user.balance;
        user.balance = 0;

        (bool withdrawSuccess, ) = payable(msg.sender).call{value: balance}("");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
    function getConversionRate(uint256 amount, AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * amount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function getPrice(AggregatorV3Interface priceFeed) internal view returns (uint256) {
        (
            ,
            /*uint80 roundID*/
            int256 price, /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/
            ,
            ,

        ) = priceFeed.latestRoundData();

        return uint256(price * 100000000);
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