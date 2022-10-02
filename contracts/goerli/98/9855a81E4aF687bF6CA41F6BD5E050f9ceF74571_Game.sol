// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.0.0/contracts/token/ERC20/IERC20.sol";


contract Game {

    address public UCTCTokenAddress;

    constructor(address _token) {
        UCTCTokenAddress = _token;
    }

    struct EyeSpyGame {
        uint256 id;
        uint256 costToPlay;
        uint256 numberOfGuesses;
        uint256 prize;
        address winner;
        address owner;
        bool gameStatus;
    }

    mapping(uint256 => bytes32) private answers;
    mapping(uint256 => EyeSpyGame) public games;
    uint256 numberOfGames = 0;

    function createGame(bytes32 _answer, uint256 _costToPlay) public {
        require(_costToPlay < 1000, "Cost too large");

        games[numberOfGames] = EyeSpyGame({
            id: numberOfGames,
            costToPlay: _costToPlay,
            numberOfGuesses: 0,
            prize: 0,
            winner: address(0),
            owner: msg.sender,
            gameStatus: true
        });

        answers[numberOfGames] = _answer;

        numberOfGames++;
    }

    function playGame(uint256 _gameId, bytes32 _guess) public {

        EyeSpyGame memory tempGame = games[_gameId];

        require(tempGame.gameStatus == true, "Game is closed");
        require(_gameId <= numberOfGames, "Invalid game ID");
        require(msg.sender != tempGame.owner, "STOP STEALING");

        require(IERC20(UCTCTokenAddress).transferFrom(msg.sender, address(this), tempGame.costToPlay), "Transfer Failed"); 
        
        games[_gameId].prize += tempGame.costToPlay;
        games[_gameId].numberOfGuesses++;

        if (_guess == answers[_gameId]){
            // send the prize money to the address of the guesser, and close the game
            games[_gameId].winner = msg.sender;
            games[_gameId].gameStatus = false;

            IERC20(UCTCTokenAddress).transfer(msg.sender, games[_gameId].prize);
        }
    }
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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