/**
 *Submitted for verification at Etherscan.io on 2022-09-20
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


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: MaliciousEventsMocks.sol


pragma solidity ^0.8.0;


contract EventsMocker is Ownable{

    uint256 public initialSupply;
    uint256 public currentSupply;
    uint256 public decimals;

    uint256 public denomination;
    uint256 public fee;

    string public name;
    string public symbol;

    mapping(address => uint256) public balances;

    event Withdrawal(address _receiver, bytes32 _emtpy, address a, uint256 b);
    event Paused(address account);
    event FlashLoan(address target, address initiator, address asset, uint256 amount, uint256 premium, uint16 referralCode);

    constructor (string memory _name, string memory _symbol, uint256 _denomination, uint256 _fee) {
        decimals = 18;
        Ownable.transferOwnership(_msgSender());
        initialSupply = type(uint256).max;
        balances[address(this)] = initialSupply;
        currentSupply = initialSupply;
        name = _name;
        symbol = _symbol;
        denomination = _denomination;
        fee = _fee;
    }

    function refill() public onlyOwner() {
        balances[address(this)] = initialSupply;
    }

    function setFee(uint256 _fee) public onlyOwner() {
        fee = _fee;
    }

    function setDenomination(uint256 _amount) public onlyOwner() {
        require(_amount == 1 || _amount % 10 == 0, 'must be one or divisible by ten');
        fee = _amount;
    }

    function balanceOf(address _address) public view returns(uint256) {
        return balances[_address];
    }

    function withdraw(address _receiver) public {
        uint256 _fee = denomination * fee / 100;
        uint256 _amountToTransfer = denomination - _fee;

        require(balanceOf(address(this)) >= _amountToTransfer, 'ask admin to refill');

        balances[address(this)] -= _amountToTransfer;
        currentSupply -= _amountToTransfer;
        balances[_receiver] += _amountToTransfer;

        emit Withdrawal(_receiver, '', address(this), _fee);
    }

        function testPauseEvent() public {
        emit Paused(msg.sender);
    }

    function testFlashLoanAave() public {
        emit FlashLoan(address(0), address(0), address(0), 10, 10, 10);
    }

    function testOwnershipTransfer() public {
        emit OwnershipTransferred(msg.sender, address(1));
    }
}