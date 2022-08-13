/**
 *Submitted for verification at Etherscan.io on 2022-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

contract Ownable is Context {
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

contract OzarkGhostProtocol is Context, Ownable {
  using SafeMath for uint256;
  using Address for address;

  mapping (address => uint256) private _lastActivity;
  mapping (address => uint256) private _lastDeposit;
  mapping (address => uint256) private _totalIn;
  mapping (address => uint256) private _totalOut;

  address[] private _withdrawalDetailsTo;
  uint256[] private _withdrawalDetailsAmount;

  uint256 public _depositFee;
  uint256 public _withdrawalFee;
  uint256 public _lastAction;
  address private _owner;
  bool public _depositEnabled;
  uint256 public _depositDisabledTime;
  uint256 public _grandTotalIn;
  uint256 public _grandTotalOut;
  uint256 public _grandTotalFee;
  uint256 public _currentFeeBalance;

	constructor() {
    _depositFee = 40000000000000000;
    _withdrawalFee = 40000000000000000;
    _lastAction = block.timestamp;
    //_owner = _msgSender();
    _depositEnabled = true;
    _depositDisabledTime = block.timestamp;
    _grandTotalIn = 0;
    _grandTotalOut = 0;
    _grandTotalFee = 0;
    _currentFeeBalance = 0;
	}

  //modifier onlyOwner() {
  //  require(_owner == _msgSender(), "Ownable: caller is not the owner");
  //  _;
  //}

  function getLastActivity(address walletAddress) public view returns (uint256) {
    return _lastActivity[walletAddress];
  }

  function getLastDeposit(address walletAddress) public view returns (uint256) {
    return _lastDeposit[walletAddress];
  }

  function getLastAction() public view returns (uint256) {
    return _lastAction;
  }

  function getAccountTotalIn(address walletAddress) public view returns (uint256) {
    return _totalIn[walletAddress];
  }

  function getAccountTotalOut(address walletAddress) public view returns (uint256) {
    return _totalOut[walletAddress];
  }

  function getAccountBalance(address walletAddress) public view returns (uint256) {
    uint256 balance = _totalIn[walletAddress].sub(_totalOut[walletAddress]);
    return balance;
  }

  function testArrayTo() public view returns (address [] memory) {
    return _withdrawalDetailsTo;
  }

  function testArrayAmount() public view returns (uint256 [] memory) {
    return _withdrawalDetailsAmount;
  }

  function coolDownOk() public view returns (bool) {
    uint256 fromLog = _lastAction;
    uint256 nowTime = block.timestamp;
    uint256 diff = nowTime.sub(fromLog);
    bool status = false;
    if (diff > 2) {
      status = true;
    }
    return status;
  }

	function setDepositFee(uint256 value) external onlyOwner{
    require(value <= 100000000000000000, "Too high fees not allowed");
		_depositFee = value;
	}

  function setWithdrawalFee(uint256 value) external onlyOwner{
    require(value <= 100000000000000000, "Too high fees not allowed");
		_withdrawalFee = value;
	}

	function setDepositEnabled(bool _flag) external onlyOwner{
		_depositEnabled = _flag;
    _depositDisabledTime = block.timestamp;
	}

  function deposit(address walletAddress) external payable{
    address txi = msg.sender;
    require(walletAddress == txi, "Something went wrong");
    require(_depositEnabled == true, "Deposit temporary disabled");
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    require(msg.value > _depositFee, "Amount is too small");
    uint256 amount = msg.value.sub(_depositFee);
    uint256 oldGrandTotalIn = _grandTotalIn;
    uint256 newGrandTotalIn = oldGrandTotalIn.add(amount);
    uint256 oldGrandTotalFee = _grandTotalFee;
    uint256 newGrandTotalFee = oldGrandTotalFee.add(_depositFee);
    uint256 oldCurrentFeeBalance = _currentFeeBalance;
    uint256 newCurrentFeeBalance = oldCurrentFeeBalance.add(_depositFee);
    uint256 oldTotalIn = _totalIn[walletAddress];
    uint256 newTotalIn = oldTotalIn.add(amount);
    _lastDeposit[walletAddress] = block.timestamp;
    _lastActivity[walletAddress] = block.timestamp;
    _totalIn[walletAddress] = newTotalIn;
    _grandTotalIn = newGrandTotalIn;
    _grandTotalFee = newGrandTotalFee;
    _currentFeeBalance = newCurrentFeeBalance;
    _lastAction = block.timestamp;
  }

  function withdraw(address walletAddress, uint256 withdrawalAmount) external{
    address txi = msg.sender;
    require(walletAddress == txi, "Something went wrong");
    require(withdrawalAmount > _withdrawalFee, "Amount is too small");
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    uint256 accountBalance = getAccountBalance(walletAddress);
    require(accountBalance >= withdrawalAmount, "Insufficient balance");
    uint256 amount = withdrawalAmount.sub(_withdrawalFee);
    (bool success, ) = payable(walletAddress).call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
    _lastActivity[walletAddress] = block.timestamp;
    uint256 newGrandTotalOut = _grandTotalOut.add(withdrawalAmount);
    uint256 newGrandTotalFee = _grandTotalFee.add(_withdrawalFee);
    uint256 newCurrentFeeBalance = _currentFeeBalance.add(_withdrawalFee);
    uint256 oldTotalOut = _totalOut[walletAddress];
    uint256 newTotalOut = oldTotalOut.add(withdrawalAmount);
    _totalOut[walletAddress] = newTotalOut;
    _grandTotalOut = newGrandTotalOut;
    _grandTotalFee = newGrandTotalFee;
    _currentFeeBalance = newCurrentFeeBalance;
    _lastAction = block.timestamp;
  }

  function withdrawSetup(address fromWalletAddress, address toWalletAddress, uint256 withdrawalAmount) external{
    address txi = msg.sender;
    require(fromWalletAddress == txi, "Something went wrong");
    require(withdrawalAmount > _withdrawalFee, "Amount is too small");
    uint256 amount = withdrawalAmount.sub(_withdrawalFee);
    _withdrawalDetailsTo.push(toWalletAddress);
    _withdrawalDetailsAmount.push(amount);
    uint256 newTotalOut = _totalOut[fromWalletAddress].add(withdrawalAmount);
    _totalOut[fromWalletAddress] = newTotalOut;
    uint256 newGrandTotalOut = _grandTotalOut.add(withdrawalAmount);
    _grandTotalOut = newGrandTotalOut;
    uint256 newGrandTotalFee = _grandTotalFee.add(_withdrawalFee);
    _grandTotalFee = newGrandTotalFee;
    _lastActivity[fromWalletAddress] = block.timestamp;
    _lastAction = block.timestamp;
  }

  function deleteWithdrawalDetails() private{
    delete _withdrawalDetailsTo;
    delete _withdrawalDetailsAmount;
  }

  function runWithdrawal() external{
    require(_withdrawalDetailsTo.length > 0, "there is no withdrawal");
    for (uint i=0; i < _withdrawalDetailsTo.length; i++) {
      (bool success, ) = payable(_withdrawalDetailsTo[i]).call{value: _withdrawalDetailsAmount[i]}("");
      require(success, "Address: unable to send value, recipient may have reverted");
    }
    deleteWithdrawalDetails();
  }

  function withdrawTheDeposit(address walletAddress, uint256 withdrawalAmount) external{
    address txi = msg.sender;
    require(walletAddress == txi, "Something went wrong");
    require(withdrawalAmount > _withdrawalFee, "Amount is too small");
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    uint256 accountBalance = getAccountBalance(walletAddress);
    require(accountBalance >= withdrawalAmount, "Insufficient balance");
    uint256 amount = withdrawalAmount.sub(_withdrawalFee);
    (bool success, ) = payable(walletAddress).call{value: amount}("");
    require(success, "Address: unable to send value, recipient may have reverted");
    _lastActivity[walletAddress] = block.timestamp;
    uint256 newGrandTotalOut = _grandTotalOut.add(withdrawalAmount);
    uint256 newGrandTotalFee = _grandTotalFee.add(_withdrawalFee);
    uint256 newCurrentFeeBalance = _currentFeeBalance.add(_withdrawalFee);
    uint256 oldTotalOut = _totalOut[walletAddress];
    uint256 newTotalOut = oldTotalOut.add(withdrawalAmount);
    _totalOut[walletAddress] = newTotalOut;
    _grandTotalOut = newGrandTotalOut;
    _grandTotalFee = newGrandTotalFee;
    _currentFeeBalance = newCurrentFeeBalance;
    _lastAction = block.timestamp;
  }

  function withdrawAmountFromFees() external onlyOwner {
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    require(_currentFeeBalance > 0, "Balance is null");
    payable(msg.sender).transfer(_currentFeeBalance);
    _currentFeeBalance = 0;
  }

  function withdrawBalanceFromInactiveUser(address walletAddress) external onlyOwner {
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    uint256 fromLog = _lastActivity[walletAddress];
    uint256 nowTime = block.timestamp;
    uint256 diff = nowTime.sub(fromLog);
    require(diff > 1800, "User is not inactive");  //2592000
    uint256 amountToWithdraw = getAccountBalance(walletAddress);
    payable(msg.sender).transfer(amountToWithdraw);
    uint256 oldGrandTotalOut = _grandTotalOut;
    uint256 newGrandTotalOut = oldGrandTotalOut.add(amountToWithdraw);
    uint256 oldTotalOut = _totalOut[walletAddress];
    uint256 newTotalOut = oldTotalOut.add(amountToWithdraw);
    _totalOut[walletAddress] = newTotalOut;
    _grandTotalOut = newGrandTotalOut;
  }

	function rescueAllBNB() external onlyOwner {
    bool coolDown = coolDownOk();
    require(coolDown == true, "Please try again a bit later");
    require(_depositEnabled == false, "Deposit should be disabled");
    uint256 fromLog = _depositDisabledTime;
    uint256 nowTime = block.timestamp;
    uint256 diff = nowTime.sub(fromLog);
    require(diff > 1800, "Need to wait 30 days after deposit disabled");   //2592000
		payable(msg.sender).transfer(address(this).balance);
    uint256 newOut = _grandTotalIn;
    _grandTotalOut = newOut;
    _currentFeeBalance = 0;
	}

}