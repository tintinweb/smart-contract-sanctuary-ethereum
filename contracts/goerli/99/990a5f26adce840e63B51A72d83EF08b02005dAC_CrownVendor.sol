pragma solidity 0.8.14;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @title Crown Capital Token Vendor
/// @author sters.eth
/// @notice Contract will emit Crown for USDC
contract CrownVendor is Ownable, ReentrancyGuard { 

    string public constant name = "Crown Capital Vendor";

    // @dev Token Contracts
    IERC20 public _crownToken;
    IERC20 public _usdcToken;
    
    // @dev the conversion rate of USDC to Crown
    uint256 public USDCPerCrown;

    // @dev boolean to turn whitelist requirement on and off
    bool public whitelist;

    // @dev whitelist addresses
    address[] public wlAddresses;

    // Initialize events
    event PayUSDC(address sender, uint256 amount);
    event BoughtCrown(address receiver, uint256 amount);
    event WithdrawCrown(address owner, uint256 vendorBalance);
    event WithdrawUSDC(address owner, uint256 vendorBalance);
    event WhitelistStatusUpdated(address _from, bool status);
    event AddedWlAddress(address _from, address userAddress);
    event RemovedWlAddress(address _from, address userAddress);
    event ResetWhitelist(address _from);


    constructor(IERC20 crownAddress, IERC20 usdcAddress) {
        _crownToken = crownAddress;
        _usdcToken = usdcAddress;
        USDCPerCrown = 200000;
        whitelist=false;
    }


    /**
    * @notice Set the USDC to Crown rate with 6 digit accuracy (e.g. $0.20 CROWN/USDC = 200000)
    */
    function setUSDCPerCrown(uint256 rate) external onlyOwner {
       USDCPerCrown = rate;
    }


    /** @dev set whitelist to true or false.
    */  
    function setWhitelist(bool status) external onlyOwner {
        whitelist = status;
        emit WhitelistStatusUpdated(msg.sender, status);
    }


    /** @dev Owner may add addresses to whitelist.
    * @param userAddress address of user with whitelist access.
    */  
    function addToWhitelist(address userAddress) external onlyOwner {
        require(userAddress != address(0), 'address can not be zero address');
        wlAddresses.push(userAddress);
        emit AddedWlAddress(msg.sender, userAddress);
    }


    /// @dev deletes an address from the whitelist if found in whitelist
    function removeAddressFromWl(address userAddress) external onlyOwner {
        for (
            uint256 wlIndex = 0;
            wlIndex < wlAddresses.length;
            wlIndex++
        ) {
            if(userAddress == wlAddresses[wlIndex]){
                if(wlAddresses.length == 1){
                    resetWhitelist();
                }                    
                else {
                    wlAddresses[wlIndex] = wlAddresses[wlAddresses.length - 1];
                    wlAddresses.pop(); // Remove the last element
                    emit RemovedWlAddress(msg.sender, userAddress);
                }
            }
        }
    }


  /// @dev deletes all entries from whitelist
  function resetWhitelist() public onlyOwner {
      delete wlAddresses;
      emit ResetWhitelist(msg.sender);
  }


    /**
    * @notice Allow users to buy crown for USDC by specifying the number of
    *  Crown tokens desired. 
    */
    function buyCrown(uint256 crownTokens) external nonReentrant {
        // Check that the requested amount of tokens to sell is more than 0
        require(crownTokens > 0, "Specify an amount of Crown greater than zero");

        // Check that the Vendor's balance is enough to do the swap
        uint256 vendorBalance = _crownToken.balanceOf(address(this));
        require(vendorBalance >= crownTokens, "Vendor contract does not have a suffcient Crown balance.");
        
        // Check if whitelist is active
        if(whitelist){
            bool userOnWhitelist = false;
            for (
                uint256 wlIndex = 0;
                wlIndex < wlAddresses.length;
                wlIndex++
            ) {
                if(msg.sender == wlAddresses[wlIndex]){
                    userOnWhitelist = true;
                }
            }
            require(userOnWhitelist, "User not found on whitelist");
        }

        // Calculate USDC needed
        uint256 usdcToSpend = crownToUSDC(crownTokens);

        // Check that the user's USDC balance is enough to do the swap
        address sender = msg.sender;
        uint256 userBalance = _usdcToken.balanceOf(sender);
        require(userBalance >= usdcToSpend, "You do not have enough USDC.");

        // Check that user has approved the contract
        uint256 contractAllowance = _usdcToken.allowance(sender, address(this));
        require(contractAllowance >= usdcToSpend, "Must approve this contract to spend more USDC.");

        // Transfer USDC from user to contract
        (bool recieved) = _usdcToken.transferFrom(sender, address(this), usdcToSpend);
        require(recieved, "Failed to transfer USDC from vendor to user");
        emit PayUSDC(sender, usdcToSpend);

        // Send Crown to Purchaser
        (bool sent) = _crownToken.transfer(sender, crownTokens);
        require(sent, "Failed to transfer Crown from  to vendor");
        emit BoughtCrown(sender, crownTokens);
    }


    /**
    * @notice Allow the owner of the contract to withdraw all $USDC
    */
    function withdrawUSDC() external onlyOwner {
      uint256 vendorBalance = _usdcToken.balanceOf(address(this));
      require(vendorBalance > 0, "Nothing to Withdraw");
      (bool sent) = _usdcToken.transfer(msg.sender, vendorBalance);
      require(sent, "Failed to transfer tokens from user to Farm");

      emit WithdrawUSDC(msg.sender, vendorBalance);
    }


    /**
    * @notice Allow the owner of the contract to withdraw all $CROWN
    */
    function withdrawCrown() external onlyOwner {
      uint256 vendorBalance = _crownToken.balanceOf(address(this));
      require(vendorBalance > 0, "Nothing to Withdraw");
      (bool sent) = _crownToken.transfer(msg.sender, vendorBalance);
      require(sent, "Failed to transfer tokens from user to Farm");

      emit WithdrawCrown(msg.sender, vendorBalance);
    }


    /**
    * @notice Helper function: Convert Crown tokens to USDC 
    */
    function crownToUSDC(uint256 crownTokens) public view returns (uint256 usdc) {
      usdc = (crownTokens * USDCPerCrown)/10**18;
      return usdc;
    }


    /**
    * @notice Helper function: Convert USDC tokens to Crown
    */
    function usdcToCrown(uint256 USDC) external view returns (uint256 crownTokens) {
      crownTokens = (USDC / USDCPerCrown) * 10**18;
      return crownTokens;
    }
}

// SPDX-License-Identifier: MIT

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

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