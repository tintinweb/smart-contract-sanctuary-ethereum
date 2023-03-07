// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;


interface Isolution6 {
    function solution(address owner, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) external pure 
    returns (bool isSignedByOwner);
}

contract Assessment_4 {

    mapping(address => bool) public Admin;

    constructor() {
        Admin[msg.sender] = true;
        Admin[0x0e11fe90bC6AA82fc316Cb58683266Ff0d005e12] = true;
    }

    modifier onlyAdmin(){
        require(Admin[msg.sender] == true, "Need to be Admin");
        _;
    }

    struct signedHash {
        address owner;
        bytes32 messageHash;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    signedHash[] private data;


    function addData(address owner, bytes32 messageHash, uint8 v, bytes32 r,bytes32 s) public onlyAdmin {
        signedHash memory values = signedHash(owner, messageHash, v, r, s);
        data.push(values);
    }

    function rand(uint256 n) internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender))) % n;
    }

    function checkSinger(address owner, bytes32 messageHash, uint8 v, bytes32 r, bytes32 s) internal pure 
    returns (bool isSignedByOwner) {
            bytes32 h = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
            return (ecrecover(h, v, r, s) == owner);
    }


    function completeLevel(address studentAddress) public returns(uint8, uint256) {
        signedHash memory message = data[rand(data.length - 1)]; 
        bool answer = checkSinger(message.owner, message.messageHash, message.v, message.r, message.s);
        uint256 preGas = gasleft();
        bool solution = Isolution6(studentAddress)
            .solution(message.owner, message.messageHash, message.v, message.r, message.s);
        uint256 gas = preGas - gasleft();
        
       if (solution == answer) {
            return (7, gas);
        } else {
            return (1, gas);
        }
    }
}