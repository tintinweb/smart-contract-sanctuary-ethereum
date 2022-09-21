/**
 *Submitted for verification at Etherscan.io on 2022-09-21
*/

// // SPDX-License-Identifier: MIT
pragma solidity >=0.8.1;

contract PriceKeeper {
    uint8 constant PRICE_DIFF = 200; // 200 base points = 2%

    event PriceUpdate(
        string indexed _id,
        uint256 _timestamp,
        string _name,
        uint256 _price
    );

    mapping(string => uint256) public prices;

    function set(
        string memory _id,
        string memory _name,
        uint256 _value
    ) public {
        require(_value > 0, "Price cannot be 0");

        if (prices[_id] > 0) {
            require(
                hasPriceChanged(prices[_id], _value),
                "Price has changed too little"
            );
        }

        prices[_id] = _value;
        emit PriceUpdate(_id, block.timestamp, _name, _value);
    }

    function hasPriceChanged(uint256 _oldVal, uint256 _newVal)
        internal
        pure
        returns (bool)
    {
        uint256 diff = _oldVal >= _newVal
            ? _oldVal - _newVal
            : _newVal - _oldVal;

        // Using base points instead of regular percentages
        uint256 percentage = (diff * 10000) / _oldVal;

        return percentage >= PRICE_DIFF;
    }
}