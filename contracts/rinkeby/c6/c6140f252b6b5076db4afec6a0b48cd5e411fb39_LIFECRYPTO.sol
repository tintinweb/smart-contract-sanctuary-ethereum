/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;
 
contract LIFECRYPTO {
    mapping(string => address[]) private _userNameAddress;
    string[] private _listOfUsers;

    constructor(){
    }

    function getAddressByUser(string memory userName) public view returns (address[] memory) {
        return _userNameAddress[userName];
    }

    function checkUserNameAndAddress(string memory userName,address account) public view virtual returns (bool){
        uint256 totalUseraddress=_userNameAddress[userName].length;
        bool flag=false;
        for(uint i=0;i<totalUseraddress;i++){
            if (_userNameAddress[userName][i]==account) 
            {
                flag=true;
                break;
            }
             
        }
        return flag;
    }
    
    function checkExistsAddress(address account) internal virtual returns (bool){
        uint256 totalUsers = _listOfUsers.length;
        bool flag=false;
         for(uint j=0;j<totalUsers;j++){
             string memory userName = _listOfUsers[j];
            uint256 totalUseraddress=_userNameAddress[userName].length;
            for(uint i=0;i<totalUseraddress;i++){
                if (_userNameAddress[userName][i]==account) 
                {
                    flag=true;
                    break;
                }
                
            }
         }
        return flag;
    }

    function removeAddressAfterTransfer(string memory userName,address account) internal  virtual returns (bool) { 
        uint256 totalUseraddress=_userNameAddress[userName].length;
        bool flag=false;
        for(uint i=0;i<totalUseraddress;i++){
            if (_userNameAddress[userName][i]==account) 
            {
                _userNameAddress[userName][i]= address(0);
                deleteArray(userName);
                flag=true;
                break;
            }
             
        }
        return true; 
    }
   
 
    function setUserAddress(string memory userName, address walletAddress) public returns (bool) {
        require(walletAddress != address(0), "LIFE: walletAddress to the zero address");
        require(!checkExistsAddress(walletAddress), "LIFE: Address already exist!.");
        _userNameAddress[userName].push(walletAddress);
        _listOfUsers.push(userName);
        return true;
    }

    function transferUserAddress(string memory fromUserName, string memory toUserName, address transferAddress) public returns (bool) {
        require(transferAddress != address(0), "LIFE: walletAddress to the zero address");
        require(checkUserNameAndAddress(fromUserName,transferAddress), "LIFE: Address not found!.");
        require(!checkUserNameAndAddress(toUserName,transferAddress), "LIFE: Address already exist for toUserName!.");
        _userNameAddress[toUserName].push(transferAddress);
        removeAddressAfterTransfer(fromUserName,transferAddress);
        return true;
    }
    function deleteArray(string memory fromUserName) internal returns (bool) {
        uint256 totalUseraddress=_userNameAddress[fromUserName].length;
        uint256 count;
            for(uint i=0;i<totalUseraddress;i++){
                if ( _userNameAddress[fromUserName][i] == address(0)) 
                {
                    count +=1;
                }
                
            }
            if(totalUseraddress == count){
                delete _userNameAddress[fromUserName];
            }
        return true;
    }
}