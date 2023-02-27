// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
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
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

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
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
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
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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

pragma solidity ^0.8.4;

interface IICHOR {
    function name() external returns (string memory);

    function symbol() external returns (string memory);

    function decimals() external returns (uint8);

    function totalSupply() external returns (uint256);

    function balanceOf(address account) external returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function setCooldownEnabled(bool onoff) external;

    function setSwapEnabled(bool onoff) external;

    function openTrading() external;

    function setBots(address[] memory bots_) external;

    function setMaxBuyAmount(uint256 maxBuy) external;

    function setMaxSellAmount(uint256 maxSell) external;

    function setMaxWalletAmount(uint256 maxToken) external;

    function setSwapTokensAtAmount(uint256 newAmount) external;

    function setProjectWallet(address projectWallet) external;

    function setCharityAddress(address charityAddress) external;

    function getCharityAddress() external view returns (address charityAddress);

    function excludeFromFee(address account) external;

    function includeInFee(address account) external;

    function setBuyFee(uint256 buyProjectFee) external;

    function setSellFee(uint256 sellProjectFee) external;

    function setBlocksToBlacklist(uint256 blocks) external;

    function delBot(address notbot) external;

    function manualswap() external;

    function withdrawStuckETH() external;
}

pragma solidity ^0.8.4;

interface IUnicornToken {
    function getIsUnicorn(address user) external view returns (bool);

    function getAllUnicorns() external view returns (address[] memory);

    function getUnicornsLength() external view returns (uint256);

    function mint(address to) external;

    function burn(address from) external;

    function init(address user) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVotingInitialize.sol";

interface IVoting is IVotingInitialize {
    function initialize(
        Params memory _params,
        address _applicant,
        address _ichorTokenAddress,
        address _unicornToken,
        VotingVariants votingType
    ) external;

    function getAllVoters() external view returns (address[] memory);

    function getbalanceVoted(address account_) external view returns (uint256);

    function getVoterCount() external view returns (uint256);

    function getStats()
        external
        view
        returns (uint256 _for, uint256 _against, uint256 _count);

    function voteFor(uint256 amount_) external;

    function voteAgainst(uint256 amount_) external;

    function finishVoting() external;

    function getVotingResults() external;

    function withdraw() external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "./IVotingInitialize.sol";

interface IVotingFactory is IVotingInitialize {
    function createVoting(
        VotingVariants _typeVoting,
        bytes memory _voteDescription,
        uint256 _duration,
        uint256 _qtyVoters,
        uint256 _minPercentageVoters,
        address _applicant
    ) external;

    function getVotingInstancesLength() external view returns (uint256);

    function isVotingInstance(address instance) external view returns (bool);

    event CreateVoting(
        address indexed instanceAddress,
        VotingVariants indexed instanceType
    );
    event SetMasterVoting(
        address indexed previousContract,
        address indexed newContract
    );
    event SetMasterVotingAllowList(
        address indexed previousContract,
        address indexed newContract
    );
    event SetVotingTokenRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
    event SetCreateProposalRate(
        uint256 indexed previousRate,
        uint256 indexed newRate
    );
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IVotingInitialize {
    enum VotingVariants {
        UNICORNADDING,
        UNICORNREMOVAL,
        CHARITY
    }

    struct Params {
        bytes description;
        uint256 start;
        uint256 qtyVoters;
        uint256 minPercentageVoters;
        uint256 minQtyVoters;
        uint256 duration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IVotingFactory.sol";
import "./interfaces/IICHOR.sol";
import "./interfaces/IVoting.sol";
import "./interfaces/IUnicornToken.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "./interfaces/IVotingInitialize.sol";

/// @notice Voting contract
contract Voting is Initializable, ContextUpgradeable, IVoting {
    struct ballot {
        /// @notice Address of voter
        address voterAddress;

        /// @notice Voter's choise
        bool choice;
    }

    /// @notice Params structure
    Params public params;

    /// @notice Total amount of For votes
    uint256 internal totalForVotes;

    /// @notice Total amount of Against votes
    uint256 internal totalAgainstVotes;

    /// @notice Array of all voters
    ballot[] internal voters;

    /// @notice Mapping (address => uint256). Contains balances of locked tokens For
    mapping(address => uint256) internal balancesFor;

    /// @notice Mapping (address => uint256). Contains balances of locked tokens Against
    mapping(address => uint256) internal balancesAgainst;

    /// @notice ICHOR instance
    IICHOR public ichorToken;

    /// @notice UnicornToken instance
    IUnicornToken public unicornToken;

    /// @notice Shows if result of voting has been completed
    bool private resultCompleted;

    /// @notice Address of applicant
    address private applicant;

    /// @notice Amount of total votes For
    uint256 private totalAmountFor;

    /// @notice Amount of total votes Against
    uint256 private totalAmountAgainst;

    /// @notice Voting type
    VotingVariants private votingType;

    /// @notice Indicates that user is voted
    /// @param voter Address of voter
    /// @param choice Choice of  voter (True - For, False - Against)
    /// @param amount_ Amount of ICHOR tokens locked
    event Voted(address voter, bool choice, uint256 amount_);

    /// @notice Indicates that voting was successfull
    /// @param _for Total amount of votes For
    /// @param _against Total amount of votes Against
    /// @param _total Total amount of voters
    event VotingSuccessful(uint256 _for, uint256 _against, uint256 _total);

    /// @notice Indicates that voting was Failed
    /// @param _for Total amount of votes For
    /// @param _against Total amount of votes Against
    /// @param _total Total amount of voters
    event VotingFailed(uint256 _for, uint256 _against, uint256 _total);

    /// @notice Checks if voting result has been completed
    modifier votingResultNotCompleted() {
        require(!resultCompleted, "Voting: Voting result already completed!");
        _;
    }

    /// @notice Checks if caller is a ICHOR token holder
    modifier tokenHoldersOnly() {
        require(
            ichorToken.balanceOf(_msgSender()) > 0,
            "Voting: Not enough ICHOR tokens!"
        );
        _;
    }

    /// @notice Checks if voting is over
    modifier votingIsOver() {
        require(
            block.timestamp > params.start + params.duration,
            "Voting: Voting is not over!"
        );
        _;
    }

    /// @notice Checks if voting is active
    modifier votingIsActive() {
        require(
            block.timestamp >= params.start &&
                block.timestamp <= (params.start + params.duration),
            "Voting: Voting is over"
        );
        _;
    }

    /// @notice Initialize contract
    /// @param _params Params structure
    /// @param _applicant The applicant to whom the result of the vote will be applied
    /// @param _ichorTokenAddress ICHOR token address
    /// @param _unicornToken Unicorn token address
    /// @param _votingType Type of Voting. UNICORN or CHARITY (0|1)
    function initialize(
        Params memory _params,
        address _applicant,
        address _ichorTokenAddress,
        address _unicornToken,
        VotingVariants _votingType
    ) public virtual override initializer {
        params = _params;
        ichorToken = IICHOR(_ichorTokenAddress);
        resultCompleted = false;
        applicant = _applicant;
        unicornToken = IUnicornToken(_unicornToken);
        votingType = _votingType;
    }

    /// @notice Returns all voters
    /// @return array Array of all voters
    function getAllVoters() external view returns (address[] memory) {
        address[] memory addressVoters = new address[](voters.length);
        for (uint256 i = 0; i < voters.length; i++) {
            addressVoters[i] = voters[i].voterAddress;
        }
        return addressVoters;
    }

    /// @notice Returns total amount of voters
    /// @return Amount total amount of voters
    function getVoterCount() public view returns (uint256) {
        return voters.length;
    }

    /// @notice Returns voting balance of user
    /// @param account_ Voter's address
    /// @return amount Voting balance of user
    function getbalanceVoted(address account_) external view returns (uint256) {
        if (balancesFor[account_] > 0) {
            return balancesFor[account_];
        } else {
            return balancesAgainst[account_];
        }
    }

    /// @notice Returns stats of the voting
    /// @return _for Total For votes
    /// @return _against Total Against votes
    /// @return _count Total amount of users voted
    function getStats()
        public
        view
        returns (uint256 _for, uint256 _against, uint256 _count)
    {
        return (totalAmountFor, totalAmountAgainst, getVoterCount());
    }

    /// @notice Votes For
    /// @param amount_ Amount of tokens to lock
    /**
    @dev This method can be called by ICHOR holders only.
    This method can be called only while voting is active.
    **/
    function voteFor(
        uint256 amount_
    ) public virtual tokenHoldersOnly votingIsActive {
        require(
            balancesAgainst[_msgSender()] == 0,
            "Voting: you cant vote for two options!"
        );
        ichorToken.transferFrom(_msgSender(), address(this), amount_);

        if (balancesFor[_msgSender()] == 0) {
            voters.push(ballot({voterAddress: _msgSender(), choice: true}));
        }

        uint256 amountWithFee = amount_ - ((amount_ * 4) / 100);

        balancesFor[_msgSender()] += amountWithFee;
        totalAmountFor += amountWithFee;
        totalForVotes++;
        emit Voted(_msgSender(), true, amountWithFee);
    }

    /// @notice Votes Against
    /// @param amount_ Amount of tokens to lock
    /**
    @dev This method can be called by ICHOR holders only.
    This method can be called only while voting is active.
    **/
    function voteAgainst(
        uint256 amount_
    ) public virtual tokenHoldersOnly votingIsActive {
        require(
            balancesFor[_msgSender()] == 0,
            "Voting: you cant vote for two options!"
        );
        ichorToken.transferFrom(_msgSender(), address(this), amount_);

        if (balancesAgainst[_msgSender()] == 0) {
            voters.push(ballot({voterAddress: _msgSender(), choice: false}));
        }
        uint256 amountWithFee = amount_ - ((amount_ * 4) / 100);

        balancesAgainst[_msgSender()] += amountWithFee;
        totalAmountAgainst += amountWithFee;
        totalAgainstVotes++;

        emit Voted(_msgSender(), false, amountWithFee);
    }

    /// @notice Completes and finishes Voting
    /**
    @dev This method can be called only when voting is over.
    This method can be called only if result is not completed
    **/
    function finishVoting() external votingIsOver votingResultNotCompleted {
        resultCompleted = true;
        (uint256 _for, uint256 _against, uint256 _total) = getStats();

        if (_total >= params.minQtyVoters) {
            if (_for > _against) {
                if (votingType == VotingVariants.UNICORNADDING) {
                    unicornToken.mint(applicant);
                } else if (votingType == VotingVariants.UNICORNREMOVAL) {
                    unicornToken.burn(applicant);
                } else if (votingType == VotingVariants.CHARITY) {
                    ichorToken.setCharityAddress(applicant);
                }
                
            }
        }
    }

    /// @notice Returns voting results (by event)
    /**
    @dev This method can be called only when voting is over.
    **/
    function getVotingResults() external votingIsOver {
        (uint256 _for, uint256 _against, uint256 _total) = getStats();
        if (_total >= params.minQtyVoters) {
            emit VotingSuccessful(_for, _against, _total);
        } else {
            emit VotingFailed(_for, _against, _total);
        }
    }

    /// @notice Withdraws locked tokens back to user
    /**
    @dev This method can be called only when voting is over.
    **/
    function withdraw() external votingIsOver {
        require(
            balancesFor[_msgSender()] > 0 || balancesAgainst[_msgSender()] > 0,
            "Voting: no tokens to withdraw"
        );
        uint256 amountToTransfer;
        if (balancesFor[_msgSender()] > 0) {
            amountToTransfer = balancesFor[_msgSender()];
        } else {
            amountToTransfer = balancesAgainst[_msgSender()];
        }
        ichorToken.transfer(_msgSender(), amountToTransfer);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Voting.sol";
import "./interfaces/IVotingFactory.sol";
import "./interfaces/IUnicornToken.sol";
import "./interfaces/IVotingInitialize.sol";
import "./interfaces/IVoting.sol";

/// @notice VotingFactory contract
contract VotingFactory is Ownable, IVotingFactory {
    struct votingInstance {
        /// @notice Voting instance address
        address addressInstance;

        /// @notice Voting type
        VotingVariants typeInstance;
    }

    /// @notice Address of master voting
    address public masterVoting;

    /// @notice Array if voting instances
    votingInstance[] public votingInstances;

    /// @notice ICHOR instance
    IICHOR public ichorToken;

    /// @notice Uicorn token instance
    IUnicornToken public unicornToken;

    /// @notice Mapping (address => bool). Shows if address is Voting instance
    mapping(address => bool) private mVotingInstances;

    /// @notice Checks if caller is a Unicorn
    modifier onlyUnicorns() {
        require(
            unicornToken.getIsUnicorn(msg.sender),
            "VotingFactory: caller is not a Unicorn"
        );
        _;
    }

    constructor() {
        masterVoting = address(new Voting());
    }

    /// @notice Sets new ICHOR token address
    /// @param ichorToken_ New ICHOR token address
    /// @dev This method can be called only by an Owner of the contract
    function setIchorAddress(address ichorToken_) external onlyOwner {
        ichorToken = IICHOR(ichorToken_);
    }

    /// @notice Returns current ICHOR token address
    /// @return address Current ICHOR token address
    function getIchorAddress() external view returns (address) {
        return address(ichorToken);
    }

    /// @notice Sets new Unicorn token address
    /// @param unicornToken_ New Unicorn token address
    /// @dev This method can be called only by an Owner of the contract
    function setUnicornToken(address unicornToken_) external onlyOwner {
        unicornToken = IUnicornToken(unicornToken_);
    }

    /// @notice Returns current Unicorn token address
    /// @return address Current Unicorn token address
    function getUnicornToken() external view returns (address) {
        return address(unicornToken);
    }

    /// @notice Creates Voting
    /// @param _typeVoting type of Voting. UNICORN or CHARITY (0|1)
    /// @param _voteDescription Description of Voting
    /// @param _duration Duration of the Voting
    /// @param _qtyVoters Quantity of voters
    /// @param _minPercentageVoters Min percentage of voters required for successful voting
    /// @param _applicant The applicant to whom the result of the vote will be applied
    /// @dev This method can be called only by Unicorns
    function createVoting(
        VotingVariants _typeVoting,
        bytes memory _voteDescription,
        uint256 _duration,
        uint256 _qtyVoters,
        uint256 _minPercentageVoters,
        address _applicant
    ) external override onlyUnicorns {
        require(
            _duration >= 518400 && _duration <= 1317600,
            "VotingFactory: Duration exceeds the allowable interval"
        );
        require(
            _qtyVoters > 0,
            "VotingFactory: QtyVoters must be greater than zero"
        );
        require(
            _minPercentageVoters > 0,
            "VotingFactory: Percentage must be greater than zero"
        );

        address instance;
        instance = Clones.clone(masterVoting);
        IVoting(instance).initialize(
            IVotingInitialize.Params({
                description: _voteDescription,
                start: block.timestamp,
                qtyVoters: _qtyVoters,
                minPercentageVoters: _minPercentageVoters,
                minQtyVoters: _mulDiv(_minPercentageVoters, _qtyVoters, 100),
                duration: _duration
            }),
            _applicant,
            address(ichorToken),
            address(unicornToken),
            _typeVoting
        );
        votingInstances.push(
            votingInstance({
                addressInstance: instance,
                typeInstance: _typeVoting
            })
        );
        mVotingInstances[instance] = true;
        emit CreateVoting(instance, _typeVoting);
    }

    /// @notice Returns total amount of Voting instances
    /// @return amount Total amount of Voting instances
    function getVotingInstancesLength()
        external
        view
        override
        returns (uint256)
    {
        return votingInstances.length;
    }

    /// @notice Returns True if address is Voting instance, returns false if not
    /// @return bool True if address is Voting instance, returns false if not
    function isVotingInstance(address instance) external view returns (bool) {
        return mVotingInstances[instance];
    }

    /// @notice Calculates the minimum amount of voters needed for successfull voting
    /// @dev This in an internal method
    function _mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) internal pure returns (uint256) {
        uint256 a = x / z;
        uint256 b = x % z; // x = a * z + b
        uint256 c = y / z;
        uint256 d = y % z; // y = c * z + d
        return a * b * z + a * d + b * c + (b * d) / z;
    }
}