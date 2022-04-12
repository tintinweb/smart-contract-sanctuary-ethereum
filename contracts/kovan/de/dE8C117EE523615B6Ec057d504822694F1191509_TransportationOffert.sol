/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

pragma solidity ^0.8.7;
// SPDX-License-Identifier: MIT

contract TransportationOffert { // 
    address public owner;
    uint256 public balance;
    uint public no_of_agreements = 0;
    
    struct Driver {
    string startTime;
    string pickupLoation;
    string arrivalTime;
    string finalDestination;
    uint256 finalPrice;
    address payable client;
    address payable driver;
    bool fundsTransferred;
    bool transportDone;
    }

    mapping(uint => Driver) public Agreement_by_No;

    modifier onlyClient(uint _index) {
        require(msg.sender == Agreement_by_No[_index].client, "Only Client can access this");
        _;
    }
    
    modifier notClient(uint _index) {
        require(msg.sender == Agreement_by_No[_index].driver, "Only Driver can access this");
        _;
    }

    modifier enoughFunds(uint _index) {
        require(msg.value >= uint(uint(Agreement_by_No[_index].finalPrice)), "Not enough Ether in your wallet");
        _;
    }

    modifier transportDone(uint _index) {
        require(Agreement_by_No[_index].transportDone == true, "Transport is not done");
        _;
    }

    modifier fundsNotTransferred(uint _index) {
        require(Agreement_by_No[_index].fundsTransferred == false, "Funds were transferred");
        _;
    }

    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }

    function getContractPrice(uint _index) public view returns (uint256) { return Agreement_by_No[_index].finalPrice; }

    function createContract(uint _index, string memory _startTime, string memory _pickupLoation, string memory _arrivalTime, string memory _finalDestination, uint256 _finalPrice, address payable _driver) public payable  onlyClient(_index) enoughFunds(_index) {
        require(msg.sender != address(0));
        no_of_agreements++;
        Agreement_by_No[no_of_agreements] = Driver(_startTime, _pickupLoation, _arrivalTime, _finalDestination, _finalPrice, payable(msg.sender), _driver, false, false);
    }

    function getFundsAfterTransportCompleted(uint _index) public payable notClient(_index) transportDone(_index) fundsNotTransferred(_index) {
        require(msg.sender != address(0));
        Agreement_by_No[no_of_agreements].driver.transfer(Agreement_by_No[no_of_agreements].finalPrice);
        balance -= Agreement_by_No[no_of_agreements].finalPrice;
        Agreement_by_No[no_of_agreements].fundsTransferred = true;
    }
    
    function withdrawFundsAfterTransportCompleted(uint _index) public payable onlyClient(_index) fundsNotTransferred(_index) {
        require(msg.sender != address(0));
        Agreement_by_No[no_of_agreements].driver.transfer(Agreement_by_No[no_of_agreements].finalPrice); // send funds to given address
        balance -= Agreement_by_No[no_of_agreements].finalPrice;
        Agreement_by_No[no_of_agreements].fundsTransferred = true;
    }

    function updateTransportCompleted(uint _index) public onlyClient(_index) {
        require(msg.sender != address(0));
        Agreement_by_No[no_of_agreements].transportDone = true;
    }
}