// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Donation {

  address public owner;
  address[] internal arrayOfDonators;
  address public donationAddress;
  uint internal arrayIndex;

  constructor() {
    owner = msg.sender;
    donationAddress = address(this);
    arrayIndex = 1;
  }

  mapping (address => uint) internal donation;

  event Received(address, uint);

  function donate () public payable {
    donation[msg.sender] += msg.value;
/*   
    // должен был добавлять в массив только уникальные адреса
    bool isDonatorExist = false;
    
    for(uint i = 0; i <= arrayIndex; i++) {
      if (msg.sender == arrayOfDonators[i]){
        isDonatorExist = true;
      }
    }

    if (isDonatorExist == false) {
      arrayOfDonators.push(msg.sender);
      arrayIndex++;
    } 
*/
    arrayOfDonators.push(msg.sender);

    emit Received(msg.sender, msg.value);
  }

  function getBalance () public view returns (uint) {
    return address(this).balance;
  }

  function showDonationSum (address donatorAddress) public view returns (uint) {
    return donation[donatorAddress];
  }

  function showAllDonators () public view returns (address[] memory) {
    return arrayOfDonators;
  }

  function withdrawDonations (address payable _receiver) external onlyOwner {
    _receiver.transfer(address(this).balance);
  }

  modifier onlyOwner () {
    require(msg.sender == owner, "You`re not an owner!");
    _;
  }

  receive() external payable {
    donation[msg.sender] += msg.value;
    arrayOfDonators.push(msg.sender);

    emit Received(msg.sender, msg.value);
  }
}