//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AmountPiggyBank.sol";
import "./PiggyBank.sol";
import "./TimePiggyBank.sol";

contract PiggyBankFactory {
    mapping(address => address[]) private addressToPiggyBanks;
    mapping(address => bool) private piggyBanks;

    function createTimePiggyBank(
        address _owner,
        string memory _desc,
        uint64 _endTime
    ) public returns (address) {
        address newTimePiggyBank = address(new TimePiggyBank(_owner, _desc, _endTime));
        _registerPiggyBank(_owner, newTimePiggyBank);
        return newTimePiggyBank;
    }

    function createAmountPiggyBank(
        address _owner,
        string memory _desc,
        uint256 _targetAmount
    ) public returns (address) {
        address newAmountPiggyBank = address(new AmountPiggyBank(_owner, _desc, _targetAmount));
        _registerPiggyBank(_owner, newAmountPiggyBank);
        return newAmountPiggyBank;
    }

    function getPiggyBanksByAddress(address _address) public view returns (address[] memory) {
        return addressToPiggyBanks[_address];
    }

    function registerPiggyBank(address _address) public {
        require(!piggyBanks[_address], "Already registered!");

        PiggyBank piggyBank = PiggyBank(_address);
        address owner = piggyBank.owner();
        require(owner == msg.sender, "You are not an owner!");

        _registerPiggyBank(owner, _address);
    }

    function _registerPiggyBank(address _owner, address _piggyBank) private {
        addressToPiggyBanks[_owner].push(_piggyBank);
        piggyBanks[_piggyBank] = true;
    }
}