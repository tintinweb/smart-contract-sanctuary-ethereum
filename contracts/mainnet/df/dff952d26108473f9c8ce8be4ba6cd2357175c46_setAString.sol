/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

pragma solidity ^0.8.4;

contract setAString {

    string public setMe;
    IAmAStruct public globalStruct;

    struct IAmAStruct {
        address AAddress;
        string AString;
    }

    function getMeMyArrayLength(IAmAStruct memory _a) public {
        globalStruct.AAddress = _a.AAddress;
        globalStruct.AString = _a.AString;
    }


    function setMeAString(string memory _a) public {
        setMe = _a;
    }

}