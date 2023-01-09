// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title NotarizerWeb
/// @author ZirconTech
/// @notice It allows you to notarize IPFS CIDs in an easy way, charging a pretty small fee.
/// @dev It allows you to notarize IPFS CIDs in an easy way, charging a pretty small fee.

library PriceConverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // PAIR TK1/TK2 rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 tokenAmount,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        uint256 tokenPrice = getPrice(priceFeed);
        uint256 tokenAmountInUsd = (tokenPrice * tokenAmount) /
            1000000000000000000;
        // the actual token/USD conversation rate, after adjusting the extra 0s.
        return tokenAmountInUsd;
    }
}

contract NotarizerWeb {
    // State Variables
    using PriceConverter for uint256;
    mapping(uint256 => Content) public contents;
    mapping(string => bool) public notarizedHashes;
    uint256 public contentId;
    address constant ZIRCON_WALLET = 0x3099a9d5a86e16Cd363c2CD8867F5b3035f6F5D7; // testing wallet
    AggregatorV3Interface public s_priceFeed;
    // Events
    event Notarize(
        address indexed _notary,
        string indexed _ipfsHash,
        string indexed _tag
    );
    // Modifiers
    modifier onlyValidHashed(string memory s) {
        bytes memory b = bytes(s);
        require(b.length == 46, "This is not an accepted IpfsHash");
        require(
            (b[0] == "Q" && b[1] == "m"),
            "Invalid IpfsHash, must be a CIDv0"
        );
        _;
    }

    struct Content {
        uint256 contentId;
        string ipfsHash;
        address notary;
    }

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    // Functions
    function withdrawCollectedFees(uint _amount) external {
        require(msg.sender == ZIRCON_WALLET, "only ZirconTech can withdraw");
        require(address(this).balance >= _amount, "request exceeds balance");
        (bool sent, bytes memory data) = ZIRCON_WALLET.call{value: (_amount)}(
            ""
        );
        require(sent, "Failed to send Ether");
    }

    function notarizeCID(
        string memory _ipfsHash,
        string memory _tag
    ) public payable onlyValidHashed(_ipfsHash) returns (uint256) {
        uint fee = _getFee();
        require(msg.value >= fee, "Must cover fee value");
        require(notarizedHashes[_ipfsHash] == false, "Already notarized");
        contentId++;
        // Notarization logic
        Content memory content;
        content.contentId = contentId;
        content.ipfsHash = _ipfsHash;
        content.notary = msg.sender;

        contents[contentId] = content;
        notarizedHashes[_ipfsHash] = true;

        emit Notarize(msg.sender, _ipfsHash, _tag);

        return contentId;
    }

    function getIpfsHash(uint _contentId) public view returns (string memory) {
        Content memory content;
        content = contents[_contentId];
        string memory ipfsHash = content.ipfsHash;
        return ipfsHash;
    }

    function isHashNotarized(
        string memory _ipfsHash
    ) public view onlyValidHashed(_ipfsHash) returns (bool) {
        return notarizedHashes[_ipfsHash];
    }

    function _getFee() internal view returns (uint256) {
        // Logic for updating fee goes here
        // currentFee expressed in wei
        uint256 minimumUSD = 2 * 10 ** 18; // Equivalent to 2 dollars
        uint currentFee = minimumUSD.getConversionRate(s_priceFeed);
        // uint currentFee = 100000000000000; // Equivalent to 0.0001 Ether
        return currentFee;
    }
}