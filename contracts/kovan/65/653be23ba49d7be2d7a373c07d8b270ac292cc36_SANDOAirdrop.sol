// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./IERC20.sol";

contract SANDOAirdrop is Ownable {

    IERC20 public token;
    uint public AirdropPerUser=100*10**18;
    address public OwnerTokenAddress;
    string phaseOfsales="Airdrop";
    event airdrop_log(string remark, address _msgSender, uint _amount,bool _status);
    event OwnerWithdraw(string phase,uint256 amount);

    mapping(address => bool) public hasClaimed;

    /*constructor (IERC20 _tokenAddr)  public {
        token = IERC20(_tokenAddr);
    }*/

   bool internal locked;

    modifier noReentrant() {
        require(!locked,"The list is not complete. please wait a moment.");
        locked = true; //before use function, set status locked is true.
        _;
    }

    function _changeTokenAirdrop(IERC20 _tokenAddr) public onlyOwner {
        token = IERC20(_tokenAddr);
    }

    function _setAirdropAmount(uint _amount) public onlyOwner {
        AirdropPerUser = _amount;
    }

    function getAirdrop() public {
        require(msg.sender != address(0x0),"Address is not zero.");
        require(hasClaimed[msg.sender] != true,"You has airdrop claimed.") ;
        require(AirdropPerUser <= token.balanceOf(address(this)) ,"Airdrops are sold out.");
        token.transfer(msg.sender, AirdropPerUser);
        hasClaimed[msg.sender] = true;
        emit airdrop_log("You have airdrop.",msg.sender,(AirdropPerUser/10**18), hasClaimed[msg.sender]);
    }

    function _clearhasClaimed(address claimAddress) public onlyOwner returns(bool){
        require(claimAddress != address(0x0),"Address is not zero.");
        hasClaimed[claimAddress] = false;    
        return hasClaimed[msg.sender];
    }

    function _getOwnerToken() public onlyOwner returns(address){
        bytes memory payload = abi.encodeWithSignature("_owner()","");  
        bool succcess = false;
        bytes memory result;
        (succcess, result)= address(token).call(payload);
        // Decode data
        OwnerTokenAddress = abi.decode(result, (address));
        return OwnerTokenAddress;
    }

    function _getBalanceWEI() external view returns(uint256){
        return address(this).balance;
    }

    function _getRemainToken() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function _OwnerWithdrawAll() public onlyOwner noReentrant{
      payable(msg.sender).transfer(address(this).balance);
      emit OwnerWithdraw(phaseOfsales, address(this).balance);
    }

    function _returnTokentoOriginAll() public onlyOwner noReentrant{
      uint256 AirdropBalance =  token.balanceOf(address(this)); 
      require(AirdropBalance > 0, "You need to send some ether");
      require(OwnerTokenAddress != address(0x0),"Address is not zero");
      token.transfer(OwnerTokenAddress, AirdropBalance);
      emit OwnerWithdraw(phaseOfsales,  AirdropBalance);
      locked = false; //after use function is finish, set status locked is false.

    }

    fallback() external payable {
    }

    receive() external payable {
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.13;

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
    
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when `value` tokens are befor moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event beforeTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when when `value` tokens are afther moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event afterTransfer(string remark, address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.13;

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
    address private _firstOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
        _firstOwner = msg.sender;
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
        _transferOwnership(_firstOwner);
        //_transferOwnership(address(0));
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

pragma solidity ^0.8.13;

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
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}