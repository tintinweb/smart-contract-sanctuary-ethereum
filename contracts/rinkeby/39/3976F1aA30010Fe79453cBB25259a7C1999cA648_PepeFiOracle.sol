/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

pragma solidity ^0.8.9;

contract PepeFiOracle {
    event OracleUpdate(address collection, uint256 value, uint256 timestamp);
    mapping (address => uint256) public prices;

    address updater;

    modifier onlyUpdater {
        require(msg.sender == updater);
        _;
    }

    constructor(address _updater) {
        updater = _updater;
    }

    function updatePrices(address[] calldata _collections, uint256[] calldata _values) public onlyUpdater{

        require(_collections.length == _values.length, "The length of two arrays must be same");

        for (uint i=0; i<_collections.length; i++) {
            prices[_collections[i]] = _values[i];
            emit OracleUpdate(_collections[i], _values[i], block.timestamp);
        }
    }

    function getPrice(address _collection) public view returns (uint256) {
        return prices[_collection];
    }
}