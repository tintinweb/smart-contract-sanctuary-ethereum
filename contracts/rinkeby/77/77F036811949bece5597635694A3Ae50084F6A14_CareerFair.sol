//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract CareerFair {
    string private greeting;
    // My code
    address public owner;
    address[] public attendees;
    string[] companies;

    event logEnrollment(
        string indexed code,
        uint indexed enrollmentTime,
        string indexed message,
        address sender
    );

    event logAdd(
        string indexed code,
        uint indexed addTime,
        string indexed message,
        address sender
    );
    
    event logAttendees(
        string indexed code,
        address[] _attendees
    );

    event logConnection(
        string indexed message
    );

    // Maps
    mapping(address => bool) studentEnroll;
    mapping(string => bool) companyRegistered;
    mapping(address => uint) enrollmentIdx;


    constructor() {
        //console.log("Hello, ", msg.sender);

        owner = msg.sender;
        attendees.push(owner);
        enrollmentIdx[owner] = 0;

        // Load Initial Companies
        add("Amazon");
        add("Google");
        add("Apple");
        add("Microsoft");
        add("Meta");
        add("Gemini");
        add("SecureEd");



    }


    function enroll() public{
        //require(studentEnroll[msg.sender] == false,"Back to the Future much? You can't be in the same place at the same time. Only one career fair enrollment per student is accepted.");
        string memory _message;

        if(!studentEnroll[msg.sender]) {

            attendees.push(msg.sender);
            studentEnroll[msg.sender] = true;
            _message = string(abi.encodePacked(msg.sender, " was added to the Career Fair."));
            emit logEnrollment("eventEnroll", block.timestamp, _message, msg.sender);
            //console.log(_message);


        } else {

            _message = string(abi.encodePacked(msg.sender, " is already enrolled in the career fair."));
            emit logEnrollment("eventEnroll", block.timestamp, _message, msg.sender);
            //console.log(_message);


        }

        //console.log(_message);

    }


    function add(string memory companyName) public{
        //require(msg.sender == owner, "Only the owner can add a company.");
        string memory _message;

        if(msg.sender == owner){

            if(!companyRegistered[companyName]){

                companies.push(companyName);
                //companyRegistered[companyName] = companies.length - 1;
                _message = string(abi.encodePacked(companyName, " was added to the Career Fair.")); // ref: https://ethereum.stackexchange.com/questions/729/how-to-concatenate-strings-in-solidity
                companyRegistered[companyName] = true;
                emit logAdd("eventAddCompanySuccess", block.timestamp, _message, msg.sender);

            } else {

                _message = string(abi.encodePacked(companyName, " is already registered.")); 
                emit logAdd("eventAddCompanyFailed", block.timestamp, _message, msg.sender);

            }
        } else {

            _message = "Only the owner can add a company";
            emit logAdd("eventAddCompanyOwnerFailure", block.timestamp, _message, msg.sender);

        }

        //console.log(_message);

    }


    function getAttendees() public returns (address[] memory){
        emit logAttendees("eventGetAttendees", attendees);
        //console.log(attendees);
        return attendees;
    }


    function unenroll() public{
        // require(studentEnroll[msg.sender] == true,"One cannot very well unenroll from that which they have not enrolled, can they?");
        string memory _message;
        if (studentEnroll[msg.sender] && msg.sender != owner){    

            attendees.push(msg.sender);
            studentEnroll[msg.sender] = false;
            _message = string(abi.encodePacked(msg.sender, " has been unenrolled.")); 
            emit logEnrollment("eventUnenroll", block.timestamp, _message, msg.sender);

        } else {

            emit logEnrollment("eventUnenroll", block.timestamp, "You are already enrolled in the career fair", msg.sender);

        }
        //console.log(_message);
    }


    function getCompanyNum() public view returns (uint){
        return companies.length;
    }


    function getCompanies() public view returns (string[] memory){
        return companies;
    }

    function getLastAddedCompany() public view returns(string memory){
        uint _idx = companies.length - 1;
        return companies[_idx];
    }


    function testConnection() public returns (string memory){
        emit logConnection("Connection OK");
        return ("cnxt ok");
    }


    function getOwner() public view returns (address){
        return owner;
    }


    function getCompanyStatus(string memory _co) public view returns(bool){
        return companyRegistered[_co];
    }
 
}