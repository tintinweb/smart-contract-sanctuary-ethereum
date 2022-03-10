//we want to do:
//  - stake tokens
//  - unstake tokens
//  - issue tokens
//  - add allowed tokens
//  - getEthValue : get the value of the underlying staked tokens
//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0; //since we are using 0.8,

//we don't need to worry about safeMath
//when using ownable/onlyOwner, import:
import "Ownable.sol";
//need the interface, because we don't need the whole contract
import "IERC20.sol";
import "AggregatorV3Interface.sol";

contract TokenFarm is Ownable {
    //mapping to keep track of how much tokens each person sent here
    //map token address -->staker address -->amount
    //how much of each token, each staker has staked
    //mapping(token_address=>mapping(user_address=>uint256))
    mapping(address => mapping(address => uint256)) public stakingBalance;
    //how many different tokens each one of these addresses has staked
    mapping(address => uint256) public uniqueTokensStaked;
    mapping(address => address) public tokenPriceFeedMapping;
    address[] public allowedTokens; //this is a list of all the allowed tokens
    //a list of all stakers on my platform;
    address[] public stakers;
    IERC20 public dappToken;

    //we need to know the address of the Dapp Token
    //store the Dapp Token as a global variable
    constructor(address _dappTokenAddress) public {
        dappToken = IERC20(_dappTokenAddress);
    }

    //set the price feed associated with the token
    //we don't want anybody to set what these price feeds should be
    //we just want the owner to do this
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    function stakeTokens(uint256 _amount, address _token) public {
        //some amount of some token
        //what tokens can they stake?
        //how much can they stake? YOu can stake any amount greater than 0
        require(_amount > 0, "Amount must be more than 0.");
        //only want certain specific tokens to be staked on my platform
        require(tokenIsAllowed(_token), "Token is currently not allowed.");

        //ERC20 transfer(): can only be called from the wallet who owns the tokens
        //ERC20 transferFrom(): can be called from any wallet that does not own the tokens
        //my TokenFarm contract is not the one who owns the tokens
        //also need the abi to use the transfer function, therefore need the IERC20 Interface
        //IERC20(_token) is the ABI
        //address(this) : send the tokens to this TokenFarm address
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);

        //when somebody stakes a token, update my stakers list. only add to the list if they are not already on the list
        updateUniqueTokensStaked(msg.sender, _token); //how many unique tokens each user has

        //need to keep track of how much of these tokens they have actually sent us
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        //the above allows uers to stake tokens on my platform
        if (uniqueTokensStaked[msg.sender] == 1) {
            //if the current token is the user's first token, then add the user to the staker's list
            stakers.push(msg.sender);
        }
    }

    //anybody can call this
    function unstakeTokens(address _token) public {
        //fetch the staking balance
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be 0.");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        //is this vulnerable to re-entrancy attack
        uniqueTokensStaked[msg.sender] = uniqueTokensStaked[msg.sender] - 1;
    }

    //internal: only this contract can call this function
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] = uniqueTokensStaked[_user] + 1;
        }
    }

    //issue rewards to users who use my platform
    //issue tokens based on the value of the underlying tokens
    //that the user gives me
    //a user deposits 100 ETH :
    //1:1, for every 1 ETH, we give 1 DAPP token.
    //50 ETh and 50 Dai staked, we want to give a reward of 1DAPP /1DAI
    //the function can only be called by the owner or the admin of the contract

    function issueTokens() public onlyOwner {
        //issue tokens to all stakers
        //loop through the list of stakers
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            // send them a token reward (the Dapp Token)
            dappToken.transfer(recipient, userTotalValue); //issue 1:1 reward to users

            // based on their total value locked
        }
    }

    //find how much each of these tokens actulaly has
    //a lot of protocols allow people to claim their tokens, instead of issuing tokens
    //it is a lot more gas efficient to have users claim the airdropped, instead of the application issuing tokens
    //it is gas expensive to loop through all addresses and check all addresses
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked!");
        for (
            uint256 allowedTokensIndex = 0;
            allowedTokensIndex < allowedTokens.length;
            allowedTokensIndex++
        ) {
            totalValue =
                totalValue +
                getUserSingleTOkenValue(
                    _user,
                    allowedTokens[allowedTokensIndex]
                );
        }
        return totalValue;
    }

    function getUserSingleTOkenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        //if the user stakes 1ETH, and the price of 1ETH is $2K, this will return 2K
        //or if the user stakes 200 Dai, ->$200, this will return 200
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        //get the value of a single token
        //price of the token * stakingbalance[_token][_user]
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        //this is where we need some price information
        //work with chainlink price feed
        //need a priceFeedAddress, map each token to its price feed address
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        //use AggregatorV3Interface
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        //need to know how many deciamls that the price feed has, so that i can match up using the same units
        uint256 decimals = uint256(priceFeed.decimals());
        return (uint256(price), decimals);
    }

    //only the admin wallet or hte owner of this contract can do
    function addAllowedTokens(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool) {
        //loop through the list of allowed tokens
        for (
            uint256 allowedTokenIndex = 0;
            allowedTokenIndex < allowedTokens.length;
            allowedTokenIndex++
        ) {
            if (allowedTokens[allowedTokenIndex] == _token) {
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