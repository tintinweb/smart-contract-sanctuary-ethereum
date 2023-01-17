// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
pragma solidity ^0.8.13;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract XOGame is Ownable {
    Cell public nextTurn;
    Cell public winner;
    uint16 public nonce;
    uint64 public lastMoveTimestamp;

    address public immutable partyX;
    address public immutable partyO;

    enum Cell {
        Empty,
        X,
        O
    }

    Cell[256][256] public field;

    event Move(uint8 x, uint8 y, Cell cell);
    event Victory(address player, Cell cell);
    event PrizeContribution(address sponsor, uint256 amount);

    constructor(address _partyX, address _partyO) payable {
        partyX = _partyX;
        partyO = _partyO;
    }

    function play(uint8 x, uint8 y, uint256 _nonce) public {
        require(msg.sender == partyX || msg.sender == partyO, "Not a player");
        require(winner == Cell.Empty, "Game is over");
        require(nonce == _nonce, "Invalid nonce");
        Cell cell = msg.sender == partyX ? Cell.X : Cell.O;

        require(cell == nextTurn || nextTurn == Cell.Empty, "Not your turn");
        require(field[x][y] == Cell.Empty, "Cell is not empty");

        field[x][y] = cell;
        nextTurn = cell == Cell.X ? Cell.O : Cell.X;
        lastMoveTimestamp = uint64(block.timestamp);
        nonce = nonce + 1;

        emit Move(x, y, cell);
    }

    function win(uint8 x, uint8 y, int8 dx, int8 dy) public {
        require(dx == -1 || dx == 0 || dx == 1, "dx must be -1, 0 or 1");
        require(dy == -1 || dy == 0 || dy == 1, "dy must be -1, 0 or 1");
        require(dx != 0 || dy != 0, "dx and dy cannot be both 0");
        require(winner == Cell.Empty, "Game is over");

        Cell cell = field[x][y];
        require(cell != Cell.Empty, "Cell is empty");

        for (uint256 i = 0; i < 5; i++) {
            require(field[x][y] == cell, "Not a line");
            x = inc(x, dx);
            y = inc(y, dy);
        }

        declareWinner(cell == Cell.X ? partyX : partyO);
    }

    function playAndWin(uint8 x, uint8 y, uint256 _nonce, uint8 startX, uint8 startY, int8 dx, int8 dy) public {
        play(x, y, _nonce);
        win(startX, startY, dx, dy);
    }

    function timedOut() external {
        require(winner == Cell.Empty, "Already won");
        require(nextTurn != Cell.Empty, "Not started");
        require(block.timestamp - lastMoveTimestamp > 3 days, "Too soon");

        declareWinner(nextTurn == Cell.X ? partyO : partyX);
    }

    function declareWinner(address party) internal {
        safeSend(party, address(this).balance);
        winner = party == partyX ? Cell.X : Cell.O;

        emit Victory(party, winner);
    }

    function emergencyStop() external onlyOwner {
        uint256 balance = address(this).balance;
        if (balance > 0) {
            safeSend(partyX, balance / 2);
            safeSend(partyO, balance / 2);
        }
    }

    function safeSend(address to, uint256 amount) internal {
        bool success = payable(to).send(amount);
        if (!success) {
            WETH weth = WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
            weth.deposit{value: amount}();
            require(weth.transfer(to, amount), "Payment failed");
        }
    }

    function inc(uint8 v, int8 d) internal pure returns (uint8) {
        if (d == 0) {
            return v;
        }

        int256 r = int256(uint256(v)) + int256(d);
        require(r >= 0 && r < 256, "Out of bounds");
        return uint8(uint256(r));
    }

    receive() external payable {
        // Prevent contributions after the game is over
        require(winner == Cell.Empty, "Game is over");
        emit PrizeContribution(msg.sender, msg.value);
    }
}

interface WETH {
    function deposit() external payable;
    function transfer(address dst, uint256 wad) external returns (bool);
}