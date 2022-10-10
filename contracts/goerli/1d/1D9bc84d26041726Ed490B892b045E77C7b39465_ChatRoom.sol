// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.2;

// 0xC9F7b2fBa1273bbb4820430f1807EE942F5545D6
contract ChatRoom {
  string public announcement;
  uint256 public announcementLastPaidVal;

  mapping(address => string[]) public userToMsgs;

  event newMessage(address user, string message);
  event newAnnouncementEvent(address user, string message);
  event newAnnouncementLastPaidVal(address user, uint256 value);

  function newMsg(string memory str) public {
    userToMsgs[msg.sender].push(str);
    emit newMessage(msg.sender, str);
  }

  function lenUserToMsgs(address user) public view returns (uint256) {
    return userToMsgs[user].length;
  }

  function showLastestMsg(uint256 len, address user) public view returns (string[] memory) {
    require(len != 0 && user != address(0), "Input not valid");

    uint256 totalLen = userToMsgs[user].length;
    uint256 finalLen = totalLen > len ? len : totalLen;
    string[] memory retMsgs = new string[](finalLen); 
    if(finalLen == 0) return retMsgs;

    uint256 index = totalLen - 1;
    uint256 k = 0;
    while(index >= 0){
      retMsgs[k] = userToMsgs[user][index];
      if(index > 0) index--;
      k++;
      if(k == finalLen) break;
    }
    return retMsgs;
  }

  function newAnnouncement(string memory str) public payable {
    require(msg.value > announcementLastPaidVal, "Not enough fund");
    announcementLastPaidVal = msg.value;
    announcement = str;
    emit newAnnouncementEvent(msg.sender, str);
    emit newAnnouncementLastPaidVal(msg.sender, announcementLastPaidVal);
  }
}