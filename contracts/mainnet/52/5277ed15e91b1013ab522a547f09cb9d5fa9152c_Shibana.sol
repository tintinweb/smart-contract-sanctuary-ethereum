/**
 *Submitted for verification at Etherscan.io on 2022-05-08
*/

// SPDX-License-Identifier: MIT

/*

    Shibana - DAO Empowered Charity

Telegram: https://t.me/ShibanaDAO
Twitter: https://twitter.com/shibanadao 
Website: https://shibanadao.com/

*/

pragma solidity ^0.8.13;


library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

     

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Ownable {
    address private _owner;
    address private _previousOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router {
    function factory() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract Shibana is IERC20, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping (address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;

    mapping(address => bool) public botWallets;

    address[] private _excluded;
    
    using EnumerableSet for EnumerableSet.AddressSet;
    EnumerableSet.AddressSet electedCouncil;

    address constant public ZERO = address(0x0);
 
    address public DAOcandidate;
    uint256 public DAOcandidateScore;
    mapping(address => uint256) public DAOwinningBuy;
    
    uint256 public timeLastDAOcandidate;    
    uint256 public DAOcandidateRoundDuration = 6 hours;    
    uint256 public totalDAOrewards;
    
    uint256 public launchBlock;
   
    uint256 public constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 69_000_000 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    
    address public autoLiquidityReceiver = 0x96c8dB3284948011FFE230d669c2e2Ab3A103Ef0;
    address public treasuryAddress = 0x506F5D1c3E403d234c9Df98Cb3a79F2fbCC905d1;
	address public developmentAddress = msg.sender;

    address private constant USDCaddress = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address private constant WETHaddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    uint256 public charityFunds;
    uint256 public treasuryFunds;
    uint256 private developmentFunds;

    string private constant _name = "Shibana";
    string private constant _symbol = "SHIBANA";
    uint8 private constant _decimals = 9;
    
    uint256 public _taxFee = 3;
    uint256 private _previousTaxFee = _taxFee;
   
    uint256 public _liquidityFee = 9;
    uint256 private _previousLiquidityFee = _liquidityFee;

    IUniswapV2Router public constant uniswapV2Router = IUniswapV2Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); //Mainnet & Testnet ETH;
    address public uniswapV2Pair;
     
    bool inSwapAndLiquify;
    
    uint256 public walletRestrictionAmount; // max token transaction and wallet amount
    uint256 public constant MIN_WALLETRESTRICTION_AMOUNT = 3 * _tTotal / 200; // 1.5% 
 
    uint256 public numTokensSellToAddToLiquidity =  _tTotal / 200; // 0.5...%
    
    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event V1Airdrop(address indexed sender, uint256 indexed totalAirdroppedTokens);
    
    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }
    
    constructor() {
        _rOwned[msg.sender] = _rTotal;
        
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;      
        
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        uint256 _allowance = _allowances[sender][msg.sender];
        _approve(sender, msg.sender, _allowance - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        uint256 _allowance = _allowances[msg.sender][spender];
        _approve(msg.sender, spender, _allowance - subtractedValue);
        return true;
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }
    
    function deliver(uint256 tAmount) external {
        require(!_isExcluded[ msg.sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[ msg.sender] = _rOwned[ msg.sender]  - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) external view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    function excludeFromReward(address account) external onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
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

    function isExcludedFromReward(address account) external view returns (bool) {
        return _isExcluded[account];
    }

    function excludeFromFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) external onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapThresholdAmount(uint256 _numTokensSellToAddToLiquidity) external onlyOwner {
        require(_numTokensSellToAddToLiquidity >= _tTotal / 1000, "[0.1,MAXUINT_256] % supply)");
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }
    
    function claimStuckTokens(address tokenAddress, address walletaddress) external onlyOwner {
        require(tokenAddress != address(this));
        IERC20 token = IERC20(tokenAddress);
        token.transfer(walletaddress, token.balanceOf(address(this)));
    }
    
    function claimStuckBalance(address payable walletaddress) external onlyOwner {
        walletaddress.transfer(address(this).balance - charityFunds - developmentFunds - treasuryFunds);
    }
    
    function addBotWallet(address botwallet) external onlyOwner {
        require(block.number <= launchBlock + 60, "Antibot only first 60 blocks");
        botWallets[botwallet] = true;
    }
    
    function removeBotWallet(address botwallet) external onlyOwner {
        botWallets[botwallet] = false;
    }
    
    function allowtrading() payable external onlyOwner() {
        require(walletRestrictionAmount < MIN_WALLETRESTRICTION_AMOUNT, "Launched");
        walletRestrictionAmount = MIN_WALLETRESTRICTION_AMOUNT;

        uint256 liquidityAmount = (balanceOf(msg.sender) - 5 * _tTotal / 100) * _getRate();
        _rOwned[msg.sender] -= liquidityAmount;
        _rOwned[address(this)] += liquidityAmount;
        emit Transfer(msg.sender, address(this), tokenFromReflection(liquidityAmount));

        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory())
            .createPair(address(this), WETHaddress); 
            
        _approve(address(this), address(uniswapV2Router), MAX);
        uniswapV2Router.addLiquidityETH{value: msg.value}(
            address(this),
            tokenFromReflection(liquidityAmount),
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );

        launchBlock = block.number;        
    }    

    function setWalletRestrictionAmount(uint256 _walletRestrictionAmount) external onlyOwner {
        require(_walletRestrictionAmount >= MIN_WALLETRESTRICTION_AMOUNT, "[1.5, MAXUINT_256] %");
        walletRestrictionAmount = _walletRestrictionAmount;
    }

    function setFeeReceivers(address _treasuryAddress, address _developmentAddress) external onlyOwner {
        treasuryAddress = _treasuryAddress;
        developmentAddress = _developmentAddress;
    }

    function setDAOcandidateRoundDuration(uint256 _roundDurationHours) external onlyOwner {
        require(_roundDurationHours >= 6);
        DAOcandidateRoundDuration = _roundDurationHours * 1 hours;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount - tFee - tLiquidity;
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) 
            private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rLiquidity;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }
    
    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();        

        uint256 contractTokens = 7 * tLiquidity / 9;
        tLiquidity -= contractTokens;

        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[autoLiquidityReceiver] = _rOwned[autoLiquidityReceiver] + rLiquidity;
        if(_isExcluded[autoLiquidityReceiver])
            _tOwned[autoLiquidityReceiver] = _tOwned[autoLiquidityReceiver] + tLiquidity;

        rLiquidity = contractTokens * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + contractTokens;
    }
    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount * _taxFee / 10**2;
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount * _liquidityFee / 10**2;
    }
    
    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0) return;
        
        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        
        _taxFee = 0;
        _liquidityFee = 0;
    }
    
    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
    }
    
    function isExcludedFromFee(address account) external view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
  
    function _transfer(address from, address to, uint256 amount) private {
        require(amount > 0, "Transfer more than 0");
        require(!botWallets[from], "No bots");        

        bool takeFee = true;
        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takeFee = false;
        }
        else{
            uint256 _walletRestrictionAmount = walletRestrictionAmount;
            require(_walletRestrictionAmount >= MIN_WALLETRESTRICTION_AMOUNT, "Launching");
            //Limits in effect
            if(_walletRestrictionAmount < MAX){    
                require(amount <= _walletRestrictionAmount && 
               (to == uniswapV2Pair || (balanceOf(to) + amount <= _walletRestrictionAmount)), "maxTx/maxWallet");                      
            }
        }

        if(takeFee){
            address _DAOcandidate = DAOcandidate;
            if(from == uniswapV2Pair){
                address[] memory path = new address[](2);
                path[0] = WETHaddress;
                path[1] = address(this);
                uint256 buyAmountETH = uniswapV2Router.getAmountsIn(amount, path)[0];                
                if(block.timestamp > timeLastDAOcandidate + DAOcandidateRoundDuration && _DAOcandidate != ZERO){
                    if(electedCouncil.contains(_DAOcandidate) == false){
                        electedCouncil.add(_DAOcandidate);
                    }                    
                    DAOwinningBuy[_DAOcandidate] = DAOcandidateScore;
                    DAOcandidateScore = 0;
                }
                if(buyAmountETH > DAOcandidateScore){                                    
                    if(_DAOcandidate != to){ 
                        DAOcandidate = to;
                    }
                    DAOcandidateScore = buyAmountETH;
                    timeLastDAOcandidate = block.timestamp;
                }
            }
            else{
                if(from == DAOcandidate){                       
                    DAOcandidate = ZERO;
                    DAOcandidateScore = 0;
                    timeLastDAOcandidate = block.timestamp;
                }
                else if(!inSwapAndLiquify){
                    uint256 _numTokensSellToAddToLiquidity = numTokensSellToAddToLiquidity;
                    if(balanceOf(autoLiquidityReceiver) >= _numTokensSellToAddToLiquidity){
                        addLiquidity(_numTokensSellToAddToLiquidity);
                    }
                    else if(balanceOf(address(this)) >= _numTokensSellToAddToLiquidity && _DAOcandidate != ZERO){
                        swapAndLiquify(_numTokensSellToAddToLiquidity);
                    }
                }                                
            }
        }
        _tokenTransfer(from,to,amount,takeFee);
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {

        uint256 oldBalance = address(this).balance;
        swapTokensForEth(tokenAmount); 
        uint256 swappedBalance = address(this).balance - oldBalance;

        treasuryFunds += swappedBalance * 3 / 7; 
		developmentFunds += swappedBalance / 7;
		charityFunds += swappedBalance * 2 / 7;
        uint256 DAOrewards = swappedBalance / 7;
        payable(DAOcandidate).transfer(DAOrewards);	 
        totalDAOrewards += DAOrewards;
    }

    function addLiquidity(uint256 tokenAmount) private lockTheSwap {
        uint256 rTransferAmount = tokenAmount * _getRate();
        _rOwned[autoLiquidityReceiver] -= rTransferAmount;
        _rOwned[address(this)] += rTransferAmount;
                
        uint256 amountToLiquify = tokenAmount / 2;
        uint256 amountToSwap = tokenAmount - amountToLiquify;

        uint256 balanceBefore = address(this).balance;
        swapTokensForEth(amountToSwap);
        uint256 amountETHLiquidity = address(this).balance - balanceBefore;

        if (amountToLiquify > 0 && amountETHLiquidity > 0) { 
            uniswapV2Router.addLiquidityETH{value: amountETHLiquidity}(
                address(this),
                amountToLiquify,
                0, // slippage is unavoidable
                0, // slippage is unavoidable
                owner(),
                block.timestamp
            );
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WETHaddress;

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function donateToCharity(address _charityAddress, uint256 _charityContribution) external onlyOwner {
        payable(_charityAddress).transfer(_charityContribution);		
        charityFunds -= _charityContribution;
    }
    
    function transferToTreasury() external {
        require(msg.sender == treasuryAddress || msg.sender == owner());
        payable(treasuryAddress).transfer(treasuryFunds);
        treasuryFunds -= treasuryFunds;
    }
    function viewTreasuryFunds() external view returns (uint256) {
        return treasuryFunds;
    }
    function transferToDevelopment() external {
        require(msg.sender == developmentAddress || msg.sender == owner());
        payable(developmentAddress).transfer(developmentFunds);
        developmentFunds -= developmentFunds;
    }
    function viewDevelopmentFunds() external view returns (uint256) {
        require(msg.sender == developmentAddress || msg.sender == owner());
        return developmentFunds;
    }

    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
        if(!takeFee)
            removeAllFee();
        
        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferStandard(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
        
        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, 
          uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, 
          uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;           
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, 
          uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;   
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, 
          uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;        
        _takeLiquidity(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function numDAOelected() external view returns (uint256) {
        return electedCouncil.length();
    }

    function viewDAOelected(uint256 index) external view returns (address) {
        return electedCouncil.at(index);
    }

    function estimatedUSD(uint256 amount) internal view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = USDCaddress;
        path[1] = WETHaddress; 
        return uniswapV2Router.getAmountsIn(amount, path)[0];
    }

    struct WalletData {
        uint256 tokenBalance;        
        uint256 DAOwinningBuy;        
    }

    struct TokenData {
        uint256 totalReflections;
        uint256 DAOcandidateRoundDuration;
        address DAOcandidate;
        uint256 DAOcandidateScore;
        uint256 timeLastDAOcandidate;
        uint256 numDAOmembers;
        uint256 totalDAOrewards;
        uint256 treasuryFunds;
        uint256 charityFunds;
        uint256 liquidityFunds;        
    }

    function fetchWalletData(address wallet) external view returns (WalletData memory) {
        return WalletData(balanceOf(wallet), DAOwinningBuy[wallet]);
    }

    function fetchBigDataA() external view returns (TokenData memory) {
        return TokenData(_tFeeTotal, DAOcandidateRoundDuration, DAOcandidate, 
            DAOcandidateScore, timeLastDAOcandidate, electedCouncil.length(), totalDAOrewards, 
            treasuryFunds, charityFunds, IERC20(WETHaddress).balanceOf(uniswapV2Pair));
    }
    function fetchBigDataB() external view returns (TokenData memory) {
        return TokenData(_tFeeTotal, DAOcandidateRoundDuration, DAOcandidate, 
            DAOcandidateScore, timeLastDAOcandidate, electedCouncil.length(), totalDAOrewards, 
            estimatedUSD(treasuryFunds), estimatedUSD(charityFunds), 
            estimatedUSD(IERC20(WETHaddress).balanceOf(uniswapV2Pair)));
    }
     
    function V1airdrop(address[] calldata wallets, uint256[] calldata airdropAmounts) external onlyOwner {
        uint256 airdroppedTokens;
        uint256 currentRate = _getRate();
        address sender = msg.sender;
        for(uint256 i = 0; i < wallets.length; i++){
            uint256 rAmount = airdropAmounts[i] * currentRate;
            _rOwned[wallets[i]] += rAmount;
            airdroppedTokens += rAmount;
            emit Transfer(sender, wallets[i], airdropAmounts[i]);
        }
        _rOwned[sender] -= airdroppedTokens;
        emit V1Airdrop(sender, airdroppedTokens);
    }

    receive() external payable {}
}