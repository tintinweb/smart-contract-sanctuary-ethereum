// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./IOwnable.sol";
import "./IPaymentProcessor.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/interfaces/IERC1271.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title  PaymentProcessor
 * @author Limit Break, Inc.
 * @notice The world's first ERC721-C compatible marketplace contract!  
 * @notice Use ERC721-C to whitelist this contract or other marketplace contracts that process royalties entirely 
 *         on-chain manner to make them 100% enforceable and fully programmable! 
 *
 * @notice <h4>Features</h4>
 *
 * @notice <ul>
 *            <li>Creator Defined Security Profiles</li>
 *            <ul>
 *             <li>Exchange Whitelist On/Off</li>
 *             <li>Payment Method Whitelist On/Off</li>
 *             <li>Pricing Constraints On/Off</li>
 *             <li>Private Sales On/Off</li>
 *             <li>Delegate Purchase Wallets On/Off</li>
 *             <li>Smart Contract Buyers/Sellers On/Off</li>
 *             <li>Exchange Whitelist Bypass for EOAs On/Off</li>
 *            </ul>
 *           <li>Enforceable/Programmable Fees</li>
 *           <ul>
 *             <li>Built-in EIP-2981 Royalty Enforcement</li>
 *             <li>Built-in Marketplace Fee Enforcement</li>
 *           </ul>
 *           <li>Multi-Standard Support</li>
 *           <ul>
 *             <li>ERC721-C</li>
 *             <li>ERC1155-C</li>
 *             <li>ERC721 + EIP-2981</li>
 *             <li>ERC1155 + EIP-2981</li>
 *           </ul>
 *           <li>Payments</li>
 *           <ul>
 *             <li>Native Currency (ETH or Equivalent)</li>
 *             <li>ERC-20 Coin Payments</li>
 *           </ul>
 *           <li>A Multitude of Supported Sale Types</li>
 *           <ul>
 *             <li>Buy Single Listing</li>
 *             <ul>
 *               <li>Collection-Level Offers</li>
 *               <li>Item-Specific Offers</li>
 *             </ul>
 *             <li>Buy Batch of Listings (Shopping Cart)</li>
 *             <li>Buy Bundled Listing (From One Collection)</li>
 *             <li>Sweep Listings (From One Collection)</li>
 *             <li>Partial Order Fills (When ERC-20 Payment Method Is Used)</li>
 *           </ul>
 *         </ul>
 *
 * @notice <h4>Security Considerations for Users</h4>
 *
 * @notice Virtually all on-chain marketplace contracts have the potential to be front-run.
 *         When purchasing high-value items, whether individually or in a batch/bundle it is highly
 *         recommended to execute transactions using Flashbots RPC Relay/private mempool to avoid
 *         sniper bots.  Partial fills are available for batched purchases, bundled listing purchases,
 *         and collection sweeps when the method of payment is an ERC-20 token, but not for purchases
 *         using native currency.  It is preferable to use wrapped ETH (or equivalent) when buying
 *         multiple tokens and it is highly advisable to use Flashbots whenever possible.  [Read the
 *         quickstart guide for more information](https://docs.flashbots.net/flashbots-protect/rpc/quick-start).
 */
contract PaymentProcessor is ERC165, EIP712, Ownable, Pausable, IPaymentProcessor {

    error PaymentProcessor__AddressCannotBeZero();
    error PaymentProcessor__AmountForERC721SalesMustEqualOne();
    error PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
    error PaymentProcessor__BundledOfferPriceMustEqualSumOfAllListingPrices();
    error PaymentProcessor__BuyerDidNotAuthorizePurchase();
    error PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
    error PaymentProcessor__CallerDoesNotOwnSecurityPolicy();
    error PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
    error PaymentProcessor__CallerIsNotWhitelistedMarketplace();
    error PaymentProcessor__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
    error PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
    error PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
    error PaymentProcessor__CoinDoesNotImplementDecimalsAndLikelyIsNotAnERC20Token();
    error PaymentProcessor__CoinIsApproved();
    error PaymentProcessor__CoinIsNotApproved();
    error PaymentProcessor__CollectionLevelOrItemLevelOffersCanOnlyBeMadeUsingERC20PaymentMethods();
    error PaymentProcessor__DispensingTokenWasUnsuccessful();
    error PaymentProcessor__EIP1271SignaturesAreDisabled();
    error PaymentProcessor__EIP1271SignatureInvalid();
    error PaymentProcessor__ExchangeIsWhitelisted();
    error PaymentProcessor__ExchangeIsNotWhitelisted();
    error PaymentProcessor__FailedToTransferProceeds();
    error PaymentProcessor__InputArrayLengthCannotBeZero();
    error PaymentProcessor__InputArrayLengthMismatch();
    error PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
    error PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
    error PaymentProcessor__OfferHasExpired();
    error PaymentProcessor__OfferPriceMustEqualSalePrice();
    error PaymentProcessor__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
    error PaymentProcessor__OverpaidNativeFunds();
    error PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
    error PaymentProcessor__PricingBoundsAreImmutable();
    error PaymentProcessor__RanOutOfNativeFunds();
    error PaymentProcessor__SaleHasExpired();
    error PaymentProcessor__SalePriceAboveMaximumCeiling();
    error PaymentProcessor__SalePriceBelowMinimumFloor();
    error PaymentProcessor__SalePriceBelowSellerApprovedMinimum();
    error PaymentProcessor__SecurityPolicyDoesNotExist();
    error PaymentProcessor__SecurityPolicyOwnershipCannotBeTransferredToZeroAddress();
    error PaymentProcessor__SellerDidNotAuthorizeSale();
    error PaymentProcessor__SignatureAlreadyUsedOrRevoked();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
    error PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();

    /// @dev Convenience to avoid magic number in bitmask get/set logic.
    uint256 private constant ONE = uint256(1);

    /// @notice The default admin role for NFT collections using Access Control.
    bytes32 private constant DEFAULT_ACCESS_CONTROL_ADMIN_ROLE = 0x00;

    /// @notice The default security policy id.
    uint256 public constant DEFAULT_SECURITY_POLICY_ID = 0;

    /// @notice The denominator used when calculating the marketplace fee.
    /// @dev    0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
    uint256 public constant FEE_DENOMINATOR = 10_000;

    /// @notice keccack256("OfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 tokenId,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant OFFER_APPROVAL_HASH = 0x2008a1ab898fdaa2d8f178bc39e807035d2d6e330dac5e42e913ca727ab56038;

    /// @notice keccack256("CollectionOfferApproval(uint8 protocol,bool collectionLevelOffer,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 amount,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant COLLECTION_OFFER_APPROVAL_HASH = 0x0bc3075778b80a2341ce445063e81924b88d61eb5f21c815e8f9cc824af096d0;

    /// @notice keccack256("BundledOfferApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address delegatedPurchaser,address buyer,address tokenAddress,uint256 price,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] itemSalePrices)")
    bytes32 public constant BUNDLED_OFFER_APPROVAL_HASH = 0x126520d0bca0cfa7e5852d004cc4335723ce67c638cbd55cd530fe992a089e7b;

    /// @notice keccack256("SaleApproval(uint8 protocol,bool sellerAcceptedOffer,address marketplace,uint256 marketplaceFeeNumerator,uint256 maxRoyaltyFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 tokenId,uint256 amount,uint256 minPrice,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin)")
    bytes32 public constant SALE_APPROVAL_HASH = 0xd3f4273db8ff5262b6bc5f6ee07d139463b4f826cce90c05165f63062f3686dc;

    /// @notice keccack256("BundledSaleApproval(uint8 protocol,address marketplace,uint256 marketplaceFeeNumerator,address privateBuyer,address seller,address tokenAddress,uint256 expiration,uint256 nonce,uint256 masterNonce,address coin,uint256[] tokenIds,uint256[] amounts,uint256[] maxRoyaltyFeeNumerators,uint256[] itemPrices)")
    bytes32 public constant BUNDLED_SALE_APPROVAL_HASH = 0x80244acca7a02d7199149a3038653fc8cb10ca984341ec429a626fab631e1662;

    /// @dev Tracks the most recently created security profile id
    uint256 private lastSecurityPolicyId;

    /// @dev Mapping of token address (NFT collection) to a security policy id.
    mapping(address => uint256) private tokenSecurityPolicies;

    /// @dev Mapping of whitelisted exchange addresses, organized by security policy id.
    mapping(uint256 => mapping(address => bool)) private exchangeWhitelist;

    /// @dev Mapping of coin addresses that are approved for payments, organized by security policy id.
    mapping(uint256 => mapping(address => bool)) private paymentMethodWhitelist;

    /// @dev Mapping of security policy id to security policy settings.
    mapping(uint256 => SecurityPolicy) private securityPolicies;

    /**
     * @notice User-specific master nonce that allows buyers and sellers to efficiently cancel all listings or offers
     *         they made previously. The master nonce for a user only changes when they explicitly request to revoke all
     *         existing listings and offers.
     *
     * @dev    When prompting sellers to sign a listing or offer, marketplaces must query the current master nonce of
     *         the user and include it in the listing/offer signature data.
     */
    mapping(address => uint256) public masterNonces;

    /**
     * @dev The mapping key is the keccak256 hash of marketplace address and user address.
     *
     * @dev ```keccak256(abi.encodePacked(marketplace, user))```
     *
     * @dev The mapping value is another nested mapping of "slot" (key) to a bitmap (value) containing boolean flags
     *      indicating whether or not a nonce has been used or invalidated.
     *
     * @dev Marketplaces MUST track their own nonce by user, incrementing it for every signed listing or offer the user
     *      creates.  Listings and purchases may be executed out of order, and they may never be executed if orders
     *      are not matched prior to expriation.
     *
     * @dev The slot and the bit offset within the mapped value are computed as:
     *
     * @dev ```slot = nonce / 256;```
     * @dev ```offset = nonce % 256;```
     */
    mapping(bytes32 => mapping(uint256 => uint256)) private invalidatedSignatures;

    /**
     * @dev Mapping of token contract addresses to the address of the ERC-20 payment coin tokens are priced in.
     *      When unspecified, the default currency for collections is the native currency.
     *
     * @dev If the designated ERC-20 payment coin is not in the list of approved coins, sales cannot be executed
     *      until the designated coin is set to an approved payment coin.
     */
    mapping (address => address) public collectionPaymentCoins;

    /**
     * @dev Mapping of token contract addresses to the collection-level pricing boundaries (floor and ceiling price).
     */
    mapping (address => PricingBounds) private collectionPricingBounds;

    /**
     * @dev Mapping of token contract addresses to the token-level pricing boundaries (floor and ceiling price).
     */
    mapping (address => mapping (uint256 => PricingBounds)) private tokenPricingBounds;

    constructor(
        address defaultContractOwner_,
        uint32 defaultPushPaymentGasLimit_, 
        address[] memory defaultPaymentMethods) EIP712("PaymentProcessor", "1") {

        securityPolicies[DEFAULT_SECURITY_POLICY_ID] = SecurityPolicy({
            enforceExchangeWhitelist: false,
            enforcePaymentMethodWhitelist: true,
            enforcePricingConstraints: false,
            disablePrivateListings: false,
            disableDelegatedPurchases: false,
            disableEIP1271Signatures: false,
            disableExchangeWhitelistEOABypass: false,
            pushPaymentGasLimit: defaultPushPaymentGasLimit_,
            policyOwner: address(0)
        });

        emit CreatedOrUpdatedSecurityPolicy(
            DEFAULT_SECURITY_POLICY_ID, 
            false,
            true,
            false,
            false,
            false,
            false,
            false,
            defaultPushPaymentGasLimit_,
            "DEFAULT SECURITY POLICY");

        for (uint256 i = 0; i < defaultPaymentMethods.length;) {
            address coin = defaultPaymentMethods[i];

            paymentMethodWhitelist[DEFAULT_SECURITY_POLICY_ID][coin] = true;
            emit PaymentMethodAddedToWhitelist(DEFAULT_SECURITY_POLICY_ID, coin);

            unchecked {
                ++i;
            }
        }

        _transferOwnership(defaultContractOwner_);
    }

    /**
     * @notice Allows Payment Processor contract owner to pause trading on this contract.  This is only to be used
     *         in case a future vulnerability emerges to allow a migration to an updated contract.
     *
     * @dev    Throws when caller is not the contract owner.
     * @dev    Throws when contract is already paused.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The contract has been placed in the `paused` state.
     * @dev    2. Trading is frozen.
     */
    function pause() external {
        _checkOwner();
        _pause();
    }

    /**
     * @notice Allows Payment Processor contract owner to resume trading on this contract.  This is only to be used
     *         in case a pause was not necessary and trading can safely resume.
     *
     * @dev    Throws when caller is not the contract owner.
     * @dev    Throws when contract is not currently paused.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The contract has been placed in the `unpaused` state.
     * @dev    2. Trading is resumed.
     */
    function unpause() external {
        _checkOwner();
        _unpause();
    }

    /**
     * @notice Allows any user to create a new security policy for the payment processor.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy id tracker has been incremented by `1`.
     * @dev    2. The security policy has been added to the security policies mapping.
     * @dev    3. The caller has been assigned as the owner of the security policy.
     * @dev    4. A `CreatedOrUpdatedSecurityPolicy` event has been emitted.
     *
     * @param  enforceExchangeWhitelist          Requires external exchange contracts be whitelisted to make buy calls.
     * @param  enforcePaymentMethodWhitelist     Requires that ERC-20 payment methods be pre-approved.
     * @param  enforcePricingConstraints         Allows the creator to specify exactly one approved payment method, 
     *                                           a minimum floor price and a maximum ceiling price.  
     *                                           When true, this value supercedes `enforcePaymentMethodWhitelist`.
     * @param  disablePrivateListings            Prevents private sales.
     * @param  disableDelegatedPurchases         Prevents delegated purchases.
     * @param  disableEIP1271Signatures          Prevents EIP-1271 compliant smart contracts such as multi-sig wallets
     *                                           from buying or selling.  Forces buyers and sellers to be EOAs.
     * @param  disableExchangeWhitelistEOABypass When exchange whitelists are enforced, prevents EOAs from executing
     *                                           purchases directly and bypassing whitelisted exchange contracts.
     * @param  pushPaymentGasLimit               The amount of gas to forward when pushing native proceeds.
     * @param  registryName                      A human readable name that describes the security policy.
     */
    function createSecurityPolicy(
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external override returns (uint256) {
        uint256 securityPolicyId;
        
        unchecked {
            securityPolicyId = ++lastSecurityPolicyId;
        }
        
        _createOrUpdateSecurityPolicy(
            securityPolicyId,
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName
        );

        return securityPolicyId;
    }

    /**
     * @notice Allows security policy owners to update existing security policies.
     * 
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified security policy id does not exist.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy details have been updated in the security policies mapping.
     * @dev    2. A `CreatedOrUpdatedSecurityPolicy` event has been emitted.
     *
     * @param  enforceExchangeWhitelist          Requires external exchange contracts be whitelisted to make buy calls.
     * @param  enforcePaymentMethodWhitelist     Requires that ERC-20 payment methods be pre-approved.
     * @param  enforcePricingConstraints         Allows the creator to specify exactly one approved payment method, 
     *                                           a minimum floor price and a maximum ceiling price.  
     *                                           When true, this value supercedes `enforcePaymentMethodWhitelist`.
     * @param  disablePrivateListings            Prevents private sales.
     * @param  disableDelegatedPurchases         Prevents delegated purchases.
     * @param  disableEIP1271Signatures          Prevents EIP-1271 compliant smart contracts such as multi-sig wallets
     *                                           from buying or selling.  Forces buyers and sellers to be EOAs.
     * @param  disableExchangeWhitelistEOABypass When exchange whitelists are enforced, prevents EOAs from executing
     *                                           purchases directly and bypassing whitelisted exchange contracts.
     * @param  pushPaymentGasLimit               The amount of gas to forward when pushing native proceeds.
     * @param  registryName                      A human readable name that describes the security policy.
     */
    function updateSecurityPolicy(
        uint256 securityPolicyId,
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        _createOrUpdateSecurityPolicy(
            securityPolicyId,
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName
        );
    }

    /**
     * @notice Allow security policy owners to transfer ownership of their security policy to a new account.
     *
     * @dev    Throws when `newOwner` is the zero address.
     * @dev    Throws when caller is not the owner of the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy owner has been updated in the security policies mapping.
     * @dev    2. A `SecurityPolicyOwnershipTransferred` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  newOwner         The new policy owner address.
     */
    function transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) external override {
        if(newOwner == address(0)) {
            revert PaymentProcessor__SecurityPolicyOwnershipCannotBeTransferredToZeroAddress();
        }

        _transferSecurityPolicyOwnership(securityPolicyId, newOwner);
    }

    /**
     * @notice Allow security policy owners to transfer ownership of their security policy to the zero address.
     *         This can be done to make a security policy permanently immutable.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The security policy owner has been set to the zero address in the security policies mapping.
     * @dev    2. A `SecurityPolicyOwnershipTransferred` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     */
    function renounceSecurityPolicyOwnership(uint256 securityPolicyId) external override {
        _transferSecurityPolicyOwnership(securityPolicyId, address(0));
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         set the security policy for their collection..
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified collection.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The `tokenSecurityPolicies` mapping has be updated to reflect the designated security policy id.
     * @dev    2. An `UpdatedCollectionSecurityPolicy` event has been emitted.
     *
     * @param  tokenAddress     The smart contract address of the NFT collection.
     * @param  securityPolicyId The security policy id to use for the collection.
     */
    function setCollectionSecurityPolicy(address tokenAddress, uint256 securityPolicyId) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if (securityPolicyId > lastSecurityPolicyId) {
            revert PaymentProcessor__SecurityPolicyDoesNotExist();
        }

        tokenSecurityPolicies[tokenAddress] = securityPolicyId;
        emit UpdatedCollectionSecurityPolicy(tokenAddress, securityPolicyId);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify the currency their collection is priced in.  Only applicable when `enforcePricingConstraints` 
     *         security setting is in effect for a collection.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the specified coin address non-zero and does not implement decimals() > 0.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The `collectionPaymentCoins` mapping has be updated to reflect the designated payment coin.
     * @dev    2. An `UpdatedCollectionPaymentCoin` event has been emitted.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  coin         The address of the designated ERC-20 payment coin smart contract.
     *                      Specify address(0) to designate native currency as the payment currency.
     */
    function setCollectionPaymentCoin(address tokenAddress, address coin) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);
        collectionPaymentCoins[tokenAddress] = coin;
        emit UpdatedCollectionPaymentCoin(tokenAddress, coin);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify their own bounded price at the collection level.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the previously set pricing bounds were set to be immutable.
     * @dev    Throws when the specified floor price is greater than the ceiling price.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The collection-level pricing bounds for the specified tokenAddress has been set.
     * @dev    2. An `UpdatedCollectionLevelPricingBoundaries` event has been emitted.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  pricingBounds Including the floor price, ceiling price, and an immutability flag.
     */
    function setCollectionPricingBounds(address tokenAddress, PricingBounds calldata pricingBounds) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if(collectionPricingBounds[tokenAddress].isImmutable) {
            revert PaymentProcessor__PricingBoundsAreImmutable();
        }

        if(pricingBounds.floorPrice > pricingBounds.ceilingPrice) {
            revert PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
        }
        
        collectionPricingBounds[tokenAddress] = pricingBounds;
        
        emit UpdatedCollectionLevelPricingBoundaries(
            tokenAddress, 
            pricingBounds.floorPrice, 
            pricingBounds.ceilingPrice);
    }

    /**
     * @notice Allows the smart contract, the contract owner, or the contract admin of any NFT collection to 
     *         specify their own bounded price at the individual token level.
     *
     * @dev    Throws when the specified tokenAddress is address(0).
     * @dev    Throws when the caller is not the contract, the owner or the administrator of the specified tokenAddress.
     * @dev    Throws when the lengths of the tokenIds and pricingBounds array don't match.
     * @dev    Throws when the tokenIds or pricingBounds array length is zero.     
     * @dev    Throws when the previously set pricing bounds of a token were set to be immutable.
     * @dev    Throws when the any of the specified floor prices is greater than the ceiling price for that token id.
     * 
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The token-level pricing bounds for the specified tokenAddress and token ids has been set.
     * @dev    2. An `UpdatedTokenLevelPricingBoundaries` event has been emitted.
     *
     * @param  tokenAddress  The smart contract address of the NFT collection.
     * @param  tokenIds      An array of token ids for which pricing bounds are being set.
     * @param  pricingBounds An array of pricing bounds used to set the floor, ceiling and immutability flag on the 
     *                       individual token level.
     */
    function setTokenPricingBounds(
        address tokenAddress, 
        uint256[] calldata tokenIds, 
        PricingBounds[] calldata pricingBounds) external override {
        _requireCallerIsNFTOrContractOwnerOrAdmin(tokenAddress);

        if(tokenIds.length != pricingBounds.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if(tokenIds.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        mapping (uint256 => PricingBounds) storage ptrTokenPricingBounds = tokenPricingBounds[tokenAddress];

        uint256 tokenId;
        for(uint256 i = 0; i < tokenIds.length;) {
            tokenId = tokenIds[i];
            PricingBounds memory pricingBounds_ = pricingBounds[i];

            if(ptrTokenPricingBounds[tokenId].isImmutable) {
                revert PaymentProcessor__PricingBoundsAreImmutable();
            }

            if(pricingBounds_.floorPrice > pricingBounds_.ceilingPrice) {
                revert PaymentProcessor__CeilingPriceMustBeGreaterThanFloorPrice();
            }

            ptrTokenPricingBounds[tokenId] = pricingBounds_;

            emit UpdatedTokenLevelPricingBoundaries(
                tokenAddress, 
                tokenId, 
                pricingBounds_.floorPrice, 
                pricingBounds_.ceilingPrice);
            
            unchecked {
                ++i;
            }
        }
    }

    /**
     * @notice Allows security policy owners to whitelist an exchange.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified address is address(0).
     * @dev    Throws when the specified address is already whitelisted under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `account` has been whitelisted in `exchangeWhitelist` mapping.
     * @dev    2. An `ExchangeAddedToWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  account          The address of the exchange to whitelist.
     */
    function whitelistExchange(uint256 securityPolicyId, address account) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        if (account == address(0)) {
            revert PaymentProcessor__AddressCannotBeZero();
        }

        mapping (address => bool) storage ptrExchangeWhitelist = exchangeWhitelist[securityPolicyId];

        if (ptrExchangeWhitelist[account]) {
            revert PaymentProcessor__ExchangeIsWhitelisted();
        }

        ptrExchangeWhitelist[account] = true;
        emit ExchangeAddedToWhitelist(securityPolicyId, account);
    }

    /**
     * @notice Allows security policy owners to remove an exchange from the whitelist.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified address is not whitelisted under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `account` has been unwhitelisted and removed from the `exchangeWhitelist` mapping.
     * @dev    2. An `ExchangeRemovedFromWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  account          The address of the exchange to unwhitelist.
     */
    function unwhitelistExchange(uint256 securityPolicyId, address account) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrExchangeWhitelist = exchangeWhitelist[securityPolicyId];

        if (!ptrExchangeWhitelist[account]) {
            revert PaymentProcessor__ExchangeIsNotWhitelisted();
        }

        delete ptrExchangeWhitelist[account];
        emit ExchangeRemovedFromWhitelist(securityPolicyId, account);
    }

    /**
     * @notice Allows security policy owners to approve a new coin for use as a payment currency.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified coin address is address(0).
     * @dev    Throws when the specified coin does not implement the decimals() that returns a non-zero value. 
     * @dev    Throws when the specified coin is already approved under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `coin` has been approved in `paymentMethodWhitelist` mapping.
     * @dev    2. A `PaymentMethodAddedToWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  coin             The address of the coin to approve.
     */
    function whitelistPaymentMethod(uint256 securityPolicyId, address coin) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrPaymentMethodWhitelist = paymentMethodWhitelist[securityPolicyId];

        if (ptrPaymentMethodWhitelist[coin]) {
            revert PaymentProcessor__CoinIsApproved();
        }

        ptrPaymentMethodWhitelist[coin] = true;
        emit PaymentMethodAddedToWhitelist(securityPolicyId, coin);
    }

    /**
     * @notice Allows security policy owners to remove a coin from the list of approved payment currencies.
     *
     * @dev    Throws when caller is not the owner of the specified security policy.
     * @dev    Throws when the specified coin is not currently approved under the specified security policy.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. `coin` has been removed from the `paymentMethodWhitelist` mapping.
     * @dev    2. A `PaymentMethodRemovedFromWhitelist` event has been emitted.
     *
     * @param  securityPolicyId The id of the security policy to update.
     * @param  coin             The address of the coin to disapprove.
     */
    function unwhitelistPaymentMethod(uint256 securityPolicyId, address coin) external override {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        mapping (address => bool) storage ptrPaymentMethodWhitelist = paymentMethodWhitelist[securityPolicyId];

        if (!ptrPaymentMethodWhitelist[coin]) {
            revert PaymentProcessor__CoinIsNotApproved();
        }

        delete ptrPaymentMethodWhitelist[coin];
        emit PaymentMethodRemovedFromWhitelist(securityPolicyId, coin);
    }

    /**
     * @notice Allows a user to revoke/cancel all prior signatures of listings and offers.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The user's master nonce has been incremented by `1` in contract storage, rendering all signed
     *            approvals using the prior nonce unusable.
     * @dev    2. A `MasterNonceInvalidated` event has been emitted.
     */
    function revokeMasterNonce() external override {
        emit MasterNonceInvalidated(masterNonces[_msgSender()], _msgSender());

        unchecked {
            ++masterNonces[_msgSender()];
        }
    }

    /**
     * @notice Allows a user to revoke/cancel a single, previously signed listing or offer by specifying the marketplace
     *         and nonce of the listing or offer.
     *
     * @dev    Throws when the user has already revoked the nonce.
     * @dev    Throws when the nonce was already used to successfully buy or sell an NFT.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The specified `nonce` for the specified `marketplace` and `msg.sender` pair has been revoked and can
     *            no longer be used to execute a sale or purchase.
     * @dev    2. A `RevokedListingOrOffer` event has been emitted.
     *
     * @param  marketplace The marketplace where the `msg.sender` signed the listing or offer.
     * @param  nonce       The nonce that was signed in the revoked listing or offer.
     */
    function revokeSingleNonce(address marketplace, uint256 nonce) external override {
        _checkAndInvalidateNonce(marketplace, _msgSender(), nonce, true);
    }

    /**
     * @notice Executes the sale of one ERC-721 or ERC-1155 token.
     *
     * @notice The seller's signature must be provided that proves that they approved the sale.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase.  There are two
     *         formats for this approval, one format to be used for collection-level offers when a specific token id is 
     *         not specified and one format to be used for item-level offers when a specific token id is specified.
     *
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         OfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice OR
     *
     * @notice ```
     *         CollectionOfferApproval(
     *           uint8 protocol,
     *           bool collectionLevelOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is ETH/native currency and the order was a collection or item offer.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the expiration timestamp of the listing or offer is in the past/expired.
     * @dev    Throws when the offer price is less than the seller-approved minimum price.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the seller or buyer is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         token or collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the token from the
     *         seller to the buyer.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuySingleListing` event has been emitted.
     * @dev    7. The token has been transferred from the seller to the buyer.
     *
     * @param saleDetails   See `MatchedOrder` struct.
     * @param signedListing See `SignatureECSA` struct.
     * @param signedOffer   See `SignatureECSA` struct.
     */
    function buySingleListing(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer
    ) external payable override {
        _requireNotPaused();
        if (!_executeMatchedOrderSale(msg.value, saleDetails, signedListing, signedOffer)) {
            revert PaymentProcessor__DispensingTokenWasUnsuccessful();
        }
    }

    /**
     * @notice Executes the sale of multiple ERC-721 or ERC-1155 tokens.
     *
     * @notice Sales may be a combination of native currency and ERC-20 payments.  Matched orders may be any combination
     *         of ERC-721 or ERC-1155 sales, as each matched order signature is validated independently against
     *         individual listings/orders associated with the matched orders.
     *
     * @notice A batch of orders will be partially filled in the case where an NFT is not available at the time of sale,
     *         but only if the method of payment is an ERC-20 token.  Partial fills are not supported for native
     *         payments to limit re-entrancy risks associated with issuing refunds.
     *
     * @notice The seller's signatures must be provided that proves that they approved the sales of each item.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each item.
     *         There are two formats for this approval, one format to be used for collection-level offers when a 
     *         specific token id is not specified and one format to be used for item-level offers when a specific token 
     *         id is specified.
     *
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         OfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice OR
     *
     * @notice ```
     *         CollectionOfferApproval(
     *           uint8 protocol,
     *           bool collectionLevelOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 amount,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when any of the input arrays have mismatched lengths.
     * @dev    Throws when any of the input arrays are empty.
     * @dev    Throws when the the amount of native funds included isn't exactly equal to the sum of the native sale
     *         prices of individual items.
     * @dev    Throws when the the amount of ERC-20 funds approved is less than the sum of the ERC-20
     *         prices of individual items.
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    For each individual matched order to process:
     *
     * @dev    Throws when payment method is ETH/native currency and the order was a collection or item offer.
     * @dev    Throws when payment method is an ERC-20 coin and supplied ETH/native funds for item is not equal to zero.
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the expiration timestamp of the listing or offer is in the past/expired.
     * @dev    Throws when the offer price is less than the seller-approved minimum price.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the seller or buyer is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         token or collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the token from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    For each item:
     *
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuySingleListing` event has been emitted.
     * @dev    7. The token has been transferred from the seller to the buyer.
     *
     * @param saleDetailsArray An array of `MatchedOrder` structs.
     * @param signedListings   An array of `SignatureECDSA` structs.
     * @param signedOffers     An array of `SignatureECDSA` structs.
     */
    function buyBatchOfListings(
        MatchedOrder[] calldata saleDetailsArray,
        SignatureECDSA[] calldata signedListings,
        SignatureECDSA[] calldata signedOffers
    ) external payable override {
        _requireNotPaused();

        if (saleDetailsArray.length != signedListings.length || 
            saleDetailsArray.length != signedOffers.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if (saleDetailsArray.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        uint256 runningBalanceNativeProceeds = msg.value;

        MatchedOrder memory saleDetails;
        SignatureECDSA memory signedListing;
        SignatureECDSA memory signedOffer;
        uint256 msgValue;

        for (uint256 i = 0; i < saleDetailsArray.length;) {
            saleDetails = saleDetailsArray[i];
            signedListing = signedListings[i];
            signedOffer = signedOffers[i];
            msgValue = 0;

            if(saleDetails.paymentCoin == address(0)) {
                msgValue = saleDetails.offerPrice;

                if (runningBalanceNativeProceeds < msgValue) {
                    revert PaymentProcessor__RanOutOfNativeFunds();
                }

                unchecked {
                    runningBalanceNativeProceeds -= msgValue;
                }

                if (!_executeMatchedOrderSale(msgValue, saleDetails, signedListing, signedOffer)) {
                    revert PaymentProcessor__DispensingTokenWasUnsuccessful();
                }
            } else {
                _executeMatchedOrderSale(msgValue, saleDetails, signedListing, signedOffer);
            }

            unchecked {
                ++i;
            }
        }

        if (runningBalanceNativeProceeds > 0) {
            revert PaymentProcessor__OverpaidNativeFunds();
        }
    }

    /**
     * @notice Executes the bundled sale of ERC-721 or ERC-1155 token listed by a single seller for a single collection.
     *
     * @notice Orders will be partially filled in the case where an NFT is not available at the time of sale,
     *         but only if the method of payment is an ERC-20 token.  Partial fills are not supported for native
     *         payments to limit re-entrancy risks associated with issuing refunds.
     *
     * @notice The seller's signature must be provided that proves that they approved the sale of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledSaleApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] maxRoyaltyFeeNumerators,
     *           uint256[] itemPrices)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledOfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] itemSalePrices)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when the bundled items array has a length of zero.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the offer price does not equal the sum of the individual item prices in the listing.
     * @dev    Throws when the expiration timestamp of the offer is in the past/expired.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    For each item in the bundled listing:
     *
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when the expiration timestamp of the listing is in the past/expired.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         tokens in the collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the tokens from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `BuyBundledListingERC721` or `BuyBundledListingERC1155`  event has been emitted.
     * @dev    7. The tokens in the bundle has been transferred from the seller to the buyer.
     *
     * @param signedListing See `SignatureECSA` struct.
     * @param signedOffer   See `SignatureECSA` struct.
     * @param bundleDetails See `MatchedOrderBundleExtended` struct.
     * @param bundleItems   See `BundledItem` struct. 
     */
    function buyBundledListing(
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] calldata bundleItems) external payable override {
        _requireNotPaused();

        if (bundleItems.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        (uint256 securityPolicyId, SecurityPolicy storage securityPolicy) = 
            _getTokenSecurityPolicy(bundleDetails.bundleBase.tokenAddress);

        SignatureECDSA[] memory signedListingAsSingletonArray = new SignatureECDSA[](1);
        signedListingAsSingletonArray[0] = signedListing;

        (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) = 
        _validateBundledItems(
            false,
            securityPolicy,
            bundleDetails,
            bundleItems,
            signedListingAsSingletonArray
        );

        _validateBundledOffer(
            securityPolicyId,
            securityPolicy,
            bundleDetails.bundleBase,
            accumulator,
            signedOffer
        );

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: bundleDetails.bundleBase.delegatedPurchaser == address(0) ? bundleDetails.bundleBase.buyer : bundleDetails.bundleBase.delegatedPurchaser,
                paymentCoin: IERC20(bundleDetails.bundleBase.paymentCoin),
                funcPayout: bundleDetails.bundleBase.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: bundleDetails.bundleBase.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsBatch
        );

        if (bundleDetails.bundleBase.protocol == TokenProtocols.ERC1155) {
            emit BuyBundledListingERC1155(
                    bundleDetails.bundleBase.marketplace,
                    bundleDetails.bundleBase.tokenAddress,
                    bundleDetails.bundleBase.paymentCoin,
                    bundleDetails.bundleBase.buyer,
                    bundleDetails.seller,
                    unsuccessfulFills,
                    accumulator.tokenIds,
                    accumulator.amounts,
                    accumulator.salePrices);
        } else {
            emit BuyBundledListingERC721(
                    bundleDetails.bundleBase.marketplace,
                    bundleDetails.bundleBase.tokenAddress,
                    bundleDetails.bundleBase.paymentCoin,
                    bundleDetails.bundleBase.buyer,
                    bundleDetails.seller,
                    unsuccessfulFills,
                    accumulator.tokenIds,
                    accumulator.salePrices);
        }
    }

    /**
     * @notice Executes the bundled purchase of ERC-721 or ERC-1155 tokens individually listed for a single collection.
     *
     * @notice The seller's signatures must be provided that proves that they approved the sales of each item.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         SaleApproval(
     *           uint8 protocol,
     *           bool sellerAcceptedOffer,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           uint256 maxRoyaltyFeeNumerator,
     *           address privateBuyer,
     *           address seller,
     *           address tokenAddress,
     *           uint256 tokenId,
     *           uint256 amount,
     *           uint256 minPrice,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin)
     *         ```
     *
     * @notice The buyer's signature must be provided that proves that they approved the purchase of each token.
     * @notice This an an EIP-712 signature with the following data format.
     * @notice ```EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)```
     * @notice ```
     *         BundledOfferApproval(
     *           uint8 protocol,
     *           address marketplace,
     *           uint256 marketplaceFeeNumerator,
     *           address delegatedPurchaser,
     *           address buyer,
     *           address tokenAddress,
     *           uint256 price,
     *           uint256 expiration,
     *           uint256 nonce,
     *           uint256 masterNonce,
     *           address coin,
     *           uint256[] tokenIds,
     *           uint256[] amounts,
     *           uint256[] itemSalePrices)
     *         ```
     *
     * @dev    WARNING: Calling marketplaces MUST be aware that for ERC-1155 sales, a `safeTransferFrom` function is
     *         called which provides surface area for cross-contract re-entrancy.  Marketplace contracts are responsible
     *         for ensuring this is safely handled.
     *
     * @dev    Throws when payment processor has been `paused`.
     * @dev    Throws when any of the input arrays have mismatched lengths.
     * @dev    Throws when any of the input array have a length of zero.
     * @dev    Throws when payment method is ETH/native currency and offer price does not equal `msg.value`.
     * @dev    Throws when payment method is an ERC-20 coin and `msg.value` is not equal to zero.
     * @dev    Throws when the offer price does not equal the sum of the individual item prices in the listing.
     * @dev    Throws when the expiration timestamp of the offer is in the past/expired.
     * @dev    Throws when a private buyer is specified and the buyer does not match the private buyer.
     * @dev    Throws when a private buyer is specified and private listings are disabled by collection security policy.
     * @dev    Throws when a delegated purchaser is specified and the `msg.sender` is not the delegated purchaser.
     * @dev    Throws when a delegated purchaser is specified and delegated purchases are disabled by collection 
     *         security policy.
     * @dev    Throws when the exchange whitelist is enforced by collection security policy and `msg.sender` is a 
     *         smart contract that is not on the whitelist.
     * @dev    Throws when the exchange whitelist is enforced AND exchange whitelist EOA bypass is disabled by 
     *         collection security policy and `msg.sender` is an EOA that is not whitelisted. 
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the buyer's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed offer is not equal to the buyer's current `masterNonce.
     * @dev    Throws when the buyer is an EOA and ECDSA recover operation on the OfferApproval EIP-712 signature 
     *         does not return the buyer's address, meaning the buyer did not approve the purchase with the provided 
     *         purchase details.
     * @dev    Throws when the buyer is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied offer signature.
     * @dev    Throws when the transfer of ERC-20 coin payment tokens from the purchaser fails.
     * @dev    Throws when the distribution of native proceeds cannot be accepted or fails for any reason.
     *
     * @dev    For each item in the bundled listing:
     *
     * @dev    Throws when the protocol is ERC-721 and amount is not equal to `1`.
     * @dev    Throws when the protocol is ERC-1155 and amount is equal to `0`.
     * @dev    Throws when the marketplace fee + royalty fee numerators exceeds 10,000 (100%).
     * @dev    Throws when the collection security policy enforces pricing constraints and the payment/sale price
     *         violates the constraints.
     * @dev    Throws when the expiration timestamp of the listing is in the past/expired.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been used to execute a sale.
     * @dev    Throws when the seller's nonce on the specified marketplace has already been revoked/canceled.
     * @dev    Throws when the `masterNonce` in the signed listing is not equal to the seller's current `masterNonce.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signatures are disabled by collection
     *         security policy.
     * @dev    Throws when the seller is an EOA and ECDSA recover operation on the SaleApproval EIP-712 signature 
     *         does not return the seller's address, meaning the seller did not approve the sale with the provided 
     *         sale details.
     * @dev    Throws when the seller is a smart contract and EIP-1271 signature validation returns false for the
     *         supplied listing signature.
     * @dev    Throws when the onchain royalty amount exceeds the seller-approved maximum royalty fee.
     * @dev    Throws when the seller has not approved the Payment Processor contract for transfers of the specified
     *         tokens in the collection.
     * @dev    Throws when transferFrom (ERC-721) or safeTransferFrom (ERC-1155) fails to transfer the tokens from the
     *         seller to the buyer and method of payment is native currency. (Partial fills allowed for ERC-20 payments).
     *
     * @dev    <h4>Postconditions:</h4>
     * @dev    1. The listing nonce for the specified marketplace and seller has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    2. The offer nonce for the specified marketplace and buyer has been marked as invalidated so that it 
     *            cannot be replayed/used again.
     * @dev    3. Applicable royalties have been paid to the address designated with EIP-2981 (when implemented on the
     *            NFT contract).
     * @dev    4. Applicable marketplace fees have been paid to the designated marketplace.
     * @dev    5. All remaining funds have been paid to the seller of the token.
     * @dev    6. The `SweepCollectionERC721` or `SweepCollectionERC1155`  event has been emitted.
     * @dev    7. The tokens in the bundle has been transferred from the seller to the buyer.
     *
     * @param signedOffer    See `SignatureECSA` struct.
     * @param bundleDetails  See `MatchedOrderBundleBase` struct.
     * @param bundleItems    See `BundledItem` struct. 
     * @param signedListings See `SignatureECSA` struct.
     */
    function sweepCollection(
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleBase memory bundleDetails,
        BundledItem[] calldata bundleItems,
        SignatureECDSA[] calldata signedListings) external payable override {
        _requireNotPaused();

        if (bundleItems.length != signedListings.length) {
            revert PaymentProcessor__InputArrayLengthMismatch();
        }

        if (bundleItems.length == 0) {
            revert PaymentProcessor__InputArrayLengthCannotBeZero();
        }

        (uint256 securityPolicyId, SecurityPolicy storage securityPolicy) = 
            _getTokenSecurityPolicy(bundleDetails.tokenAddress);

        (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) = 
        _validateBundledItems(
            true,
            securityPolicy,
            MatchedOrderBundleExtended({
                bundleBase: bundleDetails,
                seller: address(0),
                listingNonce: 0,
                listingExpiration: 0
            }),
            bundleItems,
            signedListings
        );

        _validateBundledOffer(
            securityPolicyId,
            securityPolicy,
            bundleDetails,
            accumulator,
            signedOffer
        );

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: bundleDetails.delegatedPurchaser == address(0) ? bundleDetails.buyer : bundleDetails.delegatedPurchaser,
                paymentCoin: IERC20(bundleDetails.paymentCoin),
                funcPayout: bundleDetails.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: bundleDetails.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsBatch
        );

        if (bundleDetails.protocol == TokenProtocols.ERC1155) {
            emit SweepCollectionERC1155(
                    bundleDetails.marketplace,
                    bundleDetails.tokenAddress,
                    bundleDetails.paymentCoin,
                    bundleDetails.buyer,
                    unsuccessfulFills,
                    accumulator.sellers,
                    accumulator.tokenIds,
                    accumulator.amounts,
                    accumulator.salePrices);
        } else {
            emit SweepCollectionERC721(
                    bundleDetails.marketplace,
                    bundleDetails.tokenAddress,
                    bundleDetails.paymentCoin,
                    bundleDetails.buyer,
                    unsuccessfulFills,
                    accumulator.sellers,
                    accumulator.tokenIds,
                    accumulator.salePrices);
        }
    }

    /**
     * @notice Returns the EIP-712 domain separator for this contract.
     */
    function getDomainSeparator() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @notice Returns the security policy details for the specified security policy id.
     * 
     * @param  securityPolicyId The security policy id to lookup.
     * @return securityPolicy   The security policy details.
     */
    function getSecurityPolicy(uint256 securityPolicyId) external view override returns (SecurityPolicy memory) {
        return securityPolicies[securityPolicyId];
    }

    /**
     * @notice Returns whitelist status of the exchange address for the specified security policy id.
     *
     * @param  securityPolicyId The security policy id to lookup.
     * @param  account          The address to check.
     * @return isWhitelisted    True if the address is whitelisted, false otherwise.
     */
    function isWhitelisted(uint256 securityPolicyId, address account) external view override returns (bool) {
        return exchangeWhitelist[securityPolicyId][account];
    }

    /**
     * @notice Returns approval status of the payment coin address for the specified security policy id.
     *
     * @param  securityPolicyId        The security policy id to lookup.
     * @param  coin                    The coin address to check.
     * @return isPaymentMethodApproved True if the coin address is approved, false otherwise.
     */
    function isPaymentMethodApproved(uint256 securityPolicyId, address coin) external view override returns (bool) {
        return paymentMethodWhitelist[securityPolicyId][coin];
    }

    /**
     * @notice Returns the current security policy id for the specified collection address.
     * 
     * @param  collectionAddress The address of the collection to lookup.
     * @return securityPolicyId  The current security policy id for the specifed collection.
     */
    function getTokenSecurityPolicyId(address collectionAddress) external view override returns (uint256) {
        return tokenSecurityPolicies[collectionAddress];
    }

    /**
     * @notice Returns whether or not the price of a collection is immutable.
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @return True if the floor and ceiling price for the specified token contract has been set immutably, false otherwise.
     */
    function isCollectionPricingImmutable(address tokenAddress) external view override returns (bool) {
        return collectionPricingBounds[tokenAddress].isImmutable;
    }

    /**
     * @notice Returns whether or not the price of a specific token is immutable.
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return True if the floor and ceiling price for the specified token contract and tokenId has been set immutably, false otherwise.
     */
    function isTokenPricingImmutable(address tokenAddress, uint256 tokenId) external view override returns (bool) {
        return tokenPricingBounds[tokenAddress][tokenId].isImmutable;
    }

    /**
     * @notice Gets the floor price for the specified nft contract address and token id.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return The floor price.
     */
    function getFloorPrice(address tokenAddress, uint256 tokenId) external view override returns (uint256) {
        (uint256 floorPrice,) = _getFloorAndCeilingPrices(tokenAddress, tokenId);
        return floorPrice;
    }

    /**
     * @notice Gets the ceiling price for the specified nft contract address and token id.
     *
     * @param  tokenAddress The smart contract address of the NFT collection.
     * @param  tokenId      The token id.
     * @return The ceiling price.
     */
    function getCeilingPrice(address tokenAddress, uint256 tokenId) external view override returns (uint256) {
        (, uint256 ceilingPrice) = _getFloorAndCeilingPrices(tokenAddress, tokenId);
        return ceilingPrice;
    }

    /**
     * @notice ERC-165 Interface Introspection Support.
     * @dev    Supports `IPaymentProcessor` interface as well as parent contract interfaces.
     * @param  interfaceId The interface to query.
     * @return True if the interface is supported, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IPaymentProcessor).interfaceId || super.supportsInterface(interfaceId);
    }

    function _payoutNativeCurrency(
        address payee, 
        address /*payer*/, 
        IERC20 /*paymentCoin*/, 
        uint256 proceeds, 
        uint256 gasLimit_) internal {
        _pushProceeds(payee, proceeds, gasLimit_);
    }

    function _payoutCoinCurrency(
        address payee, 
        address payer, 
        IERC20 paymentCoin, 
        uint256 proceeds, 
        uint256 /*gasLimit_*/) internal {
        SafeERC20.safeTransferFrom(paymentCoin, payer, payee, proceeds);
    }

    function _dispenseERC721Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 /*amount*/) internal returns (bool) {
        try IERC721(tokenAddress).transferFrom(from, to, tokenId) {
            return true;
        } catch {
            return false;
        }
    }

    function _dispenseERC1155Token(
        address from, 
        address to, 
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount) internal returns (bool) {
        try IERC1155(tokenAddress).safeTransferFrom(from, to, tokenId, amount, "") {
            return true;
        } catch {
            return false;
        }
    }

    function _requireCallerIsNFTOrContractOwnerOrAdmin(address tokenAddress) internal view {
        bool callerHasPermissions = false;
        
        callerHasPermissions = _msgSender() == tokenAddress;
        if(!callerHasPermissions) {
            try IOwnable(tokenAddress).owner() returns (address contractOwner) {
                callerHasPermissions = _msgSender() == contractOwner;
            } catch {}

            if(!callerHasPermissions) {
                try IAccessControl(tokenAddress).hasRole(DEFAULT_ACCESS_CONTROL_ADMIN_ROLE, _msgSender()) 
                    returns (bool callerIsContractAdmin) {
                    callerHasPermissions = callerIsContractAdmin;
                } catch {}
            }
        }

        if(!callerHasPermissions) {
            revert PaymentProcessor__CallerMustHaveElevatedPermissionsForSpecifiedNFT();
        }
    }

    function _verifyPaymentCoinIsApproved(
        uint256 securityPolicyId, 
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        address tokenAddress, 
        address coin) internal view virtual {
        if (enforcePricingConstraints) {
            if(collectionPaymentCoins[tokenAddress] != coin) {
                revert PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
            }
        } else if (enforcePaymentMethodWhitelist) {
            if (!paymentMethodWhitelist[securityPolicyId][coin]) {
                revert PaymentProcessor__PaymentCoinIsNotAnApprovedPaymentMethod();
            }
        }
    }

    function _createOrUpdateSecurityPolicy(
        uint256 securityPolicyId,
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) private {

        securityPolicies[securityPolicyId] = SecurityPolicy({
            enforceExchangeWhitelist: enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist: enforcePaymentMethodWhitelist,
            enforcePricingConstraints: enforcePricingConstraints,
            disablePrivateListings: disablePrivateListings,
            disableDelegatedPurchases: disableDelegatedPurchases,
            disableEIP1271Signatures: disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass: disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit: pushPaymentGasLimit,
            policyOwner: _msgSender()
        });

        emit CreatedOrUpdatedSecurityPolicy(
            securityPolicyId, 
            enforceExchangeWhitelist,
            enforcePaymentMethodWhitelist,
            enforcePricingConstraints,
            disablePrivateListings,
            disableDelegatedPurchases,
            disableEIP1271Signatures,
            disableExchangeWhitelistEOABypass,
            pushPaymentGasLimit,
            registryName);
    }

    function _transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) private {
        _requireCallerOwnsSecurityPolicy(securityPolicyId);

        SecurityPolicy storage securityPolicy = securityPolicies[securityPolicyId];

        address oldOwner = securityPolicy.policyOwner;
        securityPolicy.policyOwner = newOwner;
        emit SecurityPolicyOwnershipTransferred(oldOwner, newOwner);
    }

    function _executeMatchedOrderSale(
        uint256 msgValue,
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer
    ) private returns (bool tokenDispensedSuccessfully) {
        uint256 securityPolicyId = tokenSecurityPolicies[saleDetails.tokenAddress];
        SecurityPolicy memory securityPolicy = securityPolicies[securityPolicyId];

        if (saleDetails.paymentCoin == address(0)) {
            if (saleDetails.offerPrice != msgValue) {
                revert PaymentProcessor__OfferPriceMustEqualSalePrice();
            }

            if (saleDetails.sellerAcceptedOffer || saleDetails.seller == tx.origin) {
                revert PaymentProcessor__CollectionLevelOrItemLevelOffersCanOnlyBeMadeUsingERC20PaymentMethods();
            }
        } else {
            if (msgValue > 0) {
                revert PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
            }

            _verifyPaymentCoinIsApproved(
                securityPolicyId, 
                securityPolicy.enforcePaymentMethodWhitelist, 
                securityPolicy.enforcePricingConstraints,
                saleDetails.tokenAddress, 
                saleDetails.paymentCoin);
        }
        
        if (saleDetails.protocol == TokenProtocols.ERC1155) {
            if (saleDetails.amount == 0) {
                revert PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
            }
        } else {
            if (saleDetails.amount != ONE) {
                revert PaymentProcessor__AmountForERC721SalesMustEqualOne();
            }
        }

        if (block.timestamp > saleDetails.listingExpiration) {
            revert PaymentProcessor__SaleHasExpired();
        }

        if (block.timestamp > saleDetails.offerExpiration) {
            revert PaymentProcessor__OfferHasExpired();
        }

        if (saleDetails.offerPrice < saleDetails.listingMinPrice) {
            revert PaymentProcessor__SalePriceBelowSellerApprovedMinimum();
        }

        if (saleDetails.marketplaceFeeNumerator + saleDetails.maxRoyaltyFeeNumerator > FEE_DENOMINATOR) {
            revert PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
        }

        if (saleDetails.privateBuyer != address(0)) {
            if (saleDetails.buyer != saleDetails.privateBuyer) {
                revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
            }
    
            if (securityPolicy.disablePrivateListings) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
            }
        }

        if (saleDetails.delegatedPurchaser != address(0)) {
            if (_msgSender() != saleDetails.delegatedPurchaser) {
                revert PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
            }

            if(securityPolicy.disableDelegatedPurchases) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
            }
        }

        if(securityPolicy.disableEIP1271Signatures) {
            if (saleDetails.seller.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }

            if (saleDetails.buyer.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }
        }

        if (securityPolicy.enforceExchangeWhitelist) {
            if (_msgSender() != tx.origin) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__CallerIsNotWhitelistedMarketplace();
                }
            } else if (securityPolicy.disableExchangeWhitelistEOABypass) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
                }
            }
        }

        if (securityPolicy.enforcePricingConstraints) {
            if (saleDetails.paymentCoin == address(0)) {
                if(collectionPaymentCoins[saleDetails.tokenAddress] != address(0)) {
                    revert PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
                }
            }

            _verifySalePriceInRange(
                saleDetails.tokenAddress, 
                saleDetails.tokenId, 
                saleDetails.amount, 
                saleDetails.offerPrice);
        }

        _verifySignedItemListing(saleDetails, signedListing);

        if (saleDetails.collectionLevelOffer) {
            _verifySignedCollectionOffer(saleDetails, signedOffer);
        } else {
            _verifySignedItemOffer(saleDetails, signedOffer);
        }

        MatchedOrder[] memory saleDetailsSingletonBatch = new MatchedOrder[](1);
        saleDetailsSingletonBatch[0] = saleDetails;

        bool[] memory unsuccessfulFills = _computeAndDistributeProceeds(
            ComputeAndDistributeProceedsArgs({
                pushPaymentGasLimit: securityPolicy.pushPaymentGasLimit,
                purchaser: saleDetails.delegatedPurchaser == address(0) ? saleDetails.buyer : saleDetails.delegatedPurchaser,
                paymentCoin: IERC20(saleDetails.paymentCoin),
                funcPayout: saleDetails.paymentCoin == address(0) ? _payoutNativeCurrency : _payoutCoinCurrency,
                funcDispenseToken: saleDetails.protocol == TokenProtocols.ERC1155 ? _dispenseERC1155Token : _dispenseERC721Token
            }),
            saleDetailsSingletonBatch
        );

        tokenDispensedSuccessfully = !unsuccessfulFills[0];

        if (tokenDispensedSuccessfully) {
            emit BuySingleListing(
                saleDetails.marketplace,
                saleDetails.tokenAddress,
                saleDetails.paymentCoin,
                saleDetails.buyer,
                saleDetails.seller,
                saleDetails.tokenId,
                saleDetails.amount,
                saleDetails.offerPrice);
        }
    }

    function _validateBundledOffer(
        uint256 securityPolicyId,
        SecurityPolicy storage securityPolicy,
        MatchedOrderBundleBase memory bundleDetails,
        Accumulator memory accumulator,
        SignatureECDSA memory signedOffer) private {
        if (bundleDetails.paymentCoin != address(0)) {
            if (msg.value > 0) {
                revert PaymentProcessor__CannotIncludeNativeFundsWhenPaymentMethodIsAnERC20Coin();
            }
    
            _verifyPaymentCoinIsApproved(
                securityPolicyId, 
                securityPolicy.enforcePaymentMethodWhitelist, 
                securityPolicy.enforcePricingConstraints,
                bundleDetails.tokenAddress, 
                bundleDetails.paymentCoin);
        } else {
            if (msg.value != bundleDetails.offerPrice) {
                revert PaymentProcessor__OfferPriceMustEqualSalePrice();
            }

            if (securityPolicy.enforcePricingConstraints) {
                if(collectionPaymentCoins[bundleDetails.tokenAddress] != address(0)) {
                    revert PaymentProcessor__NativeCurrencyIsNotAnApprovedPaymentMethod();
                }
            }
        }

        if (block.timestamp > bundleDetails.offerExpiration) {
            revert PaymentProcessor__OfferHasExpired();
        }

        if (bundleDetails.delegatedPurchaser != address(0)) {
            if (_msgSender() != bundleDetails.delegatedPurchaser) {
                revert PaymentProcessor__CallerIsNotTheDelegatedPurchaser();
            }

            if(securityPolicy.disableDelegatedPurchases) {
                revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowDelegatedPurchases();
            }
        }

        if(securityPolicy.disableEIP1271Signatures) {
            if (bundleDetails.buyer.code.length > 0) {
                revert PaymentProcessor__EIP1271SignaturesAreDisabled();
            }
        }

        if (securityPolicy.enforceExchangeWhitelist) {
            if (_msgSender() != tx.origin) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__CallerIsNotWhitelistedMarketplace();
                }
            } else if (securityPolicy.disableExchangeWhitelistEOABypass) {
                if (!exchangeWhitelist[securityPolicyId][_msgSender()]) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowEOACallers();
                }
            }
        }

        if (accumulator.sumListingPrices != bundleDetails.offerPrice) {
            revert PaymentProcessor__BundledOfferPriceMustEqualSumOfAllListingPrices();
        }

        _verifySignedOfferForBundledItems(
            keccak256(abi.encodePacked(accumulator.tokenIds)),
            keccak256(abi.encodePacked(accumulator.amounts)),
            keccak256(abi.encodePacked(accumulator.salePrices)),
            bundleDetails,
            signedOffer
        );
    }

    function _validateBundledItems(
        bool individualListings,
        SecurityPolicy storage securityPolicy,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] memory bundledOfferItems,
        SignatureECDSA[] memory signedListings) 
        private returns (Accumulator memory accumulator, MatchedOrder[] memory saleDetailsBatch) {

        saleDetailsBatch = new MatchedOrder[](bundledOfferItems.length);
        accumulator = Accumulator({
            tokenIds: new uint256[](bundledOfferItems.length),
            amounts: new uint256[](bundledOfferItems.length),
            salePrices: new uint256[](bundledOfferItems.length),
            maxRoyaltyFeeNumerators: new uint256[](bundledOfferItems.length),
            sellers: new address[](bundledOfferItems.length),
            sumListingPrices: 0
        });

        for (uint256 i = 0; i < bundledOfferItems.length;) {

            address seller = bundleDetails.seller;
            uint256 listingNonce = bundleDetails.listingNonce;
            uint256 listingExpiration = bundleDetails.listingExpiration;

            if (individualListings) {
                seller = bundledOfferItems[i].seller;
                listingNonce = bundledOfferItems[i].listingNonce;
                listingExpiration = bundledOfferItems[i].listingExpiration;
            }
            
            MatchedOrder memory saleDetails = 
                MatchedOrder({
                    sellerAcceptedOffer: false,
                    collectionLevelOffer: false,
                    protocol: bundleDetails.bundleBase.protocol,
                    paymentCoin: bundleDetails.bundleBase.paymentCoin,
                    tokenAddress: bundleDetails.bundleBase.tokenAddress,
                    seller: seller,
                    privateBuyer: bundleDetails.bundleBase.privateBuyer,
                    buyer: bundleDetails.bundleBase.buyer,
                    delegatedPurchaser: bundleDetails.bundleBase.delegatedPurchaser,
                    marketplace: bundleDetails.bundleBase.marketplace,
                    marketplaceFeeNumerator: bundleDetails.bundleBase.marketplaceFeeNumerator,
                    maxRoyaltyFeeNumerator: bundledOfferItems[i].maxRoyaltyFeeNumerator,
                    listingNonce: listingNonce,
                    offerNonce: bundleDetails.bundleBase.offerNonce,
                    listingMinPrice: bundledOfferItems[i].itemPrice,
                    offerPrice: bundledOfferItems[i].itemPrice,
                    listingExpiration: listingExpiration,
                    offerExpiration: bundleDetails.bundleBase.offerExpiration,
                    tokenId: bundledOfferItems[i].tokenId,
                    amount: bundledOfferItems[i].amount
                });

            saleDetailsBatch[i] = saleDetails;

            accumulator.tokenIds[i] = saleDetails.tokenId;
            accumulator.amounts[i] = saleDetails.amount;
            accumulator.salePrices[i] = saleDetails.listingMinPrice;
            accumulator.maxRoyaltyFeeNumerators[i] = saleDetails.maxRoyaltyFeeNumerator;
            accumulator.sellers[i] = saleDetails.seller;
            accumulator.sumListingPrices += saleDetails.listingMinPrice;

            if (saleDetails.protocol == TokenProtocols.ERC1155) {
                if (saleDetails.amount == 0) {
                    revert PaymentProcessor__AmountForERC1155SalesGreaterThanZero();
                }
            } else {
                if (saleDetails.amount != ONE) {
                    revert PaymentProcessor__AmountForERC721SalesMustEqualOne();
                }
            }

            if (saleDetails.marketplaceFeeNumerator + saleDetails.maxRoyaltyFeeNumerator > FEE_DENOMINATOR) {
                revert PaymentProcessor__MarketplaceAndRoyaltyFeesWillExceedSalePrice();
            }

            if (securityPolicy.enforcePricingConstraints) {
                _verifySalePriceInRange(
                    saleDetails.tokenAddress, 
                    saleDetails.tokenId, 
                    saleDetails.amount, 
                    saleDetails.offerPrice);
            }
   
            if (individualListings) {
                if (block.timestamp > saleDetails.listingExpiration) {
                    revert PaymentProcessor__SaleHasExpired();
                }

                if (saleDetails.privateBuyer != address(0)) {
                    if (saleDetails.buyer != saleDetails.privateBuyer) {
                        revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
                    }
    
                    if (securityPolicy.disablePrivateListings) {
                        revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
                    }
                }
        
                if(securityPolicy.disableEIP1271Signatures) {
                    if (saleDetails.seller.code.length > 0) {
                        revert PaymentProcessor__EIP1271SignaturesAreDisabled();
                    }
                }
    
                _verifySignedItemListing(saleDetails, signedListings[i]);
            }

            unchecked {
                ++i;
            }
        }

        if(!individualListings) {
            if (block.timestamp > bundleDetails.listingExpiration) {
                revert PaymentProcessor__SaleHasExpired();
            }

            if (bundleDetails.bundleBase.privateBuyer != address(0)) {
                if (bundleDetails.bundleBase.buyer != bundleDetails.bundleBase.privateBuyer) {
                    revert PaymentProcessor__BuyerMustBeDesignatedPrivateBuyer();
                }
    
                if (securityPolicy.disablePrivateListings) {
                    revert PaymentProcessor__TokenSecurityPolicyDoesNotAllowPrivateListings();
                }
            }

            if(securityPolicy.disableEIP1271Signatures) {
                if (bundleDetails.seller.code.length > 0) {
                    revert PaymentProcessor__EIP1271SignaturesAreDisabled();
                }
            }

            _verifySignedBundleListing(
                AccumulatorHashes({
                    tokenIdsKeccakHash: keccak256(abi.encodePacked(accumulator.tokenIds)),
                    amountsKeccakHash: keccak256(abi.encodePacked(accumulator.amounts)),
                    maxRoyaltyFeeNumeratorsKeccakHash: keccak256(abi.encodePacked(accumulator.maxRoyaltyFeeNumerators)),
                    itemPricesKeccakHash: keccak256(abi.encodePacked(accumulator.salePrices))
                }),
                bundleDetails, 
                signedListings[0]);
        }
    }

    function _verifySignedItemOffer(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedOffer) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        OFFER_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.delegatedPurchaser,
                        saleDetails.buyer,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.amount,
                        saleDetails.offerPrice
                    ),
                    abi.encode(
                        saleDetails.offerExpiration,
                        saleDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.buyer, 
                            saleDetails.offerNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.buyer, digest, signedOffer);
        } else if (saleDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedCollectionOffer(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedOffer) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        COLLECTION_OFFER_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.collectionLevelOffer,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.delegatedPurchaser,
                        saleDetails.buyer,
                        saleDetails.tokenAddress,
                        saleDetails.amount,
                        saleDetails.offerPrice
                    ),
                    abi.encode(
                        saleDetails.offerExpiration,
                        saleDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.buyer, 
                            saleDetails.offerNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.buyer, digest, signedOffer);
        } else if (saleDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedOfferForBundledItems(
        bytes32 tokenIdsKeccakHash,
        bytes32 amountsKeccakHash,
        bytes32 salePricesKeccakHash,
        MatchedOrderBundleBase memory bundledOfferDetails,
        SignatureECDSA memory signedOffer) private {

        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_OFFER_APPROVAL_HASH,
                        uint8(bundledOfferDetails.protocol),
                        bundledOfferDetails.marketplace,
                        bundledOfferDetails.marketplaceFeeNumerator,
                        bundledOfferDetails.delegatedPurchaser,
                        bundledOfferDetails.buyer,
                        bundledOfferDetails.tokenAddress,
                        bundledOfferDetails.offerPrice
                    ),
                    abi.encode(
                        bundledOfferDetails.offerExpiration,
                        bundledOfferDetails.offerNonce,
                        _checkAndInvalidateNonce(
                            bundledOfferDetails.marketplace, 
                            bundledOfferDetails.buyer, 
                            bundledOfferDetails.offerNonce,
                            false
                        ),
                        bundledOfferDetails.paymentCoin,
                        tokenIdsKeccakHash,
                        amountsKeccakHash,
                        salePricesKeccakHash
                    )
                )
            )
        );

        if(bundledOfferDetails.buyer.code.length > 0) {
            _verifyEIP1271Signature(bundledOfferDetails.buyer, digest, signedOffer);
        } else if (bundledOfferDetails.buyer != ECDSA.recover(digest, signedOffer.v, signedOffer.r, signedOffer.s)) {
            revert PaymentProcessor__BuyerDidNotAuthorizePurchase();
        }
    }

    function _verifySignedBundleListing(
        AccumulatorHashes memory accumulatorHashes,
        MatchedOrderBundleExtended memory bundleDetails,
        SignatureECDSA memory signedListing) private {

        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        BUNDLED_SALE_APPROVAL_HASH,
                        uint8(bundleDetails.bundleBase.protocol),
                        bundleDetails.bundleBase.marketplace,
                        bundleDetails.bundleBase.marketplaceFeeNumerator,
                        bundleDetails.bundleBase.privateBuyer,
                        bundleDetails.seller,
                        bundleDetails.bundleBase.tokenAddress
                    ),
                    abi.encode(
                        bundleDetails.listingExpiration,
                        bundleDetails.listingNonce,
                        _checkAndInvalidateNonce(
                            bundleDetails.bundleBase.marketplace, 
                            bundleDetails.seller, 
                            bundleDetails.listingNonce,
                            false
                        ),
                        bundleDetails.bundleBase.paymentCoin,
                        accumulatorHashes.tokenIdsKeccakHash,
                        accumulatorHashes.amountsKeccakHash,
                        accumulatorHashes.maxRoyaltyFeeNumeratorsKeccakHash,
                        accumulatorHashes.itemPricesKeccakHash
                    )
                )
            )
        );

        if(bundleDetails.seller.code.length > 0) {
            _verifyEIP1271Signature(bundleDetails.seller, digest, signedListing);
        } else if (bundleDetails.seller != ECDSA.recover(digest, signedListing.v, signedListing.r, signedListing.s)) {
            revert PaymentProcessor__SellerDidNotAuthorizeSale();
        }
    }

    function _verifySignedItemListing(
        MatchedOrder memory saleDetails,
        SignatureECDSA memory signedListing) private {
        bytes32 digest = 
            _hashTypedDataV4(keccak256(
                bytes.concat(
                    abi.encode(
                        SALE_APPROVAL_HASH,
                        uint8(saleDetails.protocol),
                        saleDetails.sellerAcceptedOffer,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.maxRoyaltyFeeNumerator,
                        saleDetails.privateBuyer
                    ),
                    abi.encode(
                        saleDetails.seller,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.amount,
                        saleDetails.listingMinPrice,
                        saleDetails.listingExpiration,
                        saleDetails.listingNonce,
                        _checkAndInvalidateNonce(
                            saleDetails.marketplace, 
                            saleDetails.seller, 
                            saleDetails.listingNonce,
                            false
                        ),
                        saleDetails.paymentCoin
                    )
                )
            )
        );

        if(saleDetails.seller.code.length > 0) {
            _verifyEIP1271Signature(saleDetails.seller, digest, signedListing);
        } else if (saleDetails.seller != ECDSA.recover(digest, signedListing.v, signedListing.r, signedListing.s)) {
            revert PaymentProcessor__SellerDidNotAuthorizeSale();
        }
    }

    function _checkAndInvalidateNonce(
        address marketplace, 
        address account, 
        uint256 nonce, 
        bool wasCancellation) private returns (uint256) {

        mapping(uint256 => uint256) storage ptrInvalidatedSignatureBitmap =
            invalidatedSignatures[keccak256(abi.encodePacked(marketplace, account))];

        unchecked {
            uint256 slot = nonce / 256;
            uint256 offset = nonce % 256;
            uint256 slotValue = ptrInvalidatedSignatureBitmap[slot];

            if (((slotValue >> offset) & ONE) == ONE) {
                revert PaymentProcessor__SignatureAlreadyUsedOrRevoked();
            }

            ptrInvalidatedSignatureBitmap[slot] = (slotValue | ONE << offset);
        }

        emit NonceInvalidated(nonce, account, marketplace, wasCancellation);

        return masterNonces[account];
    }

    function _computeAndDistributeProceeds(
        ComputeAndDistributeProceedsArgs memory args,
        MatchedOrder[] memory saleDetailsBatch) private returns (bool[] memory unsuccessfulFills) {

        unsuccessfulFills = new bool[](saleDetailsBatch.length);

        PayoutsAccumulator memory accumulator = PayoutsAccumulator({
            lastSeller: address(0),
            lastMarketplace: address(0),
            lastRoyaltyRecipient: address(0),
            accumulatedSellerProceeds: 0,
            accumulatedMarketplaceProceeds: 0,
            accumulatedRoyaltyProceeds: 0
        });

        for (uint256 i = 0; i < saleDetailsBatch.length;) {
            MatchedOrder memory saleDetails = saleDetailsBatch[i];

            bool successfullyDispensedToken = 
                args.funcDispenseToken(
                    saleDetails.seller, 
                    saleDetails.buyer, 
                    saleDetails.tokenAddress, 
                    saleDetails.tokenId, 
                    saleDetails.amount);

            if (!successfullyDispensedToken) {
                if (address(args.paymentCoin) == address(0)) {
                    revert PaymentProcessor__DispensingTokenWasUnsuccessful();
                }

                unsuccessfulFills[i] = true;
            } else {
                SplitProceeds memory proceeds =
                    _computePaymentSplits(
                        saleDetails.offerPrice,
                        saleDetails.tokenAddress,
                        saleDetails.tokenId,
                        saleDetails.marketplace,
                        saleDetails.marketplaceFeeNumerator,
                        saleDetails.maxRoyaltyFeeNumerator
                    );
    
                if (proceeds.royaltyRecipient != accumulator.lastRoyaltyRecipient) {
                    if(accumulator.accumulatedRoyaltyProceeds > 0) {
                        args.funcPayout(accumulator.lastRoyaltyRecipient, args.purchaser, args.paymentCoin, accumulator.accumulatedRoyaltyProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastRoyaltyRecipient = proceeds.royaltyRecipient;
                    accumulator.accumulatedRoyaltyProceeds = 0;
                }
    
                if (saleDetails.marketplace != accumulator.lastMarketplace) {
                    if(accumulator.accumulatedMarketplaceProceeds > 0) {
                        args.funcPayout(accumulator.lastMarketplace, args.purchaser, args.paymentCoin, accumulator.accumulatedMarketplaceProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastMarketplace = saleDetails.marketplace;
                    accumulator.accumulatedMarketplaceProceeds = 0;
                }
    
                if (saleDetails.seller != accumulator.lastSeller) {
                    if(accumulator.accumulatedSellerProceeds > 0) {
                        args.funcPayout(accumulator.lastSeller, args.purchaser, args.paymentCoin, accumulator.accumulatedSellerProceeds, args.pushPaymentGasLimit);
                    }
    
                    accumulator.lastSeller = saleDetails.seller;
                    accumulator.accumulatedSellerProceeds = 0;
                }

                unchecked {
                    accumulator.accumulatedRoyaltyProceeds += proceeds.royaltyProceeds;
                    accumulator.accumulatedMarketplaceProceeds += proceeds.marketplaceProceeds;
                    accumulator.accumulatedSellerProceeds += proceeds.sellerProceeds;
                }
            }

            unchecked {
                ++i;
            }
        }

        if(accumulator.accumulatedRoyaltyProceeds > 0) {
            args.funcPayout(accumulator.lastRoyaltyRecipient, args.purchaser, args.paymentCoin, accumulator.accumulatedRoyaltyProceeds, args.pushPaymentGasLimit);
        }

        if(accumulator.accumulatedMarketplaceProceeds > 0) {
            args.funcPayout(accumulator.lastMarketplace, args.purchaser, args.paymentCoin, accumulator.accumulatedMarketplaceProceeds, args.pushPaymentGasLimit);
        }

        if(accumulator.accumulatedSellerProceeds > 0) {
            args.funcPayout(accumulator.lastSeller, args.purchaser, args.paymentCoin, accumulator.accumulatedSellerProceeds, args.pushPaymentGasLimit);
        }

        return unsuccessfulFills;
    }

    function _pushProceeds(address to, uint256 proceeds, uint256 pushPaymentGasLimit_) private {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(pushPaymentGasLimit_, to, proceeds, 0, 0, 0, 0)
        }

        if (!success) {
            revert PaymentProcessor__FailedToTransferProceeds();
        }
    }

    function _computePaymentSplits(
        uint256 salePrice,
        address tokenAddress,
        uint256 tokenId,
        address marketplaceFeeRecipient,
        uint256 marketplaceFeeNumerator,
        uint256 maxRoyaltyFeeNumerator) private view returns (SplitProceeds memory proceeds) {

        proceeds.sellerProceeds = salePrice;

        try IERC2981(tokenAddress).royaltyInfo(
            tokenId, 
            salePrice) 
            returns (address royaltyReceiver, uint256 royaltyAmount) {
            if (royaltyReceiver == address(0)) {
                royaltyAmount = 0;
            }

            if (royaltyAmount > 0) {
                if (royaltyAmount > (salePrice * maxRoyaltyFeeNumerator) / FEE_DENOMINATOR) {
                    revert PaymentProcessor__OnchainRoyaltiesExceedMaximumApprovedRoyaltyFee();
                }

                proceeds.royaltyRecipient = royaltyReceiver;
                proceeds.royaltyProceeds = royaltyAmount;

                unchecked {
                    proceeds.sellerProceeds -= royaltyAmount;
                }
            }
        } catch (bytes memory) {}

        proceeds.marketplaceProceeds =
            marketplaceFeeRecipient != address(0) ? (salePrice * marketplaceFeeNumerator) / FEE_DENOMINATOR : 0;
        if (proceeds.marketplaceProceeds > 0) {
            unchecked {
                proceeds.sellerProceeds -= proceeds.marketplaceProceeds;
            }
        }
    }

    function _getTokenSecurityPolicy(address tokenAddress) private view returns (uint256, SecurityPolicy storage) {
        uint256 securityPolicyId = tokenSecurityPolicies[tokenAddress];
        SecurityPolicy storage securityPolicy = securityPolicies[securityPolicyId];
        return (securityPolicyId, securityPolicy);
    }

    function _requireCallerOwnsSecurityPolicy(uint256 securityPolicyId) private view {
        if(_msgSender() != securityPolicies[securityPolicyId].policyOwner) {
            revert PaymentProcessor__CallerDoesNotOwnSecurityPolicy();
        }
    }

    function _getFloorAndCeilingPrices(
        address tokenAddress, 
        uint256 tokenId) private view returns (uint256, uint256) {

        PricingBounds memory tokenLevelPricingBounds = tokenPricingBounds[tokenAddress][tokenId];
        if (tokenLevelPricingBounds.isEnabled) {
            return (tokenLevelPricingBounds.floorPrice, tokenLevelPricingBounds.ceilingPrice);
        } else {
            PricingBounds memory collectionLevelPricingBounds = collectionPricingBounds[tokenAddress];
            if (collectionLevelPricingBounds.isEnabled) {
                return (collectionLevelPricingBounds.floorPrice, collectionLevelPricingBounds.ceilingPrice);
            }
        }

        return (0, type(uint256).max);
    }

    function _verifySalePriceInRange(
        address tokenAddress, 
        uint256 tokenId, 
        uint256 amount, 
        uint256 salePrice) private view {

        uint256 salePricePerUnit = salePrice / amount;

        (uint256 floorPrice, uint256 ceilingPrice) = _getFloorAndCeilingPrices(tokenAddress, tokenId);

        if(salePricePerUnit < floorPrice) {
            revert PaymentProcessor__SalePriceBelowMinimumFloor();
        }

        if(salePricePerUnit > ceilingPrice) {
            revert PaymentProcessor__SalePriceAboveMaximumCeiling();
        }
    }

    function _verifyEIP1271Signature(
        address signer, 
        bytes32 hash, 
        SignatureECDSA memory signatureComponents) private view {
        bool isValidSignatureNow;
        
        try IERC1271(signer).isValidSignature(
            hash, 
            abi.encodePacked(signatureComponents.r, signatureComponents.s, signatureComponents.v)) 
            returns (bytes4 magicValue) {
            isValidSignatureNow = magicValue == IERC1271.isValidSignature.selector;
        } catch {}

        if (!isValidSignatureNow) {
            revert PaymentProcessor__EIP1271SignatureInvalid();
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IOwnable {
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./PaymentProcessorDataTypes.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title IPaymentProcessor
 * @author Limit Break, Inc.
 * @notice Interface definition for payment processor contracts.
 */
interface IPaymentProcessor is IERC165 {

    /// @notice Emitted when a bundle of ERC-721 tokens is successfully purchased using `buyBundledListing`
    event BuyBundledListingERC721(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        bool[] unsuccessfulFills,
        uint256[] tokenIds,
        uint256[] salePrices);

    /// @notice Emitted when a bundle of ERC-1155 tokens is successfully purchased using `buyBundledListing`
    event BuyBundledListingERC1155(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        bool[] unsuccessfulFills,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] salePrices);

    /// @notice Emitted for each token successfully purchased using either `buySingleLising` or `buyBatchOfListings`
    event BuySingleListing(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        address seller,
        uint256 tokenId,
        uint256 amount,
        uint256 salePrice);

    /// @notice Emitted when a security policy is either created or modified
    event CreatedOrUpdatedSecurityPolicy(
        uint256 indexed securityPolicyId, 
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string policyName);

    /// @notice Emitted when an address is added to the exchange whitelist for a security policy
    event ExchangeAddedToWhitelist(uint256 indexed securityPolicyId, address indexed exchange);

    /// @notice Emitted when an address is removed from the exchange whitelist for a security policy
    event ExchangeRemovedFromWhitelist(uint256 indexed securityPolicyId, address indexed exchange);

    /// @notice Emitted when a user revokes all of their existing listings or offers that share the master nonce.
    event MasterNonceInvalidated(uint256 indexed nonce, address indexed account);

    /// @notice Emitted when a user revokes a single listing or offer nonce for a specific marketplace.
    event NonceInvalidated(
        uint256 indexed nonce, 
        address indexed account, 
        address indexed marketplace, 
        bool wasCancellation);

    /// @notice Emitted when a coin is added to the approved coins mapping for a security policy
    event PaymentMethodAddedToWhitelist(uint256 indexed securityPolicyId, address indexed coin);

    /// @notice Emitted when a coin is removed from the approved coins mapping for a security policy
    event PaymentMethodRemovedFromWhitelist(uint256 indexed securityPolicyId, address indexed coin);

    /// @notice Emitted when the ownership of a security policy is transferred to a new account
    event SecurityPolicyOwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice Emitted when a collection of ERC-721 tokens is successfully swept using `sweepCollection`
    event SweepCollectionERC721(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        bool[] unsuccessfulFills,
        address[] sellers,
        uint256[] tokenIds,
        uint256[] salePrices);

    /// @notice Emitted when a collection of ERC-1155 tokens is successfully swept using `sweepCollection`
    event SweepCollectionERC1155(
        address indexed marketplace,
        address indexed tokenAddress,
        address indexed paymentCoin,
        address buyer,
        bool[] unsuccessfulFills,
        address[] sellers,
        uint256[] tokenIds,
        uint256[] amounts,
        uint256[] salePrices);

    /// @notice Emitted whenever the designated security policy id changes for a collection.
    event UpdatedCollectionSecurityPolicy(address indexed tokenAddress, uint256 indexed securityPolicyId);

    /// @notice Emitted whenever the supported ERC-20 payment is set for price-constrained collections.
    event UpdatedCollectionPaymentCoin(address indexed tokenAddress, address indexed paymentCoin);

    /// @notice Emitted whenever pricing bounds change at a collection level for price-constrained collections.
    event UpdatedCollectionLevelPricingBoundaries(
        address indexed tokenAddress, 
        uint256 floorPrice, 
        uint256 ceilingPrice);

    /// @notice Emitted whenever pricing bounds change at a token level for price-constrained collections.
    event UpdatedTokenLevelPricingBoundaries(
        address indexed tokenAddress, 
        uint256 indexed tokenId, 
        uint256 floorPrice, 
        uint256 ceilingPrice);
    
    function createSecurityPolicy(
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external returns (uint256);

    function updateSecurityPolicy(
        uint256 securityPolicyId,
        bool enforceExchangeWhitelist,
        bool enforcePaymentMethodWhitelist,
        bool enforcePricingConstraints,
        bool disablePrivateListings,
        bool disableDelegatedPurchases,
        bool disableEIP1271Signatures,
        bool disableExchangeWhitelistEOABypass,
        uint32 pushPaymentGasLimit,
        string calldata registryName) external;

    function transferSecurityPolicyOwnership(uint256 securityPolicyId, address newOwner) external;
    function renounceSecurityPolicyOwnership(uint256 securityPolicyId) external;
    function setCollectionSecurityPolicy(address tokenAddress, uint256 securityPolicyId) external;
    function setCollectionPaymentCoin(address tokenAddress, address coin) external;
    function setCollectionPricingBounds(address tokenAddress, PricingBounds calldata pricingBounds) external;

    function setTokenPricingBounds(
        address tokenAddress, 
        uint256[] calldata tokenIds, 
        PricingBounds[] calldata pricingBounds) external;

    function whitelistExchange(uint256 securityPolicyId, address account) external;
    function unwhitelistExchange(uint256 securityPolicyId, address account) external;
    function whitelistPaymentMethod(uint256 securityPolicyId, address coin) external;
    function unwhitelistPaymentMethod(uint256 securityPolicyId, address coin) external;
    function revokeMasterNonce() external;
    function revokeSingleNonce(address marketplace, uint256 nonce) external;

    function buySingleListing(
        MatchedOrder memory saleDetails, 
        SignatureECDSA memory signedListing, 
        SignatureECDSA memory signedOffer
    ) external payable;

    function buyBatchOfListings(
        MatchedOrder[] calldata saleDetailsArray,
        SignatureECDSA[] calldata signedListings,
        SignatureECDSA[] calldata signedOffers
    ) external payable;

    function buyBundledListing(
        SignatureECDSA memory signedListing,
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleExtended memory bundleDetails,
        BundledItem[] calldata bundleItems) external payable;

    function sweepCollection(
        SignatureECDSA memory signedOffer,
        MatchedOrderBundleBase memory bundleDetails,
        BundledItem[] calldata bundleItems,
        SignatureECDSA[] calldata signedListings) external payable;

    function getDomainSeparator() external view returns (bytes32);
    function getSecurityPolicy(uint256 securityPolicyId) external view returns (SecurityPolicy memory);
    function isWhitelisted(uint256 securityPolicyId, address account) external view returns (bool);
    function isPaymentMethodApproved(uint256 securityPolicyId, address coin) external view returns (bool);
    function getTokenSecurityPolicyId(address collectionAddress) external view returns (uint256);
    function isCollectionPricingImmutable(address tokenAddress) external view returns (bool);
    function isTokenPricingImmutable(address tokenAddress, uint256 tokenId) external view returns (bool);
    function getFloorPrice(address tokenAddress, uint256 tokenId) external view returns (uint256);
    function getCeilingPrice(address tokenAddress, uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

enum TokenProtocols { ERC721, ERC1155 }

/**
 * @dev The `v`, `r`, and `s` components of an ECDSA signature.  For more information
 *      [refer to this article](https://medium.com/mycrypto/the-magic-of-digital-signatures-on-ethereum-98fe184dc9c7).
 */
struct SignatureECDSA {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

/**
 * @dev This struct is used as input to `buySingleListing` and `buyBatchOfListings` calls after an exchange matches
 * @dev a buyer and seller.
 *
 * @dev **sellerAcceptedOffer**: Denotes that the transaction was initiated by the seller account by accepting an offer.
 * @dev When true, ETH/native payments are not accepted, and only ERC-20 payment methods can be used.
 * @dev **collectionLevelOffer**: Denotes that the offer that was accepted was at the collection level.  When `true`,
 * @dev the Buyer should be prompted to sign the the collection offer approval stucture.  When false, the Buyer should
 * @dev prompted to sign the offer approval structure.
 * @dev **protocol**: 0 for ERC-721 or 1 for ERC-1155.  See `TokenProtocols`.
 * @dev **paymentCoin**: `address(0)` denotes native currency sale.  Otherwise ERC-20 payment coin address.
 * @dev **tokenAddress**: The smart contract address of the ERC-721 or ERC-1155 token being sold.
 * @dev **seller**: The seller/current owner of the token.
 * @dev **privateBuyer**: `address(0)` denotes a listing available to any buyer.  Otherwise, this denotes the privately
 * @dev designated buyer.
 * @dev **buyer**: The buyer/new owner of the token.
 * @dev **delegatedPurchaser**: Allows a buyer to delegate an address to buy a token on their behalf.  This would allow
 * @dev a warm burner wallet to purchase tokens and allow them to be received in a cold wallet, for example.
 * @dev **marketplace**: The address designated to receive marketplace fees, if applicable.
 * @dev **marketplaceFeeNumerator**: Marketplace fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev **maxRoyaltyFeeNumerator**: Maximum approved royalty fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev Marketplaces are responsible to query EIP-2981 royalty info from the NFT contract when presenting this
 * @dev for signature.
 * @dev **listingNonce**: The nonce the seller signed in the listing.
 * @dev **offerNonce**: The nonce the buyer signed in the offer.
 * @dev **listingMinPrice**: The minimum price the seller signed off on, in wei.  Buyer can buy above, 
 * @dev but not below the seller-approved minimum price.
 * @dev **offerPrice**: The sale price of the matched order, in wei.  Buyer signs off on the final offer price.
 * @dev **listingExpiration**: The timestamp at which the listing expires.
 * @dev **offerExpiration**: The timestamp at which the offer expires.
 * @dev **tokenId**: The id of the token being sold.  For ERC-721 tokens, this is the specific NFT token id.  
 * @dev For ERC-1155 tokens, this denotes the token type id.
 * @dev **amount**: The number of tokens being sold.  For ERC-721 tokens, this must always be `1`.
 * @dev For ERC-1155 tokens where balances are transferred, this must be greater than or equal to `1`.
 */
struct MatchedOrder {
    bool sellerAcceptedOffer;
    bool collectionLevelOffer;
    TokenProtocols protocol;
    address paymentCoin;
    address tokenAddress;
    address seller;
    address privateBuyer;
    address buyer;
    address delegatedPurchaser;
    address marketplace;
    uint256 marketplaceFeeNumerator;
    uint256 maxRoyaltyFeeNumerator;
    uint256 listingNonce;
    uint256 offerNonce;
    uint256 listingMinPrice;
    uint256 offerPrice;
    uint256 listingExpiration;
    uint256 offerExpiration;
    uint256 tokenId;
    uint256 amount;
}

/**
 * @dev This struct is used as input to `buyBundledListing` calls after an exchange matches a buyer and seller.
 * @dev Wraps `MatchedOrderBundleBase` and adds seller, listing nonce and listing expiration.
 *
 * @dev **bundleBase**: Includes all fields from `MatchedOrderBundleBase`.
 * @dev **seller**: The seller/current owner of all the tokens in a bundled listing.
 * @dev **listingNonce**: The nonce the seller signed in the listing. Only one nonce is required approving the sale
 * @dev of multiple tokens from one collection.
 * @dev **listingExpiration**: The timestamp at which the listing expires.
 */
struct MatchedOrderBundleExtended {
    MatchedOrderBundleBase bundleBase; 
    address seller;
    uint256 listingNonce;
    uint256 listingExpiration;
}

/**
 * @dev This struct is used as input to `sweepCollection` calls after an exchange matches multiple individual listings
 * @dev with a single buyer.
 *
 * @dev **protocol**: 0 for ERC-721 or 1 for ERC-1155.  See `TokenProtocols`.
 * @dev **paymentCoin**: `address(0)` denotes native currency sale.  Otherwise ERC-20 payment coin address.
 * @dev **tokenAddress**: The smart contract address of the ERC-721 or ERC-1155 token being sold.
 * @dev **privateBuyer**: `address(0)` denotes a listing available to any buyer.  Otherwise, this denotes the privately
 * @dev designated buyer.
 * @dev **buyer**: The buyer/new owner of the token.
 * @dev **delegatedPurchaser**: Allows a buyer to delegate an address to buy a token on their behalf.  This would allow
 * @dev a warm burner wallet to purchase tokens and allow them to be received in a cold wallet, for example.
 * @dev **marketplace**: The address designated to receive marketplace fees, if applicable.
 * @dev **marketplaceFeeNumerator**: Marketplace fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev **offerNonce**: The nonce the buyer signed in the offer.  Only one nonce is required approving the purchase
 * @dev of multiple tokens from one collection.
 * @dev **offerPrice**: The sale price of the entire order, in wei.  Buyer signs off on the final offer price.
 * @dev **offerExpiration**: The timestamp at which the offer expires.
 */
struct MatchedOrderBundleBase {
    TokenProtocols protocol;
    address paymentCoin;
    address tokenAddress;
    address privateBuyer;
    address buyer;
    address delegatedPurchaser;
    address marketplace;
    uint256 marketplaceFeeNumerator;
    uint256 offerNonce;
    uint256 offerPrice;
    uint256 offerExpiration;
}

/**
 * @dev This struct is used as input to `sweepCollection` and `buyBundledListing` calls.
 * @dev These fields are required per individual item listed.
 *
 * @dev **tokenId**: The id of the token being sold.  For ERC-721 tokens, this is the specific NFT token id.  
 * @dev For ERC-1155 tokens, this denotes the token type id.
 * @dev **amount**: The number of tokens being sold.  For ERC-721 tokens, this must always be `1`.
 * @dev For ERC-1155 tokens where balances are transferred, this must be greater than or equal to `1`.
 * @dev **maxRoyaltyFeeNumerator**: Maximum approved royalty fee percentage.  Denominator is 10,000.
 * @dev 0.5% fee numerator is 50, 1% fee numerator is 100, 10% fee numerator is 1,000 and so on.
 * @dev Marketplaces are responsible to query EIP-2981 royalty info from the NFT contract when presenting this
 * @dev for signature.
 * @dev **itemPrice**: The exact price the seller signed off on for an individual item, in wei. 
 * @dev Purchase price for the item must be exactly the listing item price.
 * @dev **listingNonce**: The nonce the seller signed in the listing for an individual item.  This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 * @dev **listingExpiration**: The timestamp at which an individual listing expires. This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 * @dev **seller**: The seller/current owner of the token. This should be set
 * @dev for collection sweep transactions, but it should be zero for bundled listings, as the listing nonce is global
 * @dev in that case.
 */
struct BundledItem {
    uint256 tokenId;
    uint256 amount;
    uint256 maxRoyaltyFeeNumerator;
    uint256 itemPrice;
    uint256 listingNonce;
    uint256 listingExpiration;
    address seller;
}

/**
 * @dev This struct is used to define the marketplace behavior and constraints, giving creators flexibility to define
 *      marketplace behavior(s).
 *
 * @dev **enforceExchangeWhitelist**: Requires `buy` calls from smart contracts to be whitelisted.
 * @dev **enforcePaymentMethodWhitelist**: Requires ERC-20 payment coins for `buy` calls to be whitelisted as an 
 * @dev approved payment method.
 * @dev **enforcePricingConstraints**: Allows the creator to specify exactly one approved payment method, a minimum
 * @dev floor price and a maximum ceiling price.  When true, this value supercedes `enforcePaymentMethodWhitelist`.
 * @dev **disablePrivateListings**: Disables private sales.
 * @dev **disableDelegatedPurchases**: Disables purchases by delegated accounts on behalf of buyers.
 * @dev **disableEIP1271Signatures**: Disables sales and purchases using multi-sig wallets that implement EIP-1271.
 * @dev Enforces that buyers and sellers are EOAs.
 * @dev **disableExchangeWhitelistEOABypass**: Has no effect when `enforceExchangeWhitelist` is false.
 * @dev When exchange whitelist is enforced, this disables calls from EOAs, effectively requiring purchases to be
 * @dev composed by whitelisted 3rd party exchange contracts.
 * @dev **pushPaymentGasLimit**: This is the amount of gas to forward when pushing native payments.
 * @dev At the time this contract was written, 2300 gas is the recommended amount, but should costs of EVM opcodes
 * @dev change in the future, this field can be used to increase or decrease the amount of forwarded gas.  Care should
 * @dev be taken to ensure not enough gas is forwarded to result in possible re-entrancy.
 * @dev **policyOwner**: The account that has access to modify a security policy or update the exchange whitelist
 * @dev or approved payment list for the security policy.
 */
struct SecurityPolicy {
    bool enforceExchangeWhitelist;
    bool enforcePaymentMethodWhitelist;
    bool enforcePricingConstraints;
    bool disablePrivateListings;
    bool disableDelegatedPurchases;
    bool disableEIP1271Signatures;
    bool disableExchangeWhitelistEOABypass;
    uint32 pushPaymentGasLimit;
    address policyOwner;
}

/**
 * @dev This struct is used to define pricing constraints for a collection or individual token.
 *
 * @dev **isEnabled**: When true, this indicates that pricing constraints are set for the collection or token.
 * @dev **isImmutable**: When true, this indicates that pricing constraints are immutable and cannot be changed.
 * @dev **floorPrice**: The minimum price for a token or collection.  This is only enforced when 
 * @dev `enforcePricingConstraints` is `true`.
 * @dev **ceilingPrice**: The maximum price for a token or collection.  This is only enforced when
 * @dev `enforcePricingConstraints` is `true`.
 */
struct PricingBounds {
    bool isEnabled;
    bool isImmutable;
    uint256 floorPrice;
    uint256 ceilingPrice;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct SplitProceeds {
    address royaltyRecipient;
    uint256 royaltyProceeds;
    uint256 marketplaceProceeds;
    uint256 sellerProceeds;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct Accumulator {
    uint256[] tokenIds;
    uint256[] amounts;
    uint256[] salePrices;
    uint256[] maxRoyaltyFeeNumerators;
    address[] sellers;
    uint256 sumListingPrices;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct AccumulatorHashes {
    bytes32 tokenIdsKeccakHash;
    bytes32 amountsKeccakHash;
    bytes32 maxRoyaltyFeeNumeratorsKeccakHash;
    bytes32 itemPricesKeccakHash;
}

/** 
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct PayoutsAccumulator {
    address lastSeller;
    address lastMarketplace;
    address lastRoyaltyRecipient;
    uint256 accumulatedSellerProceeds;
    uint256 accumulatedMarketplaceProceeds;
    uint256 accumulatedRoyaltyProceeds;
}

/**
 * @dev Internal contract use only - this is not a public-facing struct
 */
struct ComputeAndDistributeProceedsArgs {
    uint256 pushPaymentGasLimit;
    address purchaser;
    IERC20 paymentCoin;
    function(address,address,IERC20,uint256,uint256) funcPayout;
    function(address,address,address,uint256,uint256) returns (bool) funcDispenseToken;
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