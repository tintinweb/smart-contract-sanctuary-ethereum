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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./interfaces/Action.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BaseVault is Ownable {
    uint256 _transactionFee;
    uint256 _firstDeposit;
    uint256 _minDeposit;
    uint256 _maxDeposit;
    uint256 _maxWithdraw;
    uint256 _targetReservesLevel;
    uint256 _onchainServiceFeeRate;
    uint256 _offchainServiceFeeRate;

    // event SetTransactionFeeWeekdayRate(uint256 transactionFeeWeekdayRate);
    // event SetTransactionFeeWeekendRate(uint256 transactionFeeWeekendRate);

    event SetTransactionFee(uint256 transactionFee);
    event SetFirsetDeposit(uint256 firstDeposit);
    event SetMinDeposit(uint256 minDeposit);
    event SetMaxDeposit(uint256 maxDeposit);
    event SetMaxWithdraw(uint256 maxWithdraw);
    event SetTargetReservesLevel(uint256 targetReservesLevel);
    event SetOnchainServiceFeeRate(uint256 onchainServiceFeeRate);
    event SetOffchainServiceFeeRate(uint256 offchainServiceFeeRate);
    event SetFirstDeposit(uint256 firstDeposit);

    constructor(
        uint256 transactionFee,
        uint256 firstDeposit,
        uint256 minDeposit,
        uint256 maxDeposit,
        uint256 maxWithdraw,
        uint256 targetReservesLevel,
        uint256 onchainServiceFeeRate,
        uint256 offchainServiceFeeRate
    ) {
        // _params.transactionFeeWeekdayRate = params.transactionFeeWeekdayRate;
        // _params.transactionFeeWeekendRate = params.transactionFeeWeekendRate;
        _transactionFee = transactionFee;
        _firstDeposit = firstDeposit;
        _minDeposit = minDeposit;
        _maxDeposit = maxDeposit;
        _maxWithdraw = maxWithdraw;
        _targetReservesLevel = targetReservesLevel;
        _onchainServiceFeeRate = onchainServiceFeeRate;
        _offchainServiceFeeRate = offchainServiceFeeRate;
    }

    // function setTransactionFeeWeekdayRate(uint256 transactionFeeWeekdayRate) onlyAdminOrOperator whenPaused external {
    //     _params.transactionFeeWeekdayRate =  transactionFeeWeekdayRate;
    //     emit SetTransactionFeeWeekdayRate(transactionFeeWeekdayRate);
    // }

    // function setTransactionFeeWeekendRate(uint256 transactionFeeWeekendRate) onlyAdminOrOperator whenPaused external {
    //     _params.transactionFeeWeekendRate =  transactionFeeWeekendRate;
    //     emit SetTransactionFeeWeekendRate(transactionFeeWeekendRate);
    // }

    function setTransactionFee(uint256 transactionFee) external onlyOwner {
        _transactionFee = transactionFee;
        emit SetTransactionFee(transactionFee);
    }

    function setFirstDeposit(uint256 firstDeposit) external onlyOwner {
        _firstDeposit = firstDeposit;
        emit SetFirstDeposit(firstDeposit);
    }

    function setMinDeposit(uint256 minDeposit) external onlyOwner {
        _minDeposit = minDeposit;
        emit SetMinDeposit(minDeposit);
    }

    function setMaxDeposit(uint256 maxDeposit) external onlyOwner {
        _maxDeposit = maxDeposit;
        emit SetMaxDeposit(maxDeposit);
    }

    function setMaxWithdraw(uint256 maxWithdraw) external onlyOwner {
        _maxWithdraw = maxWithdraw;
        emit SetMaxWithdraw(maxWithdraw);
    }

    function setTargetReservesLevel(
        uint256 targetReservesLevel
    ) external onlyOwner {
        _targetReservesLevel = targetReservesLevel;
        emit SetTargetReservesLevel(targetReservesLevel);
    }

    function setOnchainServiceFeeRate(
        uint256 onchainServiceFeeRate
    ) external onlyOwner {
        _onchainServiceFeeRate = onchainServiceFeeRate;
        emit SetOnchainServiceFeeRate(onchainServiceFeeRate);
    }

    function setOffchainServiceFeeRate(
        uint256 offchainServiceFeeRate
    ) external onlyOwner {
        _offchainServiceFeeRate = offchainServiceFeeRate;
        emit SetOffchainServiceFeeRate(offchainServiceFeeRate);
    }

    function getTransactionFee() external view returns (uint256 txFee) {
        return _transactionFee;
    }

    function getMinMaxDeposit()
        external
        view
        returns (uint256 minDeposit, uint256 maxDeposit)
    {
        return (_minDeposit, _maxDeposit);
    }

    function getMaxWithdraw() external view returns (uint256 maxWithdraw) {
        return _maxWithdraw;
    }

    function getTargetReservesLevel()
        external
        view
        returns (uint256 targetReservesLevel)
    {
        return _targetReservesLevel;
    }

    function getOnchainAndOffChainServiceFeeRate()
        external
        view
        returns (uint256 onchainFeeRate, uint256 offchainFeeRate)
    {
        return (_onchainServiceFeeRate, _offchainServiceFeeRate);
    }

    function getFirstDeposit() external view returns (uint256 firstDeposit) {
        return _firstDeposit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

enum Action {
    DEPOSIT,
    WITHDRAW,
    EPOCH_UPDATE,
    WITHDRAW_QUEUE
}

struct VaultParameters {
    uint256 transactionFee; // 5 bps
    // uint256 transactionFeeWeekdayRate; // 5 bps
    // uint256 transactionFeeWeekendRate; // 10 bps
    uint256 firstDeposit; // first deposit amount
    uint256 minDeposit; // 100000 USDC
    uint256 maxDeposit; // max deposit on a day
    uint256 maxWithdraw; // max withdraw on a day
    uint256 targetReservesLevel; // 10%
    uint256 onchainServiceFeeRate; // 40 bps
    uint256 offchainServiceFeeRate; // 40 bps
}