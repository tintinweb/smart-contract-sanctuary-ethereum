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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./library/TimeLock.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Governor is Initializable, Timelock {
    function __Governor_init__(address _manager) public initializer {
        __Timelock_init__(_manager);
    }

    /// @notice The name of this contract
    string public constant name = "ANW Governor";

    /// @notice The total number of proposals
    uint256 public proposalCount;

    struct Proposal {
        /// @notice Unique id for looking up a proposal
        uint256 id;
        /// @notice Flag marking whether the proposal has been defeated
        bytes32 txHash;
        /// @notice Flag marking whether the proposal has been defeated
        bool defeated;
        /// @notice Flag marking whether the proposal has been canceled
        bool canceled;
        /// @notice Flag marking whether the proposal has been executed
        bool executed;
    }



    /// @notice The official record of all proposals ever proposed
    mapping(uint256 => Proposal) public proposals;


    /// @notice An event emitted when a new proposal is created
    event ProposalCreated(
        uint256 id,
        bytes32 txHash
    );


    /// @notice An event emitted when a proposal has been canceled
    event ProposalCanceled(uint256 id);

    /// @notice An event emitted when a proposal has been queued in the Timelock
    event ProposalQueued(uint256 id);

    /// @notice An event emitted when a proposal has been defeated in the Timelock
    event ProposalDefeated(uint256 id);

    /// @notice An event emitted when a proposal has been executed in the Timelock
    event ProposalExecuted(uint256 id);

    function propose(bytes32 _txHash)
        public
        onlyAdmin
        returns (uint256)
    {

        proposalCount++;

        Proposal memory newProposal = Proposal({
            id: proposalCount,
            txHash: _txHash,
            canceled: false,
            defeated: false,
            executed: false
        });

        emit ProposalCreated(
            newProposal.id,
            _txHash
        );

        return newProposal.id;
    }

    function queue(uint256 proposalId, bytes32 _txHash) public onlyAdmin {
        Proposal storage proposal = proposals[proposalId];

        require(
            proposal.txHash == _txHash, 
            "GovernorAlpha:: different publish txHash"
        );
        _queueOrRevert(_txHash);
        emit ProposalQueued(proposalId);
    }

    function _queueOrRevert(
        bytes32 _txHash
    ) internal {
        require(
            !queuedTransactions[_txHash],
            "GovernorAlpha::_queueOrRevert: proposal action already queued"
        );
        queueTransaction(_txHash);
    }

    function execute(uint256 proposalId, bytes32 _txHash) external payable onlyAdmin {

        Proposal storage proposal = proposals[proposalId];
        
        require(
            proposal.txHash == _txHash, 
            "GovernorAlpha:: different publish txHash"
        );

        proposal.executed = true;
        executeTransaction(proposal.txHash);
        emit ProposalExecuted(proposalId);
    }

    function cancel(uint256 proposalId, bytes32 _txHash) external onlyAdmin {

        Proposal storage proposal = proposals[proposalId];

        require(
            proposal.txHash == _txHash, 
            "GovernorAlpha:: different publish txHash"
        );

        require(
            !proposal.executed, 
            "GovernorAlpha::_queueOrRevert: cancel an excuted proposal" 
        );

        proposal.canceled = true;
        cancelTransaction(proposal.txHash);

        emit ProposalCanceled(proposalId);
    }

    function defeated(uint256 proposalId, bytes32 _txHash) external onlyAdmin {

        Proposal storage proposal = proposals[proposalId];

        require(
            proposal.txHash == _txHash, 
            "GovernorAlpha:: different publish txHash"
        );

        require(
            !proposal.executed, 
            "GovernorAlpha::_queueOrRevert: cancel an excuted proposal" 
        );

        proposal.defeated = true;
        defeatedTransaction(proposal.txHash);

        emit ProposalDefeated(proposalId);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.2 <0.9.0;

interface IManager {
    function isAdmin(address _user) external view returns (bool);
    function isGorvernance(address _user) external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../interfaces/IManager.sol";

contract Timelock {

    event NewDelay(uint256 indexed newDelay);
    event CancelTransaction(bytes32 indexed txHash);
    event DefeatedTransaction(bytes32 indexed txHash);
    event ExecuteTransaction(bytes32 indexed txHash);
    event QueueTransaction(bytes32 indexed txHash);

    address public manager;

    mapping (bytes32 => bool) public queuedTransactions;

    function __Timelock_init__( address _manager) internal {
        manager = _manager;
    }

    modifier onlyAdmin() {
        require(
            IManager(manager).isAdmin(msg.sender),
            "Timelock: Call must come from admin"
        );
        _;
    }

    receive() external payable { }


    function queueTransaction(bytes32 _txHash) internal returns (bytes32) {

        queuedTransactions[_txHash] = true;

        emit QueueTransaction(_txHash);
        return _txHash;
    }

    function cancelTransaction(bytes32 _txHash) internal {

        queuedTransactions[_txHash] = false;

        emit CancelTransaction(_txHash);
    }

    function defeatedTransaction(bytes32 _txHash) internal {

        queuedTransactions[_txHash] = false;

        emit DefeatedTransaction(_txHash);
    }

    function executeTransaction(bytes32 _txHash) internal returns (bytes32) {

        require(queuedTransactions[_txHash], "Timelock::executeTransaction: Transaction hasn't been queued.");

        queuedTransactions[_txHash] = false;

        emit ExecuteTransaction(_txHash);

        return _txHash;
    }

}