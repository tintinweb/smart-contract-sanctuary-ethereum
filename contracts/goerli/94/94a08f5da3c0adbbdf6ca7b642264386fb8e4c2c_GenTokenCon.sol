/**
 *Submitted for verification at Etherscan.io on 2022-08-15
*/

// SPDX-License-Identifier: MIT
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: GenToken.sol


pragma solidity 0.8.9;


interface IERC20 {
   
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)external returns (bool);
    function allowance(address owner, address spender)external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender,address recipient,uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
}


contract GenTokenCon is IERC20 {
    
    using SafeMath for uint256;
    // using Address for address;

    string private _name = "GenToken";
    string private _symbol = "GEN";
    uint8 private _decimals = 18;

    address public contractOwner;
    
    mapping(address => uint256) internal _reflectionBalance;
    mapping(address => uint256) internal _tokenBalance;
    mapping(address => mapping(address => uint256)) internal _allowances;
    
    uint256 private constant MAX = ~uint256(0);
    uint256 internal _tokenTotal = 200000 *10**18; //  200k totalSupply
    uint256 internal _reflectionTotal = (MAX - (MAX % _tokenTotal));
    
    mapping(address => bool) isExcludedFromFee;
    mapping(address => bool) internal _isExcluded;
    mapping(address => bool) public blackListed;
    address[] internal _excluded;
    
    uint256 public _arenaFee = 200; // 200 = 2.00%
    uint256 public _winnerFee = 100; // 100 = 1.00%
    uint256 public _burningFee = 200; // 200 = 2.0%
    uint256 public _lpFee = 400; // 400 = 4%
    uint256 public _insuranceFee = 400; // 400 = 4%
    uint256 public _treasuryFee = 200; // 200 = 2%
    uint256 public _referalFee = 100; // 100 = 1%
    uint256 public _selltreasuryFee = 300; // 300 = 3%
    uint256 public _sellinsuranceFee = 500; // 500 = 5%
    uint256 public _inbetweenFee_ = 4000; // 4000 = 40%

    uint256 public _maxTxAmount = 10000 * 10**18; // 10k inicial máx transfer
    
    uint256 public _arenaFeeTotal;
    uint256 public _winnerFeeTotal;
    uint256 public _burningFeeTotal;
    uint256 public _lpFeeTotal;
    uint256 public _insuranceFeeTotal;
    uint256 public _sellinsuranceFeeTotal;
    uint256 public _selltreasuryFeeTotal;
    uint256 public _treasuryFeeTotal;
    uint256 public _referalFeeTotal;
    uint256 public _inbetweenFeeTotal;

    address public stakingContractAddress = 0x0000000000000000000000000000000000000000;
    address public arenaAddress  = 0x95D92D17AEff61aad72e04804fe0b7Be422C6E7B;      // BuyBackv1 Address
    address public winnerAddress  = 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC;      // BuyBackv2 Address
    address public burningAddress;  // 0x000000000000000000000000000000000000dead  Burning Address add after deployment
    address public lpAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;      // SMarketing Address
    address public insuranceAddress = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;      // SMarketing Address
    address public treasuryAddress = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB;      // SMarketing Address
    address public referalAddress = 0x583031D1113aD414F02576BD6afaBfb302140225;      // SMarketing Address
    address public inbetweenAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;      // SMarketing Address

    event RewardsDistributed(uint256 amount);
    
    

    constructor() {

        contractOwner = msg.sender;
        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        _reflectionBalance[msg.sender] = _reflectionTotal;
        emit Transfer(address(0), msg.sender, _tokenTotal);
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

    function totalSupply() public override view returns (uint256) {
        return _tokenTotal;
    }

    function balanceOf(address account) public override view returns (uint256) {
        if (_isExcluded[account]) return _tokenBalance[account];
        return tokenFromReflection(_reflectionBalance[account]);
    }

    function transfer(address recipient, uint256 amount) public override virtual returns (bool) {
       _transfer(msg.sender,recipient,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override virtual returns (bool) {
        _transfer(sender,recipient,amount);
               
        _approve(sender,msg.sender,_allowances[sender][msg.sender].sub( amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

   

    function tokenFromReflection(uint256 reflectionAmount) public view returns (uint256) {
        require(reflectionAmount <= _reflectionTotal, "Amount must be less than total reflections");
        uint256 currentRate = _getReflectionRate();
        return reflectionAmount.div(currentRate);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address sender, address recipient, uint256 amount) private {

        require(!blackListed[msg.sender], "You are blacklisted so you canot buy, Sell and Transfer Gen tokens!");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        
        uint256 transferAmount = amount;
        uint256 rate = _getReflectionRate();
        
        if(sender != contractOwner && recipient != contractOwner)
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        if(isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
            transferAmount = amount;
        }
        if(!isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
            transferAmount = betweencollectFee(sender,amount,rate);
        }
        if(isExcludedFromFee[sender] && !isExcludedFromFee[recipient]){
            transferAmount = collectFee(sender,amount,rate);
        }
        if(!isExcludedFromFee[sender] && isExcludedFromFee[recipient]){
            transferAmount = SellcollectFee(sender,amount,rate);
        }


        //@dev Transfer reflection
        _reflectionBalance[sender] = _reflectionBalance[sender].sub(amount.mul(rate));
        _reflectionBalance[recipient] = _reflectionBalance[recipient].add(transferAmount.mul(rate));
        
        //@dev If any account belongs to the excludedAccount transfer token
        if (_isExcluded[sender]) {
            _tokenBalance[sender] = _tokenBalance[sender].sub(amount);
        }
        if (_isExcluded[recipient]) {
            _tokenBalance[recipient] = _tokenBalance[recipient].add(transferAmount);
        }
        
        emit Transfer(sender, recipient, transferAmount);
    }
    
    function _burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        require(account == msg.sender);
        
        _reflectionBalance[account] = _reflectionBalance[account].sub(amount, "ERC20: burn amount exceeds balance");
        _tokenTotal = _tokenTotal.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function collectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        
        uint256 transferAmount = amount;
        
        uint256 arenaFee = amount.mul(_arenaFee).div(10000);
        uint256 winnerFee = amount.mul(_winnerFee).div(10000);
        uint256 burningFee = amount.mul(_burningFee).div(10000);
        uint256 lpFee = amount.mul(_lpFee).div(10000);
        uint256 insuranceFee = amount.mul(_insuranceFee).div(10000);
        uint256 treasuryFee = amount.mul(_treasuryFee).div(10000);
        uint256 referalFee = amount.mul(_referalFee).div(10000);

          //@dev Burning fee
        if (burningFee > 0){
            transferAmount = transferAmount.sub(burningFee);
            _reflectionBalance[burningAddress] = _reflectionBalance[burningAddress].add(burningFee.mul(rate));
            _burningFeeTotal = _burningFeeTotal.add(burningFee);
            emit Transfer(account,burningAddress,burningFee);
        }
        
         //@dev SMarketing fee
        if (lpFee > 0){
            transferAmount = transferAmount.sub(lpFee);
            _reflectionBalance[lpAddress] = _reflectionBalance[lpAddress].add(lpFee.mul(rate));
            _lpFeeTotal = _lpFeeTotal.add(lpFee);
            emit Transfer(account,lpAddress,lpFee);
        }

        
        //@dev Tax fee
   
        //@dev BuyBackv1 fee
        if(arenaFee > 0){
            transferAmount = transferAmount.sub(arenaFee);
            _reflectionBalance[arenaAddress] = _reflectionBalance[arenaAddress].add(arenaFee.mul(rate));
            _arenaFeeTotal = _arenaFeeTotal.add(arenaFee);
            emit Transfer(account,arenaAddress,arenaFee);
        }
        
        //@dev BuyBackv2 fee
        if(winnerFee > 0){
            transferAmount = transferAmount.sub(winnerFee);
            _reflectionBalance[winnerAddress] = _reflectionBalance[winnerAddress].add(winnerFee.mul(rate));
            _winnerFeeTotal = _winnerFeeTotal.add(winnerFee);
            emit Transfer(account,winnerAddress,winnerFee);
        }
        if(insuranceFee > 0){
            transferAmount = transferAmount.sub(insuranceFee);
            _reflectionBalance[insuranceAddress] = _reflectionBalance[insuranceAddress].add(insuranceFee.mul(rate));
            _insuranceFeeTotal = _insuranceFeeTotal.add(insuranceFee);
            emit Transfer(account,insuranceAddress,insuranceFee);
        }
        if(treasuryFee > 0){
            transferAmount = transferAmount.sub(treasuryFee);
            _reflectionBalance[treasuryAddress] = _reflectionBalance[treasuryAddress].add(treasuryFee.mul(rate));
            _treasuryFeeTotal = _treasuryFee.add(treasuryFee);
            emit Transfer(account,treasuryAddress,treasuryFee);
        }
        if(referalFee > 0){
            transferAmount = transferAmount.sub(referalFee);
            _reflectionBalance[referalAddress] = _reflectionBalance[referalAddress].add(referalFee.mul(rate));
            _referalFeeTotal = _referalFee.add(referalFee);
            emit Transfer(account,referalAddress,referalFee);
        }
        
       
        return transferAmount;
    }


    function SellcollectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        
        uint256 transferAmount = amount;
        
        uint256 arenaFee = amount.mul(_arenaFee).div(10000);
        uint256 winnerFee = amount.mul(_winnerFee).div(10000);
        uint256 burningFee = amount.mul(_burningFee).div(10000);
        uint256 lpFee = amount.mul(_lpFee).div(10000);
        uint256 sellinsuranceFee = amount.mul(_sellinsuranceFee).div(10000);
        uint256 selltreasuryFee = amount.mul(_selltreasuryFee).div(10000);
        uint256 referalFee = amount.mul(_referalFee).div(10000);

          //@dev Burning fee
        if (burningFee > 0){
            transferAmount = transferAmount.sub(burningFee);
            _reflectionBalance[burningAddress] = _reflectionBalance[burningAddress].add(burningFee.mul(rate));
            _burningFeeTotal = _burningFeeTotal.add(burningFee);
            emit Transfer(account,burningAddress,burningFee);
        }
        
         //@dev SMarketing fee
        if (lpFee > 0){
            transferAmount = transferAmount.sub(lpFee);
            _reflectionBalance[lpAddress] = _reflectionBalance[lpAddress].add(lpFee.mul(rate));
            _lpFeeTotal = _lpFeeTotal.add(lpFee);
            emit Transfer(account,lpAddress,lpFee);
        }

        
        //@dev Tax fee
   
        //@dev BuyBackv1 fee
        if(arenaFee > 0){
            transferAmount = transferAmount.sub(arenaFee);
            _reflectionBalance[arenaAddress] = _reflectionBalance[arenaAddress].add(arenaFee.mul(rate));
            _arenaFeeTotal = _arenaFeeTotal.add(arenaFee);
            emit Transfer(account,arenaAddress,arenaFee);
        }
        
        //@dev BuyBackv2 fee
        if(winnerFee > 0){
            transferAmount = transferAmount.sub(winnerFee);
            _reflectionBalance[winnerAddress] = _reflectionBalance[winnerAddress].add(winnerFee.mul(rate));
            _winnerFeeTotal = _winnerFeeTotal.add(winnerFee);
            emit Transfer(account,winnerAddress,winnerFee);
        }
        if(sellinsuranceFee > 0){
            transferAmount = transferAmount.sub(sellinsuranceFee);
            _reflectionBalance[insuranceAddress] = _reflectionBalance[insuranceAddress].add(sellinsuranceFee.mul(rate));
            _sellinsuranceFeeTotal = _sellinsuranceFeeTotal.add(sellinsuranceFee);
            emit Transfer(account,insuranceAddress,sellinsuranceFee);
        }
        if(selltreasuryFee > 0){
            transferAmount = transferAmount.sub(selltreasuryFee);
            _reflectionBalance[treasuryAddress] = _reflectionBalance[treasuryAddress].add(selltreasuryFee.mul(rate));
           _selltreasuryFeeTotal = _selltreasuryFeeTotal.add(selltreasuryFee);
            emit Transfer(account,treasuryAddress,selltreasuryFee);
        }
        if(referalFee > 0){
            transferAmount = transferAmount.sub(referalFee);
            _reflectionBalance[referalAddress] = _reflectionBalance[referalAddress].add(referalFee.mul(rate));
            _referalFeeTotal = _referalFee.add(referalFee);
            emit Transfer(account,referalAddress,referalFee);
        }
        
       
        return transferAmount;
    }


 function betweencollectFee(address account, uint256 amount, uint256 rate) private returns (uint256) {
        
        uint256 transferAmount = amount;
       
        uint256 _inbetweenFee = amount.mul(_inbetweenFee_).div(10000);

        if (_inbetweenFee > 0){
            transferAmount = transferAmount.sub(_inbetweenFee);
            _reflectionBalance[inbetweenAddress] = _reflectionBalance[inbetweenAddress].add(_inbetweenFee.mul(rate));
            _inbetweenFeeTotal = _inbetweenFeeTotal.add(_inbetweenFee);
            emit Transfer(account,inbetweenAddress,_inbetweenFee);
        }
       
        return transferAmount;
    }

    function _getReflectionRate() private view returns (uint256) {
        uint256 reflectionSupply = _reflectionTotal;
        uint256 tokenSupply = _tokenTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _reflectionBalance[_excluded[i]] > reflectionSupply ||
                _tokenBalance[_excluded[i]] > tokenSupply
            ) return _reflectionTotal.div(_tokenTotal);
            reflectionSupply = reflectionSupply.sub(
                _reflectionBalance[_excluded[i]]
            );
            tokenSupply = tokenSupply.sub(_tokenBalance[_excluded[i]]);
        }
        if (reflectionSupply < _reflectionTotal.div(_tokenTotal))
            return _reflectionTotal.div(_tokenTotal);
        return reflectionSupply.div(tokenSupply);
    }
    
    
    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function getChainId() internal view returns (uint) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }

    function addInBlackList(address account, bool) public onlyOwner {
        blackListed[account] = true;
    }
    
    function removeFromBlackList(address account, bool) public onlyOwner {
        blackListed[account] = false;
    }
   
    function ExcludedFromFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = true;
    }
    
    function IncludeInFee(address account, bool) public onlyOwner {
        isExcludedFromFee[account] = false;
    }
    
     function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner {
        _maxTxAmount = _tokenTotal.mul(maxTxPercent).div(
            10**2
        );
     }
     
    function setWinnerFee(uint256 fee) public onlyOwner {
        _winnerFee = fee;
    }
    
    function setarenaFee(uint256 fee) public onlyOwner {
        _arenaFee = fee;
    }
    
     function setBurningFee(uint256 fee) public onlyOwner {
        _burningFee = fee;
    }
    
     function setlpFee(uint256 fee) public onlyOwner {
        _lpFee = fee;
    }
    function setinsuranceFee(uint256 fee) public onlyOwner {
        _insuranceFee = fee;
    }
    function settreasuryFee(uint256 fee) public onlyOwner {
        _treasuryFee = fee;
    }
    function setselltreasuryFee(uint256 fee) public onlyOwner {
        _selltreasuryFee = fee;
    }
    function setsellinsuranceFee(uint256 fee) public onlyOwner {
        _sellinsuranceFee = fee;
    }
     function inbetweenFee(uint256 fee) public onlyOwner {
        _inbetweenFee_ = fee;
    }
    function setArenaAddress(address _Address) public onlyOwner {
        require(_Address != arenaAddress);
        
        arenaAddress = _Address;
    }
    function setinbetweenAddress(address _Address) public onlyOwner {
        require(_Address != inbetweenAddress);
        
        inbetweenAddress = _Address;
    }

    function setSakingTokenAddress(address _Address) public onlyOwner {
        require(_Address != inbetweenAddress);
        
        stakingContractAddress = _Address;
    }
    
    function setWinnerAddress(address _Address) public onlyOwner {
        require(_Address != winnerAddress);
        
        winnerAddress = _Address;
    }
    
    function setBurningAddress(address _Address) public onlyOwner {
        require(_Address != burningAddress);
        
        burningAddress = _Address;
    }
    
     function setLPAddress(address _Address) public onlyOwner {
        require(_Address != lpAddress);
        
        lpAddress = _Address;
    }
    function setInsuranceAddress(address _Address) public onlyOwner {
        require(_Address != insuranceAddress);
        
        insuranceAddress = _Address;
    }
    function settreasuryAddress(address _Address) public onlyOwner {
        require(_Address != treasuryAddress);
        
        treasuryAddress = _Address;
    }
     function setReferalAddress(address _Address) public onlyOwner {
        require(_Address != referalAddress);
        
        referalAddress = _Address;
    }
    
    // function to allow admin to transfer ETH from this contract
    function TransferETH(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
    }
    
    modifier onlyOwner {
        require(msg.sender == contractOwner, "Only owner can call this function.");
        _;
    }
    
    
    receive() external payable {}
}