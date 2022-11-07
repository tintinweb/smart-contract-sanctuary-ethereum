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
    /// @notice This smart contract eradicates the need for tax collectors which could lead to traffic on a travel highway, it calculates tax base on giving details, taking into count neccesary scenerios where change might be needed.
    /// @dev A solution to failed taxing system.

    //library
    using TaxConverter for uint256;

    //variables
    address private immutable i_owner;
    uint256 public s_tripPrice = 1;
    uint256 private s_maxTripCount = 25;
    uint256 private s_totalPriceInNairaForADayTrip =
        s_tripPrice * s_maxTripCount;
    uint256 public s_taxRate = 2;
    uint256 private s_maxBusCapacity = 18;
    AggregatorV3Interface private s_priceFeed;

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
    mapping(uint256 => string) private s_driverIdToName;
    Driver[] private s_drivers;

    //events
    event registered(
        uint256 indexed _passId,
        address indexed _address,
        uint256 _busCapacity
    );

    //constructor
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    //setters
    function setPrice(uint256 _newPrice) public onlyOwner {
        s_tripPrice = _newPrice;
    }

    function setmaxBusCapacity(uint256 maxBusCapacity) public onlyOwner {
        s_maxBusCapacity = maxBusCapacity;
    }

    function setMaxTrip(uint256 maxTripCount) public onlyOwner {
        s_maxTripCount = maxTripCount;
    }

    function setTaxRate(uint256 _taxrate) public onlyOwner {
        s_taxRate = _taxrate;
    }

    //getters
    function getDrivers() public view onlyOwner returns (Driver[] memory) {
        return s_drivers;
    }

    function getDriversCount() public view onlyOwner returns (uint256) {
        return s_drivers.length;
    }

    function getDriverNameWithId(uint256 _passId)
        public
        view
        onlyOwner
        returns (string memory)
    {
        return s_driverIdToName[_passId];
    }

    //functions
    function register(
        uint256 _passId,
        string memory _name,
        uint8 _busCapacity
    ) public notOwner {
        Driver[] memory s_driversArrray = s_drivers;
        for (uint i = 0; i < s_driversArrray.length; i++) {
            if (
                s_driversArrray[i].addr == msg.sender ||
                s_driversArrray[i].passId == _passId
            ) {
                revert registrationFailed("Failed to register this account");
            }
        }
        if (_busCapacity < 12 || _busCapacity > s_maxBusCapacity)
            revert InvalidInput(12, s_maxBusCapacity);
        s_drivers.push(
            Driver(msg.sender, _passId, _name, _busCapacity, 0, true)
        );
        s_driverIdToName[_passId] = _name;
        handleTax();
        emit registered(_passId, msg.sender, _busCapacity);
    }

    function handleTax() public {
        Driver[] memory s_driversArrray = s_drivers;
        for (uint256 i = 0; i < s_driversArrray.length; i++) {
            require(s_driversArrray[i].isWorking == true);
            uint256 _taxAmount = s_totalPriceInNairaForADayTrip.getTaxPrice(
                s_priceFeed,
                s_drivers[i].busCapacity,
                s_taxRate
            );
            s_drivers[i].tax = _taxAmount;
        }
    }

    //getter func

    function getDriverTax(uint256 _passId) public view returns (uint256) {
        Driver[] memory s_driversArrray = s_drivers;
        uint256 tax;
        for (uint256 i = 0; i < s_driversArrray.length; i++) {
            if (s_driversArrray[i].addr != msg.sender) {
                revert Unauthorized();
            }
            if (s_driversArrray[i].passId == _passId) {
                tax = s_drivers[i].tax;
            }
        }
        return tax;
    }

    //setter func
    function setWorkingStatus() public notOwner {
        Driver[] memory s_driversArrray = s_drivers;
        for (uint256 i = 0; i < s_driversArrray.length; i++) {
            if (s_driversArrray[i].addr == msg.sender) {
                s_drivers[i].isWorking = !s_drivers[i].isWorking;
            }
        }
    }

    //modifiers
    modifier onlyOwner() {
        require(msg.sender == i_owner, "Not Permitted");
        _;
    }

    modifier notOwner() {
        require(msg.sender != i_owner, "Not Permitted");
        _;
    }
}

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

    function getTaxPrice(
        uint256 totalPriceInNairaForADayTrip,
        AggregatorV3Interface priceFeed,
        uint256 busCapacity,
        uint256 taxRate
    ) internal view returns (uint256) {
        uint256 taxAmount = ((totalPriceInNairaForADayTrip * busCapacity) *
            taxRate) / 100;
        uint256 taxAmountInWei = taxAmount * 10**18;
        uint256 ethPriceInWei = getPrice(priceFeed);
        uint256 taxInWei = taxAmountInWei / ethPriceInWei;
        return taxInWei;
    }
}

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