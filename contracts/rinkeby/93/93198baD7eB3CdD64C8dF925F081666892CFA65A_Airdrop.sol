// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "IERC20.sol";
import "SafeERC20.sol";
import "MerkleProof.sol";
import "Ownable.sol";

contract Airdrop is Ownable {
    // Using
    using SafeERC20 for IERC20;

    // Tranche info
    struct TrancheRelease {
        uint256 startTime;       // start time of this tranche
        uint256 endTime;         // end time of this tranche
        uint256 penaltyRate;     // penalty rate if user withdraw before endTime
        uint256 totalAllocation; // total amount  allocated to this tranche
        uint256 claimed;         // total claimed amount of this tranche
        bool isPause;            // for security if there is issue
    }

    uint256 internal constant oneYear = 86400 * 365;

    // penalty amount will go to rewardReserve (kind of treasury) when user withdraw sooner than endTime
    address public rewardReserve;

    // airdrop token
    IERC20 public immutable token;

    // current tranche
    uint256 public tranche;

    // tranche -> merkel root: store merkel root of this tranche
    mapping(uint256 => bytes32) public merkleRoots;

    // tranche => user => isClaimed
    mapping(uint256 => mapping(address => bool)) public claimed;

    // trancheId -> TrancheRelease
    mapping(uint256 => TrancheRelease) public trancheReleases;

    // Events
    event TrancheAdded(uint256 indexed tranche, bytes32 indexed merkleRoot, uint256 totalAmount);
    event TrancheExpired(uint256 indexed tranche);
    event Claimed(address indexed claimant, uint256 indexed tranche, uint256 claimedAmout, uint256 penaltyAmount);
    event Sweep(address indexed recipient, uint256 amount);
    event TranchePaused(uint256 indexed tranche);
    event TrancheUnpaused(uint256 indexed tranche);

    /**
     * @dev constructor
     * @param _token Token to airdrop
     * @param _rewardReserve Address of rewardReserve contract, penalty amount will go here
     */
    constructor(address _token, address _rewardReserve) {
        require(_rewardReserve != address(0), "ADDRESS_ZERO");
        require(_token != address(0), "ADDRESS_ZERO");

        token = IERC20(_token);
        rewardReserve = _rewardReserve;
    }

    /**
     * @dev setup a new tranche
     * @param _merkleRoot Merkel root of this tranche
     * @param _totalAllocation Total amount allocated to this tranche
     * @param _startTime Start time of this tranche
     * @param _endTime End time of this tranche
     * @param _penaltyRate Penalty rate if user withdraw before endtime
     */
    function newTranche(
        bytes32 _merkleRoot,
        uint256 _totalAllocation,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _penaltyRate
    ) external onlyOwner returns (uint256 trancheId) {

        require(_startTime < _endTime && _penaltyRate < 51, "INVALID_TRANCHE_RELEASE");

        trancheId = tranche;
        merkleRoots[trancheId] = _merkleRoot;

        trancheReleases[trancheId] = TrancheRelease({
        startTime : _startTime,
        endTime : _endTime,
        penaltyRate : _penaltyRate,
        totalAllocation : _totalAllocation,
        claimed : 0,
        isPause : false
        });

        tranche = trancheId + 1;

        token.safeTransferFrom(msg.sender, address(this), _totalAllocation);

        emit TrancheAdded(trancheId, _merkleRoot, _totalAllocation);
    }

    /**
     * @dev close a tranche
     * @param _trancheId ID of the tranche
     */
    function closeTranche(uint256 _trancheId) external onlyOwner {
        require(_trancheId < tranche, "TRANCHE_DOES_NOT_EXIST");

        merkleRoots[_trancheId] = bytes32(0);
        emit TrancheExpired(_trancheId);
    }

    /**
     * @dev pause a tranche
     * @param _trancheId ID of the tranche
     */
    function pauseTranche(uint256 _trancheId) external onlyOwner {
        require(_trancheId < tranche, "TRANCHE_DOES_NOT_EXIST");
        require(!trancheReleases[_trancheId].isPause, "TRANCHE_ALREADY_PAUSED");

        trancheReleases[_trancheId].isPause = true;
        emit TranchePaused(_trancheId);
    }

    /**
     * @dev un-pause a tranche
     * @param _trancheId ID of the tranche
     */
    function unpauseTranche(uint256 _trancheId) external onlyOwner {
        require(_trancheId < tranche, "TRANCHE_DOES_NOT_EXIST");
        require(trancheReleases[_trancheId].isPause, "TRANCHE_NOT_PAUSED");

        trancheReleases[_trancheId].isPause = false;
        emit TrancheUnpaused(_trancheId);
    }

    /**
     * @dev set reward reserve address
     * @param _rewardReserve Address of rewardReserve contract, penalty amount will go here
     */
    function setRewardReserve(address _rewardReserve) external onlyOwner {
        require(_rewardReserve != address(0), "ADDRESS_ZERO");
        rewardReserve = _rewardReserve;
    }

    /**
     * @dev sweeps any remaining tokens after 1 year.
     * @param _trancheId ID of the tranche
     */
    function sweep(uint256 _trancheId) external onlyOwner {

        require(_trancheId < tranche, "TRANCHE_DOES_NOT_EXIST");

        TrancheRelease storage _tranche = trancheReleases[_trancheId];

        require(_tranche.startTime + oneYear < block.timestamp, "TOO_EARLY");

        uint256 totalAllocation = _tranche.totalAllocation;

        uint256 _amount = totalAllocation - _tranche.claimed;

        require(_amount > 0, "NOTHING_TO_SWEEP");

        _tranche.claimed = totalAllocation;

        // close the tranche after sweep all of its tokens
        merkleRoots[_trancheId] = bytes32(0);

        token.safeTransfer(rewardReserve, _amount);

        emit TrancheExpired(_trancheId);

        emit Sweep(rewardReserve, _amount);
    }

    /**
     * @dev claim token
     * @param _trancheId ID of the tranche
     * @param _amount amount to claim
     * @param _merkleProof Merkel proofs of this user of this tranche
     */
    function claim(
        uint256 _trancheId,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) external {

        require(_trancheId < tranche, "TRANCHE_DOES_NOT_EXIST");
        require(_amount > 0, "INVALID_AMOUNT");
        require(!trancheReleases[_trancheId].isPause, "PAUSED");
        require(merkleRoots[_trancheId] != bytes32(0), "TRANCHE_CLOSED");

        _claim(msg.sender, _trancheId, _amount, _merkleProof);
        _disburse(msg.sender, _trancheId, _amount);
    }

    /**
     * @dev verify if _walletAddress is qualified for the airdrop
     * @param _walletAddress Wallet address of user
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     * @param _merkleProof Merkel proofs of this user of this tranche
     */
    function verify(
        address _walletAddress,
        uint256 _tranche,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) external view returns (bool valid) {
        return _verify(_walletAddress, _tranche, _amount, _merkleProof);
    }

    /**
     * @dev return claimable amount and penalty amount.
     * @param _walletAddress Wallet address of user
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     */
    function claimableBalance(uint256 _tranche, address _walletAddress, uint256 _amount)
    external
    view
    returns (uint256 claimableAmount, uint256 penaltyAmount)
    {
        if (claimed[_tranche][_walletAddress]) {
            return (0, 0);
        }

        return _claimableBalance(_tranche, _amount);
    }

    /**
     * @dev return claimable amount and penalty amount.
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     */
    function _claimableBalance(uint256 _tranche, uint256 _amount)
    internal
    view
    returns (uint256 claimableAmount, uint256 penaltyAmount)
    {
        TrancheRelease memory tr = trancheReleases[_tranche];

        uint256 _penaltyMath = (tr.penaltyRate * (block.timestamp - tr.startTime)) / (tr.endTime - tr.startTime);

        uint256 _penaltyRate = _penaltyMath > tr.penaltyRate ? 0 : tr.penaltyRate - _penaltyMath;

        if (_penaltyRate == 0) {
            claimableAmount = _amount;
        } else {
            claimableAmount = _amount - (_amount * _penaltyRate) / 100;
            penaltyAmount = _amount - claimableAmount;
        }
    }

    /**
     * @dev claim token.
     * @param _walletAddress Wallet address of user
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     * @param _merkleProof Merkel proofs of this user of this tranche
     */
    function _claim(
        address _walletAddress,
        uint256 _tranche,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) private {

        require(!claimed[_tranche][_walletAddress], "ALREADY_CLAIMED");

        require(_verify(_walletAddress, _tranche, _amount, _merkleProof), "INCORRECT_PROOF");

        claimed[_tranche][_walletAddress] = true;

        TrancheRelease storage _tr = trancheReleases[_tranche];
        _tr.claimed += _amount;
    }

    /**
     * @dev verify if _walletAddress is qualified for the airdrop.
     * @param _walletAddress Wallet address of user
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     * @param _merkleProof Merkel proof of this user of this tranche
     */
    function _verify(
        address _walletAddress,
        uint256 _tranche,
        uint256 _amount,
        bytes32[] memory _merkleProof
    ) private view returns (bool valid) {
        bytes32 leaf = keccak256(abi.encodePacked(_walletAddress, _amount));
        return MerkleProof.verify(_merkleProof, merkleRoots[_tranche], leaf);
    }

    /**
     * @dev transfer/disburse token to user.
     * @param _to Wallet address of user
     * @param _tranche ID of the tranche
     * @param _amount amount to claim
     */
    function _disburse(
        address _to,
        uint256 _tranche,
        uint256 _amount
    ) private {
        (uint256 claimableAmount, uint256 penaltyAmount) = _claimableBalance(_tranche, _amount);

        if (penaltyAmount > 0) {
            token.safeTransfer(rewardReserve, penaltyAmount);
        }
        token.safeTransfer(_to, claimableAmount);

        emit Claimed(_to, _tranche, claimableAmount, penaltyAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "IERC20.sol";
import "Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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