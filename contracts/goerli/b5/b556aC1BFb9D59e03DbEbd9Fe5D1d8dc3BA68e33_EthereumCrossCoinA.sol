pragma solidity ^0.8.4;

import "../security/Pausable.sol";
import "../token/ERC20Implementation.sol";

contract EthereumCrossCoinA is ERC20Implementation {
    struct PendingTx {
        uint256 _primaryKey;
        address _sender;
        uint256 _amount;
    }

    PendingTx[] public pendingTx;
    mapping(uint256 => uint256) public pkToIndex; //primary key to index

    uint256 primaryKey = 0;
    mapping(uint256 => bool) pkExist;

    event crossChain(uint256 _primaryKey, address _sender, uint256 _amount);
    event sendMoonneen(uint256 _primaryKey, address _sender, uint256 _amount);
    event removePendingTX(
        uint256 _primaryKey,
        address _sender,
        uint256 _amount
    );

    receive() external payable {}

    function name() public pure returns (string memory) {
        return "Wrap CoinA";
    }

    function symbol() public pure returns (string memory) {
        return "WCA";
    }

    ///@dev cross chain funciton, need to send moonneen token to this contract first
    function crossChainMint(uint256 _amount) external {
        require(_balances[msg.sender] >= _amount, "Not Enough Tokens");
        _burn(msg.sender, _amount);

        primaryKey++;

        _addToPendingTransaction(primaryKey, msg.sender, _amount);

        emit crossChain(primaryKey, msg.sender, _amount);
    }

    function removePendingTransaction(uint256 _primaryKey) external onlyAdmin {
        require(pkExist[_primaryKey], "Invalid PK");
        _removeTransaction(_primaryKey);
    }

    /// @dev from server calling this function to send moonneen to user
    function crossChainBack(
        uint256 _primaryKey,
        address _address,
        uint256 _amount
    ) external onlyAdmin {
        _mint(_address, _amount);
        emit sendMoonneen(_primaryKey, _address, _amount);
    }

    function getPendingTXLength() external view returns (uint256) {
        return pendingTx.length;
    }

    function _addToPendingTransaction(
        uint256 _primaryKey,
        address _sender,
        uint256 _amount
    ) internal {
        pkToIndex[_primaryKey]=pendingTx.length;
        pendingTx.push(PendingTx(_primaryKey, _sender, _amount));
        pkExist[_primaryKey] = true;
    }

    function _removeTransaction(uint256 _primaryKey) internal {
        uint256 index = pkToIndex[_primaryKey];
        uint256 lastIndex = pendingTx.length - 1;

        // change array
        PendingTx memory originPendingTX = pendingTx[index];
        PendingTx memory lastPendingTX = pendingTx[lastIndex];
        pendingTx[index] = lastPendingTX;
        pendingTx.pop();

        // change mapping
        pkToIndex[lastPendingTX._primaryKey] = index;
        delete pkToIndex[_primaryKey];

        emit removePendingTX(
            _primaryKey,
            originPendingTX._sender,
            originPendingTX._amount
        );
    }

    function _burn(address _address, uint256 amount) internal {
        _balances[_address] -= amount;
        _totalSupply -= amount;
        emit Transfer(_address, address(0), amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

import './AccessControl.sol';

contract Pausable is AccessControl{

    /// @dev Error message.
    string constant PAUSED='paused';
    string constant NOT_PAUSED='not paused';

    /// @dev Keeps track whether the contract is paused. When this is true, most actions are blocked.
    bool public paused = false;

    /// @dev Modifier to allow actions only when the contract is not paused
    modifier whenNotPaused {
        require(!paused,PAUSED);
        _;
    }

    /// @dev Modifier to allow actions only when the contract is paused
    modifier whenPaused {
        require(paused,NOT_PAUSED);
        _;
    }

    /// @dev Called by superAdmin to pause the contract. Used when something goes wrong
    ///  and we need to limit damage.
    function pause() external onlySuperAdmin whenNotPaused {
        paused = true;
    }

    /// @dev Unpauses the smart contract. Can only be called by the superAdmin.
    function unpause() external onlySuperAdmin whenPaused {
        paused = false;
    }
}

pragma solidity ^0.8.4;

import './IERC20.sol';
import '../security/Pausable.sol';

/// @title Standard ERC20 token

contract ERC20Implementation is IERC20, Pausable {

    mapping (address => uint256) _balances;

    mapping (address => mapping (address => uint256)) _allowed;

    uint256 _totalSupply;

    /// @dev Total number of tokens in existence
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /// @dev Gets the balance of the specified address.
    /// @param _owner The address to query the balance of.
    function balanceOf(address _owner) public override view returns (uint256 balance) {
        return _balances[_owner];
    }

    /// @dev Transfer token for a specified address
    /// @param _to The address to transfer to.
    /// @param _value The amount to be transferred.
    function transfer(address _to, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_to != address(0),INVALID_ADDRESS);
        _balances[msg.sender]-=_value;
        _balances[_to]+=_value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /// @dev Transfer tokens from one address to another
    /// @param _from address The address which you want to send tokens from
    /// @param _to address The address which you want to transfer to
    /// @param _value uint256 the amount of tokens to be transferred
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_to != address(0),INVALID_ADDRESS);
        _balances[_from]-=_value;
        _balances[_to]+=_value;
        _allowed[_from][msg.sender]-=_value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /// @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    /// @param _spender The address which will spend the funds.
    /// @param _value The amount of tokens to be spent.
    function approve(address _spender, uint256 _value) public whenNotPaused override returns (bool success) {
        require(_spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /// @dev Function to check the amount of tokens that an owner allowed to a spender.
    /// @param _owner The address which owns the funds.
    /// @param _spender The address which will spend the funds.
    function allowance(address _owner, address _spender) public override view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }

    /// @dev Increase the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param addedValue The amount of tokens to increase the allowance by.
    function increaseAllowance(address spender,uint256 addedValue) public whenNotPaused returns (bool) {
        require(spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][spender]+=addedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Decrease the amount of tokens that an owner allowed to a spender.
    /// @param spender The address which will spend the funds.
    /// @param subtractedValue The amount of tokens to decrease the allowance by.
    function decreaseAllowance(address spender,uint256 subtractedValue) public whenNotPaused returns (bool) {
        require(spender != address(0),INVALID_ADDRESS);
        _allowed[msg.sender][spender]-=subtractedValue;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

    /// @dev Internal function that mints an amount of the token and assigns it to an account.
    ///  This encapsulates the modification of balances such that the proper events are emitted.
    /// @param account The account that will receive the created tokens.
    /// @param amount The amount that will be created.
    function _mint(address account, uint256 amount) internal {
        require(account != address(0),INVALID_ADDRESS);
        _totalSupply+=amount;
        _balances[account]+=amount;
        emit Transfer(address(0), account, amount);
    }
}

pragma solidity >=0.8.0 <0.9.0;

contract AccessControl{

    /// @dev Error message.
    string constant NO_PERMISSION='no permission';
    string constant INVALID_ADDRESS ='invalid address';
    
    /// @dev Administrator with highest authority. Should be a multisig wallet.
    address payable superAdmin;

    /// @dev Administrator of this contract.
    address payable admin;

    /// Sets the original admin and superAdmin of the contract to the sender account.
    constructor(){
        superAdmin=payable(msg.sender);
        admin=payable(msg.sender);
    }

    /// @dev Throws if called by any account other than the superAdmin.
    modifier onlySuperAdmin{
        require(msg.sender==superAdmin,NO_PERMISSION);
        _;
    }

    /// @dev Throws if called by any account other than the admin.
    modifier onlyAdmin{
        require(msg.sender==admin,NO_PERMISSION);
        _;
    }

    /// @dev Allows the current superAdmin to change superAdmin.
    /// @param addr The address to transfer the right of superAdmin to.
    function changeSuperAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        superAdmin=addr;
    }

    /// @dev Allows the current superAdmin to change admin.
    /// @param addr The address to transfer the right of admin to.
    function changeAdmin(address payable addr) external onlySuperAdmin{
        require(addr!=payable(address(0)),INVALID_ADDRESS);
        admin=addr;
    }

    /// @dev Called by superAdmin to withdraw balance.
    function withdrawBalance(uint256 amount) external onlySuperAdmin{
        superAdmin.transfer(amount);
    }

    fallback() external {}
}

pragma solidity >=0.8.0 <0.9.0;

interface IERC20 {

    /// MUST trigger when tokens are transferred, including zero value transfers.
    /// A token contract which creates new tokens SHOULD trigger a Transfer event with 
    ///  the _from address set to 0x0 when tokens are created.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /// MUST trigger on any successful call to approve(address _spender, uint256 _value).
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /// Returns the total token supply.
    function totalSupply() external view returns (uint256);

    /// Returns the account balance of another account with address _owner.
    function balanceOf(address _owner) external view returns (uint256 balance);

    /// Transfers _value amount of tokens to address _to, and MUST fire the Transfer event. 
    /// The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transfer(address _to, uint256 _value) external returns (bool success);

    /// Transfers _value amount of tokens from address _from to address _to, and MUST fire the Transfer event.
    /// The transferFrom method is used for a withdraw workflow, allowing contracts to transfer tokens on your behalf. 
    /// This can be used for example to allow a contract to transfer tokens on your behalf and/or to charge fees in sub-currencies. 
    /// The function SHOULD throw unless the _from account has deliberately authorized the sender of the message via some mechanism.
    /// Note Transfers of 0 values MUST be treated as normal transfers and fire the Transfer event.
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

    /// Allows _spender to withdraw from your account multiple times, up to the _value amount. 
    /// If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) external returns (bool success);

    /// Returns the amount which _spender is still allowed to withdraw from _owner.
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
}