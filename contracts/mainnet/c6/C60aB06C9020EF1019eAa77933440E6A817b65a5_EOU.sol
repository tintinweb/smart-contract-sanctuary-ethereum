/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract EOU is Context, IERC20, Ownable {
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFees;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;

    string private _name     = "Exodus Our Universe";
    string private _symbol   = "EOU";  
    uint8  private _decimals = 18;
   
    uint256 private constant MAX = type(uint256).max;
    uint256 private _tTotal = 100_000_000 * (10 ** _decimals);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    uint256 public taxCap = 10;

    uint256 public reflectionFee = 1;
    uint256 private _previousReflectionFee = reflectionFee;
    
    uint256 public liquidityFee = 2;
    uint256 private _previousLiquidityFee = liquidityFee;

    uint256 public marketingFee = 2;
    uint256 private _previousMarketingFee = marketingFee;

    uint256 public developmentFee = 5;
    uint256 private _previousDevelopmentFee = developmentFee;

    address public marketingWallet = 0x0000000000000000000000000000000000000000;
    address public liquidityWallet = 0x0000000000000000000000000000000000000000;
    address public developmentWallet = 0x0000000000000000000000000000000000000000;

    event ExcludeFromFees(address indexed account, bool isExcluded);
    event MarketingWalletChanged(address marketingWallet);
    event LiquidityWalletChanged(address liquidityWallet);
    event DevelopmentWalletChanged(address developmentWallet);
    event ReflectionFeeChanged(uint256 reflectionFee);
    event LiquidityFeeChanged(uint256 liquidityFee);
    event MarketingFeeChanged(uint256 marketingFee);
    event DevelopmentFeeChanged(uint256 developmentFee);
    event TaxCapChanged(uint256 taxCap);
    
    constructor() { 
        _isExcludedFromFees[owner()] = true;
        _isExcludedFromFees[marketingWallet] = true;
        _isExcludedFromFees[liquidityWallet] = true;
        _isExcludedFromFees[developmentWallet] = true;
        _isExcludedFromFees[address(this)] = true;

        _rOwned[owner()] = _rTotal;
        emit Transfer(address(0), owner(), _tTotal);
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
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    // This function returns the amount of tokens that a spender is allowed to spend on behalf of an owner
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    // This function allows a spender to spend tokens on behalf of the caller, up to the approved amount.
    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    // This function transfers tokens from the sender's address to the recipient's address on 
    // the condition that the sender has previously been approved to spend the required amount of tokens.
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    // This function increases the amount of tokens that a spender is allowed to spend on behalf of the caller.
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    // This function decreases the amount of tokens that a spender is allowed to spend on behalf of the caller.
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }

    // This function returns a boolean indicating whether an account is excluded from receiving rewards.
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    // This function returns the total amount of reflections distributed as a result of token transfers.
    function totalReflectionDistributed() public view returns (uint256) {
        return _tFeeTotal;
    }

    // This is a public view function that calculates and returns the corresponding token amount for a 
    // given reflection amount rAmount. Reflections are a technique used by some tokens to calculate rewards 
    // and fees, and this function converts them back to their equivalent token amount.
    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount / currentRate;
    }

    // This is a public function that allows the owner of the contract to exclude an address account from 
    // receiving rewards for holding the token. If the address is not already excluded, the function sets 
    // _isExcluded[account] to true and adds it to the _excluded array. If the address already owns some tokens, 
    // it calculates the token amount based on the reflection balance and sets 
    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    // This is a public function that allows the owner of the contract to include an address account in receiving 
    // rewards for holding the token. If the address is already excluded, the function sets _isExcluded[account] 
    // to false and removes it from the _excluded array. If the address was previously excluded, it sets 
    // _tOwned[account] to 0.
    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already included");
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

    // This is a private function that handles the reflection fee mechanism. It reduces the total reflection 
    // supply _rTotal by rFee and increases the total fee _tFeeTotal by tFee.
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    // This is a private function that approves a spender spender to transfer tokens on behalf of the owner 
    // owner up to a certain amount amount.
    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    // This is a private function that transfers tokens from the from address to the to address, and handles 
    // the associated fees and liquidity. If either address is excluded from fees, it temporarily removes all 
    // fees before executing the transfer, and restores the fees afterward. It then calls one of several 
    // different transfer functions based on the combination of excluded or included status of the sender and 
    // recipient address.
    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        bool restoreFees = false;

        if (_isExcludedFromFees[from] || 
            _isExcludedFromFees[to]
        ) {
            removeAllFee();
            restoreFees = true;
        }

        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, amount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, amount);
        } else if (!_isExcluded[from] && !_isExcluded[to]) {
            _transferStandard(from, to, amount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, amount);
        } else {
            _transferStandard(from, to, amount);
        }

        if (restoreFees) {
            restoreAllFee();
        }
    }

    // This is a private function that transfers tokens between two non-excluded addresses, 
    // and calculates the reflection and token fees.
    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDevelopment) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeMarketing(sender, tMarketing);
        _takeLiquidity(sender, tLiquidity);
        _takeDevelopment(sender, tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // This is a private function that transfers tokens from a non-excluded address to an 
    // excluded address, and calculates the reflection and token fees.
    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDevelopment) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeMarketing(sender, tMarketing);           
        _takeLiquidity(sender, tLiquidity);
        _takeDevelopment(sender, tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // This is a private function that transfers tokens from an excluded address to a non-excluded 
    // address, and calculates the reflection and token fees.
    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDevelopment) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount; 
        _takeMarketing(sender, tMarketing);  
        _takeLiquidity(sender, tLiquidity);
        _takeDevelopment(sender, tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // This is a private function that transfers tokens between two excluded addresses, and calculates 
    // the reflection and token fees.
    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDevelopment) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeMarketing(sender, tMarketing);        
        _takeLiquidity(sender, tLiquidity);
        _takeDevelopment(sender, tDevelopment);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    // This is a private view function that calculates and returns the reflection and token values 
    // for a given token amount tAmount.
    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tMarketing, uint256 tDevelopment) = _getTValues(tAmount);
        uint256[3] memory rValues = _getRValues(tAmount, [tFee, tLiquidity, tMarketing, tDevelopment, _getRate()]);
        return (rValues[0], rValues[1], rValues[2], tTransferAmount, tFee, tLiquidity, tMarketing, tDevelopment);
    }

    // This is a private view function that calculates and returns the token values for a given 
    // token amount tAmount, including the fees for reflection, liquidity, marketing, and development.
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = tAmount * reflectionFee / 100;
        uint256 tLiquidity = tAmount * liquidityFee / 100;
        uint256 tMarketing = tAmount * marketingFee / 100;
        uint256 tDevelopment = tAmount * developmentFee / 100;
        uint256 tTransferAmount = tAmount - tFee - tLiquidity - tMarketing - tDevelopment;
        return (tTransferAmount, tFee, tLiquidity, tMarketing, tDevelopment);
    }

    // This is a private pure function that calculates and returns the reflection values for a 
    // given token amount tAmount and token fee values. It takes
    function _getRValues(uint256 tAmount, uint256[5] memory tValues) private pure returns (uint256[3] memory) {
        uint256 rAmount = tAmount * tValues[4];
        uint256 rFee = tValues[0] * tValues[4];
        uint256 rLiquidity = tValues[1] * tValues[4];
        uint256 rMarketing = tValues[2] * tValues[4];
        uint256 rDevelopment = tValues[3] * tValues[4];
        uint256 rTransferAmount = rAmount - rFee - rLiquidity - rMarketing - rDevelopment;
        return [rAmount, rTransferAmount, rFee];
    }

    // returns the current conversion rate between the reflection token and the total token supply.
    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    // calculates the current reflection and total supply of the token. It does this by initializing 
    // the reflection supply to the total reflection supply and the total supply to the total token 
    // supply. It then iterates through all excluded addresses and subtracts their reflection and token 
    // balances from the respective supplies. If the reflection or token balance of any excluded address 
    // is greater than the current reflection or token supply, the function returns the total reflection 
    // and token supply. If the reflection supply is less than the total reflection supply divided by the 
    // total token supply, the function also returns the total reflection and token supply. Otherwise, it 
    // returns the current reflection and token supply.
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
    
    // This function is used to take a portion of the transaction amount (specified by tLiquidity) as 
    // a liquidity fee and transfer it to a designated liquidity wallet. The amount is converted to 
    // reflection tokens and added to the balance of the liquidity wallet.
    function _takeLiquidity(address sender, uint256 tLiquidity) private {
        if (tLiquidity > 0) {
            uint256 currentRate =  _getRate();
            uint256 rLiquidity = tLiquidity * currentRate;

            _rOwned[liquidityWallet] = _rOwned[liquidityWallet] + rLiquidity;

            if(_isExcluded[liquidityWallet]) {
                _tOwned[liquidityWallet] = _tOwned[liquidityWallet] + tLiquidity;
            }

            emit Transfer(sender, liquidityWallet, tLiquidity);
        }
    }

    // This function is used to take a portion of the transaction amount (specified by tMarketing) as 
    // a marketing fee and transfer it to a designated marketing wallet. The amount is converted to 
    // reflection tokens and added to the balance of the marketing wallet.
    function _takeMarketing(address sender, uint256 tMarketing) private {
        if (tMarketing > 0) {
            uint256 currentRate =  _getRate();
            uint256 rMarketing = tMarketing * currentRate;

            _rOwned[marketingWallet] = _rOwned[marketingWallet] + rMarketing;

            if(_isExcluded[marketingWallet]) {
                _tOwned[marketingWallet] = _tOwned[marketingWallet] + tMarketing;
            }

            emit Transfer(sender, marketingWallet, tMarketing);
        }
    }

    // This function is used to take a portion of the transaction amount (specified by tDevelopment) as 
    // a development fee and transfer it to a designated development wallet. The amount is converted to 
    // reflection tokens and added to the balance of the development wallet.
    function _takeDevelopment(address sender, uint256 tDevelopment) private {
        if (tDevelopment > 0) {
            uint256 currentRate =  _getRate();
            uint256 rDevelopment = tDevelopment * currentRate;

            _rOwned[developmentWallet] = _rOwned[developmentWallet] + rDevelopment;

            if(_isExcluded[developmentWallet]) {
                _tOwned[developmentWallet] = _tOwned[developmentWallet] + tDevelopment;
            }

            emit Transfer(sender, developmentWallet, tDevelopment);
        }
    }
    
    // This function is used to set all fees (reflectionFee, liquidityFee, marketingFee, and developmentFee) to zero.
    function removeAllFee() private {
        _previousReflectionFee  = reflectionFee;
        _previousLiquidityFee   = liquidityFee;
        _previousMarketingFee   = marketingFee;
        _previousDevelopmentFee = developmentFee;
        
        reflectionFee  = 0;
        marketingFee   = 0;
        liquidityFee   = 0;
        developmentFee = 0;
    }
    
    // This function is used to restore the previous values of fees that were saved by removeAllFee().
    function restoreAllFee() private {
       reflectionFee  = _previousReflectionFee;
       liquidityFee   = _previousLiquidityFee;
       marketingFee   = _previousMarketingFee;
       developmentFee = _previousDevelopmentFee;
    }

    // This function is used to exclude an account from being charged any fees.
    function excludeFromFees(address account, bool excluded) external onlyOwner {
        require(_isExcludedFromFees[account] != excluded, "Account is already the value of 'excluded'");
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    // This function is used to check if an account is excluded from being charged any fees.
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFees[account];
    }
    
    // This function is used to change the address of the marketing wallet.
    function changeMarketingWallet(address _marketingWallet) external onlyOwner {
        require(_marketingWallet != marketingWallet, "Marketing wallet is already that address");
        require(_marketingWallet != address(0), "Marketing wallet cannot be the zero address");
        marketingWallet = _marketingWallet;
        emit MarketingWalletChanged(marketingWallet);
    }

    // This function is used to change the address of the liquidity wallet.
    function changeLiquidityWallet(address _liquidityWallet) external onlyOwner {
        require(_liquidityWallet != liquidityWallet, "Liquidity wallet is already that address");
        require(_liquidityWallet != address(0), "Liquidity wallet cannot be the zero address");
        liquidityWallet = _liquidityWallet;
        emit LiquidityWalletChanged(liquidityWallet);
    }

    // This function is used to change the address of the development wallet.
    function changeDevelopmentWallet(address _developmentWallet) external onlyOwner {
        require(_developmentWallet != developmentWallet, "Development wallet is already that address");
        require(_developmentWallet != address(0), "Development wallet cannot be the zero address");
        developmentWallet = _developmentWallet;
        emit DevelopmentWalletChanged(developmentWallet);
    }

    // This function is used to set the percentage of the transaction amount that will be 
    // charged as a reflection fee.
    function setReflectionFeePercent(uint256 _reflectionFee) external onlyOwner() {
        reflectionFee = _reflectionFee;
        require(reflectionFee + marketingFee + liquidityFee + developmentFee <= taxCap, "Fees cannot be more than 10%");
        emit ReflectionFeeChanged(reflectionFee);
    }

    // This function is used to set the percentage of the transaction amount that will be 
    // charged as a marketing fee.
    function setMarketingFeePercent(uint256 _marketing) external onlyOwner {
        marketingFee = _marketing;
        require(reflectionFee + marketingFee + liquidityFee + developmentFee <= taxCap, "Fee total cannot exceed tax cap");
        emit MarketingFeeChanged(marketingFee);
    }
    
    // This function is used to set the percentage of the transaction amount that will be 
    // charged as a liquidity fee.
    function setLiquidityFeePercent(uint256 _liquidityFee) external onlyOwner() {
        liquidityFee = _liquidityFee;
        require(reflectionFee + marketingFee + liquidityFee + developmentFee <= taxCap, "Fee total cannot exceed tax cap");
        emit LiquidityFeeChanged(liquidityFee);
    }

    // This function is used to set the percentage of the transaction amount that will be 
    // charged as a development fee.
    function setDevelopmentFeePercent(uint256 _developmentFee) external onlyOwner() {
        developmentFee = _developmentFee;
        require(reflectionFee + marketingFee + liquidityFee + developmentFee <= taxCap, "Fee total cannot exceed tax cap");
        emit DevelopmentFeeChanged(developmentFee);
    }

    // This function is used to set a maximum percentage of the total transaction amount 
    // that can be charged as fees.
    function setTaxCap(uint _newCap) external onlyOwner() {
        require(_newCap < taxCap, "Tax cap only can be decreased");
        taxCap = _newCap;
        emit TaxCapChanged(taxCap);
    }

    // This function is used to transfer any tokens that are currently stuck in the contract 
    // back to the owner of the contract. This is useful in case tokens were accidentally sent 
    // to the contract address instead of the owner's address.
    function claimStuckTokens(address token) external onlyOwner {
        IERC20 ERC20token = IERC20(token);
        uint256 balance = ERC20token.balanceOf(address(this));
        ERC20token.transfer(msg.sender, balance);
    }
}