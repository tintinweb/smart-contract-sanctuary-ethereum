pragma solidity ^0.8.17;

    error Location__NotEnoughtETHEntered();

    struct LocationData {
        address sender;
        string  date;
        uint128 longitute;
        uint128 latitude;
    }

contract NoFeeLocation {

    LocationData[] private s_locationData;

    event locationSend(address indexed sender,string date, uint128 longitude, uint128 latitude);

    constructor() {
    }
    function sendLocation(uint128 longitude, uint128 latitude, string memory date) public payable{

        s_locationData.push(LocationData(payable(msg.sender),date,longitude,latitude));

        emit locationSend(msg.sender,date,longitude,latitude);
    }

    function getLocationData(uint256 index) public view returns(LocationData memory) {
        return s_locationData[index];
    }
}