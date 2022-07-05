/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.9;

interface ERC20Interface {

    function decimals() external pure returns (uint8);
    function balanceOf(address _owner) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function burn(uint256 _amount, address _burner) external returns (bool);
    function mint(uint256 _amount) external;
}

contract TokenContract is ERC20Interface {
    string constant public name = 'Niery Token Papa';
    string constant public symbol = 'NTP';
    uint8 constant private _decimals = 18;
    
    // It can be 'external' instead of 'public' but we have to check how to call an external method from another contract
    uint256 public totalSupply; 

    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowed;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    address private vaultAddress;
    
    modifier isValidAddress(address _address) {
        require(_address != address(0) && _address != address(this), 'The provided address is not valid');
        _;
    }

    modifier isValidVaultAddress() {
        require(vaultAddress != address(0) && vaultAddress != address(this), 'The Vault address is not valid');
        _;
    }

    constructor(uint256 _initialAmount, address _vaultAddress) isValidAddress(_vaultAddress) {
        require(_initialAmount > 0, 'Initial amount must be greater than zero');
        totalSupply = _initialAmount;
        vaultAddress = _vaultAddress;
        _balances[address(msg.sender)] = _initialAmount;
        emit Transfer(address(0x0), address(msg.sender), _initialAmount);
    }

    function decimals() external pure returns (uint8){
        return _decimals;
    }


    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    /**
     * @dev Transfers @param _value amount of tokens to address @param _to, and MUST fire the Transfer event.
     * The function SHOULD throw if the message caller’s account balance does not have enough tokens to spend.
     * @param _to address that will receive tokens
     * @param _value amount of tokens to transfer. Transfers of 0 values MUST be treated as normal transfers
     * @return true if the amount was trafsfered correctly
     */
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0), 'Receiver cannot be address(0)');
        // require(_value > 0, 'Amount must be positive'); // La quite porque en el standard ERC-20 dice que las transferencias de valor 0 deben ser tratadas como una transferencia normal.
        require(_balances[msg.sender] >= _value, 'Sender has insufficient tokens to transfer');
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev Is used for a withdraw workflow, allowing contrats to transfer tokens on @param _from behalf.
     * It can be used to allow a contract to transfer tokens on other's behalf and/or to charge fees in sub-currencies.
     * The function SHOULD throw unless the _from account has deliberately authorized the msg.sender of the message via some mechanism
     * @param _to address that will receive tokens
     * @param _value amount of tokens to transfer. Transfers of 0 values MUST be treated as normal transfers
     * @return true if the amount was trafsfered correctly
     *
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool) {
        require(_from != address(0), '_from cannot be adress(0)');
        require(_to != address(0), '_to cannot be adress(0)');
        require(_value <= _allowed[_from][msg.sender], "Tx signer is not allowed to transfer the desired amount on _from's behalf"); // el que firma la transaccion tiene que estar autorizado a gastar toens de _from
        require(_balances[_from] >= _value, '_from has insufficient tokens to transfer');

        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowed[_from][msg.sender] -= _value; // le resto monto permitido porque me lo acabo de gastar.

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Allows @param _spender to withdraw from your account multiple times,
     * up to the @param _value amount. If this function is called again it overwrites the current allowance with @param _value.
     * @param _spender who will be allowed to use tokens on msg.sender's behalf.
     * @param _value amount of tokens allowed to use
     * @return true if the amount was allowed correctly
     */
    function approve(address _spender, uint256 _value) external returns (bool) {
        require(_spender != address(0), '_spender cannot be adress(0)');
        _allowed[msg.sender][_spender] = 0; // lo dice el standard ERC-20
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _allowed[msg.sender][_spender]);
        return true;
    }

    /**
     * @dev Returns the amount which @param _spender is still allowed to withdraw from @param _owner.
     */
    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    /**
     * @dev It burns an @param _amount from the balance of the sender 
     */
    function burn(uint256 _amount, address _burner) external isValidVaultAddress isValidAddress(_burner) returns (bool) {
        require(msg.sender == vaultAddress, 'Only Vault can call this function');
        require(_amount <= _balances[_burner], '_amount cannot be greater than sender balance');
        _balances[_burner] -= _amount;
        totalSupply -= _amount;

        emit Transfer(_burner, address(0), _amount);
        return true;
    }

     /**
     * @dev It mint an @param _amount from the balance of the sender 
     */
    function mint(uint256 _amount) external isValidVaultAddress {
        require(msg.sender == vaultAddress, 'Only Vault can call this function');
        require(_amount > 0, '_amount must be greater than 0');
        _balances[msg.sender] += _amount;
        totalSupply += _amount;

        emit Transfer(address(0), msg.sender, _amount);
    }
}