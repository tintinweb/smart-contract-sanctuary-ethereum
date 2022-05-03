/**
 *Submitted for verification at Etherscan.io on 2022-05-03
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

    modifier fundsNotTransferred(uint _index) {
        require(Agreement_by_No[_index].fundsTransferred == false, "Funds were transferred");
        _;
    }

      modifier transferredFundsCorrectAmount(uint _price) {
        require(_price == msg.value, "Transffered amount does not match the price");
        _;
    }

    receive() payable external {
        balance += msg.value; // keep track of balance (in WEI)
    }

    function getContractPrice(uint _index) public view returns (uint256) { return Agreement_by_No[_index].finalPrice; }

    function createContract(string memory _startTime, string memory _pickupLoation, string memory _arrivalTime, string memory _finalDestination, uint256 _finalPrice, address payable _driver) transferredFundsCorrectAmount(_finalPrice) public payable {
        no_of_agreements++;
        balance += msg.value;
        Agreement_by_No[no_of_agreements] = Driver(_startTime, _pickupLoation, _arrivalTime, _finalDestination, _finalPrice, payable(msg.sender), _driver, false);
    }

    function getFundsAfterTransportCompleted(uint _index) notClient(_index) fundsNotTransferred(_index) public {
        Agreement_by_No[_index].driver.transfer(Agreement_by_No[_index].finalPrice);
        balance -= Agreement_by_No[_index].finalPrice;
        Agreement_by_No[_index].fundsTransferred = true;
    }
    
    function withdrawFundsAfterTransportCompleted(uint _index) onlyClient(_index) fundsNotTransferred(_index) public payable {
        Agreement_by_No[_index].driver.transfer(Agreement_by_No[_index].finalPrice); // send funds to given address
        balance -= Agreement_by_No[_index].finalPrice;
        Agreement_by_No[_index].fundsTransferred = true;
    }
}