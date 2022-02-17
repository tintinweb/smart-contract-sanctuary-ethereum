/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {size := extcodesize(account)}
        return size > 0;
    }
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }
    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

interface IST20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeST20 {
    using Address for address;
    function safeTransfer(IST20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
    function safeTransferFrom(IST20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
    function safeApprove(IST20 token, address spender, uint256 value) internal {
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0), "SafeST20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
    function safeIncreaseAllowance(IST20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }
    function safeDecreaseAllowance(IST20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeST20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }
    function _callOptionalReturn(IST20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(data, "SafeST20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeST20: ERC20 operation did not succeed");
        }
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IUniRouterV1 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidity(address tokenA, address tokenB, uint amountADesired, uint amountBDesired, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(address tokenA, address tokenB, uint liquidity, uint amountAMin, uint amountBMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline) external payable returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IUniRouterV2 is IUniRouterV1 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(address token, uint liquidity, uint amountTokenMin, uint amountETHMin, address to, uint deadline, bool approveMax, uint8 v, bytes32 r, bytes32 s) external returns (uint amountETH);
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(uint amountOutMin, address[] calldata path, address to, uint deadline) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
}

interface IFactory {
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

contract PLUXEL is IST20, Ownable {
    using SafeMath for uint256;
    using SafeST20 for IST20;
    struct FeeInfo {
        uint256 reflectionFee;
        uint256 liquidityFee;
        uint256 teamFee;
        uint256 marketingFee;
        uint256 burnFee;
    }
    struct FeeValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rFee;
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tLiquidityFee;
        uint256 tTeamFee;
        uint256 tMarketingFee;
        uint256 tBurnFee;
    }
    struct tFeeValues {
        uint256 tTransferAmount;
        uint256 tReflectionFee;
        uint256 tLiquidityFee;
        uint256 tTeamFee;
        uint256 tMarketingFee;
        uint256 tBurnFee;
    }
    struct UserInfo {
        uint256 rOwned;
        uint256 tOwned;
        bool excludedFromFee;
        bool excludedFromReward;
        bool blacklisted;
    }

    address public constant burnAddress = 0x000000000000000000000000000000000000dEaD;      
    uint256 private constant PERCENT_FACTOR = 100; //100%
    
    IST20 private wBNB;
    string public name; 
    string public symbol;
    uint8 public immutable decimals;
    uint256 private rTotal;
    uint256 private tTotal;   
    mapping(address => UserInfo) private userMap;
    address[] private excluded;
    mapping (address => mapping (address => uint256)) private allowances;
    uint256 private nonce;
    uint256 private minRemainingTokens;

    uint256 public maxFee = 30; //Maximum fees
    uint256 private tFeeTotal; //Total collected fees
    FeeInfo public buyFees; //Total collected buy fees
    FeeInfo public p2pFees; //Total collected wallet transfer fees
    FeeInfo public sellFees; //Total collected sell fees
    FeeInfo private emptyFees; //NIL fees
    address public teamFeeAddress; //Team fees address
    address public marketingFeeAddress; //Marketing fees address
    uint256 private accumulatedLiquidityFee;
    uint256 private accumulatedTeamFee;
    uint256 private accumulatedMarketingFee;

    IUniRouterV2 public router;
    IST20 public routerPair;

    bool private inSwapAndLiquify;
    bool public swapAndLiquifyEnabled;
    uint256 private swapTokensAtHigh;
    uint256 private swapTokensAtLow;

    event SwapAndLiquifyEnabledUpdated(bool _enabled);
    event Liquified(uint256 _tokensSwapped, uint256 _bnbReceived, uint256 _tokensIntoLiquidity);
    event SwappedForBNB(uint256 _tokensSwapped, uint256 _bnbReceived);
    event ChangeFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee);

    constructor() {
        IUniRouterV2 routerAddress = IUniRouterV2(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        address initialOwner = 0xE69Ac38Cd6DA0EA9a540B47399C430131216Ced7;
        marketingFeeAddress = 0x714674009B8e0F873DBa410c29d936517cd7ce2a;
        teamFeeAddress = 0x714674009B8e0F873DBa410c29d936517cd7ce2a;        
        name = "PLUXEL";
        symbol = "PLXL";
        decimals = 18;
        tTotal = 1000000000000 * 10**18;    
        minRemainingTokens = 1 * 10**18; 
        swapTokensAtLow = 1000000000 * 10**18; 
        swapTokensAtHigh = 3000000000 * 10**18;         

        router = routerAddress;
        wBNB = IST20(router.WETH());
        rTotal = (type(uint256).max - (type(uint256).max % totalSupply()));
        swapAndLiquifyEnabled = true;
        excludeFromFee(address(this));

        routerPair = IST20(IFactory(router.factory()).createPair(address(this), address(wBNB)));
      
        UserInfo storage user = userMap[initialOwner];
        user.rOwned = rTotal;
        user.excludedFromFee = true;
        emit Transfer(address(0), initialOwner, tTotal);

        excludeFromReward(burnAddress);

        buyFees = FeeInfo({
            reflectionFee: 4,
            liquidityFee: 3,
            teamFee: 0,
            marketingFee: 1,
            burnFee: 2
        });
        sellFees = FeeInfo({
            reflectionFee: 4,
            liquidityFee: 3,
            teamFee: 0,
            marketingFee: 1,
            burnFee: 2
        });
        p2pFees = FeeInfo({
            reflectionFee: 1,
            liquidityFee: 1,
            teamFee: 0,
            marketingFee: 0,
            burnFee: 0
        });
    }   

    receive() external payable {}
    function totalSupply() public view override returns (uint256) {
        return tTotal;
    }
    function totalFees() public view returns (uint256) {
        return tFeeTotal;
    }
    function allowance(address _owner, address _spender) public view override returns (uint256) {
        return allowances[_owner][_spender];
    }
    function approve(address _spender, uint256 _amount) public override returns (bool) {
        _approve(msg.sender, _spender, _amount);
        return true;
    }
    function increaseAllowance(address _spender, uint256 _addedValue) public virtual returns (bool) {
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].add(_addedValue));
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public virtual returns (bool) {
        require(allowances[msg.sender][_spender] >= _subtractedValue, "BEP20: decreased allowance below zero");
        _approve(msg.sender, _spender, allowances[msg.sender][_spender].sub(_subtractedValue));
        return true;
    }    
    function _approve(address _owner, address _spender, uint256 _amount) private {
        preventBlacklisted(_owner, "Owner address is blacklisted");
        preventBlacklisted(_spender, "Spender address is blacklisted");
        require(_owner != address(0), "approve from the zero address");
        require(_spender != address(0), "approve to the zero address");
        allowances[_owner][_spender] = _amount;
        emit Approval(_owner, _spender, _amount);
    } 
    function preventBlacklisted(address _account, string memory _errorMsg) private view {
        UserInfo storage user = userMap[_account];
        require(!user.blacklisted, _errorMsg);
    }
    function getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = rTotal;
        uint256 tSupply = tTotal;
        for (uint256 n = 0; n < excluded.length; n++) {
            UserInfo storage user = userMap[excluded[n]];
            if (user.rOwned > rSupply
                || user.tOwned > tSupply) {
                return (rTotal, tTotal);
            }          
            rSupply = rSupply.sub(user.rOwned);
            tSupply = tSupply.sub(user.tOwned);
        }
        if (rSupply < rTotal.div(tTotal)) {
            return (rTotal, tTotal);
        }
        return (rSupply, tSupply);
    }
    function setMinTokenAmount(uint256 _tokens) external onlyOwner {
        minRemainingTokens = _tokens;
    } 
    function setSwapTokensAtAmount(uint256 _low, uint256 _high) external onlyOwner {
        require(_high > _low, "High must be more than low");
        swapTokensAtLow = _low;
        swapTokensAtHigh = _high;
    }
    function setReflectionFee(int8 _feeType, uint256 _fee) external onlyOwner {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, _fee, fees.liquidityFee, fees.teamFee, fees.marketingFee, fees.burnFee);
    }
    function setLiquidityFee(int8 _feeType, uint256 _fee) external onlyOwner {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, _fee, fees.teamFee, fees.marketingFee, fees.burnFee);
    }
    function setTeamFee(int8 _feeType, uint256 _fee) external onlyOwner {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, _fee, fees.marketingFee, fees.burnFee);
    }
    function setMarketingFee(int8 _feeType, uint256 _fee) external onlyOwner {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, fees.teamFee, _fee, fees.burnFee);
    }
    function setBurnFee(int8 _feeType, uint256 _fee) external onlyOwner {
        FeeInfo memory fees = getFees(_feeType);
        setFees(_feeType, fees.reflectionFee, fees.liquidityFee, fees.teamFee, fees.marketingFee, _fee);
    }
    function setAllFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee) external onlyOwner {
        setFees(_feeType, _reflectionFee, _liquidityFee, _teamFee, _marketingFee, _burnFee);        
    }
    function setTeamFeeAddress(address _address) external onlyOwner {
        teamFeeAddress = _address;
    }
    function setMarketingFeeAddress(address _address) external onlyOwner {
        marketingFeeAddress = _address;
    }
    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }
    function excludeFromFee(address _account) public onlyOwner {
        UserInfo storage user = userMap[_account];
        user.excludedFromFee = true;
    }
    function includeInFee(address _account) public onlyOwner {        
        UserInfo storage user = userMap[_account];
        user.excludedFromFee = false;
    }
    function blacklistAddress(address _account) public onlyOwner {
        UserInfo storage user = userMap[_account];
        user.blacklisted = true;
    }
    function unBlacklistAddress(address _account) public onlyOwner {
        UserInfo storage user = userMap[_account];
        user.blacklisted = false;
    }   
    function excludeFromReward(address _account) public onlyOwner {
        UserInfo storage user = userMap[_account];
        require(!user.excludedFromReward, "Account is already excluded");
        if (user.rOwned > 0) {
            user.tOwned = tokenFromReflection(user.rOwned);
        }
        user.excludedFromReward = true;
        excluded.push(_account);
    }
    function includeInReward(address _account) external onlyOwner {
        UserInfo storage user = userMap[_account];
        require(user.excludedFromReward, "Account is already included");
        for (uint256 n = 0; n < excluded.length; n++) {
            if (excluded[n] == _account) {
                excluded[n] = excluded[excluded.length - 1];
                user.tOwned = 0;
                user.excludedFromReward = false;
                excluded.pop();
                break;
            }
        }
    }
    function isExcludedFromFee(address _account) public view returns (bool) {
        UserInfo storage user = userMap[_account];
        return user.excludedFromFee;
    }
    function isBlacklisted(address _account) public view returns (bool) {
        UserInfo storage user = userMap[_account];
        return user.blacklisted;
    }
    function balanceOf(address _account) public view override returns (uint256) {
        UserInfo storage user = userMap[_account];
        if (user.excludedFromReward) {
            return user.tOwned;
        }
        return tokenFromReflection(user.rOwned);
    }
    function isExcludedFromReward(address _account) public view returns (bool) {
        UserInfo storage user = userMap[_account];
        return user.excludedFromReward;
    }    
    function getSwapAmount() private returns (uint256) {
        uint256 pr = uint256(keccak256(abi.encodePacked(tx.origin, block.timestamp, nonce++)));
        return swapTokensAtLow.add(pr.mod(swapTokensAtHigh.sub(swapTokensAtLow)));
    }
    function manualProcessFees(uint256 _amount) external onlyOwner {
        processFees(_amount);
    }
    function processFees(uint256 _amount) private {
        uint256 accumulatedTotal = accumulatedLiquidityFee.add(accumulatedTeamFee).add(accumulatedMarketingFee);
        uint256 tokenForLiquidity = _amount.mul(accumulatedLiquidityFee).div(accumulatedTotal);
        uint256 tokenForMarketing = _amount.mul(accumulatedMarketingFee).div(accumulatedTotal);
        uint256 tokenForTeam = _amount.mul(accumulatedTeamFee).div(accumulatedTotal);
        uint256 liquidityHalf = tokenForLiquidity.div(2);
        uint256 liquidityHalfOther = tokenForLiquidity.sub(liquidityHalf);
        uint256 swapAmount = tokenForMarketing.add(tokenForMarketing).add(liquidityHalf);
        accumulatedLiquidityFee = accumulatedLiquidityFee.sub(tokenForLiquidity);
        accumulatedMarketingFee = accumulatedMarketingFee.sub(tokenForMarketing);
        accumulatedTeamFee = accumulatedTeamFee.sub(tokenForTeam);
        inSwapAndLiquify = true;
        uint256 initialBalance = address(this).balance;
        swapForBNB(swapAmount);
        uint256 gainedBalance = address(this).balance.sub(initialBalance);        
        uint256 bnbForMarketing = gainedBalance.mul(accumulatedMarketingFee).div(accumulatedTotal);
        payable(marketingFeeAddress).transfer(bnbForMarketing);
        uint256 bnbForTeam = gainedBalance.mul(accumulatedTeamFee).div(accumulatedTotal);
        payable(teamFeeAddress).transfer(bnbForTeam);
        uint256 remainingGainedBalance = address(this).balance.sub(initialBalance); 
        addLiquidity(liquidityHalfOther, remainingGainedBalance);
        inSwapAndLiquify = false;
    }
    function takeFees(address _sender, FeeValues memory _values) private { 
        takeFee(_sender, _values.tLiquidityFee, address(this));
        accumulatedLiquidityFee = accumulatedLiquidityFee.add(_values.tLiquidityFee);
        takeFee(_sender, _values.tTeamFee, address(this));
        accumulatedTeamFee = accumulatedTeamFee.add(_values.tTeamFee);
        takeFee(_sender, _values.tMarketingFee, address(this));
        accumulatedMarketingFee = accumulatedMarketingFee.add(_values.tMarketingFee);
        takeBurn(_sender, _values.tBurnFee);
    }
    function takeFee(address _sender, uint256 _tAmount, address _recipient) private {
        if (_recipient == address(0) || _tAmount == 0) {
            return;
        }
        uint256 rAmount = _tAmount.mul(getRate());
        UserInfo storage user = userMap[_recipient];
        user.rOwned = user.rOwned.add(rAmount);
        if (user.excludedFromReward) {
            user.tOwned = user.tOwned.add(_tAmount);
        }        
        emit Transfer(_sender, _recipient, _tAmount);
    }
    function takeBurn(address sender, uint256 _amount) private {
        if (_amount == 0) {
            return;
        }
        UserInfo storage user = userMap[burnAddress];
        user.tOwned = user.tOwned.add(_amount);
        emit Transfer(sender, burnAddress, _amount);
    }
    function calculateFee(uint256 _amount, uint256 _fee) private pure returns (uint256) {
        if (_fee == 0) {
            return 0;
        }
        return _amount.mul(_fee).div(PERCENT_FACTOR);
    }
    function checkFees(FeeInfo memory _info) private view {
        uint256 fees = _info.reflectionFee.add(_info.liquidityFee).add(_info.teamFee).add(_info.marketingFee).add(_info.burnFee);
        require(fees <= maxFee, "Fees exceeded max limitation");
    }
    function getFees(int8 _feeType) private view returns (FeeInfo memory) {
        if (_feeType < 0) {
            return sellFees;
        } else if (_feeType > 0) {
            return buyFees;
        }
        return p2pFees;
    }
    function setFees(int8 _feeType, uint256 _reflectionFee, uint256 _liquidityFee, uint256 _teamFee, uint256 _marketingFee, uint256 _burnFee) internal {
        if (_feeType == 1) {
            sellFees.reflectionFee  = _reflectionFee;
            sellFees.liquidityFee   = _liquidityFee;
            sellFees.teamFee        = _teamFee;
            sellFees.marketingFee   = _marketingFee;
            sellFees.burnFee        = _burnFee;
            checkFees(sellFees);         
        } else if (_feeType == 2) {
            buyFees.reflectionFee   = _reflectionFee;
            buyFees.liquidityFee    = _liquidityFee;
            buyFees.teamFee         = _teamFee;
            buyFees.marketingFee    = _marketingFee;
            buyFees.burnFee         = _burnFee;
            checkFees(buyFees);              
        } else {
            p2pFees.reflectionFee   = _reflectionFee;
            p2pFees.liquidityFee    = _liquidityFee;
            p2pFees.teamFee         = _teamFee;
            p2pFees.marketingFee    = _marketingFee;
            p2pFees.burnFee         = _burnFee;
            checkFees(p2pFees);   
        }
        emit ChangeFees(_feeType, _reflectionFee, _liquidityFee, _teamFee, _marketingFee, _burnFee);
    }
    function swapForBNB(uint256 _amount) private {       
        uint256 initialBalance = address(this).balance;
        swapTokensForBNB(_amount);
        uint256 newBalance = address(this).balance.sub(initialBalance);
        emit SwappedForBNB(_amount, newBalance);
    }
    function swapTokensForBNB(uint256 _amount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = address(wBNB);       
        _approve(address(this), address(router), _amount);
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 _tokenAmount, uint256 _bnbAmount) private {
        _approve(address(this), address(router), _tokenAmount);
        router.addLiquidityETH{value: _bnbAmount}(
            address(this),
            _tokenAmount,
            0,
            0,
            owner(),
            block.timestamp
        );
    }    
    function getValues(uint256 _tAmount, FeeInfo memory _fees) private view returns (FeeValues memory) {
        tFeeValues memory tValues = getTValues(_tAmount, _fees);
        uint256 tTransferFee = tValues.tLiquidityFee.add(tValues.tTeamFee).add(tValues.tMarketingFee).add(tValues.tBurnFee);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = getRValues(_tAmount, tValues.tReflectionFee, tTransferFee, getRate());
        return FeeValues(
        {
            rAmount: rAmount,
            rTransferAmount: rTransferAmount,
            rFee: rFee,    
            tTransferAmount: tValues.tTransferAmount,
            tReflectionFee: tValues.tReflectionFee,
            tLiquidityFee: tValues.tLiquidityFee,
            tTeamFee: tValues.tTeamFee,
            tMarketingFee: tValues.tMarketingFee,
            tBurnFee: tValues.tBurnFee
        });
    }
    function getTValues(uint256 _tAmount, FeeInfo memory _fees) private pure returns (tFeeValues memory) {
        tFeeValues memory tValues = tFeeValues(
        {
            tTransferAmount: 0,
            tReflectionFee: calculateFee(_tAmount, _fees.reflectionFee),
            tLiquidityFee: calculateFee(_tAmount, _fees.liquidityFee),
            tTeamFee: calculateFee(_tAmount, _fees.teamFee),
            tMarketingFee: calculateFee(_tAmount, _fees.marketingFee),
            tBurnFee: calculateFee(_tAmount, _fees.burnFee)
        });
        tValues.tTransferAmount = _tAmount.sub(tValues.tReflectionFee).sub(tValues.tLiquidityFee).sub(tValues.tTeamFee).sub(tValues.tMarketingFee).sub(tValues.tBurnFee);
        return tValues;
    }
    function getRValues(uint256 _tAmount, uint256 _tFee, uint256 _tTransferFee, uint256 _currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = _tAmount.mul(_currentRate);
        uint256 rFee = _tFee.mul(_currentRate);
        uint256 rTransferFee = _tTransferFee.mul(_currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTransferFee);
        return (rAmount, rTransferAmount, rFee);
    }
    function getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = getCurrentSupply();
        return rSupply.div(tSupply);
    }
    function tokenFromReflection(uint256 _rAmount) public view returns (uint256) {
        require(_rAmount <= rTotal, "Amount must be less than total reflections");
        uint256 currentRate = getRate();
        return _rAmount.div(currentRate);
    }

    function reflectFee(uint256 _rFee, uint256 _tFee) private {
        rTotal = rTotal.sub(_rFee);
        tFeeTotal = tFeeTotal.add(_tFee);
    }
    function getTransferAmount(uint256 _amount, address _from) private view returns (uint256) {
        uint256 transferAmount = _amount;
        if (_from != address(router)
            && _from != address(routerPair)
            && _from != address(this)) {
            uint256 maxTransferAmount = balanceOf(_from);
            maxTransferAmount = (maxTransferAmount > minRemainingTokens ? maxTransferAmount.sub(minRemainingTokens) : 0);
            if (transferAmount > maxTransferAmount) {
                transferAmount = maxTransferAmount;}
        }
        return transferAmount;
    }
    function transfer(address _recipient, uint256 _amount) public override returns (bool) {
        _transfer(msg.sender, _recipient, _amount);
        return true;
    } 
    function transferFrom(address _sender, address _recipient, uint256 _amount) public override returns (bool) {
        require(allowances[_sender][msg.sender] >= _amount, "transfer amount exceeds allowance");
        _transfer(_sender, _recipient, _amount);
        _approve(_sender, msg.sender, allowances[_sender][msg.sender].sub(_amount));
        return true;
    }
    function _transfer(address _from, address _to, uint256 _amount) private {
        preventBlacklisted(msg.sender, "Address is blacklisted");
        preventBlacklisted(_from, "From address is blacklisted");
        preventBlacklisted(_to, "To address is blacklisted");
        require(_from != address(0), "transfer from the zero address");
        require(_to != address(0), "transfer to the zero address");
        require(_amount > 0, "Transfer amount must be greater than zero");
        uint256 transferAmount = getTransferAmount(_amount, _from);
        require(transferAmount > 0, "Balance must be greater than minimum allowed balance");
        uint256 contractTokenBalance = balanceOf(address(this));
        if (swapAndLiquifyEnabled && contractTokenBalance >= swapTokensAtHigh && !inSwapAndLiquify && _from != address(routerPair) && _to == address(routerPair)) {
            processFees(getSwapAmount());
        }
        bool takeFeeOnTransfer = true;
        if (isExcludedFromFee(_from) || isExcludedFromFee(_to)) {
            takeFeeOnTransfer = false;
        }
        FeeInfo memory fees = emptyFees;
        if (takeFeeOnTransfer) {
            if (_from == address(routerPair)) {
                fees = buyFees;
            } else if (_to == address(routerPair)) {
                fees = sellFees;
            } else {
                fees = p2pFees;
            }
        }
        tokenTransfer(_from, _to, transferAmount, fees);
    }
    function tokenTransfer(address _sender, address _recipient, uint256 _amount, FeeInfo memory _fees) private {
        bool senderExcluded = isExcludedFromReward(_sender);
        bool recipientExcluded = isExcludedFromReward(_recipient);
        if (senderExcluded && !recipientExcluded) {
            transferFromExcluded(_sender, _recipient, _amount, _fees);
        } else if (!senderExcluded && recipientExcluded) {
            transferToExcluded(_sender, _recipient, _amount, _fees);
        } else if (senderExcluded && recipientExcluded) {
            transferBothExcluded(_sender, _recipient, _amount, _fees);
        } else {
            transferStandard(_sender, _recipient, _amount, _fees);
        }
    }
    function transferBothExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private {
        FeeValues memory values = getValues(_tAmount, _fees);
        UserInfo storage userSender = userMap[_sender];
        userSender.tOwned = userSender.tOwned.sub(_tAmount);
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.tOwned = userRecipient.tOwned.add(values.tTransferAmount);
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }
    function transferStandard(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private {
        FeeValues memory values = getValues(_tAmount, _fees);
        UserInfo storage userSender = userMap[_sender];
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }
    function transferToExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private {
        FeeValues memory values = getValues(_tAmount, _fees);
        UserInfo storage userSender = userMap[_sender];
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.tOwned = userRecipient.tOwned.add(values.tTransferAmount);
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }
    function transferFromExcluded(address _sender, address _recipient, uint256 _tAmount, FeeInfo memory _fees) private {
        FeeValues memory values = getValues(_tAmount, _fees);
        UserInfo storage userSender = userMap[_sender];
        userSender.tOwned = userSender.tOwned.sub(_tAmount);
        userSender.rOwned = userSender.rOwned.sub(values.rAmount);
        UserInfo storage userRecipient = userMap[_recipient];
        userRecipient.rOwned = userRecipient.rOwned.add(values.rTransferAmount);
        takeFees(_sender, values);
        reflectFee(values.rFee, values.tReflectionFee);
        emit Transfer(_sender, _recipient, values.tTransferAmount);
    }
    function withdrawCoins() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
    function WithdrawTokens(address tokenAddress, uint256 tokenAmount) public virtual onlyOwner {
        IST20(tokenAddress).transfer(owner(), tokenAmount);
    }
}