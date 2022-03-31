// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "Ownable.sol";
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    // need mapping of token address -> staker address -> amount
    mapping(address => mapping(address => uint256)) public stakingBalance;
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public stakers; //this list is so that we can capture the list of stakers for that particular token

    //stake token
    //unstake token
    //issue token
    //add allowed token
    //getEthValue
    address[] public allowedTokens; //this is a list of allowed tokens to be staked
    IERC20 public dappToken; //defining the dapptoken as a ERC20 type

    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress); //defining dapptoken variable as a dapptoken token from dapptoken.sol
    }

    //function to get the price feed contract
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed; // this mapping is to set the address of the price feed based on the token key
    }

    //function that will issue token as a reward for staking. for 1 ether give 1 dapptoken, for dai, need to covnert to eth first and then provide 1 dapptoken
    function issueTokens() public onlyOwner {
        //looping through the stakers(ie user address) list so that we can gather the totalvalue staked and transfer a corrosponding amount of dapptoken
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex]; //setting recipient to the current staker address in the loop
            uint256 userTotalValue = getUserTotalValue(recipient); //getting the total value from all the tokens by using the getTotalValue function

            //send them token reward based on total value of all staked token locked
            dappToken.transfer(recipient, userTotalValue); //token farm contract is the contract holding the dapptoken
        }
    }

    //function to get UserTotalValue,  user will get the value instead of protocol issuing, more gas efficient.  totalvalue across all owned tokens by user tokens are coverted to usd
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "no staked tokens"); //require atleast a certain amount of token staked
        //looping through the allowed tokens list and see if staker has an amout staked of that token.  then sum up all the value of the staked token as a total value
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTokenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue; //this is the total value of all the tokens owned by the user
    }

    //function to get a user single token value
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token); //need price of the token
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    //function to get the price of the token so that all token will have the same basis price
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        //will need to use chainlink pricefeeds
        address priceFeedAddress = tokenPriceFeedMapping[_token]; //storing the address of the price feed contract inside the pricefeedaddress variable obtained from mapping
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        ); //this is defining the priceFeed contract by utilizing the interface
        (, int256 price, , , ) = priceFeed.latestRoundData(); // this is getting the price conversion from the latest round data function which returns several values
        uint256 decimals = priceFeed.decimals(); //nneed to get decimals as well to use in conversion formula
        return (uint256(price), decimals);
    }

    //function takes in amount to stake and the token contract address
    function stakeTokens(uint256 _amount, address _token) public {
        //what types of token can they stake?
        //how much can they stake?

        require(_amount > 0, "amount not enough to stake");
        require(tokenIsAllowed(_token), "token is not allowed");
        //need to call transferfrom function since token farm contract does not own the token
        IERC20(_token).transferFrom(msg.sender, address(this), _amount); //using IERC20 interface to get abi, provide token address as argument, hence contract call complete thus can call transfer from function
        updateUniqueTokensStaked(msg.sender, _token); //calling function to check whether token currently staked is unique or not
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    //function to unstake token
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender]; //getting the balace of sender
        require(balance > 0, "staking balance cannot be 0");
        IERC20(_token).transfer(msg.sender, balance); //transferring out the balance from the contract back to the sender
        stakingBalance[_token][msg.sender] = 0; //zeroiing out the mapping sinice the balance has been transfered out
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1; //zerooing out the amount of unique token staked since the balance hass been withdrawn
    }

    //function to determine if token staked is unique or not and therefore if needed to update the stakes list
    function updateUniqueTokensStaked(address _user, address _token) internal {
        //is internal so only this contract can call the function
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    //function that adds the allowed tokens that can be staked
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    //create a function that defines what tokens are allowed to be staked
    function tokenIsAllowed(address _token) public returns (bool) {
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            if (allowedTokens[allowedTokensIndex] == _token) {
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