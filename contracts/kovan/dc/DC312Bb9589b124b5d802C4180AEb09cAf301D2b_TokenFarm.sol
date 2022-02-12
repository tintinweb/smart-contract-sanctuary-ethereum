/**
 *Submitted for verification at Etherscan.io on 2022-02-12
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

// Part: smartcontractkit/[email protected]/AggregatorV3Interface

interface AggregatorV3Interface {

  function decimals()
    external
    view
    returns (
      uint8
    );

  function description()
    external
    view
    returns (
      string memory
    );

  function version()
    external
    view
    returns (
      uint256
    );

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(
    uint80 _roundId
  )
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

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

contract TokenFarm is Ownable{
    
    address[] public allowedTokenAddresses;
    //map  token address -> user address -> amount
    // sort of like a dict within a dict
    mapping (address => mapping(address => uint256)) public stakingBalance;

    //map user address => number of unique token staked
    mapping(address => uint256) public uniqueTokensStaked;

    //map token address => price feed address
    mapping (address => address) public tokenPriceFeedMap;

    //list of users how has staked tokens
    address[] public stakers;
    
    //since we are incentivising the stakers with dapp token
    //we need to get the dapp token contract 
    IERC20 public dappToken;

    //construnctor
    constructor(address _dappTokenAddress) public{
        dappToken = IERC20(_dappTokenAddress);
    }

    //function to set the price feed address against a token address
    function setPriceFeedContract(address _tokenAddress , address _priceFeedAddress) public onlyOwner{
        tokenPriceFeedMap[_tokenAddress] = _priceFeedAddress;
    }

    //this function allows you to stake tokens
    //only certain tokens, filtered by the address, will be allowed to be staked
    function stakeTokens(uint256 _amount, address _tokenAddress) public{
        //need a minimal stake amount
        require(_amount >0, "Need more tokens to stake,please enter a higher amount");
        //need to make sure that the given token is an allowed one        
        require(tokenIsAllowed(_tokenAddress));
        IERC20(_tokenAddress).transferFrom(msg.sender,address(this),_amount);
        //we need a mechanism to identify the number of unique tokens that the user has staked
        //this will allow us to identify new users from alreading existing ones
        //this can further come in handy while rewarding the users
        updateUniqueTokenStaked( _tokenAddress,  msg.sender);
        //add the stake balace to the stakeBalance mapping
        //here the balance of the user of a perticular token is updated with the current amount they sent
        stakingBalance[_tokenAddress][msg.sender] = stakingBalance[_tokenAddress][msg.sender] + _amount;
        // if the user is a first time staker, add him to the staker list
        if(uniqueTokensStaked[msg.sender]== 1){//this means user is a new guy
            stakers.push(msg.sender); //this only pushes new users
        } 

    }

    //function to unstake tokens
    function unstakeTokens(address _tokenAddress) public{
        uint256 balance = stakingBalance[_tokenAddress][msg.sender];
        require(balance >0 , "Nothing to unstake here ! ");
        IERC20(_tokenAddress).transfer(msg.sender,balance);
        stakingBalance[_tokenAddress][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] -1;
    }

    //we need a function to issue new dappTokens as incentives to people who staked tokens

    function issueToken() public onlyOwner {
        for(uint256 stakerIndex = 0; stakerIndex < stakers.length; stakerIndex ++){
            address recipient = stakers[stakerIndex]; //get staker address
            //now we need to find the total value of the coins the recipient holds
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient,userTotalValue);

        }
        
    }

    //function to get the total token value the user owns
    function getUserTotalValue(address _user) public view returns(uint256){
        uint256 totalValue = 0;
        //make sure the user has some tokens staked
        require(uniqueTokensStaked[_user] > 0,"No tokens staked!");
        //get the value of each allowed tokens staked by the user
        for(uint256 allowedTokenIndex = 0;allowedTokenIndex<allowedTokenAddresses.length;allowedTokenIndex++){
            //get the value of each tokens
            // the value has to be converted to a common currency i.e ETH value
            totalValue = totalValue + getUserSingleTokenValue(_user,allowedTokenAddresses[allowedTokenIndex]);
        }
        return totalValue;

    }

    //get the value against eth for each alloed token staked by the user
    function getUserSingleTokenValue(address _user, address _tokenAddress) public view returns(uint256){
        if(uniqueTokensStaked[_user] <= 0){
            return 0;
        }
        //total value = priceOfToken in eth * no of that token that the user owns
        //we need to get the token value
        (uint256 price, uint256 decimals) = getTokenValue(_tokenAddress);
        return price * stakingBalance[_tokenAddress][_user] / 10 ** decimals;
    }

    //function to get the token value from priceFeed
    function getTokenValue(address _tokenAddress) 
    public view 
    returns(uint256,uint256){
        //get pricefeed address based on token
        address priceFeedAddress = tokenPriceFeedMap[_tokenAddress];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        ( , int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), decimals);

    }

    function updateUniqueTokenStaked(address _tokenAddress , address _senderAddress) internal{
        //check if user already staked this token, using stakeBalance mapping
        if(stakingBalance[_tokenAddress][_senderAddress] <= 0){
            uniqueTokensStaked[_senderAddress] = uniqueTokensStaked[_senderAddress]+1;
        }
    }

    //checks if a token is an allowed token
    function tokenIsAllowed(address _tokenAddress) public returns(bool){
        for(uint256 allowdTokenIndex = 0 ; allowdTokenIndex < allowedTokenAddresses.length;allowdTokenIndex++ ){
            if(allowedTokenAddresses[allowdTokenIndex] == _tokenAddress){
                return true;
            }
            return false;
        }
    }

    //add tokens to allowed token list
    function addAllowedTokens(address _tokenAddress) public onlyOwner{
        allowedTokenAddresses.push(_tokenAddress);
    }



}