/**
 *Submitted for verification at Etherscan.io on 2023-03-08
*/

// Sources flattened with hardhat v2.12.7 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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


// File contracts/interfaces/IZyberRouter01.sol

pragma solidity >=0.6.2;

interface IZyberRouter01 {
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
    )
        external
        payable
        returns (uint amountToken, uint amountETH, uint liquidity);

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
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint amountA, uint amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
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

    function swapExactETHForTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactETH(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapExactTokensForETH(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapETHForExactTokens(
        uint amountOut,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable returns (uint[] memory amounts);

    function quote(
        uint amountA,
        uint reserveA,
        uint reserveB
    ) external pure returns (uint amountB);

    function getAmountOut(
        uint amountIn,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountOut);

    function getAmountIn(
        uint amountOut,
        uint reserveIn,
        uint reserveOut
    ) external pure returns (uint amountIn);

    function getAmountsOut(
        uint amountIn,
        address[] calldata path
    ) external view returns (uint[] memory amounts);

    function getAmountsIn(
        uint amountOut,
        address[] calldata path
    ) external view returns (uint[] memory amounts);
}


// File contracts/interfaces/IZyberRouter02.sol

pragma solidity >=0.6.2;

interface IZyberRouter02 is IZyberRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}


// File contracts/DEGGSPresaleV2.sol

pragma solidity ^0.8.9;


contract DEGGSPresaleV2 {
    address public constant ZYBER_ROUTER = 0x16e71B13fE6079B4312063F7E81F76d165Ad32Ad;

    uint256 public startTime;
    uint256 public endTime;
    address public DEGGS;

    address public immutable owner;
    uint256 public immutable maxPerWallet = 10 ether;

    // 1 eth = 1000000000 DEGGS
    uint256 public presalePrice = 1000000000 * 1e18;

    // launchPrice = (1.2)* presalePrice
    uint256 public launchPrice = (presalePrice * 5) / 6;

    // The pre sale eth max amount
    uint256 public presaleMax = 320 ether;
    uint256 public presaleSoftMax = 10 ether;

    uint256 public totalPurchased;
    bool public initLP = false;
    bool public initConfig = false;
    mapping(address => uint256) public amountPurchased;

    uint256 public totalReferralReward;
    uint256 public totalUnclaimedReferralReward;
    address[] public referrers;
    mapping(address => uint256) public referralInfo;

    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor(uint256 _startTime, uint256 _endTime) {
        owner = msg.sender;
        startTime = _startTime;
        endTime = _endTime;
    }

    function initConfigDEGGS(address _tokenAddress) external onlyOwner {
        require(_tokenAddress != address(0), "No zero address");
        require(!initConfig, "Already configured");

        DEGGS = _tokenAddress;
        initConfig = true;
    }

    function buyPresale(address referralAddress) external payable {
        require(
            block.timestamp >= startTime && block.timestamp <= endTime,
            "Not active"
        );
        require(msg.sender == tx.origin, "No contracts");
        require(msg.value > 0, "Zero amount");
        require(msg.sender != referralAddress, "Illegal referral address ");
        require(
            amountPurchased[msg.sender] + msg.value <= maxPerWallet,
            "Over wallet limit"
        );
        require(totalPurchased + msg.value <= presaleMax, "Amount over limit");

        amountPurchased[msg.sender] += msg.value;
        totalPurchased += msg.value;

        if (
            referralAddress != address(0) &&
            referralAddress !=
            address(0x000000000000000000000000000000000000dEaD)
        ) {
            uint256 amount = calculateRefAmount(msg.value);
            referralInfo[referralAddress] += amount;
            totalReferralReward += amount;
            totalUnclaimedReferralReward += amount;
            referrers.push(referralAddress);
        }
    }

    function claimDEGGS() external {
        require(
            block.timestamp > endTime && totalPurchased >= presaleSoftMax,
            "Not claimable"
        );
        require(amountPurchased[msg.sender] > 0, "No amount claimable");
        require(initLP, "No liquidity pool setup");

        uint256 amount = (amountPurchased[msg.sender] * presalePrice) / 1e18;
        amountPurchased[msg.sender] = 0;
        IERC20(DEGGS).transfer(msg.sender, amount);
    }

    function claimRefETHReward() external {
        require(
            block.timestamp > endTime && totalPurchased >= presaleSoftMax,
            "Not claimable"
        );
        uint256 amount = referralInfo[msg.sender];
        require(amount > 0, "No claimable amount");

        referralInfo[msg.sender] = 0;
        totalUnclaimedReferralReward -= amount;
        payable(msg.sender).transfer(amount);
    }

    function payRefETHReward() external onlyOwner {
        require(
            block.timestamp > endTime && totalPurchased >= presaleSoftMax,
            "Not payable"
        );
        for (uint i = 0; i < referrers.length; i++) {
            address referrer = referrers[i];
            uint256 amount = referralInfo[referrer];
            if (amount > 0) {
                (bool success,) = referrer.call{value : amount}("");
                if (success) {
                    referralInfo[referrer] = 0;
                    totalUnclaimedReferralReward -= amount;
                }
            }
        }
    }

    // Presale amount < presaleSoftMax == Failed
    function claimEthBackWhenPresaleFailed(address participant) external {
        require(block.timestamp > endTime, "Not backable");
        require(totalPurchased < presaleSoftMax, "Presale not failed");
        require(amountPurchased[participant] > 0, "No claimable amount");
        payable(participant).transfer(amountPurchased[participant]);
    }

    function handleUnclaimedRefReward() external onlyOwner {
        require(block.timestamp > endTime + 30 days, "Not claimable");
        require(totalUnclaimedReferralReward > 0, "No claimable amount ");
        payable(msg.sender).transfer(totalUnclaimedReferralReward);
    }

    function setMax(uint256 _max) external onlyOwner {
        require(_max > 0, "Amount Error");
        presaleMax = _max;
    }

    function setPresaleSoftMax(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Amount Error");
        presaleSoftMax = _amount;
    }

    function setStartTimeAndEndTime(
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner {
        require(_startTime < _endTime && _startTime >= startTime);
        startTime = _startTime;
        endTime = _endTime;
    }

    function addLiquidity() external onlyOwner {
        require(block.timestamp > endTime, "Not finished");
        require(totalPurchased >= presaleSoftMax, "Presale Failed");
        require(!initLP && initConfig);

        uint256 totalAvailable = totalPurchased - totalReferralReward;
        uint256 ethAmount = (totalAvailable * 80) / 100;
        uint256 tokenAmount = (ethAmount * launchPrice) / 1e18;
        require(
            IERC20(DEGGS).balanceOf(address(this)) >= tokenAmount,
            "Insufficient DEGGS balance"
        );

        IERC20(DEGGS).approve(ZYBER_ROUTER, tokenAmount);
        (bool success,) = owner.call{value : (totalAvailable * 20) / 100}("");
        require(success);
        initLP = true;

        IZyberRouter02(ZYBER_ROUTER).addLiquidityETH{value : ethAmount}(
            DEGGS,
            tokenAmount,
            1,
            1,
            0x000000000000000000000000000000000000dEaD,
            type(uint256).max
        );
    }

    function getRequestDEGGSAmount() public view returns (uint256 amount) {
        require(block.timestamp > endTime, "Not finished");
        require(totalPurchased >= presaleSoftMax, "Presale Failed");
        require(!initLP);

        uint256 totalAvailable = totalPurchased - totalReferralReward;
        uint256 ethAmount = (totalAvailable * 80) / 100;
        uint256 lpDEGGSAmount = (ethAmount * launchPrice) / 1e18;
        uint256 presalDEGGSAmount = (totalAvailable * presalePrice) / 1e18;
        amount = lpDEGGSAmount + presalDEGGSAmount;
    }

    /**
     *
     * @param amount buyPresale amount
     */
    function calculateRefAmount(uint256 amount) public pure returns (uint256) {
        if (amount == 10 ether) {
            return 1 ether;
        }

        if (amount < 0.1 ether) {
            return 0 ether;
        }

        if (amount >= 0.1 ether && amount < 0.3 ether) {
            return (amount * 10) / 1000;
        }

        if (amount >= 0.3 ether && amount < 0.5 ether) {
            return (amount * 12) / 1000;
        }

        if (amount >= 0.5 ether && amount < 2 ether) {
            return (amount * 17) / 1000;
        }

        if (amount >= 2 ether && amount < 3 ether) {
            return (amount * 35) / 1000;
        }

        if (amount >= 3 ether && amount < 4 ether) {
            return (amount * 50) / 1000;
        }

        if (amount >= 4 ether && amount < 6 ether) {
            return (amount * 60) / 1000;
        }

        if (amount >= 6 ether && amount < 10 ether) {
            return (amount * 80) / 1000;
        }

        return 0;
    }
}