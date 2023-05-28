// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./reservation-system-instance.contract.sol";

error AlreadyExists();

contract ReservationSystemFactory is ReservationSystemTypes {
    mapping(address => ReservationSystemInstance) private addressToInstance;

    address private constant DEFAULT_ADDRESS =
        0x0000000000000000000000000000000000000000;

    event ReservationAdded(Reservation reservation);

    function createNewHotel() public alreadyExists returns (address) {
        addressToInstance[msg.sender] = new ReservationSystemInstance(
            msg.sender
        );
        return addressToInstance[msg.sender].i_owner();
    }

    function hfAddReservation(
        Reservation memory _reservation
    ) public returns (bool success) {
        addressToInstance[msg.sender].addReservation(msg.sender, _reservation);
        emit ReservationAdded(_reservation);
        return true;
    }

    function hfGetAllReservations() public view returns (Reservation[] memory) {
        return addressToInstance[msg.sender].getAllReservations(msg.sender);
    }

    modifier alreadyExists() {
        if (
            addressToInstance[msg.sender] !=
            ReservationSystemInstance(DEFAULT_ADDRESS)
        ) {
            revert AlreadyExists();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./reservation-system.types.sol";

error NotOwner();

contract ReservationSystemInstance is ReservationSystemTypes {
    address public immutable i_owner;
    Reservation[] private HotelReservations;

    event ReservationAdded(Reservation reservation);

    constructor(address _owner) {
        i_owner = _owner;
    }

    function addReservation(
        address _sender,
        Reservation calldata _reservation
    ) public onlyOwner(_sender) returns (bool success) {
        HotelReservations.push(_reservation);
        emit ReservationAdded(_reservation);
        return true;
    }

    function getAllReservations(
        address _sender
    ) public view onlyOwner(_sender) returns (Reservation[] memory) {
        return HotelReservations;
    }

    modifier onlyOwner(address _msgSender) {
        if (_msgSender != i_owner) {
            revert NotOwner();
        }
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract ReservationSystemTypes {
    struct Reservation {
        uint startDate;
        uint endDate;
    }
}