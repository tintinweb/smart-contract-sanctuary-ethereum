// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CoinTossGame {
    address public owner;
    mapping(address => mapping(address => uint256)) public balances;

    enum CoinSide {Heads, Tails}
    enum GameResult {Pending, Win, Lose}

    struct Game {
        address player;
        CoinSide chosenSide;
        GameResult result;
    }

    Game[] public games;

    address public erc20Token; // Address of the specific ERC20 token

    event GameStarted(uint256 indexed gameId, address indexed player);
    event GameEnded(uint256 indexed gameId, GameResult result);
    event HouseBalanceDeposited(uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function.");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setERC20Token(address _tokenAddress) external onlyOwner {
        erc20Token = _tokenAddress;
    }

    function startGame(CoinSide _chosenSide, uint256 _betAmount) external {
        require(_chosenSide == CoinSide.Heads || _chosenSide == CoinSide.Tails, "Invalid coin side.");

        IERC20 token = IERC20(erc20Token);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _betAmount, "Insufficient allowance to play the game.");

        uint256 balanceBefore = token.balanceOf(address(this));

        token.transferFrom(msg.sender, address(this), _betAmount);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == _betAmount, "Token transfer failed.");

        uint256 gameId = games.length;
        games.push(Game(msg.sender, _chosenSide, GameResult.Pending));
        emit GameStarted(gameId, msg.sender);

        // Perform the coin toss and determine the result
        CoinSide coinSide = randomCoinSide();
        GameResult result = (coinSide == _chosenSide) ? GameResult.Win : GameResult.Lose;
        games[gameId].result = result;

        emit GameEnded(gameId, result);

        // Transfer the funds from the house balance to the player if they win
        if (result == GameResult.Win) {
            balances[msg.sender][erc20Token] += _betAmount;
        } else {
            balances[address(this)][erc20Token] += _betAmount;
        }
    }

    function randomCoinSide() private view returns (CoinSide) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 2;
        return CoinSide(randomNumber);
    }

    function withdrawFunds(address _token, uint256 _amount) external {
        require(_amount <= balances[msg.sender][_token], "Insufficient balance.");
        balances[msg.sender][_token] -= _amount;

        IERC20 token = IERC20(_token);
        token.transfer(msg.sender, _amount);
    }

    function withdrawHouseBalance(address _token) external onlyOwner {
        uint256 amount = balances[address(this)][_token];
        require(amount > 0, "No house balance to withdraw.");
        balances[address(this)][_token] = 0;

        IERC20 token = IERC20(_token);
        token.transfer(owner, amount);
    }

    function depositToHouseBalance(address _token, uint256 _amount) external onlyOwner {
        IERC20 token = IERC20(_token);
        uint256 allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amount, "Insufficient allowance to deposit to house balance.");

        uint256 balanceBefore = token.balanceOf(address(this));

        token.transferFrom(msg.sender, address(this), _amount);

        uint256 balanceAfter = token.balanceOf(address(this));
        require(balanceAfter - balanceBefore == _amount, "Token transfer failed.");

        balances[address(this)][_token] += _amount;

        emit HouseBalanceDeposited(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}