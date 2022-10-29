/**
 *Submitted for verification at Etherscan.io on 2022-10-29
*/

pragma solidity =0.5.16;


contract PermitCheck {

    // one address one code
    mapping(address => bytes16) public codeOf;

    address owner;


    constructor() public {
        owner = msg.sender;
    }

    // can add code by everyone
    // one address one code
    function addCode(bytes16 inputcode) public {
        codeOf[msg.sender] = inputcode;
    }
}