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

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC20.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract Fees is Ownable {
    uint256 public defaultFee;

    constructor(uint256 defaultFee_) {
        defaultFee = defaultFee_;
    }

    struct FeeTokenData {
        uint256 minBalance;
        uint256 fee;
    }

    //mappings
    //strategyId => feeCollector
    mapping(uint256 => address) public feeCollector;

    //strategyId => feeToken => FeeTokenData
    mapping(uint256 => mapping(address => FeeTokenData)) public feeTokenMap;

    //strategyId => depositStatus
    mapping(uint256 => bool) public depositStatus;

    //strategyId => tokenAddress => status
    mapping(uint256 => mapping(address => bool))
        public whitelistedDepositCurrencies;

    //read functions

    //calculates expected fee for specified parameters
    function calcFee(
        uint256 strategyId,
        address user,
        address feeToken
    ) public view returns (uint256) {
        FeeTokenData memory feeData = feeTokenMap[strategyId][feeToken];
        if (
            feeData.minBalance > 0 &&
            IERC20(feeToken).balanceOf(user) >= feeData.minBalance
        ) {
            return feeData.fee;
        }
        return defaultFee;
    }

    //write functions

    //sets fee benefits if user holds token
    function setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) external onlyOwner {
        _setTokenFee(strategyId, feeToken, minBalance, fee);
    }

    //convenience method to set fees for multiple tokens
    function setTokenMulti(
        uint256 strategyId,
        address[] calldata feeTokens,
        uint256[] calldata minBalance,
        uint256[] calldata fee
    ) external onlyOwner {
        require(
            feeTokens.length == minBalance.length &&
                minBalance.length == fee.length,
            "setMulti: length mismatch"
        );
        for (uint256 i = 0; i < feeTokens.length; i++) {
            _setTokenFee(strategyId, feeTokens[i], minBalance[i], fee[i]);
        }
    }

    function setDepositStatus(uint256 strategyId, bool status)
        external
        onlyOwner
    {
        depositStatus[strategyId] = status;
    }

    function setFeeCollector(uint256 strategyId, address newFeeCollector)
        external
        onlyOwner
    {
        feeCollector[strategyId] = newFeeCollector;
    }

    function setDefaultFee(uint256 newDefaultFee) external onlyOwner {
        require(newDefaultFee<1000, "setDefaultFee: exceed 1%");
        defaultFee = newDefaultFee;
    }

    function toggleWhitelistTokens(
        uint256 strategyId,
        address[] calldata tokens,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < tokens.length; i++) {
            whitelistedDepositCurrencies[strategyId][tokens[i]] = state;
        }
    }

    //internal functions

    function _setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) internal {
        feeTokenMap[strategyId][feeToken] = FeeTokenData({
            minBalance: minBalance,
            fee: fee
        });
    }
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function decimals() external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}