//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IERC20.sol";

/// @title staking contract for stake uniswap v2 lp tokens
/// @dev reward calculates every rewardPeriod and depends on rewardPercent and lpAmount per period
contract Staking {
    struct Stake {
        uint256 lpAmount;
        uint256 rewardAmount;
        uint256 startTime;
    }

    IUniswapV2Pair tokenPair;
    IERC20 rewardToken;

    mapping(address => Stake) private _stakes;

    address public owner;

    uint256 public freezePeriod = 30 * 60;
    uint256 public rewardPeriod = 10 * 60;
    uint256 public rewardPercent = 15;

    event Staked(address from, uint256 amount);
    event Unstaked(address to, uint256 amount);
    event Claimed(address to, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner allowed");
        _;
    }

    constructor(IUniswapV2Pair tokenPair_, IERC20 rewardToken_) {
        owner = msg.sender;
        tokenPair = tokenPair_;
        rewardToken = rewardToken_;
    }

    function stake(uint256 amount) public {
        require(
            tokenPair.balanceOf(msg.sender) >= amount,
            "not enough balance"
        );
        require(
            tokenPair.allowance(msg.sender, address(this)) >= amount,
            "not enough allowed"
        );

        if (_stakes[msg.sender].lpAmount > 0) {
            _stakes[msg.sender].rewardAmount += _calcReward(msg.sender);
            _stakes[msg.sender].lpAmount += amount;
        } else {
            _stakes[msg.sender].lpAmount = amount;
        }

        _stakes[msg.sender].startTime = block.timestamp;
        tokenPair.transferFrom(msg.sender, address(this), amount);

        emit Staked(msg.sender, amount);
    }

    function unstake() public {
        require(
            block.timestamp > _stakes[msg.sender].startTime + freezePeriod,
            "tokens still freezed"
        );

        _stakes[msg.sender].rewardAmount += _calcReward(msg.sender);
        uint256 lpAmount = _stakes[msg.sender].lpAmount;
        _stakes[msg.sender].lpAmount = 0;
        tokenPair.transfer(msg.sender, lpAmount);

        emit Unstaked(msg.sender, lpAmount);
    }

    function claim() public {
        uint256 rewardAmount = _stakes[msg.sender].rewardAmount + _calcReward(msg.sender);
        require(rewardAmount > 0, "nothing to claim");

        _stakes[msg.sender].rewardAmount = 0;
        _stakes[msg.sender].startTime = block.timestamp;
        rewardToken.transfer(msg.sender, rewardAmount);

        emit Claimed(msg.sender, rewardAmount);
    }

    function setFreezePeriod(uint256 freezePeriod_) public onlyOwner {
        freezePeriod = freezePeriod_;
    }

    function setRewardPeriod(uint256 rewardPeriod_) public onlyOwner {
        rewardPeriod = rewardPeriod_;
    }

    function setRewardPercent(uint256 rewardPercent_) public onlyOwner {
        rewardPercent = rewardPercent_;
    }

    function getStakeData()
        public
        view
        returns (
            uint256 lpAmount,
            uint256 rewardAmount,
            uint256 startTime
        )
    {
        return (
            _stakes[msg.sender].lpAmount,
            _stakes[msg.sender].rewardAmount,
            _stakes[msg.sender].startTime
        );
    }

    function _calcReward(address addr) private view returns (uint256) {
        uint256 rewardPeriodsCount = (block.timestamp - _stakes[addr].startTime) / rewardPeriod;
        return (rewardPeriodsCount * _stakes[addr].lpAmount * rewardPercent) / 100;
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

pragma solidity >=0.5.0;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}