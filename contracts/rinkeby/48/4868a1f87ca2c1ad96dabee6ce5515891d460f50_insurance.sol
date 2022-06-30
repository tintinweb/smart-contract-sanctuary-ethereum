/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// File: Name.insurance.sol


pragma solidity ^0.8.9;

contract insurance {
    
    address owner;
    address cryptoSpaceAddress;
    mapping (address =>uint) insuranceDates;
    mapping (uint => address) insuranceAddresses;
    uint addressesCounter;

    event addUser(uint indexed userId, address indexed userAddress, uint indexed insuranceAmount);

    constructor(address _owner){
        owner = _owner;
    }
    receive() external payable{}

    modifier onlyOwner() {
      require(owner == msg.sender, "Ownable: caller is not the owner");
      _;
    }

    modifier onlyCryptoSpace() {
      require(cryptoSpaceAddress == msg.sender, "Ownable: caller is not the owner");
      _;
    }

    function setCryptoSpaceAddress(address _cryptoSpaceAddress) external onlyOwner {
        cryptoSpaceAddress = _cryptoSpaceAddress;
    }

    function writeInsuranceDates(uint256 Ipayment, address Iaddress) external onlyCryptoSpace {
        addressesCounter++;
        insuranceAddresses[addressesCounter] = Iaddress;
        insuranceDates[Iaddress] = Ipayment;
        emit addUser(addressesCounter, Iaddress, Ipayment);
    }
    
    function payment() external payable onlyCryptoSpace {
        for (uint i = 1; i <=addressesCounter; i++) {  
            address receiver = insuranceAddresses[i];
            uint amount = insuranceDates[receiver];
            (bool success, ) = receiver.call{value: amount}("");
            require(success, "Failed to send insurance");
        }
    }

    function getBalance() public view onlyOwner returns(uint256) {
        return address(this).balance;
    }

    function withdraw(address _receiver) external onlyOwner {
        (bool success, ) = _receiver.call{value: address(this).balance}("");
        require(success, "Failed");
    }
}