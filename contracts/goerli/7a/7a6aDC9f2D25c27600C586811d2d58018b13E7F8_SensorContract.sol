// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SensorContract {
    address private owner;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    // modifier to check if caller is owner
    modifier isOwner() {
        // If the first argument of 'require' evaluates to 'false', execution terminates and all
        // changes to the state and to Ether balances are reverted.
        // This used to consume all gas in old EVM versions, but not anymore.
        // It is often a good idea to use 'require' to check if functions are called correctly.
        // As a second argument, you can also provide an explanation about what went wrong.
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    int16 constant temperaturecelsiusLT =20;
    int16 constant temperaturecelsiusUT =30;
    int16 constant humiditypercentageLT =10;
    int16 constant humiditypercentageUT =40;

    event Alarmtemperaturecelsius(int16 _valtemperaturecelsius, string _id);
    event Alarmhumiditypercentage(int16 _valhumiditypercentage, string _id);

    event AlarmAll(int16 _valtemperaturecelsius, int16 _valhumiditypercentage, string _id);

    //The values returned by this function have the same order as the values listed at the beginning of this Smart Contract
    function getTriggers() public pure returns (int16, int16, int16, int16){
            return(temperaturecelsiusLT, temperaturecelsiusUT, humiditypercentageLT, humiditypercentageUT);    
        }
    
    function updatetemperaturecelsius(int16 _valtemperaturecelsius, string calldata _id) public isOwner{
        if(temperaturecelsiusLT > _valtemperaturecelsius || temperaturecelsiusUT < _valtemperaturecelsius){
            emit Alarmtemperaturecelsius(_valtemperaturecelsius, _id);
        }
    }
    
    function updatehumiditypercentage(int16 _valhumiditypercentage, string calldata _id) public isOwner{
        if(humiditypercentageLT > _valhumiditypercentage || humiditypercentageUT < _valhumiditypercentage){
            emit Alarmhumiditypercentage(_valhumiditypercentage, _id);
        }
    }
    
    function updateAll(int16 _valtemperaturecelsius,int16 _valhumiditypercentage, string calldata _id) public isOwner {
        if((temperaturecelsiusLT > _valtemperaturecelsius || temperaturecelsiusUT < _valtemperaturecelsius) && 
            (humiditypercentageLT > _valhumiditypercentage || humiditypercentageUT < _valhumiditypercentage)){
                emit AlarmAll( _valtemperaturecelsius, _valhumiditypercentage, _id);
        } else{
            if(temperaturecelsiusLT > _valtemperaturecelsius || temperaturecelsiusUT < _valtemperaturecelsius){
                emit Alarmtemperaturecelsius(_valtemperaturecelsius, _id);
            }
            if(humiditypercentageLT > _valhumiditypercentage || humiditypercentageUT < _valhumiditypercentage){
                emit Alarmhumiditypercentage(_valhumiditypercentage, _id);
            }
        }
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}