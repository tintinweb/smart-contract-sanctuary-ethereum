// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import './libraries/Ownable.sol';
import "./libraries/TimeLock.sol";
import './interfaces/IUniswapV2Factory.sol';
import './interfaces/IUniswapV2Pair.sol';
import './interfaces/IUniswapV2Router02.sol';

contract HashtagCoin is IERC20, TimeLock, Ownable {

    struct Minting {
        address recipient;
        uint amount;
    }

    struct StandardFees {
        uint taxFee;
        uint rewardFee;
        uint marketFee;
        uint taxPenaltyFee;
        uint rewardPenaltyFee;
        uint marketPenaltyFee;
    }

    StandardFees private standardFees;

    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private shoppingCart;
    address private rewardWallet;
    address private uniswapPair;

    address[] private excludedList;

    string public name;
    string public symbol;

    uint private constant MAX = ~uint(0);
    uint private constant GRANULARITY = 100;

    uint private constant SUPPLY_TOTAL = 1e9 ether;        // 1 billion
    uint private constant SUPPLY_TEAM = 100 * 1e6 ether;   // 100 mil for team
    uint private constant SUPPLY_REWARD = 50 * 1e6 ether;  // 50 mil for rewards wallet
    uint private constant SUPPLY_MARKET = 100 * 1e6 ether; // 100 mil for marketing wallet
    uint private constant SUPPLY_LIQ = 750 * 1e6 ether;    // 750 mil for liquidity
    
    uint private constant LOCK_PERIOD = 180 days;          // lock period 
    uint private constant COOLDOWN_PERIOD = 30 minutes;          // lock period     

    uint public TAX_FEE;    // 3%
    uint public BURN_FEE;   // 3%
    uint public MARKET_FEE; // 3%

    uint public totalFees;
    uint public totalBurn;
    uint public totalMarketingFee;
    uint private r_Total;    
    uint private mintedTeamSupply;

    bool private isPaused;
    bool private isEnableSwapTokenforEth;

    mapping(address => uint) private r_Owned;
    mapping(address => uint) private t_Owned;
    mapping(address => mapping(address => uint)) private allowanceList;

    mapping(address => uint) public cooldownOf;
    mapping(address => uint) private basisInfo;
    mapping(address => bool) private isAllowedTransfer;
    mapping(address => bool) private isExcluded;
    mapping(address => address) private referralOwner;
    mapping(address => uint) private referralOwnerTotalFee;
    
    constructor(
        string memory _name, 
        string memory _symbol
    ) {
        name = _name;
        symbol = _symbol;

        r_Total = (MAX - (MAX % SUPPLY_TOTAL));

        // setup uniswap pair and store address
        uniswapPair = IUniswapV2Factory(IUniswapV2Router02(UNISWAP_ROUTER).factory())
            .createPair(IUniswapV2Router02(UNISWAP_ROUTER).WETH(), address(this));

        r_Owned[address(this)] = r_Total;

        __excludeAccount(msg.sender);
        __excludeAccount(address(this));
        __excludeAccount(uniswapPair);
        __excludeAccount(UNISWAP_ROUTER);

        // prepare to add liquidity
        _approve(address(this), owner, r_Total);

        isPaused = true;
        isEnableSwapTokenforEth = false;

        // Transfer token(750 mil) to owner(msg.sender) for adding liquidity
        __transfer(address(this), msg.sender, SUPPLY_LIQ);
    }

    receive () external payable {}

    modifier isNotPaused() {
        require(isPaused == false, "ERR: paused already");
        _;
    }

    function totalSupply() external pure override returns (uint) {
        return SUPPLY_TOTAL;
    }

    function balanceOf(address account) public view override returns (uint) {
        if (isExcluded[account]) return t_Owned[account];

        return tokenFromReflection(r_Owned[account]);
    }

    function transfer(address recipient, uint amount) external override returns (bool) {
        __transfer(msg.sender, recipient, amount);

        return true;
    }

    function allowance(address holder, address spender) external view override returns (uint) {
        return allowanceList[holder][spender];
    }

    function approve(address spender, uint amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);

        return true;
    }

    function transferFrom(address sender, address recipient, uint amount) external override returns (bool) {
        __transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowanceList[sender][msg.sender] - amount);

        return true;
    }

    function increaseAllowance(address spender, uint addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowanceList[msg.sender][spender] + addedValue);

        return true;
    }

    function decreaseAllowance(address spender, uint subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, allowanceList[msg.sender][spender] - subtractedValue);

        return true;
    }

    function isExcludedAcount(address account) external view returns (bool) {
        return isExcluded[account];
    }

    function checkReferralReward(address referOwner) external view returns (uint) {
        return referralOwnerTotalFee[referOwner];
    }
    function reflectionFromToken(uint tAmount, bool deductTransferFee) external view returns(uint) {
        require(tAmount <= SUPPLY_TOTAL, "Amount must be less than supply");
        
        if (!deductTransferFee) {
            (uint rAmount,,,,,,) = __getValues(tAmount);
            return rAmount;
        } else {
            (,uint rTransferAmount,,,,,) = __getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint rAmount) public view returns(uint) {
        require(rAmount <= r_Total, "Amount must be less than total reflections");

        return rAmount / __getRate();
    }

    function excludeAccount(address account) external onlyOwner {
        __excludeAccount(account);
    }

    function __excludeAccount(address account) private {
        require(!isExcluded[account], "Account is already excluded");

        if(r_Owned[account] > 0) {
            t_Owned[account] = tokenFromReflection(r_Owned[account]);
        }

        isExcluded[account] = true;
        excludedList.push(account);
        isAllowedTransfer[account] = true;

        excludeFromLock(account);
    }

    function includeAccount(address account) external onlyOwner {
        require(isExcluded[account], "Account is already included");
        for (uint i = 0; i < excludedList.length; i++) {
            if (excludedList[i] == account) {
                excludedList[i] = excludedList[excludedList.length - 1];
                t_Owned[account] = 0;
                isExcluded[account] = false;
                excludedList.pop();
                break;
            }
        }
    }

    function _approve(address holder, address spender, uint amount) private {
        require(holder != address(0), "TOKEN20: approve from the zero address");
        require(spender != address(0), "TOKEN20: approve to the zero address");

        allowanceList[holder][spender] = amount;

        emit Approval(holder, spender, amount);
    }

    function basisOf(address account) public view returns (uint) {
        uint basis = basisInfo[account];
        if (basis == 0 && balanceOf(account) > 0) basis = 0;

        return basis;
    }

    function setBusinessWallet(address businessAddress) external onlyOwner isNotPaused returns (bool) {
        require(businessAddress != address(0), "ERR: zero address");

        shoppingCart = businessAddress;
        uint cartAmount = SUPPLY_MARKET;

        __removeFee();
        __transferFromExcluded(address(this), businessAddress, cartAmount);
        __restoreAllFee();
        __excludeAccount(businessAddress);

        return true;
    }

    function setRewardAddress(address rewardAddress) external onlyOwner isNotPaused returns (bool) {
        require(rewardAddress != address(0), "ERR: zero address");

        rewardWallet = rewardAddress;
        uint burnAmount = SUPPLY_REWARD;

        __removeFee();
        __transferFromExcluded(address(this), rewardAddress, burnAmount);
        __restoreAllFee();
        __excludeAccount(rewardAddress);

        return true;
    }

    function setReferralOwner(address referUser, address referOwner) external returns (bool) {
        require(referralOwner[referUser] == address(0), "ERR: address registered already");
        require(referUser != address(0) && referOwner != address(0), "ERR: zero address");

        referralOwner[referUser] = referOwner;

        return true;
    }

    function setStandardFee(StandardFees memory _standardFee) external onlyOwner isNotPaused returns (bool) {
        require (
            _standardFee.taxFee < 100 && _standardFee.rewardFee < 100 && _standardFee.marketFee < 100, 
            "ERR: Fee is so high"
        );
        require (
            _standardFee.taxPenaltyFee < 100 && _standardFee.rewardPenaltyFee < 100 && _standardFee.marketPenaltyFee < 100, 
            "ERR: Fee is so high"
        );

        standardFees = _standardFee;

        return true;
    }
   
    function mintDev(Minting[] calldata mintings) external onlyOwner returns (bool) {
        require(mintings.length > 0, "ERR: zero address array");

        __removeFee();       

        for(uint i = 0; i < mintings.length; i++) {
            Minting memory m = mintings[i];

            require(mintedTeamSupply + m.amount <= SUPPLY_TEAM, "ERR: exceed max team mint amount");

            __transferFromExcluded(address(this), m.recipient, m.amount);

            mintedTeamSupply += m.amount;

            lockAddress(m.recipient, uint64(LOCK_PERIOD));
        }       

        __restoreAllFee();

        return true;
    }    

    function pausedEnable() external onlyOwner returns (bool) {
        require(!isPaused, "ERR: already pause enabled");
        isPaused = true;
        return true;
    }

    function pausedNotEnable() external onlyOwner returns (bool) {
        require(isPaused, "ERR: already pause disabled");
        isPaused = false;
        return true;
    }

    function swapTokenForEthEnable() external onlyOwner isNotPaused returns (bool) {
        require(!isEnableSwapTokenforEth, "ERR: already enabled");
        isEnableSwapTokenforEth = true;
        return true;
    }

    function swapTokenForEthDisable() external onlyOwner isNotPaused returns (bool) {
        require(isEnableSwapTokenforEth, "ERR: already disabled");
        isEnableSwapTokenforEth = false;
        return true;
    }

    function checkReferralOwner(address referUser) external view returns (address) {
        require(referUser != address(0), "ERR: zero address");

        return referralOwner[referUser];
    }

    function checkedTimeLock(address user) external view returns (bool) {
        return !isUnLocked(user);
    }

    function checkAllowedTransfer(address user) external view returns (bool) {
        return isAllowedTransfer[user];
    }

    function __beforeTokenTransfer(
        address from,
        address to,
        uint amount
    ) internal {
        // ignore minting and burning
        if (from == address(0) || to == address(0)) return;
        // ignore add/remove liquidity
        if (from == address(this) || to == address(this)) return;
        if (from == owner || to == owner) return;
        if (from == UNISWAP_ROUTER || to == UNISWAP_ROUTER) return;

        require(
            msg.sender == UNISWAP_ROUTER ||
            msg.sender == uniswapPair || msg.sender == owner ||
            isAllowedTransfer[from] || isAllowedTransfer[to],
            "ERR: sender must be uniswap or shoppingCart"
        );

        address[] memory path = new address[](2);

        if (from == uniswapPair && !isExcluded[to]) {
            require(isUnLocked(to), "ERR: address is locked(buy)");
            require(cooldownOf[to] < block.timestamp);
            
            cooldownOf[to] = block.timestamp + COOLDOWN_PERIOD;

            path[0] = IUniswapV2Router02(UNISWAP_ROUTER).WETH();
            path[1] = address(this);
            uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsIn(amount, path);

            uint balance = balanceOf(to);
            uint fromBasis = (1 ether) * amounts[0] / amount;
            basisInfo[to] = (fromBasis * amount + basisOf(to) * balance) / (amount + balance);

        } else if (to == uniswapPair && !isExcluded[from]) {
            require(isUnLocked(from), "ERR: address is locked(sales)");            
            require(cooldownOf[from] < block.timestamp);

            cooldownOf[from] = block.timestamp + COOLDOWN_PERIOD;            
        }
    }

    function __transfer(
        address sender, 
        address recipient, 
        uint amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        __beforeTokenTransfer(sender, recipient, amount);
        __transferWithFee(sender, recipient, amount);
        
        emit Transfer(sender, recipient, amount);
    }

    function __transferWithFee(
        address sender, 
        address recipient, 
        uint amount
    ) private returns (bool) {
        uint liquidityBalance = balanceOf(uniswapPair);

        if(sender == uniswapPair && !isAllowedTransfer[recipient]) {
            require(amount <= liquidityBalance / 100, "ERR: Exceed the 1% of current liquidity balance");
            __restoreAllFee();
        }
        else if(recipient == uniswapPair && !isAllowedTransfer[sender]) {
            require(isEnableSwapTokenforEth, "ERR: disabled swap");
            require(amount <= liquidityBalance / 100, "ERR: Exceed the 1% of current liquidity balance");

            address[] memory path = new address[](2);
            path[0] = address(this);
            path[1] = IUniswapV2Router02(UNISWAP_ROUTER).WETH();
            uint[] memory amounts = IUniswapV2Router02(UNISWAP_ROUTER).getAmountsOut(amount, path);

            if(basisOf(sender) <= (1 ether) * amounts[1] / amount) __restoreAllFee();
            else __setPenaltyFee();
        } else {
            __removeFee();
        }

        if (isExcluded[sender] && !isExcluded[recipient]) {
            __transferFromExcluded(sender, recipient, amount);
        } 
        else if (!isExcluded[sender] && isExcluded[recipient]) {
            if(recipient == uniswapPair) __transferToExcludedForSale(sender, recipient, amount);
            else __transferToExcluded(sender, recipient, amount);
        } 
        else if (!isExcluded[sender] && !isExcluded[recipient]) {
            __transferStandard(sender, recipient, amount);
        } 
        else if (isExcluded[sender] && isExcluded[recipient]) {
            __transferBothExcluded(sender, recipient, amount);
        } 
        else {
            __transferStandard(sender, recipient, amount);
        }

        __restoreAllFee();

        return true;
    }

    function __transferStandard(address sender, address recipient, uint tAmount) private {
        uint currentRate = __getRate();
        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rFee, 
            uint tTransferAmount, 
            uint tFee, 
            uint tBurn, 
            uint tMarket
        ) = __getValues(tAmount);

        uint rBurn = tBurn * currentRate;
        uint rMarket = tMarket * currentRate;     
        __standardTransferContent(sender, recipient, rAmount, rTransferAmount);

        if(tMarket > 0) __sendToBusinees(tMarket, sender, recipient);
        
        if(tBurn > 0) __sendToBurn(tBurn, sender);
        
        __reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function __standardTransferContent(
        address sender, 
        address recipient, 
        uint rAmount, 
        uint rTransferAmount
    ) private {
        r_Owned[sender] = r_Owned[sender] - rAmount;
        r_Owned[recipient] = r_Owned[recipient] + rTransferAmount;
    }
    
    function __transferToExcluded(
        address sender, 
        address recipient, 
        uint tAmount
    ) private {
        uint currentRate =  __getRate();
        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rFee, 
            uint tTransferAmount, 
            uint tFee, 
            uint tBurn, 
            uint tMarket
        ) = __getValues(tAmount);

        uint rBurn =  tBurn * currentRate;
        uint rMarket = tMarket * currentRate;
        __excludedFromTransferContent(sender, recipient, tTransferAmount, rAmount, rTransferAmount);        

        if(tMarket > 0) __sendToBusinees(tMarket, sender, recipient);
        
        if(tBurn > 0) __sendToBurn(tBurn, sender);
        
        __reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function __excludedFromTransferContent(
        address sender, 
        address recipient, 
        uint tTransferAmount, 
        uint rAmount, 
        uint rTransferAmount
    ) private {
        r_Owned[sender] = r_Owned[sender] - rAmount;
        t_Owned[recipient] = t_Owned[recipient] + tTransferAmount;
        r_Owned[recipient] = r_Owned[recipient] + rTransferAmount;    
    }
    
    function __transferToExcludedForSale(
        address sender, 
        address recipient, 
        uint tAmount
    ) private {
        uint currentRate =  __getRate();
        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rFee, 
            uint tTransferAmount, 
            uint tFee, 
            uint tBurn, 
            uint tMarket
        ) = __getValuesForSale(tAmount);

        uint rBurn =  tBurn * currentRate;
        uint rMarket = tMarket * currentRate;
        __excludedFromTransferContentForSale(sender, recipient, tAmount, rAmount, rTransferAmount);      

        if(tMarket > 0) __sendToBusinees(tMarket, sender, recipient);
        
        if(tBurn > 0) __sendToBurn(tBurn, sender);
        
        __reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function __excludedFromTransferContentForSale(
        address sender, 
        address recipient, 
        uint tAmount, 
        uint rAmount, 
        uint rTransferAmount
    ) private {
        r_Owned[sender] = r_Owned[sender] - rTransferAmount;
        t_Owned[recipient] = t_Owned[recipient] + tAmount;
        r_Owned[recipient] = r_Owned[recipient] + rAmount;    
    }    

    function __transferFromExcluded(
        address sender, 
        address recipient, 
        uint tAmount
    ) private {
        uint currentRate =  __getRate();
        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rFee, 
            uint tTransferAmount, 
            uint tFee, 
            uint tBurn, 
            uint tMarket
        ) = __getValues(tAmount);

        uint rBurn =  tBurn * currentRate;
        uint rMarket = tMarket * currentRate;
        __excludedToTransferContent(sender, recipient, tAmount, rAmount, rTransferAmount);

        if(tMarket > 0) __sendToBusinees(tMarket, sender, recipient);
        
        if(tBurn > 0) __sendToBurn(tBurn, sender);
        
        __reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function __excludedToTransferContent(
        address sender, 
        address recipient, 
        uint tAmount, 
        uint rAmount, 
        uint rTransferAmount
    ) private {
        t_Owned[sender] = t_Owned[sender] - tAmount;
        r_Owned[sender] = r_Owned[sender] - rAmount;
        r_Owned[recipient] = r_Owned[recipient] + rTransferAmount;  
    }

    function __transferBothExcluded(
        address sender, 
        address recipient, 
        uint tAmount
    ) private {
        uint currentRate =  __getRate();
        (
            uint rAmount, 
            uint rTransferAmount, 
            uint rFee, 
            uint tTransferAmount, 
            uint tFee, 
            uint tBurn, 
            uint tMarket
        ) = __getValues(tAmount);

        uint rBurn =  tBurn * currentRate;
        uint rMarket = tMarket * currentRate;    
        __bothTransferContent(sender, recipient, tAmount, rAmount, tTransferAmount, rTransferAmount);  

        if(tMarket > 0) __sendToBusinees(tMarket, sender, recipient);
        
        if(tBurn > 0) __sendToBurn(tBurn, sender);
        
        __reflectFee(rFee, rBurn, rMarket, tFee, tBurn, tMarket);

        emit Transfer(sender, recipient, tTransferAmount);
    }
    
    function __bothTransferContent(
        address sender, 
        address recipient, 
        uint tAmount, 
        uint rAmount, 
        uint tTransferAmount, 
        uint rTransferAmount
    ) private {
        t_Owned[sender] = t_Owned[sender] - tAmount;
        r_Owned[sender] = r_Owned[sender] - rAmount;
        t_Owned[recipient] = t_Owned[recipient] + tTransferAmount;
        r_Owned[recipient] = r_Owned[recipient] + rTransferAmount;  
    }

    function __reflectFee(
        uint rFee, 
        uint rBurn, 
        uint rMarket, 
        uint tFee, 
        uint tBurn, 
        uint tMarket
    ) private {
        r_Total = r_Total - rFee - rBurn - rMarket;
        totalFees = totalFees + tFee;
        totalBurn = totalBurn + tBurn;
        totalMarketingFee = totalMarketingFee + tMarket;
    }

    function __getValues(uint tAmount) private view returns (uint, uint, uint, uint, uint, uint, uint) {
        (uint tFee, uint tBurn, uint tMarket) = __getTBasics(tAmount, TAX_FEE, BURN_FEE, MARKET_FEE);

        uint tTransferAmount = __getTTransferAmount(tAmount, tFee, tBurn, tMarket);

        uint currentRate = __getRate();

        (uint rAmount, uint rFee) = __getRBasics(tAmount, tFee, currentRate);

        uint rTransferAmount = __getRTransferAmount(rAmount, rFee, tBurn, tMarket, currentRate);

        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tBurn, tMarket);
    }

    function __getValuesForSale(uint tAmount) private view returns (uint, uint, uint, uint, uint, uint, uint) {
        (uint tFee, uint tBurn, uint tMarket) = __getTBasics(tAmount, TAX_FEE, BURN_FEE, MARKET_FEE);

        uint tTransferAmountForSale = __getTTransferAmountForSale(tAmount, tFee, tBurn, tMarket);

        uint currentRate = __getRate();

        (uint rAmount, uint rFee) = __getRBasics(tAmount, tFee, currentRate);

        uint rTransferAmountForSale = __getRTransferAmountForSale(rAmount, rFee, tBurn, tMarket, currentRate);

        return (rAmount, rTransferAmountForSale, rFee, tTransferAmountForSale, tFee, tBurn, tMarket);
    }
    
    function __getTBasics(
        uint tAmount, 
        uint taxFee, 
        uint burnFee, 
        uint marketFee
    ) private pure returns (uint, uint, uint) {
        uint tFee = (tAmount * taxFee) / GRANULARITY / 100;
        uint tBurn = (tAmount * burnFee) / GRANULARITY / 100;
        uint tMarket = (tAmount * marketFee) / GRANULARITY / 100;

        return (tFee, tBurn, tMarket);
    }
    
    function __getTTransferAmount(
        uint tAmount, 
        uint tFee, 
        uint tBurn, 
        uint tMarket
    ) private pure returns (uint) {
        return tAmount - tFee - tBurn - tMarket;
    }
    function __getTTransferAmountForSale(
        uint tAmount, 
        uint tFee, 
        uint tBurn, 
        uint tMarket
    ) private pure returns (uint) {
        return tAmount + tFee + tBurn + tMarket;
    }
    
    function __getRBasics(
        uint tAmount, 
        uint tFee, 
        uint currentRate
    ) private pure returns (uint, uint) {
        uint rAmount = tAmount * currentRate;
        uint rFee = tFee * currentRate;

        return (rAmount, rFee);
    }
    
    function __getRTransferAmount(
        uint rAmount, 
        uint rFee, 
        uint tBurn, 
        uint tMarket, 
        uint currentRate
    ) private pure returns (uint) {
        uint rBurn = tBurn * currentRate;
        uint rMarket = tMarket * currentRate;
        uint rTransferAmount = rAmount - rFee - rBurn - rMarket;

        return rTransferAmount;
    }

    function __getRTransferAmountForSale(
        uint rAmount, 
        uint rFee, 
        uint tBurn, 
        uint tMarket, 
        uint currentRate
    ) private pure returns (uint) {
        uint rBurn = tBurn * currentRate;
        uint rMarket = tMarket * currentRate;
        uint rTransferAmountForSale = rAmount + rFee + rBurn + rMarket;

        return rTransferAmountForSale;
    }

    function __getRate() private view returns(uint) {
        (uint rSupply, uint tSupply) = __getCurrentSupply();

        return rSupply / tSupply;
    }

    function __getCurrentSupply() private view returns(uint, uint) {
        uint rSupply = r_Total;
        uint tSupply = SUPPLY_TOTAL;      

        for (uint i = 0; i < excludedList.length; i++) {
            if (r_Owned[excludedList[i]] > rSupply || t_Owned[excludedList[i]] > tSupply) return (r_Total, SUPPLY_TOTAL);

            rSupply = rSupply - r_Owned[excludedList[i]];
            tSupply = tSupply - t_Owned[excludedList[i]];
        }

        if (rSupply < r_Total / SUPPLY_TOTAL) return (r_Total, SUPPLY_TOTAL);

        return (rSupply, tSupply);
    }

    function __sendToBusinees(
        uint tMarket, 
        address sender, 
        address recipient
    ) private {
        uint currentRate = __getRate();
        uint rMarket = tMarket * currentRate;

        if(sender == uniswapPair && referralOwner[recipient] != address(0)) {
            __sendToReferralOwner(tMarket, rMarket, referralOwner[recipient]);

            emit Transfer(sender,  referralOwner[recipient], tMarket);
        } else {
            r_Owned[shoppingCart] = r_Owned[shoppingCart] + rMarket;
            t_Owned[shoppingCart] = t_Owned[shoppingCart] + tMarket;

            emit Transfer(sender, shoppingCart, tMarket);
        }
    }

    function __sendToBurn(uint tBurn, address sender) private {
        uint currentRate = __getRate();
        uint rBurn = tBurn * currentRate;

        r_Owned[rewardWallet] = r_Owned[rewardWallet] + rBurn;
        t_Owned[rewardWallet] = t_Owned[rewardWallet] + rBurn;

        emit Transfer(sender, rewardWallet, tBurn);
    }

    function __sendToReferralOwner(
        uint tMarket, 
        uint rMarket, 
        address referOwner
    ) private {
        if(isExcluded[referOwner]) {
            r_Owned[referOwner] = r_Owned[referOwner] + rMarket;
            t_Owned[referOwner] = t_Owned[referOwner] + tMarket;
        }
        else {
            r_Owned[referOwner] = r_Owned[referOwner] + rMarket;
        }

        referralOwnerTotalFee[referOwner] += tMarket;
    }

    function __removeFee() private {
        if(TAX_FEE == 0 && BURN_FEE == 0 && MARKET_FEE == 0) return;

        TAX_FEE = 0;
        BURN_FEE = 0;
        MARKET_FEE = 0;
    }

    function __restoreAllFee() private {
        TAX_FEE = standardFees.taxFee * 100;
        BURN_FEE = standardFees.rewardFee * 100;
        MARKET_FEE = standardFees.marketFee * 100;
    }

    function __setPenaltyFee() private {
        TAX_FEE = standardFees.taxPenaltyFee * 100;
        BURN_FEE = standardFees.rewardPenaltyFee * 100;
        MARKET_FEE = standardFees.marketPenaltyFee * 100;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
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
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

contract Ownable {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    function transferOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Ownable: Zero newOwner address");
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

abstract contract TimeLock {

    struct LockedAddress {
        uint64 lockedPeriod;
        uint64 endTime;
    }
    
    mapping(address => LockedAddress) private lockedList;
    mapping(address => bool) private isExlcludeFromLock;
    
    constructor() { }

    function lockAddress(address _lockAddress, uint64 _lockTime) internal virtual {
        require(_lockAddress != address(0), "ERR: zero lock address");
        require(_lockTime > 0, "ERR: zero lock period");
        
        if(!isExlcludeFromLock[_lockAddress]) {
            lockedList[_lockAddress].lockedPeriod = _lockTime;
            lockedList[_lockAddress].endTime = uint64(block.timestamp) + _lockTime;
        }
    }

    function isUnLocked(address _lockAddress) internal view virtual returns (bool) {
        require(_lockAddress != address(0), "ERR: zero lock address");
        
        if(isExlcludeFromLock[_lockAddress]) return true;
        
        return lockedList[_lockAddress].endTime < uint64(block.timestamp);
    }

    function excludeFromLock(address _lockAddress) internal virtual {
        require(_lockAddress != address(0), "ERR: zero lock address");
        
        if(isExlcludeFromLock[_lockAddress]) return;

        isExlcludeFromLock[_lockAddress] = true;
    }
}