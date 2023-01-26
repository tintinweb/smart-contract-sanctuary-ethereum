//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBaccarat.sol";

contract Baccarat is IBaccarat, Ownable {
    Card[] private _shoe;
    uint256 private _cursor;

    LayoutAction[] private _layout;

    // player address => token address => amount
    // user can withdraw Cheques
    mapping(address => mapping(address => uint256)) private _cheques;

    Card[] private _playerHands;
    Card[] private _bankerHands;

    constructor() {
        // push 8 decks of cards into shoe
        for (uint256 i = 0; i < 8; i++) {
            for (uint256 j = 0; j < 52; j++) {
                Card memory card;
                card.suit = uint8(j / 13) + 1;
                card.rank = uint8(j % 13) + 1;
                _shoe.push(card);
            }
        }
    }

    // @notice player action
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair, 5 = banker super six, 6 = player super six
    function action(address _token, uint256 _amount, uint256 _betType) payable external {
        uint256 cheques = _cheques[msg.sender][_token];
        if (_token == address(0)) {
            if (cheques >= _amount) {
                _cheques[msg.sender][_token] = cheques - _amount;
            } else {
                _cheques[msg.sender][_token] = 0;
                require(msg.value == _amount - cheques, "Baccarat: insufficient ether");
            }
        } else {
            if (cheques >= _amount) {
                _cheques[msg.sender][_token] = cheques - _amount;
            } else {
                _cheques[msg.sender][_token] = 0;
                require(IERC20(_token).transferFrom(msg.sender, address(this), _amount - cheques), "Baccarat: insufficient token");
            }
        }

        // check if already bet, if yes, add amount
        bool bet = false;
        for (uint256 i = 0; i < _layout.length; i++) {
            if (_layout[i].player == msg.sender && _layout[i].token == _token && _layout[i].betType == _betType) {
                _layout[i].amount += _amount;
                bet = true;
                break;
            }
        }
        if (!bet) {
            _layout.push(LayoutAction(msg.sender, _token, _amount, _betType));
        }

        emit Action(_token, _amount, _betType);
    }

    // @notice play the game and settle the bet
    // @param nonce random number, anyone can call this function
    function settle(uint256 nonce) external {
        require(_checkAction(), "Baccarat: need both bet banker and player");

        // delete playerHands and bankerHands
        delete _playerHands;
        delete _bankerHands;

        uint256 seed = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                _cursor,
                nonce
            )));
        if (_shoe.length - _cursor < 6) {
            // shuffle
            _cursor = 0;
            _shuffle(seed);
            _burning();
        } else {
            // re-shuffle the Shoe after cursor
            _shuffle(seed);
        }

        ActionResult memory result;

        // player hands
        _playerHands.push(_shoe[_cursor]);
        _bankerHands.push(_shoe[_cursor + 1]);
        _playerHands.push(_shoe[_cursor + 2]);
        _bankerHands.push(_shoe[_cursor + 3]);
        _cursor += 4;

        // calculate hands value
        uint256 playerHandsValue = _getPoint(_getPoint(_playerHands[0].rank) + _getPoint(_playerHands[1].rank));
        uint256 bankerHandsValue = _getPoint(_getPoint(_bankerHands[0].rank) + _getPoint(_bankerHands[1].rank));

        // if not Natural
        if (playerHandsValue < 8 && bankerHandsValue < 8) {
            // if player hands value is less than 6, draw a third card
            if (playerHandsValue < 6) {
                _playerHands.push(_shoe[_cursor]);
                playerHandsValue = _getPoint(playerHandsValue + _getPoint(_playerHands[2].rank));
                _cursor += 1;
            }

            // if player no need draw a third card, banker < 6, banker need draw a third card
            if (_playerHands.length == 2 && bankerHandsValue < 6) {
                // draw
                _bankerHands.push(_shoe[_cursor]);
                bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                _cursor += 1;
            }

            if (_playerHands.length == 3) {
                if (bankerHandsValue <= 2) {
                    // draw
                    _bankerHands.push(_shoe[_cursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                    _cursor += 1;
                }
                if (bankerHandsValue == 3 && _getPoint(_playerHands[2].rank) != 8) {
                    // draw
                    _bankerHands.push(_shoe[_cursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                    _cursor += 1;
                }
                if (bankerHandsValue == 4 && _getPoint(_playerHands[2].rank) >= 2 && _getPoint(_playerHands[2].rank) <= 7) {
                    // draw
                    _bankerHands.push(_shoe[_cursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                    _cursor += 1;
                }
                if (bankerHandsValue == 5 && _getPoint(_playerHands[2].rank) >= 4 && _getPoint(_playerHands[2].rank) <= 7) {
                    // draw
                    _bankerHands.push(_shoe[_cursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                    _cursor += 1;
                }
                if (bankerHandsValue == 6 && _getPoint(_playerHands[2].rank) >= 6 && _getPoint(_playerHands[2].rank) <= 7) {
                    // draw
                    _bankerHands.push(_shoe[_cursor]);
                    bankerHandsValue = _getPoint(bankerHandsValue + _getPoint(_bankerHands[2].rank));
                    _cursor += 1;
                }
            }
        }

        // settle the bet
        if (playerHandsValue < bankerHandsValue) {
            result.banker = true;
            for (uint256 i = 0; i < _layout.length; i++) {
                // banker win, 1 : 0.95
                if (_layout[i].betType == uint256(BetType.Banker)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 195 / 100);
                }
                if (_layout[i].betType == uint256(BetType.SuperSix) && bankerHandsValue == 6) {
                    result.superSix = true;
                    if (_bankerHands.length == 3) {
                        // banker win with 3 cards, super six, 1 : 20
                        _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 21);
                    } else {
                        // banker win with 2 cards, super six, 1 : 12
                        _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 13);
                    }
                }
            }
        } else if (playerHandsValue > bankerHandsValue) {
            // player win, 1 : 1
            result.player = true;
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.Player)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 2);
                }
            }
        } else {
            // tie, 1 : 8
            result.tie = true;
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.Tie)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 9);
                }
            }
        }

        // banker pair, 1 : 11
        if (_bankerHands[0].rank == _bankerHands[1].rank) {
            result.bankerPair = true;
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.BankerPair)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 12);
                }
            }
        }

        // player pair, 1 : 11
        if (_playerHands[0].rank == _playerHands[1].rank) {
            result.playerPair = true;
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.PlayerPair)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 12);
                }
            }
        }

        delete _layout;
        emit Settle(result, _bankerHands, _playerHands);
    }

    // @notice withdraw the token from contract
    // @param _token the token address
    // @param _amount the amount of token
    function withdraw(address _token, uint256 _amount) external {
        require(_cheques[msg.sender][_token] >= _amount, "not enough credit");
        _cheques[msg.sender][_token] -= _amount;
        _safeTransfer(_token, msg.sender, _amount);
    }

    function withdrawOnlyOwner(address _token, uint256 _amount) external onlyOwner {
        _safeTransfer(_token, msg.sender, _amount);
    }

    // @notice get the point of the card
    // @param _rank the rank of the card
    function _getPoint(uint256 _rank) internal pure returns (uint256) {
        if (_rank >= 10) {
            return 0;
        } else {
            return _rank;
        }
    }

    // @dev transfer the token, or record the cheque
    function _safeTransfer(address _token, address _to, uint256 _amount) internal {
        if (_token == address(0)) {
            if (address(this).balance >= _amount) {
                payable(_to).transfer(_amount);
            } else {
                _cheques[_to][_token] += _amount;
            }
        } else {
            if (IERC20(_token).balanceOf(address(this)) >= _amount) {
                IERC20(_token).transfer(_to, _amount);
            } else {
                _cheques[_to][_token] += _amount;
            }
        }
    }

    // @dev check whether can be settle, only can be settle when have banker and player
    function _checkAction() internal view returns (bool) {
        // need both have banker and player betting
        bool banker = false;
        bool player = false;
        for (uint256 i = 0; i < _layout.length; i++) {
            if (_layout[i].betType == 0) {
                banker = true;
            } else if (_layout[i].betType == 1) {
                player = true;
            }
        }

        return banker && player;
    }

    // burn some cards after init shuffle
    function _burning() internal {
        uint256 point = _getPoint(_shoe[_cursor].rank);
        if (point <= 7) {
            _cursor += 3;
        } else {
            _cursor += 2;
        }

        emit Burning(point);
    }

    // @notice Use Knuth shuffle algorithm to shuffle the cards
    // @param _seed random seed, from business data and block data
    function shuffle(uint256 _seed) external {
        _shuffle(_seed);
    }

    function _shuffle(uint256 _nonce) internal {
        uint256 n = _shoe.length;
        for (uint256 i = _cursor; i < n; i++) {
            // Pseudo random number between i and n-1
            uint256 j = i + uint256(keccak256(abi.encodePacked(i, _nonce))) % (n - i);
            // swap i and j
            Card memory temp = _shoe[i];
            _shoe[i] = _shoe[j];
            _shoe[j] = temp;
        }
        emit Shuffle(_cursor, _nonce);
    }

    // @notice get the card from the shoe
    // @param cursor start begin
    // @param count the number of card
    function cardsOf(uint256 cursor_, uint256 count_) external view returns (Card[] memory) {
        require((cursor_ + count_) <= _shoe.length, "not enough cards");
        Card[] memory cards = new Card[](count_);
        for (uint256 i = 0; i < count_; i++) {
            cards[i] = _shoe[cursor_ + i];
        }
        return cards;
    }

    // @notice get the actions at the current layout
    function layout() external view returns (LayoutAction[] memory) {
        return _layout;
    }

    // @notice get current cursor
    function cursor() external view returns (uint256) {
        return _cursor;
    }

    // @notice get cheque balance of the user
    function chequesOf(address _player, address _token) external view returns (uint256) {
        return _cheques[_player][_token];
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
        SuperSix
    }

    struct Card {
        uint8 rank; // 1-13, 1 is Ace, 11 is Jack, 12 is Queen, 13 is King
        uint8 suit; // 1-4, 1 = spades, 2 = hearts, 3 = diamonds, 4 = clubs
    }

    struct LayoutAction {
        address player;
        address token;
        uint256 amount;
        uint256 betType;
    }

    struct ActionResult {
        bool banker;
        bool player;
        bool tie;
        bool bankerPair;
        bool playerPair;
        bool superSix;
    }

    event Action(address indexed _token, uint256 _amount, uint256 indexed _betType);
    event Settle(ActionResult result, Card[] bankerHands, Card[] playerHands);
    event Shuffle(uint256 _cursor, uint256 _nonce);
    event Burning(uint256 _amount);

    // Returns the shuffled deck of cards
    function shuffle(uint256 _nonce) external;

    // @notice player action
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair
    function action(address _token, uint256 _amount, uint256 _betType) payable external;

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