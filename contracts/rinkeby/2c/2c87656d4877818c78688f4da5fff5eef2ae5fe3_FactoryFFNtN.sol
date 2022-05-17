/**
 *Submitted for verification at Etherscan.io on 2022-05-17
*/

// SPDX-License-Identifier : MIT

pragma solidity ^0.6.0;

contract FromFirstNametoName {

    function addPerson (string memory _firstName, string memory _name) public {
        NameToFirstName[_firstName] = _name ;
    }

    mapping (string => string) public NameToFirstName;



}

contract FactoryFFNtN {
    
    FromFirstNametoName[] FFNtNArray; 


    function CreateFFNtNContract() public {
        FromFirstNametoName ffntn = new FromFirstNametoName();
        FFNtNArray.push(ffntn);
    }
    
    function addTheme (uint256 FFNTNIndex, string memory _theme) public {
        FromThemetoIndex[_theme] = FFNTNIndex ;
    }

    mapping (string => uint)  FromThemetoIndex;

    function faddPerson(string memory _theme, string memory _ffirstName, string memory _fname) public {
        FromFirstNametoName(address(FFNtNArray[FromThemetoIndex[_theme]])).addPerson( _ffirstName, _fname);
    }

    function fRetrieve(string memory _theme, string memory _ffirstName) public view returns (string memory) {
        return FromFirstNametoName(address(FFNtNArray[FromThemetoIndex[_theme]])).NameToFirstName( _ffirstName);
    }
}