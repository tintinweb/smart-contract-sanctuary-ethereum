/**
 *Submitted for verification at Etherscan.io on 2022-04-26
*/

pragma solidity 0.6.0;

contract Hello {
    string fullname;

    constructor(string memory _fullname) public {
        fullname = _fullname;
    }

    function setFullname(string memory name) public view returns (string memory) {
        return string(abi.encodePacked(fullname, name));
    }
}