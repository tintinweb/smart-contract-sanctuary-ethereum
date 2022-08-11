// SPDX-License-Identifier: MIT

// Stake Tokens
// unStakeTOken
// issueTOken some rewards
// addAllowedTokens
// getETHvalue

// 100 ETH 1:1 for every ETH we give 1 DappToken

pragma solidity ^0.8.0;

import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm {
    address[] public allowed_tokens;

    address owner;
    IERC20 public _DappToken;

    constructor(address _dapptoken) public {
        owner = msg.sender;
        _DappToken = IERC20(_dapptoken);
    }

    // mapping token address => staker address => amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    address[] public stakers;

    mapping(address => uint256) public UniqueTokenStaked;
    mapping(address => address) public token_price_feed_mapping;

    function stakeTokens(uint256 _amount, address _token) public {
        // what tokens can they stake?
        // how much can they stake?
        require(_amount > 0, "Amount must be more than 0");
        // require(_token is allowed??);
        require(tokenIsAllowed(_token), "Token is currently no allowed");
        // transferFrom of ERC20 not transfer because transfer is when
        // you own tokens mais lÃ  c'est le contrat qui va faire la transaction
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokenStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] += _amount;
        if (UniqueTokenStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0!");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        UniqueTokenStaked[msg.sender] = UniqueTokenStaked[msg.sender] - 1;
    }

    function updateUniqueTokenStaked(address _sender, address _token) internal {
        if (stakingBalance[_token][_sender] <= 0) {
            UniqueTokenStaked[_sender] = UniqueTokenStaked[_sender] + 1;
        }
    }

    function issueToken() public OnlyOwner {
        for (uint256 i = 0; i <= stakers.length; i++) {
            address recipient = stakers[i];
            // send them a token reward based on their total value locked
            uint256 userTotalValue = getUserTotalValue(recipient);
            _DappToken.transfer(recipient, userTotalValue);
        }
    }

    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalvalue = 0;
        require(UniqueTokenStaked[_user] > 0, "No tokens Staked");
        for (uint256 i = 0; i <= allowed_tokens.length; i++) {
            totalvalue += getUserSingleTokenValue(_user, allowed_tokens[i]);
        }
        return totalvalue;
    }

    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        // 1 ETH -> $2,000 => return 2000
        if (UniqueTokenStaked[_user] <= 0) {
            return 0;
        }
        // price of the token * stakingBlance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / 10**decimals);
    }

    function setPriceFeedContract(address _token, address _pricefeed)
        public
        OnlyOwner
    {
        token_price_feed_mapping[_token] = _pricefeed;
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // pricefeedAddress
        address pricefeedaddress = token_price_feed_mapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            pricefeedaddress
        );
        (
            ,
            /*uint80 roundID*/
            int256 price,
            ,
            ,

        ) = /*uint startedAt*/
            /*uint timeStamp*/
            /*uint80 answeredInRound*/
            priceFeed.latestRoundData();
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    modifier OnlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function addAllowedToken(address _token) public OnlyOwner {
        allowed_tokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        for (uint256 i = 0; i <= allowed_tokens.length; i++) {
            if (allowed_tokens[i] == _token) {
                return true;
            }
        }
        return false;
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