// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IDistributionFactory.sol";
import "./Distribution.sol";

/// @title Create new contracts
contract DistributionFactory is IDistributionFactory, Ownable {
    address[] public contracts;

    /// @notice Return total sales contract count
    function getContractsCount() external view override returns (uint256) {
        return contracts.length;
    }

    /**
     * @notice Create new contract
     * @param _token ERC20 token for distribution
     * @param _startsAt Distribution start timestamp, seconds
     * @param _contractOwner New owner of Distribution contract
     */
    function create(address _token, uint64 _startsAt, address _contractOwner) external override onlyOwner {
        Distribution _contract = new Distribution(_token, _startsAt);
        _contract.transferOwnership(_contractOwner);

        contracts.push(address(_contract));

        emit ContractCreated(address(_contract));
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
interface IDistributionFactory {
    event ContractCreated(address newContractAddress);

    /// @notice Return total contracts count
    function getContractsCount() external view returns (uint256);

    /**
     * @notice Create new contract
     * @param _token ERC20 token for distribution
     * @param _startsAt Distribution start timestamp, seconds
     * @param _contractOwner New owner of Distribution contract
     */
    function create(address _token, uint64 _startsAt, address _contractOwner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

import "./interfaces/IDistribution.sol";

contract Distribution is IDistribution, Ownable {
    using Math for uint256;

    /// @notice Timestamp when distribution begins
    uint64 public startsAt;
    /// @notice Token for distribution
    IERC20 public token;
    /// @notice Total distribution amount
    uint256 public totalDistributionAmount;
    /// @notice Address => AddressInfo
    mapping(address => AddressInfo) public addressInfo;


    constructor(address _token, uint64 _startsAt) {
        require(_startsAt > block.timestamp, "Dist: invalid timestamp");

        startsAt = _startsAt;
        token = IERC20(_token);
    }

    /**
     * @notice Add distribution info for each input address. `Cliff` should be included inside `interval`
     * @notice All parameters must be set before distribution begins
     * @param _addresses List of addresses
     * @param _amounts List with tokens amount for each address, wei
     * @param _intervals List with distribution interval for each address, timestamp
     * @param _cliffs List with cliff interval for each address, timestamp
     */
    function addDistributionInfo(
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint64[] calldata _intervals,
        uint64[] calldata _cliffs
    ) external onlyOwner {
        require(block.timestamp < startsAt, "Dist: vesting begun");

        uint256 _totalDistributionAmount = totalDistributionAmount;
        for (uint256 _i; _i < _addresses.length; _i++) {
            AddressInfo storage _addressInfo = addressInfo[_addresses[_i]];

            if (_amounts[_i] == 0) {
                _totalDistributionAmount -= _addressInfo.amount;
                delete _addressInfo.amount;

                continue;
            }

            require(_cliffs[_i] < _intervals[_i], "Dist: invalid interval");

            _totalDistributionAmount = _totalDistributionAmount + _amounts[_i] - _addressInfo.amount;

            _addressInfo.amount = _amounts[_i];
            _addressInfo.interval = _intervals[_i];
            _addressInfo.cliff = _cliffs[_i];
        }

        totalDistributionAmount = _totalDistributionAmount;

        emit DistributionAddressesEdited(_addresses);
    }

    /**
     * @notice Sender withdraw tokens for `_recipient`
     * @param _recipient Address
     */
    function withdraw(address _recipient) external {
        uint256 _amount = addressInfo[_recipient].amount;
        require(_amount > 0, "Dist: nothing to withdraw (1)");

        uint256 _cliff = addressInfo[_recipient].cliff;
        uint256 _startsAt = startsAt + _cliff;
        require(block.timestamp > _startsAt, "Dist: pending distribution");

        uint256 _paid = addressInfo[_recipient].paid;
        uint256 _distributionInterval = addressInfo[_recipient].interval - _cliff;
        uint256 _toPay = _amount * (block.timestamp - _startsAt) / _distributionInterval;
        _toPay = (_toPay - _paid).min(_amount - _paid);
        require(_toPay > 0, "Dist: nothing to withdraw (2)");

        addressInfo[_recipient].paid = _paid + _toPay;
        totalDistributionAmount -= _toPay;
        token.transfer(_recipient, _toPay);

        emit Withdrawn(_recipient, _toPay);
    }

    /**
     * @notice Withdrawal of excess tokens
     * @param _token Token address
     * @param _amount Token amount
     * @param _to Recipient address
     */
    function withdrawERC20(IERC20 _token, uint256 _amount, address _to) external onlyOwner {
        if (_token == token) {
            _amount = _amount.min(_token.balanceOf(address(this)) - totalDistributionAmount);
        } else {
            _amount = _amount.min(_token.balanceOf(address(this)));
        }

        require(_amount > 0, "Dist: nothing to withdraw");

        IERC20(_token).transfer(_to, _amount);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDistribution {
    event DistributionAddressesEdited(address[] addresses);
    event Withdrawn(address recipient, uint256 amount);

    struct AddressInfo {
        uint256 amount;
        uint256 paid;
        uint64 interval;
        uint64 cliff;
    }

    /**
     * @notice Add distribution info for each input address. `Cliff` should be included inside `interval`
     * @notice All parameters must be set before distribution begins
     * @param _addresses List of addresses
     * @param _amounts List with tokens amount for each address, wei
     * @param _intervals List with distribution interval for each address, timestamp
     * @param _cliffs List with cliff interval for each address, timestamp
     */
    function addDistributionInfo(
        address[] calldata _addresses,
        uint256[] calldata _amounts,
        uint64[] calldata _intervals,
        uint64[] calldata _cliffs
    ) external;

    /**
     * @notice Sender withdraw tokens for `_recipient`
     * @param _recipient Address
     */
    function withdraw(address _recipient) external;

    /**
     * @notice Withdrawal of excess tokens
     * @param _token Token address
     * @param _amount Token amount
     * @param _to Recipient address
     */
    function withdrawERC20(IERC20 _token, uint256 _amount, address _to) external;
}