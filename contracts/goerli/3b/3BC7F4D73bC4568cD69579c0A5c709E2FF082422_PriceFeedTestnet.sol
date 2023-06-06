// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

import "../../Interfaces/IPriceFeed.sol";
import "../../Interfaces/IFallbackCaller.sol";
import "../../Dependencies/Ownable.sol";
import "../../Dependencies/CheckContract.sol";
import "../../Dependencies/AuthNoOwner.sol";

/*
 * PriceFeed placeholder for testnet and development. The price can be manually input or fetched from
   the Fallback's TestNet implementation. Backwards compatible with local test environment as it defaults to use
   the manual price.
 */
contract PriceFeedTestnet is IPriceFeed, Ownable, CheckContract, AuthNoOwner {
    // --- variables ---

    uint256 private _price = 7428 * 1e13; // stETH/BTC price == ~15.8118 ETH per BTC
    bool public _useFallback;
    IFallbackCaller public fallbackCaller; // Wrapper contract that calls the Fallback system

    constructor(address _authorityAddress) {
        _initializeAuthority(_authorityAddress);
    }

    // --- Dependency setters ---

    function setAddresses(
        address _priceAggregatorAddress, // Not used but kept for compatibility with deployment script
        address _fallbackCallerAddress,
        address _authorityAddress
    ) external onlyOwner {
        checkContract(_fallbackCallerAddress);

        fallbackCaller = IFallbackCaller(_fallbackCallerAddress);

        _initializeAuthority(_authorityAddress);

        renounceOwnership();
    }

    // --- Functions ---

    // View price getter for simplicity in tests
    function getPrice() external view returns (uint256) {
        return _price;
    }

    function fetchPrice() external override returns (uint256) {
        // Fire an event just like the mainnet version would.
        // This lets the subgraph rely on events to get the latest price even when developing locally.
        if (_useFallback) {
            FallbackResponse memory fallbackResponse = _getCurrentFallbackResponse();
            if (fallbackResponse.success) {
                _price = fallbackResponse.answer;
            }
        }
        emit LastGoodPriceUpdated(_price);
        return _price;
    }

    // Manual external price setter.
    function setPrice(uint256 price) external returns (bool) {
        _price = price;
        return true;
    }

    // Manual toggle use of Tellor testnet feed
    function toggleUseFallback() external returns (bool) {
        _useFallback = !_useFallback;
        return _useFallback;
    }

    function setFallbackCaller(address _fallbackCaller) external requiresAuth {
        address oldFallbackCaller = address(fallbackCaller);
        fallbackCaller = IFallbackCaller(_fallbackCaller);
        emit FallbackCallerChanged(oldFallbackCaller, _fallbackCaller);
    }

    // --- Oracle response wrapper functions ---
    /*
     * "_getCurrentFallbackResponse" fetches stETH/BTC from the Fallback, and returns it as a
     * FallbackResponse struct.
     */
    function _getCurrentFallbackResponse()
        internal
        view
        returns (FallbackResponse memory fallbackResponse)
    {
        uint stEthBtcValue;
        uint stEthBtcTimestamp;
        bool stEthBtcRetrieved;

        // Attempt to get the Fallback's stETH/BTC price
        try fallbackCaller.getFallbackResponse() returns (
            uint256 answer,
            uint256 timestampRetrieved,
            bool success
        ) {
            fallbackResponse.answer = answer;
            fallbackResponse.timestamp = timestampRetrieved;
            fallbackResponse.success = success;
        } catch {
            return (fallbackResponse);
        }
        return (fallbackResponse);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

import {Authority} from "./Authority.sol";

/// @notice Provides a flexible and updatable auth pattern which is completely separate from application logic.
/// @author Modified by BadgerDAO to remove owner
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
contract AuthNoOwner {
    event AuthorityUpdated(address indexed user, Authority indexed newAuthority);

    Authority public authority;
    bool public authorityInitialized;

    modifier requiresAuth() virtual {
        require(isAuthorized(msg.sender, msg.sig), "Auth: UNAUTHORIZED");

        _;
    }

    function isAuthorized(address user, bytes4 functionSig) internal view virtual returns (bool) {
        Authority auth = authority; // Memoizing authority saves us a warm SLOAD, around 100 gas.

        // Checking if the caller is the owner only after calling the authority saves gas in most cases, but be
        // aware that this makes protected functions uncallable even to the owner if the authority is out of order.
        return (address(auth) != address(0) && auth.canCall(user, address(this), functionSig));
    }

    function setAuthority(address newAuthority) public virtual {
        // We check if the caller is the owner first because we want to ensure they can
        // always swap out the authority even if it's reverting or using up a lot of gas.
        require(authority.canCall(msg.sender, address(this), msg.sig));

        authority = Authority(newAuthority);

        // Once authority is set once via any means, ensure it is initialized
        if (!authorityInitialized) {
            authorityInitialized = true;
        }

        emit AuthorityUpdated(msg.sender, Authority(newAuthority));
    }

    /// @notice Changed constructor to initialize to allow flexiblity of constructor vs initializer use
    /// @notice sets authorityInitiailzed flag to ensure only one use of
    function _initializeAuthority(address newAuthority) internal {
        require(address(authority) == address(0), "Auth: authority is non-zero");
        require(!authorityInitialized, "Auth: authority already initialized");

        authority = Authority(newAuthority);
        authorityInitialized = true;

        emit AuthorityUpdated(address(this), Authority(newAuthority));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.17;

/// @notice A generic interface for a contract which provides authorization data to an Auth instance.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Auth.sol)
/// @author Modified from Dappsys (https://github.com/dapphub/ds-auth/blob/master/src/auth.sol)
interface Authority {
    function canCall(address user, address target, bytes4 functionSig) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/**
 * Check that the account is an already deployed non-destroyed contract.
 * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
 */

contract CheckContract {
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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
    function checkContract(address account) internal view {
        require(account != address(0), "Account cannot be zero address");
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        require(account.code.length > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity 0.8.17;

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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity 0.8.17;

import "./Context.sol";

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

pragma solidity 0.8.17;

interface IFallbackCaller {
    // --- Events ---
    event FallbackTimeOutChanged(uint256 _oldTimeOut, uint256 _newTimeOut);

    // --- Function External View ---

    // NOTE: The fallback oracle must always return its answer scaled to 18 decimals where applicable
    //       The system will assume an 18 decimal response for efficiency.
    function getFallbackResponse() external view returns (uint256, uint256, bool);

    // NOTE: this returns the timeout window interval for the fallback oracle instead
    // of storing in the `PriceFeed` contract is retrieve for the `FallbackCaller`
    function fallbackTimeout() external view returns (uint256);

    // --- Function External Setter ---

    function setFallbackTimeout(uint256 newFallbackTimeout) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IPriceFeed {
    // --- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);
    event PriceFeedStatusChanged(Status newStatus);
    event FallbackCallerChanged(address _oldFallbackCaller, address _newFallbackCaller);
    event UnhealthyFallbackCaller(address _fallbackCaller, uint256 timestamp);

    // --- Structs ---

    struct ChainlinkResponse {
        uint80 roundEthBtcId;
        uint80 roundStEthEthId;
        uint256 answer;
        uint256 timestampEthBtc;
        uint256 timestampStEthEth;
        bool success;
    }

    struct FallbackResponse {
        uint256 answer;
        uint256 timestamp;
        bool success;
    }

    // --- Enum ---

    enum Status {
        chainlinkWorking,
        usingFallbackChainlinkUntrusted,
        bothOraclesUntrusted,
        usingFallbackChainlinkFrozen,
        usingChainlinkFallbackUntrusted
    }

    // --- Function ---
    function fetchPrice() external returns (uint);
}