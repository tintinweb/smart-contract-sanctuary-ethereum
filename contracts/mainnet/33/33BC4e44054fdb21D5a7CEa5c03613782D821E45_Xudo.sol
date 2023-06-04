/**
 *Submitted for verification at Etherscan.io on 2023-06-04
*/

/**
* Website: https://xudo.io
* Twitter: https://twitter.com/xudoio
* Telegram: https://t.me/xudoportal
*/

// SPDX-License-Identifier: MIT
pragma solidity =0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory {
    function createPair(
        address tokenA,
        address tokenB
    ) external returns (address pair);
}

interface IRouter {
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
        returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

library Address {
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }
}

contract Xudo is Context, IERC20, Ownable {
    using Address for address payable;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    address[] private _excluded;

    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 18;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 100_000_000 * 10 ** _decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    address public marketingWallet = 0x462b599CD0273F1e3445e81E56eCa1A8E4e7B6D5;

    string private constant _name = "Xudo";
    string private constant _symbol = "XUDO";

    struct Taxes {
        uint256 rfi;
        uint256 marketing;
    }

    Taxes public buyTax = Taxes(1, 4);
    Taxes public sellTax = Taxes(1, 4);

    struct TotFeesPaidStruct {
        uint256 rfi;
        uint256 marketing;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues {
        uint256 rAmount;
        uint256 rTransferAmount;
        uint256 rRfi;
        uint256 rMarketing;
        uint256 tTransferAmount;
        uint256 tRfi;
        uint256 tMarketing;
    }

    modifier lockTheSwap() {
        swapping = true;
        _;
        swapping = false;
    }

    constructor() {
        address routerAddress;
        if (block.chainid == 56) {
            routerAddress = 0x10ED43C718714eb63d5aA57B78B54704E256024E; // BSC Pancake Mainnet Router
        } else if (block.chainid == 97) {
            routerAddress = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1; // BSC Pancake Testnet Router
        } else if (block.chainid == 1 || block.chainid == 5) {
            routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D; // ETH Uniswap Mainnet % Testnet
        } else {
            revert();
        }

        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory()).createPair(
            address(this),
            _router.WETH()
        );

        router = _router;
        pair = _pair;

        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[marketingWallet] = true;
        _isExcludedFromFee[
            address(0x462b599CD0273F1e3445e81E56eCa1A8E4e7B6D5)
        ] = true;
        emit Transfer(address(0), owner(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function allowance(
        address owner,
        address spender
    ) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public returns (bool) {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function transfer(
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function tokenFromReflection(
        uint256 rAmount
    ) public view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function setBuyTax(
        uint256 _reflection,
        uint256 _marketing
    ) external onlyOwner {
        require(
            buyTax.rfi != _reflection || buyTax.marketing != _marketing,
            "Tax already that amount"
        );

        require(
            _reflection + _marketing <= 25,
            "Tax cannot be more than 25 percent"
        );

        buyTax.rfi = _reflection;
        buyTax.marketing = _marketing;
    }

    function setSellTax(
        uint256 _reflection,
        uint256 _marketing
    ) external onlyOwner {
        require(
            sellTax.rfi != _reflection || sellTax.marketing != _marketing,
            "Tax already that amount"
        );

        require(
            _reflection + _marketing <= 25,
            "Tax cannot be more than 25 percent"
        );

        sellTax.rfi = _reflection;
        sellTax.marketing = _marketing;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is not excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -= rRfi;
        totFeesPaid.rfi += tRfi;
    }

    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing += tMarketing;

        if (_isExcluded[address(marketingWallet)]) {
            _tOwned[address(marketingWallet)] += tMarketing;
        }
        _rOwned[address(marketingWallet)] += rMarketing;
    }

    function _getValues(
        uint256 tAmount,
        bool takeFee,
        address sender,
        address recipient
    ) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee, sender, recipient);
        (
            to_return.rAmount,
            to_return.rTransferAmount,
            to_return.rRfi,
            to_return.rMarketing
        ) = _getRValues(to_return, tAmount, takeFee, _getRate());

        return to_return;
    }

    function _getTValues(
        uint256 tAmount,
        bool takeFee,
        address sender,
        address recipient
    ) private view returns (valuesFromGetValues memory s) {
        if (!takeFee) {
            s.tTransferAmount = tAmount;
            return s;
        }

        if (sender == address(pair)) {
            s.tRfi = (tAmount * buyTax.rfi) / 100;
            s.tMarketing = (tAmount * buyTax.marketing) / 100;
            s.tTransferAmount = tAmount - s.tRfi - s.tMarketing;
            return s;
        } else if (recipient == address(pair)) {
            s.tRfi = (tAmount * sellTax.rfi) / 100;
            s.tMarketing = (tAmount * sellTax.marketing) / 100;
            s.tTransferAmount = tAmount - s.tRfi - s.tMarketing;
            return s;
        } else {
            s.tTransferAmount = tAmount;
            return s;
        }
    }

    function _getRValues(
        valuesFromGetValues memory s,
        uint256 tAmount,
        bool takeFee,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rRfi,
            uint256 rMarketing
        )
    {
        rAmount = tAmount * currentRate;

        if (!takeFee) {
            return (rAmount, rAmount, 0, 0);
        }

        rRfi = s.tRfi * currentRate;
        rMarketing = s.tMarketing * currentRate;
        rTransferAmount = rAmount - rRfi - rMarketing;
        return (rAmount, rTransferAmount, rRfi, rMarketing);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= balanceOf(from),
            "You are trying to transfer more than your balance"
        );

        bool takeFee = true;
        if (
            swapping ||
            _isExcludedFromFee[from] ||
            _isExcludedFromFee[to] ||
            (from != address(pair) && to != address(pair))
        ) takeFee = false;

        if (takeFee) {
            if (from == address(pair) && buyTax.rfi + buyTax.marketing == 0) {
                takeFee = false;
            } else if (
                to == address(pair) && sellTax.rfi + sellTax.marketing == 0
            ) {
                takeFee = false;
            }
        }

        _tokenTransfer(from, to, amount, takeFee);
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 tAmount,
        bool takeFee
    ) private {
        valuesFromGetValues memory s = _getValues(
            tAmount,
            takeFee,
            sender,
            recipient
        );

        if (_isExcluded[sender]) {
            //from excluded
            _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) {
            //to excluded
            _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender] - s.rAmount;
        _rOwned[recipient] = _rOwned[recipient] + s.rTransferAmount;

        if (s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);
        if (s.rMarketing > 0 || s.tMarketing > 0)
            _takeMarketing(s.rMarketing, s.tMarketing);
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function bulkExcludeFee(
        address[] memory accounts,
        bool state
    ) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = state;
        }
    }

    function updateMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Fee address cannot be zero address");
        marketingWallet = newWallet;
    }

    function rescueWETH(uint256 weiAmount) external onlyOwner {
        require(address(this).balance >= weiAmount, "Insufficient ETH balance");
        payable(msg.sender).transfer(weiAmount);
    }

    function rescueAnyERC20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable {}
}