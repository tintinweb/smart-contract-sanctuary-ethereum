//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.1;

/**  
* @title Standard but handmade contract by standard ERC20.
* @author Pavel E. Hrushchev (DrHPoint).
* @notice You can use this contract for standard token transactions.
* @dev All function calls are currently implemented without side effects. 
*/
contract Standart_ERC20 {
    string private _name;
    string private _symbol;
    uint8 private immutable _decimals; // = 18;
    uint256 private _totalSupply = 0;
    address public owner;
    address public bridge;
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    /** 
    * @notice This event shows from which (_from) and to which address (_to) a certain amount (_value) of tokens were transferred.
    * @dev Nothing unusual. Standard event with two addresses and the amount of tokens for which the transaction is made.
    * @param _from is the address from which the transaction is made.
    * @param _to is the address to which the transaction is made.
    * @param _value is the value by which the transaction is made.
    */
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    /**  
    * @notice This event indicates that a user with one address (_owner) has entrusted a user with a different address (_spender) to use a certain number of tokens (_value).
    * @dev Nothing unusual. Standard event with two addresses and the amount of tokens with which action is allowed.
    * @param _owner is the address from which the approval was given to carry out transactions by proxy.
    * @param _spender is the address to which the approval was given to carry out transactions by proxy.
    * @param _value is the value by which the approval was given to carry out transactions by proxy.
    */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**  
    * @notice This event notifies about the transfer of ownership of the contract from the old address (_previousOwner) to the new address(_newOwner)
    * @dev Nothing unusual. Standard event with two addresses signifying the transfer of ownership to a contract
    * @param _previousOwner is the address of previous owner of that contract.
    * @param _newOwner is the address of new owner of that contract.
    */
    event OwnershipTransferred(address indexed _previousOwner, address indexed _newOwner);

    /** 
    *@dev Currently, the value of '_totalSupply' shown in the constructor, cannot be set. Set '_name', '_symbol' and '_decimals' value
    * @param Name is Name of Token.
    * @param Symbol is Symbol of Token.
    * @param Decimals is Decimals of the token (how many the whole token is being divided).
    */  
    constructor(string memory Name, string memory Symbol, uint8 Decimals) {
        owner = msg.sender;
        _name = Name;
        _symbol = Symbol;
        _decimals = Decimals;
        mint(owner, 19632017 * 1e18);
    }

    ///@dev modifier to check for owner address
    modifier onlyForOwnerAndBridge () {
        require(((msg.sender == owner) || (msg.sender == bridge)), "Not owner or bridge");
        _;
   }  

    ///@dev modifier to check for owner address
    modifier onlyForOwner () {
        require(msg.sender == owner, "Not owner");
        _;
   }  

    /**  
    * @notice This function returns the name of the token.
    * @dev Returns the name of the token, which is hardcoded in the parameters of the contract.
    * @return _name - Name of Token.
    */
    function name() external view returns (string memory) {
        return _name;
    }

    /**  
    * @notice This function returns the symbol of the token.
    * @dev Returns the symbol of the token, which is hardcoded in the parameters of the contract.
    * @return _symbol - Symbol of Token.
    */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**  
    * @notice This function shows how many the whole token is being divided.
    * @dev Returns the decimals of the token, which is hardcoded in the parameters of the contract.
    * @return _decimals - Decimals of the token (how many the whole token is being divided).
    */
    function decimals() external view returns (uint8){
        return _decimals;
    }

    /**  
    * @notice This function shows the sum of all balances.
    * @dev Standard function that returns the current amount of balances.
    * @return totalSupply - the sum of all balances.
    */
    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    /**  
    * @notice This function shows the balance of the address (_owner) you need to know.
    * @dev Standart view balance function without any complexity.
    * @param _owner - The address of the client whose balance you want to check.
    * @return balance - The client's token balance
    */
    function balanceOf(address _owner) external view returns (uint256 balance){
        return _balances[_owner];
    }

    /**  
    * @notice This function transfers a certain number of tokens (_value) from the address from which the user applies to another address specified in the parameters (_to).
    * @dev The function checks for a zero address, then for a sufficient number of tokens on the balance of the contacting user, after which it conducts a transfer and calls transaction event.
    * @param _to - The address of the user to whose balance the transfer is made.
    * @param _value - The value of tokens used in the transfer.
    * @return success - value "true" if the transfer was successful.
    */
    function transfer(address _to, uint256 _value) external returns (bool success) {
        require(_to != address(0), "Transfer to the zero address");
        require(_balances[msg.sender] >= _value, "Not enough tokens");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /** 
    *  @notice This function transfers a certain number of tokens (_value) from the address from which the user wants to transfer tokens (_from) to another address specified in the parameters (_to).
    * @dev The function checks for a zero address, then for a sufficient number of tokens on the balance of another user, from which the contact's user wants to transfer tokens and whether it is allowed to him, after which it conducts a transfer, reduces the number of trusted tokens and calls transaction event.
    * @param _from - The address of the user from whose balance the transfer is made.
    * @param _to - The address of the user to whose balance the transfer is made.
    * @param _value - The value of tokens used in the transfer.
    * @return success - value "true" if the transfer was successful.
    */
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success){
        require(_from != address(0), "Transfer from the zero address");
        require(_to != address(0), "Transfer to the zero address");
        require(_allowances[_from][msg.sender] >= _value, "Not enough allowed amount");
        require(_balances[_from] >= _value, "Not enough tokens");
        _balances[_from] -= _value;
        _balances[_to] += _value;
        _allowances[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**  
    * @notice This function allows the requesting user to entrust the management of a certain amount of tokens (_value) to a user with a different address (_spender).
    * @dev The function checks for the presence of a zero address, after which it assigns a power of attorney for the use of a certain number of tokens and calls approval event.
    * @param _spender - The address of the user who is allowed to use other user tokens.
    * @param _value - The value of tokens that the specified user is allowed to use.
    * @return success - value "true" if the approve was successful.
    */
    function approve(address _spender, uint256 _value) external returns (bool success){
        require(_spender != address(0), "Approve to the zero address");
        _allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**  
    * @notice This function allows you to find out how many tokens a user with one specified address (_owner) is trusted to use from the user's balance with another specified address (_spender).
    * @dev Nothing unusual. Returns the current trusted tokens.
    * @param _owner - The address of the user who trusts the use of their tokens.
    * @param _spender - The address of the user who is allowed to use other user tokens.
    * @return remaining - The current number of tokens trusted by one user to another user.
    */
    function allowance(address _owner, address _spender) external view returns (uint256 remaining){
        return _allowances[_owner][_spender];
    }

    /** @notice This function allows you to burn a certain number of tokens from a specified address (_from).
    * @dev The function checks for the owner of the contract, for a zero address, for a sufficient number of tokens at a given user address and burns tokens from this address, together with a decrease totalSupply, after which it calls transaction event.
    * @param _from - User address from whose balance tokens are burned.
    * @param _value - The value of tokens to be burned.
    * @return success - value "true" if the burn of tokens was successful.
    */
    function burn(address _from, uint256 _value) public onlyForOwnerAndBridge returns (bool success){
        require(_from != address(0), "Burn from the zero address");
        require(_balances[_from] >= _value, "Not enough tokens");
        _balances[_from] -= _value;
        _totalSupply -= _value;
        emit Transfer(_from, address(0), _value);
        return true;
    }

    /**  
    * @notice This function allows you to mint a certain number of tokens to a specified address (_to).
    * @dev The function checks for the owner of the contract, for a zero address and burns tokens from at a given user address, together with a decrease totalSupply, after which it calls transaction event.
    * @param _to - User address from whose balance tokens are minted.
    * @param _value - The value of tokens to be minted.
    * @return success - value "true" if the mint of tokens was successful.
    */
    function mint(address _to, uint256 _value) public onlyForOwnerAndBridge returns (bool success){
        require(_to != address(0), "Mint to the zero address");
        _balances[_to] += _value;
        _totalSupply += _value;
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**  
    * @notice This function allows you to transfer ownership of a contract to a new owner(_newOwner).
    * @dev The function checks for the owner of the contract, for a zero address and transfer ownership of a contract to a new owner, after which it calls ownership transferred event.
    * @param _newOwner - User address from whose balance tokens are minted.
    */
    function transferOwnership(address _newOwner) public onlyForOwner {
        require(_newOwner != address(0), "New owner have the zero address");
        address oldOwner = owner;
        owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    /**  
    * @notice This function allows you to set a new bridge address(_newBridge).
    * @dev The function checks for the owner of the contract, for a zero address and transfer ownership of a contract to a new owner, after which it calls ownership transferred event.
    * @param _newBridge - User address from whose balance tokens are minted.
    */
    function setBridgeAddress(address _newBridge) public onlyForOwner {
        require(_newBridge != address(0), "New bridge have the zero address");
        bridge = _newBridge;
    }
}