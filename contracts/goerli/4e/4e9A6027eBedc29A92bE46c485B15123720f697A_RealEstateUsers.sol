//SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

contract RealEstateUsers{

   
    struct User{
        address  walletAddres;
        string firstName;
        string  lastName;
        string email;
        string password;
        string  phoneNumber;
        uint   dateOfBirth;
    }
    mapping (string => User) public Users;
    mapping(address=>string[]) public url_documentation;
    

    function createUsers(address _walletAddres,string memory _firstName,string memory _lastName, string memory _email,string memory _phoneNumber,uint _dateOfBirth,string memory _password) public{
       Users[_email] = User(_walletAddres,_firstName,_lastName,_email,_password,_phoneNumber,_dateOfBirth);
    }

    function add_documentOfUser(address userAddress,string memory _cid )  public{
        url_documentation[userAddress].push(_cid);
    }

    // function deopsit(address payable  wallateaddress) payable returns(string memory){

    // } 

    function getUser(string memory email) external  view returns (User memory) {
       return Users[email];
    }
    

}