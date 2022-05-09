// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "IBettable.sol";
import "IBetResolvable.sol";
import "INicknameStorage.sol";

contract Betting is Ownable, IBettable, INicknameStorage, IBetResolvable {

    address[] public allowedTokens;
    mapping(address => uint256[]) public allowedBets;
    mapping(address => uint256) public commision;

    // Tokens will be locked for this long
    uint256 public lockTime = 15 minutes;

    uint256 public currentBetNumber = 1;

    uint256 public payoutPercentage = 95;

    struct Bet {
        uint256 uniqueIdentifier;
        address player;
        address token;
        uint256 amount;
        uint256 enterDate;
    }

    Bet[] public currentBets;
    mapping(uint256 => Bet) public allBets;


    function allowBet(address _token, uint256 _amount) onlyOwner public {
        if (!tokenIsAllowed(_token)) {
            allowedTokens.push(_token);
        }
        if (!betIsAllowed(_token, _amount)) {
            allowedBets[_token].push(_amount);
        }
    }

    event BetPlaced(address _player, address _token, uint256 _amount);
    event BetRefunded(address _player, address _token, uint256 _amount);
    event BetSettled(address _player1, address _player2, address _token, uint256 _winnerAmount, uint256 _commisionAmount);

    function withdrawCommisions() onlyOwner public {
        for (uint256 i = 0; i<allowedTokens.length; ++i) {
            address token = allowedTokens[i];
            IERC20 tokenContract = IERC20(token);
            uint256 amount = commision[token];
            require (tokenContract.balanceOf(address(this)) >= amount, "Fatal error, unexpected amount");
            commision[token] = 0;
            tokenContract.transfer(msg.sender, amount);
        }
    }

    function enterWithBet(address _token, uint256 _amount) external returns (uint256) {
        require(_amount > 0, "Amount must be more than 0");
        require(tokenIsAllowed(_token), "Token is currently not allowed!");
        require(betIsAllowed(_token, _amount), "This bet amount is not allowed!");
        require(playerAllowedToEnter(msg.sender), "You cannot enter right now.");
        // // TransferFrom - allowed ! :)
        IERC20 tokenContract = IERC20(_token);
        
        currentBets.push(Bet(
            currentBetNumber,
            msg.sender,
            _token,
            _amount,
            block.timestamp
        ));
        
        allBets[currentBets[currentBets.length-1].uniqueIdentifier] = currentBets[currentBets.length-1];
        currentBetNumber += 1;

        tokenContract.transferFrom(msg.sender, address(this), _amount);

        emit BetPlaced(msg.sender, _token, _amount);
        return currentBets[currentBets.length-1].uniqueIdentifier;
    }

    function refundNeeded() onlyOwner public view returns (bool) {
        for (uint256 i = 0; i<currentBets.length; i++) {
            if (betIsExpired(currentBets[i].uniqueIdentifier)) {
                return true;
            }
        }
        return false;
    }

    function refundAll() onlyOwner public {
        for (uint256 i = 0; i<currentBets.length; i++) {
            if (betIsExpired(currentBets[i].uniqueIdentifier)) {
                refund(currentBets[i].uniqueIdentifier);
                i = 0;
            }
        } 
    }

    function refund(uint256 _betIdentifier) onlyOwner internal {
        require(isBetInProgress(_betIdentifier));
        removeBet(_betIdentifier);
        address token = allBets[_betIdentifier].token;
        uint256 amount = allBets[_betIdentifier].amount;
        address player = allBets[_betIdentifier].player;
        IERC20(token).transfer(player, amount);
        emit BetRefunded(player, token, amount);
    }

    function matchSettled(uint256 _betId1, uint256 _betId2, uint256 _winnerIndex) onlyOwner public {
        require(_betId1 != _betId2);
        require(isBetInProgress(_betId1), "Bet already settled");
        require(isBetInProgress(_betId2), "Bet already settled");

        Bet memory bet1 = allBets[_betId1];
        Bet memory bet2 = allBets[_betId2];

        require(areBetsCompatible(_betId1, _betId2), "Cannot settle bet for different amounts. Please refund manually");
        uint256 totalPool = bet1.amount + bet2.amount;
        uint256 wonAmount = (totalPool * payoutPercentage) / 100;
        uint256 betCommision = totalPool - wonAmount;

        address winner;

        if (_winnerIndex == 0) {
            winner = bet1.player;
        } else {
            winner = bet2.player;
        }

        removeBet(_betId1);
        removeBet(_betId2);
        commision[bet1.token] += betCommision;
        IERC20 token = IERC20(bet1.token);
        token.transfer(winner, wonAmount);
        emit BetSettled(bet1.player, bet2.player, bet1.token, wonAmount, betCommision);
    }

    function getPayoutForBet(address _token, uint256 _amount) external view returns (uint256) {
        require(betIsAllowed(_token, _amount), "Bet is not allowed");
        uint256 totalPool = _amount * 2;
        return (totalPool * payoutPercentage) / 100;
    }

    function areBetsCompatible(uint256 _bet1Identifier, uint256 _bet2Identifier) public view returns(bool) {
        Bet memory bet1 = allBets[_bet1Identifier];
        Bet memory bet2 = allBets[_bet2Identifier];
        require (bet1.player != address(0), "Invalid bet");
        require (bet2.player != address(0), "Invalid bet");
        require (_bet1Identifier != _bet2Identifier);
        return bet1.token == bet2.token && bet1.amount == bet2.amount && bet1.player != bet2.player;
    }

    function isBetInProgress(uint256 _betIdentifier) public view returns (bool) {
        require(allBets[_betIdentifier].player != address(0), "Invalid bet");
        for (uint256 i = 0; i < currentBets.length; i++) {
            if (currentBets[i].uniqueIdentifier == _betIdentifier) {
                return true;
            }
        }
        return false;
    }

    function removeBet(uint256 _betIdentifier) onlyOwner internal {
        require (currentBets.length > 0);
        uint256 index = indexOfBet(_betIdentifier);
        require (index < currentBets.length);
        if (currentBets.length > 1) {
            currentBets[index] = currentBets[currentBets.length - 1];
        }
        currentBets.pop();
    }

    function indexOfBet(uint256 _betIdentifier) public view returns (uint256) {
        for (uint256 i = 0; i < currentBets.length; i++) {
            if (currentBets[i].uniqueIdentifier == _betIdentifier) {
                return i;
            }
        }
        require(false, "Cannot find bet");
    }
    

    function betIsExpired(uint256 _betIdentifier) public view returns (bool) {
        return block.timestamp > allBets[_betIdentifier].enterDate + lockTime;
    }

    function playerAllowedToEnter(address _player) public view returns (bool) {
        // This is disabled for current testing purposes
        // return !playerCurrentlyBetting(_player);
        return true;
    }

    function playerCurrentlyBetting(address _player) external view returns (bool) {
        for (uint256 i = 0; i < currentBets.length; i++) {
            if (currentBets[i].player == _player) {
                return true;
            }
        }
        return false;
    }

    function betIsAllowed(address _token, uint256 _amount) public view returns (bool) {
        if (!tokenIsAllowed(_token)) { return false; }
        uint256[] memory allowedBetsForToken = allowedBets[_token];
        for (uint256 i=0; i<allowedBetsForToken.length; ++i) {
            if (allowedBetsForToken[i] == _amount) {
                return true;
            }
        }
        return false;
    }

    function tokenIsAllowed(address _token) public view returns (bool) {
        for (uint256 i = 0; i < allowedTokens.length; i++) {
            if (allowedTokens[i] == _token) {
                return true;
            }
        }
        return false;
    }

    function getAllowedBets(address _token) external view returns (uint256[] memory) {
        return allowedBets[_token];
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokens;
    }

/// INicknameStorage

    mapping (address => string) private nicknames;

    function saveNickname(string memory _nickname) external {
         nicknames[msg.sender] = _nickname;
    }

    function hasNickname(address _player) external view returns (bool) {
        bytes memory stringValue = bytes(nicknames[_player]);
        return stringValue.length != 0;
    }

    function hasNickname() external view returns (bool) {
        return this.hasNickname(msg.sender);
    }

    function getNickname(address _player) external view returns (string memory) {
        return nicknames[_player];
    }

    function getNickname() external view returns (string memory) {
        return this.getNickname(msg.sender);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IBettable {
    // This will charge sender with amount of token, only when bet is allowed. Please remember to first approve _token for address of this contract
    function enterWithBet(address _token, uint256 _amount) external returns (uint256);

    // How much can I earn when betting this amount of token if I win?
    function getPayoutForBet(address _token, uint256 _amount) external view returns (uint256);

    // Indicates whether there are any unsettled bets for player address
    function playerCurrentlyBetting(address _player) external view returns (bool);

    // Can I bet token from address _token? This must be ERC20.
    function tokenIsAllowed(address _token) external view returns (bool);

    // Can I bet this amount of token?
    function betIsAllowed(address _token, uint256 _amount) external view returns (bool);

    function getAllowedTokens() external view returns (address[] memory);
    function getAllowedBets(address _token) external view returns (uint256[] memory);
    
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface IBetResolvable {
    function withdrawCommisions() external;
    function refundNeeded() external view returns (bool);
    function refundAll() external;
    function matchSettled(uint256 _betId1, uint256 _betId2, uint256 _winnerIndex) external;
}

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.0;

interface INicknameStorage {
    function saveNickname(string memory _nickname) external;
    function hasNickname() external view returns (bool);
    function getNickname() external view returns (string memory);
}