//SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./HGSBoxOffice.sol";
import "./DateConverter.sol";
import "./ToString.sol";

error Administration__NotOwner();
error Administration__CallFailed();
error Administration__NotRecordedBoxOffice();
error Administration__AlreadyRecordedVehicle();
error Administration__NotRecordedVehicle();

contract Administration {
  using DateConverter for uint64;

  enum vehicleType {
    car,
    minibus,
    bus
  }

  struct vehicleStruct {
    uint64 HGSNumber;
    string name;
    string surname;
    vehicleType vehicleClass;
    uint64[] crossingHistories;
  }

  struct VehicleCrossingTime {
    DateConverter._DateTime date;
    address vehicle;
  }

  mapping(address => vehicleStruct) private registeredVehicles;
  address[] private registeredVehiclesAddress;
  mapping(address => bool) private vehicleExists;
  uint256 public numberOfVehicle = 0;

  address private immutable i_owner;
  address private immutable i_priceFeedAddress;
  address[] public hgsBoxOfficesAddress;
  mapping(address => HGSBoxOffice) hgsBoxOffices;
  mapping(address => bool) hgsBoxOfficesExists;
  uint256 public numberOfOffices = 0;

  mapping(string => VehicleCrossingTime[]) private dailyPass;

  constructor(address _priceFeedAddress) {
    i_owner = msg.sender;
    i_priceFeedAddress = _priceFeedAddress;
  }

  modifier onlyOwner() {
    if (msg.sender != i_owner) revert Administration__NotOwner();
    _;
  }

  modifier notRecordedBoxOffice() {
    if (!hgsBoxOfficesExists[msg.sender])
      revert Administration__NotRecordedBoxOffice();
    _;
  }

  modifier notRecordedBoxOffice2(address _hgsBoxOfficeAddress) {
    if (!hgsBoxOfficesExists[_hgsBoxOfficeAddress])
      revert Administration__NotRecordedBoxOffice();
    _;
  }

  modifier alreadyRecordedVehicle(address _owner) {
    if (vehicleExists[_owner]) revert Administration__AlreadyRecordedVehicle();
    _;
  }

  modifier notRecordedVehicle(address _sender) {
    if (!vehicleExists[_sender]) revert Administration__NotRecordedVehicle();
    _;
  }

  function crossing(address sender)
    public
    notRecordedBoxOffice
    notRecordedVehicle(sender)
  {
    VehicleCrossingTime memory vehicleCrossingTime;
    vehicleCrossingTime.date = uint64(block.timestamp).parseTimestamp();
    vehicleCrossingTime.vehicle = sender;
    string memory day = string.concat(
      Strings.toString(vehicleCrossingTime.date.year),
      ".",
      Strings.toString(vehicleCrossingTime.date.month),
      ".",
      Strings.toString(vehicleCrossingTime.date.day)
    );
    dailyPass[day].push(vehicleCrossingTime);
    registeredVehicles[sender].crossingHistories.push(uint64(block.timestamp));
  }

  function addVehicle(
    address _owner,
    uint64 _HGSNumber,
    string memory _name,
    string memory _surname,
    vehicleType _vehicleClass
  ) public onlyOwner alreadyRecordedVehicle(_owner) {
    registeredVehicles[_owner] = vehicleStruct(
      _HGSNumber,
      _name,
      _surname,
      _vehicleClass,
      new uint64[](0)
    );
    registeredVehiclesAddress.push(_owner);
    vehicleExists[_owner] = true;
    numberOfVehicle++;
  }

  function deleteVehicle(address _owner) public onlyOwner {
    delete registeredVehicles[_owner];
    numberOfVehicle--;
    vehicleExists[_owner] = false;
  }

  function createOffice(
    uint256 _CAR_FEE_USD,
    uint256 _MINIBUS_FEE_USD,
    uint256 _BUS_FEE_USD
  ) public onlyOwner {
    HGSBoxOffice _hgsBoxOffices = new HGSBoxOffice(
      this,
      i_priceFeedAddress,
      _CAR_FEE_USD,
      _MINIBUS_FEE_USD,
      _BUS_FEE_USD
    );
    hgsBoxOfficesAddress.push(address(_hgsBoxOffices));
    hgsBoxOffices[address(_hgsBoxOffices)] = _hgsBoxOffices;
    hgsBoxOfficesExists[address(_hgsBoxOffices)] = true;
    numberOfOffices++;
  }

  function setFees(
    address _hgsBoxOfficeAddress,
    uint256 _CAR_FEE_USD,
    uint256 _MINIBUS_FEE_USD,
    uint256 _BUS_FEE_USD
  ) public onlyOwner notRecordedBoxOffice2(_hgsBoxOfficeAddress) {
    hgsBoxOffices[_hgsBoxOfficeAddress].setFees(
      _CAR_FEE_USD,
      _MINIBUS_FEE_USD,
      _BUS_FEE_USD
    );
  }

  function deleteOffice(address _hgsBoxOfficeAddress)
    public
    onlyOwner
    notRecordedBoxOffice2(_hgsBoxOfficeAddress)
  {
    hgsBoxOffices[_hgsBoxOfficeAddress].withdraw();
    delete hgsBoxOffices[_hgsBoxOfficeAddress];
    hgsBoxOfficesExists[_hgsBoxOfficeAddress] = false;
    numberOfOffices--;
  }

  function withdraw() public payable onlyOwner {
    address[] memory _hgsBoxOfficesAddress = hgsBoxOfficesAddress;
    for (uint256 i = 0; i < _hgsBoxOfficesAddress.length; i++) {
      if (hgsBoxOfficesExists[_hgsBoxOfficesAddress[i]])
        hgsBoxOffices[_hgsBoxOfficesAddress[i]].withdraw();
    }
    (bool successCall, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    if (!successCall) revert Administration__CallFailed();
  }

  function totalBalanceOfOffices()
    public
    view
    onlyOwner
    returns (uint256 totalBalance)
  {
    address[] memory _hgsBoxOfficesAddress = hgsBoxOfficesAddress;
    uint256 total = 0;
    for (uint256 i = 0; i < _hgsBoxOfficesAddress.length; i++) {
      total += _hgsBoxOfficesAddress[i].balance;
    }
    return total;
  }

  function getVehicle(address _owner)
    public
    view
    returns (vehicleStruct memory)
  {
    return registeredVehicles[_owner];
  }

  function getVehicle() public view returns (vehicleStruct memory) {
    return registeredVehicles[msg.sender];
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./PriceConverter.sol";
import "./Administration.sol";

error HGSBoxOffice__LessFee();
error HGSBoxOffice__CallFailed();
error HGSBoxOffice__NotRecorded();
error HGSBoxOffice__NotOwner();

contract HGSBoxOffice {
  using PriceConverter for uint256;

  address private immutable i_owner;

  AggregatorV3Interface private immutable s_priceFeed;
  Administration private immutable admin;

  uint256 public CAR_FEE_USD;
  uint256 public MINIBUS_FEE_USD;
  uint256 public BUS_FEE_USD;

  constructor(
    Administration _admin,
    address priceFeedAddress,
    uint256 _CAR_FEE_USD,
    uint256 _MINIBUS_FEE_USD,
    uint256 _BUS_FEE_USD
  ) {
    i_owner = msg.sender;
    s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    admin = _admin;

    CAR_FEE_USD = _CAR_FEE_USD;
    MINIBUS_FEE_USD = _MINIBUS_FEE_USD;
    BUS_FEE_USD = _BUS_FEE_USD;
  }

  modifier notRecorded() {
    if (admin.getVehicle(msg.sender).HGSNumber == 0)
      revert HGSBoxOffice__NotRecorded();
    _;
  }

  modifier lessFee(Administration.vehicleType vehicleClass, uint256 fee) {
    if (
      (vehicleClass == Administration.vehicleType.car && fee < CAR_FEE_USD) ||
      (vehicleClass == Administration.vehicleType.minibus &&
        fee < MINIBUS_FEE_USD) ||
      (vehicleClass == Administration.vehicleType.bus && fee < BUS_FEE_USD)
    ) {
      revert HGSBoxOffice__LessFee();
    }
    _;
  }

  modifier notOwner() {
    if (msg.sender != i_owner) revert HGSBoxOffice__NotOwner();
    _;
  }

  function setFees(
    uint256 _CAR_FEE_USD,
    uint256 _MINIBUS_FEE_USD,
    uint256 _BUS_FEE_USD
  ) public notOwner {
    CAR_FEE_USD = _CAR_FEE_USD;
    MINIBUS_FEE_USD = _MINIBUS_FEE_USD;
    BUS_FEE_USD = _BUS_FEE_USD;
  }

  function crossing()
    public
    payable
    notRecorded
    lessFee(
      admin.getVehicle(msg.sender).vehicleClass,
      msg.value.getConversionRate(s_priceFeed)
    )
  {
    admin.crossing(msg.sender);
  }

  function withdraw() public payable notOwner {
    (bool successCall, ) = payable(msg.sender).call{
      value: address(this).balance
    }("");
    if (!successCall) revert HGSBoxOffice__CallFailed();
  }

  receive() external payable {
    crossing();
  }

  fallback() external payable {
    crossing();
  }

  function getVehicle()
    public
    view
    returns (Administration.vehicleStruct memory)
  {
    return admin.getVehicle(msg.sender);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library DateConverter {
  struct _DateTime {
    uint16 year;
    uint8 month;
    uint8 day;
    uint8 hour;
    uint8 minute;
    uint8 second;
    uint8 weekday;
  }

  uint256 constant DAY_IN_SECONDS = 86400;
  uint256 constant YEAR_IN_SECONDS = 31536000;
  uint256 constant LEAP_YEAR_IN_SECONDS = 31622400;

  uint256 constant HOUR_IN_SECONDS = 3600;
  uint256 constant MINUTE_IN_SECONDS = 60;

  uint16 constant ORIGIN_YEAR = 1970;

  function isLeapYear(uint16 year) public pure returns (bool) {
    if (year % 4 != 0) {
      return false;
    }
    if (year % 100 != 0) {
      return true;
    }
    if (year % 400 != 0) {
      return false;
    }
    return true;
  }

  function leapYearsBefore(uint256 year) public pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year)
    public
    pure
    returns (uint8)
  {
    if (
      month == 1 ||
      month == 3 ||
      month == 5 ||
      month == 7 ||
      month == 8 ||
      month == 10 ||
      month == 12
    ) {
      return 31;
    } else if (month == 4 || month == 6 || month == 9 || month == 11) {
      return 30;
    } else if (isLeapYear(year)) {
      return 29;
    } else {
      return 28;
    }
  }

  function parseTimestamp(uint256 timestamp)
    internal
    pure
    returns (_DateTime memory)
  {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;
    _DateTime memory dt;

    // Year
    dt.year = getYear(timestamp);
    buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
    secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

    // Month
    uint256 secondsInMonth;
    for (i = 1; i <= 12; i++) {
      secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
      if (secondsInMonth + secondsAccountedFor > timestamp) {
        dt.month = i;
        break;
      }
      secondsAccountedFor += secondsInMonth;
    }

    // Day
    for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
      if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
        dt.day = i;
        break;
      }
      secondsAccountedFor += DAY_IN_SECONDS;
    }

    // Hour
    dt.hour = getHour(timestamp);

    // Minute
    dt.minute = getMinute(timestamp);

    // Second
    dt.second = getSecond(timestamp);

    // Day of week.
    dt.weekday = getWeekday(timestamp);

    return dt;
  }

  function getYear(uint256 timestamp) public pure returns (uint16) {
    uint256 secondsAccountedFor = 0;
    uint16 year;
    uint256 numLeapYears;

    // Year
    year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
    numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

    secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
    secondsAccountedFor +=
      YEAR_IN_SECONDS *
      (year - ORIGIN_YEAR - numLeapYears);

    while (secondsAccountedFor > timestamp) {
      if (isLeapYear(uint16(year - 1))) {
        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
      } else {
        secondsAccountedFor -= YEAR_IN_SECONDS;
      }
      year -= 1;
    }
    return year;
  }

  function getMonth(uint256 timestamp) public pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) public pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) public pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) public pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) public pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) public pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) public pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) public pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute
  ) public pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, minute, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) public pure returns (uint256 timestamp) {
    uint16 i;

    // Year
    for (i = ORIGIN_YEAR; i < year; i++) {
      if (isLeapYear(i)) {
        timestamp += LEAP_YEAR_IN_SECONDS;
      } else {
        timestamp += YEAR_IN_SECONDS;
      }
    }

    // Month
    uint8[12] memory monthDayCounts;
    monthDayCounts[0] = 31;
    if (isLeapYear(year)) {
      monthDayCounts[1] = 29;
    } else {
      monthDayCounts[1] = 28;
    }
    monthDayCounts[2] = 31;
    monthDayCounts[3] = 30;
    monthDayCounts[4] = 31;
    monthDayCounts[5] = 30;
    monthDayCounts[6] = 31;
    monthDayCounts[7] = 31;
    monthDayCounts[8] = 30;
    monthDayCounts[9] = 31;
    monthDayCounts[10] = 30;
    monthDayCounts[11] = 31;

    for (i = 1; i < month; i++) {
      timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
    }

    // Day
    timestamp += DAY_IN_SECONDS * (day - 1);

    // Hour
    timestamp += HOUR_IN_SECONDS * (hour);

    // Minute
    timestamp += MINUTE_IN_SECONDS * (minute);

    // Second
    timestamp += second;

    return timestamp;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
  bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
  uint8 private constant _ADDRESS_LENGTH = 20;

  /**
   * @dev Converts a `uint256` to its ASCII `string` decimal representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return "0";
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    while (value != 0) {
      digits -= 1;
      buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
      value /= 10;
    }
    return string(buffer);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
   */
  function toHexString(uint256 value) internal pure returns (string memory) {
    if (value == 0) {
      return "0x00";
    }
    uint256 temp = value;
    uint256 length = 0;
    while (temp != 0) {
      length++;
      temp >>= 8;
    }
    return toHexString(value, length);
  }

  /**
   * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
   */
  function toHexString(uint256 value, uint256 length)
    internal
    pure
    returns (string memory)
  {
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = _HEX_SYMBOLS[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  /**
   * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
   */
  function toHexString(address addr) internal pure returns (string memory) {
    return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

library PriceConverter {
  function getPrice(AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    (, int256 price, , , ) = priceFeed.latestRoundData();
    return uint256(price);
  }

  function getConversionRate(uint256 ethAmount, AggregatorV3Interface priceFeed)
    internal
    view
    returns (uint256)
  {
    return (ethAmount * getPrice(priceFeed)) / 1e26;
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