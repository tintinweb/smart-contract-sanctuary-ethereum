/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18 .0;

contract Vote {
    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public VOTE_FUNC_TYPEHASH;
    address public owner;
    event Voted(address indexed voter, bytes32 indexed hash, string vote);

    constructor() {
        owner = 0x96cd1cdb9069D64F55270204B3d203162222147D;
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
                ),
                keccak256(bytes("SecretVote")),
                keccak256(bytes("1")),
                5,
                address(this),
                0xbd58d893d5c124e362bf114ac1e391ef1f38f4316b25a68cb2de6cbe77b94fb3
            )
        );
        VOTE_FUNC_TYPEHASH = keccak256(
            "Vote(address voter,string value,string zkp)"
        );
    }

    function vote(bytes32 _pkhash, string memory _vote) external {
        require(msg.sender == owner, "Not permitted");
        emit Voted(msg.sender, _pkhash, _vote);
    }

    function verify(
        address voter,
        string memory value,
        string memory zkp,
        bytes memory signature
    ) external view returns (bool) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOTE_FUNC_TYPEHASH,
                        voter,
                        keccak256(abi.encodePacked(value)),
                        keccak256(abi.encodePacked(zkp))
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        address recoveredAddress = ecrecover(digest, v, r, s);
        return recoveredAddress == voter;
    }
}