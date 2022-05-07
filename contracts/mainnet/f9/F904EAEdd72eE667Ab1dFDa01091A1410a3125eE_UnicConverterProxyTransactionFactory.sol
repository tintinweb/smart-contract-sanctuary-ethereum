/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// File: @openzeppelin/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// File: contracts/interfaces/IProxyTransaction.sol

pragma solidity >=0.5.0;

interface IProxyTransaction {
    function forwardCall(address target, uint256 value, bytes calldata callData) external payable returns (bool success, bytes memory returnData);
}

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/ConverterGovernorAlphaConfig.sol

pragma solidity 0.6.12;

contract ConverterGovernorAlphaConfig is Ownable {
    uint public constant MINIMUM_DELAY = 1 days;
    uint public constant MAXIMUM_DELAY = 30 days;

    // 1000 / quorumVotesDivider = percentage needed
    uint public quorumVotesDivider;
    // 1000 / proposalThresholdDivider = percentage needed
    uint public proposalThresholdDivider;
    // The maximum number of individual transactions that can make up a proposal
    uint public proposalMaxOperations;
    // Time period (in blocks) during which the proposal can be voted on
    uint public votingPeriod;
    // Delay (in blocks) that must be waited after a proposal has been added before the voting phase begins
    uint public votingDelay;

    // Time period in which the transaction must be executed after the delay expires
    uint public gracePeriod;
    // Delay that must be waited after the voting period has ended and a proposal has been queued before it can be executed
    uint public delay;

    event NewQuorumVotesDivider(uint indexed newQuorumVotesDivider);
    event NewProposalThresholdDivider(uint indexed newProposalThresholdDivider);
    event NewProposalMaxOperations(uint indexed newProposalMaxOperations);
    event NewVotingPeriod(uint indexed newVotingPeriod);
    event NewVotingDelay(uint indexed newVotingDelay);

    event NewGracePeriod(uint indexed newGracePeriod);
    event NewDelay(uint indexed newDelay);

    constructor () public {
        quorumVotesDivider = 16; // 62.5%
        proposalThresholdDivider = 2000; // 0.5%
        proposalMaxOperations = 10;
        votingPeriod = 17280;
        votingDelay = 1;

        gracePeriod = 14 days;
        delay = 2 days;
    }

    function setQuorumVotesDivider(uint _quorumVotesDivider) external onlyOwner {
        quorumVotesDivider = _quorumVotesDivider;
        emit NewQuorumVotesDivider(_quorumVotesDivider);
    }
    function setProposalThresholdDivider(uint _proposalThresholdDivider) external onlyOwner {
        proposalThresholdDivider = _proposalThresholdDivider;
        emit NewProposalThresholdDivider(_proposalThresholdDivider);
    }
    function setProposalMaxOperations(uint _proposalMaxOperations) external onlyOwner {
        proposalMaxOperations = _proposalMaxOperations;
        emit NewProposalMaxOperations(_proposalMaxOperations);
    }
    function setVotingPeriod(uint _votingPeriod) external onlyOwner {
        votingPeriod = _votingPeriod;
        emit NewVotingPeriod(_votingPeriod);
    }
    function setVotingDelay(uint _votingDelay) external onlyOwner {
        votingDelay = _votingDelay;
        emit NewVotingDelay(_votingDelay);
    }

    function setGracePeriod(uint _gracePeriod) external onlyOwner {
        gracePeriod = _gracePeriod;
        emit NewGracePeriod(_gracePeriod);
    }
    function setDelay(uint _delay) external onlyOwner {
        require(_delay >= MINIMUM_DELAY, "TimeLock::setDelay: Delay must exceed minimum delay.");
        require(_delay <= MAXIMUM_DELAY, "TimeLock::setDelay: Delay must not exceed maximum delay.");
        delay = _delay;
        emit NewDelay(_delay);
    }
}

// File: contracts/ConverterTimeLock.sol

// COPIED FROM https://github.com/compound-finance/compound-protocol/blob/master/contracts/Governance/GovernorAlpha.sol
// Copyright 2020 Compound Labs, Inc.
// Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
// 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
// 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
// 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

pragma solidity 0.6.12;



/**
 * Time lock for queued proposals to ensure the minimum delay between the end of voting and execution
 */
contract ConverterTimeLock {
    using SafeMath for uint;

    event NewAdmin(address indexed newAdmin);
    event NewPendingAdmin(address indexed newPendingAdmin);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature,  bytes data, uint eta);
    event QueueTransaction(bytes32 indexed txHash, address indexed target, uint value, string signature, bytes data, uint eta);

    // @dev the corresponding ConverterGovernorAlpha
    address public admin;

    ConverterGovernorAlphaConfig public config;

    mapping (bytes32 => bool) public queuedTransactions;

    IProxyTransaction converter;

    constructor(address admin_, address _converter, address _config) public {
        require(admin_ != address(0) && _converter != address(0) && _config != address(0), "Invalid address");
        admin = admin_;

        converter = IProxyTransaction(_converter);
        config = ConverterGovernorAlphaConfig(_config);
    }

    receive() external payable { }

    /**
     * @dev for the UnicGovernorAlphaFactory
     */
    function setAdmin(address _admin) public {
        require(msg.sender == admin, "TimeLock::acceptAdmin: Call must come from admin.");
        admin = _admin;

        emit NewAdmin(admin);
    }

    function queueTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public returns (bytes32) {
        require(msg.sender == admin, "TimeLock::queueTransaction: Call must come from admin.");
        require(eta >= getBlockTimestamp().add(config.delay()), "TimeLock::queueTransaction: Estimated execution block must satisfy delay.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = true;

        emit QueueTransaction(txHash, target, value, signature, data, eta);
        return txHash;
    }

    function cancelTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public {
        require(msg.sender == admin, "TimeLock::cancelTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        queuedTransactions[txHash] = false;

        emit CancelTransaction(txHash, target, value, signature, data, eta);
    }

    function executeTransaction(address target, uint value, string memory signature, bytes memory data, uint eta) public payable returns (bytes memory) {
        require(msg.sender == admin, "TimeLock::executeTransaction: Call must come from admin.");

        bytes32 txHash = keccak256(abi.encode(target, value, signature, data, eta));
        require(queuedTransactions[txHash], "TimeLock::executeTransaction: Transaction hasn't been queued.");
        require(getBlockTimestamp() >= eta, "TimeLock::executeTransaction: Transaction hasn't surpassed time lock.");
        require(getBlockTimestamp() <= eta.add(config.gracePeriod()), "TimeLock::executeTransaction: Transaction is stale.");

        queuedTransactions[txHash] = false;

        bytes memory callData;

        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = converter.forwardCall.value(value)(target, value, callData);
        require(success, "TimeLock::executeTransaction: Transaction execution reverted.");

        emit ExecuteTransaction(txHash, target, value, signature, data, eta);

        return returnData;
    }

    function getBlockTimestamp() internal view returns (uint) {
        // solium-disable-next-line security/no-block-members
        return block.timestamp;
    }
}

// File: contracts/interfaces/IUnicConverterGovernorAlphaFactory.sol

pragma solidity >=0.5.0;

interface IUnicConverterGovernorAlphaFactory {
    function createGovernorAlpha(
        address uToken,
        address guardian,
        address converterTimeLock,
        address config
    ) external returns (address);
}

// File: contracts/interfaces/IUnicConverterProxyTransactionFactory.sol

pragma solidity >=0.5.0;

interface IUnicConverterProxyTransactionFactory {
    event UnicGovernorAlphaCreated(address indexed governorAlpha, address indexed timelock);

    function createProxyTransaction(address uToken, address guardian) external returns (address, address);
}

// File: contracts/UnicConverterProxyTransactionFactory.sol

pragma solidity 0.6.12;



contract UnicConverterProxyTransactionFactory is IUnicConverterProxyTransactionFactory {

    // ConverterGovernorAlphaConfig
    address public config;

    IUnicConverterGovernorAlphaFactory public governorAlphaFactory;

    constructor (address _config, address _governorAlphaFactory) public {
        require(_config != address(0) && _governorAlphaFactory != address(0), "Invalid address");
        config = _config;
        governorAlphaFactory = IUnicConverterGovernorAlphaFactory(_governorAlphaFactory);
    }

    /**
     * Creates the contracts for the proxy transaction functionality for a given uToken
     */
    function createProxyTransaction(address uToken, address guardian) external override returns (address, address) {
        ConverterTimeLock converterTimeLock = new ConverterTimeLock(address(this), uToken, config);
        address converterGovernorAlpha = governorAlphaFactory.createGovernorAlpha(uToken, guardian, address(converterTimeLock), config);
        // Initialize timelock admin
        converterTimeLock.setAdmin(address(converterGovernorAlpha));

        emit UnicGovernorAlphaCreated(converterGovernorAlpha, address(converterTimeLock));
        
        return (converterGovernorAlpha, address(converterTimeLock));
    }
}