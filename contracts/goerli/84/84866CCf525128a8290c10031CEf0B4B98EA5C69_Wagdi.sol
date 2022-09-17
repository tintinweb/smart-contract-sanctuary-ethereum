/**
 *Submitted for verification at Etherscan.io on 2022-09-17
*/

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: WAGDI/contracts/contracts/Wagdi.sol



pragma solidity ^0.8.4;


contract Wagdi {
    using Address for address payable;

    enum Selection {
        ROCK,
        PAPER,
        SCISSORS,
        LIZZARD,
        SPOCK
    }

    uint8 private constant selection_length = 4;

    enum State {
        FIRST_COMMIT,
        FIRST_REVEAL,
        FINISHED
    }

    struct Player {
        address addr;
        bytes32 commitment;
        Selection reveal;
    }

    struct Game {
        uint256 gameId;
        Player player1;
        Player player2;
        uint256 deadline;
        State state;
    }

    struct PlayerBalance {
        uint256 stakedBalance;
        uint256 withdrawBalance;
    }

    mapping(uint256 => Game) public games;
    mapping(address => PlayerBalance) public balances;

    uint256 internal gameID;
    uint256 internal constant DEADLINE = 15 minutes;
    uint256 public constant INITIAL_STAKE = 0.001 ether;
    uint256 public constant CUT = INITIAL_STAKE / 2;

    Player public player1;
    Player public player2;

    error NotEnoughStake();
    error GameExpired();
    error WrongState();
    error YouCantPlayAgainstYourself();
    error YouAreNotAllowedToCall();
    error WrongSelection();
    error NotEnoughBalance();
    error GameNotExpired();
    error GameHasEnded();

    address public immutable DONATION_ADDRESS;

    constructor(address donation) {
        DONATION_ADDRESS = donation;
    }

    // create game:
    // one player creates game, game has uniqe id, player1 transfers token and pass selection param to contract
    // emit event: GameCreated(id, timestamp, sender)
    function createGame(bytes32 _commitment) public payable returns(uint256){
        if (msg.value != INITIAL_STAKE) revert NotEnoughStake();
        balances[msg.sender].stakedBalance += msg.value;
        Game storage game = games[gameID];

        game.gameId = gameID;
        game.player1.addr = msg.sender;
        game.player1.commitment = _commitment;
        game.deadline = block.timestamp + DEADLINE;
        game.state = State.FIRST_COMMIT;

        emit GameCreated(
            gameID,
            block.timestamp,
            game.deadline,
            msg.sender,
            game.state
        );

        gameID++;

        return game.gameId;
    }

    // join game by id:
    // player2 joins game, player2 transfers token and pass selection param to contract
    // emit event: GameJoined(id, timestamp, sender)
    // TODO; check check for correctness of selection
    function joinGame(
        uint256 _gameId,
        Selection _selection,
        bytes memory _passphrase
    ) public payable {
        if (msg.value != INITIAL_STAKE) revert NotEnoughStake();
        if (!validateSelection(_selection)) revert WrongSelection();
        balances[msg.sender].stakedBalance += msg.value;

        Game storage game = games[_gameId];

        if (block.timestamp > game.deadline) revert GameExpired();
        if (game.state != State.FIRST_COMMIT) revert WrongState();
        if (msg.sender == game.player1.addr)
            revert YouCantPlayAgainstYourself();

        game.player2.addr = msg.sender;
        game.player2.commitment = keccak256(
            abi.encodePacked(_selection, _passphrase)
        );
        game.deadline = block.timestamp + DEADLINE;
        game.state = State.FIRST_REVEAL;
        game.player2.reveal = _selection;

        emit GameJoined(
            _gameId,
            block.timestamp,
            game.deadline,
            msg.sender,
            game.state
        );
    }

    // reveal:
    // player1 passes passphrase and gameId to contract
    // player2 passes passphrase and gameId to contract + check who won, update amounts
    // TODO: selection must exist
    function reveal(
        uint256 _gameId,
        Selection _selection,
        bytes memory _passphrase
    ) public {
        Game storage game = games[_gameId];

        if (block.timestamp > game.deadline) revert GameExpired();
        if (game.state != State.FIRST_REVEAL) revert WrongState();
        if (msg.sender != game.player1.addr) revert YouAreNotAllowedToCall();
        if (!validateSelection(_selection)) revert WrongSelection();

        address winner;
        address loser;

        bytes32 commitment = keccak256(
            abi.encodePacked(_selection, _passphrase)
        );

        if (commitment != game.player1.commitment) {
            // player1 loses
            winner = game.player2.addr;
            loser = game.player1.addr;

            // pl1: staked 1 eth
            // pl2: staked 1 eth
            // pl1 loses the 1 eth
            // pl2 wins 0.5 eth and 0.5 eth goes to donation

            removeGameStake(game);

            // add to winner withdraw balance:
            balances[winner].withdrawBalance += INITIAL_STAKE + CUT;
            balances[address(this)].withdrawBalance += CUT;
        } else {
            // who won?
            game.player1.reveal = _selection;
            if (game.player1.reveal == game.player2.reveal) {
                // nobody won
                removeGameStake(game);

                // add stakes to winners withdraw balance:
                balances[game.player1.addr].withdrawBalance += CUT;
                balances[game.player2.addr].withdrawBalance += CUT;
                balances[address(this)].withdrawBalance += INITIAL_STAKE;
                winner = address(this);
            } else {
                (bool pl1, ) = evaluateGame(
                    game.player1.reveal,
                    game.player2.reveal
                );

                game.state = State.FINISHED;

                if (pl1) {
                    winner = game.player1.addr;
                    loser = game.player2.addr;
                } else {
                    winner = game.player2.addr;
                    loser = game.player1.addr;
                }

                removeGameStake(game);
                // add stakes to winner withdraw balance:
                balances[winner].withdrawBalance += INITIAL_STAKE + CUT;
                balances[address(this)].withdrawBalance += CUT;
            }
        }

        game.state = State.FINISHED;

        emit GameResult(
            _gameId,
            block.timestamp,
            game.deadline,
            winner,
            game.state
        );
    }

    function removeGameStake(Game storage currentGame) internal {
        balances[currentGame.player1.addr].stakedBalance -= INITIAL_STAKE;
        balances[currentGame.player2.addr].stakedBalance -= INITIAL_STAKE;
    }

    function validateSelection(Selection _selection)
        internal
        pure
        returns (bool)
    {
        return (uint8(_selection) <= selection_length);
    }

    function evaluateGame(Selection _selection1, Selection _selection2)
        internal
        pure
        returns (bool, bool)
    {
        if (_selection1 == Selection.ROCK && _selection2 == Selection.SCISSORS)
            return (true, false);
        if (_selection1 == Selection.ROCK && _selection2 == Selection.PAPER)
            return (false, true);
        if (_selection1 == Selection.ROCK && _selection2 == Selection.LIZZARD)
            return (true, false);
        if (_selection1 == Selection.ROCK && _selection2 == Selection.SPOCK)
            return (false, true);
        
        if (_selection1 == Selection.PAPER && _selection2 == Selection.ROCK)
            return (true, false);
        if (_selection1 == Selection.PAPER && _selection2 == Selection.SCISSORS)
            return (false, true);
        if (_selection1 == Selection.PAPER && _selection2 == Selection.SPOCK)
            return (true, false);
        if (_selection1 == Selection.PAPER && _selection2 == Selection.LIZZARD)
            return (false, true);
        
        if (_selection1 == Selection.SCISSORS && _selection2 == Selection.ROCK)
            return (false, true);
        if (_selection1 == Selection.SCISSORS && _selection2 == Selection.PAPER)
            return (true, false);
        if (_selection1 == Selection.SCISSORS && _selection2 == Selection.SPOCK)
            return (false, true);
        if (_selection1 == Selection.SCISSORS && _selection2 == Selection.LIZZARD)
            return (true, false);
        
        if (_selection1 == Selection.LIZZARD && _selection2 == Selection.PAPER)
            return (true, false);
        if (_selection1 == Selection.LIZZARD && _selection2 == Selection.SPOCK)
            return (true, false);
        if (_selection1 == Selection.LIZZARD && _selection2 == Selection.ROCK)
            return (true, false);
        if (_selection1 == Selection.LIZZARD && _selection2 == Selection.SCISSORS)
            return (false, true);
        
    }

    // user can withdraw to their address
    function withdraw() external {
        sendToken(msg.sender, msg.sender);
    }

    // donate:
    // anyone can call donate - donates money from donation pool
    function donate() external {
        sendToken(address(this), DONATION_ADDRESS);
    }

    function sendToken(address origin, address destination) internal {
        uint256 amount = balances[origin].withdrawBalance;
        if (amount == 0) revert NotEnoughBalance();

        balances[origin].withdrawBalance = 0;

        // contract to msg.sender
        payable(destination).sendValue(amount);
    }

    // check game expiration time and decide on how to evaluateGame
    function unlockStakedValue(uint256 _gameId) public {
        Game storage game = games[_gameId];

        // time has expired and state is still not finished
        if (block.timestamp < game.deadline) revert GameNotExpired();
        if (game.state == State.FINISHED) revert GameHasEnded();

        if (game.state == State.FIRST_COMMIT) {
            // pl1 played but pl2 not, pl1 gets money back
            balances[game.player1.addr].stakedBalance -= INITIAL_STAKE;
            balances[game.player1.addr].withdrawBalance += INITIAL_STAKE;
        } else if (game.state == State.FIRST_REVEAL) {
            // pl2 played but pl1 did not reveal, pl1 loses
            removeGameStake(game);

            // add to winner withdraw balance:
            balances[game.player2.addr].withdrawBalance += INITIAL_STAKE + CUT;
            balances[address(this)].withdrawBalance += CUT;
        }
    }

    function getCommit(Selection _selection, bytes memory _passphrase) external pure returns(bytes32) {
        return keccak256(abi.encodePacked(_selection, _passphrase));
    }

    // endGame:
    // if one playe not reveals or reveals a wrong passphrase, the game is ended and the other player wins
    // can be called after time X

    event GameCreated(
        uint256 gameId,
        uint256 timestamp,
        uint256 deadline,
        address player1,
        State state
    );
    event GameJoined(
        uint256 gameId,
        uint256 timestamp,
        uint256 deadline,
        address player2,
        State state
    );
    event GameResult(
        uint256 gameId,
        uint256 timestamp,
        uint256 deadline,
        address winner,
        State state
    );
}