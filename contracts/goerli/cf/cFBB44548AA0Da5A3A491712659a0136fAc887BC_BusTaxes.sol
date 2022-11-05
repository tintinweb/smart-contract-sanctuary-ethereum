// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./TaxConverter.sol";

error Unauthorized();
error InsufficientFunds(uint256 _val, uint256 _tax);
error InvalidInput(uint256 _minRequred, uint256 _maxRequired);
error registrationFailed(string _message);

contract BusTaxes {
    /// @title A contract for Bus Taxing System
    /// @author iamenochlee
    /// @notice This smart contract eradicates the need for tax collectors which could lead to traffic on a travel highway, it calculates tax base on giving details, taking into count neccesary scenerios where change might be needed
    /// @dev A solution to failed taxing system.

    //library
    using TaxConverter for uint256;

    //variables
    address immutable i_owner;
    // uint256 public price = 1 * 10**18;
    uint256 public tripPrice = 200;
    uint256 private maxTripCount = 25;
    uint256 private totalPriceInNairaForADayTrip = tripPrice * maxTripCount;
    uint256 public constant taxRate = 5;
    uint256 private maxBusCapacity = 18;
    AggregatorV3Interface private s_priceFeed;
    uint256 private rate;

    //struct
    struct Driver {
        address addr;
        uint256 passId;
        string name;
        uint8 busCapacity;
        uint256 tax;
        bool isWorking;
    }

    //mapping
    mapping(uint256 => string) driverIdToName;
    Driver[] public drivers;

    //events
    event registered(
        uint256 indexed _passId,
        address indexed _address,
        uint256 _busCapacity
    );

    constructor(address priceFeed, uint256 _rate) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
        rate = _rate;
    }

    function setPrice(uint256 _newPrice) public onlyOwner {
        tripPrice = _newPrice;
    }

    function setMaxBusCapacity(uint256 _maxBusCapacity) public onlyOwner {
        maxBusCapacity = _maxBusCapacity;
    }

    function register(
        uint256 _passId,
        string memory _name,
        uint8 _busCapacity
    ) public notOwner {
        for (uint i = 0; i < drivers.length; i++) {
            if (drivers[i].addr == msg.sender || drivers[i].passId == _passId) {
                revert registrationFailed("Failed to register this account");
            }
        }
        if (_busCapacity < 12 || _busCapacity > maxBusCapacity)
            revert InvalidInput(12, maxBusCapacity);
        drivers.push(Driver(msg.sender, _passId, _name, _busCapacity, 0, true));
        driverIdToName[_passId] = _name;
        handleTax();
        emit registered(_passId, msg.sender, _busCapacity);
    }

    function handleTax() public {
        for (uint256 i = 0; i < drivers.length; i++) {
            require(drivers[i].isWorking == true);
            uint256 _taxAmount = totalPriceInNairaForADayTrip.getTaxPrice(
                s_priceFeed,
                rate,
                drivers[i].busCapacity,
                taxRate
            );
            drivers[i].tax = _taxAmount;
        }
    }

    function getDriversCount() public view onlyOwner returns (uint256) {
        return drivers.length;
    }

    function getDriverTax(uint256 _passId) public view returns (uint256) {
        uint256 tax;
        for (uint256 i = 0; i < drivers.length; i++) {
            if (drivers[i].addr != msg.sender) {
                revert Unauthorized();
            }
            if (drivers[i].passId == _passId) {
                tax = drivers[i].tax;
            }
        }
        return tax;
    }

    function setWorkingStatus() public notOwner {
        for (uint256 i = 0; i < drivers.length; i++) {
            if (drivers[i].addr == msg.sender) {
                drivers[i].isWorking = !drivers[i].isWorking;
            }
        }
    }

    // function payTax() public payable notOwner {
    //    address(this).balance += msg.value;
    // }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not Permitted");
        _;
    }

    modifier notOwner() {
        require(msg.sender != i_owner, "Not Permitted");
        _;
    }
}
//  for (uint256 i = 0; i < drivers.length; i++) {
//             if (msg.sender == drivers[i].addr) {
//                 if (msg.value < msg.sender.balance) {
//                     revert InsufficientFunds(msg.value, drivers[i].tax);
//                 }
//                 require(
//                     msg.value == drivers[i].tax,
//                     "Incomplete payment not allowed"
//                 );
//             }
//         }

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library TaxConverter {
    function getPrice(AggregatorV3Interface priceFeed)
        internal
        view
        returns (uint256)
    {
        (, int256 price, , , ) = priceFeed.latestRoundData();

        return uint256(price * 1e10);
    }

    function _nairaToDolar(uint256 price, uint256 _rate)
        internal
        pure
        returns (uint256)
    {
        return (price * _rate) / 100;
    }

    function getTaxPrice(
        uint256 totalPriceInNairaForADayTrip,
        AggregatorV3Interface priceFeed,
        uint256 rate,
        uint256 busCapacity,
        uint256 taxRate
    ) internal view returns (uint256) {
        uint256 price = totalPriceInNairaForADayTrip * busCapacity;
        uint256 ethAmount = _nairaToDolar(price, rate) * 10**18;
        uint256 ethPrice = getPrice(priceFeed);
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1e18;
        uint256 tax = (ethAmountInUsd * taxRate) / 100;
        return tax;
    }
}

//fisrt get the tax price, buscapacity, tax rate
// tp 500 naira, 15, 5
//covert 200 to $ using rate
//convert $ to gwei

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