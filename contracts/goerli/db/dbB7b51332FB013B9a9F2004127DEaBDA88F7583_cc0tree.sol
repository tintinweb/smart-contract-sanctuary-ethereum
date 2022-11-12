/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract cc0tree {

    address OWNER = 0xCB7504C4cb986E80AB4983b44263381F21273482;     
    address VERIFIER;                                               // external contract to verify
    address FILTER;                                                 // possible filter contract

    bool FILTERisON;

    bool AdminLock;

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

    struct AddressInfo {                                            // keeping track of each Work involved
        mapping (uint => uint[]) tokenArrayByIDsOrig;
        mapping (uint => uint[]) tokenArrayByIDsDeriv;
        uint isOrig;
        uint isDeriv;
        uint[] origArray;           //locations in main mapping of use as Orig/deriv
        uint[] derivArray;
    }

    mapping (uint => Derivative) public derivatives;                 // MAIN MAPPING
    mapping (address => AddressInfo) public addressInfos;
    mapping (uint => bool) public isEntryVerifiedbyOrig;
    mapping (uint => bool) public isEntryVerifiedbyDeriv;

    mapping (string => uint[]) public isExisty;

    uint derivCount;                                                // current total derivatives in main mapping
    uint arrayCountDer;      //number of derivative addresses
    uint arrayCountOri;      //number of orig addresses


    function addDeriv(address ContractOfORIGINAL, uint256 TokenIDofORIGINAL, address ContractOfDERIVATIVE, uint256 TokenIDofDERIVATIVE) public {
        
        //if (FILTERisON = true) {
        //    require (msg.sender == FILTER, "Only FILTER contract can add entries now.");
        //}

        derivCount++;           

        derivatives[derivCount].Orig._Address = ContractOfORIGINAL;     //take function info into struct, push into array
        derivatives[derivCount].Orig._ID = TokenIDofORIGINAL;
        derivatives[derivCount].Deriv._Address = ContractOfDERIVATIVE;
        derivatives[derivCount].Deriv._ID = TokenIDofDERIVATIVE;
        derivatives[derivCount].Registrant = msg.sender;

        addressInfos[ContractOfORIGINAL].isOrig ++;                     //keep count in unique address struct
        addressInfos[ContractOfDERIVATIVE].isDeriv ++;
        addressInfos[ContractOfORIGINAL].origArray.push(derivCount);    //mark this derivative entry in struct arrays
        addressInfos[ContractOfDERIVATIVE].derivArray.push(derivCount);

        addressInfos[ContractOfORIGINAL].tokenArrayByIDsOrig[TokenIDofORIGINAL].push(derivCount);
        addressInfos[ContractOfDERIVATIVE].tokenArrayByIDsDeriv[TokenIDofDERIVATIVE].push(derivCount);
    }

    function getENTRY(uint databaseNUMBER) public view returns (address, uint, address, uint, address, bool, bool) {
        return (derivatives[databaseNUMBER].Orig._Address,
        derivatives[databaseNUMBER].Orig._ID,
        derivatives[databaseNUMBER].Deriv._Address,
        derivatives[databaseNUMBER].Deriv._ID,
        derivatives[databaseNUMBER].Registrant,
        derivatives[databaseNUMBER].isVerifiedbyDeriv,
        derivatives[databaseNUMBER].isVerifiedbyOrig);
    }

    function GetOrigByWork(address a, uint ID) public view returns (uint[] memory) {    //returns mapping entries where used as Original
        return addressInfos[a].tokenArrayByIDsOrig[ID];
    }

    function GetDerivByWork(address a, uint ID) public view returns (uint[] memory) { // returns mapping entries where used as Deriv
        return addressInfos[a].tokenArrayByIDsDeriv[ID];
    }



/////////////  MAIN USE CASES - could run recursively

    function GetDerivativesOf(address a, uint ID) public view returns (Work[] memory forRETURN) {  // returns Work structs where it's been the orig
        uint[] memory entries = GetOrigByWork(a, ID);
        uint i;
        while (i < entries.length) {
            forRETURN[i] = (derivatives[entries[i]].Deriv);
            i++;
        }
        return forRETURN;         
    }

    function GetOriginalsOf(address a, uint ID) public view returns (Work[] memory forRETURN) {  // returns Work structs where it's been the deriv
        uint[] memory entries = GetDerivByWork(a, ID);
        uint i;
        while (i < entries.length) {
            forRETURN[i] = (derivatives[entries[i]].Orig);
            i++;
        }         
        return forRETURN;
    }

///////////////////////////////

    function GetRoot(address a, uint ID) public view returns (Work memory) {     //returns first original work
        return GetOriginalsOf(a, ID)[0];
    }

    //function GetNewestBranch(address a, uint ID) public view returns (Works memory) {      //returns end(s?) of branch(es?) or maybe fullest branch?

    //}

    function GetAddressUseCounts(address a) public view returns (uint, uint) {        //number of entries found as derivatives & original
        return (addressInfos[a].isOrig, addressInfos[a].isDeriv);
    }

    function GetDerivByAddress(address a) public view returns (uint[] memory) {           //anytime contract used as Deriv
        return addressInfos[a].derivArray;
    }

    function GetOrigByAddress(address a) public view returns (uint[] memory) {              //anytime contract used as Orig
        return addressInfos[a].origArray;
    }

    function verifyModular(uint arrayIndex, bool original) public {                     //composibility for verification
        require(msg.sender == VERIFIER, "Only VERIFIER contract can verify");
            if (original = true) {
                require(derivatives[arrayIndex].isVerifiedbyDeriv == false,"This entry has already been verified by the Derivative.");
                derivatives[arrayIndex].isVerifiedbyDeriv = true;
                isEntryVerifiedbyDeriv[arrayIndex] = true;          //for mapping of verifications by Deriv
                //update mapping of Verify quadrants
            } 
            if (original = false) {
                require(derivatives[arrayIndex].isVerifiedbyOrig == false,"This entry has already been verified by the Original.");
                derivatives[arrayIndex].isVerifiedbyOrig = true;
                isEntryVerifiedbyOrig[arrayIndex] = true;          //for mapping of verifications by Orig
                //update mapping of Verify quandrants
            }
    }

    //admin

    function setOWNER (address newOWNER) public {
        require(AdminLock == false, "Admin has been locked for immutability.");
        require(msg.sender == OWNER);
        OWNER = newOWNER;
    }

    function onFILTER () public {
        require(AdminLock == false, "Admin has been locked for immutability.");
        require(msg.sender == OWNER);
        FILTERisON = true;
    }

    function offFILTER () public {
        require(AdminLock == false, "Admin has been locked for immutability.");
        require(msg.sender == OWNER);
        FILTERisON = false;
    }

    function setVERIFIER (address newVERIFIER) public  {
        require(AdminLock == false, "Admin has been locked for immutability.");
        require(msg.sender == OWNER);
        VERIFIER = newVERIFIER;
    }

    function LOCK_ADMIN () public {
        require(msg.sender == OWNER, "Only owner can lock admin functions.");
        AdminLock = true;
    }


}