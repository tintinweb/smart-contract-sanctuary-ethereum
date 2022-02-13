/**
 *Submitted for verification at Etherscan.io on 2022-02-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

contract Greeter {
    string private greeting;

    uint dataId = 0;
    struct Data{
        uint id;
        string name;
        uint price;
    }
    mapping(uint => Data) public idToData;
    event DataCreated(
        uint id,
        string name,
        uint price
    );
    event DataUpdated(uint id,string name, uint price);
    event DataDeleted(uint id);

    function createData(string memory _name, uint _price) public{
        require(bytes(_name).length != 0, "Parameters can't be empty!");
        dataId++;
        idToData[dataId] = Data(
            dataId,
            _name,
            _price
        );

        emit DataCreated(dataId, _name, _price);
    }

    function updateData(uint _dataId, string memory _name, uint _price) public {
        require(_dataId > 0 && _dataId <= dataId, "Data doesn't exist!");
        idToData[_dataId].name = _name;
        idToData[_dataId].price = _price;
        emit DataUpdated(_dataId, _name, _price);
    }

    function deleteData(uint _dataId) public{
        require(_dataId > 0 && _dataId <= dataId, "Data doesn't exist!");
        delete idToData[_dataId];
        emit DataDeleted(_dataId);
    }

    constructor(string memory _greeting) {
        greeting = _greeting;
    }

    function greet() public view returns (string memory) {
        return greeting;
    }

    function setGreeting(string memory _greeting) public {
        greeting = _greeting;
    }
}