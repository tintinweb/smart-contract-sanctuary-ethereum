/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

pragma solidity ^0.5.0;
contract GeoTrankingStstem {
    //Record each user location with timestam
    struct locationstamp {
        uint256 lat;
        uint256 long;
        uint256 datetime;
    }

    //User fullnames / nicknames 
    mapping (address => string) users;

    //Historical locations of all users 
    mapping (address => locationstamp[]) public userLocations;

    //register username 
    function register(string memory userName) public {
        users[msg.sender] = userName;
    }

    //Getter og username
    function getPublicName(address userAddress) public view returns (string memory) {
        return users[userAddress];
    }

    function track(uint256 lat, uint256 long) public {
        locationstamp memory currentLocation;
        currentLocation.lat = lat;
        currentLocation.long = long;
        currentLocation.datetime = now; //block.timestamp;
        userLocations[msg.sender].push (currentLocation);
    }

    function getLastestlocation(address userAddress)
        public view returns (uint256 lat, uint256 long, uint256 datetime) {
            locationstamp[] storage locations = userLocations[msg.sender];
            locationstamp storage Lastestlocation = locations[locations.length - 1];
                // return (
                //     Lastestlocation.lat;
                //     Lastestlocation.long;
                //     Lastestlocation.datetime;
                // );
                lat = Lastestlocation.lat;
                long = Lastestlocation.long;
                datetime = Lastestlocation.datetime;
        }
}