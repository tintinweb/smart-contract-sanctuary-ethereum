// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address private _owner;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view onlyOwner returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    //Allow some address to add education / certificate / work experience
    mapping(address => bool) public AllowedAddAddress;

    function setAllowedAddAddress(address _address) public onlyOwner {
        AllowedAddAddress[_address] = true;
    }

    function isAllowedAddAddress() public view returns (bool) {
        return AllowedAddAddress[msg.sender];
    }

    modifier onlyAllowedAddAddress() {
        require(isAllowedAddAddress(), "The function cannot be used at this address !!");
        _;
    }
    //Allow some address to view education / certificate / work experience
    mapping(address => bool) public AllowedViewAddress;

    function setAllowedViewAddress(address _address) public onlyOwner {
        AllowedViewAddress[_address] = true;
    }

    function isAllowedViewAddress() public view returns (bool) {
        return AllowedViewAddress[msg.sender];
    }

    modifier onlyAllowedViewAddress() {
        require(isAllowedViewAddress(), "The function cannot be used at this address !!");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";

contract User is Ownable {
    //personal information
    string _name;
    uint _age;
    string _phoneNumber;
    uint _height;
    string _birthday;
    string _email;
    string _linkedInURL;

    // constructor(
    //     string memory name,
    //     uint age,
    //     string memory phoneNumber,
    //     uint height,
    //     string memory birthday,
    //     string memory email,
    //     string memory linkedInURL
    // ) {
    //     _name = name;
    //     _age = age;
    //     _phoneNumber = phoneNumber;
    //     _height = height;
    //     _birthday = birthday;
    //     _email = email;
    //     _linkedInURL = linkedInURL;
    // }

    //Education
    struct Education {
        string school;
        string degree;
        string major;
    }
    Education[] private education;

    function addEducation(
        string memory _school,
        string memory _degree,
        string memory _major
    ) public onlyAllowedAddAddress {
        education.push(Education(_school, _degree, _major));
    }

    function getEducation() public view onlyAllowedViewAddress returns (Education[] memory) {
        return education;
    }

    //Certificate
    struct Certificate {
        string nameOfcertificate;
        string grade;
        string date;
    }
    Certificate[] private certificate;

    function addCertificate(
        string memory _nameOfCertificate,
        string memory _grade,
        string memory _date
    ) public onlyAllowedAddAddress {
        certificate.push(Certificate(_nameOfCertificate, _grade, _date));
    }

    function getCertificate() public view onlyAllowedViewAddress returns (Certificate[] memory) {
        return certificate;
    }

    //Working Experience
    struct WorkingExperience {
        string nameOfCompany;
        string duration;
        string position;
    }
    WorkingExperience[] private workingExperience;

    function addWorkingExperience(
        string memory _nameOfCompany,
        string memory _duration,
        string memory _position
    ) public onlyAllowedAddAddress {
        workingExperience.push(WorkingExperience(_nameOfCompany, _duration, _position));
    }

    function getWorkingExperience()
        public
        view
        onlyAllowedViewAddress
        returns (WorkingExperience[] memory)
    {
        return workingExperience;
    }

    //Getter of Personal information
    function getName() public view onlyAllowedViewAddress returns (string memory) {
        return _name;
    }

    function getAge() public view onlyAllowedViewAddress returns (uint) {
        return _age;
    }

    function getPhoneNumber() public view onlyAllowedViewAddress returns (string memory) {
        return _phoneNumber;
    }

    function getHeight() public view onlyAllowedViewAddress returns (uint) {
        return _height;
    }

    function getBirthday() public view onlyAllowedViewAddress returns (string memory) {
        return _birthday;
    }

    function getEmail() public view onlyAllowedViewAddress returns (string memory) {
        return _email;
    }

    function getLinkedInURL() public view onlyAllowedViewAddress returns (string memory) {
        return _linkedInURL;
    }

    //Setter of Personal information
    function setName(string memory name) public onlyOwner {
        _name = name;
    }

    function setAge(uint age) public onlyOwner {
        _age = age;
    }

    function setPhoneNumber(string memory phoneNumber) public onlyOwner {
        _phoneNumber = phoneNumber;
    }

    function setHeight(uint height) public onlyOwner {
        _height = height;
    }

    function setBirthday(string memory birthday) public onlyOwner {
        _birthday = birthday;
    }

    function setEmail(string memory email) public onlyOwner {
        _email = email;
    }

    function setLinkedInURL(string memory linkedInURL) public onlyOwner {
        _linkedInURL = linkedInURL;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./User.sol";

contract UserFactory {
    User[] public userArray;

    function createUserContract() public {
        User user = new User();
        userArray.push(user);
    }

    function getUserIndex() public view returns (uint) {
        return userArray.length;
    }

    function userRegister(
        uint256 _userIndex,
        string memory _name,
        uint _age,
        string memory _phoneNumber,
        uint _height,
        string memory _birthday,
        string memory _email,
        string memory _linkedInURL
    ) public {
        userArray[_userIndex - 1].setName(_name);
        userArray[_userIndex - 1].setAge(_age);
        userArray[_userIndex - 1].setPhoneNumber(_phoneNumber);
        userArray[_userIndex - 1].setHeight(_height);
        userArray[_userIndex - 1].setBirthday(_birthday);
        userArray[_userIndex - 1].setEmail(_email);
        userArray[_userIndex - 1].setLinkedInURL(_linkedInURL);
    }

    function getInfo(
        uint256 _userIndex
    )
        public
        view
        returns (
            string memory userName,
            uint userAge,
            string memory userPhone,
            uint userHeight,
            string memory userBirthday,
            string memory userEmail,
            string memory userLinkedInURL
        )
    {
        userName = userArray[_userIndex - 1].getName();
        userAge = userArray[_userIndex - 1].getAge();
        userPhone = userArray[_userIndex - 1].getPhoneNumber();
        userHeight = userArray[_userIndex - 1].getHeight();
        userBirthday = userArray[_userIndex - 1].getBirthday();
        userEmail = userArray[_userIndex - 1].getEmail();
        userLinkedInURL = userArray[_userIndex - 1].getLinkedInURL();
        return (userName, userAge, userPhone, userHeight, userBirthday, userEmail, userLinkedInURL);
    }
}