// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ITokenSaleFactory.sol";
import "./TokenSale.sol";

/// @title TokenSaleFactory contract.
contract TokenSaleFactory is ITokenSaleFactory, Ownable {
    address[] public contracts;

    /// @notice Return total sales contract count.
    function getContractsCount() external view override returns (uint256) {
        return contracts.length;
    }

    /// @notice Create new TokenSale contract.
    /// @param _buyStartTimestamp Timestamp.
    /// @param _withdrawTimestamp Timestamp.
    function create(
        uint64 _buyStartTimestamp,
        uint64 _withdrawTimestamp
    ) external override onlyOwner {
        TokenSale _contract = new TokenSale(_buyStartTimestamp, _withdrawTimestamp);
        _contract.transferOwnership(msg.sender);

        contracts.push(address(_contract));

        emit TokenSaleCreated(address(_contract));
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @title Interface ITokenSaleFactory for TokenSaleFactory contract.
interface ITokenSaleFactory {
    event TokenSaleCreated(address newContractAddress);

    /// @notice Return total sales contract count.
    function getContractsCount() external view returns (uint256);

    /// @notice Create new TokenSale contract.
    /// @param _buyStartTimestamp Timestamp.
    /// @param _withdrawTimestamp Timestamp.
    function create(
        uint64 _buyStartTimestamp,
        uint64 _withdrawTimestamp
    ) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./interfaces/ITokenSale.sol";

/// @title TokenSale contract.
contract TokenSale is ITokenSale, Ownable, ReentrancyGuard {
    using Math for uint256;

    /// @dev START WHITELISTING SETTING
    bool public whitelistIsEnable;
    mapping(address => bool) public whitelistIsAddressOn;
    /// @dev END WHITELISTING SETTING

    /// @dev START TIMESTAMP LIMITS
    uint64 public buyStartTimestamp;
    uint64 public buyEndTimestamp;
    uint64 public withdrawTimestamp;
    /// @dev END TIMESTAMP LIMITS

    /// @dev START EXCHANGE INFO
    IERC20Metadata public paymentToken;
    IERC20Metadata public exchangeToken;
    uint256 public exchangeRatio;
    /// @dev END EXCHANGE INFO

    /// @dev START TIER INFO
    ITier public tierContract;
    uint64[] public tiersInTokenSale;
    mapping(uint64 => uint64) public tierIdToBuyStartTimestamp;
    /// @dev END TIER INFO

    /// @dev START POOL AND LIMIT SETTING
    uint256 public allocatedInPool;
    uint256 public boughtInPool;
    mapping(uint64 => uint256) public tierIdToAddressBuyLimit;
    mapping(address => uint256) public addressToBought;
    mapping(address => bool) public hasWithdrawn;
    /// @dev END POOL AND LIMIT SETTING

    /// @dev START CONTRACT VIEW VARIABLE
    address[] public participatingAddresses;
    uint256 public totalWithdrawnAmount;
    /// @dev END CONTRACT VIEW VARIABLE

    modifier beforeWithdrawal() {
        require(block.timestamp < withdrawTimestamp, "TokenSale: withdrawal has begun.");
        _;
    }

    modifier beforeSales() {
        require(block.timestamp < buyStartTimestamp, "TokenSale: sales have started.");
        _;
    }

    /// @param _buyStartTimestamp Timestamp.
    /// @param _withdrawTimestamp Timestamp.
    constructor(uint64 _buyStartTimestamp, uint64 _withdrawTimestamp) {
        require(block.timestamp < _buyStartTimestamp, "TokenSale: invalid buy start timestamp.");
        require(_buyStartTimestamp < _withdrawTimestamp, "TokenSale: invalid withdraw timestamp.");

        buyStartTimestamp = _buyStartTimestamp;
        withdrawTimestamp = _withdrawTimestamp;
    }

    /// @notice Set buy end timestamp.
    /// @param _buyEndTimestamp Timestamp.
    function setBuyEndTimestamp(uint64 _buyEndTimestamp) external override onlyOwner beforeWithdrawal {
        uint256 _tiersCount = tiersInTokenSale.length;
        if (_tiersCount > 0) require(_buyEndTimestamp > tierIdToBuyStartTimestamp[tiersInTokenSale[_tiersCount - 1]],
            "TokenSale: buy end timestamp should be more than last tier buy start timestamp.");
        require(_buyEndTimestamp < withdrawTimestamp,
            "TokenSale: buy end timestamp should be less than withdraw timestamp.");

        buyEndTimestamp = _buyEndTimestamp;
    }

    /// @notice Set actual tiers for sale and there start timestamp.
    /// @param _tierContract Address.
    /// @param _tiersInTokenSale Tier numbers.
    /// @param _tierToBuyStartTimestamp Timestamps.
    function setTiers(
        ITier _tierContract,
        uint64[] calldata _tiersInTokenSale,
        uint64[] calldata _tierToBuyStartTimestamp
    ) external override onlyOwner beforeWithdrawal {
        require(_tiersInTokenSale.length > 0, "TokenSale: tiers is not set.");
        require(_tiersInTokenSale.length == _tierToBuyStartTimestamp.length, "TokenSale: different array length.");
        require(address(_tierContract) != address(0), "TokenSale: invalid tier contract address.");

        require(_tierToBuyStartTimestamp[0] < buyEndTimestamp,
            "TokenSale: invalid buy start timestamp for tiers (2).");
        require(_tierToBuyStartTimestamp[_tiersInTokenSale.length - 1] == buyStartTimestamp,
            "TokenSale: different buy start timestamp.");

        for (uint256 i = 0; i < _tiersInTokenSale.length; i++) {
            if (i > 0) {
                require(_tierToBuyStartTimestamp[i - 1] > _tierToBuyStartTimestamp[i],
                    "TokenSale: invalid buy start timestamp for tiers (1).");
                require(_tiersInTokenSale[i - 1] < _tiersInTokenSale[i],
                    "TokenSale: invalid tier order.");
            }

            tierIdToBuyStartTimestamp[_tiersInTokenSale[i]] = _tierToBuyStartTimestamp[i];
        }

        tierContract = _tierContract;
        tiersInTokenSale = _tiersInTokenSale;

        emit TiersInfoChanged(_tiersInTokenSale, _tierToBuyStartTimestamp);
    }

    /// @notice Setup exchange token and payment token.
    /// @param _paymentToken Address.
    /// @param _exchangeToken Address.
    function setPaymentAndExchangeToken(
        IERC20Metadata _paymentToken,
        IERC20Metadata _exchangeToken
    ) external override onlyOwner beforeSales {
        require(address(_exchangeToken) != address(0), "TokenSale: invalid exchange contract address.");

        paymentToken = _paymentToken;
        exchangeToken = _exchangeToken;

        emit PaymentTokenChanged(address(_paymentToken));
        emit ExchangeTokenChanged(address(_exchangeToken));
    }

    /// @notice Setup exchange ratio.
    /// @param _exchangeRatio Exchange ratio. If equal 2.5, 1 PaymentToken = 2.5 Exchange token. In decimals 2.5 * 10^27
    function setExchangeRatio(uint256 _exchangeRatio) external override onlyOwner beforeSales {
        require(_exchangeRatio != 0, "TokenSaleERC20: exchange ratio can not be a zero.");

        exchangeRatio = _exchangeRatio;

        emit ExchangeRationChanged(exchangeRatio);
    }

    /// @notice Add tokens to allocation pool before withdrawing.
    /// @param _amount Wei.
    function addToPool(uint256 _amount) external override onlyOwner beforeWithdrawal {
        allocatedInPool += _amount;

        emit PoolIncreased(_amount);
    }

    /// @notice Set address buy limit for each tier.
    /// @param _limits Wei.
    function setAddressLimits(uint256[] calldata _limits) external override onlyOwner beforeWithdrawal {
        require(_limits.length == tiersInTokenSale.length, "TokenSale: different array length.");

        for (uint256 i = 0; i < _limits.length; i++) {
            tierIdToAddressBuyLimit[tiersInTokenSale[i]] = _limits[i];
        }

        emit AddressLimitsChanged(_limits);
    }

    /// @notice Add or remove addresses from whitelist.
    /// @param _addresses Addresses.
    /// @param _isAdd Switch to TRUE for adding to whitelist and to FALSE for remove.
    function changeWhitelistAddresses(address[] calldata _addresses, bool _isAdd) external override onlyOwner {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelistIsAddressOn[_addresses[i]] = _isAdd;
        }
    }

    /// @notice Change whitelisting status for sale.
    function changeWhitelistStatus() external override onlyOwner {
        whitelistIsEnable = !whitelistIsEnable;
    }

    /// @notice Buy exchange tokens.
    /// @param _amount Wei.
    function buy(uint256 _amount) external payable override nonReentrant {
        require(_amount > 0, "TokenSale: amount is zero.");
        require(exchangeRatio > 0, "TokenSale: exchange ration is't set.");

        require(!whitelistIsEnable || whitelistIsAddressOn[msg.sender], "TokenSale: you aren't in whitelist.");

        uint64 _tierId = _getTierId();
        require(tierIdToBuyStartTimestamp[_tierId] <= block.timestamp,
            "TokenSale: the sale for your tier has not yet begun.");
        require(block.timestamp <= buyEndTimestamp, "TokenSale: sale is over.");

        // START recalculate the amount based on the address limit
        uint256 _addressLimit = tierIdToAddressBuyLimit[_tierId];
        uint256 _bought = addressToBought[msg.sender];
        if (_bought == 0) participatingAddresses.push(msg.sender);
        _amount = Math.min(_amount, _addressLimit - _bought);
        require(_amount > 0, "TokenSale: address limit reached.");
        // END recalculate the amount based on the address limit

        // START recalculate the amount based on pool limit
        uint256 _allocatedInPool = allocatedInPool;
        uint256 _boughtInPool = boughtInPool;
        _amount = Math.min(_amount, _allocatedInPool - _boughtInPool);
        require(_amount > 0, "TokenSale: sale limit reached.");
        // END recalculate the amount based on pool limit

        // START consider the decimals of the tokens
        (_amount,) = _getAmountConsideringDecimals(_amount);
        // END consider the decimals of the tokens

        // START change storage
        addressToBought[msg.sender] += _amount;
        boughtInPool += _amount;
        // END change storage

        _paymentProcess(_amount);
    }

    /// @notice Withdraw exchange tokens.
    function withdraw() external override {
        require(withdrawTimestamp <= block.timestamp, "TokenSale: withdrawal is not yet available.");
        require(!hasWithdrawn[msg.sender], "TokenSale: this address already withdraw.");

        uint256 _bought = addressToBought[msg.sender];
        require(_bought > 0, "TokenSale: the withdraw amount is zero.");

        uint256 _toWithdraw;
        (,_toWithdraw) = _getAmountConsideringDecimals(_bought);

        totalWithdrawnAmount += _toWithdraw;
        hasWithdrawn[msg.sender] = true;

        exchangeToken.transfer(msg.sender, _toWithdraw);

        emit Withdrawn(_toWithdraw);
    }

    /// @notice Return recalculate payable amount and potential exchange amount.
    /// @param _amount Payable token amount. Wei.
    function getPotentialExchangeAmount(uint256 _amount) external view override returns (uint256, uint256) {
        return _getAmountConsideringDecimals(_amount);
    }

    /// @notice Withdraw rest of rewards to address
    /// @param _amount Amount to withdraw
    /// @param _address Token recipient address
    function withdrawRestExchangeToken(uint256 _amount, address _address) external override onlyOwner {
        IERC20 _exchangeToken = exchangeToken;

        (,uint256 _shouldBeWithdrawn) = _getAmountConsideringDecimals(boughtInPool);
        uint256 _balance = _exchangeToken.balanceOf(address(this));
        require(_balance >= _shouldBeWithdrawn - totalWithdrawnAmount, "TokenSale: nothing to withdraw (1).");

        uint256 _availableToWithdrawn = _balance - (_shouldBeWithdrawn - totalWithdrawnAmount);
        _amount = _availableToWithdrawn < _amount ? _availableToWithdrawn : _amount;
        require(_amount > 0, "TokenSale: nothing to withdraw (2).");

        _exchangeToken.transfer(_address, _amount);
    }

    /// @notice Transfer stuck tokens.
    /// @param _token Address.
    /// @param _to Address.
    /// @param _amount Wei.
    function withdrawStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        require(address(_token) != address(exchangeToken), "TokenSale: transfer is not possible for this contract.");
        _token.transfer(_to, _amount);
    }

    /// @notice Withdraw native token from contract.
    /// @param _to Address.
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /// @notice Return first tier ID that address has and that participate in sale.
    function _getTierId() private view returns (uint64) {
        uint256 _tiersCount = tiersInTokenSale.length;
        ITier _tierContract = tierContract;

        for (uint256 i = _tiersCount; i > 0; i--) {
            uint64 _tierId = tiersInTokenSale[i - 1];

            if (_tierContract.hasTier(_tierId, msg.sender)) return _tierId;
        }

        revert("TokenSaleBase: address can't participate in sale.");
    }

    /// @notice Return TRUE if payment is native.
    function _isPaymentTokenNative() private view returns (bool) {
        return address(0) == address(paymentToken);
    }

    /// @notice Transfer ERC20 or native token from sender to contract.
    /// @notice Native token should have 18 decimals!!!!
    function _paymentProcess(uint256 _amount) private {
        if (_isPaymentTokenNative()) {
            require(msg.value >= _amount, "TokenSale: insufficient funds for payment.");
            if (msg.value > _amount) payable(msg.sender).transfer(msg.value - _amount);
        } else {
            paymentToken.transferFrom(msg.sender, address(this), _amount);
        }

        emit Bought(_amount);
    }

    /// @notice Recalculate input amount considering decimals, return exchange amount.
    function _getAmountConsideringDecimals(uint256 _amount) private view returns (uint256, uint256) {
        uint256 _paymentDecimals = _isPaymentTokenNative() ? 18 : paymentToken.decimals();
        uint256 _exchangeDecimals = exchangeToken.decimals();
        uint256 _exchangeAmount = 0;

        if (_exchangeDecimals >= _paymentDecimals) {
            _exchangeAmount = (_amount * exchangeRatio * 10**(_exchangeDecimals - _paymentDecimals)) / _getDecimals();
        } else {
            uint256 _paymentAmountToExchange = _amount / 10**(_paymentDecimals - _exchangeDecimals);
            _amount = _paymentAmountToExchange * 10**(_paymentDecimals - _exchangeDecimals);
            _exchangeAmount = (_paymentAmountToExchange * exchangeRatio) / _getDecimals();
        }

        return (_amount, _exchangeAmount);
    }

    function _getDecimals() private pure returns (uint256) {
        return 10**27;
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
// OpenZeppelin Contracts v4.4.1 (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./ITier.sol";

/// @title Interface ITokenSale for TokenSale contract.
interface ITokenSale {
    event TiersInfoChanged(uint64[] newTiersInTokenSale, uint64[] newTierToBuyStartTimestamp);
    event PaymentTokenChanged(address newPaymentToken);
    event ExchangeTokenChanged(address newExchangeToken);
    event ExchangeRationChanged(uint256 newExchangeRatio);
    event PoolIncreased(uint256 increaseValue);
    event AddressLimitsChanged(uint256[] newLimits);
    event Bought(uint256 amount);
    event Withdrawn(uint256 amount);

    /// @notice Set buy end timestamp.
    /// @param _buyEndTimestamp Timestamp.
    function setBuyEndTimestamp(uint64 _buyEndTimestamp) external;

    /// @notice Set actual tiers for sale and there start timestamp.
    /// @param _tierContract Address.
    /// @param _tiersInTokenSale Tier numbers.
    /// @param _tierToBuyStartTimestamp Timestamps.
    function setTiers(
        ITier _tierContract,
        uint64[] calldata _tiersInTokenSale,
        uint64[] calldata _tierToBuyStartTimestamp
    ) external;

    /// @notice Setup exchange token and payment token.
    /// @param _paymentToken Address.
    /// @param _exchangeToken Address.
    function setPaymentAndExchangeToken(
        IERC20Metadata _paymentToken,
        IERC20Metadata _exchangeToken
    ) external;

    /// @notice Setup exchange ratio.
    /// @param _exchangeRatio Exchange ratio. If equal 2.5, 1 PaymentToken = 2.5 Exchange token. In decimals 2.5 * 10^27
    function setExchangeRatio(uint256 _exchangeRatio) external;

    /// @notice Add tokens to allocation pool before withdrawing.
    /// @param _amount Wei.
    function addToPool(uint256 _amount) external;

    /// @notice Set address buy limit for each tier.
    /// @param _limits Wei.
    function setAddressLimits(uint256[] calldata _limits) external;

    /// @notice Add or remove addresses from whitelist.
    /// @param _addresses Addresses.
    /// @param _isAdd Switch to TRUE for adding to whitelist and to FALSE for remove.
    function changeWhitelistAddresses(address[] calldata _addresses, bool _isAdd) external;

    /// @notice Change whitelisting status for sale.
    function changeWhitelistStatus() external;

    /// @notice Buy exchange tokens.
    /// @param _amount Wei.
    function buy(uint256 _amount) external payable;

    /// @notice Withdraw exchange tokens.
    function withdraw() external;

    /// @notice Return recalculate payable amount and potential exchange amount.
    /// @param _amount Payable token amount. Wei.
    function getPotentialExchangeAmount(uint256 _amount) external view returns (uint256, uint256);

    /// @notice Withdraw rest of rewards to address
    /// @param _amount Amount to withdraw
    /// @param _address Token recipient address
    function withdrawRestExchangeToken(uint256 _amount, address _address) external;

    /// @notice Transfer stuck tokens.
    /// @param _token Address.
    /// @param _to Address.
    /// @param _amount Wei.
    function withdrawStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external;

    /// @notice Withdraw native token from contract.
    /// @param _to Address.
    function withdrawNative(address _to) external;
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./ICompoundRateKeeperV2.sol";

/// @title Tier contract
interface ITier is ICompoundRateKeeperV2 {
    event TierCreated(uint64 id);
    event TierNameChanged(uint64 id, string newName);
    event TierRequiredAmountChanged(uint64 id, uint256 newRequiredAmount);
    event TierStatusChanged(uint64 id, bool newStatus);
    event AddressStaked(address staker, uint256 amount);
    event AddressWithdrawn(address staker, uint256 amount);

    /// @notice Set lock period for stake
    /// @param _lockPeriod Seconds
    function setLockPeriod(uint64 _lockPeriod) external;

    /// @notice Create new tier
    /// @param _amount Required amount. Wei
    function createTier(string calldata _name, uint256 _amount) external;

    /// @notice Update tier name
    /// @param _tierId Tier id
    /// @param _name New name
    function updateTierName(uint64 _tierId, string calldata _name) external;

    /// @notice Update existed tier
    /// @param _tierId Tier id
    /// @param _amount Required amount
    function updateTierRequiredAmount(uint64 _tierId, uint256 _amount) external;

    /// @notice Update tier status
    /// @param _tierId Tier id
    /// @param _status New status
    function updateTierStatus(uint64 _tierId, bool _status) external;

    /// @notice Stake tokens.
    /// @param _amount Staked amount
    function stake(uint256 _amount) external;

    /// @notice Withdraw staked tokens.
    /// @param _amount Withdraw amount
    function withdraw(uint256 _amount) external;

    /// @notice Return max tier number for address
    /// @param _address Address
    function getTierIdByAddress(address _address) external view returns (uint64);

    /// @notice Checks if the address has the requested tier.
    /// @param _tierId Requested tier ID
    /// @param _address Address
    function hasTier(uint64 _tierId, address _address) external view returns (bool);

    /// @notice Return address balance considering the interest at the moment
    function getExistedStakeAmount(address _address) external view returns (uint256);

    /// @notice Add payment tokens to contract address to be spent as rewards.
    /// @param _amount Token amount that will be added to contract as reward
    function supplyRewardPool(uint256 _amount) external;

    /// @notice Get the amount of tokens that should be on the contract if all users withdraw their stakes
    /// @notice at the current time.
    function getCollateralAmount() external view returns (uint256);

    /// @notice Get coefficient. Tokens on the contract / total stake + total reward to be paid
    function monitorSecurityMargin() external view returns (uint256);

    /// @notice Withdraw rest of rewards to address
    /// @param _amount Amount to withdraw
    /// @param _address Token recipient address
    function withdrawRest(uint256 _amount, address _address) external;

    /// @notice Transfer stuck tokens.
    /// @param _token Token contract address
    /// @param _to Receiver address
    /// @param _amount Token amount
    function withdrawStuckERC20(IERC20 _token, address _to, uint256 _amount) external;

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/// @notice Interface for CompoundRateKeeperV2 contract.
interface ICompoundRateKeeperV2 {
    event CapitalizationPeriodChanged(uint256 indexed newCapitalizationPeriod);
    event AnnualPercentChanged(uint256 indexed newAnnualPercent);

    /// @notice Set new capitalization period
    /// @param _capitalizationPeriod Seconds
    function setCapitalizationPeriod(uint32 _capitalizationPeriod) external;

    /// @notice Set new annual percent
    /// @param _annualPercent = 1*10^27 (0% per period), 1.1*10^27 (10% per period), 2*10^27 (100% per period)
    function setAnnualPercent(uint256 _annualPercent) external;

    /// @notice Call this function only when getCompoundRate() or getPotentialCompoundRate() throw error
    /// @notice Update hasMaxRateReached switcher to True
    function emergencyUpdateCompoundRate() external;

    /// @notice Calculate compound rate for this moment.
    function getCompoundRate() external view returns (uint256);

    /// @notice Calculate compound rate at a particular time.
    /// @param _timestamp Seconds
    function getPotentialCompoundRate(uint64 _timestamp) external view returns (uint256);
}