//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "./Token.sol";

/**
 @title chd
 @dev chd is the synthetic representation of deposits on other AMM's created by the charon system
**/    
contract CHD is Token{

    //storage
    address public charon;//address of the charon contract

    //events
    event CHDMinted(address _to, uint256 _amount);
    event CHDBurned(address _from, uint256 _amount);

    //functions
    /**
     * @dev constructor to initialize contract and token
     */
    constructor(address _charon,string memory _name, string memory _symbol) Token(_name,_symbol){
        charon = _charon;
    }

    /**
     * @dev allows the charon contract to burn tokens of users
     * @param _from address to burn tokens of
     * @param _amount amount of tokens to burn
     */
    function burnCHD(address _from, uint256 _amount) external{
        require(msg.sender == charon);
        _burn(_from, _amount);
        emit CHDBurned(_from,_amount);
    }
    
    /**
     * @dev allows the charon contract to mint chd tokens
     * @param _to address to mint tokens to
     * @param _amount amount of tokens to mint
     */
    function mintCHD(address _to, uint256 _amount) external{
        require(msg.sender == charon);
        _mint(_to,_amount);
        emit CHDMinted(_to,_amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "../CHD.sol";

/**
 @title MockERC20
 @dev mock token contract to allow minting and burning for testing
**/  
contract MockERC20 is CHD{

    constructor(address _charon,string memory _name, string memory _symbol) CHD(_charon,_name,_symbol){
    }

    function burn(address _account, uint256 _amount) external virtual {
        _burn(_account,_amount);
    }
    
    function mint(address _account, uint256 _amount) external virtual {
        _mint(_account,_amount);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

/**
 @title Token
 @dev base ERC20 to act as token underlying CHD and pool tokens
 */
contract Token{

    //storage
    string  private tokenName;
    string  private tokenSymbol;
    uint256 internal supply;//totalSupply
    mapping(address => uint) balance;
    mapping(address => mapping(address=>uint)) userAllowance;//allowance

    //events
    event Approval(address indexed _src, address indexed _dst, uint _amt);
    event Transfer(address indexed _src, address indexed _dst, uint _amt);

    //functions
    /**
     * @dev Constructor to initialize token
     * @param _name of token
     * @param _symbol of token
     */
    constructor(string memory _name, string memory _symbol){
        tokenName = _name;
        tokenSymbol = _symbol;
    }

    /**
     * @dev allows a user to approve a spender of their tokens
     * @param _spender address of party granting approval
     * @param _amount amount of tokens to allow spender access
     */
    function approve(address _spender, uint256 _amount) external returns (bool) {
        userAllowance[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    /**
     * @dev function to transfer tokens
     * @param _to destination of tokens
     * @param _amount of tokens
     */
    function transfer(address _to, uint256 _amount) external returns (bool) {
        _move(msg.sender, _to, _amount);
        return true;
    }

    /**
     * @dev allows a party to transfer tokens from an approved address
     * @param _from address source of tokens 
     * @param _to address destination of tokens
     * @param _amount uint256 amount of tokens
     */
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool) {
        require(msg.sender == _from || _amount <= userAllowance[_from][msg.sender], "not approved");
        _move(_from,_to,_amount);
        if (msg.sender != _from) {
            userAllowance[_from][msg.sender] = userAllowance[_from][msg.sender] -  _amount;
            emit Approval(_from, msg.sender, userAllowance[_from][msg.sender]);
        }
        return true;
    }

    //Getters
    /**
     * @dev retrieves standard token allowance
     * @param _src user who owns tokens
     * @param _dst spender (destination) of these tokens
     * @return uint256 allowance
     */
    function allowance(address _src, address _dst) external view returns (uint256) {
        return userAllowance[_src][_dst];
    }

    /**
     * @dev retrieves balance of token holder
     * @param _user address of token holder
     * @return uint256 balance of tokens
     */
    function balanceOf(address _user) external view returns (uint256) {
        return balance[_user];
    }
    
    /**
     * @dev retrieves token number of decimals
     * @return uint8 number of decimals (18 standard)
     */
    function decimals() external pure returns(uint8) {
        return 18;
    }

    /**
     * @dev retrieves name of token
     * @return string token name
     */
    function name() external view returns (string memory) {
        return tokenName;
    }

    /**
     * @dev retrieves symbol of token
     * @return string token sybmol
     */
    function symbol() external view returns (string memory) {
        return tokenSymbol;
    }

    /**
     * @dev retrieves totalSupply of token
     * @return amount of token
     */
    function totalSupply() external view returns (uint256) {
        return supply;
    }

    //internal
    /**
     * @dev burns tokens
     * @param _from address to burn tokens from
     * @param _amount amount of token to burn
     */
    function _burn(address _from, uint256 _amount) internal {
        balance[_from] = balance[_from] - _amount;//will overflow if too big
        supply = supply - _amount;
        emit Transfer(_from, address(0), _amount);
    }

    /**
     * @dev mints tokens
     * @param _to address of recipient
     * @param _amount amount of token to send
     */
    function _mint(address _to,uint256 _amount) internal {
        balance[_to] = balance[_to] + _amount;
        supply = supply + _amount;
        emit Transfer(address(0), _to, _amount);
    }

    /**
     * @dev moves tokens from one address to another
     * @param _src address of sender
     * @param _dst address of recipient
     * @param _amount amount of token to send
     */
    function _move(address _src, address _dst, uint256 _amount) internal virtual{
        balance[_src] = balance[_src] - _amount;//will overflow if too big
        balance[_dst] = balance[_dst] + _amount;
        emit Transfer(_src, _dst, _amount);
    }
}