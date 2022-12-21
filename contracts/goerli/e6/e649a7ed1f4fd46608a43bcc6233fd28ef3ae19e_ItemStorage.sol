/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract ItemStorage {

//SLA structs an mapps/arrays
    struct SLA{
        string name;
        SLARange[] SLARanges;
    }

    string[] SLANames;

//Ranges structs an mapps/arrays
    struct SLARange{
        uint max;
        uint min;
        uint percentage; 
    }

    mapping(string => SLARange[]) SLAMap; 

//Record structs an mapps/arrays
    struct Record {
        bool isDowntime;
        uint time;
    }
    struct RecordCreator {
        uint _circuitIdentifier;
        bool isDowntime;
        uint time;
    }
    mapping(uint => Record[]) recordMap; // Accedemos con identificador de circuito

    uint[] monthDateArray; //length = 4

//Circuit structs an mapps/arrays

    struct asociatedSLA{
        string SLAName;
        uint startDate;
        uint endDate;
    }


    mapping(uint => asociatedSLA[]) circuitSLAMap; //storage all the asociated SLA to circuits (historic)
    uint[] circuitsArray;



//SLA functions
    function createSLA(string memory _name, SLARange[] memory _SLARanges) public {
        for(uint i = 0; i < _SLARanges.length; i++){
            SLAMap[_name].push(_SLARanges[i]);
        }
        SLANames.push(_name);
    }

    function getSLA() public view returns (SLA[] memory){
        SLA[] memory returnedSLAs = new SLA[](SLANames.length);
        
        for(uint i = 0; i < SLANames.length; i++){
            returnedSLAs[i] = (SLA({name:SLANames[i], SLARanges:SLAMap[SLANames[i]] }));
        }
        return returnedSLAs;
    }

//Ranges functions
    function addRangesToSLA(string memory _name, SLARange[] memory _rangesArray) public returns (string memory){
        require (SLAMap[_name].length > 0);        //VALIDAMOS QUE EL RANGO NO ESTE YA CARGADO? O LO HACEMOS EN EL SERVER?
        for(uint i = 0; i < _rangesArray.length; i++){
            SLAMap[_name].push(_rangesArray[i]);
        }   
        return "Ranges added";
    }
    function removeRangeFromSLA(string memory _name, SLARange memory _range) public returns (string memory){
        if(SLAMap[_name].length > 0){
            for(uint i = 0; i < SLAMap[_name].length; i++){
                if(SLAMap[_name][i].max == _range.max && SLAMap[_name][i].min == _range.min && SLAMap[_name][i].percentage == _range.percentage){
                    SLAMap[_name][i] = SLAMap[_name][SLAMap[_name].length - 1];
                    SLAMap[_name].pop();
                }
            }   
            return "Range not found";
        }
        return "SLA not found";
    }
//Circuit functions

    function getSLAOfCircuit(uint _circuitIdentifier) public view returns (asociatedSLA memory, asociatedSLA[] memory) {
        require (circuitSLAMap[_circuitIdentifier].length > 0);  //Check if key exists


        asociatedSLA memory actualAsociatedSLA;
        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp){
                if(circuitSLAMap[_circuitIdentifier][i].startDate < block.timestamp){
                    actualAsociatedSLA = circuitSLAMap[_circuitIdentifier][i];
                }
                else{
                    length++;
                }
            }
        }

        asociatedSLA[] memory futureAsociatedSLAArray = new asociatedSLA[](length);

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp &&
                circuitSLAMap[_circuitIdentifier][i].startDate > block.timestamp){
                    futureAsociatedSLAArray[position] = circuitSLAMap[_circuitIdentifier][i]; 
                    position++;
            }
        }

        return (actualAsociatedSLA, futureAsociatedSLAArray);

    }

    function addSLAToCircuit(string memory _name, uint _circuitIdentifier, uint _startDate, uint _endDate) public {
        require (SLAMap[_name].length > 0);  //Check if key exists
        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            require(! (circuitSLAMap[_circuitIdentifier][i].endDate > _startDate && 
                    circuitSLAMap[_circuitIdentifier][i].startDate < _endDate));  //check if overlap with other asociatedSLA
        }
        
        asociatedSLA memory newAsociation = asociatedSLA({SLAName:_name, startDate:_startDate, endDate:_endDate});
        circuitSLAMap[_circuitIdentifier].push(newAsociation);
    }

//Records functions
    function getRecords(uint _circuitIdentifier, uint _startDate, uint _endDate) public view returns (Record[] memory) {
        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < recordMap[_circuitIdentifier].length; i++){
            if(recordMap[_circuitIdentifier][i].time >= _startDate && recordMap[_circuitIdentifier][i].time <= _endDate){
                length++;
            }
        }

        Record[] memory returnedRecords = new Record[](length);

        for(uint i = 0; i < recordMap[_circuitIdentifier].length; i++){
            if(recordMap[_circuitIdentifier][i].time >= _startDate && recordMap[_circuitIdentifier][i].time <= _endDate){
                returnedRecords[position]=recordMap[_circuitIdentifier][i];
                position ++;
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

    // function calculatePorcentage() public {

    //     this.getRecords(1, monthDateArray[3] + 1, monthDateArray[4]);
        
        
        
    // }



}