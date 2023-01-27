/**
 *Submitted for verification at Etherscan.io on 2023-01-27
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
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
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
    function transferFrom(
        address sender,
        address recipient,
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

contract CoinFlip is Ownable {
    using Address for address;
    using SafeMath for uint256;

    event GameStarted(
        address indexed better,
        address token,
        uint256 wager,
        uint8 predictedOutcome,
        uint32 id
    );

    event GameFinished(
        address indexed better,
        address token,
        bool winner,
        uint256 wager,
        uint32 id
    );

    event PayoutComplete(
        address indexed winner,
        address token,
        uint256 winnings
    );

    event DevFeeReceiverChanged(
        address oldReceiver,
        address newReceiver
    );

    event HouseFeeReceiverChanged(
        address oldReceiver,
        address newReceiver
    );

    event DevFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    event HouseFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    event ReferrerFeePercentageChanged(
        uint8 oldPercentage,
        uint8 newPercentage
    );

    struct Game {
        address better;
        address token;
        uint32 id;
        uint8 predictedOutcome;
        bool finished;
        bool winner;
        uint256 wager;
        uint256 startBlock;
    }

    struct Queue {
        uint32 start;
        uint32 end;
    }

    address public _houseFeeReceiver = address(0x32634D7a09AFb82550dB39644172aB138aAE0e8A);
    uint8 public _houseFeePercentage = 30; 

    address public _devFeeReceiver = address(0x32634D7a09AFb82550dB39644172aB138aAE0e8A);
    uint8 public _devFeePercentage = 3; //0.3%

    uint8 public _referrerFeePercentage = 5; 

    mapping (address => bool) public _team;
    mapping (address => bool) public _isBlacklisted;

    // Game Details
    mapping (uint256 => Game) public _games; // Game ID -> Game
    Queue private _queuedGames;
    bool _gameEnabled = true; // If we want to pause the flip game
    uint32 public _queueResetSize = 1; // How many games we want to queue before finalizing a game
    uint256 public _blockWaitTime = 2; // How many blocks we want to wait before finalizing a game
    uint256 private _globalQueueSize;
    mapping (address => mapping (address => uint256)) public _winnings;
    mapping (address => uint256) public _minBetForToken;
    mapping (address => uint256) public _maxBetForToken;
    mapping (address => address) public _referrer;

    modifier onlyTeam {
        _onlyTeam();
        _;
    }

    function _onlyTeam() private view {
        require(_team[_msgSender()], "Only a team member may perform this action");
    }

    constructor() 
    {
        _team[owner()] = true;
    }

    // To recieve BNB from anyone, including the router when swapping
    receive() external payable {}

    function withdrawBNB(uint256 amount) external onlyOwner {
        (bool sent, bytes memory data) = _msgSender().call{value: amount}("");
        require(sent, "Failed to send BNB");
    }

    function enterGame(uint256 wager, uint8 outcome, address token, address referrer) external payable {
        require(_gameEnabled, "Game is currently paused");
        require(!_isBlacklisted[_msgSender()], "This user is blacklisted");
        require(!(_msgSender().isContract()), "Contracts are not allowed to play the game");
        require(msg.sender == tx.origin, "Sender must be the same as the address that started the tx");

        IERC20 gameToken = IERC20(token);
        if (_minBetForToken[token] != 0) {
            require(wager >= _minBetForToken[token], "This wager is lower than the minimum bet for this token");
        }
        if (_maxBetForToken[token] != 0) {
            require(wager <= _maxBetForToken[token], "This wager is larger than the maximum bet for this token");
        }
        require(outcome < 2, "Must choose heads or tails (0 or 1)");

        if (token != address(0x0)) {
            require(wager <= gameToken.balanceOf(address(this)).div(2), "Can't bet more than the amount available in the contract to pay you");
            gameToken.transferFrom(_msgSender(), address(this), wager);
        } else {
            require(wager <= address(this).balance.div(2), "Can't bet more than the amount available in the contract to pay you");
            require(msg.value == wager, "Must send same amount as specified in wager");
        }

        if (referrer != address(0x0) && referrer != _msgSender() && (_referrer[_msgSender()] == address(0x0))) {
            _referrer[_msgSender()] = referrer;
        }

        emit GameStarted(_msgSender(), token, wager, outcome, _queuedGames.end);
        _games[_queuedGames.end++] = Game({better: _msgSender(), token: token, id: _queuedGames.end, predictedOutcome: outcome, finished: false, winner: false, wager: wager, startBlock: block.number});
        _globalQueueSize++;

        completeQueuedGames();
    }

    function completeQueuedGames() internal {
        while (_globalQueueSize > _queueResetSize) {
            Game storage game = _games[_queuedGames.start];
            if (block.number < game.startBlock.add(_blockWaitTime) ||
                game.better == _msgSender()) {
                // Wait _blockWaitTime before completing this game, to avoid exploits.
                // Don't allow someone to complete their own game
                break;
            }
            _queuedGames.start++;
            _globalQueueSize--;

            game.winner = (rand() % 2) == game.predictedOutcome;

            if (game.winner) {
                _winnings[game.better][game.token] += (game.wager * 2);
            }

            game.finished = true;

            emit GameFinished(game.better, game.token, game.winner, game.wager, game.id);
        }
    }

    function rand() public view returns(uint256)
    {
        uint256 seed = uint256(keccak256(abi.encodePacked(
            block.timestamp + block.difficulty +
            ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (block.timestamp)) +
            block.gaslimit + 
            ((uint256(keccak256(abi.encodePacked(_msgSender())))) / (block.timestamp)) +
            block.number + _globalQueueSize
        )));

        return seed;
    }

    // If you need to withdraw BNB, tokens, or anything else that's been sent to the contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
        IERC20 tokenContract = IERC20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }

    function setTeamMember(address member, bool isTeamMember) external onlyOwner {
        _team[member] = isTeamMember;
    }

    function setHouseFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Can't set the zero address as the receiver");
        require(newReceiver != _houseFeeReceiver, "This is already the house fee receiver");

        emit HouseFeeReceiverChanged(_houseFeeReceiver, newReceiver);

        _houseFeeReceiver = newReceiver;
    }

    function setHouseFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _houseFeePercentage, "This is already the house fee percentage");
        require(newPercentage <= 40, "Cannot set house fee percentage higher than 4 percent");

        emit HouseFeePercentageChanged(_houseFeePercentage, newPercentage);

        _houseFeePercentage = newPercentage;
    }

    function setDevFeeReceiver(address newReceiver) external onlyOwner {
        require(newReceiver != address(0x0), "Can't set the zero address as the receiver");
        require(newReceiver != _devFeeReceiver, "This is already the dev fee receiver");

        emit DevFeeReceiverChanged(_devFeeReceiver, newReceiver);

        _devFeeReceiver = newReceiver;
    }

    function setDevFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _devFeePercentage, "This is already the dev fee percentage");
        require(newPercentage <= 5, "Cannot set dev fee percentage higher than 0.5 percent");

        emit DevFeePercentageChanged(_devFeePercentage, newPercentage);

        _devFeePercentage = newPercentage;
    }

    function setReferrerFeePercentage(uint8 newPercentage) external onlyOwner {
        require(newPercentage != _referrerFeePercentage, "This is already the referrer fee percentage");
        require(newPercentage <= 20, "Cannot set dev fee percentage higher than 2 percent");

        emit ReferrerFeePercentageChanged(_referrerFeePercentage, newPercentage);

        _referrerFeePercentage = newPercentage;
    }

    function setQueueSize(uint32 newSize) external onlyTeam {
        require(newSize != _queueResetSize, "This is already the queue size");

        _queueResetSize = newSize;
    }

    function setGameEnabled(bool enabled) external onlyTeam {
        require(enabled != _gameEnabled, "Must set a new value for gameEnabled");

        _gameEnabled = enabled;
    }

    function setMinBetForToken(address token, uint256 minBet) external onlyTeam {
        _minBetForToken[token] = minBet;
    }

    function setMaxBetForToken(address token, uint256 maxBet) external onlyTeam {
        _maxBetForToken[token] = maxBet;
    }

    function setBlacklist(address wallet, bool isBlacklisted) external onlyTeam {
        _isBlacklisted[wallet] = isBlacklisted;
    }

    function forceCompleteQueuedGames() external onlyTeam {
        completeQueuedGames();
    }

    function claimWinnings(address token) external {
        require(!_isBlacklisted[_msgSender()], "This user is blacklisted");
        uint256 winnings = _winnings[_msgSender()][token];
        require(winnings > 0, "This user has no winnings to claim");
        IERC20 gameToken = IERC20(token);

        if (token != address(0x0)) {
            require(winnings <= gameToken.balanceOf(address(this)), "Not enough tokens in the contract to distribute winnings");
        } else {
            require(winnings <= address(this).balance, "Not enough BNB in the contract to distribute winnings");
        }

        delete _winnings[_msgSender()][token];

        uint256 feeToHouse = winnings.mul(_houseFeePercentage).div(1000);
        uint256 feeToDev = winnings.mul(_devFeePercentage).div(1000);
        uint256 feeToReferrer = 0;

        address referrer = _referrer[_msgSender()];
        if (referrer != address(0x0)) {
            feeToReferrer = winnings.mul(_referrerFeePercentage).div(1000);
        }

        uint256 winningsToUser = winnings.sub(feeToHouse).sub(feeToDev).sub(feeToReferrer);

        if (token != address(0x0)) {
            gameToken.transfer(_houseFeeReceiver, feeToHouse);
            gameToken.transfer(_devFeeReceiver, feeToDev);

            if (feeToReferrer > 0) {
                gameToken.transfer(referrer, feeToReferrer);
            }

            gameToken.transfer(_msgSender(), winningsToUser);
        } else {
            _devFeeReceiver.call{value: feeToDev}("");
            _houseFeeReceiver.call{value: feeToHouse}("");

            if (feeToReferrer > 0) {
                referrer.call{value: feeToReferrer}("");
            }

            _msgSender().call{value: winningsToUser}("");
        }

        completeQueuedGames();

        emit PayoutComplete(_msgSender(), token, winningsToUser);
    }
}