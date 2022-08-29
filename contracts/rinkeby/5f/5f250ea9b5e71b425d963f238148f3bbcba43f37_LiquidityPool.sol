/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

// SPDX-License-Identifier: MIT

// File: ERC20Token.sol



pragma solidity ^0.8.0;

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; 
}

contract ERC20Token {
    // Public variables of the token
    string public name;
    string public symbol;
    // 18 decimals is the strongly suggested default, avoid changing it
    uint256  totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    // This generates a public event on the blockchain that will notify clients
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount minted
    event Mint(address indexed from, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constructor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(
        uint256 initialSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;                // Give the creator all initial tokens
        name = tokenName;                                   // Set the name for display purposes
        symbol = tokenSymbol;                               // Set the symbol for display purposes
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != address(0x0));
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(balanceOf[_to] + _value >= balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        // Subtract from the sender
        balanceOf[_from] -= _value;
        // Add the same to the recipient
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender], "Invalid allowance");     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Mint tokens.
     * Create `_value` new tokens and credit them to a specified address
     * @param _receiver the address of the receiver of the new minted token
     * @param _value the amount of token to create
     */
    function _mint(address _receiver, uint256 _value) internal returns (bool success) {
        balanceOf[_receiver] += _value;            // add new tokens to the balance of the receiver
        totalSupply += _value;                     // Updates totalSupply
        emit Mint(msg.sender, _value);
        return true;
    }

    /**
     * Burn tokens.
     * Remove `_value` tokens from the system irreversibly
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] -= _value;            // Update balances of the sender
        totalSupply -= _value;                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }



}
// File: SafeMath.sol


pragma solidity ^0.8.0;



library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'ds-math-add-overflow');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'ds-math-sub-underflow');
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'ds-math-mul-overflow');
    }
}

// File: LiquidityPool.sol



pragma solidity ^0.8.0;


// import "./librairies/Math.sol";


contract LiquidityPool is ERC20Token {

    using SafeMath for uint;

    // Public variables of the Liquidity Pool
    address public addressTokenA; 
    address public addressTokenB; 
    address public owner; 
    uint256 public reserveTokenA;
    uint256 public reserveTokenB;
    uint32 private blockTimestampLast;
    uint256 public priceTokenA;
    uint256 public priceTokenB;
    // XXX TODO Add fees

    event Sync(uint256 reserveTokenA, uint256 reserveTokenB);

    event MintLPToken(address indexed from, uint256 amountTokenA, uint256 amountTokenB);

    constructor(
        string memory _name,
        string memory _symbol,
        address _addressTokenA,
        address _addressTokenB
    ) ERC20Token(0, _name, _symbol) {
        addressTokenA = _addressTokenA;
        addressTokenB = _addressTokenB;
        owner = msg.sender;
    }

    function addLiquidity(
        uint256 _amountTokenA,
        uint256 _amountTokenB
    ) public returns (bool success) {
        // XXX TODO add check to make sure ratio tokenA/tokenB is correct

        ERC20Token tokenA = ERC20Token(addressTokenA);
        require(
            tokenA.transferFrom(msg.sender, address(this), _amountTokenA),
            "Tranfer of token failed"
        );
        ERC20Token tokenB = ERC20Token(addressTokenB);
        require(
            tokenB.transferFrom(msg.sender, address(this), _amountTokenB),
            "Tranfer of token failed"
        );

        mint(msg.sender); // mint new LP tokens

        return true;
    }


    function mint(address to) internal returns (uint liquidity) {
        uint256 _balanceTokenA = ERC20Token(addressTokenA).balanceOf(address(this));
        uint256 _balanceTokenB = ERC20Token(addressTokenB).balanceOf(address(this));

        uint256 _reserveTokenA = reserveTokenA;
        uint256 _reserveTokenB = reserveTokenB;

        uint256 _amountTokenA = _balanceTokenA - _reserveTokenA;
        uint256 _amountTokenB = _balanceTokenB - _reserveTokenB;
        
        uint256 _totalSupply = totalSupply; 
        if (_totalSupply == 0) { 
            liquidity = _amountTokenA * _amountTokenB / _amountTokenB; 
        } else {
            liquidity = _amountTokenA * _amountTokenB / _amountTokenB;
        }
        require(liquidity > 0, 'Liquidity added invalid');
        _mint(to, liquidity);
        _update(_balanceTokenA, _balanceTokenB, _reserveTokenA, _reserveTokenB); 
        emit MintLPToken(msg.sender, _amountTokenA, _amountTokenB);
    }


    // given an input amount of an asset and pair reserves, returns the maximum output amount of the other asset
    // function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) internal pure returns (uint amountOut) {
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
        require(amountIn > 0, 'UniswapV2Library: INSUFFICIENT_INPUT_AMOUNT');
        require(reserveIn > 0 && reserveOut > 0, 'UniswapV2Library: INSUFFICIENT_LIQUIDITY');
        uint amountInWithFee = amountIn.mul(997);
        uint numerator = amountInWithFee.mul(reserveOut);
        uint denominator = reserveIn.mul(1000).add(amountInWithFee);
        amountOut = numerator / denominator;
    }


    




    function _update(
        uint256 _balanceTokenA,
        uint256 _balanceTokenB,
        uint256 _reserveTokenA,
        uint256 _reserveTokenB
    ) private {
        require(_balanceTokenA >= 0 && _balanceTokenB >= 0, "Invalid balances");
        if(_reserveTokenA > 0 && _reserveTokenB > 0) {
            priceTokenA += _reserveTokenA / _reserveTokenB;
            priceTokenB += _reserveTokenB / _reserveTokenA;
        }

        reserveTokenA = _balanceTokenA;
        reserveTokenB = _balanceTokenB;

        emit Sync(reserveTokenA, reserveTokenA);
    }

    function sync() external {
        _update(
            ERC20Token(addressTokenA).balanceOf(address(this)),
            ERC20Token(addressTokenB).balanceOf(address(this)),
            reserveTokenA,
            reserveTokenB
        );
    }
}

// File: DEX.sol



pragma solidity ^0.8.0;


contract DEX {

    // XXX TODO Add fees const

    string public name = "My AMM Dex";

    mapping(address => mapping(address => address)) public getLiquidityPool;
    address[] public allLiquidityPools;

    event LiquidityPoolCreated(address indexed addressTokenA, address indexed addressTokenB, address indexed liquidityPool, string symbol);

    constructor() {}

    function createLiquidityPool(string memory _name, string memory _symbol, address _tokenA, address _tokenB) external returns (address) {
        require(_tokenA != _tokenB, 'Invalid tokens addresses');
        require(_tokenA != address(0), 'Invalid address');
        require(_tokenB != address(0), 'Invalid address');
        require(getLiquidityPool[_tokenA][_tokenB] == address(0), 'Liquidity Pool already exists');
        require(getLiquidityPool[_tokenB][_tokenA] == address(0), 'Liquidity Pool already exists'); 
        
        address liquidityPool = address(new LiquidityPool(_name, _symbol, _tokenA, _tokenB));
        getLiquidityPool[_tokenA][_tokenB] = liquidityPool;
        getLiquidityPool[_tokenB][_tokenA] = liquidityPool;
        allLiquidityPools.push(liquidityPool);
        
        emit LiquidityPoolCreated(_tokenA, _tokenB, liquidityPool, _symbol);
        return liquidityPool;
    }
}