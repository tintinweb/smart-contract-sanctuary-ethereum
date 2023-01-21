/**
 *Submitted for verification at Etherscan.io on 2023-01-21
*/

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


library MyLibary {
    

    function getLatestPrice(address address_AggregatorV3Interface) internal view returns (int256) {
        (,int256 price,,,) = AggregatorV3Interface(address_AggregatorV3Interface).latestRoundData();
        return price;
    }

    function getLatestEasyPrice(uint256 amountEth,address address_AggregatorV3Interface) internal view returns (uint256) {
        (,int256 price,,,) = AggregatorV3Interface(address_AggregatorV3Interface).latestRoundData();
        uint256 returnvalue= uint256(price);
        returnvalue =(returnvalue*amountEth/1e8);
        return returnvalue;
    }

    function getVersion(address address_AggregatorV3Interface) internal view returns (uint256) {
        return AggregatorV3Interface(address_AggregatorV3Interface).version();
    }
}
//Erorr Codes
//Interfaces , Libraries,Contracts



 /**@title A contract for Funding
  * @author Bach Duc
  * @notice this contract is the demo 
  * @dev This implements price feed from chainlink as a libary
  */
contract FundMe {
    //Type Declarations
     using MyLibary for uint256;
    //State Variables
    address public immutable owner ;
    address public address_AggregatorV3Interface;
    address[] public funders;
    mapping(address => uint256) public adresstoamount;

    //Events
    //...
    //Modifiers
    modifier OnlyOwner{
            require(msg.sender==owner, "My message: You are not the Owner contract!");
            _;
    }
    //Functions

    constructor(address _address_AggregatorV3Interface){
        owner = msg.sender;
        address_AggregatorV3Interface=_address_AggregatorV3Interface;
    }

    receive () external payable{
       Fund();
    }

    fallback() external payable{
        Fund();
    }

    /**
    * @notice This function Funding to the contract
    * @dev This implements price feed from chainlink as a libary
    */

    function Fund() public payable {
        require(
            (msg.value.getLatestEasyPrice(address_AggregatorV3Interface)) / 1e18 >= 0,
                "My message:The Amount ETH to run no enought !"
        );
        funders.push(msg.sender);
        //using below if want save ETH
        // adresstoamount[msg.sender] = msg.value / 1e18; 
        adresstoamount[msg.sender] = msg.value;
    }

    function Withdraw() public OnlyOwner{
        for (uint256 i = 0; i < funders.length; i++) {
            adresstoamount[funders[i]] = 0;
        }
        funders = new address[](0);
        (bool Callsuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        if(Callsuccess!=true){revert();}
    }

    function get_address_AggregatorV3Interface() public view returns (address) {
            return address_AggregatorV3Interface;
    }


    function get_Funded(address funder) public view  returns (uint256) {
        return adresstoamount[funder];
    }

  

    function get_adresstoamount() public view returns (address[] memory,uint256[] memory){
    address[] memory Funderaddress= funders ;
    uint256[] memory Funderbalance= new uint256[](funders.length) ;
    for (uint256 i = 0; i < Funderaddress.length; i++) {
        Funderbalance[i]= (adresstoamount[Funderaddress[i]]);
    }
      return (Funderaddress,Funderbalance);
    }
    
}