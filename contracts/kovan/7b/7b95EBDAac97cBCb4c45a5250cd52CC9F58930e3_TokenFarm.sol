// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm
{
    address[] public allowedTokens;
    address public admin;
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public mapOfStakers;
    address[] public stakers;
    IERC20 public dappToken;
    mapping(address => address) public tokenTo_priceFeedMapping;

    constructor(address _dappTokenAddress) {
        admin= msg.sender;
        dappToken= IERC20(_dappTokenAddress);
    }
    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner {
        tokenTo_priceFeedMapping[_token] = _priceFeed;
    }
    function stakeTokens(address _token, uint256 _amount) public {
        require(_amount> 0, "amount should be greater than '0'");
        require(TokenValidator(_token), "This token is not currently supported on our plantform.");
        // they should approve
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); // same thing as object making // holders address(here- since take perspective of user not dev.)/asset address, TokenFarm contract address(don't u ever dare to take it in personal address), amount to be staked.
        uniquenessValidator(_token, msg.sender);
        stakingBalance[_token][msg.sender]= stakingBalance[_token][msg.sender] + _amount;
        if (mapOfStakers[msg.sender]== 1) {
            stakers.push(msg.sender);
        }
    }
    function uniquenessValidator(address _token,address _user) internal {
        if (stakingBalance[_token][_user]>= 0) {
            mapOfStakers[_user]= mapOfStakers[_user]+ 1;
        }
    }
    function TokenValidator(address _token) public view returns (bool) {
        for(uint256 j=0; j<allowedTokens.length; j++) {
            if(allowedTokens[j]== _token) {
                return true;
            }
        }
        return false;
    }
    function issueTokens () public onlyOwner {
        // issue tokens to all stakers when called by admin..
// # we are staking 1 dapp_token == in price to 1 ETH
// # soo... we should get 2,000 dapp tokens in reward
// # since the price of eth is $2,000
        for (uint256 stakersIndex= 0; stakersIndex< stakers.length; stakersIndex++) {
            dappToken.transfer(stakers[stakersIndex], getUserTotalValueStakedAcross(stakers[stakersIndex]));
        }
    }
    function getUserTotalValueStakedAcross (address _user) public view returns (uint256) {// returns value staked across different allowed tokens
        require(mapOfStakers[_user]> 0);
        uint256 Totalvalue =0;
        for (uint256 allowedTokensIndex; allowedTokensIndex< allowedTokens.length; allowedTokensIndex++) {
            Totalvalue= Totalvalue+ valueStaked_inEachTokens(allowedTokens[allowedTokensIndex],_user);// example:- 0+45+323+0+32+0+0
        }
        return Totalvalue;
    }
    function valueStaked_inEachTokens(address _token,address _user) public view returns (uint256) { // value return in usd
        if (mapOfStakers[_user]<= 0) {
            return 0;
        }
        // since our token is not so famous so its priceFeeds are not given at chainlink or anywhere else so we will convert it to usd here and then will later convert it to equivalent dappTokens
        (uint256 price, uint256 decimals)= valueIn_usd(_token);
        return (stakingBalance[_token][_user] * price/(10**decimals));
    }
    function valueIn_usd(address _token) public view returns (uint256, uint256) {
        address _priceFeeds= tokenTo_priceFeedMapping[_token];
        AggregatorV3Interface priceFeeds= AggregatorV3Interface(_priceFeeds); // creates a fluctuating in priceFeeds
        (,int256 price,,,)= priceFeeds.latestRoundData(); // we get price in 8 decimals from this contract and also it is signed interger
        uint256 decimals= uint256(priceFeeds.decimals());
        // uint256 adjustedPrice= uint256(price)*10**10;
        return (uint256(price), decimals);
    }
    function unstakeTokens(address _token) public {// being called by the user
        // we transfer balance
        // we resettle those 2 mappings and 1 list
        uint256 balance= stakingBalance[_token][msg.sender];
        require(balance<= 0, "Have no tokens staked in!!");
        IERC20(_token).transfer(msg.sender, balance);
        // 
        stakingBalance[_token][msg.sender]= 0;
        mapOfStakers[_token]= mapOfStakers[_token]- 1;
        for (uint256 stakersIndex= 0; stakersIndex< stakers.length; stakersIndex++) {
            if (stakers[stakersIndex]== msg.sender) {
                stakers[stakersIndex]= stakers[stakers.length- 1];
                stakers.pop();
            }
        }
    }
    modifier onlyOwner {
        require(msg.sender== admin);
        _;
    }
    function addAllowedTokens(address newTokenAllowed) public onlyOwner {
        allowedTokens.push(newTokenAllowed);
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