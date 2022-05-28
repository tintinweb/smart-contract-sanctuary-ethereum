// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Wallet.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title TicTacToe contract
/// @author Dampilov D.

contract TicTacToe {
    uint256 gameId;
    uint256 immutable commission;
    address public owner;
    address public wallet;

    mapping(uint256 => Game) public games;
    mapping(uint256 => bool) public isERC20Game;
    mapping(uint256 => mapping(address => bool)) canWithdraw;

    /// @notice Sign for gamer, cross or zero
    mapping(address => mapping(uint256 => SquareState)) public sign;

    enum GameState {
        free,
        playing,
        finished
    }

    /// @dev Conditions for cells
    enum SquareState {
        free,
        cross,
        zero,
        draw
    }

    /// @dev isCrossMove - switch to determine the current move
    /// @dev winner - sign of the winner, or draw if ended in a draw
    struct Game {
        uint256 id;
        address owner;
        GameState state;
        SquareState[3][3] cell;
        bool isCrossMove;
        SquareState winner;
        address rival;
        uint256 waitingTime;
        uint256 lastActiveTime;
        uint256 betSize;
    }

    event GameCreated(uint256 indexed _gameId, address indexed owner, uint256 indexed waitingTime, uint256 createdTime, uint256 betSize);
    event JoinedToGame(uint256 indexed _gameId, address indexed joined, uint256 timeOfJoin, uint256 indexed betSize);
    event MoveMade(uint256 indexed _gameId, address indexed whoMoved, uint256 x, uint256 y, uint256 indexed timeOfMove);
    event GameResult(uint256 indexed _gameId, SquareState indexed winner, address indexed winnerAddress, uint256 finishedTime);
    event Withdraw(uint256 indexed _gameId, address indexed recipient, uint256 indexed count);

    /// @dev Game should be free
    modifier GameIsFree(uint256 _gameId) {
        require(games[_gameId].state == GameState.free, "Not free game");
        _;
    }

    /// @dev Already playing the game
    modifier GameIsStarted(uint256 _gameId) {
        require(games[_gameId].state == GameState.playing, "Don't being played");
        _;
    }

    modifier GameIsFinished(uint256 _gameId) {
        require(games[_gameId].state == GameState.finished, "Unauthorized access");
        _;
    }

    modifier onlyPlayer(uint256 _gameId) {
        require(msg.sender == games[_gameId].owner || msg.sender == games[_gameId].rival, "Not your game");
        _;
    }

    modifier GameExist(uint256 _gameId) {
        require(_gameId < gameId, "Game not exist");
        _;
    }

    constructor(address _walletAddress) {
        commission = 5;
        owner = msg.sender;
        wallet = _walletAddress;
    }

    /// @notice Create new game from ether
    /// @param _days, _hours, _minutes - move waiting time
    function createGameFromEth(
        uint64 _days,
        uint64 _hours,
        uint64 _minutes
    ) external payable {
        require(_days + _hours + _minutes > 0, "Time not set");
        require(msg.value >= 0.001 ether, "Not enaught ETH");
        (bool success, ) = address(wallet).call{value: (msg.value * commission) / 100}("");
        require(success, "Failed to send Ether");
        _createGame(_days, _hours, _minutes, msg.value);
    }

    /// @notice Create new game from ERC20 tokens
    /// @param _days, _hours, _minutes - move waiting time
    function createGamefromERC20(
        address _token,
        uint64 _days,
        uint64 _hours,
        uint64 _minutes,
        uint256 _betAmount
    ) external {
        require(_days + _hours + _minutes > 0, "Time not set");
        require(_betAmount >= 5, "Not enaught tokens");
        ERC20(_token).transferFrom(msg.sender, address(this), _betAmount);
        ERC20(_token).transfer(address(wallet), (_betAmount * commission) / 100);
        MultisigWallet(wallet).receiveERC20(_token, _betAmount);
        isERC20Game[gameId] = true;
        _createGame(_days, _hours, _minutes, _betAmount);
    }

    /// @notice Join free game from ether
    function joinGameFromEth(uint256 _gameId) external payable GameIsFree(_gameId) GameExist(_gameId) {
        require(msg.sender != games[_gameId].owner, "Can't play with yourself");
        require(msg.value == games[_gameId].betSize, "Not correct bet size");

        (bool success, ) = address(wallet).call{value: (msg.value * commission) / 100}("");
        require(success, "Failed to send Ether");
        _joinGame(_gameId);
    }

    /// @notice Join free game from ERC20 tokens
    function joinGameFromERC20(uint256 _gameId, address _token) external GameIsFree(_gameId) GameExist(_gameId) {
        require(msg.sender != games[_gameId].owner, "Can't play with yourself");
        require(isERC20Game[_gameId], "Bet by ether");

        ERC20(_token).transferFrom(msg.sender, address(this), games[_gameId].betSize);
        ERC20(_token).transfer(address(wallet), (games[_gameId].betSize * commission) / 100);
        MultisigWallet(wallet).receiveERC20(_token, games[_gameId].betSize);
        _joinGame(_gameId);
    }

    /// @notice Make a move
    /// @param _x, _y - coordinates where you want to put your sign
    function step(
        uint256 _gameId,
        uint256 _x,
        uint256 _y
    ) external GameIsStarted(_gameId) onlyPlayer(_gameId) {
        require(block.timestamp <= games[_gameId].waitingTime + games[_gameId].lastActiveTime, "Move time over");
        require(games[_gameId].cell[_x][_y] == SquareState.free, "Square not free");
        require(_x < 3 && _y < 3, "Not correct position");
        require((games[_gameId].isCrossMove && sign[msg.sender][_gameId] == SquareState.cross) || (!games[_gameId].isCrossMove && sign[msg.sender][_gameId] == SquareState.zero), "Not your move");

        games[_gameId].cell[_x][_y] = sign[msg.sender][_gameId];
        games[_gameId].isCrossMove = !games[_gameId].isCrossMove;
        games[_gameId].lastActiveTime = block.timestamp;
        emit MoveMade(_gameId, msg.sender, _x, _y, block.timestamp);
        SquareState gameWinner = _checkEndGame(games[_gameId], sign[msg.sender][_gameId], _x, _y);
        /// @dev If game is over
        if (gameWinner != SquareState.free) {
            _finishGame(_gameId, gameWinner);
        }
    }

    /// @notice Checking if the turn time has expired
    /// @dev If the time is up then the game is over
    function checkGameTime(uint256 _gameId) external {
        if (block.timestamp > games[_gameId].waitingTime + games[_gameId].lastActiveTime) {
            games[_gameId].state = GameState.finished;
            if (games[_gameId].isCrossMove) {
                /// @dev Zero won
                _finishGame(_gameId, SquareState.zero);
            } else {
                /// @dev Cross won
                _finishGame(_gameId, SquareState.cross);
            }
        }
    }

    /// @notice Withdraw ethers, if you won or game end in draw
    function withdrawETH(uint256 _gameId) external GameIsFinished(_gameId) onlyPlayer(_gameId) {
        require(canWithdraw[_gameId][msg.sender], "Can't withdraw");
        require(!isERC20Game[_gameId], "Bet by tokens");
        uint256 withdrawCount;
        delete canWithdraw[_gameId][msg.sender];
        if (games[_gameId].winner == SquareState.draw) {
            withdrawCount = (games[_gameId].betSize * (100 - commission)) / 100;
            payable(msg.sender).transfer(withdrawCount);
            emit Withdraw(_gameId, msg.sender, withdrawCount);
        }
        if (games[_gameId].winner == sign[msg.sender][_gameId]) {
            withdrawCount = (2 * games[_gameId].betSize * (100 - commission)) / 100;
            payable(msg.sender).transfer(withdrawCount);
            emit Withdraw(_gameId, msg.sender, withdrawCount * 2);
        }
    }

    /// @notice Withdraw ERC20 tokens, if you won or game end in draw
    function withdrawERC20(uint256 _gameId, address token) external GameIsFinished(_gameId) onlyPlayer(_gameId) {
        require(isERC20Game[_gameId], "Bet by ether");
        require(canWithdraw[_gameId][msg.sender], "Can't withdraw");
        uint256 withdrawCount;
        withdrawCount = (games[_gameId].betSize * (100 - commission)) / 100;
        delete canWithdraw[_gameId][msg.sender];
        if (games[_gameId].winner == SquareState.draw) {
            ERC20(token).transfer(msg.sender, withdrawCount);
            emit Withdraw(_gameId, msg.sender, withdrawCount);
        }
        if (games[_gameId].winner == sign[msg.sender][_gameId]) {
            ERC20(token).transfer(msg.sender, withdrawCount * 2);
            emit Withdraw(_gameId, msg.sender, withdrawCount * 2);
        }
    }

    /// @return freeGamesList - List of free games
    function freeGames() external view returns (Game[] memory freeGamesList) {
        /// @dev Number of free games
        (uint256 gameCount, ) = _getGamesByFilter(GameState.free, SquareState.free, address(0));
        freeGamesList = new Game[](gameCount);
        uint256 counter;
        for (uint256 i; i < gameId; i++) {
            if (games[i].state == GameState.free) {
                freeGamesList[counter] = games[i];
                counter++;
            }
        }
    }

    /// @return Percentage of games ending in a draw
    function getDrawGameStatistic() external view returns (uint256) {
        /// @dev Numbers of finished and ending in a draw games
        (uint256 gameCount, uint256 signCount) = _getGamesByFilter(GameState.finished, SquareState.draw, address(0));
        return gameCount > 0 ? (signCount * 100) / gameCount : 0;
    }

    /// @return Percentage of games where the cross wins
    function getCrossGameStatistic() external view returns (uint256) {
        /// @dev Numbers of finished and the cross wins games
        (uint256 gameCount, uint256 signCount) = _getGamesByFilter(GameState.finished, SquareState.cross, address(0));
        return gameCount > 0 ? (signCount * 100) / gameCount : 0;
    }

    /// @return Percentage of games where the zero wins
    function getZeroGameStatistic() external view returns (uint256) {
        /// @dev Numbers of finished and the zero wins games
        (uint256 gameCount, uint256 signCount) = _getGamesByFilter(GameState.finished, SquareState.zero, address(0));
        return gameCount > 0 ? (signCount * 100) / gameCount : 0;
    }

    /// @param _gamer - address of player
    /// @return Percentage of games where the player wins
    function getStatisticByAddress(address _gamer) external view returns (uint256) {
        /// @dev Numbers of finished and the player wins games
        (uint256 gameCount, uint256 signCount) = _getGamesByFilter(GameState.finished, SquareState.free, _gamer);
        return gameCount > 0 ? (signCount * 100) / gameCount : 0;
    }

    /// @return cell - game board, three by three matrix
    function getCell(uint256 _gameId) external view returns (uint8[3][3] memory cell) {
        for (uint256 i; i < 3; i++) {
            for (uint256 j; j < 3; j++) {
                if (games[_gameId].cell[i][j] == SquareState.free) cell[i][j] = 0;
                if (games[_gameId].cell[i][j] == SquareState.cross) cell[i][j] = 1;
                if (games[_gameId].cell[i][j] == SquareState.zero) cell[i][j] = 2;
            }
        }
    }

    /// @dev Create new game
    function _createGame(
        uint64 _days,
        uint64 _hours,
        uint64 _minutes,
        uint256 betAmount
    ) internal {
        SquareState[3][3] memory tictac;
        games[gameId] = Game(gameId, msg.sender, GameState.free, tictac, true, SquareState.free, address(0), (_days * 1 days) + (_hours * 1 hours) + (_minutes * 1 minutes), block.timestamp, betAmount);
        sign[msg.sender][gameId] = SquareState.cross;
        emit GameCreated(gameId, msg.sender, games[gameId].waitingTime, block.timestamp, betAmount);
        gameId++;
    }

    /// @dev Join player to some free game
    function _joinGame(uint256 _gameId) internal {
        games[_gameId].rival = msg.sender;
        sign[msg.sender][_gameId] = SquareState.zero;
        games[_gameId].state = GameState.playing;
        games[_gameId].lastActiveTime = block.timestamp;
        emit JoinedToGame(_gameId, msg.sender, block.timestamp, games[_gameId].betSize);
    }

    /// @dev Finish game, and determine the winner
    function _finishGame(uint256 _gameId, SquareState winner) internal {
        games[_gameId].state = GameState.finished;
        games[_gameId].winner = winner;
        if (winner == SquareState.draw) {
            canWithdraw[_gameId][games[_gameId].owner] = true;
            canWithdraw[_gameId][games[_gameId].rival] = true;
            emit GameResult(_gameId, winner, address(0), block.timestamp);
        } else {
            if (winner == SquareState.cross) {
                canWithdraw[_gameId][games[_gameId].owner] = true;
                emit GameResult(_gameId, winner, games[_gameId].owner, block.timestamp);
            } else {
                canWithdraw[_gameId][games[_gameId].rival] = true;
                emit GameResult(_gameId, winner, games[_gameId].rival, block.timestamp);
            }
        }
    }

    /// @dev Get number of all games and number of games where the corresponding sign won
    function _getGamesByFilter(
        GameState _state,
        SquareState _sign,
        address _gamer
    ) internal view returns (uint256 gameCount, uint256 signCount) {
        for (uint256 i; i < gameId; i++) {
            if (games[i].state == _state) {
                gameCount++;
                if (games[i].winner == _sign || games[i].winner == sign[_gamer][i]) signCount++;
            }
        }
    }

    /// @dev Checking if the game is over
    /// @param _x, _y - coordinates where you want to put your sign
    /**
     @return If game is not over, return SquareState.free.
     If someone won, return his sign.
     If game over in draw, return SquareState.draw
     */
    function _checkEndGame(
        Game memory game,
        SquareState _sign,
        uint256 _x,
        uint256 _y
    ) internal pure returns (SquareState) {
        bool[5] memory line;
        line[0] = true;
        line[1] = true;
        line[4] = true;
        /// @dev If lies on one of the diagonals, then you can check
        if ((_x + _y) % 2 == 0) {
            line[2] = true;
            line[3] = true;
        }

        for (uint256 i; i < 3 && (line[0] || line[1] || line[2] || line[3] || line[4]); i++) {
            /// @dev Vertical and horizontal check
            if (game.cell[_x][i] != _sign) {
                line[0] = false;
            }
            if (game.cell[i][_y] != _sign) {
                line[1] = false;
            }
            /// @dev Diagonals check
            if ((_x + _y) % 2 == 0) {
                if (game.cell[i][i] != _sign) {
                    line[2] = false;
                }

                if (game.cell[i][2 - i] != _sign) {
                    line[3] = false;
                }
            }
            /// @dev Checking for a draw
            for (uint256 j; j < 3 && line[4]; j++) {
                if (game.cell[i][j] == SquareState.free) line[4] = false;
            }
        }
        if (line[0] || line[1] || line[2] || line[3]) return _sign;
        if (line[4]) return SquareState.draw;
        return SquareState.free;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface MultisigWallet {
    event Deposit(address indexed sender, uint256 indexed amount);
    event DepositERC20(address indexed tokenAddress, uint256 indexed amount);
    event Approval(address indexed owner, uint256 indexed txId);
    event Submit(uint256 indexed txId);
    event Execute(uint256 indexed txId);

    function receiveERC20(address _tokenAddress, uint256 _value) external;

    function submit(address _to, uint256 _value) external;

    function submitERC20(
        address _to,
        uint256 _value,
        address tokenAddress
    ) external;

    function approve(uint256 _txId) external;

    function execute(uint256 _txId) external;

    function balance() external view returns (uint256);
}

/// @title MultisigWallet
/// @author Dampilov D.

contract Wallet is MultisigWallet {
    /// @dev Required count of owners
    uint256 public required;

    address[] public owners;
    Transaction[] public transactions;

    mapping(address => bool) isOwner;

    /// @dev If wanna withdraw ERC20 tokens
    mapping(uint256 => ERC20Tx) public tokenTx;
    mapping(uint256 => mapping(address => bool)) public approved;

    struct ERC20Tx {
        bool isERC20Tx;
        address tokenAddress;
    }

    struct Transaction {
        bool executed;
        address to;
        uint256 value;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not owner");
        _;
    }

    modifier txExist(uint256 _txId) {
        require(_txId < transactions.length, "tx doesn't exist");
        _;
    }

    modifier notApproved(uint256 _txId) {
        require(!approved[_txId][msg.sender], "tx already approved");
        _;
    }

    modifier notExecuted(uint256 _txId) {
        require(!transactions[_txId].executed, "tx already executed");
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        require(_owners.length > 0, "Owners required");
        require(_required > 0 && _required <= _owners.length, "Invalid require number");

        required = _required;
        for (uint256 i; i < _owners.length; i++) {
            require(_owners[i] != address(0), "There is a null address");
            require(!isOwner[_owners[i]], "Not unique owners");

            isOwner[_owners[i]] = true;
            owners.push(_owners[i]);
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function receiveERC20(address _tokenAddress, uint256 _value) external {
        emit DepositERC20(_tokenAddress, _value);
    }

    /// @notice Create transaction to withdraw ether funds
    function submit(address _to, uint256 _value) public onlyOwner {
        transactions.push(Transaction(false, _to, _value));
        emit Submit(transactions.length - 1);
    }

    /// @notice Create transaction to withdraw tokens funds
    function submitERC20(
        address _to,
        uint256 _value,
        address tokenAddress
    ) external onlyOwner {
        submit(_to, _value);
        tokenTx[transactions.length - 1] = ERC20Tx(true, tokenAddress);
    }

    /// @notice Approve transaction to withdraw funds
    function approve(uint256 _txId) external onlyOwner txExist(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approval(msg.sender, _txId);
    }

    /// @dev Count the number of approved owners by transaction
    function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) count++;
        }
    }

    /// @notice Try to execute a transaction
    function execute(uint256 _txId) external txExist(_txId) notExecuted(_txId) {
        require(_getApprovalCount(_txId) >= required, "Not approved");
        transactions[_txId].executed = true;

        if (tokenTx[_txId].isERC20Tx) {
            ERC20(tokenTx[_txId].tokenAddress).transfer(transactions[_txId].to, transactions[_txId].value);
        } else {
            (bool success, ) = transactions[_txId].to.call{value: transactions[_txId].value}("");
            require(success, "tx failed");
        }
        emit Execute(_txId);
    }

    /// @notice View ETH balance of wallet
    function balance() external view returns (uint256) {
        return address(this).balance;
    }
}