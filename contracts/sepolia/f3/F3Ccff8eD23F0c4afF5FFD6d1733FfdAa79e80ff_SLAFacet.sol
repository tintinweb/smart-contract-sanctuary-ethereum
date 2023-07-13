// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "../service/ServiceLib.sol";
import "./SLALib.sol";
// Author: @Linkchar
contract SLAFacet {

    function getSLAs() external view returns (SLALib.SLA[] memory) {
        return SLALib.getSLAs();
    }

    function getSLAsIDs() external view returns (string[] memory){
        return SLALib.getSLAsIDs();
    }

    function addSLA(
        string calldata _SLAID,
        uint[] calldata _maxRanges,
        uint[] calldata _minRanges,
        uint[] calldata _percentage
        ) external returns (SLALib.SLA memory createdSLA) {
        require(_maxRanges.length == _minRanges.length && _maxRanges.length ==_percentage.length);

        SLALib.SLARange[] memory _SLARanges = new SLALib.SLARange[](_maxRanges.length);

        for(uint i=0; _maxRanges.length > i; i++){
            _SLARanges[i] = SLALib.SLARange({max:_maxRanges[i], min:_minRanges[i], percentage:_percentage[i]});
        }
        return SLALib.addSLA(_SLAID, _SLARanges);
    }

    function deleteSLA(string calldata _SLAId) external { 
        SLALib.deleteSLA(_SLAId);
    }

    function SLAInUse(string memory _slaIdentifier) public view returns (bool) {
        ServiceLib.ServiceStorageData storage returnedService = ServiceLib.getStorage();
        for(uint i=0; returnedService.serviceArray.length > i; i++){                   // for each Service
            for(uint j=0; returnedService.serviceSLAMap[returnedService.serviceArray[i]].length > j; j++){     //for each associatedSLA element in array
                if(keccak256(abi.encodePacked(returnedService.serviceSLAMap[returnedService.serviceArray[i]][j].SLAName)) == keccak256(abi.encodePacked(_slaIdentifier))){
                    return(true);
                }
            }
        }
        return(false);
    }

    function getConfigurations() external view returns (
        uint maintenanceConf,
        uint forceMajeureConf,
        uint timeLimitConf,
        string memory defaultResolutionConf){

        (maintenanceConf, forceMajeureConf, timeLimitConf, defaultResolutionConf) = SLALib.getConfigurations();

    }

    function updateConfigurations(
        uint _maintenanceConf,
        uint _forceMajeureConf,
        uint _timeLimitConf,
        string memory _defaultResolutionConf) external{

        SLALib.updateConfigurations(
            _maintenanceConf,
            _forceMajeureConf,
            _timeLimitConf,
            _defaultResolutionConf
            );

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