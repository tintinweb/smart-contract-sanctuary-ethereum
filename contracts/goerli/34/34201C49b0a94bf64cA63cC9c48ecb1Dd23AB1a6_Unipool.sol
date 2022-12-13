// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "../Dependencies/LiquityMath.sol";
import "../Dependencies/Ownable.sol";
import "../Dependencies/CheckContract.sol";
import "../Interfaces/ILQTYToken.sol";
import "./Dependencies/SafeERC20.sol";
import "./Interfaces/ILPTokenWrapper.sol";
import "./Interfaces/IUnipool.sol";
import "../Dependencies/console.sol";


// Adapted from: https://github.com/Synthetixio/Unipool/blob/master/contracts/Unipool.sol
// Some more useful references:
// Synthetix proposal: https://sips.synthetix.io/sips/sip-31
// Original audit: https://github.com/sigp/public-audits/blob/master/synthetix/unipool/review.pdf
// Incremental changes (commit by commit) from the original to this version: https://github.com/liquity/dev/pull/271

// LPTokenWrapper contains the basic staking functionality
contract LPTokenWrapper is ILPTokenWrapper {
    using SafeERC20 for IERC20;

    IERC20 public uniToken;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function stake(uint256 amount) public virtual override {
        _totalSupply = _totalSupply + amount;
        _balances[msg.sender] = _balances[msg.sender] + amount;
        uniToken.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint256 amount) public virtual override {
        _totalSupply = _totalSupply - amount;
        _balances[msg.sender] = _balances[msg.sender] - amount;
        uniToken.safeTransfer(msg.sender, amount);
    }
}

/*
 * On deployment a new Uniswap pool will be created for the pair LUSD/ETH and its token will be set here.

 * Essentially the way it works is:

 * - Liquidity providers add funds to the Uniswap pool, and get UNIv2 LP tokens in exchange
 * - Liquidity providers stake those UNIv2 LP tokens into Unipool rewards contract
 * - Liquidity providers accrue rewards, proportional to the amount of staked tokens and staking time
 * - Liquidity providers can claim their rewards when they want
 * - Liquidity providers can unstake UNIv2 LP tokens to exit the program (i.e., stop earning rewards) when they want

 * Funds for rewards will only be added once, on deployment of LQTY token,
 * which will happen after this contract is deployed and before this `setParams` in this contract is called.

 * If at some point the total amount of staked tokens is zero, the clock will be “stopped”,
 * so the period will be extended by the time during which the staking pool is empty,
 * in order to avoid getting LQTY tokens locked.
 * That also means that the start time for the program will be the event that occurs first:
 * either LQTY token contract is deployed, and therefore LQTY tokens are minted to Unipool contract,
 * or first liquidity provider stakes UNIv2 LP tokens into it.
 */
contract Unipool is LPTokenWrapper, Ownable, CheckContract, IUnipool {
    string constant public NAME = "Unipool";

    uint256 public duration;
    ILQTYToken public lqtyToken;

    uint256 public periodFinish = 0;
    uint256 public rewardRate = 0;
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;
    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event UniTokenAddressChanged(address _uniTokenAddress);
    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    // initialization function
    function setParams(
        address _lqtyTokenAddress,
        address _uniTokenAddress,
        uint _duration
    )
        external
        override
        onlyOwner
    {
        checkContract(_lqtyTokenAddress);
        checkContract(_uniTokenAddress);

        uniToken = IERC20(_uniTokenAddress);
        lqtyToken = ILQTYToken(_lqtyTokenAddress);
        duration = _duration;

        _notifyRewardAmount(lqtyToken.getLpRewardsEntitlement(), _duration);

        emit LQTYTokenAddressChanged(_lqtyTokenAddress);
        emit UniTokenAddressChanged(_uniTokenAddress);

        _renounceOwnership();
    }

    // Returns current timestamp if the rewards program has not finished yet, end time otherwise
    function lastTimeRewardApplicable() public view override returns (uint256) {
        return LiquityMath._min(block.timestamp, periodFinish);
    }

    // Returns the amount of rewards that correspond to each staked token
    function rewardPerToken() public view override returns (uint256) {
        if (totalSupply() == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored + (lastTimeRewardApplicable() - lastUpdateTime * rewardRate * (1e18) / totalSupply());
    }

    // Returns the amount that an account can claim
    function earned(address account) public view override returns (uint256) {
        return
            balanceOf(account)*(rewardPerToken() - userRewardPerTokenPaid[account]) / (1e18) + rewards[account];
    }

    // stake visibility is public as overriding LPTokenWrapper's stake() function
    function stake(uint256 amount) public override {
        require(amount > 0, "Cannot stake 0");
        require(address(uniToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updatePeriodFinish();
        _updateAccountReward(msg.sender);

        super.stake(amount);

        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public override {
        require(amount > 0, "Cannot withdraw 0");
        require(address(uniToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updateAccountReward(msg.sender);

        super.withdraw(amount);

        emit Withdrawn(msg.sender, amount);
    }

    // Shortcut to be able to unstake tokens and claim rewards in one transaction
    function withdrawAndClaim() external override {
        withdraw(balanceOf(msg.sender));
        claimReward();
    }

    function claimReward() public override {
        require(address(uniToken) != address(0), "Liquidity Pool Token has not been set yet");

        _updatePeriodFinish();
        _updateAccountReward(msg.sender);

        uint256 reward = earned(msg.sender);

        require(reward > 0, "Nothing to claim");

        rewards[msg.sender] = 0;
        lqtyToken.transfer(msg.sender, reward);
        emit RewardPaid(msg.sender, reward);
    }

    // Used only on initialization, sets the reward rate and the end time for the program
    function _notifyRewardAmount(uint256 _reward, uint256 _duration) internal {
        assert(_reward > 0);
        assert(_reward == lqtyToken.balanceOf(address(this)));
        assert(periodFinish == 0);

        _updateReward();

        rewardRate = _reward / _duration;

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + _duration;
        emit RewardAdded(_reward);
    }

    // Adjusts end time for the program after periods of zero total supply
    function _updatePeriodFinish() internal {
        if (totalSupply() == 0) {
            assert(periodFinish > 0);
            /*
             * If the finish period has been reached (but there are remaining rewards due to zero stake),
             * to get the new finish date we must add to the current timestamp the difference between
             * the original finish time and the last update, i.e.:
             *
             * periodFinish = block.timestamp.add(periodFinish.sub(lastUpdateTime));
             *
             * If we have not reached the end yet, we must extend it by adding to it the difference between
             * the current timestamp and the last update (the period where the supply has been empty), i.e.:
             *
             * periodFinish = periodFinish.add(block.timestamp.sub(lastUpdateTime));
             *
             * Both formulas are equivalent.
             */
            periodFinish = periodFinish + (block.timestamp - lastUpdateTime);
        }
    }

    function _updateReward() internal {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
    }

    function _updateAccountReward(address account) internal {
        _updateReward();

        assert(account != address(0));

        rewards[account] = earned(account);
        userRewardPerTokenPaid[account] = rewardPerTokenStored;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

// Buidler's helper contract for console logging
library console {
	address constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);

	function log() internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log()"));
		ignored;
	}	function logInt(int p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(int)", p0));
		ignored;
	}

	function logUint(uint p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint)", p0));
		ignored;
	}

	function logString(string memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
		ignored;
	}

	function logBool(bool p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
		ignored;
	}

	function logAddress(address p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
		ignored;
	}

	function logBytes(bytes memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes)", p0));
		ignored;
	}

	function logByte(bytes memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(byte)", p0));
		ignored;
	}

	function logBytes1(bytes1 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes1)", p0));
		ignored;
	}

	function logBytes2(bytes2 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes2)", p0));
		ignored;
	}

	function logBytes3(bytes3 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes3)", p0));
		ignored;
	}

	function logBytes4(bytes4 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes4)", p0));
		ignored;
	}

	function logBytes5(bytes5 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes5)", p0));
		ignored;
	}

	function logBytes6(bytes6 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes6)", p0));
		ignored;
	}

	function logBytes7(bytes7 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes7)", p0));
		ignored;
	}

	function logBytes8(bytes8 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes8)", p0));
		ignored;
	}

	function logBytes9(bytes9 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes9)", p0));
		ignored;
	}

	function logBytes10(bytes10 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes10)", p0));
		ignored;
	}

	function logBytes11(bytes11 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes11)", p0));
		ignored;
	}

	function logBytes12(bytes12 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes12)", p0));
		ignored;
	}

	function logBytes13(bytes13 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes13)", p0));
		ignored;
	}

	function logBytes14(bytes14 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes14)", p0));
		ignored;
	}

	function logBytes15(bytes15 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes15)", p0));
		ignored;
	}

	function logBytes16(bytes16 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes16)", p0));
		ignored;
	}

	function logBytes17(bytes17 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes17)", p0));
		ignored;
	}

	function logBytes18(bytes18 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes18)", p0));
		ignored;
	}

	function logBytes19(bytes19 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes19)", p0));
		ignored;
	}

	function logBytes20(bytes20 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes20)", p0));
		ignored;
	}

	function logBytes21(bytes21 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes21)", p0));
		ignored;
	}

	function logBytes22(bytes22 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes22)", p0));
		ignored;
	}

	function logBytes23(bytes23 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes23)", p0));
		ignored;
	}

	function logBytes24(bytes24 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes24)", p0));
		ignored;
	}

	function logBytes25(bytes25 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes25)", p0));
		ignored;
	}

	function logBytes26(bytes26 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes26)", p0));
		ignored;
	}

	function logBytes27(bytes27 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes27)", p0));
		ignored;
	}

	function logBytes28(bytes28 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes28)", p0));
		ignored;
	}

	function logBytes29(bytes29 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes29)", p0));
		ignored;
	}

	function logBytes30(bytes30 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes30)", p0));
		ignored;
	}

	function logBytes31(bytes31 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes31)", p0));
		ignored;
	}

	function logBytes32(bytes32 p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bytes32)", p0));
		ignored;
	}

	function log(uint p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint)", p0));
		ignored;
	}

	function log(string memory p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string)", p0));
		ignored;
	}

	function log(bool p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool)", p0));
		ignored;
	}

	function log(address p0) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address)", p0));
		ignored;
	}

	function log(uint p0, uint p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint)", p0, p1));
		ignored;
	}

	function log(uint p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string)", p0, p1));
		ignored;
	}

	function log(uint p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool)", p0, p1));
		ignored;
	}

	function log(uint p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address)", p0, p1));
		ignored;
	}

	function log(string memory p0, uint p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint)", p0, p1));
		ignored;
	}

	function log(string memory p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string)", p0, p1));
		ignored;
	}

	function log(string memory p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool)", p0, p1));
		ignored;
	}

	function log(string memory p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address)", p0, p1));
		ignored;
	}

	function log(bool p0, uint p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint)", p0, p1));
		ignored;
	}

	function log(bool p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string)", p0, p1));
		ignored;
	}

	function log(bool p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool)", p0, p1));
		ignored;
	}

	function log(bool p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address)", p0, p1));
		ignored;
	}

	function log(address p0, uint p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint)", p0, p1));
		ignored;
	}

	function log(address p0, string memory p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string)", p0, p1));
		ignored;
	}

	function log(address p0, bool p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool)", p0, p1));
		ignored;
	}

	function log(address p0, address p1) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address)", p0, p1));
		ignored;
	}

	function log(uint p0, uint p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,uint)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, uint p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,string)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, uint p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, uint p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,address)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, string memory p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,uint)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,string)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,address)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, bool p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,uint)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, address p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,uint)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,string)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,uint)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, uint p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(string memory p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,uint)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, uint p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(bool p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,uint)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, uint p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, string memory p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, bool p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, uint p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, string memory p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, bool p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool)", p0, p1, p2));
		ignored;
	}

	function log(address p0, address p1, address p2) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address)", p0, p1, p2));
		ignored;
	}

	function log(uint p0, uint p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, uint p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,uint,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(uint p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(uint,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, uint p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,uint,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(string memory p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(string,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, uint p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,uint,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(bool p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(bool,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, uint p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,uint,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, string memory p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,string,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, bool p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,bool,address,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, uint p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,uint,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, string memory p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,string,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, bool p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,bool,address)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, uint p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,uint)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, string memory p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,string)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, bool p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,bool)", p0, p1, p2, p3));
		ignored;
	}

	function log(address p0, address p1, address p2, address p3) internal view {
		(bool ignored, ) = CONSOLE_ADDRESS.staticcall(abi.encodeWithSignature("log(address,address,address,address)", p0, p1, p2, p3));
		ignored;
	}

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface IUnipool {
    function setParams(address _lqtyTokenAddress, address _uniTokenAddress, uint256 _duration) external;
    function lastTimeRewardApplicable() external view returns (uint256);
    function rewardPerToken() external view returns (uint256);
    function earned(address account) external view returns (uint256);
    function withdrawAndClaim() external;
    function claimReward() external;
    //function notifyRewardAmount(uint256 reward) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


interface ILPTokenWrapper {
    function stake(uint256 amount) external;
    function withdraw(uint256 amount) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender) - value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../Dependencies/IERC2612.sol";

interface ILQTYToken is IERC20, IERC2612 { 
   
    // --- Events ---
    
    event CommunityIssuanceAddressSet(address _communityIssuanceAddress);
    event LQTYStakingAddressSet(address _lqtyStakingAddress);
    event LockupContractFactoryAddressSet(address _lockupContractFactoryAddress);

    // --- Functions ---
    
    function sendToLQTYStaking(address _sender, uint256 _amount) external;

    function getDeploymentStartTime() external view returns (uint256);

    function getLpRewardsEntitlement() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 *
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     *
     * NOTE: This function is not safe, as it doesn’t check owner is calling it.
     * Make sure you check it before calling it.
     */
    function _renounceOwnership() internal {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

import "./console.sol";

library LiquityMath {

    uint internal constant DECIMAL_PRECISION = 1e18;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
     *
     * - Making it “too high” could lead to overflows.
     * - Making it “too low” could lead to an ICR equal to zero, due to truncation from Solidity floor division. 
     *
     * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 ETH,
     * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
     *
     */
    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }

    function _max(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a : _b;
    }

    /* 
    * Multiply two decimal numbers and use normal rounding rules:
    * -round product up if 19'th mantissa digit >= 5
    * -round product down if 19'th mantissa digit < 5
    *
    * Used only inside the exponentiation, _decPow().
    */
    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x * y;

        decProd = prod_xy + (DECIMAL_PRECISION / 2) / (DECIMAL_PRECISION);
    }

    /* 
    * _decPow: Exponentiation function for 18-digit decimal base, and integer exponent n.
    * 
    * Uses the efficient "exponentiation by squaring" algorithm. O(log(n)) complexity. 
    * 
    * Called by two functions that represent time in units of minutes:
    * 1) TroveManager._calcDecayedBaseRate
    * 2) CommunityIssuance._getCumulativeIssuanceFraction 
    * 
    * The exponent is capped to avoid reverting due to overflow. The cap 525600000 equals
    * "minutes in 1000 years": 60 * 24 * 365 * 1000
    * 
    * If a period of > 1000 years is ever used as an exponent in either of the above functions, the result will be
    * negligibly different from just passing the cap, since: 
    *
    * In function 1), the decayed base rate will be 0 for 1000 years or > 1000 years
    * In function 2), the difference in tokens issued at 1000 years and any time > 1000 years, will be negligible
    */
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n / 2;
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n - 1) / 2;
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a - _b : _b - _a;
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll * NICR_PRECISION / _debt;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll * _price / _debt;

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Trove has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.10;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}