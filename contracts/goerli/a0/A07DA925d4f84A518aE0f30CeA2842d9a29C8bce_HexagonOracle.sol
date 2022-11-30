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

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

interface IEpochs {
    function getCurrentEpoch() external view returns (uint256);

    function isStarted() external view returns (bool);

    function isDecisionWindowOpen() external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IHexagonOracle {
    function getTotalETHStakingProceeds(uint256 epoch) external view returns (uint256);
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEpochs.sol";

/**
 * @title Implementation of Beacon chain oracle
 *
 * @notice The goal of the oracle is to provide balance of the Golem Foundation validator's account on the ETH 2.0 side.
 * Balance for epoch will be taken from block which corresponds to end of Hexagon epoch (check `Epochs.sol` contract).
 */
contract BeaconChainOracle is Ownable {
    /// @notice Epochs contract address.
    IEpochs public immutable epochs;

    /// @notice Foundation validator's indexes
    string public validatorIndexes;

    /// @notice balance from beacon chain in given epoch
    mapping(uint256 => uint256) public balanceByEpoch;

    /// @param epochsAddress Address of Epochs contract.
    constructor(address epochsAddress) {
        epochs = IEpochs(epochsAddress);
    }

    function setBalance(uint256 epoch, uint256 balance) external onlyOwner {
        require(
            epoch > 0 && epoch == epochs.getCurrentEpoch() - 1,
            "HN/can-set-balance-for-previous-epoch-only"
        );
        require(balanceByEpoch[epoch] == 0, "HN/balance-for-given-epoch-already-exists");
        balanceByEpoch[epoch] = balance;
    }

    function setValidatorIndexes(string memory _validatorIndexes) external onlyOwner {
        validatorIndexes = _validatorIndexes;
    }
}

pragma solidity ^0.8.9;

/* SPDX-License-Identifier: UNLICENSED */

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IEpochs.sol";

/**
 * @title Implementation of execution layer oracle.
 *
 * @notice The goal of the oracle is to provide balance of the Golem Foundation validator execution layer's account
 * which collects fee.
 * Balance for epoch will be taken from block which corresponds to end of Hexagon epoch (check `Epochs.sol` contract).
 */
contract ExecutionLayerOracle is Ownable {
    /// @notice Epochs contract address.
    IEpochs public immutable epochs;

    /// @notice validator's address collecting fees
    address public validatorAddress;

    /// @notice execution layer account balance in given epoch
    mapping(uint256 => uint256) public balanceByEpoch;

    /// @param epochsAddress Address of Epochs contract.
    constructor(address epochsAddress) {
        epochs = IEpochs(epochsAddress);
    }

    function setBalance(uint256 epoch, uint256 balance) external onlyOwner {
        require(
            epoch > 0 && epoch == epochs.getCurrentEpoch() - 1,
            "HN/can-set-balance-for-previous-epoch-only"
        );
        require(balanceByEpoch[epoch] == 0, "HN/balance-for-given-epoch-already-exists");
        balanceByEpoch[epoch] = balance;
    }

    function setValidatorAddress(address _validatorAddress) external onlyOwner {
        validatorAddress = _validatorAddress;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "../interfaces/IHexagonOracle.sol";
import "./BeaconChainOracle.sol";
import "./ExecutionLayerOracle.sol";

/**
 * @title Implementation of hexagon oracle.
 *
 * @notice Trusted oracle maintained by Golem Foundation responsible for calculating ETH staking proceeds of
 * foundation's ETH 2.0 validator node. These proceeds include profit which validator makes on beacon chain
 * side (staking rewards for participating in Ethereum consensus) and tx inclusion fees on execution layer
 * side (tips for block proposer and eventual MEVs).
 */
contract HexagonOracle is IHexagonOracle {
    /**
     * @notice BeaconChainOracle contract.
     * Provides balance of the Golem Foundation validator's account on the ETH 2.0 side.
     */
    BeaconChainOracle private immutable beaconChainOracle;

    /**
     * @notice ExecutionLayerOracle contract address.
     * Provides balance of the Golem Foundation validator execution layer's account
     * which collects fee.
     */
    ExecutionLayerOracle private immutable executionLayerOracle;

    constructor(address _beaconChainOracleAddress, address _executionLayerOracleAddress) {
        beaconChainOracle = BeaconChainOracle(_beaconChainOracleAddress);
        executionLayerOracle = ExecutionLayerOracle(_executionLayerOracleAddress);
    }

    /**
     * @notice Checks how much yield (ETH staking proceeds) is generated by Golem Foundation at particular epoch.
     * @param epoch - Hexagon Epoch's number.
     * @return Total ETH staking proceeds made by foundation in wei for particular epoch.
     */
    function getTotalETHStakingProceeds(uint256 epoch) public view returns (uint256) {
        uint256 epochExecutionLayerBalance = executionLayerOracle.balanceByEpoch(epoch);
        uint256 epochBeaconChainBalance = beaconChainOracle.balanceByEpoch(epoch);

        if (epochBeaconChainBalance == 0 || epochExecutionLayerBalance == 0) {
            return 0;
        }

        uint256 previousExecutionLayerBalance = executionLayerOracle.balanceByEpoch(epoch - 1);
        uint256 previousBeaconChainBalance = beaconChainOracle.balanceByEpoch(epoch - 1);

        return
            (epochExecutionLayerBalance + epochBeaconChainBalance) -
            (previousBeaconChainBalance + previousExecutionLayerBalance);
    }
}