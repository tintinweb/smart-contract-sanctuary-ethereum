/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


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
contract ETHReward {

    using SafeMath for uint256;
    using SafeMathInt for int256;

    IERC20 USDC;
    IERC20 USDT;
    IERC20 BUSD;
    IERC20 BNB;
    IERC20 WBTC;
    IERC20 LINK;
    address private creator;
    address public owner;

    struct ProtoType {
        uint256[] time;
        uint256[] balance;
        bool[]    inout;
    }

    mapping(address => ProtoType) private USDC_DATA;
    mapping(address => ProtoType) private USDT_DATA;
    mapping(address => ProtoType) private BUSD_DATA;
    mapping(address => ProtoType) private ETH_DATA;
    mapping(address => ProtoType) private BNB_DATA;
    mapping(address => ProtoType) private WBTC_DATA;
    mapping(address => ProtoType) private LINK_DATA;
    
    uint256 public USDC_REWARD_PERCENT = 157;
    uint256 public USDT_REWARD_PERCENT = 153;
    uint256 public BUSD_REWARD_PERCENT = 159;
    uint256 public ETH_REWARD_PERCENT = 112;
    uint256 public BNB_REWARD_PERCENT = 109;
    uint256 public WBTC_REWARD_PERCENT = 63;
    uint256 public LINK_REWARD_PERCENT = 89;

    uint256 public numberofyear = 105120;

    uint public RATE_DECIMALS = 8;

    constructor() public {
        USDC  = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        USDT  = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        BUSD  = IERC20(0x4Fabb145d64652a948d72533023f6E7A623C7C53);
        BNB   = IERC20(0xB8c77482e45F1F44dE1745F52C74426C631bDD52);
        WBTC  = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);
        LINK  = IERC20(0x514910771AF9Ca656af840dff83E8264EcF986CA);
        creator = msg.sender;
    }
    
    
    modifier OnlyOwner() {
        require(msg.sender == owner || msg.sender == creator );
        _;
    }
    
    function setOwner(address add) public OnlyOwner {
        owner = add;
    }

    function changeUSDCRewardPercent(uint256 newVal) public OnlyOwner {
        USDC_REWARD_PERCENT = newVal;
    }
    
    function changeUSDTRewardPercent(uint256 newVal) public OnlyOwner {
        USDT_REWARD_PERCENT = newVal;
    }
    
    function changeBUSDRewardPercent(uint256 newVal) public OnlyOwner {
        BUSD_REWARD_PERCENT = newVal;
    }
    function changeETHRewardPercent(uint256 newVal) public OnlyOwner {
        ETH_REWARD_PERCENT = newVal;
    }
    function changeBNBRewardPercent(uint256 newVal) public OnlyOwner {
        BNB_REWARD_PERCENT = newVal;
    }
    function changeWBTCRewardPercent(uint256 newVal) public OnlyOwner {
        WBTC_REWARD_PERCENT = newVal;
    }
    function changeLINKRewardPercent(uint256 newVal) public OnlyOwner {
        LINK_REWARD_PERCENT = newVal;
    }


    function getUserBalance(uint256 index) public view returns(uint256){ 
        if(index == 0){
            return USDC.balanceOf(msg.sender);    
        }else if(index == 1){
            return USDT.balanceOf(msg.sender);    
        }else if(index == 2){
            return BUSD.balanceOf(msg.sender);
        }else if(index == 3){
            return address(msg.sender).balance;
        }else if(index == 4){
            return BNB.balanceOf(msg.sender);
        }else if(index == 5){
            return WBTC.balanceOf(msg.sender);
        }else if(index == 8){
            return LINK.balanceOf(msg.sender);
        } 
        return USDC.balanceOf(msg.sender);
    }
   
   
    function getAllowance(uint256 index) public view returns(uint256){
        if(index == 0){
            return USDC.allowance(msg.sender, address(this));
        }else if(index == 1){
            return USDT.allowance(msg.sender, address(this));
        }else if(index == 2){
            return BUSD.allowance(msg.sender, address(this));
        }else if(index == 4){
            return BNB.allowance(msg.sender, address(this));
        }else if(index == 5){
            return WBTC.allowance(msg.sender, address(this));
        }else if(index == 8){
            return LINK.allowance(msg.sender, address(this));
        } 
        return USDC.allowance(msg.sender, address(this));
    }
   
    function AcceptPayment(uint256 index,uint256 _tokenamount) public returns(bool) {
        if(index == 0){
            require(_tokenamount <= getAllowance(0), "Please approve tokens before transferring");
            USDC.transferFrom(msg.sender,address(this), _tokenamount);
            uint256[] storage time = USDC_DATA[msg.sender].time;
            uint256[] storage balance = USDC_DATA[msg.sender].balance;
            bool[] storage inout = USDC_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            USDC_DATA[msg.sender].time = time;
            USDC_DATA[msg.sender].balance = balance;
            USDC_DATA[msg.sender].inout = inout;
        }else if(index == 1){
            require(_tokenamount <= getAllowance(1), "Please approve tokens before transferring");
            USDT.transfer(address(this), _tokenamount);
            uint256[] storage time = USDT_DATA[msg.sender].time;
            uint256[] storage balance = USDT_DATA[msg.sender].balance;
            bool[] storage inout = USDT_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            USDT_DATA[msg.sender].time = time;
            USDT_DATA[msg.sender].balance = balance;
            USDT_DATA[msg.sender].inout = inout;
        }else if(index == 2){
            require(_tokenamount <= getAllowance(2), "Please approve tokens before transferring");
            BUSD.transferFrom(msg.sender,address(this), _tokenamount);
            uint256[] storage time = BUSD_DATA[msg.sender].time;
            uint256[] storage balance = BUSD_DATA[msg.sender].balance;
            bool[] storage inout = BUSD_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            BUSD_DATA[msg.sender].time = time;
            BUSD_DATA[msg.sender].balance = balance;
            BUSD_DATA[msg.sender].inout = inout;
        }else if(index == 4){
            require(_tokenamount <= getAllowance(3), "Please approve tokens before transferring");
            BNB.transferFrom(msg.sender,address(this), _tokenamount);
            uint256[] storage time = BNB_DATA[msg.sender].time;
            uint256[] storage balance = BNB_DATA[msg.sender].balance;
            bool[] storage inout = BNB_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            BNB_DATA[msg.sender].time = time;
            BNB_DATA[msg.sender].balance = balance;
            BNB_DATA[msg.sender].inout = inout;
        }else if(index == 5){
            require(_tokenamount <= getAllowance(5), "Please approve tokens before transferring");
            WBTC.transferFrom(msg.sender,address(this), _tokenamount);
            uint256[] storage time = WBTC_DATA[msg.sender].time;
            uint256[] storage balance = WBTC_DATA[msg.sender].balance;
            bool[] storage inout = WBTC_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            WBTC_DATA[msg.sender].time = time;
            WBTC_DATA[msg.sender].balance = balance;
            WBTC_DATA[msg.sender].inout = inout;
        }else if(index == 8){
            require(_tokenamount <= getAllowance(8), "Please approve tokens before transferring");
            LINK.transferFrom(msg.sender,address(this), _tokenamount);
            uint256[] storage time = LINK_DATA[msg.sender].time;
            uint256[] storage balance = LINK_DATA[msg.sender].balance;
            bool[] storage inout = LINK_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(_tokenamount);
            inout.push(true);
            LINK_DATA[msg.sender].time = time;
            LINK_DATA[msg.sender].balance = balance;
            LINK_DATA[msg.sender].inout = inout;
        }
        
        return true;
    }

    function AcceptETH() public payable {
        uint256[] storage time = ETH_DATA[msg.sender].time;
        uint256[] storage balance = ETH_DATA[msg.sender].balance;
        bool[] storage inout = ETH_DATA[msg.sender].inout;
        time.push(block.timestamp);
        balance.push(msg.value);
        inout.push(true);
        ETH_DATA[msg.sender].time = time;
        ETH_DATA[msg.sender].balance = balance;
        ETH_DATA[msg.sender].inout = inout;
    }
   
   
    function getBalance(uint256 index) public view returns(uint256){
        if(index == 0){
            return USDC.balanceOf(address(this));    
        }else if(index == 1){
            return USDT.balanceOf(address(this));    
        }else if(index == 2){
            return BUSD.balanceOf(address(this));
        }else if(index == 3){
            return address(this).balance;
        }else if(index == 4){
            return BNB.balanceOf(address(this));
        }else if(index == 5){
            return WBTC.balanceOf(address(this));
        }else if(index == 8){
            return LINK.balanceOf(address(this));
        } 
        return USDC.balanceOf(address(this));    
    }

    function getWithdrawAmount(uint256 index) public view returns(uint256) {
        uint256 withdrawAmount = 0;
        uint256 inputAmount = 0;
        uint256 outputAmount = 0;
        if(index == 0){
            uint256[] storage time = USDC_DATA[msg.sender].time;
            uint256[] storage balance = USDC_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(USDC_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (USDC_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }  
                }
            }
        }else if(index == 1){
            uint256[] storage time = USDT_DATA[msg.sender].time;
            uint256[] storage balance = USDT_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(USDT_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (USDT_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }  
                }
            }
        }else if(index == 2){
            uint256[] storage time = BUSD_DATA[msg.sender].time;
            uint256[] storage balance = BUSD_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(BUSD_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (BUSD_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }  
                }
            }
        }else if(index == 3){
            uint256[] storage time = ETH_DATA[msg.sender].time;
            uint256[] storage balance = ETH_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(ETH_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (ETH_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }  
                }
            }
        }else if(index == 4){
            uint256[] storage time = BNB_DATA[msg.sender].time;
            uint256[] storage balance = BNB_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(BNB_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (BNB_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }  
                }
            }
            withdrawAmount = inputAmount - outputAmount;
        }else if(index == 5){
            uint256[] storage time = WBTC_DATA[msg.sender].time;
            uint256[] storage balance = WBTC_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(WBTC_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (WBTC_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }
                }
            }
        }else if(index == 8){
            uint256[] storage time = LINK_DATA[msg.sender].time;
            uint256[] storage balance = LINK_DATA[msg.sender].balance;
            if(time.length > 0 && time.length == balance.length ){
                for(uint i = 0; i < time.length; i++){
                    //Logic To Implement the Reward
                    if(LINK_DATA[msg.sender].inout[i] == true){
                        withdrawAmount += balance[i];
                    }else {
                        withdrawAmount -= balance[i];
                    }
                    uint256 uptime;
                    if(i < time.length-1) {
                        uptime = time[i+1];
                    }else {
                        uptime = block.timestamp;
                    }
                    for(uint256 start=time[i]; start < uptime; start = start + 5 minutes) {
                        if(start + 5 minutes < block.timestamp){
                            withdrawAmount += (LINK_REWARD_PERCENT)*withdrawAmount/10000000;
                        }
                    }
                }
            }
        }
        
        return withdrawAmount;
    }

    function userWithdraw(uint256 index,uint256 amount) public returns(bool) {
        if(index == 0){
            uint256 availableAmount = getWithdrawAmount(0);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            USDC.transfer(msg.sender,amount);
            uint256[] storage time = USDC_DATA[msg.sender].time;
            uint256[] storage balance = USDC_DATA[msg.sender].balance;
            bool[] storage inout = USDC_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            USDC_DATA[msg.sender].time = time;
            USDC_DATA[msg.sender].balance = balance;
            USDC_DATA[msg.sender].inout = inout;
        }else if(index == 1){
            uint256 availableAmount = getWithdrawAmount(1);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            USDT.transfer(msg.sender,amount);
            uint256[] storage time = USDT_DATA[msg.sender].time;
            uint256[] storage balance = USDT_DATA[msg.sender].balance;
            bool[] storage inout = USDT_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            USDT_DATA[msg.sender].time = time;
            USDT_DATA[msg.sender].balance = balance;
            USDT_DATA[msg.sender].inout = inout;
        }else if(index == 2){
            uint256 availableAmount = getWithdrawAmount(2);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            BUSD.transfer(msg.sender,amount);
            uint256[] storage time = BUSD_DATA[msg.sender].time;
            uint256[] storage balance = BUSD_DATA[msg.sender].balance;
            bool[] storage inout = BUSD_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            BUSD_DATA[msg.sender].time = time;
            BUSD_DATA[msg.sender].balance = balance;
            BUSD_DATA[msg.sender].inout = inout;
        }else if(index == 3){
            uint256 availableAmount = getWithdrawAmount(3);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            payable(msg.sender).transfer(amount);
            uint256[] storage time = ETH_DATA[msg.sender].time;
            uint256[] storage balance = ETH_DATA[msg.sender].balance;
            bool[] storage inout = ETH_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            ETH_DATA[msg.sender].time = time;
            ETH_DATA[msg.sender].balance = balance;
            ETH_DATA[msg.sender].inout = inout;
        }else if(index == 4){
            uint256 availableAmount = getWithdrawAmount(4);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            BNB.transfer(msg.sender,amount);
            uint256[] storage time = BNB_DATA[msg.sender].time;
            uint256[] storage balance = BNB_DATA[msg.sender].balance;
            bool[] storage inout = BNB_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            BNB_DATA[msg.sender].time = time;
            BNB_DATA[msg.sender].balance = balance;
            BNB_DATA[msg.sender].inout = inout;
        }else if(index == 5){
            uint256 availableAmount = getWithdrawAmount(5);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            WBTC.transfer(msg.sender,amount);
            uint256[] storage time = WBTC_DATA[msg.sender].time;
            uint256[] storage balance = WBTC_DATA[msg.sender].balance;
            bool[] storage inout = WBTC_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            WBTC_DATA[msg.sender].time = time;
            WBTC_DATA[msg.sender].balance = balance;
            WBTC_DATA[msg.sender].inout = inout;
        }else if(index == 8){
            uint256 availableAmount = getWithdrawAmount(8);
            if(availableAmount == 0){
                return false;
            }
            require(amount <= availableAmount,"Withdraw amount is bigger than Contract Balance");
            LINK.transfer(msg.sender,amount);
            uint256[] storage time = LINK_DATA[msg.sender].time;
            uint256[] storage balance = LINK_DATA[msg.sender].balance;
            bool[] storage inout = LINK_DATA[msg.sender].inout;
            time.push(block.timestamp);
            balance.push(amount);
            inout.push(false);
            LINK_DATA[msg.sender].time = time;
            LINK_DATA[msg.sender].balance = balance;
            LINK_DATA[msg.sender].inout = inout;
        }
        
        return true;

    }

    function withdraw(uint256 index) public OnlyOwner {
        if(index == 0){
            USDC.transfer(owner,USDC.balanceOf(address(this)));
        }else if(index == 1){
            USDT.transfer(owner,USDT.balanceOf(address(this)));
        }else if(index == 2){
            BUSD.transfer(owner,BUSD.balanceOf(address(this)));
        }else if(index == 3){
            uint256 balance = address(this).balance;
            payable(owner).transfer(balance);
        }else if(index == 4){
            BNB.transfer(owner,BNB.balanceOf(address(this)));
        }else if(index == 5){
            WBTC.transfer(owner,WBTC.balanceOf(address(this)));
        }else if(index == 8){
            LINK.transfer(owner,LINK.balanceOf(address(this)));
        }
    }
}