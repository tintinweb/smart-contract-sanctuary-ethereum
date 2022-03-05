// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";       // https://docs.chain.link/docs/get-the-latest-price/

contract TokenFarm is Ownable{
    //stakeTokens - Done 
    //unstakeTokens
    //issueToken    - Done 
    //addAllowedToken   - Done 
    //getValue  - Done 

        
        mapping(address => mapping(address => uint256 )) public stakingBalance;     // mapping token address -> staker address -> amount

        mapping(address => uint256) public uniqueTokensStaked; // we'll know how many different tokens each one of these addresses actually hs staked

        mapping(address => address) public tokenPriceFeedMapping; // token with associated pricefeed addresses

        address[] public allowedTokens;

        address[] public stakers;

        IERC20 public dappToken;

        constructor(address _dappTokenAddress) public {
            // to keep track of our reward token
            dappToken = IERC20(_dappTokenAddress);
        }

        function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
            // Function to set token with respected pricefeed
            tokenPriceFeedMapping[_token] = _priceFeed;             // https://docs.chain.link/docs/ethereum-addresses/
            
        }


        function issueTokens() public onlyOwner {

            // Issuing Token we will reward them based in the value of token they staked 
            // eg: 100ETH 1:1 for every 1 ETH, we give 1 DappToken
            // 50 ETH and 50 DAI staked, and we want to give a reward of 1Dapp / 1DAI then we'll conver eth to dai using live rate conversion 

            // now to issue rewards to all those stakers we need a list of stakers and we created up there

            for (uint256 stakersIndex = 0; stakersIndex < stakers.length; stakersIndex ++){
                address recepient = stakers[stakersIndex];
                // send them a token reward     - our DappToken that we created
                // based on their total value locked

                // So right before we deploy we need to know what our reward token is actually to be so we can do is
                // right at the constructor we can store what our reward token is to be 

                uint256 userTotalValue = getUserTotalValue(recepient); // this will return the total value of the token staked on based on it we reward them


                dappToken.transfer(recepient, userTotalValue);      // Now we can call function on it example we can call dapptoken.transfer beacuse our token farm contract is going to be the contract that actually holds all thses dapp tokens
                                        // and we are going to send this token to recepient but how much are we going to send 

            }



        }
        
        function getUserTotalValue(address _user) public view returns (uint256){
            // we are gonna find out how each these tokens actually has 
            // Now alot of protocols actually do instead of them sending and them issuing the tokens is they actually just they have some internal method
            // which allows people to go and claim their tokens right we've probably seen that before people claiming airdrops
            // thats because its alot more gas efficient to have the users claim the airdrpped instead of the application actually issuing the tokens right its going to be very close to be very gas expensive to do looping 
            // through all these addresses and checking all these addresses right we're going to do it though beacuse we are a wonderful amazing protocol and we want to give our users the best experience 
            // and this is going to be public view function that will return a uiny256 
        
            // we are going to return this total value to our issue token here

            uint256 totalValue = 0;
 
            require(uniqueTokensStaked[_user] > 0, "NO tokens staked !");
            for( uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex ++){

                    totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[allowedTokensIndex]);
            }
            return totalValue;
            // Now we can pull up our issue token
        } 

        function getUserSingleTokenValue(address _user, address _token) public view returns (uint256) {

            // staked 1ETH -> $2,000  2000
            // staked 200 DAI -> $200  200
            if (uniqueTokensStaked[_user] <= 0){
                return 0;           // we dont need a require here as we already require() in the calling function
            }

            // price of the token * stakingBalance[_token][_user]
            // so lets create another function getTokenValue()

            (uint256 price, uint256 decimals) = getTokenValue(_token);

            return ( stakingBalance[_token][_user] * price / (10 **decimals)); 
            // 10_0000000000_0000000ETH         just 10ETH  
            // all the tokens are converted to usd price 
            //ETH/USD -> 100_00000000 assuming $100 
            // 10 * 100 = 1000
            // our staking balance is going to be 18 decimals  

            //this is a function that we definitely need to TEST! 

            
        }

        function getTokenValue(address _token) public view returns (uint256,uint256){
            // pricefeed 
            // so now we have to associate each token to their associated price feed addresses so we some mapping
            address priceFeedAddress = tokenPriceFeedMapping[_token];
            // now we have this(pricefeedaddress) we can use this on an aggregator v3 interface  
            //https://docs.chain.link/docs/get-the-latest-price/
            AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
            (,int256 price,,,) = priceFeed.latestRoundData(); // returns 5 data
            uint256 decimals = priceFeed.decimals(); // we care about the decimals in that way we can match everything into the same units
            // priceFeed.decimals() it actually returns uint 8 so we will wra it arounf uint256 
            return (uint256(price), uint256(decimals));
        
        }

        
        
        function stakeTokens(uint256 _amount, address _token) public {
            // keeping in mind what token can they stake?
            //how much can they stake?
            require(_amount > 0, "Amount must be more than 0"); // you can stake any amount greater than zero ; code - passes only if amount is greater htan zero

            // Now lets check if token is allowed? 
            // so lets make a function for that 

            require(tokenIsAllowed(_token), "Token is currently not allowed");

             // remember ERC20 has two transfer 
             // transfer() and transferFrom()
             // transfer only works it it's being called from the wallet who owns the tokens 
             // if we dont own thr token we have to do transferFrom() and they have to call approve first 
             //so we are going to call the transferFrom () from the ERC20 since our tokenFarm isnt the one that owns the erc20 
             // we also have to have the abi to call this transferFrom() so we are going to need the IERC20 interface  
             
             //we are using the interface instead of using the entire contract
             //Now lets wrap this token address as an ERC20 token
             IERC20(_token).transferFrom(msg.sender, address(this), _amount); 
             //so now we have the abi via this interface and the address and we'll call that transferFrom()
            // and we will send this to the tokenFarm contract and we will send an amount


            updateUniqueTokensStaked(msg.sender, _token);       // mapping for keeping track of how many unoque Tokens an user has

            // Now we have to keep track of how much of these tokens have been send to us 
            // lets create some mapping  token address -> staker address -> amount 
            stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;      //Now this allowed users to stake different token 

            if(uniqueTokensStaked[msg.sender] == 1){
                stakers.push(msg.sender);       // we are updating our no of stakers 
            }
 

        }


        function unstakeTokens(address _token) public {
            uint256 balance = stakingBalance[_token][msg.sender]; 
            require(balance > 0, "staking balance cannot be 0");
            IERC20(_token).transfer(msg.sender, balance);   // we are going to transfer 
            // once we transfer our token 
            stakingBalance[_token][msg.sender] = 0; // once it is transfered we are going to make this token balanv=ceto be zero 
                                                    // because we are going to transfer the entire balance here and then we are ging to update how many of those
                                                    // unique tokens that they have 

           // note: Reentrancy attacks 

           uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1; // as we transfered one whole token to user we will reduce the unique token count by 1 | logic

           // Now the last thing we could do is we should probably should actually update 
           // our stakers array to remove this person if they no longer have anything staked

           // But for time being its not an issue to add this functionality as the issueToken() check to see how much can they actually have staked and if they dont have anything staked
           // they are not going to get sent any tokens                                             


        } 


        function updateUniqueTokensStaked(address _user, address _token) internal {
            // internal - only this contract can call this function
            if (stakingBalance[_token][_user] <= 0){
                uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1 ;     // unique tokens staked by the user is incremented when the token is less than or eq 0  
            }   

        }


        function addAllowedTokens(address _token) public onlyOwner {
            allowedTokens.push(_token);
        }

        function tokenIsAllowed(address _token) public returns (bool){
            // so how do we know if a token is allowed we'll probably need a list of mapping  
            // we could use list or mapping to achieve this but for simplicity we used list
            for(uint256 allowedTokensIndex = 0; allowedTokensIndex < allowedTokens.length; allowedTokensIndex++){
                if(allowedTokens[allowedTokensIndex] == _token){
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