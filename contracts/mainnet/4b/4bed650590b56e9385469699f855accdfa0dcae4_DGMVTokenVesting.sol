/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b,  "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
       
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
       
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,  "SafeMath: modulo by zero");
        return a % b;
    }
}
/**
* @title interface of ERC 20 token
* 
*/

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
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
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _newOwner;

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
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Propose the new Owner of the smart contract 
     */
    function proposeOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _newOwner = newOwner;
    }

    /**
     * @dev Accept the ownership of the smart contract as a new Owner
     */
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner");
        require(_owner != address(0), "Ownable: ownership is renounched already");
        emit OwnershipTransferred(_owner, _newOwner);
        _owner = _newOwner;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


contract DGMVTokenVesting is Ownable{
    
    using SafeMath for uint256; 
    
    address public immutable DGMV_TOKEN; // Contract Address of DGMV Token
    
    struct VestedToken{
        uint256 cliff;
        uint256 start;
        uint256 duration;
        uint256 releasedToken;
        uint256 totalToken;
        bool revoked;
    }
    
    mapping (address => VestedToken) public vestedUser; 
    event TokenReleased(address indexed account, uint256 amount);
    event VestingRevoked(address indexed account);
    
    constructor (address dgmv_token){
        require(dgmv_token != address(0));
        DGMV_TOKEN = dgmv_token;
    }
  
     /**
     * @dev this will set the beneficiary with vesting 
     * parameters provided
     * @param account address of the beneficiary for vesting
     * @param amount  totalToken to be vested
     * @param cliff In seconds of one period in vesting
     * @param duration In seconds of total vesting 
     * @param startAt UNIX timestamp in seconds from where vesting will start
     */
     function setVesting(address account, uint256 amount, uint256 cliff, uint256 duration, uint256 startAt ) external returns(bool){
         VestedToken storage vested = vestedUser[account];
         if(vested.start > 0){
             require(vested.revoked);
             uint unclaimedTokens = _vestedAmount(account).sub(vested.releasedToken);
             require(unclaimedTokens == 0);
         }
         IERC20(DGMV_TOKEN).transferFrom(_msgSender(), address(this) ,amount);
         _setVesting(account, amount, cliff, duration, startAt);
         return true;
     }
     
     /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
     function vestedToken(address account) external view returns (uint256) {
       return _vestedAmount(account);
    }
    
    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
     function releasableToken(address account) external view returns (uint256) {
       return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }
     
     /**
      * @dev Internal function to set default vesting parameters
      * @param account address of the beneficiary for vesting
      * @param amount  totalToken to be vested
      * @param cliff In seconds of one period in vestin
      * @param duration In seconds of total vesting duration
      * @param startAt UNIX timestamp in seconds from where vesting will start
      *
      */
     function _setVesting(address account, uint256 amount, uint256 cliff, uint256 duration, uint256 startAt) internal {
         require(account!=address(0));
         require(startAt >= block.timestamp);
         require(cliff<=duration);
         VestedToken storage vested = vestedUser[account];
         vested.cliff = cliff;
         vested.start = startAt;
         vested.duration = duration;
         vested.totalToken = amount;
         vested.releasedToken = 0;
         vested.revoked = false;
     }

    /**
     * @notice Transfers vested tokens to beneficiary.
     * anyone can release their token 
     */
    function releaseMyToken() external returns(bool) {
        releaseToken(msg.sender);
        return true;
    }
    
     /**
     * @notice Transfers vested tokens to the given account.
     * @param account address of the vested user
     */
    function releaseToken(address account) public {
       require(account != address(0));
       VestedToken storage vested = vestedUser[account];
       uint256 unreleasedToken = _releasableAmount(account);  // total releasable token currently
       require(unreleasedToken>0);
       vested.releasedToken = vested.releasedToken.add(unreleasedToken);
       IERC20(DGMV_TOKEN).transfer(account,unreleasedToken);
       emit TokenReleased(account, unreleasedToken);
    }
    
    /**
     * @dev Calculates the amount that has already vested but hasn't been released yet.
     * @param account address of user
     */
    function _releasableAmount(address account) internal view returns (uint256) {
        return _vestedAmount(account).sub(vestedUser[account].releasedToken);
    }

  
    /**
     * @dev Calculates the amount that has already vested.
     * @param account address of the user
     */
    function _vestedAmount(address account) internal view returns (uint256) {
        VestedToken storage vested = vestedUser[account];
        uint256 totalToken = vested.totalToken;
        if(block.timestamp <  vested.start.add(vested.cliff)){
            return 0;
        }else if(block.timestamp >= vested.start.add(vested.duration) || vested.revoked){
            return totalToken;
        }else{
            uint256 numberOfPeriods = (block.timestamp.sub(vested.start)).div(vested.cliff);
            return totalToken.mul(numberOfPeriods.mul(vested.cliff)).div(vested.duration);
        }
    }
    
    /**
     * @notice Allows the owner to revoke the vesting. Tokens already vested
     * remain in the contract, the rest are returned to the owner.
     * @param account address in which the vesting is revoked
     */
    function revoke(address account) external onlyOwner returns(bool) {
        VestedToken storage vested = vestedUser[account];
        require(!vested.revoked);
        uint256 balance = vested.totalToken;
        uint256 vestedAmount = _vestedAmount(account);
        uint256 refund = balance.sub(vestedAmount);
        require(refund > 0);
        vested.revoked = true;
        vested.totalToken = vestedAmount;
        IERC20(DGMV_TOKEN).transfer(owner(), refund);
        emit VestingRevoked(account);
        return true;
    }
}