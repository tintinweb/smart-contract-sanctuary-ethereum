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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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

// SPDX-License-Identifier: GPL-3.0


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
/** 
 * @title Central Vault
 * @dev Users can deposit Central Tokens in 5 different slabs 
 */

pragma solidity 0.8.17;


contract CentralVault is Ownable {
 
     //Events to deposit and withdraw tokens
     event DepositTokens(address user, uint256 amount);
     event WithdrawTokens(address user, uint256 amount, uint256 vaultTokens);

     IERC20 public centralTokenAddress;

      /**
     * @notice Construct a new Vault with token address and define capacity slab
     * @param _centralTokenAddress The Central token address
     */
    constructor(IERC20 _centralTokenAddress) {
        centralTokenAddress = _centralTokenAddress;
        initSlabCapacities();

    }
    
    /// @notice For denoting the different slabs
    enum slabStatus{
        SLAB0,
        SLAB1,
        SLAB2,
        SLAB3,
        SLAB4
    }

 
    /// @notice For monitoring the capacity in each slabs
    struct Slab{
        slabStatus capacitySlab;
        uint256 slabAmount;
    }

    struct userDetails{
        address user;
        slabStatus slabType;
    }

       /// @notice For mapping user address to amount of Central tokens deposited in this vault
    mapping (address => mapping (IERC20 => uint256)) userTokenBalance;


    /// @notice For determining which slab user belongs to
    mapping (address => userDetails) userSlab;


    Slab[5] public slabs;

    function initSlabCapacities() internal{
        slabs[0].slabAmount = 100;
        slabs[1].slabAmount = 200;
        slabs[2].slabAmount = 300;
        slabs[3].slabAmount = 400;
        slabs[4].slabAmount = 500;
    }

    function setSlabCapacities(uint256[5] memory _capacities) external onlyOwner{
        slabs[0].slabAmount = _capacities[0];
        slabs[1].slabAmount = _capacities[1];
        slabs[2].slabAmount = _capacities[2];
        slabs[3].slabAmount = _capacities[3];
        slabs[4].slabAmount = _capacities[4];
    }


     /**
     * @notice Called by the user for depositing Central tokens which also checks the capacity slab levels
     * @param  amount The amount of central tokens to deposit
     */
    function DepositCentralTokens( uint256 amount) public {
        require(IERC20(centralTokenAddress).balanceOf(msg.sender) >= amount, "Your token balance must be greater than the amount you are trying to deposit");
        require(IERC20(centralTokenAddress).approve(address(this), amount));
        IERC20(centralTokenAddress).transferFrom(msg.sender, address(this), amount);

        userTokenBalance[msg.sender][centralTokenAddress] += amount;
        if((userTokenBalance[msg.sender][centralTokenAddress])<=500){
            userSlab[msg.sender].slabType = slabStatus.SLAB4;
        }
        if((userTokenBalance[msg.sender][centralTokenAddress])<=900){
            userSlab[msg.sender].slabType = slabStatus.SLAB3;
        }
        if((userTokenBalance[msg.sender][centralTokenAddress])<=1200){
            userSlab[msg.sender].slabType = slabStatus.SLAB2;
        }
        if((userTokenBalance[msg.sender][centralTokenAddress])<=1400){
            userSlab[msg.sender].slabType = slabStatus.SLAB1;
        }
        if((userTokenBalance[msg.sender][centralTokenAddress])<=1500){
            userSlab[msg.sender].slabType = slabStatus.SLAB0;
        }
        emit DepositTokens(msg.sender, amount);
    }

    function checkVaultCapacity() public view returns (uint256){
        return address(this).balance;

    }

    function checkUserSlab() public view returns (userDetails memory){
        return userSlab[msg.sender];

    }

}