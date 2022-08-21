// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 <0.9.0;
pragma experimental ABIEncoderV2;

contract Issue {

    mapping(address => mapping(address => bool)) private Issued;

    

    event emitIssue(address indexed receiver, address issuer_id, uint256[2] h, uint256[2] t1, uint256[2] t2);

    function SendBlindSign(address receiver, uint256[2] memory h, uint256[2] memory t1, uint256[2] memory t2) public {
        Issued[msg.sender][receiver] = true;
        emit emitIssue(receiver, msg.sender, h, t1, t2);
    }

    function isIssued(address validator, address user) public view returns(bool) {
        return Issued[validator][user];
    }
}