/**
 *Submitted for verification at Etherscan.io on 2023-03-10
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

interface ITaxCalculator {
    function getTax(address from, address to, uint256 amount) external returns (uint256, uint256);
}

contract Spiral is Context, IERC20, Ownable {

    struct UserInfo {
        bool feesExcluded;
        bool isAMM;
        uint64 balances;
    }

    struct TransferInfo {
        bool swapEnabled;
        uint8 trading;
        uint8 buyTax;
        uint8 buyLP;
        uint8 sellTax;
        uint8 sellLP;
        uint32 swapTokensAtAmount; 
        ITaxCalculator taxCalculator;
    }

    string private _name = 'Spiral';
    string private _symbol = 'SPIRAL';
    uint8 private _decimals = 9;
    uint256 private constant _totalSupply = 1e16;
    uint256 public constant maxFee = 200;

    TransferInfo public transferInfoStor;

    mapping(address => UserInfo) public userInfo;
    mapping (address => mapping (address => uint256)) private _allowances;

    IUniswapV2Router02 public mainRouter = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
    address public fundAddress;
    address public mainPair;
    address public pairedToken;

    event ExcludeFromFees(address indexed account, bool isExcluded);

    constructor (address _fundAddress, address _pairedToken) {
        userInfo[_msgSender()].balances = uint64(_totalSupply);
        mainPair = IUniswapV2Factory(mainRouter.factory()).createPair(address(this), _pairedToken);
        userInfo[mainPair].isAMM = true;
        transferInfoStor = TransferInfo(true,2,0,0,0,0,1e6,ITaxCalculator(address(0)));
        pairedToken = _pairedToken;
        fundAddress = _fundAddress;
        _approve(address(this), address(mainRouter), ~uint(256));

        emit Transfer(address(0), _msgSender(), _totalSupply);
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

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return userInfo[account].balances;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return userInfo[account].feesExcluded;
    }

    function isAMM(address account) public view returns (bool) {
        return userInfo[account].isAMM;
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

    // change the minimum amount of tokens to sell from fees
    function updateSwapTokensAtAmount(uint256 newAmount) external onlyOwner {
        transferInfoStor.swapTokensAtAmount = uint32(newAmount);
    }

    // only use to disable contract sales if absolutely necessary (emergency use only)
    function updateSwapEnabled(bool enabled) external onlyOwner {
        transferInfoStor.swapEnabled = enabled;
    }

    function setTaxCalculator(ITaxCalculator taxCalculator) external onlyOwner {
        if (address(taxCalculator) != address(0)){
            taxCalculator.getTax(address(0), address(0), 0);
        }
        transferInfoStor.taxCalculator = taxCalculator;
    }

    function excludeFromFees(address account, bool excluded) external onlyOwner {
        userInfo[account].feesExcluded = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function updateFundAddress(address _fundAddress) external onlyOwner {
        fundAddress = _fundAddress;
    }

    function setTrading(uint256 trading) external onlyOwner {
        require(trading < 2);
        transferInfoStor.trading = uint8(trading);
    }

    function updateTax(uint256 _buyLP, uint256 _buyTax, uint256 _sellLP, uint256 _sellTax) external onlyOwner {
        require (_buyTax <= maxFee);
        require (_sellTax <= maxFee);
        require (_buyLP <= _buyTax);
        require (_sellLP <= _sellTax);
        transferInfoStor.buyLP = uint8(_buyLP);
        transferInfoStor.buyTax = uint8(_buyTax);
        transferInfoStor.sellLP = uint8(_sellLP);
        transferInfoStor.sellTax = uint8(_sellTax);
        _approve(address(this), address(mainRouter), ~uint(256));
    }

    function setAMMPairs(address pair, bool _isAMM) external onlyOwner {
        userInfo[pair].isAMM = _isAMM;
    }

    function setMainPair(address _pairedToken, IUniswapV2Router02 _mainRouter) external onlyOwner {
        address _mainPair = IUniswapV2Factory(_mainRouter.factory()).getPair(address(this), _pairedToken);
        require(userInfo[_mainPair].isAMM);
        pairedToken = _pairedToken;
        mainPair = _mainPair;
        mainRouter = _mainRouter;
    }

    function retrieveToken(IERC20 _token) public onlyOwner {
        uint256 contractBalance = _token.balanceOf(address(this));
        _token.transfer(owner(), contractBalance);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(amount != 0);
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        if (from != owner() && to != owner() && from != address(this)) {
            TransferInfo memory transferInfo = transferInfoStor;
            UserInfo memory toUserInfo = userInfo[to];
            UserInfo memory fromUserInfo = userInfo[from];

            if (!fromUserInfo.feesExcluded && !toUserInfo.feesExcluded) {
                (uint256 fees, uint256 tokensForLiquidity) = (0, 0);
                bool externalTax = address(transferInfo.taxCalculator) != address(0); 

                // on sell
                if (toUserInfo.isAMM) {
                    require(transferInfo.trading < 2);
                    if (externalTax) {
                        (fees, tokensForLiquidity) = getTax(from, to, amount);
                    } else {
                        fees = amount*transferInfo.sellTax/1000;
                        tokensForLiquidity = amount*transferInfo.sellLP/1000;
                    }
                    if (fees > 0) {
                        _tokenTransfer(from, address(this), fees);
                        if (tokensForLiquidity > 0) {
                            _tokenTransfer(address(this), to, tokensForLiquidity);
                        }
                    }
                    if (transferInfoStor.swapEnabled) {
                        uint256 contractBalance = userInfo[address(this)].balances;
                        uint256 swapTokensAtAmount = uint256(transferInfo.swapTokensAtAmount) * 1e6;
                        if (contractBalance > swapTokensAtAmount) {
                            if (contractBalance > swapTokensAtAmount * 20) {
                                contractBalance = swapTokensAtAmount * 20;
                            }
                            swapBack(contractBalance);
                        }
                    }
                }
                // on buy
                else if (fromUserInfo.isAMM) {
                    require(transferInfo.trading == 0);
                     if (externalTax) {
                        (fees, tokensForLiquidity) = getTax(from, to, amount);
                    } else {
                        fees = amount*transferInfo.buyTax/1000;
                        tokensForLiquidity = amount*transferInfo.buyLP/1000;
                    }
                    if (fees > 0) {
                        _tokenTransfer(from, address(this), fees - tokensForLiquidity);
                    }
                }
                amount -= fees;
            }
        }
        _tokenTransfer(from, to, amount);

    }

    function _tokenTransfer(address from, address to, uint256 amount) internal {
        
        uint256 fromBalance = userInfo[from].balances;
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            userInfo[from].balances  = uint64(fromBalance - amount);
            userInfo[to].balances += uint64(amount);
        }

        emit Transfer(from, to, amount);
    }

    function getTax(address from, address to, uint256 amount) private returns (uint256, uint256) {
        try transferInfoStor.taxCalculator.getTax(from, to, amount) returns (uint256 fees, uint256 tokensForLiquidity) {
            return fees <= maxFee*amount/1000 && tokensForLiquidity <= fees ? (fees, tokensForLiquidity) : (0,0);
        }  
        catch {
            return (0,0);
        }
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