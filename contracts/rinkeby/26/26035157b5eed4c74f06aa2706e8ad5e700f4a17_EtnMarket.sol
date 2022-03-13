/**
 *Submitted for verification at Etherscan.io on 2022-03-13
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
}

contract EtnMarket is Ownable{
    using SafeMath for uint;
    ERC20 public etncoins;
    uint public sold = 0;
    uint public basePrice = 10 ether; //每一个etn需要的eth

    event BuyToken(address indexed from,uint gotValue, uint constVlau);
    event GovWithdraw(address indexed to, uint256 value);
    event GovWithdrawToken( address indexed to, uint256 value);

    constructor(address _etncoins)public {
        etncoins = ERC20(_etncoins);
    }

    function getCost(uint256 _value) public view returns (uint){
        return _value.mul(basePrice.mul(sold).div(1 ether).div(1000).add(basePrice)).div(1 ether);
    }

    function buy(uint256 _value) public payable{
        uint amount = getCost(_value);
        require(
            amount <= msg.value,
            "Not enough coin sent"
        );
        etncoins.transfer( msg.sender, amount);
        uint change = msg.value.sub(amount);
        if(change > 0){
            msg.sender.transfer(change);
        }
        sold = sold + _value;
        BuyToken(msg.sender,_value, amount);
    }

    function setBasePrice(uint256 _basePrice) public onlyOwner {
        basePrice = _basePrice;
    }

    function setToken(address _etncoins) public onlyOwner {
        etncoins = ERC20(_etncoins);
    }

    function withdraw(address to) public onlyOwner {
        uint256 balance = address(this).balance;
        payable(to).transfer(balance);
        emit GovWithdraw( to, balance);
    }

    function withdrawToken(address _to,uint256 _amount) public onlyOwner {
        require(_amount > 0, "!zero input");
        etncoins.transfer( _to, _amount);
        emit GovWithdrawToken( _to, _amount);
    }
}