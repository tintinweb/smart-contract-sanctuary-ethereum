// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import"./v3.sol";

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
    uint256 internal END_TIME;
    uint256 internal SALE_PRICE;
    bool public SALE_STARTED;
    IERC20 public BUSD;
    IERC20 public BTC;
    IERC20 public USDT;
    IERC20 public USDC;
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
    
        totalLimit = 100000000000*10**18;
        BTC = IERC20(0x779877A7B0D9E8603169DdbD7836e478b4624789);
        USDC = IERC20(0x58AEfEf2FFe8FD4bA76c66a7F1BC43cD06C74231);
        BUSD = IERC20(0x01aF897a5A4CA0aA87D4705721Fb2721f3A81Ef7);
        USDT = IERC20(0xD1F4a26a530cbe61DAF0F47fDFbd63b7FD25Eb62);
        PEDULI=IERC20(0x865AAAbc455cCd2f699909a197Fe37eE587df06e);

        SALE_PRICE = 20 ;
        SALE_STARTED = true;
         END_TIME =  1665313235;
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

    function getPeduliForUSDC(uint256 usdc) public view returns(uint256){
        return (usdc.mul(10**18)).div(SALE_PRICE);
    }

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
    function buy(uint256 Usd_AMOUNT) public nonReentrant {
        require(Usd_AMOUNT>=500*10**18, "Minimum Sale amount is 500 Usd");
        require(isSaleLive() == true, "Sale has ended");
        uint256 peduliUsd = getPeduliForUSDC(Usd_AMOUNT);
        require(getTotalSale().add(peduliUsd)<=getTotalLimit(), "Purchase would exceed total limit");
        totalSale=totalSale.add(peduliUsd);
        USDC.transferFrom(msg.sender, address(this), Usd_AMOUNT);
        updateUser(msg.sender, Usd_AMOUNT);
    }

    function updateUser(address wallet, uint256 amount) internal {
        user[wallet].wallet = wallet;
        user[wallet].amount=user[wallet].amount.add(amount);
        emit userBought(wallet, amount);
    }

     function withdraw() external onlyOwner {
        USDC.transfer(msg.sender, USDC.balanceOf(address(this)));
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}