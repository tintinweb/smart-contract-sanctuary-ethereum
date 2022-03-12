/**
 *Submitted for verification at Etherscan.io on 2022-03-11
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//web3 engineer www.twitter.com/SCowboy88


contract landBaronStorage{
    address owner;
    address public propertiesContract;
    address public grouperLooperContractAddress;

    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyPropertyContract{
        require(msg.sender == propertiesContract, "Only the property contract can call this function");
        _;
    }

    modifier onlyGrouperLooperContract{
        require(msg.sender == grouperLooperContractAddress, "Only the grouper looper contract can call this function");
        _;
    }

    constructor(){
        owner = msg.sender;
    } 

    function getOwner() external view returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) external {
        owner = _newOwner;
    }

    ///////////////Only Owner//////////////////

    function setPropertiesContract(address _propertiesContractAddress) external onlyOwner{
        propertiesContract = _propertiesContractAddress;
    }

    function setGrouperLooperContract(address _grouperLooperContractAddress) external onlyOwner{
        grouperLooperContractAddress = _grouperLooperContractAddress;
    }
    ////////////////////////////////


    ///////////////////Properties Contract////////////////

    struct reservationTimes{
        uint startTimestamp;
        uint stopTimestamp;
    }

    reservationTimes[] reset; //for resetting reservations array for property

    mapping (string=>bool) reservableStatus;
    mapping (string=>bool) propertyExists;
    mapping (string=>reservationTimes[]) reservations;
    
    string[] properties;

    function updateProperties(string[] memory _properties) external onlyPropertyContract{
        properties = _properties;
    }

    function getProperties() external view returns(string[] memory){
        return properties;
    }

    function getReservableStatus(string calldata _propertyName) external view returns(bool){
        return reservableStatus[_propertyName];
    }

    function getPropertyExists(string calldata _propertyName) external view returns(bool){
        return propertyExists[_propertyName];
    }

    function getReservations(string calldata _propertyName) external view returns(reservationTimes[] memory){
        require(propertyExists[_propertyName], "Property doesn't exist");
        return reservations[_propertyName];
    }

    function setReservableStatus(string calldata _propertyName, bool _status) external onlyPropertyContract{
        reservableStatus[_propertyName] = _status;
    }

    function setPropertyExists(string calldata _propertyName, bool _status) external onlyPropertyContract{
        propertyExists[_propertyName] = _status;
    }

    function resetReservations(string calldata _propertyName) external onlyPropertyContract{
        reservations[_propertyName] = reset;
    }

    function addReservation(string calldata _propertyName, uint _startTimestamp, uint _stopTimestamp) external onlyPropertyContract{
        reservations[_propertyName].push(reservationTimes(_startTimestamp, _stopTimestamp));
    }
    /////////////////End Properties Contract//////////////

    //////////////Land Baron Token Contract///////////////
    uint price = 1000000000000000000;
    // address = [];
    //////////////End Land Baron Contract/////////////////

    //////////////Grouper Looper Contract///////////////
    mapping (address=>uint) group;
	mapping (uint=>address[]) members;

    function getGroupId(address _member) external view returns(uint){
        return group[_member];
    }

    function getGroupMembers(uint _groupId) external view returns(address[] memory){
        return members[_groupId];
    }

    function addToGroup(address _member, uint _groupId) external onlyGrouperLooperContract{
        group[_member] = _groupId;
    }

    function removeFromGroup(address _member) external onlyGrouperLooperContract{
        group[_member] = 0;
    }

    function addToMembers(uint _groupId, address _member) external onlyGrouperLooperContract{
        members[_groupId].push(_member);
    }

    function updateMembers(uint _groupId, address[] calldata _members) external onlyGrouperLooperContract{
        members[_groupId] = _members;
    }
    // function removeFromMembers(uint _groupId, address _member)
    
    //////////////End Grouper Looper Contract////////////

}