/**
 *Submitted for verification at Etherscan.io on 2022-07-16
*/

pragma solidity =0.6.6;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function decimals() external view returns (uint8);
}

contract UMarket is Ownable{
    using SafeMath for uint;
    ERC20 public U;
    ERC20 public usdt;

    address public toAddress1;
    address public toAddress2;
    address public toAddress3;
    address public toAddress4;

    uint public salePrice;
    uint public totalBuy;
    mapping(address => uint) public cacheMap;
    mapping(address => uint) public timeMap;
    mapping(address => uint) public buyMap;
    mapping(address => uint) public returnMap;

    uint public totalTime = 60*60*24*3650;

    event BuyU(address indexed from,uint getValue,uint constValue);
    event SaleU(address indexed from,uint getValue,uint constValue);
    event GovWithdrawToken( address indexed to, uint256 value);

    constructor(address _U, address _usdt)public {
        U = ERC20(_U);
        usdt = ERC20(_usdt);
        uint usdtDecimals = usdt.decimals();
        salePrice = uint(10**usdtDecimals).mul(9).div(10);
    }

    function getBuyCost(uint _value) public view returns (uint){
        uint uDecimals = U.decimals();
        uint usdtDecimals = usdt.decimals();
        return _value.mul(10**uDecimals).div(10**usdtDecimals);
    }

    function getSaleCost(uint _value) public view returns (uint){
        uint uDecimals = U.decimals();
        return _value.mul(salePrice).div(10**uDecimals);
    }

    function buyU(uint256 _amount) public {
        require(_amount > 0, "!zero input");

        uint cost = getBuyCost(_amount);
        uint allowed = usdt.allowance(msg.sender,address(this));
        uint balanced = usdt.balanceOf(msg.sender);
        require(allowed >= cost, "!allowed");
        require(balanced >= cost, "!balanced");
        usdt.transferFrom(msg.sender,address(this), cost);

        uint uBalanced = U.balanceOf(address(this));
        require(uBalanced >= _amount, "!market balanced");
        sendToAddr(cost);
        saveRecord(msg.sender,_amount);
        U.transfer( msg.sender,_amount);
        BuyU(msg.sender, _amount, cost);
    }

    function saleU(uint256 _amount) public {
        require(_amount > 0, "!zero input");

        uint cost = getSaleCost(_amount);
        uint allowed = U.allowance(msg.sender,address(this));
        uint balanced = U.balanceOf(msg.sender);
        require(allowed >= cost, "!allowed");
        require(balanced >= cost, "!balanced");
        U.transferFrom(msg.sender,address(this), cost);

        uint usdtBalanced = usdt.balanceOf(address(this));
        require(usdtBalanced >= _amount, "!market balanced");

        usdt.transfer( msg.sender,_amount);
        SaleU(msg.sender, _amount, cost);
    }

    function sendToAddr(uint _amount) private {
        uint _amount1 = _amount.mul(51).div(100);
        uint _amount2 = _amount.mul(20).div(100);
        uint _amount3 = _amount.mul(19).div(100);
        uint _amount4 = _amount.sub(_amount1).sub(_amount2).sub(_amount3);
        U.transfer( toAddress1, _amount1);
        U.transfer( toAddress2, _amount2);
        U.transfer( toAddress3, _amount3);
        U.transfer( toAddress4, _amount4);
    }

    function saveRecord(address _to, uint _amount) private {
        uint buyed = buyMap[_to];
        uint lastTime = timeMap[_to];
        if(buyed > 0 && lastTime > 0){
            uint timeRange = now.sub(lastTime);
            uint tmp = buyed.mul(timeRange).div(totalTime);
            cacheMap[_to] = cacheMap[_to].add(tmp);
        }
        timeMap[_to] = now;
        buyMap[_to] = buyed.add(_amount);
    }

    function refund() public {
        uint amount = refundAble(msg.sender);
        require(amount > 0, "no refundAble value");
        timeMap[msg.sender] = now;
        returnMap[msg.sender] = returnMap[msg.sender].add(amount);
        cacheMap[msg.sender] = 0;
        U.transfer( msg.sender, amount);
    }

    function refundAble(address _to) public view returns (uint) {
        uint buyed = buyMap[_to];
        uint lastTime = timeMap[_to];
        if(buyed > 0 && lastTime > 0){
            uint timeRange = now.sub(lastTime);
            uint tmp = buyed.mul(timeRange).div(totalTime);
            uint refundAmount = tmp.add(cacheMap[_to]);
            if(refundAmount.add(returnMap[_to]) > buyed){
                return buyed.sub(returnMap[_to]);
            }
            return refundAmount;
        }else{
            return 0;
        }
    }

    function setU(address _U) public onlyOwner {
        U = ERC20(_U);
    }

    function setUsdt(address _usdt) public onlyOwner {
        usdt = ERC20(_usdt);
    }

    function setAddress(address _addr1,address _addr2,address _addr3,address _addr4) public onlyOwner {
        toAddress1 = _addr1;
        toAddress2 = _addr2;
        toAddress3 = _addr3;
        toAddress4 = _addr4;
    }

    function withdrawToken(address _token, address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        ERC20 token = ERC20(_token);
        uint balanced = token.balanceOf(address(this));
        require(balanced >= _amount, "!balanced");
        token.transfer( _to, _amount);
    }
}