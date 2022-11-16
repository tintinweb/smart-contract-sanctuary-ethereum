// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ConfirmedOwnerWithProposal.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwner is ConfirmedOwnerWithProposal {
  constructor(address newOwner) ConfirmedOwnerWithProposal(newOwner, address(0)) {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/OwnableInterface.sol";

/**
 * @title The ConfirmedOwner contract
 * @notice A contract with helpers for basic contract ownership.
 */
contract ConfirmedOwnerWithProposal is OwnableInterface {
  address private s_owner;
  address private s_pendingOwner;

  event OwnershipTransferRequested(address indexed from, address indexed to);
  event OwnershipTransferred(address indexed from, address indexed to);

  constructor(address newOwner, address pendingOwner) {
    require(newOwner != address(0), "Cannot set owner to zero");

    s_owner = newOwner;
    if (pendingOwner != address(0)) {
      _transferOwnership(pendingOwner);
    }
  }

  /**
   * @notice Allows an owner to begin transferring ownership to a new address,
   * pending.
   */
  function transferOwnership(address to) public override onlyOwner {
    _transferOwnership(to);
  }

  /**
   * @notice Allows an ownership transfer to be completed by the recipient.
   */
  function acceptOwnership() external override {
    require(msg.sender == s_pendingOwner, "Must be proposed owner");

    address oldOwner = s_owner;
    s_owner = msg.sender;
    s_pendingOwner = address(0);

    emit OwnershipTransferred(oldOwner, msg.sender);
  }

  /**
   * @notice Get the current owner
   */
  function owner() public view override returns (address) {
    return s_owner;
  }

  /**
   * @notice validate, transfer ownership, and emit relevant events
   */
  function _transferOwnership(address to) private {
    require(to != msg.sender, "Cannot transfer to self");

    s_pendingOwner = to;

    emit OwnershipTransferRequested(s_owner, to);
  }

  /**
   * @notice validate access
   */
  function _validateOwnership() internal view {
    require(msg.sender == s_owner, "Only callable by owner");
  }

  /**
   * @notice Reverts if called by anyone other than the contract owner.
   */
  modifier onlyOwner() {
    _validateOwnership();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationCompatibleInterface directly.
 */
pragma solidity ^0.8.0;
import {AutomationCompatibleInterface as KeeperCompatibleInterface} from "./AutomationCompatibleInterface.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface OwnableInterface {
  function owner() external returns (address);

  function transferOwnership(address recipient) external;

  function acceptOwnership() external;
}

// SPDX-License-Identifier: MIT
/**
 * @notice This is a deprecated interface. Please use AutomationBase directly.
 */
pragma solidity ^0.8.0;
import {AutomationBase as KeeperBase} from "./AutomationBase.sol";

pragma solidity 0.8.6;

import {Cron as CronInternal, Spec} from "../internal/Cron.sol";

/**
 * @title The Cron library
 * @notice A utility contract for encoding/decoding cron strings (ex: 0 0 * * *) into an
 * abstraction called a Spec. The library also includes a spec function, nextTick(), which
 * determines the next time a cron job should fire based on the current block timestamp.
 * @dev this is the external version of the library, which relies on the internal library
 * by the same name.
 */
library Cron {
  using CronInternal for Spec;
  using CronInternal for string;

  /**
   * @notice nextTick calculates the next datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function nextTick(Spec calldata spec) public view returns (uint256) {
    return spec.nextTick();
  }

  /**
   * @notice lastTick calculates the previous datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function lastTick(Spec calldata spec) public view returns (uint256) {
    return spec.lastTick();
  }

  /**
   * @notice matches evaluates whether or not a spec "ticks" at a given timestamp
   * @param spec the spec to evaluate
   * @param timestamp the timestamp to compare against
   * @return true / false if they match
   */
  function matches(Spec calldata spec, uint256 timestamp) public view returns (bool) {
    return spec.matches(timestamp);
  }

  /**
   * @notice toSpec converts a cron string to a spec struct. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the spec struct
   */
  function toSpec(string calldata cronString) public pure returns (Spec memory) {
    return cronString.toSpec();
  }

  /**
   * @notice toEncodedSpec converts a cron string to an abi-encoded spec. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the abi-encoded spec
   */
  function toEncodedSpec(string calldata cronString) public pure returns (bytes memory) {
    return cronString.toEncodedSpec();
  }

  /**
   * @notice toCronString converts a cron spec to a human-readable cron string. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param spec the cron spec
   * @return the corresponding cron string
   */
  function toCronString(Spec calldata spec) public pure returns (string memory) {
    return spec.toCronString();
  }
}

// SPDX-License-Identifier: MIT

/*
  The Cron contract serves two primary functions:
    * parsing cron-formatted strings like "0 0 * * *" into
      structs called "Specs"
    * computing the "next tick" of a cron spec

  Because manipulating strings is gas-expensive in solidity,
  the intended use of this contract is for users to first convert
  their cron strings to encoded Spec structs via toEncodedSpec().
  Then, the user stores the Spec on chain. Finally, users use the nextTick(),
  function to determine the datetime of the next cron job run.

  Cron jobs are interpreted according to this format:

  ┌───────────── minute (0 - 59)
  │ ┌───────────── hour (0 - 23)
  │ │ ┌───────────── day of the month (1 - 31)
  │ │ │ ┌───────────── month (1 - 12)
  │ │ │ │ ┌───────────── day of the week (0 - 6) (Monday to Sunday)
  │ │ │ │ │
  │ │ │ │ │
  │ │ │ │ │
  * * * * *

  Special limitations:
    * there is no year field
    * no special characters: ? L W #
    * lists can have a max length of 26
    * no words like JAN / FEB or MON / TUES
*/

pragma solidity 0.8.6;

import "../../vendor/Strings.sol";
import "../../vendor/DateTime.sol";

// The fields of a cron spec, by name
string constant MINUTE = "minute";
string constant HOUR = "hour";
string constant DAY = "day";
string constant MONTH = "month";
string constant DAY_OF_WEEK = "day of week";

error UnknownFieldType();
error InvalidSpec(string reason);
error InvalidField(string field, string reason);
error ListTooLarge();

// Set of enums representing a cron field type
enum FieldType {
  WILD,
  EXACT,
  INTERVAL,
  RANGE,
  LIST
}

// A spec represents a cron job by decomposing it into 5 fields
struct Spec {
  Field minute;
  Field hour;
  Field day;
  Field month;
  Field dayOfWeek;
}

// A field represents a single element in a cron spec. There are 5 types
// of fields (see above). Not all properties of this struct are present at once.
struct Field {
  FieldType fieldType;
  uint8 singleValue;
  uint8 interval;
  uint8 rangeStart;
  uint8 rangeEnd;
  uint8 listLength;
  uint8[26] list;
}

/**
 * @title The Cron library
 * @notice A utility contract for encoding/decoding cron strings (ex: 0 0 * * *) into an
 * abstraction called a Spec. The library also includes a spec function, nextTick(), which
 * determines the next time a cron job should fire based on the current block timestamp.
 */
library Cron {
  using strings for *;

  /**
   * @notice nextTick calculates the next datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   * @dev this is the internal version of the library. There is also an external version.
   */
  function nextTick(Spec memory spec) internal view returns (uint256) {
    uint16 year = DateTime.getYear(block.timestamp);
    uint8 month = DateTime.getMonth(block.timestamp);
    uint8 day = DateTime.getDay(block.timestamp);
    uint8 hour = DateTime.getHour(block.timestamp);
    uint8 minute = DateTime.getMinute(block.timestamp);
    uint8 dayOfWeek;
    for (; true; year++) {
      for (; month <= 12; month++) {
        if (!matches(spec.month, month)) {
          day = 1;
          hour = 0;
          minute = 0;
          continue;
        }
        uint8 maxDay = DateTime.getDaysInMonth(month, year);
        for (; day <= maxDay; day++) {
          if (!matches(spec.day, day)) {
            hour = 0;
            minute = 0;
            continue;
          }
          dayOfWeek = DateTime.getWeekday(DateTime.toTimestamp(year, month, day));
          if (!matches(spec.dayOfWeek, dayOfWeek)) {
            hour = 0;
            minute = 0;
            continue;
          }
          for (; hour < 24; hour++) {
            if (!matches(spec.hour, hour)) {
              minute = 0;
              continue;
            }
            for (; minute < 60; minute++) {
              if (!matches(spec.minute, minute)) {
                continue;
              }
              return DateTime.toTimestamp(year, month, day, hour, minute);
            }
            minute = 0;
          }
          hour = 0;
        }
        day = 1;
      }
      month = 1;
    }
  }

  /**
   * @notice lastTick calculates the previous datetime that a spec "ticks", starting
   * from the current block timestamp. This is gas-intensive and therefore should
   * only be called off-chain.
   * @param spec the spec to evaluate
   * @return the next tick
   */
  function lastTick(Spec memory spec) internal view returns (uint256) {
    uint16 year = DateTime.getYear(block.timestamp);
    uint8 month = DateTime.getMonth(block.timestamp);
    uint8 day = DateTime.getDay(block.timestamp);
    uint8 hour = DateTime.getHour(block.timestamp);
    uint8 minute = DateTime.getMinute(block.timestamp);
    uint8 dayOfWeek;
    bool resetDay;
    for (; true; year--) {
      for (; month > 0; month--) {
        if (!matches(spec.month, month)) {
          resetDay = true;
          hour = 23;
          minute = 59;
          continue;
        }
        if (resetDay) {
          day = DateTime.getDaysInMonth(month, year);
        }
        for (; day > 0; day--) {
          if (!matches(spec.day, day)) {
            hour = 23;
            minute = 59;
            continue;
          }
          dayOfWeek = DateTime.getWeekday(DateTime.toTimestamp(year, month, day));
          if (!matches(spec.dayOfWeek, dayOfWeek)) {
            hour = 23;
            minute = 59;
            continue;
          }
          for (; hour >= 0; hour--) {
            if (!matches(spec.hour, hour)) {
              minute = 59;
              if (hour == 0) {
                break;
              }
              continue;
            }
            for (; minute >= 0; minute--) {
              if (!matches(spec.minute, minute)) {
                if (minute == 0) {
                  break;
                }
                continue;
              }
              return DateTime.toTimestamp(year, month, day, hour, minute);
            }
            minute = 59;
            if (hour == 0) {
              break;
            }
          }
          hour = 23;
        }
        resetDay = true;
      }
      month = 12;
    }
  }

  /**
   * @notice matches evaluates whether or not a spec "ticks" at a given timestamp
   * @param spec the spec to evaluate
   * @param timestamp the timestamp to compare against
   * @return true / false if they match
   */
  function matches(Spec memory spec, uint256 timestamp) internal view returns (bool) {
    DateTime._DateTime memory dt = DateTime.parseTimestamp(timestamp);
    return
      matches(spec.month, dt.month) &&
      matches(spec.day, dt.day) &&
      matches(spec.hour, dt.hour) &&
      matches(spec.minute, dt.minute);
  }

  /**
   * @notice toSpec converts a cron string to a spec struct. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the spec struct
   */
  function toSpec(string memory cronString) internal pure returns (Spec memory) {
    strings.slice memory space = strings.toSlice(" ");
    strings.slice memory cronSlice = strings.toSlice(cronString);
    if (cronSlice.count(space) != 4) {
      revert InvalidSpec("4 spaces required");
    }
    strings.slice memory minuteSlice = cronSlice.split(space);
    strings.slice memory hourSlice = cronSlice.split(space);
    strings.slice memory daySlice = cronSlice.split(space);
    strings.slice memory monthSlice = cronSlice.split(space);
    // DEV: dayOfWeekSlice = cronSlice
    // The cronSlice now contains the last section of the cron job,
    // which corresponds to the day of week
    if (
      minuteSlice.len() == 0 ||
      hourSlice.len() == 0 ||
      daySlice.len() == 0 ||
      monthSlice.len() == 0 ||
      cronSlice.len() == 0
    ) {
      revert InvalidSpec("some fields missing");
    }
    return
      validate(
        Spec({
          minute: sliceToField(minuteSlice),
          hour: sliceToField(hourSlice),
          day: sliceToField(daySlice),
          month: sliceToField(monthSlice),
          dayOfWeek: sliceToField(cronSlice)
        })
      );
  }

  /**
   * @notice toEncodedSpec converts a cron string to an abi-encoded spec. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param cronString the cron string
   * @return the abi-encoded spec
   */
  function toEncodedSpec(string memory cronString) internal pure returns (bytes memory) {
    return abi.encode(toSpec(cronString));
  }

  /**
   * @notice toCronString converts a cron spec to a human-readable cron string. This is gas-intensive
   * and therefore should only be called off-chain.
   * @param spec the cron spec
   * @return the corresponding cron string
   */
  function toCronString(Spec memory spec) internal pure returns (string memory) {
    return
      string(
        bytes.concat(
          fieldToBstring(spec.minute),
          " ",
          fieldToBstring(spec.hour),
          " ",
          fieldToBstring(spec.day),
          " ",
          fieldToBstring(spec.month),
          " ",
          fieldToBstring(spec.dayOfWeek)
        )
      );
  }

  /**
   * @notice matches evaluates if a values matches a field.
   * ex: 3 matches *, 3 matches 0-5, 3 does not match 0,2,4
   * @param field the field struct to match against
   * @param value the value of a field
   * @return true / false if they match
   */
  function matches(Field memory field, uint8 value) private pure returns (bool) {
    if (field.fieldType == FieldType.WILD) {
      return true;
    } else if (field.fieldType == FieldType.INTERVAL) {
      return value % field.interval == 0;
    } else if (field.fieldType == FieldType.EXACT) {
      return value == field.singleValue;
    } else if (field.fieldType == FieldType.RANGE) {
      return value >= field.rangeStart && value <= field.rangeEnd;
    } else if (field.fieldType == FieldType.LIST) {
      for (uint256 idx = 0; idx < field.listLength; idx++) {
        if (value == field.list[idx]) {
          return true;
        }
      }
      return false;
    }
    revert UnknownFieldType();
  }

  // VALIDATIONS

  /**
   * @notice validate validates a spec, reverting if any errors are found
   * @param spec the spec to validate
   * @return the original spec
   */
  function validate(Spec memory spec) private pure returns (Spec memory) {
    validateField(spec.dayOfWeek, DAY_OF_WEEK, 0, 6);
    validateField(spec.month, MONTH, 1, 12);
    uint8 maxDay = maxDayForMonthField(spec.month);
    validateField(spec.day, DAY, 1, maxDay);
    validateField(spec.hour, HOUR, 0, 23);
    validateField(spec.minute, MINUTE, 0, 59);
    return spec;
  }

  /**
   * @notice validateField validates the value of a field. It reverts if an error is found.
   * @param field the field to validate
   * @param fieldName the name of the field ex "minute" or "hour"
   * @param min the minimum value a field can have (usually 1 or 0)
   * @param max the maximum value a field can have (ex minute = 59, hour = 23)
   */
  function validateField(
    Field memory field,
    string memory fieldName,
    uint8 min,
    uint8 max
  ) private pure {
    if (field.fieldType == FieldType.WILD) {
      return;
    } else if (field.fieldType == FieldType.EXACT) {
      if (field.singleValue < min || field.singleValue > max) {
        string memory reason = string(
          bytes.concat("value must be >=,", uintToBString(min), " and <=", uintToBString(max))
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.INTERVAL) {
      if (field.interval < 1 || field.interval > max) {
        string memory reason = string(
          bytes.concat("inverval must be */(", uintToBString(1), "-", uintToBString(max), ")")
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.RANGE) {
      if (field.rangeEnd > max || field.rangeEnd <= field.rangeStart) {
        string memory reason = string(
          bytes.concat("inverval must be within ", uintToBString(min), "-", uintToBString(max))
        );
        revert InvalidField(fieldName, reason);
      }
    } else if (field.fieldType == FieldType.LIST) {
      if (field.listLength < 2) {
        revert InvalidField(fieldName, "lists must have at least 2 items");
      }
      string memory reason = string(
        bytes.concat("items in list must be within ", uintToBString(min), "-", uintToBString(max))
      );
      uint8 listItem;
      for (uint256 idx = 0; idx < field.listLength; idx++) {
        listItem = field.list[idx];
        if (listItem < min || listItem > max) {
          revert InvalidField(fieldName, reason);
        }
      }
    } else {
      revert UnknownFieldType();
    }
  }

  /**
   * @notice maxDayForMonthField returns the maximum valid day given the month field
   * @param month the month field
   * @return the max day
   */
  function maxDayForMonthField(Field memory month) private pure returns (uint8) {
    // DEV: ranges are always safe because any two consecutive months will always
    // contain a month with 31 days
    if (month.fieldType == FieldType.WILD || month.fieldType == FieldType.RANGE) {
      return 31;
    } else if (month.fieldType == FieldType.EXACT) {
      // DEV: assume leap year in order to get max value
      return DateTime.getDaysInMonth(month.singleValue, 4);
    } else if (month.fieldType == FieldType.INTERVAL) {
      if (month.interval == 9 || month.interval == 11) {
        return 30;
      } else {
        return 31;
      }
    } else if (month.fieldType == FieldType.LIST) {
      uint8 result;
      for (uint256 idx = 0; idx < month.listLength; idx++) {
        // DEV: assume leap year in order to get max value
        uint8 daysInMonth = DateTime.getDaysInMonth(month.list[idx], 4);
        if (daysInMonth == 31) {
          return daysInMonth;
        }
        if (daysInMonth > result) {
          result = daysInMonth;
        }
      }
      return result;
    } else {
      revert UnknownFieldType();
    }
  }

  /**
   * @notice sliceToField converts a strings.slice to a field struct
   * @param fieldSlice the slice of a string representing the field of a cron job
   * @return the field
   */
  function sliceToField(strings.slice memory fieldSlice) private pure returns (Field memory) {
    strings.slice memory star = strings.toSlice("*");
    strings.slice memory dash = strings.toSlice("-");
    strings.slice memory slash = strings.toSlice("/");
    strings.slice memory comma = strings.toSlice(",");
    Field memory field;
    if (fieldSlice.equals(star)) {
      field.fieldType = FieldType.WILD;
    } else if (fieldSlice.contains(dash)) {
      field.fieldType = FieldType.RANGE;
      strings.slice memory start = fieldSlice.split(dash);
      field.rangeStart = sliceToUint8(start);
      field.rangeEnd = sliceToUint8(fieldSlice);
    } else if (fieldSlice.contains(slash)) {
      field.fieldType = FieldType.INTERVAL;
      fieldSlice.split(slash);
      field.interval = sliceToUint8(fieldSlice);
    } else if (fieldSlice.contains(comma)) {
      field.fieldType = FieldType.LIST;
      strings.slice memory token;
      while (fieldSlice.len() > 0) {
        if (field.listLength > 25) {
          revert ListTooLarge();
        }
        token = fieldSlice.split(comma);
        field.list[field.listLength] = sliceToUint8(token);
        field.listLength++;
      }
    } else {
      // needs input validation
      field.fieldType = FieldType.EXACT;
      field.singleValue = sliceToUint8(fieldSlice);
    }
    return field;
  }

  /**
   * @notice fieldToBstring converts a field to the bytes representation of that field string
   * @param field the field to stringify
   * @return bytes representing the string, ex: bytes("*")
   */
  function fieldToBstring(Field memory field) private pure returns (bytes memory) {
    if (field.fieldType == FieldType.WILD) {
      return "*";
    } else if (field.fieldType == FieldType.EXACT) {
      return uintToBString(uint256(field.singleValue));
    } else if (field.fieldType == FieldType.RANGE) {
      return bytes.concat(uintToBString(field.rangeStart), "-", uintToBString(field.rangeEnd));
    } else if (field.fieldType == FieldType.INTERVAL) {
      return bytes.concat("*/", uintToBString(uint256(field.interval)));
    } else if (field.fieldType == FieldType.LIST) {
      bytes memory result = uintToBString(field.list[0]);
      for (uint256 idx = 1; idx < field.listLength; idx++) {
        result = bytes.concat(result, ",", uintToBString(field.list[idx]));
      }
      return result;
    }
    revert UnknownFieldType();
  }

  /**
   * @notice uintToBString converts a uint256 to a bytes representation of that uint as a string
   * @param n the number to stringify
   * @return bytes representing the string, ex: bytes("1")
   */
  function uintToBString(uint256 n) private pure returns (bytes memory) {
    if (n == 0) {
      return "0";
    }
    uint256 j = n;
    uint256 len;
    while (j != 0) {
      len++;
      j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len;
    while (n != 0) {
      k = k - 1;
      uint8 temp = (48 + uint8(n - (n / 10) * 10));
      bytes1 b1 = bytes1(temp);
      bstr[k] = b1;
      n /= 10;
    }
    return bstr;
  }

  /**
   * @notice sliceToUint8 converts a strings.slice to uint8
   * @param slice the string slice to convert to a uint8
   * @return the number that the string represents ex: "20" --> 20
   */
  function sliceToUint8(strings.slice memory slice) private pure returns (uint8) {
    bytes memory b = bytes(slice.toString());
    uint8 i;
    uint8 result = 0;
    for (i = 0; i < b.length; i++) {
      uint8 c = uint8(b[i]);
      if (c >= 48 && c <= 57) {
        result = result * 10 + (c - 48);
      }
    }
    return result;
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @notice getRevertMsg extracts a revert reason from a failed contract call
 */
function getRevertMsg(bytes memory payload) pure returns (string memory) {
  if (payload.length < 68) return "transaction reverted silently";
  assembly {
    payload := add(payload, 0x04)
  }
  return abi.decode(payload, (string));
}

// SPDX-License-Identifier: MIT

// sourced from https://github.com/pipermerriam/ethereum-datetime

pragma solidity ^0.8.0;

library DateTime {
  /*
   *  Date and Time utilities for ethereum contracts
   *
   */
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

  function isLeapYear(uint16 year) internal pure returns (bool) {
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

  function leapYearsBefore(uint256 year) internal pure returns (uint256) {
    year -= 1;
    return year / 4 - year / 100 + year / 400;
  }

  function getDaysInMonth(uint8 month, uint16 year)
    internal
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
    returns (_DateTime memory dt)
  {
    uint256 secondsAccountedFor = 0;
    uint256 buf;
    uint8 i;

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
  }

  function getYear(uint256 timestamp) internal pure returns (uint16) {
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

  function getMonth(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).month;
  }

  function getDay(uint256 timestamp) internal pure returns (uint8) {
    return parseTimestamp(timestamp).day;
  }

  function getHour(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60 / 60) % 24);
  }

  function getMinute(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / 60) % 60);
  }

  function getSecond(uint256 timestamp) internal pure returns (uint8) {
    return uint8(timestamp % 60);
  }

  function getWeekday(uint256 timestamp) internal pure returns (uint8) {
    return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, 0, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, 0, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute
  ) internal pure returns (uint256 timestamp) {
    return toTimestamp(year, month, day, hour, minute, 0);
  }

  function toTimestamp(
    uint16 year,
    uint8 month,
    uint8 day,
    uint8 hour,
    uint8 minute,
    uint8 second
  ) internal pure returns (uint256 timestamp) {
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

// SPDX-License-Identifier: Apache 2.0

/*
 * @title String & slice utility library for Solidity contracts.
 * @author Nick Johnson <[email protected]>
 *
 * @dev Functionality in this library is largely implemented using an
 *      abstraction called a 'slice'. A slice represents a part of a string -
 *      anything from the entire string to a single character, or even no
 *      characters at all (a 0-length slice). Since a slice only has to specify
 *      an offset and a length, copying and manipulating slices is a lot less
 *      expensive than copying and manipulating the strings they reference.
 *
 *      To further reduce gas costs, most functions on slice that need to return
 *      a slice modify the original one instead of allocating a new one; for
 *      instance, `s.split(".")` will return the text up to the first '.',
 *      modifying s to only contain the remainder of the string after the '.'.
 *      In situations where you do not want to modify the original slice, you
 *      can make a copy first with `.copy()`, for example:
 *      `s.copy().split(".")`. Try and avoid using this idiom in loops; since
 *      Solidity has no memory management, it will result in allocating many
 *      short-lived slices that are later discarded.
 *
 *      Functions that return two slices come in two versions: a non-allocating
 *      version that takes the second slice as an argument, modifying it in
 *      place, and an allocating version that allocates and returns the second
 *      slice; see `nextRune` for example.
 *
 *      Functions that have to copy string data will return strings rather than
 *      slices; these can be cast back to slices for further processing if
 *      required.
 *
 *      For convenience, some functions are provided with non-modifying
 *      variants that create a new slice and return both; for instance,
 *      `s.splitNew('.')` leaves s unmodified, and returns two values
 *      corresponding to the left and right parts of the string.
 */

pragma solidity ^0.8.0;

library strings {
  struct slice {
    uint256 _len;
    uint256 _ptr;
  }

  function memcpy(
    uint256 dest,
    uint256 src,
    uint256 len
  ) private pure {
    // Copy word-length chunks while possible
    for (; len >= 32; len -= 32) {
      assembly {
        mstore(dest, mload(src))
      }
      dest += 32;
      src += 32;
    }

    // Copy remaining bytes
    uint256 mask = type(uint256).max;
    if (len > 0) {
      mask = 256**(32 - len) - 1;
    }
    assembly {
      let srcpart := and(mload(src), not(mask))
      let destpart := and(mload(dest), mask)
      mstore(dest, or(destpart, srcpart))
    }
  }

  /*
   * @dev Returns a slice containing the entire string.
   * @param self The string to make a slice from.
   * @return A newly allocated slice containing the entire string.
   */
  function toSlice(string memory self) internal pure returns (slice memory) {
    uint256 ptr;
    assembly {
      ptr := add(self, 0x20)
    }
    return slice(bytes(self).length, ptr);
  }

  /*
   * @dev Returns the length of a null-terminated bytes32 string.
   * @param self The value to find the length of.
   * @return The length of the string, from 0 to 32.
   */
  function len(bytes32 self) internal pure returns (uint256) {
    uint256 ret;
    if (self == 0) return 0;
    if (uint256(self) & type(uint128).max == 0) {
      ret += 16;
      self = bytes32(uint256(self) / 0x100000000000000000000000000000000);
    }
    if (uint256(self) & type(uint64).max == 0) {
      ret += 8;
      self = bytes32(uint256(self) / 0x10000000000000000);
    }
    if (uint256(self) & type(uint32).max == 0) {
      ret += 4;
      self = bytes32(uint256(self) / 0x100000000);
    }
    if (uint256(self) & type(uint16).max == 0) {
      ret += 2;
      self = bytes32(uint256(self) / 0x10000);
    }
    if (uint256(self) & type(uint8).max == 0) {
      ret += 1;
    }
    return 32 - ret;
  }

  /*
   * @dev Returns a slice containing the entire bytes32, interpreted as a
   *      null-terminated utf-8 string.
   * @param self The bytes32 value to convert to a slice.
   * @return A new slice containing the value of the input argument up to the
   *         first null.
   */
  function toSliceB32(bytes32 self) internal pure returns (slice memory ret) {
    // Allocate space for `self` in memory, copy it there, and point ret at it
    assembly {
      let ptr := mload(0x40)
      mstore(0x40, add(ptr, 0x20))
      mstore(ptr, self)
      mstore(add(ret, 0x20), ptr)
    }
    ret._len = len(self);
  }

  /*
   * @dev Returns a new slice containing the same data as the current slice.
   * @param self The slice to copy.
   * @return A new slice containing the same data as `self`.
   */
  function copy(slice memory self) internal pure returns (slice memory) {
    return slice(self._len, self._ptr);
  }

  /*
   * @dev Copies a slice to a new string.
   * @param self The slice to copy.
   * @return A newly allocated string containing the slice's text.
   */
  function toString(slice memory self) internal pure returns (string memory) {
    string memory ret = new string(self._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    memcpy(retptr, self._ptr, self._len);
    return ret;
  }

  /*
   * @dev Returns the length in runes of the slice. Note that this operation
   *      takes time proportional to the length of the slice; avoid using it
   *      in loops, and call `slice.empty()` if you only need to know whether
   *      the slice is empty or not.
   * @param self The slice to operate on.
   * @return The length of the slice in runes.
   */
  function len(slice memory self) internal pure returns (uint256 l) {
    // Starting at ptr-31 means the LSB will be the byte we care about
    uint256 ptr = self._ptr - 31;
    uint256 end = ptr + self._len;
    for (l = 0; ptr < end; l++) {
      uint8 b;
      assembly {
        b := and(mload(ptr), 0xFF)
      }
      if (b < 0x80) {
        ptr += 1;
      } else if (b < 0xE0) {
        ptr += 2;
      } else if (b < 0xF0) {
        ptr += 3;
      } else if (b < 0xF8) {
        ptr += 4;
      } else if (b < 0xFC) {
        ptr += 5;
      } else {
        ptr += 6;
      }
    }
  }

  /*
   * @dev Returns true if the slice is empty (has a length of 0).
   * @param self The slice to operate on.
   * @return True if the slice is empty, False otherwise.
   */
  function empty(slice memory self) internal pure returns (bool) {
    return self._len == 0;
  }

  /*
   * @dev Returns a positive number if `other` comes lexicographically after
   *      `self`, a negative number if it comes before, or zero if the
   *      contents of the two slices are equal. Comparison is done per-rune,
   *      on unicode codepoints.
   * @param self The first slice to compare.
   * @param other The second slice to compare.
   * @return The result of the comparison.
   */
  function compare(slice memory self, slice memory other)
    internal
    pure
    returns (int256)
  {
    uint256 shortest = self._len;
    if (other._len < self._len) shortest = other._len;

    uint256 selfptr = self._ptr;
    uint256 otherptr = other._ptr;
    for (uint256 idx = 0; idx < shortest; idx += 32) {
      uint256 a;
      uint256 b;
      assembly {
        a := mload(selfptr)
        b := mload(otherptr)
      }
      if (a != b) {
        // Mask out irrelevant bytes and check again
        uint256 mask = type(uint256).max; // 0xffff...
        if (shortest < 32) {
          mask = ~(2**(8 * (32 - shortest + idx)) - 1);
        }
        unchecked {
          uint256 diff = (a & mask) - (b & mask);
          if (diff != 0) return int256(diff);
        }
      }
      selfptr += 32;
      otherptr += 32;
    }
    return int256(self._len) - int256(other._len);
  }

  /*
   * @dev Returns true if the two slices contain the same text.
   * @param self The first slice to compare.
   * @param self The second slice to compare.
   * @return True if the slices are equal, false otherwise.
   */
  function equals(slice memory self, slice memory other)
    internal
    pure
    returns (bool)
  {
    return compare(self, other) == 0;
  }

  /*
   * @dev Extracts the first rune in the slice into `rune`, advancing the
   *      slice to point to the next rune and returning `self`.
   * @param self The slice to operate on.
   * @param rune The slice that will contain the first rune.
   * @return `rune`.
   */
  function nextRune(slice memory self, slice memory rune)
    internal
    pure
    returns (slice memory)
  {
    rune._ptr = self._ptr;

    if (self._len == 0) {
      rune._len = 0;
      return rune;
    }

    uint256 l;
    uint256 b;
    // Load the first byte of the rune into the LSBs of b
    assembly {
      b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF)
    }
    if (b < 0x80) {
      l = 1;
    } else if (b < 0xE0) {
      l = 2;
    } else if (b < 0xF0) {
      l = 3;
    } else {
      l = 4;
    }

    // Check for truncated codepoints
    if (l > self._len) {
      rune._len = self._len;
      self._ptr += self._len;
      self._len = 0;
      return rune;
    }

    self._ptr += l;
    self._len -= l;
    rune._len = l;
    return rune;
  }

  /*
   * @dev Returns the first rune in the slice, advancing the slice to point
   *      to the next rune.
   * @param self The slice to operate on.
   * @return A slice containing only the first rune from `self`.
   */
  function nextRune(slice memory self)
    internal
    pure
    returns (slice memory ret)
  {
    nextRune(self, ret);
  }

  /*
   * @dev Returns the number of the first codepoint in the slice.
   * @param self The slice to operate on.
   * @return The number of the first codepoint in the slice.
   */
  function ord(slice memory self) internal pure returns (uint256 ret) {
    if (self._len == 0) {
      return 0;
    }

    uint256 word;
    uint256 length;
    uint256 divisor = 2**248;

    // Load the rune into the MSBs of b
    assembly {
      word := mload(mload(add(self, 32)))
    }
    uint256 b = word / divisor;
    if (b < 0x80) {
      ret = b;
      length = 1;
    } else if (b < 0xE0) {
      ret = b & 0x1F;
      length = 2;
    } else if (b < 0xF0) {
      ret = b & 0x0F;
      length = 3;
    } else {
      ret = b & 0x07;
      length = 4;
    }

    // Check for truncated codepoints
    if (length > self._len) {
      return 0;
    }

    for (uint256 i = 1; i < length; i++) {
      divisor = divisor / 256;
      b = (word / divisor) & 0xFF;
      if (b & 0xC0 != 0x80) {
        // Invalid UTF-8 sequence
        return 0;
      }
      ret = (ret * 64) | (b & 0x3F);
    }

    return ret;
  }

  /*
   * @dev Returns the keccak-256 hash of the slice.
   * @param self The slice to hash.
   * @return The hash of the slice.
   */
  function keccak(slice memory self) internal pure returns (bytes32 ret) {
    assembly {
      ret := keccak256(mload(add(self, 32)), mload(self))
    }
  }

  /*
   * @dev Returns true if `self` starts with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function startsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    if (self._len < needle._len) {
      return false;
    }

    if (self._ptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let selfptr := mload(add(self, 0x20))
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }
    return equal;
  }

  /*
   * @dev If `self` starts with `needle`, `needle` is removed from the
   *      beginning of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function beyond(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    bool equal = true;
    if (self._ptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let selfptr := mload(add(self, 0x20))
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
      self._ptr += needle._len;
    }

    return self;
  }

  /*
   * @dev Returns true if the slice ends with `needle`.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return True if the slice starts with the provided text, false otherwise.
   */
  function endsWith(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    if (self._len < needle._len) {
      return false;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;

    if (selfptr == needle._ptr) {
      return true;
    }

    bool equal;
    assembly {
      let length := mload(needle)
      let needleptr := mload(add(needle, 0x20))
      equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
    }

    return equal;
  }

  /*
   * @dev If `self` ends with `needle`, `needle` is removed from the
   *      end of `self`. Otherwise, `self` is unmodified.
   * @param self The slice to operate on.
   * @param needle The slice to search for.
   * @return `self`
   */
  function until(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    if (self._len < needle._len) {
      return self;
    }

    uint256 selfptr = self._ptr + self._len - needle._len;
    bool equal = true;
    if (selfptr != needle._ptr) {
      assembly {
        let length := mload(needle)
        let needleptr := mload(add(needle, 0x20))
        equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
      }
    }

    if (equal) {
      self._len -= needle._len;
    }

    return self;
  }

  // Returns the memory address of the first byte of the first occurrence of
  // `needle` in `self`, or the first byte after `self` if not found.
  function findPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr = selfptr;
    uint256 idx;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        uint256 end = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr >= end) return selfptr + selflen;
          ptr++;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }

        for (idx = 0; idx <= selflen - needlelen; idx++) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr;
          ptr += 1;
        }
      }
    }
    return selfptr + selflen;
  }

  // Returns the memory address of the first byte after the last occurrence of
  // `needle` in `self`, or the address of `self` if not found.
  function rfindPtr(
    uint256 selflen,
    uint256 selfptr,
    uint256 needlelen,
    uint256 needleptr
  ) private pure returns (uint256) {
    uint256 ptr;

    if (needlelen <= selflen) {
      if (needlelen <= 32) {
        bytes32 mask;
        if (needlelen > 0) {
          mask = bytes32(~(2**(8 * (32 - needlelen)) - 1));
        }

        bytes32 needledata;
        assembly {
          needledata := and(mload(needleptr), mask)
        }

        ptr = selfptr + selflen - needlelen;
        bytes32 ptrdata;
        assembly {
          ptrdata := and(mload(ptr), mask)
        }

        while (ptrdata != needledata) {
          if (ptr <= selfptr) return selfptr;
          ptr--;
          assembly {
            ptrdata := and(mload(ptr), mask)
          }
        }
        return ptr + needlelen;
      } else {
        // For long needles, use hashing
        bytes32 hash;
        assembly {
          hash := keccak256(needleptr, needlelen)
        }
        ptr = selfptr + (selflen - needlelen);
        while (ptr >= selfptr) {
          bytes32 testHash;
          assembly {
            testHash := keccak256(ptr, needlelen)
          }
          if (hash == testHash) return ptr + needlelen;
          ptr -= 1;
        }
      }
    }
    return selfptr;
  }

  /*
   * @dev Modifies `self` to contain everything from the first occurrence of
   *      `needle` to the end of the slice. `self` is set to the empty slice
   *      if `needle` is not found.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function find(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len -= ptr - self._ptr;
    self._ptr = ptr;
    return self;
  }

  /*
   * @dev Modifies `self` to contain the part of the string from the start of
   *      `self` to the end of the first occurrence of `needle`. If `needle`
   *      is not found, `self` is set to the empty slice.
   * @param self The slice to search and modify.
   * @param needle The text to search for.
   * @return `self`.
   */
  function rfind(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory)
  {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    self._len = ptr - self._ptr;
    return self;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and `token` to everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function split(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = self._ptr;
    token._len = ptr - self._ptr;
    if (ptr == self._ptr + self._len) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
      self._ptr = ptr + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything after the first
   *      occurrence of `needle`, and returning everything before it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` up to the first occurrence of `delim`.
   */
  function split(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    split(self, needle, token);
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and `token` to everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and `token` is set to the entirety of `self`.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @param token An output parameter to which the first token is written.
   * @return `token`.
   */
  function rsplit(
    slice memory self,
    slice memory needle,
    slice memory token
  ) internal pure returns (slice memory) {
    uint256 ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
    token._ptr = ptr;
    token._len = self._len - (ptr - self._ptr);
    if (ptr == self._ptr) {
      // Not found
      self._len = 0;
    } else {
      self._len -= token._len + needle._len;
    }
    return token;
  }

  /*
   * @dev Splits the slice, setting `self` to everything before the last
   *      occurrence of `needle`, and returning everything after it. If
   *      `needle` does not occur in `self`, `self` is set to the empty slice,
   *      and the entirety of `self` is returned.
   * @param self The slice to split.
   * @param needle The text to search for in `self`.
   * @return The part of `self` after the last occurrence of `delim`.
   */
  function rsplit(slice memory self, slice memory needle)
    internal
    pure
    returns (slice memory token)
  {
    rsplit(self, needle, token);
  }

  /*
   * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return The number of occurrences of `needle` found in `self`.
   */
  function count(slice memory self, slice memory needle)
    internal
    pure
    returns (uint256 cnt)
  {
    uint256 ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) +
      needle._len;
    while (ptr <= self._ptr + self._len) {
      cnt++;
      ptr =
        findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) +
        needle._len;
    }
  }

  /*
   * @dev Returns True if `self` contains `needle`.
   * @param self The slice to search.
   * @param needle The text to search for in `self`.
   * @return True if `needle` is found in `self`, false otherwise.
   */
  function contains(slice memory self, slice memory needle)
    internal
    pure
    returns (bool)
  {
    return
      rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
  }

  /*
   * @dev Returns a newly allocated string containing the concatenation of
   *      `self` and `other`.
   * @param self The first slice to concatenate.
   * @param other The second slice to concatenate.
   * @return The concatenation of the two strings.
   */
  function concat(slice memory self, slice memory other)
    internal
    pure
    returns (string memory)
  {
    string memory ret = new string(self._len + other._len);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }
    memcpy(retptr, self._ptr, self._len);
    memcpy(retptr + self._len, other._ptr, other._len);
    return ret;
  }

  /*
   * @dev Joins an array of slices, using `self` as a delimiter, returning a
   *      newly allocated string.
   * @param self The delimiter to use.
   * @param parts A list of slices to join.
   * @return A newly allocated string containing all the slices in `parts`,
   *         joined with `self`.
   */
  function join(slice memory self, slice[] memory parts)
    internal
    pure
    returns (string memory)
  {
    if (parts.length == 0) return "";

    uint256 length = self._len * (parts.length - 1);
    for (uint256 i = 0; i < parts.length; i++) length += parts[i]._len;

    string memory ret = new string(length);
    uint256 retptr;
    assembly {
      retptr := add(ret, 32)
    }

    for (uint256 i = 0; i < parts.length; i++) {
      memcpy(retptr, parts[i]._ptr, parts[i]._len);
      retptr += parts[i]._len;
      if (i < parts.length - 1) {
        memcpy(retptr, self._ptr, self._len);
        retptr += self._len;
      }
    }

    return ret;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import { GameV1Interface } from "./interfaces/GameV1Interface.sol";
import { CronUpkeepInterface } from "./interfaces/CronUpkeepInterface.sol";

import { Cron as CronExternal } from "@chainlink/contracts/src/v0.8/libraries/external/Cron.sol";

contract GameV1 is GameV1Interface, ReentrancyGuard, Pausable {
    using Address for address;

    bool private _isBase;

    uint256 private randNonce;

    address public owner;
    address public creator;
    address public factory;

    address public cronUpkeep;
    string public encodedCron;
    uint256 private cronUpkeepJobId;

    uint256 public registrationAmount;

    uint256 public constant MAX_TREASURY_FEE = 1000; // 10%
    uint256 public constant MAX_CREATOR_FEE = 500; // 5%

    uint256 public treasuryFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public treasuryAmount; // treasury amount that was not claimed

    uint256 public creatorFee; // treasury rate (e.g. 200 = 2%, 150 = 1.50%)
    uint256 public creatorAmount; // treasury amount that was not claimed

    uint256 public id; // id is fix and represent the fixed id for the game
    uint256 public roundId; // roundId gets incremented every time the game restarts

    bytes32 public name;

    uint256 public version;

    uint256 public playTimeRange; // time length of a round in hours

    uint256 public maxPlayers;

    bool public isInProgress; // helps the keeper determine if a game has started or if we need to start it

    address[] public playerAddresses;
    mapping(address => Player) public players;
    mapping(uint256 => Winner[]) winners;
    mapping(uint256 => Prize[]) prizes;

    ///
    /// CONSTRUCTOR AND INITIALISATION
    ///

    /**
     * @notice Constructor that define itself as base
     */
    constructor() {
        _isBase = true;
    }

    /**
     * @notice Create a new Game Implementation by cloning the base contract
     * @param _initialization the initialisation data with params as follow :
     *  @param _initialization.creator the game creator
     *  @param _initialization.owner the general admin address
     *  @param _initialization.cronUpkeep the cron upkeep address
     *  @param _initialization.name the game name
     *  @param _initialization.version the version of the game implementation
     *  @param _initialization.id the unique game id (fix)
     *  @param _initialization.playTimeRange the time range during which a player can play in hour
     *  @param _initialization.maxPlayers the maximum number of players for a game
     *  @param _initialization.registrationAmount the amount that players will need to pay to enter in the game
     *  @param _initialization.treasuryFee the treasury fee in percent
     *  @param _initialization.creatorFee creator fee in percent
     *  @param _initialization.encodedCron the cron string
     *  @param _initialization.prizes the cron string
     * @dev TODO NEXT VERSION Remove _isGameAllPrizesStandard limitation to include other prize typ
     * @dev TODO NEXT VERSION Make it only accessible to factory
     */
    function initialize(Initialization calldata _initialization)
        external
        payable
        override
        onlyIfNotBase
        onlyIfNotAlreadyInitialized
        onlyAllowedNumberOfPlayers(_initialization.maxPlayers)
        onlyAllowedPlayTimeRange(_initialization.playTimeRange)
        onlyTreasuryFee(_initialization.treasuryFee)
        onlyCreatorFee(_initialization.creatorFee)
        onlyIfPrizesParam(_initialization.prizes)
    {
        owner = _initialization.owner;
        creator = _initialization.creator;
        factory = msg.sender;

        name = _initialization.name;

        randNonce = 0;

        registrationAmount = _initialization.registrationAmount;
        treasuryFee = _initialization.treasuryFee;
        creatorFee = _initialization.creatorFee;

        treasuryAmount = 0;
        creatorAmount = 0;

        id = _initialization.id;
        version = _initialization.version;

        roundId = 0;
        playTimeRange = _initialization.playTimeRange;
        maxPlayers = _initialization.maxPlayers;

        encodedCron = _initialization.encodedCron;
        bytes memory encodedCronBytes = CronExternal.toEncodedSpec(encodedCron);

        cronUpkeep = _initialization.cronUpkeep;

        // Setup prizes structure
        _checkIfPrizeAmountIfNeeded(_initialization.prizes);
        _addPrizes(_initialization.prizes);

        // Verify Game Configuration :
        // Game can only be payable only if also standard
        // OR Game can be not payable and everything else
        require((_isGamePayable() && _isGameAllPrizesStandard()) || !_isGamePayable(), "Configuration missmatch");

        // Limitation for current version as standard for NFT is not implemented
        require(_isGameAllPrizesStandard(), "This version only allow standard prize");

        // Register the keeper job
        uint256 nextCronJobIDs = CronUpkeepInterface(cronUpkeep).getNextCronJobIDs();
        cronUpkeepJobId = nextCronJobIDs;

        CronUpkeepInterface(cronUpkeep).createCronJobFromEncodedSpec(
            address(this),
            bytes("triggerDailyCheckpoint()"),
            encodedCronBytes
        );
    }

    /**
     * @notice Function that is called by the keeper when game is ready to start
     * @dev TODO NEXT VERSION remove this function in next smart contract version
     */
    function startGame() external override onlyAdminOrCreator whenNotPaused onlyIfFull {
        _startGame();
    }

    ///
    /// MAIN FUNCTIONS
    ///

    /**
     * @notice Function that allow players to register for a game
     * @dev Creator cannot register for his own game
     */
    function registerForGame()
        external
        payable
        override
        onlyHumans
        whenNotPaused
        onlyIfGameIsNotInProgress
        onlyIfNotFull
        onlyIfNotAlreadyEntered
        onlyRegistrationAmount
        onlyNotCreator
    {
        players[msg.sender] = Player({
            playerAddress: msg.sender,
            roundCount: 0,
            hasPlayedRound: false,
            hasLost: false,
            isSplitOk: false,
            position: playerAddresses.length + 1,
            roundRangeUpperLimit: 0,
            roundRangeLowerLimit: 0
        });
        playerAddresses.push(msg.sender);

        emit RegisteredForGame(players[msg.sender].playerAddress, playerAddresses.length);
    }

    /**
     * @notice Function that allow players to play for the current round
     * @dev Creator cannot play for his own game
     * @dev Callable by remaining players
     */
    function playRound()
        external
        override
        onlyHumans
        whenNotPaused
        onlyIfFull
        onlyIfAlreadyEntered
        onlyIfHasNotLost
        onlyIfHasNotPlayedThisRound
        onlyNotCreator
        onlyIfGameIsInProgress
    {
        Player storage player = players[msg.sender];

        //Check if attempt is in the allowed time slot
        if (block.timestamp < player.roundRangeLowerLimit || block.timestamp > player.roundRangeUpperLimit)
            _setPlayerAsHavingLost(player);
        else {
            player.hasPlayedRound = true;
            player.roundCount += 1;
            emit PlayedRound(player.playerAddress);
        }
    }

    /**
     * @notice Function that is called by the keeper based on the keeper cron
     * @dev Callable by admin or keeper
     * @dev TODO NEXT VERSION Update triggerDailyCheckpoint to make it only callable by keeper
     */
    function triggerDailyCheckpoint() external override onlyAdminOrKeeper whenNotPaused {
        if (isInProgress) {
            _refreshPlayerStatus();
            _checkIfGameEnded();
        } else if (playerAddresses.length == maxPlayers) _startGame();
    }

    /**
     * @notice Function that allow player to vote to split pot
     * @dev Only callable if less than 50% of the players remain
     * @dev Callable by remaining players
     */
    function voteToSplitPot()
        external
        override
        onlyIfGameIsInProgress
        onlyIfAlreadyEntered
        onlyIfHasNotLost
        onlyIfPlayersLowerHalfRemaining
        onlyIfGameIsSplittable
    {
        players[msg.sender].isSplitOk = true;
        emit VoteToSplitPot(roundId, players[msg.sender].playerAddress);
    }

    /**
     * @notice Function that is called by a winner to claim his prize
     * @dev TODO NEXT VERSION Update claim process according to prize type
     */
    function claimPrize(uint256 _roundId) external override onlyIfRoundId(_roundId) {
        for (uint256 i = 0; i < winners[_roundId].length; i++)
            if (winners[_roundId][i].playerAddress == msg.sender) {
                require(!winners[_roundId][i].prizeClaimed, "Prize for this game already claimed");
                require(address(this).balance >= winners[_roundId][i].amountWon, "Not enough funds in contract");

                winners[_roundId][i].prizeClaimed = true;
                emit GamePrizeClaimed(msg.sender, _roundId, winners[_roundId][i].amountWon);
                _safeTransfert(msg.sender, winners[_roundId][i].amountWon);
                return;
            }
        require(false, "Player did not win this game");
    }

    /**
     * @notice Prizes adding management
     * @dev Callable by admin or creator
     * @dev TODO NEXT VERSION add a taxe for creator in case of free games
     *      Need to store the factory gameCreationAmount in this contract on initialisation
     * @dev TODO NEXT VERSION Remove _isGameAllPrizesStandard limitation to include other prize typ
     */
    function addPrizes(Prize[] memory _prizes)
        external
        payable
        override
        onlyAdminOrCreator
        onlyIfGameIsNotInProgress
        onlyIfPrizesParam(_prizes)
        onlyIfPrizeAmountIfNeeded(_prizes)
    {
        _addPrizes(_prizes);
        // Limitation for current version as standard for NFT is not implemented
        require(_isGameAllPrizesStandard(), "This version only allow standard prize");
    }

    ///
    /// INTERNAL FUNCTIONS
    ///

    /**
     * @notice Start the game(called when all conditions are ok)
     */
    function _startGame() internal {
        for (uint256 i = 0; i < playerAddresses.length; i++) _resetRoundRange(players[playerAddresses[i]]);
        isInProgress = true;
        emit StartedGame(block.timestamp, playerAddresses.length);
    }

    /**
     * @notice Reset the game (called at the end of the current game)
     */
    function _resetGame() internal {
        isInProgress = false;
        for (uint256 i = 0; i < playerAddresses.length; i++) delete players[playerAddresses[i]];

        delete playerAddresses;

        emit ResetGame(block.timestamp, roundId);
        roundId += 1;

        // Stop game if not payable to allow creator to add prizes
        if (!_isGamePayable()) return _pauseGame();

        Prize[] storage oldPrize = prizes[roundId - 1];

        for (uint256 i = 0; i < oldPrize.length; i++) _addPrize(oldPrize[i]);
    }

    /**
     * @notice Transfert funds
     * @param _receiver the receiver address
     * @param _amount the amount to transfert
     * @dev TODO NEXT VERSION use SafeERC20 library from OpenZeppelin
     */
    function _safeTransfert(address _receiver, uint256 _amount) internal onlyIfEnoughtBalance(_amount) {
        (bool success, ) = _receiver.call{ value: _amount }("");

        if (!success) {
            emit FailedTransfer(_receiver, _amount);
            require(false, "Transfer failed.");
        }
    }

    /**
     * @notice Check if game as ended
     * If so, it will create winners and reset the game
     */
    function _checkIfGameEnded() internal {
        uint256 remainingPlayersCount = _getRemainingPlayersCount();
        bool isPlitPot = _isAllPlayersSplitOk();

        if (remainingPlayersCount > 1 && !isPlitPot) return;

        uint256 treasuryRoundAmount = 0;
        uint256 creatorRoundAmount = 0;

        Prize[] memory _prizes = prizes[roundId];

        if (remainingPlayersCount == 1)
            // Distribute prizes over winners
            for (uint256 i = 0; i < playerAddresses.length; i++) {
                Player memory currentPlayer = players[playerAddresses[i]];

                if (!currentPlayer.hasLost) {
                    // Player is winner
                    treasuryRoundAmount = (_prizes[0].amount * treasuryFee) / 10000;
                    creatorRoundAmount = (_prizes[0].amount * creatorFee) / 10000;
                    uint256 rewardAmount = _prizes[0].amount - treasuryRoundAmount - creatorRoundAmount;

                    _addWinner(0, currentPlayer.playerAddress, rewardAmount);
                } else if (i < _prizes.length && currentPlayer.position <= _prizes[i].position) {
                    // Player has won a prize
                    treasuryRoundAmount = (_prizes[0].amount * treasuryFee) / 10000;
                    creatorRoundAmount = (_prizes[0].amount * creatorFee) / 10000;
                    uint256 rewardAmount = _prizes[0].amount - treasuryRoundAmount - creatorRoundAmount;

                    _addWinner(currentPlayer.position, currentPlayer.playerAddress, rewardAmount);
                }
            }

        if (isPlitPot) {
            // Split with remaining player
            uint256 prizepool = 0;
            for (uint256 i = 0; i < _prizes.length; i++) prizepool += _prizes[i].amount;

            treasuryRoundAmount = (prizepool * treasuryFee) / 10000;
            creatorRoundAmount = (prizepool * creatorFee) / 10000;
            uint256 rewardAmount = prizepool - treasuryRoundAmount - creatorRoundAmount;
            uint256 splittedPrize = rewardAmount / remainingPlayersCount;

            for (uint256 i = 0; i < playerAddresses.length; i++) {
                Player memory currentPlayer = players[playerAddresses[i]];
                if (!currentPlayer.hasLost && currentPlayer.isSplitOk)
                    _addWinner(1, currentPlayer.playerAddress, splittedPrize);
            }
            emit GameSplitted(roundId, remainingPlayersCount, splittedPrize);
        }

        if (remainingPlayersCount == 0)
            // Creator will take everything except the first prize
            for (uint256 i = 0; i < _prizes.length; i++) {
                treasuryRoundAmount = (_prizes[i].amount * treasuryFee) / 10000;
                creatorRoundAmount = (_prizes[i].amount * creatorFee) / 10000;

                uint256 rewardAmount = _prizes[i].amount - treasuryRoundAmount - creatorRoundAmount;

                address winnerAddress = i == 1 ? owner : creator;
                _addWinner(_prizes[i].position, winnerAddress, rewardAmount);
            }

        treasuryAmount += treasuryRoundAmount;
        creatorAmount += creatorRoundAmount;
        _resetGame();
    }

    /**
     * @notice Refresh players status for remaining players
     */
    function _refreshPlayerStatus() internal {
        // If everyone is ok to split, we wait
        if (_isAllPlayersSplitOk()) return;

        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            // Refresh player status to having lost if player has not played
            if (!player.hasPlayedRound && !player.hasLost) _setPlayerAsHavingLost(player);
            else {
                // Reset round limits and round status for each remaining user
                _resetRoundRange(player);
                player.hasPlayedRound = false;
            }
        }
    }

    function _addWinner(
        uint256 _position,
        address _playerAddress,
        uint256 _amount
    ) internal {
        winners[roundId].push(
            Winner({
                roundId: roundId,
                position: _position,
                playerAddress: _playerAddress,
                amountWon: _amount,
                prizeClaimed: false
            })
        );
        emit GameWon(roundId, winners[roundId].length, _playerAddress, _amount);
    }

    /**
     * @notice Check if msg.value have the right amount if needed
     * @param _prizes list of prize details
     */
    function _checkIfPrizeAmountIfNeeded(Prize[] memory _prizes) internal view {
        if (_isGamePayable()) return;

        uint256 prizepool = 0;
        for (uint256 i = 0; i < _prizes.length; i++) prizepool += _prizes[i].amount;

        require(msg.value == prizepool, "Need to send prizepool amount");
    }

    /**
     * @notice Internal function for prizes adding management
     * @param _prizes list of prize details
     */
    function _addPrizes(Prize[] memory _prizes) internal {
        uint256 prizepool = 0;
        for (uint256 i = 0; i < _prizes.length; i++) {
            _addPrize(_prizes[i]);
            prizepool += _prizes[i].amount;
        }

        if (_isGamePayable()) {
            uint256 prizepoolVerify = registrationAmount * maxPlayers;
            require(prizepool == prizepoolVerify, "Wrong total amount to won");
        }
    }

    /**
     * @notice Internal function to add a Prize
     * @param _prize the prize to add
     */
    function _addPrize(Prize memory _prize) internal {
        prizes[roundId].push(_prize);
        emit PrizeAdded(
            roundId,
            _prize.position,
            _prize.amount,
            _prize.standard,
            _prize.contractAddress,
            _prize.tokenId
        );
    }

    /**
     * @notice Internal function to check if game is payable
     * @return isPayable set to true if game is payable
     */
    function _isGamePayable() internal view returns (bool isPayable) {
        return registrationAmount > 0;
    }

    /**
     * @notice Internal function to check if all games are of type standard
     * @return isStandard set to true if all games are of type standard
     */
    function _isGameAllPrizesStandard() internal view returns (bool isStandard) {
        for (uint256 i = 0; i < prizes[roundId].length; i++) if (prizes[roundId][i].standard != 0) return false;
        return true;
    }

    /**
     * @notice Returns a number between 0 and 24 minus the current length of a round
     * @param _playerAddress the player address
     * @return randomNumber the generated number
     */
    function _randMod(address _playerAddress) internal returns (uint256 randomNumber) {
        // Increase nonce
        randNonce++;
        uint256 maxUpperRange = 25 - playTimeRange; // We use 25 because modulo excludes the higher limit
        uint256 randNumber = uint256(keccak256(abi.encodePacked(block.timestamp, _playerAddress, randNonce))) %
            maxUpperRange;
        return randNumber;
    }

    /**
     * @notice Reset the round range for a player
     * @param _player the player
     */
    function _resetRoundRange(Player storage _player) internal {
        uint256 newRoundLowerLimit = _randMod(_player.playerAddress);
        _player.roundRangeLowerLimit = block.timestamp + newRoundLowerLimit * 60 * 60;
        _player.roundRangeUpperLimit = _player.roundRangeLowerLimit + playTimeRange * 60 * 60;
    }

    /**
     * @notice Update looser player
     * @param _player the player
     */
    function _setPlayerAsHavingLost(Player storage _player) internal {
        _player.position = _getRemainingPlayersCount();
        _player.hasLost = true;
        _player.isSplitOk = false;

        emit GameLost(roundId, _player.playerAddress, _player.roundCount);
    }

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function _isAllPlayersSplitOk() internal view returns (bool isSplitOk) {
        uint256 remainingPlayersSplitOkCounter = 0;
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        for (uint256 i = 0; i < playerAddresses.length; i++)
            if (players[playerAddresses[i]].isSplitOk) remainingPlayersSplitOkCounter++;

        return remainingPlayersLength != 0 && remainingPlayersSplitOkCounter == remainingPlayersLength;
    }

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function _getRemainingPlayersCount() internal view returns (uint256 remainingPlayersCount) {
        uint256 remainingPlayers = 0;
        for (uint256 i = 0; i < playerAddresses.length; i++)
            if (!players[playerAddresses[i]].hasLost) remainingPlayers++;

        return remainingPlayers;
    }

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */

    function _pauseGame() internal whenNotPaused {
        _pause();
        CronUpkeepInterface(cronUpkeep).deleteCronJob(cronUpkeepJobId);
    }

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function _unpauseGame() internal whenPaused {
        _unpause();

        // Reset round limits and round status for each remaining user
        for (uint256 i = 0; i < playerAddresses.length; i++) {
            Player storage player = players[playerAddresses[i]];
            if (!player.hasLost) {
                _resetRoundRange(player);
                player.hasPlayedRound = false;
            }
        }
        uint256 nextCronJobIDs = CronUpkeepInterface(cronUpkeep).getNextCronJobIDs();
        cronUpkeepJobId = nextCronJobIDs;

        bytes memory encodedCronBytes = CronExternal.toEncodedSpec(encodedCron);

        CronUpkeepInterface(cronUpkeep).createCronJobFromEncodedSpec(
            address(this),
            bytes("triggerDailyCheckpoint()"),
            encodedCronBytes
        );
    }

    ///
    /// GETTERS FUNCTIONS
    ///

    /**
     * @notice Return game informations
     * @return gameData the game status data with params as follow :
     *  gameData.creator the creator address of the game
     *  gameData.roundId the roundId of the game
     *  gameData.name the name of the game
     *  gameData.playerAddressesCount the number of registered players
     *  gameData.maxPlayers the maximum players of the game
     *  gameData.registrationAmount the registration amount of the game
     *  gameData.playTimeRange the player time range of the game
     *  gameData.treasuryFee the treasury fee of the game
     *  gameData.creatorFee the creator fee of the game
     *  gameData.isPaused a boolean set to true if game is paused
     *  gameData.isInProgress a boolean set to true if game is in progress
     */
    function getGameData() external view override returns (GameData memory gameData) {
        return
            GameData({
                id: id,
                roundId: roundId,
                name: name,
                playerAddressesCount: playerAddresses.length,
                maxPlayers: maxPlayers,
                registrationAmount: registrationAmount,
                playTimeRange: playTimeRange,
                treasuryFee: treasuryFee,
                creatorFee: creatorFee,
                isPaused: paused(),
                isInProgress: isInProgress,
                creator: creator,
                admin: owner,
                encodedCron: encodedCron
            });
    }

    /**
     * @notice Return the players addresses for the current game
     * @return gamePlayerAddresses list of players addresses
     */
    function getPlayerAddresses() external view override returns (address[] memory gamePlayerAddresses) {
        return playerAddresses;
    }

    /**
     * @notice Return a player for the current game
     * @param _player the player address
     * @return gamePlayer if finded
     */
    function getPlayer(address _player) external view override returns (Player memory gamePlayer) {
        return players[_player];
    }

    /**
     * @notice Return the winners for a round id
     * @param _roundId the round id
     * @return gameWinners list of Winner
     */
    function getWinners(uint256 _roundId)
        external
        view
        override
        onlyIfRoundId(_roundId)
        returns (Winner[] memory gameWinners)
    {
        return winners[_roundId];
    }

    /**
     * @notice Return the winners for a round id
     * @param _roundId the round id
     * @return gamePrizes list of Prize
     */
    function getPrizes(uint256 _roundId)
        external
        view
        override
        onlyIfRoundId(_roundId)
        returns (Prize[] memory gamePrizes)
    {
        return prizes[_roundId];
    }

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function isAllPlayersSplitOk() external view override returns (bool isSplitOk) {
        return _isAllPlayersSplitOk();
    }

    /**
     * @notice Check if Game is payable
     * @return isPayable set to true if game is payable, false otherwise
     */
    function isGamePayable() external view override returns (bool isPayable) {
        return _isGamePayable();
    }

    /**
     * @notice Check if Game prizes are standard
     * @return isStandard true if game prizes are standard, false otherwise
     */
    function isGameAllPrizesStandard() external view override returns (bool isStandard) {
        return _isGameAllPrizesStandard();
    }

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function getRemainingPlayersCount() external view override returns (uint256 remainingPlayersCount) {
        return _getRemainingPlayersCount();
    }

    ///
    /// SETTERS FUNCTIONS
    ///

    /**
     * @notice Set the name of the game
     * @param _name the new game name
     * @dev Callable by creator
     */
    function setName(bytes32 _name) external override onlyCreator {
        name = _name;
    }

    /**
     * @notice Set the maximum allowed players for the game
     * @param _maxPlayers the new max players limit
     * @dev Callable by admin or creator
     */
    function setMaxPlayers(uint256 _maxPlayers)
        external
        override
        onlyAdminOrCreator
        onlyAllowedNumberOfPlayers(_maxPlayers)
        onlyIfGameIsNotInProgress
    {
        maxPlayers = _maxPlayers;
    }

    /**
     * @notice Set the creator fee for the game
     * @param _creatorFee the new creator fee in %
     * @dev Callable by admin or creator
     * @dev Callable when game if not in progress
     */
    function setCreatorFee(uint256 _creatorFee)
        external
        override
        onlyAdminOrCreator
        onlyIfGameIsNotInProgress
        onlyCreatorFee(_creatorFee)
    {
        creatorFee = _creatorFee;
    }

    /**
     * @notice Allow creator to withdraw his fee
     * @dev Callable by admin
     */
    function claimCreatorFee()
        external
        override
        onlyCreator
        onlyIfClaimableAmount(creatorAmount)
        onlyIfEnoughtBalance(creatorAmount)
    {
        uint256 currentCreatorAmount = creatorAmount;
        creatorAmount = 0;
        emit CreatorFeeClaimed(currentCreatorAmount);
        _safeTransfert(creator, currentCreatorAmount);
    }

    ///
    /// ADMIN FUNCTIONS
    ///

    /**
     * @notice Withdraw Treasury fee
     * @dev Callable by admin
     */
    function claimTreasuryFee()
        external
        override
        onlyAdmin
        onlyIfClaimableAmount(treasuryAmount)
        onlyIfEnoughtBalance(treasuryAmount)
    {
        uint256 currentTreasuryAmount = treasuryAmount;
        treasuryAmount = 0;
        emit TreasuryFeeClaimed(currentTreasuryAmount);
        _safeTransfert(owner, currentTreasuryAmount);
    }

    /**
     * @notice Set the treasury fee for the game
     * @param _treasuryFee the new treasury fee in %
     * @dev Callable by admin
     * @dev Callable when game if not in progress
     */
    function setTreasuryFee(uint256 _treasuryFee)
        external
        override
        onlyAdmin
        onlyIfGameIsNotInProgress
        onlyTreasuryFee(_treasuryFee)
    {
        treasuryFee = _treasuryFee;
    }

    /**
     * @notice Set the keeper address
     * @param _cronUpkeep the new keeper address
     * @dev Callable by admin or factory
     */
    function setCronUpkeep(address _cronUpkeep) external override onlyAdminOrFactory onlyAddressInit(_cronUpkeep) {
        cronUpkeep = _cronUpkeep;
        emit CronUpkeepUpdated(cronUpkeepJobId, cronUpkeep);

        uint256 nextCronJobIDs = CronUpkeepInterface(cronUpkeep).getNextCronJobIDs();
        cronUpkeepJobId = nextCronJobIDs;

        bytes memory encodedCronBytes = CronExternal.toEncodedSpec(encodedCron);

        CronUpkeepInterface(cronUpkeep).createCronJobFromEncodedSpec(
            address(this),
            bytes("triggerDailyCheckpoint()"),
            encodedCronBytes
        );
    }

    /**
     * @notice Set the encoded cron
     * @param _encodedCron the new encoded cron as * * * * *
     * @dev Callable by admin or creator
     */
    function setEncodedCron(string memory _encodedCron) external override onlyAdminOrCreator {
        require(bytes(_encodedCron).length != 0, "Keeper cron need to be initialised");

        encodedCron = _encodedCron;
        bytes memory encodedCronBytes = CronExternal.toEncodedSpec(encodedCron);

        emit EncodedCronUpdated(cronUpkeepJobId, encodedCron);

        CronUpkeepInterface(cronUpkeep).updateCronJob(
            cronUpkeepJobId,
            address(this),
            bytes("triggerDailyCheckpoint()"),
            encodedCronBytes
        );
    }

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function pause() external override onlyAdminOrCreatorOrFactory whenNotPaused {
        _pauseGame();
    }

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function unpause()
        external
        override
        onlyAdminOrCreatorOrFactory
        whenPaused
        onlyIfKeeperDataInit
        onlyIfPrizesIsNotEmpty
    {
        _unpauseGame();
    }

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Admin Ownership
     * @param _adminAddress the new admin address
     * @dev Callable by admin
     */
    function transferAdminOwnership(address _adminAddress) external override onlyAdmin onlyAddressInit(_adminAddress) {
        emit AdminOwnershipTransferred(owner, _adminAddress);
        owner = _adminAddress;
    }

    /**
     * @notice Transfert Creator Ownership
     * @param _creator the new creator address
     * @dev Callable by creator
     */
    function transferCreatorOwnership(address _creator) external override onlyCreator onlyAddressInit(_creator) {
        emit CreatorOwnershipTransferred(creator, _creator);
        creator = _creator;
    }

    /**
     * @notice Transfert Factory Ownership
     * @param _factory the new factory address
     * @dev Callable by factory
     */
    function transferFactoryOwnership(address _factory) external override onlyAdminOrFactory onlyAddressInit(_factory) {
        emit FactoryOwnershipTransferred(factory, _factory);
        factory = _factory;
    }

    /**
     * @notice Allow admin to withdraw all funds of smart contract
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawFunds(address _receiver) external override onlyAdminOrFactory {
        _safeTransfert(_receiver, address(this).balance);
    }

    ///
    /// FALLBACK FUNCTIONS
    ///

    /**
     * @notice Called for empty calldata (and any value)
     */
    receive() external payable override {
        emit Received(msg.sender, msg.value);
    }

    /**
     * @notice Called when no other function matches (not even the receive function). Optionally payable
     */
    fallback() external payable override {
        emit Received(msg.sender, msg.value);
    }

    ///
    /// MODIFIERS
    ///

    /**
     * @notice Modifier that ensure only admin can access this function
     */
    modifier onlyAdmin() {
        require(msg.sender == owner, "Caller is not the admin");
        _;
    }

    /**
     * @notice Modifier that ensure only creator can access this function
     */
    modifier onlyCreator() {
        require(msg.sender == creator, "Caller is not the creator");
        _;
    }

    /**
     * @notice Modifier that ensure only factory can access this function
     */
    modifier onlyFactory() {
        require(msg.sender == factory, "Caller is not the factory");
        _;
    }

    /**
     * @notice Modifier that ensure only not creator can access this function
     */
    modifier onlyNotCreator() {
        require(msg.sender != creator, "Caller can't be the creator");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or creator can access this function
     */
    modifier onlyAdminOrCreator() {
        require(msg.sender == creator || msg.sender == owner, "Caller is not the admin or creator");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or creator or factory can access this function
     */
    modifier onlyAdminOrCreatorOrFactory() {
        require(
            msg.sender == creator || msg.sender == owner || msg.sender == factory,
            "Caller is not the admin or creator or factory"
        );
        _;
    }

    /**
     * @notice Modifier that ensure only admin or keeper can access this function
     */
    modifier onlyAdminOrKeeper() {
        require(msg.sender == creator || msg.sender == owner, "Caller is not the admin or keeper");
        _;
    }

    /**
     * @notice Modifier that ensure only admin or factory can access this function
     */
    modifier onlyAdminOrFactory() {
        require(msg.sender == factory || msg.sender == owner, "Caller is not the admin or factory");
        _;
    }

    /**
     * @notice Modifier that ensure only keeper can access this function
     */
    modifier onlyKeeper() {
        require(msg.sender == cronUpkeep, "Caller is not the keeper");
        _;
    }

    /**
     * @notice Modifier that ensure that address is initialised
     */
    modifier onlyAddressInit(address _toCheck) {
        require(_toCheck != address(0), "address need to be initialised");
        _;
    }

    /**
     * @notice Modifier that ensure that keeper data are initialised
     */
    modifier onlyIfKeeperDataInit() {
        require(cronUpkeep != address(0), "Keeper need to be initialised");
        require(bytes(encodedCron).length != 0, "Keeper cron need to be initialised");
        _;
    }

    /**
     * @notice Modifier that ensure that game is not full
     */
    modifier onlyIfNotFull() {
        require(playerAddresses.length < maxPlayers, "This game is full");
        _;
    }

    /**
     * @notice Modifier that ensure that game is full
     */
    modifier onlyIfFull() {
        require(playerAddresses.length == maxPlayers, "This game is not full");
        _;
    }

    /**
     * @notice Modifier that ensure that player not already entered in the game
     */
    modifier onlyIfNotAlreadyEntered() {
        require(players[msg.sender].playerAddress == address(0), "Player already entered in this game");
        _;
    }

    /**
     * @notice Modifier that ensure that player already entered in the game
     */
    modifier onlyIfAlreadyEntered() {
        require(players[msg.sender].playerAddress != address(0), "Player has not entered in this game");
        _;
    }

    /**
     * @notice Modifier that ensure that player has not lost
     */
    modifier onlyIfHasNotLost() {
        require(!players[msg.sender].hasLost, "Player has already lost");
        _;
    }

    /**
     * @notice Modifier that ensure that player has not already played this round
     */
    modifier onlyIfHasNotPlayedThisRound() {
        require(!players[msg.sender].hasPlayedRound, "Player has already played in this round");
        _;
    }

    /**
     * @notice Modifier that ensure that there is less than 50% of remaining players
     */
    modifier onlyIfPlayersLowerHalfRemaining() {
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        require(
            remainingPlayersLength <= maxPlayers / 2,
            "Remaining players must be less or equal than half of started players"
        );
        _;
    }

    /**
     * @notice Modifier that ensure that the game is in progress
     */
    modifier onlyIfGameIsInProgress() {
        require(isInProgress, "Game is not in progress");
        _;
    }

    /**
     * @notice Modifier that ensure that the game is not in progress
     */
    modifier onlyIfGameIsNotInProgress() {
        require(!isInProgress, "Game is already in progress");
        _;
    }

    /**
     * @notice Modifier that ensure that caller is not a smart contract
     */
    modifier onlyHumans() {
        uint256 size;
        address addr = msg.sender;
        assembly {
            size := extcodesize(addr)
        }
        require(size == 0, "No contract allowed");
        _;
    }

    /**
     * @notice Modifier that ensure that amount sended is registration amount
     */
    modifier onlyRegistrationAmount() {
        require(msg.value == registrationAmount, "Only registration amount is allowed");
        _;
    }

    /**
     * @notice Modifier that ensure that roundId exist
     */
    modifier onlyIfRoundId(uint256 _roundId) {
        require(_roundId <= roundId, "This round does not exist");
        _;
    }

    /**
     * @notice Modifier that ensure that there is less than 50% of remaining players
     */
    modifier onlyIfPlayerWon() {
        uint256 remainingPlayersLength = _getRemainingPlayersCount();
        require(
            remainingPlayersLength <= maxPlayers / 2,
            "Remaining players must be less or equal than half of started players"
        );
        _;
    }

    /**
     * @notice Modifier that ensure that we can't initialize the implementation contract
     */
    modifier onlyIfNotBase() {
        require(!_isBase, "The implementation contract can't be initialized");
        _;
    }

    /**
     * @notice Modifier that ensure that we can't initialize a cloned contract twice
     */
    modifier onlyIfNotAlreadyInitialized() {
        require(creator == address(0), "Contract already initialized");
        _;
    }

    /**
     * @notice Modifier that ensure that max players is in allowed range
     */
    modifier onlyAllowedNumberOfPlayers(uint256 _maxPlayers) {
        require(_maxPlayers > 1, "maxPlayers should be bigger than or equal to 2");
        require(_maxPlayers <= 100, "maxPlayers should not be bigger than 100");
        _;
    }

    /**
     * @notice Modifier that ensure that play time range is in allowed range
     */
    modifier onlyAllowedPlayTimeRange(uint256 _playTimeRange) {
        require(_playTimeRange > 0, "playTimeRange should be bigger than 0");
        require(_playTimeRange < 9, "playTimeRange should not be bigger than 8");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyIfClaimableAmount(uint256 _amount) {
        require(_amount > 0, "Nothing to claim");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyIfEnoughtBalance(uint256 _amount) {
        require(address(this).balance >= _amount, "Not enough in contract balance");
        _;
    }

    /**
     * @notice Modifier that ensure that treasury fee are not too high
     */
    modifier onlyTreasuryFee(uint256 _treasuryFee) {
        require(_treasuryFee <= MAX_TREASURY_FEE, "Treasury fee too high");
        _;
    }

    /**
     * @notice Modifier that ensure that creator fee are not too high
     */
    modifier onlyCreatorFee(uint256 _creatorFee) {
        require(_creatorFee <= MAX_CREATOR_FEE, "Creator fee too high");
        _;
    }

    /**
     * @notice Modifier that ensure that game is payable
     */
    modifier onlyIfGameIsPayable() {
        require(_isGamePayable(), "Game is not payable");
        _;
    }

    /**
     * @notice Modifier that ensure that game is not payable
     */
    modifier onlyIfGameIsNotPayable() {
        require(!_isGamePayable(), "Game is payable");
        _;
    }

    /**
     * @notice Modifier that ensure that game is splittable
     */
    modifier onlyIfGameIsSplittable() {
        require(_isGameAllPrizesStandard(), "Game is not splittable");
        _;
    }

    /**
     * @notice Modifier that ensure that prize details param is not empty
     * @param _prizes list of prize details
     */
    modifier onlyIfPrizesParam(Prize[] memory _prizes) {
        require(_prizes.length > 0, "Prizes should be greather or equal to 1");
        for (uint256 i = 0; i < _prizes.length; i++) require(_prizes[i].position == i + 1, "Prize list is not ordered");
        _;
    }

    /**
     * @notice Modifier that ensure thatmsg.value have the right amount if needed
     * @param _prizes list of prize details
     */
    modifier onlyIfPrizeAmountIfNeeded(Prize[] memory _prizes) {
        _checkIfPrizeAmountIfNeeded(_prizes);
        _;
    }

    /**
     * @notice Modifier that ensure that prize details is not empty
     */
    modifier onlyIfPrizesIsNotEmpty() {
        require(prizes[roundId].length > 0, "Prizes should be greather or equal to 1");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/proxy/Proxy.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@chainlink/contracts/src/v0.8/KeeperBase.sol";
import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";

import { Cron as CronInternal, Spec } from "@chainlink/contracts/src/v0.8/libraries/internal/Cron.sol";
import { Cron as CronExternal } from "@chainlink/contracts/src/v0.8/libraries/external/Cron.sol";

import { getRevertMsg } from "@chainlink/contracts/src/v0.8/utils/utils.sol";

/**
  The Cron contract is a chainlink keepers-powered cron job runner for smart contracts.
  The contract enables developers to trigger actions on various targets using cron
  strings to specify the cadence. For example, a user may have 3 tasks that require
  regular service in their dapp ecosystem:
    1) 0xAB..CD, update(1), "0 0 * * *"     --> runs update(1) on 0xAB..CD daily at midnight
    2) 0xAB..CD, update(2), "30 12 * * 0-4" --> runs update(2) on 0xAB..CD weekdays at 12:30
    3) 0x12..34, trigger(), "0 * * * *"     --> runs trigger() on 0x12..34 hourly
  To use this contract, a user first deploys this contract and registers it on the chainlink
  keeper registry. Then the user adds cron jobs by following these steps:
    1) Convert a cron string to an encoded cron spec by calling encodeCronString()
    2) Take the encoding, target, and handler, and create a job by sending a tx to createCronJob()
    3) Cron job is running :)
*/

interface CronUpkeepInterface {
    event CronJobExecuted(uint256 indexed id, uint256 timestamp);
    event CronJobCreated(uint256 indexed id, address target, bytes handler);
    event CronJobUpdated(uint256 indexed id, address target, bytes handler);
    event CronJobDeleted(uint256 indexed id);

    /**
     * @notice Executes the cron job with id encoded in performData
     * @param performData abi encoding of cron job ID and the cron job's next run-at datetime
     */
    function performUpkeep(bytes calldata performData) external;

    /**
     * @notice Creates a cron job from the given encoded spec
     * @param target the destination contract of a cron job
     * @param handler the function signature on the target contract to call
     * @param encodedCronSpec abi encoding of a cron spec
     */
    function createCronJobFromEncodedSpec(
        address target,
        bytes memory handler,
        bytes memory encodedCronSpec
    ) external;

    /**
     * @notice Updates a cron job from the given encoded spec
     * @param id the id of the cron job to update
     * @param newTarget the destination contract of a cron job
     * @param newHandler the function signature on the target contract to call
     * @param newEncodedCronSpec abi encoding of a cron spec
     */
    function updateCronJob(
        uint256 id,
        address newTarget,
        bytes memory newHandler,
        bytes memory newEncodedCronSpec
    ) external;

    /**
     * @notice Deletes the cron job matching the provided id. Reverts if
     * the id is not found.
     * @param id the id of the cron job to delete
     */
    function deleteCronJob(uint256 id) external;

    /**
     * @notice Add a delegator to the smart contract.
     * @param delegator the address of delegator to add
     */
    function addDelegator(address delegator) external;

    /**
     * @notice Remove a delegator to the smart contract.
     * @param delegator the address of delegator to remove
     */
    function removeDelegator(address delegator) external;

    /**
     * @notice Pauses the contract, which prevents executing performUpkeep
     */
    function pause() external;

    /**
     * @notice Unpauses the contract
     */
    function unpause() external;

    /**
     * @notice Get the id of an eligible cron job
     * @return upkeepNeeded signals if upkeep is needed, performData is an abi encoding
     * of the id and "next tick" of the elligible cron job
     */
    function checkUpkeep(bytes calldata) external returns (bool, bytes memory);

    /**
     * @notice gets a list of active cron job IDs
     * @return list of active cron job IDs
     */
    function getActiveCronJobIDs() external view returns (uint256[] memory);

    /**
     * @notice gets the next cron job IDs
     * @return next cron job IDs
     */
    function getNextCronJobIDs() external view returns (uint256);

    /**
   * @notice gets a cron job
   * @param id the cron job ID
   * @return target - the address a cron job forwards the eth tx to
             handler - the encoded function sig to execute when forwarding a tx
             cronString - the string representing the cron job
             nextTick - the timestamp of the next time the cron job will run
   */
    function getCronJob(uint256 id)
        external
        view
        returns (
            address target,
            bytes memory handler,
            string memory cronString,
            uint256 nextTick
        );
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "@openzeppelin/contracts/utils/Address.sol";

import { CronUpkeepInterface } from "./CronUpkeepInterface.sol";
import { Cron as CronExternal } from "@chainlink/contracts/src/v0.8/libraries/external/Cron.sol";

interface GameV1Interface {
    ///STRUCTS

    /**
     * @notice Player structure that contain all usefull data for a player
     */
    struct Player {
        address playerAddress;
        uint256 roundRangeLowerLimit;
        uint256 roundRangeUpperLimit;
        bool hasPlayedRound;
        uint256 roundCount;
        uint256 position;
        bool hasLost;
        bool isSplitOk;
    }

    /**
     * @notice Winner structure that contain all usefull data for a winner
     */
    struct Winner {
        uint256 roundId;
        address playerAddress;
        uint256 amountWon;
        uint256 position;
        bool prizeClaimed;
    }

    /**
     * @notice PrizeStandard ENUM
     */
    enum PrizeStandard {
        STANDARD,
        ERC20,
        ERC721,
        ERC1155
    }
    /**
     * @notice Prize structure that contain a list of prizes for the current roundId
     */
    struct Prize {
        uint256 position;
        uint256 amount;
        /*
         * This will return a single integer between 0 and 5.
         * The numbers represent different ‘states’ a name is currently in.
         * 0 - STANDARD
         * 1 - ERC20
         * 2 - ERC721
         * 3 - ERC1155
         */
        uint256 standard;
        address contractAddress;
        uint256 tokenId;
    }

    /**
     * @notice Initialization structure that contain all the data that are needed to create a new game
     */
    struct Initialization {
        address owner;
        address creator;
        address cronUpkeep;
        bytes32 name;
        uint256 version;
        uint256 id;
        uint256 playTimeRange;
        uint256 maxPlayers;
        uint256 registrationAmount;
        uint256 treasuryFee;
        uint256 creatorFee;
        string encodedCron;
        Prize[] prizes;
    }

    struct GameData {
        uint256 id;
        uint256 roundId;
        bytes32 name;
        uint256 playerAddressesCount;
        uint256 maxPlayers;
        uint256 registrationAmount;
        uint256 playTimeRange;
        uint256 treasuryFee;
        uint256 creatorFee;
        bool isPaused;
        bool isInProgress;
        address creator;
        address admin;
        string encodedCron;
    }

    ///
    ///EVENTS
    ///

    /**
     * @notice Called when a player has registered for a game
     */
    event RegisteredForGame(address playerAddress, uint256 playersCount);
    /**
     * @notice Called when the keeper start the game
     */
    event StartedGame(uint256 timelock, uint256 playersCount);
    /**
     * @notice Called when the keeper reset the game
     */
    event ResetGame(uint256 timelock, uint256 resetId);
    /**
     * @notice Called when a player lost a game
     */
    event GameLost(uint256 roundId, address playerAddress, uint256 roundCount);
    /**
     * @notice Called when a player play a round
     */
    event PlayedRound(address playerAddress);
    /**
     * @notice Called when a player won the game
     */
    event GameWon(uint256 roundId, uint256 winnersCounter, address playerAddress, uint256 amountWon);
    /**
     * @notice Called when some player(s) split the game
     */
    event GameSplitted(uint256 roundId, uint256 remainingPlayersCount, uint256 amountWon);
    /**
     * @notice Called when a player vote to split pot
     */
    event VoteToSplitPot(uint256 roundId, address playerAddress);
    /**
     * @notice Called when a prize is added
     */
    event PrizeAdded(
        uint256 roundId,
        uint256 position,
        uint256 amount,
        uint256 standard,
        address contractAddress,
        uint256 tokenId
    );
    /**
     * @notice Called when a methode transferCreatorOwnership is called
     */
    event CreatorOwnershipTransferred(address oldCreator, address newCreator);
    /**
     * @notice Called when a methode transferAdminOwnership is called
     */
    event AdminOwnershipTransferred(address oldAdmin, address newAdmin);
    /**
     * @notice Called when a methode transferFactoryOwnership is called
     */
    event FactoryOwnershipTransferred(address oldFactory, address newFactory);
    /**
     * @notice Called when a transfert have failed
     */
    event FailedTransfer(address receiver, uint256 amount);
    /**
     * @notice Called when the contract have receive funds via receive() or fallback() function
     */
    event Received(address sender, uint256 amount);
    /**
     * @notice Called when a player have claimed his prize
     */
    event GamePrizeClaimed(address claimer, uint256 roundId, uint256 amountClaimed);
    /**
     * @notice Called when the treasury fee are claimed
     */
    event TreasuryFeeClaimed(uint256 amount);
    /**
     * @notice Called when the treasury fee are claimed by factory
     */
    event TreasuryFeeClaimedByFactory(uint256 amount);
    /**
     * @notice Called when the creator fee are claimed
     */
    event CreatorFeeClaimed(uint256 amount);
    /**
     * @notice Called when the creator or admin update encodedCron
     */
    event EncodedCronUpdated(uint256 jobId, string encodedCron);
    /**
     * @notice Called when the factory or admin update cronUpkeep
     */
    event CronUpkeepUpdated(uint256 jobId, address cronUpkeep);

    ///
    /// INITIALISATION
    ///

    /**
     * @notice Create a new Game Implementation by cloning the base contract
     * @param _initialization the initialisation data with params as follow :
     *  @param _initialization.creator the game creator
     *  @param _initialization.owner the general admin address
     *  @param _initialization.cronUpkeep the cron upkeep address
     *  @param _initialization.name the game name
     *  @param _initialization.version the version of the game implementation
     *  @param _initialization.id the unique game id (fix)
     *  @param _initialization.playTimeRange the time range during which a player can play in hour
     *  @param _initialization.maxPlayers the maximum number of players for a game
     *  @param _initialization.registrationAmount the amount that players will need to pay to enter in the game
     *  @param _initialization.treasuryFee the treasury fee in percent
     *  @param _initialization.creatorFee creator fee in percent
     *  @param _initialization.encodedCron the cron string
     *  @param _initialization.prizes the prizes list
     * @dev TODO NEXT VERSION Remove _isGameAllPrizesStandard limitation to include other prize typ
     * @dev TODO NEXT VERSION Make it only accessible to factory
     */
    function initialize(Initialization calldata _initialization) external payable;

    /**
     * @notice Function that is called by the keeper when game is ready to start
     * @dev TODO NEXT VERSION remove this function in next smart contract version
     */
    function startGame() external;

    ///
    /// MAIN FUNCTIONS
    ///

    /**
     * @notice Function that allow players to register for a game
     * @dev Creator cannot register for his own game
     */
    function registerForGame() external payable;

    /**
     * @notice Function that allow players to play for the current round
     * @dev Creator cannot play for his own game
     * @dev Callable by remaining players
     */
    function playRound() external;

    /**
     * @notice Function that is called by the keeper based on the keeper cron
     * @dev Callable by admin or keeper
     * @dev TODO NEXT VERSION Update triggerDailyCheckpoint to mae it only callable by keeper
     */
    function triggerDailyCheckpoint() external;

    /**
     * @notice Function that allow player to vote to split pot
     * @dev Only callable if less than 50% of the players remain
     * @dev Callable by remaining players
     */
    function voteToSplitPot() external;

    /**
     * @notice Function that is called by a winner to claim his prize
     * @dev TODO NEXT VERSION Update claim process according to prize type
     */
    function claimPrize(uint256 _roundId) external;

    /**
     * @notice Prizes adding management
     * @dev Callable by admin or creator
     * @dev TODO NEXT VERSION add a taxe for creator in case of free games
     *      Need to store the factory gameCreationAmount in this contract on initialisation
     * @dev TODO NEXT VERSION Remove _isGameAllPrizesStandard limitation to include other prize typ
     */
    function addPrizes(Prize[] memory _prizes) external payable;

    ///
    /// GETTERS FUNCTIONS
    ///

    /**
     * @notice Return game informations
     * @return gameData the game status data with params as follow :
     *  gameData.creator the creator address of the game
     *  gameData.roundId the roundId of the game
     *  gameData.name the name of the game
     *  gameData.playerAddressesCount the number of registered players
     *  gameData.maxPlayers the maximum players of the game
     *  gameData.registrationAmount the registration amount of the game
     *  gameData.playTimeRange the player time range of the game
     *  gameData.treasuryFee the treasury fee of the game
     *  gameData.creatorFee the creator fee of the game
     *  gameData.isPaused a boolean set to true if game is paused
     *  gameData.isInProgress a boolean set to true if game is in progress
     */
    function getGameData() external view returns (GameData memory gameData);

    /**
     * @notice Return the players addresses for the current game
     * @return gamePlayerAddresses list of players addresses
     */
    function getPlayerAddresses() external view returns (address[] memory gamePlayerAddresses);

    /**
     * @notice Return a player for the current game
     * @param _player the player address
     * @return gamePlayer if finded
     */
    function getPlayer(address _player) external view returns (Player memory gamePlayer);

    /**
     * @notice Return the winners for a round id
     * @param _roundId the round id
     * @return gameWinners list of Winner
     */
    function getWinners(uint256 _roundId) external view returns (Winner[] memory gameWinners);

    /**
     * @notice Return the winners for a round id
     * @param _roundId the round id
     * @return gamePrizes list of Prize
     */
    function getPrizes(uint256 _roundId) external view returns (Prize[] memory gamePrizes);

    /**
     * @notice Check if all remaining players are ok to split pot
     * @return isSplitOk set to true if all remaining players are ok to split pot, false otherwise
     */
    function isAllPlayersSplitOk() external view returns (bool isSplitOk);

    /**
     * @notice Check if Game is payable
     * @return isPayable set to true if game is payable, false otherwise
     */
    function isGamePayable() external view returns (bool isPayable);

    /**
     * @notice Check if Game prizes are standard
     * @return isStandard true if game prizes are standard, false otherwise
     */
    function isGameAllPrizesStandard() external view returns (bool isStandard);

    /**
     * @notice Get the number of remaining players for the current game
     * @return remainingPlayersCount the number of remaining players for the current game
     */
    function getRemainingPlayersCount() external view returns (uint256 remainingPlayersCount);

    ///
    /// SETTERS FUNCTIONS
    ///

    /**
     * @notice Set the name of the game
     * @param _name the new game name
     * @dev Callable by creator
     */
    function setName(bytes32 _name) external;

    /**
     * @notice Set the maximum allowed players for the game
     * @param _maxPlayers the new max players limit
     * @dev Callable by admin or creator
     */
    function setMaxPlayers(uint256 _maxPlayers) external;

    /**
     * @notice Set the creator fee for the game
     * @param _creatorFee the new creator fee in %
     * @dev Callable by admin or creator
     * @dev Callable when game if not in progress
     */
    function setCreatorFee(uint256 _creatorFee) external;

    /**
     * @notice Allow creator to withdraw his fee
     * @dev Callable by admin
     */
    function claimCreatorFee() external;

    ///
    /// ADMIN FUNCTIONS
    ///

    /**
     * @notice Withdraw Treasury fee
     * @dev Callable by admin
     */
    function claimTreasuryFee() external;

    /**
     * @notice Set the treasury fee for the game
     * @param _treasuryFee the new treasury fee in %
     * @dev Callable by admin
     * @dev Callable when game if not in progress
     */
    function setTreasuryFee(uint256 _treasuryFee) external;

    /**
     * @notice Set the keeper address
     * @param _cronUpkeep the new keeper address
     * @dev Callable by admin or factory
     */
    function setCronUpkeep(address _cronUpkeep) external;

    /**
     * @notice Set the encoded cron
     * @param _encodedCron the new encoded cron as * * * * *
     * @dev Callable by admin or creator
     */
    function setEncodedCron(string memory _encodedCron) external;

    /**
     * @notice Pause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function pause() external;

    /**
     * @notice Unpause the current game and associated keeper job
     * @dev Callable by admin or creator
     */
    function unpause() external;

    ///
    /// EMERGENCY
    ///

    /**
     * @notice Transfert Admin Ownership
     * @param _adminAddress the new admin address
     * @dev Callable by admin
     */
    function transferAdminOwnership(address _adminAddress) external;

    /**
     * @notice Transfert Creator Ownership
     * @param _creator the new creator address
     * @dev Callable by creator
     */
    function transferCreatorOwnership(address _creator) external;

    /**
     * @notice Transfert Factory Ownership
     * @param _factory the new factory address
     * @dev Callable by factory
     */
    function transferFactoryOwnership(address _factory) external;

    /**
     * @notice Allow admin to withdraw all funds of smart contract
     * @param _receiver the receiver for the funds (admin or factory)
     * @dev Callable by admin or factory
     */
    function withdrawFunds(address _receiver) external;

    ///
    /// FALLBACK FUNCTIONS
    ///

    /**
     * @notice Called for empty calldata (and any value)
     */
    receive() external payable;

    /**
     * @notice Called when no other function matches (not even the receive function). Optionally payable
     */
    fallback() external payable;
}