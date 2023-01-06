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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// Modified from OpenZeppelin Contracts (last updated v4.7.0) (utils/escrow/Escrow.sol)
// Written by wk0 (github), reachout for questions / concerns / vuln reports

pragma solidity 0.8.16;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/utils/Address.sol";

/**
 * @title BattleEscrow
 * Modified OpenZeppelin Escrow Contract.
 */

contract BattleEscrow is Ownable {
    using Address for address payable;

    event Deposited(address indexed payee, uint256 battleId, uint256 weiAmount);
    event Withdrawn(address indexed payee, uint256 battleId, uint256 weiAmount);

    mapping(address => mapping(uint256 => uint256)) private _deposits;

    function depositsOf(address payee, uint256 battleId)
        public
        view
        returns (uint256)
    {
        return _deposits[payee][battleId];
    }

    /**
     * @dev Stores the sent amount as credit to be withdrawn.
     * @param payee The destination address of the funds.
     *
     * Emits a {Deposited} event.
     */
    function deposit(address payee, uint256 battleId) public payable onlyOwner {
        uint256 amount = msg.value;
        _deposits[payee][battleId] += amount;
        emit Deposited(payee, battleId, amount);
    }

    /**
     * @dev Withdraw accumulated balance for a payee, forwarding all gas to the
     * recipient.
     *
     * WARNING: Forwarding all gas opens the door to reentrancy vulnerabilities.
     * Make sure you trust the recipient, or are either following the
     * checks-effects-interactions pattern or using {ReentrancyGuard}.
     *
     * @param payee The address whose funds will be withdrawn and transferred to.
     *
     * Emits a {Withdrawn} event.
     */
    function withdraw(
        address payee,
        address payable receiver,
        uint256 battleId,
        uint256 amount
    ) public onlyOwner {
        uint256 total = _deposits[payee][battleId];
        // require(total - amount > 0, "Not enough funds");
        // _deposits[payee] = total - amount;

        _deposits[payee][battleId] = 0;
        receiver.sendValue(total);

        emit Withdrawn(receiver, battleId, amount);
    }
}

// SPDX-License-Identifier: MIT
// Written by wk0 (github), reachout for questions / concerns / vuln reports
pragma solidity 0.8.16;

import "openzeppelin-contracts/access/Ownable.sol";
import "openzeppelin-contracts/security/ReentrancyGuard.sol";

import "./BattleEscrow.sol";

error BattleNotInitialized();
error BattleAlreadyMatched();
error BattleAlreadyFinished();
error BattleAlreadyClaimed();
error ForgedSignature();
error ForgedWithdrawSignature();
error StakeAlreadyWithdrawn();
error NotAllowedParticipant();
error ClaimFromNonParticipant();
error UserAlreadyWithdrawn();
error WithdrawFromNonParticipant();
error ZeroAddressNotAllowed();
error TransferFailed();

contract SimpleBattle is ReentrancyGuard, Ownable {
    BattleEscrow escrow;
    address public escrowAddr;
    address public judge;
    address public withdrawJudge;

    uint256 public nextBattleId;

    struct BattleParticipant {
        address user;
        uint256 stake;
        bool isWinner;
        bool hasWithdrawn;
    }

    struct Battle {
        BattleParticipant one;
        BattleParticipant two;
        bool claimed;
        bool matched;
    }
    mapping(uint256 => Battle) public battles;

    constructor(
        address _owner,
        address _judge,
        address _withdrawJudge
    ) {
        if (
            _owner == address(0) ||
            _judge == address(0) ||
            _withdrawJudge == address(0)
        ) {
            revert ZeroAddressNotAllowed();
        }
        escrow = new BattleEscrow();
        escrowAddr = address(escrow);
        judge = _judge;
        withdrawJudge = _withdrawJudge;
        _transferOwnership(_owner);
    }

    function emergencyWithdraw(address payable payee)
        external
        onlyOwner
        nonReentrant
    {
        if (payee == address(0)) {
            revert ZeroAddressNotAllowed();
        }
        uint256 balance = address(this).balance;
        (bool transferTx, ) = payee.call{value: balance}("");
        if (!transferTx) {
            revert TransferFailed();
        }
    }

    function emergencyRefund(uint256 battleId)
        external
        battleExists(battleId)
        onlyOwner
        nonReentrant
    {
        Battle storage selectedBattle = battles[battleId];
        if (!selectedBattle.claimed) {
            selectedBattle.claimed = true;
            battles[battleId] = selectedBattle;
            escrow.withdraw(
                selectedBattle.one.user,
                payable(selectedBattle.one.user),
                battleId,
                selectedBattle.one.stake
            );
            escrow.withdraw(
                selectedBattle.two.user,
                payable(selectedBattle.two.user),
                battleId,
                selectedBattle.two.stake
            );
        }
    }

    modifier battleExists(uint256 battleId) {
        require(battleId < nextBattleId, "Battle must exist!");
        _;
    }

    function getBattle(uint256 battleId)
        external
        view
        battleExists(battleId)
        returns (
            address,
            uint256,
            bool,
            bool,
            address,
            uint256,
            bool,
            bool,
            bool,
            bool
        )
    {
        Battle memory btl = battles[battleId];
        return (
            btl.one.user,
            btl.one.stake,
            btl.one.isWinner,
            btl.one.hasWithdrawn,
            btl.two.user,
            btl.two.stake,
            btl.two.isWinner,
            btl.two.hasWithdrawn,
            btl.claimed,
            btl.matched
        );
    }

    function initBattle(address challenging)
        external
        payable
        nonReentrant
        returns (uint256)
    {
        uint256 battleId = nextBattleId;
        nextBattleId++;
        battles[battleId] = Battle({
            one: BattleParticipant({
                user: msg.sender,
                stake: msg.value,
                isWinner: false,
                hasWithdrawn: false
            }),
            two: BattleParticipant({
                user: challenging,
                stake: 0,
                isWinner: false,
                hasWithdrawn: false
            }),
            claimed: false,
            matched: false
        });
        escrow.deposit{value: msg.value}(msg.sender, battleId);
        return battleId;
    }

    function joinBattle(uint256 battleId)
        external
        payable
        battleExists(battleId)
        nonReentrant
    {
        Battle storage selectedBattle = battles[battleId];
        if (selectedBattle.matched) {
            revert BattleAlreadyMatched();
        } else if (selectedBattle.claimed) {
            revert BattleAlreadyFinished();
        } else if (selectedBattle.two.user != msg.sender) {
            revert NotAllowedParticipant();
        } else {
            selectedBattle.matched = true;
            selectedBattle.two.stake = msg.value;
            battles[battleId] = selectedBattle;
            escrow.deposit{value: msg.value}(msg.sender, battleId);
        }
    }

    function claimProceeds(
        uint256 battleId,
        bytes32 hashMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external battleExists(battleId) {
        if (battles[battleId].claimed) {
            revert BattleAlreadyClaimed();
        }

        address signer = ecrecover(hashMsg, v, r, s);
        if (signer != judge) {
            revert ForgedSignature();
        } else {
            Battle storage selectedBattle = battles[battleId];

            if (msg.sender == selectedBattle.one.user) {
                selectedBattle.one.isWinner = true;
            } else if (msg.sender == selectedBattle.two.user) {
                selectedBattle.two.isWinner = true;
            } else {
                revert ClaimFromNonParticipant();
            }
            selectedBattle.claimed = true;
            battles[battleId] = selectedBattle;

            escrow.withdraw(
                selectedBattle.one.user,
                payable(msg.sender),
                battleId,
                selectedBattle.one.stake
            );
            escrow.withdraw(
                selectedBattle.two.user,
                payable(msg.sender),
                battleId,
                selectedBattle.two.stake
            );
        }
    }

    function withdrawStake(
        uint256 battleId,
        bytes32 hashMsg,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external battleExists(battleId) {
        Battle storage selectedBattle = battles[battleId];

        if (selectedBattle.claimed) {
            revert BattleAlreadyClaimed();
        }

        if (selectedBattle.one.user == msg.sender) {
            if (selectedBattle.one.hasWithdrawn) {
                revert UserAlreadyWithdrawn();
            }
        } else if (selectedBattle.two.user == msg.sender) {
            if (selectedBattle.two.hasWithdrawn) {
                revert UserAlreadyWithdrawn();
            }
        } else {
            revert WithdrawFromNonParticipant();
        }

        address signer = ecrecover(hashMsg, v, r, s);
        if (signer != withdrawJudge) {
            revert ForgedWithdrawSignature();
        } else {
            escrow.withdraw(
                selectedBattle.one.user,
                payable(selectedBattle.one.user),
                battleId,
                selectedBattle.one.stake
            );
            escrow.withdraw(
                selectedBattle.two.user,
                payable(selectedBattle.two.user),
                battleId,
                selectedBattle.two.stake
            );
        }
    }
}