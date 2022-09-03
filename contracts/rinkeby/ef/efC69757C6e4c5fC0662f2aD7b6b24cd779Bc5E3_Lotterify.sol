// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "Ownable.sol";

contract Lotterify is Ownable {
    address payable[] internal players;
    uint256 public prize_amount;
    uint256 public Ticket_Price;
    uint16 public Tickets_Count;
    address payable public recent_Winner;
    uint256 public Lottery_start_date;
    address payable internal fees_address;
    enum LOTTERY_STATE {
        OPEN,
        CLOSED,
        CALCULATING_WINNER
    }
    LOTTERY_STATE public lottery_state;

    constructor() public {
        Ticket_Price = 50000000000000000;
        Tickets_Count = 5000;
        prize_amount = 0;
        lottery_state = LOTTERY_STATE.OPEN;
        Lottery_start_date = now;
        fees_address = msg.sender;
    }

    function enter() public payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= Ticket_Price, "Not enough ETH!");
        uint256 i = msg.value;
        while (i >= Ticket_Price) {
            i -= Ticket_Price;
            players.push(msg.sender);
            prize_amount += Ticket_Price;
        }
        if (players.length >= Tickets_Count) {
            bool flag = endLottery();
        } else if (now >= (Lottery_start_date + 2628000)) {
            bool flag = endLottery();
        }
    }

    event Received(address, uint256);

    receive() external payable {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(msg.value >= Ticket_Price, "Not enough ETH!");
        emit Received(msg.sender, msg.value);
        uint256 i = msg.value;
        while (i >= Ticket_Price) {
            i -= Ticket_Price;
            players.push(msg.sender);
            prize_amount += Ticket_Price;
        }
        if (players.length >= Tickets_Count) {
            bool flag = endLottery();
        } else if (now >= (Lottery_start_date + 2628000)) {
            bool flag = endLottery();
        }
    }

    function CountChances(address _subscriber_address)
        public
        view
        returns (uint8)
    {
        uint8 chances_count;
        for (uint8 i = 0; i < players.length; i++) {
            if (players[i] == _subscriber_address) {
                chances_count += 1;
            }
        }
        return (chances_count);
    }

    function SendAdministrativeFees() internal {
        fees_address.transfer(address(this).balance);
    }

    function endLottery() internal returns (bool) {
        require(lottery_state == LOTTERY_STATE.OPEN);
        require(players.length > 0);
        lottery_state = LOTTERY_STATE.CALCULATING_WINNER;
        recent_Winner = players[
            uint16(
                uint256(keccak256(abi.encodePacked(block.difficulty, now))) %
                    players.length
            )
        ];
        recent_Winner.transfer(prize_amount);
        prize_amount = 0;
        players = new address payable[](0);
        Lottery_start_date = now;
        lottery_state = LOTTERY_STATE.OPEN;
        return true;
    }

    function endLottery2() public view returns (uint16) {
        uint16 random_int;
        random_int = uint16(
            uint256(keccak256(abi.encodePacked(block.difficulty, now))) %
                Tickets_Count
        );
        return random_int;
    }

    function SetTickets_Count(uint16 _Tickets_Count) public onlyOwner {
        Tickets_Count = _Tickets_Count;
    }

    function SetFeesAddress(address payable _fees_address) public onlyOwner {
        fees_address = _fees_address;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}