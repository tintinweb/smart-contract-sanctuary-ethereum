// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**@title A contract for storing data
 * @author Eugenio Pacelli Flores
 * @notice This contract is to demo a storing data contract
 */

contract DataStorage {
    struct People {
        string name;
        string idNumber;
        string email;
        uint256 amount;
    }

    People[] public people;
    mapping(string => string) idNumberToName;
    mapping(string => uint256) idNumberToAmount;
    mapping(string => string) idNumberToEmail;

    function addPerson(
        string memory _name,
        string memory _idNumber,
        string memory _email,
        uint256 _amount
    ) public {
        people.push(People(_name, _idNumber, _email, _amount));
        idNumberToName[_idNumber] = _name;
        idNumberToAmount[_idNumber] = _amount;
        idNumberToEmail[_idNumber] = _email;
    }

    function getData(string memory _idNumber)
        public
        view
        returns (
            string memory,
            string memory,
            uint256
        )
    {
        return (
            idNumberToName[_idNumber],
            idNumberToEmail[_idNumber],
            idNumberToAmount[_idNumber]
        );
    }
}