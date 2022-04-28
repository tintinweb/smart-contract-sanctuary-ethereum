pragma solidity ^0.8.0;

// external
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";

// internal
import "../utils/proxy/solidity-0.8.0/ProxyReentrancyGuard.sol";
import "../utils/proxy/solidity-0.8.0/ProxyOwned.sol";
import "../interfaces/IExoticPositionalMarketManager.sol";
import "../interfaces/IExoticPositionalMarket.sol";
import "../interfaces/IStakingThales.sol";

contract ThalesBonds is Initializable, ProxyOwned, PausableUpgradeable, ProxyReentrancyGuard {
    using SafeMathUpgradeable for uint;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    IExoticPositionalMarketManager public marketManager;
    struct MarketBond {
        uint totalDepositedMarketBond;
        uint totalMarketBond;
        uint creatorBond;
        uint resolverBond;
        uint disputorsTotalBond;
        uint disputorsCount;
        mapping(address => uint) disputorBond;
    }

    mapping(address => MarketBond) public marketBond;
    mapping(address => uint) public marketFunds;

    uint private constant CREATOR_BOND = 101;
    uint private constant RESOLVER_BOND = 102;
    uint private constant DISPUTOR_BOND = 103;
    uint private constant CREATOR_AND_DISPUTOR = 104;
    uint private constant RESOLVER_AND_DISPUTOR = 105;

    IStakingThales public stakingThales;

    function initialize(address _owner) public initializer {
        setOwner(_owner);
        initNonReentrant();
    }

    function getTotalDepositedBondAmountForMarket(address _market) external view returns (uint) {
        return marketBond[_market].totalDepositedMarketBond;
    }

    function getClaimedBondAmountForMarket(address _market) external view returns (uint) {
        return marketBond[_market].totalDepositedMarketBond.sub(marketBond[_market].totalMarketBond);
    }

    function getClaimableBondAmountForMarket(address _market) external view returns (uint) {
        return marketBond[_market].totalMarketBond;
    }

    function getDisputorBondForMarket(address _market, address _disputorAddress) external view returns (uint) {
        return marketBond[_market].disputorBond[_disputorAddress];
    }

    function getCreatorBondForMarket(address _market) external view returns (uint) {
        return marketBond[_market].creatorBond;
    }

    function getResolverBondForMarket(address _market) external view returns (uint) {
        return marketBond[_market].resolverBond;
    }

    // different deposit functions to flag the bond amount : creator
    function sendCreatorBondToMarket(
        address _market,
        address _creatorAddress,
        uint _amount
    ) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(_amount > 0, "Bond zero");
        // no checks for active market, market creation not finalized
        marketBond[_market].creatorBond = _amount;
        marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.add(_amount);
        marketBond[_market].totalDepositedMarketBond = marketBond[_market].totalDepositedMarketBond.add(_amount);
        transferToMarketBond(_creatorAddress, _amount);
        emit CreatorBondSent(_market, _creatorAddress, _amount);
    }

    // different deposit functions to flag the bond amount : resolver
    function sendResolverBondToMarket(
        address _market,
        address _resolverAddress,
        uint _amount
    ) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(_amount > 0, "Bond zero");
        require(marketManager.isActiveMarket(_market), "Invalid address");
        // in case the creator is the resolver, move the bond to the resolver
        marketBond[_market].resolverBond = _amount;
        marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.add(_amount);
        marketBond[_market].totalDepositedMarketBond = marketBond[_market].totalDepositedMarketBond.add(_amount);
        transferToMarketBond(_resolverAddress, _amount);
        emit ResolverBondSent(_market, _resolverAddress, _amount);
    }

    // different deposit functions to flag the bond amount : disputor
    function sendDisputorBondToMarket(
        address _market,
        address _disputorAddress,
        uint _amount
    ) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(_amount > 0, "Bond zero");
        require(marketManager.isActiveMarket(_market), "Invalid address");

        // if it is first dispute for the disputor, the counter is increased
        if (marketBond[_market].disputorBond[_disputorAddress] == 0) {
            marketBond[_market].disputorsCount = marketBond[_market].disputorsCount.add(1);
        }
        marketBond[_market].disputorBond[_disputorAddress] = marketBond[_market].disputorBond[_disputorAddress].add(_amount);
        marketBond[_market].disputorsTotalBond = marketBond[_market].disputorsTotalBond.add(_amount);
        marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.add(_amount);
        marketBond[_market].totalDepositedMarketBond = marketBond[_market].totalDepositedMarketBond.add(_amount);
        transferToMarketBond(_disputorAddress, _amount);
        emit DisputorBondSent(_market, _disputorAddress, _amount);
    }

    // universal claiming amount function to adapt for different scenarios, e.g. SafeBox
    function sendBondFromMarketToUser(
        address _market,
        address _account,
        uint _amount,
        uint _bondToReduce,
        address _disputorAddress
    ) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(marketManager.isActiveMarket(_market), "Invalid address");
        require(_amount <= marketBond[_market].totalMarketBond, "Exceeds bond");
        require(_bondToReduce >= CREATOR_BOND && _bondToReduce <= RESOLVER_AND_DISPUTOR, "Invalid bondToReduce");
        if (_bondToReduce == CREATOR_BOND && _amount <= marketBond[_market].creatorBond) {
            marketBond[_market].creatorBond = marketBond[_market].creatorBond.sub(_amount);
        } else if (_bondToReduce == RESOLVER_BOND && _amount <= marketBond[_market].resolverBond) {
            marketBond[_market].resolverBond = marketBond[_market].resolverBond.sub(_amount);
        } else if (
            _bondToReduce == DISPUTOR_BOND &&
            marketBond[_market].disputorBond[_disputorAddress] >= 0 &&
            _amount <= IExoticPositionalMarket(_market).disputePrice()
        ) {
            marketBond[_market].disputorBond[_disputorAddress] = marketBond[_market].disputorBond[_disputorAddress].sub(
                _amount
            );
            marketBond[_market].disputorsTotalBond = marketBond[_market].disputorsTotalBond.sub(_amount);
            marketBond[_market].disputorsCount = marketBond[_market].disputorBond[_disputorAddress] > 0
                ? marketBond[_market].disputorsCount
                : marketBond[_market].disputorsCount.sub(1);
        } else if (
            _bondToReduce == CREATOR_AND_DISPUTOR &&
            _amount <= marketBond[_market].creatorBond.add(IExoticPositionalMarket(_market).disputePrice()) &&
            _amount > marketBond[_market].creatorBond
        ) {
            marketBond[_market].disputorBond[_disputorAddress] = marketBond[_market].disputorBond[_disputorAddress].sub(
                _amount.sub(marketBond[_market].creatorBond)
            );
            marketBond[_market].disputorsTotalBond = marketBond[_market].disputorsTotalBond.sub(
                _amount.sub(marketBond[_market].creatorBond)
            );
            marketBond[_market].creatorBond = 0;
            marketBond[_market].disputorsCount = marketBond[_market].disputorBond[_disputorAddress] > 0
                ? marketBond[_market].disputorsCount
                : marketBond[_market].disputorsCount.sub(1);
        } else if (
            _bondToReduce == RESOLVER_AND_DISPUTOR &&
            _amount <= marketBond[_market].resolverBond.add(IExoticPositionalMarket(_market).disputePrice()) &&
            _amount > marketBond[_market].resolverBond
        ) {
            marketBond[_market].disputorBond[_disputorAddress] = marketBond[_market].disputorBond[_disputorAddress].sub(
                _amount.sub(marketBond[_market].resolverBond)
            );
            marketBond[_market].disputorsTotalBond = marketBond[_market].disputorsTotalBond.sub(
                _amount.sub(marketBond[_market].resolverBond)
            );
            marketBond[_market].resolverBond = 0;
            marketBond[_market].disputorsCount = marketBond[_market].disputorBond[_disputorAddress] > 0
                ? marketBond[_market].disputorsCount
                : marketBond[_market].disputorsCount.sub(1);
        }
        marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.sub(_amount);
        transferBondFromMarket(_account, _amount);
        emit BondTransferredFromMarketBondToUser(_market, _account, _amount);
    }

    function sendOpenDisputeBondFromMarketToDisputor(
        address _market,
        address _account,
        uint _amount
    ) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(marketManager.isActiveMarket(_market), "Invalid address");
        require(
            _amount <= marketBond[_market].totalMarketBond && _amount <= marketBond[_market].disputorsTotalBond,
            "Exceeds bond"
        );
        require(
            marketBond[_market].disputorsCount > 0 && marketBond[_market].disputorBond[_account] >= _amount,
            "Already claimed"
        );
        marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.sub(_amount);
        marketBond[_market].disputorBond[_account] = marketBond[_market].disputorBond[_account].sub(_amount);
        marketBond[_market].disputorsTotalBond = marketBond[_market].disputorsTotalBond.sub(_amount);
        marketBond[_market].disputorsCount = marketBond[_market].disputorBond[_account] > 0
            ? marketBond[_market].disputorsCount
            : marketBond[_market].disputorsCount.sub(1);
        transferBondFromMarket(_account, _amount);
        emit BondTransferredFromMarketBondToUser(_market, _account, _amount);
    }

    function issueBondsBackToCreatorAndResolver(address _market) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(marketManager.isActiveMarket(_market), "Invalid address");
        uint totalIssuedBack;
        if (marketBond[_market].totalMarketBond >= marketBond[_market].creatorBond.add(marketBond[_market].resolverBond)) {
            marketBond[_market].totalMarketBond = marketBond[_market].totalMarketBond.sub(
                marketBond[_market].creatorBond.add(marketBond[_market].resolverBond)
            );
            if (
                marketManager.creatorAddress(_market) != marketManager.resolverAddress(_market) &&
                marketBond[_market].creatorBond > 0
            ) {
                totalIssuedBack = marketBond[_market].creatorBond;
                marketBond[_market].creatorBond = 0;
                transferBondFromMarket(marketManager.creatorAddress(_market), totalIssuedBack);
                emit BondTransferredFromMarketBondToUser(_market, marketManager.creatorAddress(_market), totalIssuedBack);
            }
            if (marketBond[_market].resolverBond > 0) {
                totalIssuedBack = marketBond[_market].resolverBond;
                marketBond[_market].resolverBond = 0;
                transferBondFromMarket(marketManager.resolverAddress(_market), totalIssuedBack);
                emit BondTransferredFromMarketBondToUser(_market, marketManager.resolverAddress(_market), totalIssuedBack);
            }
        }
    }

    function transferCreatorToResolverBonds(address _market) external onlyOracleCouncilManagerAndOwner nonReentrant {
        require(marketManager.isActiveMarket(_market), "Invalid address");
        require(marketBond[_market].creatorBond > 0, "Creator bond 0");
        marketBond[_market].resolverBond = marketBond[_market].creatorBond;
        marketBond[_market].creatorBond = 0;
        emit BondTransferredFromCreatorToResolver(_market, marketBond[_market].resolverBond);
    }

    function transferToMarket(address _account, uint _amount) external whenNotPaused {
        require(marketManager.isActiveMarket(msg.sender), "Not active market.");
        marketFunds[msg.sender] = marketFunds[msg.sender].add(_amount);
        if (address(stakingThales) != address(0)) {
            stakingThales.updateVolume(_account, _amount);
        }
        transferToMarketBond(_account, _amount);
    }

    function transferFromMarket(address _account, uint _amount) external whenNotPaused {
        require(marketManager.isActiveMarket(msg.sender), "Not active market.");
        require(marketFunds[msg.sender] >= _amount, "Low funds.");
        marketFunds[msg.sender] = marketFunds[msg.sender].sub(_amount);
        transferBondFromMarket(_account, _amount);
    }

    function transferToMarketBond(address _account, uint _amount) internal whenNotPaused {
        IERC20Upgradeable(marketManager.paymentToken()).safeTransferFrom(_account, address(this), _amount);
    }

    function transferBondFromMarket(address _account, uint _amount) internal whenNotPaused {
        IERC20Upgradeable(marketManager.paymentToken()).safeTransfer(_account, _amount);
    }

    function setMarketManager(address _managerAddress) external onlyOwner {
        require(_managerAddress != address(0), "Invalid OC");
        marketManager = IExoticPositionalMarketManager(_managerAddress);
        emit NewManagerAddress(_managerAddress);
    }

    function setStakingThalesContract(address _stakingThales) external onlyOwner {
        require(_stakingThales != address(0), "Invalid address");
        stakingThales = IStakingThales(_stakingThales);
        emit NewStakingThalesAddress(_stakingThales);
    }

    modifier onlyOracleCouncilManagerAndOwner() {
        require(
            msg.sender == marketManager.oracleCouncilAddress() ||
                msg.sender == address(marketManager) ||
                msg.sender == owner,
            "Not OC/Manager/Owner"
        );
        require(address(marketManager) != address(0), "Invalid Manager");
        require(marketManager.oracleCouncilAddress() != address(0), "Invalid OC");
        _;
    }

    event CreatorBondSent(address market, address creator, uint amount);
    event ResolverBondSent(address market, address resolver, uint amount);
    event DisputorBondSent(address market, address disputor, uint amount);
    event BondTransferredFromMarketBondToUser(address market, address account, uint amount);
    event NewOracleCouncilAddress(address oracleCouncil);
    event NewManagerAddress(address managerAddress);
    event BondTransferredFromCreatorToResolver(address market, uint amount);
    event NewStakingThalesAddress(address stakingThales);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
    function transferFrom(
        address sender,
        address recipient,
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the `nonReentrant` modifier
 * available, which can be aplied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 */
contract ProxyReentrancyGuard {
    /// @dev counter to allow mutex lock with only one SSTORE operation
    uint256 private _guardCounter;
    bool private _initialized;

    function initNonReentrant() public {
        require(!_initialized, "Already initialized");
        _initialized = true;
        _guardCounter = 1;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Clone of syntetix contract without constructor
contract ProxyOwned {
    address public owner;
    address public nominatedOwner;
    bool private _initialized;
    bool private _transferredAtInit;

    function setOwner(address _owner) public {
        require(_owner != address(0), "Owner address cannot be 0");
        require(!_initialized, "Already initialized, use nominateNewOwner");
        _initialized = true;
        owner = _owner;
        emit OwnerChanged(address(0), _owner);
    }

    function nominateNewOwner(address _owner) external onlyOwner {
        nominatedOwner = _owner;
        emit OwnerNominated(_owner);
    }

    function acceptOwnership() external {
        require(msg.sender == nominatedOwner, "You must be nominated before you can accept ownership");
        emit OwnerChanged(owner, nominatedOwner);
        owner = nominatedOwner;
        nominatedOwner = address(0);
    }

    function transferOwnershipAtInit(address proxyAddress) external onlyOwner {
        require(proxyAddress != address(0), "Invalid address");
        require(!_transferredAtInit, "Already transferred");
        owner = proxyAddress;
        _transferredAtInit = true;
        emit OwnerChanged(owner, proxyAddress);
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }

    function _onlyOwner() private view {
        require(msg.sender == owner, "Only the contract owner may perform this action");
    }

    event OwnerNominated(address newOwner);
    event OwnerChanged(address oldOwner, address newOwner);
}

pragma solidity ^0.8.0;

interface IExoticPositionalMarketManager {
    /* ========== VIEWS / VARIABLES ========== */
    function paused() external view returns (bool);
    function getActiveMarketAddress(uint _index) external view returns(address);
    function getActiveMarketIndex(address _marketAddress) external view returns(uint);
    function isActiveMarket(address _marketAddress) external view returns(bool);
    function numberOfActiveMarkets() external view returns(uint);
    function getMarketBondAmount(address _market) external view returns (uint);
    function maximumPositionsAllowed() external view returns(uint);
    function paymentToken() external view returns(address);
    function owner() external view returns(address);
    function thalesBonds() external view returns(address);
    function oracleCouncilAddress() external view returns(address);
    function safeBoxAddress() external view returns(address);
    function creatorAddress(address _market) external view returns(address);
    function resolverAddress(address _market) external view returns(address);
    function isPauserAddress(address _pauserAddress) external view returns(bool);
    function safeBoxPercentage() external view returns(uint);
    function creatorPercentage() external view returns(uint);
    function resolverPercentage() external view returns(uint);
    function withdrawalPercentage() external view returns(uint);
    function pDAOResolveTimePeriod() external view returns(uint);
    function claimTimeoutDefaultPeriod() external view returns(uint);
    function maxOracleCouncilMembers() external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);
    function disputeStringLengthLimit() external view returns(uint);
    function cancelledByCreator(address _market) external view returns(bool);
    function withdrawalTimePeriod() external view returns(uint);    
    function maxAmountForOpenBidPosition() external view returns(uint);    
    function maxFinalWithdrawPercentage() external view returns(uint);    

    function createExoticMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        string[] memory _positionPhrases
    ) external;
    
    function createCLMarket(
        string memory _marketQuestion,
        string memory _marketSource,
        uint _endOfPositioning,
        uint _fixedTicketPrice,
        bool _withdrawalAllowed,
        uint[] memory _tags,
        uint _positionCount,
        uint[] memory _positionsOfCreator,
        string[] memory _positionPhrases
    ) external;
    
    function disputeMarket(address _marketAddress, address disputor) external;
    function resolveMarket(address _marketAddress, uint _outcomePosition) external;
    function resetMarket(address _marketAddress) external;
    function cancelMarket(address _market) external ;
    function closeDispute(address _market) external ;
    function setBackstopTimeout(address _market) external; 
    function sendMarketBondAmountTo(address _market, address _recepient, uint _amount) external;
    function addPauserAddress(address _pauserAddress) external;
    function removePauserAddress(address _pauserAddress) external;
    function sendRewardToDisputor(address _market, address _disputorAddress, uint amount) external;
    function issueBondsBackToCreatorAndResolver(address _marketAddress) external ;


}

pragma solidity ^0.8.0;

interface IExoticPositionalMarket {
    /* ========== VIEWS / VARIABLES ========== */
    function isMarketCreated() external view returns (bool);
    function creatorAddress() external view returns (address);
    function resolverAddress() external view returns (address);
    function totalBondAmount() external view returns(uint);

    function marketQuestion() external view returns(string memory);
    function marketSource() external view returns(string memory);
    function positionPhrase(uint index) external view returns(string memory);

    function getTicketType() external view returns(uint);
    function positionCount() external view returns(uint);
    function endOfPositioning() external view returns(uint);
    function resolvedTime() external view returns(uint);
    function fixedTicketPrice() external view returns(uint);
    function creationTime() external view returns(uint);
    function winningPosition() external view returns(uint);
    function getTags() external view returns(uint[] memory);
    function getTotalPlacedAmount() external view returns(uint);
    function getTotalClaimableAmount() external view returns(uint);
    function getPlacedAmountPerPosition(uint index) external view returns(uint);
    function fixedBondAmount() external view returns(uint);
    function disputePrice() external view returns(uint);
    function safeBoxLowAmount() external view returns(uint);
    function arbitraryRewardForDisputor() external view returns(uint);
    function backstopTimeout() external view returns(uint);
    function disputeClosedTime() external view returns(uint);
    function totalUsersTakenPositions() external view returns(uint);
    
    function withdrawalAllowed() external view returns(bool);
    function disputed() external view returns(bool);
    function resolved() external view returns(bool);
    function canUsersPlacePosition() external view returns (bool);
    function canMarketBeResolvedByPDAO() external view returns(bool);
    function canMarketBeResolved() external view returns (bool);
    function canUsersClaim() external view returns (bool);
    function isMarketCancelled() external view returns (bool);
    function paused() external view returns (bool);
    function canCreatorCancelMarket() external view returns (bool);
    function getAllFees() external view returns (uint, uint, uint, uint);
    function canIssueFees() external view returns (bool);
    function noWinners() external view returns (bool);


    function transferBondToMarket(address _sender, uint _amount) external;
    function resolveMarket(uint _outcomePosition, address _resolverAddress) external;
    function cancelMarket() external;
    function resetMarket() external;
    function claimWinningTicketOnBehalf(address _user) external;
    function openDispute() external;
    function closeDispute() external;
    function setBackstopTimeout(uint _timeoutPeriod) external;


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16;

interface IStakingThales {
    function updateVolume(address account, uint amount) external;
    
    /* ========== VIEWS / VARIABLES ========== */
    function totalStakedAmount() external view returns (uint);

    function stakedBalanceOf(address account) external view returns (uint); 

    function currentPeriodRewards() external view returns (uint);

    function currentPeriodFees() external view returns (uint);

    function getLastPeriodOfClaimedRewards(address account) external view returns (uint);

    function getRewardsAvailable(address account) external view returns (uint);

    function getRewardFeesAvailable(address account) external view returns (uint);

    function getAlreadyClaimedRewards(address account) external view returns (uint);

    function getAlreadyClaimedFees(address account) external view returns (uint);

    function getContractRewardFunds() external view returns (uint);

    function getContractFeeFunds() external view returns (uint);

    
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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