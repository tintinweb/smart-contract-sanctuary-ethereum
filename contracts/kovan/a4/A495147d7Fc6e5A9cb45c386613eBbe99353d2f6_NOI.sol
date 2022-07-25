// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

error NOI__NotAuthorized();
error NOI__InvalidDestination();
error NOI__InsufficientBalance();
error NOI__InsufficientAllowance();

contract NOI {
    // --- Auth ---
    mapping(address => bool) public authorizedAccounts;

    function addAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = true;
        emit AddAuthorization(account);
    }

    function removeAuthorization(address account) external isAuthorized {
        authorizedAccounts[account] = false;
        emit RemoveAuthorization(account);
    }

    modifier isAuthorized() {
        if (authorizedAccounts[msg.sender] == false)
            revert NOI__NotAuthorized();
        _;
    }

    // The name of this coin
    string public name;
    // The symbol of this coin
    string public symbol;
    // The version of this Coin contract
    string public version = "1";
    // The number of decimals that this coin has
    uint8 public constant decimals = 18;

    // The id of the chain where this coin was deployed
    uint256 public chainId;
    // The total supply of this coin
    uint256 public totalSupply;

    // Mapping of coin balances
    mapping(address => uint256) public balanceOf;
    // Mapping of allowances
    mapping(address => mapping(address => uint256)) public allowance;
    // Mapping of nonces used for permits
    mapping(address => uint256) public nonces;

    // --- Events ---
    event AddAuthorization(address account);
    event RemoveAuthorization(address account);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _chainId
    ) {
        authorizedAccounts[msg.sender] = true;
        name = _name;
        symbol = _symbol;
        chainId = _chainId;
        emit AddAuthorization(msg.sender);
    }

    /*
     * @notice Transfer coins to another address
     * @param _dst The address to transfer coins to
     * @param amount The amount of coins to transfer
     */
    function transfer(address _dst, uint256 _amount) external returns (bool) {
        return transferFrom(msg.sender, _dst, _amount);
    }

    /*
     * @notice Transfer coins from a source address to a destination address (if allowed)
     * @param _src The address from which to transfer coins
     * @param _dst The address that will receive the coins
     * @param _amount The _amount of coins to transfer
     */
    function transferFrom(
        address _src,
        address _dst,
        uint256 _amount
    ) public returns (bool) {
        if (_dst == address(0) || _dst == address(this))
            revert NOI__InvalidDestination();
        if (balanceOf[_src] < _amount) revert NOI__InsufficientBalance();
        if (_src != msg.sender) {
            if(allowance[_src][msg.sender] < _amount)
                revert NOI__InsufficientAllowance();
            allowance[_src][msg.sender] = allowance[_src][msg.sender] - _amount;
        }
        balanceOf[_src] = balanceOf[_src] - _amount;
        balanceOf[_dst] = balanceOf[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
        return true;
    }

    /*
     * @notice Mint new coins
     * @param _usr The address for which to mint coins
     * @param _amount The _amount of coins to mint
     */
    function mint(address _usr, uint256 _amount) external isAuthorized {
        balanceOf[_usr] = balanceOf[_usr] + _amount;
        totalSupply = totalSupply + _amount;
        emit Transfer(address(0), _usr, _amount);
    }

    /*
     * @notice Burn coins from an address
     * @param _usr The address that will have its coins burned
     * @param _amount The amount of coins to burn
     */
    function burn(address _usr, uint256 _amount) external isAuthorized {
        if(balanceOf[_usr] < _amount) revert NOI__InsufficientBalance();
        if (_usr != msg.sender) {
            if(allowance[_usr][msg.sender] < _amount) 
                revert NOI__InsufficientAllowance();
            allowance[_usr][msg.sender] = allowance[_usr][msg.sender] - _amount;
        }
        balanceOf[_usr] = balanceOf[_usr] - _amount;
        totalSupply = totalSupply - _amount;
        emit Transfer(_usr, address(0), _amount);
    }

    /*
     * @notice Change the transfer/burn allowance that another address has on your behalf
     * @param _usr The address whose allowance is changed
     * @param _amount The new total allowance for the usr
     */
    function approve(address _usr, uint256 _amount) external returns (bool) {
        allowance[msg.sender][_usr] = _amount;
        emit Approval(msg.sender, _usr, _amount);
        return true;
    }
}