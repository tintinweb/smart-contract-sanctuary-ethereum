pragma solidity ^0.8.15;

contract TestContract {

    uint256 public x;

    address[] public addresses;

    string public y;

    struct Constructor {
        uint256 x;
        address[] addresses;
        string y;
    }

    constructor(Constructor memory request) {
        x = request.x;
        addresses = request.addresses;
        y = request.y;
    }

    function init(Constructor memory request) public {
        x = request.x;
        addresses = request.addresses;
        y = request.y;
    }

    function getAddresses() public view returns (address[] memory list) {
        list = new address[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            list[i] = addresses[i];
        }
    }
}