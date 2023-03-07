// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.4;

contract BonusRateLockUp {

    struct BonusRates {
        uint8 intervalWeeks;
        uint16[] rates;
    }

    uint256 public id;
    mapping(uint256 => BonusRates) public bonusRates;

    event CreatedBonusRates(uint256 _id, uint8 _intervalWeeks);

    constructor() {}

    function createBonusRates (
        uint8 _intervalWeeks,
        uint16[] calldata _rates
    ) external {
        require(_intervalWeeks != 0, "zero _intervalWeeks");
        require(_rates.length != 0, "rates is empty");
        id++;

        bonusRates[id] = BonusRates({
            intervalWeeks: _intervalWeeks,
            rates: new uint16[](_rates.length)
        });

        bonusRates[id].rates = _rates;

        emit CreatedBonusRates(id, _intervalWeeks);
    }

    function getRatesInfo(uint256 _id) public view returns (BonusRates memory) {
        return bonusRates[_id];
    }

    function getRatesByIndex(uint256 _id, uint256 index) public view returns (uint16 rate) {

        BonusRates memory _rates = bonusRates[_id];

        if (_rates.intervalWeeks != 0 || index < _rates.rates.length) {
            rate = _rates.rates[index];
        }
    }

    function getRatesByWeeks(uint256 _id, uint8 _weeks) public view returns (uint16 rate) {

        BonusRates memory _rates = bonusRates[_id];

        if (_rates.intervalWeeks != 0 ) {
            uint8 index = _weeks / _rates.intervalWeeks;
            if (index < _rates.rates.length) rate = _rates.rates[index];
        }
    }

}