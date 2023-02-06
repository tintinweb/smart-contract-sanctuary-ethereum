/**
 *Submitted for verification at Etherscan.io on 2023-02-06
*/

/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/security/Pausable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;


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

// File: swapp.sol

/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

pragma solidity ^0.8.0;

interface IBEP20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

// this contract should be deployed after the deployment of the two contracts TokenABC and TokenXYZ
// as instrcuted in the 2_deploy_contracts file
contract SwappingExchange is Pausable, Ownable  {

    //0.00401245GoerliETH Gas Fee

    address payable immutable admin;
    //ratioAX is the percentage of how much TokenA is worth of TokenX
    uint256 public ratioAX;
    uint256  public fees;
  
   

    IBEP20 public immutable token;
    IBEP20 public immutable coin;

    uint256 public tokenPrice;
    uint256 public tokensSold;

    uint256 public coinPrice;
    uint256 public coinsSold;

    event PriceChanged (uint256,address);
     event TokenSold (uint256, address);
     event CoinSold (uint256, address);
    
    constructor(IBEP20 _token, IBEP20 _coin,uint256 _tokenPrice,uint256 _coinPrice) {
        admin = payable(msg.sender);
        token = IBEP20(_token);
        coin = IBEP20(_coin);

        tokenPrice = _tokenPrice;
        coinPrice = _coinPrice;
    }

    function withdrawToken(address _tokenContract, uint256 _amount) external onlyAdmin{
        IBEP20 tokenContract = IBEP20(_tokenContract);
        
        // transfer the token from address of this contract
        // to address of the user (executing the withdrawToken() function)
        tokenContract.transfer(msg.sender, _amount);
    }


    modifier onlyAdmin() {
        payable(msg.sender) == admin;
        _;
    }

    function setRatio(uint256 _ratio) public onlyAdmin {
        ratioAX = _ratio;
    }

    function setFees(uint256 _Fees) public onlyAdmin {
        fees = _Fees;
    
    }

   
    // accepts amount of TokenABC and exchenge it for TokenXYZ, vice versa with function swapTKX
    // transfer tokensABC from sender to smart contract after the user has approved the smart contract to
    // withdraw amount TKA from his account, this is a better solution since it is more open and gives the
    // control to the user over what calls are transfered instead of inspecting the smart contract
    // approve the caller to transfer one time from the smart contract address to his address
    // transfer the exchanged TokenXYZ to the sender
    function swapTokenToCoin(uint256 amountTK) public whenNotPaused returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange
        require(amountTK > 0, "amountTK must be greater then zero");
        require(
            token.balanceOf(msg.sender) >= amountTK,
            "sender doesn't have enough Tokens"
        );

        uint256 exchangeA = uint256(mul(amountTK, ratioAX));
        uint256 exchangeAmount = exchangeA -
            uint256((mul(exchangeA, fees)) / 100);
        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            coin.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough Coins, please retry later :=("
        );

       require(token.transferFrom(msg.sender, address(this), amountTK));
        require(coin.transfer(
            msg.sender,
            exchangeAmount
        ));
        return exchangeAmount;
    }

    function swapCoinToToken(uint256 amountCoin) public whenNotPaused returns (uint256) {
        //check if amount given is not 0
        // check if current contract has the necessary amout of Tokens to exchange and the sender
        require(amountCoin > 0, "amountTKX must be greater then ratio");
        require(
            coin.balanceOf(msg.sender) >= amountCoin,
            "sender doesn't have enough Tokens/Coins"
        );

        uint256 exchangeA = amountCoin / ratioAX;
        uint256 exchangeAmount = exchangeA - ((exchangeA * fees) / 100);

        require(
            exchangeAmount > 0,
            "exchange Amount must be greater then zero"
        );

        require(
            token.balanceOf(address(this)) > exchangeAmount,
            "currently the exchange doesnt have enough Tokens, please retry later :=("
        );
        require(coin.transferFrom( msg.sender, address(this), amountCoin));
        require(token.transfer(
            msg.sender,
            exchangeAmount
        ));
        return exchangeAmount;
    }
    

   

     function buyTokens(uint256 numberOfTokens) external whenNotPaused payable {
        // keep track of number of tokens sold
        // require that a contract have enough tokens
        // require tha value sent is equal to token price
        // trigger sell event
        require(msg.value > 0," msg.value should be greater than 0");
        require(token.balanceOf(address(this)) >= numberOfTokens,"Not an enough Contract liquidity for tokens");
        require(token.transfer(msg.sender, numberOfTokens * 10**18));

        tokensSold += numberOfTokens;
        emit TokenSold (tokensSold, msg.sender);
    }

     function buyCoins(uint256 numberOfCoins) external whenNotPaused payable {
        // keep track of number of coins sold
        // require that a contract have enough coins
        // require that value sent is equal to coin price
        // trigger sell event
        require(msg.value > 0," msg.value should be greater than 0");
        require(coin.balanceOf(address(this)) >= numberOfCoins,"Not an enough contract liquidity of coin");
        require(coin.transfer(msg.sender, numberOfCoins * 10**18));

        coinsSold += numberOfCoins;
         emit CoinSold (coinsSold, msg.sender);
    }
     //Tells the liquidity of exchange
     //About token and coin 
     function exchangeLiquidity() public view returns (uint256, uint256) {
        return (token.balanceOf(address(this)),coin.balanceOf(address(this)));
    }
     
    //Change the price of Token
    function changePrice(uint newPrice)  public onlyAdmin  {  // Update Price of Token
        require(newPrice >0,"SHOULD_NOT_ZERO");
        uint256 UpdatePriceToken;
        UpdatePriceToken = newPrice;
        emit PriceChanged(newPrice,msg.sender);
    } 

    //Change the Price of Coin
    function changeCoinPrice(uint newPrice)  public onlyAdmin  {  // Update Price of Token
        require(newPrice >0,"SHOULD_NOT_ZERO");
        uint256 UpdatePriceCoin;
        UpdatePriceCoin = newPrice;
        emit PriceChanged(newPrice,msg.sender);
    }

    function mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }
}