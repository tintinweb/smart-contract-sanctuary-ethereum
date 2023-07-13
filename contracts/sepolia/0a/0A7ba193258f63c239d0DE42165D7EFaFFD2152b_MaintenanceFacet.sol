// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./maintenanceLib.sol";
// Author: @Linkchar
contract MaintenanceFacet{

    function getMaintenanceTimes(string memory _serviceId, uint _startDate, uint _endDate)public view returns (MaintenanceLib.Maintenance[] memory) {
        uint length = 0;
        uint position = 0;

        MaintenanceLib.Maintenance[] storage storageMaintenance = MaintenanceLib.getStorage().maintenanceMap[_serviceId];

        for(uint i = 0; i < storageMaintenance.length; i++){
            if(
                storageMaintenance[i].startDate >= _startDate && 
                storageMaintenance[i].endDate <= _endDate || //In this case the maintenance is all inside the ranges

                storageMaintenance[i].startDate <= _startDate && 
                storageMaintenance[i].endDate >= _endDate || //In this the case the maintenance starts before but ends in the requested range
                
                storageMaintenance[i].startDate >= _startDate && 
                storageMaintenance[i].startDate <= _endDate || //In this the case the maintenance starts after the start of requested time 
                                                                //but ends before the requested range
                storageMaintenance[i].endDate >= _startDate &&
                storageMaintenance[i].endDate <= _endDate)      //In this case the maintenance ends after the start frequested time
                                                                // but ends before the requested end time    
                {
                length++;
            }
        }

        MaintenanceLib.Maintenance[] memory returnedMaintenance = new MaintenanceLib.Maintenance[](length);
        for(uint i = 0; i < storageMaintenance.length; i++){
            if(
                storageMaintenance[i].startDate >= _startDate && 
                storageMaintenance[i].endDate <= _endDate || //In this case the maintenance is all inside the ranges

                storageMaintenance[i].startDate <= _startDate && 
                storageMaintenance[i].endDate >= _endDate || //In this the case the maintenance starts before but ends in the requested range
                
                storageMaintenance[i].startDate >= _startDate && 
                storageMaintenance[i].startDate <= _endDate|| //In this the case the maintenance starts after the start of requested time 
                                                                //but ends before the requested range
                storageMaintenance[i].endDate >= _startDate &&
                storageMaintenance[i].endDate <= _endDate)      //In this case the maintenance ends after the start frequested time
                                                                // but ends before the requested end time    
                {
                returnedMaintenance[position]=storageMaintenance[i];
                position ++;
            }
        }
        return returnedMaintenance;
    }

    function getMaintenanceTimesIDs(string memory _serviceId) external view returns (string[] memory){
        return MaintenanceLib.getMaintenanceIDs(_serviceId);
    }

    function createMaintenanceTime(
        string[] memory _serviceIds,
        string[] memory _maintenanceIds,
        uint[] memory _startDate, 
        uint[] memory _endDate) 
        public{

        require(
            _serviceIds.length == _startDate.length &&
            _serviceIds.length == _endDate.length &&
            _serviceIds.length == _maintenanceIds.length);

        for(uint forceMajeureNumber = 0; forceMajeureNumber < _serviceIds.length; forceMajeureNumber++){
            MaintenanceLib.Maintenance memory newMaintenance = MaintenanceLib.Maintenance({
                                                            maintenanceId:_maintenanceIds[forceMajeureNumber],
                                                            startDate:_startDate[forceMajeureNumber], 
                                                            endDate:_endDate[forceMajeureNumber]
                                                            });
            MaintenanceLib.addMaintenance(_serviceIds[forceMajeureNumber], newMaintenance);
        }
    }

    function updateMaintenanceTime(
        string memory _serviceId,
        string memory _maintenanceId,
        uint _startDate,
        uint _endDate)
        public{

        MaintenanceLib.Maintenance[] storage storageMaintenance = MaintenanceLib.getStorage().maintenanceMap[_serviceId];

        for(uint i = 0; i < storageMaintenance.length; i++){
            if(keccak256(abi.encodePacked(storageMaintenance[i].maintenanceId)) == keccak256(abi.encodePacked(_maintenanceId))){
                MaintenanceLib.updateMaintenanceTime(_serviceId, i, _startDate, _endDate);
                break;
            }
        }   
    }

    function deleteMaintenanceTime(
        string memory _serviceId,
        string memory _maintenanceId)
        public{

        MaintenanceLib.Maintenance[] storage storageMaintenance = MaintenanceLib.getStorage().maintenanceMap[_serviceId];

        for(uint i = 0; i < storageMaintenance.length; i++){
            if(keccak256(abi.encodePacked(storageMaintenance[i].maintenanceId)) == keccak256(abi.encodePacked(_maintenanceId))){
                MaintenanceLib.deleteMaintenanceTime(_serviceId, i);
                break;
            }
        }   
    }


}

// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;


library MaintenanceLib{

    bytes32 internal constant NAMESPACE = keccak256("wtf.lib.maintenace");
    
    struct Maintenance{
        string maintenanceId;
        uint startDate;
        uint endDate;
    }

    struct MaintenanceStorageData{
        mapping(string => Maintenance[]) maintenanceMap; // Storage the relation between services and its mantenance times
        mapping(string => string[]) maintenanceIdsMap;// Storage the ids of mantenance to every service 
    }

    function getStorage() internal pure returns (MaintenanceStorageData storage s){
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    } 

    function getMaintenanceIDs(string memory _serviceId) internal view returns (string[] memory returnedIDs){
        
        string[] storage maintenanceIds = getStorage().maintenanceIdsMap[_serviceId];
        returnedIDs = new string[](maintenanceIds.length);
        
        for(uint i = 0; i < maintenanceIds.length; i++){
            returnedIDs[i] = maintenanceIds[i];
        }
        return returnedIDs;
    } 

    function addMaintenance(string memory _serviceId, Maintenance memory _maintenance) internal{
        getStorage().maintenanceMap[_serviceId].push(_maintenance);
        getStorage().maintenanceIdsMap[_serviceId].push(_maintenance.maintenanceId);
    }

    function updateMaintenanceTime(string memory _serviceId, uint _position, uint _startDate,uint _endDate) internal {
        getStorage().maintenanceMap[_serviceId][_position].startDate = _startDate;
        getStorage().maintenanceMap[_serviceId][_position].endDate = _endDate;
    }

    function deleteMaintenanceTime(string memory _serviceId, uint _position) internal {
        string[] storage maintenanceIdsArray = getStorage().maintenanceIdsMap[_serviceId];
        string memory maintenanceId = getStorage().maintenanceMap[_serviceId][_position].maintenanceId;
        for(uint i = 0; maintenanceIdsArray.length > i; i++){       //delete the identifier from the idenfiersArray
            if (keccak256(abi.encodePacked(maintenanceIdsArray[i])) == keccak256(abi.encodePacked(maintenanceId))){
                maintenanceIdsArray[i] = maintenanceIdsArray[maintenanceIdsArray.length - 1];
                maintenanceIdsArray.pop();
                break;
            }
        }
        uint lastPosition = getStorage().maintenanceMap[_serviceId].length; 
        getStorage().maintenanceMap[_serviceId][_position] = getStorage().maintenanceMap[_serviceId][lastPosition-1];
        getStorage().maintenanceMap[_serviceId].pop();
    }



}