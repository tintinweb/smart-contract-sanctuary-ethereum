/**
 *Submitted for verification at Etherscan.io on 2022-03-28
*/

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

pragma solidity ^0.8.4;

interface Token {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
    function transferFrom(address _from, address _to, uint _value)external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address owner, address spender) external returns (uint256);
}

contract Destructible is Ownable {

  constructor() payable { }

  /**
   * @dev Transfers the current balance to the owner and terminates the contract.
   */
  function destroy() onlyOwner public  payable{
    address finalOwner = owner();
    selfdestruct(payable(finalOwner));
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(payable(_recipient));
  }
}


contract BankSafe is Destructible{
    address mainOwner;
    uint256 timelock;
    uint256 poolAmount = 0;
    uint256 startTime = block.timestamp;
    uint256 setTime;
    uint256 totalStaked;
    uint256 usersStaked=0;
    address tokenAddress;
    
    struct User {
        address userAddress;
        uint tokenAmount;
        bool available;
    }
    mapping (address=>User) user;
    event Deposited(address user, uint256 amount);
    event Withdrawn(address user, uint256 amount);
    event PoolUpgraded(uint256 amount);
    
    constructor(address _tokenAddress, uint256 _setTime){
        mainOwner = msg.sender;
        timelock = block.timestamp + _setTime;
        setTime = _setTime;
        tokenAddress = _tokenAddress;
    }

    receive() external payable{
        revert();
    }

    function depositToken(uint256 _amount) depositOnly public{
        Token token = Token(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= _amount, "Not enough token allowance");

        token.transferFrom(msg.sender, address(this), _amount);
        if(!user[msg.sender].available){
            user[msg.sender] = User(msg.sender, _amount, true);
            usersStaked+=1;
        }else{
            uint256 formerAmount = user[msg.sender].tokenAmount;
            user[msg.sender] = User(msg.sender, _amount+formerAmount, true);
        }

        totalStaked += _amount;
        emit Deposited(msg.sender, _amount);
    }

    function addToPool(uint256 _amount) onlyOwnerAllowed public{
        Token token = Token(tokenAddress);
        require(token.allowance(msg.sender, address(this)) >= _amount, "Not enough token allowance");

        token.transferFrom(msg.sender, address(this), _amount);
        poolAmount += _amount;
        emit PoolUpgraded(_amount);
    }

    function withdrawToken(uint256 _amount) withdrawOnly public{
        uint256 rewards = getRewards(msg.sender);
        uint256 totalWithdrawToken = rewards + _amount;
        uint256 formerAmount = user[msg.sender].tokenAmount;
        require(_amount <= formerAmount, "You cannpt withdraw more than you deposited");
        Token token = Token(tokenAddress);
        token.transfer(msg.sender, totalWithdrawToken);
        poolAmount -= rewards;
        if(_amount == formerAmount){
            usersStaked -=1;
            user[msg.sender] = User(msg.sender, 0, false);
        }else{
            user[msg.sender] = User(msg.sender, formerAmount - _amount, true);
        }
        
        emit Withdrawn(msg.sender, totalWithdrawToken);
    }

    function getRewards(address _user) internal view returns(uint256){
        uint256 userStaked = user[_user].tokenAmount;
        uint256 userRatio = userStaked / totalStaked; //in 10**18 so decimal is almost avoidabal is insignificant
        uint256 timeSpent = block.timestamp - startTime;
        uint256 rewardsRatio = 0;

        if(timeSpent > 2 * setTime){
            rewardsRatio += 20;
        }

        if(timeSpent > 3 * setTime){
            rewardsRatio += 30;
        }

        if(timeSpent > 4 * setTime){
            rewardsRatio += 50;
        }

        uint256 totalRatio = (rewardsRatio * userRatio)/100;
        uint256 rewards = totalRatio * poolAmount;

        return rewards;
    }

    function closeContract() public onlyOwnerAllowed{
        uint256 timeSpent = block.timestamp - startTime;
        if(timeSpent > 4 * setTime && usersStaked == 0){
            Token token = Token(tokenAddress);
            token.transfer(mainOwner, poolAmount);
            destroy();
        }
    }
    
    modifier onlyOwnerAllowed {
        require(mainOwner == msg.sender, "unauthorized caller");
        _;
    }

    modifier depositOnly {
        require((block.timestamp - startTime) <= setTime, "deposit period is expired");
        _;
    }

    modifier withdrawOnly {
        require((block.timestamp - startTime) > 2 * setTime, "Staking rewards not yet matured");
        _;
    }
}