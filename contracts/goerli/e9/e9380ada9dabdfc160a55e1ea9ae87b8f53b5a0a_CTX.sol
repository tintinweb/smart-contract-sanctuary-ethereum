/**
 *Submitted for verification at Etherscan.io on 2023-01-19
*/

/**
 *Submitted for verification at BscScan.com on 2022-09-02
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

contract CTX {
    using SafeMath for uint256;
    //Mainnet
    // IERC20 public usdt = IERC20(0x55d398326f99059fF775485246999027B3197955);
    // IERC20 public busd = IERC20(0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56);
    // IERC20 public usdc = IERC20(0x9A06e2E3B6b7d6E1BD451659352b0aA96ca37cA0); // on remix ide

    //Testnet
    IERC20 public usdt = IERC20(0x7ef95a0FEE0Dd31b22626fA2e10Ee6A223F8a684);
    IERC20 public busd = IERC20(0x78867BbEeF44f2326bF8DDd1941a4439382EF2A7);
    IERC20 public usdc = IERC20(0xd9145CCE52D386f254917e481eB44e9943F39138); // test net
   
   struct UserBuy{
       uint[] amount;
       uint[] date;
   }
    
    IERC20 public token;

    bool public paused; 
    uint256 minDeposit = 50000000000000000000;  //10$...
    address public owner;
    address public feeReciever;
    uint256 public perDollarPrice;  //in decimals...
    uint256 public UsdtoBnb; //one usd to bnb
    uint256 public totalSold;
    mapping(address => uint256) public userBuy;
    mapping (address=>uint256) public userFirstBuyDate;
    address[] public buyers; 
    mapping (address => mapping (address => bool)) public referral;

    uint releaseDelay = 1 days* 365;



    modifier onlyOwner {
        require(owner == msg.sender,"Caller must be Ownable!!");
        _;
    }
    
    constructor(uint256 _price,uint _perUsdtoBnb,address _presaleToken,address _feeReciever){
        owner = msg.sender;
        perDollarPrice = _price;
        token = IERC20(_presaleToken);
        UsdtoBnb = _perUsdtoBnb;
        feeReciever = _feeReciever;
    }

    function allBuyers() public view returns (uint){
        return buyers.length;
    } 

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

    function setUSDC(address _token) public onlyOwner{
        usdc = IERC20(_token);
    }

    //pid for selection of token USDT -> 1 or BUSD -> 2 or USDC -> 3
    function buyfromToken(uint _pid,address payable ref,uint amount) public payable {
        // need to set min amount to buy.
        require(amount<=minDeposit, "Invalid ammount");
        require(!paused,"Presale is Paused!!");
        uint check = 1;   

        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){

        }
        else{
            referral[msg.sender][ref] = true;
            check = 2;
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


            uint temp = amount;
            uint multiplier = ( perDollarPrice  * temp ) / 10 ** 18;

            if(userBuy[msg.sender]==0){
                buyers.push(msg.sender);
                userFirstBuyDate[msg.sender] = block.timestamp;
            }
            userBuy[msg.sender] +=multiplier;

            //token.transfer(msg.sender,multiplier);

        }
        else if(_pid == 2){

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

            uint temp = amount;
            uint multiplier = ( perDollarPrice  * temp ) / 10 ** 18;
            if(userBuy[msg.sender]==0){
                buyers.push(msg.sender);
                userFirstBuyDate[msg.sender] = block.timestamp;
            }
            userBuy[msg.sender] +=multiplier;
            //token.transfer(msg.sender,multiplier);
        }
        else if(_pid == 3){
            require(usdc.allowance(msg.sender, address(this))>0, "Not enough allowance");
            usdc.transferFrom(msg.sender,address(this),amount);
            if(check == 2){
                uint per5 = ( amount * 5 ) / 100;
                uint per95 = ( amount * 95 ) / 100;
                usdc.transfer(ref,per5);
                usdc.transfer(owner,per95);
            }else{
                usdc.transfer(owner,amount);
            }
            uint temp = amount;
            uint multiplier = ( perDollarPrice  * temp ) / 10 ** 18;
            
            if(userBuy[msg.sender]==0){
                buyers.push(msg.sender);
                userFirstBuyDate[msg.sender] = block.timestamp;
            }
            userBuy[msg.sender] +=multiplier;
            
            // //token.transfer(msg.sender,multiplier);
        }
        else{
            revert("wrong selection");
        }

        

    }

    function buyFromNative(address ref) public payable {

        require(msg.value>=0.17 ether, "Invalid amount");
        require(!paused,"Presale is Paused!!");


        uint check = 1;   

        if(ref == address(0) || ref == msg.sender || referral[msg.sender][ref]){}
        else{
            referral[msg.sender][ref] = true;
            check = 2;
        }

        uint value = msg.value;

        uint equaltousd = value / UsdtoBnb;

        uint multiplier = perDollarPrice  * equaltousd;

        //token.transfer(msg.sender,multiplier);
        if(userBuy[msg.sender]==0){
                buyers.push(msg.sender);
                userFirstBuyDate[msg.sender] = block.timestamp;
            }
        userBuy[msg.sender] +=multiplier;

        if(check == 2){
            uint per5 = ( value * 5 ) / 100;
            uint per95 = ( value * 95 ) / 100;
            payable(ref).transfer(per5);
            payable(owner).transfer(per95);
        }
        else{
            payable(owner).transfer(value);
        }

    }


    function releaseToken(address _receiver) public{
        require(block.timestamp-userFirstBuyDate[msg.sender]>releaseDelay, "1 year has not passed yet.");
        require(userBuy[msg.sender]>0, "Receiver have not bought any token");
        userBuy[msg.sender] = 0;
        token.transfer(msg.sender,userBuy[_receiver]);
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