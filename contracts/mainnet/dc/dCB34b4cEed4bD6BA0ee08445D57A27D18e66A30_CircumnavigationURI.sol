pragma solidity 0.8.4;

import "./AggregatorV3Interface.sol";
import "./ICircumnavigationURI.sol";

contract CircumnavigationURI is ICircumnavigationURI {
    struct CircumnavigationIIIUri {
        string wagmi;
        string ngmi;
    }
    // holds the uris for Circumnavigation III Gold, Silver, and Bronze (both states for each)
    CircumnavigationIIIUri[] private cIIIUris;

    AggregatorV3Interface private btcPriceFeed =
        AggregatorV3Interface(0xF4030086522a5bEEa4988F8cA5B36dbC97BeE88c);
    AggregatorV3Interface private ethPriceFeed =
        AggregatorV3Interface(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
    
    
    uint80 private roundInterval = 5; // ~once an hour

    constructor() {
        // Populates the uris for Circumnavigation III
        // index 0: gold
        cIIIUris.push(
            CircumnavigationIIIUri({
                wagmi: "https://ipfs.io/ipfs/QmZveSf2iM4FwJ5ZtioKaxFWsgg1WpfpmpX8n42dB5yd3Q",
                ngmi: "https://ipfs.io/ipfs/QmXrpgyz1JZp7LebmsPJjUEYfVC7iA99Q11GiDSZdGSdYM"
            })
        );
        // index 1: silver
        cIIIUris.push(
            CircumnavigationIIIUri({
                wagmi: "https://ipfs.io/ipfs/QmcgpNcUQPkpzHwVKPe9X6PBjgjHV87d26JwKaas6oJUYb",
                ngmi: "https://ipfs.io/ipfs/Qmc7fYRBwS9coYVYBv36D79j4v1jsWQdSS2KVwPpfY9Soo"
            })
        );
        // index 2: bronze
        cIIIUris.push(
            CircumnavigationIIIUri({
                wagmi: "https://ipfs.io/ipfs/QmbCniBY2tEQ46a5vtiuFArt8d2aeVzxpyeTdaBetVjKev",
                ngmi: "https://ipfs.io/ipfs/QmeCJf1aEhh9d56UcNFrAd9tHnVFbtSLxM2pPd66LSKYJm"
            })
        );
    }
    /**
     * get the price for 0: BTC, 1: ETH
     * This should be the only function that needs to be duplicated if Open Editions
     * and drawings are still on a separate contract
     */
    function getPrice(uint8 priceType) private view returns (uint256, uint256) {
        AggregatorV3Interface feed = priceType == 0
            ? btcPriceFeed
            : ethPriceFeed;
        // current price data
        (uint80 roundId, int256 answer, , , ) = feed.latestRoundData();
        uint256 current = uint256(answer) / (10**uint256(feed.decimals()));
        // previous price data
        (, int256 prevAnswer, , , ) = feed.getRoundData(
            roundId - roundInterval
        );
        uint256 prev = uint256(prevAnswer) / (10**uint256(feed.decimals()));
        return (prev, current);
    }
    /**
     * Returns the token uri for Circumnavigation I (OE)
     *
     */
    function cITokenURI() external view override returns (string memory) {
        (uint256 prevBTC, uint256 currentBTC) = getPrice(0);
        (uint256 prevETH, uint256 currentETH) = getPrice(1);
        // Both up
        if (currentBTC > prevBTC && currentETH > prevETH)
            return
                "https://ipfs.io/ipfs/Qmbr7w9D5gTuQyajGRxgG2xLcEQUffLXa3DcYcdweXC5ff";
        // BTC up ETH down
        if (currentBTC > prevBTC && prevETH > currentETH)
            return
                "https://ipfs.io/ipfs/QmVp3dGZbnHpzbBJP56NyDnvCWx43w3bQYYuSZ7TMpUWQZ";
        // ETH up BTC down
        if (prevBTC > currentBTC && currentETH > prevETH)
            return
                "https://ipfs.io/ipfs/QmYoeAvKYtiLoX7ASBabBS82m48zKuxa8gapBXVE35dMJB";
        // Both down
        return
            "https://ipfs.io/ipfs/QmVsmdjgL4KQFmUANhcc5PUVGkSyFyZKAaBpZKEPJHREBa";
    }
    /**
     * Returns the token uri for Circumnavigation II (GM, GA, GN)
     */
    function cIITokenURI() external view override returns (string memory) {
        uint8 hour = uint8((block.timestamp / 60 / 60) % 24);
        // GM (morning)
        if (hour >= 5 && hour < 12)
            return
                "https://ipfs.io/ipfs/QmW4iZGe7ERjtAof3ikSqya4tySHZtUZ9J31yYNLrmSMBE";
        // GA (afternoon)
        if (hour >= 12 && hour <= 17)
            return
                "https://ipfs.io/ipfs/QmNeGtVLr6GCvNrJ1wrL1M4ypdhKWViRsButyW6qkaq4TW";
        // GN (night)
        return
            "https://ipfs.io/ipfs/QmczyDnpaRshUnH9cLs6QEcqi9K4xh4aDZwavBj9UgdL7D";
    }
    /**
     * Returns the token uri for Circumnavigation III (WAGMI/NGMI)
     * niftyType 0: Gold
     * niftyType 1: Silver
     * niftyType 2: Bronze
     */
    function cIIITokenURI(uint8 niftyType) external view override returns (string memory)
    {
        (uint256 prevBTC, uint256 currentBTC) = getPrice(0);
        (uint256 prevETH, uint256 currentETH) = getPrice(1);
        if (currentBTC + currentETH >= prevBTC + prevETH)
            return cIIIUris[niftyType].wagmi;
        return cIIIUris[niftyType].ngmi;
    }

    /**
     * Returns the token uri for Circumnavigation I (one of one)
     */
    function cIOneOfOneTokenURI() external pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmUUbqDQdAXAKvXbJpNs1hk9Gbq35AEYTnoAUhbJ8NGfZC";
    }

    /**
     * Returns the token uri for Circumnavigation II (one of one)
     */
    function cIIOneOfOneTokenURI() external pure override returns (string memory) {
        return
            "https://ipfs.io/ipfs/QmcPFA4r3J9LcGXA1vCeJs86QsoiccmJhnC2joKFPod9z5";
    }
}

pragma solidity 0.8.4;

// Part: smartcontractkit/[email protected]/AggregatorV3Interface
// Interface declaration would need to be in both Open Edition and Drawings contracts
interface AggregatorV3Interface {
    function decimals() external view returns (uint8);
    function description() external view returns (string memory);
    function version() external view returns (uint256);
    // getRoundData and latestRoundData should both raise "No data present"
    // if they do not have data to report, instead of returning unset values
    // which could be misinterpreted as actual reported values.
    function getRoundData(uint80 _roundId)
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
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

pragma solidity 0.8.4;

interface ICircumnavigationURI {
    function cITokenURI() external view returns (string memory);
    function cIITokenURI() external view returns (string memory);
    function cIIITokenURI(uint8 niftyType) external view returns (string memory);    
    function cIOneOfOneTokenURI() external view returns (string memory);    
    function cIIOneOfOneTokenURI() external view returns (string memory);
}