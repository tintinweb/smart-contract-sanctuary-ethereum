//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


library Validations {
  function revertOnZeroAddress(address _address) internal pure {
    require(address(0) != address(_address), "zero address not accepted!");
  }
}

interface IBEP20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory __name, string memory __symbol, uint8 __decimals)  {
        _name = __name;
        _symbol = __symbol;
        _decimals = __decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}


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
        require(c / a == b);
        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://eips.ethereum.org/EIPS/eip-20
 *
 * This implementation emits additional Approval events, allowing applications to reconstruct the allowance status for
 * all accounts just by listening to said events. Note that this isn't required by the specification, and other
 * compliant implementations may not do it.
 */
contract ERC20 is IERC20 {

    using SafeMath for uint256;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint256 private _totalSupply;

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public override returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public override returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * From MonolithDAO Token.sol
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */







/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract ERC20Burnable is ERC20 {
    /**
     * @dev Burns a specific amount of tokens.
     * @param value The amount of token to be burned.
     */
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

    /**
     * @dev Burns a specific amount of tokens from the target address and decrements allowance
     * @param from address The account whose tokens will be burned.
     * @param value uint256 The amount of token to be burned.
     */
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


interface IPool {
  struct PoolModel {
    uint256 hardCap; // how much project wants to raise
    uint256 softCap; // how much of the raise will be accepted as successful IDO
    uint256 startDateTime;
    uint256 endDateTime;
  //  uint256 poolCount;
    PoolStatus status; //: by default “Upcoming”,

  }

  struct IDOInfo {
    address walletAddress; // address where Ether is sent
    address projectTokenAddress; //the address of the token that project is offering in return
    uint16 minAllocationPerUser;
    uint256 maxAllocationPerUser;
    uint256 totalTokenProvided;
    uint256 exchangeRate;
    uint256 tokenPrice;
    uint256 totalTokenSold;
  }

  // Pool data that needs to be retrieved:
  struct CompletePoolDetails {
    Participations participationDetails;
    PoolModel pool;
    IDOInfo poolDetails;
    uint256 totalRaised;
  }

  struct Participations {
    ParticipantDetails[] investorsDetails;
    uint256 count;
  }

  struct ParticipantDetails {
    address addressOfParticipant;
    uint256 totalRaisedInWei;
  }

  enum PoolStatus {
    Upcoming,
    Ongoing,
    Finished,
    Paused,
    Cancelled
  }

  function addIDOInfo(IDOInfo memory _detailedPoolInfo) external;

  function getCompletePoolDetails()
    external
    view
    returns (CompletePoolDetails memory poolDetails);

  function updatePoolStatus(uint256 _newStatus) external;

  function deposit(address _sender) external payable;

  function unclaimedTokens(address _participant)
    external
    view
    returns (uint256 _tokensAmount);
}









contract Whitelist {
  mapping(address => bool) private whitelistedAddressesMap;
  address[] private whitelistedAddressesArray;

  event AddedToWhitelist(address indexed account);
  event RemovedFromWhitelist(address indexed accout);

  constructor() {}

  function addToWhitelist(address[] calldata _addresses)
    internal
    returns (bool success)
  {
    require(_addresses.length > 0, "an array of address is expected");

    for (uint256 i = 0; i < _addresses.length; i++) {
      address userAddress = _addresses[i];

      Validations.revertOnZeroAddress(userAddress);

      if (!isAddressWhitelisted(userAddress))
        addAddressToWhitelist(userAddress);
    }
    success = true;
  }

  function isWhitelisted(address _address)
    internal
    view
    _nonZeroAddress(_address)
    returns (bool isIt)
  {
    isIt = whitelistedAddressesMap[_address];
  }

  function getWhitelistedUsers() internal view returns (address[] memory) {
    uint256 count = whitelistedAddressesArray.length;

    address[] memory _whitelistedAddresses = new address[](count);

    for (uint256 i = 0; i < count; i++) {
      _whitelistedAddresses[i] = whitelistedAddressesArray[i];
    }
    return _whitelistedAddresses;
  }

  modifier _nonZeroAddress(address _address) {
    Validations.revertOnZeroAddress(_address);
    _;
  }

  function isAddressWhitelisted(address _address)
    private
    view
    returns (bool isIt)
  {
    isIt = whitelistedAddressesMap[_address];
  }

  function addAddressToWhitelist(address _address) private {
    whitelistedAddressesMap[_address] = true;
    whitelistedAddressesArray.push(_address);
    emit AddedToWhitelist(_address);
  }
}


contract Pool is IPool, Ownable {
  PoolModel private poolInformation;
  IDOInfo private idoInfo;
  uint256 public idoCount;

  address[] public participantsAddress;                 //DOPrivate
  mapping(address => uint256) public collaborations;    //DOPrivate
  uint256 private _weiRaised = 0;

  event LogPoolContractAddress(address);
  event LogPoolStatusChanged(uint256 currentStatus, uint256 newStatus);
  event LogDeposit(address indexed participant, uint256 amount);

  constructor(PoolModel memory _pool) {
    _preValidatePoolCreation(_pool);
    poolInformation = IPool.PoolModel({
      hardCap: _pool.hardCap,
      softCap: _pool.softCap,
      startDateTime: _pool.startDateTime,
      endDateTime: _pool.endDateTime,
      status: _pool.status
    });

    emit LogPoolContractAddress(address(this));
  }
//["0x0dAf35==a138536A30105a7B4f8269920c88312996","0x7ed77E24f3a5fe34BeB09328fb921fd3Ee06D9ca","0xA71647E045E79823837457A05B01981A75a0CD2e"]
  modifier _addIDOInfoOnlyOnce() {
       idoCount++;
       require(idoCount<=3, "Cannot create more than 3 IDO" );
    // require(
    // //   address(idoInfo.walletAddress) == address(0),
    // //   "already added IDO info"
    // // );
    _;
  }

  function addIDOInfo(IDOInfo memory _pdi)
    external 
    override
    onlyOwner
    _addIDOInfoOnlyOnce
  {
    _preIDOInfoUpdate(_pdi);

    idoInfo.walletAddress = _pdi.walletAddress;
    idoInfo.projectTokenAddress = _pdi.projectTokenAddress;
    idoInfo.minAllocationPerUser = _pdi.minAllocationPerUser;
    idoInfo.maxAllocationPerUser = _pdi.maxAllocationPerUser;
    idoInfo.totalTokenProvided = _pdi.totalTokenProvided;
    idoInfo.exchangeRate = _pdi.exchangeRate;
    idoInfo.tokenPrice = _pdi.tokenPrice;
    idoInfo.totalTokenSold = _pdi.totalTokenSold;
  }

  receive() external payable {
    revert("Call deposit()");
  }

  function deposit(address _sender)
    external
    payable
    override
    //  onlyOwner     // doUncomment
  //  _pooIsOngoing(poolInformation) doUncomment
    _hardCapNotPassed(poolInformation.hardCap)
  {
    uint256 _amount = msg.value;

    _increaseRaisedWEI(_amount);
    _addToParticipants(_sender);

    emit LogDeposit(_sender, _amount);
  }

  function unclaimedTokens(address _participant)
    public    //doexternal
    view
    override
    onlyOwner
    // _isPoolFinished(poolInformation)
    returns (uint256 _tokensAmount)
  {
    uint256 amountParticipated = collaborations[_participant];
    uint256 totalRaised = _getTotalRaised();

   _tokensAmount = amountParticipated*idoInfo.tokenPrice;

    // _tokensAmount = 1; //TODO do the calculation here
  }

  function calculateTokens(address _participant) public view returns(uint256 _tokensAmount)
  {
    uint256 amountParticipated = collaborations[_participant];
  return _tokensAmount = amountParticipated*idoInfo.tokenPrice;

  }


  function updatePoolStatus(uint256 _newStatus) external override onlyOwner {
    require(_newStatus < 5 && _newStatus >= 0, "wrong Status;");
    uint256 currentStatus = uint256(poolInformation.status);
    poolInformation.status = PoolStatus(_newStatus);
    emit LogPoolStatusChanged(currentStatus, _newStatus);
  }

  function getCompletePoolDetails()
    external
    view
    override
    returns (CompletePoolDetails memory poolDetails)
  {
    poolDetails = CompletePoolDetails({
      participationDetails: _getParticipantsInfo(),
      totalRaised: _getTotalRaised(),
      pool: poolInformation,
      poolDetails: idoInfo
    });
  }

  function _getParticipantsInfo()
    private
    view
    returns (Participations memory participants)
  {
    uint256 count = participantsAddress.length;

    ParticipantDetails[] memory parts = new ParticipantDetails[](count);

    for (uint256 i = 0; i < count; i++) {
      address userAddress = participantsAddress[i];
      parts[i] = ParticipantDetails(userAddress, collaborations[userAddress]);
    }
    participants.count = count;
    participants.investorsDetails = parts;
  }

  function _getTotalRaised() private view returns (uint256 amount) {
    amount = _weiRaised;
  }

  function _increaseRaisedWEI(uint256 _amount) private {
    require(_amount > 0, "No WEI found!");

    uint256 _weiBeforeRaise = _getTotalRaised();
    _weiRaised += msg.value;

    assert(_weiRaised > _weiBeforeRaise); //TODO requires more research
  }

  function _addToParticipants(address _address) private {
    if (!_didAlreadyParticipated(_address)) _addToListOfParticipants(_address);
    _keepRecordOfWEIRaised(_address);
  }

  function _didAlreadyParticipated(address _address)
    private
    view
    returns (bool isIt)
  {
    isIt = collaborations[_address] > 0;
  }

  function _addToListOfParticipants(address _address) private {
    participantsAddress.push(_address);
  }

  function _keepRecordOfWEIRaised(address _address) private {
    collaborations[_address] += msg.value;
  }

  function _preValidatePoolCreation(IPool.PoolModel memory _pool) private view {
    require(_pool.hardCap > 0, "hardCap must be > 0");
    require(_pool.softCap > 0, "softCap must be > 0");
    require(_pool.softCap < _pool.hardCap, "softCap must be < hardCap");
    require(
      //solhint-disable-next-line not-rely-on-time
      _pool.startDateTime > block.timestamp,
      "startDateTime must be > now"
    );
    require(
      //solhint-disable-next-line not-rely-on-time
      _pool.endDateTime > block.timestamp,
      "endDate must be at future time"
    ); //TODO how much in the future?
  }

  function _preIDOInfoUpdate(IDOInfo memory _idoInfo) private pure {
    require(
      address(_idoInfo.walletAddress) != address(0),
      "walletAddress is a zero address!"
    );
    require(_idoInfo.minAllocationPerUser > 0, "minAllocation must be > 0!");
    require(
      _idoInfo.minAllocationPerUser < _idoInfo.maxAllocationPerUser,
      "minAllocation must be < max!"
    );

    require(_idoInfo.exchangeRate > 0, "exchangeRate must be > 0!");
    require(_idoInfo.tokenPrice > 0, "token price must be > 0!");
  }

  modifier _pooIsOngoing(IPool.PoolModel storage _pool) {
    require(_pool.status == IPool.PoolStatus.Ongoing, "Pool not open!");
    // solhint-disable-next-line not-rely-on-time
    require(_pool.startDateTime <= block.timestamp, "Pool not started yet!");
    // solhint-disable-next-line not-rely-on-time
    require(_pool.endDateTime >= block.timestamp, "pool endDate passed!");

    _;
  }

  modifier _isPoolFinished(IPool.PoolModel storage _pool) {
    require(
      _pool.status == IPool.PoolStatus.Finished,
      "Pool status not Finished!"
    );
    _;
  }

  modifier _hardCapNotPassed(uint256 _hardCap) {
    uint256 _beforeBalance = _getTotalRaised();

    uint256 sum = _getTotalRaised() + msg.value;
    require(sum <= _hardCap, "hardCap reached!");
    assert(sum > _beforeBalance);
    _;
  }
}

contract projectToken  is ERC20, ERC20Detailed, ERC20Burnable {
    uint256 owner;
    constructor() ERC20Detailed("Token", "Jem", 18)  {
       _mint(msg.sender,255000000* 10 ** 18);
   
    }
}

contract IDO is Pausable, AccessControl, Ownable, Whitelist {
  using SafeMath for uint256;
  mapping(address => bool) private _didRefund; // keep track of users who did refund project token.
  bytes32 private constant POOL_OWNER_ROLE = keccak256("POOL_OWNER_ROLE");
    IPool private pool;
    IERC20 private projectToken;
    IBEP20 public DWD;
    uint256 public percentage;
    uint256 public BUSDRate = 100;
    uint256 public directPercentage = 5;
    uint256 public inviteePercentage = 4;
    uint256 public poolCount;
    bool public saleOn;
    uint256 public Time;
    address[] private AllUsers;
    mapping(address=>address) private alladdress;
    mapping(address=>address[]) public totalInvitee;




  event LogPoolOwnerRoleGranted(address indexed owner);
  event LogPoolOwnerRoleRevoked(address indexed owner);
  event LogPoolCreated(address indexed poolOwner);
  event LogPoolStatusChanged(address indexed poolOwner, uint256 newStatus);
  event LogWithdraw(address indexed participant, uint256 amount);

  constructor(IBEP20 _DWD) {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        DWD =_DWD;
        AllUsers.push(owner());
  }



   
    /**
        * @dev Owner can set up BUSD To HPG rate
     */
   
            /* @dev Get addresses from mapping
     */
    function getaddresses(address _user) public view returns(address add1,address add2)
    {
        add1 = getaddress(_user);           
        add2 = getaddress(add1);
        return(add1,add2);
    }
    /**
            /* @dev Transfer addresses and amount upto 4 referrels 
     */
    function Refer(address referredBy, uint256 _amount)
    internal
    {
        require(referredBy!=msg.sender,"Please add a valid referred address");
        AllUsers.push(msg.sender);
        alladdress[msg.sender] = referredBy;
        totalInvitee[referredBy].push(msg.sender);
       
        (uint256 referrer1Amount, uint256 referrer2Amount)
        =
        getValues(_amount);
        (address referral1Address , address referral2Address)
        =
        getaddresses(msg.sender);
        if(
        referral1Address == address(0)||
        referral2Address == address(0)
        )
        {
          if(referral2Address==address(0))
          {referral2Address=owner();}
        }
            DWD.transfer(referral1Address,referrer1Amount);
            DWD.transfer(referral2Address,referrer2Amount);
    }

    function setPercentages
    (uint256 _directPercentage,uint256 _inviteePercentage)
    public
    onlyOwner
    {
        directPercentage=_directPercentage;
        inviteePercentage=_inviteePercentage;
    }
    /**
            /* @dev Get Percentages of Referrals
     */
    function getValues(uint256 _amount) public view returns(uint256,uint256){

        uint256 referral1Amount = _amount.mul(directPercentage).div(100);
        uint256 referral2Amount = _amount.mul(inviteePercentage).div(100);
        
        return(referral1Amount,referral2Amount);
    }
    /**
            /* @dev Get All users 
     */
    function ViewUsers() public view returns(address [] memory){
        return AllUsers;
    }
    /**
    
   
    /**
            /* @dev Get address against the given address from mapping 
     */
    function getaddress(address _user) public view returns(address){
        return alladdress[_user];
    }

  // Admin grants PoolOwner role to some address;
  function grantPoolOwnerRole(address _address)
    external
    onlyOwner
    _nonZeroAddress(_address)
    returns (bool success)
  {
    grantRole(POOL_OWNER_ROLE, _address);
    success = true;
  }

  // Admin revokes PoolOwner role feom an address;
  function revokePoolOwnerRole(address _address)
    external
    onlyOwner
    _nonZeroAddress(_address)
  {
    revokeRole(POOL_OWNER_ROLE, _address);
  }

  function createPool(
    uint256 _hardCap,
    uint256 _softCap,
    uint256 _startDateTime,
    uint256 _endDateTime,
    uint256 _status
  )
    external
    payable
    onlyRole(POOL_OWNER_ROLE)
    _createPoolOnlyOnce
    returns (bool success)
  {
    IPool.PoolModel memory model = IPool.PoolModel({
      hardCap: _hardCap,
      softCap: _softCap,
      startDateTime: _startDateTime,
      endDateTime: _endDateTime,
      status: IPool.PoolStatus(_status)
    });

    pool = new Pool(model);
    emit LogPoolCreated(_msgSender());
    success = true;
  }

  function addIDOInfo(
    address _walletAddress,
    address _projectTokenAddress,
    uint16 _minAllocationPerUser,
    uint256 _maxAllocationPerUser,
    uint256 _totalTokenProvided,
    uint256 _exchangeRate,
    uint256 _tokenPrice,
    uint256 _totalTokenSold
  ) external onlyRole(POOL_OWNER_ROLE) {
    projectToken = IERC20(_projectTokenAddress);
    pool.addIDOInfo(
      IPool.IDOInfo({
        walletAddress: _walletAddress,
        projectTokenAddress: _projectTokenAddress,
        minAllocationPerUser: _minAllocationPerUser,
        maxAllocationPerUser: _maxAllocationPerUser,
        totalTokenProvided: _totalTokenProvided,
        exchangeRate: _exchangeRate,
        tokenPrice: _tokenPrice,
        totalTokenSold: _totalTokenSold
      })
    );
  }

  function updatePoolStatus(uint256 newStatus)
    external
    onlyRole(POOL_OWNER_ROLE)
    returns (bool success)
  {
    pool.updatePoolStatus(newStatus);
    emit LogPoolStatusChanged(_msgSender(), newStatus);
    success = true;
  }

  function addAddressesToWhitelist(address[] calldata whitelistedAddresses)
    external
    onlyRole(POOL_OWNER_ROLE)
  {
    addToWhitelist(whitelistedAddresses);
  }

  function getCompletePoolDetails()
    external
    view
    _poolIsCreated
    returns (IPool.CompletePoolDetails memory poolDetails)
  {
    poolDetails = pool.getCompletePoolDetails();
  }

  // Whitelisted accounts can invest in the Pool by just sending ETH to IDO contract;
  receive() external payable _onlyWhitelisted(msg.sender)  {
    require(msg.value>1,"please enter more amount");
    pool.deposit{value: msg.value}(msg.sender);
  
  }

   function investInPool() public payable _onlyWhitelisted(msg.sender)  {
    require(msg.value>1,"please enter more amount");
    pool.deposit{value: msg.value}(msg.sender);
  
  }

function invest(address referredBy) public payable _onlyWhitelisted(msg.sender) returns(bool) {
    require(msg.value>1,"please enter more amount");
    pool.deposit{value: msg.value}(msg.sender);
      uint256 _amount = pool.unclaimedTokens(msg.sender);
     Refer(referredBy,_amount);

    return true;
  }
  function refund()
    external
    _onlyWhitelisted(msg.sender)
    _refundOnlyOnce(msg.sender)
  {
    address _receiver = msg.sender;
    _didRefund[_receiver] = true;

    uint256 _amount = pool.unclaimedTokens(_receiver);
    require(_amount > 0, "no participations found!");

    _beforeTransferChecks();

    bool success = projectToken.transfer(_receiver, _amount);
    require(success, "Token transfer failed!");

    _afterTransferAsserts();

    emit LogWithdraw(_receiver, _amount);
  }

  function poolAddress()
    external
    view
    onlyRole(POOL_OWNER_ROLE)
    returns (address _pool)
  {
    _pool = address(pool);
  }

  modifier _onlyWhitelisted(address _address) {
    require(isWhitelisted(_address), "Not Whitelisted!");
    _;
  }

  modifier _refundOnlyOnce(address _participant) {
    require(!_didRefund[_participant], "Already claimed!");
    _;
  }

  modifier _createPoolOnlyOnce() {
    poolCount++;
    require(poolCount<=3, "Cannot create more thn 3 Pools!");
    
    _;
  }

  modifier _poolIsCreated() {
    require(address(pool) != address(0), "Pool not created yet!");
    _;
  }

  function _beforeTransferChecks() public {
    //Some business logic, before transfering tokens to recipient
  }

  function _afterTransferAsserts() private {
    //Some business logic, after project token transfer is possible
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}