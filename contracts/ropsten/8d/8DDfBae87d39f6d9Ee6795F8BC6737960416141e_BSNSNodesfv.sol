/**
 *Submitted for verification at Etherscan.io on 2022-06-19
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-18
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

    function owner() public view virtual returns (address) {
        return _owner;
    }


    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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


interface IERC20 {
  
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BSNSNodesfv is Ownable {

    using SafeMath for uint256;

    IERC20 public token;
    address public deductionReciever;
    bool public paused;

    //days to percentage
    /*
        A) 1-5 (25%}
        B) 6-10 days (20%)
        C) 11-15 days (15%)
        D) 16-20 days (10%)
        E) 21-25 days (5%)
        F) 26-30 days (3%)
        G) more than 30 days (2%)
    */
    uint tokendecimal = 18;

    uint public minStakeAmount = 100 * 10 ** tokendecimal;
    uint public maxStakeAmount = 100000 * 10 ** tokendecimal;
    
    uint public generationTime = 2 minutes;

    uint public totalStakedSoFar;

    mapping(uint256 => mapping (uint256 => uint256)) public timeslots;
   
    mapping(uint256 => mapping (uint256 => uint256)) public slotAmount;

    struct database {
        uint256 userindex;
        uint256 usertimeslotIndexs;  //incrementable start from 
        uint256 totalStaked;
        uint256 stakeStart;
        uint256 userExists;
    }

    mapping(address => database) public record;

    uint256 public totalStakers;

    constructor(address _token,
                address _deductionWallet
    ) {
        token = IERC20(_token);
        deductionReciever = _deductionWallet;
    }

    function stake(uint _amount) public {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        require(_amount >= minStakeAmount && _amount <= maxStakeAmount,"Error: Value Exceed from Limit!");

        token.transferFrom(msg.sender,address(this),_amount);

        totalStakedSoFar+=_amount;

        store(msg.sender,block.timestamp,_amount);
    }

    function store(address _user, uint256 time, uint _amount) internal {

        if(record[_user].userExists == 1){
            record[_user].usertimeslotIndexs++;
        }
        
        if(record[_user].userExists != 1) {
            totalStakers++;
            record[_user].userindex = totalStakers;
            record[_user].userExists = 1;
            record[_user].usertimeslotIndexs = 1;
            record[_user].stakeStart = block.timestamp;
        }

        if(record[_user].stakeStart == 0) {
            record[_user].stakeStart = block.timestamp;
        }

        record[_user].totalStaked += _amount;

        timeslots[record[_user].userindex][record[_user].usertimeslotIndexs] = time;
        slotAmount[record[_user].userindex][timeslots[record[_user].userindex][record[_user].usertimeslotIndexs]] = _amount;
        
    }

    function calapy(uint _amount) internal pure returns (uint){
        uint num = _amount.mul(15).div(10e2);
        return num.div(31536000);
    }

    function calreward(uint _time) internal view returns (uint) {
        uint sec = block.timestamp.sub(_time);
        return sec;
    }

    function unstake() public {

        require(!paused,"We are Closed due to some reasons!! Will back soon :");

        require(record[msg.sender].stakeStart + generationTime <= block.timestamp,"Error: New Staker Need 24 Hours to Unstake!!");

        uint currentTime = block.timestamp;   //block.timestamp;
        uint userslot = record[msg.sender].userindex;
        uint totalTimeslots = record[msg.sender].usertimeslotIndexs; 

        require(record[msg.sender].totalStaked > 0,"You have Zero Amount to Release!!");

        uint totalAmount;
        uint totalDeduction;
        uint AmountwithApy;

        for(uint i = 1; i <= totalTimeslots; i++) {

            uint _slottime = timeslots[userslot][i];
            uint _runningAmount = slotAmount[userslot][_slottime];

            if(_slottime + 5 minutes > currentTime){   //1-5 days (25%}
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(25).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

            else if(_slottime + 10 minutes > currentTime){   //6-10 days (20%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(20).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

            else if(_slottime + 15 minutes > currentTime){   //11-15 days (15%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(15).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

            else if(_slottime + 20 minutes > currentTime){   //16-20 days (10%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(10).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

            else if(_slottime + 25 minutes > currentTime){   //21-25 days (5%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(5).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }
            
            else if(_slottime + 30 minutes > currentTime){   //26-30 days (3%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(3).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

            else {  // >30 days (2%)
                totalAmount += _runningAmount;
                totalDeduction += _runningAmount.mul(2).div(100);
                uint sec = calreward(_slottime);
                uint factor = calapy(_runningAmount);
                AmountwithApy += sec.mul(factor);
            }

        }

        require(totalAmount > 0,"Error: 404!");

        uint256 afterDeduction = totalAmount.sub(totalDeduction);
        uint256 SubTotal = afterDeduction.add(AmountwithApy);

        token.transfer(deductionReciever,totalDeduction);
        token.transfer(msg.sender,SubTotal);

        removeStaker(msg.sender);

    }

    function removeStaker(address _user) internal {
        record[_user].usertimeslotIndexs = 0;
        record[_user].totalStaked = 0;
        record[_user].stakeStart = 0;
    }

    //donot change if the contract is working
    function setToken(address _adr) public onlyOwner {
        token = IERC20(_adr);
    }

    function setTokenDecimal(uint _dec) public onlyOwner {
        tokendecimal = _dec;
    }

    function emergencyPause(bool _status) public onlyOwner {
        paused = _status;
    }

    function setDeductionWallet(address _adr) public onlyOwner {
        deductionReciever = _adr;
    }

    function setUnstakeTimeI(uint _time) public onlyOwner {
        generationTime = _time;
    }

    function rescueToken(address _erc20,address recipient,uint _amount) public onlyOwner {
        IERC20(_erc20).transfer(recipient,_amount);
    }

    function rescueFunds() public onlyOwner {
        (bool os,) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }


}