/**
 *Submitted for verification at Etherscan.io on 2022-06-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract DigitalIdentity {
    struct UserI {
        string firstName;
        string lastName;
        string email;
        string CNP;
    }
    mapping(address => UserI) internal usersI;

    function setUserI(
        string calldata _firstName,
        string calldata _lastName,
        string calldata _email,
        string calldata _CNP
    ) public {
        usersI[msg.sender].firstName = _firstName;
        usersI[msg.sender].lastName = _lastName;
        usersI[msg.sender].email = _email;
        usersI[msg.sender].CNP = _CNP;
    }

    function getUserI(address _userAddress)
        public
        view
        returns (
            string memory _firstName,
            string memory _lastName,
            string memory _email,
            string memory _CNP
        )
    {
        UserI memory tempUser = usersI[_userAddress];
        return(
            tempUser.firstName,
            tempUser.lastName,
            tempUser.email,
            tempUser.CNP

        );
    }
}