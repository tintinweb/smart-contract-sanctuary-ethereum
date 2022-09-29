// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.4;

import "./_external/Ownable.sol";

interface IUFragmentsPolicy {
    function rebase() external;
}

/**
 * @title Orchestrator
 * @notice The orchestrator is the main entry point for rebase operations. It coordinates the policy
 * actions with external consumers.
 */
contract Orchestrator is Ownable {
    struct Transaction {
        bool enabled;
        address destination;
        bytes data;
    }

    // Stable ordering is not guaranteed.
    Transaction[] public transactions;

    IUFragmentsPolicy public policy;

    /**
     * @param policy_ Address of the UFragments policy.
     */
    constructor(address policy_) public {
        Ownable.initialize(msg.sender);
        policy = IUFragmentsPolicy(policy_);
    }

    /**
     * @notice Main entry point to initiate a rebase operation.
     *         The Orchestrator calls rebase on the policy and notifies downstream applications.
     *         Contracts are guarded from calling, to avoid flash loan attacks on liquidity
     *         providers.
     *         If a transaction in the transaction list fails, Orchestrator will stop execution
     *         and revert to prevent a gas underprice attack.
     */
    function rebase() external {
        require(msg.sender == tx.origin); // solhint-disable-line avoid-tx-origin

        policy.rebase();

        for (uint256 i = 0; i < transactions.length; i++) {
            Transaction storage t = transactions[i];
            if (t.enabled) {
                (bool result, ) = t.destination.call(t.data);
                if (!result) {
                    revert("Transaction Failed");
                }
            }
        }
    }

    /**
     * @notice Adds a transaction that gets called for a downstream receiver of rebases
     * @param destination Address of contract destination
     * @param data Transaction data payload
     */
    function addTransaction(address destination, bytes memory data) external onlyOwner {
        transactions.push(Transaction({enabled: true, destination: destination, data: data}));
    }

    /**
     * @param index Index of transaction to remove.
     *              Transaction ordering may have changed since adding.
     */
    function removeTransaction(uint256 index) external onlyOwner {
        require(index < transactions.length, "index out of bounds");

        if (index < transactions.length - 1) {
            transactions[index] = transactions[transactions.length - 1];
        }

        transactions.pop();
    }

    /**
     * @param index Index of transaction. Transaction ordering may have changed since adding.
     * @param enabled True for enabled, false for disabled.
     */
    function setTransactionEnabled(uint256 index, bool enabled) external onlyOwner {
        require(index < transactions.length, "index must be in range of stored tx list");
        transactions[index].enabled = enabled;
    }

    /**
     * @return Number of transactions, both enabled and disabled, in transactions list.
     */
    function transactionsSize() external view returns (uint256) {
        return transactions.length;
    }
}

pragma solidity 0.8.4;

import "./Initializable.sol";

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable is Initializable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    function initialize(address sender) public virtual initializer {
        _owner = sender;
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    uint256[50] private ______gap;
}

pragma solidity 0.8.4;

/**
 * @title Initializable
 *
 * @dev Helper contract to support initializer functions. To use it, replace
 * the constructor with a function that has the `initializer` modifier.
 * WARNING: Unlike constructors, initializer functions must be manually
 * invoked. This applies both to deploying an Initializable contract, as well
 * as extending an Initializable contract via inheritance.
 * WARNING: When used with inheritance, manual care must be taken to not invoke
 * a parent initializer twice, or ensure that all initializers are idempotent,
 * because this is not dealt with automatically as with constructors.
 */
contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to use in the initializer function of a contract.
     */
    modifier initializer() {
        require(
            initializing || isConstructor() || !initialized,
            "Contract instance has already been initialized"
        );

        bool wasInitializing = initializing;
        initializing = true;
        initialized = true;

        _;

        initializing = wasInitializing;
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.

        // MINOR CHANGE HERE:

        // previous code
        // uint256 cs;
        // assembly { cs := extcodesize(address) }
        // return cs == 0;

        // current code
        address _self = address(this);
        uint256 cs;
        assembly {
            cs := extcodesize(_self)
        }
        return cs == 0;
    }

    // Reserved storage space to allow for layout changes in the future.
    uint256[50] private ______gap;
}