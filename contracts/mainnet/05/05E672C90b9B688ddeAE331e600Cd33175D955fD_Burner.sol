// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBurnable is IERC20 {
    function burn(uint256 amount) external;
}

interface ILocker {
    function owner() external returns (address);
    function changeOwner(address newOwner) external;
}

interface IWETH {
    function deposit() external payable;
    function withdraw(uint wad) external;
}

contract Burner {
    using SafeERC20 for IERC20;

    struct Player {
        uint16 ID;      // probably not going to have more than 65K participants
        uint128 score;   // up to 16,777,216 WHOLE tokens burned per player
    }

    struct PlayerData {
        address player;
        uint128 score;
        uint mrfBalance;
        uint mrfAllowance;
    }

    struct GameData {
        uint endTime;
        uint playerCount;
        uint totalBurnt;
    }

    address immutable token;                // the burnable token
    address immutable WETH;                 // address of the WETH contract
    address immutable locker;               // the liquidity locker acquiring ether fees
    address owner;                          // owner address
    address public frogContract;                   // address of the ownership destination for the liquidity locker
    uint16 players;                         // total amount of players, used to determine player ID
    uint public endTime;                           // the timestamp that the game absolutely ends at
    uint trackedWETH;                       // how much wrapped ether is tracked an counted towards the final prize amount
    uint totalBurnt;                        // track total amount burnt
    uint constant BONUS_TIME = 60 minutes;  // how much time to increase the end time by when someone changes the leaderboard
    uint constant public WINNER_MAX = 10;          // how many top players to pay out?
    uint constant MINIMUM_PLAY = 100e18;    // how many tokens, minimum, to play each tx?
    uint constant poolA = 511310;
    uint constant poolB = 511313;
    mapping (address => uint16) public IDs;        // mapping of player addresses to IDs
    mapping (uint16 => address) public addresses;  // mapping of player IDs to addresses
    mapping (uint16 => uint128) public score;       // mapping of player addresses to scores
    mapping (uint16 => bool) public claimed;       // mapping of player IDs to boolean indicating if they claimed already
    Player[WINNER_MAX] public top;          // store packed player data because need to load this each play()
    bool potBuilt;                          // boolean indicating final pot status

    constructor(address _token, address _WETH, address _locker) {
        token = _token;
        WETH = _WETH;
        locker = _locker;
        owner = msg.sender;
    }

    receive() external payable {}

    function gameOver()
    external view returns (bool) {
        return endTime != 0 && block.timestamp > endTime;
    }
    function leaderboard(uint _topIndex)
    external view returns (address) {
        require(_topIndex < WINNER_MAX, "Invalid index");        // index must be less than max number of winners
        return addresses[top[_topIndex].ID];
    }
    function setFrogContract(address _frogContract, uint _gameTime)
    external {
        require(msg.sender == owner, "Not owner");
        frogContract = _frogContract;
        endTime = uint(block.timestamp) + _gameTime;
    }
    function emergencyOwnershipTransfer()
    external {
        require(msg.sender == owner, "Not owner");      // in case this contract is bricked somehow...
        address this_ = address(this);                  // shorthand
        if (ILocker(locker).owner() == this_)
            ILocker(locker).changeOwner(owner);         // transfer lp ownership back to Mr F
        IERC20 WETH_ = IERC20(WETH);                    // load WETH interface
        uint wethBal = WETH_.balanceOf(this_);          // load WETH balance
        if (wethBal > 0)
            IWETH(WETH).withdraw(wethBal);              // withdraw ETH from WETH contract
        if (this_.balance > 0)
            payable(owner).transfer(this_.balance);     // transfer the ether out to Mr F
    }
    function getData()
    external view returns (GameData memory game) {
        game.endTime = endTime;
        game.totalBurnt = totalBurnt;
        game.playerCount = players;
        return game;
    }
    function getPlayers(uint16 start, uint16 max)
    external view returns (PlayerData[] memory) {
        uint16 last = start + max;
        if (last > players) {
            last = players;
        }
        PlayerData[] memory data = new PlayerData[](last-start);
        uint i;
        for(uint16 x = start; x < last; x++) {
            data[i] = getPlayer(addresses[x+1]);    // IDs are stored 1-indexed but accessed via 0-index
            i++;
        }
        return data;
    }
    function getPlayer(address addr)
    public view returns (PlayerData memory player) {
        uint16 x = IDs[addr];
        player.player = addr;
        player.mrfBalance = IERC20(token).balanceOf(addr);
        player.mrfAllowance = IERC20(token).allowance(addr, address(this));
        player.score = score[x];
        return player;
    }
    function _burn(address _from, uint _amount)
    internal {
        totalBurnt += _amount;                                           // increment total burnt
        IERC20(token).safeTransferFrom(_from, address(this), _amount);   // transfer tokens to this contract
        IBurnable(token).burn(_amount);                                  // burn tokens
    }
    function _rank(uint16 _playerID, uint128 _score)
    internal {
        Player[WINNER_MAX] memory data = top;   // load data into memory
        uint place = WINNER_MAX;                // initial placement
        for(uint x = WINNER_MAX; x > 0; x--)        // loop backwards
            if(_score > data[x-1].score)            // if their score is more than the placed score
                place = x-1;                            // update their placement
            else                                    // otherwise
                break;                                  // break out of loop
        if(place != WINNER_MAX) {               // if they have a valid placement
            if (place != WINNER_MAX - 1) {
                uint start = WINNER_MAX - 1;            // start looping from the second to last player
                uint end = place + 1;

                for(uint x = start; x >= end; x--) {  // loop backwards up to their placement
                    data[x].ID = data[x-1].ID;              // replace old data
                    data[x].score = data[x-1].score;        // replace old data
                    top[x] = data[x];                   // write to storage
                }
            }

            data[place].ID = _playerID;             // replace the current rank data
            data[place].score = _score;             // replace the current rank data
            top[place] = data[place];               // write to storage
            if(endTime > 0)   // if game has started
                endTime += BONUS_TIME;
        }
    }

    function _pullFees()
    internal {
        bool ignoreMe;
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolA));  // attempt to pull liquidity fees from poolA
        (ignoreMe,) = address(locker).call(abi.encodeWithSignature("withdrawTradingFees(uint256)", poolB));  // attempt to pull liquidity fees from poolB
        ILocker(locker).changeOwner(frogContract);       // transfer ownership to Mr Frog
    }
    function _buildPot()
    internal {
        address this_ = address(this);          // shorthand
        uint Ebal = this_.balance;              // load current ether balance into memory
        if(Ebal > 0)                            // if current ether balance is greater than zero
            IWETH(WETH).deposit{value: Ebal}(); // deposit ether balance into WETH contract
        IERC20 WETH_ = IERC20(WETH);            // load WETH interface
        if(ILocker(locker).owner() == this_)    // if this contract still has ownership of the liquidity locker
            _pullFees();                            // pull fees from LP - this comes in the form of WETH
        trackedWETH = WETH_.balanceOf(this_);   // what is the current WETH balance?
        potBuilt = true;                        // the final pot is now built
    }
    function receiveApproval(address _receiveFrom, uint256 _amount, address _token, bytes memory _data)
    public {
        require(msg.sender == token, "Invalid token");
        _play(_amount, _receiveFrom);
    }
    function play(uint _amount)
    external {
        _play(_amount, msg.sender);
    }
    function _play(uint256 _amount, address _caller)
    internal {
        require(endTime == 0 || block.timestamp <= endTime, "Game over");  // only proceed if we are before the end time
        require(_amount >= MINIMUM_PLAY, "Amount too low");                // only proceed if the intended play amount is greater than or equal to the minimum
        uint16 playerID = IDs[_caller];                                     // load player ID into memory
        if(playerID == 0) {                                                // if the caller is not tracked as a player yet
            players += 1;                                                      // increase player count
            playerID = players;                                                // determine their player ID
            IDs[_caller] = playerID;                                           // assign their player ID to their address
            addresses[playerID] = _caller;                                     // assign their player address to their ID
        }
        uint128 newScore = score[playerID] + uint128(_amount);
        score[playerID] = newScore;           // increase the all-time score for the caller
        _rank(IDs[_caller], newScore);         // attempt to modify the top player placement
        _burn(_caller, _amount);                 // transfer and burn whole token amount
    }
    function claim(uint _topIndex)
    external {
        require(_topIndex < WINNER_MAX, "Invalid index");        // index must be less than max number of winners
        require(endTime != 0, "Game not started");               // game must have begun
        require(block.timestamp > endTime, "Game not over");     // only proceed if the game is actually over
        address caller = msg.sender;                             // shorthand
        uint16 playerID = IDs[caller];                           // load player ID into memory
        require(playerID > 0, "Invalid ID");                     // only proceed if they actually played
        require(playerID == top[_topIndex].ID, "Invalid ID");    // only proceed if the player ID matches that of a top player
        require(claimed[playerID] == false, "Already claimed");  // only proceed if the player hasn't claimed before
        claimed[playerID] = true;                                // the caller has claimed
        require(score[playerID] > 0, "Not a winner");            // only proceed if the player score is greater than zero
        if(potBuilt == false)                                    // if the final pot hasn't been built yet
            _buildPot();                                         // build it
        uint prize = trackedWETH / WINNER_MAX;                   // calculate prize amount
        IWETH(WETH).withdraw(prize);                             // withdraw ETH from WETH contract
        payable(caller).transfer(prize);                         // transfer the claimed ether out to the caller
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
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
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

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