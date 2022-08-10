/**
 *Submitted for verification at Etherscan.io on 2022-08-10
*/

/*
Mini-Stars $STARS

Website: https://ministars.club
Telegram: https://t.me/ministarsportal
Twitter: https://twitter.com/ministarseth
Discord: https://discord.gg/ministars

    ________________________________________________________________________________
    ______________________________________________________________g ________________
    ____________________________________________________________a$$r________________
    __________________________________________________________,$$$$r________________
    ________________________________________________________,$$$$$$r________________
    [email protected]`________________
    ______________ @________________________________________|[email protected]`________________
    ______________ [email protected]__][email protected]*_________________
    ______________ $$$ _______________________________g$$[__][email protected]__ ________________
    _______________$$$&,____________________________,[email protected]__]@F___;_________________
    _______________$$$$&w____,._____________________]$$$$[__'___,&&_________________
    [email protected];___________________]$$$$H____,$$$$_________________
    [email protected][email protected]_.`_________,,____][email protected][email protected]_________________
    _______________$$$$$$$$$$$$$$[_]$N,_____g$$&[email protected]_________________
    [email protected]_]$$$$__]$$$$$&[email protected]_________________
    _______________$$$["[email protected]_]&&@@__|$$$$$$$w_]$$$$U__j$$$$$[_________________
    _______________$$$[_]$$$$F][email protected]_ |L____|[email protected]$$$$H__j$$$$$[_________________
    _______________$$$[__]$N__][email protected]_j$$$$__]$$$$$$$$$$$$$$[__j$$$$$[_________________
    _______________$$$[__,|[email protected]_j$$$$__]$$$[R$$$$$$$$$[__][email protected]_________________
    _______________RRRM!!!`[email protected]_j$$$$__]$$$h_*[email protected]__][email protected]_________________
    ____________________... __"&$$_j$$$M,[email protected]___ RMMRRN_________________
    ________________,$$$$$$[[email protected];_]T_jM*!'_,,[email protected]_____BN*_____....____________________
    ________________$$$NRRRh_$$&w '|r.,@@@@@%&&gr_______,[email protected]_________________
    [email protected]__';___7&$$Wg|]@@M*%@@%gWgy/`___)$$$$$$$$$$[_________________
    ________________$$$&w,'!;:.|[email protected]$H%@@  %@@@$$MR&[email protected]__&$$$N____"""_________________
    ________________J$$$$$$W___][email protected]:"]@%@@@@@K$$r_ [email protected]___ ___________________
    __________________T&[email protected]__]$$m|,#@[email protected]@%[email protected][email protected]$$N _&$$$$$&@g,   ________________
    _______________,gg __]$$$__][email protected]''#@@ _]@@@$$H $&,___&[email protected] ________________
    _______________]$$&w;g$$$________"_______*T&U_][email protected]   __T&[email protected] _______________
    ________________]$$$$$$$C________________________`,,,; _ ^7&[email protected]_______________
    __________________?TMMF___________________________]$$$N,[email protected]_______________
    [email protected]@@$$$$$H_______________
    ____________________________________________________J$$$$$$$$$$M________________
    ______________________________________________________"TMRRRM*__________________
    ________________________________________________________________________________
    ________________________________________________________________________________

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;


library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * C U ON THE MOON
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IDEXPair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IAntiSnipe {
  function setTokenOwner(address owner, address pair) external;

  function onPreTransferCheck(
    address from,
    address to,
    uint256 amount
  ) external returns (bool checked);
}

contract MiniStars is IERC20, Ownable {
    using Address for address;
    
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;

    string constant _name = "Mini-Stars";
    string constant _symbol = "STARS";
    uint8 constant _decimals = 9;

    uint256 constant _totalSupply = 1_000_000_000 * (10 ** _decimals);

    mapping (address => uint256) _balances;
    mapping (address => mapping (address => uint256)) _allowances;

    mapping (address => bool) isFeeExempt;
    mapping (address => bool) protectedWallet;

    uint256 NBAFee = 10;
    uint256 marketingFee = 30;
    uint256 stakingFee = 30;
    uint256 NBASellFee = 10;
    uint256 marketingSellFee = 85;
    uint256 stakingSellFee = 75;
    uint256 totalFee = 70;
    uint256 totalSellFee = 170;

    uint256 constant feeDenominator = 1000;

    address public NBAReceiver;
    address public marketingReceiver;
    address public stakingReceiver;

    IDEXRouter public router;
    
    address constant routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping (address => bool) liquidityPools;
    mapping (address => bool) liquidityProviders;

    address public pair;

    uint256 public launchedAt;
    uint256 public launchedTime;
 
    IAntiSnipe public antisnipe;
    bool public protectionEnabled = true;
    bool public protectionDisabled = false;

    bool public swapEnabled = true;
    uint256 public swapThreshold = _totalSupply / 400; //0.25%
    uint256 public swapMinimum = _totalSupply / 10000; //0.01%
    bool inSwap;
    modifier swapping() { inSwap = true; _; inSwap = false; }

    constructor (address _nba, address _marketing, address _staking) {
        NBAReceiver = _nba;
        marketingReceiver = _marketing;
        stakingReceiver = _staking;
      
        isFeeExempt[owner()] = true;

        uint256 contractBalance = _totalSupply / 10;
        uint256 ownerBalance = _totalSupply - contractBalance;

        _balances[owner()] = ownerBalance;
        emit Transfer(address(0), owner(), ownerBalance);
        _balances[address(this)] = contractBalance;
        emit Transfer(address(0), address(this), contractBalance);
    }

    receive() external payable { }

    function totalSupply() external pure override returns (uint256) { return _totalSupply; }
    function decimals() external pure returns (uint8) { return _decimals; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function name() external pure returns (string memory) { return _name; }
    function getOwner() external view returns (address) { return owner(); }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 currentAllowance = _allowances[msg.sender][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, type(uint256).max);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if(_allowances[sender][msg.sender] != type(uint256).max){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }

        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Insufficient balance");
        require(amount > 0, "Zero amount transferred");

        if(inSwap){ return _basicTransfer(sender, recipient, amount); }

        if(!launched()){ require(liquidityProviders[sender] || liquidityProviders[recipient], "Contract not launched yet."); }

        _balances[sender] -= amount;

        uint256 amountReceived = shouldTakeFee(sender) && shouldTakeFee(recipient) ? takeFee(sender, recipient, amount) : amount;
        
        if(shouldSwapBack(sender, recipient)){ if (amount > 0) swapBack(amount); }
        
        _balances[recipient] += amountReceived;
            
        if(launched() && protectionEnabled)
            antisnipe.onPreTransferCheck(sender, recipient, amount);

        require(!isProtectedWallet(sender), "Wallet protection enabled, please contact support");

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function shouldTakeFee(address sender) internal view returns (bool) {
        return !isFeeExempt[sender];
    }

    function getTotalFee(bool selling) public view returns (uint256) {
        if (selling) return totalSellFee;
        return totalFee;
    }

    function takeFee(address sender, address recipient, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * getTotalFee(liquidityPools[recipient])) / feeDenominator;
        
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);

        if(liquidityPools[sender] && block.number <= launchedAt + 2){ protectedWallet[recipient] = true; }

        return amount - feeAmount;
    }

    function shouldSwapBack(address sender, address recipient) internal view returns (bool) {
        return !liquidityPools[sender]
        && !isFeeExempt[sender]
        && !inSwap
        && swapEnabled
        && liquidityPools[recipient]
        && _balances[address(this)] >= swapMinimum && 
        (totalFee > 0 || totalSellFee > 0);
    }

    function swapBack(uint256 amount) internal swapping {
        uint256 amountToSwap = amount < swapThreshold ? amount : swapThreshold;
        if (_balances[address(this)] < amountToSwap) amountToSwap = _balances[address(this)];

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        
        //Guaranteed swap desired to prevent trade blockages
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 contractBalance = address(this).balance;
        uint256 totalETHFee = totalFee + totalSellFee;

        uint256 amountNBA = (contractBalance * (NBAFee + NBASellFee)) / totalETHFee;
        uint256 amountStaking = (contractBalance * (stakingFee + stakingSellFee)) / totalETHFee;
        uint256 amountMarketing = contractBalance - (amountNBA + amountStaking);
        
        if (amountNBA > 0) {
            (bool sentNBA, ) = NBAReceiver.call{value: amountNBA}("");
            require(sentNBA, "Failed to transfer funds to NBA wallet");
        }
        if (amountStaking > 0) {
            (bool sentStaking, ) = stakingReceiver.call{value: amountStaking}("");
            require(sentStaking, "Failed to transfer funds to staking wallet");
        }
        if (amountMarketing > 0) {
            (bool sentMarketing, ) = marketingReceiver.call{value: amountMarketing}("");
            require(sentMarketing, "Failed to transfer funds to marketing wallet");
        }
    }

    function extractStuckETH() external onlyOwner {
        (bool extracted, ) = owner().call{value: address(this).balance}("");
        require(extracted, "Failed to transfer funds");
    }

    function launched() internal view returns (bool) {
        return launchedAt != 0;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return _totalSupply - (balanceOf(DEAD) + balanceOf(address(0)));
    }

    function getLiquidityBacking(uint256 accuracy) public view returns (uint256) {
        return (accuracy * balanceOf(pair)) / getCirculatingSupply();
    }

    function isOverLiquified(uint256 target, uint256 accuracy) public view returns (bool) {
        return getLiquidityBacking(accuracy) > target;
    }

    function transferOwnership(address newOwner) public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.transferOwnership(newOwner);
        isFeeExempt[newOwner] = true;
        liquidityProviders[newOwner] = true;
        _allowances[newOwner][routerAddress] = type(uint256).max;
    }

    function renounceOwnership() public virtual override onlyOwner {
        isFeeExempt[owner()] = false;
        liquidityProviders[owner()] = false;
        _allowances[owner()][routerAddress] = 0;
        super.renounceOwnership();
    }

    function setProtectionEnabled(bool _protect) external onlyOwner {
        if (_protect)
            require(!protectionDisabled, "Protection disabled");
        protectionEnabled = _protect;
        emit ProtectionToggle(_protect);
    }
    
    function setProtection(address _protection, bool _call) external onlyOwner {
        if (_protection != address(antisnipe)){
            require(!protectionDisabled, "Protection disabled");
            antisnipe = IAntiSnipe(_protection);
        }
        if (_call)
            antisnipe.setTokenOwner(address(this), pair);
        
        emit ProtectionSet(_protection);
    }
    
    function disableProtection() external onlyOwner {
        protectionEnabled = false;
        protectionDisabled = true;
        emit ProtectionDisabled();
    }

    function isProtectedWallet(address _wallet) public view returns(bool) {
        return protectedWallet[_wallet];
    }

    function removeProtectedWallet(address _wallet) external onlyOwner {
        if (isProtectedWallet(_wallet)) protectedWallet[_wallet] = false;
    }
    
    function setLiquidityProvider(address _provider) external onlyOwner {
        require(_provider != pair && _provider != routerAddress, "Can't alter trading contracts in this manner.");
        isFeeExempt[_provider] = true;
        liquidityProviders[_provider] = true;
        emit LiquidityProviderSet(_provider);
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        require(holder != address(0), "Invalid address");
        isFeeExempt[holder] = exempt;
        emit FeeExemptSet(holder, exempt);
    }

    function setBuyFees(uint256 _NBAFee, uint256 _marketingFee, uint256 _stakingFee) external onlyOwner {
        NBAFee = _NBAFee;
        marketingFee = _marketingFee;
        stakingFee = _stakingFee;
        totalFee = _NBAFee + _marketingFee + _stakingFee;
        require(totalFee * 100 / feeDenominator <= 15 , "Fees too high");
        emit FeesSet(totalFee, feeDenominator);
    }

    function setSellFees(uint256 _NBAFee, uint256 _marketingFee, uint256 _stakingFee) external onlyOwner {
        NBASellFee = _NBAFee;
        marketingSellFee = _marketingFee;
        stakingSellFee = _stakingFee;
        totalSellFee = _NBAFee + _marketingFee + _stakingFee;
        require(totalSellFee * 100 / feeDenominator <= 20, "Fees too high");
        emit FeesSet(totalSellFee, feeDenominator);
    }

    function setNBAReceiver(address _nba) external onlyOwner {
        NBAReceiver = _nba;
        emit UpdatedFeeReceiver(_nba);
    }

    function setMarketingReceiver(address _marketing) external onlyOwner {
        marketingReceiver = _marketing;
        emit UpdatedFeeReceiver(_marketing);
    }

    function setStakingReceiver(address _staking) external onlyOwner {
        stakingReceiver = _staking;
        emit UpdatedFeeReceiver(_staking);
    }

    function setSwapBackSettings(bool _enabled, uint256 _denominator, uint256 _denominatorMin) external onlyOwner {
        require(_denominator > 0 && _denominatorMin > 0, "Denominators must be greater than 0");
        swapEnabled = _enabled;
        swapMinimum = _totalSupply / _denominatorMin;
        swapThreshold = _totalSupply / _denominator;
        emit SwapSettingsSet(swapMinimum, swapThreshold, swapEnabled);
    }

    function addLiquidityPool(address _pool, bool _enabled) external onlyOwner {
        require(_pool != address(0), "Invalid address");
        liquidityPools[_pool] = _enabled;
        emit LiquidityPoolSet(_pool, _enabled);
    }

    function addLP() external payable onlyOwner() {
        require(!launched(), "Liquidity already added"); 
        require(msg.value > 0, "Insufficient funds");
        uint256 toLP = msg.value;

        router = IDEXRouter(routerAddress);
        pair = IDEXFactory(router.factory()).createPair(address(this),router.WETH());
        liquidityPools[pair] = true;

        liquidityProviders[address(this)] = true;
        isFeeExempt[address(this)] = true;
        _allowances[address(this)][routerAddress] = type(uint256).max;

        router.addLiquidityETH{value: toLP}(address(this),balanceOf(address(this)),0,0,msg.sender,block.timestamp);

        launchedAt = block.number;
        launchedTime = block.timestamp;
        emit TradingLaunched();
    }

	function airdrop(address[] calldata _addresses, uint256[] calldata _amount) external onlyOwner
    {
        require(_addresses.length == _amount.length, "Array lengths don't match");

        //This function may run out of gas intentionally to prevent partial airdrops
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(!liquidityPools[_addresses[i]] && _addresses[i] != address(0), "Can't airdrop the liquidity pool or address 0");
            _basicTransfer(msg.sender, _addresses[i], _amount[i] * (10 ** _decimals));
        }

        emit AirdropSent(msg.sender);
    }

    event AutoLiquify(uint256 amount, uint256 amountToken);
    event ProtectionSet(address indexed protection);
    event ProtectionDisabled();
    event LiquidityProviderSet(address indexed provider);
    event TradingLaunched();
    event FeeExemptSet(address indexed wallet, bool isExempt);
    event FeesSet(uint256 totalFees, uint256 denominator);
    event UpdatedFeeReceiver(address indexed wallet);
    event SwapSettingsSet(uint256 minimum, uint256 maximum, bool enabled);
    event LiquidityPoolSet(address indexed pool, bool enabled);
    event AirdropSent(address indexed from);
    event ProtectionToggle(bool isEnabled);
}