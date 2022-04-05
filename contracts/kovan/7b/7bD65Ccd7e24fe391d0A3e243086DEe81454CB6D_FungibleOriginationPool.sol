//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./interface/IFungibleOriginationPool.sol";

contract FungibleOriginationPool is
    IFungibleOriginationPool,
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using SafeERC20 for IERC20Metadata;

    //--------------------------------------------------------------------------
    // Constants
    //--------------------------------------------------------------------------

    uint256 constant TIME_PRECISION = 1e10;
    uint256 constant MAX_SALE_DURATION = 4 weeks;

    //--------------------------------------------------------------------------
    // State variables
    //--------------------------------------------------------------------------

    // the token being offered for sale
    IERC20Metadata public offerToken;
    // the token used to purchase the offered token
    IERC20Metadata public purchaseToken;
    // the amount of offer token decimals
    uint256 private offerTokenDecimals;
    // the amount of purchase token decimals
    uint256 private purchaseTokenDecimals;

    // Token sale params
    // the sale starting price (in purchase token amount)
    uint256 public startingPrice;
    // the sale ending price (in purchase token amount)
    uint256 public endingPrice;
    // the sale duration (in seconds)
    uint256 public saleDuration;
    // the total amount of offer tokens for sale
    uint256 public totalOfferingAmount;
    // need to raise this amount of purchase tokens for sale completion
    uint256 public reserveAmount;
    // the vesting period (can be 0)
    uint256 public vestingPeriod;
    // the vesting cliff period (must be <= vesting period)
    uint256 public cliffPeriod;
    // the whitelist data
    Whitelist public whitelist;

    // the fee owed to the origination core when purchasing tokens (ex: 1e16 = 1% fee)
    uint256 public originationFee;
    // the origination core contract
    IOriginationCore private originationCore;

    // address with manager capabilities
    address public manager;

    // true if sale has started, false otherwise
    bool public saleInitiated;
    // the timestamp of the beginning of the sale
    uint256 public saleInitiatedTimestamp;
    // the timestamp of the end of the sale
    uint256 public saleEndTimestamp;

    // the amount of offer tokens vested
    uint256 public amountVested;
    // id to keep track of vesting positions
    uint256 public vestingID;

    // Sale trackers
    // vesting entry id to vesting entry data
    mapping(uint256 => VestingEntry) public vestingEntries;
    // purchaser address to vesting entry data
    mapping(address => uint256[]) public userVestingEntries;
    // purchaser address to amount purchased
    mapping(address => uint256) public offerTokenAmountPurchased;
    // purchaser address to amount contributed
    mapping(address => uint256) public purchaseTokenContribution;
    // the total amount of offer tokens sold
    uint256 public offerTokenAmountSold;
    // the total amount of purchase tokens acquired
    uint256 public purchaseTokensAcquired;
    // the total amount of origination fees
    uint256 public originationCoreFees;
    // true if the sponsor has claimed purchase tokens / remaining offer tokens at conclusion of sale, false otherwise
    bool public sponsorTokensClaimed;

    //--------------------------------------------------------------------------
    // Events
    //--------------------------------------------------------------------------

    event InitiateSale(uint256 saleInitiatedTimestamp);
    event PurchaseTokenClaim(address owner, uint256 amountClaimed);
    event Purchase(address purchaser, uint256 contributionAmount, uint256 offerAmount, uint256 purchaseFee);
    event CreateVestingEntry(address purchaser, uint256 vestingId, uint256 saleEndTimestamp, uint256 offerTokenAmount);
    event ClaimVested(address purchaser, uint256 offerTokenAmountClaimed);

    //--------------------------------------------------------------------------
    // Modifiers
    //--------------------------------------------------------------------------

    modifier onlyOwnerOrManager() {
        require(isOwnerOrManager(msg.sender), "Not owner or manager");
        _;
    }

    //--------------------------------------------------------------------------
    // Constructor / Initializer
    //--------------------------------------------------------------------------

    // Initialize the implementation
    constructor() initializer {}

    /**
     * @dev Initializes the origination pool contract
     *
     * @param _originationFee The fee owed to the origination core when purchasing tokens. E.g. 1e16 = 1% fee
     * @param _originationCore The origination core contract
     * @param _admin The admin/owner of the pool
     * @param _saleParams The sale params
     */
    function initialize(
        uint256 _originationFee,
        IOriginationCore _originationCore,
        address _admin,
        SaleParams calldata _saleParams
    ) external override initializer {
        __Ownable_init();
        __ReentrancyGuard_init_unchained();

        offerToken = IERC20Metadata(_saleParams.offerToken);
        purchaseToken = IERC20Metadata(_saleParams.purchaseToken);
        offerTokenDecimals = 10**offerToken.decimals();
        purchaseTokenDecimals = _saleParams.purchaseToken == address(0) ? 10**18 : 10**purchaseToken.decimals(); // check if token is ETH

        startingPrice = _saleParams.startingPrice;
        endingPrice = _saleParams.endingPrice;

        require(_saleParams.saleDuration <= MAX_SALE_DURATION, "Invalid sale duration");
        saleDuration = _saleParams.saleDuration;

        totalOfferingAmount = _saleParams.totalOfferingAmount;
        reserveAmount = _saleParams.reserveAmount;
        vestingPeriod = _saleParams.vestingPeriod;
        cliffPeriod = _saleParams.cliffPeriod;
        originationFee = _originationFee;
        originationCore = _originationCore;

        _transferOwnership(_admin);
    }

    //--------------------------------------------------------------------------
    // Investor Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Purchases the offer token with a contribution amount of purchase tokens
     * @dev If purchasing with ETH, contribution amount must equal ETH sent
     *
     * @param _merkleProof The merkle proof associated with msg.sender to prove whitelisted
     * @param _contributionAmount The contribution amount in purchase tokens
     */
    function whitelistPurchase(bytes32[] calldata _merkleProof, uint256 _contributionAmount) external payable {
        require(whitelist.enabled, "Whitelist not enabled");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof, whitelist.whitelistMerkleRoot, leaf), "Address not whitelisted");

        _purchase(_contributionAmount);
    }

    /**
     * @dev Purchases the offer token with a contribution amount of purchase tokens
     * @dev If purchasing with ETH, contribution amount must equal ETH sent
     *
     * @param _contributionAmount The contribution amount in purchase tokens
     */
    function purchase(uint256 _contributionAmount) external payable {
        require(!whitelist.enabled, "Whitelist enabled");

        _purchase(_contributionAmount);
    }

    function _purchase(uint256 _contributionAmount) internal nonReentrant {
        require(saleInitiated, "Sale not open");
        require(block.timestamp <= saleEndTimestamp, "Sale ended");
        require(_contributionAmount > 0, "Must contribute");

        address sender = msg.sender;
        if (address(purchaseToken) == address(0)) {
            // eth = purchase token
            require(msg.value == _contributionAmount);
        } else {
            purchaseToken.safeTransferFrom(sender, address(this), _contributionAmount);
        }

        (uint256 offerTokenAmount, uint256 feeInPurchaseToken) = calculateOfferTokenAmountAndPurchaseTokenFee(
            _contributionAmount
        );

        // Update the sale trackers
        offerTokenAmountPurchased[sender] += offerTokenAmount;
        purchaseTokenContribution[sender] += _contributionAmount;
        offerTokenAmountSold += offerTokenAmount;
        purchaseTokensAcquired += _contributionAmount;
        originationCoreFees += feeInPurchaseToken;

        // Make sure offer token amount sold is not greater than the sale offering
        require(offerTokenAmountSold <= totalOfferingAmount, "Sale amount greater than offering");

        // If sale is whitelisted, check to ensure purchase cap is not exceeded
        require(
            !whitelist.enabled || offerTokenAmountPurchased[sender] <= whitelist.purchaseCap,
            "Must not exceed purchase cap"
        );

        if (vestingPeriod > 0) {
            _createVestingEntry(sender, offerTokenAmount);
        }

        emit Purchase(sender, _contributionAmount, offerTokenAmount, feeInPurchaseToken);
    }

    /**
     * @dev Creates a vesting entry for purchaser
     *
     * @param _sender The purchaser
     * @param _offerTokenAmount The offer token amount
     */
    // TODO: because all vesting entries initiate vesting at end of sale, one address
    // should only have one vesting entry per pool
    // we need to change vesting entry into a transferable NFT
    // mint NFT on first purchase. NFT has `totalPurchaseAmount` and `totalClaimedAmount`
    function _createVestingEntry(address _sender, uint256 _offerTokenAmount) private {
        VestingEntry storage vestingEntry = vestingEntries[vestingID];
        vestingEntry.user = _sender;
        vestingEntry.offerTokenAmount = _offerTokenAmount;

        userVestingEntries[_sender].push(vestingID);

        emit CreateVestingEntry(_sender, vestingID, saleEndTimestamp, _offerTokenAmount);

        vestingID++;
        amountVested += _offerTokenAmount;
    }

    /**
     * @dev Claims vesting entries
     * @dev If sale did not reach reserve amount vesting entries are canceled
     *
     * @param _vestingEntries The vesting entries ids
     */
    // see note on _createVestingEntry. the new interface for this func is
    // claimVested(uint256[] calldata _nftIds)
    // though most addresses will only hold one, unless they trade for another
    function claimVested(uint256[] calldata _vestingEntries) external nonReentrant {
        require(block.timestamp > saleEndTimestamp, "Sale has not ended");
        require(saleEndTimestamp + cliffPeriod < block.timestamp, "Not past cliff period");

        if (purchaseTokensAcquired >= reserveAmount) {
            for (uint256 i = 0; i < _vestingEntries.length; i++) {
                VestingEntry storage entry = vestingEntries[_vestingEntries[i]];
                require(entry.user == msg.sender, "User not owner of vest id");

                uint256 offerTokenPayout = calculateClaimableVestedOfferToken(entry);
                entry.offerTokenAmountClaimed += offerTokenPayout;

                offerToken.safeTransfer(msg.sender, offerTokenPayout);
                amountVested -= offerTokenPayout;

                emit ClaimVested(msg.sender, offerTokenPayout);
            }
        }
    }

    /**
     * @dev User callable function that will either return purchase tokens or the acquired offer tokens
     * @dev Can only be called at the conclusion of the sale
     */
    function claimTokens() external nonReentrant {
        require(block.timestamp > saleEndTimestamp, "Sale has not ended");

        uint256 tokenAmount;
        if (purchaseTokensAcquired >= reserveAmount) {
            // Sale reached the reserve amount therefore send acquired offer tokens
            require(offerTokenAmountPurchased[msg.sender] > 0, "No purchase made");
            tokenAmount = offerTokenAmountPurchased[msg.sender];
            offerTokenAmountPurchased[msg.sender] = 0;
            offerToken.safeTransfer(msg.sender, tokenAmount);
        } else {
            // Sale did not reach reserve amount therefore return purchase tokens
            require(purchaseTokenContribution[msg.sender] > 0, "No contribution made");
            tokenAmount = purchaseTokenContribution[msg.sender];
            purchaseTokenContribution[msg.sender] = 0;
            _returnPurchaseTokens(msg.sender, tokenAmount);
        }
    }

    function _returnPurchaseTokens(address purchaser, uint256 tokenAmount) internal {
        if (address(purchaseToken) == address(0)) {
            // send eth
            (bool success, ) = payable(purchaser).call{ value: tokenAmount }("");
            require(success);
        } else {
            purchaseToken.safeTransfer(purchaser, tokenAmount);
        }
    }

    //--------------------------------------------------------------------------
    // View Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Calculates the offer token amount and the fee to paid from a contribution amount of purchase tokens
     *
     * @param _contributionAmount The contribution amount of purchase tokens
     * @return offerTokenAmount The offer token amount
     * @return feeInPurchaseToken The fee in purchase tokens
     */
    function calculateOfferTokenAmountAndPurchaseTokenFee(uint256 _contributionAmount)
        public
        view
        returns (uint256 offerTokenAmount, uint256 feeInPurchaseToken)
    {
        require(block.timestamp <= saleEndTimestamp, "Sale ended");

        uint256 timeElapsed = block.timestamp - saleInitiatedTimestamp;
        uint256 saleRange = startingPrice < endingPrice ? endingPrice - startingPrice : startingPrice - endingPrice;
        uint256 saleCompletionRatio = (saleDuration * TIME_PRECISION) / timeElapsed;
        uint256 saleDelta = (saleRange * TIME_PRECISION) / saleCompletionRatio;
        // Determine the offer token price in purchase tokens
        uint256 offerTokenPriceInPurchaseTokens = startingPrice < endingPrice
            ? startingPrice + saleDelta
            : startingPrice - saleDelta;

        // following line has 2 operations:
        //    1. Convert contribution amount to Offer Tokens (contribution / price)
        //    2. Convert previous operation from purchase token decimals to offer token decimals
        offerTokenAmount = _divUp(
            _divUp(_contributionAmount * purchaseTokenDecimals, offerTokenPriceInPurchaseTokens) * offerTokenDecimals,
            purchaseTokenDecimals
        );

        feeInPurchaseToken = _divUp(_contributionAmount * originationFee, 1e18);
    }

    /**
     * @dev Calculates the claimable vested offer token
     *
     * @param _entry The vesting entry
     * @return vestableOfferToken The claimable offer token amount
     */
    function calculateClaimableVestedOfferToken(VestingEntry memory _entry)
        public
        view
        returns (uint256 vestableOfferToken)
    {
        uint256 timeSinceInit = block.timestamp - saleEndTimestamp;

        vestableOfferToken = timeSinceInit >= vestingPeriod
            ? _entry.offerTokenAmount - _entry.offerTokenAmountClaimed
            : ((timeSinceInit * _entry.offerTokenAmount) / vestingPeriod) - _entry.offerTokenAmountClaimed;
    }

    /**
     * @dev Checks to see if address is an admin (owner or manager)
     *
     * @param _address The address of verify
     * @return True if owner of manager, false otherwise
     */
    function isOwnerOrManager(address _address) public view returns (bool) {
        return _address == owner() || _address == manager;
    }

    //--------------------------------------------------------------------------
    // Admin Functions
    //--------------------------------------------------------------------------

    /**
     * @dev Admin function used to initiate the sale
     * @dev Function will transfer the total offer tokens from admin to contract
     */
    function initiateSale() external onlyOwnerOrManager {
        require(!saleInitiated, "Sale already initiated");

        offerToken.safeTransferFrom(msg.sender, address(this), totalOfferingAmount);
        saleInitiated = true;
        saleInitiatedTimestamp = block.timestamp;
        saleEndTimestamp = saleInitiatedTimestamp + saleDuration;

        emit InitiateSale(saleInitiatedTimestamp);
    }

    /**
     * @dev Admin function to claim the purchase tokens from the sale
     * @dev Can only claim at the conclusion of the sale
     * @dev Returns unsold offer tokens or all offer tokens if reserve amount was not met
     */
    function claimPurchaseToken() external onlyOwnerOrManager {
        require(block.timestamp > saleEndTimestamp, "Sale has not ended");
        require(!sponsorTokensClaimed, "Tokens already claimed");
        sponsorTokensClaimed = true;

        // check if reserve amount was reached
        if (purchaseTokensAcquired >= reserveAmount) {
            uint256 claimAmount;
            if (address(purchaseToken) == address(0)) {
                // purchaseToken = eth
                claimAmount = address(this).balance - originationCoreFees;
                (bool success, ) = owner().call{ value: claimAmount }("");
                require(success);
                // send fees to core
                originationCore.receiveFees{ value: originationCoreFees }();
                require(success);
            } else {
                claimAmount = purchaseToken.balanceOf(address(this)) - originationCoreFees;
                purchaseToken.safeTransfer(owner(), claimAmount);
                purchaseToken.safeTransfer(address(originationCore), originationCoreFees);
            }

            // return the unsold offerTokens
            if (offerTokenAmountSold < totalOfferingAmount) {
                offerToken.safeTransfer(owner(), totalOfferingAmount - offerTokenAmountSold);
            }

            emit PurchaseTokenClaim(owner(), claimAmount);
        } else {
            // return all offer tokens back to owner
            offerToken.safeTransfer(owner(), offerToken.balanceOf(address(this)));
        }
    }

    /**
     * @dev Admin function to set a whitelist
     *
     * @param _whitelist The whitelist
     */
    function setWhitelist(Whitelist calldata _whitelist) external onlyOwnerOrManager {
        require(!saleInitiated, "Cannot set whitelist after sale initiated");

        whitelist = _whitelist;
    }

    /**
     * @dev Admin function to set a manager (fellow admin)
     *
     * @param _manager The manager address
     */
    function setManager(address _manager) external onlyOwner {
        manager = _manager;
    }

    //--------------------------------------------------------------------------
    // Utils Functions
    //--------------------------------------------------------------------------

    function _divUp(uint256 n, uint256 d) internal pure returns (uint256) {
        return (n + d - 1) / d;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
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
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

import "./IOriginationCore.sol";

interface IFungibleOriginationPool {
    struct Whitelist {
        bool enabled; // if disabled, the merkle root and purchase cap values are ignored
        bytes32 whitelistMerkleRoot; // the merkle root used to determine if an address is whitelisted
        uint256 purchaseCap; // the max amount of tokens an address can purchase
    }

    struct SaleParams {
        address offerToken; // the token being offered for sale
        address purchaseToken; // the token used to purchase the offered token
        uint256 startingPrice; // in purchase tokens
        uint256 endingPrice; // in purchase tokens
        uint256 saleDuration; // the sale duration
        uint256 totalOfferingAmount; // the total amount of offer tokens for sale
        uint256 reserveAmount; // need to raise this amount of purchase tokens for sale completion
        uint256 vestingPeriod; // the total vesting period (can be 0)
        uint256 cliffPeriod; // the cliff period in case of vesting (must be <= vesting period)
    }

    struct VestingEntry {
        address user; // the user's address with the vesting position
        uint256 offerTokenAmount; // the total vesting position amount
        uint256 offerTokenAmountClaimed; // the amount of tokens claimed so far
    }

    function initialize(
        uint256 originationFee,
        IOriginationCore core,
        address admin,
        SaleParams calldata saleParams
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.4;

interface IOriginationCore {
    function receiveFees() external payable;
}