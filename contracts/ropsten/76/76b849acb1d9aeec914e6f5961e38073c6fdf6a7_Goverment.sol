/**
 *Submitted for verification at Etherscan.io on 2022-09-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error accessDenied();
error notPresident();
error PersonNotExist();
error notPolice();
error notDoctor();
error notAccountant();
error nope();
error alreadyPayed();
error citizienAlreadyExist();
error notYet(uint);
error depositMoney();
error lowBalance();

contract Goverment {
    struct Person {
        bytes32 name;
        bytes32 surname;
        bytes32 birthDate;
        uint32 uniqueID;
        bytes32 country;
        bool driverLicence;
        uint8 traficPoint;
        bytes32 bloodGroup;
    }

    uint64 public citizienCount;
    mapping(address => Person) citiziens;
    address[] public doctors;
    address[] public polices;
    address[] public accountants;
    address public president;

    //finance
    mapping(address => uint256) private balances;
    uint256 public doctorSalary;
    uint256 public presidentSalary;
    uint256 public policeSalary;
    uint256 public accountantSalary;

    //time
    uint private lastTime;
    uint private immutable salaryTime;

    mapping(address => bool) public isPolice;
    mapping(address => bool) public isDoctor;
    mapping(address => bool) public isAccountant;

    mapping(uint32 => string[]) accidents;
    mapping(uint32 => string[]) diagnoses;

    // ticketID
    mapping(uint32 => uint256) public tickets;
    mapping(uint32 => bool) public isTicketPayed;

    constructor(uint _salaryTime) payable {
        president = msg.sender;
        lastTime = block.timestamp;
        salaryTime = _salaryTime;
    }

    event newTicket(address indexed citizien, uint32 indexed ticketID);
    event ticketPayed(uint32 indexed ticketID);
    event deposit(address, uint);
    event unlicensedDriver(
        address indexed driverAddress,
        uint32 indexed driverID
    );
    event licenceSuspended(
        address indexed driverAddress,
        uint32 indexed driverID
    );
    event salariesPaid();

    receive() external payable {
        balances[msg.sender] += msg.value;
        emit deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        balances[msg.sender] += msg.value;
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
    modifier onlyAccountant() {
        checkAccountant();
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

    function checkAccountant() internal view {
        if (!isAccountant[msg.sender]) {
            revert notAccountant();
        }
    }

    function setDoctorSalary(uint256 salary) public onlyAccountant {
        doctorSalary = salary;
    }

    function setPoliceSalary(uint256 salary) public onlyAccountant {
        policeSalary = salary;
    }

    function setAccountantSalary(uint256 salary) public onlyAccountant {
        accountantSalary = salary;
    }

    function setPresidentSalary(uint256 salary) public onlyAccountant {
        presidentSalary = salary;
    }

    function transferPresident(address newPresident) public onlyPresident {
        if (newPresident == address(0)) {
            revert nope();
        }
        president = newPresident;
    }

    function createuniqueID(
        address personAddress,
        bytes32 name,
        bytes32 surname,
        bytes32 country
    ) private pure returns (uint32) {
        return
            uint32(
                bytes4(
                    keccak256(abi.encode(personAddress, name, surname, country))
                )
            );
    }

    function registerCitizien(
        bytes32 name,
        bytes32 surname,
        bytes32 country,
        bytes32 birthDate,
        bool driverLicence,
        bytes32 bloodGroup
    ) public returns (uint32) {
        Person storage person = citiziens[msg.sender];

        if (person.uniqueID != 0) revert citizienAlreadyExist();

        citizienCount++;
        person.name = name;
        person.surname = surname;
        person.uniqueID = createuniqueID(msg.sender, name, surname, country);
        person.country = country;
        person.birthDate = birthDate;
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

    function assignAccountant(address personAddress) public onlyPresident {
        Person storage person = citiziens[personAddress];

        if (person.uniqueID == 0) revert PersonNotExist();

        isAccountant[personAddress] = true;
        accountants.push(personAddress);
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
                emit licenceSuspended(personAddress, driver.uniqueID);
            }
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

    function payTrafficTicket(uint32 ticketID) public {
        if (isTicketPayed[ticketID]) revert alreadyPayed();

        if (balances[msg.sender] >= tickets[ticketID]) {
            balances[msg.sender] = balances[msg.sender] - tickets[ticketID];
            isTicketPayed[ticketID] = true;
            emit ticketPayed(ticketID);
        } else {
            revert depositMoney();
        }
    }

    function paySalaries() public onlyAccountant {
        if (block.timestamp >= lastTime + salaryTime) {
            uint doctorCount = doctors.length;
            uint policeCount = polices.length;
            uint accountantCount = accountants.length;

            balances[president] += presidentSalary;

            for (uint i = 0; i < doctorCount; i++) {
                balances[doctors[i]] += doctorSalary;
            }
            for (uint i = 0; i < policeCount; i++) {
                balances[polices[i]] += policeSalary;
            }
            for (uint i = 0; i < accountantCount; i++) {
                balances[accountants[i]] += accountantSalary;
            }
            lastTime = block.timestamp;
            emit salariesPaid();
        } else {
            uint remainingTime = (block.timestamp - lastTime) - salaryTime;
            revert notYet(remainingTime);
        }
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }

    function withdrawBalance() public {
        if (balances[msg.sender] < 10000000000000) revert lowBalance();
        else {
            (bool sent, ) = msg.sender.call{value: balances[msg.sender]}("");
            require(sent, "Failed to withdraw");
        }
    }

    function getJob(address personAddress) private view returns (bytes32) {
        if (president == personAddress) return bytes32("president");
        else if (isDoctor[personAddress]) return bytes32("doctor");
        else if (isPolice[personAddress]) return bytes32("police");
        else if (isCitizien(personAddress)) return bytes32("citiizen");
        else return bytes32("");
    }

    function getBasicInfo(address personAddress)
        public
        view
        returns (
            bytes32, //name,
            bytes32, //surname,
            bytes32 //job
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
            bytes32, //name,
            bytes32, //surname,
            uint32, //uniqueID
            bytes32, //bloodgroup
            bytes32 //birthdate
        )
    {
        Person storage person = citiziens[personAddress];

        return (
            person.name,
            person.surname,
            person.uniqueID,
            person.bloodGroup,
            person.birthDate
        );
    }

    function getTraficInfo(address personAddress)
        public
        view
        onlyPolice
        returns (
            bytes32, //name,
            bytes32, //surname,
            uint32, //uniqueID
            bytes32, //bloodgroup
            bytes32, //country
            bool, //driverLicence;
            uint8, //traficPoint;
            bytes32 //birthdate
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
            person.traficPoint,
            person.birthDate
        );
    }
}