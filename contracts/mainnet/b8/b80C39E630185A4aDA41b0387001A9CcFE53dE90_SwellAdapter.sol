/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: None
pragma solidity 0.8.0;

interface DIA {
    function getValue(string memory key)
        external
        view
        returns (uint128, uint128);
}

contract SwellAdapter {
    address public diaOracleAddress;
    address public owner;

    constructor (
        address _diaOracleAddress
    ) {
        diaOracleAddress = _diaOracleAddress;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function _changeOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function updateDIAOracleAddress(address newDIAOracleAddress) external onlyOwner {
        diaOracleAddress = newDIAOracleAddress;
    }

    // retrieves swETH price in ETH with 8 decimals
    function getSwEthPriceEth() public view returns (uint256) {
        return (getSwEthPriceUSD()*1e8) / getEthPriceUSD();
    }

    // retrieves ETH price in USD with 8 decimals
    function getEthPriceUSD() public view returns (uint256) {
        (uint256 priceinusd, ) = DIA(diaOracleAddress).getValue("ETH/USD");
        return priceinusd;
    }

    // retrieves swETH price in USD with 8 decimals
    function getSwEthPriceUSD() public view returns (uint256) {
        (uint256 priceinusd, ) = DIA(diaOracleAddress).getValue("swETH/USD");
        return priceinusd;
    }
}