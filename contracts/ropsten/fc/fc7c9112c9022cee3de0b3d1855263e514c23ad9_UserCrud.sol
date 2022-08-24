/**
 *Submitted for verification at Etherscan.io on 2022-08-24
*/

pragma solidity ^0.8.6;
contract UserCrud {

  struct UserStruct {
    bytes32 userEmail;
    uint userAge;
    uint index;
  }
  
  mapping(address => UserStruct) private userStructs;
  address[] private userIndex;

  event LogNewUser(address indexed userAddress, uint index, bytes32 userEmail, uint userAge);
  event LogUpdateUser(address indexed userAddress, uint index, bytes32 userEmail, uint userAge);
  event LogDeleteUser(address indexed userAddress, uint index);

  function isUser(address userAddress)
    public 
    view
    returns(bool isIndeed) 
  {
    if(userIndex.length == 0) return false;
    if(userIndex.length <= userStructs[userAddress].index) return false;
    return (userIndex[userStructs[userAddress].index] == userAddress);
  }

  function insertUser(
    address userAddress, 
    bytes32 userEmail, 
    uint    userAge) 
    public
    returns(uint index)
  {
    require(!isUser(userAddress));

    userStructs[userAddress].userEmail = userEmail;
    userStructs[userAddress].userAge   = userAge;
    userIndex.push(userAddress);
    userStructs[userAddress].index     = userIndex.length-1;
    emit LogNewUser(
        userAddress, 
        userStructs[userAddress].index, 
        userEmail, 
        userAge);
    return userIndex.length-1;
  }

  function deleteUser(address userAddress) 
    public
    returns(uint index)
  {
    require(isUser(userAddress));
    uint rowToDelete = userStructs[userAddress].index;
    address keyToMove = userIndex[userIndex.length-1];
    userIndex[rowToDelete] = keyToMove;
    userStructs[keyToMove].index = rowToDelete; 
    userIndex.pop();
    emit LogDeleteUser(
        userAddress, 
        rowToDelete
    );
    emit LogUpdateUser(
        keyToMove, 
        rowToDelete, 
        userStructs[keyToMove].userEmail, 
        userStructs[keyToMove].userAge
    );
    return rowToDelete;
  }

  function getUser(address userAddress)
    public 
    view
    returns(bytes32 userEmail, uint userAge, uint index)
  {
    require(isUser(userAddress));

    return(
      userStructs[userAddress].userEmail, 
      userStructs[userAddress].userAge, 
      userStructs[userAddress].index
    );
  } 
  
  function updateUserEmail(address userAddress, bytes32 userEmail) 
    public
    returns(bool success) 
  {
    require(isUser(userAddress));
    userStructs[userAddress].userEmail = userEmail;
    emit LogUpdateUser(
      userAddress, 
      userStructs[userAddress].index,
      userEmail, 
      userStructs[userAddress].userAge
    );
    return true;
  }
  
  function updateUserAge(address userAddress, uint userAge) 
    public
    returns(bool success) 
  {
    require(isUser(userAddress)); 
    userStructs[userAddress].userAge = userAge;
    emit LogUpdateUser(
      userAddress, 
      userStructs[userAddress].index,
      userStructs[userAddress].userEmail, 
      userAge
    );
    return true;
  }

  function getUserCount() 
    public
    view
    returns(uint count)
  {
    return userIndex.length;
  }

  function getUserAtIndex(uint index)
    public
    view
    returns(address userAddress)
  {
    return userIndex[index];
  }

}