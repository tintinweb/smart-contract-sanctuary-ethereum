/**
 *Submitted for verification at Etherscan.io on 2022-06-26
*/

//SPDX-License-Identifier: Unlicensed 
pragma solidity ^0.8.7;

library SafeMath {
    function Add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function Sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function Mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function Div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract Token{
    using SafeMath for uint256;
    string public name = 'BEASTBUY';
    string public symbol = 'BB';
    uint256 public decimals = 18 ;
    uint256 public totalsupply = 10000000000000000000000 ;
    address owner;
    //5% will go to owner and 5% of transaction will burn
    uint taxfee = 5;
    uint burnfee = 5;
    bool public istransferable = false;

    //bool public ExcludedFromReward = false;


    //exclude addresses from deflation
    mapping(address=>bool) public ExcludedFromFee;
    //mapping(address=>bool) public ExcludedFromReward;
    mapping(address => uint256) public balance;
    mapping(address => mapping(address => uint256)) allowance;
    mapping (address => bool) public _Blacklisted;  

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event OwnershipTransfer(address indexed previousOwner, address indexed newOwner);

    constructor(){//(string memory Name, string memory Symbol, uint Decimals, uint TotalSupply) {
        // name = Name;
        // symbol = Symbol;
        // decimals = Decimals;
       // totalsupply = TotalSupply; 
        owner = msg.sender;
        balance[owner] = totalsupply;//TotalSupply;
        ExcludedFromFee[owner] = true;
         _rOwned[msg.sender] = _rTotal;
    }
    function Balance() public view returns(uint256) {
        return balance[owner];
    }

    function _transfer(address from, address to, uint256 value) internal transferable {
        // require(to != address(0) && balance[from] >= value);
        // require(!_Blacklisted[from] && !_Blacklisted[to], "This address is blacklisted");
        if(ExcludedFromFee[msg.sender] == true){
            require(to != address(0) && balance[from] >= value);
            require(!_Blacklisted[from] && !_Blacklisted[to], "This address is blacklisted");
            balance[from]-=value;
            balance[to] = balance[to].Add(value);   
            emit Transfer(msg.sender, to, value);
    }            
         else {
            uint burnamount = value.Mul(burnfee).Div(100);
            uint owneramount = value.Mul(taxfee).Div(100);
            require(to != address(0));
            //5% will burn 
            balance[from] = balance[from].Sub(burnamount);
            totalsupply = totalsupply.Sub(burnamount);
            //5% will add in owner's account 
            balance[from] = balance[from].Sub(owneramount);
            balance[owner] = balance[owner].Add(owneramount);
            // Then transaction will proceeed forward
            require(balance[from] >= value, "Not Enough Balance");
            require(!_Blacklisted[from] && !_Blacklisted[to], "This address is blacklisted");
            balance[from]-=value;
            balance[to]+=value;
            emit Transfer(msg.sender, to, value);
         }
    }

     function transfer(address to, uint256 value) public returns (bool success) {
         _transfer(msg.sender, to, value);
        return true;
    }

     function approve(address spender, uint256 value) external returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

      function transferFrom(address from, address to, uint256 value) public returns (bool) {
        require(value <= allowance[from][msg.sender]);
        allowance[from][msg.sender] -= value;
        _transfer(from, to, value);
        return true;
    }
    
    function Allowance (address owner, address spender) public view returns (uint256 remaining) {
        return allowance[owner][spender];
    } 

    // function increaseAllowance (address spender, uint256 qty) public returns (bool){
    //     allowance[msg.sender][spender]+=qty;
    //     emit Approval(msg.sender, spender, qty);
    //     return true;
    // } 

    modifier onlyAdmin {
        require (msg.sender==owner, "Only Admin Can Run This Function");
        _;
    }

    modifier transferable {
        require (istransferable == false , "Can't Trade, Tokens are locked");
        _;
    }

    function lockunlock (bool choice) public onlyAdmin {
        istransferable = choice;
    }

    function mint (uint256 qty) public onlyAdmin returns (uint256){
        totalsupply+=qty;
        balance[msg.sender]+= qty;
        return totalsupply;
    }

    function burn (uint256 qty) public onlyAdmin returns (uint256){
        require(balance[msg.sender]>=qty, "Not Enough Balance In Wallet");
        totalsupply-=qty;
        balance[msg.sender]-=qty;
        return totalsupply;
    }

        function newOwner(address _newOwner) public virtual onlyAdmin {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransfer(owner, _newOwner);
        owner = _newOwner;
    }

    function renounceOwnership() public virtual onlyAdmin {
        emit OwnershipTransfer(owner, address(0));
        owner = address(0);
    }

    // function newOwner (address _newOwner) public onlyAdmin  {
    //     require (_newOwner != address(0), "Address can't be 0");
    //     owner = _newOwner;
    //     balance[_newOwner] = totalsupply;
    //     // return true;
    // }

    function increaseAllowance(address spender, uint256 qty) public returns (bool) {
    require(spender != address(0));
    allowance[msg.sender][spender] = allowance[msg.sender][spender].Add(qty);
    emit Approval(msg.sender, spender, qty);
    return true;
   }

    function decreaseAllowance(address spender, uint256 qty) public returns (bool) {
    require(spender != address(0));
    allowance[msg.sender][spender] = allowance[msg.sender][spender].Sub(qty);
    emit Approval(msg.sender, spender, qty);
    return true;
}

    function addtoBlackList(address _address) external onlyAdmin {
        _Blacklisted[_address] = true;

    //   for (uint256 i; i < addresses.length; ++i) {
    //     _Blacklisted[addresses[i]] = true;
    //   }
    }


//Remove from Blacklist 
    function removefromBlackList(address account) external onlyAdmin {
        _Blacklisted[account] = false;
    }

    // ------------------>>>>> REFLECTION TOKEN  <<<<<<----------------------
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;

    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
   
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10 * 10**6 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function reflect(uint256 tAmount) public {
        require(!_isExcluded[msg.sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,) = _getValues(tAmount);
        _rOwned[msg.sender] = _rOwned[msg.sender].Sub(rAmount);
        _rTotal = _rTotal.Sub(rAmount);
        _tFeeTotal = _tFeeTotal.Add(tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.Div(currentRate);
    }

    function excludeAccount(address account) external onlyAdmin {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeAccount(address account) external onlyAdmin {
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

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[msg.sender] = _rOwned[msg.sender].Sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].Add(rTransferAmount);       
        _reflectFee(rFee, tFee);
        emit Transfer(msg.sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].Sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].Add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].Add(rTransferAmount);           
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].Sub(tAmount);
        _rOwned[sender] = _rOwned[sender].Sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].Add(rTransferAmount);   
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender].Sub(tAmount);
        _rOwned[sender] = _rOwned[sender].Sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].Add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].Add(rTransferAmount);        
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.Sub(rFee);
        _tFeeTotal = _tFeeTotal.Add(tFee);
    }

     function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee) = _getTValues(tAmount);
        uint256 currentRate =  _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee);
    }

    function _getTValues(uint256 tAmount) private pure returns (uint256, uint256) {
        uint256 tFee = tAmount.Div(100);
        uint256 tTransferAmount = tAmount.Sub(tFee);
        return (tTransferAmount, tFee);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.Mul(currentRate);
        uint256 rFee = tFee.Mul(currentRate);
        uint256 rTransferAmount = rAmount.Sub(rFee);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.Div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.Sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.Sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.Div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }









    // account will be excluded from reward
    // function isExcludedFromReward(address account) public view returns (bool) {
    //     return ExcludedFromReward[account];
    // }

}