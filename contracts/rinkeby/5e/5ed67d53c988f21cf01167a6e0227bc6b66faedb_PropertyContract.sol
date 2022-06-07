/**
 *Submitted for verification at Etherscan.io on 2022-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IlandBaronstorage{
    function getOwner() external view returns(address);
    struct reservationTimes{uint startTimestamp; uint stopTimestamp;}
    function getReservableStatus(string calldata _propertyName) external view returns(bool);
    function getPropertyExists(string calldata _propertyName) external view returns(bool);
    function setReservableStatus(string calldata _propertyName, bool _status) external;
    function setPropertyExists(string calldata _propertyName, bool _status) external;
    function getReservations(string calldata _propertyName) external view returns(reservationTimes[] memory);
    function addReservation(address _address, string calldata _propertyName, uint _startTimestamp, uint _stopTimestamp) external;
    function resetReservations(string calldata _propertyName) external;
    function updateProperties(string[] memory _properties) external;
    function getProperties() external view returns(string[] memory);
    function addTenant(address _address) external;
    function removeTenant(address _address) external;
    function updatePricePerHr(string calldata _propertyName, uint _pricePerHr) external;
    function getPricePerHr(string calldata _propertyName) external returns(uint);
    function isAdmin(address _address) external view returns(bool);
}

contract PropertyContract{
    string[] _properties; //temp variable
    string[] _reset; //reset _properties array

    address landBaronStorageContract;
    constructor(address _landBaronStorageContractAddress) {
        landBaronStorageContract = _landBaronStorageContractAddress;
    }

    modifier onlyOwner{
        require(msg.sender == IlandBaronstorage(landBaronStorageContract).getOwner(), "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyAdminOrOwner{
        require(IlandBaronstorage(landBaronStorageContract).isAdmin(msg.sender) || msg.sender == IlandBaronstorage(landBaronStorageContract).getOwner(), "Only the owner or an admin of the contract can call this function");
        _;
    }

    function changePropertyPricePerHr(string calldata _propertyName, uint _newPricePerHr) external onlyAdminOrOwner{
        IlandBaronstorage(landBaronStorageContract).updatePricePerHr(_propertyName, _newPricePerHr);
    }

    function addProperty(string calldata _propertyName, uint _propertyPricePerHr) external onlyAdminOrOwner{
        require(!IlandBaronstorage(landBaronStorageContract).getPropertyExists(_propertyName), "Property already exists");
        IlandBaronstorage(landBaronStorageContract).setReservableStatus(_propertyName, true);
        IlandBaronstorage(landBaronStorageContract).setPropertyExists(_propertyName, true);
        _properties = IlandBaronstorage(landBaronStorageContract).getProperties();
        _properties.push(_propertyName);
        IlandBaronstorage(landBaronStorageContract).updateProperties(_properties);
        IlandBaronstorage(landBaronStorageContract).updatePricePerHr(_propertyName, _propertyPricePerHr);
    }

    function updateReservableStatus(string calldata _propertyName, uint _oneOrZero) external onlyAdminOrOwner{
        require(IlandBaronstorage(landBaronStorageContract).getPropertyExists(_propertyName), "Property doesn't exists");
        require(_oneOrZero == 1 || _oneOrZero == 0, "Invalid value. 1 == true and 0 == false");
        bool _status = false;
        if(_oneOrZero == 1){
            _status = true;
        }
        IlandBaronstorage(landBaronStorageContract).setReservableStatus(_propertyName, _status);
    }

    function reserveProperty(string calldata _propertyName, uint _startTimestamp, uint _stopTimestamp) external payable {
        require(IlandBaronstorage(landBaronStorageContract).getPropertyExists(_propertyName), "Property doesn't exist");
        require(IlandBaronstorage(landBaronStorageContract).getReservableStatus(_propertyName), "Property is not reservable");
        require(_startTimestamp > block.timestamp, "Start time must be in the future");
        require(_stopTimestamp > _startTimestamp, "You may have your start and stop times backwards");
        require(msg.value == (_stopTimestamp - _startTimestamp) / 3600 * IlandBaronstorage(landBaronStorageContract).getPricePerHr(_propertyName), "Check the amount of ETH you are sending.");

        if(IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName).length == 0){
            //add the reservation
            IlandBaronstorage(landBaronStorageContract).addReservation(msg.sender, _propertyName, _startTimestamp, _stopTimestamp);
            IlandBaronstorage(landBaronStorageContract).addTenant(msg.sender);
            payable(landBaronStorageContract).transfer(msg.value);
        }else{
            for(uint i = 0; i <= IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName).length - 1; i++){
                if(IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName)[i].startTimestamp >= _startTimestamp && IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName)[i].startTimestamp <= _stopTimestamp
                || IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName)[i].stopTimestamp >= _startTimestamp && IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName)[i].stopTimestamp <= _stopTimestamp){
                    revert("The reservation time selected is already reserved or overlaps a current reservation. Either choose a different property or a different reservation time window");
                }
            }
            //if there was no revert; then add the reservation
            IlandBaronstorage(landBaronStorageContract).addReservation(msg.sender, _propertyName, _startTimestamp, _stopTimestamp);
            IlandBaronstorage(landBaronStorageContract).addTenant(msg.sender);
            payable(landBaronStorageContract).transfer(msg.value);
        }
    }

    function removeProperty(string calldata _propertyName) external onlyAdminOrOwner{
        require(IlandBaronstorage(landBaronStorageContract).getPropertyExists(_propertyName), "Property doesn't exist");
        //make sure it's not reserved
        if(IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName).length == 0){
            IlandBaronstorage(landBaronStorageContract).setReservableStatus(_propertyName, false);
            IlandBaronstorage(landBaronStorageContract).setPropertyExists(_propertyName, false);
        }else{
            for(uint i = 0; i <= IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName).length - 1; i++){
                if(IlandBaronstorage(landBaronStorageContract).getReservations(_propertyName)[i].stopTimestamp > block.timestamp){
                    revert("Cannot remove reserved properties");
                }
            }
            //if no revert then remove property
            IlandBaronstorage(landBaronStorageContract).resetReservations(_propertyName);
            IlandBaronstorage(landBaronStorageContract).setReservableStatus(_propertyName, false);
            IlandBaronstorage(landBaronStorageContract).setPropertyExists(_propertyName, false);
        }
        _properties = IlandBaronstorage(landBaronStorageContract).getProperties();
        if(_properties.length == 1){
            _properties = _reset;
            IlandBaronstorage(landBaronStorageContract).updateProperties(_reset);
        }else{
            for(uint i = 0; i <= _properties.length - 1; i++){
                if(keccak256(abi.encodePacked(_properties[i])) == keccak256(abi.encodePacked(_propertyName))){
                    _properties[i] = _properties[_properties.length - 1];
                    _properties.pop();
                    IlandBaronstorage(landBaronStorageContract).updateProperties(_properties);
                }
            } 
        }
    }

}