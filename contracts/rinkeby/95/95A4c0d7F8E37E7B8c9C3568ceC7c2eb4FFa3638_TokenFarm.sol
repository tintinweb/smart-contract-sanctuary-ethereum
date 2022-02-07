/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;



// Part: OpenZeppelin/[email protected]/Context

/*
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

// Part: OpenZeppelin/[email protected]/IERC20

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

// Part: OpenZeppelin/[email protected]/Ownable

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

// File: TokenFarm.sol

contract TokenFarm is Ownable {
    mapping(address => uint256) public stakingBalance;    //mapping token address -> user address -> amount staked
    mapping(address => uint256) public rewardBalance;    //mapping token address -> user address -> amount won in weth
    mapping(address => address) public tokenPriceFeedMapping;
    address [] allowedTokens;
    address [] emptyArray;
    address [] public stakers;
    address [] public newStakers;
    address public mintyToken;
    address public WethToken;
    uint256 public totalMintyStaked;
    uint256 public farmBalance;
    
    
    constructor(address _MintyTokenAddress, address _WethTokenAddress) {
        mintyToken = _MintyTokenAddress;
        WethToken = _WethTokenAddress;
        allowedTokens = [_MintyTokenAddress, _WethTokenAddress];
        farmBalance = 0;
    }

    //MAIN FUNCTIONS

    //fund contract with weth
    function fundContract(uint _amount) public {
        require(_amount> 0,"Amount must be more than zero");
        IERC20(WethToken).transferFrom(msg.sender, address(this), _amount);
        farmBalance += _amount;
    }
   
   //Stake tokens
    function stakeTokens(uint256 _amount, address _token) public {
        //how much can they stake?
        require(_amount > 0,"Amount must be more than zero");
        require(_token == mintyToken,"Token is not allowed");
        //use transferFrom Function because we do not own the tokens. We also need the token abi from IERC20 interface
        IERC20(mintyToken).transferFrom(msg.sender, address(this), _amount);
        //add to stakingBalance
        stakingBalance[msg.sender] += _amount;
        //increase total staked
        totalMintyStaked += _amount;
        //add to stakers
        addToStakers(msg.sender);
    }

    function unstakeTokens(address _token, uint _amount) public  {
        //check if token is minty
        require(_token == mintyToken,"Token is not allowed");
        // check amount
        require(_amount > 0, "Amount must be more than zero");
        //get amount staked
        uint256 amountStaked = stakingBalance[msg.sender];
        //check if token is staked is more than amount
        require(amountStaked >= _amount,"Amount must be less than or equal to amount staked");
        // send amount to user
        IERC20(mintyToken).transfer(msg.sender, _amount);
        //remove amount from stakingBalance
        stakingBalance[msg.sender] -= _amount;
        //remove from totalMintyStaked
        totalMintyStaked -= _amount;
    }

    //reward stakers with WETH
    function rewardStakers() public {
        //get total minty staked
       for (uint i = 0; i < stakers.length; i++) {
            //get amount staked
            uint256 amountStaked = stakingBalance[stakers[i]];
            //get amount to reward
            uint256 amountToReward = amountStaked * farmBalance/totalMintyStaked;
            //set reward balance
            rewardBalance[stakers[i]] = amountToReward;
        }
        // set farm balance to zero
        farmBalance = 0;
    }

    //withdraw reward
    function withdrawReward(address _token, uint _amount) public {
        //check if token is minty
        require(_token == WethToken,"Only Weth Token is allowed");
        // fetch reward balance
        uint256 userRewardBalance = rewardBalance[msg.sender];
        //send amount to user
        IERC20(_token).transfer(msg.sender, userRewardBalance);
        //remove amount from reward balance
        rewardBalance[msg.sender] -= _amount;
    }

    //view user staked balance
    function getStakedBalance(address _token, address _user) public view returns (uint256){
        require(_token == mintyToken, "Token is not allowed");
        return stakingBalance[_user];
    }

    //view reward balance
    function getRewardBalance(address _token, address _user) public view returns (uint256){
        require(_token == WethToken, "Token is not allowed");
        return rewardBalance[_user];
    }
    
    // HELPER FUNCTION
    function tokenIsAllowed(address _token) public returns(bool){
        for (uint256 tokenIndex=0; tokenIndex<allowedTokens.length; tokenIndex++){
            if(allowedTokens[tokenIndex] == _token){
                return true;
            }
        }
        return false;
    }
 
    function fetchAllowedTokens() public view returns (address[] memory){
        return (allowedTokens);
    }

    function addToStakers(address _user) public {
        //check if user is already in stakers
        for(uint i = 0; i < stakers.length; i++){
            if(stakers[i] == _user){
                return;
            }
        }
        //add user to stakers
        stakers.push(_user);
    }
}