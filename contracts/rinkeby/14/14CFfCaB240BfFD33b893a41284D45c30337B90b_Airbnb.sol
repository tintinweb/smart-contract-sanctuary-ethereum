//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./DatesChecker.sol";
import "./IWETH.sol";

error DateUnavailable();
error IncorrectPayment();
error RentalNotFound();

contract Airbnb is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _rentalCounter;

    struct RentalInfo {
        string name;
        string city;
        string lat;
        string long;
        string unoDescription;
        string dosDescription;
        string imgUrl;
        uint256 maxGuests;
        uint256 pricePerDay;
        uint256 id;
        address renter;
    }

    event RentalCreated(
        string name,
        string city,
        string lat,
        string long,
        string unoDescription,
        string dosDescription,
        string imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] datesBooked,
        uint256 id,
        address renter
    );

    event NewDatesBooked(
        string[] datesBooked,
        uint256 id,
        address booker,
        string city,
        string imgUrl
    );

    IWETH public weth;

    mapping(uint256 => RentalInfo) public rentals;
    uint256[] public rentalIds;
    mapping(uint256 => mapping(string => bool)) public bookings;

    constructor(IWETH _weth) {
        weth = _weth;
    }

    function createRental(
        string memory name,
        string memory city,
        string memory lat,
        string memory long,
        string memory unoDescription,
        string memory dosDescription,
        string memory imgUrl,
        uint256 maxGuests,
        uint256 pricePerDay,
        string[] memory datesBooked
    ) external onlyOwner {
        uint256 rentalId = _rentalCounter.current();
        _rentalCounter.increment();
        RentalInfo storage newRental = rentals[rentalId];
        newRental.name = name;
        newRental.city = city;
        newRental.lat = lat;
        newRental.long = long;
        newRental.unoDescription = unoDescription;
        newRental.dosDescription = dosDescription;
        newRental.imgUrl = imgUrl;
        newRental.maxGuests = maxGuests;
        newRental.pricePerDay = pricePerDay;
        newRental.id = rentalId;
        newRental.renter = msg.sender;
        _addBookings(rentalId, datesBooked);
        emit RentalCreated(
            name,
            city,
            lat,
            long,
            unoDescription,
            dosDescription,
            imgUrl,
            maxGuests,
            pricePerDay,
            datesBooked,
            rentalId,
            msg.sender
        );
    }

    function _addBookings(uint256 id, string[] memory newBookings) internal {
        DatesChecker.validateDates(newBookings);
        for (uint256 i = 0; i < newBookings.length; i++) {
            if (bookings[id][newBookings[i]])
                revert DateUnavailable();
            bookings[id][newBookings[i]] = true;
        }
    }

    function addDatesBooked(uint256 id, string[] memory newBookings)
        external
        payable
    {
        if (id >= _rentalCounter.current()) revert RentalNotFound();
        uint256 amount = rentals[id].pricePerDay * 1 ether * newBookings.length;
        if (msg.value != amount) revert IncorrectPayment();
        _addBookings(id, newBookings);
        RentalInfo memory rental = rentals[id];
        _safeTransferETHWithFallback(rental.renter, amount);
        emit NewDatesBooked(
            newBookings,
            id,
            msg.sender,
            rental.city,
            rental.imgUrl
        );
    }

    function getTotalRentals() external view returns (uint256) {
        return _rentalCounter.current();
    }

    function _safeTransferETHWithFallback(address to, uint256 amount) internal {
        if (!_safeTransferETH(to, amount)) {
            weth.deposit{value: amount}();
            require(weth.transfer(to, amount), "transfer failed");
        }
     }

    function _safeTransferETH(address to, uint256 value)
        internal
        returns (bool)
    {
        // solhint-disable-next-line
        (bool success, ) = to.call{value: value, gas: 30_000}("");
        return success;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

error InvalidDate();
error DuplicateDates();
error UnorderedDates();

library DatesChecker {
    function validateDates(string[] memory dates) internal pure {
        bytes32 maxDateHash = keccak256("");
        for (uint256 i = 0; i < dates.length; i++) {
            // check date format
            checkDate(dates[i]);

            // check duplicate dates
            bytes32 dateHash = keccak256(abi.encodePacked(dates[i]));
            if (i == 0 || maxDateHash < dateHash) {
                maxDateHash = dateHash;
            } else if (maxDateHash == dateHash) {
                revert DuplicateDates();
            } else {
                revert UnorderedDates();
            }
        }
    }

    function checkDate(string memory date)
        internal
        pure
    {
        bytes memory b = bytes(date);
        if (b.length != 10 || b[4] != 0x2d || b[7] != 0x2d) {
            revert InvalidDate();
        }
        uint16 year = getNumberFromStringBytes(b, 0, 4);
        uint16 month = getNumberFromStringBytes(b, 5, 7);
        uint16 day = getNumberFromStringBytes(b, 8, 10);
        if (month < 1 || month > 12) {
            revert InvalidDate();
        }
        uint8 maxDays;
        if (month == 2) {
            if (checkLeapYear(year)) {
                maxDays = 29;
            } else {
                maxDays = 28;
            }
        } else if (month <= 7) {
            maxDays = uint8(30 + (month % 2));
        } else {
            maxDays = uint8(31 - (month % 2));
        }
        if (day < 1 || day > maxDays) {
            revert InvalidDate();
        }
    }

    function checkLeapYear(uint16 year) internal pure returns (bool) {
        return (year % 400 == 0) || (year % 4 == 0 && year % 100 != 0);
    }

    function getNumberFromStringBytes(
        bytes memory b,
        uint256 start,
        uint256 end
    ) internal pure returns (uint16 number) {
        for (uint256 i = start; i < end; i++) {
            if (!(b[i] >= 0x30 && b[i] <= 0x39)) {
            revert InvalidDate();
            }
            number += uint16((uint8(b[i]) - 0x30) * 10**(end - 1 - i));
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function withdraw(uint256) external;
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