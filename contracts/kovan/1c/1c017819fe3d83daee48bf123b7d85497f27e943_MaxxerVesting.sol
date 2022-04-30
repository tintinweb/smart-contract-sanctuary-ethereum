/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity ^0.5.3;

/**
* @title ERC223Interface
* @dev ERC223 Contract Interface
*/
contract ERC223Interface {
    function balanceOf(address who)public view returns (uint);
    function transfer(address to, uint value)public returns (bool success);
    function transfer(address to, uint value, bytes memory data)public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint value);
}

/// @title Interface for the contract that will work with ERC223 tokens.
interface ERC223ReceivingContract {
    /**
     * @dev Standard ERC223 function that will handle incoming token transfers.
     *
     * @param _from  Token sender address.
     * @param _value Amount of tokens.
     * @param _data  Transaction data.
     */
    function tokenFallback(address _from, uint _value, bytes calldata _data) external;
}

library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

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
contract Context {
    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes  memory) {
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() public  {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
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
    function renounceOwnership() public  onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public  onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract MaxxerVesting is ERC223ReceivingContract,Ownable {
    using SafeMath for uint256;

    /**
     * Address of MaxxerToken smart contract.
     */
    address public maxxerToken;

    /**
     * Founder receiving wallet address.
     */
    address public FOUNDERS_ADDRESS;

    /**
     * Advisors receiving wallet address.
     */
    address public ADVISORS_ADDRESS;

    /**
     * Team receiving wallet address.
     */
    address public TEAM_ADDRESS;

    /**
     * Total Amount of tokens for Founders.
     */
    uint256 constant public FOUNDERS_TOTAL_TOKEN = 270000000 * 10**18;

    /**
     * Total Amount of tokens for Advisors.
     */
    uint256 constant public ADVISORS_TOTAL_TOKEN = 36000000 * 10**18;

    /**
     * Total Amount of tokens for Team.
     */
    uint256 constant public TEAM_TOTAL_TOKEN = 54000000 * 10**18;

    /**
     * Amount of tokens already sent to Founder receiving wallet.
     */
    uint256 public FOUNDERS_TOKEN_SENT;

    /**
     * Amount of tokens already sent to Advisors receiving wallet.
     */
    uint256 public ADVISORS_TOKEN_SENT;

    /**
     * Amount of tokens already sent to Team receiving wallet.
     */
    uint256 public TEAM_TOKEN_SENT;

    /**
     * Starting timestamp of the first stage of vesting (Wednesday, June 15, 2022 0:00:01 AM).
     * Will be used as a starting point for all dates calculations.
     */
    uint256 public VESTING_START_TIMESTAMP;

    /**
     * Tokens vesting stage structure with vesting date and tokens allowed to unlock.
     */
    struct VestingStage {
        uint256 date;
        uint256 foundersTokensUnlocked;
        uint256 advisorsTokensUnlocked;
        uint256 teamTokensUnlocked;
    }

    /**
     * Array for storing all vesting stages with structure defined above.
     */
    VestingStage[36] public stages;

    event Withdraw(address _to, uint256 _value);

    constructor (address _maxxerToken,uint256 _vestingStartTimestamp, address _foundersAddress,address _advisorsAddress,address _teamAddress) public {
        maxxerToken = _maxxerToken;
        VESTING_START_TIMESTAMP=_vestingStartTimestamp;
        FOUNDERS_ADDRESS=_foundersAddress;
        ADVISORS_ADDRESS=_advisorsAddress;
        TEAM_ADDRESS=_teamAddress;
        initVestingStages();
    }

    /**
     * Setup array with vesting stages dates and token amounts.
     */
    function initVestingStages () internal {
        uint256 month = 10 minutes;

        stages[0].date = VESTING_START_TIMESTAMP;
        stages[0].foundersTokensUnlocked = 67500010 * 10**18;
        stages[0].advisorsTokensUnlocked = 9000020 * 10**18;
        stages[0].teamTokensUnlocked = 13500030 * 10**18;

        for (uint8 i = 1; i < 36; i++) {
                stages[i].date = stages[i-1].date + month;
                stages[i].foundersTokensUnlocked = stages[i-1].foundersTokensUnlocked.add(5785714 * 10**18);
                stages[i].advisorsTokensUnlocked = stages[i-1].advisorsTokensUnlocked.add(771428 * 10**18);
                stages[i].teamTokensUnlocked = stages[i-1].teamTokensUnlocked.add(1157142 * 10**18);
        }
    }

    function tokenFallback(address, uint _value, bytes calldata) external {
        require(msg.sender == maxxerToken);
        uint256 TOTAL_TOKENS = FOUNDERS_TOTAL_TOKEN.add(ADVISORS_TOTAL_TOKEN).add(TEAM_TOTAL_TOKEN);
        require(_value == TOTAL_TOKENS);
    }

    /**
     * Method for Founders withdraw tokens from vesting.
     */
    function withdrawFoundersToken () external onlyOwner {
        uint256 tokensToSend = getAvailableTokensOfFounders();
        require(tokensToSend > 0,"Vesting: No withdrawable tokens available.");
        sendTokens(FOUNDERS_ADDRESS,tokensToSend);
    }

    /**
     * Method for Advisors withdraw tokens from vesting.
     */
    function withdrawAdvisorsToken () external onlyOwner {
        uint256 tokensToSend = getAvailableTokensOfAdvisors();
        require(tokensToSend > 0,"Vesting: No withdrawable tokens available.");
        sendTokens(ADVISORS_ADDRESS,tokensToSend);
    }

    /**
     * Method for Team withdraw tokens from vesting.
     */
    function withdrawTeamToken () external onlyOwner {
        uint256 tokensToSend = getAvailableTokensOfTeam();
        require(tokensToSend > 0,"Vesting: No withdrawable tokens available.");
        sendTokens(TEAM_ADDRESS,tokensToSend);
    }

    /**
     * Calculate tokens amount that is sent to Founder wallet Address.
     *
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfFounders () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(FOUNDERS_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(FOUNDERS_ADDRESS,tokensUnlocked);
    }

    /**
     * Calculate tokens amount that is sent to Advisor wallet Address.
     *
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfAdvisors () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(ADVISORS_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(ADVISORS_ADDRESS,tokensUnlocked);
    }

    /**
     * Calculate tokens amount that is sent to Team wallet Address.
     *
     * @return Amount of tokens that can be sent.
     */
    function getAvailableTokensOfTeam () public view returns (uint256 tokensToSend) {
        uint256 tokensUnlocked = getTokensUnlocked(TEAM_ADDRESS);
        tokensToSend = getTokensAmountAllowedToWithdraw(TEAM_ADDRESS,tokensUnlocked);
    }

    /**
     * Get tokens unlocked on current stage.
     *
     * @return Tokens allowed to be sent.
     */
    function getTokensUnlocked (address role) private view returns (uint256) {
        uint256 allowedTokens;

        for (uint8 i = 0; i < stages.length; i++) {
            if (now >= stages[i].date) {
                if(role == FOUNDERS_ADDRESS){
                    allowedTokens = stages[i].foundersTokensUnlocked;
                } else if(role == ADVISORS_ADDRESS){
                    allowedTokens = stages[i].advisorsTokensUnlocked;
                } else if(role == TEAM_ADDRESS){
                    allowedTokens = stages[i].teamTokensUnlocked;
                }
            }
        }

        return allowedTokens;
    }

    /**
     * Calculate tokens available for withdrawal.
     *
     * @param role Role address for which you want the amount of tokens.
     *
     * @param tokensUnlocked Percent of tokens that are allowed to be sent.
     *
     * @return Amount of tokens that can be sent according to provided role and tokensUnlocked.
     */
    function getTokensAmountAllowedToWithdraw (address role,uint256 tokensUnlocked) private view returns (uint256) {
        uint256 unsentTokensAmount;
        if(role == FOUNDERS_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(FOUNDERS_TOKEN_SENT);
        } else if(role == ADVISORS_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(ADVISORS_TOKEN_SENT);
        } else if(role == TEAM_ADDRESS){
            unsentTokensAmount = tokensUnlocked.sub(TEAM_TOKEN_SENT);
        }
        return unsentTokensAmount;
    }

    /**
     * Send tokens to given address.
     */
    function sendTokens (address role,uint256 tokensToSend) private {
        if (tokensToSend > 0) {
            if(role == FOUNDERS_ADDRESS){
                // Updating tokens sent counter
                FOUNDERS_TOKEN_SENT = FOUNDERS_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(FOUNDERS_ADDRESS, tokensToSend);
                emit Withdraw(FOUNDERS_ADDRESS,tokensToSend);
            } else if(role == ADVISORS_ADDRESS){
                // Updating tokens sent counter
                ADVISORS_TOKEN_SENT = ADVISORS_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(ADVISORS_ADDRESS, tokensToSend);
                emit Withdraw(ADVISORS_ADDRESS,tokensToSend);
            } else if(role == TEAM_ADDRESS){
                // Updating tokens sent counter
                TEAM_TOKEN_SENT = TEAM_TOKEN_SENT.add(tokensToSend);
                // Sending allowed tokens amount
                ERC223Interface(maxxerToken).transfer(TEAM_ADDRESS, tokensToSend);
                emit Withdraw(TEAM_ADDRESS,tokensToSend);
            }
        }
    }
}