// SPDX-License-Identifier: GPL-3.0

// ["0x4100000000000000000000000000000000000000000000000000000000000000","0x4200000000000000000000000000000000000000000000000000000000000000","0x4300000000000000000000000000000000000000000000000000000000000000","0x4400000000000000000000000000000000000000000000000000000000000000"]
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    struct Claimant {
        uint rights;
        bool claimed;
        uint claim;
        uint wallet;
    }

    struct Miner{
        uint rights;
        uint wallet;
    }

    struct MedicalRecord {
        bytes32 name;
        uint claimCount;
    }   


    address public insurance;
    mapping(address => Claimant) public claimants;
    mapping(address => Miner) public miners;
    MedicalRecord[] public medicalRecords;


    //Array of miners

    constructor(bytes32[] memory medicalRecordType) {
        insurance = msg.sender;
        claimants[insurance].rights = 1;

        for (uint i = 0; i < medicalRecordType.length; i++) {
            medicalRecords.push(MedicalRecord({
                name: medicalRecordType[i],
                claimCount: 0
            }));
        }
    }


    function giveRightToClaim(address claimant) public {
        require(
            msg.sender == insurance,
            "Only insurance can give right to claim."
        );
        require(
            !claimants[claimant].claimed,
            "The claimant already claimed."
        );
        require(claimants[claimant].rights == 0);
        require(
            miners[claimant].rights == 0,
            "Miners cant be claimants"
        );
        claimants[claimant].rights = 1;
    }

    function giveRightToMine(address miner) public {
        require(
            msg.sender == insurance,
            "Only insurance can give right to claim."
        );

        require(miners[miner].rights == 0);
        require(
            claimants[miner].rights == 0,
            "Claimants cant be miners"
        );
        miners[miner].rights = 1;
    }

    function claim(uint medicalRecord) public {
        Claimant storage sender = claimants[msg.sender];
        require(sender.rights != 0, "Has no right to claim");
        require(!sender.claimed, "Already claimed.");
        sender.claimed = true;
        sender.claim = medicalRecord;
        sender.wallet = sender.wallet + 1;
        medicalRecords[medicalRecord].claimCount += sender.rights;
    }


    // function winningMedicalRecord() public view
    //         returns (uint winningMedicalRecord_)
    // {
    //     uint winningVoteCount = 0;
    //     for (uint p = 0; p < medicalRecords.length; p++) {
    //         if (medicalRecords[p].claimCount > winningVoteCount) {
    //             winningVoteCount = medicalRecords[p].claimCount;
    //             winningMedicalRecord_ = p;
    //         }
    //     }
    // }
    
    // function winnerName() public view
    //         returns (bytes32 winnerName_)
    // {
    //     winnerName_ = medicalRecords[winningMedicalRecord()].name;
    // }
}