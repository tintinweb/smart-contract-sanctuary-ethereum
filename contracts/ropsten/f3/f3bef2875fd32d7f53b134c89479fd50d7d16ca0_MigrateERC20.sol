/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

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

contract Router {
  function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts) {}
}

contract MigrateERC20 is Ownable{    
    
    Router router; 
    IERC20 token_old;
    IERC20 token_new;            
    address[] tokenPath;

    uint256 public balanceIn;
    uint256 public balanceOut;
    uint256 public exchangeRatio;    
        
    uint8 public migrationStage;

    /**
    * @dev Constructor defines old, new, exchange ratio and the path to swap tokens on advanced migration stage.
    * @param _token_old ERC20 token thats is no longer used. 
    * @param _token_new ERC20 token that will be used from now.
    * @param _exchangeRatio Qty of new tokens to be given per 1 old token received.     
    **/ 
    constructor(address _token_old, address _token_new, uint256 _exchangeRatio, address _router){
        token_old = IERC20(_token_old);
        token_new = IERC20(_token_new);   

        exchangeRatio = _exchangeRatio;        
        
        tokenPath = new address[](2);
            tokenPath[0] = address(token_old);
            tokenPath[1] = address(token_new);

        router = Router(_router);
    }

    /**
    * @dev Set tokens involved in the migration processed. 
    * @param _token_old ERC20 token thats is no longer used.
    * @param _token_new ERC20 token that will be used from now.
    */
    function setTokens(address _token_old, address _token_new) external onlyOwner {
        token_old = IERC20(_token_old);
        token_new = IERC20(_token_new);         
        
        tokenPath = new address[](2);
            tokenPath[0] = address(token_old);
            tokenPath[1] = address(token_new);
    }    

    /**
    * @dev Set exchange ratio.
    * @param _exchangeRatio Qty of new tokens to be given per 1 old token received.
    *   Note: as Solidity don't accept decimal numbers 100 = 1 token, 50 = 0.5 token, 1000 = 10 tokens. 
    */
    function setExchangeRatio(uint256 _exchangeRatio) external onlyOwner{
        exchangeRatio = _exchangeRatio;
    }

    /**
    * @dev Set the migration stage to decide what path the smart contract should follow.
    * @param _migrationStage 0: Disabled, 1: Simple, 2: Exchange on Uniswap.
    */
    function setMigrationStage(uint8 _migrationStage) external onlyOwner {
        require(_migrationStage == 0 || _migrationStage == 1 || _migrationStage == 2, "Invalid migration stage");
        migrationStage = _migrationStage;
    }

    /**
    * @dev Get the address of the old token.
    */
    function getTokenOld() public view returns (address) {
        return address(token_old);
    }

    /**
    * @dev Get the address of the new token.
    */
    function getTokenNew() public view returns (address) {
        return address(token_new);
    }

    /**
    * @dev Start the migration process.
    * @param _amount amount of olds tokens to be exchanged for the new one.
    */
    function migrate(uint256 _amount) public {
        require(migrationStage != 0, "Migration has not started or has ended.");        

        if(migrationStage == 1){
            migrationSimple(_amount);
        }else{
            migrationAdvanced(_amount);
        }
    }

    function migrationSimple(uint256 _amount) internal {    
        uint256 _newAmount = ((_amount * 1e9) * exchangeRatio) / 100;         
        require(_newAmount <= token_new.balanceOf(address(this)), "Contract does not have enough V2 funds.");
        token_old.transferFrom(msg.sender, address(this), _amount);          
        token_new.transfer(msg.sender, _newAmount);
        balanceIn += _amount;
        balanceOut += _newAmount;
    }

    function migrationAdvanced(uint256 _amount) internal {
        token_old.transferFrom(msg.sender, address(this), _amount);   
        token_old.approve(address(this), _amount);         
        uint[] memory amounts = router.swapExactTokensForTokens(_amount, 0, tokenPath, address(this), block.timestamp + 6);
        token_new.transfer(msg.sender, amounts[2]);
        balanceIn += _amount;
        balanceOut += amounts[2];
    }

    function withdrawRaisedTokens() external onlyOwner {        
        uint256 oldTokenBalance = token_old.balanceOf(address(this));
        token_old.transfer(msg.sender, oldTokenBalance);
    }

    function withdrawUnclaimedTokens() external onlyOwner {
        uint256 newTokenBalance = token_new.balanceOf(address(this));
        token_new.transfer(msg.sender, newTokenBalance);
    }

    function withdrawEther() external onlyOwner {
        uint256 etherBalance = address(this).balance;
        payable(msg.sender).transfer(etherBalance);
    }

}