//TODO:
// - reset lock after 10 claims
// - finish tests

// SPDX-License-Identifier: MIT
//
//--------------------------
// 44 65 66 69 4d 6f 6f 6e
//--------------------------
//
// Syndiqate ICO seed round contract
// [+] Ownable
// [+] ERC20 interface
// [+] Accepts payment in USDT
// [+] Tokens timelocked with release over 10 months
//
// UI:
//
// - Is round active ==========================================> [bool]    isActive
// - Round end date ===========================================> [uint256] ROUND_END_DATE
// - Tokens left ==============================================> [uint256] availableTreasury
// - Return user liquid balance ===============================> [uint256] users[msg.sender].liquidBalance
// - Pending for claim for user ===============================> [uint256] users[msg.sender].pendingForClaim
// - Next unlock date for user ================================> [uint256] users[msg.sender].nextUnlockDate
// - Check allowance ==========================================> [uint256] USDT.allowance(msg.sender, address(this))
// - Buy tokens (recieve in USDT, input amount in Token) =======>           buyToken(uint256 _amount)
// - Check if user tokens unlocked and transfer them to user ==>           claimTokens()
// - Set allowance ============================================> call USDT contract from website directly
//                                                       approve amount = 200000000000000000000000000 wei
//                                                       this is WEI too much (🤡) but we'll never spend
//                                                       more than 50k, this allows us to track
//                                                       Token purchase amount limits
//
// DEPLOYMENT:
//
// - Deploy Token token
// - Deploy SeedRound, pass Token && USDT token addresses to constructor

pragma solidity ^0.8.4;

import "../libs/@openzeppelin/contracts/access/Ownable.sol";
import "../libs/@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/ITOKEN.sol";

contract Round is Ownable {

  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- ROUND PARAMETERS
  // -------------------------------------------------------------------------------------------------------

  // @notice                            round conditions
  uint256 constant public               ROUND_FUND = 30000000 ether;
  uint256 constant public               TOKEN_PRICE_USDT = 17;                // 0.017 usdt
  uint256 constant public               MIN_PURCHASE_AMOUNT = 588 ether;      // 10 usdt
  uint256 constant public               ROUND_START_DATE = 1657324800;        // 09.07.22 00:00
  //uint256 constant public               ROUND_END_DATE =   33315018412;       // 18.07.22 00:00
  //uint256 constant public               LOCK_PERIOD = 30 days;
  uint256 constant public               CLAIM_PERCENT = 10;
  uint8 constant public                 NUM_CLAIMS = 10;                      // 10 claims to be performed in total

  /////////////////// !!!!!! FOR TESTING ONLY REMOVE BEFORE DEPLOY !!!!!! ///////////////////
  uint256 public               LOCK_PERIOD = 0;
  function longLock() external onlyOwner() {
    LOCK_PERIOD = 2 seconds;
  }
  function noLock() external onlyOwner() {
    LOCK_PERIOD = 0;
  }

  uint256 public ROUND_END_DATE = 33315018412;
  function expired() external onlyOwner() {
    ROUND_END_DATE = 1657324800;
  }
  function active() external onlyOwner() {
    ROUND_END_DATE = 33315018412;
  }

  function getAvailableTreasury() public view returns(uint256) {
    return(availableTreasury);
  }
  /////////////////// !!!!!! FOR TESTING ONLY REMOVE BEFORE DEPLOY !!!!!! ///////////////////

  // @notice                            token interfaces
  address public                        TokenAddress;
  address public                        usdtAddress;
  IToken                                TOKEN;
  IERC20                                USDT;

  // @notice                            round state
  uint256 public                        availableTreasury = ROUND_FUND;
  bool    public                        isActive;




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- USER MANAGMENT
  // -------------------------------------------------------------------------------------------------------

  // @notice                            user state structure
  struct                                User {
    uint256                             totalTokenBalance;  // total num of tokens user have bought through the contract
    uint256                             tokensToIssue;      // num of tokens user have bought in current vesting period (non complete unlock cycle)
    uint256                             liquidBalance;      // amount of tokens the contract already sent to user
    uint256                             pendingForClaim;    // amount of user's tokens that are still locked
    uint256                             nextUnlockDate;     // unix timestamp of next claim unlock (defined by LOCK_PERIOD)
    uint16                              numUnlocks;         // 10 in total
    bool                                isLocked;           // are tokens currently locked
    uint256                             initialPayout;      // takes into account 10% initial issue
    bool                                hasBought;          // used in token purchase mechanics
  }

  // @notice                            keeps track of users
  mapping(address => User) public       users;
  address[] public                      icoTokenHolders;




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- EVENTS
  // -------------------------------------------------------------------------------------------------------

  event                                 TokenPurchased(address indexed user, uint256 amount);
  event                                 TokenClaimed(address indexed user,
                                                    uint256 amount,
                                                    uint256 claimsLeft,
                                                    uint256 nextUnlockDate);




  // FUNCTIONS
  //
  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Constructor
  // -------------------------------------------------------------------------------------------------------

  // @param                             [address] Token => Token token address
  // @param                             [address] usdt => USDT token address
  constructor(address token, address usdt) {
    TokenAddress = token;
    usdtAddress = usdt;
    TOKEN = IToken(token);
    USDT = IERC20(usdt);
    TOKEN.grantManagerToContractInit(address(this), ROUND_FUND);
    isActive = true;
  }




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Modifiers
  // -------------------------------------------------------------------------------------------------------

  // @notice                            checks if tokens could be sold
  // @param                             [uint256] amount => amount of tokens to sell
  modifier                              areTokensAvailable(uint256 amount) {
    require(amount >= MIN_PURCHASE_AMOUNT,
                      "Lower than min purchase amount!");
    require(availableTreasury - amount >= 0,
                      "Not enough tokens left!");
    _;
  }

  // @notice                            checks whether user's tokens are locked
  modifier                              checkLock() {
    require(users[msg.sender].pendingForClaim > 0,
                                      "Nothing to claim!");
    require(block.timestamp >= users[msg.sender].nextUnlockDate,
                                      "Tokens are still locked!");
    users[msg.sender].isLocked = false;
    _;
  }

  // @notice                            checks if round is active
  modifier                              ifActive() {
    if ((block.timestamp < ROUND_START_DATE) || (block.timestamp > ROUND_END_DATE) || availableTreasury == 0) {
      isActive = false;
      revert("Round is not active!");
    }
    isActive = true;
    _;
  }

  // @notice                            checks if round is inactive
  modifier                              ifInactive() {
    if (block.timestamp <= ROUND_END_DATE && availableTreasury > 0) {
      isActive = true;
      revert("Round is still active!");
    }
    isActive = false;
    _;
  }




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- ICO logic
  // -------------------------------------------------------------------------------------------------------

  // @notice                            checks if tokens are unlocked and transfers 10% from pendingForClaim
  //                                    user will recieve all remaining tokens with the last (9th) claim
  function                              claimTokens() public checkLock() {
    address                             user = msg.sender;
    User  storage                       userStruct = users[user];
    uint256                             amountToClaim;

    require(userStruct.isLocked == false, "Tokens are locked!");
    if (userStruct.numUnlocks < NUM_CLAIMS) {
      amountToClaim = (userStruct.tokensToIssue / 100) * CLAIM_PERCENT;
    }
    else {
      revert("Everything is already claimed!");
    }
    userStruct.isLocked = true;
    TOKEN.mint(user, amountToClaim);
    userStruct.liquidBalance += amountToClaim;
    userStruct.pendingForClaim -= amountToClaim;
    userStruct.nextUnlockDate += LOCK_PERIOD;
    userStruct.numUnlocks += 1;

    emit TokenClaimed(user,
                     amountToClaim,
                     NUM_CLAIMS - userStruct.numUnlocks, // number of claims left to perform
                     userStruct.nextUnlockDate);
  }

  // @notice                            allows to purchase Token tokens
  // @param                             [uint256] _amount => amount of Token tokens to purchase
  function                              buyTokens(uint256 _amount) public areTokensAvailable(_amount) ifActive {
    address                             user = msg.sender;
    uint256                             priceUSDT = _amount / 1000 * TOKEN_PRICE_USDT;

    require(USDT.allowance(msg.sender, address(this)) >= _amount,
                      "Not enough allowance, approve your USDT first!");
    require(USDT.balanceOf(user) >= priceUSDT, "Not enough USDT tokens!");
    require(USDT.transferFrom(user, address(this), priceUSDT) == true, "Failed to transfer USDT!");
    _lockAndDistribute(_amount, msg.sender);
    emit TokenPurchased(msg.sender, _amount);
  }

  // @notice                            when user buys Token, 10% is issued immediately
  //                                    remaining tokens are locked for 6 * LOCK_PERIOD = 18 months
  // @param                             [uint256] amount => amount of Token tokens to distribute
  // @param                             [address] _to => address to issue tokens to
  function                              _lockAndDistribute(uint256 _amount, address _to) private {
    User  storage                       userStruct = users[_to];
    uint256                             timestampNow = block.timestamp;

    if (!userStruct.hasBought || userStruct.numUnlocks == NUM_CLAIMS) {     // initial 10% will be issued only on first buy
      uint256 immediateAmount = (_amount / 100) * CLAIM_PERCENT;
      TOKEN.mint(_to, immediateAmount);                                     // issue 10% immediately
      userStruct.initialPayout += immediateAmount;
      userStruct.liquidBalance += immediateAmount;                          // issue 10% immediately to struct
      userStruct.pendingForClaim += _amount - immediateAmount;              // save the rest
      userStruct.tokensToIssue = _amount - immediateAmount;
      if (!userStruct.hasBought) {
        icoTokenHolders.push(_to);
        userStruct.hasBought = true;
      }
      if (userStruct.numUnlocks == NUM_CLAIMS) {
        userStruct.numUnlocks = 0;
      }
    }
    else {
      uint256 perClaimOld = ((userStruct.totalTokenBalance - userStruct.initialPayout) / 100) * CLAIM_PERCENT;
      uint256 perClaimNew = ((userStruct.totalTokenBalance + _amount - userStruct.initialPayout) / 100) * CLAIM_PERCENT;
      uint256 difference = (perClaimNew * userStruct.numUnlocks) - (perClaimOld * userStruct.numUnlocks);
      TOKEN.mint(_to, difference);                                          // compensate the difference
      userStruct.pendingForClaim += _amount - difference;
      userStruct.tokensToIssue += _amount;
    }

    userStruct.totalTokenBalance += _amount;
    availableTreasury -= _amount;
    userStruct.nextUnlockDate = timestampNow + LOCK_PERIOD;                 // lock for 10 months
    userStruct.isLocked = true;
  }

  // @notice                            allows admin to issue tokens with vesting rules to address
  // @param                             [uint256] _amount => amount of Token tokens to issue
  // @param                             [address] _to => address to issue tokens to
  function                              issueTokens(uint256 _amount, address _to) public areTokensAvailable(_amount) onlyOwner {
    _lockAndDistribute(_amount, _to);
    emit TokenPurchased(_to, _amount);
  }




  // -------------------------------------------------------------------------------------------------------
  // ------------------------------- Admin
  // -------------------------------------------------------------------------------------------------------

  // @notice                            allows to withdraw raised funds (USDT)
  // @param                             [address] _reciever => wallet to send tokens to
  function                              withdrawRaisedFunds(address _reciever) public onlyOwner {
    uint256                             balance = USDT.balanceOf(address(this));

    USDT.transfer(_reciever, balance);
  }

  // @notice                            allows to withdraw remaining tokens after the round end
  // @param                             [address] _reciever => wallet to send tokens to
  function                              withdrawRemainingToken(address _reciever) public onlyOwner ifInactive {
    TOKEN.mint(_reciever, availableTreasury);
    availableTreasury = 0;
  }

  // @notice                            checks if round still active
  function                              checkIfActive() public returns(bool) {
    if ((block.timestamp <= ROUND_START_DATE) || (block.timestamp >= ROUND_END_DATE) || availableTreasury == 0) {
      isActive = false;
    }
    if (block.timestamp > ROUND_START_DATE && block.timestamp < ROUND_END_DATE && availableTreasury > 0) {
      isActive = true;
    }
    return(isActive);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
//
//--------------------------
// 5F 30 78 30 30 6C 61 62
//--------------------------
//
// Token contract interface

pragma solidity ^0.8.4;

interface IToken {
  function        balanceOf(address account) external view returns (uint256);
  function        transfer(address to, uint256 amount) external returns (bool);
  function        transferFrom(address from,
                               address to,
                               uint256 amount
                               ) external returns (bool);
  function        approve(address spender, uint256 amount) external returns (bool);
  function        allowance(address owner, address spender) external view returns (uint256);
  function        grantManagerToContractInit(address account, uint256 amount) external;
  function        revokeManagerAfterContractInit(address account) external;
  function        mint(address to, uint256 amount) external;
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