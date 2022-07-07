/**
 *Submitted for verification at Etherscan.io on 2022-07-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

/**
 * @title Represents an ownable resource.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    /**
     * Constructor
     * @param addr The owner of the smart contract
     */
    constructor (address addr) {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        _owner = addr;
        emit OwnershipTransferred(address(0), addr);
    }

    /**
     * @notice This modifier indicates that the function can only be called by the owner.
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Only owner requirement");
        _;
    }

    /**
     * @notice Transfers ownership to the address specified.
     * @param addr Specifies the address of the new owner.
     * @dev Throws if called by any account other than the owner.
     */
    function transferOwnership (address addr) public onlyOwner {
        require(addr != address(0), "non-zero address required");
        emit OwnershipTransferred(_owner, addr);
        _owner = addr;
    }

    /**
     * @notice Destroys the smart contract.
     * @param addr The payable address of the recipient.
     */
    function destroy(address payable addr) public virtual onlyOwner {
        require(addr != address(0), "non-zero address required");
        require(addr != address(1), "ecrecover address not allowed");
        selfdestruct(addr);
    }

    /**
     * @notice Gets the address of the owner.
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @notice Indicates if the address specified is the owner of the resource.
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner(address addr) public view returns (bool) {
        return addr == _owner;
    }
}

interface IAugustusSwapper {
    function getTokenTransferProxy() external view returns (address);
}

interface IERC20NonCompliant {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function totalSupply() external view returns (uint256);
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

interface IMinLpToken {
    function transfer(address to, uint256 value) external;
    function transferFrom(address from, address to, uint256 value) external;
    function approve(address spender, uint256 value) external;
    function balanceOf(address addr) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}

/**
 * @title Defines the interface of the Curve/Convex registry
 */
interface ICurveConvexRegistry {
    function getCurveDepositInfo (bytes32 recordId) external view returns (
        address curveDepositAddress, 
        address inputTokenAddress, 
        address curveLpTokenAddress
    );

    function getConvexDepositInfo (bytes32 recordId) external view returns (
        uint256 convexPoolId,
        address curveLpTokenAddress, 
        address convexRewardsAddress,
        address convexPoolAddress
    );

    function getCurveAddLiquidityInfo (bytes32 recordId) external view returns (
        uint8 totalParams,
        uint8 tokenPosition,
        bool useZap,
        address curveDepositAddress,
        bytes4 addLiquidityFnSig
    );

    function getBalanceInCurve (bytes32 recordId, address callerAddr) external view returns (uint256);
    function getBalanceInConvex (bytes32 recordId, address callerAddr) external view returns (uint256);
    function buildAddLiquidityCallData (bytes32 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees, address senderAddr) external view returns (bytes memory);
}

interface IConvexRewards {
    function getReward(address account, bool claimExtras) external returns(bool);
    function withdrawAllAndUnwrap(bool claim) external;
    function balanceOf(address addr) external view returns(uint256);
    function earned(address account) external view returns (uint256);
    function rewardToken() external view returns (address);
    function stakingToken() external view returns (address);
}

interface IConvexBooster {
    function deposit(uint256 poolId, uint256 amount, bool stake) external returns(bool);
    function withdrawAll(uint256 poolId) external returns(bool);
}

/**
 * @title Represents a wallet capable of interacting with Curve and Convex.
 */
contract CurveConvexWallet is Ownable {
    address constant internal ZERO_ADDRESS = address(0);
    address constant internal CONVEX_BOOSTER_ADDRESS = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;
    address constant internal PARASWAP_SWAPPER = 0xDEF171Fe48CF0115B1d80b88dc8eAB59176FEe57;

    /**
     * @notice The registry
     */
    ICurveConvexRegistry public registry;

    // The reentrancy guard
    bool private _reentrancyGuard;

    /**
     * @notice Constructor
     * @param newOwner The contract owner
     * @param registryInterface The interface of the registry
     */
    constructor (address newOwner, ICurveConvexRegistry registryInterface) Ownable(newOwner) {
        registry = registryInterface;
    }

    /**
     * @notice Throws in case of a reentrant call
     */
    modifier ifNotReentrant () {
        require(!_reentrancyGuard, "Reentrant call rejected");
        _reentrancyGuard = true;
        _;
        _reentrancyGuard = false;
    }

    /**
     * @notice Deposits funds into this contract for further usage.
     * @param inputTokenInterface The token to deposit into this contract
     * @param depositAmount The deposit amount
     */
    function walletDeposit (IERC20NonCompliant inputTokenInterface, uint256 depositAmount) public onlyOwner ifNotReentrant {
        address senderAddr = msg.sender;

        // Make sure the sender can cover the deposit (aka: the sender has enough USDC/ERC20 on their wallet)
        require(inputTokenInterface.balanceOf(senderAddr) >= depositAmount, "Insufficient funds");

        // Make sure the user approved this contract to spend the amount specified
        require(inputTokenInterface.allowance(senderAddr, address(this)) >= depositAmount, "Insufficient allowance");

        uint256 balanceBeforeTransfer = inputTokenInterface.balanceOf(address(this));

        // Make sure the ERC20 transfer succeeded
        inputTokenInterface.transferFrom(senderAddr, address(this), depositAmount);

        require(inputTokenInterface.balanceOf(address(this)) == balanceBeforeTransfer + depositAmount, "Balance verification failed");
    }

    /**
     * @notice Withdraws funds from this contract.
     * @param tokenInterface The token to withdraw
     * @param amount The withdrawal amount
     */
    function walletWithdraw (IERC20NonCompliant tokenInterface, uint256 amount) public onlyOwner ifNotReentrant {
        require(amount > 0, "non-zero amount required");

        address senderAddr = msg.sender;

        // Check the current balance at the contract
        uint256 contractBalanceBefore = tokenInterface.balanceOf(address(this));
        require(contractBalanceBefore >= amount, "Insufficient balance");

        // Check the current balance at the user
        uint256 userBalanceBefore = tokenInterface.balanceOf(senderAddr);

        // Calculate the expected balances after transfer
        uint256 expectedContractBalanceAfterTransfer = contractBalanceBefore - amount;
        uint256 expectedUserBalanceAfterTransfer = userBalanceBefore + amount;

        // Run the transfer. We cannot rely on the non-compliant token so we are forced to check the balances instead
        tokenInterface.transfer(senderAddr, amount);

        // Calculate the balances after transfer
        uint256 contractBalanceAfter = tokenInterface.balanceOf(address(this));
        uint256 userBalanceAfter = tokenInterface.balanceOf(senderAddr);

        // Make sure the transfer succeeded
        require(contractBalanceAfter == expectedContractBalanceAfterTransfer, "Contract balance check failed");
        require(userBalanceAfter == expectedUserBalanceAfterTransfer, "User balance check failed");
    }

    /**
     * @notice Runs an atomic swap on Paraswap
     * @param recordId The ID of the record
     * @param tokenToSell The token to sell
     * @param tokenAmount The number of tokens to sell
     * @param swapPayload The payload for running the swap
     */
    function swap (bytes32 recordId, IERC20NonCompliant tokenToSell, uint256 tokenAmount, bytes memory swapPayload) public onlyOwner ifNotReentrant {
        _swap(recordId, tokenToSell, tokenAmount, swapPayload);
    }

    /**
     * @notice Makes a deposit in Curve and stakes in Convex
     * @dev Notice that the decimals of the LP tokens do not neccessarily match with the precision of the deposit token.
     * @param recordId The ID of the record
     * @param depositAmount The deposit amount
     * @param expectedLpTokensAmountAfterFees The amount of LP tokens expected, after fees.
     */
    function depositAndStake (bytes32 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees) public onlyOwner ifNotReentrant {
        _depositInCurve(recordId, depositAmount, expectedLpTokensAmountAfterFees);
        _depositInConvex(recordId);
    }

    /**
     * @notice Makes a deposit in Curve
     * @dev Notice that the decimals of the LP tokens do not neccessarily match with the precision of the deposit token.
     * @param recordId The ID of the record
     * @param depositAmount The deposit amount
     * @param expectedLpTokensAmountAfterFees The amount of LP tokens expected, after fees.
     */
    function depositInCurve (bytes32 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees) public onlyOwner ifNotReentrant {
        _depositInCurve(recordId, depositAmount, expectedLpTokensAmountAfterFees);
    }

    /**
     * @notice Makes a deposit in Convex
     * @param recordId The ID of the record
     */
    function depositInConvex (bytes32 recordId) public onlyOwner ifNotReentrant {
        _depositInConvex(recordId);
    }

    /**
     * @notice Collects rewards from Convex
     * @param recordId The ID of the record
     */
    function collectRewardsFromConvex (bytes32 recordId) public onlyOwner ifNotReentrant {
        (, , address convexRewardsAddress, address convexPoolAddress) = registry.getConvexDepositInfo(recordId);
        require(convexPoolAddress != ZERO_ADDRESS, "Invalid record");

        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);
        rewardsInterface.getReward(address(this), true);
    }

    /**
     * @notice Withdraws all funds from Convex
     * @param recordId The ID of the record
     */
    function withdrawFromConvex (bytes32 recordId) public onlyOwner ifNotReentrant {
        (, , address convexRewardsAddress, ) = registry.getConvexDepositInfo(recordId);
        require(convexRewardsAddress != ZERO_ADDRESS, "Invalid record");

        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);

        // This is the token we are staking in Convex
        address convexStakingToken = rewardsInterface.stakingToken();
        require(convexStakingToken != ZERO_ADDRESS, "Invalid staking token");

        rewardsInterface.withdrawAllAndUnwrap(true);
    }

    // Runs an atomic swap on Paraswap
    function _swap (bytes32 recordId, IERC20NonCompliant tokenToSell, uint256 tokenAmount, bytes memory swapPayload) private {
        // Checks
        require(tokenAmount > 0, "Non zero amount required");
        require(swapPayload.length > 0, "Swap payload required");

        // The token we want to sell
        uint256 tokenToSellBalanceBefore = tokenToSell.balanceOf(address(this));
        require(tokenToSellBalanceBefore >= tokenAmount, "Insufficient balance of tokens");

        // Get the required info from the trusted registry
        (, address inputTokenAddress, ) = registry.getCurveDepositInfo(recordId);

        // Make sure the record is valid
        require(inputTokenAddress != ZERO_ADDRESS, "Zero address not allowed");

        // Get the address of the token transfer proxy
        IAugustusSwapper augustusSwapperInterface = IAugustusSwapper(PARASWAP_SWAPPER);
        address tokenTransferProxyAddr = augustusSwapperInterface.getTokenTransferProxy();
        require(tokenTransferProxyAddr != ZERO_ADDRESS, "Proxy zero address not allowed");

        // This is the token we expect to receive after a successful trade. It is also the input token expected by the Curve pool.
        IERC20NonCompliant inputTokenInterface = IERC20NonCompliant(inputTokenAddress);
        uint256 contractBalanceBefore = inputTokenInterface.balanceOf(address(this));

        // Approve Paraswap's token transfer proxy. The swap will fail otherwise.
        _approveSpenderIfNeeded(address(this), tokenTransferProxyAddr, tokenAmount, tokenToSell);

        // Submit the trade to Paraswap (for example, we want to trade USDC for FRAX)
        // solhint-disable-next-line avoid-low-level-calls
        (bool success,) = PARASWAP_SWAPPER.call(swapPayload);
        require(success, "Paraswap trade failed");

        // Make sure we received the destination token (say FRAX)
        uint256 contractBalanceAfter = inputTokenInterface.balanceOf(address(this));
        require(contractBalanceAfter > contractBalanceBefore, "Balance check failed after trade");

        // Make sure we sold the token (say USDC)
        uint256 tokenToSellBalanceAfter = tokenToSell.balanceOf(address(this));
        require(tokenToSellBalanceAfter < tokenToSellBalanceBefore, "Balance check failed for source");
    }

    // Approves the spender specified, if needed
    function _approveSpenderIfNeeded (address tokenOwnerAddr, address spenderAddr, uint256 spenderAmount, IERC20NonCompliant tokenInterface) private {
        uint256 currentAllowance = tokenInterface.allowance(tokenOwnerAddr, spenderAddr);

        if (spenderAmount > currentAllowance) {
            tokenInterface.approve(spenderAddr, spenderAmount);
            uint256 newAllowance = tokenInterface.allowance(tokenOwnerAddr, spenderAddr);
            require(newAllowance >= spenderAmount, "Spender approval failed");
        }
    }

    // Makes a deposit in Curve
    function _depositInCurve (bytes32 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees) private {
        require(depositAmount > 0, "Invalid deposit amount");
        require(expectedLpTokensAmountAfterFees > 0, "Invalid LP tokens amount");
        
        // Get the required info from the trusted registry
        (address curveDepositAddress, address inputTokenAddress, address curveLpTokenAddress) = registry.getCurveDepositInfo(recordId);

        // Make sure the record is valid
        require(inputTokenAddress != ZERO_ADDRESS, "Zero address not allowed");

        // Notice that the input token, which is usually an ERC20, is not necessarily compliant with the EIP20 interface. It is partially compliant instead.
        IERC20NonCompliant inputTokenInterface = IERC20NonCompliant(inputTokenAddress);

        // Approve the Curve pool as a valid spender, if needed.
        _approveSpenderIfNeeded(address(this), curveDepositAddress, depositAmount, inputTokenInterface);

        // Build the TX call data for making a deposit
        bytes memory curveDepositTxData = registry.buildAddLiquidityCallData(recordId, depositAmount, expectedLpTokensAmountAfterFees, address(this));

        // This is the LP token we will get in exchange for our deposit
        IMinLpToken curveLpTokenInterface = IMinLpToken(curveLpTokenAddress);
        uint256 lpTokenBalanceBefore = curveLpTokenInterface.balanceOf(address(this));

        // Deposit in the Curve pool
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(curveDepositAddress).call(curveDepositTxData);
        require(success, "Curve deposit failed");

        // Check the amount of LP tokens we received in exchange for our deposit
        uint256 lpTokenBalanceAfter = curveLpTokenInterface.balanceOf(address(this));
        uint256 lpTokensReceived = lpTokenBalanceAfter - lpTokenBalanceBefore;
        require(lpTokensReceived >= expectedLpTokensAmountAfterFees, "LP Balance verification failed");
    }

    // Makes a deposit in Convex
    function _depositInConvex (bytes32 recordId) private {
        // Get the required info
        (uint256 convexPoolId, address curveLpTokenAddress, address convexRewardsAddress,) = registry.getConvexDepositInfo(recordId);

        // Make sure the record is valid
        require(curveLpTokenAddress != ZERO_ADDRESS, "Invalid record");

        // This is the LP token we received from Curve in exchange for our deposit
        IERC20NonCompliant curveLpTokenInterface = IERC20NonCompliant(curveLpTokenAddress);

        // This is the amount of LP tokens to deposit in Convex
        uint256 depositAmount = curveLpTokenInterface.balanceOf(address(this));
        require(depositAmount > 0, "Insufficient balance of LP token");

        // Convex will report our rewards through this contract
        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);

        // This is the ultimate token we will be staking in Convex after making our deposit
        address convexStakingToken = rewardsInterface.stakingToken();
        require(convexStakingToken != ZERO_ADDRESS, "Invalid staking token");

        uint256 convexBalanceBefore = rewardsInterface.balanceOf(address(this));

        // ERC20 approval
        _approveSpenderIfNeeded(address(this), CONVEX_BOOSTER_ADDRESS, depositAmount, curveLpTokenInterface);

        // Deposit and stake in Convex
        IConvexBooster convexBoosterInterface = IConvexBooster(CONVEX_BOOSTER_ADDRESS);
        require(convexBoosterInterface.deposit(convexPoolId, depositAmount, true), "Convex deposit failed");

        uint256 convexBalanceAfter = rewardsInterface.balanceOf(address(this));
        uint256 tokensReceivedFromConvex = convexBalanceAfter - convexBalanceBefore;
        require(tokensReceivedFromConvex >= depositAmount, "Convex balance mismatch");
    }
}