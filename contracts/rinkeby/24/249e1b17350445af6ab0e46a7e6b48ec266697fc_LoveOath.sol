/**
 *Submitted for verification at Etherscan.io on 2022-08-30
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

contract LoveOath {
    address payable public owner;
    uint public fee = 0;

    /// Only contract owner is allowed to excute this function
    error NotOwner();

    modifier onlyOwner (){
        if (msg.sender!= owner) revert NotOwner();
        _;
    }

    constructor() payable {
        owner = payable(msg.sender);
    }

    function balanceOf() external view onlyOwner() returns(uint){
        return address(this).balance;
    }

    function setFee(uint _fee) public onlyOwner(){
        fee = _fee;
    }

    function fundMe() payable public {

    }

    function withdraw() public payable onlyOwner(){
        payable(msg.sender).transfer(address(this).balance);
    }

    address[] public registeredMarriages;
    mapping(address=>address[]) public marriagesByOwnerAddress;
    event ContractCreated(address contractAddress);

    function createMarriage(string memory _leftName, string memory _leftVows, string memory _rightName, string memory _rightVows, string memory _location,uint _date) public payable {
        require(msg.value >= fee, "Your balance is not enough for the fee");
        address newMarriage = address(new Marriage(msg.sender, _leftName, _leftVows, _rightName, _rightVows,_location, _date));
        marriagesByOwnerAddress[msg.sender].push(newMarriage);
        emit ContractCreated(newMarriage);
        registeredMarriages.push(newMarriage);
    }

    function getDeployedMarriages() public view returns ( address[] memory) {
        return registeredMarriages;
    }

    function getMarriagesByOwnerAddress(address ownerAddress) public view returns(address[] memory){
        return marriagesByOwnerAddress[address(ownerAddress)];
    }
}


contract Marriage {

    event weddingBells(address ringer, uint256 count);

    // Owner address
    address public owner;

    /// Marriage Vows
    string public leftName;
    string public leftVows;
    string public rightName;
    string public rightVows;
    string public location;
    // date public marriageDate;
    uint public marriageDate;
    
    // Bell counter
    uint256 public bellCounter;

    /**
    * @dev Throws if called by any account other than the owner
    */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
    * @dev Constructor sets the original `owner` of the contract to the sender account, and
    * commits the marriage details and vows to the blockchain
    */
    constructor(address _owner, string memory _leftName, string memory _leftVows, string memory _rightName, string memory _rightVows,string memory _location, uint _date) {
        // TODO: Assert statements for year, month, day
        owner = _owner;
        leftName = _leftName;
        leftVows = _leftVows;
        rightName = _rightName;
        rightVows = _rightVows;
        marriageDate = _date; 
        location = _location;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) private pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    /**
    * @dev ringBell is a payable function that allows people to celebrate the couple's marriage, and
    * also send Ether to the marriage contract
    */
    function ringBell() public payable {
        bellCounter = add(1, bellCounter);
        emit weddingBells(msg.sender, bellCounter);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function collect() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    /**
    * @dev withdraw allows the owner of the contract to withdraw all ether collected by bell ringers
    */
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    /**
    * @dev returns contract metadata in one function call, rather than separate .call()s
    */
    function getMarriageDetails() public view returns (
        address, string memory, string memory, string memory, string memory, string memory,uint, uint256,uint ) {
        return (
            owner,
            leftName,
            leftVows,
            rightName,
            rightVows,
            location,
            marriageDate,
            bellCounter,
            address(this).balance
        );
    }
}