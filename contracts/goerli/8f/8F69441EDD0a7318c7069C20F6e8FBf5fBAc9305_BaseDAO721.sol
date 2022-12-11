// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/// @notice interfaces
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

/**
 * @title BaseDAO721
 * @dev only NFT holders of specific ERC-721, ERC-721A or ERC-4907 projects can create and vote on proposals
 */

interface IBaseDAOContract721 {
    function balanceOf(address) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

contract BaseDAO721 is Initializable {
    /// @notice address owner
    address public owner;

    /// @notice proposal number to be created
    uint256 proposalNumber;

    /// @notice Contract name and symbol
    string public name;
    string public symbol;

    /// @notice defining whether contract is Base or not
    bool public isBase;

    /// @notice defining whether the DAO is open to everyone, by default it is true
    bool public isOpen = false;

    /// @notice NFT contract address of which holders can interact with this contract
    IBaseDAOContract721 BaseDAOContract;

    /// @notice general structure of proposal

    struct proposal {
        uint256 id;
        bool exists;
        string description;
        uint256 deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    mapping(uint256 => proposal) public Proposals;

    /// @notice event emitted during the creation of a new proposal

    event proposalCreated(uint256 id, string description, address proposer);

    /// @notice event emitted on new vote

    event newVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposal,
        bool votedFor
    );

    event proposalCount(uint256 id, bool passed);

    /// @notice only owner modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "BaseDAO721: only owner");
        _;
    }

    /**
     * @notice initializing the cloned contract
     * @param data data for DAOProxy clone encoded
     * @param owner_ address of DAOProxy owner
     **/
    function initialize(bytes memory data, address owner_)
        external
        initializer
    {
        require(
            isBase == false,
            "BaseDAO721: this is the base contract,cannot initialize"
        );

        require(
            owner == address(0),
            "BaseDAO721: contract already initialized"
        );

        require(owner_ != address(0), "BaseDAO721: Owner address cannot be 0");

        (string memory name_, string memory symbol_, address _nftContract) = abi
            .decode(data, (string, string, address));

        require(
            _exists(_nftContract),
            "BaseDAO721: Address must be a contract"
        );

        name = name_;
        symbol = symbol_;

        owner = owner_;

        proposalNumber = 1;
        BaseDAOContract = IBaseDAOContract721(_nftContract);

        if (!BaseDAOContract.supportsInterface(0x80ac58cd)) {
            revert("BaseDAO721: Contract does not support ERC721");
        }
    }

    /**
     * @notice constructor for base contract
     **/

    constructor(string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
        isBase = true;
    }

    /**
     * @notice function that allows the DAO owner to change access
     * @param _isOpen determines wether DAO access is public or private
     **/

    function changeAccess(bool _isOpen) public onlyOwner {
        require(
            _isOpen != isOpen,
            "BaseDAO721: Access already set to this value"
        );

        isOpen = _isOpen;
    }

    /**
     * @notice function that allows the DAO owner to change NFT contract
     * @param _newAddr address of new NFT contract
     **/
    function change721Contract(address _newAddr) public onlyOwner {
        require(_exists(_newAddr), "BaseDAO721: Address must be a contract");

        require(
            _newAddr != address(BaseDAOContract),
            "BaseDAO721: Address already set"
        );

        BaseDAOContract = IBaseDAOContract721(_newAddr);

        if (!BaseDAOContract.supportsInterface(0x80ac58cd)) {
            revert("BaseDAO721: Contract does not support ERC721");
        }
    }

    /**
     * @notice private function that checks if msg sender is eligible to create a proposal
     * @param _proposer is the address that is being checked for proposal eligibility
     **/

    function checkProposalEligibility(address _proposer)
        private
        view
        returns (bool)
    {
        if (BaseDAOContract.balanceOf(_proposer) >= 1) {
            return true;
        }

        return false;
    }

    /**
     * @notice private function that checks if msg sender is eligible to vote for specific proposal
     * @param _voter address being checked for voting eligibility of proposal
     **/

    function checkVoteEligibility(address _voter) private view returns (bool) {
        if (BaseDAOContract.balanceOf(_voter) >= 1) {
            return true;
        }

        return false;
    }

    /**
     * @notice creates a new proposal
     * @param _description description of proposal
     * @param _timestamp timestamp of proposal
     **/

    function createProposal(string memory _description, uint256 _timestamp)
        public
    {
        if (!isOpen) {
            require(
                checkProposalEligibility(msg.sender),
                "BaseDAO721: Only NFT holders can put forth Proposals"
            );
        }

        proposal storage newProposal = Proposals[proposalNumber];
        newProposal.id = proposalNumber;
        newProposal.exists = true;
        newProposal.description = _description;
        newProposal.deadline = block.timestamp + _timestamp;

        emit proposalCreated(proposalNumber, _description, msg.sender);
        proposalNumber++;
    }

    /**
     * @notice vote on active proposal
     * @param _id id of proposal to vote on
     * @param _vote user can either vote true or false
     **/

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(
            Proposals[_id].exists,
            "BaseDAO721: This Proposal does not exist"
        );
        if (!isOpen) {
            require(
                checkVoteEligibility(msg.sender),
                "BaseDAO721: You can not vote on this Proposal"
            );
        }
        require(
            !Proposals[_id].voteStatus[msg.sender],
            "BaseDAO721: You have already voted on this Proposal"
        );
        require(
            block.number <= Proposals[_id].deadline,
            "BaseDAO721: The deadline has passed for this Proposal"
        );

        proposal storage p = Proposals[_id];

        if (_vote) {
            p.votesUp++;
        } else {
            p.votesDown++;
        }

        p.voteStatus[msg.sender] = true;

        emit newVote(p.votesUp, p.votesDown, msg.sender, _id, _vote);
    }

    /**
     * @notice count votes of specific proposal
     * @param _id id of proposal
     **/

    function countVotes(uint256 _id) public onlyOwner {
        require(
            Proposals[_id].exists,
            "BaseDAO721: This Proposal does not exist"
        );
        require(
            block.timestamp > Proposals[_id].deadline,
            "BaseDAO721: Voting has not concluded"
        );
        require(
            !Proposals[_id].countConducted,
            "BaseDAO721: Count already conducted"
        );

        proposal storage p = Proposals[_id];

        if (Proposals[_id].votesDown < Proposals[_id].votesUp) {
            p.passed = true;
        }

        p.countConducted = true;

        emit proposalCount(_id, p.passed);
    }

    /// @notice returns true for existing address
    /// @param _addr the address to be tested for existance
    function _exists(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            /* solium-disable-line */
            size := extcodesize(_addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}