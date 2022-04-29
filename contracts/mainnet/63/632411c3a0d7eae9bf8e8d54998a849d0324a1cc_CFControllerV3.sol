/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

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


contract ReentrancyGuard {
    uint256 private _guardCounter;

    constructor () internal {
        _guardCounter = 1;
    }

    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}


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


library SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "add");
    }
    function safeSubR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b <= a, s);
        c = a - b;
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
    function safeDivR(uint a, uint b, string memory s) public pure returns (uint c) {
        require(b > 0, s);
        c = a / b;
    }
}


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




contract TransferableTokenHelper{
  uint256 public decimals;
}

library TransferableToken{
  using SafeERC20 for IERC20;

  function transfer(address target_token, address payable to, uint256 amount) public {
    if(target_token == address(0x0)){
      (bool status, ) = to.call.value(address(this).balance)("");
      require(status, "TransferableToken, transfer eth failed");
    }else{
      IERC20(target_token).safeTransfer(to, amount);
    }
  }

  function balanceOfAddr(address target_token, address _of) public view returns(uint256){
    if(target_token == address(0x0)){
      return address(_of).balance;
    }else{
      return IERC20(target_token).balanceOf(address(_of));
    }
  }

  function decimals(address target_token) public view returns(uint256) {
    if(target_token == address(0x0)){
      return 18;
    }else{
      return TransferableTokenHelper(target_token).decimals();
    }
  }
}























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
    string public version = "AET_0.1"; //An arbitrary versioning scheme

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



contract CFControllerInterface{
  function withdraw(uint256 _amount) public;
  function deposit(uint256 _amount) public;
  function get_current_pool() public view returns(ICurvePool);
}

contract TokenInterfaceERC20{
  function destroyTokens(address _owner, uint _amount) public returns(bool);
  function generateTokens(address _owner, uint _amount) public returns(bool);
}

contract CFVaultV2 is Ownable, ReentrancyGuard{
  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using Address for address;
  using TransferableToken for address;

  address public target_token;
  CFControllerInterface public controller;

  uint256 public ratio_base;
  uint256 public withdraw_fee_ratio;
  address payable public fee_pool;
  address public lp_token;
  uint256 public max_amount;
  uint256 public slip;

  //@param _target_token, means ETH if it's 0x0
  constructor(address _target_token, address _lp_token, address _controller) public {
    require(_controller != address(0x0), "invalid controller");
    target_token = _target_token;
    controller = CFControllerInterface(_controller);
    ratio_base = 10000;
    lp_token = _lp_token;
  }

  event ChangeMaxAmount(uint256 old, uint256 _new);
  function set_max_amount(uint _amount) public onlyOwner{
    uint256 old = max_amount;
    max_amount = _amount;
    emit ChangeMaxAmount(old, max_amount);
  }

  event CFFDeposit(address from, uint256 target_amount, uint256 cff_amount, uint256 virtual_price);
  event CFFDepositFee(address from, uint256 target_amount, uint256 fee_amount);

  event ChangeSlippage(uint256 old, uint256 _new);
  function set_slippage(uint256 _slip) public onlyOwner{
    //base: 10000
    uint256 old = slip;
    slip = _slip;
    emit ChangeSlippage(old, slip);
  }

  function deposit(uint256 _amount) public payable nonReentrant{
    require(controller != CFControllerInterface(0x0) && controller.get_current_pool() != ICurvePool(0x0), "paused");
    if(target_token == address(0x0)){
      require(_amount == msg.value, "inconsist amount");
    }else{
      require(IERC20(target_token).allowance(msg.sender, address(this)) >= _amount, "CFVault: not enough allowance");
    }

    require(_amount <= max_amount, "too large amount");
    require(slip != 0, "Slippage not set");
    require(_amount != 0, "too small amount");


    uint tt_before = TransferableToken.balanceOfAddr(target_token, address(controller.get_current_pool()));
    if(target_token != address(0x0)){
      IERC20(target_token).safeTransferFrom(msg.sender, address(controller.get_current_pool()), _amount);
    }else{
      TransferableToken.transfer(target_token, address(controller.get_current_pool()).toPayable(), _amount);
    }
    uint tt_after = TransferableToken.balanceOfAddr(target_token, address(controller.get_current_pool()));
    require(tt_after.safeSub(tt_before) == _amount, "token inflation");

    uint256 lp_amount;
    uint lp_before = controller.get_current_pool().get_lp_token_balance();
    {
      uint dec = uint(10)**(TransferableToken.decimals(target_token));
      uint vir = controller.get_current_pool().get_virtual_price();
      uint min_amount = _amount.safeMul(uint(1e32)).safeMul(slip).safeDiv(dec).safeDiv(vir);


      controller.deposit(_amount);

      uint lp_after = controller.get_current_pool().get_lp_token_balance();
      lp_amount = lp_after.safeSub(lp_before);

      require(lp_amount >= min_amount, "Slippage");
    }

    uint256 d = ERC20Base(controller.get_current_pool().get_lp_token_addr()).decimals();
    require(d <= 18, "invalid decimal");
    uint cff_amount = 0;
    if (lp_before == 0){
      cff_amount = lp_amount.safeMul(uint256(10)**18).safeDiv(uint256(10)**d);
    }
    else{
      cff_amount = lp_amount.safeMul(IERC20(lp_token).totalSupply()).safeDiv(lp_before);
    }
    TokenInterfaceERC20(lp_token).generateTokens(msg.sender, cff_amount);
    emit CFFDeposit(msg.sender, _amount, cff_amount, get_virtual_price());
  }


  event CFFWithdraw(address from, uint256 target_amount, uint256 cff_amount, uint256 target_fee, uint256 virtual_price);
  //@_amount: CFLPToken amount
  function withdraw(uint256 _amount) public nonReentrant{
    require(controller != CFControllerInterface(0x0) && controller.get_current_pool() != ICurvePool(0x0), "paused");
    require(slip != 0, "Slippage not set");
    uint256 amount = IERC20(lp_token).balanceOf(msg.sender);
    require(amount >= _amount, "no enough LP tokens");

    uint LP_token_amount = _amount.safeMul(controller.get_current_pool().get_lp_token_balance()).safeDiv(IERC20(lp_token).totalSupply());

    uint dec = uint(10)**(TransferableToken.decimals(target_token));
    uint vir = controller.get_current_pool().get_virtual_price();
    uint min_amount = LP_token_amount.safeMul(vir).safeMul(slip).safeMul(dec).safeDiv(uint(1e40));

    uint256 _before = TransferableToken.balanceOfAddr(target_token, address(this));
    controller.withdraw(LP_token_amount);
    uint256 _after = TransferableToken.balanceOfAddr(target_token, address(this));
    uint256 target_amount = _after.safeSub(_before);

    require(target_amount >= min_amount, "Slippage");


    if(withdraw_fee_ratio != 0 && fee_pool != address(0x0)){
      uint256 f = target_amount.safeMul(withdraw_fee_ratio).safeDiv(ratio_base);
      uint256 r = target_amount.safeSub(f);
      TransferableToken.transfer(target_token, msg.sender, r);
      TransferableToken.transfer(target_token, fee_pool, f);
      TokenInterfaceERC20(lp_token).destroyTokens(msg.sender, _amount);
      emit CFFWithdraw(msg.sender, r, _amount, f, get_virtual_price());
    }else{
      TransferableToken.transfer(target_token, msg.sender, target_amount);
      TokenInterfaceERC20(lp_token).destroyTokens(msg.sender, _amount);
      emit CFFWithdraw(msg.sender, target_amount, _amount, 0, get_virtual_price());
    }
  }

  event ChangeWithdrawFee(uint256 old, uint256 _new);
  function changeWithdrawFee(uint256 _fee) public onlyOwner{
    require(_fee < ratio_base, "invalid fee");
    uint256 old = withdraw_fee_ratio;
    withdraw_fee_ratio = _fee;
    emit ChangeWithdrawFee(old, withdraw_fee_ratio);
  }

  event ChangeController(address old, address _new);
  function changeController(address _ctrl) public onlyOwner{
    address old = address(controller);
    controller = CFControllerInterface(_ctrl);
    emit ChangeController(old, address(controller));
  }

  event ChangeFeePool(address old, address _new);
  function changeFeePool(address payable _fp) public onlyOwner{
    address old = fee_pool;
    fee_pool = _fp;
    emit ChangeFeePool(old, fee_pool);
  }

  function get_virtual_price() public view returns(uint256){
    ICurvePool cp = controller.get_current_pool();
    uint256 v1 = cp.get_lp_token_balance().safeMul(uint256(10)**ERC20Base(lp_token).decimals());
    uint256 v2 = IERC20(lp_token).totalSupply().safeMul(uint256(10) ** ERC20Base(cp.get_lp_token_addr()).decimals());
    if(v2 == 0){
      return 0;
    }
    return v1.safeMul(cp.get_virtual_price()).safeDiv(v2);
  }

  function get_asset() public view returns(uint256) {
      return controller.get_current_pool().get_lp_token_balance();
  }

  function() external payable{}
}

contract CFVaultV2Factory{
  event NewCFVault(address addr);

  function createCFVault(address _target_token, address _lp_token, address _controller) public returns(address){
    CFVaultV2 cf = new CFVaultV2(_target_token, _lp_token, _controller);
    cf.transferOwnership(msg.sender);
    emit NewCFVault(address(cf));
    return address(cf);
  }

}


// legacy interface for this
contract ICurvePool {
    function deposit(uint256 _amount) public;
    function withdraw(uint256 _amount) public;
    function earnReward(address[] memory yieldtokens) public;

    function get_virtual_price() public view returns(uint256);
    function get_lp_token_balance() public view returns(uint256);
    function get_lp_token_addr() public view returns(address);

    function setController(address, address) public;
}

// external interfaces
contract ICurveDepositGate {
    function add_liquidity(address _pool, uint256[4] memory _deposit_amounts, uint256 _min_mint_amount) public;
    function remove_liquidity_one_coin(address _pool, uint256 _burn_amount, int128 i, uint256 _min_amount) public;
}
contract ICurveVirtualPrive{
    function get_virtual_price() public view returns(uint256);
}
contract IFeiDelegator is IERC20 {
    function balanceOfUnderlying(address owner) public returns(uint256);
    function mint(uint256 mintAmount) public;
    function redeemUnderlying(uint256 redeemAmount) public;
}
contract IFeiRewardsDistributor {
    function claimRewards(address holder, address[] memory cTokens) public;
}

contract CFPoolV3 is Ownable, ICurvePool{
    using SafeMath for uint256;

    address public controller;
    address public vault;

    IERC20 public target_token;
    ICurveDepositGate public curve_deposit_gate;
    IERC20 public curve_lp_token;
    IFeiDelegator public fei_delegator;
    IFeiRewardsDistributor public fei_rewards_distributor;
    
    uint256 public underlying_curve_lp_balance;   // curve lp

    constructor(address _fei_delegator, address _fei_rewards_distributor) public {
        // pool spcificly build for Fei.money
        target_token = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        curve_deposit_gate = ICurveDepositGate(0xA79828DF1850E8a3A3064576f380D90aECDD3359);
        curve_lp_token = IERC20(0x06cb22615BA53E60D67Bf6C341a0fD5E718E1655);
        fei_delegator = IFeiDelegator(_fei_delegator); // passing as param for test purpose
        fei_rewards_distributor = IFeiRewardsDistributor(_fei_rewards_distributor);
    }

    modifier onlyAdmin() {
        require(msg.sender == controller || msg.sender == vault);
        _;
    }
    
    /**
     * on start, target token already at dealer
     * deposit to curve'pool and then fei's pool
     */
    function deposit(uint256 amount) public onlyAdmin {
        // deposit to curve's f3 pool
        target_token.approve(address(curve_deposit_gate), 0);
        target_token.approve(address(curve_deposit_gate), amount);
        curve_deposit_gate.add_liquidity(address(curve_lp_token), [0, 0, amount, 0], 0);
        
        // deposit to fei's pool
        uint256 curve_lp_amount = curve_lp_token.balanceOf(address(this));
        curve_lp_token.approve(address(fei_delegator), 0);
        curve_lp_token.approve(address(fei_delegator), curve_lp_amount);
        fei_delegator.mint(curve_lp_amount);

        underlying_curve_lp_balance = underlying_curve_lp_balance+curve_lp_amount;
    }

    /**
     * withdraw from fei's pool
     * withdraw from curve's pool
     * send back to vault
     * @param amount in fei's lp token
     */
    function withdraw(uint256 amount) public onlyAdmin {
        // withdraw from fei's pool
        // require(amount < fei_delegator.balanceOf(address(this)))
        fei_delegator.redeemUnderlying(amount);
        // withdraw from curve's pool
        uint256 curve_lp_amount = curve_lp_token.balanceOf(address(this));
        curve_lp_token.approve(address(curve_deposit_gate), 0);
        curve_lp_token.approve(address(curve_deposit_gate), curve_lp_amount);
        curve_deposit_gate.remove_liquidity_one_coin(address(curve_lp_token), curve_lp_amount, 2, 0);

        target_token.transfer(vault, target_token.balanceOf(address(this)));
        underlying_curve_lp_balance = underlying_curve_lp_balance-curve_lp_amount;
    }

    /**
     * mint rewards
     * transfer to controller
     */
    function earnReward(address[] memory yield_tokens) public onlyAdmin {
        address[] memory ctokens = new address[](1);
        ctokens[0] = address(fei_delegator);
        fei_rewards_distributor.claimRewards(address(this), ctokens);

        for (uint i = 0; i < yield_tokens.length; i++) {
            uint256 balance = IERC20(yield_tokens[i]).balanceOf(address(this));
            IERC20(yield_tokens[i]).transfer(controller, balance);
        }
    }

    
    function get_lp_token_balance() public view returns(uint256) {
        return underlying_curve_lp_balance;
    }
    function get_lp_token_addr() public view returns(address) {
        return address(fei_delegator);
    }
    function get_virtual_price() public view returns(uint256) {
        uint256 vir = ICurveVirtualPrive(address(curve_lp_token)).get_virtual_price();
        //uint256 b = fei_delegator.balanceOf(address(this));
        //return underlying_curve_lp_balance.safeMul(vir);
        return vir;
    }

    function setController(address _controller) public onlyOwner {
        controller = _controller;
    }

    function setController(address _controller, address _vault) public onlyOwner{
        controller = _controller;
        vault = _vault;
    }

    function setVault(address _vault) public onlyOwner {
        vault = _vault;
    }
}







contract YieldHandlerInterface{
  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public;
}

contract SushiUniInterfaceERC20{
  function getAmountsOut(uint256 amountIn, address[] memory path) public view returns(uint256[] memory);
  function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint256 amountIn,   uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external ;
  function swapExactTokensForETHSupportingFeeOnTransferTokens(uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline) external;
}


contract CRVExchangeV2 is Ownable{
  address public crv_token;
  using AddressArray for address[];
  using SafeERC20 for IERC20;

  struct path_info{
    address dex;
    address[] path;
  }
  mapping(bytes32 => path_info) public paths;
  bytes32[] public path_indexes;

  address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

  constructor(address _crv) public{
    if(_crv == address(0x0)){
      crv_token = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    }else{
      crv_token = _crv;
    }
  }
  function path_from_addr(uint index) public view returns(address){
    return paths[path_indexes[index]].path[0];
  }
  function path_to_addr(uint index) public view returns(address){
    return paths[path_indexes[index]].path[paths[path_indexes[index]].path.length - 1];
  }

  function handleCRV(address target_token, uint256 amount, uint min_amount) public{
    handleExtraToken(crv_token, target_token, amount, min_amount);
  }

  function handleExtraToken(address from, address target_token, uint256 amount, uint min_amount) public{
    uint256 maxOut = 0;
    uint256 fpi = 0;

    for(uint pi = 0; pi < path_indexes.length; pi ++){
      if(path_from_addr(pi) != from || path_to_addr(pi) != target_token){
        continue;
      }
      uint256 t = get_out_for_dex_path(pi, amount);
      if( t > maxOut ){
        fpi = pi;
        maxOut = t;
      }
    }

    address dex = paths[path_indexes[fpi]].dex;
    IERC20(from).safeTransferFrom(msg.sender, address(this), amount);
    IERC20(from).safeApprove(dex, amount);
    if(target_token == weth){
      SushiUniInterfaceERC20(dex).swapExactTokensForETHSupportingFeeOnTransferTokens(amount, min_amount, paths[path_indexes[fpi]].path, address(this), block.timestamp + 10800);
      uint256 target_amount = address(this).balance;
      require(target_amount >= min_amount, "slippage screwed you");
      (bool status, ) = msg.sender.call.value(target_amount)("");
      require(status, "CRVExchange transfer eth failed");
    }else{
      SushiUniInterfaceERC20(dex).swapExactTokensForTokensSupportingFeeOnTransferTokens(amount, min_amount, paths[path_indexes[fpi]].path, address(this), block.timestamp + 10800);
      uint256 target_amount = IERC20(target_token).balanceOf(address(this));
      require(target_amount >= min_amount, "slippage screwed you");
      IERC20(target_token).safeTransfer(address(msg.sender), target_amount);
    }
  }

  function get_out_for_dex_path(uint pi, uint256 _amountIn) internal view returns(uint256) {
    address dex = paths[path_indexes[pi]].dex;
    uint256[] memory ret = SushiUniInterfaceERC20(dex).getAmountsOut(_amountIn, paths[path_indexes[pi]].path);
    return ret[ret.length - 1];
  }

  event AddPath(bytes32 hash, address dex, address[] path);
  function addPath(address dex, address[] memory path) public onlyOwner{
    SushiUniInterfaceERC20(dex).getAmountsOut(1e18, path); //This is a double check
    bytes32 hash = keccak256(abi.encodePacked(dex, path));
    require(paths[hash].path.length == 0, "already exist path");
    path_indexes.push(hash);
    paths[hash].path = path;
    paths[hash].dex = dex;
    emit AddPath(hash, dex, path);
  }

  event RemovePath(bytes32 hash);
  function removePath(address dex, address[] memory path) public onlyOwner{
    bytes32 hash = keccak256(abi.encodePacked(dex, path));
    removePathWithHash(hash);
  }

  function removePathWithHash(bytes32 hash) public onlyOwner{
    require(paths[hash].path.length != 0, "path not exist");
    delete paths[hash];
    for(uint i = 0; i < path_indexes.length; i++){
      if(path_indexes[i] == hash){
          path_indexes[i] = path_indexes[path_indexes.length - 1];
          delete path_indexes[path_indexes.length - 1];
          path_indexes.length --;
          emit RemovePath(hash);
          break;
      }
    }
  }

  function() external payable{}
}



contract CFControllerV3 is Ownable {
    using SafeERC20 for IERC20;
    using TransferableToken for address;
    using AddressArray for address[];
    using SafeMath for uint256;
    using Address for address;

    address public pool;

    uint256 public last_earn_block;
    uint256 public earn_gap;
    address public target_token;
    address[] public yield_tokens;

    address public fee_pool;
    uint256 public harvest_fee_ratio;
    uint256 public ratio_base;


    YieldHandlerInterface public yield_handler;

    address public vault;
    address weth = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    //@param _target, when it's 0, means ETH
    constructor(address _target, uint256 _earn_gap) public{
        last_earn_block = 0;
        require(_target != address(0x0), "invalid target address");
        require(_earn_gap != 0, "invalid earn gap");
        target_token = _target;
        earn_gap = _earn_gap;
        ratio_base = 10000;
    }

    function setVault(address _vault) public onlyOwner{
        require(_vault != address(0x0), "invalid vault");
        vault = _vault;
    }

    modifier onlyVault{
        require(msg.sender == vault, "only vault can call this");
        _;
    }

    function get_current_pool() public view returns(ICurvePool) {
        return ICurvePool(pool);
    }

    function deposit(uint256 _amount) public onlyVault {
        ICurvePool(pool).deposit(_amount);
    }

    function withdraw(uint256 _amount) public onlyVault{
        ICurvePool(pool).withdraw(_amount);
    }

    event EarnExtra(address addr, address token, uint256 amount);
    /**
    * @param min_amount in target token
    * @notice least min_amount blocks to call this
    */
    function earnReward(uint min_amount) public onlyOwner{
        require(yield_handler != YieldHandlerInterface(0x0), "invalid yield handler");
        require(block.number.safeSub(last_earn_block) >= earn_gap, "not long enough");
        last_earn_block = block.number;

        // call earn yield here
        ICurvePool(pool).earnReward(yield_tokens);
        // @here: yield tokens at controller
    
        // swap: yield tokens -> target token
        for(uint i = 0; i < yield_tokens.length; i++){
            uint256 amount = IERC20(yield_tokens[i]).balanceOf(address(this));
            if(amount > 0){
                IERC20(yield_tokens[i]).approve(address(yield_handler), amount);
                if(target_token == address(0x0)){
                    yield_handler.handleExtraToken(yield_tokens[i], weth, amount, min_amount);
                }else{
                    yield_handler.handleExtraToken(yield_tokens[i], target_token, amount, min_amount);
                }
            }
        }

        // @here: target tokan at controller

        uint256 amount = TransferableToken.balanceOfAddr(target_token, address(this));
        _refundTarget(amount);
    }

    event CFFRefund(uint256 amount, uint256 fee);
    function _refundTarget(uint256 _amount) internal {
        if(_amount == 0){
            return ;
        }
        if(harvest_fee_ratio != 0 && fee_pool != address(0x0)){
            uint256 f = _amount.safeMul(harvest_fee_ratio).safeDiv(ratio_base);
            emit CFFRefund(_amount, f);
            _amount = _amount.safeSub(f);
            if(f != 0){
                TransferableToken.transfer(target_token, fee_pool.toPayable(), f);
            }
        } else {
            emit CFFRefund(_amount, 0);
        }
        TransferableToken.transfer(target_token, pool.toPayable(), _amount);
        ICurvePool(pool).deposit(_amount);
    }

    function pause() public onlyOwner{
        pool = address(0x0);
    }

    event AddYieldToken(address _new);
    function addYieldToken(address _new) public onlyOwner{
        require(_new != address(0x0), "invalid extra token");
        yield_tokens.push(_new);
        emit AddYieldToken(_new);
    }

    event RemoveYieldToken(address _addr);
    function removeYieldToken(address _addr) public onlyOwner{
        require(_addr != address(0x0), "invalid address");
        uint len = yield_tokens.length;
        for(uint i = 0; i < len; i++){
            if(yield_tokens[i] == _addr){
                yield_tokens[i] = yield_tokens[len - 1];
                yield_tokens[len - 1] =address(0x0);
                yield_tokens.length = len - 1;
                emit RemoveYieldToken(_addr);
                return;
            }
        }
    }

    event ChangeYieldHandler(address old, address _new);
    function changeYieldHandler(address _new) public onlyOwner{
        address old = address(yield_handler);
        yield_handler = YieldHandlerInterface(_new);
        emit ChangeYieldHandler(old, address(yield_handler));
    }

    event ChangePool(address old, address _new);
    function changePool(address _p) public onlyOwner{
        address old = pool;
        pool = _p;
        emit ChangePool(old, pool);
    }

    event ChangeFeePool(address old, address _new);
    function changeFeePool(address _fp) public onlyOwner{
        address old = fee_pool;
        fee_pool = _fp;
        emit ChangeFeePool(old, fee_pool);
    }

    event ChangeHarvestFee(uint256 old, uint256 _new);
    function changeHarvestFee(uint256 _fee) public onlyOwner{
        require(_fee < ratio_base, "invalid fee");
        uint256 old = harvest_fee_ratio;
        harvest_fee_ratio = _fee;
        emit ChangeHarvestFee(old, harvest_fee_ratio);
    }

    function() external payable{}
}