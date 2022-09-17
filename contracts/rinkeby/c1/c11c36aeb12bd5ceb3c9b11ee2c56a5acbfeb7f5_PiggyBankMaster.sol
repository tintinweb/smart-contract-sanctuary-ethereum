/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IPiggyBankObserver {
    function handlePiggyBankCreated(
        address _owner,
        address _newPiggyBank
    ) external;
}

contract PiggyBankMaster is IPiggyBankObserver {
    struct PiggyBankDetails {
        address piggyBankAddress;
        string piggyBankType;
    }

    mapping(address => bool) private factories;
    mapping(string => bool) private piggyBankTypes;
    mapping(address => string) private factoryTypes;

    mapping(address => PiggyBankDetails[]) piggyBanksByOwner;

    function registerPiggyBankFactory(
        string memory _piggyBankType,
        address _factory
    ) external {
        // TODO:  Add authorizatoin check.
        require(!factories[_factory], "Factory is already registered!");
        require(!piggyBankTypes[_piggyBankType], "Piggy bank type is already in use!");

        factories[_factory] = true;
        piggyBankTypes[_piggyBankType] = true;
        factoryTypes[_factory] = _piggyBankType;
    }

    function handlePiggyBankCreated(
        address _owner,
        address _newPiggyBank
    ) override external {
        require(factories[msg.sender], "Not a known factory!");

        piggyBanksByOwner[_owner].push(PiggyBankDetails({
            piggyBankAddress: _newPiggyBank,
            piggyBankType: factoryTypes[msg.sender]
        }));
    }

    function getPiggyBanksByOwner(
        address _owner
    ) external view returns (PiggyBankDetails[] memory) {
        return piggyBanksByOwner[_owner];
    }
}