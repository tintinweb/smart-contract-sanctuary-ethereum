/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.6.6;

contract simpleStorage {

    uint256 public storeNumber;

    struct people {
        uint256 number;
        string name;
    }

    //Below code store number and name just for one person. 
    //people public person = people ({number: 2, name: "haseeb"});


    //Lets create an array and store data for many people

    people [] public PEOPLE; 
    //Mapping is some type of key and it spits out whatever variable its mapped to. 
    mapping (string => uint256) public nameToNumber;

    function storageFunction (uint256 _myStoredNumber) public {
            storeNumber = _myStoredNumber;
    }

    function retrieve() public view returns(uint256) {
        return storeNumber;
    }

    function addPerson (string memory _name, uint256 _number) public {
        PEOPLE.push(people({number: _number, name: _name}));
        nameToNumber[_name] = _number;
    }

}