// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/// @title Noughts and Crosses classical game (the test task for iLink Academy, 2022)
/// @author Vsevolod Medvedev
/// @notice Player can create or join a game, and once it started, do turns until win, draw or timeout
contract NoughtsAndCrosses is Initializable {
    string public constant NAME = "NoughtsAndCrosses";

    uint256 public feeBps; // In basis points (1 BPS = 0.01%)
    uint256 public minBet;
    uint256 public maxBet;
    address public wallet;
    address public admin;

    bytes32 public CHANGE_FEE_TYPEHASH;
    bytes32 public DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    enum FieldValue {
        Empty,
        Cross,
        Nought
    }

    enum GameState {
        Draw, // 0
        Player1Turn, // 1
        Player2Turn, // 2
        Player1Win, // 3
        Player2Win, // 4
        Player1Timeout, // 5
        WaitingForPlayer2ToJoin, // 6
        Closed, // 7
        Cancelled, // 8
        Player2Timeout // 9
    }

    struct GameField {
        FieldValue[3][3] values;
    }

    struct Game {
        address player1;
        address player2;
        uint256 id;
        uint256 lastTurnTime;
        uint256 timeout;
        uint256 bet;
        GameField field;
        GameState state;
    }

    Game[] games;

    event Deposit(address indexed caller, uint256 indexed amount, uint256 balance, string indexed message);
    event GameStateChanged(uint256 indexed id, address indexed player1, address player2, GameState indexed state);

    modifier notTimeout(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(block.timestamp - game.lastTurnTime < game.timeout, "Time was out!");
        _;
    }

    modifier currentPlayerOnly(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(
            (msg.sender == game.player1 && game.state == GameState.Player1Turn) ||
                (msg.sender == game.player2 && game.state == GameState.Player2Turn),
            _concat(
                "Only player whose turn it is now can make a move, current state is: ",
                _getGameStateString(game.state)
            )
        );
        _;
    }

    modifier playerOnly(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(
            (msg.sender == game.player1) || (msg.sender == game.player2),
            "This method can only be called by Player 1 or Player 2"
        );
        _;
    }

    modifier creatorOnly(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(msg.sender == game.player1, "This method can only be called by the game creator (Player 1)");
        _;
    }

    modifier stateIsAnyPlayerTurn(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(
            (game.state == GameState.Player1Turn) || (game.state == GameState.Player2Turn),
            _concat(
                "This method can only be called when any player turn it is now, current state is: ",
                _getGameStateString(game.state)
            )
        );
        _;
    }

    modifier stateIsGameEnded(uint256 _gameId) {
        Game memory game = games[_gameId];
        require(
            (game.state == GameState.Cancelled ||
                game.state == GameState.Player1Win ||
                game.state == GameState.Player2Win ||
                game.state == GameState.Draw ||
                game.state == GameState.Player1Timeout ||
                game.state == GameState.Player2Timeout),
            _concat("The game is not ended, current state is: ", _getGameStateString(game.state))
        );
        _;
    }

    modifier stateOnly(uint256 _gameId, GameState _state) {
        require(games[_gameId].state == _state, "The game is in another state");
        _;
    }

    modifier verifyFeeBps(uint256 _newFeeBps) {
        require(0 <= _newFeeBps && _newFeeBps <= 1000); // from 0% to 10%
        _;
    }

    modifier verifyBetToCreate() {
        require(minBet <= msg.value && msg.value <= maxBet, "Bet to create is out of range");
        _;
    }

    modifier verifyBetToJoin(uint256 _gameId) {
        require(msg.value == games[_gameId].bet, "Bet to join must match the game bet");
        _;
    }

    modifier verifyCoordinates(
        uint256 _gameId,
        uint8 _x,
        uint8 _y
    ) {
        require(_x >= 0 && _x <= 2 && _y >= 0 && _y <= 2, "Coordinates are out of range");
        require(games[_gameId].field.values[_y][_x] == FieldValue.Empty, "The cell is already filled");
        _;
    }

    function initialize(address _multiSigWallet, address _admin) public initializer {
        wallet = _multiSigWallet;
        feeBps = 100; // In basis points (1 BPS = 0.01%)
        minBet = 1000;
        maxBet = 1000000000000000;
        admin = _admin;

        // EIP712 / EIP-2612 domains and permissions
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(NAME)),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
        CHANGE_FEE_TYPEHASH = keccak256("changeFee(address account,uint256 newFeeBps,uint256 nonce)");
    }

    /// @notice Function to receive Ether. msg.data must be empty
    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance, "Received was called");
    }

    /// @notice Fallback function is called when msg.data is not empty
    fallback() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance, "Fallback was called");
    }

    /// @notice Get the contract balance
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /// @notice Change open and future games fee
    /// @param _newFeeBps New fee value in basis points (1 BPS = 0.01%)
    function changeFee(
        address _account,
        uint256 _newFeeBps,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external verifyFeeBps(_newFeeBps) {
        // Note: Here we demonstrate EIP-712 / EIP-2612 signing & verification approach for learning purposes
        // (otherwise it could be implemented just with adminOnly modifier)
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(CHANGE_FEE_TYPEHASH, _account, _newFeeBps, nonces[_account]++))
            )
        );
        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(
            recoveredAddress != address(0) && recoveredAddress == admin,
            "This method can only be called by administrator"
        );
        feeBps = _newFeeBps;
    }

    /// @notice Create a Noughts and Crosses game. A caller becomes player1 and waits for player2 to join
    /// @param _timeout Timeout for a turn in seconds
    function createGame(uint256 _timeout) external payable verifyBetToCreate {
        uint256 id = games.length;

        GameField memory field;
        for (uint256 i = 0; i < 3; i++) for (uint256 j = 0; j < 3; j++) field.values[i][j] = FieldValue.Empty;

        Game memory game = Game(
            msg.sender,
            address(0),
            id,
            0,
            _timeout,
            msg.value,
            field,
            GameState.WaitingForPlayer2ToJoin
        );
        games.push(game);

        emit GameStateChanged(game.id, game.player1, game.player2, game.state);
    }

    /// @notice Get the game
    /// @param _gameId The game ID
    function getGame(uint256 _gameId) external view returns (Game memory) {
        return games[_gameId];
    }

    /// @notice Get the game field
    /// @param _gameId The game ID
    function getGameField(uint256 _gameId) external view returns (GameField memory) {
        return games[_gameId].field;
    }

    /// @notice Get the game state string
    /// @param _gameId The game ID
    function getGameState(uint256 _gameId) external view returns (string memory) {
        return _getGameStateString(games[_gameId].state);
    }

    function getLastCreatedGameId() external view returns (uint256) {
        return games.length - 1;
    }

    /// @notice List created games
    function listCreatedGames() external view returns (Game[] memory) {
        uint256 size = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].state == GameState.WaitingForPlayer2ToJoin) {
                size++;
            }
        }
        Game[] memory filtered = new Game[](size);
        uint256 j = 0;
        for (uint256 i = 0; i < games.length; i++) {
            if (games[i].state == GameState.WaitingForPlayer2ToJoin) {
                filtered[j] = games[i];
                j++;
            }
        }
        return filtered;
    }

    /// @notice Cancel the specified game. Only creator (player 1) can call this
    /// @param _gameId Game to cancel
    function cancelGame(uint256 _gameId)
        external
        creatorOnly(_gameId)
        stateOnly(_gameId, GameState.WaitingForPlayer2ToJoin)
    {
        Game storage game = games[_gameId];
        game.state = GameState.Cancelled;

        emit GameStateChanged(game.id, game.player1, game.player2, game.state);
    }

    /// @notice Join the specified game. A caller becomes player2 and waits for player1 to make turn
    /// @param _gameId Game to join
    function joinGame(uint256 _gameId)
        external
        payable
        stateOnly(_gameId, GameState.WaitingForPlayer2ToJoin)
        verifyBetToJoin(_gameId)
    {
        Game storage game = games[_gameId];
        game.player2 = msg.sender;
        game.state = GameState.Player1Turn;
        game.lastTurnTime = block.timestamp;

        emit GameStateChanged(game.id, game.player1, game.player2, game.state);
    }

    /// @notice Make turn. Can only be called by the player whose turn it is now
    function makeTurn(
        uint256 _gameId,
        uint8 _x,
        uint8 _y
    )
        external
        currentPlayerOnly(_gameId)
        notTimeout(_gameId)
        verifyCoordinates(_gameId, _x, _y)
        returns (GameField memory)
    {
        Game storage game = games[_gameId];

        if (msg.sender == game.player1) {
            game.field.values[_y][_x] = FieldValue.Cross;
            game.state = GameState.Player2Turn;
        } else {
            game.field.values[_y][_x] = FieldValue.Nought;
            game.state = GameState.Player1Turn;
        }
        game.lastTurnTime = block.timestamp;

        return game.field;
    }

    function checkGameState(uint256 _gameId)
        external
        stateIsAnyPlayerTurn(_gameId)
        playerOnly(_gameId)
        returns (GameState state)
    {
        Game storage game = games[_gameId];
        GameState savedState = game.state;

        if (block.timestamp - game.lastTurnTime > game.timeout) {
            if (game.state == GameState.Player1Turn) {
                game.state = GameState.Player1Timeout;
            } else {
                game.state = GameState.Player2Timeout;
            }
        } else {
            game.state = _checkTurn(_gameId);
        }

        // Expected new state: Player1Win or Player2Win or Draw or Timeout
        if (game.state != savedState) {
            emit GameStateChanged(game.id, game.player1, game.player2, game.state);
        }

        return game.state;
    }

    /// @notice Get win. Can only be called by the player who won/lost or if the game is ended in a draw/timeout
    function getWin(uint256 _gameId) external stateIsGameEnded(_gameId) playerOnly(_gameId) {
        Game storage game = games[_gameId];

        GameState savedState = game.state;
        game.state = GameState.Closed;

        uint256 game_bet = game.bet;
        if (savedState != GameState.Cancelled) {
            game_bet = game_bet * 2;
        }
        uint256 fee = (game_bet * feeBps) / 10000;
        uint256 prize = game_bet - fee;

        // Send fee to Multi-Sig Wallet
        bool sent;
        (sent, ) = payable(wallet).call{value: fee}("");
        require(sent, "Failed to send fee to wallet");

        // Send prize to players
        if (
            savedState == GameState.Cancelled ||
            savedState == GameState.Player1Win ||
            savedState == GameState.Player2Timeout
        ) {
            (sent, ) = payable(game.player1).call{value: prize}("");
            require(sent, "Failed to send prize to Player 1");
        } else if (savedState == GameState.Player2Win || savedState == GameState.Player1Timeout) {
            (sent, ) = payable(game.player2).call{value: prize}("");
            require(sent, "Failed to send prize to Player 2");
        } else if (savedState == GameState.Draw) {
            uint256 prize_half1 = prize / 2;
            uint256 prize_half2 = prize - prize_half1;
            (bool sent1, ) = payable(game.player1).call{value: prize_half1}("");
            (bool sent2, ) = payable(game.player2).call{value: prize_half2}("");
            require(sent1 && sent2, "Failed to send prizes to players");
        }

        emit GameStateChanged(game.id, game.player1, game.player2, game.state);
    }

    /// @notice Get stats
    function getStats() external {
        // TODO
    }

    function _checkTurn(uint256 _gameId) private view returns (GameState) {
        GameField memory field = games[_gameId].field;
        GameState currentState = games[_gameId].state;

        // Check rows and columns
        for (uint256 i = 0; i < 3; i++) {
            if (
                (field.values[i][0] == FieldValue.Cross &&
                    field.values[i][1] == FieldValue.Cross &&
                    field.values[i][2] == FieldValue.Cross) ||
                (field.values[0][i] == FieldValue.Cross &&
                    field.values[1][i] == FieldValue.Cross &&
                    field.values[2][i] == FieldValue.Cross)
            ) {
                return GameState.Player1Win;
            }
            if (
                (field.values[i][0] == FieldValue.Nought &&
                    field.values[i][1] == FieldValue.Nought &&
                    field.values[i][2] == FieldValue.Nought) ||
                (field.values[0][i] == FieldValue.Nought &&
                    field.values[1][i] == FieldValue.Nought &&
                    field.values[2][i] == FieldValue.Nought)
            ) {
                return GameState.Player2Win;
            }
        }

        // Check diagonals
        if (
            (field.values[0][0] == FieldValue.Cross &&
                field.values[1][1] == FieldValue.Cross &&
                field.values[2][2] == FieldValue.Cross) ||
            (field.values[2][0] == FieldValue.Cross &&
                field.values[1][1] == FieldValue.Cross &&
                field.values[0][2] == FieldValue.Cross)
        ) {
            return GameState.Player1Win;
        }
        if (
            (field.values[0][0] == FieldValue.Nought &&
                field.values[1][1] == FieldValue.Nought &&
                field.values[2][2] == FieldValue.Nought) ||
            (field.values[2][0] == FieldValue.Nought &&
                field.values[1][1] == FieldValue.Nought &&
                field.values[0][2] == FieldValue.Nought)
        ) {
            return GameState.Player2Win;
        }

        // Check for draw
        bool isDraw = true;
        for (uint256 i = 0; i < 3; i++)
            for (uint256 j = 0; j < 3; j++)
                if (field.values[i][j] == FieldValue.Empty) {
                    isDraw = false;
                }
        if (isDraw) {
            return GameState.Draw;
        }

        return currentState;
    }

    function _concat(string memory _a, string memory _b) internal pure returns (string memory) {
        return string(abi.encodePacked(_a, _b));
    }

    function _getGameStateString(GameState _state) internal pure returns (string memory) {
        string[10] memory stateStrings = [
            "Draw",
            "Player 1 Turn",
            "Player 2 Turn",
            "Player 1 Win",
            "Player 2 Win",
            "Player 1 Timeout",
            "Waiting for Player 2 to join",
            "Closed",
            "Cancelled",
            "Player 2 Timeout"
        ];
        return stateStrings[uint256(_state)];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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