// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "./NFT.sol";
library Counters {
    struct Counter {
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract TokenStaking {
    using Counters for Counters.Counter;
    string public name = "Token Staking";
    address public owner;
    TNFT public rewardNFT;
    IERC20 public Token;
    uint256 amount;
    address[] public stakers;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasStaked;
    mapping(address => bool) public isStaking;
    mapping(address => mapping (IERC20 => bool))  istokenstaking;
    mapping(address => uint256) public _balances;
    uint256 private releasetime ;
    mapping(TNFT =>  uint256) public tokenId;
    Counters.Counter private _claimstakeNumber;
    Counters.Counter private _unlockedstakeNumber;
    struct Stake {
        IERC721 reward_NFT;
        IERC20 _token;
        address claimer;
        uint256 amount;
        uint256 releasetime;
    }
    Stake[] allstake;
    constructor(TNFT _rewardNFT,uint256 _amount) {
        owner = msg.sender;
        rewardNFT = _rewardNFT ;
        rewardNFT.internalMint(address(this),_amount);
        tokenId[_rewardNFT] = _amount;
    }
    function stakeTokens(IERC20 _token,uint256 _amount) public {
        _amount = _amount * 10 ** 18;
        require(_amount > 0, "amount can not be zero"); //if amount is zero
        require (istokenstaking[msg.sender][_token] != true,"user already staked this token ");
        Token = _token;
        Token.transferFrom(msg.sender, address(this), _amount); //transfer token
        stakingBalance[msg.sender] += _amount; //update the staking balanace
        if (!hasStaked[msg.sender]) {
            stakers.push(msg.sender); // add user to staker array
        }
        isStaking[msg.sender] = true; // update staking status for the user
        hasStaked[msg.sender] = true;
        amount = _amount;
        releasetime = block.timestamp ;
        istokenstaking[msg.sender][_token] = true;
        _balances[address(this)] = _amount;
        allstake.push(
            Stake(
                rewardNFT,
                _token,
                msg.sender,
                amount,
                releasetime
            )
        );
        _unlockedstakeNumber.increment();
    }
    function unstakeToken() public {
        uint256 balance = stakingBalance[msg.sender]; //fetch balance of staker
        require (stakingBalance[msg.sender] > 0 ,"staking balance should be greater than zero");
        require(balance > 0, "staking balance is zero"); // check if balance is zero 
        uint256 tokenID ;
        tokenID ++;
        Token.transferFrom(address(this),msg.sender, balance); //transfer back token to use
        rewardNFT.transferFrom(address(this),(msg.sender), tokenID);
        _balances[msg.sender] = tokenID;     
        stakingBalance[msg.sender] = 0; // set staking balance to zero
        isStaking[msg.sender] = false; // update the staking status
        istokenstaking[msg.sender][Token] = false;
    }
}