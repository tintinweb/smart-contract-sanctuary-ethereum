pragma solidity ^0.4.17;

import {CarLib} from "./CarLib.sol";

contract Rental {
    
    bool private stopped = false;
    address private manager;

     // The constructor. We assign the manager to be the creator of the contract.It could be enhanced to support passing maangement off.
    constructor() public  
    {
        manager = msg.sender;
    }

    //Check if sender isAdmin, this function alone could be added to multiple functions for manager only method calls
    modifier isAdmin() {
        assert(msg.sender == manager);
        _;
    }
    
    //Check if the contracts features are deactivated
    function getStopped() public view returns(bool) { return stopped; }

    
    function toggleContractActive() isAdmin public {
    // You can add an additional modifier that restricts stopping a contract to be based on another action, such as a vote of users
        stopped = !stopped;
    }


    //Number of Cars available for rent
    CarLib.Car[] public rentals;

    //Return Total Number of Cars
    function getCarCount() public constant returns(uint) {
        return rentals.length;
    }

    //Renting a car 
    function rent(uint carId) public returns (bool) {
       
       //Never Ever want to be false, therefore we use assert
       assert(!stopped); 
        
        
       //Validate cardId is within array
      uint totalCars = getCarCount();
      
    //There must be a car to rent and ID # must be within range 
      require(carId >= 0 && carId < totalCars);
    
    //Reference to the car that will be rented 
    CarLib.Car storage carToBeRented = rentals[carId];
    
    //Car must be available
    require(carToBeRented.isAvailable == true);
      
      //Assign Rentee to Sender
      carToBeRented.rentee = msg.sender;
      
      //Remove Availability
      carToBeRented.isAvailable = false; 
      
     //Return Success
      return true;
    }

    // Retrieving the car data necessary for user
    function getRentalCarInfo(uint carId) public view returns (string, string, address, address, bool, uint, uint) {
      
      uint totalCars = getCarCount();
      require(carId >= 0 && carId < totalCars);
      
      //Get specified car 
      CarLib.Car memory specificCar = rentals[carId];
      
      //Return data considered in rental process
      return (specificCar.make,specificCar.licenseNumber, specificCar.owner ,specificCar.rentee, specificCar.isAvailable, specificCar.year , specificCar.carId);
    }

    //Add RentableCar
    function addNewCar(string make, address owner, string licenseNumber, uint year) public returns (uint) {
        assert(!stopped); 
        //Create car object within function
        
        //Current # of cars
        uint count = getCarCount();
        //Increment Count
        //Construct Car Object
        CarLib.Car memory newCar = CarLib.Car(make,true, 0x0 , owner, year,licenseNumber,count);
        
        //Add to Array
        rentals.push(newCar);
        
         return count;
    }
    
    //Allow Car Owner to Mark car as returned
    function returnCar(uint carId) public  returns (bool) {
        assert(!stopped); 
        
        //Get Specific car
        CarLib.Car storage specificCar = rentals[carId];
        require(specificCar.owner == msg.sender);
        //Make car available again
        specificCar.isAvailable = true;
        //Remove previous rentee
        specificCar.rentee = 0x0;
        
        //Return Success
        return true;
    }

}

pragma solidity ^0.4.17;

library CarLib {
    //This library contains helps create Car Objects for Rental Contracts
    struct Car {
        string make; // Car Model
        bool isAvailable;  // if true, this car can be rented out
        address rentee; // person delegated to
        address owner; //Owner of Car
        uint year;   // index of the voted proposal
        string licenseNumber; // Car identification
        uint carId; // index of car to be rented 
    }
}