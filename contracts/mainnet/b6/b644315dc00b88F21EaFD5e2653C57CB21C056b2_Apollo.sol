/**
 *Submitted for verification at Etherscan.io on 2022-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;
pragma experimental ABIEncoderV2;

////// lib/openzeppelin-contracts/contracts/utils/Context.sol
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

/* pragma solidity ^0.8.0; */

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

////// lib/openzeppelin-contracts/contracts/access/Ownable.sol
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

/* pragma solidity ^0.8.0; */

/* import "../utils/Context.sol"; */

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

////// lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

/* pragma solidity ^0.8.0; */

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IUniswapV2Pair {
    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface ISpiralChef {
    function userBurntForNum(uint256 burnNum, address user) external view returns (uint256);
    function userAmount(uint256 _pid, address user) external view returns (uint256);
}

contract Apollo is Context, IERC20, Ownable {

    struct UserInfo {
        uint16 rateNum;
        uint64 burnt;
        uint64 balances;
        uint104 lastRate;
    }

    struct TransferInfo {
        bool swapEnabled;
        bool swapping;
        uint16 buyTotal;
        uint16 buyLP;
        uint16 buyRew;
        uint16 buyBurn;
        uint16 sellTotal;
        uint16 sellLP;
        uint16 sellRew;
        uint16 sellBurn;
        uint16 timePeriod;
        uint32 preTradingUntil;
        uint64 swapTokensAtAmount;
    }

    struct SupplyInfo {
        bool actBurn;
        uint8 burnRef;
        uint16 ampRate;
        uint16 rateNum; 
        uint88 rSupply;
        uint104 currentRate;
    }

    struct MainBalances{
        uint64 thisBalance;
        uint64 deadBalance;
        uint64 pairBalance;
    }

    string private _name = 'Apollo';
    string private _symbol = 'APOLLO';
    uint8 private _decimals = 9;

    uint104 private constant MAX_UINT104 = ~uint104(0);
    uint256 private constant INITIAL_FRAGMENTS_SUPPLY = 1 * 1e8 * 1e9;
    uint256 public constant maxFee = 200;
    TransferInfo public transferInfoStor;
    SupplyInfo public currentSupply;
    MainBalances public mainBalances;

    mapping(uint256 => SupplyInfo) public supplyInfo;
    mapping(address => UserInfo) public userInfo;
    mapping(address => bool) public rewardsExcluded;
    mapping(address => bool) public feesExcluded;
    mapping (address => mapping (address => uint256)) private _allowances;

    ISpiralChef public immutable spiralChef;
    IUniswapV2Router02 public constant mainRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public fundAddress;
    address public immutable mainPair;
    address public immutable pairedToken;
    address public constant deadAddress = address(0xdead);
    bool public showDead = true;    

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event ExcludeFromRewards(address indexed account, bool isExcluded);
    event Burnt(address indexed account, uint256 amount);

    constructor (address _fundAddress, address _pairedToken, ISpiralChef _spiralChef) {
        userInfo[_msgSender()] = UserInfo(0, 0, uint64(INITIAL_FRAGMENTS_SUPPLY), uint104(MAX_UINT104));
        currentSupply = SupplyInfo(false,0,20,0,uint64(INITIAL_FRAGMENTS_SUPPLY), MAX_UINT104);
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(address(this), _pairedToken);
        transferInfoStor = TransferInfo(true, false, 70,10,20,0,70,10,20,0,0,~uint32(0),1 * 1e2 * 1e9);
        pairedToken = _pairedToken;
        fundAddress = _fundAddress;
        spiralChef = _spiralChef;
        rewardsExcluded[mainPair] = true;
        rewardsExcluded[address(this)] = true;
        rewardsExcluded[deadAddress] = true;
        feesExcluded[deadAddress] = true;
        _approve(address(this), address(mainRouter), ~uint(256));

        emit Transfer(address(0), _msgSender(), INITIAL_FRAGMENTS_SUPPLY);
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

    function totalSupply() public view override returns (uint256) {
        return INITIAL_FRAGMENTS_SUPPLY - mainBalances.deadBalance;
    }

    function deadSupply() public view returns (uint256) {
        return mainBalances.deadBalance;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (account == address(this)) return mainBalances.thisBalance;
        if (account == mainPair) return mainBalances.pairBalance;
        if (account == deadAddress && showDead) return mainBalances.deadBalance;
        if (rewardsExcluded[account]) return userInfo[account].balances;
        UserInfo memory accountInfo = userInfo[account];
        if (accountInfo.rateNum == currentSupply.rateNum) {
            return _reflectionBalance(accountInfo, currentSupply);
        }
        return _reflectionBalance(accountInfo, supplyInfo[accountInfo.rateNum]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(_allowances[sender][_msgSender()]-amount >= 0, "ERC20: transfer amount exceeds allowance");
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()]-amount);
        return true;
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function rewardsEarned(address account) external view returns (uint256) {
        require(!rewardsExcluded[account]);
        UserInfo memory accountInfo = userInfo[account];
        if (accountInfo.rateNum == currentSupply.rateNum) {
            return _reflectionBalance(accountInfo, currentSupply) - accountInfo.balances;
        }
        return _reflectionBalance(accountInfo, supplyInfo[accountInfo.rateNum]) - accountInfo.balances;
    }

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        transferInfoStor.swapTokensAtAmount = uint64(newAmount);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        transferInfoStor.swapEnabled = enabled;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        feesExcluded[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function excludeFromRewards(address account, bool excluded) public onlyOwner {
        require(account != address(this) && account != deadAddress && account != mainPair);
        UserInfo memory accountInfo = userInfo[account];
        SupplyInfo memory supply = currentSupply;
        if (!rewardsExcluded[account] && excluded) {
            if (supply.rateNum == accountInfo.rateNum) {   
                accountInfo.balances = uint64(_reflectionBalance(accountInfo, supply));
                supply.rSupply -= uint88(_getUserBurnt(accountInfo)*supply.ampRate+accountInfo.balances);
                currentSupply = supply;
            }
            else {
                accountInfo.balances = uint64(_reflectionBalance(accountInfo, supplyInfo[accountInfo.rateNum]));
            }
            rewardsExcluded[account] = true;
        }
        else if (rewardsExcluded[account] && !excluded) {
            accountInfo.lastRate = supply.currentRate;
            accountInfo.rateNum = supply.rateNum;
            supply.rSupply += uint88(_getUserBurnt(accountInfo)*supply.ampRate+accountInfo.balances);
            rewardsExcluded[account] = false;
            currentSupply = supply;
        }
        userInfo[account] = accountInfo;
        emit ExcludeFromRewards(account, excluded);
    }

    function updateFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function setPreTradingUntil(uint256 _preTradingUntil) external onlyOwner {
        transferInfoStor.preTradingUntil = uint32(_preTradingUntil);
    }

    function setTimePeriod(uint256 _timePeriod) external onlyOwner {
        transferInfoStor.timePeriod = uint16(_timePeriod);
    }

    function updaterateNums(address[] memory addr) external onlyOwner {
        uint256 length = addr.length;
        for (uint256 i = 0; i < length; i++) {
            _updateUser(addr[i]);
        }
    }

    function updateBurnRef(uint256 _burnRef, bool _actBurn) external onlyOwner {
        require (_burnRef < 100);
        currentSupply.burnRef = uint8(_burnRef);
        currentSupply.actBurn = _actBurn;
    }

    function updateAmpRate(uint256 _ampRate) external onlyOwner {
        require(_ampRate < 1000);
        SupplyInfo memory _currentSupply = currentSupply;
        require(_currentSupply.rateNum + 1 != ~uint16(0));
        supplyInfo[_currentSupply.rateNum] = _currentSupply;
        currentSupply = SupplyInfo(_currentSupply.actBurn, _currentSupply.burnRef, uint16(_ampRate), uint16(_currentSupply.rateNum + 1), 0, MAX_UINT104);
    }

    function updateTax(uint256 _buyLP, uint256 _buyRew, uint256 _buyBurn, uint256 _buyTotal, uint256 _sellLP, uint256 _sellRew, uint256 _sellBurn, uint256 _sellTotal) external onlyOwner {
        require (_buyTotal <= maxFee);
        require (_sellTotal <= maxFee);
        require (_buyLP + _buyRew + _buyBurn <= _buyTotal);
        require (_sellLP + _sellRew + _sellBurn <= _sellTotal);
        transferInfoStor.buyLP = uint16(_buyLP);
        transferInfoStor.buyRew = uint16(_buyRew);
        transferInfoStor.buyBurn = uint16(_buyBurn);
        transferInfoStor.buyTotal = uint16(_buyTotal);
        transferInfoStor.sellLP = uint16(_sellLP);
        transferInfoStor.sellRew = uint16(_sellRew);
        transferInfoStor.sellBurn = uint16(_sellBurn);
        transferInfoStor.sellTotal = uint16(_sellTotal);
        _approve(address(this), address(mainRouter), ~uint(256));
    }

    function setShowDead(bool _showDead) external onlyOwner {
        showDead = _showDead;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        if (from == to) {
            _updateUser(from);
            return;
        }
        require(amount != 0);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 tokensForReflection;
        if (from != owner() && to != owner()) {
            uint256 contractBalance = mainBalances.thisBalance;
            TransferInfo memory transferInfo = transferInfoStor;
            bool canSwap = contractBalance > transferInfo.swapTokensAtAmount;
            
            if (
                mainPair == to &&
                !feesExcluded[from] &&
                !feesExcluded[to] &&
                canSwap &&
                transferInfoStor.swapEnabled &&
                !transferInfoStor.swapping
            ) {
                transferInfoStor.swapping = true;
                
                if (contractBalance > transferInfo.swapTokensAtAmount * 20) {
                    contractBalance = transferInfo.swapTokensAtAmount * 20;
                }

                swapBack(contractBalance);

                transferInfoStor.swapping = false;
            }

            bool takeFee = !transferInfoStor.swapping;
            if (feesExcluded[from] || feesExcluded[to]) {
                takeFee = false;
            }

            if (takeFee) {
                (uint256 fees, uint256 tokensForLiquidity, uint256 tokensForBurn) = (0,0,0);

                    // on sell
                    if (to == mainPair && transferInfo.sellTotal != 0) {
                        fees = amount*transferInfo.sellTotal/1000;
                        tokensForReflection = amount*transferInfo.sellRew/1000;
                        tokensForLiquidity = amount*transferInfo.sellLP/1000;
                        tokensForBurn = amount*transferInfo.sellBurn/1000;
                        if (fees > 0) {
                            _tokenTransfer(from, address(this), fees);
                            if (tokensForLiquidity > 0) {
                                _tokenTransfer(address(this), to, tokensForLiquidity);
                            }
                            if (tokensForBurn > 0) {
                                _tokenTransfer(address(this), deadAddress, tokensForBurn);
                            }
                        }
                    }
                    // on buy
                    else if (from == mainPair && transferInfo.buyTotal != 0) {
                        fees = amount*transferInfo.buyTotal/1000;
                        tokensForReflection = amount*transferInfo.buyRew/1000;
                        tokensForLiquidity = amount*transferInfo.buyLP/1000;
                        tokensForBurn = amount*transferInfo.buyBurn/1000;
                        if (fees > 0) {
                            _tokenTransfer(from, address(this), fees - tokensForLiquidity);
                            if (tokensForBurn > 0) {
                                _tokenTransfer(address(this), deadAddress, tokensForBurn);
                            }
                        }
                    }
                    amount -= fees;

                    if (block.timestamp < transferInfo.preTradingUntil + 7200 && mainPair != to) {
                        uint256 staked = spiralChef.userAmount(0, to)*10;
                        uint256 burnt = spiralChef.userBurntForNum(0, to);
                        if (block.timestamp >= transferInfo.preTradingUntil && burnt >= 1000) {
                            staked = staked*5;
                        }
                        require(staked >= (balanceOf(to) + amount));
                        require(block.timestamp >= transferInfo.preTradingUntil - burnt*transferInfo.timePeriod);
                    }
                }
        }
        _tokenTransfer(from, to, amount);

        if (tokensForReflection > 0) {
            (currentSupply, tokensForReflection) = _reflect(currentSupply, tokensForReflection);
            mainBalances.thisBalance -= uint64(tokensForReflection);
        }
    }

    function _updateUser(address user) internal {
        UserInfo memory userAcc = userInfo[user];
        SupplyInfo memory supply = currentSupply;
        if (rewardsExcluded[user] || userAcc.rateNum == supply.rateNum) {
            return;
        }
        userAcc.balances = uint64(_reflectionBalance(userAcc, supplyInfo[userAcc.rateNum]));
        supply.rSupply += uint88(_getUserBurnt(userAcc)*supply.ampRate + userAcc.balances); 
        userAcc.rateNum = supply.rateNum;
        userAcc.lastRate = supply.currentRate;
        userInfo[user] = userAcc;
        currentSupply = supply;
    }

    function _tokenTransfer(address from, address to, uint256 amount) internal {
        emit Transfer(from, to, amount);

        if (rewardsExcluded[from] && !rewardsExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!rewardsExcluded[from] && rewardsExcluded[to]) {
            if (to == deadAddress) {
                _transferToDead(from, amount);
            } else {
                _transferToExcluded(from, to, amount);}
        } else if (!rewardsExcluded[from] && !rewardsExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (rewardsExcluded[from] && rewardsExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        }
    }

    function _transferToDead(address from, uint256 amount) internal {
        UserInfo memory fromAcc = userInfo[from];
        SupplyInfo memory supply = currentSupply;
        uint256 deadAmount;
        if (fromAcc.rateNum == supply.rateNum) {
            supply.rSupply -= uint88(_getUserBurnt(fromAcc)*supply.ampRate + amount);
            fromAcc.balances = uint64(_reflectionBalance(fromAcc, supply) - amount);
            supply.rSupply -= fromAcc.balances;
        }
        else {
            fromAcc.balances = uint64(_reflectionBalance(fromAcc, supplyInfo[fromAcc.rateNum]) - amount);
        }
        uint256 brAmount = amount*(supply.burnRef)/100;
        if (supply.actBurn) {
            fromAcc.burnt += uint64(amount - brAmount);
        }
        else {
            fromAcc.burnt += uint64(amount);
        }
        amount -= brAmount;
        deadAmount += amount;
        if (brAmount != 0) {
            (supply, amount) = _reflect(supply, brAmount);
            deadAmount += brAmount - amount; 
        }
        supply.rSupply += uint88(_getUserBurnt(fromAcc)*supply.ampRate + fromAcc.balances);
        fromAcc.lastRate = supply.currentRate;
        fromAcc.rateNum = supply.rateNum;
        userInfo[from] = fromAcc;
        mainBalances.deadBalance += uint64(deadAmount);
        currentSupply = supply; 

        emit Burnt(from, deadAmount);
    }

    function _transferFromExcluded(address from, address to, uint256 amount) internal {
        UserInfo memory toAcc = userInfo[to];
        SupplyInfo memory supply = currentSupply;
        if (from == address(this)) {
            mainBalances.thisBalance -= uint64(amount);
        }
        else if (from == mainPair) {
            mainBalances.pairBalance -= uint64(amount);
        } 
        else {
            userInfo[from].balances -= uint64(amount);
        } 
        uint256 oldToBurnt; 
        uint256 newToBurnt;
        if (toAcc.rateNum == supply.rateNum) {
            oldToBurnt = _getUserBurnt(toAcc)*supply.ampRate;
            toAcc.balances = uint64(_reflectionBalance(toAcc, supply) + amount);
        }
        else {
            newToBurnt =  _reflectionBalance(toAcc, supplyInfo[toAcc.rateNum]);
            toAcc.balances = uint64(newToBurnt + amount);
        }
        toAcc.lastRate = supply.currentRate; 
        toAcc.rateNum = supply.rateNum;
        newToBurnt += _getUserBurnt(toAcc)*supply.ampRate;
        supply.rSupply = uint88(supply.rSupply + newToBurnt - oldToBurnt + amount);
        userInfo[to] = toAcc;
        currentSupply = supply;
    }

    function _transferToExcluded(address from, address to, uint256 amount) internal {
        UserInfo memory fromAcc = userInfo[from];
        SupplyInfo memory supply = currentSupply;
        if (to == address(this)) {
            mainBalances.thisBalance += uint64(amount);
        } 
        else if (to == mainPair) {
            mainBalances.pairBalance += uint64(amount);
        }
        else {
            userInfo[to].balances += uint64(amount);
        }
        uint256 oldFromBurnt; 
        uint256 newFromBurnt;
        if (fromAcc.rateNum == supply.rateNum) {
            oldFromBurnt = _getUserBurnt(fromAcc)*supply.ampRate;
            fromAcc.balances = uint64(_reflectionBalance(fromAcc, supply) - amount);
        }
        else {
            newFromBurnt = _reflectionBalance(fromAcc, supplyInfo[fromAcc.rateNum]);
            fromAcc.balances = uint64(newFromBurnt - amount);
        }
        fromAcc.lastRate = supply.currentRate;
        fromAcc.rateNum = supply.rateNum;
        newFromBurnt += _getUserBurnt(fromAcc)*supply.ampRate;
        supply.rSupply = uint88(supply.rSupply + newFromBurnt - oldFromBurnt - amount);
        userInfo[from] = fromAcc;
        currentSupply = supply;
    }

    function _transferStandard(address from, address to, uint256 amount) internal {
        UserInfo memory fromAcc = userInfo[from];
        UserInfo memory toAcc = userInfo[to];
        SupplyInfo memory supply = currentSupply;
        uint256 oldFromBurnt; 
        uint256 oldToBurnt; 
        uint256 newFromBurnt;
        uint256 newToBurnt;
        if (fromAcc.rateNum == supply.rateNum) {
            oldFromBurnt = _getUserBurnt(fromAcc)*supply.ampRate + amount;
            fromAcc.balances = uint64(_reflectionBalance(fromAcc, supply) - amount);
        }
        else{
            fromAcc.balances = uint64(_reflectionBalance(fromAcc, supplyInfo[fromAcc.rateNum]) - amount);
            newFromBurnt = fromAcc.balances;
        }
        if (toAcc.rateNum == supply.rateNum) {
            oldToBurnt = _getUserBurnt(toAcc)*supply.ampRate;
            toAcc.balances = uint64(_reflectionBalance(toAcc, supply) + amount);
            newToBurnt = amount;
        }
        else {
            toAcc.balances = uint64(_reflectionBalance(toAcc, supplyInfo[toAcc.rateNum]) + amount);
            newToBurnt =  toAcc.balances;
        }
        fromAcc.lastRate = supply.currentRate;
        toAcc.lastRate = supply.currentRate;
        fromAcc.rateNum = supply.rateNum;
        toAcc.rateNum = supply.rateNum;
        newToBurnt += _getUserBurnt(toAcc)*supply.ampRate;
        newFromBurnt += _getUserBurnt(fromAcc)*supply.ampRate;
        supply.rSupply = uint88(supply.rSupply + newFromBurnt + newToBurnt - oldFromBurnt - oldToBurnt);
        userInfo[from] = fromAcc;
        userInfo[to] = toAcc;
        currentSupply = supply;
    }

    function _transferBothExcluded(address from, address to, uint256 amount) internal {
        if (from == address(this)) {
            mainBalances.thisBalance -= uint64(amount);
        }
        else if (from == mainPair) {
            mainBalances.pairBalance -= uint64(amount);
        }
        else if (from == deadAddress) {
            mainBalances.deadBalance -= uint64(amount);
        } 
        else {
            userInfo[from].balances -= uint64(amount);
        } 
        if (to == address(this)) {
            mainBalances.thisBalance += uint64(amount);
        } 
        else if (to == mainPair) {
            mainBalances.pairBalance += uint64(amount);
        }
        else if (to == deadAddress) {
            mainBalances.deadBalance += uint64(amount);
        }
        else {
            userInfo[to].balances += uint64(amount);
        }
    }

    function _getUserBurnt(UserInfo memory accountInfo) private pure returns (uint256) {
        return accountInfo.burnt > accountInfo.balances ? accountInfo.balances : accountInfo.burnt;
    }

    function _reflectionBalance(UserInfo memory accountInfo, SupplyInfo memory supply) private pure returns (uint256) {
        uint256 burnt = _getUserBurnt(accountInfo);
        return accountInfo.balances != 0 ? (burnt*supply.ampRate+accountInfo.balances)*accountInfo.lastRate/supply.currentRate-burnt*supply.ampRate : 0;
    }

    function _reflect(SupplyInfo memory supply, uint256 amount) private pure returns (SupplyInfo memory, uint256) {
        amount = amount < supply.rSupply/100 ? amount : supply.rSupply/100;
        if (amount != 0) {
            uint256 rTotalBalances = uint256(supply.rSupply)*supply.currentRate;
            supply.rSupply += uint88(amount);
            uint104 currentRate = uint104(rTotalBalances/supply.rSupply);
            currentRate = currentRate != 0 ? currentRate : 1;
            supply.currentRate = currentRate;
        }
        return (supply, amount);
    } 

    function swapBack(uint256 tokenAmount) private {
        
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pairedToken;
        
        mainRouter.swapExactTokensForTokensSupportingFeeOnTransferTokens(
            tokenAmount,
            0, 
            path,
            fundAddress,
            block.timestamp
        );
    }

}