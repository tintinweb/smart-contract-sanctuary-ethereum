/**
 *Submitted for verification at Etherscan.io on 2022-12-19
*/

// File @openzeppelin/contracts/utils/[email protected]

// SPDX-License-Identifier: MIT
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


// File @openzeppelin/contracts/access/[email protected]


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


// File contracts/dependencies/Controller.sol


pragma solidity 0.8.4;

contract Controller is Ownable {
    mapping(address => bool) public operator;
    event OperatorCreated(address _operator, bool _whiteList);

    modifier onlyOperator() {
        require(operator[msg.sender], "Only-Operator");
        _;
    }

    function setOperator(address _operator, bool _whiteList) public onlyOwner {
        operator[_operator] = _whiteList;
        emit OperatorCreated(_operator, _whiteList);
    }

}


// File contracts/EmpireV2.sol


pragma solidity 0.8.4;

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
}

interface IEmpireFactory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IEmpireRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

/// @title EmpireV2: A contract for the EMPIREv2 token
/// @author Empire Capital (Splnty, Tranquil Flow) https://github.com/Empire-Capital
/// @dev This contract defines the core logic of EMPIRE token
contract EmpireV2 is Controller {
    string  private _name = "Empire Network";
    string  private _symbol = "EMPIRE";
    uint256 private _totalSupply;
    uint8   private _decimals = 18;

    address public pair;
    uint256 public addLiquidityAmount;
    uint256 public buyLiquidityFee;
    uint256 public sellLiquidityFee;
    uint256 public blockCooldownAmount;

    bool private _inSwap;
    bool public tradingActive;
    bool public antiBotsActive;

    IEmpireRouter private router;
    
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => uint256) private _balances;
    mapping (address => bool) public _excludedFees;
    mapping (address => bool) public _excludedAntiMev;
    mapping (address => uint256) public antiMevBlock;
    mapping (address => bool) public automatedMarketMakerPairs;
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event LiquidityAdded(uint256 tokens, uint256 nativeCoin, uint256 lpAdded);
    event NewLimit(uint256 newAddLiqAmount);
    event NewFees(uint256 newBuyLiqFee, uint256 newSellLiqFee);
    event SetExcludedFees(address addr, bool status);
    event SetTradingActive(bool status);
    
    /// @param _router The address of the router that EMPIRE is interacting with for transfer fees
    constructor (address _router) {

        router = IEmpireRouter(_router);        

        pair = IEmpireFactory(router.factory())
            .createPair(address(this), router.WETH());

        setAutomatedMarketMakerPair(pair, true);

        addLiquidityAmount = 100 * 10 **_decimals;
        buyLiquidityFee = 5000;         // 5%
        sellLiquidityFee = 5000;        // 5%
        blockCooldownAmount = 1;
        antiBotsActive = true;
        
        setExcludedFees(address(this), true);
        setExcludedFees(owner(), true);
        setExcludedAntiMev(address(this), true);
    }
    
    receive() payable external {}

    /*//////////////////////////////////////////////////////////////
                            USER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "Wallet address can not be the zero address!");
        require(spender != address(0), "Spender can not be the zero address!");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "Decreased allowance below zero!");
        _approve(msg.sender, spender, currentAllowance - subtractedValue);
        return true;
    }

    /// @notice High level function to move `amount` of tokens from `msg.sender` to `recipient` and applying fees
    /// @dev Transfers amount of tokens from the msg.sender to recipient
    /// @param recipient The address that is receiving tokens
    /// @param amount The initial amount of tokens being sent, before fees on transfer
    /// @return True if transfer is successful, else false
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    
    /// @notice High level function to move `amount` of tokens from `sender` to `recipient` and applying fees
    /// @dev Transfers amount of tokens from sender to recipient
    /// @param sender The address that is sending tokens
    /// @param recipient The address that is receiving tokens
    /// @param amount The initial amount of tokens being sent, before fees on transfer
    /// @return True if transfer is succesful, else false
    function transferFrom(address sender, address recipient, uint256 amount) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[sender][msg.sender];
        require(currentAllowance >= amount, "Amount exceeds allowance!");
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, currentAllowance - amount);    
        return true;
    }

    /// @notice Low level function that sends `amount` from `sender` to `recipient`, checking limitations & apply fees
    /// @dev Transfers amount of tokens from sender to recipient
    /// @param sender The address that is sending tokens
    /// @param recipient The address that is receiving tokens
    /// @param amount The initial amount of tokens being sent, before fees on transfer
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {

        //anti mev
        if(antiBotsActive) {
            if(!_excludedAntiMev[sender] && !_excludedAntiMev[recipient])
            {
                address actor = antiMevCheck(sender, recipient);
                antiMevFreq(actor);
                antiMevBlock[actor] = block.number;
            }
        }
        
        uint256 senderBalance = balanceOf(sender);
        require(senderBalance >= amount, "Amount exceeds senders balance!");
        _balances[sender] = senderBalance - amount;

       if(!tradingActive){
            require(_excludedFees[sender] || _excludedFees[recipient], "Trading is not active.");
        }

        bool takeFee = !_inSwap;

        if(
            _excludedFees[sender] || 
            _excludedFees[recipient] 
        ) {
            takeFee = false;
        }

        if(takeFee) {
            uint256 liquidityAmount = 0;
        
            //if buy
            if(automatedMarketMakerPairs[sender]) {
                liquidityAmount = amount * buyLiquidityFee / 100000;
            }

            //if sell
            if(automatedMarketMakerPairs[recipient]) {
                liquidityAmount = amount * sellLiquidityFee / 100000;
                
                swapAddLiquidity();
            }

            if(liquidityAmount > 0){ 
                amount -= liquidityAmount;
                _balances[address(this)] += liquidityAmount;
                emit Transfer(sender, address(this), liquidityAmount);
            }
        }
        
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    /// @dev Adds liquidity on the EMPIRE/Native Coin pair
    /// @param tokenAmount The amount of tokens for adding to liquidity
    /// @param amount The amount of native coin for adding to liquidity
    function addLiquidity(uint256 tokenAmount, uint256 amount) internal virtual {
        _approve(address(this), address(router), tokenAmount);
        (uint256 tokens, uint256 eth, uint256 lpCreated) = 
        router.addLiquidityETH{value: amount}(address(this), tokenAmount, 0, 0, address(this), block.timestamp);
        emit LiquidityAdded(tokens, eth, lpCreated);
    }

    /// @dev Swaps `amount` EMPIRE for native coin
    /// @param amount The amount of EMPIRE to swap
    function swapTokensForEth(uint256 amount) internal virtual {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        _approve(address(this), address(router), amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount, 0, path, address(this), block.timestamp);
    }

    /// @notice Sells EMPIRE for native coin and uses both to add liquidity
    /// @dev Checks if the amount of EMPIRE on the contract is > addLiquidityAmount
    function swapAddLiquidity() internal virtual {
        uint256 tokenBalance = balanceOf(address(this));
        if(!_inSwap && tokenBalance >= addLiquidityAmount) {
            _inSwap = true;
            
            uint256 sellAmount = tokenBalance;
            uint256 sellHalf = sellAmount / 2;

            uint256 initialEth = address(this).balance;
            swapTokensForEth(sellHalf);
            uint256 receivedEth = address(this).balance - initialEth;

            addLiquidity(sellAmount - sellHalf, (receivedEth));

            _inSwap = false;
        }
    }

    /// @notice Burns `amount` EMPIRE tokens
    /// @dev Used to manually burn EMPIRE
    /// @param amount The amount of EMPIRE to burn
    function manualBurn(uint256 amount) external {
        address account = msg.sender;
        require(amount <= _balances[account], "Burn amount exceeds balance");
        _balances[account] -= amount;
        _totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }

    /*//////////////////////////////////////////////////////////////
                            ANTI BOT FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function antiMevCheck(address _from, address _to) internal virtual returns (address) {
        require(!isContract(_to) || !isContract(_from), "No bots allowed!");
        if (isContract(_to)) return _from;
        else return _to;
    }

    function antiMevFreq(address addr) internal virtual {
        bool isAllowed = antiMevBlock[addr] == 0 ||
            ((antiMevBlock[addr] + blockCooldownAmount) < (block.number + 1));
        require(isAllowed, "Max tx frequency exceeded!");
    }

    /*//////////////////////////////////////////////////////////////
                            ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Withdraws token address or native if 0x0 is input
    /// @dev Withdraws native coin or tokens from contract if some gets stuck on the contract
    /// @param token The address of the token being withdrawn
    function recover(address token) external onlyOwner {
        if (token == 0x0000000000000000000000000000000000000000) {
           (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
           require(success, "Transfer failed.");
        } else {
            IERC20(token).transfer(msg.sender, IERC20(token).balanceOf(address(this)));
        }
    }

    /// @notice Changes antiBotsActive to `value`
    /// @dev Determines if anti-MEV checks are conducted on transfers
    /// @param value Determines the new value for antiBotsActive
    function setAntiBotsActive(bool value) external onlyOwner {
        antiBotsActive = value;
    }

    /// @notice Defines the new value for addLiquidityAmount (`_addLiquidityAmount`)
    /// @dev addLiquidityAmount = how many tokens to hold on contract before selling for liquidity
    /// @param _addLiquidityAmount Determines the new value for addLiquidityAmount
    function setLimit(uint256 _addLiquidityAmount) external onlyOwner {
        addLiquidityAmount = _addLiquidityAmount * 10**_decimals;
        emit NewLimit(_addLiquidityAmount);
    }

    /// @dev Defines the fees on transfer for buys and sells separately
    /// @param _buyLiquidityFee Determines the new value for buyLiquidityFee
    /// @param _sellLiquidityFee Determines the new value for sellLiquidityFee
    function setFees(
        uint256 _buyLiquidityFee,
        uint256 _sellLiquidityFee
        ) external onlyOwner {
        require(
            _buyLiquidityFee <= 5000
            && _sellLiquidityFee <= 5000
            , "Fees cannot be more than 5 percent");
        buyLiquidityFee = _buyLiquidityFee;
        sellLiquidityFee = _sellLiquidityFee;
        emit NewFees(_buyLiquidityFee, _sellLiquidityFee);
    }

    /// @notice Defines if an address (`addy`) is exempt from fees on transfer
    /// @param addy Determines the address to be excluded from fees on transfer
    /// @param status Determines if `addy` is excluded from fees on transfer
    function setExcludedFees(address addy, bool status) public onlyOwner {
        _excludedFees[addy] = status;
        emit SetExcludedFees(addy, status);
    }

    /// @notice Defines if an address (`addy`) is exempt from anti-MEV checks
    /// @param addy Determines the address to be excluded from anti-MEV checks
    /// @param status Determines if `addy` is excluded from anti-MEV checks
    function setExcludedAntiMev(address addy, bool status) public onlyOwner {
        _excludedAntiMev[addy] = status;
    }

    /// @notice Defines if `addy` is a DEX trading pair for the EMPIRE token
    /// @dev Specifies the pair address contract
    /// @param addy Determines the address of the market maker pair
    /// @param status Determines if `addy` is a market maker pair
    function setAutomatedMarketMakerPair(address addy, bool status) public onlyOwner {
        automatedMarketMakerPairs[addy] = status;
    }


    /// @notice Changes the tradingActive to `status`
    /// @dev tradingActive determines if trading on a DEX is enabled 
    /// @param status Determines the new status for tradingActive
    function setTradingActive(bool status) external onlyOwner {
        tradingActive = status;
        emit SetTradingActive(status);
    }

    /// @notice Changes the setBlockCooldown variable to `value`
    /// @dev Used to determine anti-MEV logic, setting how many blocks can elapse between transfers
    /// @param value Determines the new value for setBlockCooldown
    function setBlockCooldown(uint value) external onlyOwner {
        blockCooldownAmount = value;
    }

    /// @notice Changes the router variable to `_router`
    /// @dev Used for changing which router is integrated into the auto-liquidity feature
    /// @param _router Determines the address of the new router
    function changeRouter(address _router) external onlyOwner {
        router = IEmpireRouter(_router);
    }

    /*//////////////////////////////////////////////////////////////
                          BRIDGING FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // BRIDGE OPERATOR ONLY REQUIRES 2BA - TWO BLOCKCHAIN AUTHENTICATION //

    /// @dev Receives `amount` EMPIRE from a cross chain transfer
    /// @param account The address that is receiving a cross chain transfer
    /// @param amount The amount of EMPIRE tokens being received cross chain
    function unlock(address account, uint256 amount) external onlyOperator {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    /// @notice Called by bridge when user has calls function lock() on LockBurnBridge
    /// @dev Initiates cross chain transfer of `amount` EMPIRE to another chain
    /// @param account The address that is doing a cross chain transfer
    /// @param amount The amount of EMPIRE tokens being transferred cross chain
    function lock(address account, uint256 amount) external onlyOperator {
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

}