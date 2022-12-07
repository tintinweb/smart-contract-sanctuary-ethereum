/**
 *Submitted for verification at Etherscan.io on 2022-12-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LoveLetter{

    address owner;
    string secretLoveLetter;

    modifier onlyMyLover() {
        require((msg.sender == 0x07740Fc92A5C7b3BE799f35497150CAb6a4eDc71 || msg.sender == owner), "must be lover");
        _;
    }

    constructor(string memory _secretLoveLetter) public {
        secretLoveLetter = _secretLoveLetter;
        owner = msg.sender;
    }

    function readLoveLetter() public view onlyMyLover returns(string memory) {
        return secretLoveLetter;
    }

}