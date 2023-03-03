// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract User {
    //personal information
    string _name;
    uint _age;
    string _phoneNumber;
    uint _height;
    string _birthday;
    string _email;
    string _linkedInURL;
    address private _owner;

    constructor(
        string memory name,
        uint age,
        string memory phoneNumber,
        uint height,
        string memory birthday,
        string memory email,
        string memory linkedInURL
    ) {
        _name = name;
        _age = age;
        _phoneNumber = phoneNumber;
        _height = height;
        _birthday = birthday;
        _email = email;
        _linkedInURL = linkedInURL;
        _owner = msg.sender;
        AllowedViewAddress[_owner] = true;
        AllowedAddAddress[_owner] = true;
    }

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

    // ownable contract

    function owner() public view returns (address) {
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

    //AllowedAddAddress[msg.sender]=true;

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

    //AllowedViewAddress[_owner] = true;

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