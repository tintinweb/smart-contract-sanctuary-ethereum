pragma solidity ^0.8.17;

error Location__NotEnoughtETHEntered();

struct LocationData {
    address sender;
    bytes32 date;
    uint128 longitute;
    uint128 latitude;
}

contract Location {

    uint256 private immutable i_sendFee;
    LocationData[] private s_locationData;

    event locationSend(address indexed sender,bytes32 indexed date, uint128 longitude, uint128 latitude);

    constructor(uint256 sendFee) {
        i_sendFee = sendFee;
    }
    function sendLocation(uint128 longitude, uint128 latitude, bytes32 date) public payable{
        if(msg.value < i_sendFee) {
            revert Location__NotEnoughtETHEntered();
        }

        s_locationData.push(LocationData(payable(msg.sender),date,longitude,latitude));

        emit locationSend(msg.sender,date,longitude,latitude);
    }
    function getFee() public view returns(uint256) {
        return i_sendFee;
    }

    function getLocationData(uint256 index) public view returns(LocationData memory) {
        return s_locationData[index];
    }
}