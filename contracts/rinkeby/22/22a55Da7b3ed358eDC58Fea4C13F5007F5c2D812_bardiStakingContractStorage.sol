/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.5.16;
contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;
    constructor() public {
        _status = _NOT_ENTERED;
    }
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address dst, uint256 amount) external returns (bool success);
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
contract bardiStakingContractProxyStorage {
    // Current contract admin address
    address public admin;
    // Requested new admin for the contract
    address public pendingAdmin;
    // Current contract implementation address
    address public implementation;
    // Requested new contract implementation address
    address public pendingImplementation;
}
contract bardiStakingContractProxy is ReentrancyGuard, bardiStakingContractProxyStorage {
    constructor() public {
        admin = msg.sender;
    }
    function setPendingAdmin(address newAdmin) public adminOnly {
        pendingAdmin = newAdmin;
    }
    function acceptPendingAdmin() public {
        require(msg.sender == pendingAdmin && pendingAdmin != address(0), "Caller must be the pending admin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }
    function setPendingImplementation(address newImplementation) public adminOnly {
        pendingImplementation = newImplementation;
    }
    function acceptPendingImplementation() public {
        require(msg.sender == pendingImplementation && pendingImplementation != address(0), "Only the pending implementation contract can call this");
        implementation = pendingImplementation;
        pendingImplementation = address(0);
    }
    function () payable external {
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize)
            switch success
            case 0 { revert(free_mem_ptr, returndatasize) }
            default { return(free_mem_ptr, returndatasize) }
        }
    }
    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}
contract bardiStakingContractStorage is bardiStakingContractProxyStorage {
    uint constant nofStakingRewards = 2;
    uint constant REWARD_AVAX = 0;
    uint constant REWARD_QI = 1;
    // QI-AVAX bardi token contract address
    address public bardiTokenAddress;
    // Addresses of the ERC20 reward tokens
    mapping(uint => address) public rewardTokenAddresses;
    // Reward accrual speeds per reward token as tokens per second
    mapping(uint => uint) public rewardSpeeds;
    // Unclaimed staking rewards per user and token
    mapping(address => mapping(uint => uint)) public accruedReward;
    // Supplied bardi tokens per user
    mapping(address => uint) public supplyAmount;
    // Sum of all supplied bardi tokens
    uint public totalSupplies;
    mapping(uint => uint) public rewardIndex;
    mapping(address => mapping(uint => uint)) public supplierRewardIndex;
    uint public accrualBlockTimestamp;
}
contract bardiStakingContract is  bardiStakingContractStorage {
    using SafeMath for uint256;

    constructor() public {
        admin = msg.sender;
    }
    function deposit(uint bardiAmount) external  {
        require(bardiTokenAddress != address(0), "bardi Token address can not be zero");
        EIP20Interface bardiToken = EIP20Interface(bardiTokenAddress);
        uint contractBalance = bardiToken.balanceOf(address(this));
        bardiToken.transferFrom(msg.sender, address(this), bardiAmount);
        uint depositedAmount = bardiToken.balanceOf(address(this)).sub(contractBalance);
        require(depositedAmount > 0, "Zero deposit");
        distributeReward(msg.sender);
        totalSupplies = totalSupplies.add(depositedAmount);
        supplyAmount[msg.sender] = supplyAmount[msg.sender].add(depositedAmount);
    }
    function redeem(uint bardiAmount) external  {
        require(bardiTokenAddress != address(0), "bardi Token address can not be zero");
        require(bardiAmount <= supplyAmount[msg.sender], "Too large withdrawal");
        distributeReward(msg.sender);
        supplyAmount[msg.sender] = supplyAmount[msg.sender].sub(bardiAmount);
        totalSupplies = totalSupplies.sub(bardiAmount);
        EIP20Interface bardiToken = EIP20Interface(bardiTokenAddress);
        bardiToken.transfer(msg.sender, bardiAmount);
    }
    function claimRewards() external {
        distributeReward(msg.sender);
        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint amount = accruedReward[msg.sender][i];
            if (i == REWARD_AVAX) {
                claimAvax(msg.sender, amount);
            } else {
                claimErc20(i, msg.sender, amount);
            }
        }
    }
    function getClaimableRewards(uint rewardToken) external view returns(uint) {
        require(rewardToken <= nofStakingRewards, "Invalid reward token");
        uint rewardIndexDelta = rewardIndex[rewardToken].sub(supplierRewardIndex[msg.sender][rewardToken]);
        uint claimableReward = rewardIndexDelta.mul(supplyAmount[msg.sender]).div(1e36).add(accruedReward[msg.sender][rewardToken]);
        return claimableReward;
    }
    function setRewardSpeed(uint rewardToken, uint speed) external adminOnly {
        if (accrualBlockTimestamp != 0) {
            accrueReward();
        }
        rewardSpeeds[rewardToken] = speed;
    }
    function setRewardTokenAddress(uint rewardToken, address rewardTokenAddress) external adminOnly {
        require(rewardToken != REWARD_AVAX, "Cannot set AVAX address");
        rewardTokenAddresses[rewardToken] = rewardTokenAddress;
    }
    function setBardiTokenAddress(address newBardiTokenAddress) external adminOnly {
        bardiTokenAddress = newBardiTokenAddress;
    }
    function becomeImplementation(bardiStakingContractProxy proxy) external {
        require(msg.sender == proxy.admin(), "Only proxy admin can change the implementation");
        proxy.acceptPendingImplementation();
    }
    function accrueReward() internal {
        uint blockTimestampDelta = block.timestamp.sub(accrualBlockTimestamp);
        accrualBlockTimestamp = block.timestamp;
        if (blockTimestampDelta == 0 || totalSupplies == 0) {
            return;
        }
        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint rewardSpeed = rewardSpeeds[i];
            if (rewardSpeed == 0) {
                continue;
            }
            uint accrued = rewardSpeeds[i].mul(blockTimestampDelta);
            uint accruedPerBardi = accrued.mul(1e36).div(totalSupplies);
            rewardIndex[i] = rewardIndex[i].add(accruedPerBardi);
        }
    }
    function distributeReward(address recipient) internal {
        accrueReward();
        for (uint i = 0; i < nofStakingRewards; i += 1) {
            uint rewardIndexDelta = rewardIndex[i].sub(supplierRewardIndex[recipient][i]);
            uint accruedAmount = rewardIndexDelta.mul(supplyAmount[recipient]).div(1e36);
            accruedReward[recipient][i] = accruedReward[recipient][i].add(accruedAmount);
            supplierRewardIndex[recipient][i] = rewardIndex[i];
        }
    }
    function claimAvax(address payable recipient, uint amount) internal {
        require(accruedReward[recipient][REWARD_AVAX] <= amount, "Not enough accrued rewards");
        accruedReward[recipient][REWARD_AVAX] = accruedReward[recipient][REWARD_AVAX].sub(amount);
        recipient.transfer(amount);
    }
    function claimErc20(uint rewardToken, address recipient, uint amount) internal {
        require(rewardToken != REWARD_AVAX, "Cannot use claimErc20 for AVAX");
        require(accruedReward[recipient][rewardToken] <= amount, "Not enough accrued rewards");
        require(rewardTokenAddresses[rewardToken] != address(0), "reward token address can not be zero");
        EIP20Interface token = EIP20Interface(rewardTokenAddresses[rewardToken]);
        accruedReward[recipient][rewardToken] = accruedReward[recipient][rewardToken].sub(amount);
        token.transfer(recipient, amount);
    }
    modifier adminOnly {
        require(msg.sender == admin, "admin only");
        _;
    }
}