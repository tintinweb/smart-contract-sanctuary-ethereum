// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract gameSession is Ownable
{

    enum Status
    {
        CREATED,
        STARTED, 
        FINISHED, 
        CANCELLED
    }

    event GameTypeCreated(bytes16 _GameTypeID, string _name, uint256 _nbMinPlayers, uint256 _nbMaxPlayers);
    event GameCreated(bytes16 _GameID,address _creator, bytes16 _GameTypeID, Status _GameStatus);
    event GameJoined(bytes16 _GameID, address _player);
    event GameStarted(bytes16 _GameID, Status _GameStatus, uint256 _nbPlayers);
    event GameCancelled(bytes16 _GameID, Status _GameStatus);
    event WinnerRewarded(address _winner, uint256 _reward);
    event GameFinished(bytes16 _GameID, Status _GameStatus, address _winner);

    uint256 rewardFees; // Percentage value applied to poolPrize

    function setRewardFees(uint256 _rewardFees) public onlyGameMaster
    {
        rewardFees = _rewardFees;
    }

    struct GameType
    {
        string name;

        bytes16 gameTypeId;
        uint256 nbPlayersMin;
        uint256 nbPlayersMax;

        bool isValue;
    }
    mapping(bytes16 => GameType) public gameTypeByID;

    function setAuraToken(address _token) public onlyOwner
    {
        AuraToken = _token;
    }

    function setGameMaster(address _gameMaster) public onlyOwner
    {
        GameMaster = _gameMaster;
    }

    function createGameType(string memory _name, bytes16 _gameTypeId, uint256 _nbPlayersMin, uint256 _nbPlayersMax) public onlyGameMaster
    {
        GameType memory newGameType = GameType(
            _name, 
            _gameTypeId,
            _nbPlayersMin,
            _nbPlayersMax,
            true
        );
        gameTypeByID[_gameTypeId] = newGameType;

        emit GameTypeCreated(_gameTypeId, _name, _nbPlayersMin, _nbPlayersMax);
    }

    struct Game
    {
        GameType gameType;

        uint256 nbPlayers;
        bytes16 gameID;
        uint256 bid;
        uint256 poolPrize;
        Status status; 

        address gameCreator;
        address[] players;
        address[] playersOut;
        address winner;

        bool winnerRewarded;
        bool isValue;
    }
    mapping(bytes16 => Game) public gameByID;

    function getGameCreator(bytes16 _GameID) public view returns (address)
    {
        require(gameByID[_GameID].status == Status.CREATED, "Game does not exist");
        return gameByID[_GameID].gameCreator;
    }

    function getNbPlayers(bytes16 _GameID) public view returns(uint256)
    {
        return gameByID[_GameID].nbPlayers;
    }

    function getPlayers(bytes16 _GameID) public view returns (address[] memory)
    {
        require(gameByID[_GameID].isValue, "Game does not exist");
        return gameByID[_GameID].players;
    }

    function getGameMaster() public view returns (address)
    {
        return GameMaster;
    }

    function getBid(bytes16 _GameID) public view returns(uint256)
    {
        require(gameByID[_GameID].status == Status.CREATED, "Game does not exist");
        return gameByID[_GameID].bid;
    }

    address AuraToken;
    address GameMaster;
    modifier onlyGameMaster
    {
        require(msg.sender == GameMaster,"GameMaster function only");
        _;
    }

    function getRewardFees() public view returns(uint256)
    {
        return rewardFees;
    }

    function getReward_feesApplied(bytes16 _GameID) public view returns(uint256)
    {
        return (gameByID[_GameID].poolPrize - (gameByID[_GameID].poolPrize * rewardFees / 100));
    }

    

    function createGame(bytes16 _GameID, uint256 _bidAmount, bytes16 _gameTypeId) public
    {
        GameType storage gameType = gameTypeByID[_gameTypeId];
        require(gameType.isValue, "gameId is incorrect");
        require(!gameByID[_GameID].isValue, "GameID already used, can't create");

        ERC20(AuraToken).transferFrom(msg.sender, address(this), _bidAmount);

        Game memory newGame = Game(
            gameType,

            uint(1),
            _GameID,
            _bidAmount,
            _bidAmount,
            Status.CREATED,

            msg.sender,
            new address[](0),
            new address[](0),
            address(0),

            false,
            true
        );

        gameByID[_GameID] = newGame;
        gameByID[_GameID].players.push(msg.sender);
        
        emit GameCreated(_GameID,msg.sender, gameByID[_GameID].gameType.gameTypeId, gameByID[_GameID].status);
    }

    function  cancelGameCreation(bytes16 _GameID) public
    {
        require(gameByID[_GameID].status == Status.CREATED && msg.sender == gameByID[_GameID].gameCreator, "You're not allowed to cancel this game");

        for (uint256 i = 0; i < gameByID[_GameID].players.length; i++)
        {
            if(gameByID[_GameID].players[i] != address(0))
                ERC20(AuraToken).transfer(gameByID[_GameID].players[i], gameByID[_GameID].bid);
        }

        gameByID[_GameID].status = Status.CANCELLED;

        emit GameCancelled(_GameID, gameByID[_GameID].status);
    }

    function joinGame(bytes16 _GameID) public
    {
        require(gameByID[_GameID].status == Status.CREATED, "Game does not exist");
        require(!isPresentInGame(_GameID, msg.sender), "You already joined the game");

        ERC20(AuraToken).transferFrom(msg.sender, address(this), gameByID[_GameID].bid);

        gameByID[_GameID].players.push(msg.sender);
        gameByID[_GameID].nbPlayers = gameByID[_GameID].nbPlayers + uint(1);
        gameByID[_GameID].poolPrize = gameByID[_GameID].poolPrize + gameByID[_GameID].bid;

        emit GameJoined(_GameID,msg.sender);

        if(gameByID[_GameID].players.length == gameByID[_GameID].gameType.nbPlayersMax)
        {
            gameByID[_GameID].status = Status.STARTED;
            emit GameStarted(_GameID, gameByID[_GameID].status, gameByID[_GameID].players.length);
        }
    }

    function isPresentInGame(bytes16 _GameID, address _player) public view returns(bool)
    {
        address[] storage players = gameByID[_GameID].players;
        for (uint256 i = 0; i < players.length; i++)
        {
            if (players[i] == _player)
                return true;
        }
        return false;
    }

    function isOutOfGame(bytes16 _GameID, address _player) public view returns(bool)
    {
        require(gameByID[_GameID].isValue, "Game does not exist");

        address[] storage playersOut = gameByID[_GameID].playersOut;
        for (uint256 i = 0; i < playersOut.length; i++)
        {
            if (playersOut[i] == _player)
                return true;
        }
        return false;
    }

    function startGame(bytes16 _GameID) public
    {
        require(gameByID[_GameID].status == Status.CREATED && gameByID[_GameID].gameCreator == msg.sender, "Game does not exist or you're not allowed to start it");
        require(gameByID[_GameID].players.length >= gameByID[_GameID].gameType.nbPlayersMin, "Waiting for other players");

        gameByID[_GameID].status = Status.STARTED;

        emit GameStarted(_GameID, gameByID[_GameID].status, gameByID[_GameID].players.length);
    }

    // Returns 0x000...000 if more than 1 player is in game, the single address else
    function getLastPlayer(bytes16 _GameID) public view returns(address) 
    {
        address player = address(0);
        for (uint256 i = 0; i < gameByID[_GameID].players.length; i++)
        {
            if(gameByID[_GameID].players[i] != address(0))
            {
                if(player == address(0))
                    player = gameByID[_GameID].players[i];
                else
                    return address(0);
            }
        }
        return player;
    }

    function playerLeaves(bytes16 _GameID, address _player) public onlyGameMaster
    {
        require(!isOutOfGame(_GameID, _player), "Player is already out");
        require(isPresentInGame(_GameID, _player), "Not present in game");

        for (uint256 i = 0; i < gameByID[_GameID].players.length; i++)
        {
            if (gameByID[_GameID].players[i] == _player)
            {
                gameByID[_GameID].players[i] = address(0);
                gameByID[_GameID].nbPlayers = gameByID[_GameID].nbPlayers - uint(1);
                gameByID[_GameID].playersOut.push(_player);

                if(gameByID[_GameID].nbPlayers == 1)
                {
                    address winner = getLastPlayer(_GameID);
                    if(winner != address(0))
                        setWinner(_GameID, winner);
                }
            }
        }
    }

    function rewardLastPlayers(bytes16 _GameID) public onlyGameMaster
    {
        require(!gameByID[_GameID].winnerRewarded, "Winners has already been rewarded");

        uint256 rewardPerPlayer = uint(gameByID[_GameID].poolPrize) / uint(gameByID[_GameID].nbPlayers);
        rewardPerPlayer = rewardPerPlayer - uint(rewardPerPlayer * rewardFees / 100);

        for (uint256 i = 0; i < gameByID[_GameID].players.length; i++)
        {
            if(gameByID[_GameID].players[i] != address(0))
            {
                ERC20(AuraToken).transfer(gameByID[_GameID].players[i], rewardPerPlayer);
            }
        }
        gameByID[_GameID].status = Status.CANCELLED;
        gameByID[_GameID].winnerRewarded = true;
    }

    function setWinner(bytes16 _GameID, address _winner) public onlyGameMaster 
    {
        require(!gameByID[_GameID].winnerRewarded, "Game has ended and reward already transferred to the winner");
        require(isPresentInGame(_GameID, _winner), "Given address is incorrect");

        uint256 reward = gameByID[_GameID].poolPrize - uint(gameByID[_GameID].poolPrize * rewardFees / 100);

        gameByID[_GameID].winner = _winner;
        gameByID[_GameID].status = Status.FINISHED;

        ERC20(AuraToken).transfer(gameByID[_GameID].winner, reward);
        gameByID[_GameID].winnerRewarded = true;

        emit WinnerRewarded(gameByID[_GameID].winner, reward);
        emit GameFinished(_GameID, gameByID[_GameID].status, _winner);
    }

    function transferLiquidity(uint256 _amount) public onlyGameMaster
    {
        require(ERC20(AuraToken).balanceOf(GameMaster) > _amount, "GameMaster balance is too low to make transaction");
        ERC20(AuraToken).transfer(GameMaster, _amount);
    }

    function transferAllLiquidity() public onlyGameMaster
    {
        require(ERC20(AuraToken).balanceOf(GameMaster) > 0, "GameMaster balance is null, can't proceed");
        ERC20(AuraToken).transfer(GameMaster, ERC20(AuraToken).balanceOf(address(this)));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
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
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
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
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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