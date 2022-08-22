/**
 *Submitted for verification at Etherscan.io on 2022-08-22
*/

// SPDX-License-Identifier: MIT
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


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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

// File: contracts/MonsterBattleSHIB.sol


pragma solidity ^0.8.0;



interface ICheck {

    function checkSHIB(address _address, uint256 _amount, string memory signedMessage) external view returns (bool);
}

contract MonsterBattleSHIB is Ownable{
    ICheck private Check;
    IERC20 public SHIBToken;

    bool public _isActiveWithdrawalSHIB = true;
    

    uint256 maxWithdrawSHIB = 100000000 ether;
    uint256 withdrawTimes = 3600;
   
    address public receiver = 0xDAC226421Fe37a1B00A469Cf03Ba5629ef5a3db6;
    address public shibAddress = 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE;
   
    mapping(address => uint256) private SignatureSHIB;
   
    event withdrawSHIBEvent(address indexed to,uint256 indexed _amount,uint256 indexed _timestamp); 
   

    constructor(address _check) {  
        Check = ICheck(_check);
        SHIBToken = IERC20(shibAddress);
    }

    function withdrawSHIB(uint256 _amount, string memory _signature) public {
        require(
            _isActiveWithdrawalSHIB,
            "Withdraw must be active"
        );

         require(
            _amount > 0,
            "Withdraw SHIB must be greater than 0"
        );

        require(
            _amount <= maxWithdrawSHIB,
            "Withdraw SHIB must be less than max withdraw at 1 time"
        );

        require(
            SignatureSHIB[msg.sender] + withdrawTimes <= block.timestamp,
            "Can only withdraw 1 times at 1 hour"
        );

        require(
            Check.checkSHIB(msg.sender, _amount, _signature) == true,
            "Audit error"
        );

        require(
            SHIBToken.balanceOf(address(this)) >= _amount,
            "SHIB credit is running low"
        );

        SignatureSHIB[msg.sender] = block.timestamp;

        SHIBToken.transfer(msg.sender, _amount);

        emit withdrawSHIBEvent(msg.sender, _amount, block.timestamp);
    }
    
    function setReceiver(address _addr) public onlyOwner{
        receiver = _addr;
    }

    function setCheckContract(address _addr) public onlyOwner{
        Check = ICheck(_addr);
    }

    function setSHIBContract(address _addr) public onlyOwner{
        SHIBToken = IERC20(_addr);
    }

    function setMaxWithdrawSHIB(uint256 _amount) public onlyOwner{
        maxWithdrawSHIB = _amount;
    }

    function setWithdrawTimes(uint256 _timestamp) public onlyOwner{
        withdrawTimes = _timestamp;
    }

   

}