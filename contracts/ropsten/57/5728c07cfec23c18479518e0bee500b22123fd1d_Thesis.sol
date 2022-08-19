/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Thesis {
    address public owner;

    struct OwnderInformation {
        string NID;   
        string name; 
    }

    // Khatian Information Struct
    struct KhatianInformation {
        uint256 khatianNumber; 
        uint256 plotNumber; 
        uint256 maxOwnerCount; 
        OwnderInformation[] owners;
    }

    /// The sequence number of khatian
    uint public khatianseq;

    constructor(address _owner){
        owner = _owner; 
    }
    
    mapping(uint => KhatianInformation) public khatianInformations;

    function insertKhatianInformation(uint _khatianNumber, uint _plotNumber, string[] memory NID, string[] memory name) public {
        require(msg.sender == owner, "only the owner can do this");
        KhatianInformation storage _khatianInformation     = khatianInformations[khatianseq];

        for (uint i = 0; i < NID.length; i++) {
            _khatianInformation.owners.push(OwnderInformation({
                NID: NID[i],
                name: name[i]
            }));
        }
        _khatianInformation.khatianNumber = _khatianNumber;
        _khatianInformation.plotNumber = _plotNumber;
        _khatianInformation.maxOwnerCount = NID.length;
        khatianseq++;

    }

    function getKhatian(uint _khatianseq) public view returns 
    (
    uint khatianNumber,
    uint plotNumber,
    uint totalOwner,
    OwnderInformation[] memory
    ){
    KhatianInformation memory _khatianInformation     = khatianInformations[_khatianseq - 1];
    return (_khatianInformation.khatianNumber, _khatianInformation.plotNumber,_khatianInformation.maxOwnerCount, _khatianInformation.owners);
   }


}