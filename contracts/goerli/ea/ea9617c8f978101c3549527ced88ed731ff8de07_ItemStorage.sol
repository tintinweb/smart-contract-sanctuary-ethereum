/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ItemStorage {


    struct SLA{
        string name;
        SLARange[] slaRanges;
    }

    SLA[] SLAArray;

    string[] SLANames;

    struct SLARange{
        uint max;
        uint min;
        uint percentage; 
    }

    SLARange initializerRange;

    mapping(string => SLARange[]) SLAMap; 


    // mapping(uint => SLA) circuitMap; // Accedemos con identificador de circuito hasheado

    struct Record {
        bool isDowntime;
        uint time;
    }

    struct RecordCreator {
        uint _circuitIdentifier;
        bool isDowntime;
        uint time;
    }

    mapping(uint => Record[]) recordMap; // Accedemos con identificador de circuito hasheado

    function createSLA(string memory _name) public {
        // SLARange[] storage newRangesArray;

        // SLA memory newSLA = SLA({name:_name, slaRanges:newRangesArray});
        
        // SLAArray.push(newSLA);
        SLAMap[_name].push(initializerRange);
        SLANames.push(_name);
    }

    function getSLA() public view returns (SLA[] memory){
        SLA[] memory returnedSLAs = new SLA[](SLANames.length);
        
        for(uint i = 0; i < SLANames.length; i++){
            returnedSLAs[i] = (SLA({name:SLANames[i], slaRanges:SLAMap[SLANames[i]] }));
        }
        return returnedSLAs;
    }


    function getRecords(uint _circuitIdentifier, uint _startDate, uint _endDate) public view returns (Record[] memory) {
        uint length = 0;
        for(uint i = 0; i < recordMap[_circuitIdentifier].length; i++){
            if(recordMap[_circuitIdentifier][i].time >= _startDate && recordMap[_circuitIdentifier][i].time <= _endDate){
                length++;
            }
        }

        Record[] memory returnedRecords = new Record[](length);

        for(uint i = 0; i < recordMap[_circuitIdentifier].length; i++){
            if(recordMap[_circuitIdentifier][i].time >= _startDate && recordMap[_circuitIdentifier][i].time <= _endDate){
                returnedRecords[i]=recordMap[_circuitIdentifier][i];
            }
        }
        return returnedRecords;
    }

    function createRecord(RecordCreator[] memory _itemsToAdd) public returns (string memory) {

        for(uint i = 0; i < _itemsToAdd.length; i++){

            Record memory newRecord = Record({isDowntime:_itemsToAdd[i].isDowntime, time:_itemsToAdd[i].time});
            recordMap[_itemsToAdd[i]._circuitIdentifier].push(newRecord);
        }

        return "Records added";
    }
}