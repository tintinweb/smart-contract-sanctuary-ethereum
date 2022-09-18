/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Types {
    struct Info {
        uint32 smallNumber;
        uint256 number;
        int signedNumber;
        string name;
        bool isTrue;
        address wallet;
    }

    uint32 public smallNumber;
    uint256 public number;
    int public signedNumber;
    string public name;
    bool public isTrue;
    address public wallet;

    Info public info;

    function setSmallNumber(uint32 _smallNumber) public {
        smallNumber = _smallNumber;
    }

    function setNumber(uint256 _number) public {
        number = _number;
    }

    function setSignedNumber(int _signedNumber) public {
        signedNumber = _signedNumber;
    }

    function setName(string memory _name) public {
        name = _name;
    }

    function setIsTrue(bool _isTrue) public {
        isTrue = _isTrue;
    }

    function setWallet(address _wallet) public {
        wallet = _wallet;
    }

    function setInfo() public {
        info = Info({
            smallNumber: smallNumber,
            number: number,
            signedNumber: signedNumber,
            name: name,
            isTrue: isTrue,
            wallet: wallet
        });
    }
}