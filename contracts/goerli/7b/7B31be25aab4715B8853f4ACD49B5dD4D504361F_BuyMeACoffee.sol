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

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

import "./PriceConverter.sol";

contract BuyMeACoffee {

    using PriceConverter for uint;

    //Fund
    uint public constant MINIMUM_USD = 50 * 10**18;
    address[] private funders;
    mapping(address => uint256) private addressToAmountFunded;
    AggregatorV3Interface public priceFeed;
    address public owner;
    uint public clientCount = 0;
    uint public totalAmount = 0;

    mapping(address => uint) public totalDonatedUser;

    modifier onlyOwner() {
        require(msg.sender == owner, "User not owner");
        _;
    }

    modifier validateIdCoffees(uint id) {
        require(id < clientCount, "Client doesn't exist");
        _;
    }

    Client[] public Coffees;

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;      
    }

    function getCoffeeList() public view returns(Client[] memory){
        return Coffees;
    }

    constructor(address priceFeedAddress) {
        owner = msg.sender;
        priceFeed = AggregatorV3Interface(priceFeedAddress);
    }


    function fund() public payable {
        require( msg.value.getConversionRate(priceFeed) >= MINIMUM_USD,"You need to spend more ETH!");
        // require(PriceConverter.getConversionRate(msg.value) >= MINIMUM_USD, "You need to spend more ETH!");
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }




    struct Client {
        uint id;
        string name;
        string description;
        string urlImg;
        uint tipAmount;
        address payable wallet;
    }

    event ClientCreated(
        uint indexed userId,
        string _name,
        string _description,
        string _urlId,
        address payable wallet
    );

    function CreateUser(
        string memory _name, 
        string memory _description,
        string memory _urlImg,
        address payable wallet
        ) public onlyOwner {
            require(wallet != address(0));
            Client memory _Client = Client(
                clientCount,
                _name,
                _description,
                _urlImg,
                0,
                wallet
            );
            
            Coffees.push(_Client);
            emit ClientCreated(clientCount, _name, _description, _urlImg, wallet);
            clientCount++;
        }
        function tipCoffee(uint _id) public payable validateIdCoffees(_id) {
            Client memory _Client = Coffees[_id];
            address payable _user = _Client.wallet;
            _Client.tipAmount += msg.value;
            totalAmount = totalAmount + msg.value;
            totalDonatedUser[msg.sender] += msg.value;
            transferEth(_user, msg.value);


        }
        function transferEth(address _to, uint amount) internal {
            require(amount > 0);
            (bool success, ) = _to.call{value: amount}("");
            require(success);
        }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed) internal view returns(uint) {
      (, int256 answer, , ,) = priceFeed.latestRoundData();
      return uint(answer * 10000000000);
  }

  // 1000000000
  // call it get fiatConversionRate, since it assumes something about decimals
  // It wouldn't work for every aggregator
  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed) internal view returns (uint256) {
      uint256 ethPrice = getPrice(priceFeed);
      uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
      // the actual ETH/USD conversation rate, after adjusting the extra 0s.
      return ethAmountInUsd;
  }

}