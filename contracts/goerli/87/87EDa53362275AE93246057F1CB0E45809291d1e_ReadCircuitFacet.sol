// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./CircuitLib.sol";
import "../SLA/SLALib.sol";

contract ReadCircuitFacet {
    function getCircuits() external view returns (string[] memory) {
        return CircuitLib.getCircuits();
    }

    function addCircuit(string calldata _circuitId) external {
        CircuitLib.addCircuit(_circuitId);
    }

    function addSLAToCircuit(string calldata _SLAId, string calldata _circuitId, uint _startDate, uint _endDate) public {
        require (SLALib.getStorage().SLAMap[_SLAId].length > 0, "SLA does not exist");
        bool found = false;
        CircuitLib.Circuit storage returnedCircuit = CircuitLib.getStorage();

        for (uint i = 0; i < returnedCircuit.circuitArray.length; i++){
            if (keccak256(abi.encodePacked(returnedCircuit.circuitArray[i])) == keccak256(abi.encodePacked(_circuitId))){
                found=true;
                break;
            }
        } 
        require(found, "Circuit does not exist");

        for(uint i = 0; i < returnedCircuit.circuitSLAMap[_circuitId].length; i++){
            require(! (returnedCircuit.circuitSLAMap[_circuitId][i].endDate >= _startDate && 
                    returnedCircuit.circuitSLAMap[_circuitId][i].startDate <= _endDate), 
                    "SLA already exists in this period (probably is overlapping)"); 
                    //check if overlap with other associatedSLA 
        }

        CircuitLib.associatedSLA memory newAsociation = CircuitLib.associatedSLA({SLAName:_SLAId, startDate:_startDate, endDate:_endDate});
        returnedCircuit.circuitSLAMap[_circuitId].push(newAsociation);
    }

    function getActualCircuitSLA(string memory _circuitId) external view returns (CircuitLib.associatedSLA memory) {
        CircuitLib.Circuit storage returnedCircuit = CircuitLib.getStorage();
        require (returnedCircuit.circuitSLAMap[_circuitId].length > 0, "This circuit has no SLAs");  //Check if key exists


        CircuitLib.associatedSLA memory actualassociatedSLA;
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

    struct StorageSLA{
        string[] SLAIds; //storage all the SLAs identifiers
        mapping(string => SLARange[]) SLAMap; //Storage the relation between SLAs and its Ranges (key SLA Identifier)
    }  

    function getStorage() internal pure returns (StorageSLA storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addSLA(string calldata _SLAId, SLARange[] memory _SLARanges) internal returns(SLA memory createdSLA) {
        StorageSLA storage s = getStorage();
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
        StorageSLA storage s = getStorage();
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

    struct Circuit{
        string[] circuitArray;
        mapping(string => associatedSLA[]) circuitSLAMap; //Storage the relation between Circuit and the asociated SLA (historic) (Key Circuit Identifier)
    }  



    function getStorage() internal pure returns (Circuit storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    function addCircuit(string calldata _circuitId) internal{
        Circuit storage s = getStorage();
        s.circuitArray.push(_circuitId);
    }

    function getCircuits() internal view returns (string[] memory){
        return (getStorage().circuitArray);
    }

    

}