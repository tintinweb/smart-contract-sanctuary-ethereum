/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
            // Gas optimization: this is cheaper than requiring "a" not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}


contract ClaimAndAirdrop{
    using SafeMath for uint256;

    struct UserInfo {
        bool isWL;
        uint256 amount;
        uint256 perSecond;
        uint256 lastClaimTime;
        uint256 debt;
    }

    uint256 constant public vestingPeriod = 100 days;
    uint256 public claimStartTimestamp;
    uint256 public claimEndTimestamp;

    IERC20 public DEFIRM = IERC20(0x8544C3CC379Fb7B6E022BD010e3D0dA474385582);
    IERC20 public pDEFIRM = IERC20(0x53bB943D9Fc7C501A46D88824aC171E269d2d97F);
    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    address public owner;
    bool public claimEnabled;
    uint256 public totalburntpDefirm;
    uint256 public totalclaimedDefirm;
    uint256 public totalAirdropped;    

    mapping (address => UserInfo) public userinfo;

    modifier onlyOwner() {
        require(owner == msg.sender, "caller is not the owner");
        _;
    }

    constructor ()  {	
        owner = msg.sender;	
    }

    function openClaim() external onlyOwner{
        claimStartTimestamp = block.timestamp;
        claimEndTimestamp = claimStartTimestamp.add(vestingPeriod);
    }

    function togglePause() external onlyOwner{
        claimEnabled = !claimEnabled;
    }

    function claim() public {
        UserInfo storage user = userinfo[msg.sender];
        if(msg.sender != owner){
            require(claimEnabled, "paused");
        }        
        require(user.isWL, "not whitelisted");

        uint256 availableAmount = getAvailamount(msg.sender);
        uint256 contractBalance = DEFIRM.balanceOf(address(this));

        require(availableAmount > 0, "invalid amount");
        require(user.amount >= availableAmount, "insufficient allowed amount");
        require(contractBalance > 0, "insufficient contract balance");

        if(contractBalance < availableAmount) {
            user.debt = availableAmount.sub(contractBalance);
            availableAmount = contractBalance;            
        } else {
            user.debt = 0;
        }

        user.amount -= availableAmount;
        user.lastClaimTime = block.timestamp;
        DEFIRM.transfer(msg.sender, availableAmount);
        totalAirdropped += availableAmount;

        if(msg.sender == owner){
            claimEnabled = true;
        }
    }

    function exchange() public {
        if(msg.sender != owner){
            require(claimEnabled, "not started");
        }
        uint256 pDefirmAmount = pDEFIRM.balanceOf(msg.sender);
        require(pDefirmAmount>0, "invalid balance");
        uint256 DefirmAmount = pDefirmAmount.mul(10 ** 13).mul(105).div(100);
        require(DEFIRM.balanceOf(address(this)) >= DefirmAmount, "insufficient balance");
        totalburntpDefirm += pDefirmAmount;
        totalclaimedDefirm += DefirmAmount;
        pDEFIRM.transferFrom(msg.sender, BURN_ADDRESS, pDefirmAmount);
        DEFIRM.transfer(msg.sender, DefirmAmount);
    }

    function setWhiteList(address[] memory _accounts, uint256[] memory _amounts, bool _value) public onlyOwner {
      for(uint256 i = 0; i < _accounts.length; i++) {
            UserInfo storage user = userinfo[_accounts[i]];
            user.isWL = _value;
            user.amount = _amounts[i];
            user.perSecond = user.amount.div(vestingPeriod);
        }
    }

    function setDefirmTokens(address _defirm, address _pdefirm) external onlyOwner{
        require(_defirm != address(0), "wrong");
        require(_defirm != address(0), "wrong");
        DEFIRM = IERC20(_defirm);
        pDEFIRM = IERC20(_pdefirm);
    }

    function sendTokens(address _token, uint256 _amount, address payable _to) external onlyOwner {
        require(IERC20(_token).balanceOf(address(this)) >= _amount, "Invalid amount");
        require(_to != address(0), "Invalid address");
        if(_token == address(0)){
            _to.transfer(address(this).balance);
        } else {
            IERC20(_token).transfer(_to, _amount);
        }
    }

    function getAvailamount(address _user) public view returns(uint256){

        UserInfo storage user = userinfo[_user];

        uint256 period = 0;
        if(block.timestamp <= claimEndTimestamp) {
            if(user.lastClaimTime == 0) {
                period = block.timestamp.sub(claimStartTimestamp);    
            } else {
                period = block.timestamp.sub(user.lastClaimTime);    
            }     
        } else {
            if(user.lastClaimTime == 0) {
                period = claimEndTimestamp.sub(claimStartTimestamp);
            } else {
                period = claimEndTimestamp.sub(user.lastClaimTime);    
            }
        }

        return user.debt.add(user.perSecond.mul(period));
    }
    
    function transferOwnerShip(address _owner) external onlyOwner{
        owner = _owner;
    }
}