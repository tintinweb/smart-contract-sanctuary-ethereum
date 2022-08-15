//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract carpooling{
    address internal manager;
    enum status{open,booked,cancel,completed,expire}

    struct driver{
        address name;
        string taxi_no;
        uint register_time;
        string car_detail;
        string no_seat;
        uint base_price;
        string start_point;
        string destination;
        status a;
    }
    mapping(uint=>driver) public detail;
    uint public numrequests;
    // enum status{booked,not_book,completed,cancel}

    struct passenger{
        address name;
        uint car_detail;
    }
    mapping(uint=>passenger) public rider;
    uint public no;

    constructor(){
        manager=msg.sender;
    }
    
    function registration(string memory _taxi,string memory _car,string memory _seat,uint _price,string memory _start,string memory _end) public {
        driver storage new_driver=detail[numrequests];
        numrequests++;
        new_driver.name=msg.sender;
        new_driver.taxi_no=_taxi;
        new_driver.car_detail=_car;
        new_driver.no_seat=_seat;
        new_driver.base_price=_price;
        new_driver.start_point=_start;
        new_driver.destination=_end;
        new_driver.register_time=block.timestamp;
    }

    function ride(uint _no) public{
        driver storage new_driver=detail[_no];
        require(new_driver.a==status.open,"car already booked");
        new_driver.a=status.booked;
        passenger storage new_pass=rider[no];
        no++;
        new_pass.name=msg.sender;
        new_pass.car_detail=_no;
    }

    function update_detail(uint _no,string memory _taxi,string memory _car,string memory _seat,uint _price,string memory _start,string memory _end) public {
        require(msg.sender==manager,"You Are Not Manger To Change Detail");
        driver storage new_driver=detail[_no];
        new_driver.taxi_no=_taxi;
        new_driver.car_detail=_car;
        new_driver.no_seat=_seat;
        new_driver.base_price=_price;
        new_driver.start_point=_start;
        new_driver.destination=_end;
    }

    function passenger_cancel(uint _no)public{
        passenger storage new_pass=rider[_no];
        require(msg.sender==new_pass.name,"You have not booked this ride");
        driver storage new_driver=detail[new_pass.car_detail];
        new_driver.a=status.cancel;
    }
}