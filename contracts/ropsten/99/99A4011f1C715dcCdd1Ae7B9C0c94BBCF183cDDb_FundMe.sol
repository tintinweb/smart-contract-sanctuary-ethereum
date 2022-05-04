// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract FundMe {

    address payable public owner;
    mapping(address => uint) public addressToAmount;
    uint public totalAmount;

    struct Fund {
        address funderAddr;
        uint fundAmount;
        string fundMessage;
    }

    event funded(Fund[]);

    Fund[] public funds;

    constructor() public {
        owner = payable(msg.sender);
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner external {
        owner = payable(_newOwner);
    }

    function fund(string memory _message) public payable {
        require(msg.value > 100);
        addressToAmount[msg.sender] += msg.value;
        totalAmount += msg.value;
        funds.push(Fund(msg.sender, msg.value, _message));
        emit funded(funds);
    }

    function withdraw() payable public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function getFunds() public view returns(Fund[] memory){
        return funds;
    }

    function getTotalAmount() public view returns(uint) {
        return totalAmount;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

}