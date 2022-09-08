/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error accessDenied();
error notPresident();
error PersonNotExist();
error notPolice();
error notDoctor();
error nope();
error alreadyPayed();
error citizienAlreadyExist();

contract Goverment {
    struct Person {
        bytes name;
        bytes surname;
        uint birthDate;
        uint32 uniqueID;
        bytes country;
        bool driverLicence;
        uint8 traficPoint;
        bytes bloodGroup;
    }

    uint64 public citizienCount;
    mapping(address => Person) citiziens;
    address[] public doctors;
    address[] public polices;

    mapping(address => bool) public isPolice;
    mapping(address => bool) public isDoctor;

    mapping(uint32 => string[]) accidents;
    mapping(uint32 => string[]) diagnoses;

    mapping(uint256 => uint256) tickets;
    mapping(uint256 => bool) isTicketPayed;

    address public president;

    constructor() payable {
        president = msg.sender;
    }

    event newTicket(address indexed citizien, uint256 indexed ticketID);
    event ticketPayed(uint256 indexed ticketID);
    event deposit(address, uint);
    event unlicensedDriver(
        address indexed driverAddress,
        uint32 indexed driverID
    );
    event licenceSuspended(
        address indexed driverAddress,
        uint32 indexed driverID
    );

    receive() external payable {
        emit deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        emit deposit(msg.sender, msg.value);
    }

    modifier onlyPresident() {
        checkPresident();
        _;
    }

    modifier onlyPolice() {
        checkPolice();
        _;
    }
    modifier onlyDoctor() {
        checkDoctor();
        _;
    }

    function checkPresident() internal view {
        if (president != msg.sender) {
            revert notPresident();
        }
    }

    function checkPolice() internal view {
        if (!isPolice[msg.sender]) {
            revert notPolice();
        }
    }

    function checkDoctor() internal view {
        if (!isDoctor[msg.sender]) {
            revert notDoctor();
        }
    }

    function transferPresident(address newPresident) public onlyPresident {
        if (newPresident == address(0)) {
            revert nope();
        }
        president = newPresident;
    }

    function createuniqueID(
        address personAddress,
        bytes memory name,
        bytes memory surname,
        bytes memory country
    ) private pure returns (uint32) {
        return
            uint32(
                bytes4(
                    keccak256(abi.encode(personAddress, name, surname, country))
                )
            );
    }

    function registerCitizien(
        bytes memory name,
        bytes memory surname,
        bytes memory country,
        bool driverLicence,
        bytes memory bloodGroup
    ) public returns (uint32) {
        Person storage person = citiziens[msg.sender];

        if (person.uniqueID != 0) revert citizienAlreadyExist();

        citizienCount++;
        person.name = name;
        person.surname = surname;
        person.uniqueID = createuniqueID(msg.sender, name, surname, country);
        person.country = country;
        person.driverLicence = driverLicence;
        person.bloodGroup = bloodGroup;

        if (person.driverLicence) {
            person.traficPoint = 100;
        }

        return person.uniqueID;
    }

    function isCitizien(address personAddress) public view returns (bool) {
        if (citiziens[personAddress].uniqueID == 0) return false;
        else return true;
    }

    function assignPolice(address personAddress) public onlyPresident {
        Person storage person = citiziens[personAddress];

        if (person.uniqueID == 0) revert PersonNotExist();

        isPolice[personAddress] = true;
        polices.push(personAddress);
    }

    function assignDoctor(address personAddress) public onlyPresident {
        Person storage person = citiziens[personAddress];

        if (person.uniqueID == 0) revert PersonNotExist();

        isDoctor[personAddress] = true;
        doctors.push(personAddress);
    }

    function addDiagnose(address personAddress, string calldata diagnose)
        public
        onlyDoctor
    {
        Person storage patient = citiziens[personAddress];

        if (patient.uniqueID == 0) revert PersonNotExist();

        diagnoses[patient.uniqueID].push(diagnose);
    }

    function getDiagnoses(address personAddress)
        public
        view
        returns (string[] memory)
    {
        if (!(msg.sender == personAddress || isDoctor[msg.sender]))
            revert accessDenied();

        Person storage patient = citiziens[personAddress];
        return diagnoses[patient.uniqueID];
    }

    function addAccident(
        address personAddress,
        string calldata accident,
        uint8 penalty
    ) public onlyPolice {
        Person storage driver = citiziens[personAddress];

        if (driver.uniqueID == 0) revert PersonNotExist();

        accidents[driver.uniqueID].push(accident);
        if (driver.driverLicence) {
            driver.traficPoint = driver.traficPoint - penalty;

            if (driver.traficPoint <= 0) {
                driver.traficPoint = 0;
                driver.driverLicence = false;
            }
            emit licenceSuspended(personAddress, driver.uniqueID);
        } else emit unlicensedDriver(personAddress, driver.uniqueID);
    }

    function getAccidents(address personAddress)
        public
        view
        returns (string[] memory)
    {
        if (!(msg.sender == personAddress || isPolice[msg.sender]))
            revert accessDenied();

        Person storage driver = citiziens[personAddress];
        return accidents[driver.uniqueID];
    }

    function createTicketID(address personAddress, uint256 value)
        private
        view
        returns (uint32)
    {
        return
            uint32(
                bytes4(
                    keccak256(abi.encode(personAddress, value, block.number))
                )
            );
    }

    function giveTrafficTicket(address personAddress, uint256 penalty)
        public
        onlyPolice
        returns (uint32)
    {
        uint32 ticketID = createTicketID(personAddress, penalty);
        tickets[ticketID] = penalty;
        emit newTicket(personAddress, ticketID);
        return ticketID;
    }

    function payTrafficTicket(uint256 ticketID) public {
        if (isTicketPayed[ticketID]) revert alreadyPayed();

        (bool sent, ) = address(this).call{value: tickets[ticketID]}("");
        require(sent, "Failed to pay");

        if (sent) isTicketPayed[ticketID] = true;
        emit ticketPayed(ticketID);
    }

    function getJob(address personAddress) private view returns (bytes memory) {
        if (president == personAddress) return bytes("president");
        else if (isDoctor[personAddress]) return bytes("doctor");
        else if (isPolice[personAddress]) return bytes("police");
        else if (isCitizien(personAddress)) return bytes("citiizen");
        else return bytes("");
    }

    function getBasicInfo(address personAddress)
        public
        view
        returns (
            bytes memory, //name,
            bytes memory, //surname,
            bytes memory //job
        )
    {
        if (!isCitizien(msg.sender)) revert accessDenied();
        Person storage person = citiziens[personAddress];

        return (person.name, person.surname, getJob(personAddress));
    }

    function getMedicalInfo(address personAddress)
        public
        view
        onlyDoctor
        returns (
            bytes memory, //name,
            bytes memory, //surname,
            uint32, //uniqueID
            bytes memory //bloodgroup
        )
    {
        Person storage person = citiziens[personAddress];

        return (
            person.name,
            person.surname,
            person.uniqueID,
            person.bloodGroup
        );
    }

    function getTraficInfo(address personAddress)
        public
        view
        onlyPolice
        returns (
            bytes memory, //name,
            bytes memory, //surname,
            uint32, //uniqueID
            bytes memory, //bloodgroup
            bytes memory, //country
            bool, //driverLicence;
            uint8 //traficPoint;
        )
    {
        Person storage person = citiziens[personAddress];

        return (
            person.name,
            person.surname,
            person.uniqueID,
            person.bloodGroup,
            person.country,
            person.driverLicence,
            person.traficPoint
        );
    }
}