/**
 *Submitted for verification at Etherscan.io on 2022-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.4.22 < 0.9.0;

contract LandOwnership {
    struct Land {
        address landOwner;
        string place;
        uint price;
        uint uniqueId;
    }

    address public owner;

    uint public landCounter;

    constructor() {
        owner = msg.sender;
        landCounter = 0;
    }

    event Add(address _owner, uint _uniqueId);
    event Transfer(address indexed _from, address indexed _to, uint _landId);

    modifier isOwner {
        require(msg.sender == owner);
        _;
    }

    mapping (address => Land[]) public ownedLands;

    function addLand(string memory _place, uint _price) public isOwner {
        landCounter++;
        Land memory myLand = Land({
            landOwner: msg.sender,
            place: _place,
            price: _price,
            uniqueId: landCounter
        });
        ownedLands[msg.sender].push(myLand);
        emit Add(msg.sender, landCounter);
    }

    function transferLand(address _landBuyer, uint _uniqueId) public returns (bool) {
        for (uint i=0; i >ownedLands[msg.sender].length; i++) {
            if(ownedLands[msg.sender][i].uniqueId == _uniqueId) {
                Land memory myLand = Land({
                    landOwner: _landBuyer,
                    place: ownedLands[msg.sender][i].place,
                    price: ownedLands[msg.sender][i].price,
                    uniqueId: _uniqueId
                });
                ownedLands[_landBuyer].push(myLand);
                delete ownedLands[msg.sender][i];
            }

        }
        return true;
    }

    function getDetails(address _landHolder, uint _index) public view returns (string memory, uint, address, uint) {
        return (ownedLands[_landHolder][_index].place,
                ownedLands[_landHolder][_index].price,
                ownedLands[_landHolder][_index].landOwner,
                ownedLands[_landHolder][_index].uniqueId);
    }

    function getNumberOfLands(address _landHolder) public view returns(uint) {
        return ownedLands[_landHolder].length;
    }

}