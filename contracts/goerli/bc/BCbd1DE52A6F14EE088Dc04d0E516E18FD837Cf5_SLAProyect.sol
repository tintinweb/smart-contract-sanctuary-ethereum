/**
 *Submitted for verification at Etherscan.io on 2023-01-20
*/

// File: last_commit/structs.sol


pragma solidity ^0.8.17;

contract Structs {
//SLA and Ranges structs
    struct SLA{                             //Only used to return data
        string Id;
        SLARange[] SLARanges;
    }

    struct SLARange{
        uint max;
        uint min;
        uint percentage; 
    }
//Circuit structs
    struct associatedSLA{    
        string SLAName;
        uint startDate;
        uint endDate;
    }

    struct returnedAssociatedSLA{       //Only used to return data
        string SLAName;
        uint startDate;
        uint endDate;
        SLARange[] SLARanges;
    }
    
    struct returnedPorcentages{         //only use for return the calculated data every month
        string circuitId;
        uint date; //startdate of the month
        uint porcentage;
    }

    struct lastSendedEmail{                     //length = 4 (because only works 90 days in the past)
        uint date; //start of month
        bool hasChanged;
    }

//Record structs an mapps/arrays


    struct Record {
        bool isDowntime;
        uint time;
    }
    struct RecordCreator {                      //Used only for creation
        string circuitId;
        bool isDowntime;
        uint time;
    }







}
// File: last_commit/main.sol


pragma solidity ^0.8.17;



interface IDatetime {
    function getDaysInMonth(uint8 month, uint16 year) external pure returns (uint8);
    function getYear(uint timestamp) external pure returns (uint16);
    function getMonth(uint timestamp) external pure returns (uint8);
    function toTimestamp(uint16 year, uint8 month, uint8 day) external pure returns (uint timestamp);
}

uint constant DAY_IN_SECONDS = 86400;


contract SLAProyect is Structs{
    address datetimeAddress = 0x3A49F202b1074c1f7Ea1433BB7026b362A655036;
    address chainlinkAddress = 0x3A49F202b1074c1f7Ea1433BB7026b362A655036;

//SLA and Ranges structs and mapps/arrays


    string[] SLAIds; //storage all the SLAs identifiers

    mapping(string => SLARange[]) SLAMap; //Storage the relation between SLAs and its Ranges (key SLA Identifier)




//Circuit structs an mapps/arrays



    returnedPorcentages[] returnedPorcentagesArray;

    mapping(string => lastSendedEmail[]) lastEmailSendMap; // Storage the relation between Circuits and the last 4 reports emails sended (Key Circuit Identifier)
    mapping(string => associatedSLA[]) circuitSLAMap; //Storage the relation between Circuit and the asociated SLA (historic) (Key Circuit Identifier)

    string[] circuitsArray; //storage all the Circuits identifiers

//Record structs an mapps/arrays

    mapping(string => Record[]) recordMap; // Storage the relation between Circuits and its Records (Key Circuit Identifier)

//SLA functions
    function createSLA(string memory _name, SLARange[] memory _SLARanges) public returns (SLA memory) {
        for(uint i = 0; i < _SLARanges.length; i++){
            SLAMap[_name].push(_SLARanges[i]);
        }
        SLAIds.push(_name);
        SLA memory newSLA = (SLA({Id:_name, SLARanges:SLAMap[_name] }));
        return newSLA;
    }

    function getSLA() public view returns (SLA[] memory){
        SLA[] memory returnedSLAs = new SLA[](SLAIds.length);
        
        for(uint i = 0; i < SLAIds.length; i++){
            returnedSLAs[i] = (SLA({Id:SLAIds[i], SLARanges:SLAMap[SLAIds[i]] }));
        }
        return returnedSLAs;
    }

    function deleteSLA(string memory _SLAId) public {
        require(SLAMap[_SLAId].length > 0, "SLA does not exist");
        
        for(uint i = 0; SLAIds.length > i; i++){       //delete the identifier from the idenfiersArray
            if (keccak256(abi.encodePacked(SLAIds[i])) == keccak256(abi.encodePacked(_SLAId))){
                SLAIds[i] = SLAIds[SLAIds.length - 1];
                SLAIds.pop();
                break;
            }
        }
        delete SLAMap[_SLAId];                         //delete the Ranges from the SLAMap
    }

    function SLAInUse(string memory _slaIdentifier) public view returns (bool) {
        for(uint i=0; circuitsArray.length > i; i++){                   // for each circuit
            for(uint j=0; circuitSLAMap[circuitsArray[i]].length > j; j++){     //for each associatedSLA element in array
                if(keccak256(abi.encodePacked(circuitSLAMap[circuitsArray[i]][j].SLAName)) == keccak256(abi.encodePacked(_slaIdentifier))){
                    return(true);
                }
            }
        }
        return(false);
    }

//Circuit functions
    function createCircuit(string memory _circuitId) public {
        circuitsArray.push(_circuitId);     //Add the identifier to the identifiers array
    }

    function getCircuits() public view returns (string[] memory){
        string[] memory returnedcircuits = new string[](circuitsArray.length);
        
        for(uint i = 0; i < circuitsArray.length; i++){
            returnedcircuits[i] = circuitsArray[i] ;
        }
        return returnedcircuits;
    }

    function getSLAOfCircuit(string memory _circuitId) public view returns (associatedSLA memory, associatedSLA[] memory, associatedSLA[] memory) {
        require (circuitSLAMap[_circuitId].length > 0);  //Check if key exists

        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitId))){
                found=true;
                break;
            }
        } 
        require(found); //Check if circuit exists

        associatedSLA memory actualAssociatedSLA = this.getActualCircuitSLA(_circuitId);
        associatedSLA[] memory pastAssociatedSLAArray = this.getPastCircuitSLAs(_circuitId);
        associatedSLA[] memory futureAssociatedSLAArray = this.getFutureCircuitSLAs(_circuitId);
        return (actualAssociatedSLA, pastAssociatedSLAArray, futureAssociatedSLAArray);
    }

    function addSLAToCircuit(string memory _SLAId, string memory _circuitId, uint _startDate, uint _endDate) public {
        require (SLAMap[_SLAId].length > 0, "SLA does not exist");
        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitId))){
                found=true;
                break;
            }
        } 
        require(found, "Circuit does not exist");

        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){
            require(! (circuitSLAMap[_circuitId][i].endDate >= _startDate && 
                    circuitSLAMap[_circuitId][i].startDate <= _endDate), "SLA already exists in this period (probably is overlapping)"); 
                    //check if overlap with other associatedSLA 
        }
        
        associatedSLA memory newAsociation = associatedSLA({SLAName:_SLAId, startDate:_startDate, endDate:_endDate});
        circuitSLAMap[_circuitId].push(newAsociation);
    }

    function getActualCircuitSLA(string memory _circuitId) public view returns (associatedSLA memory) {
        require (circuitSLAMap[_circuitId].length > 0, "This circuit has no SLAs");  //Check if key exists


        associatedSLA memory actualassociatedSLA;
        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){
            if(circuitSLAMap[_circuitId][i].endDate > block.timestamp){
                if(circuitSLAMap[_circuitId][i].startDate < block.timestamp){
                    actualassociatedSLA = circuitSLAMap[_circuitId][i];
                    break;
                }
            }
        }
        return (actualassociatedSLA);

    }

    function getPastCircuitSLAs(string memory _circuitId) public view returns (associatedSLA[] memory) {
        require (circuitSLAMap[_circuitId].length > 0, "This circuit has no SLAs");  //Check if key exists

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){  //for by the number of circuit SLAs
            if(circuitSLAMap[_circuitId][i].endDate < block.timestamp){ //If the SLA is expired
                    length++;
            }
        }

        associatedSLA[] memory pastAsociatedSLAArray = new associatedSLA[](length);

        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){  //for by the number of circuit SLAs
            if(circuitSLAMap[_circuitId][i].endDate < block.timestamp){ //If the SLA is expired
                    pastAsociatedSLAArray[position] = circuitSLAMap[_circuitId][i]; 
                    position++;
            }
        }

        return (pastAsociatedSLAArray);

    }
    
    function getFutureCircuitSLAs(string memory _circuitId) public view returns (associatedSLA[] memory) {
        require (circuitSLAMap[_circuitId].length > 0, "This circuit has no SLAs");  //Check if key exists

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){
            if(circuitSLAMap[_circuitId][i].endDate > block.timestamp){
                if (!(circuitSLAMap[_circuitId][i].startDate < block.timestamp)){      
                    length++;
                }
            }
        }

        associatedSLA[] memory futureAsociatedSLAArray = new associatedSLA[](length);

        for(uint i = 0; i < circuitSLAMap[_circuitId].length; i++){
            if(circuitSLAMap[_circuitId][i].endDate > block.timestamp &&
                circuitSLAMap[_circuitId][i].startDate > block.timestamp){
                    futureAsociatedSLAArray[position] = circuitSLAMap[_circuitId][i]; 
                    position++;
            }
        }

        return (futureAsociatedSLAArray);

    }

//Records functions
    function getRecords(string memory _circuitId, uint _startDate, uint _endDate) public view returns (Record[] memory) {
        
        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitId))){
                found=true;
                break;
            }
        } 
        require(found, "Circuit does not exist"); //Check if circuit exists
        
        
        
        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < recordMap[_circuitId].length; i++){
            if(recordMap[_circuitId][i].time >= _startDate && recordMap[_circuitId][i].time <= _endDate){
                length++;
            }
        }

        Record[] memory returnedRecords = new Record[](length);

        for(uint i = 0; i < recordMap[_circuitId].length; i++){
            if(recordMap[_circuitId][i].time >= _startDate && recordMap[_circuitId][i].time <= _endDate){
                returnedRecords[position]=recordMap[_circuitId][i];
                position ++;
            }
        }
        return returnedRecords;
    }

    function createRecord(RecordCreator[] memory _itemsToAdd) public returns (string memory) {

        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){
            bool found = false;
            for (uint i = 0; i < circuitsArray.length; i++){
                if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_itemsToAdd[recordNumber].circuitId))){
                    found=true;
                    break;
                }
            } 
            require(found, "Circuit does not exist"); //Check if circuit exists
        }
        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){

            string memory circuitId = _itemsToAdd[recordNumber].circuitId;

            for (uint sendedMonthPosition = 0; lastEmailSendMap[circuitId].length > sendedMonthPosition; sendedMonthPosition++){
                
                lastSendedEmail memory startSendedEmail = lastEmailSendMap[circuitId][sendedMonthPosition];
                
                if (lastEmailSendMap[circuitId].length == sendedMonthPosition + 1){    //if all items were iterated break 
                    break;
                }
                
                lastSendedEmail memory finishSendedEmail = lastEmailSendMap[circuitId][sendedMonthPosition + 1];

                if (startSendedEmail.date < _itemsToAdd[recordNumber].time && finishSendedEmail.date -1 > _itemsToAdd[recordNumber].time){
                    lastEmailSendMap[circuitId][sendedMonthPosition].hasChanged = true;
                }
            }

            Record memory newRecord = Record({isDowntime:_itemsToAdd[recordNumber].isDowntime, time:_itemsToAdd[recordNumber].time});
            recordMap[circuitId].push(newRecord);
        }

        return "Records added";
    }

    function getReturnedPorcentages() public view returns (returnedPorcentages[] memory){
        returnedPorcentages[] memory procentagesToReturn = new returnedPorcentages[](returnedPorcentagesArray.length);
        
        for (uint i = 0 ; returnedPorcentagesArray.length > i; i++){

            returnedPorcentages memory porcentageToReturn = returnedPorcentages({circuitId:returnedPorcentagesArray[i].circuitId, date:returnedPorcentagesArray[i].date, porcentage:returnedPorcentagesArray[i].porcentage});
            procentagesToReturn[i] = porcentageToReturn;
        }
        return(procentagesToReturn);
    }

    // function getLastEmailSend(string memory _circuitId) public view returns (lastSendedEmail[] memory){
    //     lastSendedEmail[] memory emailsToSend = new lastSendedEmail[](lastEmailSendMap[_circuitId].length);
        
    //     for (uint i = 0 ; lastEmailSendMap[_circuitId].length > i; i++){

    //         lastSendedEmail memory porcentageToReturn = lastSendedEmail({date:lastEmailSendMap[_circuitId][i].date, hasChanged:lastEmailSendMap[_circuitId][i].hasChanged});
    //         emailsToSend[i] = porcentageToReturn;
    //     }
    //     return(emailsToSend);
    // }

    function calculateDownTime(string memory _circuitId, uint _startDate, uint _endDate) public view returns (uint percentage){ //testeado
        Record[] memory recordsArray = this.getRecords(_circuitId, _startDate, _endDate);
        uint downtime = 0;
        if(recordsArray.length == 0){    //testeado
            return 100; //provisional
        }
        
        if( ! recordsArray[0].isDowntime){    //testeado      //if first record is uptime, we add a downtime at the start of month 
            Record[] memory newRecordsArray = new Record[](recordsArray.length+1); //new list with +1 length for the new downtime
            newRecordsArray[0] = Record({isDowntime:true, time:_startDate});
            for(uint i = 0; recordsArray.length > i; i++){//testeado
                newRecordsArray[i+1] = recordsArray[i];
            }
            for(uint i = 0; newRecordsArray.length > i; i++){//testeado
                if(newRecordsArray.length-1 == i){//testeado
                    downtime += _endDate - newRecordsArray[i].time;
                }
                else{//testeado
                    downtime += newRecordsArray[i+1].time - newRecordsArray[i].time;
                    i++;
                }
            }
        }
        else{     //testeado
            for(uint i = 0; recordsArray.length > i; i++){
                if(recordsArray.length-1 == i){ //testeado
                    downtime += _endDate - recordsArray[i].time;
                }
                else{   //testeado
                    downtime += recordsArray[i+1].time - recordsArray[i].time;
                    i++;
                }
            }
            
        }
        
        uint upTimePorcentage = 100000 - ((downtime * 1000) * 100) / (_endDate - _startDate);



        associatedSLA memory actualSLA = this.getActualCircuitSLA(_circuitId);
        for(uint i = 0; SLAMap[actualSLA.SLAName].length > i; i++){    //testeado
            if(SLAMap[actualSLA.SLAName][i].max >= upTimePorcentage && SLAMap[actualSLA.SLAName][i].min < upTimePorcentage){
                return SLAMap[actualSLA.SLAName][i].percentage;
            }
        }
        return SLAMap[actualSLA.SLAName][SLAMap[actualSLA.SLAName].length-1].percentage; //if not found returns the last percentage
    }





    function DoExternalCalculations() external view{    //testeado
        this.DoCalculations;
    }

    function DoCalculations() public{    //testeado

        delete returnedPorcentagesArray;
        uint256 last_position;
        uint16 last_year;
        uint8 last_month;
        bool newCircuit = false;
        uint monthStart;
        for (uint i = 0; circuitsArray.length > i; i++) {//testeado    //for by every circuit
            
            string memory circuitId = circuitsArray[i];
            uint returnedporcentage;
            if (lastEmailSendMap[circuitId].length > 0){ //testeado
                last_position = lastEmailSendMap[circuitId].length-1;
                last_year = IDatetime(datetimeAddress).getYear(lastEmailSendMap[circuitId][last_position].date);
                last_month = IDatetime(datetimeAddress).getMonth(lastEmailSendMap[circuitId][last_position].date);
            }
            else{   //testeado
                newCircuit = true;
                last_position = 0;
                last_year = IDatetime(datetimeAddress).getYear(block.timestamp);
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
                monthStart = IDatetime(datetimeAddress).toTimestamp(last_year, last_month, 1);
            }

            



            uint8 days_in_month = IDatetime(datetimeAddress).getDaysInMonth(last_month, last_year);
            uint seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended

            for (uint j = 0; lastEmailSendMap[circuitId].length > j; j++){//testeado       //Resend emails for months with changes
                if (lastEmailSendMap[circuitId][j].hasChanged){
                    if (lastEmailSendMap[circuitId].length == j -1){ //if last position calculate endtime of calculations
                        returnedporcentage = this.calculateDownTime(circuitId, lastEmailSendMap[circuitId][j].date, lastEmailSendMap[circuitId][j].date + seconds_to_add);
                    }
                    else{//testeado
                        returnedporcentage =this.calculateDownTime(circuitId, lastEmailSendMap[circuitId][j].date, lastEmailSendMap[circuitId][j + 1].date -1);
                    }

                    returnedPorcentagesArray.push(returnedPorcentages({circuitId:circuitId, date:lastEmailSendMap[circuitId][j].date,porcentage:returnedporcentage}));

                    lastEmailSendMap[circuitId][j].hasChanged = false;
                }
            }

            //que el mes de los calculos sea menor al mes actual



            if(last_month > IDatetime(datetimeAddress).getMonth(block.timestamp)){
                if(lastEmailSendMap[circuitId].length < 4){  //testeado
                    if (newCircuit == true){ //testeado
                        lastSendedEmail memory newLastSendedEmail = lastSendedEmail({date:monthStart + seconds_to_add, hasChanged:false});
                        lastEmailSendMap[circuitId].push(newLastSendedEmail);
                    }
                    else{ //testeado
                        lastEmailSendMap[circuitId].push(lastSendedEmail({date:lastEmailSendMap[circuitId][last_position].date + seconds_to_add, hasChanged:false}));
                        last_position = lastEmailSendMap[circuitId].length-1;
                    }
                }
                else{ //testeado
                    for (uint j = 0; lastEmailSendMap[circuitId].length - 1 > j; j++){ //Move indexs to -1 to enter new month
                        lastEmailSendMap[circuitId][j] = lastEmailSendMap[circuitId][j + 1];
                    }
                    lastEmailSendMap[circuitId][last_position].date = lastEmailSendMap[circuitId][last_position].date + seconds_to_add;
                    lastEmailSendMap[circuitId][last_position].hasChanged = false;
                }
                
                last_year = IDatetime(datetimeAddress).getYear(lastEmailSendMap[circuitId][last_position].date);
                last_month = IDatetime(datetimeAddress).getMonth(lastEmailSendMap[circuitId][last_position].date);
                days_in_month = IDatetime(datetimeAddress).getDaysInMonth(last_month, last_year);
                seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended
            }


        


            returnedporcentage = this.calculateDownTime(circuitId, lastEmailSendMap[circuitId][last_position].date, lastEmailSendMap[circuitId][last_position].date + seconds_to_add);
            returnedPorcentagesArray.push(returnedPorcentages({circuitId:circuitId, date:lastEmailSendMap[circuitId][last_position].date, porcentage:returnedporcentage}));


        }
    }

}