// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.18;

import './sources/Ownable.sol';

interface IWETH {
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address dst, uint wad) external returns (bool);
}

contract Bridge is Ownable {

    IWETH public weth;

    struct Process {
        address sender;
        address receiver;
        uint chainID;
        address token;
        uint amount;
    }

    mapping (uint => bool) public canBridge;
    mapping (uint => Process) public processes;
    mapping (address => uint) public staked;

    uint public currentChain;
    uint public lastProcess;

    constructor(address _wethAddress, uint _chainID) {
        weth = IWETH(_wethAddress);
        currentChain = _chainID;
    }

    // Users can stake WETH on the bridge farm through this function
    function stake(uint _amount) public {
        weth.transferFrom(msg.sender, address(this), _amount);

        staked[msg.sender] += _amount;
    }

    // Users can unstake WETH from the bridge farm through this function
    function unstake(uint _amount) public {
        require(staked[msg.sender] >= _amount, "Too much");
        // MAKE THIS WORK
        // require(weth.balanceOf(address(this)) >= _amount, "Insufficient funds");

        weth.transfer(msg.sender, _amount);

        staked[msg.sender] -= _amount;
    }

    // Users can call this function to bridge tokens
    function bridgeIn(address _receiver, uint _amount, address _token, uint _chainOut) public {
        processes[lastProcess].sender = msg.sender;
        processes[lastProcess].receiver = _receiver;
        processes[lastProcess].chainID = _chainOut;
        processes[lastProcess].token = _token;
        processes[lastProcess].amount = _amount;

        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        lastProcess += 1;
    }

    // Owner can call this function to send bridged tokens
    function bridgeOut(uint processID, uint _chainIn, address _receiver, uint _amount, address _token) public onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Not enough tokens in contract");

        IERC20(_token).transfer(_receiver, _amount);
    }

    // Owner can call this function to refund bridged tokens
    function refund(uint _processID) public onlyOwner {
        Process memory proc = processes[_processID];
        require(IERC20(proc.token).balanceOf(address(this)) >= proc.amount, "Not enough tokens in contract");

        IERC20(proc.token).transfer(proc.receiver, proc.amount);
    }

    // Owner can call this function to enable a chain
    function enableBridge(uint _chainID) public onlyOwner {
        canBridge[_chainID] = true;
    }

    // Owner can call this function to disable a chain
    function disableBridge(uint _chainID) public onlyOwner {
        canBridge[_chainID] = false;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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