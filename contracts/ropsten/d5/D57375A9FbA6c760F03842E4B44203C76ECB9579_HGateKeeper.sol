/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// File: contracts/utils/Ownable.sol

pragma solidity >=0.4.21 <0.6.0;

contract Ownable {
    address private _contract_owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = msg.sender;
        _contract_owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _contract_owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_contract_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_contract_owner, newOwner);
        _contract_owner = newOwner;
    }
}

// File: contracts/erc20/IERC20.sol

pragma solidity >=0.4.21 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/ystream/IYieldStream.sol

pragma solidity >=0.4.21 <0.6.0;

contract IYieldStream{

  string public name;

  function target_token() public view returns(address);

  function getVirtualPrice() public view returns(uint256);

  function getDecimal() public pure returns(uint256);

  function getPriceDecimal() public pure returns(uint256);
}

// File: contracts/utils/SafeMath.sol

pragma solidity >=0.4.21 <0.6.0;

library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "sub");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "mul");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "div");
        c = a / b;
    }
}

// File: contracts/core/HEnv.sol

pragma solidity >=0.4.21 <0.6.0;


contract HEnv is Ownable{

  address public token_addr;

  address public fee_pool_addr;

  uint256 public ratio_base;
  uint256 public withdraw_fee_ratio;
  uint256 public cancel_fee_ratio;

  constructor(address _target_token) public{
    token_addr = _target_token;
    ratio_base = 100000000;
  }

  function changeFeePoolAddr(address _new) public onlyOwner{
    fee_pool_addr = _new;
  }

  function changeWithdrawFeeRatio(uint256 _ratio) public onlyOwner{
    require(_ratio < ratio_base, "ratio too large");
    withdraw_fee_ratio = _ratio;
  }

  function changeCancelFeeRatio(uint256 _ratio) public onlyOwner{
    require(_ratio < ratio_base, "ratio too large");
    cancel_fee_ratio = _ratio;
  }
}


contract HEnvFactory{
  event NewHEnv(address addr);
  function createHEnv(address _target_token) public returns (address){
    HEnv env = new HEnv(_target_token);
    env.transferOwnership(msg.sender);
    emit NewHEnv(address(env));
    return address(env);
  }
}

// File: contracts/utils/Address.sol

pragma solidity >=0.4.21 <0.6.0;

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

// File: contracts/erc20/SafeERC20.sol

pragma solidity >=0.4.21 <0.6.0;




library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeAdd(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).safeSub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/utils/AddressArray.sol

pragma solidity >=0.4.21 <0.6.0;

library AddressArray{
  function exists(address[] memory self, address addr) public pure returns(bool){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return true;
      }
    }
    return false;
  }

  function index_of(address[] memory self, address addr) public pure returns(uint){
    for (uint i = 0; i< self.length;i++){
      if (self[i]==addr){
        return i;
      }
    }
    require(false, "AddressArray:index_of, not exist");
  }

  function remove(address[] storage self, address addr) public returns(bool){
    uint index = index_of(self, addr);
    self[index] = self[self.length - 1];

    delete self[self.length-1];
    self.length--;
    return true;
  }
}

// File: contracts/erc20/ERC20Impl.sol

pragma solidity >=0.4.21 <0.6.0;


contract ApproveAndCallFallBack {
    function receiveApproval(
        address from,
        uint256 _amount,
        address _token,
        bytes memory _data
    ) public;
}
contract TransferEventCallBack{
  function onTransfer(address _from, address _to, uint256 _amount) public;
}

contract ERC20Base {
    string public name;                //The Token's name: e.g. GTToken
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP
    string public version = "GTT_0.1"; //An arbitrary versioning scheme

    using AddressArray for address[];
    address[] public transferListeners;

////////////////
// Events
////////////////
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _amount
        );

    event NewTransferListener(address _addr);
    event RemoveTransferListener(address _addr);

    /// @dev `Checkpoint` is the structure that attaches a block number to a
    ///  given value, the block number attached is the one that last changed the
    ///  value
    struct Checkpoint {
        // `fromBlock` is the block number that the value was generated from
        uint128 fromBlock;
        // `value` is the amount of tokens at a specific block number
        uint128 value;
    }

    // `parentToken` is the Token address that was cloned to produce this token;
    //  it will be 0x0 for a token that was not cloned
    ERC20Base public parentToken;

    // `parentSnapShotBlock` is the block number from the Parent Token that was
    //  used to determine the initial distribution of the Clone Token
    uint public parentSnapShotBlock;

    // `creationBlock` is the block number that the Clone Token was created
    uint public creationBlock;

    // `balances` is the map that tracks the balance of each address, in this
    //  contract when the balance changes the block number that the change
    //  occurred is also included in the map
    mapping (address => Checkpoint[]) balances;

    // `allowed` tracks any extra transfer rights as in all ERC20 tokens
    mapping (address => mapping (address => uint256)) allowed;

    // Tracks the history of the `totalSupply` of the token
    Checkpoint[] totalSupplyHistory;

    // Flag that determines if the token is transferable or not.
    bool public transfersEnabled;

////////////////
// Constructor
////////////////

    /// @notice Constructor to create a ERC20Base
    /// @param _parentToken Address of the parent token, set to 0x0 if it is a
    ///  new token
    /// @param _parentSnapShotBlock Block of the parent token that will
    ///  determine the initial distribution of the clone token, set to 0 if it
    ///  is a new token
    /// @param _tokenName Name of the new token
    /// @param _decimalUnits Number of decimals of the new token
    /// @param _tokenSymbol Token Symbol for the new token
    /// @param _transfersEnabled If true, tokens will be able to be transferred
    constructor(
        ERC20Base _parentToken,
        uint _parentSnapShotBlock,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        bool _transfersEnabled
    )  public
    {
        name = _tokenName;                                 // Set the name
        decimals = _decimalUnits;                          // Set the decimals
        symbol = _tokenSymbol;                             // Set the symbol
        parentToken = _parentToken;
        parentSnapShotBlock = _parentSnapShotBlock;
        transfersEnabled = _transfersEnabled;
        creationBlock = block.number;
    }


///////////////////
// ERC20 Methods
///////////////////

    /// @notice Send `_amount` tokens to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);
        return doTransfer(msg.sender, _to, _amount);
    }

    /// @notice Send `_amount` tokens to `_to` from `_from` on the condition it
    ///  is approved by `_from`
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // The standard ERC 20 transferFrom functionality
        if (allowed[_from][msg.sender] < _amount)
            return false;
        allowed[_from][msg.sender] -= _amount;
        return doTransfer(_from, _to, _amount);
    }

    /// @dev This is the actual transfer function in the token contract, it can
    ///  only be called by other functions in this contract.
    /// @param _from The address holding the tokens being transferred
    /// @param _to The address of the recipient
    /// @param _amount The amount of tokens to be transferred
    /// @return True if the transfer was successful
    function doTransfer(address _from, address _to, uint _amount) internal returns(bool) {
        if (_amount == 0) {
            return true;
        }
        require(parentSnapShotBlock < block.number);
        // Do not allow transfer to 0x0 or the token contract itself
        require((_to != address(0)) && (_to != address(this)));
        // If the amount being transfered is more than the balance of the
        //  account the transfer returns false
        uint256 previousBalanceFrom = balanceOfAt(_from, block.number);
        if (previousBalanceFrom < _amount) {
            return false;
        }
        // First update the balance array with the new value for the address
        //  sending the tokens
        updateValueAtNow(balances[_from], previousBalanceFrom - _amount);
        // Then update the balance array with the new value for the address
        //  receiving the tokens
        uint256 previousBalanceTo = balanceOfAt(_to, block.number);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(balances[_to], previousBalanceTo + _amount);
        // An event to make the transfer easy to find on the blockchain
        
        emit Transfer(_from, _to, _amount);
        onTransferDone(_from, _to, _amount);
        return true;
    }

    /// @param _owner The address that's balance is being requested
    /// @return The balance of `_owner` at the current block
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balanceOfAt(_owner, block.number);
    }

    /// @notice `msg.sender` approves `_spender` to spend `_amount` tokens on
    ///  its behalf. This is a modified version of the ERC20 approve function
    ///  to be a little bit safer
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the approval was successful
    function approve(address _spender, uint256 _amount) public returns (bool success) {
        require(transfersEnabled);

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender,0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require((_amount == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /// @dev This function makes it easy to read the `allowed[]` map
    /// @param _owner The address of the account that owns the token
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens of _owner that _spender is allowed
    ///  to spend
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /// @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    ///  its behalf, and then a function is triggered in the contract that is
    ///  being approved, `_spender`. This allows users to use their tokens to
    ///  interact with contracts in one function call instead of two
    /// @param _spender The address of the contract able to transfer the tokens
    /// @param _amount The amount of tokens to be approved for transfer
    /// @return True if the function call was successful
    function approveAndCall(ApproveAndCallFallBack _spender, uint256 _amount, bytes memory _extraData) public returns (bool success) {
        require(approve(address(_spender), _amount));

        _spender.receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

    /// @dev This function makes it easy to get the total number of tokens
    /// @return The total number of tokens
    function totalSupply() public view returns (uint) {
        return totalSupplyAt(block.number);
    }


////////////////
// Query balance and totalSupply in History
////////////////

    /// @dev Queries the balance of `_owner` at a specific `_blockNumber`
    /// @param _owner The address from which the balance will be retrieved
    /// @param _blockNumber The block number when the balance is queried
    /// @return The balance at `_blockNumber`
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint) {

        // These next few lines are used when the balance of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.balanceOfAt` be queried at the
        //  genesis block for that token as this contains initial balance of
        //  this token
        if ((balances[_owner].length == 0) || (balances[_owner][0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.balanceOfAt(_owner, min(_blockNumber, parentSnapShotBlock));
            } else {
                // Has no parent
                return 0;
            }

        // This will return the expected balance during normal situations
        } else {
            return getValueAt(balances[_owner], _blockNumber);
        }
    }

    /// @notice Total amount of tokens at a specific `_blockNumber`.
    /// @param _blockNumber The block number when the totalSupply is queried
    /// @return The total amount of tokens at `_blockNumber`
    function totalSupplyAt(uint _blockNumber) public view returns(uint) {

        // These next few lines are used when the totalSupply of the token is
        //  requested before a check point was ever created for this token, it
        //  requires that the `parentToken.totalSupplyAt` be queried at the
        //  genesis block for this token as that contains totalSupply of this
        //  token at this block number.
        if ((totalSupplyHistory.length == 0) || (totalSupplyHistory[0].fromBlock > _blockNumber)) {
            if (address(parentToken) != address(0)) {
                return parentToken.totalSupplyAt(min(_blockNumber, parentSnapShotBlock));
            } else {
                return 0;
            }

        // This will return the expected totalSupply during normal situations
        } else {
            return getValueAt(totalSupplyHistory, _blockNumber);
        }
    }

////////////////
// Generate and destroy tokens
////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function _generateTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply + _amount >= curTotalSupply); // Check for overflow
        uint previousBalanceTo = balanceOf(_owner);
        require(previousBalanceTo + _amount >= previousBalanceTo); // Check for overflow
        updateValueAtNow(totalSupplyHistory, curTotalSupply + _amount);
        updateValueAtNow(balances[_owner], previousBalanceTo + _amount);
        emit Transfer(address(0), _owner, _amount);
        onTransferDone(address(0), _owner, _amount);
        return true;
    }


    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function _destroyTokens(address _owner, uint _amount) internal returns (bool) {
        uint curTotalSupply = totalSupply();
        require(curTotalSupply >= _amount);
        uint previousBalanceFrom = balanceOf(_owner);
        require(previousBalanceFrom >= _amount);
        updateValueAtNow(totalSupplyHistory, curTotalSupply - _amount);
        updateValueAtNow(balances[_owner], previousBalanceFrom - _amount);
        emit Transfer(_owner, address(0), _amount);
        onTransferDone(_owner, address(0), _amount);
        return true;
    }

////////////////
// Enable tokens transfers
////////////////


    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function _enableTransfers(bool _transfersEnabled) internal {
        transfersEnabled = _transfersEnabled;
    }

////////////////
// Internal helper functions to query and set a value in a snapshot array
////////////////

    /// @dev `getValueAt` retrieves the number of tokens at a given block number
    /// @param checkpoints The history of values being queried
    /// @param _block The block number to retrieve the value at
    /// @return The number of tokens being queried
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) internal view returns (uint) {
        if (checkpoints.length == 0)
            return 0;

        // Shortcut for the actual value
        if (_block >= checkpoints[checkpoints.length-1].fromBlock)
            return checkpoints[checkpoints.length-1].value;
        if (_block < checkpoints[0].fromBlock)
            return 0;

        // Binary search of the value in the array
        uint min = 0;
        uint max = checkpoints.length-1;
        while (max > min) {
            uint mid = (max + min + 1) / 2;
            if (checkpoints[mid].fromBlock<=_block) {
                min = mid;
            } else {
                max = mid-1;
            }
        }
        return checkpoints[min].value;
    }

    /// @dev `updateValueAtNow` used to update the `balances` map and the
    ///  `totalSupplyHistory`
    /// @param checkpoints The history of data being updated
    /// @param _value The new number of tokens
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal {
        if ((checkpoints.length == 0) || (checkpoints[checkpoints.length - 1].fromBlock < block.number)) {
            Checkpoint storage newCheckPoint = checkpoints[checkpoints.length++];
            newCheckPoint.fromBlock = uint128(block.number);
            newCheckPoint.value = uint128(_value);
        } else {
            Checkpoint storage oldCheckPoint = checkpoints[checkpoints.length - 1];
            oldCheckPoint.value = uint128(_value);
        }
    }

    function onTransferDone(address _from, address _to, uint256 _amount) internal {
      for(uint i = 0; i < transferListeners.length; i++){
        TransferEventCallBack t = TransferEventCallBack(transferListeners[i]);
        t.onTransfer(_from, _to, _amount);
      }
    }

    function _addTransferListener(address _addr) internal {
      transferListeners.push(_addr);
      emit NewTransferListener(_addr);
    }
    function _removeTransferListener(address _addr) internal{
      transferListeners.remove(_addr);
      emit RemoveTransferListener(_addr);
    }

    /// @dev Helper function to return a min betwen the two uints
    function min(uint a, uint b) pure internal returns (uint) {
        return a < b ? a : b;
    }

    //function () external payable {
        //require(false, "cannot transfer ether to this contract");
    //}
}

// File: contracts/TrustListTools.sol

pragma solidity >=0.4.21 <0.6.0;


contract TrustListInterface{
  function is_trusted(address addr) public returns(bool);
}
contract TrustListTools is Ownable{
  TrustListInterface public trustlist;

  modifier is_trusted(address addr){
    require(trustlist != TrustListInterface(0x0), "trustlist is 0x0");
    require(trustlist.is_trusted(addr), "not a trusted issuer");
    _;
  }

  event ChangeTrustList(address _old, address _new);
  function changeTrustList(address _addr) public onlyOwner{
    address old = address(trustlist);
    trustlist = TrustListInterface(_addr);
    emit ChangeTrustList(old, _addr);
  }

}

// File: contracts/core/HToken.sol

pragma solidity >=0.4.21 <0.6.0;






contract HToken is ERC20Base, Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;

  address public target;
  uint256 public ratio_to_target;
  //uint256 public types; // 1 for in,2 for out, 3 for long term
  mapping (bytes32 => uint256) public extra;//record extra information of the token, including the round, type and ratio

  constructor(string memory _name, string memory _symbol, bool _transfersEnabled)
  ERC20Base(ERC20Base(address(0x0)), 0, _name, 18, _symbol, _transfersEnabled) public{}

  function reconstruct(string memory _name, string memory _symbol, bool _transfersEnabled) public onlyOwner{
    name = _name;
    symbol = _symbol;
    transfersEnabled = _transfersEnabled;
  }

  function mint(address addr, uint256 amount) onlyOwner public{
    _generateTokens(addr, amount);
  }
  function burnFrom(address addr, uint256 amount) onlyOwner public{
    _destroyTokens(addr, amount);
  }

  function set_extra(bytes32 _target, uint256 _value) onlyOwner public{
    extra[_target] = _value;
  }

  function set_target(address _target) onlyOwner public{
    target = _target;
  }

  function addTransferListener(address _addr) public onlyOwner{
    _addTransferListener(_addr);
  }
  function removeTransferListener(address _addr) public onlyOwner{
    _removeTransferListener(_addr);
  }

  event HTokenSetRatioToTarget(uint256 ratio_to);
  function set_ratio_to_target(uint256 _ratio_to) onlyOwner public{
    ratio_to_target = _ratio_to;
    emit HTokenSetRatioToTarget(_ratio_to);
  }
}

contract HTokenFactoryInterface{
  function createHToken(string memory _name, string memory _symbol, bool _transfersEnabled) public returns(address);
  function destroyHToken(address addr) public;
}

contract HTokenFactory is HTokenFactoryInterface{
  event NewHToken(address addr);
  event DestroyHToken(address addr);
  function createHToken(string memory _name, string memory _symbol, bool _transfersEnabled) public returns(address){
    HToken pt = new HToken(_name, _symbol, _transfersEnabled);
    pt.transferOwnership(msg.sender);
    emit NewHToken(address(pt));
    return address(pt);
  }
  function destroyHToken(address addr) public{
    //TODO, we choose do nothing here
    emit DestroyHToken(addr);
  }
}

// File: contracts/core/HInterfaces.sol

pragma solidity >=0.4.21 <0.6.0;


contract HLongTermInterface{
  function isRoundEnd(uint256 _period) public returns(bool);
  function getCurrentRound() public returns(uint256);
  function getRoundLength(uint256 _round) public view returns(uint256);
  function updatePeriodStatus() public returns(bool);
}
contract HTokenInterfaceGK{
  function mint(address addr, uint256 amount) public;
  function burnFrom(address addr, uint256 amount) public;
  function set_ratio_to_target(uint256 _balance) public;
  function set_extra(bytes32 _target, uint256 _value) public;
  function set_target(address _target) public;
  mapping (bytes32 => uint256) public extra;
  uint256 public ratio_to_target;
  function transferOwnership(address addr) public;
  function addTransferListener(address _addr) public;
  function removeTransferListener(address _addr) public;
}
contract HTokenAggregatorInterface{
  function mint(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 amount, address recv) public;
  function burn(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 amount, address recv) public;
  function balanceOf(address gk, uint256 round, uint256 ratio, uint256 _type, address recv) public view returns(uint256);
  function totalSupply(address gk, uint256 round, uint256 ratio, uint256 _type) public view returns(uint256);
  function getRatioTo(address gk, uint256 round, uint256 ratio, uint256 _type) public view returns(uint256);
  function setRatioTo(address gk, uint256 round, uint256 ratio, uint256 _type, uint256 ratio_to) public;

}
contract HDispatcherInterface{
  function getYieldStream(address _token_addr) public view returns (IYieldStream);
}
contract MinterInterfaceGK{
  function handle_bid_ratio(address addr, uint256 amount, uint256 ratio, uint256 round) public;
  function handle_withdraw(address addr, uint256 amount, uint256 ratio, uint256 round) public;
  function handle_cancel_withdraw(address addr, uint256 amount, uint256 ratio, uint256 round) public;
  function loop_prepare(uint256 fix_supply, uint256 float_supply, uint256 length, uint256 start_price, uint256 end_price) public;
  function handle_settle_round(uint256 ratio, uint256 ratio_to, uint256 intoken_ratio, uint256 lt_amount_in_ratio, uint256 nt) public;
  function handle_cancel_bid(address addr, uint256 amount, uint256 ratio, uint256 round) public;
}

// File: contracts/core/HGateKeeperParam.sol

pragma solidity >=0.4.21 <0.6.0;
pragma solidity >=0.4.21 <0.6.0;





library HGateKeeperParam{
  struct round_price_info{
    uint256 start_price;
    uint256 end_price;
  } //the start/end price of target token in a round.

  struct settle_round_param_info{
                      uint256 _round;
                       HDispatcherInterface dispatcher;
                       address target_token;
                       MinterInterfaceGK minter;
                       HLongTermInterface long_term;
                       HTokenAggregatorInterface aggr;
                       uint256[] sratios;
                       uint256 env_ratio_base;
                       address float_longterm_token;
                       address yield_interest_pool;
                       uint256 start_price;
                       uint256 end_price;
                       uint256 total_target_token;
                       uint256 total_target_token_next_round;
                       uint256 left;

  }
}

// File: contracts/core/HGateKeeperHelper.sol

pragma solidity >=0.4.21 <0.6.0;







library HGateKeeperHelper{

  using SafeMath for uint;
  using SafeERC20 for IERC20;
  event ThrowError(address gatekeeper, uint256 round, uint256 ratio);

  function _settle_round_for_one_ratio(HGateKeeperParam.settle_round_param_info storage info,
                        //mapping (uint256 => uint256) storage total_target_token_in_round,
                        mapping (bytes32 => uint256) storage target_token_amount_in_round_and_ratio,
                        mapping (bytes32 => uint256) storage long_term_token_amount_in_round_and_ratio,
                        uint256 i
      ) internal returns(uint256 s){
      // "hashs" and "hasht" corresponds to the index (hash) of the pair (_round, sratios[i]) and (_round + 1, sratios[i]),
      // the i-th ratio with current round, and the i-th ratio with the next round respectively.
      bytes32 hashs = keccak256(abi.encodePacked(info._round, info.sratios[i]));
      // "t" is actual amount of target token, invested for i-th ratio and current round,
      // including the value of longterm tokens and intokens.
      uint256 t = target_token_amount_in_round_and_ratio[hashs];
      // nt is the required interest for tokens invested for i-th ratio.
      // For example, if the i-th ratio is 5% and target token amount for this ratio is 10000,
      // start_price is 1e18, then nt = 500*1e18.
      uint256 nt = t.safeMul(info.start_price).safeMul(info.sratios[i]).safeDiv(info.env_ratio_base);
      /// require(info.long_term.get_long_term_token_with_ratio(info.sratios[i]) != address(0x0), "GK:Long term token not set");
      // simulate the distribution of total interest.
      // If the remaining interest can afford the required interest for i-th ratio,
      // then "nt" sets to be the require interest
      // Otherwise "nt" set to be the remain interest
      // So, "nt" is the actual received interest for i-th ratio.
      // The ramain interest ("left") decreases by "nt".
      if(nt > info.left){
        nt = info.left;
      }
      info.left = info.left.safeSub(nt);
      // now, set "t" to be the amount of target token (normalized to 1e18) distributed to i-th ratio and current round,
      // after the price of target token changing and the interests being distributed.
      // "t" times start price is the total price before,
      // then add "nt" is the total price after obtaining the distributed interest,
      // then div "end_price" to change the total price into the amount of target token, of new price
      t = t.safeMul(info.start_price).safeAdd(nt).safeDiv(info.end_price);

      // "ratio_to" computes the ratio of longterm token to target token, united in 1e18,
      // "long_term_token_amount_in_round_and_ratio[hashs]" records the amount of longterm tokens in i-th ratio and current round,
      // including all unexchanged intokens.
      // The default ratio is 1e18 if there is no longterm token.
      // "ratio_to" is a significant variable for updating all maintained values in "_updata_values()"
      uint256 ratio_to;
      if (long_term_token_amount_in_round_and_ratio[hashs] == 0){
        ratio_to = 1e18;
      }
      else{
        ratio_to = t.safeMul(1e18).safeDiv(long_term_token_amount_in_round_and_ratio[hashs]);
        if (ratio_to == 0) {ratio_to = 1e18; emit ThrowError(address(this), info._round, info.sratios[i]);}
      }
      //s = s.safeAdd(t);
      s = t;
      t = info.aggr.getRatioTo(address(this), 0, info.sratios[i], 3);

      //update minter info for this round
      
      if (info.minter != MinterInterfaceGK(0x0)){
        info.minter.handle_settle_round(
          info.sratios[i],
          t,
          uint256(1e36).safeDiv(ratio_to),
          long_term_token_amount_in_round_and_ratio[hashs],
          nt
        );
      }  
      
      // update the maintained values
      update_values(info, target_token_amount_in_round_and_ratio, long_term_token_amount_in_round_and_ratio, ratio_to, info.sratios[i]);
  }

  function _settle_round_for_tail(HGateKeeperParam.settle_round_param_info storage info,
                        //mapping (uint256 => uint256) storage total_target_token_in_round,
                        mapping (bytes32 => uint256) storage target_token_amount_in_round_and_ratio,
                        mapping (bytes32 => uint256) storage long_term_token_amount_in_round_and_ratio,
                        uint256 nt
                                 ) internal returns(uint256 s){

    //uint256 nt = left;
    // "left" now is the amount of target token should be allocated to floating.
    //left = total_target_token_in_round[info._round].safeSub(s);
    // handle for floating, similar to before.
    bytes32 hashs = keccak256(abi.encodePacked(info._round, uint256(0)));
    uint256 ratio_to;
    s = 0;
    if (long_term_token_amount_in_round_and_ratio[hashs] == 0){
      ratio_to = 1e18;
    }
    else{
      ratio_to = nt.safeMul(1e18).safeDiv(long_term_token_amount_in_round_and_ratio[hashs]);
      s = nt;
      if (ratio_to == 0) {ratio_to = 1e18; emit ThrowError(address(this), info._round, 0);}
      //s = s.safeAdd(left);
    }
    if (info.minter != MinterInterfaceGK(0x0)){
      info.minter.handle_settle_round(
        0,
        HTokenInterfaceGK(info.float_longterm_token).ratio_to_target(),
        uint256(1e36).safeDiv(ratio_to),
        long_term_token_amount_in_round_and_ratio[hashs],
        info.left
      );
    }
    update_values(info, target_token_amount_in_round_and_ratio, long_term_token_amount_in_round_and_ratio, ratio_to, 0);
}

  /// @dev This function is executed when the round (indexed by _round) is end.
  /// It does the settlement for current round with respect to the following things:
  /// 1.	It updates the value of all longterm tokens in target token, according to the price from yield stream in current round.
  /// It also sets the value of intokens and outtokens in the next round.
  /// 2.	It maintains the amount of longterm tokens (including unexchanged intokens) and target tokens in the next round.
  function settle_round(HGateKeeperParam.settle_round_param_info storage info,
                        //mapping (uint256 => uint256) storage total_target_token_in_round,
                        mapping (bytes32 => uint256) storage target_token_amount_in_round_and_ratio,
                        mapping (bytes32 => uint256) storage long_term_token_amount_in_round_and_ratio
                       ) public returns(uint256 settled_round){
    // get the price of target token from the yield stream. The unit is 1e18.
    if(info.end_price == 0){
      info.end_price = info.dispatcher.getYieldStream(info.target_token).getVirtualPrice();
    }
    /// "left" records the remaining interest in current round. The unit is 1e18.
    /// At the begining, it equals to the actual interest of all target tokens in current round.
    /// It then distributes to tokens invested for different ratio,
    // and decreases accordingly when it is consumed to fulfill interests.
    info.left = info.total_target_token.safeMul(info.end_price.safeSub(info.start_price));
    if (info.minter != MinterInterfaceGK(0x0)){
      info.minter.loop_prepare(
        info.total_target_token.safeSub(target_token_amount_in_round_and_ratio[keccak256(abi.encodePacked(info._round, uint256(0)))]),
        target_token_amount_in_round_and_ratio[keccak256(abi.encodePacked(info._round, uint256(0)))],
        info.long_term.getRoundLength(info._round),
        info.start_price,
        info.end_price
      );
    }
    uint256 s = 0;

    // The following FOR loop updates the value of all longterm tokens, for ratios from small to large.
    // It finally updates the value for floating.
    for(uint256 i = 0; i < info.sratios.length; i++){
      // "s" records the total amount of distributed target tokens.
      s = s.safeAdd(_settle_round_for_one_ratio(info, target_token_amount_in_round_and_ratio, long_term_token_amount_in_round_and_ratio, i));
    }
    {
      s = s.safeAdd(_settle_round_for_tail(info, target_token_amount_in_round_and_ratio, long_term_token_amount_in_round_and_ratio, info.total_target_token.safeSub(s)));
    }
    // for the case where there is no floating token,
    // the unallocated target tokens (if any) are transferred to our pool.
    if(s < info.total_target_token){
      s = info.total_target_token.safeSub(s);
      require(info.yield_interest_pool != address(0x0), "invalid yield interest pool");
      if (IERC20(info.target_token).balanceOf(address(this)) >= s){
        IERC20(info.target_token).safeTransfer(info.yield_interest_pool, s);
      }
      info.total_target_token_next_round = info.total_target_token_next_round.safeSub(s);
      //total_target_token_in_round[info._round + 1] =  total_target_token_in_round[info._round + 1].safeSub(s);
    }
    // update the variable "settled_round", means that "_round" is settled and "_round" + 1 should begin
    settled_round = info._round;
  }
  /// @dev the necessary update for maintained variables
  /// @param ratio the value of the i-th ratio (sratios[i])
  function update_values(
    HGateKeeperParam.settle_round_param_info storage info,
                        mapping (bytes32 => uint256) storage target_token_amount_in_round_and_ratio,
                        mapping (bytes32 => uint256) storage long_term_token_amount_in_round_and_ratio,
                        uint256 ratio_to, uint256 ratio) internal {
      uint256 in_target_amount;//how many newly-come target tokens for the next round.
      uint256 out_target_amount;//how many target tokens leave before the next round.
      uint256 in_long_term_amount;//how many newly-come longterm tokens for the next round.
      uint256 out_long_term_amount;//how many target tokens leave before the next round.

      //"hashs" and "hasht" are indexes the same as before
      bytes32 hashs = keccak256(abi.encodePacked(info._round, ratio));
      bytes32 hasht = keccak256(abi.encodePacked(info._round + 1, ratio));

      //set the ratio of the longterm token to target token.
      //recall that it is the definition of "ratio_to".
      //lt.set_ratio_to_target(ratio_to);
      if (ratio == 0){
        HTokenInterfaceGK(info.float_longterm_token).set_ratio_to_target(ratio_to);
      }
      else{
        info.aggr.setRatioTo(address(this), 0, ratio, 3, ratio_to);
      }
      
      //set the value of intoken in the next round, the ratio to longterm token.
      //since when the intoken is generated, its amount is 1:1 bind to target token,
      //so, the ratio of intoken to longterm token should be set to the reciprocal of "ratio_to".
      //HTokenInterfaceGK(info.long_term.hintokenAtPeriodWithRatio(info._round + 1, ratio)).set_ratio_to_target(uint256(1e36).safeDiv(ratio_to));
      in_target_amount = uint256(1e36).safeDiv(ratio_to);//temporarily use
      info.aggr.setRatioTo(address(this), info._round + 1, ratio, 1, in_target_amount);
      //since the amount of intoken is 1:1 to the target token,
      //the amount of newly-come target token equals to the total amount of intoken in the next round.
      //in_target_amount = info.long_term.totalInAtPeriodWithRatio(info._round + 1, ratio);
      in_target_amount = info.aggr.totalSupply(address(this), info._round + 1, ratio, 1);
      //compute the corresponding amount of newly-come longterm token.
      //since the ratio of intoken to longterm token has been set, compute it directly.
      //in_long_term_amount = info.long_term.totalInAtPeriodWithRatio(info._round + 1, ratio).safeMul(HTokenInterfaceGK(info.long_term.hintokenAtPeriodWithRatio(info._round + 1, ratio)).ratio_to_target()).safeDiv(1e18);
      in_long_term_amount = in_target_amount.safeMul(1e18).safeDiv(ratio_to); 
 
      //set the value of outtoken in the next round, the ratio to target token.
      //since when the outtoken is generated, its amount is 1:1 bind to long_term token at first,
      //the ratio of outtoken to target token should be set to "ratio_to".
      //HTokenInterfaceGK(info.long_term.houttokenAtPeriodWithRatio(info._round + 1, ratio)).set_ratio_to_target(ratio_to);
      info.aggr.setRatioTo(address(this), info._round + 1, ratio, 2, ratio_to);
      //compute the amount of target token that leaves. 
      //since the ratio of outtoken to target token has been set, compute it directly.
      out_target_amount = info.aggr.totalSupply(address(this), info._round + 1, ratio, 2).safeMul(ratio_to).safeDiv(1e18);
      //since the amount of outtoken is 1:1 to the longterm token at first,
      //the amount of longterm token that leaves equals to the total amount of intoken in the next round.
      out_long_term_amount = info.aggr.totalSupply(address(this), info._round + 1, ratio, 2);
   
      //update the amount of target token and long term token in the new round

      //compute the target token amount in i-th ratio for next round,
      //which means that this amount of target token joins in the game in i-th ratio and the next round.
      //It first computes the value of longterm token in target token after the price changing,
      //since the ratio_to is given.
      //It then adds the newly-come amount and subs the leave amount.
      target_token_amount_in_round_and_ratio[hasht] = long_term_token_amount_in_round_and_ratio[hashs].safeMul(ratio_to).safeDiv(1e18).safeAdd(in_target_amount).safeSub(out_target_amount);
      //The amount of total target token in the next round (to all ratios)
      //initially set to be the total target token amount in current round.
      if (ratio == info.sratios[0]) {
        //total_target_token_in_round[_round + 1] = total_target_token_in_round[_round];
        info.total_target_token_next_round = info.total_target_token;
      }
      //update the total target token amount in the next round,
      //by adding increment and subbing decrement for each ratio.
      info.total_target_token_next_round = info.total_target_token_next_round.safeAdd(in_target_amount).safeSub(out_target_amount);
      //total_target_token_in_round[_round + 1] =  total_target_token_in_round[_round + 1].safeAdd(in_target_amount).safeSub(out_target_amount);
      //update the longterm token amount in i-th ratio and the next round,
      //by taking the longterm token amount in i-th ratio and current round, and adding increment and subbing decrement.
      long_term_token_amount_in_round_and_ratio[hasht] = long_term_token_amount_in_round_and_ratio[hashs].safeAdd(in_long_term_amount).safeSub(out_long_term_amount);
      //Additional check: after update,
      //the amount of target token in i-th ratio and the next round,
      //should equal to the amount of longterm token in i-th ratio and the next round times ratio_to.
      //Due to the accuracy issue, we let the difference less than 10000(in 1e18).
      //(This should never happen)
      _abs_check(target_token_amount_in_round_and_ratio[hasht].safeMul(1e18), long_term_token_amount_in_round_and_ratio[hasht].safeMul(ratio_to));
  }

  function _abs_check(uint256 a, uint256 b) public pure{
    if (a >= b) {require (a.safeSub(b) <= 1e22, "GK: double check");}
    else {require (b.safeSub(a) <= 1e22, "GK: double check");}
  }
}

// File: contracts/core/HGateKeeper.sol

pragma solidity >=0.4.21 <0.6.0;

//import "../utils/SafeMath.sol";
//import "../erc20/SafeERC20.sol";








/// @notice Gatekeeper contains all user interfaces and updating values of tokens
contract HGateKeeper is Ownable{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using HGateKeeperHelper for HGateKeeperParam.settle_round_param_info;// mapping(uint256=>uint256) ;

  HDispatcherInterface public dispatcher;//the contracts to get the yield strem
  address public target_token;//the target token, e.g. yycurve
  HEnv public env;//the contract of environment variables, mainly the fee ratios

  HLongTermInterface public long_term;//the contract that maintain the period and generate/destroy all tokens.
  address public yield_interest_pool;//the pool that additional target tokens.
  HTokenAggregatorInterface public aggr;

  address public float_longterm_token;

  MinterInterfaceGK public minter;

  uint256 public settled_round;//the index of the round that has been settled
  uint256 public max_amount;//the max amount that a wallet allowd to bid.


  mapping (uint256 => HGateKeeperParam.round_price_info) public round_prices;//price info of all rounds

  mapping (bytes32 => uint256) target_token_amount_in_round_and_ratio;//amount of target token invested in a given round and ratio
  mapping (bytes32 => uint256) long_term_token_amount_in_round_and_ratio;//amount of longterm token in a given round and ratio
  mapping (uint256 => uint256) total_target_token_in_round;//amount of total target token invested in a round

  /// @dev Constructor to create a gatekeeper
  /// @param _token_addr Address of the target token, such as yUSD or yvUSDC
  /// @param _env Address of env, to get fee ratios
  /// @param _dispatcher Address of the dispatcher, to get yield stream
  /// @param _long_term Address of the Hlongterm contract, to generate/destroy in/out-tokens.
  constructor(address _token_addr, address _env, address _dispatcher, address _long_term, address _float_token, address _aggr) public{
    target_token = _token_addr;
    env = HEnv(_env);
    dispatcher = HDispatcherInterface(_dispatcher);
    long_term = HLongTermInterface(_long_term);
    settled_round = 0;
    aggr = HTokenAggregatorInterface(_aggr);
    float_longterm_token = _float_token;
  }

  event ChangeMaxAmount(uint256 old, uint256 _new);
  function set_max_amount(uint _amount) public onlyOwner{
    uint256 old = max_amount;
    max_amount = _amount;
    emit ChangeMaxAmount(old, max_amount);
  }

  event HorizonBid(address from, uint256 amount, uint256 share, uint256 round, uint256 ratio);
  /// @dev User invests terget tokens to the contract to take part in the game in the next round and further rounds.
  /// User gets intokens with respect to the next round.
  /// @param _amount The amount of target token that the user invests
  /// @param _ratio The ratio that the user chooses.
  function bidRatio(uint256 _amount, uint256 _ratio) public{
    require(_ratio == 0 || isSupportRatio(_ratio), "not support ratio");    
    _check_round();

    require(IERC20(target_token).allowance(msg.sender, address(this)) >= _amount, "not enough allowance");
    uint _before = IERC20(target_token).balanceOf(address(this));
    IERC20(target_token).safeTransferFrom(msg.sender, address(this), _amount);
    uint256 _after = IERC20(target_token).balanceOf(address(this));
    _amount = _after.safeSub(_before); // Additional check for deflationary tokens

    uint256 decimal = dispatcher.getYieldStream(target_token).getDecimal();
    require(decimal <= 1e18, "decimal too large");
    uint256 shares = _amount.safeMul(1e18).safeDiv(decimal);//turn into 1e18 decimal

    if(max_amount > 0){
      require(shares <= max_amount, "too large amount");
      require(aggr.balanceOf(address(this), settled_round + 2, _ratio, 1, msg.sender).safeAdd(shares) <= max_amount, "Please use another wallet");
    }
    aggr.mint(address(this), settled_round + 2, _ratio, 1, shares, msg.sender);
    //HTokenInterfaceGK(in_addr).mint(msg.sender, shares);

    if (minter != MinterInterfaceGK(0x0)){
      MinterInterfaceGK(minter).handle_bid_ratio(msg.sender, shares, _ratio, settled_round + 2);
    }
    emit HorizonBid(msg.sender, _amount, shares, settled_round + 2, _ratio);
  }

  function bidFloating(uint256 _amount) public{
    bidRatio(_amount, 0);
  }
  event CancelBid(address from, uint256 amount, uint256 fee, uint256 round, uint256 ratio);
  function cancelBid(uint256 amount, uint256 _ratio) public{
    //user can only cancel bid for the next round (during the current round period)
    require(_ratio == 0 || isSupportRatio(_ratio), "not support ratio");
    _check_round();

    //HTokenInterfaceGK(_in_token_addr).burnFrom(msg.sender, amount);
    aggr.burn(address(this), settled_round + 2, _ratio, 1, amount, msg.sender);
    
    uint256 decimal = dispatcher.getYieldStream(target_token).getDecimal();

    uint256 target_amount = amount.safeMul(decimal).safeDiv(1e18);

    if (minter != MinterInterfaceGK(0x0)){
      MinterInterfaceGK(minter).handle_cancel_bid(msg.sender, amount, _ratio, settled_round + 2);
    }

    if(env.cancel_fee_ratio() != 0 && env.fee_pool_addr() != address(0x0)){
      uint256 fee = target_amount.safeMul(env.cancel_fee_ratio()).safeDiv(env.ratio_base());
      uint256 recv = target_amount.safeSub(fee);
      IERC20(target_token).safeTransfer(msg.sender, recv);
      IERC20(target_token).safeTransfer(env.fee_pool_addr(), fee);
      emit CancelBid(msg.sender, recv, fee, settled_round + 2, _ratio);
    }else{
      IERC20(target_token).safeTransfer(msg.sender, target_amount);
      emit CancelBid(msg.sender, target_amount, 0, settled_round + 2, _ratio);
    }
  }
   /*
  function changeBid(address _in_token_addr, uint256 _new_amount, uint256 _new_ratio) public{
    cancelBid(_in_token_addr);
    bidRatio(_new_amount, _new_ratio);
  }*/

  event HorizonWithdrawLongTermToken(address from, uint256 amount, uint256 round, uint256 ratio);
  /// @dev User changes longterm tokens to outtokens with respect to the next round,
  /// meaning that he quits the game by the next round.
  /// @param _amount The amount of longterm token that the user wants to withdraw.
  function withdrawLongTerm(uint256 ratio, uint256 _amount) public{
    _check_round();
    uint256 total_amount;
    if (ratio == 0){
      require(IERC20(float_longterm_token).balanceOf(msg.sender) >= _amount, "GK:not enough balance");
      HTokenInterfaceGK(float_longterm_token).burnFrom(msg.sender, _amount);
    }
    else{
      total_amount = aggr.balanceOf(address(this), 0, ratio, 3, msg.sender);
      aggr.burn(address(this), 0, ratio, 3, _amount, msg.sender);
    }
    aggr.mint(address(this), settled_round + 2, ratio, 2, _amount, msg.sender);
    //HTokenInterfaceGK(out_addr).mint(msg.sender, _amount);
    if (minter != MinterInterfaceGK(0x0)){
      MinterInterfaceGK(minter).handle_withdraw(msg.sender, _amount, ratio, settled_round + 2);
    }

    emit HorizonWithdrawLongTermToken(msg.sender, _amount, settled_round + 2, ratio);
  }


  function withdrawInToken(uint256 ratio, uint256 round, uint256 _amount) public{
    require(ratio == 0 || isSupportRatio(ratio), "not support ratio");
    _check_round();
    require(settled_round + 1 >= round, "GK: round not sealed");

    uint256 amount = aggr.balanceOf(address(this), round, ratio, 1, msg.sender);

    require(_amount <= amount, "GK: not enough intoken balance");
    aggr.burn(address(this), round, ratio, 1, amount, msg.sender);

    uint256 ratio_to = aggr.getRatioTo(address(this), round, ratio, 1);
    uint256 lt_amount = amount.safeMul(ratio_to).safeDiv(1e18);

    emit HorizonExchangeToLongTermToken(msg.sender, _amount, lt_amount, round, ratio);

    aggr.mint(address(this), settled_round + 2, ratio, 2, _amount, msg.sender);    
    if (minter != MinterInterfaceGK(0x0)){
      MinterInterfaceGK(minter).handle_withdraw(msg.sender, lt_amount, ratio, settled_round + 2);
    }

    emit HorizonWithdrawLongTermToken(msg.sender, lt_amount, settled_round + 2, ratio);
  }
  event HorizonCancelWithdraw(address from, uint256 amount, uint256 ratio, uint256 round);
  /// @dev User cancel his/her withdraw operation,
  /// changing all outtokens back to longterm token.
  function cancelWithdraw(uint256 _ratio, uint256 _amount) public{
    require(_ratio == 0 || isSupportRatio(_ratio), "not support ratio");
    _check_round();
    aggr.burn(address(this), settled_round + 2, _ratio, 2, _amount, msg.sender);
    
    if (_ratio == 0){
      HTokenInterfaceGK(float_longterm_token).mint(msg.sender, _amount);
    }
    else
    {
      aggr.mint(address(this), 0, _ratio, 3, _amount, msg.sender);
    }
    if (minter != MinterInterfaceGK(0x0)){
      MinterInterfaceGK(minter).handle_cancel_withdraw(msg.sender, _amount, _ratio, settled_round + 2);
    }

    emit HorizonCancelWithdraw(msg.sender, _amount, _ratio, settled_round + 2);
  }

  event HorizonClaim(address from, uint256 amount, uint256 fee, uint256 round, uint256 ratio);
  /// @dev User withdraws outtokens to get target tokens.
  /// @param _amount The amount of outtoken.
  function claim(uint256 round, uint256 ratio, uint256 _amount) public {
    require(ratio == 0 || isSupportRatio(ratio), "not support ratio");
    _check_round();

    require(settled_round + 1 >= round, "GK: period not end");

    uint256 decimal = dispatcher.getYieldStream(target_token).getDecimal();
    uint256 ratio_to = aggr.getRatioTo(address(this), round, ratio, 2);
    uint256 t = _amount.safeMul(ratio_to).safeMul(decimal).safeDiv(1e36);//turn into target decimal

    aggr.burn(address(this), round, ratio, 2, _amount, msg.sender);

    if(env.withdraw_fee_ratio() != 0 && env.fee_pool_addr() != address(0x0)){
      uint256 fee = t.safeMul(env.withdraw_fee_ratio()).safeDiv(env.ratio_base());
      uint256 recv = t.safeSub(fee);
      IERC20(target_token).safeTransfer(msg.sender, recv);
      IERC20(target_token).safeTransfer(env.fee_pool_addr(), fee);
      emit HorizonClaim(msg.sender, recv, fee, round, ratio);
    }else{
      IERC20(target_token).safeTransfer(msg.sender, t);
      emit HorizonClaim(msg.sender, t, 0, round, ratio);
    }
  }

  event HorizonExchangeToLongTermToken(address from, uint256 amount_in, uint256 amount_long, uint256 round, uint256 ratio);
  /// @dev User changes all intokens to long-term tokens,
  /// so that the user can withdraw to outtoken or transfer in secondary markets.
  function exchangeToLongTermToken(uint256 round, uint256 ratio) public{
    //require(ratio == 0 || isSupportRatio(ratio), "not support ratio");
    require(ratio == 0, "not support ratio");
    _check_round();
    require(settled_round + 1 >= round, "GK: round not sealed");

    uint256 amount = aggr.balanceOf(address(this), round, ratio, 1, msg.sender);
    require(amount > 0, "GK: no in token balance");

    aggr.burn(address(this), round, ratio, 1, amount, msg.sender);

    uint256 ratio_to = aggr.getRatioTo(address(this), round, ratio, 1);

    uint256 rec = amount.safeMul(ratio_to).safeDiv(1e18);
    
    if (ratio == 0){
      HTokenInterfaceGK(float_longterm_token).mint(msg.sender, rec);
    }
    else{
      aggr.mint(address(this), 0, ratio, 3, rec, msg.sender);
    }
    emit HorizonExchangeToLongTermToken(msg.sender, amount, rec, round, ratio);
  }

  /// @dev To check whether the current round should end.
  /// If so, do settlement for the current round and begin a new round.
  HGateKeeperParam.settle_round_param_info info;
  function _check_round() internal{
    long_term.updatePeriodStatus();
    uint256 new_period = long_term.getCurrentRound();
    if(round_prices[new_period].start_price == 0){
      round_prices[new_period].start_price = dispatcher.getYieldStream(target_token).getVirtualPrice();
    }
    if(long_term.isRoundEnd(settled_round + 1)){
      /*HGateKeeperParam.settle_round_param_info memory info*/ info = HGateKeeperParam.settle_round_param_info({
                      _round:settled_round+1,
                       dispatcher:dispatcher,
                       target_token:target_token,
                       minter:minter,
                       long_term:long_term,
                       aggr:aggr,
                       sratios:sratios,
                       env_ratio_base:env.ratio_base(),
                       float_longterm_token:float_longterm_token,
                       yield_interest_pool:yield_interest_pool,
                       start_price:round_prices[settled_round+1].start_price,
                       end_price:round_prices[settled_round+1].end_price,
                       total_target_token:total_target_token_in_round[settled_round+1],
                       total_target_token_next_round:total_target_token_in_round[settled_round+2],
                       left: 0
      });
      settled_round =
        info.settle_round(target_token_amount_in_round_and_ratio, long_term_token_amount_in_round_and_ratio);
      total_target_token_in_round[settled_round + 1] = total_target_token_in_round[settled_round + 1].safeAdd(info.total_target_token_next_round);
    }
  }

  mapping (uint256 => bool) public support_ratios;
  uint256[] public sratios;

  event SupportRatiosChanged(uint256[] rs);
  function resetSupportRatios(uint256[] memory rs) public onlyOwner{
    for(uint i = 0; i < sratios.length; i++){
      delete support_ratios[sratios[i]];
    }
    delete sratios;
    for(uint i = 0; i < rs.length; i++){
      if(i > 0){
        require(rs[i] > rs[i-1], "should be ascend");
      }
      sratios.push(rs[i]);
      support_ratios[rs[i]] = true;
    }
    emit SupportRatiosChanged(sratios);
  }

  function isSupportRatio(uint256 r) public view returns(bool){
    for(uint i = 0; i < sratios.length; i++){
      if(sratios[i] == r){
        return true;
      }
    }
    return false;
  }
  function updatePeriodStatus() public{
    _check_round();
  }


  event ChangeYieldInterestPool(address old, address _new);
  function changeYieldPool(address _pool) onlyOwner public{
    require(_pool != address(0x0), "invalid pool");
    address old = yield_interest_pool;
    yield_interest_pool = _pool;
    emit ChangeYieldInterestPool(old, _pool);
  }
  event SetMinter(address addr);
  function set_minter(address addr) onlyOwner public{
    minter = MinterInterfaceGK(addr);
    emit SetMinter(addr);
  }
  
  function add_transfer_listener_to(address _listener) onlyOwner public{
    HTokenInterfaceGK(float_longterm_token).addTransferListener(_listener);
  }
  function remove_transfer_listener_to(address _listener) onlyOwner public{
    HTokenInterfaceGK(float_longterm_token).removeTransferListener(_listener);
  }
}

contract HGateKeeperFactory is Ownable{
  event NewGateKeeper(address addr);

  function createGateKeeperForPeriod(address _env_addr, address _dispatcher, address _long_term, address _float_token, address _aggr) public returns(address){
    HEnv e = HEnv(_env_addr);
    HGateKeeper gk = new HGateKeeper(e.token_addr(), _env_addr, _dispatcher, _long_term, _float_token, _aggr);
    gk.transferOwnership(msg.sender);
    emit NewGateKeeper(address(gk));
    return address(gk);
  }
}