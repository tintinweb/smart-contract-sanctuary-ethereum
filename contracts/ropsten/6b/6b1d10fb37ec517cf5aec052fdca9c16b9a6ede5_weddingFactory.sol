/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

contract Wedding {
    address public firstPerson;
    address public secondPerson;
    address public weddingAddr;

    constructor(
        address _firstPerson,
        address _secondPerson
    ) payable {
        firstPerson = _firstPerson;
        secondPerson = _secondPerson;
        weddingAddr = address(this);
    }
}

contract weddingFactory {
    Wedding[] public weddings;

    function create(
        address _firstPerson,
        address _secondPerson
    ) public returns (uint256 _index) {
        Wedding wedding = new Wedding(_firstPerson, _secondPerson);
        weddings.push(wedding);
        return weddings.length - 1;
    }

    function createAndSendEther(
        address _firstPerson,
        address _secondPerson
    ) public payable {
        Wedding wedding = (new Wedding){value: msg.value}(
            _firstPerson,
            _secondPerson
        );
        weddings.push(wedding);
        //emit event
        emit weddingCreated(weddings.length - 1);
    }

    event weddingCreated(uint256 _index);

    function create2(
        address _firstPerson,
        address _secondPerson,
        bytes32 _salt
    ) public {
        Wedding wedding = (new Wedding){salt: _salt}(
            _firstPerson,
            _secondPerson
        );

        weddings.push(wedding);
    }

    function create2AndSendEther(
        address _firstPerson,
        address _secondPerson,
        bytes32 _salt
    ) public payable {
        Wedding wedding = (new Wedding){value: msg.value, salt: _salt}(
            _firstPerson,
            _secondPerson
        );
        weddings.push(wedding);
    }

    

    function getWedding(uint256 _index)
        public
        view
        returns (
            address _firstPerson,
            address _secondPerson,
            address weddingAddr,
            uint256 balance
        )
    {
        Wedding wedding = weddings[_index];

        return (wedding.firstPerson(), wedding.secondPerson(), wedding.weddingAddr(), address(wedding).balance);
    }
}