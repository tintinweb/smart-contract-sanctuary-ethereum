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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract AlgorithmErrors {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW // The updated spot price doesn't fit into 128 bits
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../Algorithms/AlgorithmErrors.sol";

interface IMetaAlgorithm {

    function name() external pure returns( string memory );

    function validateStartPrice( uint _startPrice ) external pure returns( bool );

    function validateMultiplier( uint _multiplier ) external pure returns( bool );

    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external view 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        );

    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external view
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        );

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../pairs/MSPairBasic.sol";
import "../pairs/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

interface IMetaFactory {

    function createPair( 
        address _nft, 
        uint[] memory _nftIds,
        uint128 _multiplier,
        uint128 _startPrice,
        address _recipient,
        uint128 _fee,
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType
        ) external payable  returns(
            MSPairBasic pair
        );

    function getFactoryInfo() external view returns( uint128, uint128, address );

    function MAX_FEE_PERCENTAGE() external view returns( uint128);

    function PROTOCOL_FEE() external view returns( uint128);

    function PROTOCOL_FEE_RECIPIENT() external view returns( address );
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pairs/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

interface IMSPair {
    
    function getNFTIds() external view returns ( uint[] memory nftIds);

    function getPoolBuyInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint inputValue, uint protocolFee );

    function getPoolSellInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint outputValue, uint protocolFee );

    function getAssetsRecipient() external view returns ( address _recipient );

    function getAlgorithm() external view returns( string memory );

    function getPairInfo() external view returns( 
        uint128 pairMultiplier,
        uint128 pairStartPrice,
        uint128 pairTradeFee,
        address pairNft,
        PoolTypes.PoolType pairPoolType,
        string memory pairAlgorithm,
        uint[] memory pairNFTs);

    function init(
        uint128 _multiplier, 
        uint128 _startPrice, 
        address _recipient, 
        address _owner, 
        address _NFT, 
        uint128 _fee, 
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType 
        ) external payable;

    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) external returns( uint256 outputAmount );

    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolTypes.sol";
import "../interfaces/IMetaAlgorithm.sol";
import "../interfaces/IMetaFactory.sol";
import "../Algorithms/AlgorithmErrors.sol";
import "../interfaces/IMSPair.sol";

abstract contract MSPairBasic is IMSPair, ReentrancyGuard, Ownable {

    uint128 public multiplier;

    uint128 public startPrice;

    uint128 public tradeFee;

    uint128 public constant MAX_TRADE_FEE = 0.9e18;

    address public recipient;

    address public NFT;

    address public factory;

    PoolTypes.PoolType public currentPoolType;

    IMetaAlgorithm public Algorithm;

    event SellLog( address user, uint inputNFTs, uint amountOut );

    event BuyLog( address user, uint amountIn, uint outputNFTs );

    event NewStartPrice( uint128 newStartPrice );

    event NewMultiplier( uint128 newMultiplier );

    event NewAssetsRecipient( address newRecipient );

    event NewTradeFee( uint newFee );

    event TokenWithdrawal( address owner, uint withdrawAmount );

    event NFTWithdrawal( address owner, uint AmountOfNFTs );

    event TokenDeposit( uint amount );

    event NFTDeposit( address nft, uint tokenID );

    function _getSellNFTInfo( uint _numNFTs, uint _minExpected ) internal virtual returns ( 
            uint256 outputValue, 
            uint256 protocolFee 
        ) 
    {

        bool isValid;

        uint128 newStartPrice;

        uint128 newMultiplier;

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            outputValue, 
            protocolFee 
        ) = Algorithm.getSellInfo( 
            multiplier, 
            startPrice, 
            _numNFTs,
            IMetaFactory( factory ).PROTOCOL_FEE(),
            tradeFee
            );

        require( isValid, "Algorithm Error" );

        require( outputValue >= _minExpected, "output amount is les than min expected" );

        if( startPrice != newStartPrice ) {
            
            startPrice = newStartPrice;

            emit NewStartPrice( newStartPrice );
            
        }

        if( multiplier != newMultiplier ) { 
            
            multiplier = newMultiplier;

            emit NewMultiplier( newMultiplier );
            
        }

    }

    function _getBuyNFTInfo( uint _numNFTs, uint _maxExpectedIn ) internal virtual returns ( 
            uint256 inputValue, 
            uint256 protocolFee 
        ) 
    {

        bool isValid;

        uint128 newStartPrice;

        uint128 newMultiplier;

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            inputValue, 
            protocolFee 
        ) = Algorithm.getBuyInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            IMetaFactory( factory ).PROTOCOL_FEE(),
            tradeFee
            );

        require( isValid, "Algorithm Error" );

        require( inputValue <= _maxExpectedIn, "output amount is less than min expected" );

        if( startPrice != newStartPrice ) {
            
            startPrice = newStartPrice;

            emit NewStartPrice( newStartPrice );
            
        }

        if( multiplier != newMultiplier ) {
            
            multiplier = newMultiplier;

            emit NewMultiplier( newMultiplier );
            
        }

    }

    function _sendTokensAndPayFee( uint _protocolFee, uint _amount, address _to ) private {

        address feeRecipient = IMetaFactory( factory ).PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{value: _protocolFee}("");

        ( bool isAmountSended, ) = payable( _to ).call{ value: _amount - _protocolFee }( "" );

        require( isAmountSended && isFeeSended, "tx error" );

    }

    function _receiveTokensAndPayFee( uint _inputAmount, uint _protocolFee ) private {

        require( msg.value >= _inputAmount, "insufficient amount of ETH" );

        address _recipient = getAssetsRecipient();

        if( _recipient != address( this ) ) {

            ( bool isAssetSended, ) = payable( _recipient ).call{ value: _inputAmount - _protocolFee }("");

            require( isAssetSended, "tx error" );

        }

        address feeRecipient = IMetaFactory( factory ).PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{ value: _protocolFee }("");

        require( isFeeSended, "tx error");

    }

    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal virtual;

    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal virtual;

    function getNFTIds() public virtual view returns ( uint[] memory nftIds );

    function getPoolBuyInfo( uint _numNFTs) public view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint inputValue, uint protocolFee ) {

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            inputValue, 
            protocolFee 
        ) = Algorithm.getBuyInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            IMetaFactory( factory ).PROTOCOL_FEE(),
            tradeFee
            );
    
    }

    function getPoolSellInfo( uint _numNFTs) public view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint outputValue, uint protocolFee ) {

        (
            isValid, 
            newStartPrice, 
            newMultiplier, 
            outputValue, 
            protocolFee 
        ) = Algorithm.getSellInfo( 
            multiplier, 
            startPrice, 
            _numNFTs, 
            IMetaFactory( factory ).PROTOCOL_FEE(),
            tradeFee
            );
    
    }

    function getAssetsRecipient() public view returns ( address _recipient ) {

        if ( recipient == address(0) ) _recipient = address( this );

        else _recipient = recipient;

    }

    function getAlgorithm() public view returns( string memory ) {

        return IMetaAlgorithm( Algorithm ).name();
        
    }

    function getPairInfo() public view returns( 
        uint128 pairMultiplier,
        uint128 pairStartPrice,
        uint128 pairTradeFee,
        address pairNft,
        PoolTypes.PoolType pairPoolType,
        string memory pairAlgorithm,
        uint[] memory pairNFTs
    ){
        pairMultiplier = multiplier;

        pairStartPrice = startPrice;

        pairTradeFee = tradeFee;

        pairNft = NFT;

        pairPoolType = currentPoolType;

        pairAlgorithm = getAlgorithm();

        pairNFTs = getNFTIds();

    }

    function init(
        uint128 _multiplier, 
        uint128 _startPrice, 
        address _recipient, 
        address _owner, 
        address _NFT, 
        uint128 _fee, 
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType 
        ) public payable 
    {

        require( owner() == address(0), "it is already initialized");

        _transferOwnership( _owner );

        if( recipient != _recipient ) recipient = _recipient;

        if( tradeFee != _fee) tradeFee = _fee;

        Algorithm = _Algorithm;

        multiplier = _multiplier;

        startPrice = _startPrice;

        NFT = _NFT;

        currentPoolType = _poolType;

        factory = msg.sender;

    }

    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) public nonReentrant returns( uint256 outputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Sell || currentPoolType == PoolTypes.PoolType.Trade, "invalid pool Type" );

        uint256 protocolFee;

        ( outputAmount, protocolFee ) = _getSellNFTInfo( _tokenIDs.length, _minExpected );

        address _recipient = getAssetsRecipient();

        _sendNFTsTo( _user, _recipient, _tokenIDs );

        _sendTokensAndPayFee( protocolFee, outputAmount, _user );

        emit SellLog( _user, _tokenIDs.length, outputAmount );

    }

    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "invalid pool Type" );

        uint protocolFee;

        ( inputAmount, protocolFee ) = _getBuyNFTInfo( _tokenIDs.length, _maxExpectedIn );

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendNFTsTo( address( this ), _user, _tokenIDs );

        if ( msg.value > inputAmount ) {

            ( bool isSended , ) = payable( _user ).call{ value: msg.value - inputAmount }("");
            
            require( isSended, "tx error" );
            
        }

        emit BuyLog( _user, inputAmount, _tokenIDs.length);
        
    }

    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "invalid pool Type" );

        uint protocolFee;

        ( inputAmount, protocolFee ) = _getBuyNFTInfo( _numNFTs, _maxExpectedIn );

        _receiveTokensAndPayFee( inputAmount, protocolFee );

        _sendAnyOutNFTs( _user, _numNFTs );

        if ( msg.value > inputAmount ) {

            ( bool isSended , ) = payable( _user ).call{ value: msg.value - inputAmount }("");
            
            require( isSended, "tx error" );
            
        }

        emit BuyLog( _user, inputAmount, _numNFTs);
        
    }

    function setAssetsRecipient( address _newRecipient ) external onlyOwner {

        require( currentPoolType != PoolTypes.PoolType.Trade, "Recipient not supported in trade pools");

        require( recipient != _newRecipient, "New recipient is equal than current" );

        recipient = _newRecipient;

        emit NewAssetsRecipient( _newRecipient );

    }

    function setTradeFee( uint128 _newFee ) external onlyOwner {

        require( currentPoolType == PoolTypes.PoolType.Trade, "fee supported only on trade pools");

        require( tradeFee != _newFee, "New fee is equal than current" );

        tradeFee = _newFee;

        emit NewTradeFee( _newFee );

    }

    function setStartPrice( uint128 _newStartPrice ) external onlyOwner {

        require( startPrice != _newStartPrice, "new price is equal than current");

        require( Algorithm.validateStartPrice( _newStartPrice ), "invalid Start Price" );

        startPrice = _newStartPrice;

        emit NewStartPrice( _newStartPrice );

    }

    function setMultiplier( uint128 _newMultiplier ) external onlyOwner {

        require( multiplier != _newMultiplier, "multiplier is equal than current");

        require( Algorithm.validateMultiplier( _newMultiplier ), "invalid multiplier" );

        multiplier = _newMultiplier;

        emit NewMultiplier( _newMultiplier );
        
    }

    function withdrawTokens() external onlyOwner {

        uint balance = address( this ).balance;

        require( balance > 0, "insufficient balance" );

        ( bool isSended, ) = owner().call{ value: balance }("");

        require(isSended, "amount not sended" );

        emit TokenWithdrawal( owner(), balance );

    }

    function withdrawNFTs( IERC721 _nft, uint[] calldata _nftIds ) external virtual;

    receive() external payable {

        emit TokenDeposit( msg.value );

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "./MSPairBasic.sol";

contract MSPairNFTEnumerable is MSPairBasic, IERC721Receiver {

    function getNFTIds() public view override returns ( uint[] memory nftIds) {

        IERC721Enumerable _NFT = IERC721Enumerable( NFT );

        uint pairBalance = _NFT.balanceOf( address( this ) );

        if ( pairBalance == 0 ) return nftIds;

        uint lastIndex = pairBalance - 1;

        uint[] memory _nftIds = new uint[]( lastIndex + 1 );

        for (uint256 i = 0; i <= lastIndex; i++) {
            
            _nftIds[i] = _NFT.tokenOfOwnerByIndex( address( this ), i);

        }

        nftIds = _nftIds;

    }

    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom(_from, _to, _tokenIDs[i]);

        }

    }

    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint[] memory _tokenIds = getNFTIds();

        for (uint256 i = 0; i < _numNFTs - 1; i++) {

            _NFT.safeTransferFrom( address( this ), _to, _tokenIds[i]);

        }

    }

    function onERC721Received(address, address, uint256 id, bytes calldata) external override returns (bytes4) {

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

    function withdrawNFTs( IERC721 _nft, uint[] memory _nftIds ) external override onlyOwner {

        for (uint256 i = 0; i < _nftIds.length; i++) 
        
            _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

    }
            

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

contract PoolTypes {

    enum PoolType {
        Sell, // you can sell NFTs and get tokens
        Buy,   // you can buy NFTs with tokens
        Trade  // A pool that make both
    }
    
}