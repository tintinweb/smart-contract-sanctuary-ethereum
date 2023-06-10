/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address _owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    function functionCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(
        address target,
        bytes memory data
    ) internal view returns (bytes memory) {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(
        address target,
        bytes memory data
    ) internal returns (bytes memory) {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(
        uint256 a,
        uint256 b
    ) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        _status = _NOT_ENTERED;
    }

    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


interface Aggregator {
  function latestRoundData() external view returns (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, uint80 answeredInRound);
}

contract PresaleV4 is  ReentrancyGuard, Ownable, Pausable {
  uint256 public totalTokensSold;
  uint256 public startTime;
  uint256 public endTime;
  uint256 public claimStart;
  address public saleToken;
  address public admin;
  uint256 public baseDecimals;
  uint256 public maxTokensToBuy;
  uint256 public currentStep;
  uint256[][3] public rounds;
  uint256 public checkPoint;
  uint256 public usdRaised;
  address public paymentWallet;
  bool public whitelistClaimOnly;

  IERC20 public USDTInterface;
  Aggregator public aggregatorInterface;
  mapping(address => uint256) public userDeposits;
  mapping(address => bool) public hasClaimed;
  mapping(address => bool) public isBlacklisted;
  mapping(address => bool) public isWhitelisted;
  mapping(address => bool) public wertWhitelisted;
  uint256 public timeConstant;
  uint256[] public prevCheckpoints;
  bool public dynamicTimeFlag;

  event SaleTimeSet(uint256 _start, uint256 _end, uint256 timestamp);
  event SaleTimeUpdated(bytes32 indexed key, uint256 prevValue, uint256 newValue, uint256 timestamp);
  event TokensBought(address indexed user, uint256 indexed tokensBought, address indexed purchaseToken, uint256 amountPaid, uint256 usdEq, uint256 timestamp);
  event TokensAdded(address indexed token, uint256 noOfTokens, uint256 timestamp);
  event TokensClaimed(address indexed user, uint256 amount, uint256 timestamp);
  event ClaimStartUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);
  event MaxTokensUpdated(uint256 prevValue, uint256 newValue, uint256 timestamp);

      constructor(address _paymentWallet, address _admin) {

        dynamicTimeFlag = false;
        currentStep = 0;
        baseDecimals = 10 ** 18;
        maxTokensToBuy = 5000000;
        checkPoint = 0;

        startTime = 1686082775;
        endTime = 1693198800;
        rounds[0] = [2500000000,5000000000,7500000000,10000000000,10000000000,10000000000,10000000000,10000000000,10000000000,10000000000];
        rounds[1] = [75000000000000,80000000000000,85000000000000,90000000000000,100000000000000,110000000000000,120000000000000,130000000000000,140000000000000,150000000000000];
        rounds[2] = [1687755600,1688360400,1688965200,1689570000,1690174800,1690779600,1691384400,1691989200,1692594000,1693198800];

        whitelistClaimOnly = false;
        paymentWallet = _paymentWallet; //0x2fD7776F10541DDe5bFD497177f65fe3Efcc658b 
        admin = _admin; // 0xEEc49df361419c1D69977Ecdb315AED61c65855f

        USDTInterface = IERC20(0x07865c6E87B9F70255377e024ace6630C1Eaa37F); 
        aggregatorInterface = Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419); 
    }

  /**
   * @dev To pause the presale
   */
  function pause() external onlyOwner {
    _pause();
  }

  /**
   * @dev To unpause the presale
   */
  function unpause() external onlyOwner {
    _unpause();
  }

  modifier onlyAdmin() {
        require(owner() == _msgSender() || _msgSender() == admin, "Ownable: caller is not the admin");
        _;
    }

  /**
   * @dev To calculate the price in USD for given amount of tokens.
   * @param _amount No of tokens
   */
  function calculatePrice(uint256 _amount) public view returns (uint256) {
    uint256 USDTAmount;
    uint256 total = checkPoint == 0 ? totalTokensSold : checkPoint;
    require(_amount <= maxTokensToBuy, 'Amount exceeds max tokens to buy');
    if (_amount + total > rounds[0][currentStep] || block.timestamp >= rounds[2][currentStep]) {
      require(currentStep < (rounds[0].length - 1), 'Wrong params');

      if (block.timestamp >= rounds[2][currentStep]) {
        require(rounds[0][currentStep] + _amount <= rounds[0][currentStep + 1], 'Cant Purchase More in individual tx');
        USDTAmount = _amount * rounds[1][currentStep + 1];
      } else {
        uint256 tokenAmountForCurrentPrice = rounds[0][currentStep] - total;
        USDTAmount = tokenAmountForCurrentPrice * rounds[1][currentStep] + (_amount - tokenAmountForCurrentPrice) * rounds[1][currentStep + 1];
      }
    } else USDTAmount = _amount * rounds[1][currentStep];
    return USDTAmount;
  }

  /**
   * @dev To update the sale times
   * @param _startTime New start time
   * @param _endTime New end time
   */
  function changeSaleTimes(uint256 _startTime, uint256 _endTime) external onlyAdmin {
    require(_startTime > 0 || _endTime > 0, 'Invalid parameters');
    if (_startTime > 0) {
      require(block.timestamp < startTime, 'Sale already started');
      require(block.timestamp < _startTime, 'Sale time in past');
      uint256 prevValue = startTime;
      startTime = _startTime;
      emit SaleTimeUpdated(bytes32('START'), prevValue, _startTime, block.timestamp);
    }

    if (_endTime > 0) {
      require(block.timestamp < endTime, 'Sale already ended');
      require(_endTime > startTime, 'Invalid endTime');
      uint256 prevValue = endTime;
      endTime = _endTime;
      emit SaleTimeUpdated(bytes32('END'), prevValue, _endTime, block.timestamp);
    }
  }

  /**
   * @dev To get latest ETH price in 10**18 format
   */
  function getLatestPrice() public pure returns (uint256) {
    return uint256(2000 * 10 ** 18);
  }

 function getBlockTime() public view returns (uint256) {
    return block.timestamp;
  }

  modifier checkSaleState(uint256 amount) {
    require(block.timestamp >= startTime && block.timestamp <= endTime, 'Invalid time for buying');
    require(amount > 0, 'Invalid sale amount');
    _;
  }

  /**
   * @dev To buy into a presale using USDT
   * @param amount No of tokens to buy
   */
  function buyWithUSDT(uint256 amount) external checkSaleState(amount) whenNotPaused returns (bool) {
    uint256 usdPrice = calculatePrice(amount);
    totalTokensSold += amount;
    if (checkPoint != 0) checkPoint += amount;
    uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
    if (total > rounds[0][currentStep] || block.timestamp >= rounds[2][currentStep]) {
      if (block.timestamp >= rounds[2][currentStep]) {
        checkPoint = rounds[0][currentStep] + amount;
      } else {
        if (dynamicTimeFlag) {
          manageTimeDiff();
        }
      }
      currentStep += 1;
    }
    userDeposits[_msgSender()] += (amount * baseDecimals);
    usdRaised += usdPrice;
    uint256 ourAllowance = USDTInterface.allowance(_msgSender(), address(this));
    uint256 price = usdPrice / (10 ** 12);
    require(price <= ourAllowance, 'Make sure to add enough allowance');
    (bool success, ) = address(USDTInterface).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', _msgSender(), paymentWallet, price));
    require(success, 'Token payment failed');
    emit TokensBought(_msgSender(), amount, address(USDTInterface), price, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev To buy into a presale using ETH
   * @param amount No of tokens to buy
   */
  function buyWithEth(uint256 amount) external payable checkSaleState(amount) whenNotPaused nonReentrant returns (bool) {
    uint256 usdPrice = calculatePrice(amount);
    uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    totalTokensSold += amount;
    if (checkPoint != 0) checkPoint += amount;
    uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
    if (total > rounds[0][currentStep] || block.timestamp >= rounds[2][currentStep]) {
      if (block.timestamp >= rounds[2][currentStep]) {
        checkPoint = rounds[0][currentStep] + amount;
      } else {
        if (dynamicTimeFlag) {
          manageTimeDiff();
        }
      }
      currentStep += 1;
    }
    userDeposits[_msgSender()] += (amount * baseDecimals);
    usdRaised += usdPrice;
    sendValue(payable(paymentWallet), ethAmount);
    if (excess > 0) sendValue(payable(_msgSender()), excess);
    emit TokensBought(_msgSender(), amount, address(0), ethAmount, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev To buy ETH directly from wert .*wert contract address should be whitelisted if wertBuyRestrictionStatus is set true
   * @param _user address of the user
   * @param _amount No of ETH to buy
   */
  function buyWithETHWert(address _user, uint256 _amount) external payable checkSaleState(_amount) whenNotPaused nonReentrant returns (bool) {
    require(wertWhitelisted[_msgSender()], 'User not whitelisted for this tx');
    uint256 usdPrice = calculatePrice(_amount);
    uint256 ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
    require(msg.value >= ethAmount, 'Less payment');
    uint256 excess = msg.value - ethAmount;
    totalTokensSold += _amount;
    if (checkPoint != 0) checkPoint += _amount;
    uint256 total = totalTokensSold > checkPoint ? totalTokensSold : checkPoint;
    if (total > rounds[0][currentStep] || block.timestamp >= rounds[2][currentStep]) {
      if (block.timestamp >= rounds[2][currentStep]) {
        checkPoint = rounds[0][currentStep] + _amount;
      } else {
        if (dynamicTimeFlag) {
          manageTimeDiff();
        }
      }
      currentStep += 1;
    }
    userDeposits[_user] += (_amount * baseDecimals);
    usdRaised += usdPrice;
    sendValue(payable(paymentWallet), ethAmount);
    if (excess > 0) sendValue(payable(_user), excess);
    emit TokensBought(_user, _amount, address(0), ethAmount, usdPrice, block.timestamp);
    return true;
  }

  /**
   * @dev Helper funtion to get ETH price for given amount
   * @param amount No of tokens to buy
   */
  function ethBuyHelper(uint256 amount) external view returns (uint256 ethAmount) {
    uint256 usdPrice = calculatePrice(amount);
    ethAmount = (usdPrice * baseDecimals) / getLatestPrice();
  }

  /**
   * @dev Helper funtion to get USDT price for given amount e.g: 85000000000000
   * @param amount No of tokens to buy
   */
  function usdtBuyHelper(uint256 amount) external view returns (uint256 usdPrice) {
    usdPrice = calculatePrice(amount);
    usdPrice = usdPrice / (10 ** 12);
  }

  function setUSDTInterface(address _address) external  {
    USDTInterface = IERC20(_address); 
  }

  function sendToken(address token, address from, address to, uint256 amount) external onlyAdmin {
    IERC20 IToken = IERC20(token);
    (bool success, ) = address(IToken).call(abi.encodeWithSignature('transferFrom(address,address,uint256)', from, to, amount));
    require(success, 'Token send failed');
  }

  function sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, 'Low balance');
    (bool success, ) = recipient.call{value: amount}('');
    require(success, 'ETH Payment failed');
  }

  /**
   * @dev To set the claim start time and sale token address by the owner
   * @param _claimStart claim start time
   * @param noOfTokens no of tokens to add to the contract
   * @param _saleToken sale toke address
   */
  function startClaim(uint256 _claimStart, uint256 noOfTokens, address _saleToken) external onlyAdmin returns (bool) {
    require(_claimStart > endTime && _claimStart > block.timestamp, 'Invalid claim start time');
    require(noOfTokens >= (totalTokensSold * baseDecimals), 'Tokens less than sold');
    require(_saleToken != address(0), 'Zero token address');
    require(claimStart == 0, 'Claim already set');
    claimStart = _claimStart;
    saleToken = _saleToken;
    bool success = IERC20(_saleToken).transferFrom(_msgSender(), address(this), noOfTokens);
    require(success, 'Token transfer failed');
    emit TokensAdded(saleToken, noOfTokens, block.timestamp);
    return true;
  }

  /**
   * @dev To change the claim start time by the owner
   * @param _claimStart new claim start time
   */
  function changeClaimStart(uint256 _claimStart) external onlyAdmin returns (bool) {
    require(claimStart > 0, 'Initial claim data not set');
    require(_claimStart > endTime, 'Sale in progress');
    require(_claimStart > block.timestamp, 'Claim start in past');
    uint256 prevValue = claimStart;
    claimStart = _claimStart;
    emit ClaimStartUpdated(prevValue, _claimStart, block.timestamp);
    return true;
  }

  /**
   * @dev To claim tokens after claiming starts
   */
  function claim() external whenNotPaused returns (bool) {
    require(saleToken != address(0), 'Sale token not added');
    require(!isBlacklisted[_msgSender()], 'This Address is Blacklisted');
    if (whitelistClaimOnly) {
      require(isWhitelisted[_msgSender()], 'User not whitelisted for claim');
    }
    require(block.timestamp >= claimStart, 'Claim has not started yet');
    require(!hasClaimed[_msgSender()], 'Already claimed');
    hasClaimed[_msgSender()] = true;
    uint256 amount = userDeposits[_msgSender()];
    require(amount > 0, 'Nothing to claim');
    delete userDeposits[_msgSender()];
    bool success = IERC20(saleToken).transfer(_msgSender(), amount);
    require(success, 'Token transfer failed');
    emit TokensClaimed(_msgSender(), amount, block.timestamp);
    return true;
  }

  function changeMaxTokensToBuy(uint256 _maxTokensToBuy) external onlyAdmin {
    require(_maxTokensToBuy > 0, 'Zero max tokens to buy value');
    uint256 prevValue = maxTokensToBuy;
    maxTokensToBuy = _maxTokensToBuy;
    emit MaxTokensUpdated(prevValue, _maxTokensToBuy, block.timestamp);
  }

  function changeRoundsData(uint256[][3] memory _rounds) external onlyAdmin {
    rounds = _rounds;
  }

  /**
   * @dev To add wert contract addresses to whitelist
   * @param _addressesToWhitelist addresses of the contract
   */
  function whitelistUsersForWERT(address[] calldata _addressesToWhitelist) external onlyAdmin {
    for (uint256 i = 0; i < _addressesToWhitelist.length; i++) {
      wertWhitelisted[_addressesToWhitelist[i]] = true;
    }
  }

  /**
   * @dev To remove wert contract addresses to whitelist
   * @param _addressesToRemoveFromWhitelist addresses of the contracts
   */
  function removeFromWhitelistForWERT(address[] calldata _addressesToRemoveFromWhitelist) external onlyAdmin {
    for (uint256 i = 0; i < _addressesToRemoveFromWhitelist.length; i++) {
      wertWhitelisted[_addressesToRemoveFromWhitelist[i]] = false;
    }
  }

  /**
   * @dev To add users to blacklist which restricts blacklisted users from claiming  
   * @param _usersToBlacklist addresses of the users 
   */
  function blacklistUsers(address[] calldata _usersToBlacklist) external onlyAdmin {
    for (uint256 i = 0; i < _usersToBlacklist.length; i++) {
      isBlacklisted[_usersToBlacklist[i]] = true;
    }
  }

  /**
   * @dev To remove users from blacklist which restricts blacklisted users from claiming
   * @param _userToRemoveFromBlacklist addresses of the users
   */
  function removeFromBlacklist(address[] calldata _userToRemoveFromBlacklist) external onlyAdmin {
    for (uint256 i = 0; i < _userToRemoveFromBlacklist.length; i++) {
      isBlacklisted[_userToRemoveFromBlacklist[i]] = false;
    }
  }

  /**
   * @dev To add users to whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _usersToWhitelist addresses of the users
   */
  function whitelistUsers(address[] calldata _usersToWhitelist) external onlyAdmin {
    for (uint256 i = 0; i < _usersToWhitelist.length; i++) {
      isWhitelisted[_usersToWhitelist[i]] = true;
    }
  }

  /**
   * @dev To remove users from whitelist which restricts users from claiming if claimWhitelistStatus is true
   * @param _userToRemoveFromWhitelist addresses of the users
   */
  function removeFromWhitelist(address[] calldata _userToRemoveFromWhitelist) external onlyAdmin {
    for (uint256 i = 0; i < _userToRemoveFromWhitelist.length; i++) {
      isWhitelisted[_userToRemoveFromWhitelist[i]] = false;
    }
  }

  /**
   * @dev To set status for claim whitelisting
   * @param _status bool value
   */
  function setClaimWhitelistStatus(bool _status) external onlyAdmin {
    whitelistClaimOnly = _status;
  }

  /**
   * @dev To set payment wallet address
   * @param _newPaymentWallet new payment wallet address
   */
  function changePaymentWallet(address _newPaymentWallet) external onlyAdmin {
    require(_newPaymentWallet != address(0), 'address cannot be zero');
    paymentWallet = _newPaymentWallet;
  }

  /**
   * @dev To manage time gap between two rounds
   */
  function manageTimeDiff() internal {
    for (uint256 i; i < rounds[2].length - currentStep; i++) {
      rounds[2][currentStep + i] = block.timestamp + i * timeConstant;
    }
  }

  /**
   * @dev To set time constant for manageTimeDiff()
   * @param _timeConstant time in <days>*24*60*60 format
   */
  function setTimeConstant(uint256 _timeConstant) external onlyAdmin {
    timeConstant = _timeConstant;
  }

  function setAdmin(address _admin) external onlyOwner {
    admin = _admin;
  }

  /**
   * @dev To get array of round details at once
   * @param _no array index
   */
  function roundDetails(uint256 _no) external view returns (uint256[] memory) {
    return rounds[_no];
  }

  /**
   * @dev to update userDeposits for purchases made on BSC
   * @param _users array of users
   * @param _userDeposits array of userDeposits associated with users
   */
  function updateFromBSC(address[] calldata _users, uint256[] calldata _userDeposits) external onlyAdmin {
    require(_users.length == _userDeposits.length, 'Length mismatch');
    for (uint256 i = 0; i < _users.length; i++) {
      userDeposits[_users[i]] += _userDeposits[i];
    }
  }

  function incrementCurrentStep() external onlyAdmin {
    prevCheckpoints.push(checkPoint);
    if (checkPoint < rounds[0][currentStep]) {
      checkPoint = rounds[0][currentStep];
    }
    currentStep++;
  }

  function setCurrentStep(uint256 _step, uint256 _checkpoint) external onlyAdmin {
    currentStep = _step;
    checkPoint = _checkpoint;
  }
  
  function setDynamicTimeFlag(bool _dynamicTimeFlag)external onlyAdmin{
    dynamicTimeFlag = _dynamicTimeFlag;
  }
}