// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "ERC20.sol";

/**
 * @title BUNNY token
 *
 * @dev implementation of ERC20 token with a bit of additional functionality.
 * You are welcome to claim and get some BUNNY.
 * 
 * @dev BUNNY for everyone, for free! And may nobody go offended!
 */
contract Bunny is ERC20 {

    mapping (address => bool) claimed;
    uint256 claimedAmmound;

    event Claiming(
        address indexed _claimer, 
        uint256 _value
    );

    constructor() ERC20("BUNNY", "BUN", 18, 1000000 ether) {}

    /**
     * @dev every address can claim a half of remained not distributed amount of tokens
     * claim could be proceed only once for an address
     */
    function claim() public returns(bool success) {
        require(!claimed[msg.sender], "You've already got your BUNNY!");

        uint256 claimingAmmount = (totalSupply() - claimedAmmound) / 2;
        _mint(msg.sender, claimingAmmount);
        claimed[msg.sender] = true;
        claimedAmmound = claimedAmmound + claimingAmmount;
        emit Claiming(msg.sender, claimingAmmount);
        return true;
    }

    /**
     * @return claimable amount of the tokens
     */
    function claimable() public view returns(uint256 claimable) {
        return totalSupply() - claimedAmmound;
    }

    /**
     * @return boolean if the given address has already claimed BUNNY
     */
    function hasClaimed(address claimer) public view returns(bool) {
        return claimed[claimer];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "IERC20.sol";

/**
 * @title Simple ERC20 token
 *
 * @dev in accordance with https://eips.ethereum.org/EIPS/eip-20
 * SafeMath isn't used due to the compiler version
 */
contract ERC20 is IERC20 {

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;

    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private allowed;

    constructor(
        string memory tokenName, 
        string memory tokenSymbol, 
        uint8 tokenDecimals,
        uint256 tokenTotalSupply
    ) 
    {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = tokenDecimals;
        _totalSupply = tokenTotalSupply;        
    } 

    /**
     * @return the name of the token
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the decimals of the token
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    /**
     * @return total supply of the token
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @return balance of the given address
     */
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    /**
     * @dev transfers token to a given address
     */
    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool success) 
    {
        require(_value <= balances[msg.sender], "Insufficient balance.");

        balances[msg.sender] =  balances[msg.sender] - _value;
        balances[_to] = balances[_to] + _value;

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * @dev transfers token to a given address 
     * from a behalf of another given address
     */
    function transferFrom(
        address _from, 
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool success) 
    {
        require(_value <= allowed[_from][msg.sender], "Not allowed.");
        require(_value <= balances[_from], "Insufficient balance.");

        balances[_from] =  balances[_from] - _value;
        balances[_to] = balances[_to] + _value;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _value;

        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev approves the given address to transfer given ammount of the tokens 
     * from a behalf of sender's address
     */
    function approve(
        address _spender, 
        uint256 _value
    ) 
        public 
        returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * @return remaining amount of the tokens that the given address
     * is allowed to transfer from a behalf of a sender
     */
    function allowance(
        address _owner, 
        address _spender
    ) 
        public view 
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    /**
     * @dev mints new tokens to a given address
     * and fires a Transfer from the token contract event
     */
    function _mint(
        address _to,
        uint256 _value
    )
        internal
    {
        balances[_to] = balances[_to] + _value;
        emit Transfer(address(this), _to, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

/**
 * @title ERC20 token interface
 *
 * @dev in accordance with https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address _owner) external view 
        returns (uint256 balance);

    function transfer(address _to, uint256 _value) external 
        returns (bool success);

    function transferFrom(address _from, address _to, uint256 _value) external 
        returns (bool success);

    function approve(address _spender, uint256 _value) external 
        returns (bool success);

    function allowance(address _owner, address _spender) external view 
        returns (uint256 remaining);

    event Transfer(
        address indexed _from, 
        address indexed _to, 
        uint256 _value
    );

    event Approval(
        address indexed _owner, 
        address indexed _spender, 
        uint256 _value
    );
}