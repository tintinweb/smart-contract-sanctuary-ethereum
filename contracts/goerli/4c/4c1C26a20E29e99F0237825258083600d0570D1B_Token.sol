//SPDX-License-Identifier: UNLICENSED
//import "hardhat/console.sol";
import {MerkleProof} from "./MerkleProof.sol";

pragma solidity ^0.8.9;

contract Token {
    bytes32 merkleRoot = "";
    uint private counter = 1;
    address public ownerAddress;
    mapping(address => bool) public myMap;

    event WhiteListUpdated(bytes32 merkleRoot);
    event MintCalled(address receiver, uint amount);

    constructor() {
        ownerAddress = msg.sender;
    }

    function updateWitheList(bytes32 hashRoot) public {
        require(
            ownerAddress == msg.sender,
            "Only admin address can execute the addWhitelist function"
        );
        //console.log("executing updateWitheList");
        merkleRoot = hashRoot;
        emit WhiteListUpdated(merkleRoot);
    }

    function mint(
        bytes32[] calldata _merkleProof,
        address receiver,
        uint amount
    ) public {
        require(_merkleProof.length != 0, "Invalid Proof");
        //Verify the provided _merkleProof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(
            MerkleProof.verify(_merkleProof, merkleRoot, leaf),
            "Invalid Proof"
        );
        //console.log("executing mint");
        emit MintCalled(receiver, amount);
        //console.log(receiver);
    }
}