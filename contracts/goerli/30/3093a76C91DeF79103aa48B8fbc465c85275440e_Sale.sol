// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "./Common/Trade.sol";
import "./Common/ISale.sol";

//-----------------------------------------
// Sale
//-----------------------------------------
contract Sale is Trade, ISale {
    //-------------------------------------------
    // constant
    //-------------------------------------------
    // ID offset
    uint256 constant private SALE_ID_OFS = 1;

    // I don't want to use a structure, so I manage it with an array of [uint256]
    uint256 constant private SALE_DATA_CONTRACT_ADDRESS         = 0;    // Contract address(address)
    uint256 constant private SALE_DATA_TOKEN_ID                 = 1;    // Token ID
    uint256 constant private SALE_DATA_SELLER                   = 2;    // Seller (address)
    uint256 constant private SALE_DATA_PRICE                    = 3;    // Price
    uint256 constant private SALE_DATA_INFO                     = 4;    // Information
    uint256 constant private SALE_DATA_SIZE                     = 5;    // Data size

    // [SALE_DATA_INFO] Operation: Flag
    uint256 constant private SALE_DATA_INFO_FLAG_ACTIVE         = 0x8000000000000000000000000000000000000000000000000000000000000000; // Is it active?
    uint256 constant private SALE_DATA_INFO_FLAG_SOLD_OUT       = 0x4000000000000000000000000000000000000000000000000000000000000000; // Has it been sold?
    uint256 constant private SALE_DATA_INFO_FLAG_CANCELED       = 0x2000000000000000000000000000000000000000000000000000000000000000; // Has it been canceled?
    uint256 constant private SALE_DATA_INFO_FLAG_INVALID        = 0x1000000000000000000000000000000000000000000000000000000000000000; // Was it disabled?

    // [SALE_DATA_INFO] Operation: Buyer
    uint256 constant private SALE_DATA_INFO_BUYER_SHIFT         = 0;
    uint256 constant private SALE_DATA_INFO_BUYER_MASK          = 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF; // uint160: Buyer (address)

    // [SALE_DATA_INFO] Operation: Sales period
    uint256 constant private SALE_DATA_INFO_EXPIRE_DATE_SHIFT   = 160;
    uint256 constant private SALE_DATA_INFO_EXPIRE_DATE_MASK    = 0x00000000FFFFFFFFFFFFFFFF0000000000000000000000000000000000000000; // uint64: End of sale date and time

    //-----------------------------------------
    // storage
    //-----------------------------------------
    mapping( uint256 => mapping( uint256 => uint256 ) ) private _latestId;
     mapping( uint256 => uint256 )  public getSaleid;
    uint256[SALE_DATA_SIZE][] private _sales;

    //-----------------------------------------
    // constructor
    //-----------------------------------------
    constructor() Trade() {
    }

    //-----------------------------------------------
    // [public] Data acquisition: Premise that a valid saleId comes
    //-----------------------------------------------
    function saleContractAddress( uint256 saleId ) public view returns (address) {
        return( address((uint160(_sales[saleId-SALE_ID_OFS][SALE_DATA_CONTRACT_ADDRESS]))) );
    }

    function saleTokenId( uint256 saleId ) public view returns (uint256) {
        return( _sales[saleId-SALE_ID_OFS][SALE_DATA_TOKEN_ID] );
    }

    function saleSeller( uint256 saleId ) public view returns (address) {
        return( address((uint160(_sales[saleId-SALE_ID_OFS][SALE_DATA_SELLER]))) );
    }

    function salePrice( uint256 saleId ) public view returns (uint256) {
        return( _sales[saleId-SALE_ID_OFS][SALE_DATA_PRICE] );
    }

    function saleBuyer( uint256 saleId ) public view returns (address) {
        return( address(uint160((_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_BUYER_MASK) >> SALE_DATA_INFO_BUYER_SHIFT)) );
    }

    function saleExpireDate( uint256 saleId ) public view returns (uint256) {
        return( (_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_EXPIRE_DATE_MASK) >> SALE_DATA_INFO_EXPIRE_DATE_SHIFT );
    }

    function saleIsActive( uint256 saleId ) public view returns (bool) {
        return( (_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_FLAG_ACTIVE) != 0);
    }

    function saleIsSoldOut( uint256 saleId ) public view returns (bool) {
        return( (_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_FLAG_SOLD_OUT) != 0);
    }

    function saleIsCanceled( uint256 saleId ) public view returns (bool) {
        return( (_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_FLAG_CANCELED) != 0);
    }

    function saleIsInvalid( uint256 saleId ) public view returns (bool) {
        return( (_sales[saleId-SALE_ID_OFS][SALE_DATA_INFO] & SALE_DATA_INFO_FLAG_INVALID) != 0);
    }

    //----------------------------------------------
    // [external/onlyMarket] Sales start
    //----------------------------------------------
    function sell( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external override onlyMarket{
        // Fail if there is valid data for sale
        require( ! _alive( uint256(uint160(contractAddress)), tokenId, msgSender ), "existent alive sale" );

        // Is the owner valid?
        IERC721 tokenContract = IERC721( contractAddress );
        address owner = tokenContract.ownerOf( tokenId );
        require( owner == msgSender, "sender is not the owner" );

        // Is the price valid?
        require( _checkPrice( price ), "invalid price" );

        // Is the period valid?
        require( _checkPeriod( period ), "invalid period" );

        //------------
        // Check completed
        //------------

        uint256 saleId = SALE_ID_OFS + _sales.length;

        uint256 expireDate;
        if( period == 0 ){
            expireDate = 0;
        }else{
            expireDate = block.timestamp + period;
        }

        uint256[SALE_DATA_SIZE] memory words;
        words[SALE_DATA_CONTRACT_ADDRESS] = uint256(uint160(contractAddress));
        words[SALE_DATA_TOKEN_ID] = tokenId;
        words[SALE_DATA_SELLER] = uint256(uint160(msgSender));
        words[SALE_DATA_PRICE] = price;
        words[SALE_DATA_INFO] |= (expireDate << SALE_DATA_INFO_EXPIRE_DATE_SHIFT) & SALE_DATA_INFO_EXPIRE_DATE_MASK;

        // Flag setting (active)
        words[SALE_DATA_INFO] |= SALE_DATA_INFO_FLAG_ACTIVE;

        _sales.push( words );
         getSaleid[tokenId]=saleId;
        // Linking the latest information (suppressing relisting)
        _latestId[words[SALE_DATA_CONTRACT_ADDRESS]][words[SALE_DATA_TOKEN_ID]] = saleId;

        // event
        emit Sale( contractAddress, tokenId, msgSender, price, expireDate, saleId );
    }

    //----------------------------------------------
    // [external/onlyMarket] selling discontinued
    //----------------------------------------------
    function cancelSale( address msgSender, uint256 saleId ) external override onlyMarket{
        require( _exists( saleId ), "nonexistent sale" );

        // I don't see any invalidation here (there is no problem with the discontinuation of sales)

        // Is it active?
        require( saleIsActive( saleId ), "not active sale" );

        // Are you an exhibitor?
        require( msgSender == saleSeller( saleId ), "mismatch seller" );

        //------------
        // Check completed
        //------------

        uint256 dataId = saleId - SALE_ID_OFS;
        uint256[SALE_DATA_SIZE] memory words = _sales[dataId];

        // Flag setting (deactivated and canceled)
        words[SALE_DATA_INFO] &= ~SALE_DATA_INFO_FLAG_ACTIVE;
        words[SALE_DATA_INFO] |= SALE_DATA_INFO_FLAG_CANCELED;

        // Update
        _sales[dataId] = words;

        // event
        emit SaleCanceled( saleId, saleContractAddress( saleId ), saleTokenId( saleId ), msgSender );
    }

    //--------------------------------------------------------------
    // [external/onlyMarket] Purchase (payment and NFT processing is left to the caller)
    //--------------------------------------------------------------
    function buy( address msgSender, uint256 saleId, uint256 amount ) external override onlyMarket{
        require( _exists( saleId ), "nonexistent sale" );

        // Is it disabled? (If it is invalidated, the transaction will not be completed)
        require( ! saleIsInvalid( saleId ), "invalid sale" );

        // Is it active?
        require( saleIsActive( saleId ), "not active sale" );

        // Is the owner valid?
        IERC721 tokenContract = IERC721( saleContractAddress( saleId ) );
        address owner = tokenContract.ownerOf( saleTokenId( saleId ) );
        require( owner != msgSender, "sender is the owner" );
        require( owner == saleSeller( saleId ), "mismatch seller" );

        // Confirm payment
        uint256 price = salePrice( saleId );
        require( price <= amount, "Insufficient amount" );

        // Period judgment
        uint256 expireDate = saleExpireDate( saleId );
        require( expireDate == 0 || expireDate > block.timestamp, "expired" );

        //------------
        // Check completed
        //------------

        uint256 dataId = saleId - SALE_ID_OFS;
        uint256[SALE_DATA_SIZE] memory words = _sales[dataId];

        // Flag setting (deactivated and sold)
        words[SALE_DATA_INFO] &= ~SALE_DATA_INFO_FLAG_ACTIVE;
        words[SALE_DATA_INFO] |= SALE_DATA_INFO_FLAG_SOLD_OUT;

        // Buyer settings
        uint256 buyer = uint256( uint160(msgSender) );
        buyer = (buyer<<SALE_DATA_INFO_BUYER_SHIFT) & SALE_DATA_INFO_BUYER_MASK;
        words[SALE_DATA_INFO] &= ~SALE_DATA_INFO_BUYER_MASK;
        words[SALE_DATA_INFO] |= buyer;

        // Update
        _sales[dataId] = words;

        // event
        emit Sold( saleId, saleContractAddress( saleId ), saleTokenId( saleId ), owner, msgSender, price );
    }

    //----------------------------------------------
    // [external/onlyOwner] Disable sales
    //----------------------------------------------
    function invalidateSales( uint256[] calldata saleIds ) external override onlyOwner {
        for( uint256 i=0; i<saleIds.length; i++ ){
            uint256 saleId = saleIds[i];

            // If enabled and not yet disabled
            if( _exists( saleId ) && ! saleIsInvalid( saleId ) ){
                uint256 dataId = saleId - SALE_ID_OFS;
                uint256[SALE_DATA_SIZE] memory words = _sales[dataId];

                // Flag setting(ACTIVE does not sleep)
                words[SALE_DATA_INFO] |= SALE_DATA_INFO_FLAG_INVALID;

                // Update
                _sales[dataId] = words;

                // event
                emit SaleInvalidated( saleId, saleContractAddress( saleId ), saleTokenId( saleId ), saleSeller( saleId ) );
            }
        }
    }

    //----------------------------------------------
    // [external] Token transfer information
    //----------------------------------------------
    function transferInfo( uint256 saleId ) external view override returns (uint256[4] memory){
        require( _exists( saleId ), "nonexistent sale" );

        // See [ITrade.sol] for a breakdown of words
        uint256[4] memory words;
        words[0] = uint256(uint160(saleContractAddress( saleId )));
        words[1] = saleTokenId( saleId );
        words[2] = uint256(uint160(saleSeller( saleId )));
        words[3] = uint256(uint160(saleBuyer( saleId )));

        return( words );
    }

    //----------------------------------------------
    // [external] Get payment information
    //----------------------------------------------
    function payInfo( uint256 saleId ) external view override returns (uint256[3] memory){
        require( _exists( saleId ), "nonexistent sale" );

        // See [ITrade.sol] for a breakdown of words
        uint256[3] memory words;
        words[0] = uint256(uint160(saleSeller( saleId )));
        words[1] = uint256(uint160(saleContractAddress( saleId )));
        words[2] = salePrice( saleId );

        return( words );
    }

    //---------------------------------------------------
    // [externa] Acquisition of refund information (unnecessary because there is no concept of deposit)
    //---------------------------------------------------

    //-----------------------------------------
    // [internal] check existence
    //-----------------------------------------
    function _exists( uint256 saleId ) internal view returns (bool) {
        return( saleId >= SALE_ID_OFS && saleId < (_sales.length+SALE_ID_OFS) );
    }

    //-----------------------------------------
    // [internal] Is there a valid Sale?
    //-----------------------------------------
    function _alive( uint256 contractAddress, uint256 tokenId, address msgSender ) internal view returns (bool) {
        uint256 saleId = _latestId[contractAddress][tokenId];
        if( _exists( saleId ) ){

            if( saleIsInvalid( saleId ) ){
                return( false );
            }

            if( saleIsSoldOut( saleId ) ){
                return( false );
            }

            if( saleIsCanceled( saleId ) ){
                return( false );
            }

            if( ! saleIsActive( saleId ) ){
                return( false );
            }

            // Owners do not match
            IERC721 tokenContract = IERC721( address(uint160(contractAddress)) );
            address owner = tokenContract.ownerOf( tokenId );
            if( owner != msgSender ){
                return( false );
            }

            // Expired
            uint256 expireDate = saleExpireDate( saleId );
            if( expireDate != 0 && expireDate <= block.timestamp ){
                return( false );
            }

            return( true );
        }

        return( false );
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./ITrade.sol";

//-----------------------------------------
// Trade
//-----------------------------------------
contract Trade is Ownable, ITrade {
    //-----------------------------------------
    // Setting
    //-----------------------------------------
    address private _market;        // Implemented in Trade (not published to ITrade & no event required = no need to monitor on the server side)

    uint256 private _max_price;
    uint256 private _min_price;

    uint256 private _max_period;
    uint256 private _min_period;

    bool private _only_no_limit_period;
    bool private _accept_no_limit_period;

    //-----------------------------------------
    // [public] market
    //-----------------------------------------
    function market() public view returns( address ) {
        return( _market );
    }

    //-----------------------------------------
    // [external/onlyOwner] Market setting
    //-----------------------------------------
    function setMarket( address contractAddress ) external onlyOwner {
        _market = contractAddress;
    }

    //-----------------------------------------
    // [modifier] Can only be called from the market
    //-----------------------------------------
    modifier onlyMarket() {
        require( market() == _msgSender(), "caller is not the market" );
        _;
    }

    //-----------------------------------------
    // Constructor
    //-----------------------------------------
    constructor() Ownable() {
        // Price limit
        _max_price = 1000000000000000000000000000;      // 1,000,000,000.000000 MATIC
        _min_price = 1000000000000;                     //             0.000001 MATIC

        emit MaxPriceModified( _max_price );
        emit MinPriceModified( _min_price );

        // Time limit
        _max_period = 30*24*60*60;      // 30 days
        _min_period =  1*24*60*60;      // 1 day

        emit MaxPeriodModified( _max_period );
        emit MinPeriodModified( _min_period );

        // Indefinite setting
        _only_no_limit_period = false;
        _accept_no_limit_period = false;

        emit OnlyNoLimitPeriodModified( _only_no_limit_period );
        emit AcceptNoLimiPeriodModified( _accept_no_limit_period );
    }    

    //-----------------------------------------
    // [external] Confirmation
    //-----------------------------------------
    function maxPrice() external view virtual override returns ( uint256 ) {
        return( _max_price );
    }

    function minPrice() external view virtual override returns ( uint256 ) {
        return( _min_price );
    }

    function maxPeriod() external view virtual override returns ( uint256 ) {
        return( _max_period );
    }

    function minPeriod() external view virtual override returns ( uint256 ) {
        return( _min_period );
    }

    function onlyNoLimitPeriod() external view virtual override returns (bool){
        return( _only_no_limit_period );
    }

    function acceptNoLimitPeriod() external view virtual override returns (bool){
        return( _accept_no_limit_period );
    }

    //-----------------------------------------
    // [external/onlyOwner] Setting
    //-----------------------------------------
    function setMaxPrice( uint256 price ) external virtual override onlyOwner {
        _max_price = price;

        emit MaxPriceModified( price );
    }

    function setMinPrice( uint256 price ) external virtual override onlyOwner {
        _min_price = price;

        emit MinPriceModified( price );
    }

    function setMaxPeriod( uint256 period ) external virtual override onlyOwner {
        _max_period = period;

        emit MaxPeriodModified( period );
    }

    function setMinPeriod( uint256 period ) external virtual override onlyOwner {
        _min_period = period;

        emit MinPeriodModified( period );
    }

    function setOnlyNoLimitPeriod( bool flag ) external virtual override onlyOwner {
        _only_no_limit_period = flag;

        emit OnlyNoLimitPeriodModified( flag );
    }

    function setAcceptNoLimitPeriod( bool flag ) external virtual override onlyOwner {
        _accept_no_limit_period = flag;

        emit AcceptNoLimiPeriodModified( flag );
    }

    //-----------------------------------------
    // [internal] Price effectiveness
    //-----------------------------------------
    function _checkPrice( uint256 price ) internal view virtual returns (bool){
        if( price > _max_price ){
            return( false );
        }

        if( price < _min_price ){
            return( false );
        }

        return( true );
    }

    //-----------------------------------------
    // [internal] Validity of period
    //-----------------------------------------
    function _checkPeriod( uint256 period ) internal view virtual returns (bool){
        // When accepting only unlimited
        if( _only_no_limit_period ){
            return( period == 0 );
        }

        // When accepting unlimited
        if( _accept_no_limit_period ){
            if( period == 0 ){
                return( true );
            }
        }

        if( period > _max_period ){
            return( false );
        }

        if( period < _min_period ){
            return( false );
        }

        return( true );
    }

    //-----------------------------------------
    // [external] Token transfer information
    //-----------------------------------------
    function transferInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[4] memory){
        uint256[4] memory words;
        return( words );
    }

    //-----------------------------------------
    // [external] Get payment information
    //-----------------------------------------
    function payInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[3] memory){
        uint256[3] memory words;
        return( words );
    }

    //-----------------------------------------
    // [external] Get refund information
    //-----------------------------------------
    function refundInfo( uint256 /*tradeId*/ ) external view virtual override returns (uint256[2] memory){
        uint256[2] memory words;
        return( words );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ITrade
//-----------------------------------------------------------------------
interface ITrade {
    //----------------------------------------
    // Events
    //----------------------------------------
    event MaxPriceModified( uint256 maxPrice );
    event MinPriceModified( uint256 minPrice );

    event MaxPeriodModified( uint256 maxPrice );
    event MinPeriodModified( uint256 minPrice );

    event OnlyNoLimitPeriodModified( bool );
    event AcceptNoLimiPeriodModified( bool );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function maxPrice() external view returns ( uint256 );
    function minPrice() external view returns ( uint256 );
    function setMaxPrice( uint256 price ) external;
    function setMinPrice( uint256 price ) external;

    function maxPeriod() external view returns ( uint256 );
    function minPeriod() external view returns ( uint256 );
    function setMaxPeriod( uint256 period ) external;
    function setMinPeriod( uint256 period ) external;

    function onlyNoLimitPeriod() external view returns (bool);
    function acceptNoLimitPeriod() external view returns (bool);
    function setOnlyNoLimitPeriod( bool flag ) external;
    function setAcceptNoLimitPeriod( bool flag ) external;

    //----------------------------------------------
    // Token transfer information
    //----------------------------------------------
    // The breakdown of uint256 [4] is as follows
    // ・ [0]: Token contract (cast to ERC721 and use)
    // ・ [1]: Token ID
    // ・ [2]: Donor side (cast to address and use)
    // ・ [3]: Recipient (cast to address and use)
    //----------------------------------------------
    function transferInfo( uint256 tradeId ) external view returns (uint256[4] memory);

    // ----------------------------------------------
    // Get payment information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Payment destination (cast to payable address)
    // ・ [1]: Contract address (cast to ERC721 and used)
    // ・ [2]: Payment amount
    // ----------------------------------------------
    function payInfo( uint256 tradeId ) external view returns (uint256[3] memory);

    //----------------------------------------------
    // Get refund information
    // ----------------------------------------------
    // The breakdown of uint256 [2] is as follows
    // ・ [0]: Refund destination (cast to payable address)
    // ・ [1]: Refund amount
    //----------------------------------------------
    function refundInfo( uint256 tradeId ) external view returns (uint256[2] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7 <0.9.0;

//-----------------------------------------------------------------------
// ISale
//-----------------------------------------------------------------------
interface ISale {
	//----------------------------------------
	// Events
	//----------------------------------------
    event Sale( address indexed contractAddress, uint256 indexed tokenId, address indexed seller, uint256 price, uint256 expireDate, uint256 saleId );
    event SaleCanceled( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );
    event Sold( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller, address buyer, uint256 price );
    event SaleInvalidated( uint256 indexed saleId, address indexed contractAddress, uint256 indexed tokenId, address seller );

    //----------------------------------------
    // Functions
    //----------------------------------------
    function sell( address msgSender, address contractAddress, uint256 tokenId, uint256 price, uint256 period ) external;
    function cancelSale( address msgSender, uint256 saleId ) external;
    function buy( address msgSender, uint256 saleId, uint256 amount ) external;
    function invalidateSales( uint256[] calldata saleIds ) external;
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}