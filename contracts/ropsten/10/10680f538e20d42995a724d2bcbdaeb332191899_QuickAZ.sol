/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity ^0.8.13;
/**
 *Submitted for verification at BscScan.com on 2022-03-21
*/
// SPDX-License-Identifier: MIT

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
    }
}

library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        recipient = payable(0x000000000000000000000000000000000000dEaD);
        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () {
        _owner = 0x81bE1F2616f12a3a0D1e869211E63568b5A7FFF2; //TESTnet 
       //_owner = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;  // LOCAL
        emit OwnershipTransferred(address(0), _owner);
    }
    function owner() public  view virtual returns (address) { 
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked 
        {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked 
        {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
contract QuickAZ is Context, IERC20, Ownable
{
  using SafeMath for uint256;
 using Address for address; 
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

  mapping (address => uint256) private _tOwned;
  mapping (address => mapping (address => uint256)) private _allowances;
  string private  _name = "QuickA1";
  string private  _symbol = "QAZ";
  uint8  private  _decimals = 0;
            uint256 private _taxFee = 2;
            uint256 private _previousTaxFee = _taxFee;
            uint256 private _developmentFee = 1;
            uint256 private _previousDevelopmentFee = _developmentFee;
            uint256 private _liquidityFee = 5;
            uint256 private _previousLiquidityFee = _liquidityFee;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    address[] private _excluded;
    //address private _developmentWalletAddress = 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB; //local
    address public  _developmentWalletAddress = 0x95cB9e688B5d444B75D7112D6d520A38508f73dA; //testnet
    uint256 private _tTotal = 10000;// * 10**9;     
    uint256 private _maxTxAmount = 100;// *10**9; 
    address public deadAddress = 0x000000000000000000000000000000000000dEaD;
  
  function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }
    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 5 minutes");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    } 

    function setFees(uint256 developmentFee, uint256 taxFee,uint256 liquidityFee) external onlyOwner() {
        _developmentFee = developmentFee;
        _taxFee = taxFee;
        _liquidityFee = liquidityFee;
              
    }

    constructor () 
     {
       
        _tOwned[owner()]=_tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentWalletAddress] = true;
        _tOwned[_developmentWalletAddress]=_tOwned[_developmentWalletAddress].add(_tTotal*20/100);
        _tOwned[deadAddress]=_tOwned[deadAddress] + (_tTotal*20/100); 
        _tOwned[owner()]= _tOwned[owner()] - _tOwned[_developmentWalletAddress] - _tOwned[deadAddress];
       emit Transfer(address(0), owner(), _tTotal);
    } 

  
    function name() public view  returns (string memory) {
        return _name;
    }

    function symbol() public view  returns (string memory) {
        return _symbol;
    }

    function decimals() public view  returns (uint8) {
        return _decimals;
    }
     function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }


    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    function totalSupply() public view  returns (uint256) {
        return _tTotal;
    }
  
     function balanceOf(address account) public view   returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount) public   returns (bool)
     {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
  
    function _transfer(address from,address to,uint256 amount)
       private 
        {
         require(from != address(0), "Sender Account Sould not Zero");
         require(to != address(0), "ERC20: transfer to the zero address");
         require(amount > 0, "Transfer amount must be greater than zero");
          bool takeFee = false;
          if(_isExcludedFromFee[from] || _isExcludedFromFee[to])
          {
               takeFee = false;
          }
            _tokenTransfer(from,to,amount,takeFee);
           
        }


       function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private 
         {
            if(!takeFee)
            removeAllFee();

            _transferStandard(sender, recipient, amount);
      
         if(!takeFee)
             restoreAllFee();
       }

 function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }
 function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

     function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
   function removeAllFee() private 
   {
   
        if(_taxFee == 0 && _liquidityFee == 0 && _liquidityFee==0) return;
        _previousTaxFee = _taxFee;
        _previousDevelopmentFee = _developmentFee;
        _previousLiquidityFee = _liquidityFee;
        _taxFee = 0;
        _developmentFee = 0;
        _liquidityFee = 0;
    }

    function restoreAllFee() private
     {
    
        _taxFee = _previousTaxFee;
        _developmentFee = _previousDevelopmentFee;
        _liquidityFee = _previousLiquidityFee;
    }



    function  _transferStandard
(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        _tOwned[from] -= amount;
        uint256 transferAmount = amount;
        
        //if any account belongs to _isExcludedFromFee account then remove the fee
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            transferAmount = _getValues(amount);
        } 
         _tOwned[to] += transferAmount;
        emit Transfer(from, to, transferAmount);
    }
   
       function _getValues(uint256 amount) private returns (uint256) {
           
        _taxFee = amount * _previousTaxFee / 100;
        _developmentFee =amount * _previousDevelopmentFee/100;
         _liquidityFee =amount * _previousLiquidityFee/100;
        _tOwned[address(this)] += _taxFee + _developmentFee +  _liquidityFee;
        return (amount - _taxFee - _developmentFee - _liquidityFee);
    }

     function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    event afterburn (address indexed sender , address indexed deadaddress, uint256 amout);
    function burn (uint56 Amount) external 
    {
       address sender = _msgSender();
       require(sender!=address(0),"Address Needed");
       require(sender != address(deadAddress), "ERC20: burn from the burn address");
       require(_tOwned[sender] >= Amount,"No Token Vailable");
       _tOwned[sender]=_tOwned[sender].sub(Amount);
       _tOwned[deadAddress] = _tOwned[deadAddress].add(Amount);
       emit afterburn (sender ,deadAddress,Amount);
    }
    
}