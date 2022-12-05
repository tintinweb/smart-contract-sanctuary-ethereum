// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./verifier.sol";

contract ZKPass {
    Verifier verifier = new Verifier();

    event SetPassword(address indexed user, uint indexed pwdhash);

    event Verified(address indexed user, uint indexed nonce);

    mapping(address => uint) public pwdhashOf;

    mapping(address => uint) public nonceOf;

    constructor() {
    }

    function resetPassword(
        uint[8] memory proof1,
        uint expiration1,
        uint allhash1,
        uint[8] memory proof2,
        uint pwdhash2,
        uint expiration2,
        uint allhash2
    ) public {
        require(pwdhash2 != pwdhashOf[msg.sender], "ZKPass::resetPassword: pwdhash the same");

        uint nonce = nonceOf[msg.sender];

        if (nonce == 0) {
            //init password

            pwdhashOf[msg.sender] = pwdhash2;
            nonceOf[msg.sender] = 1;
            verify(msg.sender, proof2, 0, expiration2, allhash2);
        } else {
            //reset password

            // check old pwdhash
            verify(msg.sender, proof1, 0, expiration1, allhash1);

            // check new pwdhash
            pwdhashOf[msg.sender] = pwdhash2;
            verify(msg.sender, proof2, 0, expiration2, allhash2);
        }

        emit SetPassword(msg.sender, pwdhash2);
    }

    function verify(
        address user,
        uint[8] memory proof,
        uint datahash,
        uint expiration,
        uint allhash
    ) public {
        require(
            block.timestamp < expiration,
            "ZKPass::verify: expired"
        );

        uint pwdhash = pwdhashOf[user];
        require(
            pwdhash != 0,
            "ZKPass::verify: user not exist"
        );

        uint nonce = nonceOf[user];
        uint fullhash = uint(keccak256(abi.encodePacked(expiration, block.chainid, nonce, datahash))) / 8; // 256b->254b
        require(
            verifyProof(proof, pwdhash, fullhash, allhash),
            "ZKPass::verify: verify proof fail"
        );

        nonceOf[user] = nonce + 1;

        emit Verified(user, nonce);
    }

    /////////// util ////////////

    function verifyProof(
        uint[8] memory proof,
        uint pwdhash,
        uint fullhash, //254b
        uint allhash
    ) internal view returns (bool) {
        return
            verifier.verifyProof(
                [proof[0], proof[1]],
                [[proof[2], proof[3]], [proof[4], proof[5]]],
                [proof[6], proof[7]],
                [pwdhash, fullhash, allhash]
            );
    }
}