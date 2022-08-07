/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;
 error Airbnb__NotOwner();
 error Airbnb__NoSuchRental();
error Airbnb__AlreadyBooked();
contract Airbnb{
    address public owner;
    uint256 private counter;

    constructor(){
        counter=0;
        owner=msg.sender;
    }

     struct rentalInfo{
         string name;
         string city;
         string lat;
         string long;
         string unoDescription;
         string dosDescription;
         string imgUrl;
         uint256 maxGuests;
         uint256 pricePerDay;
         string [] datesBooked;
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
         string [] datesBooked,
         uint256 id,
         address renter
     );

     event newDatesBooked(
         string[] datesBooked,
         uint256 id,
         address booker,
         string city,
         string imgUrl
     );

     mapping(uint256=>rentalInfo)rentals;
     uint256[] public rentalIds;

     function addRentals(
         string memory  name,
         string  memory city,
         string  memory lat,
         string memory  long,
         string memory  unoDescription,
         string  memory dosDescription,
         string memory  imgUrl,
         uint256 maxGuests,
         uint256 pricePerDay,
         string []  memory datesBooked
     ) public{
        if(msg.sender!=owner){
            revert Airbnb__NotOwner();
        }
        rentalInfo storage newRental=rentals[counter];
        newRental.name=name;
        newRental.city=city;
        newRental.lat=lat;
        newRental.long=long;
        newRental.unoDescription=unoDescription;
        newRental.dosDescription=dosDescription;
        newRental.imgUrl=imgUrl;
        newRental.maxGuests=maxGuests;
        newRental.pricePerDay=pricePerDay;
        newRental.datesBooked=datesBooked;
        newRental.id=counter;
        newRental.renter=owner;
        rentalIds.push(counter);
        emit RentalCreated(name,city,lat,long,unoDescription,dosDescription,imgUrl,maxGuests,pricePerDay,datesBooked,counter,owner);
        counter++;
     }
        function checkBookings(uint256 id,string[] memory newBookings) private view returns(bool){
            for(uint i=0;i<newBookings.length;i++){
                for(uint j=0;j<rentals[id].datesBooked.length;j++){
                    if(keccak256(abi.encodePacked(rentals[id].datesBooked[j]))==keccak256(abi.encodePacked(newBookings[i]))){
                    return false;}
                }
            }
            return true;
        }
        function addDatesBooked(uint256 id,string[] memory newBookings) public payable{
            if(id>=counter){
                revert Airbnb__NoSuchRental();
            }
            if(!checkBookings(id,newBookings)){
                revert Airbnb__AlreadyBooked();
            }
          //  require(checkBookings(id,newBookings),"Already Booked for Requested Date");
            require(msg.value==(rentals[id].pricePerDay*1 ether*newBookings.length),"Please submit the amount");

            for(uint i=0;i<newBookings.length;i++){
                rentals[id].datesBooked.push(newBookings[i]);
            }
            payable(owner).transfer(msg.value);
            emit newDatesBooked(newBookings,id,msg.sender,rentals[id].city,rentals[id].imgUrl);

        }
        function getRental(uint256 id) public view returns(string memory,uint256,string[] memory){
             if(id>=counter){
                revert Airbnb__NoSuchRental();
            }
            rentalInfo storage s=rentals[id];
            return (s.name,s.pricePerDay,s.datesBooked);
        }


}