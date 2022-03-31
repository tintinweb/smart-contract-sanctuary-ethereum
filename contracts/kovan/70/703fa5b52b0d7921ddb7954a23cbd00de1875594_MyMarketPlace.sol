/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// File: contracts/MyMarketPlace.sol

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


contract MyMarketPlace{
    
    //account that going to recieve fees over tx
    address payable private immutable _feeReciever;

    //fee percent, going to add on each item
    uint private immutable feePercentage;

    //minimum price for listing an NFT
    uint private minListingPrice= 0.00001 ether;

    //contains details of one item
    struct Item{
        uint itemId;
        IERC721 contractAddress;
        uint tokenId;
        uint price;
        address payable seller;
        bool sold;
    }
    //works as a ID for each item
    uint private _itemcounter;

    //mapps each item with a token itemId
    mapping(uint => Item) public items;

    //mapping [contractAddress][tokenId] => itemID to prevent duplicate listing
    mapping(IERC721 => mapping(uint => uint)) private _collections;
    

    //event for item listing 
    event listed(uint itemId, IERC721 contractAddress, uint tokenId,uint price ,address seller);
    //event for item purchsed
    event purchsed(uint itemId,IERC721 contractAddress, uint tokenId,address from,uint price);

    constructor (uint _feePercentage){
        _feeReciever = payable(msg.sender);
        feePercentage = _feePercentage;
    }

    function listNFTforSale(uint _price,IERC721 _contractAddress ,uint _tokenId) public{
        require(_price > minListingPrice,"minimum listing price is 0.00001 ether");
        require(_contractAddress.ownerOf(_tokenId) == msg.sender,"Owner is  required for listing");
        require(_contractAddress.isApprovedForAll(msg.sender,address(this)),"Owner should approved this marketPlace as a operator before listings");
        require(_validateAddressAndToken(_contractAddress,_tokenId),"NFT is already in sale");
        
        //increment the itemId
        _itemcounter++;
        //create an item
        Item memory item = Item(
            _itemcounter,
            _contractAddress,
            _tokenId,
            _price,
            payable(msg.sender),
            false
        );
        //add the item to items collection
        items[_itemcounter] = item;
        // assign the itemId with corresponding contract address and token id
        _collections[_contractAddress][_tokenId] = _itemcounter;

        emit listed(_itemcounter,_contractAddress,_tokenId,_price,msg.sender);
    }

    function buyNFT(uint _itemId) public payable{
        require(_itemId<=_itemcounter,"NFT is not exist");
        require(!items[_itemId].sold ,"This NFT is already sold");

        //getting the amount required including percentage fee
        uint requiredAmount = getAmount(_itemId);

        require(msg.value >= requiredAmount,"send more ether");

        Item storage item = items[_itemId];

        // transfering the NFT to the buyer
        item.contractAddress.transferFrom(item.seller,msg.sender,item.tokenId);

        //marking the item as sold
        item.sold = true;

        //forward the fund to fee reciever
        _forwardFunds();

        emit purchsed(_itemId,item.contractAddress, item.tokenId,item.seller,requiredAmount);

    }

    function getAmount(uint _itemId) private view returns(uint){         
        uint  price = items[_itemId].price;
        return (price * feePercentage) / 100;
    }

    function _validateAddressAndToken(IERC721 _contractAddress, uint _tokenId) private view returns(bool){
        //if the item is new return new
        if(_collections[_contractAddress][_tokenId]==0){
            return true;
        }
        uint itemId = _collections[_contractAddress][_tokenId]; 
        Item memory item = items[itemId];
        // if the item is alreay sold return true else false
        return item.sold == true;
    }

    function _forwardFunds() private {
        _feeReciever.transfer(msg.value);
    }
}