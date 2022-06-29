//SPDX-License-Identifier: MIT

// stakeTokens
// unstakeTokens
// issueTokens
// addAllowedTokens
// getEthValue

pragma solidity ^0.8.0;

import "Ownable.sol";
import "AggregatorV3Interface.sol";
import "IERC20.sol";

contract TokenFarm is Ownable {
    
    IERC20 public daapToken ;
    address [] public allowedTokens;
    address [] public stakers;
    
    
    mapping (address => mapping (address => uint256)) public stakingBalance; //token => user => balance
    mapping (address => uint256) public uniqueTokenStaked; //how many diferent tokens each user has stacked
    mapping (address => address) public tokenPriceFeedMapping; 

    constructor (address _daapTokenAddress)  {
        daapToken =IERC20(_daapTokenAddress);
    }

    function setPriceFeedContract(address _token, address _priceFeed) public onlyOwner{
        tokenPriceFeedMapping[_token] = _priceFeed;
    }

    //function that sends tokens as a reward based on the tokens staked in the contract
    function issueTokens() public onlyOwner{
        for (uint256 i=0; i<stakers.length; i++){
            address recipient = stakers[i];
            uint256 userTotalValue = getUserTotalBalance(recipient);
            daapToken.transfer(recipient, userTotalValue);
        }

    }

    //function that returns the total balance of a single user for all its tokens
    function getUserTotalBalance(address _user) public view returns(uint256){
        uint256 totalValue = 0;
        require(uniqueTokenStaked[_user] > 0, "Not Tokens Staked");
        for (uint256 i=0; i<allowedTokens.length; i++){
            totalValue = totalValue + getUserSingleTokenValue(_user, allowedTokens[i]);
        }
        return totalValue;
    }
    //function that returns the total balance of a single user for a specific token
    function getUserSingleTokenValue(address _user, address _token) public view returns(uint256){
        if (uniqueTokenStaked[_user] <= 0)
            return 0;
        uint256 tokenBalance = stakingBalance[_token][_user];
        address priceFeedAddress = tokenPriceFeedMapping[_token];
        
        AggregatorV3Interface priceFeed = AggregatorV3Interface(priceFeedAddress);
        (,int price,,,) = priceFeed.latestRoundData();
        uint256 decimals = priceFeed.decimals();
        //DAI/ETH = price
        uint256 convertedTokenBalance = (tokenBalance * uint256(price)) / (10**decimals);
        return convertedTokenBalance;
    }

    function stakeTokens(address _token, uint256 _amount) public payable {
        //what tokens can be staked
        require(_amount > 0, "Amount must be greater than 0");
        require (tokenIsAllowed(_token), "Token is currently not allowed");
        IERC20(_token).approve(msg.sender, _amount);
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        updateUniqueTokenStaked(msg.sender, _token);
        stakingBalance[_token][msg.sender] = stakingBalance[_token][msg.sender] + _amount;
        if (uniqueTokenStaked[msg.sender] == 1) //first token staked by user
            stakers.push(msg.sender);
    }

    function unstakeTokens(address _token) public {
        uint256 balance = stakingBalance[_token][msg.sender];
        require(balance > 0, "Not token staked");
        IERC20(_token).transfer(msg.sender, balance);
        stakingBalance[_token][msg.sender] = 0;
        uniqueTokenStaked[msg.sender] = uniqueTokenStaked[msg.sender] -1;
    
    }

    //check if the user has already staked that token and if so add to the list of number of staked tokens
    function updateUniqueTokenStaked(address _sender, address _token) internal {
        if(stakingBalance[_token][_sender] <=0 ){
            uniqueTokenStaked[_sender] = uniqueTokenStaked[_sender] + 1;
        }
    }
    
    function addAllowedToken(address _token) public onlyOwner{
        allowedTokens.push(_token);
    }

    function tokenIsAllowed(address _token) public returns (bool){
        for (uint256 i=0; i < allowedTokens.length; i++)
            if (allowedTokens[i] == _token)
                return true;
        return false;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

pragma solidity ^0.8.0;

interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256 remaining);
  function approve(address spender, uint256 value) external returns (bool success);
  function balanceOf(address owner) external view returns (uint256 balance);
  function decimals() external view returns (uint8 decimalPlaces);
  function name() external view returns (string memory tokenName);
  function symbol() external view returns (string memory tokenSymbol);
  function totalSupply() external view returns (uint256 totalTokensIssued);
  function transfer(address to, uint256 value) external returns (bool success);
  function transferFrom(address from, address to, uint256 value) external returns (bool success);
  function deposit() external;
  function withdraw(uint wad) external;
}