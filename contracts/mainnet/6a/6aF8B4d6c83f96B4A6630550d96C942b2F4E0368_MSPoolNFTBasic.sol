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
pragma solidity ^0.8.9;

/// @title IMetaAlgorithm a interface to call algorithms contracts
/// @author JorgeLpzGnz & CarlosMario714
/// @dev the algorithm is responsible for calculating the prices see
interface IMetaAlgorithm {

    /// @dev See each algorithm to see how this values are calculated

    /// @notice it returns the name of the Algorithm
    function name() external pure returns( string memory );

    /// @notice it checks if the start price is valid 
    function validateStartPrice( uint _startPrice ) external pure returns( bool );

    /// @notice it checks if the multiplier is valid 
    function validateMultiplier( uint _multiplier ) external pure returns( bool );

    /// @notice in returns of the info needed to do buy NFTs
    /// @param _multiplier current multiplier used to calculate the price
    /// @param _startPrice current start price used to calculate the price
    /// @param _numItems number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid true if trade can be performed
    /// @return newStartPrice new start price used to calculate the price
    /// @return newMultiplier new multiplier used to calculate the price
    /// @return inputValue amount to send to the pool
    /// @return protocolFee Amount to charged for the trade
    function getBuyInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure 
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 inputValue, 
            uint256 protocolFee 
        );

    /// @notice in returns of the info needed to do sell NFTs
    /// @param _multiplier current multiplier used to calculate the price
    /// @param _startPrice current start price used to calculate the price
    /// @param _numItems number of NFTs to trade
    /// @param _protocolFee Fee multiplier to calculate the protocol fee
    /// @param _poolFee Fee multiplier to calculate the pool fee
    /// @return isValid true if trade can be performed
    /// @return newStartPrice new start price used to calculate the price
    /// @return newMultiplier new multiplier used to calculate the price
    /// @return outputValue amount to send to the user
    /// @return protocolFee Amount to charged for the trade
    function getSellInfo( uint128 _multiplier, uint128 _startPrice, uint _numItems, uint128 _protocolFee, uint128 _poolFee ) external pure
        returns ( 
            bool isValid, 
            uint128 newStartPrice, 
            uint128 newMultiplier, 
            uint256 outputValue, 
            uint256 protocolFee 
        );

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pools/MSPoolBasic.sol";
import "../pools/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

/// @title IMetaFactory a interface to call pool factory
/// @author JorgeLpzGnz & CarlosMario714
/// @dev this factory creates pair based on the minimal proxy standard IEP-1167
interface IMetaFactory {

    /// @notice Creates a new pool
    /// @param _nft NFT collection to trade
    /// @param _nftIds the NFTs to trade ( empty in pools type Buy )
    /// @param _multiplier the multiplier to calculate the trade price
    /// @param _startPrice the start Price to calculate the trade price
    /// start Price is just a name see de algorithm to see how this will be take it
    /// @param _recipient recipient of the input assets
    /// @param _fee fee multiplier to calculate the pool fee ( available on trade pool )
    /// @param _Algorithm Algorithm used to calculate the price
    /// @param _poolType the type of the pool ( sell, buy, trade )
    /// @return pool Address of the new pool created
    function createPool( 
        address _nft, 
        uint[] memory _nftIds,
        uint128 _multiplier,
        uint128 _startPrice,
        address _recipient,
        uint128 _fee,
        IMetaAlgorithm _Algorithm, 
        PoolTypes.PoolType _poolType
        ) external payable  returns(
            MSPoolBasic pool
        );

    /// @notice Get current pool info
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee multiplier
    /// @return PROTOCOL_FEE Current protocol fee multiplier
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function getFactoryInfo() external view returns( uint128, uint128, address );

    /// @notice Maximum multiplier fee
    /// @return MAX_FEE_PERCENTAGE The maximum percentage fee multiplier
    function MAX_FEE_PERCENTAGE() external view returns( uint128 );

    /// @notice Protocol multiplier fee, used to calculate the fee charged per trade
    /// @return PROTOCOL_FEE Current protocol fee multiplier
    function PROTOCOL_FEE() external view returns( uint128 );

    /// @notice The recipient of the fees charged per swap
    /// @return PROTOCOL_FEE_RECIPIENT The recipient of the fees
    function PROTOCOL_FEE_RECIPIENT() external view returns( address );
    
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "../pools/PoolTypes.sol";
import "./IMetaAlgorithm.sol";

/// @title IMSPool a interface to call pool functions
/// @author JorgeLpzGnz & CarlosMario714
/// @dev Pools are a IEP-1167 implementation ( minimal proxies - clones )
interface IMSPool {
    
    /// @notice Returns the the NFT IDs of the pool
    /// @dev In the buy pools this will be empty because the NFTs are push
    /// on the recipient indicated for the user
    function getNFTIds() external view returns ( uint[] memory nftIds);

    /// @notice Returns the current Buy info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid True if trade is operable
    /// @return newStartPrice New Start price that will be set 
    /// @return newMultiplier New multiplier that will be set 
    /// @return inputValue Amount of tokens to send to the pool 
    /// @return protocolFee Amount charged for the trade
    function getPoolBuyInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint inputValue, uint protocolFee );

    /// @notice returns the current Sell info
    /// @param _numNFTs Number of NFTs to buy
    /// @return isValid true if trade is operable
    /// @return newStartPrice new Start price that will be set 
    /// @return newMultiplier new multiplier that will be set 
    /// @return outputValue Amount to be sent to the user
    /// @return protocolFee Amount charged for the trade
    function getPoolSellInfo( uint _numNFTs) external view returns( bool isValid, uint128 newStartPrice, uint128 newMultiplier, uint outputValue, uint protocolFee );

    /// @return _recipient Recipient of the input assets
    function getAssetsRecipient() external view returns ( address _recipient );

    /// @notice retruns the current algorithm info
    /// @return algorithm Name of the algorithm used to calculate trade prices
    /// @return name Name of the algorithm used to calculate trade prices
    function getAlgorithmInfo() external view returns( IMetaAlgorithm algorithm, string memory name );

    /// @notice Returns the pool info
    /// @return poolMultiplier Current multiplier
    /// @return poolStartPrice Current start price 
    /// @return poolTradeFee Trade fee multiplier 
    /// @return poolNft NFT trade collection
    /// @return poolNFTs NFTs of the pool
    /// @return poolAlgorithm Address of the algorithm
    /// @return poolAlgorithmName Name of the algorithm
    /// @return poolPoolType The type of the pool
    function getPoolInfo() external view returns( 
        uint128 poolMultiplier,
        uint128 poolStartPrice,
        uint128 poolTradeFee,
        address poolNft,
        uint[] memory poolNFTs,
        IMetaAlgorithm poolAlgorithm,
        string memory poolAlgorithmName,
        PoolTypes.PoolType poolPoolType);

    /// @notice Function called when the pool is created
    /// @param _multiplier Multiplier to calculate the price
    /// @param _startPrice Start price to calculate the price 
    /// @param _recipient Recipient of the input assets ( not available on trade pools )
    /// @param _owner Owner of the pool 
    /// @param _NFT NFT trade collection
    /// @param _fee Fee multiplier to calculate pool fees ( available on trade pool )
    /// @param _Algorithm Address of the algorithm to calculate trade prices
    /// @param _poolType Type of the pool
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

    /// @notice Sell NFTs and get Tokens
    /// @param _tokenIDs NFTs to trade
    /// @param _minExpected Minimum expected to return to the user
    /// @param _user Address to send the tokens
    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) external returns( uint256 outputAmount );

    /// @notice Buy NFTs by depositing tokens
    /// @param _tokenIDs NFTs to trade
    /// @param _maxExpectedIn maximum expected cost to buy the NFTs
    /// @param _user Address to send the NFTs
    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

    /// @notice Buy NFTs by depositing tokens (used when the NFTs to be sent to the user do not matter)
    /// @param _numNFTs Number of NFTs to buy
    /// @param _maxExpectedIn maximum expected cost to buy the NFTs
    /// @param _user Address to send the NFTs
    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) external payable returns( uint256 inputAmount );

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title Arrays a library for uint256 arrays
/// @author JorgeLpzGnz & CarlosMario714
/// @notice a library to add array methods
library Arrays {

    /// @notice returns the index of the given element
    /// @dev it will reject the tx if the element doesn't exist
    function indexOf( uint[] memory array, uint element ) internal pure returns ( uint index ) {

        for ( uint256 i = 0; i < array.length; i++ ) {

            if( array[i] == element ) return i;

        }

        // if the function has not returned anything it means that the 
        // element does not exist, so it will be rejected

        require( true, "The element doesn't exist");

    }

    /// @notice returns a boolean indicating whether it is included or not
    /// @return included true = included, false = not included
    function includes(uint[] memory array, uint element ) internal pure returns ( bool included ) {

        for ( uint256 i = 0; i < array.length; i++ ) {

            if( array[i] == element ) return true;

        }

    }

    /// @notice it removes the element of the passed 
    /// @dev to remove the element, just take the last item in
    /// the array and set it to the index of the item to be removed,
    /// then remove the last item
    /// @return true if the element was deleted
    function remove( uint[] storage array, uint index ) internal returns( bool ) {

        if ( index > array.length - 1 ) return false;

        array[ index ] = array[ array.length - 1 ];

        array.pop();

        return true;

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./PoolTypes.sol";
import "../interfaces/IMetaAlgorithm.sol";
import "../interfaces/IMetaFactory.sol";
import "../interfaces/IMSPool.sol";

/// @title MSPoolBasic a basic pool template implementations
/// @author JorgeLpzGnz & CarlosMario714
/// @notice Basic implementation based on IEP-1167
abstract contract MSPoolBasic is IMSPool, ReentrancyGuard, Ownable {

    /// @notice used to calculate the swap price
    uint128 public multiplier;

    /// @notice used to calculate the swap price
    /// @notice start Price is just a name, depending of the algorithm it will take it at different ways
    uint128 public startPrice;

    /// @notice fee charged per swap ( only available in trade pools )
    uint128 public tradeFee;

    /// @notice fee charged per swap ( only available in trade pools )
    uint128 public constant MAX_TRADE_FEE = 0.9e18;

    /// @notice the address that will receive the tokens depending of the pool type
    address public recipient;

    /// @notice the collection that the pool trades
    address public NFT;

    /// @notice the address of the factory that creates this pool
    IMetaFactory public factory;

    /// @notice the type of the pool ( Sell, Buy, Trade )
    /// @dev See [ PoolTypes.sol ] for more info
    PoolTypes.PoolType public currentPoolType;

    /// @notice The algorithm that calculates the price
    /// @dev See [ IMetaAlgorithm.sol ] for more info
    IMetaAlgorithm public Algorithm;

    /*************************************************************************/
    /******************************* EVENTS **********************************/

    /// @param user User who sold nfts
    /// @param inputNFTs Amount of NFTs entered into the pool
    /// @param amountOut Amount of tokens sent to user
    event SellLog( address indexed user, uint inputNFTs, uint amountOut );

    /// @param user User who bought nfts
    /// @param amountIn Amount of tokens that entered the pool
    /// @param outputNFTs Amount of NFTs sent to user
    event BuyLog( address indexed user, uint amountIn, uint outputNFTs );

    /// @param newStartPrice The new start price
    event NewStartPrice( uint128 newStartPrice );

    /// @param newMultiplier The new multiplier
    event NewMultiplier( uint128 newMultiplier );

    /// @param newRecipient The new recipient
    event NewAssetsRecipient( address newRecipient );

    /// @param newFee The new trade fee
    event NewTradeFee( uint newFee );

    /// @param owner pool owner
    /// @param withdrawAmount amount of tokens withdrawn
    event TokenWithdrawal( address indexed owner, uint withdrawAmount );

    /// @param owner pool owner
    /// @param AmountOfNFTs amount of NFTs withdrawn
    event NFTWithdrawal( address indexed owner, uint AmountOfNFTs );

    /// @param amount amount of token deposited
    event TokenDeposit( uint amount );

    /// @param nft address of the NFT Collection
    /// @param tokenID NFT deposited
    event NFTDeposit( address nft, uint tokenID );

    /*************************************************************************/
    /*************************** PRIVATE FUNCTIONS ***************************/

    /// @notice Returns the info to sell NFTs and updates the params
    /// @param _numNFTs number of NFTs to sell at pool
    /// @param _minExpected the minimum number of tokens expected to be returned to the user
    /// @return outputValue Amount of Tokens to send to the user
    /// @return protocolFee Fee charged in a trade
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
            factory.PROTOCOL_FEE(),
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

    /// @notice Returns the info to buy NFTs and updates the params
    /// @param _numNFTs NFT number to buy at pool
    /// @param _maxExpectedIn the maximum expected cost to buy the NFTs
    /// @return inputValue Amount of tokens to pay the NFTs
    /// @return protocolFee Fee charged in a trade
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
            factory.PROTOCOL_FEE(),
            tradeFee
            );

        require( isValid, "Algorithm Error" );

        require( inputValue <= _maxExpectedIn, "input amount is greater than max expected" );

        if( startPrice != newStartPrice ) {
            
            startPrice = newStartPrice;

            emit NewStartPrice( newStartPrice );
            
        }

        if( multiplier != newMultiplier ) {
            
            multiplier = newMultiplier;

            emit NewMultiplier( newMultiplier );
            
        }

    }

    /// @notice send tokens to the given address and pay protocol fee
    /// @param _protocolFee the trade cost
    /// @param _amount amount of tokens to send
    /// @param _to the address to send the tokens
    function _sendTokensAndPayFee( uint _protocolFee, uint _amount, address _to ) private {

        address feeRecipient = factory.PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{value: _protocolFee}("");

        ( bool isAmountSended, ) = payable( _to ).call{ value: _amount - _protocolFee }( "" );

        require( isAmountSended && isFeeSended, "tx error" );

    }

    /// @notice sends the tokens to the pool and pays the protocol fee
    /// @param _inputAmount Amount of tokens that input to the pool
    /// @param _protocolFee the trade cost
    function _receiveTokensAndPayFee( uint _inputAmount, uint _protocolFee ) private {

        require( msg.value >= _inputAmount, "insufficient amount of ETH" );

        address _recipient = getAssetsRecipient();

        if( _recipient != address( this ) ) {

            ( bool isAssetSended, ) = payable( _recipient ).call{ value: _inputAmount - _protocolFee }("");

            require( isAssetSended, "tx error" );

        }

        address feeRecipient = factory.PROTOCOL_FEE_RECIPIENT();

        ( bool isFeeSended, ) = payable( feeRecipient ).call{ value: _protocolFee }("");

        require( isFeeSended, "tx error");

    }

    /// @notice send NFTs to the given address
    /// @param _from NFTs owner address
    /// @param _to address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal virtual;

    /// @notice send NFTs from the pool to the given address
    /// @param _to address to send the NFTs
    /// @param _numNFTs the number of NFTs to send
    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal virtual;

    /*************************************************************************/
    /***************************** SET FUNCTIONS *****************************/

    /// @notice it sets a new recipient 
    /// @param _newRecipient the new recipient 
    function setAssetsRecipient( address _newRecipient ) external onlyOwner {

        require( currentPoolType != PoolTypes.PoolType.Trade, "Recipient not supported in trade pools");

        require( recipient != _newRecipient, "New recipient is equal than current" );

        recipient = _newRecipient;

        emit NewAssetsRecipient( _newRecipient );

    }

    /// @notice it sets a new trade fee 
    /// @param _newFee the new trade fee 
    function setTradeFee( uint128 _newFee ) external onlyOwner {

        require( currentPoolType == PoolTypes.PoolType.Trade, "fee available only on trade pools");

        require( tradeFee != _newFee, "New fee is equal than current" );

        tradeFee = _newFee;

        emit NewTradeFee( _newFee );

    }

    /// @notice it sets a new start Price 
    /// @param _newStartPrice the new start Price 
    function setStartPrice( uint128 _newStartPrice ) external onlyOwner {

        require( startPrice != _newStartPrice, "new price is equal than current");

        require( Algorithm.validateStartPrice( _newStartPrice ), "invalid Start Price" );

        startPrice = _newStartPrice;

        emit NewStartPrice( _newStartPrice );

    }

    /// @notice it sets a new multiplier
    /// @param _newMultiplier the new multiplier
    function setMultiplier( uint128 _newMultiplier ) external onlyOwner {

        require( multiplier != _newMultiplier, "multiplier is equal than current");

        require( Algorithm.validateMultiplier( _newMultiplier ), "invalid multiplier" );

        multiplier = _newMultiplier;

        emit NewMultiplier( _newMultiplier );
        
    }

    /*************************************************************************/
    /************************** GET FUNCTIONS ********************************/
 
    /// @notice it return the pool sell info
    /// @param _numNFTs number of NFTs to buy
    /// @return isValid indicate if will be an error calculating the price
    /// @return newStartPrice the pool new Star Price
    /// @return newMultiplier the pool new Multiplier
    /// @return inputValue the amount of tokens to send at pool to buy NFTs
    /// @return protocolFee the trade cost
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
            factory.PROTOCOL_FEE(),
            tradeFee
            );
    
    }
 
    /// @notice it return the pool sell info
    /// @param _numNFTs number of NFTs to buy
    /// @return isValid indicate if will be an error calculating the price
    /// @return newStartPrice the pool new Star Price
    /// @return newMultiplier the pool new Multiplier
    /// @return outputValue the number of tokens to send to the user when selling NFTs
    /// @return protocolFee the trade cost
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
            factory.PROTOCOL_FEE(),
            tradeFee
            );
    
    }

    /// @notice it returns the NFTs hold by the pool 
    function getNFTIds() public virtual view returns ( uint[] memory nftIds );

    /// @notice returns the recipient of the input assets
    function getAssetsRecipient() public view returns ( address _recipient ) {

        if ( recipient == address(0) ) _recipient = address( this );

        else _recipient = recipient;

    }

    /// @notice returns the name of the price algorithm used
    function getAlgorithmInfo() public view returns( IMetaAlgorithm algorithm, string memory name ) {

        algorithm = Algorithm;

        name = Algorithm.name();
        
    }

    /// @notice Returns the pool info
    /// @return poolMultiplier Current multiplier
    /// @return poolStartPrice Current start price 
    /// @return poolTradeFee Trade fee multiplier 
    /// @return poolNft NFT trade collection
    /// @return poolNFTs NFTs of the pool
    /// @return poolAlgorithm Address of the algorithm
    /// @return poolAlgorithmName Name of the algorithm
    /// @return poolPoolType The type of the pool
    function getPoolInfo() public view returns( 
        uint128 poolMultiplier,
        uint128 poolStartPrice,
        uint128 poolTradeFee,
        address poolNft,
        uint[] memory poolNFTs,
        IMetaAlgorithm poolAlgorithm,
        string memory poolAlgorithmName,
        PoolTypes.PoolType poolPoolType
    ){
        poolMultiplier = multiplier;

        poolStartPrice = startPrice;

        poolTradeFee = tradeFee;

        poolNft = NFT;

        poolNFTs = getNFTIds();

        ( poolAlgorithm, poolAlgorithmName ) = getAlgorithmInfo();

        poolPoolType = currentPoolType;

    }
    
    /*************************************************************************/
    /***************************** INIT POOL *********************************/

    /// @notice it set the initial params of the pool
    /// @dev it is expected that the parameters have already been verified
    /// @param _multiplier multiplier to calculate price
    /// @param _startPrice the Star Price ( depending of the algorithm it will be take it by different ways )
    /// @param _recipient the recipient of the input assets
    /// @param _owner the owner of the pool
    /// @param _NFT the NFT collection that will be trade
    /// @param _fee pool fee charged per trade
    /// @param _Algorithm address of the algorithm to calculate the price
    /// @param _poolType the type of the pool
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

        require( owner() == address(0), "Pool it's already initialized");

        _transferOwnership( _owner );

        if( recipient != _recipient ) recipient = _recipient;

        if( tradeFee != _fee) tradeFee = _fee;

        Algorithm = _Algorithm;

        multiplier = _multiplier;

        startPrice = _startPrice;

        NFT = _NFT;

        currentPoolType = _poolType;

        factory = IMetaFactory( msg.sender );

    }

    /*************************************************************************/
    /**************************** TRADE FUNCTIONS ****************************/

    /// @notice sell NFTs for tokens
    /// @param _tokenIDs NFTs to sell
    /// @param _minExpected the minimum expected that the pool will return to the user
    /// @param _user address to send the tokens
    /// @return outputAmount the amount of tokens that output of the pool
    function swapNFTsForToken( uint[] memory _tokenIDs, uint _minExpected, address _user ) public nonReentrant returns( uint256 outputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Sell || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on buy-type pool" );

        require( address( this ).balance >= _minExpected, "insufficient token balance");

        uint256 protocolFee;

        ( outputAmount, protocolFee ) = _getSellNFTInfo( _tokenIDs.length, _minExpected );

        address _recipient = getAssetsRecipient();

        _sendNFTsTo( _user, _recipient, _tokenIDs );

        _sendTokensAndPayFee( protocolFee, outputAmount, _user );

        emit SellLog( _user, _tokenIDs.length, outputAmount );

    }

    /// @notice buy NFTs with tokens
    /// @param _tokenIDs NFTs to buy
    /// @param _maxExpectedIn the minimum expected that the trade will cost
    /// @param _user address to send the NFTs
    /// @return inputAmount amount of tokens that input of the pool
    function swapTokenForNFT( uint[] memory _tokenIDs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _tokenIDs.length,
            "Insufficient NFT balance" 
        );

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

    /// @notice buy any NFTs with tokens ( It is used when the NFTs that you want to buy do not matter )
    /// @param _numNFTs number NFTs to buy
    /// @param _maxExpectedIn the minimum expected that the trade will cost
    /// @param _user address to send the NFTs
    /// @return inputAmount amount of tokens that input of the pool
    function swapTokenForAnyNFT( uint _numNFTs, uint _maxExpectedIn, address _user ) public payable nonReentrant returns( uint256 inputAmount ) {

        require( currentPoolType == PoolTypes.PoolType.Buy || currentPoolType == PoolTypes.PoolType.Trade, "Cannot sell on sell-type pool" );

        require( 
            IERC721( NFT ).balanceOf( address( this ) ) >= _numNFTs,
            "Insufficient NFT balance" 
        );

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

    /*************************************************************************/
    /********************** WITHDRAW FUNCTIONS FUNCTIONS *********************/

    /// @notice withdraw the balance tokens
    function withdrawTokens() external onlyOwner {

        uint balance = address( this ).balance;

        require( balance > 0, "insufficient balance" );

        ( bool isSended, ) = owner().call{ value: balance }("");

        require(isSended, "amount not sended" );

        emit TokenWithdrawal( owner(), balance );

    }

    /// @notice withdraw the balance NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] calldata _nftIds ) external virtual;

    /*************************************************************************/
    /*************************** DEPOSIT FUNCTIONS ***************************/

    /// @notice allows the pool to receive ETH
    receive() external payable {

        emit TokenDeposit( msg.value );

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "../libraries/Arrays.sol";
import "./MSPoolBasic.sol";

/// @title MSPoolNFTBasic A basic ERC-721 pool template implementation
/// @author JorgeLpzGnz & CarlosMario714
/// @notice implementation based on IEP-1167
contract MSPoolNFTBasic is MSPoolBasic, IERC721Receiver {

    /// @notice a library to implement some array methods
    using Arrays for uint[];

    /// @notice An array to store the token IDs of the Pair NFTs
    uint[] private _TOKEN_IDS;

    /// @notice send NFTs to the given address
    /// @param _from NFTs owner address
    /// @param _to address to send the NFTs
    /// @param _tokenIDs NFTs to send
    function _sendNFTsTo( address _from, address _to, uint[] memory _tokenIDs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        for (uint256 i = 0; i < _tokenIDs.length; i++) {

            _NFT.safeTransferFrom(_from, _to, _tokenIDs[i]);

            if( _from == address( this ) && _TOKEN_IDS.includes( _tokenIDs[i] ) ) {

                uint tokenIndex = _TOKEN_IDS.indexOf( _tokenIDs[i] );

                require(_TOKEN_IDS.remove( tokenIndex ), "Unknown tokenID" );

            }

        }

    }

    /// @notice send NFTs from the pool to the given address
    /// @param _to address to send the NFTs
    /// @param _numNFTs the number of NFTs to send
    function _sendAnyOutNFTs( address _to, uint _numNFTs ) internal override {

        IERC721 _NFT = IERC721( NFT );

        uint[] memory NFTs = getNFTIds();

        for (uint256 i = 0; i < _numNFTs; i++) {

            _NFT.safeTransferFrom( address( this ), _to, NFTs[i]);

            uint index = _TOKEN_IDS.indexOf( NFTs[i] );

            require(_TOKEN_IDS.remove( index ), "NFT transfer error" );

        }

    }

    /// @notice ERC-721 Receiver implementation
    function onERC721Received(address, address, uint256 id, bytes calldata) external override returns (bytes4) {

        if( NFT == msg.sender ) _TOKEN_IDS.push(id);

        emit NFTDeposit( msg.sender, id );

        return IERC721Receiver.onERC721Received.selector;

    }

    /// @notice it returns the NFTs hold by the pool 
    function getNFTIds() public override view returns ( uint[] memory nftIds) {

        nftIds = _TOKEN_IDS;

    }

    /// @notice withdraw the balance NFTs
    /// @param _nft NFT collection to withdraw
    /// @param _nftIds NFTs to withdraw
    function withdrawNFTs( IERC721 _nft, uint[] memory _nftIds ) external override onlyOwner {

        IERC721 poolNFT = IERC721( NFT );

        if( _nft == poolNFT ){

            for (uint256 i = 0; i < _nftIds.length; i++) {

                poolNFT.safeTransferFrom( address( this ), owner(), _nftIds[i]);

                require( _TOKEN_IDS.remove( _TOKEN_IDS.indexOf(_nftIds[i]) ), "NFT transfer error");

            }

        } else {

            for (uint256 i = 0; i < _nftIds.length; i++) 

                _nft.safeTransferFrom( address( this ), owner(), _nftIds[i]);

        }

        emit NFTWithdrawal( owner(), _nftIds.length );

    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/// @title PoolTypes Are the type of pool available in this NFT swap
/// @author JorgeLpzGnz & CarlosMario714
contract PoolTypes {

    /// @notice available pool types
    enum PoolType {
        Sell, // you can sell NFTs and get tokens
        Buy,   // you can buy NFTs with tokens
        Trade  // A pool that make both
    }
    
}