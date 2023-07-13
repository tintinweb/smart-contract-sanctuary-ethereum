// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./ServiceLib.sol";
import "../SLA/SLALib.sol";
// Author: @Linkchar
contract ServiceFacet {

    function addService(string[] calldata _serviceIds) external {
        for(uint i=0; _serviceIds.length > i; i++){
            ServiceLib.addService(_serviceIds[i]);
        }
    }
    
    function getServices() external view returns (string[] memory) {
        return ServiceLib.getServices();
    }

    function getSLAOfService(string memory _serviceId) public view returns (
                                        ServiceLib.associatedSLA memory,
                                        ServiceLib.associatedSLA[] memory,
                                        ServiceLib.associatedSLA[] memory) {

        ServiceLib.ServiceStorageData storage returnedService = ServiceLib.getStorage();

        require (returnedService.serviceSLAMap[_serviceId].length > 0);  //Check if key exists

        bool found = false;
        for (uint i = 0; i < returnedService.serviceArray.length; i++){
            if (keccak256(abi.encodePacked(returnedService.serviceArray[i])) == keccak256(abi.encodePacked(_serviceId))){
                found=true;
                break;
            }
        } 
        require(found); //Check if Service exists

        ServiceLib.associatedSLA memory actualAssociatedSLA = this.getActualServiceSLA(_serviceId);
        ServiceLib.associatedSLA[] memory pastAssociatedSLAArray = this.getPastServiceSLAs(_serviceId);
        ServiceLib.associatedSLA[] memory futureAssociatedSLAArray = this.getFutureServiceSLAs(_serviceId);
        return (actualAssociatedSLA, pastAssociatedSLAArray, futureAssociatedSLAArray);
    }

    function addSLAToService(string calldata _SLAId, string calldata _serviceId, uint _startDate, uint _endDate) public {
        require (SLALib.getStorage().SLAMap[_SLAId].length > 0, "SLA does not exist");
        bool found = false;
        ServiceLib.ServiceStorageData storage returnedService = ServiceLib.getStorage();

        for (uint i = 0; i < returnedService.serviceArray.length; i++){
            if (keccak256(abi.encodePacked(returnedService.serviceArray[i])) == keccak256(abi.encodePacked(_serviceId))){
                found=true;
                break;
            }
        } 
        require(found, "Service does not exist");

        for(uint i = 0; i < returnedService.serviceSLAMap[_serviceId].length; i++){
            require(! (returnedService.serviceSLAMap[_serviceId][i].endDate >= _startDate && 
                    returnedService.serviceSLAMap[_serviceId][i].startDate <= _endDate), 
                    "SLA already exists in this period (probably is overlapping)"); 
                    //check if overlap with other associatedSLA 
        }

        ServiceLib.associatedSLA memory newAsociation = ServiceLib.associatedSLA({SLAName:_SLAId, startDate:_startDate, endDate:_endDate});
        returnedService.serviceSLAMap[_serviceId].push(newAsociation);
    }

    function getActualServiceSLA(string memory _serviceId) external view returns (ServiceLib.associatedSLA memory) {
        return(ServiceLib.getActualServiceSLA(_serviceId));
    }

    function getPastServiceSLAs(string memory _serviceId) public view returns (ServiceLib.associatedSLA[] memory) {
        ServiceLib.ServiceStorageData storage returnedService = ServiceLib.getStorage();

        ServiceLib.associatedSLA[] memory pastAsociatedSLAArray;

        if(returnedService.serviceSLAMap[_serviceId].length == 0){
            pastAsociatedSLAArray = new ServiceLib.associatedSLA[](1);
            pastAsociatedSLAArray[0] = ServiceLib.associatedSLA({SLAName:"", startDate:0, endDate:0});
            return pastAsociatedSLAArray;
        }

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < returnedService.serviceSLAMap[_serviceId].length; i++){  //for by the number of Service SLAs
            if(returnedService.serviceSLAMap[_serviceId][i].endDate < block.timestamp){ //If the SLA is expired
                    length++;
            }
        }

        pastAsociatedSLAArray = new ServiceLib.associatedSLA[](length);

        for(uint i = 0; i < returnedService.serviceSLAMap[_serviceId].length; i++){  //for by the number of Service SLAs
            if(returnedService.serviceSLAMap[_serviceId][i].endDate < block.timestamp){ //If the SLA is expired
                    pastAsociatedSLAArray[position] = returnedService.serviceSLAMap[_serviceId][i]; 
                    position++;
            }
        }

        return (pastAsociatedSLAArray);

    }

    function getFutureServiceSLAs(string memory _serviceId) public view returns (ServiceLib.associatedSLA[] memory) {
        ServiceLib.ServiceStorageData storage returnedService = ServiceLib.getStorage();
        ServiceLib.associatedSLA[] memory futureAsociatedSLAArray;

        if(returnedService.serviceSLAMap[_serviceId].length == 0){
            futureAsociatedSLAArray = new ServiceLib.associatedSLA[](1);
            futureAsociatedSLAArray[0] = ServiceLib.associatedSLA({SLAName:"", startDate:0, endDate:0});
            return futureAsociatedSLAArray;
        }

        uint length = 0;
        uint position = 0;

        for(uint i = 0; i < returnedService.serviceSLAMap[_serviceId].length; i++){
            if(returnedService.serviceSLAMap[_serviceId][i].endDate > block.timestamp){
                if (!(returnedService.serviceSLAMap[_serviceId][i].startDate < block.timestamp)){      
                    length++;
                }
            }
        }

        futureAsociatedSLAArray = new ServiceLib.associatedSLA[](length);

        for(uint i = 0; i < returnedService.serviceSLAMap[_serviceId].length; i++){
            if(returnedService.serviceSLAMap[_serviceId][i].endDate > block.timestamp &&
                returnedService.serviceSLAMap[_serviceId][i].startDate > block.timestamp){
                    futureAsociatedSLAArray[position] = returnedService.serviceSLAMap[_serviceId][i]; 
                    position++;
            }
        }

        return (futureAsociatedSLAArray);

    }
}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library ServiceLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.service");


    struct associatedSLA{    
        string SLAName;
        uint startDate;
        uint endDate;
    }

    struct Calculations{
        uint upTimePorcentage;
        uint credits;
    }

    struct MonthlyCalculations{
        uint16 year;
        uint8 month;
        Calculations buyerCalculations;
        Calculations sellerCalculations;
        Calculations finalCalculations;
        bool isClosed;
        uint resolutionType; //seller, buyer, middlePoint
        bool hasChanged;
    }

    struct returnedPorcentages{         //only use for return the calculated data every month
        string serviceId;
        uint date; //startdate of the month
        uint upTimePorcentage;
        uint porcentage;
    }

    struct ServiceStorageData{
        string[] serviceArray;
        mapping(string => associatedSLA[]) serviceSLAMap; //Storage the relation between service and the asociated SLA (historic) (Key service Identifier)
        mapping(string => MonthlyCalculations[]) monthlyCalculationsMap;
        returnedPorcentages[] returnedPorcentagesArray;

    }  

    function getStorage() internal pure returns (ServiceStorageData storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addService(string calldata _serviceId) internal{
        ServiceStorageData storage s = getStorage();
        s.serviceArray.push(_serviceId);
    }

    function getServices() internal view returns (string[] memory){
        return (getStorage().serviceArray);
    }

    function getMonthlyCalculations(string memory _serviceId) internal view returns (MonthlyCalculations[] storage){
        return (getStorage().monthlyCalculationsMap[_serviceId]);
    }

    function addMonthlyCalculations(string memory _serviceId, MonthlyCalculations memory _monthlyCalculations) internal{
        getStorage().monthlyCalculationsMap[_serviceId].push(_monthlyCalculations);
    }

    function getReturnedPorcentages() internal view returns (returnedPorcentages[] memory){
        return(getStorage().returnedPorcentagesArray);
    }

    function updateMonthlyCalculations(string memory _serviceId, uint _index, MonthlyCalculations memory _monthlyCalculations) internal{
        getStorage().monthlyCalculationsMap[_serviceId][_index] = _monthlyCalculations;
    }

    function addReturnedPorcentages(returnedPorcentages memory _returnedPorcentage) internal{
        getStorage().returnedPorcentagesArray.push(_returnedPorcentage);
    }

    function deleteReturnedPorcentages() internal{
        delete getStorage().returnedPorcentagesArray;
    }

    function getActualServiceSLA(string memory _serviceId) internal view returns(associatedSLA memory actualassociatedSLA) {
        ServiceStorageData storage returnedservice = getStorage();
        if(returnedservice.serviceSLAMap[_serviceId].length <= 0){
            actualassociatedSLA = associatedSLA({SLAName:"", startDate:0, endDate:0});
            return(actualassociatedSLA);
        }

        for(uint i = 0; i < returnedservice.serviceSLAMap[_serviceId].length; i++){
            if(returnedservice.serviceSLAMap[_serviceId][i].endDate > block.timestamp){
                if(returnedservice.serviceSLAMap[_serviceId][i].startDate < block.timestamp){
                    actualassociatedSLA = returnedservice.serviceSLAMap[_serviceId][i];
                    break;
                }
            }
        }
        return (actualassociatedSLA);
    }

}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

library SLALib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.sla");

    struct Configurations{
        uint maintenanceConfiguration;
        uint forceMajeureConfiguration;
        uint timeLimitForAgreement;
        string defaultResolution;
    }

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
        Configurations generalConfigurations;
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
        return createdSLA = (SLA({
                                    Id:_SLAId,
                                    SLARanges:s.SLAMap[_SLAId]
                                    }));
    }

    function getSLA(string calldata _SLAId) internal view returns(SLARange[] memory ranges){
        SLAStorageData storage s = getStorage();
        ranges = s.SLAMap[_SLAId];
        return(ranges);
    }

    function getSLAs() internal view returns (SLA[] memory){
        
        SLA[] memory returnedSLAs = new SLA[](getStorage().SLAIds.length);
        string memory actualSLA;
        
        for(uint i = 0; i < getStorage().SLAIds.length; i++){
            actualSLA = getStorage().SLAIds[i];

            returnedSLAs[i] = SLA({Id:actualSLA, SLARanges:getStorage().SLAMap[actualSLA]});
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

    function getConfigurations() internal view returns(
        uint maintenanceConf,
        uint forceMajeureConf,
        uint timeLimitConf,
        string memory defaultResolutionConf){

        maintenanceConf = getStorage().generalConfigurations.maintenanceConfiguration;
        forceMajeureConf = getStorage().generalConfigurations.forceMajeureConfiguration;
        timeLimitConf =  getStorage().generalConfigurations.timeLimitForAgreement;
        defaultResolutionConf =  getStorage().generalConfigurations.defaultResolution;

    }

    function updateConfigurations(
        uint _maintenanceConf,
        uint _forceMajeureConf,
        uint _timeLimitConf,
        string memory _defaultResolutionConf) 
        internal{

        if(_maintenanceConf != 999999){
            getStorage().generalConfigurations.maintenanceConfiguration= _maintenanceConf;
        } 
        if(_forceMajeureConf != 999999){
            getStorage().generalConfigurations.forceMajeureConfiguration = _forceMajeureConf;
        } 
        if(_timeLimitConf != 999999){
            getStorage().generalConfigurations.timeLimitForAgreement= _timeLimitConf;
        } 
        if(keccak256(abi.encodePacked(_defaultResolutionConf)) != keccak256(abi.encodePacked("-"))){
            getStorage().generalConfigurations.defaultResolution= _defaultResolutionConf;
        }
    }

}