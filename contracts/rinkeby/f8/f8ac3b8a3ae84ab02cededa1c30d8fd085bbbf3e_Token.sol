/**
 *Submitted for verification at Etherscan.io on 2022-05-07
*/

// File: contracts/interfaces/ApproveAndCallReceiver.sol

pragma solidity >=0.8.0 <0.9.0;


/*
  Copyright 2017, Jordi Baylina (Giveth)

  Original contract from https://github.com/aragon/aragon-network-token/blob/master/contracts/interface/ApproveAndCallReceiver.sol
*/
abstract contract ApproveAndCallReceiver {
    function receiveApproval(
        address _from, 
        uint256 _amount, 
        address _token, 
        bytes memory _data
    ) public virtual;
}
// File: contracts/interfaces/TokenController.sol

pragma solidity >=0.8.0 <0.9.0;


/*
  Copyright 2017, Jorge Izquierdo (Aragon Foundation)
  Copyright 2017, Jordi Baylina (Giveth)

  Based on MiniMeToken.sol from https://github.com/Giveth/minime
  Original contract from https://github.com/aragon/aragon-network-token/blob/master/contracts/interface/Controller.sol
*/
/// @dev The token controller contract must implement these functions
abstract contract TokenController {
    /// @notice Called when `_owner` sends ether to the MiniMe Token contract
    /// @param _owner The address that sent the ether to create tokens
    /// @return True if the ether is accepted, false if it throws
    function proxyPayment(address _owner) payable public virtual returns(bool);

    /// @notice Notifies the controller about a token transfer allowing the
    ///  controller to react if desired
    /// @param _from The origin of the transfer
    /// @param _to The destination of the transfer
    /// @param _amount The amount of the transfer
    /// @return False if the controller does not authorize the transfer
    function onTransfer(address _from, address _to, uint _amount) public virtual returns(bool);

    /// @notice Notifies the controller about an approval allowing the
    ///  controller to react if desired
    /// @param _owner The address that calls `approve()`
    /// @param _spender The spender in the `approve()` call
    /// @param _amount The amount in the `approve()` call
    /// @return False if the controller does not authorize the approval
    function onApprove(address _owner, address _spender, uint _amount) public virtual returns(bool);
}
// File: contracts/interfaces/Controlled.sol

pragma solidity >=0.8.0 <0.9.0;


/*
  Copyright 2017, Roderik van der Veer (SettleMint)
  Copyright 2017, Jorge Izquierdo (Aragon Foundation)
  Copyright 2017, Jordi Baylina (Giveth)

  Based on MiniMeToken.sol from https://github.com/Giveth/minime
  Original contract from https://github.com/aragon/aragon-network-token/blob/master/contracts/interface/Controlled.sol
*/
contract Controlled {

    //block for check//bool private initialed = false;
    address payable public controller;

    /// @notice The address of the controller is the only address that can call
    ///  a function with this modifier
    modifier onlyController {
        require(msg.sender == controller, "msg sender is not controller"); 
        _; 
    }

    constructor() {
      //block for check//require(!initialed);
      controller = payable(msg.sender);
      //block for check//initialed = true;
    }

    /// @notice Changes the controller of the contract
    /// @param _newController The new controller of the contract
    function changeController(address payable _newController) onlyController public {
        controller = _newController;
    }
}
// File: contracts/interfaces/ERC20Token.sol

pragma solidity >=0.8.0 <0.9.0;


/*
  Abstract contract for the full ERC 20 Token standard
  https://github.com/ethereum/EIPs/issues/20

  Copyright 2017, Jordi Baylina (Giveth)

  Original contract from https://github.com/status-im/status-network-token/blob/master/contracts/ERC20Token.sol
*/
abstract contract ERC20Token{
    /* This is a slight change to the ERC20 base standard.
      function totalSupply() constant returns (uint256 supply);
      is replaced with:
      uint256 public totalSupply;
      This automatically creates a getter function for the totalSupply.
      This is moved to the base contract since public getter functions are not
      currently recognised as an implementation of the matching abstract
      function by the compiler.
    */
    // total amount of tokens
    uint256 public totalSupply;
    //function totalSupply() public constant returns (uint256 balance);

    // @param _owner The address from which the balance will be retrieved
    // @return The balance
    mapping (address => uint256) public balanceOf;
    //function balanceOf(address _owner) public constant returns (uint256 balance);

    // @notice send `_value` token to `_to` from `msg.sender`
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) public virtual returns (bool success);

    // @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    // @param _from The address of the sender
    // @param _to The address of the recipient
    // @param _value The amount of token to be transferred
    // @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success);

    // @notice `msg.sender` approves `_spender` to spend `_value` tokens
    // @param _spender The address of the account able to transfer the tokens
    // @param _value The amount of tokens to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) public virtual returns (bool success);

    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    mapping (address => mapping (address => uint256)) public allowance;
    //function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
// File: contracts/interfaces/TokenI.sol

pragma solidity >=0.8.0 <0.9.0;




abstract contract TokenI is ERC20Token, Controlled {

    string public name;                //The Token's name: e.g. DigixDAO Tokens
    uint8 public decimals;             //Number of decimals of the smallest unit
    string public symbol;              //An identifier: e.g. REP

///////////////////
// ERC20 Methods
///////////////////

    // @notice `msg.sender` approves `_spender` to send `_amount` tokens on
    //  its behalf, and then a function is triggered in the contract that is
    //  being approved, `_spender`. This allows users to use their tokens to
    //  interact with contracts in one function call instead of two
    // @param _spender The address of the contract able to transfer the tokens
    // @param _amount The amount of tokens to be approved for transfer
    // @return success True if the function call was successful
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes memory _extraData
    ) public virtual returns (bool success);

////////////////
// Generate and destroy tokens
////////////////

    // @notice Generates `_amount` tokens that are assigned to `_owner`
    // @param _owner The address that will be assigned the new tokens
    // @param _amount The quantity of tokens generated
    // @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint _amount) public virtual returns (bool);


    // @notice Burns `_amount` tokens from `_owner`
    // @param _owner The address that will lose the tokens
    // @param _amount The quantity of tokens to burn
    // @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint _amount) public virtual returns (bool);

////////////////
// Enable tokens transfers
////////////////

    // @notice Enables token holders to transfer their tokens freely if true
    // @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) public virtual;

//////////
// Safety Methods
//////////

    // @notice This method can be used by the controller to extract mistakenly
    //  sent tokens to this contract.
    // @param _token The address of the token contract that you want to recover
    //  set to 0 in case you want to extract ether.
    //function claimTokens(address _token) public;

////////////////
// Events
////////////////

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}
// File: contracts/utils/SafeMath.sol

pragma solidity >=0.8.0 <0.9.0;


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {

  /**
   * @dev Multiplies two unsigned integers, reverts on overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

  /**
   * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // Solidity only automatically asserts when dividing by 0
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
   * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

  /**
   * @dev Adds two unsigned integers, reverts on overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

  /**
   * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
   * reverts when dividing by zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}
// File: contracts/Token.sol

pragma solidity >=0.8.0 <0.9.0;






contract Token is TokenI {
    using SafeMath for uint256;

    address public owner;

    uint256 public maximumToken = 10 * 10**8 * 10**18; //总发行量1b

    struct FreezeInfo {
        address user;
        uint256 amount;
    }

    //解锁信息
    struct UnlockStepInfo {
        uint8 step;
        uint8 sequenceNow;
        uint8 unlockTime;
    }

    //Key1: step(募资阶段); Key2: user sequence(用户序列)
    mapping (address => mapping (address => uint256)) public freezeOf; //所有锁仓，key 使用序号向上增加，方便程序查询。
    mapping (address => uint256) public freezeOfUser; //用户所有锁仓，方便用户查询自己锁仓余额

    bool public transfersEnabled;

    /* This generates a public event on the blockchain that will notify clients */
    //event Transfer(address indexed from, address indexed to, uint256 value);

    /* This notifies clients about the amount burnt */
    event Burn(address indexed from, uint256 value);
    
    /* This notifies clients about the amount frozen */
    event Freeze(address indexed from, uint256 value, address indexed nft);
    
    /* This notifies clients about the amount unfrozen */
    event Unfreeze(address indexed from, uint256 value);

    /* Initializes contract with initial supply tokens to the creator of the contract */
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol,
        bool transfersEnable
        ) {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        transfersEnabled = transfersEnable;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerOrController(){
        require(msg.sender == owner || msg.sender == controller);
        _;
    }

    modifier ownerOrUser(address user){
        require(msg.sender == owner || msg.sender == user);
        _;
    }

    modifier realUser(address user){
        if(user == address(0x0)){
            revert();
        }
        _;
    }

    modifier moreThanZero(uint256 _value){
        if (_value <= 0){
            revert();
        }
        _;
    }

    modifier moreOrEqualZero(uint256 _value){
        if(_value < 0){
            revert();
        }
        _;
    }

    /// @dev Internal function to determine if an address is a contract
    /// @param _addr The address being queried
    /// @return True if `_addr` is a contract
    function isContract(address _addr) view internal returns(bool) {
        uint size;
        if (_addr == address(0x0)) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

    /* Send coins */
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) public override returns (bool) {
        require(balanceOf[msg.sender] > _value);           // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]); // Check for overflows
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;                     // Subtract from the sender
        balanceOf[_to] = balanceOf[_to] + _value;                            // Add the same to the recipient
        emit Transfer(msg.sender, _to, _value);                   // Notify anyone listening that this transfer took place
        return true;
    }

    /* Allow another contract to spend some tokens in your behalf */
    function approve(address _spender, uint256 _value) moreThanZero(_value) public override
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * @notice `msg.sender` approves `_spender` to send `_amount` tokens on
     *  its behalf, and then a function is triggered in the contract that is
     *  being approved, `_spender`. This allows users to use their tokens to
     *  interact with contracts in one function call instead of two
     * @param _spender The address of the contract able to transfer the tokens
     * @param _amount The amount of tokens to be approved for transfer
     * @return success True if the function call was successful
     */
    function approveAndCall(address _spender, uint256 _amount, bytes memory _extraData) public override returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallReceiver(_spender).receiveApproval(
            msg.sender,
            _amount,
            address(this),
            _extraData
        );

        return true;
    }

    /* A contract attempts to get the coins */
    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) public override returns (bool success) {
        require(balanceOf[_from] > _value);                 // Check if the sender has enough
        require(balanceOf[_to] + _value > balanceOf[_to]);  // Check for overflows
        require(_value < allowance[_from][msg.sender]);     // Check allowance
        balanceOf[_from] = balanceOf[_from] - _value;                           // Subtract from the sender
        balanceOf[_to] = balanceOf[_to] + _value;                             // Add the same to the recipient
        allowance[_from][msg.sender] = allowance[_from][msg.sender] + _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMulti(address[] memory _from, address[] memory _to, uint256[] memory _value) public returns (bool success){
        require(_from.length == _to.length && _to.length == _value.length);
        uint8 len = uint8(_from.length);
        for(uint8 i; i<len; i++){
            address _fromI = _from[i];
            address _toI = _to[i];
            uint256 _valueI = _value[i];
            balanceOf[_to[i]] += _value[i];
            balanceOf[_from[i]] -= _value[i];
            emit Transfer(_fromI, _toI, _valueI);
        }
        return true;
    }

    //只能自己或者 owner 才能冻结账户
    function freeze(address _user, uint256 _value, address nft) moreThanZero(_value) onlyController public returns (bool success) {
        //info256("balanceOf[_user]", balanceOf[_user]);
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user] - _value;
        freezeOf[nft][_user] = _value;
        emit Freeze(_user, _value, nft);
        return true;
    }

    /**
     * 一次性冻结多人账户资金.
     * 用户对于每一个 NFT 拍卖，都可以进行一次独立冻结，当拍卖结束后，在对其进行解锁。
     * 此操作一次性只允许针对一个 NFT 拍卖的所有用户进行。
     */
/*
    function freezeMulti(address nft, [] _users, uint256[] _values) ownerOrController public returns (bool){
        require(_values.length == _users.length, "users length is not equal values length");
        uint256 len = _values.length;
        for(uint8 i=0; i< len; i++){
            address _user = _users[i];
            require(balanceOf[_user] >= _values[i], "amount of "+_user+" is not enough");
        }
        for(uint8 i=0; i<len; i++){
            address _user = _users[i];
            uint256 _value = _values[i];
            freezeOf[nft][_user] += _value;
            balanceOf[_user] = balanceOf[_user] - _value;
            Freeze(_user, _value, nft);
        }
        return true;
    }

    event info(string name, uint8 value);
    event info256(string name, uint256 value);
    
    //为用户解锁账户资金
    function unFreeze(address nft) onlyController public returns (bool unlockOver) {
        //info("_start", _start);
        for(; _end>_start; _end--){
            uint256 _amount = freezeOf[nft][_user];
            balanceOf[fInfo.user] += _amount;
            delete freezeOf[user];
            Unfreeze(fInfo.user, _amount);
        }
    }
*/
    
    //accept ether
    receive() external payable {
        //屏蔽控制方的合约类型检查，以兼容发行方无控制合约的情况。
        require(isContract(controller));
        bool proxyPayment = TokenController(controller).proxyPayment{value: msg.value}(msg.sender);
        require(proxyPayment);
    }

////////////////
// Generate and destroy tokens
////////////////

    // @notice Generates `_amount` tokens that are assigned to `_owner`
    // @param _user The address that will be assigned the new tokens
    // @param _amount The quantity of tokens generated
    // @return True if the tokens are generated correctly
    function generateTokens(address _user, uint _amount) onlyController public override returns (bool) {
        require(balanceOf[owner] >= _amount);
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        emit Transfer(address(0), _user, _amount);
        return true;
    }

    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _user The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _user, uint _amount) onlyController public override returns (bool) {
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        emit Transfer(_user, address(0), _amount);
        return true;
    }

    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] = balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }

////////////////
// Enable tokens transfers
////////////////

    /// @notice Enables token holders to transfer their tokens freely if true
    /// @param _transfersEnabled True if transfers are allowed in the clone
    function enableTransfers(bool _transfersEnabled) onlyController public override {
        transfersEnabled = _transfersEnabled;
    }

//////////
// Safety Methods
//////////

    /// @notice This method can be used by the controller to extract mistakenly
    ///  sent tokens to this contract.
    ///  set to 0 in case you want to extract ether.
    /*
    function claimTokens(address _token) onlyController public {
        if (_token == address(0x0)) {
            controller.transfer(address(this).balance);
            return;
        }

        Token token = Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        emit ClaimedTokens(_token, controller, balance);
    }
    */
}