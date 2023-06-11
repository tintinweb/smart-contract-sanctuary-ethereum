/**
 *Submitted for verification at Etherscan.io on 2023-06-11
*/

// File: dotApe/implementations/addressesImplementation.sol


pragma solidity ^0.8.7;

interface IApeAddreses {
    function owner() external view returns (address);
    function getDotApeAddress(string memory _label) external view returns (address);
}

pragma solidity ^0.8.7;

abstract contract apeAddressesImpl {
    address dotApeAddresses;

    constructor(address addresses_) {
        dotApeAddresses = addresses_;
    }

    function setAddressesImpl(address addresses_) public onlyOwner {
        dotApeAddresses = addresses_;
    }

    function owner() public view returns (address) {
        return IApeAddreses(dotApeAddresses).owner();
    }

    function getDotApeAddress(string memory _label) public view returns (address) {
        return IApeAddreses(dotApeAddresses).getDotApeAddress(_label);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyRegistrar() {
        require(msg.sender == getDotApeAddress("registrar"), "Ownable: caller is not the registrar");
        _;
    }

    modifier onlyErc721() {
        require(msg.sender == getDotApeAddress("erc721"), "Ownable: caller is not erc721");
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == getDotApeAddress("team"), "Ownable: caller is not team");
        _;
    }

}
// File: dotApe/priceOracle.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function latestAnswer() external view returns (int256);
}

pragma solidity ^0.8.7;


contract dotApePriceOracle is apeAddressesImpl {
    AggregatorV3Interface internal ethPriceFeed;
    AggregatorV3Interface internal apecoinPriceFeed;

    constructor(address _addresses) apeAddressesImpl(_addresses) {
        ethPriceFeed = AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        apecoinPriceFeed = AggregatorV3Interface(0xD10aBbC76679a20055E167BB80A24ac851b37056);
        uint256[] memory costs = new uint256[](4); // Specify the size as 4
        costs[0] = 640;
        costs[1] = 120;
        costs[2] = 50;
        costs[3] = 10;
        usdCosts = costs;
    }

    uint256[] private usdCosts;

    function getEthPrice() public view returns (uint256) {
        return uint256(ethPriceFeed.latestAnswer());
        //return 181395532974;
    }

    function getApecoinPrice() public view returns (uint256) {
        return uint256(apecoinPriceFeed.latestAnswer());
        //return 298060000;
    }

    function getCost(string memory name, uint256 durationInYears) public view returns (uint256) {
        uint256 _usdCost = getPriceUsd(name);
        uint256 _ethPrice = uint256(getEthPrice());
        uint256 cost = _usdCost * ( 1e18 / _ethPrice ) * durationInYears * 1e8;
        return cost;
    }

    function getCostUsd(string memory name, uint256 durationInYears) public view returns (uint256) {
        uint256 _usdCost = getPriceUsd(name);
        return _usdCost * durationInYears * 1e6;
    }

    function getCostApecoin(string memory name, uint256 durationInYears) public view returns (uint256) {
        uint256 _usdCost = getPriceUsd(name);
        uint256 _apecoinPrice = uint256(getApecoinPrice());
        uint256 cost = _usdCost * ( 1e18 / _apecoinPrice ) * durationInYears * 1e8;
        return cost;
    }

    function getPriceUsd(string memory _name) public view returns (uint256) {
        bytes memory b = bytes(_name);
        if(b.length == 3) return usdCosts[0];
        else if(b.length == 4) return usdCosts[1];
        else if(b.length == 5) return usdCosts[2];
        else return usdCosts[3];
    }

    function setPricesUsd(uint256[] memory _costs) public onlyOwner {
        usdCosts = _costs;
    }
}