/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-14
*/

/**
░▒█▀▀▄░▀█▀░▒█▀▀█░▒█░▒█░▒█▀▀▀░▒█▀▀▄░▒█▀▀▀█
░▒█░░░░▒█░░▒█▄▄█░▒█▀▀█░▒█▀▀▀░▒█▄▄▀░░▀▀▀▄▄
░▒█▄▄▀░▄█▄░▒█░░░░▒█░▒█░▒█▄▄▄░▒█░▒█░▒█▄▄▄█
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
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

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {



    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval( address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner,address indexed operator,bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from,address to,uint256 tokenId) external;
    function transferFrom(address from,address to,uint256 tokenId) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator)external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

contract BULKNFTTRANSFER   {
    
    IERC721 public contractAddress;
    AggregatorV3Interface internal priceFeed;
    uint price=1;
    uint ethPrice=1000;
    constructor()  {
        priceFeed = AggregatorV3Interface(0xA39434A63A52E749F02807ae27335515BA4b07F7);
    }
    function _getLatestPrice() public  view returns (uint) {
        // (
        //     /*uint80 roundID*/,
        //     int price,
        //     /*uint startedAt*/,
        //     /*uint timeStamp*/,
           
        // ) = priceFeed.latestRoundData();
       
       uint256  a= (price*10**18/ethPrice*10**18);
    return   a;

    }
    function bulkTransfer(address []memory _contractAddress,address[] memory _accounts,uint [] memory _ids)public payable   { 
        uint length=_accounts.length;
        for(uint i=0; i<length; i++){
            address nftAddress=_contractAddress[i];
            contractAddress= IERC721(nftAddress);
            contractAddress.transferFrom(msg.sender,_accounts[i],_ids[i]);
           
        }
    }

   
}