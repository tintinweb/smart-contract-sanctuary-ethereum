// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "../circuit/CircuitLib.sol";
import "./SLALib.sol";

contract SLAFacet {

    function getSLAs() external view returns (SLALib.SLA[] memory) {
        return SLALib.getSLAs();
    }

    function getSLAsIDs() external view returns (string[] memory){
        return SLALib.getSLAsIDs();
    }

    function addSLA(string calldata _SLAID, uint[] calldata _maxRanges,
                    uint[] calldata _minRanges, uint[] calldata _percentage) external 
                    returns (SLALib.SLA memory createdSLA) {

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
        CircuitLib.CircuitStorageData storage returnedCircuit = CircuitLib.getStorage();
        for(uint i=0; returnedCircuit.circuitArray.length > i; i++){                   // for each circuit
            for(uint j=0; returnedCircuit.circuitSLAMap[returnedCircuit.circuitArray[i]].length > j; j++){     //for each associatedSLA element in array
                if(keccak256(abi.encodePacked(returnedCircuit.circuitSLAMap[returnedCircuit.circuitArray[i]][j].SLAName)) == keccak256(abi.encodePacked(_slaIdentifier))){
                    return(true);
                }
            }
        }
        return(false);
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