// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./TicTacToeGame.sol";

contract TicTacToeGameV2 is TicTacToeGame {
    struct Comment {
        string topic;
        string commentary;
    }

    mapping(address => Comment) public comments;
    
    function addComment(address _player,string memory _topic, string memory _commentary) external {
        Comment storage comment = comments[_player];

        comment.topic = _topic;
        comment.commentary = _commentary;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Tic-tac-toe game
 * @author Anton Malko
 * @notice You can use this contract to play tic-tac-toe with your friends
 * @dev All function calls are currently implemented without side effects
 */
contract TicTacToeGame is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public id;
    uint256 public period;
    uint256 public percent;
    address ownerAddress;
    uint256 private comission;
    uint256 private comissionERC20;
    address addErc20Mock;
    address addWallet;

    enum TicTac {
        no,
        zero,
        cross
    }

    enum GameStatus {
        no,
        created,
        createdERC20,
        started,
        finished
    }

    struct Game {
        GameStatus status;
        address winner;
        uint256 deadline;
        uint256 timer;
        uint256 amount;
        uint256 comision;
        uint256 lastMove;
        address player1;
        address player2;
        uint256 countMove;
        address lastPlayer;
        TicTac[9] fields;
        bool erc20;
    }

    struct Player {
        uint256 all;
        uint256 win;
        uint256 los;
    }

    error invalidStatus();
    error invalidAddress();
    error invalidCellOrTicTac();
    error yourTimeIsUp();
    error notYourElement();
    error youAreNotWinner();

    mapping(uint256 => Game) public games;
    mapping(address => Player) private players;
    mapping(address => uint256) private balance;

    /**
     * @notice This event contains the data entered by the user, his address and game id
     * @dev Called in the createGame function
     * @param player1 Address of the player who created the game
     * @param id Id of the game created by player 1
     * @param timer The time it takes to make a move
     */
    event Player1(
        address indexed player1, 
        uint256 indexed id, 
        uint256 timer,
        uint256 amount
    );

    /**
     * @notice This event contains the data of the game the player is joining and their address.
     * @dev Called in the join function
     * @param player2 The address of the player who joined the game
     * @param id Id of the game
     * @param timer The time it takes to make a move
     */
    event Player2(
        address indexed player2, 
        uint256 indexed id, 
        uint256 timer,
        uint256 amount
    );

    /**
     * @notice This event contains the data entered by the user and his address
     * @dev Called in the move function
     * @param player The address of the player who makes the move
     * @param cell The number of the cell that the player goes to
     * @param tictac The element that the player walks
     */
    event Move(
        address indexed player, 
        uint256 indexed cell, 
        TicTac tictac
    );

    /**
     * @notice This event contains the address of the player who won the game
     * @dev Called in the gameWin, timeIsUp function
     * @param win The address of the player who won the game
     * @param id Id of the game
     */
    event GameFinished(
        address indexed win, 
        uint256 indexed id
    );

    /**
     * @notice This event contains the game id and its status
     * @dev Called in the createGame, createGameERC20, join, joinERC20, changeStat function
     * @param id Id of the game
     * @param status The amount of funds transferred
     */
    event Status(
        uint256 indexed id, 
        GameStatus indexed status
    );

    modifier atStatus(uint256 _id, GameStatus _status) {
        Game storage game = games[_id];

        if (game.status != _status) {
            revert invalidStatus();
        }

        _;
    }

    modifier addressPlayer(uint256 _id, address _player) {
        if (_player != games[_id].player1) {
            if (_player != games[_id].player2) {
                revert invalidAddress();
            }
        }

        _;
    }

    modifier timeWait(uint256 _id) {
        if ((block.timestamp - games[_id].lastMove) / 1 minutes > games[_id].timer) {
            revert yourTimeIsUp();
        }

        _;

        games[_id].lastMove = block.timestamp;
    }

    modifier element(uint256 _id, address _player, TicTac _tictac) {
        if (_player == games[_id].player1 && _tictac == TicTac.cross) {
            revert notYourElement();
        } else if (_player == games[_id].player2 && _tictac == TicTac.zero) {
                revert notYourElement();
        }

        _;
    }

    /**
     * @notice Specifies the owner of the contract
     * @param _owner Owner's address
     * @param _addErc20Mock contract address ERC20Mock
     * @param _addWallet contract address Wallet
     */
    function initialize(address _owner, address _addErc20Mock, address _addWallet) 
        public 
        initializer
    {
        ownerAddress = _owner;
        addErc20Mock = _addErc20Mock;
        addWallet = _addWallet;
        id = 0;
        period = 2 days;
        percent = 10;

        __Ownable_init();
        __UUPSUpgradeable_init();

    }

    /**
     * @notice This feature replenishes the player's balance
     * @param _amount Amount of ether to be transferred
     */
    function refill(uint256 _amount) external {
        require(_amount < 1e60, "Invalid amount");

        IERC20(addErc20Mock).transferFrom(msg.sender, address(this), _amount);
        balance[msg.sender] += _amount;
    }

    /**
     * @notice This function creates a game with ERC20
     * @dev You can set the waiting time the same for all
     * @param _timeWait The time it takes to make a move
     * @param _amount Number of tokens to transfer
     */
    function createGameERC20(uint256 _timeWait, uint256 _amount) external {
        require(balance[msg.sender] >= _amount && _amount > 0, "Invalid balance");

        Game storage game = games[id];

        game.status = GameStatus.createdERC20;
        game.player1 = msg.sender;
        game.timer = _timeWait;
        balance[msg.sender] -= _amount;
        game.amount += _amount;
        game.deadline = block.timestamp + period;
        game.comision = game.amount * percent / 100;
        game.erc20 = true;

        id++;

        emit Player1(
            game.player1, 
            id - 1, 
            game.timer,
            game.amount
        );

        emit Status(
            id - 1,
            game.status
        );
    }

    /**
     * @notice This function creates a game
     * @dev You can set the waiting time the same for all
     * @param _timeWait The time it takes to make a move
     */
    function createGame(uint256 _timeWait) external payable {
        require(msg.value > 0.001 ether, "Insufficient funds");
        
        Game storage game = games[id];

        game.status = GameStatus.created;
        game.player1 = msg.sender;
        game.timer = _timeWait;
        game.amount += msg.value;
        game.deadline = block.timestamp + period;
        game.comision = game.amount * percent / 100;

        id++;

        emit Player1(
            game.player1, 
            id - 1, 
            game.timer,
            game.amount
        );

        emit Status(
            id - 1,
            game.status
        );
    }

    /**
     * @notice This function allows another player to join the game with ERC20
     * @dev There is a modifier that checks that the game has already been created,
     * also inside the function there is a check that the player
     * who joins is not the player who created the game
     * @param _id Id of the game created by player 1
     * @param _amount Number of tokens to transfer
     */
    function joinERC20(uint256 _id, uint256 _amount) 
        external 
        atStatus(_id, GameStatus.createdERC20) 
    {
       require(balance[msg.sender] >= _amount && _amount > 0, "Invalid balance");
        if (msg.sender == games[_id].player1) {
            revert invalidAddress();
        }

        Game storage game = games[_id];

        game.player2 = msg.sender;
        game.status = GameStatus.started;
        game.lastMove = block.timestamp;
        game.lastPlayer = game.player2;
        balance[msg.sender] -= _amount;
        game.amount += _amount;
        game.comision = game.amount * percent / 100;

        
        emit Player2(
            game.player2, 
            _id, 
            game.timer,
            _amount
        );

        emit Status(
            _id,
            game.status
        );
    }

    /**
     * @notice This function allows another player to join the game
     * @dev There is a modifier that checks that the game has already been created,
     * also inside the function there is a check that the player
     * who joins is not the player who created the game
     * @param _id Id of the game created by player 1
     */
    function join(uint256 _id) 
        external 
        payable
        atStatus(_id, GameStatus.created) 
    {
        require(msg.value > 0.001 ether, "Insufficient funds");
        if (msg.sender == games[_id].player1) {
            revert invalidAddress();
        }

        Game storage game = games[_id];

        game.player2 = msg.sender;
        game.status = GameStatus.started;
        game.lastMove = block.timestamp;
        game.lastPlayer = game.player2;
        game.amount += msg.value;
        game.comision = game.amount * percent / 100;

        
        emit Player2(
            game.player2, 
            _id, 
            game.timer,
            msg.value
        );

        emit Status(
            _id,
            game.status
        );
    }

    /**
     * @notice This feature allows players to make a move
     * @dev The first atStatus modifier checks whether the game is running or not.
     * The second modifier addressPlayer checks the address of the one
     * who calls the function and requires that they be equal to the address of the game creator or
     * the address of the one who joined the game.
     * The third timeWait modifier checks if the time allotted for a move has expired.
     * The fourth turn Element modifier determines the element that the player can control.
     * @param _cell The number of the cell that the player goes to
     * @param _tictac The element that the player walks
     * @param _id Id of the game
     */
    function move(uint256 _cell, TicTac _tictac, uint256 _id) 
        external 
        atStatus(_id, GameStatus.started) 
        addressPlayer(_id, msg.sender) 
        timeWait(_id) 
        element(_id, msg.sender, _tictac) 
    {
        require(games[_id].lastPlayer != msg.sender, "Now is not your turn");
        if ((_cell > 8) || (_tictac == TicTac.no) || 
                (games[_id].fields[_cell] != TicTac.no)) {
            revert invalidCellOrTicTac();
        }

        Game storage game = games[_id];

        game.fields[_cell] = _tictac;
        game.lastPlayer = msg.sender;
        game.countMove++;

        emit Move(
            msg.sender, 
            _cell, 
            _tictac
        );
    }

    /**
     * @notice The function ends the game
     * @dev There three are  modifiers, one of them checks that the game is running,
     * and the other checks that the move was made by the player who created the game or joined.
     * The latter checks the entered element assigned to the player.
     * Inside there is a check for a draw
     * @param _id Id of the game
     * @param _tictac The element that the player walks
     */
    function gameFinished(uint256 _id, TicTac _tictac) 
        external 
        atStatus(_id, GameStatus.started) 
        addressPlayer(_id, msg.sender) 
        element(_id, msg.sender, _tictac) 
    {
        Game storage game = games[_id];
        
        win(game, _tictac, _id);        
    }

    /**
     * @notice Function that checks if the opponent has run out of the time
     * @dev There are two modifiers, one of them checks that the game is running,
     * and the other checks that the move was made by the player who created the game or joined
     * @param _id Id of the game
     */
    function timeIsUp(uint256 _id) 
        external 
        atStatus(_id, GameStatus.started) 
        addressPlayer(_id, msg.sender) 
    {
        Game storage game = games[_id];

        if (game.lastMove + game.timer < block.timestamp) {
            if (game.lastPlayer == game.player1) {
                changeStat(game.player1, game.player2, _id);

                emit GameFinished(
                    game.winner, 
                    _id
                );
            } else {
                changeStat(game.player2, game.player1, _id);

                emit GameFinished(
                    game.winner, 
                    _id
                );
            }
        }
    }

    /**
     * @notice The function credits the winnings to the balance of the winner in ERC20
     * @dev There is a modifier that checks the address of the one who calls the function
     * Also inside there is a check that checks what the bet was made in
     * @param _id Id of the game
     */
    function pickUpTheWinningsERC20(uint256 _id) 
        external 
        addressPlayer(_id, msg.sender)
    {
        require(games[_id].erc20 == true, "Invalid func");
        
        Game storage game = games[_id];
        uint256 amount = game.amount;

        if(game.status == GameStatus.finished) {
            if(game.winner == msg.sender) {
                game.amount = 0;
                balance[msg.sender] += (amount - game.comision);
            } else {
                revert youAreNotWinner();
            }
        } else if(game.status == GameStatus.createdERC20 && block.timestamp > game.deadline ) {
            game.amount = 0;
            balance[msg.sender] += amount;
        }
    }

    /**
     * @notice The function displays the winnings to the winner
     * @dev There is a modifier that checks the address of the one who calls the function
     * @param _id Id of the game
     */
    function pickUpTheWinnings(uint256 _id) 
        external 
        addressPlayer(_id, msg.sender)
    {
        require(games[_id].erc20 != true, "Invalid func");

        Game storage game = games[_id];
        uint256 amount = game.amount;

        if(game.status == GameStatus.finished) {
            if(games[_id].winner == msg.sender) {
                game.amount = 0;

                payable(msg.sender).transfer(amount - game.comision);
            } else {
                revert youAreNotWinner();
            }
        } else if(game.status == GameStatus.created && block.timestamp > game.deadline ) {
            game.amount = 0;

            payable(msg.sender).transfer(amount);
        }
    }

    /**
     * @notice This function outputs ERC20
     * @param _amount Amount of tokens to be transferred
     * @param _add address contract with token ERC20
     */
    function withdrawERC20(uint256 _amount, address _add) 
        external 
    {
        require(balance[msg.sender] >= _amount,"Invalid balance");

        balance[msg.sender] -= _amount;
        IERC20(_add).transfer(msg.sender, _amount);
    }

    /**
     * @notice This function withdraws the commission to the wallet
     * @dev The function can only be called by the owner of the contract
     */
    function withdraw() 
        external 
    {
        require(msg.sender == ownerAddress, "Invalid address");
        uint256 amount = comission;
        comission = 0;

        payable(addWallet).transfer(amount);
    }

    /**
     * @notice This function withdraws the commission ERC20 to the wallet
     * @dev The function can only be called by the owner of the contract
     */
    function withdrawComissionERC20() 
        external 
    {
        require(msg.sender == ownerAddress, "Invalid address");
        uint256 amount = comissionERC20;
        comissionERC20 = 0;

        IERC20(addErc20Mock).approve(addWallet, amount);
    }

    /**
     * @notice This function changes the commission percentage
     * @dev The function can only be called by the owner of the contract
     * @param _fee Game Commission
     */
    function comisionChang(uint256 _fee) 
        external 
    {
        require(msg.sender == ownerAddress, "Invalid address");
        
        percent = _fee;
    }

    /**
     * @notice This function changes statistics
     * @dev The function is internal
     * @param _winner Winner's address
     * @param _loser Loser's address
     * @param _id Id of the game
     */
    function changeStat(address _winner, address _loser, uint256 _id) internal {
        Game storage game = games[_id];
        Player storage player1 = players[_winner];
        Player storage player2 = players[_loser];

        player1.win++;
        player2.los++;
        player1.all++;
        player2.all++;

        game.winner = game.player1;
        game.status = GameStatus.finished;

        if (game.erc20 == true) {
             comissionERC20 += game.comision;
        } else {
            comission += game.comision;
        }

        emit Status(
            _id,
            game.status
        );
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.

     */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    /**
     * @notice This function checks whether the player has won or not.
     * @dev You can change the algorithm
     * @param _id Id of the game
     * @param _tictac The element that the player walks
     * @param _game Structure that stores game data
     */
    function win(Game storage _game, TicTac _tictac, uint256 _id) internal {
        if ((!winVertically(_game, _tictac) || !winDiagonally(_game, _tictac) || !winHorizontally(_game, _tictac)) && 
                (winVertically(_game, TicTac.cross) || winDiagonally(_game, TicTac.cross) || winHorizontally(_game, TicTac.cross))) {
            changeStat(_game.player2, _game.player1, _id);

            emit GameFinished(
                _game.winner, 
                _id
            );
        } else if ((!winVertically(_game, _tictac) || !winDiagonally(_game, _tictac) || !winHorizontally(_game, _tictac)) && 
                (winVertically(_game, TicTac.zero) || winDiagonally(_game, TicTac.zero) || winHorizontally(_game, TicTac.zero))) {
            changeStat(_game.player1, _game.player2, _id);

            emit GameFinished(
                _game.winner, 
                _id
            );
        } else if (_game.countMove == 9) {
            Player storage player1 = players[_game.player2];
            Player storage player2 = players[_game.player1];
            player1.all++;
            player2.all++;
            _game.winner = address(0);
            _game.status = GameStatus.finished;

            emit GameFinished(
                _game.winner, 
                _id
            );
        }
    }

    /**
     * @notice This function returns player statistics
     * @dev Returns a structure Player
     * @return All attributes of the Player struct
     */
    function getStatPlayer() 
        external
        view 
        returns (Player memory) 
    {
        return players[msg.sender];
    }

    /**
     * @notice Displays commission balance
     * @dev Returns comission
     * @return uint256 Comission
     */
    function getComission() 
        external
        view 
        returns (uint256) 
    {
        require(msg.sender == ownerAddress, "Invalid address");

        return comission;
    }

    /**
     * @notice Displays commission balance ERC20
     * @dev Returns comission ERC20
     * @return uint256 Comission
     */
    function getComissionERC20() 
        external
        view 
        returns (uint256) 
    {
        require(msg.sender == ownerAddress, "Invalid address");

        return comissionERC20;
    }

    /**
     * @notice This function returns the player's balance
     * @return uint256 balance
     */
    function getBalancePlayer() 
        external
        view 
        returns (uint256)
    {
        return balance[msg.sender];
    }

    /**
     * @notice This function returns the statistics of a specific game.
     * @dev Returns a structure Game
     * @param _id Game number for which statistics will be displayed
     * @return All attributes of the Game struct
     */
    function getStatGame(uint256 _id) 
        external 
        view
        returns (Game memory) 
    {
        return games[_id];
    }

    /**
     * @notice This feature checks winning combinations vertically
     * @dev You can change the algorithm for finding the winning combination
     * @param _game Structure that stores game data
     * @param _tictac The element that the player walks
     * @return Boolean Value that indicates the presence of a winning combination
     */
    function winVertically(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[3] == _tictac && _game.fields[6] == _tictac) ||
                 (_game.fields[1] == _tictac && _game.fields[4] == _tictac && _game.fields[7] == _tictac) || 
                 (_game.fields[2] == _tictac && _game.fields[5] == _tictac && _game.fields[8] == _tictac)) {
            return true;
        }

        return false;
    }

    /**
     * @notice This feature checks winning combinations horizontally
     * @dev You can change the algorithm for finding the winning combination
     * @param _game Structure that stores game data
     * @param _tictac The element that the player walks
     * @return Boolean Value that indicates the presence of a winning combination
     */
    function winHorizontally(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[1] == _tictac && _game.fields[2] == _tictac) || 
                (_game.fields[3] == _tictac && _game.fields[4] == _tictac && _game.fields[5] == _tictac) || 
                (_game.fields[6] == _tictac && _game.fields[7] == _tictac && _game.fields[8] == _tictac)) {
            return true;
        }

        return false;
    }

    /**
     * @notice This feature checks winning combinations diagonally.
     * @dev You can change the algorithm for finding the winning combination
     * @param _game Structure that stores game data
     * @param _tictac The element that the player walks
     * @return Boolean Value that indicates the presence of a winning combination
     */
    function winDiagonally(Game storage _game, TicTac _tictac) 
        internal 
        view 
        returns (bool) 
    {
        if ((_game.fields[0] == _tictac && _game.fields[4] == _tictac && _game.fields[8] == _tictac) || 
                (_game.fields[2] == _tictac && _game.fields[4] == _tictac && _game.fields[6] == _tictac)) {
            return true;
        }

        return false;
    }
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
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}