/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IHotelReservation{
    function bookRoom() payable external;
}

interface IFlightReservation{
    function bookFlight() payable external;
}

contract AtomicTripReservation{
    
    function bookTrip(address HotelReservationAddress, address FlightReservationAddress, uint256 HotelPrice, uint256 FlightPrice) payable external{
        IHotelReservation HotelReservation = IHotelReservation(HotelReservationAddress);
        IFlightReservation FlightReservation = IFlightReservation(FlightReservationAddress);
        HotelReservation.bookRoom{value:HotelPrice}();
        FlightReservation.bookFlight{value:FlightPrice}();
        uint refund = msg.value - HotelPrice - FlightPrice;
        address payable refundAddress = payable(tx.origin);
        if(refund>0){
            refundAddress.transfer(refund);
        }
    }

}