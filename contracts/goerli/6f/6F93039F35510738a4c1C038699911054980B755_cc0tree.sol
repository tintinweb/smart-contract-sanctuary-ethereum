/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract cc0tree {

    struct Derivative {
        address ContractOrig;
        uint256 TokenOrig;
        address ContractDeriv;
        uint256 TokenDeriv;
        address Registrant;
        bool isVerified;
    }

    mapping(uint => Derivative) public derivatives;

    uint derivCount;         //total derivatives in main mapping

    struct addressInfo {
        uint isOrig;
        uint isDeriv;
        uint[] origArray;
        uint[] derivArray;
    }

    uint arrayCountDer;      //number of derivative addresses
    uint arrayCountOri;      //number of orig addresses

    mapping (address => addressInfo) public addressInfos;

    mapping (uint => bool) public entryVerified;

    function addDeriv (address CO, uint256 TO, address CD, uint256 TD) public {

            derivCount++;           

            derivatives[derivCount].ContractOrig = CO;                             //take function info into struct, push into array
            derivatives[derivCount].TokenOrig = TO;
            derivatives[derivCount].ContractDeriv = CD;
            derivatives[derivCount].TokenDeriv = TD;
            derivatives[derivCount].Registrant = msg.sender;

            if (CD == msg.sender) {
                derivatives[derivCount].isVerified = true;
            }

            addressInfos[CO].isOrig ++;                     //keep count in unique address struct
            addressInfos[CD].isDeriv ++;
            addressInfos[CO].origArray.push(derivCount);    //mark this derivative entry in struct arrays
            addressInfos[CD].derivArray.push(derivCount);


    }

    function returnDeriv(uint mainArrayIndex) public view returns (address, uint, address, uint, address, bool) {
                return (derivatives[mainArrayIndex].ContractOrig,
                derivatives[mainArrayIndex].TokenOrig,
                derivatives[mainArrayIndex].ContractDeriv,
                derivatives[mainArrayIndex].TokenDeriv,
                derivatives[mainArrayIndex].Registrant,
                derivatives[mainArrayIndex].isVerified);
    }

    function addressCounts(address countAddy) public view returns (uint, uint) {
        return (addressInfos[countAddy].isOrig, addressInfos[countAddy].isDeriv);
    }

    function derivsByAddress(address a) public view returns (uint[] memory) {
        //for loop that reads array and returns as string? see next function
    }

    function origByAddress(address a) public view returns (uint[] memory) {
        //for loop that reads array and returns as string? doesn't work yet

    //    uint[] storage thing;
    //    for (uint i = 0; i < addressInfos[a].isOrig; i++) {
    //        thing.push(1);
    //    }
    //    return thing;
    }

    function verifyDeriv(uint arrayIndex) public {
    //        require(msg.sender == derivatives[arrayIndex].ContractDeriv.owner,"You're not authorized")
    //          scrap chain for the launcher of project? or just owner fine?
    //          owner provides signature
    }

}