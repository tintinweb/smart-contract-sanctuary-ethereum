// SPDX-License-Identifier: PROPRIETARY - gean
pragma solidity ^0.8.17;

import "./ContractData.sol";

contract BnbSmartChain is ContractData {
    constructor() {
        accountsInfo[firstUser].up = address(0);
        accountsInfo[firstUser].unlockedLevel = 10;
        accountsInfo[firstUser].registered = true;
        accountsInfo[firstUser].depositTotal = 1 ether;
        accountsEarnings[firstUser].depositTime = block.timestamp;
        accountsEarnings[firstUser].depositValue = 10 ether;
        accountsEarnings[firstUser].withdrawDirectBonusAmount = 15 ether;
        accountsEarnings[firstUser].receivedDirectBonusAmount = 0.5 ether;
        networkSize += 1;
    }

  // --------------------- PUBLIC METHODS ---------------------------
    function renew() external payable {
        address sender = msg.sender;
        (,uint freeToWithdrawl,,,) = availableForWithdrawal(sender);

        require(accountsInfo[sender].registered == true, "User is not registered");
        require(waitingToReceive(sender) == 0, "insufficient funds");
        require(freeToWithdrawl == 0, "it's still running");
        require(msg.value >= minAllowedDeposit, "Min amount not reached");

        _registerDeposit(sender, msg.value, 0);
    }

    function withdrawalTotal() external {
        address sender = msg.sender;
        require(waitingToReceive(sender) == 0, "insufficient funds");
        require((accountsInfo[sender].lastWithdraw + 10 minutes) < block.timestamp , "Time limit");
        (,uint freeToWithdrawl,,,) = availableForWithdrawal(sender);
        require(address(this).balance >= freeToWithdrawl, "Insufficient balance");
        distributeWithdrawalAmount(sender, freeToWithdrawl);
        payable(sender).transfer(freeToWithdrawl);
    }

    function withdrawlAndUpgrade(uint _amount) external {
        address sender = msg.sender;
        (,uint freeToWithdrawl,,,) = availableForWithdrawal(sender);
        (,,uint freePassive,,) = availableForWithdrawal(sender);
        require((accountsInfo[sender].lastWithdraw + 10 minutes) < block.timestamp , "Time limit");
        require(freeToWithdrawl > 0, "Min amount not reached");
        require(freeToWithdrawl >= _amount, "insufficient funds");
        distributeWithdrawalAmount(sender, _amount);
        accountsEarnings[sender].receivedPassiveAmount += freePassive;
        _registerDeposit(sender, _amount, 1);
    }

    function withdrawalPercent(uint _amount) external {
        address sender = msg.sender;
        (uint freeToWithdrawl,,,,) = availableForWithdrawal(sender);
        require((accountsInfo[sender].lastWithdraw + 10 minutes) < block.timestamp , "Time limit");
        require(address(this).balance >= _amount, "Insufficient balance");
        require(waitingToReceive(sender) > 0, "insufficient funds");
        require(freeToWithdrawl > 0, "Min amount not reached");
        require(freeToWithdrawl >= _amount, "insufficient funds");
        distributeWithdrawalAmount(sender, _amount);
        payable(sender).transfer(_amount);
    }

    function upgradeDeposit() external payable {
        require(msg.value >= minAllowedDeposit, "Min amount not reached");
        address sender = msg.sender;
        (,,uint freePassive,,) = availableForWithdrawal(sender);
        accountsEarnings[sender].receivedPassiveAmount += freePassive;
        _registerDeposit(sender, msg.value, 1);
    }

    function registerAccount(address ref) external payable {
        address sender = msg.sender;
        if (accountsInfo[ref].registered != true) {
            ref = firstUser;
        }
        require(accountsInfo[sender].registered == false, "User is already registered in the system");
        require(msg.value >= minAllowedDeposit, "Min amount not reached");
        //Registra o usuario na rede 
        accountsInfo[sender].up = ref;
        accountsInfo[sender].registered = true;
        networkSize += 1;
        //Realiza um novo deposito
        _registerDeposit(sender, msg.value, 0);
    }

  // --------------------- PRIVATE METHODS ---------------------------

    function _registerDeposit(address sender, uint amount, uint8 _type) private {
        require(accountsInfo[sender].registered == true, "Registration is required");

        accountsInfo[sender].lastDeposit += block.timestamp;
        //
        maxBalance = maxBalance + amount;
        networkDeposits = networkDeposits + amount;
        //
        accountsInfo[sender].depositCounter = accountsInfo[sender].depositCounter  +  1;
        accountsInfo[sender].depositTotal = accountsInfo[sender].depositTotal + amount;

        address referral = accountsInfo[sender].up;

        // Check up ref to unlock levels
        if (accountsInfo[sender].depositTotal >= minAmountToLvlUp && accountsInfo[sender].unlockedSponsor == false) {
            // unlocks a level to direct referral
            uint currentUnlockedLevel = accountsInfo[referral].unlockedLevel;
            if (currentUnlockedLevel < _unilevelPercents.length) {
            accountsInfo[referral].unlockedLevel = currentUnlockedLevel + 1;
            }
            accountsInfo[sender].unlockedSponsor == true;
        }


        // Pays the direct bonus
        if (referral != address(0) && accountsInfo[referral].depositTotal > minAmountToGetBonus) {
            uint directBonusAmount = (amount * directBonus) / 1000; // DIRECT BONUS
            directBonusAmount = getBonusValueToWrite(directBonusAmount, referral);
            if (directBonusAmount > 0) {
                emit ReceiveBonus(referral, accountsEarnings[referral].receivedDirectBonusAmount, accountsEarnings[referral].receivedLevelBonusAmount);
                accountsEarnings[referral].receivedDirectBonusAmount += directBonusAmount;
            }
        }
        //Pays residual bonus
        bool stopPayingResidual = false;
        uint8 residualLevel = 1;
        address _addressBase = sender;
        while(stopPayingResidual == false) {
            address _addressResidualReferral = accountsInfo[_addressBase].up;
            if (accountsInfo[_addressResidualReferral].registered == true && accountsInfo[_addressResidualReferral].depositTotal > minAmountToGetBonus && accountsInfo[_addressResidualReferral].unlockedLevel >= residualLevel && residualLevel < (_unilevelPercents.length + 1) ) {
                uint residualBonusAmount = (amount * _unilevelPercents[residualLevel - 1]) / 1000; // RESIDUAL BONUS
                residualBonusAmount = getBonusValueToWrite(residualBonusAmount, _addressResidualReferral);
                if (residualBonusAmount > 0) {
                    accountsEarnings[_addressResidualReferral].receivedLevelBonusAmount += residualBonusAmount;
                    emit ReceiveBonus(_addressResidualReferral, accountsEarnings[_addressResidualReferral].receivedDirectBonusAmount, accountsEarnings[_addressResidualReferral].receivedLevelBonusAmount);
                }
            }

            address nextAddress = accountsInfo[_addressResidualReferral].up;
            if (accountsInfo[nextAddress].registered == true && residualLevel < (_unilevelPercents.length + 1)) {
                residualLevel += 1;
                _addressBase = _addressResidualReferral;
            } else {
                stopPayingResidual = true;
            }
        }

        //update user information
        if (_type == 0) {
            accountsEarnings[sender].depositValue = amount;
            accountsEarnings[sender].depositTime = block.timestamp;
            accountsEarnings[sender].withdrawPassiveAmount = 0;
            accountsEarnings[sender].receivedDirectBonusAmount = 0;
            accountsEarnings[sender].withdrawDirectBonusAmount = 0;
            accountsEarnings[sender].receivedLevelBonusAmount = 0;
            accountsEarnings[sender].withdrawLevelBonusAmount = 0;
        } else if (_type == 1) {
            accountsEarnings[sender].depositValue += amount;
            accountsEarnings[sender].depositTime = block.timestamp;
        }

    }

    function distributeWithdrawalAmount(address _address, uint _amount) private returns(bool) {
        accountsInfo[_address].lastWithdraw = block.timestamp;
        networkWithdraw += _amount;
        if (accountsEarnings[_address].receivedDirectBonusAmount >= _amount) {
            accountsEarnings[_address].receivedDirectBonusAmount -= _amount;
            accountsEarnings[_address].withdrawDirectBonusAmount += _amount;
            accountsInfo[_address].withdrawDirectBonusAmount += _amount;
            return true;
        } else {
            uint freeValue = accountsEarnings[_address].receivedDirectBonusAmount;
            _amount -= freeValue;
            accountsEarnings[_address].withdrawDirectBonusAmount += freeValue;
            accountsInfo[_address].withdrawDirectBonusAmount += freeValue;
            accountsEarnings[_address].receivedDirectBonusAmount = 0;
        }

        if (accountsEarnings[_address].receivedLevelBonusAmount >= _amount) {
            accountsEarnings[_address].receivedLevelBonusAmount  -= _amount;
            accountsEarnings[_address].withdrawLevelBonusAmount += _amount;
            accountsInfo[_address].withdrawLevelBonusAmount += _amount;
            return true;
        } else {
            uint freeValue = accountsEarnings[_address].receivedLevelBonusAmount;
            _amount -= freeValue;
            accountsEarnings[_address].withdrawLevelBonusAmount += freeValue;
            accountsInfo[_address].withdrawLevelBonusAmount += freeValue;
            accountsEarnings[_address].receivedLevelBonusAmount = 0;
        }

        accountsEarnings[_address].withdrawPassiveAmount += _amount;
        accountsInfo[_address].withdrawPassiveAmount += _amount;
        
        return true;

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

// SPDX-License-Identifier: PROPRIETARY - gean
pragma solidity ^0.8.17;

import "./Authorized.sol";

contract ContractData is Authorized {
  string public name = "Bnb Smart Chain";
  string public url = "";
  
  event ReceiveBonus(
      address indexed _from,
      uint withdrawPassiveAmount,
      uint withdrawLevelBonusAmount
  );
  struct AccountInfo {
    address up;
    uint unlockedLevel;
    bool unlockedSponsor;
    bool registered;
    uint lastWithdraw;
    uint lastDeposit;
    uint depositTotal;
    uint depositCounter;
    uint withdrawTotal;
    uint withdrawPassiveAmount;
    uint withdrawDirectBonusAmount;
    uint withdrawLevelBonusAmount;
    uint withdrawCounter;
  }

  struct AccountActualEarning {
    uint depositValue;
    uint depositTime;
    uint receivedPassiveAmount;
    uint withdrawPassiveAmount;
    uint receivedDirectBonusAmount;
    uint withdrawDirectBonusAmount;
    uint receivedLevelBonusAmount;
    uint withdrawLevelBonusAmount;
  }

  struct MoneyFlow {
    uint passive;
    uint direct;
    uint bonus;
  }

  struct NetworkCheck {
    uint count;
    uint deposits;
    uint depositTotal;
    uint depositCounter;
  }

  mapping(address => AccountInfo) public accountsInfo;
  mapping(address => AccountActualEarning) public accountsEarnings;

  uint16[] _unilevelPercents = new uint16[](15);

  uint public minAllowedDeposit = 0.001 ether;
  uint8 public dailyRentability = 16;
  uint8 public maxPercentToReceive = 200;
  
  //Withdraw
  uint public wpmFeePercent = 40;
  address wpmReceiver;

  //Passive
  uint public directBonus = 100;
  uint public minAmountToGetBonus = 0.001 ether;
  uint public minAmountToLvlUp = 0.002 ether;
  uint public holdPassiveOnDrop = 75;
  bool public distributePassiveNetwork = true;

  //Network
  uint public maxBalance;
  uint public networkSize;
  uint public networkDeposits;
  uint public networkWithdraw;
  uint cumulativeNetworkFee;
  uint cumulativeWPMFee;


  address constant firstUser = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

  constructor() {
    _unilevelPercents[0] = 100;
    _unilevelPercents[1] = 70;
    _unilevelPercents[2] = 70;
    _unilevelPercents[3] = 70;
    _unilevelPercents[4] = 70;
    _unilevelPercents[5] = 40;
    _unilevelPercents[6] = 40;
    _unilevelPercents[7] = 20;
    _unilevelPercents[8] = 20;
    _unilevelPercents[9] = 20;
    _unilevelPercents[10] = 20;
    _unilevelPercents[11] = 10;
    _unilevelPercents[12] = 10;
    _unilevelPercents[13] = 10;
    _unilevelPercents[14] = 10;
  }

  function projectInfo() public view returns(uint, uint, uint) {
    return(address(this).balance, networkSize, networkDeposits);
  }

  function unilevelPercents() public view returns (uint16[] memory) {
    return _unilevelPercents;
  }

  function setUnilevelPercent(uint16 _level, uint16 _percent) public isAuthorized(1)  {
    require(_level - 1 <  _unilevelPercents.length, "The contract only allows unilever up to level 15");
    _unilevelPercents[_level - 1] = _percent;
  }

  function setDailyRentability(uint8 _percent) public isAuthorized(1)  {
    dailyRentability = _percent;
  }

  function setDirectBonus(uint8 _percent) public isAuthorized(1)  {
    directBonus = _percent;
  }
  
  function setHoldPassiveOnDrop(uint8 _percent) public isAuthorized(1)  {
    holdPassiveOnDrop = _percent;
  }

  function setWpmFeePercent(uint8 _percent) public isAuthorized(1)  {
    wpmFeePercent = _percent;
  }

  function setWpmReceiver(address _address) public isAuthorized(1)  {
    wpmReceiver = _address;
  }

  function setMinAllowedDeposit(uint _value) public isAuthorized(1)  {
    minAllowedDeposit = _value;
  }

  function setMinAmountToGetBonus(uint _value) public isAuthorized(1)  {
    minAmountToGetBonus = _value;
  }

  function setMinAmountToLvlUp(uint _value) public isAuthorized(1)  {
    minAmountToLvlUp = _value;
  }

  function passiveEarning(address _address) public view returns(uint) {
    uint secondsRunning =  block.timestamp - accountsEarnings[_address].depositTime;
    uint available =  accountsEarnings[_address].withdrawPassiveAmount + accountsEarnings[_address].receivedDirectBonusAmount + accountsEarnings[_address].withdrawDirectBonusAmount + accountsEarnings[_address].receivedLevelBonusAmount + accountsEarnings[_address].withdrawLevelBonusAmount;  
    uint maximunReceived = maximunEarning(_address);

    uint pasiveAvailable = (((((dailyRentability  * accountsEarnings[_address].depositValue) / 1000) /  1 minutes) * secondsRunning) + accountsEarnings[_address].receivedPassiveAmount) - accountsEarnings[_address].withdrawPassiveAmount;

    if ((available + pasiveAvailable) > maximunReceived) {
      pasiveAvailable = (maximunReceived - available);
    }

    return pasiveAvailable;
  }
  
  function maximunEarning (address _address) private view returns(uint) {
    return (accountsEarnings[_address].depositValue * maxPercentToReceive) / 100;
  }

  function waitingToReceive(address _address) public view returns(uint) {
    uint pasiveAvailable = passiveEarning(_address);
    uint available = pasiveAvailable + accountsEarnings[_address].withdrawPassiveAmount + accountsEarnings[_address].receivedDirectBonusAmount + accountsEarnings[_address].withdrawDirectBonusAmount + accountsEarnings[_address].receivedLevelBonusAmount + accountsEarnings[_address].withdrawLevelBonusAmount;  
    uint maximunReceived = maximunEarning(_address);
    return maximunReceived - available;
  }

  function availableForWithdrawal(address _address) public view returns(uint, uint, uint, uint, uint) {
    uint pasiveAvailable = passiveEarning(_address);
    uint totalAvailable = pasiveAvailable + accountsEarnings[_address].receivedDirectBonusAmount + accountsEarnings[_address].receivedLevelBonusAmount;    
    uint totalPercentAvailable = (totalAvailable * 30) / 100;
    
    return(totalPercentAvailable, totalAvailable, pasiveAvailable, accountsEarnings[_address].receivedDirectBonusAmount, accountsEarnings[_address].receivedLevelBonusAmount);
  }

  function getBonusValueToWrite(uint _value, address _address) public view returns(uint) {
        uint availableReferral = waitingToReceive(_address);
        return _value > availableReferral ? availableReferral : _value;
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IERC20.sol";

contract Authorized is Ownable {

  struct addressCheck {
    address _address;
    uint8 permissionLevel;
  }

  addressCheck[] public permissions;

  constructor() {
    permissions.push(
      addressCheck(
        _msgSender(),
        2
      )
    );
  }

  function findAdressIndex(address _address) private view returns(uint8){
    for (uint8 i = 0; i < permissions.length; i++) {
        if (permissions[i]._address == _address) {
          return i;
        }
    }
    return 200;
  }

  modifier isAuthorized(uint8 index) {
    uint8 addressIndex = findAdressIndex(_msgSender());
    require(addressIndex != 200, "Account does not have permission");
    uint8 _permisionLevel = permissions[findAdressIndex(_msgSender())].permissionLevel;
    if (_permisionLevel != 2) {
      require(permissions[findAdressIndex(_msgSender())].permissionLevel == index, "Account does not have permission");
    } 
    _;
  }

  function grantPermission(address operator, uint8 permissionLevel) external isAuthorized(2) {
    uint8 operatorIndex = findAdressIndex(operator);
    if (operatorIndex!= 200) {
      permissions[operatorIndex].permissionLevel = permissionLevel;
    } else {
      permissions.push(
        addressCheck(
          operator,
          permissionLevel
        )
      );
    }
  }

  function revokePermission(address operator) external isAuthorized(2) {
    permissions[findAdressIndex(operator)].permissionLevel = 0;
  }

  function safeApprove(
    address token,
    address spender,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).approve(spender, amount);
  }

  function safeTransfer(
    address token,
    address receiver,
    uint amount
  ) external isAuthorized(0) {
    IERC20(token).transfer(receiver, amount);
  }

   function listOperators() external view returns( addressCheck[] memory)  {
    return permissions;
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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