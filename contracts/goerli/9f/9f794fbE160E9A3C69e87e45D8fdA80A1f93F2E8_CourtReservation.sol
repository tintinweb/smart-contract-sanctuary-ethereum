/**
 *Submitted for verification at Etherscan.io on 2023-01-16
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.17;


contract CourtReservation {

    uint balance;
    uint standby;

    struct Player {
        string name;
        string surname;
        string email;
        string phone_number;
        bool valid;
        Reservation[] reservations;
        uint must_pay;
    }

    mapping(address => Player) players;

    struct Court {
        bool valid;
        string name;
        uint price;
        Availability[] availability;
    }

    uint courts_counter = 0;
    mapping(uint => Court) courts;

    struct Availability {
        bool[] available;
        uint[] reservations_id;
        address[] address_player;
    }

    struct Reservation {
        uint reservations_id;
        uint court_number;
        uint day;
        uint hour;
        uint price;
        bool payed;
        bool validated;
        bool deleted;
        string payhash;
        string deletehash;
    }

    address owner;

    constructor () {
        owner = msg.sender;
        balance = 0;
        standby = 0;
    }

    modifier onlyOwner {
        require (owner == msg.sender, "Only owner can do this");
        _;
    }

    function deposit(uint _reservation_id) public payable {
        require(players[msg.sender].valid, "ERROR: player not valid");
        require(players[msg.sender].reservations[_reservation_id].payed == false, "ERROR: reservation already paid");
        players[msg.sender].reservations[_reservation_id].payed = true;
        players[msg.sender].reservations[_reservation_id].price = msg.value;
        players[msg.sender].must_pay = 0;
        balance += msg.value;
        standby += msg.value;
    }

    function setPaied(address _addr) public onlyOwner {
        players[_addr].must_pay = 0;
        players[_addr].valid = true;
    }

    function getBalance() public view returns (uint) {
        return balance;
    }

    function withdraw(uint _value) public onlyOwner {
        require(_value <= balance - standby, "ERROR: amount bigger than availability");
        payable(owner).transfer(_value);
    }

    function setPlayer(string memory _name, string memory _surname, string memory _email, string memory _phone_number) public {
        players[msg.sender].name = _name;
        players[msg.sender].surname = _surname;
        players[msg.sender].email = _email;
        players[msg.sender].phone_number = _phone_number;
        players[msg.sender].valid = false;
        players[msg.sender].must_pay = 0;
    }

    function setPlayerValidity(address _addr) public onlyOwner {
        players[_addr].valid = true;
    }

    function getPlayer() public view returns (string memory, string memory, string memory, string memory, bool) {
        return(
            players[msg.sender].name,
            players[msg.sender].surname,
            players[msg.sender].email,
            players[msg.sender].phone_number,
            players[msg.sender].valid
            );
    }

    function getPlayerFromAddress(address _addr) public view returns (string memory, string memory, string memory, string memory, uint, bool) {
        return(
            players[_addr].name,
            players[_addr].surname,
            players[_addr].email,
            players[_addr].phone_number,
            players[_addr].must_pay,
            players[_addr].valid
            );
    }

    function deletePlayer() public {
        require(players[msg.sender].valid, "ERROR: player not valid");
        require(players[msg.sender].reservations[players[msg.sender].reservations.length - 1].validated == true, "ERROR: last reservation not paid");
        players[msg.sender].valid = false;
    }

    function setCourt(string memory _name, uint _price) public onlyOwner {
        courts[courts_counter].valid = true;
        courts[courts_counter].name = _name;
        courts[courts_counter].price = _price;
        courts_counter++;
    }

    function getCourPrice(uint _court_number) public view returns (string memory, uint) {
        return (courts[_court_number].name, courts[_court_number].price);
    }

    function deleteCourt(uint _court_number) public onlyOwner {
        require(courts[_court_number].valid, "ERROR: court doesn't exist");
        courts[courts_counter].valid = false;
    }

    function setDay(uint _court_number, uint _day, uint _hours) public onlyOwner {
        require(courts[_court_number].valid, "ERROR: court doesn't exist");
        bool[] memory tmp_availability = new bool[](_hours);
        bool[] memory tmp_not_availability = new bool[](_hours);
        uint[] memory tmp_reservation_id = new uint[](_hours);
        address[] memory tmp_address = new address[](_hours);
        for (uint i = 0; i < _hours; i++){
            tmp_not_availability[i] = false;
            tmp_availability[i] = true;
            tmp_reservation_id[i] = 0;
            tmp_address[i] = 0x0000000000000000000000000000000000000000;
        }
        while (courts[_court_number].availability.length < _day){
            courts[_court_number].availability.push(Availability({
                available : tmp_not_availability,
                reservations_id : tmp_reservation_id,
                address_player : tmp_address
            }));
        }
        courts[_court_number].availability.push(Availability({
                available : tmp_availability,
                reservations_id : tmp_reservation_id,
                address_player : tmp_address
            }));
    }

    function getDay(uint _day) public view returns (Reservation[] memory) {
        Reservation[] memory founded_reservations;
        uint count = 0;
        for (uint i = 0; i < courts_counter; i++)
            for (uint j = 0; j < courts[i].availability[_day].available.length; j++)
                if (courts[i].availability[_day].available[j] == false)
                    count++;
        uint index = 0;
        founded_reservations = new Reservation[](count);
        for (uint i = 0; i < courts_counter; i++)
            for (uint j = 0; j < courts[i].availability[_day].available.length; j++)
                if (courts[i].availability[_day].available[j] == false && courts[i].availability[_day].address_player[j] != 0x0000000000000000000000000000000000000000){
                    founded_reservations[index] = players[courts[i].availability[_day].address_player[j]].reservations[courts[i].availability[_day].reservations_id[j]];
                    index++;
                }
        return founded_reservations;
    }

    function getAvailableHours(uint _day) public view returns (bool[] memory) {
        bool[] memory founded_hours;
        uint max = 0;
        for (uint i = 0; i < courts_counter; i++)
            if(courts[i].valid && courts[i].availability[_day].available.length > max)
                max = courts[i].availability[_day].available.length;
        founded_hours = new bool[](max);
        for (uint i = 0; i < max; i++)
            founded_hours[i] = false;
        for (uint i = 0; i < courts_counter; i++)
            if(courts[i].valid)
                for (uint j = 0; j < courts[i].availability[_day].available.length; j++)
                    if (courts[i].availability[_day].available[j])
                        founded_hours[j] = true;
        return founded_hours;
    }

    function setReservation(uint _court_number, uint _day, uint _hour) public {
        require(players[msg.sender].valid, "ERROR: player not valid");
        require(courts[_court_number].valid, "ERROR: court doesn't exist");
        require(courts[_court_number].availability[_day].available[_hour - 1], "ERROR: court not available");
        if(players[msg.sender].reservations.length == 0 || players[msg.sender].reservations[players[msg.sender].reservations.length - 1].validated) {
            Reservation memory tmp = Reservation({
            reservations_id : players[msg.sender].reservations.length,
            court_number : _court_number,
            day : _day,
            hour : _hour,
            price : 0,
            payed : false,
            validated : false, 
            deleted : false,
            payhash : "",
            deletehash : ""

        });
        players[msg.sender].reservations.push(tmp);
        players[msg.sender].must_pay = courts[_court_number].price / 2;
        courts[_court_number].availability[_day].available[_hour - 1] = false;
        courts[_court_number].availability[_day].reservations_id[_hour - 1] = players[msg.sender].reservations.length - 1;
        courts[_court_number].availability[_day].address_player[_hour - 1] = msg.sender;
        } else
            revert("ERROR: already have a registration");
    }

    function setValidRegistration(address _addr, uint _reservation_id) public onlyOwner {
        require(players[_addr].valid, "ERROR: player not valid");
        players[_addr].reservations[_reservation_id].validated = true;
        players[_addr].must_pay = 0;
        if (players[_addr].reservations[_reservation_id].payed)
            standby -= players[_addr].reservations[_reservation_id].price;
        players[_addr].reservations[_reservation_id].payed = true;
    }

    function getReservation(uint _reservation_id) public view returns (Reservation memory){
        return players[msg.sender].reservations[_reservation_id];
    }

    function getLatestReservation() public view returns (Reservation memory){
        return players[msg.sender].reservations[players[msg.sender].reservations.length - 1];
    }

    function deleteReservation(uint _reservation_id) public {
        require(players[msg.sender].valid, "ERROR: player not valid");
        require(players[msg.sender].reservations[_reservation_id].validated == false, "ERROR: already played");
        uint reimbursement = players[msg.sender].reservations[_reservation_id].price / 2;
        if (players[msg.sender].reservations[_reservation_id].payed) {
            if (payable(msg.sender).send(reimbursement)) {
                balance -= reimbursement;
                standby -= reimbursement * 2;
            }
        } else
            players[msg.sender].valid = false;
        courts[players[msg.sender].reservations[_reservation_id].court_number].availability[players[msg.sender].reservations[_reservation_id].day].available[players[msg.sender].reservations[_reservation_id].hour - 1] = true;
        players[msg.sender].reservations[_reservation_id].deleted = true;
        players[msg.sender].reservations[_reservation_id].validated = true;
    }

    function setPayHash(uint _reservation_id, string memory _txthash) public {
        require(players[msg.sender].valid, "ERROR: player not valid");
        players[msg.sender].reservations[_reservation_id].payhash = _txthash;
    }

    function setDeleteHash(uint _reservation_id, string memory _txthash) public {
        require(players[msg.sender].valid, "ERROR: player not valid");
        players[msg.sender].reservations[_reservation_id].deletehash = _txthash;
    }

    function getCourts() public view returns (uint[] memory) {
        uint[] memory founded_courts;
        uint count = 0;
        for (uint i = 0; i < courts_counter; i++) {
            courts[i].valid == true;
            count++;
        }
        founded_courts = new uint[](count);
        uint index = 0;
        for (uint i = 0; i < courts_counter; i++) {
            courts[i].valid == true;
            founded_courts[index] = i;
            index++;
        }
        return founded_courts;
    }

    function getFreeCourt(uint _day, uint _hour) public view returns (uint[] memory) {
        uint[] memory founded_courts;
        uint count = 0;
        for (uint i = 0; i < courts_counter; i++)
            if (courts[i].valid && courts[i].availability[_day].available.length > _hour)
                if (courts[i].valid && courts[i].availability[_day].available[_hour])
                    count++;
        founded_courts = new uint[](count);
        uint index = 0;
        for (uint i = 0; i < courts_counter; i++)
            if (courts[i].valid && courts[i].availability[_day].available.length > _hour)
                if (courts[i].valid && courts[i].availability[_day].available[_hour]){
                    founded_courts[index] = i;
                    index++;
                }
        return founded_courts;
    }

    function getPlayerReservations() public view returns (Reservation[] memory) {
        return players[msg.sender].reservations;
    }
}