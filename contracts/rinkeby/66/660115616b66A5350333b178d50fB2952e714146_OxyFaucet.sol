/**
 *Submitted for verification at polygonscan.com on 2022-08-11
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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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

// File: contracts/0xyFaucet.sol

//  ██████╗ ██╗  ██╗██╗   ██╗████████╗ ██████╗  ██████╗██╗███╗   ██╗      ███████╗ █████╗ ██╗   ██╗ ██████╗███████╗████████╗
// ██╔═████╗╚██╗██╔╝╚██╗ ██╔╝╚══██╔══╝██╔═══██╗██╔════╝██║████╗  ██║      ██╔════╝██╔══██╗██║   ██║██╔════╝██╔════╝╚══██╔══╝
// ██║██╔██║ ╚███╔╝  ╚████╔╝    ██║   ██║   ██║██║     ██║██╔██╗ ██║█████╗█████╗  ███████║██║   ██║██║     █████╗     ██║
// ████╔╝██║ ██╔██╗   ╚██╔╝     ██║   ██║   ██║██║     ██║██║╚██╗██║╚════╝██╔══╝  ██╔══██║██║   ██║██║     ██╔══╝     ██║
// ╚██████╔╝██╔╝ ██╗   ██║      ██║   ╚██████╔╝╚██████╗██║██║ ╚████║      ██║     ██║  ██║╚██████╔╝╚██████╗███████╗   ██║
//  ╚═════╝ ╚═╝  ╚═╝   ╚═╝      ╚═╝    ╚═════╝  ╚═════╝╚═╝╚═╝  ╚═══╝      ╚═╝     ╚═╝  ╚═╝ ╚═════╝  ╚═════╝╚══════╝   ╚═╝

//   __      __   _     _    ____
//   \ \    / /  (_)   | |  / __ \
//    \ \  / /__  _  __| | | |  | |_ __
//     \ \/ / _ \| |/ _` | | |  | | '_ \
//      \  / (_) | | (_| | | |__| | |_) |
//       \/ \___/|_|\__,_|  \____/| .__/
//                                | |
//                                |_|

pragma solidity ^0.8.7;



contract OxyFaucet is Ownable, Pausable {
    uint256 public releaseAmount = 1 ether;
    uint256 public intervalTime = 1 days;
    uint256 public balanceLimit = 1 ether;
    mapping(address => uint256) public lastClaim;
    mapping(address => bool) public whiteListWallets;

    event Received(address, uint256);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getTokens() external whenNotPaused {
        require(whiteListWallets[msg.sender], "Wallet Not Whitelisted");
        require(
            lastClaim[msg.sender] == 0 ||
            lastClaim[msg.sender] + intervalTime < block.timestamp,
            "Need to wait"
        );
        require(
            msg.sender.balance < balanceLimit,
            "Already Have Enough in wallet!"
        );
        lastClaim[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(releaseAmount);
    }

    function setReleaseAmount(uint256 amountInWei) external onlyOwner {
        releaseAmount = amountInWei;
    }

    function setIntervalTime(uint256 time) external onlyOwner {
        intervalTime = time;
    }

    function addWhiteListAddress(address[] memory wallets) external onlyOwner {
        for(uint i=0; i<wallets.length; i++){
            whiteListWallets[wallets[i]] = true;
        }
    }

    function removeWhiteListAddress(address[] memory wallets) external onlyOwner {
        for(uint i=0; i<wallets.length; i++){
            whiteListWallets[wallets[i]] = false;
        }
    }

    function setBalanceLimit(uint256 amount) external onlyOwner {
        balanceLimit = amount * 1 wei;
    }

    function withdraw() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function togglePause() external onlyOwner {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }
}