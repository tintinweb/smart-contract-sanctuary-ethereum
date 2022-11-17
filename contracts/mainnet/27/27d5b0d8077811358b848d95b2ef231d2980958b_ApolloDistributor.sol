/**
 *Submitted for verification at Etherscan.io on 2022-11-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
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
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);
}

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract ApolloDistributor is Ownable {
    struct DistributeTo {
        address addr;
        uint256 percentage;
    }
    mapping(uint256 => DistributeTo) private distributeTo_;
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    
    function distributeTo(uint256 index)
        external
        view
        returns (DistributeTo memory)
    {
        return distributeTo_[index];
    }

    uint256 public distributeToCount;

    function addArrayToMapping(DistributeTo[] memory array) private {
        distributeToCount = array.length;
        for (uint256 i; i < array.length; i++) {
            distributeTo_[i] = array[i];
        }
    }

    function setDistributeTo(DistributeTo[] calldata toDistributeTo)
        external
        onlyOwner
    {
        if (distributeToCount != 0) distributeUSDC();
        uint256 totalPercentage;
        for (uint256 i; i < toDistributeTo.length; i++) {
            totalPercentage += toDistributeTo[i].percentage;
        }
        require(totalPercentage == 100, "Total percentage must equal to 100");

        addArrayToMapping(toDistributeTo);
    }

    function distributeUSDC() public {
        require(distributeToCount != 0, "Must have distribution set");
        uint256 totalBalance = USDC.balanceOf(address(this));
        if (totalBalance == 0) return;
        
        for (uint256 i; i < distributeToCount; i++) {
            address to = distributeTo_[i].addr;
            uint256 amount = totalBalance * distributeTo_[i].percentage / 100;
            USDC.transfer(to, amount);
        }
    }

    function retrieveToken(IERC20 _token) external onlyOwner {
        require(USDC != _token);
        uint256 contractBalance = _token.balanceOf(address(this));
        _token.transfer(owner(), contractBalance);
    }

}