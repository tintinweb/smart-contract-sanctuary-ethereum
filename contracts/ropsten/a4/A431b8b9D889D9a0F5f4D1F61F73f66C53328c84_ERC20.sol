//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import "./IERC20.sol";
import "./AccessControl.sol";

contract ERC20 is IERC20, AccessControl {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private _name;                   
    uint8 private _decimals;                
    string private _symbol; 
    uint256 private _totalSupply;
    uint256 private _initialAmount;
    bytes32  public constant ADMIN = keccak256(abi.encodePacked("ADMIN"));
    bytes32  public constant USER = keccak256(abi.encodePacked("USER"));

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint8 decimals_,
        uint256 initialAmount_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _totalSupply = initialAmount_;
        _balances[msg.sender] += initialAmount_;
        roles[ADMIN][msg.sender] = true;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view override returns (uint256) {
        return _balances[_owner];
    }

    function transfer(address _to, uint _value) public override returns (bool) {
        require(_balances[msg.sender] >= _value, "Amount of transaction is bigger then balance" );
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool) {
        require(_balances[_from] >= _value && _allowances[_from][msg.sender] >= _value, "Amount of transaction is bigger then balance of allowance");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve (address _spender, uint256 _value) public override returns (bool) {
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return _allowances[_owner][_spender];
    }

    function mint(address _owner, uint256 _value) public onlyRole(ADMIN) {
        _balances[_owner] += _value;
        _totalSupply += _value;
        emit Mint(_owner, _value);
    }

    function burn(address _owner, uint256 _value) public onlyRole(ADMIN) {
        _balances[_owner] -= _value;
        _totalSupply -= _value;
        emit Burn(_owner, _value);
    }

    event Mint(address indexed _owner, uint256 _value);
    
    event Burn(address indexed _owner, uint256 _value); 
}

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

interface IERC20 {

    /*
    * Returns the total token supply
    */
    function totalSupply() external view returns (uint256);

    /*
    * Returns the account balance of another account
    * @param _owner - address of the account whose balance we want to know
    */
    function balanceOf(address _owner) external view returns (uint256);

    /*
    * Transfers amount of tokens to specified address
    * MUST fire the Transfer event
    * SHOULD throw if the message caller’s account balance does not have enough tokens to spend
    * @param _to - address where we want to transfer tokens
    * @param _value - amount of tokens
    */
    function transfer(address _to, uint256 _value) external returns (bool);

    /*
    * Transfers amount of tokens from one address to another address
    * MUST fire the Transfer event
    * SHOULD throw unless the _from account has deliberately authorized the sender
    * @param _from - address from we want to transfer tokens
    * @param _to - address where we want to transfer tokens
    * @param _value - amount of transfer in Wei
    */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

    /*
    * Allows to withdraw from your account multiple times
    * SHOULD make sure to create user interfaces in such a way that they set the allowance first to 0 before setting it to another value for the same spender
    * @param _spender - address that would be approved to withdraw from your account
    * @param _value - amount of tokens to approve
    */
    function approve(address _spender, uint256 _value) external returns (bool);

    /*
    * Returns the amount which is still allowed to withdraw from address
    * @param _owner - address that own contract
    * @param _spender - address that want to transfer tokens from contract
    */
    function allowance(address _owner, address _spender) external view returns (uint256);

    /*
    * MUST trigger when tokens are transferred, including zero value transfers
    * A token contract which creates new tokens SHOULD trigger a Transfer event with the address set to 0x0 when tokens are created
    * @param _from - address from which tokens are transfered
    * @param _to - address to which tokens are transfered
    * @param _value - amount of tokens
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    /*
    * MUST trigger on any successful call to approve
    * @param _owner - address that own contract
    * @param _spender - address that would be approved to withdraw from your account
    * @param _value - amount of tokens to approve
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);





}

//SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

contract AccessControl {

    mapping (bytes32 => mapping(address => bool)) public roles;

    modifier onlyRole(bytes32 _role){
        require(roles[_role][msg.sender], "not authorized");
        _;
    }

    function _grantRole (bytes32 _role, address _account) internal {
        roles[_role][_account] = true;
        emit GrantRole(_role, _account);
    }

    function grantRole(bytes32 _role, address _account) external {
        require(roles[_role][msg.sender], "not authorized");
        _grantRole(_role, _account);
    }

    function revokeRole(bytes32 _role, address _account) external {
        require(roles[_role][msg.sender], "not authorized");
        roles[_role][_account] = false;
        emit RevokeRole(_role, _account);
    }

    event GrantRole(bytes32 indexed _role, address indexed _account);
    event RevokeRole(bytes32 indexed _role, address indexed _account); 

}