// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../utils/Ownable.sol";
import "../token/ILitlabGamesToken.sol";
import "../metatx/LitlabContext.sol";

/// SmartContract for CyberTitans game modality. It's a centralized SmartContract.
/// Working mode:
/// - This SmartContract is intended to manage the user tournament join, retirement and distribute prizes
/// - Previously, users have approved this contract to spend LitlabGames ERC20 token in the litlabgames webpage
/// - Then, when users want to connect to the game, when matchmaking is done (8 playes), in the server, we call the functions:
///     - createTournament: To create a new tournament. Returns a tournament id
///     - joinTournament: To join a new user to a tournament
///     - retireTournament: To retire a user from a tournament
///     - finalizeTournament: When tournament has finished, send the winner wallets and distribute the prizes according the prizes matrix
contract CyberTitansTournament is LitlabContext, Ownable {
    using SafeERC20 for IERC20;

    struct TournamentStruct {
        uint256 bet;
        address token;
        uint24 numOfPlayers;
        uint64 startDate;
        uint64 endDate;
    }
    mapping(uint256 => TournamentStruct) private tournaments;
    uint256 tournamentCounter;

    uint256 public maxBetAmount;                    // Security. Don't let create a game with a bet greater than this variable
    uint16 public penalty;                          // If the user joint to a tournament and wants to retire before starting, there's a penalty he has to pay.

    address public wallet;
    address public manager;
    address public litlabToken;

    uint32[][8] public prizes;
    uint32[][8] public players;
    uint32[][12] public tops;
    uint8[8] public winners = [3, 4, 6, 8, 16, 32, 64, 128];

    uint16 public rake = 25;
    uint16 public fee = 25;
    bool private pause;

    event onTournamentCreated(uint256 _tournamentId);
    event onTournamentFinalized(uint256 _tournamentId);
    event onJoinedTournament(uint256 _id, address _player);
    event onRetiredTournament(uint256 _id, address _player);
    event onEmergencyWithdraw(uint256 _balance, address _token);

    constructor(address _forwarder, address _manager, address _wallet, address _litlabToken, uint256 _maxBetAmount, uint8 _penalty) LitlabContext(_forwarder) {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
        maxBetAmount = _maxBetAmount;
        penalty = _penalty;

        _buildArrays();
    }

    function _buildArrays() internal {
        prizes[0] = [5000000, 3000000, 2000000];
        prizes[1] = [4000000, 2700000, 1900000, 1400000];
        prizes[2] = [3200000, 2200000, 1650000, 1250000, 900000, 800000];
        prizes[3] = [2975000, 1875000, 1475000, 1125000, 850000, 700000, 550000, 450000];
        prizes[4] = [2575000, 1705000, 1100000, 850000, 625000, 500000, 400000, 317000, 241000];
        prizes[5] = [2000000, 1400000, 945000, 770000, 600000, 500000, 400000, 312500, 164063, 110000];
        prizes[6] = [1825000, 1325000, 842000, 700000, 562500, 460000, 360000, 265000, 130000, 73000, 45390];
        prizes[7] = [1780000, 1275000, 785000, 609200, 507500, 412000, 320000, 232500, 105000, 51000, 31712, 22000];

        players[0] = [1,8];
        players[1] = [9,16];
        players[2] = [17,32];
        players[3] = [33,64];
        players[4] = [65,128];
        players[5] = [129,256];
        players[6] = [257,512];
        players[7] = [512,1024];

        tops[0] = [1,1];
        tops[1] = [2,2];
        tops[2] = [3,3];
        tops[3] = [4,4];
        tops[4] = [5,5];
        tops[5] = [6,6];
        tops[6] = [7,7];
        tops[7] = [8,8];
        tops[8] = [9,16];
        tops[9] = [17,32];
        tops[10] = [33,64];
        tops[11] = [65,128];
    }

    function changeWallets(address _manager, address _wallet, address _litlabToken) external onlyOwner {
        manager = _manager;
        wallet = _wallet;
        litlabToken = _litlabToken;
    }

    function updateFees(uint16 _fee, uint16 _rake, uint16 _penalty) external onlyOwner {
        fee = _fee;
        rake = _rake;
        penalty = _penalty;
    }

    function changeArrays(uint32[][8] calldata _prizes, uint32[][8] calldata _players, uint32[][12] calldata _tops, uint8[8] calldata _winners) external onlyOwner {
        for (uint256 i=0; i<_prizes.length; i++) prizes[i] = _prizes[i];
        for (uint256 i=0; i<_players.length; i++) players[i] = _players[i];
        for (uint256 i=0; i<_tops.length; i++) tops[i] = _tops[i];
        for (uint256 i=0; i<_winners.length; i++) winners[i] = _winners[i];
    }

    function changePause() external onlyOwner {
        pause = !pause;
    }

    function createTournament(address _token, uint64 _startDate, uint256 _amount) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");
        require(_amount != 0, "BadAmount");
        require(_amount <= maxBetAmount, "MaxAmount");
        require(_token != address(0), "BadToken");

        uint tournamentId = ++tournamentCounter;
        TournamentStruct storage tournament = tournaments[tournamentId];
        tournament.token = _token;
        tournament.bet = _amount;
        tournament.startDate = _startDate;

        emit onTournamentCreated(tournamentId);
    }

    function joinTournamentWithCTT(uint256 _id, address _user) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");

        TournamentStruct storage tournament = tournaments[_id];
        if (tournament.startDate > 0) require(block.timestamp >= tournament.startDate, "NotStarted");
        if (tournament.endDate > 0) require(block.timestamp <= tournament.endDate, "Ended");

        tournament.numOfPlayers++;
        IERC20(tournament.token).safeTransferFrom(wallet, address(this), tournament.bet);
        
        emit onJoinedTournament(_id, _user);
    }

    function joinTournament(uint256 _id) external {
        require(pause == false, "Paused");

        TournamentStruct storage tournament = tournaments[_id];
        if (tournament.startDate > 0) require(block.timestamp >= tournament.startDate, "NotStarted");
        if (tournament.endDate > 0) require(block.timestamp <= tournament.endDate, "Ended");
        
        tournament.numOfPlayers++;
        IERC20(tournament.token).safeTransferFrom(_msgSender(), address(this), tournament.bet);

        emit onJoinedTournament(_id, _msgSender());
    }

    function getTournament(uint256 _id) external view returns(TournamentStruct memory) {
        return tournaments[_id];
    }

    function retireFromTournamentWitCTT(uint256 _id, address _wallet) external {
        require(msg.sender == manager, "OnlyManager");
        require(pause == false, "Paused");
        
        // TODO. Pending of decision
        TournamentStruct memory tournament = tournaments[_id];
        IERC20(tournament.token).safeTransfer(_wallet, (tournament.bet - (tournament.bet * penalty / 1000)));
        IERC20(tournament.token).safeTransfer(wallet, (tournament.bet * penalty / 1000));

        emit onRetiredTournament(_id, _wallet);
    }

    function retireFromTournament(uint256 _id) external {
        require(pause == false, "Paused");
        
        // TODO. Pending of decision
        TournamentStruct memory tournament = tournaments[_id];
        IERC20(tournament.token).safeTransfer(_msgSender(), (tournament.bet - (tournament.bet * penalty / 1000)));
        IERC20(tournament.token).safeTransfer(wallet, (tournament.bet * penalty / 1000));

        emit onRetiredTournament(_id, _msgSender());
    }

    function finalizeTournament(uint256 _tournamentId, address[] calldata _winners) external {
        require(_msgSender() == manager, "OnlyManager");
        require(pause == false, "Paused");

        TournamentStruct memory tournament = tournaments[_tournamentId];
        uint256 index = _getPrizesColumn(tournament.numOfPlayers);
        require(winners[index] == _winners.length, "BadWinners");

        uint256 totalBet = tournament.bet * tournament.numOfPlayers;
        uint256 _rake = totalBet * rake / 1000;
        uint256 _fee = totalBet * fee / 1000;

        uint256 pot = totalBet - (_rake + _fee);

        uint8 i;
        do {
            uint256 prizePercentage = _getPrize(index, i+1);
            uint256 prize = (pot * prizePercentage) / (10 ** 7);
            if (prize != 0) IERC20(tournament.token).safeTransfer(_winners[i], prize);
            ++i;
        } while(i<_winners.length);

        if (tournament.token == litlabToken) {
            ILitlabGamesToken(tournament.token).burn(_rake);
            IERC20(tournament.token).safeTransfer(wallet, _fee);
        } else {
            IERC20(tournament.token).safeTransfer(wallet, (_rake + _fee));
        }

        emit onTournamentFinalized(_tournamentId);
    }

    function _getPrizesColumn(uint24 _numOfPlayers) internal view returns(uint16) {
        uint16 index;
        do {
            if (_numOfPlayers >= players[index][0] && _numOfPlayers <= players[index][1]) break;
            ++index;
        } while (index < 8);
    
        assert(index < 8);
        return index;
    }

    function _getPrize(uint256 _index, uint256 _position) internal view returns(uint32) {
        uint8 index;
        do {
            if (_position >= tops[index][0] && _position <= tops[index][1]) break;
            ++index;
        } while(index < 12);

        assert(index < 12);
        return prizes[_index][index];
    }

    function emergencyWithdraw(address _token) external onlyOwner {
        uint256 balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).safeTransfer(owner, balance);

        emit onEmergencyWithdraw(balance, _token);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

/// @title Ownable
/// @notice Copied from openzeppelin Ownable contract and adapted to add the functionlity of claim ownership by another wallet instead of sending the ownership.
/// This is to avoid errors sending the permission to an address with no private key (example. A SmartContract or an address with the missing private key)
abstract contract Ownable {
    address public owner;
    address public ownerPendingClaim;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event NewOwnershipProposed(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "OnlyOwner");
        _;
    }

    function proposeChangeOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "ZeroAddress");
        ownerPendingClaim = newOwner;

        emit NewOwnershipProposed(msg.sender, newOwner);
    }

    function claimOwnership() external {
        require(msg.sender == ownerPendingClaim, "OnlyProposedOwner");

        ownerPendingClaim = address(0);
        _transferOwnership(msg.sender);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface ILitlabGamesToken is IERC20 {
    function burn(uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

contract LitlabContext is ERC2771Context {

    constructor (address _forwarder) ERC2771Context(_forwarder) {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (metatx/ERC2771Context.sol)

pragma solidity ^0.8.9;

import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable
    address private immutable _trustedForwarder;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}