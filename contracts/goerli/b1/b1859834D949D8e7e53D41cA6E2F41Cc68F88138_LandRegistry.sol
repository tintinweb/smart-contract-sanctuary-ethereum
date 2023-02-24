// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./ILandRegistry.sol";

contract LandRegistry is ILandRegistry{

    address admin;
    uint[] landids;
    mapping(uint => address) landHolder;
    mapping(uint => address[]) owners;
    
    constructor(){
        admin = msg.sender;
    }


    function registerland(uint _landID) override public {
        
        if(!landExist(_landID)){
            landids.push(_landID);
            landHolder[_landID] = msg.sender;
            owners[_landID].push(msg.sender);
            emit LandRegistered(msg.sender,_landID);
        
        }else{
            
            emit LandDuplicated(msg.sender, _landID, "Trying to resgister a known land");
            
        }
        
    }

    function landExist(uint _landID) private view returns(bool){

        for(uint i = 0; i < landids.length; i++){
            if(landids[i] == _landID){
                return true;
            }
        }

        return false;
    }

    
    
    function transferFrom(address _to, uint _landID) override public{
        
        address _from = msg.sender;
        
        if(landExist(_landID) && _from == landHolder[_landID]){

            landHolder[_landID] = _to;
            owners[_landID].push(_to);
            emit Transfer(_from, _to, _landID, "Property transfer done !");

        }else{
                       
            emit LandTransferNotAutorized(_from, _landID, "Fraud detected ! ");
        }

    }

    
    function landOwners(uint _landID) override public view returns(address[] memory){
        return owners[_landID];
    }

    modifier onlyLandOwner(uint _landID){
        require(msg.sender == landHolder[_landID], "Not this land owner");
        _;
    }

    
    error registerFailed(address _from, uint _landID, string _message);
    error fraudDetected(address _from, uint _landID, string _message);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface ILandRegistry{
    
    function transferFrom(address _to, uint _landID) external;
    function registerland(uint _landID) external;
    function landOwners(uint _landID) external returns(address[] memory);
    
    event LandRegistered(address indexed _owner, uint indexed land_id);
    event LandDuplicated(address indexed _from, uint indexed land_id, string message);
    event Transfer(address indexed _from, address indexed _to, uint indexed _landID, string message);
    event LandTransferNotAutorized(address indexed _from, uint indexed _landID, string _message);
}