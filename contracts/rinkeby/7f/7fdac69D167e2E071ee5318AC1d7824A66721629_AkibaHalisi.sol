//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

//create a smart contract by the name akibaHalisi
//the contract should be able to create and store usersaccount
//users should be able to deposit and withdraw funds(after a required time stamp is reached

contract AkibaHalisi {
  address public i_Owner;
  uint256 accountNumber;

  constructor() {
    i_Owner = msg.sender;
  }

  modifier onlyOwner() {
    require(i_Owner == msg.sender, "not the owner");
    _;
  }

  struct UserAccount {
    string userName;
    uint256 userId;
    uint256 accountNumber;
  }

  UserAccount[] useraccount;
  mapping(string => uint256) public userNameToUserId;

  function storeAccount(uint256 _accountNumber) public {
    accountNumber = _accountNumber;
  }

  function retrieve() public view returns (uint256) {
    return accountNumber;
  }

  function createUserAccount(
    string memory _userName,
    uint256 _userId,
    uint256 _accountNumber
  ) public onlyOwner {
    useraccount.push(UserAccount(_userName, _userId, _accountNumber));
    userNameToUserId[_userName] = _userId;
  }
}