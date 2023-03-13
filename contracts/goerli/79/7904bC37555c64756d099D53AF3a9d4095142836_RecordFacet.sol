// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "../circuit/CircuitLib.sol";
import "../SLA/SLALib.sol";
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

    function createRecord(
        string[] memory _circuitIds, bool[] memory _isDowntime, 
        uint[] memory _time) public returns (string memory) {

        require(_circuitIds.length == _isDowntime.length && _circuitIds.length == _time.length);

        for(uint recordNumber = 0; recordNumber < _circuitIds.length; recordNumber++){
            bool found = false;
            for (uint i = 0; i < CircuitLib.getCircuits().length; i++){
                if (keccak256(abi.encodePacked(CircuitLib.getCircuits()[i])) == keccak256(abi.encodePacked(_circuitIds[recordNumber]))){
                    found=true;
                    break;
                }
            } 
            require(found, "Circuit does not exist"); //Check if circuit exists
        }

        for(uint recordNumber = 0; recordNumber < _circuitIds.length; recordNumber++){

            string memory circuitId = _circuitIds[recordNumber];
            CircuitLib.SendedEmail[] storage lastEmailSendedMap = CircuitLib.getLastSendedEmails(circuitId);
            uint endDate;
            for (uint sendedMonthPosition = 0; lastEmailSendedMap.length > sendedMonthPosition; sendedMonthPosition++){
                
                CircuitLib.SendedEmail memory monthToCheck = lastEmailSendedMap[sendedMonthPosition];
                
                uint16 actual_year = IDatetime(datetimeAddress).getYear(lastEmailSendedMap[sendedMonthPosition].date);
                uint8 actual_month = IDatetime(datetimeAddress).getMonth(lastEmailSendedMap[sendedMonthPosition].date);
                uint8 days_in_month = IDatetime(datetimeAddress).getDaysInMonth(actual_month, actual_year);
                uint seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended
                endDate = lastEmailSendedMap[sendedMonthPosition].date + seconds_to_add;

                if (monthToCheck.date < _time[recordNumber] && endDate > _time[recordNumber]){
                    lastEmailSendedMap[sendedMonthPosition].hasChanged = true;
                }
            }

            RecordLib.Record memory newRecord = RecordLib.Record({isDowntime:_isDowntime[recordNumber], time:_time[recordNumber]});
            RecordLib.addRecord(circuitId, newRecord);
        }

        return "Records added";
    }

    // Not tested
    function getReturnedPorcentages() public view returns (CircuitLib.returnedPorcentages[] memory){
        CircuitLib.returnedPorcentages[] memory returnedPorcentagesArray =  CircuitLib.getReturnedPorcentages();
        CircuitLib.returnedPorcentages[] memory procentagesToReturn = new CircuitLib.returnedPorcentages[](returnedPorcentagesArray.length);
        
        for (uint i = 0 ; returnedPorcentagesArray.length > i; i++){

            CircuitLib.returnedPorcentages memory porcentageToReturn = CircuitLib.returnedPorcentages({circuitId:returnedPorcentagesArray[i].circuitId, date:returnedPorcentagesArray[i].date, upTimePorcentage:returnedPorcentagesArray[i].upTimePorcentage, porcentage:returnedPorcentagesArray[i].porcentage});
            procentagesToReturn[i] = porcentageToReturn;
        }
        return(procentagesToReturn);
    }

    // Not tested
    function calculateDownTime(string memory _circuitId, uint _startDate, uint _endDate) public view returns (uint upTimePorcentage, uint percentage){
        RecordLib.Record[] memory recordsArray = this.getRecords(_circuitId, _startDate, _endDate);
        RecordLib.RecordStorageData storage storageRecords = RecordLib.getStorage();
        uint downtime = 0;
        if(recordsArray.length == 0){   
            if (storageRecords.recordMap[_circuitId].length > 0 && storageRecords.recordMap[_circuitId][storageRecords.recordMap[_circuitId].length - 1].isDowntime){
                return (0, 100000);
            }
            else{
                return (100000, 0);
            }
        }
        
        if( ! recordsArray[0].isDowntime){         //if first record is uptime, we add a downtime at the start of month 
            RecordLib.Record[] memory newRecordsArray = new RecordLib.Record[](recordsArray.length+1); //new list with +1 length for the new downtime
            newRecordsArray[0] = RecordLib.Record({isDowntime:true, time:_startDate});
            for(uint i = 0; recordsArray.length > i; i++){
                newRecordsArray[i+1] = recordsArray[i];
            }
            for(uint i = 0; newRecordsArray.length > i; i++){
                if(newRecordsArray.length-1 == i){
                    downtime += _endDate - newRecordsArray[i].time;
                }
                else{
                    downtime += newRecordsArray[i+1].time - newRecordsArray[i].time;
                    i++;
                }
            }
        }
        else{    
            for(uint i = 0; recordsArray.length > i; i++){
                if(recordsArray.length-1 == i){ 
                    downtime += _endDate - recordsArray[i].time;
                }
                else{  
                    downtime += recordsArray[i+1].time - recordsArray[i].time;
                    i++;
                }
            }
            
        }
        
        upTimePorcentage = 100000 - ((downtime * 1000) * 100) / (_endDate - _startDate);



        CircuitLib.associatedSLA memory actualSLA = CircuitLib.getActualCircuitSLA(_circuitId);

        SLALib.SLARange[] memory returnedSLARanges = SLALib.getSLARanges(actualSLA.SLAName) ;
        for(uint i = 0; returnedSLARanges.length > i; i++){
            if(returnedSLARanges[i].max >= upTimePorcentage && returnedSLARanges[i].min < upTimePorcentage){
                return (upTimePorcentage, returnedSLARanges[i].percentage);
            }
        }
        return (upTimePorcentage, returnedSLARanges[returnedSLARanges.length-1].percentage); //if not found returns the last percentage
    }

    // Not tested
    function DoCalculations() public{    

        CircuitLib.deleteReturnedPorcentages();
        uint256 last_position;
        uint16 last_year;
        uint8 last_month;
        bool newCircuit = false;

        for (uint i = 0; CircuitLib.getCircuits().length > i; i++) {    //for by every circuit
             
            string memory circuitId = CircuitLib.getCircuits()[i];
            uint returnedporcentage;
            uint returnerUpTimePorcentage;
                if (CircuitLib.getLastSendedEmails(circuitId).length > 0){ 
                    last_position = CircuitLib.getLastSendedEmails(circuitId).length-1;
                    last_year = IDatetime(datetimeAddress).getYear(CircuitLib.getLastSendedEmails(circuitId)[last_position].date);
                    last_month = IDatetime(datetimeAddress).getMonth(CircuitLib.getLastSendedEmails(circuitId)[last_position].date);
                }
                else{   
                    newCircuit = true;
                    last_position = 0;
                    // Error is here

                    last_year = IDatetime(datetimeAddress).getYear(block.timestamp);
                    require(false, "After last_year");

                    last_month = IDatetime(datetimeAddress).getMonth(block.timestamp);
                    if(last_month == 1){
                        last_year -= 1;
                        last_month = 11; 
                    }
                    else if(last_month == 2){
                        last_year -= 1;
                        last_month = 12;
                    }
                    else{
                        last_month -= 2;
                    }
                // Error is here

                }

                uint8 days_in_month = IDatetime(datetimeAddress).getDaysInMonth(last_month, last_year);
                uint seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended

                for (uint j = 0; CircuitLib.getLastSendedEmails(circuitId).length > j; j++){       //Resend emails for months with changes
                    if (CircuitLib.getLastSendedEmails(circuitId)[j].hasChanged){
                        // require(false, "adentro");
                        if (CircuitLib.getLastSendedEmails(circuitId).length == j + 1 ){ //if last position calculate endtime of calculations
                            (returnerUpTimePorcentage, returnedporcentage) = this.calculateDownTime(circuitId, CircuitLib.getLastSendedEmails(circuitId)[j].date, CircuitLib.getLastSendedEmails(circuitId)[j].date + seconds_to_add);
                        }
                        else{
                            (returnerUpTimePorcentage, returnedporcentage) = this.calculateDownTime(circuitId, CircuitLib.getLastSendedEmails(circuitId)[j].date, CircuitLib.getLastSendedEmails(circuitId)[j + 1].date -1);
                        }
                        CircuitLib.addReturnedPorcentages(CircuitLib.returnedPorcentages({circuitId:circuitId, date:CircuitLib.getLastSendedEmails(circuitId)[j].date, upTimePorcentage:returnerUpTimePorcentage, porcentage:returnedporcentage}));

                        CircuitLib.getLastSendedEmails(circuitId)[j].hasChanged = false;
                    }
                }

            //que el mes de los calculos sea menor al mes actual
            if(last_month > IDatetime(datetimeAddress).getMonth(block.timestamp)){
                if(CircuitLib.getLastSendedEmails(circuitId).length < 4){  
                    if (newCircuit == true){ 
                        CircuitLib.SendedEmail memory newSendedEmail = CircuitLib.SendedEmail({date:IDatetime(datetimeAddress).toTimestamp(last_year, last_month, 1) + seconds_to_add, hasChanged:false});
                        CircuitLib.getLastSendedEmails(circuitId).push(newSendedEmail);
                    }
                    else{ 
                        CircuitLib.getLastSendedEmails(circuitId).push(CircuitLib.SendedEmail({date:CircuitLib.getLastSendedEmails(circuitId)[last_position].date + seconds_to_add, hasChanged:false}));
                        last_position = CircuitLib.getLastSendedEmails(circuitId).length-1;
                    }
                }
                else{ 
                    for (uint j = 0; CircuitLib.getLastSendedEmails(circuitId).length - 1 > j; j++){ //Move indexs to -1 to enter new month
                        CircuitLib.getLastSendedEmails(circuitId)[j] = CircuitLib.getLastSendedEmails(circuitId)[j + 1];
                    }
                    CircuitLib.getLastSendedEmails(circuitId)[last_position].date = CircuitLib.getLastSendedEmails(circuitId)[last_position].date + seconds_to_add;
                    CircuitLib.getLastSendedEmails(circuitId)[last_position].hasChanged = false;
                }
                
                last_year = IDatetime(datetimeAddress).getYear(CircuitLib.getLastSendedEmails(circuitId)[last_position].date);
                last_month = IDatetime(datetimeAddress).getMonth(CircuitLib.getLastSendedEmails(circuitId)[last_position].date);
                days_in_month = IDatetime(datetimeAddress).getDaysInMonth(last_month, last_year);
                seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended
            }


        


            (returnerUpTimePorcentage, returnedporcentage) = this.calculateDownTime(circuitId, CircuitLib.getLastSendedEmails(circuitId)[last_position].date, CircuitLib.getLastSendedEmails(circuitId)[last_position].date + seconds_to_add);
            CircuitLib.addReturnedPorcentages(CircuitLib.returnedPorcentages({circuitId:circuitId, date:CircuitLib.getLastSendedEmails(circuitId)[last_position].date, upTimePorcentage:returnerUpTimePorcentage, porcentage:returnedporcentage}));


        }
    }

    // Not tested
    function DoExternalCalculations() external view{
        this.DoCalculations;
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

library SLALib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.sla");

    struct SLA{                             //Only used to return data
        string Id;
        SLARange[] SLARanges;
    }

    struct SLARange{
        uint max;
        uint min;
        uint percentage; 
    }

    struct SLAStorageData{
        string[] SLAIds; //storage all the SLAs identifiers
        mapping(string => SLARange[]) SLAMap; //Storage the relation between SLAs and its Ranges (key SLA Identifier)
    }  

    function getStorage() internal pure returns (SLAStorageData storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addSLA(string calldata _SLAId, SLARange[] memory _SLARanges) internal returns(SLA memory createdSLA) {
        SLAStorageData storage s = getStorage();
        s.SLAIds.push(_SLAId);
        for(uint i = 0; i < _SLARanges.length; i++){
            s.SLAMap[_SLAId].push(_SLARanges[i]);
        }
        return createdSLA = (SLA({Id:_SLAId, SLARanges:s.SLAMap[_SLAId]}));
    }

    function getSLAs() internal view returns (SLA[] memory){
        
        SLA[] memory returnedSLAs = new SLA[](getStorage().SLAIds.length);
        
        for(uint i = 0; i < getStorage().SLAIds.length; i++){
            returnedSLAs[i] = (SLA({Id:getStorage().SLAIds[i], SLARanges:getStorage().SLAMap[getStorage().SLAIds[i]] }));
        }
        return returnedSLAs;
        
    }

    function getSLAsIDs() internal view returns (string[] memory returnedIDs){
        
        returnedIDs = new string[](getStorage().SLAIds.length);
        
        for(uint i = 0; i < getStorage().SLAIds.length; i++){
            returnedIDs[i] = getStorage().SLAIds[i];
        }
        return returnedIDs;
        
    }

    function deleteSLA(string calldata _SLAId) internal {
        SLAStorageData storage s = getStorage();
        require(s.SLAMap[_SLAId].length > 0, "SLA does not exist");
        
        for(uint i = 0; s.SLAIds.length > i; i++){       //delete the identifier from the idenfiersArray
            if (keccak256(abi.encodePacked(s.SLAIds[i])) == keccak256(abi.encodePacked(_SLAId))){
                s.SLAIds[i] = s.SLAIds[s.SLAIds.length - 1];
                s.SLAIds.pop();
                break;
            }
        }
        delete s.SLAMap[_SLAId];                         //delete the Ranges from the SLAMap
    }

    function getSLARanges(string memory _SLAId) internal view returns(SLARange[] memory){
        return(getStorage().SLAMap[_SLAId]);
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

    struct returnedPorcentages{         //only use for return the calculated data every month
        string circuitId;
        uint date; //startdate of the month
        uint upTimePorcentage;
        uint porcentage;
    }

    struct CircuitStorageData{
        string[] circuitArray;
        mapping(string => associatedSLA[]) circuitSLAMap; //Storage the relation between Circuit and the asociated SLA (historic) (Key Circuit Identifier)
        mapping(string => SendedEmail[]) lastEmailSendMap;
        returnedPorcentages[] returnedPorcentagesArray;

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

    function getLastSendedEmails(string memory _circuitId) internal view returns (SendedEmail[] storage){
        return (getStorage().lastEmailSendMap[_circuitId]);
    }

    function getReturnedPorcentages() internal view returns (returnedPorcentages[] memory){
        return(getStorage().returnedPorcentagesArray);
    }

    function addReturnedPorcentages(returnedPorcentages memory _returnedPorcentage) internal{
        getStorage().returnedPorcentagesArray.push(_returnedPorcentage);
    }

    function deleteReturnedPorcentages() internal{
        delete getStorage().returnedPorcentagesArray;
    }

    function getActualCircuitSLA(string memory _circuitId) internal view returns(associatedSLA memory) {
        CircuitStorageData storage returnedCircuit = getStorage();
        require (returnedCircuit.circuitSLAMap[_circuitId].length > 0, "This circuit has no SLAs");  //Check if key exists


        associatedSLA memory actualassociatedSLA;
        for(uint i = 0; i < returnedCircuit.circuitSLAMap[_circuitId].length; i++){
            if(returnedCircuit.circuitSLAMap[_circuitId][i].endDate > block.timestamp){
                if(returnedCircuit.circuitSLAMap[_circuitId][i].startDate < block.timestamp){
                    actualassociatedSLA = returnedCircuit.circuitSLAMap[_circuitId][i];
                    break;
                }
            }
        }
        return (actualassociatedSLA);
    }


}