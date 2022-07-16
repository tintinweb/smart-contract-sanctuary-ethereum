// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./libraries/OrderTypes.sol";
import "./libraries/SignatureChecker.sol";

import "./interfaces/IExecutionStrategy.sol";
import "./interfaces/ICurrencyManager.sol";
import "./interfaces/IExecutionManager.sol";
import "./interfaces/IRoyaltyFeeManager.sol";

import "../Harfang.sol";

contract HarfangExchange is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    using OrderTypes for OrderTypes.MakerOrder;
    using OrderTypes for OrderTypes.TakerOrder;

    bytes32 public immutable DOMAIN_SEPARATOR;

    address public protocolFeeRecipient;
    ICurrencyManager public currencyManager;
    IExecutionManager public executionManager;
    IRoyaltyFeeManager public royaltyFeeManager;
    address public harfang;

    mapping(address => uint256) public userMinOrderNonce;
    mapping(address => mapping(uint256 => bool)) private _isUserOrderNonceExecutedOrCancelled;

    event CancelAllOrders(address indexed user, uint256 newMinNonce);
    event CancelMultipleOrders(address indexed user, uint256[] orderNonces);
    event NewCurrencyManager(address indexed currencyManager);
    event NewExecutionManager(address indexed executionManager);
    event NewProtocolFeeRecipient(address indexed protocolFeeRecipient);
    event NewRoyaltyFeeManager(address indexed royaltyFeeManager);
    event NewTransferSelectorNFT(address indexed transferSelectorNFT);
    event RoyaltyPayment(
        uint256 indexed tokenId,
        uint256 indexed sid,
        address indexed royaltyRecipient,
        address currency,
        uint256 amount
    );
    event TakerAsk(
        bytes32 orderHash, // bid hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker ask order
        address indexed maker, // maker address of the initial bid order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        uint256 id, // tokenId transferred
        uint256 sid, // amount of tokens transferred
        uint256 price // final transacted price
    );
    event TakerBid(
        bytes32 orderHash, // ask hash of the maker order
        uint256 orderNonce, // user order nonce
        address indexed taker, // sender address for the taker bid order
        address indexed maker, // maker address of the initial ask order
        address indexed strategy, // strategy that defines the execution
        address currency, // currency address
        uint256 id, // tokenId transferred
        uint256 sid, // amount of tokens transferred
        uint256 price // final transacted price
    );

    struct EIP712Domain {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
    }

    constructor(
        address _currencyManager,
        address _executionManager,
        address _royaltyFeeManager,
        address _protocolFeeRecipient,
        address _harfang
    ) {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Harfang"),
                keccak256("alpha"),
                block.chainid,
                address(this)
            )
        );

        currencyManager = ICurrencyManager(_currencyManager);
        executionManager = IExecutionManager(_executionManager);
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        protocolFeeRecipient = _protocolFeeRecipient;
        harfang = _harfang;
    }

    function cancelAllOrdersForSender(uint256 minNonce) external {
        require(minNonce > userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
        require(minNonce < userMinOrderNonce[msg.sender] + 500000, "Cancel: Cannot cancel more orders");
        userMinOrderNonce[msg.sender] = minNonce;

        emit CancelAllOrders(msg.sender, minNonce);
    }

    function cancelMultipleMakerOrders(uint256[] calldata orderNonces) external {
        require(orderNonces.length > 0, "Cancel: Cannot be empty");

        for (uint256 i = 0; i < orderNonces.length; i++) {
            require(orderNonces[i] >= userMinOrderNonce[msg.sender], "Cancel: Order nonce lower than current");
            _isUserOrderNonceExecutedOrCancelled[msg.sender][orderNonces[i]] = true;
        }

        emit CancelMultipleOrders(msg.sender, orderNonces);
    }

    function matchAskWithTakerBid(OrderTypes.TakerOrder memory takerBid, OrderTypes.MakerOrder memory makerAsk)
        external
        nonReentrant
    {
        require((makerAsk.isOrderAsk) && (!takerBid.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerBid.taker, "Order: Taker must be the sender");

        bytes32 askHash = makerAsk.hash();
        _validateOrder(makerAsk, askHash);

        (bool isExecutionValid, uint256 id, uint256 sid) = IExecutionStrategy(makerAsk.strategy)
            .canExecuteTakerBid(takerBid, makerAsk);

        require(isExecutionValid, "Strategy: Execution invalid");

        _isUserOrderNonceExecutedOrCancelled[makerAsk.signer][makerAsk.nonce] = true;

        _transferFeesAndFunds(
            makerAsk.strategy,
            id,
            sid,
            makerAsk.currency,
            msg.sender,
            makerAsk.signer,
            takerBid.price,
            makerAsk.minPercentageToAsk
        );

        _transferNonFungibleToken(makerAsk.signer, msg.sender, takerBid.id, takerBid.sid, makerAsk.strategy);

        emit TakerBid(
            askHash,
            makerAsk.nonce,
            takerBid.taker,
            makerAsk.signer,
            makerAsk.strategy,
            makerAsk.currency,
            makerAsk.id,
            makerAsk.sid,
            takerBid.price
        );
    }

    function matchBidWithTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        nonReentrant
    {
        require((!makerBid.isOrderAsk) && (takerAsk.isOrderAsk), "Order: Wrong sides");
        require(msg.sender == takerAsk.taker, "Order: Taker must be the sender");

        bytes32 bidHash = makerBid.hash();
        _validateOrder(makerBid, bidHash);

        (bool isExecutionValid, uint256 id, uint256 sid) = IExecutionStrategy(makerBid.strategy)
            .canExecuteTakerAsk(takerAsk, makerBid);

        require(isExecutionValid, "Strategy: Execution invalid");

        _isUserOrderNonceExecutedOrCancelled[makerBid.signer][makerBid.nonce] = true;

        _transferNonFungibleToken(msg.sender, makerBid.signer, id, sid, makerBid.strategy);

        _transferFeesAndFunds(
            makerBid.strategy,
            id,
            sid,
            makerBid.currency,
            makerBid.signer,
            takerAsk.taker,
            takerAsk.price,
            takerAsk.minPercentageToAsk
        );

        emit TakerAsk(
            bidHash,
            makerBid.nonce,
            takerAsk.taker,
            makerBid.signer,
            makerBid.strategy,
            makerBid.currency,
            id,
            sid,
            takerAsk.price
        );
    }


    function updateExecutionManager(address _executionManager) external onlyOwner {
        require(_executionManager != address(0), "Owner: Cannot be null address");
        executionManager = IExecutionManager(_executionManager);
        emit NewExecutionManager(_executionManager);
    }

    function updateProtocolFeeRecipient(address _protocolFeeRecipient) external onlyOwner {
        protocolFeeRecipient = _protocolFeeRecipient;
        emit NewProtocolFeeRecipient(_protocolFeeRecipient);
    }

    function updateRoyaltyFeeManager(address _royaltyFeeManager) external onlyOwner {
        require(_royaltyFeeManager != address(0), "Owner: Cannot be null address");
        royaltyFeeManager = IRoyaltyFeeManager(_royaltyFeeManager);
        emit NewRoyaltyFeeManager(_royaltyFeeManager);
    }

    function isUserOrderNonceExecutedOrCancelled(address user, uint256 orderNonce) external view returns (bool) {
        return _isUserOrderNonceExecutedOrCancelled[user][orderNonce];
    }

    function _transferFeesAndFunds(
        address strategy,
        uint256 tokenId,
        uint256 sid,
        address currency,
        address from,
        address to,
        uint256 price,
        uint256 minPercentageToAsk
    ) internal {
        uint256 finalSellerAmount = price;

        {
            uint256 protocolFeeAmount = _calculateProtocolFee(strategy, price);

            if ((protocolFeeRecipient != address(0)) && (protocolFeeAmount != 0)) {
                IERC20(currency).safeTransferFrom(from, protocolFeeRecipient, protocolFeeAmount);
                finalSellerAmount -= protocolFeeAmount;
            }
        }

        {
            (address royaltyFeeRecipient, uint256 royaltyFeeAmount) = royaltyFeeManager.calculateRoyaltyFeeAndGetRecipient(tokenId, price);

            if ((royaltyFeeRecipient != address(0)) && (royaltyFeeAmount != 0)) {
                IERC20(currency).safeTransferFrom(from, royaltyFeeRecipient, royaltyFeeAmount);
                finalSellerAmount -= royaltyFeeAmount;

                emit RoyaltyPayment(tokenId, sid, royaltyFeeRecipient, currency, royaltyFeeAmount);
            }
        }

        require((finalSellerAmount * 10000) >= (minPercentageToAsk * price), "Fees: Higher than expected");

        {
            IERC20(currency).safeTransferFrom(from, to, finalSellerAmount);
        }
    }

    function _transferNonFungibleToken(
        address from,
        address to,
        uint256 id,
        uint256 sid,
        address strategy
    ) internal {
        if(IExecutionStrategy(strategy).getStrategyType() == 1){
            Harfang(harfang).createSpecificElement(id, to);
        }else{
            Harfang(harfang).transfer(id, sid, from, to);
        }
    }

    function _calculateProtocolFee(address executionStrategy, uint256 amount) internal view returns (uint256) {
        uint256 protocolFee = IExecutionStrategy(executionStrategy).viewProtocolFee();
        return ((protocolFee * amount) / 10000) + (0.5 * 10**18);
    }

    function _validateOrder(OrderTypes.MakerOrder memory makerOrder, bytes32 orderHash) internal view {
        require(
            (!_isUserOrderNonceExecutedOrCancelled[makerOrder.signer][makerOrder.nonce]) &&
                (makerOrder.nonce >= userMinOrderNonce[makerOrder.signer]),
            "Order: Matching order expired"
        );

        require(makerOrder.signer != address(0), "Order: Invalid signer");


        require(
            SignatureChecker.verify(
                orderHash,
                makerOrder.signer,
                makerOrder.v,
                makerOrder.r,
                makerOrder.s,
                DOMAIN_SEPARATOR
            ),
            "Signature: Invalid"
        );

        require(currencyManager.isCurrencyWhitelisted(makerOrder.currency), "Currency: Not whitelisted");

        require(executionManager.isStrategyWhitelisted(makerOrder.strategy), "Strategy: Not whitelisted");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
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
pragma solidity ^0.8.0;

/**
 * @title OrderTypes
 * @notice This library contains order types for the LooksRare exchange.
 */
library OrderTypes {
    bytes32 internal constant MAKER_ORDER_HASH = 0x0c580f839e714c65f79de49a3eb3a85b0d4f8b049970c2e31fb64e38c0b32dfc;

    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        uint256 price; // price (used as )
        uint id;
        uint256 sid; // id of the token
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 id;
        uint256 sid;
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
    }

    function hash(MakerOrder memory makerOrder) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    MAKER_ORDER_HASH,
                    makerOrder.isOrderAsk,
                    makerOrder.signer,
                    makerOrder.price,
                    makerOrder.id,
                    makerOrder.sid,
                    makerOrder.strategy,
                    makerOrder.currency,
                    makerOrder.nonce,
                    makerOrder.startTime,
                    makerOrder.endTime,
                    makerOrder.minPercentageToAsk
                )
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {IERC1271} from "@openzeppelin/contracts/interfaces/IERC1271.sol";

/**
 * @title SignatureChecker
 * @notice This library allows verification of signatures for both EOAs and contracts.
 */
library SignatureChecker {
    /**
     * @notice Recovers the signer of a signature (for EOA)
     * @param hash the hash containing the signed mesage
     * @param v parameter (27 or 28). This prevents maleability since the public key recovery equation has two possible solutions.
     * @param r parameter
     * @param s parameter
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // https://ethereum.stackexchange.com/questions/83174/is-it-best-practice-to-check-signature-malleability-in-ecrecover
        // https://crypto.iacr.org/2019/affevents/wac/medias/Heninger-BiasedNonceSense.pdf
        require(
            uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0,
            "Signature: Invalid s parameter"
        );

        require(v == 27 || v == 28, "Signature: Invalid v parameter");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "Signature: Invalid signer");

        return signer;
    }

    /**
     * @notice Returns whether the signer matches the signed message
     * @param hash the hash containing the signed mesage
     * @param signer the signer address to confirm message validity
     * @param v parameter (27 or 28)
     * @param r parameter
     * @param s parameter
     * @param domainSeparator paramer to prevent signature being executed in other chains and environments
     * @return true --> if valid // false --> if invalid
     */
    function verify(
        bytes32 hash,
        address signer,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 domainSeparator
    ) internal view returns (bool) {
        // \x19\x01 is the standardized encoding prefix
        // https://eips.ethereum.org/EIPS/eip-712#specification
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hash));
        if (Address.isContract(signer)) {
            // 0x1626ba7e is the interfaceId for signature contracts (see IERC1271)
            return IERC1271(signer).isValidSignature(digest, abi.encodePacked(r, s, v)) == 0x1626ba7e;
        } else {
            return recover(digest, v, r, s) == signer;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OrderTypes} from "../libraries/OrderTypes.sol";

interface IExecutionStrategy {
    function canExecuteTakerAsk(OrderTypes.TakerOrder calldata takerAsk, OrderTypes.MakerOrder calldata makerBid)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function canExecuteTakerBid(OrderTypes.TakerOrder calldata takerBid, OrderTypes.MakerOrder calldata makerAsk)
        external
        view
        returns (
            bool,
            uint256,
            uint256
        );

    function viewProtocolFee() external view returns (uint256);
    function getStrategyType() external pure returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ICurrencyManager {
    function addCurrency(address currency) external;

    function removeCurrency(address currency) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);

    function viewWhitelistedCurrencies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedCurrencies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IExecutionManager {
    function addStrategy(address strategy) external;

    function removeStrategy(address strategy) external;

    function isStrategyWhitelisted(address strategy) external view returns (bool);

    function viewWhitelistedStrategies(uint256 cursor, uint256 size) external view returns (address[] memory, uint256);

    function viewCountWhitelistedStrategies() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRoyaltyFeeManager {
    function calculateRoyaltyFeeAndGetRecipient(
        uint256 tokenId,
        uint256 amount
    ) external view returns (address, uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Price.sol";
import "./Utils.sol";

contract Harfang is Ownable {
    using Counters for Counters.Counter;

    // storage
    mapping(uint256 => Utils.GlobalElement) private _elements;
    mapping(string => Utils.Element) private _owners;
    mapping(string => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    Counters.Counter public count;
    Counters.Counter public stampCount;
    address public marketplace;
    address public price;
    address public usdc = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;
    address public dai = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

    constructor(address _price, bytes memory cid){
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        price = _price;
        count.increment();
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            667667667667,
            Utils.ElementType.stamp,
            address(0)
        );
        count.increment();
        emit ElementCreated(cid, 667667667667, Utils.ElementType.stamp, 1, address(0));
    }

    // events

    event Transfer(address indexed _from, address indexed _to, string indexed _idEncoded);
    event Approval(address indexed _owner, address indexed _approved, string indexed _tokenId);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event ElementCreated(bytes cid, uint256 copies, Utils.ElementType indexed t, uint256 indexed id, address indexed owner);
    event SpecificElementCreated(uint256 indexed sid, uint256 indexed id, address indexed owner);
    event Stamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Unstamp(address indexed operator, string stamp, string card, bytes32 indexed stampId, bytes32 indexed cardId);
    event Burn(address indexed operator, uint256 indexed id, uint256 indexed sid, uint256 copies);
    event Withdraw(address indexed operator, uint256 daiAmount, uint256 usdcAmount);
    event NewPrice(address indexed operator, address price);
    event Marketplace(address indexed operator, address price);

    function createElement(bytes calldata cid, uint256 _copies, Utils.ElementType t, Utils.Currency currency) external {
        require(cid[0] == 0x12 && cid[1] == 0x20 && cid.length == 34, "Incorrect cid (v0 only)");
        uint256 priceToPay = Price(price).cardPrice(_copies);
        require(_copies >= 1, "copies cannot be less than 1");
        if(currency == Utils.Currency.dai) {
            require(ERC20(dai).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
        }else{
            require(ERC20(usdc).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
        }
        _elements[count.current()] = Utils.createGlobalElement(
            cid,
            _copies,
            t,
            msg.sender
        );
        count.increment();
        if(currency == Utils.Currency.dai) {
            ERC20(dai).transferFrom(msg.sender, address(this), priceToPay);
        }else{
            ERC20(usdc).transferFrom(msg.sender, address(this), priceToPay);
        }
        emit ElementCreated(cid, _copies, t, count.current()-1, msg.sender);
    }

    function createSpecificElement(uint256 id, address to) public {
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(global.creator == msg.sender || _operatorApprovals[global.creator][msg.sender], "You do not own the element");
        require(global.copies > global.lastId, "limit of copies hitted");
        require(_owners[Utils.encode(id, global.lastId)].owner == address(0), "Element already exists");
        _owners[Utils.encode(id, global.lastId)] = Utils.createLocalElement(to);
        global.lastId = global.lastId+1;
        emit SpecificElementCreated(global.lastId, id, msg.sender);
    }

    function send(uint256 id, uint256 sid, address to, bytes calldata messageURI) external {
        require(messageURI.length == 0 || messageURI[0] == 0x12 && messageURI[1] == 0x20 && messageURI.length == 34, "Not correct cid");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        if (global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is attached to a card");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else if(global.t == Utils.ElementType.card){
            // require(string(messageURI).length == 46, "Message URI is not a valid IPFS hash");
            require(element.twin != 0, "Card is not stamped");
            Utils.Element storage lstamp = _owners[Utils.encode(element.twin, element.twinSid)];
            element.owner = to;
            element.messageCID = messageURI;
            lstamp.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else{
            revert("Element does not have a type");
        }
    }

    function transfer(uint256 id, uint256 sid, address from, address to) external {
        require(msg.sender == marketplace, "Can only be executed by the marketplace contract");
        require(_tokenApprovals[Utils.encode(id, sid)] == marketplace || _operatorApprovals[from][marketplace] == true, "Marketplace is not allowed to transfer this element");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == from, "The sender is not the owner");
        if(global.t == Utils.ElementType.stamp){
            require(element.twin == 0 && element.twinSid == 0, "Stamp is linked");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else if(global.t == Utils.ElementType.card){
            require(element.twin == 0 && element.twinSid == 0, "Card is attached to stamp");
            element.owner = to;
            _tokenApprovals[Utils.encode(id, sid)] = address(0);
            emit Transfer(msg.sender, to, Utils.encode(id, sid));
        }else{ 
            revert("Element does not have a type");
        }
    }   

    function stampHarfang(uint256 cardID, uint256 cardSID) internal {
        Utils.Element storage element = _owners[Utils.encode(cardID, cardSID)];
        require(element.owner != address(0), "This specific element does not exist");
        require(element.owner == msg.sender, "The sender is not the owner");
        require(element.twin == 0 && element.twinSid == 0, "Card is already attached to stamp");
        Utils.GlobalElement storage global = _elements[cardID];
        require(global.copies >= 1, "This global card does not exist");
        require(global.t == Utils.ElementType.card, "Provided card is not a card");
        Utils.Element memory lstamp = Utils.createLocalElement(msg.sender);
        lstamp.used = true;
        string memory key = Utils.encode(1, stampCount.current());
        _owners[key] = lstamp;
        _owners[key].twin = cardID;
        _owners[key].twinSid = cardSID;
        element.twin = 1;
        element.twinSid = stampCount.current();
        stampCount.increment();
        emit Stamp(msg.sender, key, Utils.encode(cardID, cardSID), keccak256(bytes(key)), keccak256(bytes(Utils.encode(cardID, cardSID))));
    }

    function stamp(uint256 cardID, uint256 cardSID, uint256 stampID, uint256 stampSID, Utils.Currency currency) external {
        require(_elements[cardID].t == Utils.ElementType.card, "Incorrect type");
        if(stampID == 1){
            uint256 priceToPay = Price(price).stampPrice();
            stampHarfang(cardID, cardSID);
            if(currency == Utils.Currency.dai) {
                require(ERC20(dai).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
                ERC20(dai).transferFrom(msg.sender, address(this), priceToPay);
            }else{
                require(ERC20(usdc).allowance(msg.sender, address(this)) >= priceToPay, "Not enough tokens allowed");
                ERC20(usdc).transferFrom(msg.sender, address(this), priceToPay);
            }
        }else{
            Utils.Element storage card = _owners[Utils.encode(cardID, cardSID)];
            require(card.owner != address(0), "This specific card does not exist");
            Utils.GlobalElement storage gcard = _elements[cardID];
            require(gcard.copies >= 1, "This global card does not exist");
            Utils.Element storage lstamp = _owners[Utils.encode(stampID, stampSID)];
            require(lstamp.owner != address(0), "This specific stamp does not exist");
            Utils.GlobalElement storage gstamp = _elements[stampID];
            require(gstamp.copies >= 1, "This global stamp does not exist");
            require(gcard.t == Utils.ElementType.card && gstamp.t == Utils.ElementType.stamp, "Incorrect types");
            require(lstamp.twin == 0 && lstamp.twinSid == 0 && card.twin == 0 && card.twinSid == 0, "Card or Stamp already attached");
            require(card.owner == msg.sender && lstamp.owner == msg.sender, "You are not the owner");
            require(lstamp.used == false, "Stamp has already been used");
            lstamp.used = true;
            lstamp.twin = cardID;
            lstamp.twinSid = cardSID;
            card.twin = stampID;
            card.twinSid = stampSID;
            emit Stamp(msg.sender, Utils.encode(stampID, stampSID), Utils.encode(cardID, cardSID), keccak256(bytes(Utils.encode(stampID, stampSID))), keccak256(bytes(Utils.encode(cardID, cardSID))));
        }
    }

    function unstamp(uint256 id, uint256 sid) public {
        Utils.Element storage elementA = _owners[Utils.encode(id, sid)];
        require(elementA.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementA = _elements[id];
        require(gElementA.copies >= 1, "This global element does not exist");
        Utils.Element storage elementB = _owners[Utils.encode(elementA.twin, elementA.twinSid)];
        require(elementB.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage gElementB = _elements[elementA.twin];
        require(gElementB.copies >= 1, "This global element does not exist");
        require(elementA.owner == msg.sender && elementB.owner == msg.sender, "You are not the owner");
        require(elementB.twin == id && elementB.twinSid == sid, "Elements are not attached together");
        if(gElementA.t == Utils.ElementType.card){
            emit Unstamp(msg.sender, Utils.encode(elementA.twin, elementA.twinSid), Utils.encode(id, sid), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))), keccak256(bytes(Utils.encode(id, sid))));
        }else{
            emit Unstamp(msg.sender, Utils.encode(id, sid), Utils.encode(elementA.twin, elementA.twinSid), keccak256(bytes(Utils.encode(id, sid))), keccak256(bytes(Utils.encode(elementA.twin, elementA.twinSid))));
        }
        elementA.twin = 0;
        elementA.twinSid = 0;
        elementB.twin = 0;
        elementB.twinSid = 0;
    }

    function burn(uint256[2][] calldata elementsToBurn) external {
        for(uint256 i = 0;i<elementsToBurn.length;i++){
            uint256 id = elementsToBurn[i][0];
            uint256 sid = elementsToBurn[i][1];
            Utils.Element storage element = _owners[Utils.encode(id, sid)];
            require(element.owner != address(0), "This specific element does not exist");
            Utils.GlobalElement storage global = _elements[id];
            require(global.copies >= 1, "This global element does not exist");
            require(element.owner == msg.sender, "The sender is not the owner");
            if(element.twin != 0){
                unstamp(id, sid);
            }
            delete _owners[Utils.encode(id, sid)];
            emit Burn(msg.sender, id, sid, global.copies);
        }
    }

    function withdraw() external onlyOwner{
        uint256 daiAmount = ERC20(dai).balanceOf(address(this));
        uint256 usdcAmount = ERC20(usdc).balanceOf(address(this));
        ERC20(dai).transfer(msg.sender, daiAmount);
        ERC20(usdc).transfer(msg.sender, usdcAmount);
        emit Withdraw(msg.sender, daiAmount, usdcAmount);
    }

    function setPrice(address newPrice) external onlyOwner{
        price = newPrice;
        emit NewPrice(msg.sender, newPrice);
    }

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
        emit Marketplace(msg.sender, _marketplace);
    }

    function approve(address to, uint256 id, uint256 sid) external {
        require(to != msg.sender, "Sender cannot be equal to the approved"); 
        require(to != address(0), "To cannot be null");
        require(sid != 0, "SID cannot be null");
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        Utils.GlobalElement storage global = _elements[id];
        require(global.copies >= 1, "This global element does not exist");
        require(element.owner == msg.sender || msg.sender == _tokenApprovals[Utils.encode(id, sid)] || _operatorApprovals[element.owner][msg.sender], "The granter is not the owner");
        _tokenApprovals[Utils.encode(id, sid)] = to;
        emit Approval(element.owner, to, Utils.encode(id, sid));
    }

    function setApprovalForAll(address operator, bool approved) external {
        require(operator != address(0), "operator cannot be null");
        require(operator != msg.sender, "Sender cannot be equal to the operator"); 
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function getApproved(uint256 id, uint256 sid) external view returns(address) {
        return _tokenApprovals[Utils.encode(id, sid)];
    }

    function isApprovedForAll(address _owner, address _operator) external view returns(bool){
        return _operatorApprovals[_owner][_operator];
    }

    function ownerOf(uint256 id, uint256 sid) external view returns(address) {
        return _owners[Utils.encode(id, sid)].owner;
    }

    function getGlobal(uint256 id) external view returns(Utils.GlobalElement memory){
        return _elements[id];
    }

    function getElement(uint256 id, uint256 sid) external view returns (Utils.Element memory) {
        return _owners[Utils.encode(id, sid)];
    }

    function attached(uint256 id, uint256 sid) external view returns(uint256[2] memory) {
        uint256[2] memory _ids;
        Utils.Element storage element = _owners[Utils.encode(id, sid)];
        require(element.owner != address(0), "This specific element does not exist");
        _ids[0] = element.twin;
        _ids[1] = element.twinSid;
        return _ids;
    }

    function uri(uint256 id) external view returns(bytes memory) {
        return _elements[id].cid;
    }

    function messageUri(uint256 id, uint256 sid) external view returns (bytes memory){
        return _owners[Utils.encode(id, sid)].messageCID;
    }

    function copies(uint256 id) external view returns (uint256){
        return _elements[id].copies;
    }
    
    function creator(uint256 id) external view returns(address) {
        return _elements[id].creator;
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Price {

    modifier correctQuantity(uint256 quantity){
        require(quantity >= 1, "Cannot get a price less than one");
        _;
    }

    function cardPrice(uint256 copies) external pure correctQuantity(copies) returns(uint256) {
        if (copies <= 4) {
            return 4.667*10**18*copies;
        }else if (copies <= 10) {
            return 3.667*10**18*copies;
        }else if (copies <= 20) {
            return 2.980*10**18*copies;
        }else if (copies <= 100) {
            return 2.3*10**18*copies;
        }else{
            return 2*10**18;
        }
    }

    function stampPrice() external pure returns(uint256) {
        return 0.5*10**18;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./Harfang.sol";
library Utils {
    enum ElementType {
        card,
        stamp
    }

    enum MarketplaceActionType {
        Auction,
        Direct,
        Bid,
        Offer
    }

    enum Currency {
        usdc,
        dai
    }

    struct Price {
        uint256 price;
        Currency currency;
    }

    struct MarketplaceAction {
        MarketplaceActionType t;
        uint256 id;
        uint256 sid;
        address concerned;
        Price price;
        address highestBidder;
        uint256 ends;
    }

    struct Element {
        address owner;
        uint256 twin;
        uint256 twinSid;
        bytes messageCID;
        bool used;
    }

    struct GlobalElement {
        address creator;
        bytes cid;
        uint256 copies;
        ElementType t;
        uint256 lastId;
    }

    function createGlobalElement(bytes memory cid, uint256 copies, ElementType t, address owner) internal pure returns(GlobalElement memory){
        return GlobalElement(
            owner, // creator
            cid, // uri
            copies, // copies
            t, // type
            0 // lastId
        );
    }

    function createLocalElement(address owner) internal pure returns(Element memory){
        return Element(
            owner, // owner
            0, // twin
            0, // twin sid
            "", // message
            false // used
        );
    }

    function encode(uint256 x, uint256 y) internal pure returns (string memory){
        return string(abi.encodePacked(abi.encodePacked(Strings.toString(x),"-"),Strings.toString(y)));
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

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