/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: MIT

/// @title Token Distribution
/// @author André Costa @ DigitsBrands

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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

contract TokenDistribution is Ownable {

    /// Wallet that receives a majority of funds
    address public primaryWallet;
    /// Wallet that takes a fee of funds
    address public feeWallet;

    /// Fee that is distributed to feeWallet
    /// Calculated with /1000 to allow one decimal
    uint256 public fee;

    /// The ERC20 token that will be distributed
    address public tokenContractAddress;

    // controls if the round is open or closed
    enum RoundState {
        OFF,
        ON
    }
    RoundState public roundState = RoundState.OFF;

    constructor() {

    }

    //
    // MODIFIERS
    //

    /**
     * Ensure current state is correct for this method.
     */
    modifier isRoundState(RoundState roundState_) {
        require(roundState == roundState_, "Invalid state");
        _;
    }

    //
    // SETTERS
    //

    /**
     * Set new primary wallet address
     * @param newAddress The new address for the primary wallet
     */
    function setPrimaryWallet(address newAddress) external onlyOwner isRoundState(RoundState.OFF) {
        require(newAddress != address(0), "Cannot be the 0 address!");
        primaryWallet = newAddress;

    }

    /**
     * Set new fee wallet address
     * @param newAddress The new address for the fee wallet
     */
    function setFeeWallet(address newAddress) external onlyOwner isRoundState(RoundState.OFF) {
        require(newAddress != address(0), "Cannot be the 0 address!");
        feeWallet = newAddress;

    }

    /**
     * Set new token contract addresss
     * @param newAddress The new address for the fee wallet
     */
    function setTokenContractAddress(address newAddress) external onlyOwner isRoundState(RoundState.OFF) {
        require(newAddress != address(0), "Cannot be the 0 address!");
        tokenContractAddress = newAddress;

    }

    /**
     * Set new fee  
     * @param newFee The new fee
     */
    function setFee(uint256 newFee) external onlyOwner isRoundState(RoundState.OFF) {
        require(newFee < 1000, "Invalid Fee Percentage!");
        fee = newFee;
    }

    //
    // GETTERS
    //

    /**
     * Retrieve the balance in the specific token of round
     */
    function getBalance() public view returns(uint256) {
      return IERC20(tokenContractAddress).balanceOf(address(this));
    }

    //
    // ROUND FUNCTIONS
    //
 
    /**
     * Allows owner to open the round
     */
    function openRound() public onlyOwner isRoundState(RoundState.OFF) {
        require(primaryWallet != address(0), "Primary Wallet is not set!");
        require(feeWallet != address(0), "Fee Wallet is not set!");
        require(tokenContractAddress != address(0), "Token Contract Address is not set!");
        require(fee != 0, "Fee is not set!");

        roundState = RoundState.ON;
    }

    /**
     * Allows owner to close the round
     */
    function closeRound() public onlyOwner isRoundState(RoundState.ON) {
        uint256 contractBalance = getBalance();
        if (contractBalance > 0) {
            _withdraw(feeWallet, (contractBalance * fee) / 1000); 
            _withdraw(primaryWallet, getBalance()); //To avoid dust ERC20
        }
        roundState = RoundState.OFF;
    }

    

    //send the percentage of funds to a shareholder´s wallet
    function _withdraw(address account, uint256 amount) internal {
        IERC20(tokenContractAddress).transferFrom(address(this), account, amount);
    }

}