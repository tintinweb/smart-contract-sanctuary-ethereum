// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "../circuit/CircuitLib.sol";
// import "./SLALib.sol";
import "./RecordLib.sol";

interface IDatetime {
    function getDaysInMonth(uint8 month, uint16 year) external pure returns (uint8);
    function getYear(uint timestamp) external pure returns (uint16);
    function getMonth(uint timestamp) external pure returns (uint8);
    function toTimestamp(uint16 year, uint8 month, uint8 day) external pure returns (uint timestamp);
}
uint constant DAY_IN_SECONDS = 86400;


contract RecordFacet {
    address datetimeAddress = 0x3A49F202b1074c1f7Ea1433BB7026b362A655036;

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

    // Not tested
    function createRecord(RecordLib.RecordCreator[] memory _itemsToAdd) public returns (string memory) {

        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){
            bool found = false;
            for (uint i = 0; i < CircuitLib.getCircuits().length; i++){
                if (keccak256(abi.encodePacked(CircuitLib.getCircuits()[i])) == keccak256(abi.encodePacked(_itemsToAdd[recordNumber].circuitId))){
                    found=true;
                    break;
                }
            } 
            require(found, "Circuit does not exist"); //Check if circuit exists
        }
        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){

            string memory circuitId = _itemsToAdd[recordNumber].circuitId;
            CircuitLib.SendedEmail[] memory lastEmailSendedMap = CircuitLib.getLastSendedEmails(circuitId);
            uint endDate;
            for (uint sendedMonthPosition = 0; lastEmailSendedMap.length > sendedMonthPosition; sendedMonthPosition++){
                
                CircuitLib.SendedEmail memory monthToCheck = lastEmailSendedMap[sendedMonthPosition];
                
                uint16 actual_year = IDatetime(datetimeAddress).getYear(lastEmailSendedMap[sendedMonthPosition].date);
                uint8 actual_month = IDatetime(datetimeAddress).getMonth(lastEmailSendedMap[sendedMonthPosition].date);
                uint8 days_in_month = IDatetime(datetimeAddress).getDaysInMonth(actual_month, actual_year);
                uint seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended
                endDate = lastEmailSendedMap[sendedMonthPosition].date + seconds_to_add;

                if (monthToCheck.date < _itemsToAdd[recordNumber].time && endDate > _itemsToAdd[recordNumber].time){
                    lastEmailSendedMap[sendedMonthPosition].hasChanged = true;
                }
            }

            RecordLib.Record memory newRecord = RecordLib.Record({isDowntime:_itemsToAdd[recordNumber].isDowntime, time:_itemsToAdd[recordNumber].time});
            RecordLib.addRecord(circuitId, newRecord);
        }

        return "Records added";
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

    function addRecord(string memory _circuitId, Record memory _record) internal{
        getStorage().recordMap[_circuitId].push(_record);
    }

}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library CircuitLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.circuit");


    struct associatedSLA{    
        string SLAName;
        uint startDate;
        uint endDate;
    }

    struct SendedEmail{                     //length = 4 (because only works 90 days in the past)
        uint date; //start of month
        bool hasChanged;
    }

    struct CircuitStorageData{
        string[] circuitArray;
        mapping(string => associatedSLA[]) circuitSLAMap; //Storage the relation between Circuit and the asociated SLA (historic) (Key Circuit Identifier)
        mapping(string => SendedEmail[]) lastEmailSendMap;
    }  

    function getStorage() internal pure returns (CircuitStorageData storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addCircuit(string calldata _circuitId) internal{
        CircuitStorageData storage s = getStorage();
        s.circuitArray.push(_circuitId);
    }

    function getCircuits() internal view returns (string[] memory){
        return (getStorage().circuitArray);
    }

    function getLastSendedEmails(string memory _circuitId) internal view returns (SendedEmail[] memory){
        return (getStorage().lastEmailSendMap[_circuitId]);
    }



}