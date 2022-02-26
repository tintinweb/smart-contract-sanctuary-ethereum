/**
 *Submitted for verification at Etherscan.io on 2022-02-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 */
contract Signature {
    struct UserSignature {
        string userID;
        string userType;
        string signatureFile;
        string signatureS;
        int uploadDate;
        int[] usedDate;
    }

    mapping(string => UserSignature) public user;

    function storeSignature(string memory _userID,string memory _userType,string memory _signature,string memory _salt,int _uploadDate) public {
        require (bytes(_userID).length > 0,"Require userID.");
        require (bytes(_userType).length > 0,"Require userType.");
        require (bytes(_signature).length > 0,"Require signature.");
        int[] memory tmp;
        user[_userID] = UserSignature(_userID,_userType, _signature, _salt, _uploadDate,tmp);
    }

    function getSignature(string memory _userID) public view returns (UserSignature memory) { 
        require (bytes(_userID).length > 0,"Require userID.");
        return  user[_userID];
    }

    function loggetSignature(string memory _userID,int _timeNow) public {
        require (bytes(_userID).length > 0,"Require userID.");
         user[_userID].usedDate.push(_timeNow);
    }

    function getSignatureSalt(string memory _userID) public view returns (string memory) {
        require (bytes(_userID).length > 0,"Require userID.");
       return user[_userID].signatureS;
    }

}