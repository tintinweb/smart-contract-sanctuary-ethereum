/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

pragma solidity ^0.8.4;



contract testMe {

    uint256 public RunCount = 0;

    struct IAmAStruct {
        uint256 ANumber;
        address AAddress;
        string AString;
    }

    function add(IAmAStruct memory _a)  public {

        require(_a.ANumber == 1);
        require(_a.AAddress == address(this));
        require(keccak256(abi.encodePacked(_a.AString)) == keccak256(abi.encodePacked("I am a string!")));

        RunCount = RunCount + 1;
    }
}