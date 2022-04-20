// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "Ownable.sol";
//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
import "IERC20.sol";
//https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol

import "AggregatorV3Interface.sol";
//https://github.com/smartcontractkit/chainlink/blob/develop/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol

// stakeTokens
// unstakeTokens
// IssueTokens
// addAllowedTokens
// getTokenValue

// 100 ETH 1:1 for every 1 ETH, we give 1 DappToken
// 50 ETH and 50 DAI staked, and we want to give a reward of 1 DAPP / 1 DAI

contract TokenFarm is Ownable{
   // mapping token address  of staker who belong to  amount 
   mapping(address=>mapping(address=>uint256) ) public stakingBalance;
   // {'token-a': {'acc1':1,'acc2':2,'acc2':1} }

   // mapping how many token name the staker stake 
   mapping(address=>uint256) public uniqueTokensStaked;

   mapping(address=>address) public tokenPriceFeedMapping;
   // list staker address
   address[] public stakers;
   // list token allowed to stake  such as dia,jomos
   address[] public allowedTokens;

   IERC20 public jomoxToken;

   constructor (address _jomoxTokenAddress) public  
   { // Token reward  
     jomoxToken=IERC20(_jomoxTokenAddress);
   }

   //https://docs.chain.link/docs/ethereum-addresses/
   function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
      tokenPriceFeedMapping[_token]=_priceFeed;
   }


   function issueTokens() public onlyOwner{
       for (uint256 index = 0; index < stakers.length; index++) {

         address recipient=stakers[index];
         uint256 userTotalValue=getUserTotalValue(recipient);
          //send them a token reward
         jomoxToken.transfer(recipient,userTotalValue);


       }
   }
   function getUserTotalValue(address _user) public view returns(uint256) {
       uint256 totalValue=0;
       
       require(uniqueTokensStaked[_user] > 0, "No tokens staked!");

       for (uint256 allowTokensIndex = 0; allowTokensIndex < allowedTokens.length; allowTokensIndex++) {
           totalValue=totalValue + getUserSingleTokenValue(_user,  allowedTokens[allowTokensIndex]);
       }

      return totalValue;
   }
   function getUserSingleTokenValue(address _user,address _token) public view returns(uint256){
        if (uniqueTokensStaked[_user]<=0){
            return 0;
        }

       (uint256 price,uint256 decimals) = getTokenValue(_token);
        // price of the token * stakingBalance[_token][user] (price of the token*amount of token)   
        // 10 18decimals(000000000000000000) ETH  ==>(10**decimanls)
        // ETH/USD -> 10000000000  ==>price
        // 10 * 100 = 1,000
        // X worth of  token
       return  (stakingBalance[_token][_user] * price/ (10**decimals) );
   }
    function getTokenValue(address _token) public view returns (uint256, uint256) {
        // priceFeedAddress (Proxy column in table datafeed)  
        //https://docs.chain.link/docs/ethereum-addresses/  
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        // create conttract instance
        //https://github.com/smartcontractkit/chainlink-brownie-contracts/blob/main/contracts/abi/v0.8/AggregatorV3Interface.json
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
 
        // Do 2 steps 1. get price 2. get the number of decimal
        (,int256 price,,,)= priceFeed.latestRoundData();
        uint256 x_price= uint256(price);

        uint256 x_decimals = uint256(priceFeed.decimals());
        
        return (x_price, x_decimals);
    }


   function stakeToken(uint256 _amount, address _token) public{
      
       // What token do you want to stake
       // How much  you can stake
       require(_amount>0,"Amount must be more than 0");
       require(tokenIsAllowed(_token),"This token is not allowed");
        
        // IERC20 is an interface to invoke ERC20 on your behalf
       //https://docs.openzeppelin.com/contracts/4.x/api/token/erc20#IERC20-transferFrom-address-address-uint256-
       //transferFrom(address from, address to, uint256 amount)
       IERC20(_token).transferFrom(msg.sender,address(this),_amount);

       updateUniqueTokensStaked(msg.sender,_token);

       stakingBalance[_token][msg.sender]=stakingBalance[_token][msg.sender]+_amount;
       if (uniqueTokensStaked[msg.sender]==1)
        {
          stakers.push(msg.sender);
        }

   }
   function unstakeToken(address _token) public{

       uint256 balance=stakingBalance[_token][msg.sender];
       require(balance>0,"Staking balance cannot be 0");
       IERC20(_token).transfer(msg.sender,balance);

       // Unstake all amount
       // clear balance of user who staked in that token
       stakingBalance[_token][msg.sender]=0;

       // remove the token after unstaking
       uniqueTokensStaked[msg.sender]=uniqueTokensStaked[msg.sender]-1;
         
         // For multiple stake and unstake such stake#1=4 +stake2=2 and unstake#1=3 and last-unstake=3
         // 4+2=3+3 
         // The code below fixes a problem not addressed in the video, where stakers could appear twice
        // in the stakers array, receiving twice the reward.
        // if (uniqueTokensStaked[msg.sender] == 0) {
        //     for (
        //         uint256 stakersIndex = 0;
        //         stakersIndex < stakers.length;
        //         stakersIndex++
        //     ) {
        //         if (stakers[stakersIndex] == msg.sender) {
        //             stakers[stakersIndex] = stakers[stakers.length - 1];
        //             stakers.pop();
        //         }
        //     }
        // }

   }
   

   // how many tokens does the staker have in this dApp
   function updateUniqueTokensStaked(address _user,address _token) internal{
       if (stakingBalance[_token][_user]<=0){
           uniqueTokensStaked[_user]=uniqueTokensStaked[_user]+1;
           }
   }


   function addAllowedToken(address _token) public onlyOwner{

       allowedTokens.push(_token);
   }
   function listNumberOfAllowedToken() public view returns(uint256){

       return   allowedTokens.length;
   }

   function tokenIsAllowed(address _token) public returns(bool){
       for (uint256 token_index = 0; token_index < allowedTokens.length; token_index++) {
           if ( allowedTokens[token_index]==_token){
                   return true;
           }
       }
       return false;

   }


}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";

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