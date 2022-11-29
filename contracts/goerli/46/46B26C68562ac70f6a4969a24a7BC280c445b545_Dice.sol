// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Dice is ReentrancyGuard {

  uint256 private constant MULTIPLIER_POINT = 9850; //98.50
  uint256 public currentBetId;
  uint256 private maxBet = 500 * 10 ** 18;
  uint256 private seedWord;
  address public owner;

  struct UserBet {
    uint256 time;
    address bettorAddress;
    uint256 betAmount;
    uint256 sliderValue;
    uint256 multiplier;
    uint256 randomNumber;
    uint256 winningAmount;
    bool isRollOver;
    bool isEther;
    address tokenAddress;
  }

  mapping(uint256 => UserBet) public betIdToBets;
  mapping(address => bool) public whitelistedTokens;
  mapping(address => uint256) public winningsInEther;
  mapping(address => mapping(address => uint256)) public winningsInToken;
  mapping(address => bool) public isWhitelistedMember; 

  event BetPlacedInEther(
    uint256 _betId,
    uint256 _time,
    address _userAddress,
    uint256 _betAmount,
    uint256 _sliderValue,
    uint256 _multiplier,
    bool _isRollOver,
    bool _isEther
  );

  event BetPlacedInToken(
    uint256 _betId,
    uint256 _time,
    address _userAddress,
    address _tokenAddress,
    uint256 _betAmount,
    uint256 _sliderValue,
    uint256 _multiplier,
    bool _isRollOver,
    bool _isEther
  );

  event DiceRolled(uint256 indexed _betId, uint256 indexed _randomValue, uint256 indexed _winningAmount);
  event EthWithdrawn(address indexed player, uint256 indexed amount);
  event TokenWithdrawn(address indexed player, address indexed tokenAddress, uint256 indexed amount);
  event Received(address _sender, uint256 indexed _message);

 constructor(uint256 seed) {
  owner = msg.sender;
  seedWord = seed;
}


 modifier whitelisted() {
  require(isWhitelistedMember[msg.sender] || msg.sender == owner, 'not allowed to call this function');
_;
 }
  
  /** 
   * @notice calls requestRandomWords function.
   * @dev For placing the bet on dice.
   * @param sliderValue to choose the slider value while placing bet. 
   * @param isRollOver whether the user wants to roll over or roll under the chosen slider value.
   */
  function placeBet(address ERC20Address, uint amount, bool isEther, uint8 sliderValue, bool isRollOver) external payable {

    if (isRollOver) {
        require(
          sliderValue > 4 && sliderValue < 100,
          'Invalid Slider Value'
        );
      } else {
        require(sliderValue > 1 && sliderValue < 97, 'Invalid Slider Value');
      }

      uint256 _multiplier; 
      _multiplier = _calcMultiplier(sliderValue, isRollOver);

    //when paying with ERC20 Token
    if(isEther == false){
      require(whitelistedTokens[ERC20Address] == true, 'Token not allowed for placing bet');
      require(amount > 0, 'Bet Value should be greater than 0');
      require(amount <= maxBet, 'Bet Value should be less than 500');

      placedBet(sliderValue, isRollOver);

      IERC20(ERC20Address).transferFrom(msg.sender, address(this), amount);

      UserBet storage b = betIdToBets[currentBetId];
      b.betAmount = amount;
      b.multiplier = _multiplier;
      b.isEther = false;
      b.tokenAddress = ERC20Address;

      emit BetPlacedInToken(
        currentBetId,
        block.timestamp,
        msg.sender,
        ERC20Address,
        msg.value,
        sliderValue,
        _multiplier,
        isRollOver,
        false
      );
      }

      //when paying with Ether
      else {
        require(msg.value > 0, 'Bet Value should be greater than 0');
        require(msg.value <= maxBet, 'Bet Value should be less than 500');
        placedBet(sliderValue, isRollOver);

        UserBet storage b = betIdToBets[currentBetId];
        b.betAmount = msg.value;
        b.multiplier = _multiplier;
        b.isEther = true;
        b.tokenAddress = address(0);

        emit BetPlacedInEther(
          currentBetId,
          block.timestamp,
          msg.sender,
          msg.value,
          sliderValue,
          _multiplier,
          isRollOver,
          true
        );
      }
      _checkWinner(currentBetId);
  }

//Internal function that will be called by placeBet function. Used for updating UserBet struct.
function placedBet(uint8 _sliderValue, bool _isRollOver) internal {
      currentBetId = _inc(currentBetId);
      UserBet storage b = betIdToBets[currentBetId];
      b.time = block.timestamp;
      b.bettorAddress = msg.sender;
      b.sliderValue = _sliderValue;
      b.isRollOver = _isRollOver;
  }

   /*
  This function is used while adding allowed assets for placing bet on roll dice.
  Reverts if the token is already whitelisted.
  Can only be called by the owner.
  */ 
  function addWhitelistTokens(address ERC20Address) external whitelisted {
    require(whitelistedTokens[ERC20Address] == false, 'Token already whitelisted');
    whitelistedTokens[ERC20Address] = true;
  }

   /*
  This function is used while removing allowed assets for placing bet on roll dice.
  Reverts if the token is not whitelisted.
  Can only be called by the owner.
  */ 
  function removeWhitelistTokens(address ERC20Address) external whitelisted {
    require(whitelistedTokens[ERC20Address] == true, 'Token is not whitelisted');
    whitelistedTokens[ERC20Address] = false;
  }

  /*
  Internal function used for calculating multiplier based off the slider value.
  It is called in placeBet function.
  */
  function _calcMultiplier(uint8 _sliderValue, bool _isRollOver)
    internal
    pure
    returns (uint256)
  {
    if (_isRollOver) {
      return (MULTIPLIER_POINT / (100 - _sliderValue));
    } else {
      return (MULTIPLIER_POINT / (_sliderValue - 1));
    }
  }

  /*
   Checks if the user wins the dice based on the _requestId. It is called by the 
   fulfillRandomWords function. When it generates random number, it will check whether 
   the user has won the bet based on the random number generated, and transfers the
   winning amount if user won. Reverts if the contract do not have enough balance.
   */
  function _checkWinner(uint256 betId) internal {
    uint256 _winningAmount;
    UserBet storage bet = betIdToBets[betId];
    uint256 _multiplier = bet.multiplier;
    uint256 _randomNumber = ((uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,msg.sender,betId,_multiplier,seedWord)))+ 1) % 100) + 1;
    bet.randomNumber = _randomNumber;
    uint256 _sliderValue = bet.sliderValue;
    address _tokenAddress = bet.tokenAddress;

    if (bet.isRollOver && _randomNumber > _sliderValue) {
      _winningAmount = (bet.betAmount * _multiplier) / 100;
      betIdToBets[betId].winningAmount = _winningAmount;
    } else if ((!bet.isRollOver) && _randomNumber < _sliderValue) {
      _winningAmount = (bet.betAmount * _multiplier) / 100;
      betIdToBets[betId].winningAmount = _winningAmount;
    }

    if(bet.isEther) {
        winningsInEther[msg.sender] += _winningAmount;
    }
    else {
        winningsInToken[msg.sender][_tokenAddress] += _winningAmount;
    }
    emit DiceRolled(betId, _randomNumber, _winningAmount);
  }

  //Checks the balance of the contract
  function ReserveInEther() public view returns (uint256) {
    return address(this).balance;
  }

  //Checks ERC20 Token balance.
  function ReserveInToken(address ERC20Address) public view returns(uint) {
    return IERC20(ERC20Address).balanceOf(address(this));
  }

  function addWhitelistMembers(address member) external whitelisted {
    require(msg.sender == owner, "only owner can call this function");
    isWhitelistedMember[member] = true;
  }

    //Allows users to withdraw their Ether winnings.
  function withdrawEtherWinnings(uint256 amount) external nonReentrant {
    require(winningsInEther[msg.sender] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInEther() >= amount,'Sorry, Contract does not have enough reserve');
    winningsInEther[msg.sender] -= amount;
    payable(msg.sender).transfer(amount);
    emit EthWithdrawn(msg.sender, amount);
  }

  //Allows users to withdraw their ERC20 token winnings
  function withdrawTokenWinnings(address ERC20Address, uint256 amount) external nonReentrant {
    require(winningsInToken[msg.sender][ERC20Address] >= amount, "You do not have requested winning amount to withdraw");
    require(ReserveInToken(ERC20Address) >= amount,'Sorry, Contract does not have enough reserve');
    winningsInToken[msg.sender][ERC20Address] -= amount;
    bool sent = IERC20(ERC20Address).transfer(msg.sender, amount);
    require(sent, "Transaction failed");
    emit TokenWithdrawn(msg.sender, ERC20Address, amount);
  }

  //Owner is allowed to withdraw the contract's Ether balance.
  function withdrawEther(address _receiver, uint256 _amount) external whitelisted nonReentrant {
    require(
      ReserveInEther() >= _amount,
      'Sorry, Contract does not have enough balance'
    );
    payable(_receiver).transfer(_amount);
  }

  //Owner is allowed to withdraw the contract's token balance.
  function withdrawToken(address ERC20Address, address _receiver, uint256 _amount) external nonReentrant whitelisted {
    require(
      ReserveInToken(ERC20Address) >= _amount,
      'Sorry, Contract does not have enough token balance'
    );
    bool sent = IERC20(ERC20Address).transfer(_receiver, _amount);
    require(sent, "Transaction failed");
  }

  function _inc(uint256 index) private pure returns (uint256) {
    unchecked {
      return index + 1;
    }
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}