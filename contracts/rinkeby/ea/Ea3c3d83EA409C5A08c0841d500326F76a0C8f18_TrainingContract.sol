/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

pragma solidity ^0.8.14;

// https://faucet.rinkeby.io/

contract TrainingContract {

    struct Location {
        string addressLine1;
        string addressLine2;
        string city;
        string province;
        string countryCode;
        string postalCode;
    }

    string _name;
    Location _location;

    event LOCATION(Location l);
    event MONEY_RECEIVED(address, uint256);

    function setName(string memory name_) external  {
        _name = name_;
    }

    function getName() external view returns (string memory) {
        return _name;
    }

    function setLocation(Location memory location_) external  {
        _location = location_;
    }

    function getLocation() external {
        emit LOCATION(_location);
    }

    function giveMeMoney() external payable {
        emit MONEY_RECEIVED(msg.sender, msg.value);
    }

}