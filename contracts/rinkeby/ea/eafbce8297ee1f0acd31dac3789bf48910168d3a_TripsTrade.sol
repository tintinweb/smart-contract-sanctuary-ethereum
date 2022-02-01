/**
 *Submitted for verification at Etherscan.io on 2022-02-01
*/

// File: @openzeppelin/contracts/utils/Counters.sol


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

// File: TR.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


contract TripsTrade {
    using Counters for Counters.Counter;

    Counters.Counter private _propertyIdCounter;

    struct Property {
        uint256 id;
        address owner;
    }

    struct Booking {
        uint256 propertyId;
        address renter;
        uint256 checkIn;
        uint256 checkOut;
    }

    Property[] public properties;
    mapping(uint256 => Booking[]) public bookings;

    event PropertyCreated(Property);
    event BookingCreated(Booking);

    function createProperty() public payable {
        // cost 0.1 ether to create a property
        require(msg.value >= 0.1 ether, "0.1 ether to create a property");

        // assign propertyId
        uint256 propertyId = _propertyIdCounter.current();

        // increment propertyId
        _propertyIdCounter.increment();

        // create a new Property
        Property memory newProperty = Property(propertyId, msg.sender);

        // push property to properties array
        properties.push(newProperty);

        // emit property event
        emit PropertyCreated(newProperty);
    }

    function createBooking(
        uint256 propertyId,
        uint256 checkIn,
        uint256 checkOut
    ) public {
        // get property booking
        Booking[] memory propertyBookings = bookings[propertyId];

        // if bookings exist check if booked
        if (propertyBookings.length > 0) {
            // loop over bookings
            for (uint256 i; i < propertyBookings.length; i++) {
                Booking memory aBooking = propertyBookings[i];
                // check if the property is booked
                require(
                    checkIn > aBooking.checkOut || checkOut < aBooking.checkIn,
                    "Property is booked"
                );
            }
        }

        // create a new Booking
        Booking memory newBooking = Booking(
            propertyId,
            msg.sender,
            checkIn,
            checkOut
        );

        // push booking to bookings array
        bookings[propertyId].push(newBooking);

        // emit booking event
        emit BookingCreated(newBooking);
    }
}