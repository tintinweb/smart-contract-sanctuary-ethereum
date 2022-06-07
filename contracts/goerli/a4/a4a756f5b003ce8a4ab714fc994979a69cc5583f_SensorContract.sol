// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract SensorContract {
    address private owner;
    uint256 public devicesCount;

    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);

    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        devicesCount = 0;
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

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

    //modifier to check if caller is a registered device
    modifier isRegisteredDevice() {
        require(deviceMetrics[msg.sender].registered == true, "Not a registered device");
        _;
    }

    //Structure for devices
    struct Device{
        bool registered;
        string deviceName;
        uint lastTemperatureCelsius;
        int8 lastHumidityPercentage;
    }
    //Address list of registered devices
    address[] private registeredDevices;
    
    //Mapping of addresses with devices
    mapping(address => Device) private deviceMetrics;

    //Upper and Lower Thresholds for the metrics
    uint constant TemperatureCelsiusLT = 20;
    uint constant TemperatureCelsiusUT = 30;
    int8 constant HumidityPercentageLT = 10;
    int8 constant HumidityPercentageUT = 40;

    //Events to trigger whenever any of the thresholds are exceeded
    event AlarmTemperatureCelsius(uint _valTemperatureCelsius, string _id);
    event AlarmHumidityPercentage(int8 _valHumidityPercentage, string _id);
    event AlarmTemperatureAndHumidity(uint _valTemperatureCelsius, int8 _valHumidityPercentage, string _id);

    //Function to register a device. This step is mandatory to update metrics and can only be executed by the owner
    function registerDevice(string memory _deviceName, address _deviceAddress) public isOwner {
        devicesCount++;
        registeredDevices.push(_deviceAddress);
        deviceMetrics[_deviceAddress].registered = true;
        deviceMetrics[_deviceAddress].deviceName = _deviceName;
        deviceMetrics[_deviceAddress].lastHumidityPercentage = 0;
        deviceMetrics[_deviceAddress].lastTemperatureCelsius = 0;
    }

    //Function to get a list of all registered devices and last metrics per each one
    function getRegisteredDevices() public view returns (Device[] memory){
        Device[] memory devices = new Device[](devicesCount);
        for (uint256 i = 0; i < devicesCount; i++) {
            Device storage device = deviceMetrics[registeredDevices[i]];
            devices[i] = device;
        }
         return devices;
    }

    //Get the thresholds defined for the metrics
    function getTriggers() public pure returns (uint, uint, int8, int8){
        return(TemperatureCelsiusLT, TemperatureCelsiusUT, HumidityPercentageLT, HumidityPercentageUT);    
    }
    
    //Update temperature with the value given by the sensor and alarm if needed
    function updateTemperatureCelsius(uint _valTemperatureCelsius) public isRegisteredDevice{
        deviceMetrics[msg.sender].lastTemperatureCelsius = _valTemperatureCelsius;
        if(TemperatureCelsiusLT > _valTemperatureCelsius || TemperatureCelsiusUT < _valTemperatureCelsius){
            emit AlarmTemperatureCelsius(_valTemperatureCelsius, deviceMetrics[msg.sender].deviceName);
        }
    }
    
    //Update humidity with the value given by the sensor and alarm if needed
    function updateHumidityPercentage(int8 _valHumidityPercentage) public isRegisteredDevice{
        deviceMetrics[msg.sender].lastHumidityPercentage = _valHumidityPercentage;
        if(HumidityPercentageLT > _valHumidityPercentage || HumidityPercentageUT < _valHumidityPercentage){
            emit AlarmHumidityPercentage(_valHumidityPercentage, deviceMetrics[msg.sender].deviceName);
        }
    }
    
    //Update values for temperature and humidity given by the sensor and alarm if needed
    function updateTemperatureAndHumidity(uint _valTemperatureCelsius, int8 _valHumidityPercentage) public isRegisteredDevice {
        deviceMetrics[msg.sender].lastTemperatureCelsius = _valTemperatureCelsius;
        deviceMetrics[msg.sender].lastHumidityPercentage = _valHumidityPercentage;
        if((TemperatureCelsiusLT > _valTemperatureCelsius || TemperatureCelsiusUT < _valTemperatureCelsius) && 
            (HumidityPercentageLT > _valHumidityPercentage || HumidityPercentageUT < _valHumidityPercentage)){
                emit AlarmTemperatureAndHumidity( _valTemperatureCelsius, _valHumidityPercentage, deviceMetrics[msg.sender].deviceName);
        } else{
            if(TemperatureCelsiusLT > _valTemperatureCelsius || TemperatureCelsiusUT < _valTemperatureCelsius){
                emit AlarmTemperatureCelsius(_valTemperatureCelsius, deviceMetrics[msg.sender].deviceName);
            }
            if(HumidityPercentageLT > _valHumidityPercentage || HumidityPercentageUT < _valHumidityPercentage){
                emit AlarmHumidityPercentage(_valHumidityPercentage, deviceMetrics[msg.sender].deviceName);
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