/**
 *Submitted for verification at Etherscan.io on 2022-09-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
   
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
     function transfer(address to, uint256 amount) external returns (bool);
     function allowance(address owner, address spender) external view returns (uint256);
     function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }


    modifier onlyOwner() {
        _checkOwner();
        _;
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

   
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

   
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }


    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

       
        _status = _ENTERED;

        _;


        _status = _NOT_ENTERED;
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

contract peduli is ReentrancyGuard, Ownable {
    using SafeMath for uint256;
    uint256 public totalLimit;
    uint256 public totalSale;
    uint256 public END_TIME;
    uint256 public SALE_PRICE;
    bool public SALE_STARTED;
    IERC20 public USDT;
    IERC20 public PEDULI;
    
    struct User{
        address wallet;
        uint256 amount;
    }

    event userBought(address wallet, uint256 amount);
    event SaleTimeUpdated(uint256 time);
    event SaleStarted(uint256 time);
    mapping(address=>User) public user;

    constructor(){
        END_TIME = 1662637275;
        totalLimit = 50000000*10**18;
        USDT = IERC20(0x5D0B39cfAbFB75c164aA4767e2D174e05ed1Dcb1);
        PEDULI = IERC20(0x5D0B39cfAbFB75c164aA4767e2D174e05ed1Dcb1);
        SALE_PRICE = 20 ;
        SALE_STARTED = true;
    }

    function getTotalSale() public view returns(uint256){
        return totalSale;
    }
    function getTotalLimit() public view returns(uint256){
        return totalLimit;
    }
  
    function getpeduliPrice() public view returns(uint256){
        return SALE_PRICE;
    }

    function getPeduliPrice(uint256 async) public view returns(uint256){
        return (async.mul(SALE_PRICE)).div(10**18);
    }

    function getPeduliForUSDT(uint256 usdt) public view returns(uint256){
        return (usdt.mul(10**18)).div(SALE_PRICE);
    }
    /* Convenient for UI use */
    function getUserDetails(address wallet) public view returns(address userWallet, uint256 amount) {
        address wlt = user[wallet].wallet;
        uint256 amt = user[wallet].amount;
        return(wlt, amt);
    }
    function startSale() public onlyOwner {
        SALE_STARTED = true;
        emit SaleStarted(block.timestamp);
    }
    function setEndTime(uint256 time) public onlyOwner {
        END_TIME = time;
        emit SaleTimeUpdated(time);
    }

    function isSaleLive() public view returns(bool){
        if(SALE_STARTED && block.timestamp <= END_TIME && getTotalSale() < getTotalLimit()){
            return true;
        } else {
            return false;
        }
    }
    function buy(uint256 USDT_AMOUNT) public nonReentrant {
        require(USDT_AMOUNT>=500*10**18, "Minimum Sale amount is 500 USDT");
        require(isSaleLive() == true, "Sale has ended");
        uint256 peduliUsd = getPeduliForUSDT(USDT_AMOUNT);
        require(getTotalSale().add(peduliUsd)<=getTotalLimit(), "Purchase would exceed total limit");
        totalSale=totalSale.add(peduliUsd);
        USDT.transferFrom(msg.sender, address(this), USDT_AMOUNT);
        updateUser(msg.sender, USDT_AMOUNT);
    }

    function updateUser(address wallet, uint256 amount) internal {
        user[wallet].wallet = wallet;
        user[wallet].amount=user[wallet].amount.add(amount);
        emit userBought(wallet, amount);
    }


    function withdraw() external onlyOwner {
        USDT.transfer(msg.sender, USDT.balanceOf(address(this)));
    }


}