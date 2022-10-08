/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

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

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

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
}

contract TEST is Context, IERC20, Ownable {

    using SafeMath for uint256;

    string private constant _nomen = "TEST";
    string private constant _symbolum = "TST";
    uint8 private constant _decimales = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allocacionibus;
    mapping(address => bool) private _excluditurFeodum;
    uint256 private constant MAXIMUM = ~uint256(0);
    uint256 private constant _tTotus = 100000000 * 10**9;
    uint256 private _rTotus = (MAXIMUM - (MAXIMUM % _tTotus));
    uint256 private _tFeeTotus;
    uint256 private _tributumInEmptio = 6;
    uint256 private _tributumInVenditionis = 6;

    //Originale Tributum
    uint256 private _tributumFeodo = _tributumInVenditionis;
    uint256 private _praeviusTributumFeodo = _tributumFeodo;

    mapping(address => bool) public bots;
    address payable private _tributumPera = payable(0x3389d34B6c344e13717a9eB56df61f5c8FB90bA8);
    address payable private _venaliciumPera = payable(0x3389d34B6c344e13717a9eB56df61f5c8FB90bA8);

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    bool private negotiationeAperta = true;
    bool private inMutatio = false;
    bool private mutareOn = true;

    uint256 public _maximumNegotiumMagnitudine = 1000000 * 10**9;
    uint256 public _maximumPeraMagnitudine = 2000000 * 10**9;
    uint256 public _mutarePecuniamAtAmount = 10000 * 10**9;

    event MaximumNegotiumMagnitudineMutatum(uint256 _maximumNegotiumMagnitudine);
    modifier claudeMutationem {
        inMutatio = true;
        _;
        inMutatio = false;
    }

    constructor() {

        _rOwned[_msgSender()] = _rTotus;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _excluditurFeodum[owner()] = true;
        _excluditurFeodum[address(this)] = true;
        _excluditurFeodum[_tributumPera] = true;
        _excluditurFeodum[_venaliciumPera] = true;

        emit Transfer(address(0), _msgSender(), _tTotus);
    }

    function name() public pure returns (string memory) {
        return _nomen;
    }

    function symbol() public pure returns (string memory) {
        return _symbolum;
    }

    function decimals() public pure returns (uint8) {
        return _decimales;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotus;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allocacionibus[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allocacionibus[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function tokenFromReflection(uint256 rQuantitas)
        private
        view
        returns (uint256)
    {
        require(
            rQuantitas <= _rTotus,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rQuantitas.div(currentRate);
    }

    function removereOmniaTributa() private {
        if (_tributumFeodo == 0) return;

        _praeviusTributumFeodo = _tributumFeodo;

        _tributumFeodo = 0;
    }

    function restituetOmniaTributa() private {
        _tributumFeodo = _praeviusTributumFeodo;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allocacionibus[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {

            //Trade start check
            if (!negotiationeAperta) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }

            require(amount <= _maximumNegotiumMagnitudine, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");

            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maximumPeraMagnitudine, "TOKEN: Balance exceeds wallet size!");
            }

            uint256 contractusPecuniaeStatera = balanceOf(address(this));
            bool potestMutare = contractusPecuniaeStatera >= _mutarePecuniamAtAmount;

            if(contractusPecuniaeStatera >= _maximumNegotiumMagnitudine)
            {
                contractusPecuniaeStatera = _maximumNegotiumMagnitudine;
            }

            if (potestMutare && !inMutatio && from != uniswapV2Pair && mutareOn && !_excluditurFeodum[from] && !_excluditurFeodum[to]) {
                permutoPecuniamETH(contractusPecuniaeStatera);
                uint256 contractusETHStatera = address(this).balance;
                if (contractusETHStatera > 0) {
                    mittereETHAdTributum(address(this).balance);
                }
            }
        }

        bool accipereTributum = true;

        //Transfer pecuniam
        if ((_excluditurFeodum[from] || _excluditurFeodum[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            accipereTributum = false;
        } else {

            //Set tributum pro emptionibus
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _tributumFeodo = _tributumInEmptio;
            }

            //Set tributum pro venditionibus
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _tributumFeodo = _tributumInVenditionis;
            }

        }

        _tokenTransfer(from, to, amount, accipereTributum);
    }

    function permutoPecuniamETH(uint256 pecuniaMoles) private claudeMutationem {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), pecuniaMoles);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            pecuniaMoles,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function mittereETHAdTributum(uint256 amount) private {
        _venaliciumPera.transfer(amount);
    }

    function setNegotiatione(bool _negotiationeAperta) public onlyOwner {
        negotiationeAperta = _negotiationeAperta;
    }

    function manualMutatio() external {
        require(_msgSender() == _tributumPera || _msgSender() == _venaliciumPera);
        uint256 contractusStatera = balanceOf(address(this));
        permutoPecuniamETH(contractusStatera);
    }

    function manualMittere() external {
        require(_msgSender() == _tributumPera || _msgSender() == _venaliciumPera);
        uint256 contractusETHStatera = address(this).balance;
        mittereETHAdTributum(contractusETHStatera);
    }

    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool accipereTributum
    ) private {
        if (!accipereTributum) removereOmniaTributa();
        _transferStandard(sender, recipient, amount);
        if (!accipereTributum) restituetOmniaTributa();
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rQuantitas,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tTeam
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rQuantitas);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotus = _rTotus.sub(rFee);
        _tFeeTotus = _tFeeTotus.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _tributumFeodo);
        uint256 currentRate = _getRate();
        (uint256 rQuantitas, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rQuantitas, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 tributumFeodo
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(0).div(100);
        uint256 tTeam = tAmount.mul(tributumFeodo).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rQuantitas = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rQuantitas.sub(rFee).sub(rTeam);
        return (rQuantitas, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotus;
        uint256 tSupply = _tTotus;
        if (rSupply < _rTotus.div(_tTotus)) return (_rTotus, _tTotus);
        return (rSupply, tSupply);
    }

    function setFee(uint256 tributumInEmptio, uint256 tributumInVenditionis) public onlyOwner {
        _tributumInEmptio = tributumInEmptio;
        _tributumInVenditionis = tributumInVenditionis;
    }

    //Posuit limen minimum mutare pecuniam.
    function posuitLimenMinimumMutarePecuniam(uint256 mutarePecuniamAtAmount) public onlyOwner {
        _mutarePecuniamAtAmount = mutarePecuniamAtAmount;
    }

    //Set minimam pecuniam requiratur ad mutationem.
    function toggleSwap(bool _mutareOn) public onlyOwner {
        mutareOn = _mutareOn;
    }

    //Set maximum transaction moles.
    function setMaximumNegotiumMoles(uint256 maxTxMoles) public onlyOwner {
        _maximumNegotiumMagnitudine = maxTxMoles;
    }

    function setMaxPeraMagnitudine(uint256 maxPeraMagnitudine) public onlyOwner {
        _maximumPeraMagnitudine = maxPeraMagnitudine;
    }

    function pluresSacculosExFeodisExcludere(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _excluditurFeodum[accounts[i]] = excluded;
        }
    }

}