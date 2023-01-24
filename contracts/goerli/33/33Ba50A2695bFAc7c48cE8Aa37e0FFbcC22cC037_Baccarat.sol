//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./interfaces/IBaccarat.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Baccarat is IBaccarat, Ownable {
    Card[] public Shoe;
    uint256 public ShoeCursor;

    BettingView[] public BettingViews;

    // player address => token address => amount
    mapping(address => mapping(address => uint256)) public Credit;

    Card[] private playerHands;
    Card[] private bankerHands;

    constructor() {
        // push 8 decks of cards into shoe
        for (uint256 i = 0; i < 8; i++) {
            for (uint256 j = 0; j < 52; j++) {
                Card memory card;
                card.suit = uint8(j / 13) + 1;
                card.rank = uint8(j % 13) + 1;
                Shoe.push(card);
            }
        }
    }

    // @notice Use Knuth shuffle algorithm to shuffle the cards
    // @param _seed random seed, from business data and block data
    function shuffle(uint256 _seed) public {
        uint256 n = Shoe.length;
        for (uint256 i = ShoeCursor; i < n; i++) {
            // Pseudo random number between i and n-1
            uint256 j = i + uint256(keccak256(abi.encodePacked(i, _seed))) % (n - i);
            // swap i and j
            Card memory temp = Shoe[i];
            Shoe[i] = Shoe[j];
            Shoe[j] = temp;
        }
    }

    // @notice player betting
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair, 5 = banker super six, 6 = player super six
    function betting(address _token, uint256 _amount, uint256 _betType) payable external {
        if (_token == address(0)) {
            require(msg.value >= _amount, "Baccarat: betting amount is not enough");
        } else {
            require(IERC20(_token).transferFrom(msg.sender, address(this), _amount), "Baccarat: ERC20 transferFrom failed");
        }

        // check if already bet, if yes, add amount
        bool bet = false;
        for (uint256 i = 0; i < BettingViews.length; i++) {
            if (BettingViews[i].player == msg.sender && BettingViews[i].token == _token && BettingViews[i].betType == _betType) {
                BettingViews[i].amount += _amount;
                bet = true;
                break;
            }
        }
        if (!bet) {
            BettingViews.push(BettingView(msg.sender, _token, _amount, _betType));
        }
    }

    function _getPoint(uint256 _rank) internal pure returns (uint256) {
        if (_rank >= 10) {
            return 0;
        } else {
            return _rank;
        }
    }

    function _safeTransfer(address _token, address _to, uint256 _amount) internal {
        if (_token == address(0)) {
            if (address(this).balance >= _amount) {
                payable(_to).transfer(_amount);
            } else {
                Credit[_to][_token] += _amount;
            }
        } else {
            if (IERC20(_token).balanceOf(address(this)) >= _amount) {
                IERC20(_token).transfer(_to, _amount);
            } else {
                Credit[_to][_token] += _amount;
            }
        }
    }

    function _hasPair(Card[] memory _cards) internal pure returns (bool) {
        for (uint256 i = 0; i < _cards.length; i++) {
            for (uint256 j = i + 1; j < _cards.length; j++) {
                if (_cards[i].rank == _cards[j].rank) {
                    return true;
                }
            }
        }
        return false;
    }

    function _canSettle() internal view returns (bool) {
        // need both have banker and player betting
        bool banker = false;
        bool player = false;
        for (uint256 i = 0; i < BettingViews.length; i++) {
            if (BettingViews[i].betType == 0) {
                banker = true;
            } else if (BettingViews[i].betType == 1) {
                player = true;
            }
        }

        return banker && player;
    }

    function settle(uint256 nonce) external {
        require(_canSettle(), "Baccarat: need both bet banker and player");

        // delete playerHands and bankerHands
        delete playerHands;
        delete bankerHands;

        uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                ShoeCursor,
                nonce
            )));
        if (Shoe.length - ShoeCursor < 6) {
            // shuffle
            ShoeCursor = 0;
            shuffle(seed);
        } else {
            // re-shuffle the Shoe after cursor
            shuffle(seed);
        }

        // player hands
        playerHands.push(Shoe[ShoeCursor]);
        bankerHands.push(Shoe[ShoeCursor + 1]);
        playerHands.push(Shoe[ShoeCursor + 2]);
        bankerHands.push(Shoe[ShoeCursor + 3]);
        ShoeCursor += 4;

        // calculate hands value
        uint256 playerHandsValue = _getPoint(_getPoint(playerHands[0].rank) + _getPoint(playerHands[1].rank));
        uint256 bankerHandsValue = _getPoint(_getPoint(bankerHands[0].rank) + _getPoint(bankerHands[1].rank));

        // if not Natural
        if (playerHandsValue < 8 && bankerHandsValue < 8) {
            // if player hands value is less than 6, draw a third card
            if (playerHandsValue < 6) {
                playerHands.push(Shoe[ShoeCursor]);
                playerHandsValue = _getPoint(playerHandsValue + _getPoint(playerHands[2].rank));
                ShoeCursor += 1;
            }

            // if player no need draw a third card, banker < 6, banker need draw a third card
            if (playerHands.length == 2 && bankerHandsValue < 6) {
                // draw
                bankerHands.push(Shoe[ShoeCursor]);
                bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                ShoeCursor += 1;
            }

            if (playerHands.length == 3) {
                if (bankerHandsValue <= 2) {
                    // draw
                    bankerHands.push(Shoe[ShoeCursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                    ShoeCursor += 1;
                }
                if (bankerHandsValue == 3 && _getPoint(playerHands[2].rank) != 8) {
                    // draw
                    bankerHands.push(Shoe[ShoeCursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                    ShoeCursor += 1;
                }
                if (bankerHandsValue == 4 && _getPoint(playerHands[2].rank) >= 2 && _getPoint(playerHands[2].rank) <= 7) {
                    // draw
                    bankerHands.push(Shoe[ShoeCursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                    ShoeCursor += 1;
                }
                if (bankerHandsValue == 5 && _getPoint(playerHands[2].rank) >= 4 && _getPoint(playerHands[2].rank) <= 7) {
                    // draw
                    bankerHands.push(Shoe[ShoeCursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                    ShoeCursor += 1;
                }
                if (bankerHandsValue == 6 && _getPoint(playerHands[2].rank) >= 6 && _getPoint(playerHands[2].rank) <= 7) {
                    // draw
                    bankerHands.push(Shoe[ShoeCursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(bankerHands[2].rank));
                    ShoeCursor += 1;
                }
            }
        }

        // settle the bet
        if (playerHandsValue < bankerHandsValue) {
            for (uint256 i = 0; i < BettingViews.length; i++) {
                // banker win, 1 : 0.95
                if (BettingViews[i].betType == uint256(BetType.Banker)) {
                    _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 195 / 100);
                    _safeTransfer(BettingViews[i].token, owner(), BettingViews[i].amount * 5 / 100);
                }
                // banker win and super six, 1 : 20
                if (BettingViews[i].betType == uint256(BetType.BankerSuperSix) && bankerHandsValue == 6) {
                    if (bankerHands.length == 3) {
                        _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 21);
                    } else {
                        _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 13);
                    }
                }
            }
        } else if (playerHandsValue > bankerHandsValue) {
            // player win, 1 : 1
            for (uint256 i = 0; i < BettingViews.length; i++) {
                if (BettingViews[i].betType == uint256(BetType.Player)) {
                    _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 2);
                }
                // player win and super six, 1 : 20
                if (BettingViews[i].betType == uint256(BetType.PlayerSuperSix) && playerHandsValue == 6) {
                    if (playerHands.length == 3) {
                        _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 21);
                    } else {
                        _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 13);
                    }
                }
            }
        } else {
            // tie, 1 : 8
            for (uint256 i = 0; i < BettingViews.length; i++) {
                if (BettingViews[i].betType == uint256(BetType.Tie)) {
                    _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 9);
                }
            }
        }

        // check pair
        if (_hasPair(bankerHands)) {
            // player pair, 1 : 11
            for (uint256 i = 0; i < BettingViews.length; i++) {
                if (BettingViews[i].betType == uint256(BetType.BankerPair)) {
                    _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 12);
                }
            }
        }

        if (_hasPair(playerHands)) {
            // player pair, 1 : 11
            for (uint256 i = 0; i < BettingViews.length; i++) {
                if (BettingViews[i].betType == uint256(BetType.PlayerPair)) {
                    _safeTransfer(BettingViews[i].token, BettingViews[i].player, BettingViews[i].amount * 12);
                }
            }
        }
    }

    function withdraw(address _token, uint256 _amount) external {
        require(Credit[msg.sender][_token] >= _amount, "not enough credit");
        Credit[msg.sender][_token] -= _amount;
        _safeTransfer(_token, msg.sender, _amount);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IBaccarat{
    enum BetType {
        Banker,
        Player,
        Tie,
        BankerPair,
        PlayerPair,
        BankerSuperSix,
        PlayerSuperSix
    }

    struct Card {
        uint8 rank; // 1-13, 1 is Ace, 11 is Jack, 12 is Queen, 13 is King
        uint8 suit; // 1-4, 1 = spades, 2 = hearts, 3 = diamonds, 4 = clubs
    }

    struct BettingView {
        address player;
        address token;
        uint256 amount;
        uint256 betType;
    }

    // Returns the shuffled deck of cards
    function shuffle(uint256 _seed) external;

    // @notice player betting
    // can be appended,
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair
    function betting(address _token, uint256 _amount, uint256 _betType) payable external;

    // @notice play the game and settle the bet
    function settle(uint256 nonce) external;
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