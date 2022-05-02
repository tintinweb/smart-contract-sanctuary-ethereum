// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";

contract PoolGamev1 is Ownable {

    address public p1;
    address public p2;
    uint constant WAGER = 0.00025 ether;

    enum State { CLOSED, GAME_AVAILABLE, AWAITING_BOTH, AWAITING_P1, AWAITING_P2, BETS_PLACED }
    State private state;

    constructor() {
        state = State.GAME_AVAILABLE;
    }

    function register(address _p1, address _p2) external onlyOwner returns (bool) {
        require(state == State.GAME_AVAILABLE, "Betting unavailable");
        require(_p1 != address(0), "p1 was zero");
        require(_p2 != address(0), "p2 was zero");
        require(_p1 != _p2, "p1 was same as p2");

        p1 = _p1;
        p2 = _p2;
        state = State.AWAITING_BOTH;
        return true;
    }

    function getState() external onlyOwner view returns (State) {
        return state;
    }

    function placeBet() external payable {
        require(state == State.AWAITING_BOTH || state == State.AWAITING_P1 || state == State.AWAITING_P2, "wrong state for placing bets");
        require(msg.sender == p1 || msg.sender == p2, "Better not registered");
        require(msg.sender != p1 || state != State.AWAITING_P2, "P1 has already placed a bet");
        require(msg.sender != p2 ||  state != State.AWAITING_P1, "P2 has already placed a bet");
        require(msg.value == WAGER, "Incorrect money");

        if (msg.sender == p1) {
            if (state == State.AWAITING_BOTH) {
                state = State.AWAITING_P2;
                return; 
            }
            state = State.BETS_PLACED;
            return;
        }

        // At this point, msg.sender must be p2
        if (state == State.AWAITING_BOTH) {
            state = State.AWAITING_P1;
            return;
        }
        state = State.BETS_PLACED;
    }

    function settleBet(address winner) external onlyOwner {
        require(winner == p1 || winner == p2, "winner not registers");
        require(state == State.BETS_PLACED, "State not BETS_PLACED");

        // protect from reentrancy
        state = State.GAME_AVAILABLE;
        p1 = address(0);
        p2 = address(0);

        payable(winner).transfer((9 * (2 * WAGER)) / 10);
    }

    function _refundP1() internal {
        // TODO MIGHT NEED TO GUARD
        payable(p1).transfer(WAGER);
        // TODO MIGHT NEED TO UPDATE STATE
    }

    function _refundP2() internal {
        // TODO MIGHT NEED TO GUARD
        payable(p2).transfer(WAGER);
        // TODO MIGHT NEED TO UPDATE STATE
    }

    function disableBetting(bool refund) external onlyOwner {
        require(state != State.CLOSED, "Betting already disabled");
        require(!(refund && state == State.GAME_AVAILABLE), "Nobody to refund");

        if (refund) {
            if (state == State.BETS_PLACED) {
                _refundP1();
                _refundP2();
            } else if (state == State.AWAITING_P1) {
                _refundP2();
            } else if (state == State.AWAITING_P2) {
                _refundP1();
            }
        }

        state = State.CLOSED;
    }

    function enableBetting() external onlyOwner {
        require(state == State.CLOSED, "can only open from closed state");
        state = State.GAME_AVAILABLE;
    }

    function transfer() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
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