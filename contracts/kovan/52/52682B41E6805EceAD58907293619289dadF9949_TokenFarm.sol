/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;



// Part: OpenZeppelin/[email protected]/Context

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
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
        _transferOwnership(_msgSender());
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

// File: TokenFarm.sol

// -------------------------------- Contract------------------------------- //
contract TokenFarm is Ownable {
    // ---------------------------- Variables ----------------------------- //
    // This array is initialized and will store a list of tokens which can be staked to the
    // Token Farm.
    address[] public allowedTokens;

    // This array is initiallized and will store a list of everyone (by wallet address) who has
    // coins currently staked in the Token Farm.
    address[] public stakers;

    // This variable is initialized and will represent the DappTokens.
    IERC20 public dappToken;

    // ----------------------------- Mappings ----------------------------- //

    // This mapping stores the amount of each token a user has stored within
    // the Token Farm.
    mapping(address => mapping(address => uint256)) public stakingBalance;

    // This mapping associates a user's wallet address with the number of
    // unique tokens they have stored inside the TokenFarm.
    mapping(address => uint256) public uniqueTokensStaked;

    // This mapping associates a token to the contract address where it's
    // price feed information can be found.
    mapping(address => address) public tokenPriceFeedMapping;

    // ------------------------------ Events ------------------------------ //

    // ---------------------------- Contructor ---------------------------- //
    // Upon contract deployment this constructor stores the contract address
    // of the DappToken contract to the dappToken variable. This address must
    // be passed to the contract during deployment.
    constructor(address _dappTokenAddress) {
        dappToken = IERC20(_dappTokenAddress);
    }

    // ---------------------------- Functions ----------------------------- //

    /** 
    This function allows users to stake tokens to the TokenFarm. It
    requires that the tokens be in the allowedTokens array and that the user 
    sends at least 1 token. Once the token's are transferred 
    updateUniqueTokensStaked() is called to check if the user needs to be 
    added to the stakers array.
    
    Arguments: 
        _amount (uint256) - amount of tokens to be transferred into the 
        contract.
        _token (address) - the token being sent to this contract.
    */
    function stakeTokens(uint256 _amount, address _token) public {
        require(_amount > 0, "Must take more than 0 tokens.");
        require(tokenIsAllowed(_token), "Token is currently not allowed.");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokensStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] =
            stakingBalance[_token][msg.sender] +
            _amount;
        if (uniqueTokensStaked[msg.sender] == 1) {
            stakers.push(msg.sender);
        }
    }

    /** 
    This function withdraws all of a user's specified tokens from the 
    Token Farm. It requires that the user has atleast 1 of that token stored 
    within the cotract. It then remove's all of that user's token from the 
    stakingBalance and subtracts 1 from the uniquedTokensStaked for that user.
    
    Arguments: 
        _token (address) - the token which the user wishes to withdraw from 
        the Token Farm.
    */
    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Staking balance cannot be zero.");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokensStaked[msg.sender] -= 1;
    }

    /** 
    This function checks to see if a specific token is on the allowedTokens list.
    
    Arguments: 
        _token (address) - the token being checked.

    Returns:
        True - if token is on the list.
        False - if the token is not on the list.
    */
    function tokenIsAllowed(address _token) public view returns (bool) {
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

    /** 
    This function adds a specified token to the allowedTokens list.
    
    Arguments: 
        _token (address) - the token being sent to this contract.
    */
    function addAllowedToken(address _token) public onlyOwner {
        allowedTokens.push(_token);
    }

    /** 
    This function pays out Dapp Tokens to users based on the total value of 
    all their tokens.
    */
    function issueTokens() public onlyOwner {
        for (
            uint256 stakersIndex = 0;
            stakersIndex < stakers.length;
            stakersIndex++
        ) {
            address recipient = stakers[stakersIndex];
            uint256 userTotalValue = getUserTotalValue(recipient);
            dappToken.transfer(recipient, userTotalValue);
        }
    }

    /** 
    This function will check the stakingBalance to see if this user has any of
    _token currently staked in the Token Farm. If not then it will update the 
    uniqueTokensStaked list.
    
    Arguments:
        _user (address) - Wallet address of the user.
        _token (address) - The token which has been staked.
    */
    function updateUniqueTokensStaked(address _user, address _token) internal {
        if (stakingBalance[_token][_user] <= 0) {
            uniqueTokensStaked[_user] += 1;
        }
    }

    /** 
    This function returns the total value (in USD) a specific user has 
    currently staked in the Token Farm.
    
    Arguments: 
        _user (address) - Wallet address of the user.

    Returns:
        totalValue (uint256) - the total value (in USD) of the _user's staked 
        tokens.
    */
    function getUserTotalValue(address _user) public view returns (uint256) {
        uint256 totalValue = 0;
        require(uniqueTokensStaked[_user] > 0, "No tokens staked.");
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
        return totalValue;
    }

    /** 
    This function returns the total value a user has of the specified token.
    
    Arguments: 
        _user (address) - the wallet address of the user.
        _token (address) - the token which is having it's value calculated.

    Returns:
        (uint256) - the total value of the _user's _tokens.
    */
    function getUserSingleTokenValue(address _user, address _token)
        public
        view
        returns (uint256)
    {
        if (uniqueTokensStaked[_user] <= 0) {
            return 0;
        }
        (uint256 price, uint256 decimals) = getTokenValue(_token);
        return ((stakingBalance[_token][_user] * price) / (10**decimals));
    }

    /** 
    This function returns the current value (in USD) of a specified token as 
    well as that token's decimals value.
    
    Arguments: 
        _token (address) - the wallet address of the token being checked.

    Returns:
        price (uint256) - the value of this token in USD.
        decimals (uint256) - the number of decimal places for this token.
    */
    function getTokenValue(address _token)
        public
        view
        returns (uint256, uint256)
    {
        // Need a priceFeedAddress for each token.
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            priceFeedAddress
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        return (uint256(price), uint256(decimals));
    }

    /** 
    This function stores the contract address for the ChainLink PriceFeed of a
    specfic token in the tokenPriceFeedMapping. This is required for the 
    getTokenValue() function to work.
    
    Arguments: 
        _token (address) - the specific token.
        _priceFeed (address) - The contract address where the ChainLink Price 
        feed is located.
    */
    function setPriceFeedContract(address _token, address _priceFeed)
        public
        onlyOwner
    {
        tokenPriceFeedMapping[_token] = _priceFeed;
    }
}