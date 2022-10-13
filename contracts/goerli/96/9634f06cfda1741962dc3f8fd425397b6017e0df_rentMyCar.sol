/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract rentMyCar {

    // Create Struct named Car with the following members:
    //    string make; uint year; uint doors, uint mpg and uint256 rentalAmt
    struct Car{
        string make;
        uint year;
        uint doors;
        uint mpg;
        uint256 rentalAmt;
    }

    Car car;

    address owner;

    address approvedRenter;
    bool isRented;

    constructor(string memory _make, uint year, uint doors, uint mpg, uint256 rentalAmt) {

        owner = msg.sender;

        car = Car(_make,year,doors,mpg,rentalAmt);

        // set isRented to false
        isRented=false;
    }
   
    function carDetails() public view returns (Car memory) {

        return car;
    }

   
    function rentCar(uint256 amt) public payable returns (uint256 approvalCode) {
        // create 2 require statements
        // 1 ensure that the amount set is equal to the rentalAmt, if not return:
        //       Funds don't equal rental amount
        // 2 ensure car is not rented, if it is return:
        //       Car is rented already
       require(car.rentalAmt==amt,"Funds don't equal rental amount");
       require(isRented==false,"Car is rented already");
        approvedRenter = msg.sender;
        approvalCode = 0x123456789012345678901234567890;
        isRented = true;
    }

    function returnCar() public returns(uint256 returnConfirmation) {
        require(approvedRenter==msg.sender);
        returnConfirmation = 0x0987654321098765432109876543210;
        isRented = false;
    }
    receive() external payable {}
   
    function withdraw() public payable {
        require(msg.sender==owner,"Only owner can withdraw");
        // send money back to owner
        uint ra= car.rentalAmt*1 wei;
        payable (msg.sender).transfer(ra);
    }
    function getBal() public view returns (uint){
        return owner.balance;
    }
}