/**
 *Submitted for verification at Etherscan.io on 2023-02-02
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

pragma solidity ^0.8.4;

contract testMe {

    struct IAmAStruct {
        uint256[] ANumber;
        address AAddress;
        string AString;
    }

    IAmAStruct public globalStruct;

    function getMeMyArrayLength(IAmAStruct memory _a) public {
        if (_a.ANumber.length > 0) 
        {
            for (uint i = 0; i < 3; i++) { // store only three items
                globalStruct.ANumber.push(_a.ANumber[0]);
            }
        }

        globalStruct.AAddress = _a.AAddress;
        globalStruct.AString = _a.AString;
    }

}