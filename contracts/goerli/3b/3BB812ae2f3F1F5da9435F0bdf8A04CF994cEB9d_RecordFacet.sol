// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

// import "../circuit/CircuitLib.sol";
// import "./SLALib.sol";
import "./RecordLib.sol";


contract RecordFacet {

    // Not tested
    function getRecords(string memory _circuitId, uint _startDate, uint _endDate) public view returns (RecordLib.Record[] memory) {

        uint length = 0;
        uint position = 0;

        RecordLib.RecordStorageData storage storageRecords = RecordLib.getStorage();

        for(uint i = 0; i < storageRecords.recordMap[_circuitId].length; i++){
            if(storageRecords.recordMap[_circuitId][i].time >= _startDate && storageRecords.recordMap[_circuitId][i].time <= _endDate){
                length++;
            }
        }

        RecordLib.Record[] memory returnedRecords = new RecordLib.Record[](length);

        for(uint i = 0; i < storageRecords.recordMap[_circuitId].length; i++){
            if(storageRecords.recordMap[_circuitId][i].time >= _startDate && storageRecords.recordMap[_circuitId][i].time <= _endDate){
                returnedRecords[position]=storageRecords.recordMap[_circuitId][i];
                position ++;
            }
        }
        return returnedRecords;
    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library RecordLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.record");

    struct Record {
        bool isDowntime;
        uint time;
    }

    struct RecordCreator {                      //Used only for creation
        string circuitId;
        bool isDowntime;
        uint time;
    }

    struct RecordStorageData{
        mapping(string => Record[]) recordMap; // Storage the relation between Circuits and its Records (Key Circuit Identifier)
    }

    function getStorage() internal pure returns (RecordStorageData storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

}