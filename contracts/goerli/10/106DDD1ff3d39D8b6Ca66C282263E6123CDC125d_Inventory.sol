/**
 *Submitted for verification at Etherscan.io on 2022-11-28
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Inventory {
    struct tube {
        uint256 id;
        string productType;
        string warehouse;
        uint yieldStrenght;
        uint pricePerInch;
        uint internalCost;
    }

    tube[] private tubes;

    // This modifier will prevent reentrancy attacks. It will not allow the caller to call the function again until it has finished executing.
    bool private locked;
    modifier noReentrancy() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    address private owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    //The function below will take an argument and convert it to a uint.
    //This is used to convert the ID, yield strength, price per inch, and internal cost to uints.
    //This is used in the addTube function.
    function stringToUint(string memory s) private pure returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint c = uint(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    function uintToString(uint s) private pure returns (string memory) {
        if (s == 0) return "0";
        uint j = s;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (s != 0) {
            bstr[k--] = bytes1(uint8(48 + (s % 10)));
            s /= 10;
        }
        return string(bstr);
    }

    //create an event that will be emitted when a new tube is added to the inventory
    event newTubeAdded(
        uint256 id,
        string productType,
        string warehouse,
        uint yieldStrenght,
        uint pricePerInch,
        uint internalCost
    );


    //This function will add a tube to the tubes array.
    function addTube(string[] memory _tube) public onlyOwner noReentrancy {
        // This for loop will check if the tube already exists in the array. If it does, it will revert. If it doesn't, it will add the tube to the array.
        for (uint256 i = 0; i < tubes.length; i++) {
            if (stringToUint(_tube[0]) == tubes[i].id) {
                revert("ID already in use.");
            }
        }
        //
        tubes.push(
            tube(
                stringToUint(_tube[0]),
                _tube[1],
                _tube[2],
                stringToUint(_tube[3]),
                stringToUint(_tube[4]),
                stringToUint(_tube[5])
            )
        );
        //emit the event
        emit newTubeAdded(
            stringToUint(_tube[0]),
            _tube[1],
            _tube[2],
            stringToUint(_tube[3]),
            stringToUint(_tube[4]),
            stringToUint(_tube[5])
        );


    }

    //create a view function that returns all the tubes
    function getTubes() public view onlyOwner returns (tube[] memory) {
        return tubes;
    }

    //create a function that returns the quantity of tubes in the inventory
    function getTubeCount() public view onlyOwner returns (uint) {
        return tubes.length;
    }

    //create a nuke function that will delete all the tubes in the inventory
    function nuke() public onlyOwner noReentrancy {
        delete tubes;
    }
    
}