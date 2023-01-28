//SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IBaccarat.sol";

contract Baccarat is IBaccarat, Ownable {
    // @notice use 1...52 as card id to represent one suit of cards
    // if x % 13 == 1, x represents A
    // ...
    // if x % 13 == 0, x represents K
    // if x % 4 == 0, x represents spade
    // if x % 4 == 1, x represents heart
    // if x % 4 == 2, x represents club
    // if x % 4 == 3, x represents diamond
    uint8[] private _shoe;

    // @notice cursor is an important flag in shoe, it represents the index of next card to distribute
    // if index of shoe < cursor, this card will not be changed any more
    // if index of shoe >= cursor, this card will be changed when shuffle
    uint256 private _cursor;

    // @notice it only saves the current betting layout, it will be cleared when settle
    LayoutAction[] private _layout;

    // @notice player address => token address => amount
    mapping(address => mapping(address => uint256)) private _cheques;

    // @notice it saves the result of each settle, when cursor = 0, it will be cleared
    SettleResult[] private _settleResults;

    constructor() {
        for (uint256 i = 0; i < 8; i++) {
            for (uint8 j = 1; j <= 52; j++) {
                _shoe.push(j);
            }
        }
    }

    // @notice player action
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair, 5 = banker super six, 6 = player super six
    function action(address _token, uint256 _amount, uint256 _betType) payable external {
        require(_cursor > 0, "Baccarat: game not started, need to shuffle first");

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

        emit Action(msg.sender, _token, _amount, _betType);
    }

    // @notice play the game and settle the bet
    // @param nonce random number, anyone can call this function
    function settle(uint256 nonce) external {
        require(_checkAction(), "Baccarat: need both bet banker and player");

        SettleResult memory result;
        result.cursor = uint16(_cursor);

        nonce = uint256(keccak256(abi.encodePacked(
                block.timestamp,
                block.difficulty,
                _cursor,
                nonce
            )));
        // if shoe is less than 6 cards, can not play
        if (_shoe.length - _cursor < 6) {
            // set cursor to 0
            _cursor = 0;
            // delete _settleResults;
            delete _settleResults;
        }
        // shuffle shoe
        _shuffle(nonce);

        // player hands
        result.playerHands1 = _shoe[_cursor];
        result.bankerHands1 = _shoe[_cursor + 1];
        result.playerHands2 = _shoe[_cursor + 2];
        result.bankerHands2 = _shoe[_cursor + 3];
        _cursor += 4;

        // calculate hands value
        result.bankerPoints = (_getPoint(result.bankerHands1) + _getPoint(result.bankerHands2)) % 10;
        result.playerPoints = (_getPoint(result.playerHands1) + _getPoint(result.playerHands2)) % 10;

        // if not Natural
        if (result.playerPoints < 8 && result.bankerPoints < 8) {
            // if player hands value is less than 6, draw a third card
            if (result.playerPoints < 6) {
                result.playerHands3 = _shoe[_cursor];
                result.playerPoints = (result.playerPoints + _getPoint(result.playerHands3)) % 10;
                _cursor += 1;
            }

            // if player no need draw a third card, banker < 6, banker need draw a third card
            if (result.playerHands3 == 0 && result.bankerPoints < 6) {
                result.bankerHands3 = _shoe[_cursor];
                result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                _cursor += 1;
            }

            if (result.playerHands3 > 0) {
                if (result.bankerPoints <= 2) {
                    result.bankerHands3 = _shoe[_cursor];
                    result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                    _cursor += 1;
                } else if (result.bankerPoints == 3 && _getPoint(result.playerHands3) != 8) {
                    result.bankerHands3 = _shoe[_cursor];
                    result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                    _cursor += 1;
                } else if (result.bankerPoints == 4 && _getPoint(result.playerHands3) >= 2 && _getPoint(result.playerHands3) <= 7) {
                    result.bankerHands3 = _shoe[_cursor];
                    result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                    _cursor += 1;
                } else if (result.bankerPoints == 5 && _getPoint(result.playerHands3) >= 4 && _getPoint(result.playerHands3) <= 7) {
                    result.bankerHands3 = _shoe[_cursor];
                    result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                    _cursor += 1;
                } else if (result.bankerPoints == 6 && _getPoint(result.playerHands3) >= 6 && _getPoint(result.playerHands3) <= 7) {
                    result.bankerHands3 = _shoe[_cursor];
                    result.bankerPoints = (result.bankerPoints + _getPoint(result.bankerHands3)) % 10;
                    _cursor += 1;
                }
            }
        }

        // settle the bet
        if (result.playerPoints < result.bankerPoints) {
            for (uint256 i = 0; i < _layout.length; i++) {
                // banker win, 1 : 0.95
                if (_layout[i].betType == uint256(BetType.Banker)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 195 / 100);
                }
                if (_layout[i].betType == uint256(BetType.SuperSix) && result.bankerPoints == 6) {
                    if (result.bankerHands3 > 0) {
                        // banker win with 3 cards, super six, 1 : 20
                        _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 21);
                    } else {
                        // banker win with 2 cards, super six, 1 : 12
                        _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 13);
                    }
                }
            }
        } else if (result.playerPoints > result.bankerPoints) {
            // player win, 1 : 1
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.Player)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 2);
                }
            }
        } else {
            // tie, 1 : 8
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.Tie)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 9);
                }
            }
        }

        // banker pair, 1 : 11
        if (result.bankerHands1 % 13 == result.bankerHands2 % 13) {
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.BankerPair)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 12);
                }
            }
        }

        // player pair, 1 : 11
        if (result.playerHands1 % 13 == result.playerHands2 % 13) {
            for (uint256 i = 0; i < _layout.length; i++) {
                if (_layout[i].betType == uint256(BetType.PlayerPair)) {
                    _safeTransfer(_layout[i].token, _layout[i].player, _layout[i].amount * 12);
                }
            }
        }

        // save the result
        _settleResults.push(result);

        // clear the layout
        delete _layout;

        emit Settle(result);
    }

    // @notice withdraw the token from contract
    // @param _token the token address
    // @param _amount the amount of token
    function withdraw(address _token, uint256 _amount) external {
        require(_cheques[msg.sender][_token] >= _amount, "not enough credit");
        _cheques[msg.sender][_token] -= _amount;
        _safeTransfer(_token, msg.sender, _amount);
    }

    // @notice withdraw the token from contract, only owner can call this function
    // @param _token the token address
    // @param _amount the amount of token
    function withdrawOnlyOwner(address _token, uint256 _amount) external onlyOwner {
        _safeTransfer(_token, msg.sender, _amount);
    }

    // @notice get the point of the card
    // @param _rank the rank of the card
    function _getPoint(uint8 cardId) internal pure returns (uint8) {
        uint8 rank = cardId % 13;
        // 10, J, Q, K
        if (rank == 0 || rank >= 10) {
            return 0;
        }
        return rank;
    }

    // @notice transfer the token, or record the cheque
    // if the token is address 0, it means the token is ETH
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

    // @notice check whether can be settle, only can be settle when have banker and player
    // @return true if can be settle
    function _checkAction() internal view returns (bool) {
        // need both have banker and player betting
        bool banker = false;
        bool player = false;
        for (uint256 i = 0; i < _layout.length; i++) {
            if (_layout[i].betType == uint256(BetType.Banker)) {
                banker = true;
            } else if (_layout[i].betType == uint256(BetType.Player)) {
                player = true;
            }
        }

        return banker && player;
    }

    // @notice burn some cards after init shuffle
    function _burning() internal {
        uint8 point = _getPoint(_shoe[_cursor]);
        if (point <= 7) {
            _cursor += 3;
        } else {
            _cursor += 2;
        }

        emit Burning(point);
    }

    function shuffle(uint256 _nonce) external {
        _shuffle(_nonce);
    }

    // @notice Use Knuth shuffle algorithm to shuffle the cards
    // @param _nonce random number, from business data and block data
    function _shuffle(uint256 _nonce) internal {
        uint256 n = _shoe.length;
        for (uint256 i = uint256(_cursor); i < n; i++) {
            _nonce = uint256(keccak256(abi.encodePacked(
                    block.timestamp,
                    block.difficulty,
                    i,
                    _nonce
                )));
            // Pseudo random number between i and n-1
            uint256 j = i + _nonce % (n - i);
            // swap i and j
            uint8 temp = _shoe[i];
            _shoe[i] = _shoe[j];
            _shoe[j] = temp;
        }
        emit Shuffle(_nonce);
        // when cursor is 0, need to burn some cards
        if (_cursor == 0) {
            _burning();
        }
    }

    // @notice get the card from the shoe
    // @param cursor start begin
    // @param count the number of card
    // @return the cards
    function cardsOf(uint256 from_, uint256 count_) external view returns (uint8[] memory) {
        require((from_ + count_) <= _shoe.length, "not enough cards");
        uint8[] memory cards = new uint8[](count_);
        for (uint256 i = 0; i < count_; i++) {
            cards[i] = _shoe[from_ + i];
        }
        return cards;
    }

    // @notice get the actions at the current layout
    // @return the actions
    function layout() external view returns (LayoutAction[] memory) {
        return _layout;
    }

    // @notice get current cursor of shoe
    // @return the cursor
    function cursor() external view returns (uint256) {
        return _cursor;
    }

    // @notice get cheque balance of the user
    // @param _player the player address
    // @param _token the token address
    // @return the cheque balance
    function chequesOf(address _player, address _token) external view returns (uint256) {
        return _cheques[_player][_token];
    }

    // @notice get the settle results
    // @param from_ start index, from 0
    // @param count_ the number of settle results
    // @return the settle results
    function settleResultsOf(uint256 from_, uint256 count_) external view returns (SettleResult[] memory) {
        require((from_ + count_) <= _settleResults.length, "not enough settle results");
        SettleResult[] memory results = new SettleResult[](count_);
        for (uint256 i = 0; i < count_; i++) {
            results[i] = _settleResults[from_ + i];
        }

        return results;
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

    struct LayoutAction {
        address player;
        address token;
        uint256 amount;
        uint256 betType;
    }

    struct SettleResult {
        uint16 cursor;      // 0 ..< 416
        uint8 bankerPoints; // 0 ..< 10
        uint8 playerPoints; // 0 ..< 10
        uint8 bankerHands1; // 1 ... 52, 0 = no card
        uint8 bankerHands2; // 1 ... 52, 0 = no card
        uint8 bankerHands3; // 1 ... 52, 0 = no card
        uint8 playerHands1; // 1 ... 52, 0 = no card
        uint8 playerHands2; // 1 ... 52, 0 = no card
        uint8 playerHands3; // 1 ... 52, 0 = no card
    }

    event Action(address indexed _player, address indexed _token, uint256 _amount, uint256 _betType);
    event Settle(SettleResult result);
    event Shuffle(uint256 _nonce);
    event Burning(uint256 _amount);

    // Returns the shuffled deck of cards
    function shuffle(uint256 _nonce) external;

    // @notice player action
    // @param _token betting token address
    // @param _amount betting amount
    // @param _betType betting type, 0 = banker, 1 = player, 2 = tie, 3 = banker pair, 4 = player pair
    function action(address _token, uint256 _amount, uint256 _betType) payable external;

    // @notice play the game and settle the bet
    function settle(uint256 _nonce) external;
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