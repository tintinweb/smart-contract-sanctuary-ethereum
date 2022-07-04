// SPDX-License-Identifier: MIT

pragma solidity >=0.6.6;

contract Stakeholder {
    address private owner;

    mapping(address => uint256[]) private addressToAmountFunded;
    mapping(address => uint256[]) private addressToMulti;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function fund() public payable onlyOwner{
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
    }

    function bet() public payable {
        uint256 minimumUSD = 10000000000000000;
        require(msg.value >= minimumUSD, "Minimum 0.01 ETH");
        addressToAmountFunded[msg.sender].push(msg.value);
    }

    function storeMulti(uint256 _multi) public{
        addressToMulti[msg.sender].push(_multi);
    }

    function retrieveMulti(address _address) public view returns (uint256){
        return addressToMulti[_address][addressToMulti[_address].length-1];
    }

    function retrieveAmount(address _address) public view returns (uint256){
        return addressToAmountFunded[_address][addressToAmountFunded[_address].length-1];
    }

    function withdraw(address _address) public onlyOwner {
        payable(_address).transfer(retrieveAmount(_address)*retrieveMulti(_address));

        addressToAmountFunded[_address].pop();
        addressToMulti[_address].pop();
    }
}