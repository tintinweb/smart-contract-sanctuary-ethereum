/**
 *Submitted for verification at Etherscan.io on 2022-10-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

interface PnsAddressesInterface {
    function owner() external view returns (address);
    function getPnsAddress(string memory _label) external view returns(address);
}

pragma solidity 0.8.7;

abstract contract PnsAddressesImplementation is PnsAddressesInterface {
    address private PnsAddresses;
    PnsAddressesInterface pnsAddresses;

    constructor(address addresses_) {
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function setAddresses(address addresses_) public {
        require(msg.sender == owner(), "Not authorized.");
        PnsAddresses = addresses_;
        pnsAddresses = PnsAddressesInterface(PnsAddresses);
    }

    function getPnsAddress(string memory _label) public override view returns (address) {
        return pnsAddresses.getPnsAddress(_label);
    }

    function owner() public override view returns (address) {
        return pnsAddresses.owner();
    }
}

pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

pragma solidity ^0.8.7;

contract pnsPricesOracle is PnsAddressesImplementation {

    AggregatorV3Interface internal ethPriceFeed;
    uint256[] private usdCosts;

    constructor(address addresses_,address ethOracleAddress_, uint256[] memory costs_) PnsAddressesImplementation(addresses_) {
        ethPriceFeed = AggregatorV3Interface(ethOracleAddress_);
        usdCosts = costs_;
    }

    function setEthOracle(address oracleAddress) public {
        require(msg.sender == owner(), "Not authorized.");
        ethPriceFeed = AggregatorV3Interface(oracleAddress);
    }

    function getEthPrice() public view returns (int) {
        //(
        //    /*uint80 roundID*/,
        //    int price,
        //    /*uint startedAt*/,
        //    /*uint timeStamp*/,
        //    /*uint80 answeredInRound*/
        //) = ethPriceFeed.latestRoundData();
        //return price;
        return 133544739080;
    }


    function getEthCost(string memory _name, uint256 expiration) public view returns (uint256) {
        uint256 _usdCost = getUsdCost(_name);
        uint256 _ethPrice = uint256(getEthPrice());
        uint256 cost = _usdCost * ( 1e18 / _ethPrice ) * expiration * 1e8;
        return cost;
    }

    function getUsdCost(string memory _name) public view returns (uint256) {
        bytes memory b = bytes(_name);
        if(b.length == 3) return usdCosts[0];
        else if(b.length == 4) return usdCosts[1];
        else if(b.length == 5) return usdCosts[2];
        else return usdCosts[3];
    }

    function setUsdCosts(uint256[] memory _costs) public {
        require(msg.sender == owner(), "Not authorised");
        usdCosts = _costs;
    }

}