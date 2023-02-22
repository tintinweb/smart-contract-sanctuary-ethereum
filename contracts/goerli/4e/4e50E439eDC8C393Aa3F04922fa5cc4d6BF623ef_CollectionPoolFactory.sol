// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

// @dev Solmate's ERC20 is used instead of OZ's ERC20 so we can use safeTransferLib for cheaper safeTransfers for
// ETH and ERC20 tokens
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {TransferLib} from "../lib/TransferLib.sol";

import {CollectionPool} from ".//CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionPoolERC20} from ".//CollectionPoolERC20.sol";
import {CollectionPoolCloner} from "../lib/CollectionPoolCloner.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionPoolEnumerableETH} from "./CollectionPoolEnumerableETH.sol";
import {CollectionPoolEnumerableERC20} from "./CollectionPoolEnumerableERC20.sol";
import {CollectionPoolMissingEnumerableETH} from "./CollectionPoolMissingEnumerableETH.sol";
import {CollectionPoolMissingEnumerableERC20} from "./CollectionPoolMissingEnumerableERC20.sol";
import {MultiPauser} from "../lib/MultiPauser.sol";

contract CollectionPoolFactory is
    Ownable,
    ReentrancyGuard,
    ERC721,
    ERC721URIStorage,
    MultiPauser,
    ICollectionPoolFactory
{
    using CollectionPoolCloner for address;
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;

    uint256 private constant CREATION_PAUSE = 0;
    uint256 private constant SWAP_PAUSE = 1;

    /**
     * @dev The MAX_PROTOCOL_FEE constant specifies the maximum fee that can be charged by the AMM pool contract
     * for facilitating token or NFT swaps on the decentralized exchange.
     * This fee is charged as a flat percentage of the final traded price for each swap,
     * and it is used to cover the costs associated with running the AMM pool contract and providing liquidity to the decentralized exchange.
     * This is used for NFT/TOKEN trading pools, that have a limited amount of dry powder
     */
    uint256 internal constant MAX_PROTOCOL_FEE = 0.1e6; // 10%, must <= 1 - MAX_FEE
    /**
     * @dev The MAX_CARRY_FEE constant specifies the maximum fee that can be charged by the AMM pool contract for facilitating token
     * or NFT swaps on the decentralized exchange. This fee is charged as a percentage of the fee set by the trading pool creator,
     * which is itself a percentage of the final traded price. This is used for TRADE pools, that form a continuous liquidity pool
     */
    uint256 internal constant MAX_CARRY_FEE = 0.5e6; // 50%

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    CollectionPoolEnumerableETH public immutable enumerableETHTemplate;
    CollectionPoolMissingEnumerableETH public immutable missingEnumerableETHTemplate;
    CollectionPoolEnumerableERC20 public immutable enumerableERC20Template;
    CollectionPoolMissingEnumerableERC20 public immutable missingEnumerableERC20Template;
    address payable public override protocolFeeRecipient;

    // Units are in base 1e6
    uint24 public override protocolFeeMultiplier;

    // Units are in base 1e6
    uint24 public override carryFeeMultiplier;

    mapping(ICurve => bool) public bondingCurveAllowed;
    mapping(address => bool) public override callAllowed;

    struct RouterStatus {
        bool allowed;
        bool wasEverAllowed;
    }

    mapping(CollectionRouter => RouterStatus) public override routerStatus;

    string public baseURI;

    modifier whenCreationNotPaused() {
        require(!creationPaused(), "Pool creation is paused");
        _;
    }

    event NewPool(address indexed collection, address poolAddress);
    event TokenDeposit(address poolAddress);
    event ProtocolFeeRecipientUpdate(address recipientAddress);
    event ProtocolFeeMultiplierUpdate(uint24 newMultiplier);
    event CarryFeeMultiplierUpdate(uint24 newMultiplier);
    event BondingCurveStatusUpdate(ICurve bondingCurve, bool isAllowed);
    event CallTargetStatusUpdate(address target, bool isAllowed);
    event RouterStatusUpdate(CollectionRouter router, bool isAllowed);
    event CreationPaused();
    event CreationUnpaused();
    event SwapPaused();
    event SwapUnpaused();

    constructor(
        CollectionPoolEnumerableETH _enumerableETHTemplate,
        CollectionPoolMissingEnumerableETH _missingEnumerableETHTemplate,
        CollectionPoolEnumerableERC20 _enumerableERC20Template,
        CollectionPoolMissingEnumerableERC20 _missingEnumerableERC20Template,
        address payable _protocolFeeRecipient,
        uint24 _protocolFeeMultiplier,
        uint24 _carryFeeMultiplier
    ) ERC721("Collectionswap", "CollectionLP") {
        enumerableETHTemplate = _enumerableETHTemplate;
        missingEnumerableETHTemplate = _missingEnumerableETHTemplate;
        enumerableERC20Template = _enumerableERC20Template;
        missingEnumerableERC20Template = _missingEnumerableERC20Template;
        protocolFeeRecipient = _protocolFeeRecipient;

        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Protocol fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;

        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Carry fee too large");
        carryFeeMultiplier = _carryFeeMultiplier;
    }

    /**
     * External view functions. Not pausable.
     */

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view {
        require(_isApprovedOrOwner(spender, tokenId), "Not approved");
    }

    /**
     * @dev See {ICollectionPoolFactory-poolAddressOf}.
     */
    function poolAddressOf(uint256 tokenId) public pure returns (address) {
        return address(uint160(tokenId));
    }

    /**
     * @notice Check if a pool is any of the templates deployed with this factory
     */
    function isPool(address potentialPool) public view returns (bool) {
        return isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.ENUMERABLE_ETH)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ERC20)
            || isPoolVariant(potentialPool, PoolVariant.MISSING_ENUMERABLE_ETH);
    }

    /**
     * @notice Checks if an address is a CollectionPool. Uses the fact that the pools are EIP-1167 minimal proxies.
     * @param potentialPool The address to check
     * @param variant The pool variant (NFT is enumerable or not, pool uses ETH or ERC20)
     * @dev The PoolCloner contract is a utility contract that is used by the PoolFactory contract to create new instances of automated market maker (AMM) pools.
     * @return True if the address is the specified pool variant, false otherwise
     */
    function isPoolVariant(address potentialPool, PoolVariant variant) public view returns (bool) {
        if (variant == PoolVariant.ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(address(this), address(enumerableERC20Template), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            return CollectionPoolCloner.isERC20PoolClone(
                address(this), address(missingEnumerableERC20Template), potentialPool
            );
        } else if (variant == PoolVariant.ENUMERABLE_ETH) {
            return CollectionPoolCloner.isETHPoolClone(address(this), address(enumerableETHTemplate), potentialPool);
        } else if (variant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            return
                CollectionPoolCloner.isETHPoolClone(address(this), address(missingEnumerableETHTemplate), potentialPool);
        } else {
            // invalid input
            return false;
        }
    }

    function tokenURI(uint256 tokenId) public view override (ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override (IERC165, ERC721) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function swapPaused() external view returns (bool) {
        return isPaused(SWAP_PAUSE);
    }

    function creationPaused() public view returns (bool) {
        return isPaused(CREATION_PAUSE);
    }

    /**
     * Pool creation functions. Pausable
     */
    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        whenCreationNotPaused
        returns (address pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        _initializePoolETH(CollectionPoolETH(payable(pool)), params);
    }

    /**
     * @notice Creates a filtered pool contract using EIP-1167.
     * @param params The parameters to create ETH pool
     * @param filterParams The parameters needed for the filtering functionality
     * @return pool The new pool
     */
    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        whenCreationNotPaused
        returns (address pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolETH(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolETH and check later.
        CollectionPoolETH _pool = CollectionPoolETH(payable(pool));
        _pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            _pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        _pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolETH(_pool, params);
    }

    function createPoolERC20(CreateERC20PoolParams calldata params)
        external
        whenCreationNotPaused
        returns (address pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolERC20(params);

        _initializePoolERC20(CollectionPoolERC20(payable(pool)), params);
    }

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        whenCreationNotPaused
        returns (address pool, uint256 tokenId)
    {
        (pool, tokenId) = _createPoolERC20(params);

        // Check if nfts are allowed before initializing to save gas on transferring nfts on revert.
        // If not, we could re-use createPoolERC20 and check later.
        CollectionPoolERC20 _pool = CollectionPoolERC20(payable(pool));
        _pool.setTokenIDFilter(filterParams.merkleRoot, filterParams.encodedTokenIDs);
        require(
            _pool.acceptsTokenIDs(params.initialNFTIDs, filterParams.initialProof, filterParams.initialProofFlags),
            "NFT not allowed"
        );
        _pool.setExternalFilter(address(filterParams.externalFilter));

        _initializePoolERC20(_pool, params);
    }

    /**
     * Deposit functions. Not pausable
     */

    /**
     * @dev Used to deposit NFTs into a pool after creation and emit an event for indexing
     */
    function depositNFTs(
        uint256[] calldata ids,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address recipient,
        address from
    ) external {
        bool _isPool = isPool(recipient);
        require(_isPool, "Not a pool");

        CollectionPool pool = CollectionPool(recipient);
        require(pool.acceptsTokenIDs(ids, proof, proofFlags), "NFTs not allowed");

        // transfer NFTs from caller to recipient
        _depositNFTs(pool.nft(), ids, pool, from);
    }

    /**
     * @dev Used to deposit ERC20 tokens into a pool after creation and emit an event for indexing
     */
    function depositERC20(ERC20 token, uint256 amount, address recipient, address from) external {
        bool _isPool = isPool(recipient);
        require(_isPool, "Not a pool");

        CollectionPool pool = CollectionPool(recipient);

        // transfer NFTs from caller to recipient
        token.safeTransferFrom(from, recipient, amount);
        pool.depositERC20Notification(token, amount);
    }

    /**
     * Withdrawal functions. Not pausable.
     */

    /*
     * @notice NFTs that don't match filter and any airdropped assets  must be rescued prior to calling this function.
     * Requires LP token owner to give allowance to this factory contract for asset withdrawals
     * which are sent directly to the LP token owner.
     */
    function burn(uint256 tokenId) external nonReentrant {
        require(_isApprovedOrOwner(msg.sender, tokenId), "Not approved");
        address poolAddress = poolAddressOf(tokenId);
        CollectionPool pool = CollectionPool(poolAddress);
        PoolVariant poolVariant = pool.poolVariant();

        // withdraw all ETH / ERC20
        if (poolVariant == PoolVariant.ENUMERABLE_ETH || poolVariant == PoolVariant.MISSING_ENUMERABLE_ETH) {
            // withdraw ETH, sent to owner of LP token
            CollectionPoolETH(payable(poolAddress)).withdrawAllETH();
        } else if (poolVariant == PoolVariant.ENUMERABLE_ERC20 || poolVariant == PoolVariant.MISSING_ENUMERABLE_ERC20) {
            // withdraw ERC20
            CollectionPoolERC20(poolAddress).withdrawAllERC20();
        }
        // then withdraw NFTs
        pool.withdrawERC721(pool.nft(), pool.getAllHeldIds());

        _burn(tokenId);
    }

    /**
     * Admin functions. Not pausable. Pointless because pauser/unpauser is owner
     * and all admin functions are onlyOwner.
     */

    function pauseCreation() external onlyOwner {
        pause(CREATION_PAUSE);
        emit CreationPaused();
    }

    function unpauseCreation() external onlyOwner {
        unpause(CREATION_PAUSE);
        emit CreationUnpaused();
    }

    function pauseSwap() external onlyOwner {
        pause(SWAP_PAUSE);
        emit SwapPaused();
    }

    function unpauseSwap() external onlyOwner {
        unpause(SWAP_PAUSE);
        emit SwapUnpaused();
    }

    /**
     * @notice Withdraws the ETH balance to the protocol fee recipient.
     * Only callable by the owner.
     */
    function withdrawETHProtocolFees() external onlyOwner {
        protocolFeeRecipient.safeTransferETH(address(this).balance);
    }

    /**
     * @notice Withdraws ERC20 tokens to the protocol fee recipient. Only callable by the owner.
     * @param token The token to transfer
     * @param amount The amount of tokens to transfer
     */
    function withdrawERC20ProtocolFees(ERC20 token, uint256 amount) external onlyOwner {
        token.safeTransfer(protocolFeeRecipient, amount);
    }

    /**
     * @notice Changes the protocol fee recipient address. Only callable by the owner.
     * @param _protocolFeeRecipient The new fee recipient
     */
    function changeProtocolFeeRecipient(address payable _protocolFeeRecipient) external onlyOwner {
        require(_protocolFeeRecipient != address(0), "0 address");
        protocolFeeRecipient = _protocolFeeRecipient;
        emit ProtocolFeeRecipientUpdate(_protocolFeeRecipient);
    }

    /**
     * @notice Changes the protocol fee multiplier. Only callable by the owner.
     * @param _protocolFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeProtocolFeeMultiplier(uint24 _protocolFeeMultiplier) external onlyOwner {
        require(_protocolFeeMultiplier <= MAX_PROTOCOL_FEE, "Fee too large");
        protocolFeeMultiplier = _protocolFeeMultiplier;
        emit ProtocolFeeMultiplierUpdate(_protocolFeeMultiplier);
    }

    /**
     * @notice Changes the carry fee multiplier. Only callable by the owner.
     * @param _carryFeeMultiplier The new fee multiplier, 18 decimals
     */
    function changeCarryFeeMultiplier(uint24 _carryFeeMultiplier) external onlyOwner {
        require(_carryFeeMultiplier <= MAX_CARRY_FEE, "Fee too large");
        carryFeeMultiplier = _carryFeeMultiplier;
        emit CarryFeeMultiplierUpdate(_carryFeeMultiplier);
    }

    /**
     * @notice Sets the whitelist status of a bonding curve contract. Only callable by the owner.
     * @param bondingCurve The bonding curve contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setBondingCurveAllowed(ICurve bondingCurve, bool isAllowed) external onlyOwner {
        bondingCurveAllowed[bondingCurve] = isAllowed;
        emit BondingCurveStatusUpdate(bondingCurve, isAllowed);
    }

    /**
     * @notice Sets the whitelist status of a contract to be called arbitrarily by a pool.
     * Only callable by the owner.
     * @param target The target contract
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setCallAllowed(address payable target, bool isAllowed) external onlyOwner {
        // ensure target is not / was not ever a router
        if (isAllowed) {
            require(!routerStatus[CollectionRouter(target)].wasEverAllowed, "Can't call router");
        }

        callAllowed[target] = isAllowed;
        emit CallTargetStatusUpdate(target, isAllowed);
    }

    /**
     * @notice Updates the router whitelist. Only callable by the owner.
     * @param _router The router
     * @param isAllowed True to whitelist, false to remove from whitelist
     */
    function setRouterAllowed(CollectionRouter _router, bool isAllowed) external onlyOwner {
        // ensure target is not arbitrarily callable by pools
        if (isAllowed) {
            require(!callAllowed[address(_router)], "Can't call router");
        }
        routerStatus[_router] = RouterStatus({allowed: isAllowed, wasEverAllowed: true});

        emit RouterStatusUpdate(_router, isAllowed);
    }

    function setBaseURI(string calldata _uri) external onlyOwner {
        baseURI = _uri;
    }

    function setTokenURI(string calldata _uri, uint256 tokenId) external onlyOwner {
        _setTokenURI(tokenId, _uri);
    }

    /**
     * Internal functions
     */
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _createPoolETH(CreateETHPoolParams calldata params) internal returns (address pool, uint256 tokenId) {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientFallback != address(0),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableETHTemplate) : address(missingEnumerableETHTemplate);
        } catch {
            template = address(missingEnumerableETHTemplate);
        }

        pool = template.cloneETHPool(this, params.bondingCurve, params.nft, uint8(params.poolType));

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(pool));

        emit NewPool(address(params.nft), pool);
    }

    function _initializePoolETH(CollectionPoolETH _pool, CreateETHPoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial ETH to pool
        payable(address(_pool)).safeTransferETH(msg.value);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool, msg.sender);
    }

    function _createPoolERC20(CreateERC20PoolParams calldata params) internal returns (address pool, uint256 tokenId) {
        require(bondingCurveAllowed[params.bondingCurve], "Bonding curve not whitelisted");

        require(
            params.royaltyNumerator == 0 || IERC165(params.nft).supportsInterface(_INTERFACE_ID_ERC2981)
                || params.royaltyRecipientFallback != address(0),
            "Nonzero royalty for non ERC2981 without fallback"
        );

        // Check to see if the NFT supports Enumerable to determine which template to use
        address template;
        try IERC165(address(params.nft)).supportsInterface(INTERFACE_ID_ERC721_ENUMERABLE) returns (bool isEnumerable) {
            template = isEnumerable ? address(enumerableERC20Template) : address(missingEnumerableERC20Template);
        } catch {
            template = address(missingEnumerableERC20Template);
        }

        pool = template.cloneERC20Pool(this, params.bondingCurve, params.nft, uint8(params.poolType), params.token);

        // issue new token
        tokenId = mint(params.receiver, CollectionPool(pool));

        emit NewPool(address(params.nft), pool);
    }

    function _initializePoolERC20(CollectionPoolERC20 _pool, CreateERC20PoolParams calldata _params) internal {
        // initialize pool
        _pool.initialize(
            _params.assetRecipient,
            _params.delta,
            _params.fee,
            _params.spotPrice,
            _params.props,
            _params.state,
            _params.royaltyNumerator,
            _params.royaltyRecipientFallback
        );

        // transfer initial tokens to pool
        _params.token.safeTransferFrom(msg.sender, address(_pool), _params.initialTokenBalance);

        // transfer initial NFTs from sender to pool and notify pool
        _depositNFTs(_params.nft, _params.initialNFTIDs, _pool, msg.sender);
    }

    /**
     * @dev Transfers NFTs from sender and notifies pool. `ids` must already have been verified
     */
    function _depositNFTs(IERC721 _nft, uint256[] calldata nftIds, CollectionPool pool, address from) internal {
        // transfer NFTs from caller to recipient
        TransferLib.bulkSafeTransferERC721From(_nft, from, address(pool), nftIds);
        pool.depositNFTsNotification(nftIds);
    }

    /*
     * @dev Mints LP token using pool address as Token ID
     */
    function mint(address recipient, CollectionPool pool) internal returns (uint256 tokenId) {
        tokenId = uint256(uint160(address(pool)));
        _safeMint(recipient, tokenId);
    }

    /**
     * Required override functions
     */

    /**
     * @notice Allows receiving ETH in order to receive protocol fees
     */
    receive() external payable {}

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override (ERC721) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId) internal override (ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// Forked from OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol), 
// to use a custom error

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

    error Reentrancy();

    function __ReentrancyGuard_init() internal {
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
        // On the first call to nonReentrant, _notEntered will be true
        if (_status == _ENTERED) revert Reentrancy();

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * A helper library for common transfer methods such as transferring multiple token ids of the same collection, or multiple single token id of one collection.
 */
library TransferLib {
    using SafeERC20 for IERC20;

    /**
     * @notice Safe transfer N token ids of 1 ERC721
     */
    function bulkSafeTransferERC721From(IERC721 token, address from, address to, uint256[] calldata tokenIds)
        internal
    {
        uint256 length = tokenIds.length;
        for (uint256 i; i < length;) {
            token.safeTransferFrom(from, to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice safe transfer N ERC20
     * @dev The length of tokens and values are assumed to be the same and should be checked before calling.
     */
    function batchSafeTransferERC20From(IERC20[] calldata tokens, address from, address to, uint256[] calldata values)
        internal
    {
        uint256 length = tokens.length;
        for (uint256 i; i < length;) {
            tokens[i].safeTransferFrom(from, to, values[i]);
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice safe transfer N token ids of N ERC721 respectively
     * @dev The length of tokens and values are assumed to be the same and should be checked before calling.
     */
    function batchSafeTransferERC721From(
        IERC721[] calldata tokens,
        address from,
        address to,
        uint256[] calldata tokenIds
    ) internal {
        uint256 length = tokens.length;
        for (uint256 i; i < length;) {
            tokens[i].safeTransferFrom(from, to, tokenIds[i]);
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ERC1155Holder} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {ReentrancyGuard} from "../lib/ReentrancyGuard.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";
import {TokenIDFilter} from "../filter/TokenIDFilter.sol";
import {MultiPauser} from "../lib/MultiPauser.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";

/// @title The base contract for an NFT/TOKEN AMM pool
/// @author Collection
/// @notice This implements the core swap logic from NFT to TOKEN
abstract contract CollectionPool is ReentrancyGuard, ERC1155Holder, TokenIDFilter, MultiPauser, ICollectionPool {
    /**
     * @dev The RoyaltyDue struct is used to track information about royalty payments that are due on NFT swaps.
     * It contains two fields:
     * @dev amount: The amount of the royalty payment, in the token's base units.
     * This value is calculated based on the price of the NFT being swapped, and the royaltyNumerator value set in the AMM pool contract.
     * @dev recipient: The address to which the royalty payment should be sent.
     * This value is determined by the NFT being swapped, and it is specified in the ERC2981 metadata for the NFT.
     * @dev When a user swaps an NFT for tokens using the AMM pool contract, a RoyaltyDue struct is created to track the amount
     * and recipient of the royalty payment that is due on the NFT swap. This struct is then used to facilitate the payment of
     * the royalty to the appropriate recipient.
     */
    struct RoyaltyDue {
        uint256 amount;
        address recipient;
    }

    /**
     * @dev The _INTERFACE_ID_ERC2981 constant specifies the interface ID for the ERC2981 standard. This standard is used for tracking
     * royalties on non-fungible tokens (NFTs). It defines a standard interface for NFTs that includes metadata about the royalties that
     * are due on the NFT when it is swapped or transferred.
     * @dev The _INTERFACE_ID_ERC2981 constant is used in the AMM pool contract to check whether an NFT being swapped implements the ERC2981
     * standard. If it does, the contract can use the metadata provided by the ERC2981 interface to facilitate the payment of royalties on the
     * NFT swap. If the NFT does not implement the ERC2981 standard, the contract will not track or pay royalties on the NFT swap.
     * This can be overridden by the royaltyNumerator field in the AMM pool contract.
     * @dev For more information about the ERC2981 standard, see https://eips.ethereum.org/EIPS/eip-2981
     */
    bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;

    bool private initialized;

    /**
     * @dev The MAX_FEE constant specifies the maximum fee you, the user, are allowed to charge for this AMM pool.
     * It is used to limit the amount of fees that can be charged by the AMM pool contract on NFT/token swaps.
     * @dev The MAX_FEE constant is used to ensure that the AMM pool does not charge excessive fees on NFT/token swaps.
     * It also helps to protect users from paying excessive fees when using the AMM pool contract.
     * @dev usage: 90%, must <= 1 - MAX_PROTOCOL_FEE (set in CollectionPoolFactory)
     * @dev If the bid/ask is 9/10 and the fee is set to 1%, then the fee is calculated as follows:
     * @dev For a buy order, the fee would be the bid price multiplied by the fee rate, or 9 * 1% = 0.09
     * @dev For a sell order, the fee would be the ask price multiplied by the fee rate, or 10 * 1% = 0.1
     * @dev The fee is charged as a percentage of the bid/ask price, and it is used to cover the costs associated with running the AMM pool
     * contract and providing liquidity to the decentralized exchange. The fee is deducted from the final price of the token or NFT swap,
     * and it is paid to the contract owner or to a designated fee recipient. The exact fee rate and fee recipient can be configured by the
     * contract owner when the AMM pool contract is deployed.
     */
    uint24 internal constant MAX_FEE = 0.9e6;

    // The spread between buy and sell prices, set to be a multiplier we apply to the buy price
    // Fee is only relevant for TRADE pools
    // Units are in base 1e6
    uint24 public fee;

    // For every NFT swapped, a fraction of the cost will be sent to the
    // ERC2981 payable address for the NFT swapped. The fraction is equal to
    // `royaltyNumerator / 1e6`
    uint24 public royaltyNumerator;

    // An address to which all royalties will be paid to if not address(0). This
    // is a fallback to ERC2981 royalties set by the NFT creator, and allows sending
    // royalties to arbitrary addresses if a collection does not support ERC2981.
    address payable public royaltyRecipientFallback;

    uint256 internal constant POOL_SWAP_PAUSE = 0;

    // The current price of the NFT
    // @dev This is generally used to mean the immediate sell price for the next marginal NFT.
    // However, this should NOT be assumed, as future bonding curves may use spotPrice in different ways.
    // Use getBuyNFTQuote and getSellNFTQuote for accurate pricing info.
    uint128 public spotPrice;

    // The parameter for the pool's bonding curve.
    // Units and meaning are bonding curve dependent.
    uint128 public delta;

    // If set to 0, NFTs/tokens sent by traders during trades will be sent to the pool.
    // Otherwise, assets will be sent to the set address. Not available for TRADE pools.
    address payable public assetRecipient;

    // The trade fee accrued from trades.
    uint256 public accruedTradeFee;

    // The properties used by the pool's bonding curve.
    bytes public props;

    // The state used by the pool's bonding curve.
    bytes public state;

    // If non-zero, contract implementing IExternalFilter checked on (pool buying) swaps
    IExternalFilter public externalFilter;

    // Events
    event SwapNFTInPool(
        uint256[] nftIds, uint256 inputAmount, uint256 tradeFee, uint256 protocolFee, RoyaltyDue[] royaltyDue
    );
    event SwapNFTOutPool(
        uint256[] nftIds, uint256 outputAmount, uint256 tradeFee, uint256 protocolFee, RoyaltyDue[] royaltyDue
    );
    event SpotPriceUpdate(uint128 newSpotPrice);
    event TokenDeposit(address indexed collection, address indexed token, uint256 amount);
    event TokenWithdrawal(address indexed collection, address indexed token, uint256 amount);
    event AccruedTradeFeeWithdrawal(address indexed collection, address indexed token, uint256 amount);
    event NFTDeposit(address indexed collection, uint256 numNFTs);
    event NFTWithdrawal(address indexed collection, uint256 numNFTs);
    event DeltaUpdate(uint128 newDelta);
    event FeeUpdate(uint96 newFee);
    event AssetRecipientChange(address a);
    event PropsUpdate(bytes newProps);
    event StateUpdate(bytes newState);
    event RoyaltyNumeratorUpdate(uint24 newRoyaltyNumerator);
    event RoyaltyRecipientFallbackUpdate(address payable newFallback);
    event PoolSwapPaused();
    event PoolSwapUnpaused();
    event ExternalFilterSet(address indexed collection, address indexed filterAddress);

    // Parameterized Errors
    error BondingCurveError(CurveErrorCodes.Error error);
    error InsufficientLiquidity(uint256 balance, uint256 accruedTradeFee);
    error RoyaltyNumeratorOverflow();
    error SwapsArePaused();
    error InvalidPoolParams();
    error NotAuthorized();
    error InvalidModification();
    error InvalidSwapQuantity();
    error InvalidSwap();
    error SlippageExceeded();
    error RouterNotTrusted();
    error NFTsNotAccepted();
    error NFTsNotAllowed();
    error CallError();
    error MulticallError();
    error InvalidExternalFilter();

    modifier onlyFactory() {
        if (msg.sender != address(factory())) revert NotAuthorized();
        _;
    }

    /**
     * @dev Use this whenever modifying the value of royaltyNumerator.
     */
    modifier validRoyaltyNumerator(uint24 _royaltyNumerator) {
        if (_royaltyNumerator >= 1e6) revert RoyaltyNumeratorOverflow();
        _;
    }

    modifier whenPoolSwapsNotPaused() {
        if (poolSwapsPaused()) revert SwapsArePaused();
        _;
    }

    function poolSwapsPaused() public view returns (bool) {
        return factory().swapPaused() || isPaused(POOL_SWAP_PAUSE);
    }

    /**
     * Ownable functions
     */

    /// @dev Returns the address of the current owner.
    function owner() public view virtual returns (address) {
        return IERC721(address(factory())).ownerOf(tokenId());
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != owner()) revert NotAuthorized();
        _;
    }

    /// @dev Throws if called by accounts that were not authorized by the owner.
    modifier onlyAuthorized() {
        factory().requireAuthorizedForToken(msg.sender, tokenId());
        _;
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Disallows setting to the zero address as a way to more gas-efficiently avoid reinitialization
    /// When ownership is transferred, if the new owner implements IOwnershipTransferCallback, we make a callback
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public virtual onlyOwner {
        IERC721(address(factory())).safeTransferFrom(msg.sender, newOwner, tokenId());
    }

    /**
     * @notice Called during pool creation to set initial parameters
     * @dev Only called once by factory to initialize.
     * We verify this by making sure that the current owner is address(0).
     * The Ownable library we use disallows setting the owner to be address(0), so this condition
     * should only be valid before the first initialize call.
     * @param _assetRecipient The address that will receive the TOKEN or NFT sent to this pool during swaps.
     * NOTE: If set to address(0), they will go to the pool itself.
     * @param _delta The initial delta of the bonding curve
     * @param _fee The initial % fee taken, if this is a trade pool
     * @param _spotPrice The initial price to sell an asset into the pool
     * @param _royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param _royaltyRecipientFallback An address to which all royalties will be paid to if not address(0).
     * This is a fallback to ERC2981 royalties set by the NFT creator, and allows sending royalties to
     * arbitrary addresses if a collection does not support ERC2981.
     */
    function initialize(
        address payable _assetRecipient,
        uint128 _delta,
        uint24 _fee,
        uint128 _spotPrice,
        bytes calldata _props,
        bytes calldata _state,
        uint24 _royaltyNumerator,
        address payable _royaltyRecipientFallback
    ) external payable validRoyaltyNumerator(_royaltyNumerator) {
        // Do not initialize if already initialized
        if (initialized) revert InvalidPoolParams();
        initialized = true;
        __ReentrancyGuard_init();

        ICurve _bondingCurve = bondingCurve();
        PoolType _poolType = poolType();

        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            // Only Trade Pools can have nonzero fee
            if (_fee != 0) revert InvalidPoolParams();
            assetRecipient = _assetRecipient;
        } else if (_poolType == PoolType.TRADE) {
            // Trade fee must be less than 90%
            if (_fee >= MAX_FEE) revert InvalidPoolParams();
            // Trade pools can't set asset recipient
            if (_assetRecipient != address(0)) revert InvalidPoolParams();
            fee = _fee;
        }
        if (!_bondingCurve.validate(_delta, _spotPrice, _props, _state)) revert InvalidPoolParams();
        delta = _delta;
        spotPrice = _spotPrice;
        props = _props;
        state = _state;
        royaltyNumerator = _royaltyNumerator;
        royaltyRecipientFallback = _royaltyRecipientFallback;
    }

    /**
     * External state-changing functions
     */

    /**
     * @notice Sets NFT token ID filter to allow only some NFTs into this pool. Pool must be empty
     * to call this function. This filter is checked on deposits and swapping NFTs into the pool.
     * Selling into the pool may require an additional check (see `setExternalFilter`).
     * @param merkleRoot Merkle root representing all allowed IDs
     * @param encodedTokenIDs Opaque encoded list of token IDs
     */
    function setTokenIDFilter(bytes32 merkleRoot, bytes calldata encodedTokenIDs) external {
        if (msg.sender != address(factory()) && msg.sender != owner()) revert NotAuthorized();
        // Pool must be empty to change filter
        if (nft().balanceOf(address(this)) != 0) revert InvalidModification();
        _setRootAndEmitAcceptedIDs(address(nft()), merkleRoot, encodedTokenIDs);
    }

    /**
     * @notice Sets an external contract that is consulted before any NFT is swapped into the pool.
     * Typically used to implement dynamic blocklists. Because it is dynamic, deposits are not
     * checked. See also `setTokenIDFilter`.
     */
    function setExternalFilter(address provider) external {
        if (msg.sender != address(factory()) && msg.sender != owner()) revert NotAuthorized();
        if (provider == address(0)) {
            externalFilter = IExternalFilter(provider);
            emit ExternalFilterSet(address(nft()), address(0));
            return;
        }

        if (isContract(provider)) {
            try IERC165(provider).supportsInterface(type(IExternalFilter).interfaceId) returns (bool isFilter) {
                if (isFilter) {
                    externalFilter = IExternalFilter(provider);
                    emit ExternalFilterSet(address(nft()), provider);
                    return;
                }
            } catch {}
        }

        revert InvalidExternalFilter();
    }

    /**
     * @notice Sends token to the pool in exchange for any `numNFTs` NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo.
     * This swap function is meant for users who are ID agnostic
     * @dev The nonReentrant modifier is in swapTokenForSpecificNFTs
     * @param numNFTs The number of NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable virtual whenPoolSwapsNotPaused returns (uint256 inputAmount) {
        IERC721 _nft = nft();
        // 0 < Swap quantity <= NFT balance
        if ((numNFTs <= 0) || (numNFTs > _nft.balanceOf(address(this)))) revert InvalidSwapQuantity();

        uint256[] memory tokenIds = _selectArbitraryNFTs(_nft, numNFTs);
        inputAmount = swapTokenForSpecificNFTs(tokenIds, maxExpectedTokenInput, nftRecipient, isRouter, routerCaller);
    }

    /**
     * @notice Sends token to the pool in exchange for a specific set of NFTs
     * @dev To compute the amount of token to send, call bondingCurve.getBuyInfo
     * This swap is meant for users who want specific IDs. Also higher chance of
     * reverting if some of the specified IDs leave the pool before the swap goes through.
     * @param nftIds The list of IDs of the NFTs to purchase
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @param nftRecipient The recipient of the NFTs
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return inputAmount The amount of token used for purchase
     */
    function swapTokenForSpecificNFTs(
        uint256[] memory nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) public payable virtual nonReentrant whenPoolSwapsNotPaused returns (uint256 inputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            // Can only buy from NFT or two sided pools
            if (_poolType == PoolType.TOKEN) revert InvalidSwap();
            if (nftIds.length <= 0) revert InvalidSwapQuantity();
        }

        // Prevent users from making a ridiculous pool, buying out their "sucker" price, and
        // then staking this pool with liquidity at really bad prices into a reward vault.
        if (isInCreationBlock()) revert InvalidSwap();

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        uint256 lastSwapPrice;
        (inputAmount, fees, lastSwapPrice) =
            _calculateBuyInfoAndUpdatePoolParams(nftIds.length, maxExpectedTokenInput, _bondingCurve, _factory);

        accruedTradeFee += fees.trade;
        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nftIds, fees.royalties);

        _pullTokenInputAndPayProtocolFee(inputAmount, isRouter, routerCaller, _factory, fees.protocol, royaltiesDue);

        _withdrawNFTs(nftRecipient, nftIds);

        _refundTokenToSender(inputAmount);

        emit SwapNFTOutPool(nftIds, inputAmount, fees.trade, fees.protocol, royaltiesDue);

        notifySwap(IPoolActivityMonitor.EventType.BOUGHT_NFT_FROM_POOL, nftIds.length, lastSwapPrice, inputAmount);
    }

    /**
     * @notice Sends a set of NFTs to the pool in exchange for token. Token must be allowed by
     * filters, see `setTokenIDFilter` and `setExternalFilter`.
     * @dev To compute the amount of token to that will be received, call bondingCurve.getSellInfo.
     * @param nfts The list of IDs of the NFTs to sell to the pool along with its Merkle multiproof.
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param tokenRecipient The recipient of the token output
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for
     * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     * @return outputAmount The amount of token received
     */
    function swapNFTsForToken(
        ICollectionPool.NFTs calldata nfts,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller,
        bytes calldata externalFilterContext
    ) external virtual nonReentrant whenPoolSwapsNotPaused returns (uint256 outputAmount) {
        // Store locally to remove extra calls
        ICollectionPoolFactory _factory = factory();
        ICurve _bondingCurve = bondingCurve();

        // Input validation
        {
            PoolType _poolType = poolType();
            // Can only sell to Token / 2-sided pools
            if (_poolType == PoolType.NFT) revert InvalidSwap();
            if (nfts.ids.length <= 0) revert InvalidSwapQuantity();
            if (!acceptsTokenIDs(nfts.ids, nfts.proof, nfts.proofFlags)) revert NFTsNotAccepted();
            if (
                address(externalFilter) != address(0)
                    && !externalFilter.areNFTsAllowed(address(nft()), nfts.ids, externalFilterContext)
            ) {
                revert NFTsNotAllowed();
            }
        }

        // Prevent users from making a ridiculous pool, buying out their "sucker" price, and
        // then staking this pool with liquidity at really bad prices into a reward vault
        if (isInCreationBlock()) revert InvalidSwap();

        // Call bonding curve for pricing information
        ICurve.Fees memory fees;
        uint256 lastSwapPrice;
        (outputAmount, fees, lastSwapPrice) =
            _calculateSellInfoAndUpdatePoolParams(nfts.ids.length, minExpectedTokenOutput, _bondingCurve);

        // Accrue trade fees before sending token output. This ensures that the balance is always sufficient for trade fee withdrawal.
        accruedTradeFee += fees.trade;

        RoyaltyDue[] memory royaltiesDue = _getRoyaltiesDue(nft(), nfts.ids, fees.royalties);

        _sendTokenOutput(tokenRecipient, outputAmount, royaltiesDue);

        _payProtocolFeeFromPool(_factory, fees.protocol);

        _takeNFTsFromSender(nfts.ids, _factory, isRouter, routerCaller);

        emit SwapNFTInPool(nfts.ids, outputAmount, fees.trade, fees.protocol, royaltiesDue);

        uint256[] memory amounts = new uint256[](3);
        amounts[0] = nfts.ids.length;
        amounts[1] = lastSwapPrice;
        amounts[2] = outputAmount;

        notifySwap(IPoolActivityMonitor.EventType.SOLD_NFT_TO_POOL, nfts.ids.length, lastSwapPrice, outputAmount);
    }

    function balanceToFulfillSellNFT(uint256 numNFTs)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 balance)
    {
        uint256 totalAmount;
        (error,, totalAmount,,) = getSellNFTQuote(numNFTs);
        balance = accruedTradeFee + totalAmount;
    }

    /**
     * View functions
     */

    /**
     * @notice Checks if NFTs is allowed in this pool
     * @param tokenID NFT ID
     * @param proof Merkle proof
     */
    function acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) public view returns (bool) {
        return _acceptsTokenID(tokenID, proof);
    }

    /**
     * @notice Checks if list of NFTs are allowed in this pool using Merkle multiproof and flags
     * @param tokenIDs List of NFT IDs
     * @param proof Merkle multiproof
     * @param proofFlags Merkle multiproof flags
     */
    function acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        public
        view
        returns (bool)
    {
        return _acceptsTokenIDs(tokenIDs, proof, proofFlags);
    }

    /**
     * @dev Used as read function to query the bonding curve for buy pricing info
     * @param numNFTs The number of NFTs to buy from the pool
     */
    function getBuyNFTQuote(uint256 numNFTs)
        public
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params memory newParams,
            uint256 totalAmount,
            uint256 inputAmount,
            ICurve.Fees memory fees
        )
    {
        (error, newParams, inputAmount, fees,) = bondingCurve().getBuyInfo(curveParams(), numNFTs, feeMultipliers());

        // Since inputAmount is already inclusive of fees.
        totalAmount = inputAmount;
    }

    /**
     * @dev Used as read function to query the bonding curve for sell pricing info
     * @param numNFTs The number of NFTs to sell to the pool
     */
    function getSellNFTQuote(uint256 numNFTs)
        public
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params memory newParams,
            uint256 totalAmount,
            uint256 outputAmount,
            ICurve.Fees memory fees
        )
    {
        (error, newParams, outputAmount, fees,) = bondingCurve().getSellInfo(curveParams(), numNFTs, feeMultipliers());

        totalAmount = outputAmount + fees.trade + fees.protocol;
        uint256 length = fees.royalties.length;
        for (uint256 i; i < length;) {
            totalAmount += fees.royalties[i];
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Returns all NFT IDs held by the pool
     */
    function getAllHeldIds() external view virtual returns (uint256[] memory);

    /**
     * @notice Returns LP token ID for this pool
     */
    function tokenId() public view returns (uint256 _tokenId) {
        _tokenId = uint256(uint160(address(this)));
    }

    /**
     * @notice Returns the pool's variant (NFT is enumerable or not, pool uses ETH or ERC20)
     */
    function poolVariant() public pure virtual returns (ICollectionPoolFactory.PoolVariant);

    function factory() public pure returns (ICollectionPoolFactory _factory) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _factory := shr(0x60, calldataload(sub(calldatasize(), paramsLength)))
        }
    }

    /**
     * @notice Returns the type of bonding curve that parameterizes the pool
     */
    function bondingCurve() public pure returns (ICurve _bondingCurve) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _bondingCurve := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 20)))
        }
    }

    /**
     * @notice Returns the NFT collection that parameterizes the pool
     */
    function nft() public pure returns (IERC721 _nft) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _nft := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 40)))
        }
    }

    /**
     * @notice Returns the pool's type (TOKEN/NFT/TRADE)
     */
    function poolType() public pure returns (PoolType _poolType) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _poolType := shr(0xf8, calldataload(add(sub(calldatasize(), paramsLength), 60)))
        }
    }

    function isInCreationBlock() private view returns (bool _isInCreationBlock) {
        uint256 paramsLength = _immutableParamsLength();
        uint256 _creationBlockNumber;

        assembly {
            _creationBlockNumber := shr(0xe0, calldataload(add(sub(calldatasize(), paramsLength), 61)))
        }
        // Only the (lower) 32 bits are stored (~2000 years with 15s blocks). We compare with uint32(block.number)
        // so we can still detect if we're in the same block in the unlikely event of an overflow
        _isInCreationBlock = uint32(_creationBlockNumber) == uint32(block.number);
    }

    /**
     * @notice Handles royalty recipient and fallback logic. Attempts to honor
     * ERC2981 where possible, followed by the owner's set fallback. If neither
     * is a valid address, then royalties go to the asset recipient for this
     * pool.
     * @param erc2981Recipient The address to which royalties should be paid as
     * returned by the IERC2981 `royaltyInfo` method. `payable(address(0))` if
     * the nft does not implement IERC2981.
     * @return The address to which royalties should be paid
     */
    function getRoyaltyRecipient(address payable erc2981Recipient) public view returns (address payable) {
        if (erc2981Recipient != address(0)) {
            return erc2981Recipient;
        }

        // No recipient from ERC2981 royaltyInfo method. Check if we have a fallback
        if (royaltyRecipientFallback != address(0)) {
            return royaltyRecipientFallback;
        }

        // No ERC2981 recipient or recipient fallback. Default to pool's assetRecipient.
        return getAssetRecipient();
    }

    /**
     * @notice Returns the address that assets that receives assets when a swap is done with this pool
     * Can be set to another address by the owner, if set to address(0), defaults to the pool's own address
     */
    function getAssetRecipient() public view returns (address payable _assetRecipient) {
        // If it's a TRADE pool, we know the recipient is 0 (TRADE pools can't set asset recipients)
        // so just return address(this)
        if (poolType() == PoolType.TRADE) {
            return payable(address(this));
        }

        // Otherwise, we return the recipient if it's been set
        // or replace it with address(this) if it's 0
        _assetRecipient = assetRecipient;
        if (_assetRecipient == address(0)) {
            // Tokens will be transferred to address(this)
            _assetRecipient = payable(address(this));
        }
    }

    function curveParams() public view returns (ICurve.Params memory params) {
        return ICurve.Params(spotPrice, delta, props, state);
    }

    function feeMultipliers() public view returns (ICurve.FeeMultipliers memory) {
        uint24 protocolFeeMultiplier;
        uint24 carryFeeMultiplier;

        PoolType _poolType = poolType();
        if ((_poolType == PoolType.TOKEN) || (_poolType == PoolType.NFT)) {
            protocolFeeMultiplier = factory().protocolFeeMultiplier();
        } else if (_poolType == PoolType.TRADE) {
            carryFeeMultiplier = factory().carryFeeMultiplier();
        }

        return ICurve.FeeMultipliers(fee, protocolFeeMultiplier, royaltyNumerator, carryFeeMultiplier);
    }

    /**
     * Internal functions
     */

    /**
     * @notice Calculates the amount needed to be sent into the pool for a buy and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to purchase from the pool
     * @param maxExpectedTokenInput The maximum acceptable cost from the sender. If the actual
     * amount is greater than this value, the transaction will be reverted.
     * @return inputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function _calculateBuyInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        ICurve _bondingCurve,
        ICollectionPoolFactory
    ) internal returns (uint256 inputAmount, ICurve.Fees memory fees, uint256 lastSwapPrice) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, inputAmount, fees, lastSwapPrice) =
            _bondingCurve.getBuyInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if input is more than expected
        if (inputAmount > maxExpectedTokenInput) revert SlippageExceeded();

        _updatePoolParams(params, newParams);
    }

    /**
     * @notice Calculates the amount needed to be sent by the pool for a sell and adjusts spot price or delta if necessary
     * @param numNFTs The amount of NFTs to send to the the pool
     * @param minExpectedTokenOutput The minimum acceptable token received by the sender. If the actual
     * amount is less than this value, the transaction will be reverted.
     * @param _bondingCurve The bonding curve used to fetch pricing information from
     * @return outputAmount The amount of tokens total tokens receive
     * @return fees The amount of tokens to send as fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function _calculateSellInfoAndUpdatePoolParams(
        uint256 numNFTs,
        uint256 minExpectedTokenOutput,
        ICurve _bondingCurve
    ) internal returns (uint256 outputAmount, ICurve.Fees memory fees, uint256 lastSwapPrice) {
        CurveErrorCodes.Error error;
        ICurve.Params memory params = curveParams();
        ICurve.Params memory newParams;
        (error, newParams, outputAmount, fees, lastSwapPrice) =
            _bondingCurve.getSellInfo(params, numNFTs, feeMultipliers());

        // Revert if bonding curve had an error
        if (error != CurveErrorCodes.Error.OK) {
            revert BondingCurveError(error);
        }

        // Revert if output is too little
        if (outputAmount < minExpectedTokenOutput) revert SlippageExceeded();

        _updatePoolParams(params, newParams);
    }

    function _updatePoolParams(ICurve.Params memory params, ICurve.Params memory newParams) internal {
        // Consolidate writes to save gas
        if (params.spotPrice != newParams.spotPrice || params.delta != newParams.delta) {
            spotPrice = newParams.spotPrice;
            delta = newParams.delta;
        }

        if (keccak256(params.state) != keccak256(newParams.state)) {
            state = newParams.state;

            emit StateUpdate(newParams.state);
        }

        // Emit spot price update if it has been updated
        if (params.spotPrice != newParams.spotPrice) {
            emit SpotPriceUpdate(newParams.spotPrice);
        }

        // Emit delta update if it has been updated
        if (params.delta != newParams.delta) {
            emit DeltaUpdate(newParams.delta);
        }
    }

    /**
     * @notice Pulls the token input of a trade from the trader and pays the protocol fee.
     * @param inputAmount The amount of tokens to be sent
     * @param isRouter Whether or not the caller is CollectionRouter
     * @param routerCaller If called from CollectionRouter, store the original caller
     * @param _factory The CollectionPoolFactory which stores CollectionRouter allowlist info
     * @param protocolFee The protocol fee to be paid
     * @param royaltyAmounts An array of royalties to pay
     */
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltyAmounts
    ) internal virtual;

    /**
     * @notice Sends excess tokens back to the caller (if applicable)
     * @dev We send ETH back to the caller even when called from CollectionRouter because we do an aggregate slippage check for certain bulk swaps. (Instead of sending directly back to the router caller)
     * Excess ETH sent for one swap can then be used to help pay for the next swap.
     */
    function _refundTokenToSender(uint256 inputAmount) internal virtual;

    /**
     * @notice Sends protocol fee (if it exists) back to the CollectionPoolFactory from the pool
     */
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal virtual;

    /**
     * @notice Sends tokens to a recipient and pays royalties owed
     * @param tokenRecipient The address receiving the tokens
     * @param outputAmount The amount of tokens to send
     * @param royaltiesDue An array of royalties to pay
     */
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        virtual;

    /**
     * @notice Select arbitrary NFTs from pool
     * @param _nft The address of the NFT to send
     * @param numNFTs The number of NFTs to send
     */
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs) internal virtual returns (uint256[] memory tokenIds);

    /**
     * @notice Takes NFTs from the caller and sends them into the pool's asset recipient
     * @dev This is used by the CollectionPool's swapNFTForToken function.
     * @param nftIds The specific NFT IDs to take
     * @param isRouter True if calling from CollectionRouter, false otherwise. Not used for * ETH pools.
     * @param routerCaller If isRouter is true, ERC20 tokens will be transferred from this address. Not used for
     * ETH pools.
     */
    function _takeNFTsFromSender(
        uint256[] calldata nftIds,
        ICollectionPoolFactory _factory,
        bool isRouter,
        address routerCaller
    ) internal virtual {
        {
            address _assetRecipient = getAssetRecipient();
            uint256 numNFTs = nftIds.length;

            if (isRouter) {
                // Verify if router is allowed
                CollectionRouter router = CollectionRouter(payable(msg.sender));

                {
                    (bool routerAllowed,) = _factory.routerStatus(router);
                    if (!routerAllowed) revert RouterNotTrusted();
                }

                IERC721 _nft = nft();

                // Call router to pull NFTs
                // If more than 1 NFT is being transfered, do balance check instead of ownership check,
                // as pools are indifferent between NFTs from the same collection
                if (numNFTs > 1) {
                    uint256 beforeBalance = _nft.balanceOf(_assetRecipient);
                    for (uint256 i = 0; i < numNFTs;) {
                        router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[i], poolVariant());

                        unchecked {
                            ++i;
                        }
                    }
                    // Check if NFT was transferred
                    if ((_nft.balanceOf(_assetRecipient) - beforeBalance) != numNFTs) revert RouterNotTrusted();
                } else {
                    router.poolTransferNFTFrom(_nft, routerCaller, _assetRecipient, nftIds[0], poolVariant());
                    // Check if NFT was transferred
                    if (_nft.ownerOf(nftIds[0]) != _assetRecipient) revert RouterNotTrusted();
                }

                if (_assetRecipient == address(this)) {
                    _depositNFTsNotification(nftIds);
                }
            } else {
                // Pull NFTs directly from sender
                if (_assetRecipient == address(this)) {
                    _depositNFTs(msg.sender, nftIds);
                } else {
                    TransferLib.bulkSafeTransferERC721From(nft(), msg.sender, _assetRecipient, nftIds);
                }
            }
        }
    }

    /**
     * @dev Used internally to grab pool parameters from calldata, see CollectionPoolCloner for technical details
     */
    function _immutableParamsLength() internal pure virtual returns (uint256);

    /**
     * Owner functions
     */

    /// @inheritdoc ICollectionPool
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external override onlyAuthorized {
        IERC721 _nft = nft();
        address _owner = owner();

        // If it's not the pool's NFT, just withdraw normally
        if (a != _nft) {
            TransferLib.bulkSafeTransferERC721From(a, address(this), _owner, nftIds);
        }
        // Otherwise, withdraw and also remove the ID from the ID set
        else {
            _withdrawNFTs(_owner, nftIds);

            emit NFTWithdrawal(address(_nft), nftIds.length);
            /// @dev No need to notify pool monitors as pool monitors own the pool,
            /// thus only the monitor can withdraw from the pool and notifications
            /// are redundant
        }
    }

    /**
     * @notice Rescues ERC1155 tokens from the pool to the owner. Only callable by the owner.
     * @param a The NFT to transfer
     * @param ids The NFT ids to transfer
     * @param amounts The amounts of each id to transfer
     */
    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external onlyAuthorized {
        a.safeBatchTransferFrom(address(this), owner(), ids, amounts, "");
        // TODO update idSet or not?
    }

    /**
     * @notice Withdraws the accrued trade fee owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAccruedTradeFee() external virtual;

    function pausePoolSwaps() external onlyOwner {
        pause(POOL_SWAP_PAUSE);
    }

    function unpausePoolSwaps() external onlyOwner {
        unpause(POOL_SWAP_PAUSE);
    }

    /**
     * @notice Updates the selling spot price. Only callable by the owner.
     * @param newSpotPrice The new selling spot price value, in Token
     */
    function changeSpotPrice(uint128 newSpotPrice) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateSpotPrice(newSpotPrice)) revert InvalidModification();
        if (spotPrice != newSpotPrice) {
            spotPrice = newSpotPrice;
            emit SpotPriceUpdate(newSpotPrice);
        }
    }

    /**
     * @notice Updates the delta parameter. Only callable by the owner.
     * @param newDelta The new delta parameter
     */
    function changeDelta(uint128 newDelta) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateDelta(newDelta)) revert InvalidModification();
        if (delta != newDelta) {
            delta = newDelta;
            emit DeltaUpdate(newDelta);
        }
    }

    /**
     * @notice Updates the props parameter. Only callable by the owner.
     * @param newProps The new props parameter
     */
    function changeProps(bytes calldata newProps) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateProps(newProps)) revert InvalidModification();
        if (keccak256(props) != keccak256(newProps)) {
            props = newProps;
            emit PropsUpdate(newProps);
        }
    }

    /**
     * @notice Updates the state parameter. Only callable by the owner.
     * @param newState The new state parameter
     */
    function changeState(bytes calldata newState) external onlyOwner {
        ICurve _bondingCurve = bondingCurve();
        if (!_bondingCurve.validateState(newState)) revert InvalidModification();
        if (keccak256(state) != keccak256(newState)) {
            state = newState;
            emit StateUpdate(newState);
        }
    }

    /**
     * @notice Updates the fee taken by the LP. Only callable by the owner.
     * Only callable if the pool is a Trade pool. Reverts if the fee is >=
     * MAX_FEE.
     * @param newFee The new LP fee percentage, 18 decimals
     */
    function changeFee(uint24 newFee) external onlyOwner {
        PoolType _poolType = poolType();
        // Only trade pools can set fee. Max fee must be strictly greater too.
        if (_poolType != PoolType.TRADE || newFee >= MAX_FEE) revert InvalidModification();
        if (fee != newFee) {
            fee = newFee;
            emit FeeUpdate(newFee);
        }
    }

    /**
     * @notice Changes the address that will receive assets received from
     * trades. Only callable by the owner.
     * @param newRecipient The new asset recipient
     */
    function changeAssetRecipient(address payable newRecipient) external onlyOwner {
        PoolType _poolType = poolType();
        // Trade pools cannot set asset recipient
        if (_poolType == PoolType.TRADE) revert InvalidModification();
        if (assetRecipient != newRecipient) {
            assetRecipient = newRecipient;
            emit AssetRecipientChange(newRecipient);
        }
    }

    function changeRoyaltyNumerator(uint24 newRoyaltyNumerator)
        external
        onlyOwner
        validRoyaltyNumerator(newRoyaltyNumerator)
    {
        // Check whether the resulting combination of numerator and fallback is valid
        if (!_validRoyaltyState(newRoyaltyNumerator, royaltyRecipientFallback, nft())) revert InvalidModification();
        royaltyNumerator = newRoyaltyNumerator;
        emit RoyaltyNumeratorUpdate(newRoyaltyNumerator);
    }

    function changeRoyaltyRecipientFallback(address payable newFallback) external onlyOwner {
        if (!_validRoyaltyState(royaltyNumerator, newFallback, nft())) revert InvalidModification();
        royaltyRecipientFallback = newFallback;
        emit RoyaltyRecipientFallbackUpdate(newFallback);
    }

    /**
     * @notice Allows the pool to make arbitrary external calls to contracts
     * whitelisted by the protocol. Only callable by authorized parties.
     * @param target The contract to call
     * @param data The calldata to pass to the contract
     */
    function call(address payable target, bytes calldata data) external onlyAuthorized {
        ICollectionPoolFactory _factory = factory();
        // Only whitelisted targets can be called
        if (!_factory.callAllowed(target)) revert CallError();
        (bool result,) = target.call{value: 0}(data);
        if (!result) revert CallError();
    }

    /**
     * @notice Allows owner to batch multiple calls, forked from: https://github.com/boringcrypto/BoringSolidity/blob/master/contracts/BoringBatchable.sol
     * @dev Intended for withdrawing/altering pool pricing in one tx, only callable by owner, cannot change owner
     * @param calls The calldata for each call to make
     * @param revertOnFail Whether or not to revert the entire tx if any of the calls fail
     */
    function multicall(bytes[] calldata calls, bool revertOnFail) external onlyAuthorized {
        for (uint256 i; i < calls.length;) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }

            unchecked {
                ++i;
            }
        }

        // Prevent multicall from malicious frontend sneaking in ownership change
        if (owner() != msg.sender) revert MulticallError();
    }

    /**
     * @param _returnData The data returned from a multicall result
     * @dev Used to grab the revert string from the underlying call
     */
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    function _getRoyaltiesDue(IERC721 _nft, uint256[] memory nftIds, uint256[] memory royaltyAmounts)
        private
        view
        returns (RoyaltyDue[] memory royaltiesDue)
    {
        uint256 length = royaltyAmounts.length;
        royaltiesDue = new RoyaltyDue[](length);
        bool is2981 = IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981);
        if (royaltyNumerator != 0) {
            for (uint256 i = 0; i < length;) {
                // 2981 recipient, if nft is 2981 and recipient is set.
                address recipient2981;
                if (is2981) {
                    (recipient2981,) = IERC2981(address(_nft)).royaltyInfo(nftIds[i], 0);
                }

                address recipient = getRoyaltyRecipient(payable(recipient2981));
                royaltiesDue[i] = RoyaltyDue({amount: royaltyAmounts[i], recipient: recipient});

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Returns true if it's valid to set the contract variables to the
     * variables passed to this function.
     */
    function _validRoyaltyState(uint256 _royaltyNumerator, address payable _royaltyRecipientFallback, IERC721 _nft)
        internal
        view
        returns (bool)
    {
        return
        // Supports 2981 interface to tell us who gets royalties or
        (
            IERC165(_nft).supportsInterface(_INTERFACE_ID_ERC2981)
            // There is a fallback so we always know where to send royaltiers or
            || _royaltyRecipientFallback != address(0)
            // Royalties will not be paid
            || _royaltyNumerator == 0
        );
    }

    function notifySwap(
        IPoolActivityMonitor.EventType eventType,
        uint256 numNFTs,
        uint256 lastSwapPrice,
        uint256 swapValue
    ) internal {
        uint256[] memory amounts = new uint256[](3);
        amounts[0] = numNFTs;
        amounts[1] = lastSwapPrice;
        amounts[2] = swapValue;

        notifyChanges(eventType, amounts);
    }

    function notifyDeposit(IPoolActivityMonitor.EventType eventType, uint256 amount) internal {
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = amount;

        notifyChanges(eventType, amounts);
    }

    /**
     * @dev The only limitation of this function is that contracts calling `isContract`
     * from within their constructor will have extcodesize 0 and thus return false.
     * Thus, note that this function should not be used indirectly by any contract
     * constructors
     */
    function isContract(address _addr) private view returns (bool) {
        uint32 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

    function notifyChanges(IPoolActivityMonitor.EventType eventType, uint256[] memory amounts) internal {
        if (isContract(owner())) {
            try IERC165(owner()).supportsInterface(type(IPoolActivityMonitor).interfaceId) returns (bool isMonitored) {
                if (isMonitored) {
                    IPoolActivityMonitor(owner()).onBalancesChanged(address(this), eventType, amounts);
                }
            } catch {}
        }
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /// @inheritdoc ICollectionPool
    function depositNFTsNotification(uint256[] calldata nftIds) external override onlyFactory {
        _depositNFTsNotification(nftIds);

        emit NFTDeposit(address(nft()), nftIds.length);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_NFT, nftIds.length);
    }

    function depositNFTs(uint256[] calldata nftIds, bytes32[] calldata proof, bool[] calldata proofFlags) external {
        if (!acceptsTokenIDs(nftIds, proof, proofFlags)) revert NFTsNotAccepted();
        _depositNFTs(msg.sender, nftIds);

        emit NFTDeposit(address(nft()), nftIds.length);

        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_NFT, nftIds.length);
    }

    /**
     * @dev Deposit NFTs from given address. NFT IDs must have been validated against the filter.
     */
    function _depositNFTs(address from, uint256[] calldata nftIds) internal virtual;

    /**
     * @dev Used to indicate deposited NFTs.
     */
    function _depositNFTsNotification(uint256[] calldata nftIds) internal virtual;

    /**
     * @notice Sends specific NFTs to a recipient address
     * @param to The receiving address for the NFTs
     * @param nftIds The specific IDs of NFTs to send
     */
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal virtual;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";

contract CollectionRouter {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    struct PoolSwapAny {
        CollectionPool pool;
        uint256 numItems;
    }

    struct PoolSwapSpecific {
        CollectionPool pool;
        uint256[] nftIds;
        bytes32[] proof;
        bool[] proofFlags;
        /// @dev only used for selling into pools
        bytes externalFilterContext;
    }

    struct RobustPoolSwapAny {
        PoolSwapAny swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecific {
        PoolSwapSpecific swapInfo;
        uint256 maxCost;
    }

    struct RobustPoolSwapSpecificForToken {
        PoolSwapSpecific swapInfo;
        uint256 minOutput;
    }

    struct NFTsForAnyNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapAny[] tokenToNFTTrades;
    }

    struct NFTsForSpecificNFTsTrade {
        PoolSwapSpecific[] nftToTokenTrades;
        PoolSwapSpecific[] tokenToNFTTrades;
    }

    struct RobustPoolNFTsFoTokenAndTokenforNFTsTrade {
        RobustPoolSwapSpecific[] tokenToNFTTrades;
        RobustPoolSwapSpecificForToken[] nftToTokenTrades;
        uint256 inputAmount;
        address payable tokenRecipient;
        address nftRecipient;
    }

    modifier checkDeadline(uint256 deadline) {
        _checkDeadline(deadline);
        _;
    }

    ICollectionPoolFactory public immutable factory;

    constructor(ICollectionPoolFactory _factory) {
        factory = _factory;
    }

    /**
     * ETH swaps
     */

    /**
     * @notice Swaps ETH into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForAnyNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps ETH into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent ETH amount
     */
    function swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapETHForSpecificNFTs(swapList, msg.value, ethRecipient, nftRecipient);
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForAnyNFTsThroughETH(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for any NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount =
            _swapETHForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * ETH as the intermediary.
     * @param trade The struct containing all NFT-to-ETH swaps and ETH-to-NFT swaps.
     * @param minOutput The minimum acceptable total excess ETH received
     * @param ethRecipient The address that will receive the ETH output
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH received
     */
    function swapNFTsForSpecificNFTsThroughETH(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 minOutput,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ETH
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(address(this)));

        // Add extra value to buy NFTs
        outputAmount += msg.value;

        // Swap ETH for specific NFTs
        // cost <= inputValue = outputAmount - minOutput, so outputAmount' = (outputAmount - minOutput - cost) + minOutput >= minOutput
        outputAmount = _swapETHForSpecificNFTs(
            trade.tokenToNFTTrades, outputAmount - minOutput, ethRecipient, nftRecipient
        ) + minOutput;
    }

    /**
     * ERC20 swaps
     *
     * Note: All ERC20 swaps assume that a single ERC20 token is used for all the pools involved.
     * Swapping using multiple tokens in the same transaction is possible, but the slippage checks
     * & the return values will be meaningless, and may lead to undefined behavior.
     *
     * Note: The sender should ideally grant infinite token approval to the router in order for NFT-to-NFT
     * swaps to work smoothly.
     */

    /**
     * @notice Swaps ERC20 tokens into NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForAnyNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps ERC20 tokens into specific NFTs using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function swapERC20ForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 remainingValue) {
        return _swapERC20ForSpecificNFTs(swapList, inputAmount, nftRecipient);
    }

    /**
     * @notice Swaps NFTs into ETH/ERC20 using multiple pools.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param minOutput The minimum acceptable total tokens received
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total tokens received
     */
    function swapNFTsForToken(
        PoolSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        return _swapNFTsForToken(swapList, minOutput, payable(tokenRecipient));
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForAnyNFTsThroughERC20(
        NFTsForAnyNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for any NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount = _swapERC20ForAnyNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * @notice Swaps one set of NFTs into another set of specific NFTs using multiple pools, using
     * an ERC20 token as the intermediary.
     * @param trade The struct containing all NFT-to-ERC20 swaps and ERC20-to-NFT swaps.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param minOutput The minimum acceptable total excess tokens received
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ERC20 tokens received
     */
    function swapNFTsForSpecificNFTsThroughERC20(
        NFTsForSpecificNFTsTrade calldata trade,
        uint256 inputAmount,
        uint256 minOutput,
        address nftRecipient,
        uint256 deadline
    ) external checkDeadline(deadline) returns (uint256 outputAmount) {
        // Swap NFTs for ERC20
        // minOutput of swap set to 0 since we're doing an aggregate slippage check
        // output tokens are sent to msg.sender
        outputAmount = _swapNFTsForToken(trade.nftToTokenTrades, 0, payable(msg.sender));

        // Add extra value to buy NFTs
        outputAmount += inputAmount;

        // Swap ERC20 for specific NFTs
        // cost <= maxCost = outputAmount - minOutput, so outputAmount' = outputAmount - cost >= minOutput
        // input tokens are taken directly from msg.sender
        outputAmount =
            _swapERC20ForSpecificNFTs(trade.tokenToNFTTrades, outputAmount - minOutput, nftRecipient) + minOutput;
    }

    /**
     * Robust Swaps
     * These are "robust" versions of the NFT<>Token swap functions which will never revert due to slippage
     * Instead, users specify a per-swap max cost. If the price changes more than the user specifies, no swap is attempted. This allows users to specify a batch of swaps, and execute as many of them as possible.
     */

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @notice Swaps as much ETH for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;

        // Try doing each swap
        uint256 poolCost;
        CurveErrorCodes.Error error;
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs{value: poolCost}(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @dev We assume msg.value >= sum of values in maxCostPerPool
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param ethRecipient The address that will receive the unspent ETH input
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapETHForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) public payable virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = msg.value;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                // We know how much ETH to send because we already did the math above
                // So we just send that much
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for any NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the number of NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForAnyNFTs(
        RobustPoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) external virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.numItems);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForAnyNFTs(
                    swapList[i].swapInfo.numItems, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many ERC20 tokens for specific NFTs as possible, respecting the per-swap max cost.
     * @param swapList The list of pools to trade with and the IDs of the NFTs to buy from each.
     * @param inputAmount The amount of ERC20 tokens to add to the ERC20-to-NFT swaps
     *
     * @param nftRecipient The address that will receive the NFT output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return remainingValue The unspent token amount
     */
    function robustSwapERC20ForSpecificNFTs(
        RobustPoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address nftRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 remainingValue) {
        remainingValue = inputAmount;
        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate actual cost per swap
            (error,,, poolCost,) = swapList[i].swapInfo.pool.getBuyNFTQuote(swapList[i].swapInfo.nftIds.length);

            // If within our maxCost and no error, proceed
            if (poolCost <= swapList[i].maxCost && error == CurveErrorCodes.Error.OK) {
                remainingValue -= swapList[i].swapInfo.pool.swapTokenForSpecificNFTs(
                    swapList[i].swapInfo.nftIds, poolCost, nftRecipient, true, msg.sender
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps as many NFTs for tokens as possible, respecting the per-swap min output
     * @param swapList The list of pools to trade with and the IDs of the NFTs to sell to each.
     * @param tokenRecipient The address that will receive the token output
     * @param deadline The Unix timestamp (in seconds) at/after which the swap will revert
     * @return outputAmount The total ETH/ERC20 received
     */
    function robustSwapNFTsForToken(
        RobustPoolSwapSpecificForToken[] calldata swapList,
        address payable tokenRecipient,
        uint256 deadline
    ) public virtual checkDeadline(deadline) returns (uint256 outputAmount) {
        // Try doing each swap
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            uint256 poolOutput;

            // Locally scoped to avoid stack too deep error
            {
                CurveErrorCodes.Error error;
                (error,,, poolOutput,) = swapList[i].swapInfo.pool.getSellNFTQuote(swapList[i].swapInfo.nftIds.length);
                if (error != CurveErrorCodes.Error.OK) {
                    unchecked {
                        ++i;
                    }
                    continue;
                }
            }

            // If at least equal to our minOutput, proceed
            if (poolOutput >= swapList[i].minOutput) {
                // Do the swap and update outputAmount with how many tokens we got
                outputAmount += swapList[i].swapInfo.pool.swapNFTsForToken(
                    ICollectionPool.NFTs(
                        swapList[i].swapInfo.nftIds, swapList[i].swapInfo.proof, swapList[i].swapInfo.proofFlags
                    ),
                    0,
                    tokenRecipient,
                    true,
                    msg.sender,
                    swapList[i].swapInfo.externalFilterContext
                );
            }

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Buys NFTs with ETH and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapETHForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = msg.value;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,, poolCost,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    // We know how much ETH to send because we already did the math above
                    // So we just send that much
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs{value: poolCost}(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Return remaining value to sender
            if (remainingValue > 0) {
                params.tokenRecipient.safeTransferETH(remainingValue);
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,, poolOutput,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender,
                        params.nftToTokenTrades[i].swapInfo.externalFilterContext
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /**
     * @notice Buys NFTs with ERC20, and sells them for tokens in one transaction
     * @param params All the parameters for the swap (packed in struct to avoid stack too deep), containing:
     * - ethToNFTSwapList The list of NFTs to buy
     * - nftToTokenSwapList The list of NFTs to sell
     * - inputAmount The max amount of tokens to send (if ERC20)
     * - tokenRecipient The address that receives tokens from the NFTs sold
     * - nftRecipient The address that receives NFTs
     * - deadline UNIX timestamp deadline for the swap
     */
    function robustSwapERC20ForSpecificNFTsAndNFTsToToken(RobustPoolNFTsFoTokenAndTokenforNFTsTrade calldata params)
        external
        payable
        virtual
        returns (uint256 remainingValue, uint256 outputAmount)
    {
        {
            remainingValue = params.inputAmount;
            uint256 poolCost;
            CurveErrorCodes.Error error;

            // Try doing each swap
            uint256 numSwaps = params.tokenToNFTTrades.length;
            for (uint256 i; i < numSwaps;) {
                // Calculate actual cost per swap
                (error,,, poolCost,) = params.tokenToNFTTrades[i].swapInfo.pool.getBuyNFTQuote(
                    params.tokenToNFTTrades[i].swapInfo.nftIds.length
                );

                // If within our maxCost and no error, proceed
                if (poolCost <= params.tokenToNFTTrades[i].maxCost && error == CurveErrorCodes.Error.OK) {
                    remainingValue -= params.tokenToNFTTrades[i].swapInfo.pool.swapTokenForSpecificNFTs(
                        params.tokenToNFTTrades[i].swapInfo.nftIds, poolCost, params.nftRecipient, true, msg.sender
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
        {
            // Try doing each swap
            uint256 numSwaps = params.nftToTokenTrades.length;
            for (uint256 i; i < numSwaps;) {
                uint256 poolOutput;

                // Locally scoped to avoid stack too deep error
                {
                    CurveErrorCodes.Error error;
                    (error,,, poolOutput,) = params.nftToTokenTrades[i].swapInfo.pool.getSellNFTQuote(
                        params.nftToTokenTrades[i].swapInfo.nftIds.length
                    );
                    if (error != CurveErrorCodes.Error.OK) {
                        unchecked {
                            ++i;
                        }
                        continue;
                    }
                }

                // If at least equal to our minOutput, proceed
                if (poolOutput >= params.nftToTokenTrades[i].minOutput) {
                    // Do the swap and update outputAmount with how many tokens we got
                    outputAmount += params.nftToTokenTrades[i].swapInfo.pool.swapNFTsForToken(
                        ICollectionPool.NFTs(
                            params.nftToTokenTrades[i].swapInfo.nftIds,
                            params.nftToTokenTrades[i].swapInfo.proof,
                            params.nftToTokenTrades[i].swapInfo.proofFlags
                        ),
                        0,
                        params.tokenRecipient,
                        true,
                        msg.sender,
                        params.nftToTokenTrades[i].swapInfo.externalFilterContext
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    receive() external payable {}

    /**
     * Restricted functions
     */

    /**
     * @dev Allows an ERC20 pool contract to transfer ERC20 tokens directly from
     * the sender, in order to minimize the number of token transfers. Only callable by an ERC20 pool.
     * @param token The ERC20 token to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferERC20From(
        ERC20 token,
        address from,
        address to,
        uint256 amount,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPoolVariant(msg.sender, variant), "Not pool");

        // verify caller is an ERC20 pool
        require(
            variant == ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20
                || variant == ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20,
            "Not ERC20 pool"
        );

        // transfer tokens to pool
        token.safeTransferFrom(from, to, amount);
    }

    /**
     * @dev Allows a pool contract to transfer ERC721 NFTs directly from
     * the sender, in order to minimize the number of token transfers. Only callable by a pool.
     * @param nft The ERC721 NFT to transfer
     * @param from The address to transfer tokens from
     * @param to The address to transfer tokens to
     * @param id The ID of the NFT to transfer
     * @param variant The pool variant of the pool contract
     */
    function poolTransferNFTFrom(
        IERC721 nft,
        address from,
        address to,
        uint256 id,
        ICollectionPoolFactory.PoolVariant variant
    ) external {
        // verify caller is a trusted pool contract
        require(factory.isPoolVariant(msg.sender, variant), "Not pool");

        // transfer NFTs to pool
        nft.safeTransferFrom(from, to, id);
    }

    /**
     * Internal functions
     */

    /**
     * @param deadline The last valid time for a swap
     */
    function _checkDeadline(uint256 deadline) internal view {
        require(block.timestamp <= deadline, "Deadline passed");
    }

    /**
     * @notice Internal function used to swap ETH for any NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForAnyNFTs(
        PoolSwapAny[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,, poolCost,) = swapList[i].pool.getBuyNFTQuote(swapList[i].numItems);

            // Require no error
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs{value: poolCost}(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap ETH for a specific set of NFTs
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ETH to send
     * @param ethRecipient The address receiving excess ETH
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapETHForSpecificNFTs(
        PoolSwapSpecific[] calldata swapList,
        uint256 inputAmount,
        address payable ethRecipient,
        address nftRecipient
    ) internal virtual returns (uint256 remainingValue) {
        remainingValue = inputAmount;

        uint256 poolCost;
        CurveErrorCodes.Error error;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Calculate the cost per swap first to send exact amount of ETH over, saves gas by avoiding the need to send back excess ETH
            (error,,, poolCost,) = swapList[i].pool.getBuyNFTQuote(swapList[i].nftIds.length);

            // Require no errors
            require(error == CurveErrorCodes.Error.OK, "Bonding curve error");

            // Total ETH taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs{value: poolCost}(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }

        // Return remaining value to sender
        if (remainingValue > 0) {
            ethRecipient.safeTransferETH(remainingValue);
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for any NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForAnyNFTs(PoolSwapAny[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForAnyNFTs(
                swapList[i].numItems, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Internal function used to swap an ERC20 token for specific NFTs
     * @dev Note that we don't need to query the pool's bonding curve first for pricing data because
     * we just calculate and take the required amount from the caller during swap time.
     * However, we can't "pull" ETH, which is why for the ETH->NFT swaps, we need to calculate the pricing info
     * to figure out how much the router should send to the pool.
     * @param swapList The list of pools and swap calldata
     * @param inputAmount The total amount of ERC20 tokens to send
     * @param nftRecipient The address receiving the NFTs from the pools
     * @return remainingValue The unspent token amount
     */
    function _swapERC20ForSpecificNFTs(PoolSwapSpecific[] calldata swapList, uint256 inputAmount, address nftRecipient)
        internal
        virtual
        returns (uint256 remainingValue)
    {
        remainingValue = inputAmount;

        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Tokens are transferred in by the pool calling router.poolTransferERC20From
            // Total tokens taken from sender cannot exceed inputAmount
            // because otherwise the deduction from remainingValue will fail
            remainingValue -= swapList[i].pool.swapTokenForSpecificNFTs(
                swapList[i].nftIds, remainingValue, nftRecipient, true, msg.sender
            );

            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Swaps NFTs for tokens, designed to be used for 1 token at a time
     * @dev Calling with multiple tokens is permitted, BUT minOutput will be
     * far from enough of a safety check because different tokens almost certainly have different unit prices.
     * @param swapList The list of pools and swap calldata
     * @param minOutput The minimum number of tokens to be receieved from the swaps
     * @param tokenRecipient The address that receives the tokens
     * @return outputAmount The number of tokens to be received
     */
    function _swapNFTsForToken(PoolSwapSpecific[] calldata swapList, uint256 minOutput, address payable tokenRecipient)
        internal
        virtual
        returns (uint256 outputAmount)
    {
        // Do swaps
        uint256 numSwaps = swapList.length;
        for (uint256 i; i < numSwaps;) {
            // Do the swap for token and then update outputAmount
            // Note: minExpectedTokenOutput is set to 0 since we're doing an aggregate slippage check below
            outputAmount += swapList[i].pool.swapNFTsForToken(
                ICollectionPool.NFTs(swapList[i].nftIds, swapList[i].proof, swapList[i].proofFlags),
                0,
                tokenRecipient,
                true,
                msg.sender,
                swapList[i].externalFilterContext
            );

            unchecked {
                ++i;
            }
        }

        // Aggregate slippage check
        require(outputAmount >= minOutput, "outputAmount too low");
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";

/**
 * @title An NFT/Token pool where the token is ETH
 * @author Collection
 */
abstract contract CollectionPoolETH is CollectionPool {
    using SafeTransferLib for address payable;
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 65;

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = address(this).balance;
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool, /*isRouter*/
        address, /*routerCaller*/
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value >= inputAmount, "Sent too little ETH");

        // Pay royalties first to obtain total amount of royalties paid
        uint256 totalRoyaltiesPaid = _payRoyalties(royaltiesDue);

        // Transfer inputAmount ETH to assetRecipient if it's been set
        address payable _assetRecipient = getAssetRecipient();
        if (_assetRecipient != address(this)) {
            _assetRecipient.safeTransferETH(inputAmount - protocolFee - totalRoyaltiesPaid);
        }

        _payProtocolFeeFromPool(_factory, protocolFee);
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Give excess ETH back to caller
        if (msg.value > inputAmount) {
            payable(msg.sender).safeTransferETH(msg.value - inputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal override {
        // Take protocol fee
        if (protocolFee > 0) {
            // Round down to the actual ETH balance if there are numerical stability issues with the bonding curve calculations
            if (protocolFee > address(this).balance) {
                protocolFee = address(this).balance;
            }

            if (protocolFee > 0) {
                payable(address(_factory)).safeTransferETH(protocolFee);
            }
        }
    }

    function _payRoyalties(RoyaltyDue[] memory royaltiesDue) internal returns (uint256 totalRoyaltiesPaid) {
        uint256 length = royaltiesDue.length;
        for (uint256 i = 0; i < length;) {
            RoyaltyDue memory due = royaltiesDue[i];
            uint256 royaltyAmount = due.amount;
            if (royaltyAmount > 0) {
                totalRoyaltiesPaid += royaltyAmount;

                address recipient = getRoyaltyRecipient(payable(due.recipient));
                payable(recipient).safeTransferETH(royaltyAmount);
            }

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        override
    {
        _payRoyalties(royaltiesDue);

        // Send ETH to caller
        if (outputAmount > 0) {
            require(liquidity() >= outputAmount, "Too little ETH");
            tokenRecipient.safeTransferETH(outputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @notice Withdraws all token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllETH() external onlyAuthorized {
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        uint256 amount = address(this).balance;
        payable(owner()).safeTransferETH(amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since ETH is the pool token
        address _nft = address(nft());
        emit TokenWithdrawal(_nft, address(0), amount);
        emit AccruedTradeFeeWithdrawal(_nft, address(0), _accruedTradeFee);
    }

    /**
     * @notice Withdraws a specified amount of token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     * @param amount The amount of token to send to the owner. If the pool's balance is less than
     * this value, the transaction will be reverted.
     */
    function withdrawETH(uint256 amount) external onlyAuthorized {
        require(liquidity() >= amount, "Too little ETH");

        payable(owner()).safeTransferETH(amount);

        // emit event since ETH is the pool token
        emit TokenWithdrawal(address(nft()), address(0), amount);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            payable(owner()).safeTransferETH(_accruedTradeFee);

            // emit event since ETH is the pool token
            emit AccruedTradeFeeWithdrawal(address(nft()), address(0), _accruedTradeFee);
        }
    }

    function depositERC20Notification(ERC20, uint256) external view onlyFactory {
        revert InvalidModification();
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    receive() external payable {
        emit TokenDeposit(address(nft()), address(0), msg.value);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, msg.value);
    }

    /**
     * @dev All ETH transfers into the pool are accepted. This is the main method
     * for the owner to top up the pool's token reserves.
     */
    fallback() external payable {
        // Only allow calls without function selector
        require(msg.data.length == _immutableParamsLength());
        emit TokenDeposit(address(nft()), address(0), msg.value);
        notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, msg.value);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CurveErrorCodes} from "./CurveErrorCodes.sol";

interface ICurve {
    /**
     * @param spotPrice The current selling spot price of the pool, in tokens
     * @param delta The delta parameter of the pool, what it means depends on the curve
     * @param props The properties of the pool, what it means depends on the curve
     * @param state The state of the pool, what it means depends on the curve
     */
    struct Params {
        uint128 spotPrice;
        uint128 delta;
        bytes props;
        bytes state;
    }

    /**
     * @param trade The amount of fee to send to the pool, in tokens
     * @param protocol The amount of fee to send to the protocol, in tokens
     * @param royalties The amount to pay for each item in the order they
     * are purchased. Always has length `numItems`.
     */
    struct Fees {
        uint256 trade;
        uint256 protocol;
        uint256[] royalties;
    }

    /**
     * @param feeMultiplier Determines how much fee the LP takes from this trade, 18 decimals
     * @param fees.protocolMultiplier Determines how much fee the protocol takes from this trade, 18 decimals
     * @param royaltyNumerator Determines how much of the trade value is awarded as royalties. 5 decimals
     * @param carryFeeMultiplier Determines how much carry fee the protocol takes from this trade, 18 decimals
     */
    struct FeeMultipliers {
        uint24 trade;
        uint24 protocol;
        uint24 royaltyNumerator;
        uint24 carry;
    }

    /**
     * @notice Validates if a delta value is valid for the curve. The criteria for
     * validity can be different for each type of curve, for instance ExponentialCurve
     * requires delta to be greater than 1.
     * @param delta The delta value to be validated
     * @return valid True if delta is valid, false otherwise
     */
    function validateDelta(uint128 delta) external pure returns (bool valid);

    /**
     * @notice Validates if a new spot price is valid for the curve. Spot price is generally assumed to be the immediate sell price of 1 NFT to the pool, in units of the pool's pooled token.
     * @param newSpotPrice The new spot price to be set
     * @return valid True if the new spot price is valid, false otherwise
     */
    function validateSpotPrice(uint128 newSpotPrice) external view returns (bool valid);

    /**
     * @notice Validates if a props value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param props The props value to be validated
     * @return valid True if props is valid, false otherwise
     */
    function validateProps(bytes calldata props) external view returns (bool valid);

    /**
     * @notice Validates if a state value is valid for the curve. The criteria for validity can be different for each type of curve.
     * @param state The state value to be validated
     * @return valid True if state is valid, false otherwise
     */
    function validateState(bytes calldata state) external view returns (bool valid);

    /**
     * @notice Validates given delta, spot price, props value and state value for the curve. The criteria for validity can be different for each type of curve.
     * @param delta The delta value to be validated
     * @param newSpotPrice The new spot price to be set
     * @param props The props value to be validated
     * @param state The state value to be validated
     * @return valid True if all parameters are valid, false otherwise
     */
    function validate(uint128 delta, uint128 newSpotPrice, bytes calldata props, bytes calldata state)
        external
        view
        returns (bool valid);

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should pay to purchase an NFT from the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is buying from the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return inputValue The amount that the user should pay, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getBuyInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 inputValue,
            ICurve.Fees calldata fees,
            uint256 lastSwapPrice
        );

    /**
     * @notice Given the current state of the pool and the trade, computes how much the user
     * should receive when selling NFTs to the pool, the new spot price, and other values.
     * @dev Do not try to optimize the length of fees.royalties; compiler
     * ^0.8.0 throws a YulException if you try to use an if-guard in the sigmoid
     * calculation loop due to stack depth
     * @param params Parameters of the pool that affect the bonding curve.
     * @param numItems The number of NFTs the user is selling to the pool
     * @param feeMultipliers Determines how much fee is taken from this trade.
     * @return error Any math calculation errors, only Error.OK means the returned values are valid
     * @return newParams The updated parameters of the pool that affect the bonding curve.
     * @return outputValue The amount that the user should receive, in tokens
     * @return fees The amount of fees
     * @return lastSwapPrice The swap price of the last NFT traded with fees applied
     */
    function getSellInfo(ICurve.Params calldata params, uint256 numItems, ICurve.FeeMultipliers calldata feeMultipliers)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params calldata newParams,
            uint256 outputValue,
            ICurve.Fees calldata fees,
            uint256 lastSwapPrice
        );
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {ERC20} from "solmate/src/tokens/ERC20.sol";

import {ICurve} from "../bonding-curves/ICurve.sol";
import {ICollectionPoolFactory} from "../pools/ICollectionPoolFactory.sol";

library CollectionPoolCloner {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneETHPool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 76
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 65 bytes of extra data = 118 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 41
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_76_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (65 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only

            instance := create(0, ptr, 0x7f)
        }
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     *
     * During the delegate call, extra data is copied into the calldata which can then be
     * accessed by the implementation contract.
     */
    function cloneERC20Pool(
        address implementation,
        ICollectionPoolFactory factory,
        ICurve bondingCurve,
        IERC721 nft,
        uint8 poolType,
        ERC20 token
    ) internal returns (address instance) {
        uint256 blockNumber = block.number;

        assembly {
            let ptr := mload(0x40)

            // -------------------------------------------------------------------------------------------------------------
            // CREATION (9 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // creation size = 09
            // runtime size = 8a
            // 60 runtime  | PUSH1 runtime (r)     | r                       | –
            // 3d          | RETURNDATASIZE        | 0 r                     | –
            // 81          | DUP2                  | r 0 r                   | –
            // 60 creation | PUSH1 creation (c)    | c r 0 r                 | –
            // 3d          | RETURNDATASIZE        | 0 c r 0 r               | –
            // 39          | CODECOPY              | 0 r                     | [0-runSize): runtime code
            // f3          | RETURN                |                         | [0-runSize): runtime code

            // -------------------------------------------------------------------------------------------------------------
            // RUNTIME (53 bytes of code + 85 bytes of extra data = 138 bytes)
            // -------------------------------------------------------------------------------------------------------------

            // extra data size = 55
            // 3d          | RETURNDATASIZE        | 0                       | –
            // 3d          | RETURNDATASIZE        | 0 0                     | –
            // 3d          | RETURNDATASIZE        | 0 0 0                   | –
            // 3d          | RETURNDATASIZE        | 0 0 0 0                 | –
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | –
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | –
            // 3d          | RETURNDATASIZE        | 0 0 cds 0 0 0 0         | –
            // 37          | CALLDATACOPY          | 0 0 0 0                 | [0, cds) = calldata
            // 60 extra    | PUSH1 extra           | extra 0 0 0 0           | [0, cds) = calldata
            // 60 0x35     | PUSH1 0x35            | 0x35 extra 0 0 0 0      | [0, cds) = calldata // 0x35 (53) is runtime size - data
            // 36          | CALLDATASIZE          | cds 0x35 extra 0 0 0 0  | [0, cds) = calldata
            // 39          | CODECOPY              | 0 0 0 0                 | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 36          | CALLDATASIZE          | cds 0 0 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 60 extra    | PUSH1 extra           | extra cds 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 01          | ADD                   | cds+extra 0 0 0 0       | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | 0 cds 0 0 0 0           | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 73 addr     | PUSH20 0x123…         | addr 0 cds 0 0 0 0      | [0, cds) = calldata, [cds, cds+0x35) = extraData
            mstore(
                ptr,
                hex"60_8a_3d_81_60_09_3d_39_f3_3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00"
            )
            mstore(add(ptr, 0x1d), shl(0x60, implementation))

            // 5a          | GAS                   | gas addr 0 cds 0 0 0 0  | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // f4          | DELEGATECALL          | success 0 0             | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds success 0 0         | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3d          | RETURNDATASIZE        | rds rds success 0 0     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 93          | SWAP4                 | 0 rds success 0 rds     | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 80          | DUP1                  | 0 0 rds success 0 rds   | [0, cds) = calldata, [cds, cds+0x35) = extraData
            // 3e          | RETURNDATACOPY        | success 0 rds           | [0, rds) = return data (there might be some irrelevant leftovers in memory [rds, cds+0x37) when rds < cds+0x37)
            // 60 0x33     | PUSH1 0x33            | 0x33 sucess 0 rds       | [0, rds) = return data
            // 57          | JUMPI                 | 0 rds                   | [0, rds) = return data
            // fd          | REVERT                | –                       | [0, rds) = return data
            // 5b          | JUMPDEST              | 0 rds                   | [0, rds) = return data
            // f3          | RETURN                | –                       | [0, rds) = return data
            mstore(
                add(ptr, 0x31),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )

            // -------------------------------------------------------------------------------------------------------------
            // EXTRA DATA (85 bytes)
            // -------------------------------------------------------------------------------------------------------------

            mstore(add(ptr, 0x3e), shl(0x60, factory))
            mstore(add(ptr, 0x52), shl(0x60, bondingCurve))
            mstore(add(ptr, 0x66), shl(0x60, nft))
            mstore8(add(ptr, 0x7a), poolType)
            mstore(add(ptr, 0x7b), shl(0xe0, blockNumber)) // lower 32 bits only
            mstore(add(ptr, 0x7f), shl(0x60, token))

            instance := create(0, ptr, 0x93)
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolETH.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param factory the factory that deployed the clone
     * @param implementation the CollectionPoolETH implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isETHPoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_41_60_35_36_39_36_60_41_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }

    /**
     * @notice Checks if a contract is a clone of a CollectionPoolERC20.
     * @dev Only checks the runtime bytecode, does not check the extra data.
     * @param implementation the CollectionPoolERC20 implementation contract
     * @param query the contract to check
     * @return result True if the contract is a clone, false otherwise
     */
    function isERC20PoolClone(
        address factory,
        address implementation,
        address query
    ) internal view returns (bool result) {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(
                ptr,
                hex"3d_3d_3d_3d_36_3d_3d_37_60_55_60_35_36_39_36_60_55_01_3d_73_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(
                add(ptr, 0x28),
                hex"5a_f4_3d_3d_93_80_3e_60_33_57_fd_5b_f3_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00_00"
            )
            mstore(add(ptr, 0x35), shl(0x60, factory))

            // compare expected bytecode with that of the queried contract
            let other := add(ptr, 0x49)
            extcodecopy(query, other, 0, 0x49)
            result := and(
                eq(mload(ptr), mload(other)),
                and(
                    eq(mload(add(ptr, 0x20)), mload(add(other, 0x20))),
                    eq(mload(add(ptr, 0x29)), mload(add(other, 0x29)))
                )
            )
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {IPoolActivityMonitor} from "./IPoolActivityMonitor.sol";

/**
 * @title An NFT/Token pool where the token is an ERC20
 * @author Collection
 */
abstract contract CollectionPoolERC20 is CollectionPool {
    using SafeTransferLib for ERC20;

    uint256 internal constant IMMUTABLE_PARAMS_LENGTH = 85;

    /**
     * @notice Returns the ERC20 token associated with the pool
     * @dev See CollectionPoolCloner for an explanation on how this works
     */
    function token() public pure returns (ERC20 _token) {
        uint256 paramsLength = _immutableParamsLength();
        assembly {
            _token := shr(0x60, calldataload(add(sub(calldatasize(), paramsLength), 65)))
        }
    }

    /// @inheritdoc ICollectionPool
    function liquidity() public view returns (uint256) {
        uint256 _balance = token().balanceOf(address(this));
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_balance < _accruedTradeFee) revert InsufficientLiquidity(_balance, _accruedTradeFee);

        return _balance - _accruedTradeFee;
    }

    /// @inheritdoc CollectionPool
    function _pullTokenInputAndPayProtocolFee(
        uint256 inputAmount,
        bool isRouter,
        address routerCaller,
        ICollectionPoolFactory _factory,
        uint256 protocolFee,
        RoyaltyDue[] memory royaltiesDue
    ) internal override {
        require(msg.value == 0, "ERC20 pool");

        ERC20 _token = token();

        uint256 length = royaltiesDue.length;
        uint256 totalRoyaltiesPaid;

        if (isRouter) {
            // Verify if router is allowed
            CollectionRouter router = CollectionRouter(payable(msg.sender));

            // Locally scoped to avoid stack too deep
            {
                (bool routerAllowed,) = _factory.routerStatus(router);
                require(routerAllowed, "Not router");
            }

            // Pay royalties first to obtain total amount of royalties paid
            for (uint256 i = 0; i < length;) {
                // Cache state and then call router to transfer tokens from user
                RoyaltyDue memory due = royaltiesDue[i];
                uint256 royaltyAmount = due.amount;
                if (royaltyAmount > 0) {
                    totalRoyaltiesPaid += royaltyAmount;

                    address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                    uint256 royaltyInitBalance = _token.balanceOf(royaltyRecipient);

                    router.poolTransferERC20From(_token, routerCaller, royaltyRecipient, royaltyAmount, poolVariant());

                    // Verify token transfer (protect pool against malicious router)
                    require(
                        _token.balanceOf(royaltyRecipient) - royaltyInitBalance == royaltyAmount,
                        "ERC20 royalty not transferred in"
                    );
                }

                unchecked {
                    ++i;
                }
            }

            // Cache state and then call router to transfer tokens from user
            address _assetRecipient = getAssetRecipient();
            uint256 beforeBalance = _token.balanceOf(_assetRecipient);
            uint256 amountToAssetRecipient = inputAmount - protocolFee - totalRoyaltiesPaid;
            router.poolTransferERC20From(_token, routerCaller, _assetRecipient, amountToAssetRecipient, poolVariant());

            // Verify token transfer (protect pool against malicious router)
            require(
                _token.balanceOf(_assetRecipient) - beforeBalance == amountToAssetRecipient, "ERC20 not transferred in"
            );

            router.poolTransferERC20From(_token, routerCaller, address(_factory), protocolFee, poolVariant());

            // Note: no check for factory balance's because router is assumed to be set by factory owner
            // so there is no incentive to *not* pay protocol fee
        } else {
            // Pay royalties first to obtain total amount of royalties paid
            for (uint256 i = 0; i < length;) {
                RoyaltyDue memory due = royaltiesDue[i];
                uint256 royaltyAmount = due.amount;
                if (royaltyAmount > 0) {
                    totalRoyaltiesPaid += royaltyAmount;

                    address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                    _token.safeTransferFrom(msg.sender, royaltyRecipient, royaltyAmount);
                }

                unchecked {
                    ++i;
                }
            }

            // Transfer tokens directly
            _token.safeTransferFrom(msg.sender, getAssetRecipient(), inputAmount - protocolFee - totalRoyaltiesPaid);

            // Take protocol fee (if it exists)
            if (protocolFee > 0) {
                _token.safeTransferFrom(msg.sender, address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _refundTokenToSender(uint256 inputAmount) internal override {
        // Do nothing since we transferred the exact input amount
    }

    /// @inheritdoc CollectionPool
    function _payProtocolFeeFromPool(ICollectionPoolFactory _factory, uint256 protocolFee) internal override {
        // Take protocol fee (if it exists)
        if (protocolFee > 0) {
            ERC20 _token = token();

            // Round down to the actual token balance if there are numerical stability issues with the bonding curve calculations
            uint256 poolTokenBalance = _token.balanceOf(address(this));
            if (protocolFee > poolTokenBalance) {
                protocolFee = poolTokenBalance;
            }
            if (protocolFee > 0) {
                _token.safeTransfer(address(_factory), protocolFee);
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _sendTokenOutput(address payable tokenRecipient, uint256 outputAmount, RoyaltyDue[] memory royaltiesDue)
        internal
        override
    {
        ERC20 _token = token();

        uint256 length = royaltiesDue.length;
        for (uint256 i = 0; i < length;) {
            RoyaltyDue memory due = royaltiesDue[i];
            uint256 royaltyAmount = due.amount;
            if (royaltyAmount > 0) {
                address royaltyRecipient = getRoyaltyRecipient(payable(due.recipient));
                _token.safeTransfer(royaltyRecipient, royaltyAmount);
            }
            unchecked {
                ++i;
            }
        }

        // Send tokens to caller
        if (outputAmount > 0) {
            require(liquidity() >= outputAmount, "Too little ERC20");
            _token.safeTransfer(tokenRecipient, outputAmount);
        }
    }

    /// @inheritdoc CollectionPool
    // @dev see CollectionPoolCloner for params length calculation
    function _immutableParamsLength() internal pure override returns (uint256) {
        return IMMUTABLE_PARAMS_LENGTH;
    }

    /**
     * @dev Deposit ERC20s into pool
     */
    function depositERC20(ERC20 a, uint256 amount) external {
        a.safeTransferFrom(msg.sender, address(this), amount);
        _depositERC20Notification(a, amount);
    }

    /**
     * @notice Used by factory to notify pools of deposits initiated on the factory
     * side
     */
    function depositERC20Notification(ERC20 a, uint256 amount) external onlyFactory {
        _depositERC20Notification(a, amount);
    }

    function _depositERC20Notification(ERC20 a, uint256 amount) internal {
        if (a == token()) {
            emit TokenDeposit(address(nft()), address(a), amount);
            notifyDeposit(IPoolActivityMonitor.EventType.DEPOSIT_TOKEN, amount);
        }
    }

    /**
     * @notice Withdraws all pool token owned by the pool to the owner address.
     * @dev Only callable by the owner.
     */
    function withdrawAllERC20() external onlyAuthorized {
        uint256 _accruedTradeFee = accruedTradeFee;
        accruedTradeFee = 0;

        ERC20 _token = token();
        uint256 amount = _token.balanceOf(address(this));
        _token.safeTransfer(owner(), amount);

        if (_accruedTradeFee >= amount) {
            _accruedTradeFee = amount;
            amount = 0;
        } else {
            amount -= _accruedTradeFee;
        }

        // emit event since it is the pool token
        address _nft = address(nft());
        emit TokenWithdrawal(_nft, address(_token), amount);
        emit AccruedTradeFeeWithdrawal(_nft, address(_token), _accruedTradeFee);
    }

    /// @inheritdoc ICollectionPool
    function withdrawERC20(ERC20 a, uint256 amount) external onlyAuthorized {
        if (a == token()) {
            require(liquidity() >= amount, "Too little ERC20");

            // emit event since it is the pool token
            emit TokenWithdrawal(address(nft()), address(a), amount);
        }

        a.safeTransfer(owner(), amount);
    }

    /// @inheritdoc CollectionPool
    function withdrawAccruedTradeFee() external override onlyOwner {
        uint256 _accruedTradeFee = accruedTradeFee;
        if (_accruedTradeFee > 0) {
            accruedTradeFee = 0;

            ERC20 _token = token();
            _token.safeTransfer(msg.sender, _accruedTradeFee);

            // emit event since it is the pool token
            emit AccruedTradeFeeWithdrawal(address(nft()), address(_token), _accruedTradeFee);
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";

interface ICollectionPoolFactory is IERC721 {
    enum PoolVariant {
        ENUMERABLE_ETH,
        MISSING_ENUMERABLE_ETH,
        ENUMERABLE_ERC20,
        MISSING_ENUMERABLE_ERC20
    }

    struct LPTokenParams721 {
        address nftAddress;
        address bondingCurveAddress;
        address tokenAddress;
        address payable poolAddress;
        uint24 fee;
        uint128 delta;
        uint24 royaltyNumerator;
    }

    /**
     * @param merkleRoot Merkle root for NFT ID filter
     * @param encodedTokenIDs Encoded list of acceptable NFT IDs
     * @param initialProof Merkle multiproof for initial NFT IDs
     * @param initialProofFlags Merkle multiproof flags for initial NFT IDs
     * @param externalFilter Address implementing IExternalFilter for external filtering
     */
    struct NFTFilterParams {
        bytes32 merkleRoot;
        bytes encodedTokenIDs;
        bytes32[] initialProof;
        bool[] initialProofFlags;
        IExternalFilter externalFilter;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends
     * on the specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param royaltyRecipientFallback An address to which all royalties will
     * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @return pool The new pool
     */
    struct CreateETHPoolParams {
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint24 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint24 royaltyNumerator;
        address payable royaltyRecipientFallback;
        uint256[] initialNFTIDs;
    }

    /**
     * @notice Creates a pool contract using EIP-1167.
     * @param token The ERC20 token used for pool swaps
     * @param nft The NFT contract of the collection the pool trades
     * @param bondingCurve The bonding curve for the pool to price NFTs, must be whitelisted
     * @param assetRecipient The address that will receive the assets traders give during trades.
     * If set to address(0), assets will be sent to the pool address. Not available to TRADE pools.
     * @param receiver Receiver of the LP token generated to represent ownership of the pool
     * @param poolType TOKEN, NFT, or TRADE
     * @param delta The delta value used by the bonding curve. The meaning of delta depends on the
     * specific curve.
     * @param fee The fee taken by the LP in each trade. Can only be non-zero if _poolType is Trade.
     * @param spotPrice The initial selling spot price, in ETH
     * @param royaltyNumerator All trades will result in `royaltyNumerator` * <trade amount> / 1e6
     * being sent to the account to which the traded NFT's royalties are awardable.
     * Must be 0 if `_nft` is not IERC2981 and no recipient fallback is set.
     * @param royaltyRecipientFallback An address to which all royalties will
     * be paid to if not address(0) and ERC2981 is not supported or ERC2981 recipient is not set.
     * @param initialNFTIDs The list of IDs of NFTs to transfer from the sender to the pool
     * @param initialTokenBalance The initial token balance sent from the sender to the new pool
     * @return pool The new pool
     */
    struct CreateERC20PoolParams {
        ERC20 token;
        IERC721 nft;
        ICurve bondingCurve;
        address payable assetRecipient;
        address receiver;
        ICollectionPool.PoolType poolType;
        uint128 delta;
        uint24 fee;
        uint128 spotPrice;
        bytes props;
        bytes state;
        uint24 royaltyNumerator;
        address payable royaltyRecipientFallback;
        uint256[] initialNFTIDs;
        uint256 initialTokenBalance;
    }

    function protocolFeeMultiplier() external view returns (uint24);

    function protocolFeeRecipient() external view returns (address payable);

    function carryFeeMultiplier() external view returns (uint24);

    function callAllowed(address target) external view returns (bool);

    function routerStatus(CollectionRouter router) external view returns (bool allowed, bool wasEverAllowed);

    function isPool(address potentialPool) external view returns (bool);

    function isPoolVariant(address potentialPool, PoolVariant variant) external view returns (bool);

    function requireAuthorizedForToken(address spender, uint256 tokenId) external view;

    function swapPaused() external view returns (bool);

    function creationPaused() external view returns (bool);

    function createPoolETH(CreateETHPoolParams calldata params)
        external
        payable
        returns (address pool, uint256 tokenId);

    function createPoolERC20(CreateERC20PoolParams calldata params) external returns (address pool, uint256 tokenId);

    function createPoolETHFiltered(CreateETHPoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        payable
        returns (address pool, uint256 tokenId);

    function createPoolERC20Filtered(CreateERC20PoolParams calldata params, NFTFilterParams calldata filterParams)
        external
        returns (address pool, uint256 tokenId);

    function depositNFTs(
        uint256[] calldata ids,
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        address recipient,
        address from
    ) external;

    function depositERC20(ERC20 token, uint256 amount, address recipient, address from) external;

    function burn(uint256 tokenId) external;

    /**
     * @dev Returns the pool address of the `tokenId` token.
     */
    function poolAddressOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "./CollectionPoolERC20.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is an ERC20
 * @author Collection
 */
contract CollectionPoolEnumerableERC20 is CollectionPoolEnumerable, CollectionPoolERC20 {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ERC20;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolERC20} from "../pools/CollectionPoolERC20.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableERC20 is CollectionPoolMissingEnumerable, CollectionPoolERC20 {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ERC20;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

/**
 * @notice Manages 256 independent pause states. Idiomatic use of these functions when
 * exposing them as external functions would be to give an appropriate name and
 * abstract away the passing of `index` variables using immutable contract
 * variables. Initializes with all pause states unpaused.
 */
contract MultiPauser {
    uint256 pauseStates;

    modifier validIndex(uint256 index) {
        require(index <= 255, "Invalid pause index");
        _;
    }

    modifier onlyPaused(uint256 index) {
        require(index <= 255, "Invalid pause index");
        require(isPaused(index), "Must be paused");
        _;
    }

    modifier onlyUnpaused(uint256 index) {
        require(index <= 255, "Invalid pause index");
        require(!isPaused(index), "Must be unpaused");
        _;
    }

    /**
     * @notice Pauses the pause with the given index. 0 <= index <= 255.
     * @dev While using a uint8 as the type of index would enforce the
     * precondition for us, it costs extra gas as solidity will carry out
     * bit extensions and truncations to make it word length
     */
    function pause(uint256 index) validIndex(index) internal {
        pauseStates = pauseStates | (1 << index);
    }

    /**
     * @notice Unpauses the pause with the given index. 0 <= index <= 255.
     * @dev While using a uint8 as the type of index would enforce the
     * precondition for us, it costs extra gas as solidity will carry out
     * bit extensions and truncations to make it word length
     */
    function unpause(uint256 index) validIndex(index) internal {
        /**
         * @dev Generate all 1's except in position `index`. Use XOR as no ~ in
         * solidity.
         */ 
        pauseStates &= ~(1 << index);
    }

    /**
     * @notice Returns true iff the pause with the given index is paused
     */
    function isPaused(uint256 index) validIndex(index) internal view returns (bool) {
        return (pauseStates & (1 << index)) > 0;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "../pools/CollectionPoolETH.sol";
import {CollectionPoolMissingEnumerable} from "./CollectionPoolMissingEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

contract CollectionPoolMissingEnumerableETH is CollectionPoolMissingEnumerable, CollectionPoolETH {
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.MISSING_ENUMERABLE_ETH;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {CollectionPoolETH} from "./CollectionPoolETH.sol";
import {CollectionPoolEnumerable} from "./CollectionPoolEnumerable.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool where the NFT implements ERC721Enumerable, and the token is ETH
 * @author Collection
 */
contract CollectionPoolEnumerableETH is CollectionPoolEnumerable, CollectionPoolETH {
    /**
     * @notice Returns the CollectionPool type
     */
    function poolVariant() public pure override returns (ICollectionPoolFactory.PoolVariant) {
        return ICollectionPoolFactory.PoolVariant.ENUMERABLE_ETH;
    }
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {ICurve} from "../bonding-curves/ICurve.sol";
import {CurveErrorCodes} from "../bonding-curves/CurveErrorCodes.sol";
import {ITokenIDFilter} from "../filter/ITokenIDFilter.sol";
import {IExternalFilter} from "../filter/IExternalFilter.sol";

interface ICollectionPool is ITokenIDFilter {
    enum PoolType {
        TOKEN,
        NFT,
        TRADE
    }

    /**
     * @param ids The list of IDs of the NFTs to sell to the pool
     * @param proof Merkle multiproof proving list is allowed by pool
     * @param proofFlags Merkle multiproof flags for proof
     */
    struct NFTs {
        uint256[] ids;
        bytes32[] proof;
        bool[] proofFlags;
    }

    function bondingCurve() external view returns (ICurve);

    /**
     * @notice Only tracked IDs are returned
     */
    function getAllHeldIds() external view returns (uint256[] memory);

    function delta() external view returns (uint128);

    function fee() external view returns (uint24);

    function nft() external view returns (IERC721);

    function poolType() external view returns (PoolType);

    function spotPrice() external view returns (uint128);

    function royaltyNumerator() external view returns (uint24);

    function poolSwapsPaused() external view returns (bool);

    function externalFilter() external view returns (IExternalFilter);

    /**
     * @notice The usable balance of the pool. This is the amount the pool needs to have to buy NFTs and pay out royalties.
     */
    function liquidity() external view returns (uint256);

    function balanceToFulfillSellNFT(uint256 numNFTs)
        external
        view
        returns (CurveErrorCodes.Error error, uint256 balance);

    /**
     * @notice Rescues a specified set of NFTs owned by the pool to the owner address. (onlyOwnable modifier is in the implemented function)
     * @dev If the NFT is the pool's collection, we also remove it from the id tracking
     * @param a The NFT to transfer
     * @param nftIds The list of IDs of the NFTs to send to the owner
     */
    function withdrawERC721(IERC721 a, uint256[] calldata nftIds) external;

    /**
     * @notice Rescues ERC20 tokens from the pool to the owner. Only callable by the owner (onlyOwnable modifier is in the implemented function).
     * @param a The token to transfer
     * @param amount The amount of tokens to send to the owner
     */
    function withdrawERC20(ERC20 a, uint256 amount) external;

    function withdrawERC1155(IERC1155 a, uint256[] calldata ids, uint256[] calldata amounts) external;

    function getSellNFTQuote(uint256 numNFTs)
        external
        view
        returns (
            CurveErrorCodes.Error error,
            ICurve.Params memory newParams,
            uint256 totalAmount,
            uint256 outputAmount,
            ICurve.Fees memory fees
        );

    /**
     * @dev Deposit NFTs into pool and emit event for indexing.
     */
    function depositNFTs(uint256[] calldata ids, bytes32[] calldata proof, bool[] calldata proofFlags) external;

    /**
     * @dev Used by factory to indicate deposited NFTs.
     * @dev Must only be called by factory. NFT IDs must have been validated against the filter.
     */
    function depositNFTsNotification(uint256[] calldata nftIds) external;

    /**
     * @dev Used by factory to indicate deposited ERC20 tokens.
     * @dev Must only be called by factory.
     */
    function depositERC20Notification(ERC20 a, uint256 amount) external;

    /**
     * @notice Returns number of NFTs in pool that matches filter
     */
    function NFTsLength() external view returns (uint256);
}

interface ICollectionPoolETH is ICollectionPool {
    function withdrawAllETH() external;
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IExternalFilter is IERC165 {
    /**
     * @notice Pools can nominate an external contract to approve whether NFT IDs are accepted.
     * This is typically used to implement some kind of dynamic block list, e.g. stolen NFTs.
     * @param collection NFT contract address
     * @param nftIds List of NFT IDs to check
     * @return allowed True if swap (pool buys) is allowed
     */
    function areNFTsAllowed(address collection, uint256[] calldata nftIds, bytes calldata context)
        external
        returns (bool allowed);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

contract CurveErrorCodes {
    enum Error {
        OK, // No error
        INVALID_NUMITEMS, // The numItem value is 0
        SPOT_PRICE_OVERFLOW, // The updated spot price doesn't fit into 128 bits
        TOO_MANY_ITEMS // The value of numItems passes was too great
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {ITokenIDFilter} from "./ITokenIDFilter.sol";

contract TokenIDFilter is ITokenIDFilter {
    event AcceptsTokenIDs(address indexed _collection, bytes32 indexed _root, bytes _data);

    // Merkle root
    bytes32 public tokenIDFilterRoot;

    function _setRootAndEmitAcceptedIDs(address collection, bytes32 root, bytes calldata data) internal {
        tokenIDFilterRoot = root;
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenID(uint256 tokenID, bytes32[] calldata proof) internal view returns (bool) {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        // double hash to prevent second preimage attack
        bytes32 leaf = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenID)))));

        return MerkleProof.verifyCalldata(proof, tokenIDFilterRoot, leaf);
    }

    function _emitTokenIDs(address collection, bytes calldata data) internal {
        emit AcceptsTokenIDs(collection, tokenIDFilterRoot, data);
    }

    function _acceptsTokenIDs(uint256[] calldata tokenIDs, bytes32[] calldata proof, bool[] calldata proofFlags)
        internal
        view
        returns (bool)
    {
        if (tokenIDFilterRoot == 0) {
            return true;
        }

        uint256 length = tokenIDs.length;
        bytes32[] memory leaves = new bytes32[](length);

        for (uint256 i; i < length;) {
            // double hash to prevent second preimage attack
            leaves[i] = keccak256(abi.encodePacked(keccak256(abi.encodePacked((tokenIDs[i])))));
            unchecked {
                ++i;
            }
        }

        return MerkleProof.multiProofVerify(proof, proofFlags, tokenIDFilterRoot, leaves);
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";

interface IPoolActivityMonitor is IERC165 {
    enum EventType {
        BOUGHT_NFT_FROM_POOL,
        SOLD_NFT_TO_POOL,
        DEPOSIT_TOKEN,
        DEPOSIT_NFT
    }

    /**
     * @dev This hook allows pool owners (i.e. owner of the LP token) to observe
     * changes to pools initiated by third-parties, i.e. swaps and deposits.
     *
     * @param amounts If `eventType` is a swap, then `amounts` is an array with
     * 3 elements. The first is the number of nfts swapped. The second is the
     * price of the last NFT swapped (after all fees are applied, i.e. input or
     * output amount if quantity were 1). The third is the total value of the
     * swap with fees included. If `eventType` is not a swap, then amounts is a
     * length 1 array of the amount of token/NFT deposited/withdrawn.
     */
    function onBalancesChanged(address poolAddress, EventType eventType, uint256[] memory amounts) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

interface ITokenIDFilter {
    function tokenIDFilterRoot() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {BitMaps} from "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";
import {ICollectionPool} from "./ICollectionPool.sol";
import {CollectionPool} from "./CollectionPool.sol";
import {ICollectionPoolFactory} from "./ICollectionPoolFactory.sol";

/**
 * @title An NFT/Token pool for an NFT that implements ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolEnumerable is CollectionPool {
    using BitMaps for BitMaps.BitMap;

    // NFT IDs that match our filter are maintained in this BitMap and counted in idLength
    BitMaps.BitMap private idMap;
    uint256 private idLength;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721 _nft, uint256 numNFTs)
        internal
        view
        override
        returns (uint256[] memory nftIds)
    {
        // numNFTs > 0 when called by buyAny function.
        nftIds = new uint256[](numNFTs);
        uint256 j;

        for (uint256 i; i < numNFTs;) {
            // index will be out of bounds if numNFTs > balance
            uint256 nftId = IERC721Enumerable(address(_nft)).tokenOfOwnerByIndex(address(this), j);

            // make sure it's a legal (filtered) ID
            if (idMap.get(nftId)) {
                nftIds[i] = nftId;
                unchecked {
                    ++i;
                }
            }

            unchecked {
                ++j;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        return _selectArbitraryNFTs(nft(), idLength);
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update map/size
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            if (!idMap.get(nftId)) {
                idMap.set(nftId);
                ++_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        // Send NFTs to given address, update map and count
        IERC721 _nft = nft();
        uint256 numNFTs = nftIds.length;
        uint256 _idLength = idLength;

        for (uint256 i; i < numNFTs;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(address(this), to, nftId);
            // Remove from id map
            if (idMap.get(nftId)) {
                idMap.unset(nftId);
                --_idLength;
            }

            unchecked {
                ++i;
            }
        }

        idLength = _idLength;
    }

    /// @inheritdoc ICollectionPool
    function NFTsLength() external view returns (uint256) {
        return idLength;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }
}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {TransferLib} from "../lib/TransferLib.sol";
import {ICollectionPool} from "../pools/ICollectionPool.sol";
import {CollectionPool} from "../pools/CollectionPool.sol";
import {CollectionRouter} from "../routers/CollectionRouter.sol";

/**
 * @title An NFT/Token pool for an NFT that does not implement ERC721Enumerable
 * @author Collection
 */
abstract contract CollectionPoolMissingEnumerable is CollectionPool {
    using EnumerableSet for EnumerableSet.UintSet;

    // Used for internal ID tracking
    EnumerableSet.UintSet private idSet;

    /// @inheritdoc CollectionPool
    function _selectArbitraryNFTs(IERC721, uint256 numNFTs) internal view override returns (uint256[] memory nftIds) {
        nftIds = new uint256[](numNFTs);

        // NOTE: We start from last index to first index to save on gas when we eventully _withdrawNFTs on results
        // crash if nothing to select (numNFTs is always > 1)
        uint256 lastIndex = idSet.length() - 1;

        for (uint256 i; i < numNFTs;) {
            // will throw if numNFTs > length due to underflow
            uint256 nftId = idSet.at(lastIndex);
            nftIds[i] = nftId;

            unchecked {
                --lastIndex;
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function getAllHeldIds() public view override returns (uint256[] memory nftIds) {
        nftIds = idSet.values();
    }

    /// @inheritdoc CollectionPool
    function _depositNFTs(address from, uint256[] calldata nftIds) internal override {
        // transfer NFTs to this pool and update set
        IERC721 _nft = nft();
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            uint256 nftId = nftIds[i];
            _nft.safeTransferFrom(from, address(this), nftId);
            idSet.add(nftId);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _depositNFTsNotification(uint256[] calldata nftIds) internal override {
        uint256 length = nftIds.length;
        for (uint256 i; i < length;) {
            idSet.add(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc CollectionPool
    function _withdrawNFTs(address to, uint256[] memory nftIds) internal override {
        IERC721 _nft = nft();

        // Send NFTs to given addres and update valid set
        uint256 numNFTs = nftIds.length;
        for (uint256 i; i < numNFTs;) {
            _nft.safeTransferFrom(address(this), to, nftIds[i]);
            idSet.remove(nftIds[i]);

            unchecked {
                ++i;
            }
        }
    }

    /// @inheritdoc ICollectionPool
    function NFTsLength() external view returns (uint256) {
        return idSet.length();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}