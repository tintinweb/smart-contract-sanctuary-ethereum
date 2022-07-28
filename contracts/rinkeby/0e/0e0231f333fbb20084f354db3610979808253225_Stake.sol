// SPDX-License-Identifier: BSD-3-Clause
pragma solidity 0.8.11;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Whitelist is OwnableUpgradeable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender], 'not whitelisted');
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @dev return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @dev return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @dev return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @dev return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] memory addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

}

interface Token {
    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function transfer(address, uint256) external returns (bool);
}

interface cmnReferral {
    function payReferral(
        address,
        address,
        uint256,
        uint256
    ) external returns (bool);

    function setUserReferral(address, address) external returns (bool);

    function setReferralAddressesOfUsers(address, address)
        external
        returns (bool);

    function getUserReferral(address) external view returns (address);

    function getReferralAddressOfUsers(address)
        external
        view
        returns (address[] memory);

    function getUserByReferralCode(bytes3) external view returns (address);
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract Stake is Initializable, ContextUpgradeable, UUPSUpgradeable, Whitelist{
    using SafeMath for uint256;
    // using EnumerableSet for EnumerableSet.AddressSet;

    event RewardsTransferred(address holder, uint256 amount);

    enum UserActions {
        DEPOSIT,
        REFER,
        HARVEST,
        WITHDRAW,
        UNSTAKE,
        REINVEST,
        ALL
    }

    struct WhitelistUserDeposits{
        uint depositedTokens;
        uint depositedTokensInUSDT;
        uint withdrawnAmount;
        uint lastWithdrawTime;
    }

    struct UserDetails{
        uint depositedTokens;
        uint stakingTime;
        uint lastClaimedTime;
        uint totalEarnedTokens;
        uint rewardRateForUser;
        uint cmnStakePrice;
        uint userWithdrawPercenage;
        uint depositedTokensInUSDT;
    }

    struct BlackListDetails{
        bool isBlackListForDeposit;
        bool isBlackListForRefer;
        bool isBlackListForHarvest;
        bool isBlackListForWithdraw;
        bool isBlackListForUnstake;
        bool isBlackListForReinvest; 
    }

    IPancakeRouter02 public router;

    // deposit token contract address
    address public depositToken;

    // reward token contract address
    address public rewardToken;

    // referral contract address
    address public referralAddress;

    // reward rate in percentage per year
    uint256 public rewardRate;
    uint256 public rewardInterval;

    // Referral fee in percentage
    uint256 public referralFeeRate;

    uint256 public poolLimit;

    uint256 public poolLimitPerUser;

    uint256 public totalClaimedRewards;

    uint256 public totalStaked;

    uint256 public minAmount;

    uint256 public poolOpenTill;

    uint256 public poolExpiryTime;

    uint256 public cmnRate;

    uint256 private time;

    uint256 public harvestFee;

    uint256 public withdrawTimeLimit;

    uint256 public withdrawPercentage;

    bool public isHarvestOpen;

    bool public isUserLimit;

    // EnumerableSet.AddressSet private holders;
    address[] public holders;

    address[] public path;

    mapping(address => UserDetails) public userDetails;

    mapping(address => address) public myReferralAddresses; // get my referal address that i refer
    mapping(address => bool) public alreadyReferral;
    mapping(address => uint256) public pendingReward;
    mapping(address => BlackListDetails) public isBlackList;
    mapping(address => bool) public isWhitelistForEmergencyWithdraw;
    mapping(address => WhitelistUserDeposits) public whitelistUserDeposits;
    mapping(bytes3 => bool) public isReferCodeBlock;

    
    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setValues(
        address _depositTokens,
        address _rewardToken
    ) public onlyOwner {
        depositToken = _depositTokens;
        rewardToken = _rewardToken;
        rewardRate = 4800;
        rewardInterval = 1555000;
        poolOpenTill = block.timestamp.add(1555000);
        poolLimit = 10000000 ether;
        poolLimitPerUser = 10000000 ether;
        referralFeeRate = 0;
        poolExpiryTime = block.timestamp.add(1555000);
        time = 365 hours;
        withdrawTimeLimit = 30 hours;
        withdrawPercentage = 300;
        minAmount = 10;
    }

    function setPoolOpenTime(uint256 _time) public onlyOwner {
        poolOpenTill = block.timestamp.add(_time);
    }

    function setRewardRate(uint256 _rate) public onlyOwner {
        rewardRate = _rate;
    }

    function setPoolLimit(uint256 _amount) public onlyOwner {
        poolLimit = _amount;
    }

    function setPoolLimitperUser(uint256 _amount) public onlyOwner {
        poolLimitPerUser = _amount;
    }

    function setReferralFeeRate(uint256 _rate) public onlyOwner {
        referralFeeRate = _rate;
    }

    function setMinAmount(uint256 _amount) public onlyOwner {
        minAmount = _amount;
    }

    function setCMNPrice(uint256 _rate) public onlyOwner {
        cmnRate = _rate;
    }

    function setReferralAddress(address _referralAddress) public onlyOwner {
        referralAddress = _referralAddress;
    }

    function setTotalPoolIntervalTime(uint256 _time) public onlyOwner {
        time = _time;
    }

    function setWhitelistAddressForEmergencyWithdraw(address _user) public onlyOwner {
        isWhitelistForEmergencyWithdraw[_user] = true;
    }

    function setUserWithdrawPercentage(address _user, uint _percentage) public onlyOwner {
        userDetails[_user].userWithdrawPercenage = _percentage;
    }

    function blockReferCode(bytes3 code, bool value) public onlyOwner {
        isReferCodeBlock[code] = value;
    }

    function enableHarvest() public onlyOwner {
        isHarvestOpen = true;
    }

    function disableHarvest() public onlyOwner {
        isHarvestOpen = false;
    }

    function enableUserLimit() public onlyOwner {
        isUserLimit = true;
    }

    function disableUserLimit() public onlyOwner {
        isUserLimit = false;
    }

    function setHarvestFees(uint256 _fees) public onlyOwner {
        harvestFee = _fees;
    }

    function setPath(address path0, address path1) public onlyOwner{
        path.push(path0);
        path.push(path1);
    }

    function setRewardInterval(uint256 _time) public onlyOwner {
        rewardInterval = _time;
    }

    /**
     * @notice Only Holder - check holder is exists in our contract or not
     * @return bool value
     */
    function onlyHolder(address _holder) public view returns (bool) {
        bool condition = false;
        for (uint256 i = 0; i < holders.length; i++) {
            if (holders[i] == _holder) {
                condition = true;
                return true;
            }
        }
        return false;
    }

    function setAddressBlackList(address _userAddress, UserActions _action)
        public onlyOwner
    {
        if (_action == UserActions.DEPOSIT) {
            isBlackList[_userAddress].isBlackListForDeposit = true;
        } else if (_action == UserActions.REFER) {
            isBlackList[_userAddress].isBlackListForRefer = true;
        } else if (_action == UserActions.HARVEST) {
            isBlackList[_userAddress].isBlackListForHarvest = true;
        } else if (_action == UserActions.WITHDRAW) {
            isBlackList[_userAddress].isBlackListForWithdraw = true;
        } else if (_action == UserActions.UNSTAKE) {
            isBlackList[_userAddress].isBlackListForUnstake = true;
        } else if (_action == UserActions.REINVEST) {
            isBlackList[_userAddress].isBlackListForReinvest = true;
        } else if (_action == UserActions.ALL) {
            isBlackList[_userAddress].isBlackListForDeposit = true;
            isBlackList[_userAddress].isBlackListForRefer = true;
            isBlackList[_userAddress].isBlackListForHarvest = true;
            isBlackList[_userAddress].isBlackListForWithdraw = true;
            isBlackList[_userAddress].isBlackListForUnstake = true;
            isBlackList[_userAddress].isBlackListForReinvest = true;
        }
    }

    function setAddressUnBlackList(address _userAddress, UserActions _action)
        public onlyOwner
    {
        if (_action == UserActions.DEPOSIT) {
            isBlackList[_userAddress].isBlackListForDeposit = false;
        } else if (_action == UserActions.REFER) {
            isBlackList[_userAddress].isBlackListForRefer = false;
        } else if (_action == UserActions.HARVEST) {
            isBlackList[_userAddress].isBlackListForHarvest = false;
        } else if (_action == UserActions.WITHDRAW) {
            isBlackList[_userAddress].isBlackListForWithdraw = false;
        } else if (_action == UserActions.UNSTAKE) {
            isBlackList[_userAddress].isBlackListForUnstake = false;
        } else if (_action == UserActions.REINVEST) {
            isBlackList[_userAddress].isBlackListForReinvest = false;
        } else if (_action == UserActions.ALL) {
            isBlackList[_userAddress].isBlackListForDeposit = false;
            isBlackList[_userAddress].isBlackListForRefer = false;
            isBlackList[_userAddress].isBlackListForHarvest = false;
            isBlackList[_userAddress].isBlackListForWithdraw = false;
            isBlackList[_userAddress].isBlackListForUnstake = false;
            isBlackList[_userAddress].isBlackListForReinvest = false;
        }
    }

    function updateAccount(address account) private {
        uint256 pendingDivs = getPendingDivs(account);
        if (pendingDivs > 0) {
            uint256 fee = pendingDivs.mul(harvestFee).div(1e4);
            uint256 amountAfterFee = pendingDivs.sub(fee);
            require(
                Token(depositToken).transfer(account, amountAfterFee.div(cmnRate).mul(100)),
                "Could not transfer tokens."
            );
            require(
                Token(depositToken).transfer(owner(), fee.div(cmnRate).mul(100)),
                "Could not transfer tokens."
            );
            userDetails[account].totalEarnedTokens = userDetails[account].totalEarnedTokens.add(
                pendingDivs
            );
            totalClaimedRewards = totalClaimedRewards.add(pendingDivs);
            emit RewardsTransferred(account, pendingDivs);
        }
        userDetails[account].lastClaimedTime = block.timestamp;
    }

    function getPendingDivs(address _holder) public view returns (uint256) {
        if (!onlyHolder(_holder)) return 0;
        if (userDetails[_holder].depositedTokens == 0) return 0;

        if(userDetails[_holder].stakingTime.add(rewardInterval) < userDetails[_holder].lastClaimedTime){
            return 0;
        }

        // uint256 timeDiff = block.timestamp.sub(lastClaimedTime[_holder]);
        uint256 timeDiff;
        block.timestamp <= userDetails[_holder].stakingTime.add(rewardInterval)
            ? timeDiff = block.timestamp.sub(userDetails[_holder].lastClaimedTime)
            : timeDiff = userDetails[_holder].stakingTime.add(rewardInterval).sub(
            userDetails[_holder].lastClaimedTime
        );
        uint256 stakedAmount = userDetails[_holder].depositedTokens;

        uint256 pendingDivs = userDetails[_holder].depositedTokensInUSDT
            .mul(userDetails[_holder].rewardRateForUser)
            .mul(timeDiff)
            .div(time)
            .div(1e4);

        return (pendingDivs).add(pendingReward[_holder]);
    }

    function getNumberOfHolders() public view returns (uint256) {
        return holders.length;
    }

    function deposit(address userAddress, uint256 amountToStake) public {
        // require(block.timestamp <= poolExpiryTime, "Pool is expired");
        require(block.timestamp <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(!isBlackList[userAddress].isBlackListForDeposit, "User is blacklisted");
        // require(
        //     totalStaked.add(amountToStake) <= poolLimit,
        //     "Pool limit reached"
        // );
        if (isUserLimit) {
            require(
                userDetails[userAddress].depositedTokens.add(amountToStake) <=
                    poolLimitPerUser,
                "Pool limit reached"
            );
        }
        require(
            amountToStake.div(1e18).mul(cmnRate) >= minAmount,
            "Staking amount is less than min value"
        );
        require(
            Token(depositToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        updateAccount(userAddress);

        address myReferralAddredd = myReferralAddresses[userAddress];

        if (
            amountToStake > 0 &&
            myReferralAddredd != address(0) &&
            myReferralAddredd != userAddress
        ) {
            require(
                cmnReferral(referralAddress).payReferral(
                    userAddress,
                    userAddress,
                    0,
                    amountToStake
                ),
                "Can't pay referral"
            );
        }

        userDetails[userAddress].depositedTokens = userDetails[userAddress].depositedTokens.add(
            amountToStake
        );
        userDetails[userAddress].depositedTokensInUSDT = userDetails[userAddress].depositedTokensInUSDT.add(
            amountToStake.mul(cmnRate).div(100)
        );

        if(whitelist[userAddress]){
            if(whitelistUserDeposits[userAddress].depositedTokens == 0){
                whitelistUserDeposits[userAddress].depositedTokens = amountToStake;
                whitelistUserDeposits[userAddress].depositedTokensInUSDT = amountToStake.mul(cmnRate).div(100);
                whitelistUserDeposits[userAddress].lastWithdrawTime = block.timestamp;
            }
        }
            

        totalStaked = totalStaked.add(amountToStake);
        userDetails[userAddress].cmnStakePrice = cmnRate;

        if (!onlyHolder(userAddress)) {
            holders.push(userAddress);
            userDetails[userAddress].stakingTime = block.timestamp;
            userDetails[userAddress].rewardRateForUser = rewardRate;
        }
    }

    function depositWithReferral(
        address userAddress,
        uint256 amountToStake,
        bytes3 referralCode
    ) public {
        require(!isReferCodeBlock[referralCode], "Refer code blocked");
        // require(block.timestamp <= poolExpiryTime, "Pool is expired");
        require(block.timestamp <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(!isBlackList[userAddress].isBlackListForDeposit, "User is blacklisted");
        // require(
        //     totalStaked.add(amountToStake) <= poolLimit,
        //     "Pool limit reached"
        // );
        if (isUserLimit) {
            require(
                userDetails[userAddress].depositedTokens.add(amountToStake) <=
                    poolLimitPerUser,
                "Pool limit reached"
            );
        }
        require(userDetails[userAddress].depositedTokens == 0, "Invalid Contract Call");
        require(
            amountToStake.div(1e18).mul(cmnRate) >= minAmount,
            "Staking amount is less than min value"
        );
        require(
            !alreadyReferral[userAddress],
            "You can't use refer program multiple times"
        );
        require(
            Token(depositToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        address referral = cmnReferral(referralAddress).getUserByReferralCode(
            referralCode
        );
        require(referral != address(0), "Please enter valid referral code");

        updateAccount(userAddress);

        if (
            amountToStake > 0 &&
            referral != address(0) &&
            referral != userAddress
        ) {
            require(!isBlackList[userAddress].isBlackListForRefer, "User is blacklisted");
            alreadyReferral[userAddress] = true;
            myReferralAddresses[userAddress] = referral;

            require(
                cmnReferral(referralAddress).setUserReferral(
                    userAddress,
                    referral
                ),
                "Can't set user referral"
            );

            require(
                cmnReferral(referralAddress).setReferralAddressesOfUsers(
                    userAddress,
                    referral
                ),
                "Can't update referral list"
            );

            require(
                cmnReferral(referralAddress).payReferral(
                    userAddress,
                    userAddress,
                    0,
                    amountToStake
                ),
                "Can't pay referral"
            );
        }

        userDetails[userAddress].depositedTokens = userDetails[userAddress].depositedTokens.add(
            amountToStake
        );

        userDetails[userAddress].depositedTokensInUSDT = userDetails[userAddress].depositedTokensInUSDT.add(
            amountToStake.mul(cmnRate).div(100)
        );

        if(whitelist[userAddress]){
            if(whitelistUserDeposits[userAddress].depositedTokens == 0){
                whitelistUserDeposits[userAddress].depositedTokens = amountToStake;
                whitelistUserDeposits[userAddress].depositedTokensInUSDT = amountToStake.mul(cmnRate).div(100);
                whitelistUserDeposits[userAddress].lastWithdrawTime = block.timestamp;
            }
        }

        totalStaked = totalStaked.add(amountToStake);
        userDetails[userAddress].cmnStakePrice = cmnRate;

        if (!onlyHolder(userAddress)) {
            holders.push(userAddress);
            userDetails[userAddress].stakingTime = block.timestamp;
            userDetails[userAddress].rewardRateForUser = rewardRate;
        }
    }

    function depositUSDT(address userAddress, uint256 amountToStake) public {
        // require(block.timestamp <= poolExpiryTime, "Pool is expired");
        require(block.timestamp <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(!isBlackList[userAddress].isBlackListForDeposit, "User is blacklisted");
        // require(
        //     totalStaked.add(amountToStake) <= poolLimit,
        //     "Pool limit reached"
        // );
        require(
            amountToStake.div(1e18) >= minAmount.div(1e2),
            "Staking amount is less than min value"
        );
        require(
            Token(rewardToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        updateAccount(userAddress);

        address myReferralAddredd = myReferralAddresses[userAddress];

        if (
            amountToStake > 0 &&
            myReferralAddredd != address(0) &&
            myReferralAddredd != userAddress
        ) {
            require(
                cmnReferral(referralAddress).payReferral(
                    userAddress,
                    userAddress,
                    0,
                    amountToStake.div(cmnRate).mul(100)
                ),
                "Can't pay referral"
            );
        }

        userDetails[userAddress].depositedTokens = userDetails[userAddress].depositedTokens.add(
            amountToStake.div(cmnRate).mul(100)
        );

        userDetails[userAddress].depositedTokensInUSDT = userDetails[userAddress].depositedTokensInUSDT.add(
            amountToStake
        );

        if(whitelist[userAddress]){
            if(whitelistUserDeposits[userAddress].depositedTokens == 0){
                whitelistUserDeposits[userAddress].depositedTokens = amountToStake.div(cmnRate).mul(100);
                whitelistUserDeposits[userAddress].depositedTokensInUSDT = amountToStake;
                whitelistUserDeposits[userAddress].lastWithdrawTime = block.timestamp;
            }
        }

        totalStaked = totalStaked.add(amountToStake.div(cmnRate).mul(100));
        userDetails[userAddress].cmnStakePrice = cmnRate;

        if (!onlyHolder(userAddress)) {
            holders.push(userAddress);
            userDetails[userAddress].stakingTime = block.timestamp;
            userDetails[userAddress].rewardRateForUser = rewardRate;
        }
    }

    function depositUSDTWithReferral(
        address userAddress,
        uint256 amountToStake,
        bytes3 referralCode
    ) public {
        require(!isReferCodeBlock[referralCode], "Refer code blocked");
        // require(block.timestamp <= poolExpiryTime, "Pool is expired");
        require(block.timestamp <= poolOpenTill, "Pool is closed");
        require(amountToStake > 0, "Cannot deposit 0 Tokens");
        require(!isBlackList[userAddress].isBlackListForDeposit, "User is blacklisted");
        // require(
        //     totalStaked.add(amountToStake.div(1e8).div(cmnRate)) <= poolLimit,
        //     "Pool limit reached"
        // );
        require(userDetails[userAddress].depositedTokens == 0, "Invalid Contract Call");
        require(
            amountToStake.div(1e18) >= minAmount.div(1e2),
            "Staking amount is less than min value"
        );
        require(
            !alreadyReferral[userAddress],
            "You can't use refer program multiple times"
        );
        require(
            Token(rewardToken).transferFrom(
                msg.sender,
                address(this),
                amountToStake
            ),
            "Insufficient Token Allowance"
        );

        address referral = cmnReferral(referralAddress).getUserByReferralCode(
            referralCode
        );
        require(referral != address(0), "Please enter valid referral code");

        updateAccount(userAddress);

        if (
            amountToStake > 0 &&
            referral != address(0) &&
            referral != userAddress
        ) {
            require(!isBlackList[userAddress].isBlackListForRefer, "User is blacklisted");
            require(!isBlackList[referral].isBlackListForRefer, "User is blacklisted");
            alreadyReferral[userAddress] = true;
            myReferralAddresses[userAddress] = referral;

            cmnReferral(referralAddress).setUserReferral(userAddress, referral);

            cmnReferral(referralAddress).setReferralAddressesOfUsers(
                userAddress,
                referral
            );

            cmnReferral(referralAddress).payReferral(
                userAddress,
                userAddress,
                0,
                amountToStake.div(cmnRate).mul(100)
            );
        }

        userDetails[userAddress].depositedTokens = userDetails[userAddress].depositedTokens.add(
            amountToStake.div(cmnRate).mul(100)
        );
        userDetails[userAddress].depositedTokensInUSDT = userDetails[userAddress].depositedTokensInUSDT.add(
            amountToStake
        );

        if(whitelist[userAddress]){
            if(whitelistUserDeposits[userAddress].depositedTokens == 0){
                whitelistUserDeposits[userAddress].depositedTokens = amountToStake.div(cmnRate).mul(100);
                whitelistUserDeposits[userAddress].depositedTokensInUSDT = amountToStake;
                whitelistUserDeposits[userAddress].lastWithdrawTime = block.timestamp;
            }
        }

        totalStaked = totalStaked.add(amountToStake.div(cmnRate).mul(100));
        userDetails[userAddress].cmnStakePrice = cmnRate;

        if (!onlyHolder(userAddress)) {
            holders.push(userAddress);
            userDetails[userAddress].stakingTime = block.timestamp;
            userDetails[userAddress].rewardRateForUser = rewardRate;
        }
    }

    function withdraw() public onlyWhitelisted {
        require(!isBlackList[msg.sender].isBlackListForWithdraw, "User is blacklisted");

        require(getIsWithdrawAvailable(msg.sender), "Withdraw not available");

        uint256 temp = userDetails[msg.sender].userWithdrawPercenage != 0 ? userDetails[msg.sender].userWithdrawPercenage : withdrawPercentage;

        uint256 tokentoSend = whitelistUserDeposits[msg.sender].depositedTokensInUSDT.mul(temp).div(10000);

        updateAccount(msg.sender);
        
        require(
            Token(rewardToken).transfer(msg.sender, tokentoSend),
            "Could not transfer tokens."
        );

        userDetails[msg.sender].depositedTokens = userDetails[msg.sender].depositedTokens.sub(
            tokentoSend.div(userDetails[msg.sender].cmnStakePrice).mul(100)
        );

        userDetails[msg.sender].depositedTokensInUSDT = userDetails[msg.sender].depositedTokensInUSDT.sub(
            tokentoSend
        );
        
        whitelistUserDeposits[msg.sender].withdrawnAmount = whitelistUserDeposits[msg.sender].withdrawnAmount.add(tokentoSend);  
        
        if (onlyHolder(msg.sender) &&  userDetails[msg.sender].depositedTokens == 0) {
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == msg.sender) {
                    delete holders[i];
                }
            }
        }
        whitelistUserDeposits[msg.sender].lastWithdrawTime = block.timestamp;
    }

    function unstake(uint256 amountToWithdraw) public {
        require(
             userDetails[msg.sender].depositedTokens >= amountToWithdraw,
            "Invalid amount to withdraw"
        );

        require(!isBlackList[msg.sender].isBlackListForUnstake, "User is blacklisted");

        require(
            block.timestamp.sub( userDetails[msg.sender].stakingTime) > rewardInterval,
            "You recently staked, please wait before withdrawing."
        );
        updateAccount(msg.sender);

        require(
            Token(depositToken).transfer(msg.sender, amountToWithdraw),
            "Could not transfer tokens."
        );

         userDetails[msg.sender].depositedTokens =  userDetails[msg.sender].depositedTokens.sub(
            amountToWithdraw
        );

        if (onlyHolder(msg.sender) &&  userDetails[msg.sender].depositedTokens == 0) {
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == msg.sender) {
                    delete holders[i];
                }
            }
        }


    }

    function emergencyWithdraw() public {
        require(
            isWhitelistForEmergencyWithdraw[msg.sender],
            "User is not whitelisted"
        );

         userDetails[msg.sender].depositedTokens = 0;

        if (onlyHolder(msg.sender) &&  userDetails[msg.sender].depositedTokens == 0) {
            for (uint256 i = 0; i < holders.length; i++) {
                if (holders[i] == msg.sender) {
                    delete holders[i];
                }
            }
        }
        isWhitelistForEmergencyWithdraw[msg.sender] = false;
        require(
            Token(depositToken).transfer(
                msg.sender,
                 userDetails[msg.sender].depositedTokens
            ),
            "Could not transfer tokens."
        );
    }

    function claimDivs() public {
        require(isHarvestOpen, "Harvest is Closed now");
        require(!isBlackList[msg.sender].isBlackListForHarvest, "User is blacklisted");
        updateAccount(msg.sender);
    }

    function reinvest() public {

        require(getIsWithdrawAvailable(msg.sender), "Withdraw/Reinvest not available");
        require(!isBlackList[msg.sender].isBlackListForReinvest, "User is blacklisted");

        uint256 temp = userDetails[msg.sender].userWithdrawPercenage != 0 ? userDetails[msg.sender].userWithdrawPercenage : withdrawPercentage;

        uint256 amountToStake = whitelistUserDeposits[msg.sender].depositedTokensInUSDT.mul(temp).div(10000);
        
        updateAccount(msg.sender);

        userDetails[msg.sender].depositedTokensInUSDT =  userDetails[msg.sender].depositedTokensInUSDT.add(
            amountToStake
        );

        userDetails[msg.sender].cmnStakePrice = cmnRate;
        whitelistUserDeposits[msg.sender].lastWithdrawTime = block.timestamp;

    }

    function getIsWithdrawAvailable(address userAddress) public view returns(bool){
        if(block.timestamp >= whitelistUserDeposits[userAddress].lastWithdrawTime.add(withdrawTimeLimit)){
            return true;
        }
        return false;
    }

    function setWithdrawTimeLimit(uint _time) public onlyOwner {
        withdrawTimeLimit = _time;
    }

    function getStakersList(uint256 startIndex, uint256 endIndex)
        public
        view
        returns (
            address[] memory stakers,
            uint256[] memory stakingTimestamps,
            uint256[] memory lastClaimedTimeStamps,
            uint256[] memory stakedTokens
        )
    {
        require(startIndex < endIndex);

        uint256 length = endIndex.sub(startIndex);
        address[] memory _stakers = new address[](length);
        uint256[] memory _stakingTimestamps = new uint256[](length);
        uint256[] memory _lastClaimedTimeStamps = new uint256[](length);
        uint256[] memory _stakedTokens = new uint256[](length);

        for (uint256 i = startIndex; i < endIndex; i = i.add(1)) {
            address staker = holders[i];
            uint256 listIndex = i.sub(startIndex);
            _stakers[listIndex] = staker;
            _stakingTimestamps[listIndex] =  userDetails[staker].stakingTime;
            _lastClaimedTimeStamps[listIndex] = userDetails[staker].lastClaimedTime;
            _stakedTokens[listIndex] = userDetails[staker].depositedTokens;
        }

        return (
            _stakers,
            _stakingTimestamps,
            _lastClaimedTimeStamps,
            _stakedTokens
        );
    }

    uint256 private constant stakingAndDaoTokens = 5129e18;

    function getStakingAndDaoAmount() public view returns (uint256) {
        if (totalClaimedRewards >= stakingAndDaoTokens) {
            return 0;
        }
        uint256 remaining = stakingAndDaoTokens.sub(totalClaimedRewards);
        return remaining;
    }

    // function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    function transferAnyBEP20Tokens(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        Token(_tokenAddr).transfer(_to, _amount);
    }

    function getTokenPrice() public view returns(uint256){
        uint256[] memory tokenPrice = router.getAmountsOut(1 ether, path);
        return tokenPrice[1];
    }

    function getTokenToUSD(uint tokenAmount) public view returns(uint256){
        uint256[] memory tokenPrice = router.getAmountsOut(1 ether, path);
        return uint(tokenAmount).mul(tokenPrice[1]).div(1e18);
    }

    function getUSDToToken(uint usdAmount) public view returns(uint256){
        uint256[] memory tokenPrice = router.getAmountsOut(1 ether, path);
        return (usdAmount.mul(1e18)).div(tokenPrice[1]);
    }

    function _isBlackListForDeposit(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForDeposit;
    }

    function _isBlackListForHarvest(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForHarvest;
    }

    function _isBlackListForRefer(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForRefer;
    }

    function _isBlackListForReinvest(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForReinvest;
    }

    function _isBlackListForUnstake(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForUnstake;
    }

    function _isBlackListForWithdraw(address userAddress) public view returns(bool){
        return isBlackList[userAddress].isBlackListForWithdraw;
    }

    function _depositedTokens(address userAddress) public view returns(uint){
        return userDetails[userAddress].depositedTokens;
    }

    function _stakingTime(address userAddress) public view returns(uint){
        return userDetails[userAddress].stakingTime;
    }

    function _lastClaimedTime(address userAddress) public view returns(uint){
        return userDetails[userAddress].lastClaimedTime;
    }

    function _totalEarnedTokens(address userAddress) public view returns(uint){
        return userDetails[userAddress].totalEarnedTokens;
    }

    function _rewardRateForUser(address userAddress) public view returns(uint){
        return userDetails[userAddress].rewardRateForUser;
    }

    function _cmnStakePrice(address userAddress) public view returns(uint){
        return userDetails[userAddress].cmnStakePrice;
    }

    function _userWithdrawPercenage(address userAddress) public view returns(uint){
        return userDetails[userAddress].userWithdrawPercenage;
    }

    function updateWhitelist(address userAddress) public onlyOwner{
         if(whitelist[userAddress]){
            whitelistUserDeposits[userAddress].depositedTokens = userDetails[userAddress].depositedTokens;
            whitelistUserDeposits[userAddress].depositedTokensInUSDT = userDetails[userAddress].depositedTokens.mul(cmnRate).div(100);
            whitelistUserDeposits[userAddress].lastWithdrawTime = userDetails[userAddress].lastClaimedTime;
        }
    } 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !AddressUpgradeable.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}