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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./Types.sol";
import "./ElectionTime.sol";

/**
 * @title Election
 * @author Faraj Shuauib
 * @dev Implements voting process along with winning candidate
 */
contract Election is Ownable, ElectionTime {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address payable;

    Counters.Counter private _voterIds;
    Counters.Counter private _ccandidateIds;
    Counters.Counter private _voteIds;

    constructor() {
        _voterIds.increment();
        _ccandidateIds.increment();
    }

    mapping(uint256 => Types.Voter) idVoter;
    mapping(uint256 => Types.Candidate) idCandidate;
    mapping(uint256 => Types.Vote) idVote;

    /**
     * @notice To check if the voter's age is greater than or equal to 18
     */
    modifier isEligibleVote(uint256 voterIndex, uint256 candidateIndex) {
        require(msg.sender != address(0), "address not found !!");
        require(
            idVoter[voterIndex].nationalId != 0,
            "You are not registered as a voter"
        );
        require(
            idCandidate[candidateIndex].nationalId != 0,
            "You are not trying to vote for not registered candidate"
        );
        require(
            idVote[voterIndex].voterId == 0,
            "You are already voted for this election, you can't vote again"
        );
        _;
    }

    modifier isEligibleToRegisterAsVoter(
        uint256 nationalId,
        string memory name,
        uint8 age
    ) {
        require(msg.sender != address(0), "address not found !!");
        require(
            idVoter[nationalId].nationalId == 0,
            "You are already registered as a voter"
        );
        require(age >= 18, "You are not eligible to register as a voter");
        require(
            bytes(name).length > 0,
            "You must enter your name to register as a voter"
        );
        _;
    }

    modifier isEligibleToRegisterAsCandidate(
        uint256 nationalId,
        string memory name,
        uint8 age,
        string memory kyc_hash_link
    ) {
        require(msg.sender != address(0), "address not found !!");
        require(
            idCandidate[nationalId].nationalId == 0,
            "You are already registered as a candidate"
        );
        require(age >= 18, "You are not eligible to register as a candidate");
        require(
            bytes(name).length > 0,
            "You must enter your name to register as a candidate"
        );
        require(
            bytes(kyc_hash_link).length > 0,
            "You must enter your kyc_hash_link to register as a candidate"
        );
        _;
    }

    function createVoter(
        string memory name,
        uint256 nationalId,
        uint8 age
    ) public votingDuration isEligibleToRegisterAsVoter(nationalId, name, age) {
        _voterIds.increment();
        uint256 newVoterId = _voterIds.current();

        idVoter[newVoterId] = Types.Voter({
            id: newVoterId,
            nationalId: nationalId,
            name: name,
            age: age
        });
    }

    function createCandidate(
        string memory name,
        uint256 nationalId,
        uint8 age,
        string memory kyc_hash_link
    )
        public
        votingDuration
        isEligibleToRegisterAsCandidate(nationalId, name, age, kyc_hash_link)
    {
        _ccandidateIds.increment();
        uint256 newCandidateId = _ccandidateIds.current();

        idCandidate[newCandidateId] = Types.Candidate({
            id: newCandidateId,
            nationalId: nationalId,
            name: name,
            age: age,
            kyc_hash_link: kyc_hash_link
        });
    }

    function vote(
        uint256 voterIndex,
        uint256 candidateIndex
    ) public votingDuration isEligibleVote(voterIndex, candidateIndex) {
        _voteIds.increment();
        uint256 newVoteId = _voteIds.current();

        idVote[newVoteId] = Types.Vote({
            id: newVoteId,
            voterId: voterIndex,
            candidateId: candidateIndex
        });
    }

    function getVoter(
        uint256 voterIndex
    ) public view returns (Types.Voter memory) {
        return idVoter[voterIndex];
    }

    function getCandidate(
        uint256 candidateIndex
    ) public view returns (Types.Candidate memory) {
        return idCandidate[candidateIndex];
    }

    function getVote(
        uint256 voteIndex
    ) public view returns (Types.Vote memory) {
        return idVote[voteIndex];
    }

    function getVoterCount() public view returns (uint256) {
        return _voterIds.current();
    }

    function getCandidateCount() public view returns (uint256) {
        return _ccandidateIds.current();
    }

    function getVoteCount() public view returns (uint256) {
        return _voteIds.current();
    }

    function getVotersList() public view returns (Types.Voter[] memory) {
        uint256 voterCount = getVoterCount();
        Types.Voter[] memory voters = new Types.Voter[](voterCount);
        for (uint256 i = 1; i <= voterCount; i++) {
            voters[i - 1] = getVoter(i);
        }
        return voters;
    }

    function getCandidatesList()
        public
        view
        returns (Types.Candidate[] memory)
    {
        uint256 candidateCount = getCandidateCount();
        Types.Candidate[] memory candidates = new Types.Candidate[](
            candidateCount
        );
        for (uint256 i = 1; i <= candidateCount; i++) {
            candidates[i - 1] = getCandidate(i);
        }
        return candidates;
    }

    function getVotesList() public view returns (Types.Vote[] memory) {
        uint256 voteCount = getVoteCount();
        Types.Vote[] memory votes = new Types.Vote[](voteCount);
        for (uint256 i = 1; i <= voteCount; i++) {
            votes[i - 1] = getVote(i);
        }
        return votes;
    }

    function getCandidateVotes(
        uint256 candidateIndex
    ) public view returns (Types.Vote[] memory) {
        uint256 voteCount = getVoteCount();
        Types.Vote[] memory votes = new Types.Vote[](voteCount);
        uint256 j = 0;
        for (uint256 i = 1; i <= voteCount; i++) {
            if (idVote[i].candidateId == candidateIndex) {
                votes[j] = getVote(i);
                j++;
            }
        }
        return votes;
    }

    function getWinnerCandidate() public view returns (Types.Candidate memory) {
        uint256 candidateCount = getCandidateCount();
        uint256 maxVotes = 0;
        uint256 winnerCandidateId = 0;
        for (uint256 i = 1; i <= candidateCount; i++) {
            uint256 candidateVotesCount = getCandidateVotes(i).length;
            if (candidateVotesCount > maxVotes) {
                maxVotes = candidateVotesCount;
                winnerCandidateId = i;
            }
        }
        return getCandidate(winnerCandidateId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract ElectionTime is Ownable {
    uint256 private startTime;
    uint256 private endTime;

    //modifier to check if the voting has already started
    modifier votingStarted() {
        if (startTime != 0) {
            require(block.timestamp < startTime, "Voting has already started.");
        }
        _;
    }

    //modifier to check if the voting has ended
    modifier votingEnded() {
        if (endTime != 0) {
            require(block.timestamp < endTime, "Voting has already ended.");
        }
        _;
    }

    //modifier to check if the voting is active or not
    modifier votingDuration() {
        require(block.timestamp > startTime, "voting hasn't started");
        require(block.timestamp < endTime, "voting has already ended");
        _;
    }
    //modifier to check if the vote Duration and Locking periods are valid or not
    modifier voteValid(uint256 _startTime, uint256 _endTime) {
        require(
            block.timestamp < _startTime,
            "Starting time is less than current TimeStamp!"
        );
        require(_startTime < _endTime, "Invalid vote Dates!");
        _;
    }

    //function to get the voting start time
    function getStartTime() public view returns (uint256) {
        return startTime;
    }

    //function to get the voting end time
    function getEndTime() public view returns (uint256) {
        return endTime;
    }

    //function to set voting duration and locking periods
    function setVotingPeriodParams(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
        votingStarted
        voteValid(_startTime, _endTime)
    {
        startTime = _startTime;
        endTime = _endTime;
    }

    // Stop the voting
    function stopVoting() external onlyOwner {
        require(block.timestamp > startTime, "Voting hasn't started yet!");
        if (block.timestamp < endTime) {
            endTime = block.timestamp;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

/**
 * @title Types
 * @author Faraj Shuauib
 * @dev All custom types that we have used in E-Voting will be declared here
 */
library Types {
    struct Voter {
        uint256 id;
        uint256 nationalId; // voter unique ID example: الرقم الوطني
        string name;
        uint8 age;
    }

    struct Candidate {
        // Note: If we can limit the length to a certain number of bytes,
        // we can use one of bytes1 to bytes32 because they are much cheaper
        uint256 id;
        uint256 nationalId; // candidate unique ID example: الرقم الوطني
        string name;
        uint8 age;
        string kyc_hash_link;
    }

    struct Vote {
        uint256 id;
        uint256 voterId;
        uint256 candidateId;
    }

    struct Result {
        uint256 candidateId;
        uint256 votes;
    }
}