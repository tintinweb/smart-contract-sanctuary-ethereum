pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IJOLTNativeCurrencyPriceOracle.sol";
import "../interfaces/IMaster.sol";
import "../interfaces/IWorkEvaluator.sol";

/**
 * @title EIP1559WorkEvaluator
 * @dev EIP1559WorkEvaluator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
contract EIP1559WorkEvaluator is IWorkEvaluator, Ownable {
    uint256 private immutable BASE = 10000;

    address public nativeTokenNativeCurrencyPriceOracle;
    address public bonder;
    uint32 public minimumBonus;
    uint32 public maximumBonus;

    error ZeroAddressOracle();
    error UnbondedWorker();
    error Forbidden();
    error InvalidMinimumBonus();
    error InvalidMaximumBonus();

    event SetNativeTokenNativeCurrencyPriceOracle(
        address nativeTokenNativeCurrencyPriceOracle
    );
    event SetBonder(address bonder);
    event SetMinimumBonus(uint256 minimumBonus);
    event SetMaximumBonus(uint256 maximumBonus);

    constructor(
        address _nativeTokenNativeCurrencyPriceOracle,
        address _bonder,
        uint32 _minimumBonus,
        uint32 _maximumBonus
    ) {
        if (_nativeTokenNativeCurrencyPriceOracle == address(0))
            revert ZeroAddressOracle();
        if (_minimumBonus > BASE) revert InvalidMinimumBonus();
        if (_maximumBonus > BASE) revert InvalidMaximumBonus();

        nativeTokenNativeCurrencyPriceOracle = _nativeTokenNativeCurrencyPriceOracle;
        bonder = _bonder;
        minimumBonus = _minimumBonus;
        maximumBonus = _maximumBonus;
    }

    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        view
        override
        returns (uint256)
    {
        uint256 _baseFee;
        assembly {
            _baseFee := basefee()
        }

        uint256 _nativeCurrencyFee = (_gasUsed + 50_000) * (_baseFee + 2 gwei);

        uint256 _minimumPaid = ((_nativeCurrencyFee * (BASE + minimumBonus)) /
            BASE);
        uint256 _maximumPaid = ((_nativeCurrencyFee * (BASE + maximumBonus)) /
            BASE);

        // FIXME: these (total bonded and bonded by worker) can be passed in as inputs to save some gas
        uint256 _totalBonded = IMaster(bonder).totalBonded();
        uint256 _workerBond = IMaster(bonder).bonded(_worker);
        if (_workerBond == 0) revert UnbondedWorker();

        // TODO: consider using a multiplier to improve precision
        return
            IJOLTNativeCurrencyPriceOracle(nativeTokenNativeCurrencyPriceOracle)
                .quote(
                    _nativeCurrencyFee +
                        (((_maximumPaid - _minimumPaid) * _workerBond) /
                            _totalBonded)
                );
    }

    function setNativeTokenNativeCurrencyPriceOracle(
        address _nativeTokenNativeCurrencyPriceOracle
    ) external {
        if (msg.sender != owner()) revert Forbidden();
        if (_nativeTokenNativeCurrencyPriceOracle == address(0))
            revert ZeroAddressOracle();
        nativeTokenNativeCurrencyPriceOracle = _nativeTokenNativeCurrencyPriceOracle;
        emit SetNativeTokenNativeCurrencyPriceOracle(
            _nativeTokenNativeCurrencyPriceOracle
        );
    }

    function setBonder(address _bonder) external {
        if (msg.sender != owner()) revert Forbidden();
        bonder = _bonder;
        emit SetBonder(_bonder);
    }

    function setMinimumBonus(uint32 _minimumBonus) external {
        if (_minimumBonus > BASE) revert InvalidMinimumBonus();
        if (msg.sender != owner()) revert Forbidden();
        minimumBonus = _minimumBonus;
        emit SetMinimumBonus(_minimumBonus);
    }

    function setMaximumBonus(uint32 _maximumBonus) external {
        if (_maximumBonus > BASE) revert InvalidMaximumBonus();
        if (msg.sender != owner()) revert Forbidden();
        maximumBonus = _maximumBonus;
        emit SetMaximumBonus(_maximumBonus);
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

pragma solidity >=0.8.10;

/**
 * @title IJOLTNativeCurrencyPriceOracle
 * @dev IJOLTNativeCurrencyPriceOracle contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IJOLTNativeCurrencyPriceOracle {
    function quote(uint256 _nativeCurrencyAmount)
        external
        view
        returns (uint256);
}

pragma solidity >=0.8.10;

/**
 * @title IMaster
 * @dev IMaster contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IMaster {
    struct Worker {
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct WorkerInfo {
        address addrezz;
        bool disallowed;
        uint256 bonded;
        uint256 earned;
        uint256 bonding;
        uint256 bondingBlock;
        uint256 unbonding;
        uint256 unbondingBlock;
    }

    struct Credit {
        uint256 amount;
        uint256 locked;
    }

    struct Job {
        address addrezz;
        address owner;
        string specification;
        Credit credit;
    }

    struct JobInfo {
        uint256 id;
        address addrezz;
        address owner;
        string specification;
        Credit credit;
    }

    struct EnumerableJobSet {
        mapping(uint256 => Job) byId;
        mapping(address => uint256) idForAddress;
        mapping(address => uint256[]) byOwner;
        uint256[] keys;
        uint256 ids;
    }

    struct EnumerableWorkerSet {
        mapping(address => Worker) byAddress;
        address[] keys;
    }

    function bond(uint256 _amount) external;

    function bondWithPermit(
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function consolidateBond() external;

    function cancelBonding() external;

    function unbond(uint256 _amount) external;

    function consolidateUnbonding() external;

    function cancelUnbonding() external;

    function slash(address _worker, uint256 _amount) external;

    function disallow(address _worker) external;

    function allowLiquidity(address _liquidity, address _weightCalculator)
        external;

    function disallowLiquidity(address _liquidity) external;

    function allowJobCreator(address _creator) external;

    function disallowJobCreator(address _creator) external;

    function addJob(
        address _address,
        address _owner,
        string calldata _specification
    ) external;

    function upgradeJob(
        uint256 _id,
        address _newJob,
        string calldata _newSpecification
    ) external;

    function removeJob(uint256 _id) external;

    function addCredit(uint256 _id, uint256 _amount) external;

    function addCreditWithPermit(
        uint256 _id,
        uint256 _amount,
        uint256 _permittedAmount, // can be used for infinite approvals
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external;

    function addLiquidityCredit(
        uint256 _id,
        address _liquidity,
        uint256 _amount
    ) external;

    function removeCredit(uint256 _id, uint256 _amount) external;

    function workable(address _worker, uint256 _jobId)
        external
        view
        returns (bool, bytes memory);

    function work(uint256 _id, bytes calldata _data) external;

    function setFee(uint16 _fee) external;

    function setLiquidityTokenPremium(uint16 _fee) external;

    function setAssignedTurnBlocks(uint32 _assignedTurnBlocks) external;

    function setCompetitiveTurnBlocks(uint32 _competitiveTurnBlocks) external;

    function setJolt(address _jolt) external;

    function setFeeReceiver(address _feeReceiver) external;

    function setWorkEvaluator(address _workEvaluator) external;

    function setBondingBlocks(uint32 _bondingBlocks) external;

    function setUnbondingBlocks(uint32 _unbondingBlocks) external;

    function totalBonded() external view returns (uint256);

    function epochCheckpoint() external view returns (uint256);

    function bondingBlocks() external view returns (uint32);

    function unbondingBlocks() external view returns (uint32);

    function fee() external view returns (uint16);

    function liquidityTokenPremium() external view returns (uint16);

    function assignedTurnBlocks() external view returns (uint32);

    function competitiveTurnBlocks() external view returns (uint32);

    function jolt() external view returns (address);

    function feeReceiver() external view returns (address);

    function bonded(address _address) external view returns (uint256);

    function earned(address _address) external view returns (uint256);

    function disallowed(address _address) external view returns (bool);

    function liquidityWeightCalculator(address _liquidityToken)
        external
        view
        returns (address);

    function jobsCreator(address _jobsCreator) external view returns (bool);

    function workersAmount() external view returns (uint256);

    function worker(address _address) external view returns (WorkerInfo memory);

    function workersSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (WorkerInfo[] memory);

    function jobsAmount() external view returns (uint256);

    function job(uint256 _id) external view returns (JobInfo memory);

    function credit(uint256 _id) external view returns (Credit memory);

    function jobsSlice(uint256 _fromIndex, uint256 _toIndex)
        external
        view
        returns (JobInfo[] memory);

    function jobsOfOwner(address _owner)
        external
        view
        returns (JobInfo[] memory);
}

pragma solidity >=0.8.10;

/**
 * @title IWorkEvaluator
 * @dev IWorkEvaluator contract
 * @author Federico Luzzi - <[email protected]>
 * SPDX-License-Identifier: GPL-3.0
 */
interface IWorkEvaluator {
    function evaluateCost(address _worker, uint256 _gasUsed)
        external
        returns (uint256);
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