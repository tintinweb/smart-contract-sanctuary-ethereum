/**
 *Submitted for verification at Etherscan.io on 2023-06-10
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/[email protected]/utils/Context.sol


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

// File: @openzeppelin/[email protected]/access/Ownable.sol


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

// File: New/Stake.sol


pragma solidity ^0.8.4;


interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract StakeToken is Ownable{

    //1000000000 * 10 ** 18

    IERC20 public immutable stakingToken;

    mapping (address => uint256) myBalance;
    mapping (address => uint256) myStartTime;
    mapping (address => uint256) myDeposit;

    uint256 APR = 1000000000;

    uint256 allDeposit = 0;

    constructor (address _stakingToken){
        stakingToken = IERC20(_stakingToken);
    }

    function showDeposit(address _myAddres) public view returns(uint256){
        return myDeposit[_myAddres];
    }

    function showMyBalance(address _myAddres) public view returns(uint256){
      return myDeposit[_myAddres] + myBalance[_myAddres] / 100 * ((APR-allDeposit)/10000000) / 365 /60 * (block.timestamp - myStartTime[_myAddres]) / 60;
    }

     function showTimeAllStake(address _myAddres) public view returns(uint256){
      return block.timestamp - myStartTime[_myAddres];
    }

    function showEarned(address _myAddres) public view returns(uint256){
        return myBalance[_myAddres] / 100 * ((APR-allDeposit)/10000000) / 365 /60 * (block.timestamp - myStartTime[_myAddres]) / 60 ;
    }

    function showAPR() public view returns(uint256){
        return ((APR-allDeposit)/10000000);
    }

    function ShowBalanceContract() public view returns(uint256){
        return stakingToken.balanceOf(address(this));
    }

    function staking(uint256 _amount) public {
        require (_amount > 0 , "amount < 0");
        require(stakingToken.balanceOf(msg.sender) >= _amount, "insufficient funds");
        require(myDeposit[msg.sender] == 0, "Already staking");
        myBalance[msg.sender] += _amount;
        myDeposit[msg.sender] += _amount;
        myStartTime[msg.sender] = block.timestamp;
        stakingToken.transferFrom(msg.sender,address(this),_amount);
        allDeposit += _amount;
    }

    function addStaking(uint256 _amount) public{
        myBalance[msg.sender] += _amount;
        myDeposit[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender,address(this),_amount);
    }

    function withdraw() public{
         stakingToken.transfer(msg.sender, myDeposit[msg.sender] + myBalance[msg.sender] / 100 * ((APR-allDeposit)/10000000) / 365 /60 * (block.timestamp - myStartTime[msg.sender]) / 60);
         myBalance[msg.sender] = 0;
         myDeposit[msg.sender] = 0;
         myStartTime[msg.sender] = 0;
         allDeposit -= myDeposit[msg.sender];
    }
    
}