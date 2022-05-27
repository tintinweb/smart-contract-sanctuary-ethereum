/**
 *Submitted for verification at Etherscan.io on 2022-05-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMathInt {
    
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != -1 || a != MIN_INT256);

        return a / b;
    }

    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

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

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }

}

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

contract Sale {

    //Mainnet
    // IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    // IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    //Testnet
    IERC20 public usdt = IERC20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
    IERC20 public busd = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    
    IERC20 public token;

    bool public paused; 

    address public owner;

    uint256 public perDollarPrice;  //in decimals

    uint256 minDeposit = 2000000000000000000;  //2$

    mapping (address => uint256) public record;

    address[] public indexRecord;

    mapping (address => mapping (address => bool)) public referral;

    modifier onlyOwner {
        require(owner == msg.sender,"Caller must be Ownable!!");
        _;
    }

    // constructor(uint256 _price,address _presaleToken){
    //     owner = msg.sender;
    //     perDollarPrice = _price;
    //     token = IERC20(_presaleToken);
    // }

    constructor(uint256 _price){
        owner = msg.sender;
        perDollarPrice = _price;
    }

    //minimum deposit 20$
    //5% referral directly go to user account
    //$1 is 54,868

    function Balance(address _user) public view returns(uint){
        return token.balanceOf(_user);
    }

    function remainingToken() public view returns(uint){
        return token.balanceOf(address(this));
    }

    function getBalance(address _user) public view returns (uint){
        return record[_user];
    }

    function getUsers() public view returns (uint){
        return indexRecord.length;
    }

    //per dollar price in decimals
    function setTokenPrice(uint _price) public onlyOwner{
        perDollarPrice = _price;
    }

    function setPause(bool _value) public onlyOwner{
        paused = _value;
    }

    function setToken(address _token) public onlyOwner{
        token = IERC20(_token);
    }

    function setBusd(address _token) public onlyOwner{
        busd = IERC20(_token);
    }

    function setUsdt(address _token) public onlyOwner{
        usdt = IERC20(_token);
    }

    //pid for selection of token USDT -> 1 or BUSD -> 2
    function buy(uint _pid,address ref,uint amount) public {

        require(!paused,"Presale is Paused!!");

        require(amount >= minDeposit,"You cannot buy less then 2$!!");
        uint check = 1;
        
        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){}
        else{
            referral[msg.sender][ref] = true;
            check = 2;
        } 

        if(record[msg.sender] == 0){
            indexRecord.push(msg.sender);
        }
     
        if(_pid == 1){

            usdt.transferFrom(msg.sender,address(this),amount);

            if(check == 2){
                uint per5 = ( amount * 5 ) / 100;
                uint per95 = ( amount * 95 ) / 100;
                usdt.transfer(ref,per5);
                usdt.transfer(owner,per95);
            }
            else{
                usdt.transfer(owner,amount);
            }

            uint temp = amount / 10 ** 18;
            uint multiplier = perDollarPrice  * temp;
            token.transfer(msg.sender,multiplier);
            record[msg.sender] += multiplier;

        }
        if(_pid == 2){

            busd.transferFrom(msg.sender,address(this),amount);

            if(check == 2){
                uint per5 = ( amount * 5 ) / 100;
                uint per95 = ( amount * 95 ) / 100;
                busd.transfer(ref,per5);
                busd.transfer(owner,per95);
            }
            else{
                busd.transfer(owner,amount);
            }

            uint temp = amount / 10 ** 18;
            uint multiplier = perDollarPrice  * temp;
            token.transfer(msg.sender,multiplier);

            record[msg.sender] += multiplier;

        }

    }

    function RescueTokens(IERC20 _add,uint _amount,address _recipient) public onlyOwner{
        _add.transfer(_recipient,_amount);
    }


}