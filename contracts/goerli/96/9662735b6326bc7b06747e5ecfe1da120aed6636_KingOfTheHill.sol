/**
 *Submitted for verification at Etherscan.io on 2022-11-27
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

// File: test.sol


pragma solidity ^0.8.17;



contract KingOfTheHill is Ownable {
    mapping (address => uint) public winnerToPrize;

    address public highestCallerAddress;
    uint public highestDeposit;
    uint public timeStampLastDeposit = block.timestamp;
    uint public roundTime = 120 seconds;
    uint public prizePool;
    uint public comissionRateToWithdraw = 0.001 ether;

    event NewDeposit(address from, uint value);
    event NewRound(uint roundTime);
    event NewWinner(address _address, uint _prize);
    event WithdrawPrize(address _address, uint _prize);
    event SetNewRoundTime (uint roundTime);
    event NewComissionRateToWithdraw(uint comissionRateToWithdraw);

    function deposit() external payable {
        require(block.timestamp - timeStampLastDeposit < roundTime, "It's time to refresh");
        require(highestCallerAddress != msg.sender, 'You are the highest');
        require(msg.value > highestDeposit, 'Deposit must be greater than highest deposit');
        timeStampLastDeposit = block.timestamp;
        highestCallerAddress = msg.sender;
        highestDeposit = msg.value;
        prizePool += msg.value;

        emit NewDeposit(msg.sender, msg.value);
    }

    function checkRound() public {
        require(block.timestamp - timeStampLastDeposit >= roundTime, "Don't need to refresh");
        refreshRound();
    }

    function refreshRound() private {
        emit NewWinner(highestCallerAddress, prizePool);

        winnerToPrize[highestCallerAddress] += prizePool;
        prizePool = 0;
        timeStampLastDeposit = block.timestamp;
        highestDeposit = 0;
        highestCallerAddress = address(this);

        emit NewRound(roundTime);
    }

    function withdrawPrize() payable external {
        require(winnerToPrize[msg.sender] > 0);
        require(msg.value == comissionRateToWithdraw);

        payable(msg.sender).transfer(winnerToPrize[msg.sender]);
        emit WithdrawPrize(msg.sender, winnerToPrize[msg.sender]);
        delete winnerToPrize[msg.sender];
    }

    function setRoundTime(uint _roundTime) public onlyOwner {
        require(roundTime != _roundTime);
        roundTime = _roundTime;

        emit SetNewRoundTime(roundTime);
    }

    function setComissionRateToWithdraw(uint _comissionRateToWithdraw) public onlyOwner {
        require(comissionRateToWithdraw != _comissionRateToWithdraw);
        comissionRateToWithdraw = _comissionRateToWithdraw;

        emit NewComissionRateToWithdraw(comissionRateToWithdraw);
    }
}