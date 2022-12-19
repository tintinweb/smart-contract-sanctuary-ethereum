/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


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

// File: contracts/Dongjeon.sol

pragma solidity ^0.8.17;


contract Dongjeon is Ownable {
    uint public winningPercent;
    uint public feePercent;

    event Win(address winner, uint amount);
    event Lose(address loser, uint amount);
    event Deposit(address sender, uint amount);
    event Reveal(uint got, uint given);

    constructor(uint _winningPercent, uint _feePercent) public {
        require(
            (_winningPercent < 100) && (_feePercent < 100),
            "Winning/fee percent should be smaller than 100"
        );
        winningPercent = _winningPercent;
        feePercent = _feePercent;
    }

    function _transferEth(address _to, uint256 _amount) internal {
        bool callStatus;
        assembly {
            // Transfer the ETH and store if it succeeded or not.
            callStatus := call(gas(), _to, _amount, 0, 0, 0, 0)
        }
        require(callStatus, "_transferEth: Eth transfer failed");
    }

    function toss() external payable returns (bool) {
        uint expectedPayoff = (address(this).balance - msg.value) / 100 * winningPercent;
        require(
            msg.value >= expectedPayoff,
            "The amount for betting should be greater than or equal to the expected payoff"
        );

        // Make a random number
        // TODO: This is not safe! oraclize this random number generation
        uint randomNumber = uint(blockhash(block.number - 1)) % 100;
        emit Reveal(randomNumber, winningPercent);

        if (randomNumber <= winningPercent) {
            // Send a fee to the owner
            uint feeAmount = address(this).balance / 100 * feePercent;
            _transferEth(owner(), feeAmount);

            emit Win(msg.sender, address(this).balance);
            selfdestruct(payable(msg.sender));

            return true;
        } else {
            emit Lose(msg.sender, msg.value);
        }
        return false;
    }

    fallback() external payable {
        emit Deposit(msg.sender, msg.value);
    }
}