/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// File: structs.sol


pragma solidity ^0.8.17;

contract Structs {
//SLA and Ranges structs
    struct SLA{                             //Only used to return data
        string Identifier;
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
    
    struct returnedPorcentages{         //only use for return the calculated data every month
        string circuitIdentifier;
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
        string circuitIdentifier;
        bool isDowntime;
        uint time;
    }







}
// File: datetime.sol



pragma solidity ^0.8.17;

contract Datetime{


    struct _DateTime {
        uint16 year;
        uint8 month;
        uint8 day;
        uint8 hour;
        uint8 minute;
        uint8 second;
        uint8 weekday;
    }

    uint constant DAY_IN_SECONDS = 86400;
    uint constant YEAR_IN_SECONDS = 31536000;
    uint constant LEAP_YEAR_IN_SECONDS = 31622400;

    uint constant HOUR_IN_SECONDS = 3600;
    uint constant MINUTE_IN_SECONDS = 60;

    uint16 constant ORIGIN_YEAR = 1970;

    function isLeapYear(uint16 year) public pure returns (bool) {
        if (year % 4 != 0) {
                return false;
        }
        if (year % 100 != 0) {
                return true;
        }
        if (year % 400 != 0) {
                return false;
        }
        return true;
    }

    function leapYearsBefore(uint year) public pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function getDaysInMonth(uint8 month, uint16 year) public pure returns (uint8) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
                return 31;
        }
        else if (month == 4 || month == 6 || month == 9 || month == 11) {
                return 30;
        }
        else if (isLeapYear(year)) {
                return 29;
        }
        else {
                return 28;
        }
    }

    function parseTimestamp(uint timestamp) internal pure returns (_DateTime memory dt) {
        uint secondsAccountedFor = 0;
        uint buf;
        uint8 i;

        // Year
        dt.year = getYear(timestamp);
        buf = leapYearsBefore(dt.year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * buf;
        secondsAccountedFor += YEAR_IN_SECONDS * (dt.year - ORIGIN_YEAR - buf);

        // Month
        uint secondsInMonth;
        for (i = 1; i <= 12; i++) {
                secondsInMonth = DAY_IN_SECONDS * getDaysInMonth(i, dt.year);
                if (secondsInMonth + secondsAccountedFor > timestamp) {
                        dt.month = i;
                        break;
                }
                secondsAccountedFor += secondsInMonth;
        }

        // Day
        for (i = 1; i <= getDaysInMonth(dt.month, dt.year); i++) {
                if (DAY_IN_SECONDS + secondsAccountedFor > timestamp) {
                        dt.day = i;
                        break;
                }
                secondsAccountedFor += DAY_IN_SECONDS;
        }

        // Hour
        dt.hour = getHour(timestamp);

        // Minute
        dt.minute = getMinute(timestamp);

        // Second
        dt.second = getSecond(timestamp);

        // Day of week.
        dt.weekday = getWeekday(timestamp);
    }

    function getYear(uint timestamp) public pure returns (uint16) {
        uint secondsAccountedFor = 0;
        uint16 year;
        uint numLeapYears;

        // Year
        year = uint16(ORIGIN_YEAR + timestamp / YEAR_IN_SECONDS);
        numLeapYears = leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR);

        secondsAccountedFor += LEAP_YEAR_IN_SECONDS * numLeapYears;
        secondsAccountedFor += YEAR_IN_SECONDS * (year - ORIGIN_YEAR - numLeapYears);

        while (secondsAccountedFor > timestamp) {
                if (isLeapYear(uint16(year - 1))) {
                        secondsAccountedFor -= LEAP_YEAR_IN_SECONDS;
                }
                else {
                        secondsAccountedFor -= YEAR_IN_SECONDS;
                }
                year -= 1;
        }
        return year;
    }

    function getMonth(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).month;
    }

    function getDay(uint timestamp) public pure returns (uint8) {
        return parseTimestamp(timestamp).day;
    }

    function getHour(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60 / 60) % 24);
    }

    function getMinute(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / 60) % 60);
    }

    function getSecond(uint timestamp) public pure returns (uint8) {
        return uint8(timestamp % 60);
    }

    function getWeekday(uint timestamp) public pure returns (uint8) {
        return uint8((timestamp / DAY_IN_SECONDS + 4) % 7);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, 0, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, 0, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) public pure returns (uint timestamp) {
        return toTimestamp(year, month, day, hour, minute, 0);
    }

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute, uint8 second) public pure returns (uint timestamp) {
        uint16 i;

        // Year
        for (i = ORIGIN_YEAR; i < year; i++) {
                if (isLeapYear(i)) {
                        timestamp += LEAP_YEAR_IN_SECONDS;
                }
                else {
                        timestamp += YEAR_IN_SECONDS;
                }
        }

        // Month
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
                monthDayCounts[1] = 29;
        }
        else {
                monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
                timestamp += DAY_IN_SECONDS * monthDayCounts[i - 1];
        }

        // Day
        timestamp += DAY_IN_SECONDS * (day - 1);

        // Hour
        timestamp += HOUR_IN_SECONDS * (hour);

        // Minute
        timestamp += MINUTE_IN_SECONDS * (minute);

        // Second
        timestamp += second;

        return timestamp;
    }

}

// File: test.sol


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
//SLA and Ranges structs and mapps/arrays


    string[] SLAIdentifiers; //storage all the SLAs identifiers

    mapping(string => SLARange[]) SLAMap; //Storage the relation between SLAs and its Ranges (key SLA Identifier)




//Circuit structs an mapps/arrays



    returnedPorcentages[] returnedPorcentagesArray;

    mapping(string => lastSendedEmail[]) lastEmailSendMap; // Storage the relation between Circuits and the last 4 reports emails sended (Key Circuit Identifier)
    mapping(string => associatedSLA[]) circuitSLAMap; //Storage the relation between Circuit and the asociated SLA (historic) (Key Circuit Identifier)

    string[] public circuitsArray; //storage all the Circuits identifiers

//Record structs an mapps/arrays



    mapping(string => Record[]) recordMap; // Storage the relation between Circuits and its Records (Key Circuit Identifier)







//SLA functions
    function createSLA(string memory _name, SLARange[] memory _SLARanges) public returns (SLA memory) {
        for(uint i = 0; i < _SLARanges.length; i++){
            SLAMap[_name].push(_SLARanges[i]);
        }
        SLAIdentifiers.push(_name);
        SLA memory newSLA = (SLA({Identifier:_name, SLARanges:SLAMap[_name] }));
        return newSLA;
    }

    function getSLA() public view returns (SLA[] memory){
        SLA[] memory returnedSLAs = new SLA[](SLAIdentifiers.length);
        
        for(uint i = 0; i < SLAIdentifiers.length; i++){
            returnedSLAs[i] = (SLA({Identifier:SLAIdentifiers[i], SLARanges:SLAMap[SLAIdentifiers[i]] }));
        }
        return returnedSLAs;
    }

    function deleteSLA(string memory _SLAIdentifier) public {
        require(SLAMap[_SLAIdentifier].length > 0, "SLA does not exist");
        
        for(uint i = 0; SLAIdentifiers.length > i; i++){       //delete the identifier from the idenfiersArray
            if (keccak256(abi.encodePacked(SLAIdentifiers[i])) == keccak256(abi.encodePacked(_SLAIdentifier))){
                SLAIdentifiers[i] = SLAIdentifiers[SLAIdentifiers.length - 1];
                SLAIdentifiers.pop();
                break;
            }
        }
        delete SLAMap[_SLAIdentifier];                         //delete the Ranges from the SLAMap
    }


//Circuit functions
    function createCircuit(string memory _circuitIdentifier) public {
        for (uint i = 0; i < circuitsArray.length; i++)
            require(keccak256(abi.encodePacked(circuitsArray[i])) != keccak256(abi.encodePacked(_circuitIdentifier)), "Circuit already exists"); //Check if circuit already exists
        circuitsArray.push(_circuitIdentifier);     //Add the identifier to the identifiers array
    }
    
    // function getSLAOfCircuit(string memory _circuitIdentifier) public view returns (associatedSLA memory, associatedSLA[] memory, associatedSLA[] memory) {
    //     require (circuitSLAMap[_circuitIdentifier].length > 0);  //Check if key exists

    //     bool found = false;
    //     for (uint i = 0; i < circuitsArray.length; i++){
    //         if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitIdentifier))){
    //             found=true;
    //             break;
    //         }
    //     } 
    //     require(found); //Check if circuit exists


    //     associatedSLA memory actualAsociatedSLA;
    //     uint future_length = 0;
    //     uint past_length = 0;

    //     uint past_position = 0;
    //     uint future_position = 0;

    //     for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
    //         if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp){
    //             if(circuitSLAMap[_circuitIdentifier][i].startDate < block.timestamp){
    //                 actualAsociatedSLA = circuitSLAMap[_circuitIdentifier][i];
    //             }
    //             else{
    //                 future_length++;
    //             }
    //         }
    //         else{
    //             past_length++;
    //         }
    //     }

    //     associatedSLA[] memory futureAsociatedSLAArray = new associatedSLA[](future_length);
    //     associatedSLA[] memory pastAsociatedSLAArray = new associatedSLA[](past_length);

    //     for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
    //         if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp){

    //             if(circuitSLAMap[_circuitIdentifier][i].startDate > block.timestamp){
    //                 futureAsociatedSLAArray[future_position] = circuitSLAMap[_circuitIdentifier][i]; 
    //                 future_position++;
    //             } 
    //         }
    //         else{
    //             pastAsociatedSLAArray[past_position] = circuitSLAMap[_circuitIdentifier][i]; 
    //             past_position++; 
    //         }
    //     }

    //     return (actualAsociatedSLA, pastAsociatedSLAArray, futureAsociatedSLAArray);

    // }
    function getSLAOfCircuit(string memory _circuitIdentifier) public view returns (associatedSLA memory, associatedSLA[] memory, associatedSLA[] memory) {
        require (circuitSLAMap[_circuitIdentifier].length > 0);  //Check if key exists

        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitIdentifier))){
                found=true;
                break;
            }
        } 
        require(found); //Check if circuit exists

        associatedSLA memory actualAssociatedSLA = this.getActualCircuitSLA(_circuitIdentifier);
        associatedSLA[] memory pastAssociatedSLAArray = this.getPastCircuitSLAs(_circuitIdentifier);
        associatedSLA[] memory futureAssociatedSLAArray = this.getFutureCircuitSLAs(_circuitIdentifier);
        return (actualAssociatedSLA, pastAssociatedSLAArray, futureAssociatedSLAArray);
    }

    function addSLAToCircuit(string memory _SLAIdentifier, string memory _circuitIdentifier, uint _startDate, uint _endDate) public {
        require (SLAMap[_SLAIdentifier].length > 0, "SLA does not exist");
        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitIdentifier))){
                found=true;
                break;
            }
        } 
        require(found, "Circuit does not exist");

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            require(! (circuitSLAMap[_circuitIdentifier][i].endDate >= _startDate && 
                    circuitSLAMap[_circuitIdentifier][i].startDate <= _endDate), "SLA already exists in this period (probably is overlapping)"); 
                    //check if overlap with other associatedSLA 
        }
        
        associatedSLA memory newAsociation = associatedSLA({SLAName:_SLAIdentifier, startDate:_startDate, endDate:_endDate});
        circuitSLAMap[_circuitIdentifier].push(newAsociation);
    }

    function getActualCircuitSLA(string memory _circuitIdentifier) public view returns (associatedSLA memory) {
        require (circuitSLAMap[_circuitIdentifier].length > 0, "Circuit does not exist");  //Check if key exists


        associatedSLA memory actualassociatedSLA;
        bool found = false;
        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp){
                if(circuitSLAMap[_circuitIdentifier][i].startDate < block.timestamp){
                    actualassociatedSLA = circuitSLAMap[_circuitIdentifier][i];
                    found = true;
                    break;
                }
            }
        }
        return (actualassociatedSLA);

    }

    function getPastCircuitSLAs(string memory _circuitIdentifier) public view returns (associatedSLA[] memory) {
        require (circuitSLAMap[_circuitIdentifier].length > 0, "Circuit does not exist");  //Check if key exists

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){  //for by the number of circuit SLAs
            if(circuitSLAMap[_circuitIdentifier][i].endDate < block.timestamp){ //If the SLA is expired
                    length++;
            }
        }

        associatedSLA[] memory pastAsociatedSLAArray = new associatedSLA[](length);

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){  //for by the number of circuit SLAs
            if(circuitSLAMap[_circuitIdentifier][i].endDate < block.timestamp){ //If the SLA is expired
                    pastAsociatedSLAArray[position] = circuitSLAMap[_circuitIdentifier][i]; 
                    position++;
            }
        }

        return (pastAsociatedSLAArray);

    }
    
    function getFutureCircuitSLAs(string memory _circuitIdentifier) public view returns (associatedSLA[] memory) {
        require (circuitSLAMap[_circuitIdentifier].length > 0, "Circuit does not exist");  //Check if key exists

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp){
                if (!(circuitSLAMap[_circuitIdentifier][i].startDate < block.timestamp)){      
                    length++;
                }
            }
        }

        associatedSLA[] memory futureAsociatedSLAArray = new associatedSLA[](length);

        for(uint i = 0; i < circuitSLAMap[_circuitIdentifier].length; i++){
            if(circuitSLAMap[_circuitIdentifier][i].endDate > block.timestamp &&
                circuitSLAMap[_circuitIdentifier][i].startDate > block.timestamp){
                    futureAsociatedSLAArray[position] = circuitSLAMap[_circuitIdentifier][i]; 
                    position++;
            }
        }

        return (futureAsociatedSLAArray);

    }

//Records functions
    function getRecords(string memory _circuitIdentifier, uint _startDate, uint _endDate) public view returns (Record[] memory) {
        
        bool found = false;
        for (uint i = 0; i < circuitsArray.length; i++){
            if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitIdentifier))){
                found=true;
                break;
            }
        } 
        require(found, "Circuit does not exist"); //Check if circuit exists
        
        
        
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

    // function getLastRecord(string memory _circuitIdentifier) public view returns (uint, bool){
    //     require(recordMap[_circuitIdentifier].length > 0, "Circuit does not have records"); //Check if circuit has records

    //     bool found = false;
    //     for (uint i = 0; i < circuitsArray.length; i++){
    //         if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_circuitIdentifier))){
    //             found=true;
    //             break;
    //         }
    //     } 
    //     require(found, "Circuit does not exist"); //Check if circuit exists


    //     return (recordMap[_circuitIdentifier][recordMap[_circuitIdentifier].length-1].time, recordMap[_circuitIdentifier][recordMap[_circuitIdentifier].length-1].isDowntime);
    // }

    function createRecord(RecordCreator[] memory _itemsToAdd) public returns (string memory) {

        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){
            bool found = false;
            for (uint i = 0; i < circuitsArray.length; i++){
                if (keccak256(abi.encodePacked(circuitsArray[i])) == keccak256(abi.encodePacked(_itemsToAdd[recordNumber].circuitIdentifier))){
                    found=true;
                    break;
                }
            } 
            require(found, "Circuit does not exist"); //Check if circuit exists
        }
        for(uint recordNumber = 0; recordNumber < _itemsToAdd.length; recordNumber++){

            string memory circuitIdentifier = _itemsToAdd[recordNumber].circuitIdentifier;

            for (uint sendedMonthPosition = 0; lastEmailSendMap[circuitIdentifier].length > sendedMonthPosition; sendedMonthPosition++){
                
                lastSendedEmail memory startSendedEmail = lastEmailSendMap[circuitIdentifier][sendedMonthPosition];
                
                if (lastEmailSendMap[circuitIdentifier].length == sendedMonthPosition + 1){    //if all items were iterated break 
                    break;
                }
                
                lastSendedEmail memory finishSendedEmail = lastEmailSendMap[circuitIdentifier][sendedMonthPosition + 1];

                if (startSendedEmail.date < _itemsToAdd[recordNumber].time && finishSendedEmail.date -1 > _itemsToAdd[recordNumber].time){
                    lastEmailSendMap[circuitIdentifier][sendedMonthPosition].hasChanged = true;
                }
            }

            Record memory newRecord = Record({isDowntime:_itemsToAdd[recordNumber].isDowntime, time:_itemsToAdd[recordNumber].time});
            recordMap[circuitIdentifier].push(newRecord);
        }

        return "Records added";
    }
//



    function getReturnedPorcentages() public view returns (returnedPorcentages[] memory){
        returnedPorcentages[] memory procentagesToReturn = new returnedPorcentages[](returnedPorcentagesArray.length);
        
        for (uint i = 0 ; returnedPorcentagesArray.length > i; i++){

            returnedPorcentages memory porcentageToReturn = returnedPorcentages({circuitIdentifier:returnedPorcentagesArray[i].circuitIdentifier, date:returnedPorcentagesArray[i].date, porcentage:returnedPorcentagesArray[i].porcentage});
            procentagesToReturn[i] = porcentageToReturn;
        }
        return(procentagesToReturn);



    
    }



    function getLastEmailSend(string memory _circuitIdentifier) public view returns (lastSendedEmail[] memory){
        lastSendedEmail[] memory emailsToSend = new lastSendedEmail[](lastEmailSendMap[_circuitIdentifier].length);
        
        for (uint i = 0 ; lastEmailSendMap[_circuitIdentifier].length > i; i++){

            lastSendedEmail memory porcentageToReturn = lastSendedEmail({date:lastEmailSendMap[_circuitIdentifier][i].date, hasChanged:lastEmailSendMap[_circuitIdentifier][i].hasChanged});
            emailsToSend[i] = porcentageToReturn;
        }
        return(emailsToSend);
    }

    function calculateDownTime(string memory _circuitIdentifier, uint _startDate, uint _endDate) public view returns (uint percentage){ //testeado
        Record[] memory recordsArray = this.getRecords(_circuitIdentifier, _startDate, _endDate);
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



        associatedSLA memory actualSLA = this.getActualCircuitSLA(_circuitIdentifier);
        for(uint i = 0; SLAMap[actualSLA.SLAName].length > i; i++){    //testeado
            if(SLAMap[actualSLA.SLAName][i].max >= upTimePorcentage && SLAMap[actualSLA.SLAName][i].min < upTimePorcentage){
                return SLAMap[actualSLA.SLAName][i].percentage;
            }
        }
        return SLAMap[actualSLA.SLAName][SLAMap[actualSLA.SLAName].length-1].percentage; //if not found returns the last percentage
    }




    function activatedByCron() public returns (returnedPorcentages[] memory){    //testeado

        delete returnedPorcentagesArray;
        uint256 last_position;
        uint16 last_year;
        uint8 last_month;
        bool newCircuit = false;
        uint monthStart;
        for (uint i = 0; circuitsArray.length > i; i++) {//testeado    //for by every circuit
            
            string memory circuitIdentifier = circuitsArray[i];
            uint returnedporcentage;
            if (lastEmailSendMap[circuitIdentifier].length > 0){ //testeado
                last_position = lastEmailSendMap[circuitIdentifier].length-1;
                last_year = IDatetime(datetimeAddress).getYear(lastEmailSendMap[circuitIdentifier][last_position].date);
                last_month = IDatetime(datetimeAddress).getMonth(lastEmailSendMap[circuitIdentifier][last_position].date);
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

            for (uint j = 0; lastEmailSendMap[circuitIdentifier].length > j; j++){//testeado       //Resend emails for months with changes
                if (lastEmailSendMap[circuitIdentifier][j].hasChanged){
                    if (lastEmailSendMap[circuitIdentifier].length == j -1){ //if last position calculate endtime of calculations
                        returnedporcentage = this.calculateDownTime(circuitIdentifier, lastEmailSendMap[circuitIdentifier][j].date, lastEmailSendMap[circuitIdentifier][j].date + seconds_to_add);
                    }
                    else{//testeado
                        returnedporcentage =this.calculateDownTime(circuitIdentifier, lastEmailSendMap[circuitIdentifier][j].date, lastEmailSendMap[circuitIdentifier][j + 1].date -1);
                    }

                    returnedPorcentagesArray.push(returnedPorcentages({circuitIdentifier:circuitIdentifier, date:lastEmailSendMap[circuitIdentifier][j].date,porcentage:returnedporcentage}));

                    lastEmailSendMap[circuitIdentifier][j].hasChanged = false;
                }
            }
            if(lastEmailSendMap[circuitIdentifier].length < 4){  //testeado
                if (newCircuit == true){ //testeado
                    lastSendedEmail memory newLastSendedEmail = lastSendedEmail({date:monthStart + seconds_to_add, hasChanged:false});
                    lastEmailSendMap[circuitIdentifier].push(newLastSendedEmail);
                }
                else{ //testeado
                    lastEmailSendMap[circuitIdentifier].push(lastSendedEmail({date:lastEmailSendMap[circuitIdentifier][last_position].date + seconds_to_add, hasChanged:false}));
                    last_position = lastEmailSendMap[circuitIdentifier].length-1;
                }
            }
            else{ //testeado
                for (uint j = 0; lastEmailSendMap[circuitIdentifier].length - 1 > j; j++){ //Move indexs to -1 to enter new month
                    lastEmailSendMap[circuitIdentifier][j] = lastEmailSendMap[circuitIdentifier][j + 1];
                }
                lastEmailSendMap[circuitIdentifier][last_position].date = lastEmailSendMap[circuitIdentifier][last_position].date + seconds_to_add;
                lastEmailSendMap[circuitIdentifier][last_position].hasChanged = false;
            }

        
            last_year = IDatetime(datetimeAddress).getYear(lastEmailSendMap[circuitIdentifier][last_position].date);
            last_month = IDatetime(datetimeAddress).getMonth(lastEmailSendMap[circuitIdentifier][last_position].date);
            days_in_month = IDatetime(datetimeAddress).getDaysInMonth(last_month, last_year);
            seconds_to_add = days_in_month * DAY_IN_SECONDS; //second of the last month with an email sended


            returnedporcentage = this.calculateDownTime(circuitIdentifier, lastEmailSendMap[circuitIdentifier][last_position].date, lastEmailSendMap[circuitIdentifier][last_position].date + seconds_to_add);
            returnedPorcentagesArray.push(returnedPorcentages({circuitIdentifier:circuitIdentifier, date:lastEmailSendMap[circuitIdentifier][last_position].date, porcentage:returnedporcentage}));


        }
        return(returnedPorcentagesArray);
    }

}