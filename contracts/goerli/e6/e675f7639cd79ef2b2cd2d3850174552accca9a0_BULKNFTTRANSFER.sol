/**
 *Submitted for verification at Etherscan.io on 2022-12-01
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
interface IERC1155 is IERC165{
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);
    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );
    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);
    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);
    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);
    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);
    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;
    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);
    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}






contract BULKNFTTRANSFER   {
    
    IERC721 public contractAddress;
    IERC1155 public contractAddress1155;
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
    function bulkTransferForMultipleRecievers(address []memory _contractAddress,address[] memory _recieverAddresses,uint [] memory _ids)public payable   { 
        uint length=_recieverAddresses.length;
        for(uint i=0; i<length; i++){
            address nftAddress=_contractAddress[i];
            contractAddress= IERC721(nftAddress);
            contractAddress.transferFrom(msg.sender,_recieverAddresses[i],_ids[i]);
           
        }
    }
    function bulkTransferForMultipleRecieversERC1155(address []memory _contractAddress,address[] memory _recieverAddresses,uint [] memory _ids,uint [] memory _quantity)public payable   { 
        uint length=_recieverAddresses.length;
        for(uint i=0; i<length; i++){
            address nftAddress=_contractAddress[i];
            contractAddress1155= IERC1155(nftAddress);
            contractAddress1155.safeTransferFrom(msg.sender,_recieverAddresses[i],_ids[i],_quantity[i],"");
           
        }
    }
    function bulkTransferForSingleRecieversERC1155(address []memory _contractAddress,address _recieverAddress,uint [] memory _ids,uint [] memory _quantity)public payable   { 
        uint length=_contractAddress.length;
        for(uint i=0; i<length; i++){
            address nftAddress=_contractAddress[i];
            contractAddress1155= IERC1155(nftAddress);
            contractAddress1155.safeTransferFrom(msg.sender,_recieverAddress,_ids[i],_quantity[i],"");
           
        }
    }


function getTokenType(address _assetContract) public  view returns (uint) {
            if(IERC165(_assetContract).supportsInterface(type(IERC721).interfaceId))
            {
                return 1;
            }else if (IERC165(_assetContract).supportsInterface(type(IERC1155).interfaceId)) {
                return 2;
            }
            else {
            revert("token must be ERC1155 or ERC721.");
        }
  }

   
}