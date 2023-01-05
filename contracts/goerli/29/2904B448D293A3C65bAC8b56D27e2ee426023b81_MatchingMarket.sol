/**
 *Submitted for verification at Etherscan.io on 2023-01-05
*/

// Sources flattened with hardhat v2.8.2 https://hardhat.org

// File contracts/libraries/DSMath.sol

pragma solidity 0.8.10;

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

}


// File contracts/interfaces/IMaintainersRegistry.sol

pragma solidity 0.8.10;

interface IMaintainersRegistry {
    function isMaintainer(address _address) external view returns (bool);
}


// File contracts/system/OrderBookUpgradable.sol

pragma solidity 0.8.10;

contract OrderBookUpgradable {

    address public hordCongress;
    IMaintainersRegistry public maintainersRegistry;

    modifier onlyMaintainer {
        require(maintainersRegistry.isMaintainer(msg.sender), "Restricted only to maintainer.");
        _;
    }

    modifier onlyHordCongress {
        require(msg.sender == hordCongress, "Restricted only to HordCongress.");
        _;
    }

    function setCongressAndMaintainers(
        address _hordCongress,
        address _maintainersRegistry
    )
    internal
    {
        require(_hordCongress != address(0), "Hord congress can't be 0x0 address");
        require(_maintainersRegistry != address(0), "Maintainers regsitry can't be 0x0 address");
        hordCongress = _hordCongress;
        maintainersRegistry = IMaintainersRegistry(_maintainersRegistry);
    }

}


// File contracts/interfaces/IOrderbookConfiguration.sol

pragma solidity 0.8.10;

interface IOrderbookConfiguration {
    function hordToken() external view returns(address);
    function dustToken() external view returns(address);
    function dustLimit() external view returns (uint256);
    function calculateTotalFee(uint256 amount) external view returns (uint256);
    function calculateChampionFee(uint256 amount) external view returns (uint256);
    function calculateOrderbookFee(uint256 amount) external view returns (uint256);
}


// File contracts/interfaces/IHPool.sol

pragma solidity 0.8.10;

interface IHPool {
    struct HPoolInfo {
        address championAddress;
        address hPoolImplementation;
        address baseAsset;
        uint256 totalBaseAssetAtLaunch;
        uint256 hPoolId;
        uint256 bePoolId;
        uint256 initialPoolWorthUSD;
        uint256 availableToClaimChampionSuccessFee;
        uint256 totalChampionSuccessFee;
        uint256 availableToClaimProtocolFee;
        uint256 totalProtocolFee;
        uint256 totalDeposit;
        bool isHPoolEnded;
    }
    function hPool() external returns (HPoolInfo memory);
}


// File contracts/interfaces/IERC20.sol

pragma solidity 0.8.10;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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


// File contracts/interfaces/IHPoolManager.sol

pragma solidity 0.8.10;

interface IHPoolManager {
    function isHPoolToken(address hPoolToken) external view returns (bool);
    function getPoolInfo(
        uint256 poolId
    )
    external
    view
    returns (
        uint256,
        uint256,
        address,
        uint256,
        uint256,
        bool,
        uint256,
        address,
        uint256,
        uint256,
        uint256,
        uint256
    );
}


// File contracts/interfaces/IVPoolManager.sol

pragma solidity 0.8.10;

interface IVPoolManager {
    function isVPoolToken(address vPoolToken) external view returns (bool);
    function getPoolInfo(uint256 poolId)
    external
    view
    returns (
        uint256,
        address,
        address,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    );
}


// File contracts/interfaces/IHordTreasury.sol

pragma solidity 0.8.10;

interface IHordTreasury {
    function depositToken(address token, uint256 amount) external;
}


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts-upgradeable/proxy/utils/[email protected]

// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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


// File @openzeppelin/contracts-upgradeable/utils/[email protected]

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}


// File @openzeppelin/contracts-upgradeable/security/[email protected]

// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}


// File contracts/SimpleMarket.sol


/// simple_market.sol

// Copyright (C) 2016 - 2021 Dai Foundation

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.10;










contract EventfulMarket {
    event LogItemUpdate(uint id);
    event LogTrade(uint pay_amt, address indexed pay_gem,
        uint buy_amt, address indexed buy_gem);

    event LogMake(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20             pay_gem,
        IERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogBump(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event LogTake(
        bytes32           id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20            pay_gem,
        IERC20            buy_gem,
        address  indexed  taker,
        uint128           take_amt,
        uint128           give_amt,
        uint64            timestamp
    );

    event LogKill(
        bytes32  indexed  id,
        bytes32  indexed  pair,
        address  indexed  maker,
        IERC20             pay_gem,
        IERC20             buy_gem,
        uint128           pay_amt,
        uint128           buy_amt,
        uint64            timestamp
    );

    event FeesTaken(
        uint256 totalFee
    );
}

contract SimpleMarket is EventfulMarket, DSMath, OrderBookUpgradable, ReentrancyGuardUpgradeable, PausableUpgradeable {

    uint public last_offer_id; // last offer id to keep track of the last index
    bool public locked; // locked variable for reentrancy attack prevention

    mapping (uint => OfferInfo) public offers; // offer id => OfferInfo mapping
    mapping (address => ChampionFee) public poolToChampionFee;
    mapping (address => PlatformFee) public poolToPlatformFee;

    IHPoolManager public hPoolManager; // Instance of HPoolManager
    IVPoolManager public vPoolManager; // Instance of VPoolManager
    IHordTreasury public hordTreasury; // Instance of HordTreasury
    IOrderbookConfiguration public orderbookConfiguration; // Instance of Orderbook configuration contract
    IERC20 public dustToken; // main token that gets trading against HPool tokens

    struct OfferInfo {
        uint     pay_amt;
        IERC20    pay_gem;
        uint     buy_amt;
        IERC20    buy_gem;
        address  owner;
        uint64   timestamp;
    }

    struct ChampionFee {
        uint256 totalTransferFeesInPoolTokens;
        uint256 availableTransferFeesInPoolTokens;
        uint256 totalTradingFeesInStableCoin;
        uint256 availableTradingFeesInStableCoin;
    }

     struct PlatformFee {
         uint256 totalTransferFeesInPoolTokens;
         uint256 availableTransferFeesInPoolTokens;
         uint256 totalTradingFeesInStableCoin;
         uint256 availableTradingFeesInStableCoin;
     }

    event ChampionWithdrawFees(
        address championAddress,
        uint256 amountInHpoolTokens,
        uint256 amountInBaseTokens
    );
    event ProtocolWithdrawFees(
        uint256 amountInPoolTokens,
        uint256 amountInBaseTokens
    );

    /**
        * @notice          modifier to check if user can take specific order
        * @param           id offer id
    */
    modifier can_buy(uint id) {
        require(isActive(id), "Offer is not active.");
        _;
    }

    /**
        * @notice          modifier to check if user can cancel specific order, checks if offer is active and caller is owner of offer
        * @param           id offer id
    */
    modifier can_cancel_simple_market(uint id) {
        require(isActive(id), "Offer is not active.");
        require(getOwner(id) == msg.sender, "Only owner can cancel offer.");
        _;
    }

    /**
        * @notice          modifier to prevent reentrancy attack
    */
    modifier synchronized {
        require(!locked, "Locked");
        locked = true;
        _;
        locked = false;
    }

    /**
        * @notice          function that returns if offer is valid active offer
        * @param           id offer id
    */
    function isActive(uint id) public view returns (bool active) {
        return offers[id].timestamp > 0;
    }

    function withdrawProtocolFee(address pool) external nonReentrant onlyMaintainer {
        require(hPoolManager.isHPoolToken(pool) || vPoolManager.isVPoolToken(pool), "PoolToken is not valid");

        uint256 amountInPoolTokens = poolToPlatformFee[pool].availableTransferFeesInPoolTokens;
        poolToPlatformFee[pool].availableTransferFeesInPoolTokens = 0;

        IERC20(pool).approve(address(hordTreasury), amountInPoolTokens);
        hordTreasury.depositToken(pool, amountInPoolTokens);

        uint256 amountInBaseTokens = poolToPlatformFee[pool].availableTradingFeesInStableCoin;
        poolToPlatformFee[pool].availableTradingFeesInStableCoin = 0;

        IERC20(orderbookConfiguration.dustToken()).approve(address(hordTreasury), amountInBaseTokens);
        hordTreasury.depositToken(orderbookConfiguration.dustToken(), amountInBaseTokens);


        emit ProtocolWithdrawFees(amountInPoolTokens, amountInBaseTokens);
    }

    /**
        * @notice          function that returns owner address of specific order
        * @param           id offer id
    */
    function getOwner(uint id) public view returns (address owner) {
        return offers[id].owner;
    }

    /**
        * @notice          function that returns from specific order the buy token, buy token amount, sell token and sell token amount
        * @param           id offer id
    */
    function getOffer(uint id) external view returns (uint, IERC20, uint, IERC20) {
        OfferInfo memory offer = offers[id];
        return (offer.pay_amt, offer.pay_gem,
        offer.buy_amt, offer.buy_gem);
    }

    // ---- Public entrypoints ---- //

    function bump(bytes32 id_)
    external
    can_buy(uint256(id_))
    {
        uint256 id = uint256(id_);
        emit LogBump(
            id_,
            keccak256(abi.encodePacked(offers[id].pay_gem, offers[id].buy_gem)),
            offers[id].owner,
            offers[id].pay_gem,
            offers[id].buy_gem,
            uint128(offers[id].pay_amt),
            uint128(offers[id].buy_amt),
            offers[id].timestamp
        );
    }

    /**
        * @notice          function that transfers funds from caller to offer maker, and from market to caller. Accepts given `quantity` of an offer
        * @param           id offer id
        * @param           quantity amount of tokens to buy
    */
    function buy_simple_market(uint id, uint quantity)
    internal
    can_buy(id)
    synchronized
    returns (bool)
    {
        OfferInfo memory offer = offers[id];
        uint spend = mul(quantity, offer.buy_amt) / offer.pay_amt;

        require(uint128(spend) == spend, "Cast error.");
        require(uint128(quantity) == quantity, "Cast error.");

        // For backwards semantic compatibility.
        if (quantity == 0 || spend == 0 ||
        quantity > offer.pay_amt || spend > offer.buy_amt)
        {
            return false;
        }

        offers[id].pay_amt = sub(offer.pay_amt, quantity);
        offers[id].buy_amt = sub(offer.buy_amt, spend);

        if (address(offer.buy_gem) == address(dustToken)) { // offer.buy_gem is BUSD
            uint256 totalFee = orderbookConfiguration.calculateTotalFee(spend);

            uint256 updatedSpend = spend - totalFee; // take champion and protocol fee from BUSD

            poolToPlatformFee[address(offer.pay_gem)].availableTradingFeesInStableCoin += totalFee;
            poolToPlatformFee[address(offer.pay_gem)].totalTradingFeesInStableCoin += totalFee;

            safeTransferFrom(offer.buy_gem, msg.sender, address(this), totalFee);
            safeTransferFrom(offer.buy_gem, msg.sender, offer.owner, updatedSpend);
            safeTransfer(offer.pay_gem, msg.sender, quantity);

            emit FeesTaken(
                totalFee
            );

        } else if(address(offer.pay_gem) == address(dustToken)) { // offer.pay_gem is BUSD
            // In this condition the protocol fee already is on orderbook contract, so we dont need to transfer BUSD to it
            uint256 totalFee = orderbookConfiguration.calculateTotalFee(quantity);

            uint256 updatedQuantity = quantity - totalFee; // take champion and protocol fee from BUSD

            poolToPlatformFee[address(offer.buy_gem)].availableTradingFeesInStableCoin += totalFee;
            poolToPlatformFee[address(offer.buy_gem)].totalTradingFeesInStableCoin += totalFee;

            safeTransferFrom(offer.buy_gem, msg.sender, offer.owner, spend);
            safeTransfer(offer.pay_gem, msg.sender, updatedQuantity);

            emit FeesTaken(
                totalFee
            );
        }


        emit LogItemUpdate(id);
        emit LogTake(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            msg.sender,
            uint128(quantity),
            uint128(spend),
            uint64(block.timestamp)
        );
        emit LogTrade(quantity, address(offer.pay_gem), spend, address(offer.buy_gem));

        if (offers[id].pay_amt == 0) {
            delete offers[id];
        }

        return true;
    }

    /**
        * @notice          function that cancels an offer and refunds offer to maker
        * @param           id offer id
    */
    function cancel_simple_market(uint id)
    internal
    can_cancel_simple_market(id)
    synchronized
    returns (bool success)
    {
        // read-only offer. Modify an offer by directly accessing offers[id]
        OfferInfo memory offer = offers[id];
        delete offers[id];

        safeTransfer(offer.pay_gem, offer.owner, offer.pay_amt);

        emit LogItemUpdate(id);
        emit LogKill(
            bytes32(id),
            keccak256(abi.encodePacked(offer.pay_gem, offer.buy_gem)),
            offer.owner,
            offer.pay_gem,
            offer.buy_gem,
            uint128(offer.pay_amt),
            uint128(offer.buy_amt),
            uint64(block.timestamp)
        );

        success = true;
    }

    /**
        * @notice          function that creates a new offer. Takes funds from the caller into market escrow
        * @param           pay_amt is the amount of the token user wants to sell
        * @param           pay_gem is an ERC20 token user wants to sell
        * @param           buy_amt is the amount of the token user wants to buy
        * @param           buy_gem is an ERC20 token user wants to buy
    */
    function offer_simple_market(uint pay_amt, IERC20 pay_gem, uint buy_amt, IERC20 buy_gem)
    internal
    synchronized
    returns (uint id)
    {
        require(uint128(pay_amt) == pay_amt, "Cast error.");
        require(uint128(buy_amt) == buy_amt, "Cast error.");
        require(pay_amt > 0, "Pay amount must be greater than 0.");
        require(pay_gem != IERC20(address(0)), "Pay token can not be 0x0 address.");
        require(buy_amt > 0, "Buy ampunt must be greater than 0.");
        require(buy_gem != IERC20(address(0)), "Buy token can not be 0x0 address.");
        require(pay_gem != buy_gem, "Pay token must be different than buy token.");

        OfferInfo memory info;
        info.pay_amt = pay_amt;
        info.pay_gem = pay_gem;
        info.buy_amt = buy_amt;
        info.buy_gem = buy_gem;
        info.owner = msg.sender;
        info.timestamp = uint64(block.timestamp);
        id = _next_id();
        offers[id] = info;

        safeTransferFrom(pay_gem, msg.sender, address(this), pay_amt);

        emit LogItemUpdate(id);
        emit LogMake(
            bytes32(id),
            keccak256(abi.encodePacked(pay_gem, buy_gem)),
            msg.sender,
            pay_gem,
            buy_gem,
            uint128(pay_amt),
            uint128(buy_amt),
            uint64(block.timestamp)
        );
    }

    /**
        * @notice          function that returns the next available id
    */
    function _next_id()
    internal
    returns (uint)
    {
        last_offer_id++; return last_offer_id;
    }

    /**
        * @notice          function that calls transfer function of ERC20 token
        * @param           token is the ERC20 token that gets transfered
        * @param           to is the address of the ERC20 token gets transfered to
        * @param           value is the amount of the ERC20 token that gets transfered
    */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
        * @notice          function that calls transferFrom function of ERC20 token
        * @param           token is the the ERC20 token that gets transfered
        * @param           from is the address the ERC20 token gets transfered from
        * @param           value is the amount of the ERC20 token that gets transfered
    */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        uint256 size;
        assembly { size := extcodesize(token) }
        require(size > 0, "Not a contract");

        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "Token call failed");
        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }

    /**
       * @notice  Function allowing congress to pause the smart-contract
       * @dev     Can be only called by HordCongress
    */
    function pause()
    external
    onlyHordCongress
    {
        _pause();
    }

    /**
        * @notice  Function allowing congress to unpause the smart-contract
        * @dev     Can be only called by HordCongress
     */
    function unpause()
    external
    onlyHordCongress
    {
        _unpause();
    }

}


// File contracts/MatchingMarket.sol


/// matching_market.sol

// Copyright (C) 2017 - 2021 Dai Foundation

//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity 0.8.10;

contract MatchingEvents {
    event LogMinSell(address pay_gem, uint min_amount);
    event LogUnsortedOffer(uint id);
    event LogSortedOffer(uint id);
    event BuyAndBurn(uint256 amountEthSpent, uint256 amountHordBurned);
    event HordTreasurySet(address hordTreasury);
}

contract MatchingMarket is MatchingEvents, SimpleMarket {
    struct sortInfo {
        uint next; //points to id of next higher offer
        uint prev; //points to id of previous lower offer
        uint delb; //the blocknumber where this entry was marked for delete
    }

    mapping(uint => sortInfo) public _rank; //doubly linked lists of sorted offer ids
    mapping(address => mapping(address => uint)) public _best; //id of the highest offer for a token pair
    mapping(address => mapping(address => uint)) public _span; //number of offers stored for token pair in sorted orderbook
    mapping(address => uint) public _dust; //minimum sell amount for a token to avoid dust offers
    mapping(uint => uint) public _near; //next unsorted offer id
    uint public _head; //first unsorted offer id

    // dust management
    uint256 public dustLimit;
    address public hordETHStakingManager;


    function initialize (
        address _hordCongress,
        address _maintainersRegistry,
        address _orderbookConfiguration,
        address _hPoolManager,
        address _vPoolManager,
        address _hordTreasury
    )
    external
    initializer
    {
        require(_hPoolManager != address(0), "HPoolManager can not be 0x0 address");
        require(_vPoolManager != address(0), "VPoolManager can not be 0x0 address");
        require(_orderbookConfiguration != address(0), "OrderbookConfiguration can not be 0x0 address");

        // Set hord congress and maintainers registry
        setCongressAndMaintainers( _hordCongress, _maintainersRegistry);

        __ReentrancyGuard_init();

        orderbookConfiguration = IOrderbookConfiguration(_orderbookConfiguration);
        hPoolManager = IHPoolManager(_hPoolManager);
        vPoolManager = IVPoolManager(_vPoolManager);
        hordTreasury = IHordTreasury(_hordTreasury);

        dustToken = IERC20(orderbookConfiguration.dustToken());
        dustLimit = orderbookConfiguration.dustLimit();

        _setMinSell(IERC20(dustToken), dustLimit);
    }

    /**
        * @notice          modifier to ensure that one of the tokens is the dust token (BUSD), and one of the tokens is an HPool token
        * @param           tokenA is a token user wants trade
        * @param           tokenB is another token user wants to trade against tokenB
     */
    modifier isValidPoolTokenPair(IERC20 tokenA, IERC20 tokenB) {
        require(
            hPoolManager.isHPoolToken(address(tokenA)) && address(tokenB) == address(dustToken) ||
            hPoolManager.isHPoolToken(address(tokenB)) && address(tokenA) == address(dustToken) ||
            vPoolManager.isVPoolToken(address(tokenA)) && address(tokenB) == address(dustToken) ||
            vPoolManager.isVPoolToken(address(tokenB)) && address(tokenA) == address(dustToken) ||
            address(tokenA) == hordETHStakingManager && address(tokenB) == address(dustToken) ||
            address(tokenB) == hordETHStakingManager && address(tokenA) == address(dustToken),
            "The pair is not valid."
        );
        _;
    }

    // If owner, can cancel an offer
    // If dust, anyone can cancel an offer
    modifier can_cancel(uint id) {
        require(isActive(id), "Offer was deleted or taken, or never existed.");

        require(
            msg.sender == getOwner(id) || offers[id].pay_amt < _dust[address(offers[id].pay_gem)],
            "Offer can not be cancelled because user is not owner nor a dust one."
        );
        _;
    }

    function setHordETHStakingManager(address _hordETHStakingManager) external onlyHordCongress {
        require(_hordETHStakingManager != address(0), "can not be 0x0 address");
        hordETHStakingManager = _hordETHStakingManager;
    }

    // ---- Public entrypoints ---- //

    /**
        * @notice          function to take specific order. Calls buy function which executes the buy
        * @param           id id of the specific order
        * @param           maxTakeAmount maximal amount of tokens user wants to buy from specific order
    */
    function take(bytes32 id, uint128 maxTakeAmount) public whenNotPaused {
        require(buy(uint256(id), maxTakeAmount), "Revert in buy function.");
    }

    /**
        * @notice          function to kill specific order. Calls cancel function which executes the cancellation of the specific order
        * @param           id id of the specific order
    */
    function kill(bytes32 id) external whenNotPaused {
        require(cancel(uint256(id)), "Revert in cancel function.");
    }

    /**
        * @notice          function to make a new offer. Takes funds from the caller into market escrow
        * @param           pay_amt is the amount of the token maker wants to sell
        * @param           pay_gem is an ERC20 token maker wants to sell
        * @param           buy_amt is the amount of the token maker wants to buy
        * @param           buy_gem is an ERC20 token maker wants to buy
        * @param           pos position where to insert the new offer, 0 should be used if unknown
    */
    function offer(
        uint pay_amt,
        IERC20 pay_gem,
        uint buy_amt,
        IERC20 buy_gem,
        uint pos
    )
    external
    whenNotPaused
    isValidPoolTokenPair(pay_gem, buy_gem)
    returns (uint)
    {
        return offerWithRounding(pay_amt, pay_gem, buy_amt, buy_gem, pos, true);
    }

    /**
        * @notice          function to make a new offer. Takes funds from the caller into market escrow
        * @param           pay_amt is the amount of the token maker wants to sell
        * @param           pay_gem is an ERC20 token maker wants to sell
        * @param           buy_amt is the amount of the token maker wants to buy
        * @param           buy_gem is an ERC20 token maker wants to buy
        * @param           pos is the OFFER ID of the first offer that has a higher (or lower depending on whether it is bid or ask ) price than the new offer that the caller is making. 0 should be used if unknown.
        * @param           rounding boolean value indicating whether "close enough" orders should be matched
    */
    function offerWithRounding(
        uint pay_amt,
        IERC20 pay_gem,
        uint buy_amt,
        IERC20 buy_gem,
        uint pos,
        bool rounding
    )
    public
    whenNotPaused
    isValidPoolTokenPair(pay_gem, buy_gem)
    returns (uint)
    {
        require(!locked, "Reentrancy attempt");
        require(_dust[address(pay_gem)] <= pay_amt, "The amount of tokens for sale is less than the lower limit.");

        return _matcho(pay_amt, pay_gem, buy_amt, buy_gem, pos, rounding);
    }

    /**
        * @notice          function that transfers funds from caller to offer maker, and from market to caller
        * @param           id id of the specific order
        * @param           amount amount of tokens user wants to buy from specific order
    */
    function buy(uint id, uint amount)
    public
    whenNotPaused
    can_buy(id)
    returns (bool)
    {
        require(!locked, "Reentrancy attempt");
        return _buys(id, amount);
    }

    /**
        * @notice          function that cancels an offer and refunds offer to maker
        * @param           id id of the specific order
    */
    function cancel(uint id)
    public
    whenNotPaused
    can_cancel(id)
    returns (bool success)
    {
        require(!locked, "Reentrancy attempt");
        if (isOfferSorted(id)) {
            require(_unsort(id), "Revert in _unsort function.");
        } else {
            require(_hide(id), "Revert in _hide function.");
        }
        return cancel_simple_market(id);    //delete the offer.
    }

    //returns the minimum sell amount for an offer
    function getMinSell(
        IERC20 pay_gem      //token for which minimum sell amount is queried
    )
    external
    view
    returns (uint)
    {
        return _dust[address(pay_gem)];
    }

    //return the best offer for a token pair
    //      the best offer is the lowest one if it's an ask,
    //      and highest one if it's a bid offer
    function getBestOffer(IERC20 sell_gem, IERC20 buy_gem) public view returns(uint) {
        return _best[address(sell_gem)][address(buy_gem)];
    }

    //return the next worse offer in the sorted list
    //      the worse offer is the higher one if its an ask,
    //      a lower one if its a bid offer,
    //      and in both cases the newer one if they're equal.
    function getWorseOffer(uint id) public view returns(uint) {
        return _rank[id].prev;
    }

    //return the next better offer in the sorted list
    //      the better offer is in the lower priced one if its an ask,
    //      the next higher priced one if its a bid offer
    //      and in both cases the older one if they're equal.
    function getBetterOffer(uint id) external view returns(uint) {

        return _rank[id].next;
    }

    //return the amount of better offers for a token pair
    function getOfferCount(IERC20 sell_gem, IERC20 buy_gem) external view returns(uint) {
        return _span[address(sell_gem)][address(buy_gem)];
    }

    //get the first unsorted offer that was inserted by a contract
    //      Contracts can't calculate the insertion position of their offer because it is not an O(1) operation.
    //      Their offers get put in the unsorted list of offers.
    //      Keepers can calculate the insertion position offchain and pass it to the insert() function to insert
    //      the unsorted offer into the sorted list. Unsorted offers will not be matched, but can be bought with buy().
    function getFirstUnsortedOffer() external view returns(uint) {
        return _head;
    }

    //get the next unsorted offer
    //      Can be used to cycle through all the unsorted offers.
    function getNextUnsortedOffer(uint id) external view returns(uint) {
        return _near[id];
    }

    function isOfferSorted(uint id) public view returns(bool) {
        return _rank[id].next != 0
        || _rank[id].prev != 0
        || _best[address(offers[id].pay_gem)][address(offers[id].buy_gem)] == id;
    }

    /**
        * @notice          function that attempts to exchange all of the pay_gem tokens for at least the specified amount of
                           buy_gem tokens. It is possible that more tokens will be bought (depending on the current state of
                           the orderbook). Transaction will fail if the method call determines that the caller will receive
                           less amount than the amount specified as min_fill_amount.
        * @param           pay_gem is an ERC20 token user wants to sell
        * @param           pay_amt is the amount of the token user wants to sell
        * @param           buy_gem is an ERC20 token user wants to buy
        * @param           min_fill_amount The least amount that the caller is willing to receive. If slippage happens and
                           price declines the user might end up with less of the buy_gem. In order to avoid big losses the
                           caller should provide this threshold
    */
    function sellAllAmount(IERC20 pay_gem, uint pay_amt, IERC20 buy_gem, uint min_fill_amount)
    external
    whenNotPaused
    returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (pay_amt > 0) {                           //while there is amount to sell
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0, "offerId can not be 0.");                      //Fails if there are not more offers

            // There is a chance that pay_amt is smaller than 1 wei of the other token
            if (pay_amt * 1 ether < wdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (pay_amt >= offers[offerId].buy_amt) {                       //If amount to sell is higher or equal than current offer amount to buy
                fill_amt = add(fill_amt, offers[offerId].pay_amt);          //Add amount bought to acumulator
                pay_amt = sub(pay_amt, offers[offerId].buy_amt);            //Decrease amount to sell
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else { // if lower
                uint256 baux = rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9;
                fill_amt = add(fill_amt, baux);         //Add amount bought to acumulator
                take(bytes32(offerId), uint128(baux));  //We take the portion of the offer that we need
                pay_amt = 0;                            //All amount is sold
            }
        }
        require(fill_amt >= min_fill_amount, "fill_amt is less than min_fill_amount.");
    }

    /**
       * @notice          function that attempts to exchange at most specified amount of pay_gem tokens for a
                          specified amount of buy_gem tokens. It is possible that less tokens will be spent (depending
                          on the current state of the orderbook). Transaction will fail if the method call determines
                          that the caller will pay more than the amount specified as max_fill_amount.
       * @param           buy_gem is an ERC20 token user wants to buy
       * @param           buy_amt is the amount of the token user wants to buy
       * @param           pay_gem is an ERC20 token user wants to sell
       * @param           max_fill_amount The most amount that the caller is willing to pay. If slippage happens and
                          price increases the user might end up with paying more of the pay_gem. In order to avoid big
                          losses the caller should provide this threshold.
   */
    function buyAllAmount(IERC20 buy_gem, uint buy_amt, IERC20 pay_gem, uint max_fill_amount)
    external
    whenNotPaused
    returns (uint fill_amt)
    {
        require(!locked, "Reentrancy attempt");
        uint offerId;
        while (buy_amt > 0) {                           //Meanwhile there is amount to buy
            offerId = getBestOffer(buy_gem, pay_gem);   //Get the best offer for the token pair
            require(offerId != 0, "offerId can not be 0.");

            // There is a chance that buy_amt is smaller than 1 wei of the other token
            if (buy_amt * 1 ether < wdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) {
                break;                                  //We consider that all amount is sold
            }
            if (buy_amt >= offers[offerId].pay_amt) {                       //If amount to buy is higher or equal than current offer amount to sell
                fill_amt = add(fill_amt, offers[offerId].buy_amt);          //Add amount sold to acumulator
                buy_amt = sub(buy_amt, offers[offerId].pay_amt);            //Decrease amount to buy
                take(bytes32(offerId), uint128(offers[offerId].pay_amt));   //We take the whole offer
            } else {                                                        //if lower
                fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add amount sold to acumulator
                take(bytes32(offerId), uint128(buy_amt));                   //We take the portion of the offer that we need
                buy_amt = 0;                                                //All amount is bought
            }
        }
        require(fill_amt <= max_fill_amount, "fill_amt is less than min_fill_amount.");
    }

    function getBuyAmount(IERC20 buy_gem, IERC20 pay_gem, uint pay_amt) external view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (pay_amt > offers[offerId].buy_amt) {
            fill_amt = add(fill_amt, offers[offerId].pay_amt);  //Add amount to buy accumulator
            pay_amt = sub(pay_amt, offers[offerId].buy_amt);    //Decrease amount to pay
            if (pay_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0, "offerId can not be 0.");                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(pay_amt * 10 ** 9, rdiv(offers[offerId].pay_amt, offers[offerId].buy_amt)) / 10 ** 9); //Add proportional amount of last offer to buy accumulator
    }

    function getPayAmount(IERC20 pay_gem, IERC20 buy_gem, uint buy_amt) external view returns (uint fill_amt) {
        uint256 offerId = getBestOffer(buy_gem, pay_gem);           //Get best offer for the token pair
        while (buy_amt > offers[offerId].pay_amt) {
            fill_amt = add(fill_amt, offers[offerId].buy_amt);  //Add amount to pay accumulator
            buy_amt = sub(buy_amt, offers[offerId].pay_amt);    //Decrease amount to buy
            if (buy_amt > 0) {                                  //If we still need more offers
                offerId = getWorseOffer(offerId);               //We look for the next best offer
                require(offerId != 0, "offerId can not be 0.");                          //Fails if there are not enough offers to complete
            }
        }
        fill_amt = add(fill_amt, rmul(buy_amt * 10 ** 9, rdiv(offers[offerId].buy_amt, offers[offerId].pay_amt)) / 10 ** 9); //Add proportional amount of last offer to pay accumulator
    }

    // ---- Internal Functions ---- //

    function _setMinSell(
        IERC20 pay_gem,     //token to assign minimum sell amount to
        uint256 dust
    )
    internal
    {
        _dust[address(pay_gem)] = dust;
        emit LogMinSell(address(pay_gem), dust);
    }

    function _buys(uint id, uint amount)
    internal
    returns (bool)
    {
        if (amount == offers[id].pay_amt) {
            if (isOfferSorted(id)) {
                //offers[id] must be removed from sorted list because all of it is bought
                _unsort(id);
            }else{
                _hide(id);
            }
        }
        require(buy_simple_market(id, amount), "Revert in buy_simple_market function.");
        // If offer has become dust during buy, we cancel it
        if (isActive(id) && offers[id].pay_amt < _dust[address(offers[id].pay_gem)]) {
            cancel(id);
        }
        return true;
    }

    //find the id of the next higher offer after offers[id]
    function _find(uint id)
    internal
    view
    returns (uint)
    {
        require(id > 0, "id must be greater than 0.");

        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        uint top = _best[pay_gem][buy_gem];
        uint old_top = 0;

        // Find the larger-than-id order whose successor is less-than-id.
        while (top != 0 && _isPricedLtOrEq(id, top)) {
            old_top = top;
            top = _rank[top].prev;
        }
        return old_top;
    }

    //find the id of the next higher offer after offers[id]
    function _findpos(uint id, uint pos)
    internal
    view
    returns (uint)
    {
        require(id > 0, "id must be greater than 0.");

        // Look for an active order.
        while (pos != 0 && !isActive(pos)) {
            pos = _rank[pos].prev;
        }

        if (pos == 0) {
            //if we got to the end of list without a single active offer
            return _find(id);

        } else {
            // if we did find a nearby active offer
            // Walk the order book down from there...
            if(_isPricedLtOrEq(id, pos)) {
                uint old_pos;

                // Guaranteed to run at least once because of
                // the prior if statements.
                while (pos != 0 && _isPricedLtOrEq(id, pos)) {
                    old_pos = pos;
                    pos = _rank[pos].prev;
                }
                return old_pos;

                // ...or walk it up.
            } else {
                while (pos != 0 && !_isPricedLtOrEq(id, pos)) {
                    pos = _rank[pos].next;
                }
                return pos;
            }
        }
    }

    /**
        * @notice          function returns true if offers[low] priced less than or equal to offers[high]
        * @param           low lower priced offer's id
        * @param           high higher priced offer's id
    */
    function _isPricedLtOrEq(
        uint low,
        uint high
    )
    internal
    view
    returns (bool)
    {
        return offers[low].buy_amt * offers[high].pay_amt
        >= offers[high].buy_amt * offers[low].pay_amt;
    }

    //these variables are global only because of solidity local variable limit

    /**
        * @notice          function that matches offers with taker offer, and execute token transactions
        * @param           t_pay_amt is the amount of the token taker wants to sell
        * @param           t_pay_gem is an ERC20 token taker wants to sell
        * @param           t_buy_amt is the amount of the token taker wants to buy
        * @param           t_buy_gem is an ERC20 token taker wants to buy
        * @param           pos is the OFFER ID of the first offer that has a higher (or lower depending on whether it is bid or ask ) price than the new offer that the caller is making. 0 should be used if unknown.
        * @param           rounding boolean value indicating whether "close enough" orders should be matched
    */
    function _matcho(
        uint t_pay_amt,
        IERC20 t_pay_gem,
        uint t_buy_amt,
        IERC20 t_buy_gem,
        uint pos,
        bool rounding
    )
    internal
    returns (uint id)
    {
        uint best_maker_id;    //highest maker id
        uint t_buy_amt_old;    //taker buy how much saved
        uint m_buy_amt;        //maker offer wants to buy this much token
        uint m_pay_amt;        //maker offer wants to sell this much token

        // there is at least one offer stored for token pair
        while (_best[address(t_buy_gem)][address(t_pay_gem)] > 0) {
            best_maker_id = _best[address(t_buy_gem)][address(t_pay_gem)];
            m_buy_amt = offers[best_maker_id].buy_amt;
            m_pay_amt = offers[best_maker_id].pay_amt;

            // Ugly hack to work around rounding errors. Based on the idea that
            // the furthest the amounts can stray from their "true" values is 1.
            // Ergo the worst case has t_pay_amt and m_pay_amt at +1 away from
            // their "correct" values and m_buy_amt and t_buy_amt at -1.
            // Since (c - 1) * (d - 1) > (a + 1) * (b + 1) is equivalent to
            // c * d > a * b + a + b + c + d, we write...
            if (mul(m_buy_amt, t_buy_amt) > mul(t_pay_amt, m_pay_amt) +
            (rounding ? m_buy_amt + t_buy_amt + t_pay_amt + m_pay_amt : 0))
            {
                break;
            }
            // ^ The `rounding` parameter is a compromise borne of a couple days
            // of discussion.
            buy(best_maker_id, min(m_pay_amt, t_buy_amt)); // buys if its possible
            t_buy_amt_old = t_buy_amt;
            t_buy_amt = sub(t_buy_amt, min(m_pay_amt, t_buy_amt));
            t_pay_amt = mul(t_buy_amt, t_pay_amt) / t_buy_amt_old;

            if (t_pay_amt == 0 || t_buy_amt == 0) {
                break;
            }
        }

        if (t_buy_amt > 0 && t_pay_amt > 0 && t_pay_amt >= _dust[address(t_pay_gem)]) {
            //new offer should be created
            id = offer_simple_market(t_pay_amt, t_pay_gem, t_buy_amt, t_buy_gem); // makes offer if something is left
            //insert offer into the sorted list
            _sort(id, pos);
        }


    }


    /**
        * @notice          function that puts offer into the sorted list
        * @param           id maker (ask) id
        * @param           pos position to insert into
    */
    function _sort(
        uint id,
        uint pos
    )
    internal
    {
        require(isActive(id), "offer is not active.");

        IERC20 buy_gem = offers[id].buy_gem;
        IERC20 pay_gem = offers[id].pay_gem;
        uint prev_id;                                      //maker (ask) id

        pos = pos == 0 || offers[pos].pay_gem != pay_gem || offers[pos].buy_gem != buy_gem || !isOfferSorted(pos)
        ?
        _find(id)
        :
        _findpos(id, pos);

        if (pos != 0) {                                    //offers[id] is not the highest offer
            //requirement below is satisfied by statements above
            //require(_isPricedLtOrEq(id, pos));
            prev_id = _rank[pos].prev;
            _rank[pos].prev = id;
            _rank[id].next = pos;
        } else {                                           //offers[id] is the highest offer
            prev_id = _best[address(pay_gem)][address(buy_gem)];
            _best[address(pay_gem)][address(buy_gem)] = id;
        }

        if (prev_id != 0) {                               //if lower offer does exist
            //requirement below is satisfied by statements above
            //require(!_isPricedLtOrEq(id, prev_id));
            _rank[prev_id].next = id;
            _rank[id].prev = prev_id;
        }

        _span[address(pay_gem)][address(buy_gem)]++;
        emit LogSortedOffer(id);
    }

    /**
        * @notice          function that removes offer from the sorted list (does not cancel offer)
        * @param           id id of maker (ask) offer to remove from sorted list
    */
    function _unsort(
        uint id
    )
    internal
    returns (bool)
    {
        address buy_gem = address(offers[id].buy_gem);
        address pay_gem = address(offers[id].pay_gem);
        require(_span[pay_gem][buy_gem] > 0, "There is no offer for this token pair.");

        require(_rank[id].delb == 0 &&                    //assert id is in the sorted list
            isOfferSorted(id), "Id is not in the sorted list.");

        if (id != _best[pay_gem][buy_gem]) {              // offers[id] is not the highest offer
            require(_rank[_rank[id].next].prev == id, "Id is not on valid pos.");
            _rank[_rank[id].next].prev = _rank[id].prev;
        } else {                                          //offers[id] is the highest offer
            _best[pay_gem][buy_gem] = _rank[id].prev;
        }

        if (_rank[id].prev != 0) {                        //offers[id] is not the lowest offer
            require(_rank[_rank[id].prev].next == id, "Id is not on valid pos.");
            _rank[_rank[id].prev].next = _rank[id].next;
        }

        _span[pay_gem][buy_gem]--;
        _rank[id].delb = block.number;                    //mark _rank[id] for deletion
        return true;
    }

    //Hide offer from the unsorted order book (does not cancel offer)
    function _hide(
        uint id     //id of maker offer to remove from unsorted list
    )
    internal
    returns (bool)
    {
        uint uid = _head;               //id of an offer in unsorted offers list
        uint pre = uid;                 //id of previous offer in unsorted offers list

        require(!isOfferSorted(id), "OrderId is in sorted offers list.");    //make sure offer id is not in sorted offers list

        if (_head == id) {              //check if offer is first offer in unsorted offers list
            _head = _near[id];          //set head to new first unsorted offer
            _near[id] = 0;              //delete order from unsorted order list
            return true;
        }
        while (uid > 0 && uid != id) {  //find offer in unsorted order list
            pre = uid;
            uid = _near[uid];
        }
        if (uid != id) {                //did not find offer id in unsorted offers list
            return false;
        }
        _near[pre] = _near[id];         //set previous unsorted offer to point to offer after offer id
        _near[id] = 0;                  //delete order from unsorted order list
        return true;
    }
}