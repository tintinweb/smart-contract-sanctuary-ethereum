/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-06-03
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

contract BSNSale {

    //Mainnet
   //  IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
   //  IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);

    //Testnet
    IERC20 public usdt = IERC20(0xBEe33b6B1C3df2c4468510E87d6330daA5709F3E);
    IERC20 public busd = IERC20(0xBEe33b6B1C3df2c4468510E87d6330daA5709F3E);
    
    IERC20 public token;

    bool public paused; 

    address public owner;
    address public feeReciever;

    uint256 public perDollarPrice;  //in decimals

    uint256 public UsdtoBnb; //one usd to bnb

    uint256 minDeposit = 10000000000000000000;  //10$

    mapping (address => mapping (address => bool)) public referral;

    modifier onlyOwner {
        require(owner == msg.sender,"Caller must be Ownable!!");
        _;
    }

    constructor(uint256 _price,address _presaleToken , uint _perUsdtoBnb,address _feeReciever){
        owner = msg.sender;
        perDollarPrice = _price;
        token = IERC20(_presaleToken);
        UsdtoBnb = _perUsdtoBnb;
        feeReciever = _feeReciever;
    }

    //minimum deposit 20$
    //5% referral directly go to user account
    //$1 is 54,868

    function ikeBalance(address _user) public view returns(uint){
        return token.balanceOf(_user);
    }

    function contractBalance() public view returns (uint) {
        return address(this).balance;
    }

    function remainingToken() public view returns(uint){
        return token.balanceOf(address(this));
    }

    //per dollar price in decimals
    function setTokenPrice(uint _price) public onlyOwner{
        perDollarPrice = _price;
    }

    //per dollar price in decimals of bnb
    function setBnbPrice(uint _price) public onlyOwner{
        UsdtoBnb = _price;
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
    function buyfromToken(uint _pid,uint amount) public payable {

        require(!paused,"Presale is Paused!!");

        require(amount >= minDeposit,"You cannot buy less then 10$!!");    

        uint twoDollarFee = UsdtoBnb*2;    
        require(msg.value == twoDollarFee,"Need 2$ as Fee!!");
     
        if(_pid == 1){

            usdt.transferFrom(msg.sender,address(this),amount);
            usdt.transfer(owner,amount);

            uint temp = amount / 10 ** 18;
            uint multiplier = perDollarPrice  * temp;

            token.transfer(msg.sender,multiplier);

        }
        if(_pid == 2){

            busd.transferFrom(msg.sender,address(this),amount);
            busd.transfer(owner,amount);
            uint temp = amount / 10 ** 18;
            uint multiplier = perDollarPrice  * temp;

            token.transfer(msg.sender,multiplier);

        }

        payable(feeReciever).transfer(msg.value);

    }


    function buyFromNative() public payable {

        require(!paused,"Presale is Paused!!");

        uint tenUsdWorth = UsdtoBnb*10;
        uint twoDollarFee = UsdtoBnb*2;

        uint subMin = tenUsdWorth + twoDollarFee;

        require(msg.value >= subMin,"You cannot buy less then 10$!!");

        uint equaltousd = msg.value / UsdtoBnb;

        uint multiplier = perDollarPrice  * equaltousd;

        token.transfer(msg.sender,multiplier);

        uint value = msg.value - twoDollarFee;

        payable(owner).transfer(value);
        payable(feeReciever).transfer(twoDollarFee);


    }

    function RescueFunds() public onlyOwner {
        payable(msg.sender).transfer( address(this).balance );
    }

    function RescueTokens(IERC20 _add,uint _amount,address _recipient) public onlyOwner{
        _add.transfer(_recipient,_amount);
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function changeFeeReciever(address _newRec) public onlyOwner {
        feeReciever = _newRec;
    }

}