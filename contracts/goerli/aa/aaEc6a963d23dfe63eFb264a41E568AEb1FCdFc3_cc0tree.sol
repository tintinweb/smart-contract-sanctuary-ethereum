/**
 *Submitted for verification at Etherscan.io on 2022-10-31
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract cc0tree {

    address OWNER = 0xCB7504C4cb986E80AB4983b44263381F21273482;     
    address VERIFIER;                                               // external contract to verify
    address FILTER;                                                 //possible filter contract

    struct Work {                                                   // base unit
        address _Address;
        uint256 _ID;
    }

    struct Derivative {                                             // unit of MAIN MAPPING
        Work Orig;
        Work Deriv;
        address Registrant;
        bool isVerifiedbyOrig;
        bool isVerifiedbyDeriv;
    }

    struct addressInfo {                                            // keeping track of each address involved
        uint isOrig;
        uint isDeriv;
        uint[] origArray;
        uint[] derivArray;
    }

    mapping(uint => Derivative) public derivatives;                 // MAIN MAPPING

    uint derivCount;                                                // current total derivatives in main mapping

    uint arrayCountDer;      //number of derivative addresses
    uint arrayCountOri;      //number of orig addresses

    mapping (address => addressInfo) public addressInfos;

    mapping (uint => bool) public entryVerified;

    function addDeriv(address ContractOfORIGINAL, uint256 TokenIDofORIGINAL, address ContractOfDERIVATIVE, uint256 TokenIDofDERIVATIVE) public {

            derivCount++;           

            derivatives[derivCount].Orig._Address = ContractOfORIGINAL;                             //take function info into struct, push into array
            derivatives[derivCount].Orig._ID = TokenIDofORIGINAL;
            derivatives[derivCount].Deriv._Address = ContractOfDERIVATIVE;
            derivatives[derivCount].Deriv._ID = TokenIDofDERIVATIVE;
            derivatives[derivCount].Registrant = msg.sender;

            if (ContractOfDERIVATIVE == msg.sender) {
                derivatives[derivCount].isVerifiedbyDeriv = true;
            }
            if (ContractOfORIGINAL == msg.sender) {
                derivatives[derivCount].isVerifiedbyOrig = true;
            }

            addressInfos[ContractOfORIGINAL].isOrig ++;                     //keep count in unique address struct
            addressInfos[ContractOfDERIVATIVE].isDeriv ++;
            addressInfos[ContractOfORIGINAL].origArray.push(derivCount);    //mark this derivative entry in struct arrays
            addressInfos[ContractOfDERIVATIVE].derivArray.push(derivCount);
    }

    function getDeriv(uint databaseNUMBER) public view returns (address, uint, address, uint, address, bool, bool) {
        return (derivatives[databaseNUMBER].Orig._Address,
        derivatives[databaseNUMBER].Orig._ID,
        derivatives[databaseNUMBER].Deriv._Address,
        derivatives[databaseNUMBER].Deriv._ID,
        derivatives[databaseNUMBER].Registrant,
        derivatives[databaseNUMBER].isVerifiedbyDeriv,
        derivatives[databaseNUMBER].isVerifiedbyOrig);
    }

    function setOWNER (address newOWNER) public {
        if (msg.sender == OWNER) {
            VERIFIER = newOWNER;
       }
    }

    function setVERIFIER (address newVERIFIER) public  {
        if (msg.sender == OWNER) {
            OWNER = newVERIFIER;
        }
    }

    function GetAddressUseCounts(address a) public view returns (uint, uint) {        //number of entries found as derivatives & original
        return (addressInfos[a].isOrig, addressInfos[a].isDeriv);
    }

    function GetDerivByAddress(address a) public view returns (uint[] memory) {           //returns arry of specific entries used
        return addressInfos[a].derivArray;
    }

    function GetOrigByAddress(address a) public view returns (uint[] memory) {
        return addressInfos[a].origArray;
    }

    function verifyModular(uint arrayIndex, bool original) public {
        require(msg.sender == VERIFIER, "Only VERIFIER contract can verify");
            if (original = true) {
                require(derivatives[arrayIndex].isVerifiedbyDeriv == false,"This entry has already been verified by the Derivative.");
                derivatives[arrayIndex].isVerifiedbyDeriv = true;
                //update mapping of Verify quadrants
            } 
            if (original = false) {
                require(derivatives[arrayIndex].isVerifiedbyOrig == false,"This entry has already been verified by the Original.");
                derivatives[arrayIndex].isVerifiedbyOrig = true;
                //update mapping of Verify quandrants
            }
        }
    }