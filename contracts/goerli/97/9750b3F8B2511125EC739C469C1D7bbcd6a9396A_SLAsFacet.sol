// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.15;

import "./SLALib.sol";

contract SLAsFacet {
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
            _SLARanges[i] = SLALib.SLARange({max:_maxRanges[i], min:_minRanges[i], percentage:_percentage.length});
        }
        return SLALib.addSLA(_SLAID, _SLARanges);
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

}