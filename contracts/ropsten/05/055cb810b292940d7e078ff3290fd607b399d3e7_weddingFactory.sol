/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Wedding {
    address public firstPerson;
    address public secondPerson;
    string public model;
    address public weddingAddr;

    constructor(
        address _firstPerson,
        address _secondPerson,
        string memory _model
    ) payable {
        firstPerson = _firstPerson;
        secondPerson = _secondPerson;
        model = _model;
        weddingAddr = address(this);
    }
}

contract weddingFactory {
    Wedding[] public weddings;

    function create(
        address _firstPerson,
        address _secondPerson,
        string memory _model
    ) public {
        Wedding wedding = new Wedding(_firstPerson, _secondPerson, _model);
        weddings.push(wedding);
    }

    function createAndSendEther(
        address _firstPerson,
        address _secondPerson,
        string memory _model
    ) public payable {
        Wedding wedding = (new Wedding){value: msg.value}(
            _firstPerson,
            _secondPerson,
            _model
        );
        weddings.push(wedding);
    }

    function create2(
        address _firstPerson,
        address _secondPerson,
        string memory _model,
        bytes32 _salt
    ) public {
        Wedding wedding = (new Wedding){salt: _salt}(
            _firstPerson,
            _secondPerson,
            _model
        );
        weddings.push(wedding);
    }

    function create2AndSendEther(
        address _firstPerson,
        address _secondPerson,
        string memory _model,
        bytes32 _salt
    ) public payable {
        Wedding wedding = (new Wedding){value: msg.value, salt: _salt}(
            _firstPerson,
            _secondPerson,
            _model
        );
        weddings.push(wedding);
    }

    function getWedding(uint256 _index)
        public
        view
        returns (
            address _firstPerson,
            address _secondPerson,
            string memory model,
            address carAddr,
            uint256 balance
        )
    {
        Wedding wedding = weddings[_index];

        return (wedding.firstPerson(), wedding.secondPerson(), wedding.model(), wedding.weddingAddr(), address(wedding).balance);
    }
}