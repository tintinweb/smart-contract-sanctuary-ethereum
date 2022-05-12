/**
 *Submitted for verification at Etherscan.io on 2022-05-11
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;



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

// File: tokenfarm.sol

contract tokenfarm{
//STAKETOKENS
//UNSTAKETOKENS
//ISSUETOKENS
//DDALLOWEDTOKENS
//GETETHVALUE
    address[] public tokens;
    address public owner;
    address[] public stakers;
    

    mapping(address => mapping(address => uint256)) public stakingbalance;
    mapping(address => uint256) public uniquetokenstake;
    mapping(address => address) public tokenpricefeedmapping;

    IERC20 public dapptoken;

    constructor(address _dapptoken)  {
        owner = msg.sender;
        dapptoken = IERC20(_dapptoken);

    }

    function setpricefeedcontract(address _token, address _pricefeed) public {
        require(msg.sender == owner,'mmmm ya');
        tokenpricefeedmapping[_token] = _pricefeed;
    }

    function issuetokens () public{
        require(msg.sender == owner,'mmmm ya');
        for (uint i = 0; i<stakers.length; i++){
            address recipient = stakers[i];
            uint256 usertotalvalue = getusertotalvalue(recipient);
            dapptoken.transfer(recipient, usertotalvalue);
            
        }

    }

    function getusertotalvalue(address _user) public view returns(uint256){
        uint totalvalue = 0;
        require(uniquetokenstake[_user]>0,'you dont have any stake');
        for (uint i =0; i<tokens.length; i++){
            totalvalue = totalvalue + getusersingletokenvalue(_user, tokens[i]);     
        } 
        return totalvalue;

    }

    function getusersingletokenvalue (address _user, address _token) public view returns(uint256){
        if(uniquetokenstake[_user]<=0){
            return 0;
        }
        (uint256 price, uint256 decimals) = gettokenvalue(_token);
        return (stakingbalance[_token][_user]*price / (10**decimals));
    }

    function gettokenvalue(address _token) public view returns(uint256, uint256){
        address pricefeedaddress=  tokenpricefeedmapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(pricefeedaddress);
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);



    }

    function staketoken(uint256 _amount, address _tokens) public {
        require(_amount >0, 'so you wanna stake 0 token xd');
        require(allowtokens(_tokens),"token is no allowed");
        IERC20(_tokens).transferFrom(msg.sender, address(this), _amount);
        updateuniquetokenstake(msg.sender, _tokens );
        stakingbalance[_tokens][msg.sender] += _amount;
        if(uniquetokenstake[msg.sender] == 1){
            stakers.push(msg.sender);
        }
    }

    function unstaketoken(address _tokens) public {
        uint256 amount = stakingbalance[_tokens][msg.sender];
        require(amount>0,'what do you going to unstake budddy??? xd');
        IERC20(_tokens).transfer(msg.sender,amount);
        stakingbalance[_tokens][msg.sender] = 0;
        uniquetokenstake[msg.sender] -= 1;
       
    }

    function updateuniquetokenstake(address _user, address _tokens) internal{
        if(stakingbalance[_tokens][_user] <= 0){
            uniquetokenstake[_user] += 1;
        }

    }

    function addtoken(address _tokens) public {
        require(msg.sender == owner, "mmmm ya ");
        tokens.push(_tokens);
    }
    function allowtokens(address _tokens) public returns(bool){
        for (uint i = 0; i<tokens.length; i++){
            if(tokens[i] == _tokens){
                return true;
            }
        return false; 
        }
    }


}