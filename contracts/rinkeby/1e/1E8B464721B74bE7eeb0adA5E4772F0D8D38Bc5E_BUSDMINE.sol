/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
    }

    function owner() public view returns (address) {
      return _owner;
    }

    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }
}

interface ERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract BUSDMINE is Context, Ownable {
    address constant BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint256 constant private DEPOSIT_FEE = 10;
    uint256 constant private COLLECT_FEE = 8;
    uint256 constant private REFERRAL_BONUS = 10;
    uint256 constant private MIN_DEPOSIT = 20 * 10**18;
    bool private initialized = false;

    struct User {
		uint256 deposit;
        uint256 withdraw;
		uint256 lastTime;
		uint256 bonus;
		uint256 totalBonus;
	}

    mapping (address => User) private users;

    constructor() {
    }
    
    function collect() external {
        require(initialized, "err: not started");

        address msgSender = _msgSender();
        require(users[msgSender].lastTime > 0, "err: no deposit");

        uint256 maxCollect = users[msgSender].deposit * 3;
        require(users[msgSender].withdraw < maxCollect, "err: shouldn't withdraw more than 3X");

        uint256 amount = getRewards(msgSender);
        uint256 realAmount = amount * (100 - COLLECT_FEE) / 100;
        if (users[msgSender].withdraw + realAmount > maxCollect) {
            amount = (maxCollect - users[msgSender].withdraw) * 100 / (100 - COLLECT_FEE);
        }

        uint256 fee = amount * COLLECT_FEE / 100;
        ERC20(BUSD).transfer(owner(), fee);

        users[msgSender].lastTime = block.timestamp;
        users[msgSender].withdraw += amount - fee;

        ERC20(BUSD).transfer(msgSender, amount - fee);
    }
    
    function deposit(address ref, uint256 amount) external {
        require(initialized, "err: not started");
        require(amount >= MIN_DEPOSIT, "err: should deposit at least 20 BUSD");

        address msgSender = _msgSender();

        ERC20(BUSD).transferFrom(msgSender, address(this), amount);

        uint256 fee = amount * DEPOSIT_FEE / 100;
        ERC20(BUSD).transfer(owner(), fee);

        uint256 reward_amount = getRewards(msgSender);
        users[msgSender].deposit += amount - fee + reward_amount;

        users[msgSender].lastTime = block.timestamp;

        // referral
        if(ref == msgSender) {
            ref = address(0);
        }
        
        if (ref != address(0))
        {
            uint256 referralFee = amount * REFERRAL_BONUS / 100;
            users[ref].bonus += referralFee;
            users[ref].totalBonus += referralFee;
        }
    }
    
    function compoundRef() external {
        require(initialized, "err: not started");

        address msgSender = _msgSender();
        require(users[msgSender].bonus > 0, "err: zero amount");

        uint256 reward_amount = getRewards(msgSender);
        users[msgSender].deposit += users[msgSender].bonus + reward_amount;
        users[msgSender].bonus = 0;
        users[msgSender].lastTime = block.timestamp;
    }

    function collectRef() external {
        require(initialized, "err: not started");

        address msgSender = _msgSender();
        require(users[msgSender].bonus > 0, "err: zero amount");

        ERC20(BUSD).transfer(msgSender, users[msgSender].bonus);
        users[msgSender].bonus = 0;
    }
    
    function start() public onlyOwner {
        require(initialized == false, "err: already started");
        initialized=true;
    }
    
	function getUserReferralBonus(address addr) external view returns(uint256) {
		return users[addr].bonus;
	}

	function getUserReferralWithdrawn(address addr) external view returns(uint256) {
		return users[addr].totalBonus - users[addr].bonus;
	}

	function getUserDepositAmount(address addr) external view returns(uint256) {
		return users[addr].deposit;
	}

	function getUserWithdrawAmount(address addr) external view returns(uint256) {
		return users[addr].withdraw;
	}

	function getUserCheckPoint(address addr) external view returns(uint256) {
		return users[addr].lastTime;
	}

    function getRewards(address addr) public view returns(uint256) {
        uint256 secondsPassed = block.timestamp - users[addr].lastTime;
        return secondsPassed * users[addr].deposit / 2880000;
    }
}