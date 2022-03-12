// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/Counters.sol";

contract RoomBooking {

    using Counters for Counters.Counter;

    uint32 public colaDayStartingTimestamp;
    uint8 private constant ROOMS_AVAILABLE = 20;
    Counters.Counter private idReservation;

    enum Brand {
        coke,
        pepsi
    }

    Brand public brands;

    struct reservation {
        uint32 id;
        address user;
        uint32 startingTime;
        uint32 endingTime;
        Brand brand;
        string roomName;
    }

    reservation[] public reservations;   

    constructor(uint32 _colaDayStartingTimestamp) {
        //require(block.timestamp < _colaDayStartingTimestamp, "Can't start the Cola Day in the past");
        colaDayStartingTimestamp = _colaDayStartingTimestamp;
    }

    function getAllReservations() external view returns(reservation[] memory) {
        return reservations;
    }

    function bookMeeting(address _user, uint32 _startingTime, uint32 _endingTime, Brand _brand, string memory _roomName) external {
        require(!isAlreadyBooked(_startingTime, _endingTime, _roomName), "Room already Booked");
        reservation memory thisReservation = reservation(uint32(idReservation.current()), _user, _startingTime, _endingTime, _brand, _roomName);
        reservations.push(thisReservation);
        idReservation.increment();
    }

    function cancelMeeting(uint32 _id) external {
        for(uint32 i = 0 ; i < reservations.length ; i++) {
            if(reservations[i].id == _id) {
                require(msg.sender == reservations[i].user, "Can't delete reservations of other people.");
                delete reservations[i];
            }
        }
    }

    function isAlreadyBooked(uint32 _startingTime, uint32 _endingTime, string memory _roomName) internal view returns(bool) {
        bool result = false;
        for(uint i = 0 ; i < reservations.length ; i++) {
            if(keccak256(abi.encodePacked(reservations[i].roomName)) == keccak256(abi.encodePacked(_roomName))) {
                if((_startingTime >= reservations[i].startingTime && _startingTime < reservations[i].endingTime) 
                || (_endingTime > reservations[i].startingTime && _endingTime <= reservations[i].endingTime)) {
                    result = true;
                }
            }
        }
        return result;
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