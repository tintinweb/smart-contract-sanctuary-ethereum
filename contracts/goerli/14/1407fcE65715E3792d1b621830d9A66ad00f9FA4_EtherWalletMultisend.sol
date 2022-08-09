// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EtherWalletMultisend is Ownable {
    uint256 public taxPercent;
    uint256 public lockForTime;

    struct Balance {
        uint256 amount;
        uint256 lockedUntil;
        bool transactionProcessingLock;
        bool isExists;
    }

    mapping(address => Balance) balances;
    mapping(address => mapping(address => uint256)) receivers;
    mapping(address => address[]) receiversAddresses;

    constructor(uint256 _taxPercent) {
        taxPercent = _taxPercent;
        lockForTime = 5;
    }

    modifier balanceExists() {
        require(
            balances[_msgSender()].isExists,
            "Please, create balance first!"
        );
        _;
    }

    modifier enoughCash(uint256 _amount) {
        uint256 realAmount = calculateAmountWithTax(_amount);
        require(
            balances[_msgSender()].amount >= realAmount,
            "Not enough cash!"
        );
        _;
    }

    modifier validateAmount(uint256 _amount) {
        require(_amount > 0, "Sending amount must be greater that 0");
        _;
    }

    modifier valdateAddress(address _user) {
        require(_user != address(0), "Send real address!");
        _;
    }

    modifier noReentrant() {
        require(
            !balances[_msgSender()].transactionProcessingLock,
            "There is some transaction, that locking yours"
        );
        balances[_msgSender()].transactionProcessingLock = true;
        _;
        balances[_msgSender()].transactionProcessingLock = false;
    }

    modifier notLocked() {
        require(
            balances[_msgSender()].lockedUntil < block.timestamp,
            "Balance is locked, you cannot withdraval for now"
        );
        _;
    }

    function setLockForTime(uint256 _seconds) public onlyOwner {
        lockForTime = _seconds;
    }

    function addClient(address _client)
        public
        onlyOwner
        valdateAddress(_client)
    {
        Balance memory newClientBalance = Balance({
            amount: 0,
            lockedUntil: 0,
            transactionProcessingLock: false,
            isExists: true
        });
        balances[_client] = newClientBalance;
    }

    // For deposit amount - tax returns amount which will be deposited
    function withdrawalTaxDeposit(uint256 _amount) internal returns (uint256) {
        uint256 tax;
        uint256 amount;
        unchecked {
            tax = (_amount / 100) * taxPercent;
            amount = _amount - tax;
        }
        (bool success, ) = owner().call{value: tax}("");
        require(success, "Transfer failed.");
        return amount;
    }

    function withdrawalTax(uint256 _amount) internal {
        uint256 tax;
        unchecked {
            tax = (_amount / 100) * taxPercent;
        }
        (bool success, ) = owner().call{value: tax}("");
        require(success, "Transfer failed.");
    }

    function calculateAmountWithTax(uint256 _amount)
        internal
        view
        returns (uint256)
    {
        uint256 realAmount;
        unchecked {
            realAmount = _amount + (_amount / 100) * taxPercent;
        }
        return realAmount;
    }

    function getBalance() public view balanceExists returns (uint256) {
        return balances[_msgSender()].amount;
    }

    function withdrawal(uint256 _amount)
        external
        notLocked
        noReentrant
        balanceExists
        validateAmount(_amount)
        enoughCash(_amount)
    {
        uint256 amount = calculateAmountWithTax(_amount);
        withdrawalTax(_amount);
        unchecked {
            balances[_msgSender()].amount -= amount;
        }
        payable(_msgSender()).transfer(_amount);
    }

    function deposit()
        external
        payable
        notLocked
        noReentrant
        balanceExists
        validateAmount(msg.value)
    {
        uint256 amount = withdrawalTaxDeposit(msg.value);
        unchecked {
            balances[_msgSender()].amount += amount;
            balances[_msgSender()].lockedUntil = block.timestamp + lockForTime;
        }
    }

    function transferTo(address payable _to, uint256 _amount)
        external
        notLocked
        noReentrant
        balanceExists
        validateAmount(_amount)
        enoughCash(_amount)
        valdateAddress(_to)
    {
        uint256 amount = calculateAmountWithTax(_amount);
        withdrawalTax(_amount);
        unchecked {
            balances[_msgSender()].amount -= amount;
        }
        _to.transfer(_amount);
    }

    function setReceiver(address _receiver, uint256 _amount)
        external
        valdateAddress(_receiver)
        validateAmount(_amount)
    {
        receivers[_msgSender()][_receiver] = _amount;
        receiversAddresses[_msgSender()].push(_receiver);
    }

    function getReceiver(address _receiver)
        external
        view
        valdateAddress(_receiver)
        returns (uint256)
    {
        return receivers[_msgSender()][_receiver];
    }

    function transferToMany() external notLocked noReentrant balanceExists {
        address currentReceiver;
        uint256 currentReceiverAmount;
        address[] memory _receiversAddresses = receiversAddresses[_msgSender()];

        for (uint256 i = 0; i < _receiversAddresses.length; i++) {
            currentReceiver = _receiversAddresses[i];
            currentReceiverAmount = receivers[_msgSender()][currentReceiver];
            uint256 realAmount = calculateAmountWithTax(currentReceiverAmount);

            require(
                balances[_msgSender()].amount >= realAmount,
                "Not enough cash!"
            );

            withdrawalTax(currentReceiverAmount);

            unchecked {
                balances[_msgSender()].amount -= realAmount;
            }

            payable(currentReceiver).transfer(currentReceiverAmount);
        }
    }
}

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