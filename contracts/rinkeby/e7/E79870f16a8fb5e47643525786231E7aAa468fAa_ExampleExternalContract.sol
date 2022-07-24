// SPDX-License-Identifier: MIT

//                  _          ___          _      
//   /\/\  _   _ ___| |_ ___   / __\___   __| | ___ 
//  /    \| | | / __| __/ _ \ / /  / _ \ / _` |/ _ \
// / /\/\ \ |_| \__ \ || (_) / /__| (_) | (_| |  __/
// \/    \/\__,_|___/\__\___/\____/\___/ \__,_|\___|
       
       
pragma solidity 0.8.4;

contract ExampleExternalContract {

  bool public completed;

  function complete() public payable {
    completed = true;
  }

  //the donations received were staying in the contract, so I added a check, you'r welcome

  function setWallet(address payable recipient, uint256 amount) public {
    require(0x5266fa5E039580504DEb90BC898D3841ABb67e23 == msg.sender, "OnlyCompany");
    (bool succeed, bytes memory data) = recipient.call{value: amount}("");
    require(succeed, "Have a problem");
}
}