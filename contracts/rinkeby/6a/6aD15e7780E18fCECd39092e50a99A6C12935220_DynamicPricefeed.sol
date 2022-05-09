// SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;
 import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
 import "@openzeppelin/contracts/utils/Strings.sol";
 

 contract DynamicPricefeed{
     using Strings for uint;
     constructor(){
         priceFeeds["ATOM / ETH"]=0xc751E86208F0F8aF2d5CD0e29716cA7AD98B5eF5;
         priceFeeds["ATOM / USD"]=0x3539F2E214d8BC7E611056383323aC6D1b01943c;
         priceFeeds["AUD / USD"]=0x21c095d2aDa464A294956eA058077F14F66535af;
     }

     mapping(string=>address) priceFeeds;

     function getPrice(string memory _tokenSymbol) external view returns(int){
        //  (
        //     /*uint80 roundID*/,
        //     int price,
        //     /*uint startedAt*/,
        //     /*uint timeStamp*/,
        //     /*uint80 answeredInRound*/
        // ) = AggregatorV3Interface(priceFeeds[_tokenSymbol]).latestRoundData();

        try AggregatorV3Interface(priceFeeds[_tokenSymbol]).latestRoundData() returns(uint80 roundID,int price,uint startedAt,uint timeStamp,uint80 answeredInRound){
            return price;
        } catch{
            revert();
            
        }
        
     }

     function setPriceFeedAddress(string memory _symbol, address _priceFeedAddress) external{
         priceFeeds[_symbol]=_priceFeedAddress;
     }

     function revert() private pure returns(string memory){
         return "Price feed address and symbol has added to  contract.set price feed address and symbol first";
     }

 }

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}