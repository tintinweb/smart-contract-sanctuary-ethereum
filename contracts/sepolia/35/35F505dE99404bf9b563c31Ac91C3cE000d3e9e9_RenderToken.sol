pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract Migratable {

  event Migrated(string contractName, string migrationId);

  mapping (string => mapping (string => bool)) internal migrated;

  string constant private INITIALIZED_ID = "initialized";

  modifier isInitializer(string contractName, string migrationId) {
    validateMigrationIsPending(contractName, INITIALIZED_ID);
    validateMigrationIsPending(contractName, migrationId);
    _;
    emit Migrated(contractName, migrationId);
    migrated[contractName][migrationId] = true;
    migrated[contractName][INITIALIZED_ID] = true;
  }

  modifier isMigration(string contractName, string requiredMigrationId, string newMigrationId) {
    require(isMigrated(contractName, requiredMigrationId), "Prerequisite migration ID has not been run yet");
    validateMigrationIsPending(contractName, newMigrationId);
    _;
    emit Migrated(contractName, newMigrationId);
    migrated[contractName][newMigrationId] = true;
  }

  function isMigrated(string contractName, string migrationId) public view returns(bool) {
    return migrated[contractName][migrationId];
  }

  function initialize() isInitializer("Migratable", "1.2.1") public {
  }

  function validateMigrationIsPending(string contractName, string migrationId) private {
    require(!isMigrated(contractName, migrationId), "Requested target migration ID has already been run");
  }
}

contract Ownable is Migratable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function initialize(address _sender) public isInitializer("Ownable", "1.9.0") {
    owner = _sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    return a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Escrow is Migratable, Ownable {
  using SafeERC20 for ERC20;
  using SafeMath for uint256;

  mapping(string => uint256) private jobBalances;
  address public renderTokenAddress;
  address public disbursalAddress;

  event DisbursalAddressUpdate(address disbursalAddress);
  event JobBalanceUpdate(string _jobId, uint256 _balance);
  event RenderTokenAddressUpdate(address renderTokenAddress);

  modifier canDisburse() {
    require(msg.sender == disbursalAddress, "message sender not authorized to disburse funds");
    _;
  }

  function initialize (address _owner, address _renderTokenAddress) public isInitializer("Escrow", "0") {
    require(_owner != address(0), "_owner must not be null");
    require(_renderTokenAddress != address(0), "_renderTokenAddress must not be null");
    Ownable.initialize(_owner);
    disbursalAddress = _owner;
    renderTokenAddress = _renderTokenAddress;
  }

  function changeDisbursalAddress(address _newDisbursalAddress) external onlyOwner {
    disbursalAddress = _newDisbursalAddress;

    emit DisbursalAddressUpdate(disbursalAddress);
  }

  function changeRenderTokenAddress(address _newRenderTokenAddress) external onlyOwner {
    require(_newRenderTokenAddress != address(0), "_newRenderTokenAddress must not be null");
    renderTokenAddress = _newRenderTokenAddress;

    emit RenderTokenAddressUpdate(renderTokenAddress);
  }

  function disburseJob(string _jobId, address[] _recipients, uint256[] _amounts) external canDisburse {
    require(jobBalances[_jobId] > 0, "_jobId has no available balance");
    require(_recipients.length == _amounts.length, "_recipients and _amounts must be the same length");

    for(uint256 i = 0; i < _recipients.length; i++) {
      jobBalances[_jobId] = jobBalances[_jobId].sub(_amounts[i]);
      ERC20(renderTokenAddress).safeTransfer(_recipients[i], _amounts[i]);
    }

    emit JobBalanceUpdate(_jobId, jobBalances[_jobId]);
  }

  function fundJob(string _jobId, uint256 _tokens) external {
    require(msg.sender == renderTokenAddress, "message sender not authorized");
    jobBalances[_jobId] = jobBalances[_jobId].add(_tokens);

    emit JobBalanceUpdate(_jobId, jobBalances[_jobId]);
  }

  function jobBalance(string _jobId) external view returns(uint256) {
    return jobBalances[_jobId];
  }

}

contract MigratableERC20 is Migratable {
  using SafeERC20 for ERC20;

  address public constant BURN_ADDRESS = address(0xdead);

  ERC20 public legacyToken;

  function initialize(address _legacyToken) isInitializer("OptInERC20Migration", "1.9.0") public {
    legacyToken = ERC20(_legacyToken);
  }

  function migrate() public {
    uint256 amount = legacyToken.balanceOf(msg.sender);
    migrateToken(amount);
  }

  function migrateToken(uint256 _amount) public {
    migrateTokenTo(msg.sender, _amount);
  }

  function migrateTokenTo(address _to, uint256 _amount) public {
    _mintMigratedTokens(_to, _amount);
    legacyToken.safeTransferFrom(msg.sender, BURN_ADDRESS, _amount);
  }

  function _mintMigratedTokens(address _to, uint256 _amount) internal;
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

contract RenderToken is Migratable, MigratableERC20, Ownable, StandardToken {

  string public constant name = "Render Token";
  string public constant symbol = "RNDR";
  uint8 public constant decimals = 18;

  address public escrowContractAddress;

  event EscrowContractAddressUpdate(address escrowContractAddress);
  event TokensEscrowed(address indexed sender, string jobId, uint256 amount);
  event TokenMigration(address indexed receiver, uint256 amount);

  function initialize(address _owner, address _legacyToken) public isInitializer("RenderToken", "0") {
    require(_owner != address(0), "_owner must not be null");
    require(_legacyToken != address(0), "_legacyToken must not be null");
    Ownable.initialize(_owner);
    MigratableERC20.initialize(_legacyToken);
  }

  function holdInEscrow(string _jobID, uint256 _amount) public {
    require(transfer(escrowContractAddress, _amount), "token transfer to escrow address failed");
    Escrow(escrowContractAddress).fundJob(_jobID, _amount);

    emit TokensEscrowed(msg.sender, _jobID, _amount);
  }

  function _mintMigratedTokens(address _to, uint256 _amount) internal {
    require(_to != address(0), "_to address must not be null");
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);

    emit TokenMigration(_to, _amount);
    emit Transfer(address(0), _to, _amount);
  }

  function setEscrowContractAddress(address _escrowAddress) public onlyOwner {
    require(_escrowAddress != address(0), "_escrowAddress must not be null");
    escrowContractAddress = _escrowAddress;

    emit EscrowContractAddressUpdate(escrowContractAddress);
  }

}