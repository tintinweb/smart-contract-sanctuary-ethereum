/**
 *Submitted for verification at Etherscan.io on 2022-09-15
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
    }

    uint arrayCountDer;      //number of derivative addresses
    uint arrayCountOri;      //number of orig addresses

    uint[] public origCounter;  //total number of orinal work
    uint[] public derivCounter;  //total number of derivative works

    mapping (address => addressInfo) public addressInfos;
    //mapping (bool => derivCount) public mappingVerified1;
    //mapping (derivCount => isVerified) public mappingVerified2;
    

    function addDeriv (address CO, uint256 TO, address CD, uint256 TD) public {
            
            derivatives[derivCount].ContractOrig = CO;                             //take function info into struct, push into array
            derivatives[derivCount].TokenOrig = TO;
            derivatives[derivCount].ContractDeriv = CD;
            derivatives[derivCount].TokenDeriv = TD;
            derivatives[derivCount].Registrant = msg.sender;
            derivatives[derivCount].isVerified = false;

            addressInfos[CO].isOrig ++;
            addressInfos[CD].isDeriv ++;

            //uint[] memory a = new uint[](4);
            //origCounter origCounter1;

           // a.push(derivCount);
            //origCounter1.push(derivCount);

            //addressInfos[CO].arrayIndexD;
//            tempInfoD.derivsMade ++;
//            addressInfo memory tempInfoD = addressInfos[CD];        //store derivative address in address mapping
//            tempInfoD.arrayIndexD = 1;
            //uint[] storage howDeriv;                                //make new array
            //howDeriv.push(derivCount);

            //addressInfo memory tempInfoO = addressInfos[CO];       //store orig address in address mapping 
            //tempInfoO.isOrig ++;
            //tempInfoO.arrayIndexO = 1;
            //uint[] storage howOrig;                                 //make new array
            //howOrig.push(derivCount);           
            
            //make mapping for verifiedBool too

            //if address is new, make new address array, set derivsCount to 1
            //if not, up derivesMade number

            derivCount++;
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

    //function verifyDeriv(uint arrayIndex) public {
    //        addressInfo memory tempStructAlt = derivatives[arrayIndex];
    //        require(msg.sender == tempStructAlt.ContractOrig,"You're not authorized")
        //}
// function that edits array?
// some way of only contract owner being able to sign? or maybe make that a separate verification function/validate/verify thing
//      yeah anyone can submit, contract owner must verify. not source contract tho, only derivative needs to

// boolean entirecollection (false if just 1 token is derivative)   
//      separate array for collections?

}