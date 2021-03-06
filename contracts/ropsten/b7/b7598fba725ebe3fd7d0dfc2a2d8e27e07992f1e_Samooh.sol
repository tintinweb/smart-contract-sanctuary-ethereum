/**
 *Submitted for verification at Etherscan.io on 2021-02-16
*/

pragma solidity ^0.6.0;


library UserAddress {
  struct data {
     address userAddress;
     bool isValue;
   }
}


contract Samooh {
    

    using UserAddress for UserAddress.data;
    
    mapping(string => UserAddress.data) public usernameMap;
    
    mapping(address => string) public userProfileDataMap;
    

    function setUsernameAddress(string memory _username) public {
        
        require(!usernameMap[_username].isValue, "username already exists.");

        usernameMap[_username].userAddress = msg.sender;
        usernameMap[_username].isValue = true;
      
    }
    

    function setUsernameProfile(string memory _profile) public {
        
        userProfileDataMap[msg.sender] = _profile;
        
    }

    function sendTip(address payable _toAddress) public payable {
        
        uint256 _fee = msg.value / 2;
        
        uint256 _amt = msg.value - _fee;
    
        _toAddress.transfer(_amt);
    }

    
}