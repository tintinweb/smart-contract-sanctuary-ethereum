/**
 *Submitted for verification at Etherscan.io on 2023-01-25
*/

/*

TG : https://t.me/Z3_Portal

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface InterfaceLP {
    function sync() external;
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint8 _tokenDecimals
    ) {
        _name = _tokenName;
        _symbol = _tokenSymbol;
        _decimals = _tokenDecimals;
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
}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
}

interface IDEXFactory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TokenHandler is Ownable {
    function sendTokenToOwner(address token) external onlyOwner {
        if(IERC20(token).balanceOf(address(this)) > 0){
            IERC20(token).transfer(owner(), IERC20(token).balanceOf(address(this)));
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract ZCubed is ERC20Detailed, Ownable {

    bool public tradingActive = false;
    bool public swapEnabled = true;

    uint256 public rewardYield = 315920639267394;
    uint256 public rewardYieldDenominator = 100000000000000000;

    uint256 public rebaseFrequency = 1 days / 2; // 43200 seconds - every 12 hours
    uint256 public nextRebase;
    bool public autoRebase = true;

    uint256 public timeBetweenRebaseReduction = 90 days; // 90 days
    uint256 public rebaseReductionAmount = 3; // 30% reduction
    uint256 public lastReduction;

    uint256 public maxTxnAmount;
    uint256 public maxWallet;

    mapping(address => bool) _isFeeExempt;
    address[] public _makerPairs;
    mapping (address => bool) public automatedMarketMakerPairs;

    uint256 public constant MAX_FEE_RATE = 4;
    uint256 public constant MAX_REBASE_FREQUENCY = 43200;
    uint256 public constant MIN_REBASE_FREQUENCY = 43200;
    uint256 private constant DECIMALS = 18;
    uint256 private constant MAX_UINT256 = type(uint256).max;
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 2_100_000 * 10**DECIMALS;
    uint256 private constant TOTAL_GONS = type(uint256).max - (type(uint256).max % INITIAL_FRAGMENTS_SUPPLY);
    uint256 private constant MAX_SUPPLY = 21_000_000 * 10**DECIMALS;

    event LogRebase(uint256 indexed epoch, uint256 totalSupply);
    event SetAutomatedMarketMakerPair(address indexed pair, bool indexed value);
    event RemovedLimits();

    address DEAD = 0x000000000000000000000000000000000000dEaD;
    address ZERO = 0x0000000000000000000000000000000000000000;

    address public marketingAddress;
    address public treasuryAddress;
    address public PAIREDTOKEN;

    IDEXRouter public immutable router;
    address public pair;

    TokenHandler public tokenHandler;

     // Anti-bot and anti-whale mappings and variables
    mapping(address => uint256) private _holderLastTransferBlock; // to hold last Transfers temporarily during launch
    bool public transferDelayEnabled = true;

    uint256 public liquidityFee = 1;
    uint256 public marketingFee = 2;
    uint256 public treasuryFee = 1;
    uint256 public totalFee = liquidityFee + marketingFee + treasuryFee;
    uint256 public feeDenominator = 100;
    
    bool public limitsInEffect = true;

    bool inSwap;

    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }
    
    uint256 private _totalSupply;
    uint256 private _gonsPerFragment;
    uint256 private gonSwapThreshold = (TOTAL_GONS / 100000 * 25);

    mapping(address => uint256) private _gonBalances;
    mapping(address => mapping(address => uint256)) private _allowedFragments;

    modifier validRecipient(address to) {
        require(to != address(0x0));
        _;
    }

    constructor() ERC20Detailed(block.chainid==1 ? "Z-Cubed" : "ZTEST", block.chainid==1 ? "Z3" : "ZTEST", 18) {
        address dexAddress;
        address pairedTokenAddress;
        if(block.chainid == 1){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            pairedTokenAddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        } else if(block.chainid == 5){
            dexAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
            pairedTokenAddress = 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557;
        } else if (block.chainid == 97){
            dexAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
            pairedTokenAddress  = 0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7;
        } else {
            revert("Chain not configured");
        }

        marketingAddress = address(0x77B2aE7647afAa8Eef08572CF7b77803C5aE95d7);
        treasuryAddress = address(0x4f013300A0DcE6193388Cd057108eecB9e1054aC);

        nextRebase = block.timestamp + rebaseFrequency;
        
        PAIREDTOKEN = pairedTokenAddress;

        router = IDEXRouter(dexAddress);

        tokenHandler = new TokenHandler();

        _allowedFragments[address(this)][address(router)] = ~uint256(0);
        _allowedFragments[address(msg.sender)][address(router)] = ~uint256(0);
        _allowedFragments[address(this)][address(this)] = ~uint256(0);

        _totalSupply = INITIAL_FRAGMENTS_SUPPLY;
        _gonBalances[msg.sender] = TOTAL_GONS / 100 * 95;
        _gonBalances[treasuryAddress] += TOTAL_GONS - _gonBalances[msg.sender];
        _gonsPerFragment = TOTAL_GONS/(_totalSupply);

        maxTxnAmount = _totalSupply * 5 / 1000; // 0.5%
        maxWallet = _totalSupply * 1 / 100;
        
        _isFeeExempt[address(this)] = true;
        _isFeeExempt[address(msg.sender)] = true;
        _isFeeExempt[address(dexAddress)] = true;
        _isFeeExempt[address(0xdead)] = true;

        emit Transfer(address(0x0), msg.sender, balanceOf(msg.sender));
        emit Transfer(address(0x0), treasuryAddress, balanceOf(treasuryAddress));  
    }

    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }

    function allowance(address owner_, address spender) external view override returns (uint256){
        return _allowedFragments[owner_][spender];
    }

    function balanceOf(address who) public view override returns (uint256) {
        return _gonBalances[who]/(_gonsPerFragment);
    }

    function checkFeeExempt(address _addr) external view returns (bool) {
        return _isFeeExempt[_addr];
    }

    function checkSwapThreshold() external view returns (uint256) {
        return gonSwapThreshold/(_gonsPerFragment);
    }

    function shouldRebase() public view returns (bool) {
        return nextRebase <= block.timestamp;
    }

    function shouldTakeFee(address from, address to) internal view returns (bool) {
        if(_isFeeExempt[from] || _isFeeExempt[to]){
            return false;
        } else {
            return (automatedMarketMakerPairs[from] || automatedMarketMakerPairs[to]);
        }
    }

    function shouldSwapBack() internal view returns (bool) {
        return
        !inSwap &&
        swapEnabled &&
        totalFee > 0 &&
        _gonBalances[address(this)] >= gonSwapThreshold;
    }

    function manualSync() public {
        for(uint i = 0; i < _makerPairs.length; i++){
            try InterfaceLP(_makerPairs[i]).sync(){} catch {}
        }
    }

    function transfer(address to, uint256 value) external override validRecipient(to) returns (bool){
        _transferFrom(msg.sender, to, value);
        return true;
    }

    // remove limits after token is stable
    function removeLimits() external onlyOwner {
        limitsInEffect = false;
        emit RemovedLimits();
    }

    // alter the paired token so bots can't prep for new path (hypothetically)
    function alterToken(address newToken) external onlyOwner {
        require(newToken != address(0), "Zero address");
        require(!tradingActive, "trading already active");
        pair = IDEXFactory(router.factory()).createPair(address(this), newToken);
        _allowedFragments[address(this)][pair] = ~uint256(0);
        setAutomatedMarketMakerPair(pair, true);
        PAIREDTOKEN = newToken;
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {

        if(!tradingActive){
            require(_isFeeExempt[sender] || _isFeeExempt[recipient], "Trading is paused");
        }

        if(limitsInEffect){
            if (!_isFeeExempt[sender] && !_isFeeExempt[recipient]){

                // at launch if the transfer delay is enabled, ensure the block timestamps for purchasers is set -- during launch.  
                if (transferDelayEnabled){
                    if (recipient != address(router) && !automatedMarketMakerPairs[recipient]){
                        require(_holderLastTransferBlock[tx.origin] + 2 < block.number && _holderLastTransferBlock[recipient] + 2 < block.number, "_transfer:: Transfer Delay enabled.  Try again later.");
                        _holderLastTransferBlock[tx.origin] = block.number;
                        _holderLastTransferBlock[recipient] = block.number;
                    }
                }
                //when buy
                if (automatedMarketMakerPairs[sender]) {
                    require(amount <= maxTxnAmount, "Buy transfer amount exceeds the max buy.");
                }
                if (!automatedMarketMakerPairs[recipient]){
                    require(balanceOf(recipient) + amount <= maxWallet, "Max Wallet Exceeded");
                }
            }
        }

        if(!_isFeeExempt[sender] && !_isFeeExempt[recipient] && shouldSwapBack() && !automatedMarketMakerPairs[sender]){
            inSwap = true;
            swapBack();
            inSwap = false;
        }

        if(autoRebase && !automatedMarketMakerPairs[sender] && !inSwap && shouldRebase() && !_isFeeExempt[recipient] && !_isFeeExempt[sender]){
            rebase();
        }

        uint256 gonAmount = amount*(_gonsPerFragment);

        _gonBalances[sender] = _gonBalances[sender]-(gonAmount);

        uint256 gonAmountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, gonAmount) : gonAmount;
        _gonBalances[recipient] = _gonBalances[recipient]+(gonAmountReceived);

        emit Transfer(sender, recipient, gonAmountReceived/(_gonsPerFragment));

        return true;
    }

    function transferFrom(address from, address to,  uint256 value) external override validRecipient(to) returns (bool) {
        if (_allowedFragments[from][msg.sender] != MAX_UINT256) {
            require(_allowedFragments[from][msg.sender] >= value,"Insufficient Allowance");
            _allowedFragments[from][msg.sender] = _allowedFragments[from][msg.sender]-(value);
        }
        _transferFrom(from, to, value);
        return true;
    }

    

    function swapBack() public {

        uint256 contractBalance = balanceOf(address(this));

        if(contractBalance > gonSwapThreshold/(_gonsPerFragment) * 20){
            contractBalance = gonSwapThreshold/(_gonsPerFragment) * 20;
        }

        uint256 tokensForLiquidity = contractBalance * liquidityFee / totalFee;

        if(tokensForLiquidity > 0 && contractBalance >= tokensForLiquidity){
            _transferFrom(address(this), pair, tokensForLiquidity);
            manualSync();
            contractBalance -= tokensForLiquidity;
            tokensForLiquidity = 0;
        }
        
        swapTokensForPAIREDTOKEN(contractBalance);

        tokenHandler.sendTokenToOwner(address(PAIREDTOKEN));
        
        uint256 pairedTokenBalance = IERC20(PAIREDTOKEN).balanceOf(address(this));

        uint256 pairedTokenForTreasury = pairedTokenBalance * treasuryFee / (treasuryFee + marketingFee);

        if(pairedTokenForTreasury > 0){
            IERC20(PAIREDTOKEN).transfer(treasuryAddress, pairedTokenForTreasury);
        }

        if(IERC20(PAIREDTOKEN).balanceOf(address(this)) > 0){
            IERC20(PAIREDTOKEN).transfer(marketingAddress, IERC20(PAIREDTOKEN).balanceOf(address(this)));
        }
    }

    function swapTokensForPAIREDTOKEN(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(PAIREDTOKEN);

        // make the swap
        router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount
            path,
            address(tokenHandler),
            block.timestamp
        );
    }

    function takeFee(address sender, uint256 gonAmount) internal returns (uint256){

        uint256 feeAmount = gonAmount*(totalFee)/(feeDenominator);

        _gonBalances[address(this)] = _gonBalances[address(this)]+(feeAmount);
        emit Transfer(sender, address(this), feeAmount/(_gonsPerFragment));

        return gonAmount-(feeAmount);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool){
        uint256 oldValue = _allowedFragments[msg.sender][spender];
        if (subtractedValue >= oldValue) {
            _allowedFragments[msg.sender][spender] = 0;
        } else {
            _allowedFragments[msg.sender][spender] = oldValue-(
                subtractedValue
            );
        }
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool){
        _allowedFragments[msg.sender][spender] = _allowedFragments[msg.sender][
        spender
        ]+(addedValue);
        emit Approval(
            msg.sender,
            spender,
            _allowedFragments[msg.sender][spender]
        );
        return true;
    }

    function approve(address spender, uint256 value) public override returns (bool){
        _allowedFragments[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function getSupplyDeltaOnNextRebase() external view returns (uint256){
        return (_totalSupply*rewardYield)/rewardYieldDenominator;
    }

    function rebase() private returns (uint256) {
        uint256 epoch = block.timestamp;

        if(lastReduction + timeBetweenRebaseReduction <= block.timestamp){
            rewardYield -= rewardYield * rebaseReductionAmount / 10;
            lastReduction = block.timestamp;
        }

        uint256 supplyDelta = (_totalSupply*rewardYield)/rewardYieldDenominator;
        
        nextRebase = nextRebase + rebaseFrequency;

        if (supplyDelta == 0) {
            emit LogRebase(epoch, _totalSupply);
            return _totalSupply;
        }

        _totalSupply = _totalSupply+supplyDelta;

        if (_totalSupply > MAX_SUPPLY) {
            _totalSupply = MAX_SUPPLY;
        }

        _gonsPerFragment = TOTAL_GONS/(_totalSupply);

        manualSync();

        emit LogRebase(epoch, _totalSupply);
        return _totalSupply;
    }

    function manualRebase() external {
        require(!inSwap, "Try again");
        require(shouldRebase(), "Not in time");
        rebase();
    }
    
    function setAutomatedMarketMakerPair(address _pair, bool _value) public onlyOwner {
        require(automatedMarketMakerPairs[_pair] != _value, "Value already set");

        automatedMarketMakerPairs[_pair] = _value;

        if(_value){
            _makerPairs.push(_pair);
        } else {
            require(_makerPairs.length > 1, "Required 1 pair");
            for (uint256 i = 0; i < _makerPairs.length; i++) {
                if (_makerPairs[i] == _pair) {
                    _makerPairs[i] = _makerPairs[_makerPairs.length - 1];
                    _makerPairs.pop();
                    break;
                }
            }
        }

        emit SetAutomatedMarketMakerPair(_pair, _value);
    }

    function enableTrading() external onlyOwner {
        require(!tradingActive, "Trading already active");
        tradingActive = true;
        nextRebase = block.timestamp + rebaseFrequency;
        lastReduction = block.timestamp;
    }

    // disable Transfer delay - cannot be reenabled
    function disableTransferDelay() external onlyOwner {
        transferDelayEnabled = false;
    }

    function setFeeExempt(address _addr, bool _value) external onlyOwner {
        require(_isFeeExempt[_addr] != _value, "Not changed");
        _isFeeExempt[_addr] = _value;
    }

    function setFeeReceivers(address _marketingReceiver, address _treasuryReceiver) external onlyOwner {
        require(_marketingReceiver != address(0) && _treasuryReceiver != address(0), "zero address");
        treasuryAddress = _treasuryReceiver;
        marketingAddress = _marketingReceiver;
    }

    function setFees(uint256 _liquidityFee, uint256 _marketingFee, uint256 _treasuryFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        marketingFee = _marketingFee;
        treasuryFee = _treasuryFee;
        totalFee = liquidityFee + marketingFee + treasuryFee;
        require(totalFee <= MAX_FEE_RATE, "Fees set too high");
    }

    function rescueToken(address tokenAddress, uint256 tokens, address destination) external onlyOwner returns (bool success){
        require(tokenAddress != address(this), "Cannot take native tokens");
        return ERC20Detailed(tokenAddress).transfer(destination, tokens);
    }

    function setNextRebase(uint256 _nextRebase) external onlyOwner {
        require(_nextRebase > block.timestamp, "Must set rebase in the future");
        nextRebase = _nextRebase;
    }
}