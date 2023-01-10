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

    function sendLocation(uint128 longitude, uint128 latitude, string memory date) public payable{

        s_locationData.push(LocationData(payable(msg.sender),date,longitude,latitude));

        emit locationSend(msg.sender,date,longitude,latitude);
    }

    function clearLocations() public {
        delete s_locationData;
    }

    function deleteLocation(uint256 index) public {
        if (index >= s_locationData.length) return;

        for (uint i = index; i < s_locationData.length - 1; i++) {
            s_locationData[i] = s_locationData[i+1];
        }
        s_locationData.pop();
    }

    function getLocationDataByIndex(uint256 index) public view returns(LocationData memory) {
        return s_locationData[index];
    }

    function getLocationData() public view returns(LocationData[] memory) {
        return s_locationData;
    }
}