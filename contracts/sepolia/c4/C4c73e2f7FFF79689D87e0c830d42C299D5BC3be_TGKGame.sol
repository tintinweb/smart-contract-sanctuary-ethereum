/**
 *Submitted for verification at Etherscan.io on 2023-05-23
*/

// Sources flattened with hardhat v2.14.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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


// File @openzeppelin/contracts/token/ERC20/[email protected]


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


// File contracts/TGKGame.sol



pragma solidity ^0.8.0;


interface ITGKToken is IERC20 {
    function burn(uint256 value) external;
}

contract TGKGame is Ownable {
    ITGKToken public token;
    uint256 public gameEndTime;
    uint256 public gameCounter;
    uint256 public tokensToBurn;

    struct GameBalance {
        uint256 lastGameId;
        uint256 amount;
    }

    struct GameWinnerInfo {
        address winnerAddress;
        uint256 winningAmount;
    }

    mapping(address => GameBalance) public stakedBalances;
    mapping(address => uint256) internal claimableAmount;
    mapping(uint256 => GameWinnerInfo[]) internal gameWinners;
    mapping(uint256 => bool) internal gameWinnersSet;

    event Staked(uint256 indexed gameCounter,address indexed user, uint256 amount);
    event Claimed(uint256 indexed gameCounter,address indexed user, uint256 amount);
    event GameStarted(uint256 indexed gameCounter, uint256 gameEndTime);
    event GameWinner(uint256 indexed gameCounter, address user, uint256 winningAmount);
    event SetWinners(uint256 gameCount);
    event WinnersList(uint256 gameCount, address[] gameWinners);

    constructor(address tokenAddress) {
        token = ITGKToken(tokenAddress);
        gameWinnersSet[0]=true;
        gameCounter=1;
    }

    function isGameLive() public view returns(bool) {
        return block.timestamp < gameEndTime;
    }

    function isGameWinnersSet(uint256 gameId) internal view returns(bool) {
        return gameWinnersSet[gameId];
    }

    function startGame(uint256 gameDuration) external onlyOwner {
        require(!isGameLive(), "Game is live");
        require(isGameWinnersSet(gameCounter-1),"Winners not set");
        uint256 gameEnd = block.timestamp + gameDuration;
        gameEndTime = gameEnd;
        emit GameStarted(gameCounter, gameEnd);
    }

    function stake(uint256 _amount) external {
        require(isGameLive(), "Game not live");
        GameBalance memory stakedBalance = stakedBalances[msg.sender];
        if(gameCounter > stakedBalance.lastGameId && stakedBalance.amount >0){
            claimableAmount[msg.sender] += stakedBalance.amount/2;
            stakedBalance.amount=0;
            tokensToBurn += stakedBalance.amount/2;
        }
        token.transferFrom(msg.sender, address(this), _amount);
        stakedBalances[msg.sender].lastGameId = gameCounter;
        stakedBalances[msg.sender].amount = _amount + stakedBalance.amount;
        emit Staked(gameCounter, msg.sender, _amount);
    }

    function claim() external {
        // user will claim all the winning amount
        GameBalance memory stakedBalance = stakedBalances[msg.sender];
        uint256 claimAmount = claimableAmount[msg.sender];

        if(gameCounter > stakedBalance.lastGameId && stakedBalance.amount >0){
            claimAmount += stakedBalance.amount/2;
            stakedBalances[msg.sender].amount=0;
            tokensToBurn += stakedBalance.amount/2;
        }
        claimableAmount[msg.sender] = 0;
        token.transfer(msg.sender,claimAmount);
        require(claimAmount>0, "No tokens to claim");
        emit Claimed(gameCounter, msg.sender, claimAmount);       
    }

    function setWinners(address[] calldata users, uint256[] calldata multipliers) external onlyOwner {
        require(!isGameLive(), "Game is live");
        require(!isGameWinnersSet(gameCounter),"Winners already set");
        uint256 winningAmount;
        GameWinnerInfo[] storage gameWinnerInfoList = gameWinners[gameCounter];
        for(uint i=0;i<users.length;i++){
            winningAmount =  (stakedBalances[users[i]].amount * multipliers[i])/10000;
            stakedBalances[users[i]].amount=0;
            claimableAmount[users[i]] += winningAmount;
            gameWinnerInfoList.push(GameWinnerInfo(users[i],winningAmount));
            emit GameWinner(gameCounter, users[i], winningAmount);
        }
        emit SetWinners(gameCounter);
        gameWinnersSet[gameCounter]=true;

        gameCounter++;
    }

    function burnToken() external onlyOwner {
        token.burn(tokensToBurn);
        tokensToBurn=0;
    }

    function getGameWinners(uint256 gameId) external view returns(GameWinnerInfo [] memory) {
        return gameWinners[gameId];
    }

    function getClaimableAmount(address user) external view returns(uint256 claimAmount) {
        GameBalance memory stakedBalance = stakedBalances[user];
        claimAmount = claimableAmount[user];
        if(gameCounter > stakedBalance.lastGameId && stakedBalance.amount >0){
            claimAmount += stakedBalance.amount/2;
        }
    }

}