// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**@title A Sample Storing Data Contract
 * @author Eugenio Flores
 * @notice This is a demo contract to store data
 * @dev This contract implements struct and mappings
 */

contract DataStorage {
    struct People {
        string name;
        string idNumber;
        string email;
        uint256 amount;
    }

    People[] private s_people;
    mapping(string => string) private s_idNumberToName;
    mapping(string => uint256) private s_idNumberToAmount;
    mapping(string => string) private s_idNumberToEmail;

    /**@notice Stores data in the contract*/
    function addPerson(
        string memory _name,
        string memory _idNumber,
        string memory _email,
        uint256 _amount
    ) public {
        s_people.push(People(_name, _idNumber, _email, _amount));
        s_idNumberToName[_idNumber] = _name;
        s_idNumberToAmount[_idNumber] = _amount;
        s_idNumberToEmail[_idNumber] = _email;
    }

    /** @notice Fetch the data of a person
     *  @param _idNumber the id of a person
     *  @return name, email and amount of the person
     */
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
            s_idNumberToName[_idNumber],
            s_idNumberToEmail[_idNumber],
            s_idNumberToAmount[_idNumber]
        );
    }

    function getPeopleArr(uint256 index) public view returns (People memory) {
        return s_people[index];
    }
}