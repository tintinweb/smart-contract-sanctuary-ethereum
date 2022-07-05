/**
 *Submitted for verification at Etherscan.io on 2022-07-05
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


/**
 * @notice This library provides stateless, general purpose functions.
 */
library Utils {
    // The code hash of any EOA
    bytes32 constant internal EOA_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    /**
     * @notice Indicates if the address specified represents a smart contract.
     * @dev Notice that this method returns TRUE if the address is a contract under construction
     * @param addr The address to evaluate
     * @return Returns true if the address represents a smart contract
     */
    function isContract (address addr) internal view returns (bool) {
        bytes32 eoaHash = EOA_HASH;

        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return (codeHash != eoaHash && codeHash != 0x0);
    }

    /**
     * @notice Gets the code hash of the address specified
     * @param addr The address to evaluate
     * @return Returns a hash
     */
    function getCodeHash (address addr) internal view returns (bytes32) {
        bytes32 codeHash;

        // solhint-disable-next-line no-inline-assembly
        assembly { codeHash := extcodehash(addr) }

        return codeHash;
    }
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

contract CurveConvexRegistry is Ownable {
    address constant internal ZERO_ADDRESS = address(0);
    bytes4 constant internal ADD_LIQUIDITY_2_POOL = 0x0b4c7e4d; // bytes4(keccak256("add_liquidity(uint256[2],uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_2_ZAP  = 0x4fb92465; // bytes4(keccak256("add_liquidity(address,uint256[2],uint256,address)"));
    bytes4 constant internal ADD_LIQUIDITY_4_POOL = 0x029b2f34; // bytes4(keccak256("add_liquidity(uint256[4],uint256)"));
    bytes4 constant internal ADD_LIQUIDITY_4_ZAP  = 0xd0b951e8; // bytes4(keccak256("add_liquidity(address,uint256[4],uint256,address)"));

    struct Record {
        bytes32 curvePoolHash;
        address curvePoolAddress;
        address curveLpTokenAddress;
        address curveDepositAddress;
        address inputTokenAddress;
        address convexPoolAddress; 
        address convexRewardsAddress;
        uint256 convexPoolId; 
        uint8 totalParams;
        uint8 tokenPosition;
        bool useZap;
        bytes4 addLiquidityFnSig;
    }

    uint256 private _seed;
    mapping (uint256 => Record) internal _records;

    constructor (address newOwner) Ownable(newOwner) { // solhint-disable-line no-empty-blocks
    }

    /**
     * @notice Updates the maximum limit of the total supply.
     * @param poolName The human readable name of the pool
     * @param curvePoolAddr The address of the pool, per Curve
     * @param curveLpTokenAddr The address of the LP token, per Curve
     * @param curveDepositAddr The deposit address in Curve
     * @param useZap Indicates if the deposit address is a Zap address or not
     * @param totalParams The number of parameters expected when adding liquidity to the pool
     * @param convexPoolAddr The address of the Convex pool
     * @param convexRewardsAddr The address of the Convex rewards
     * @param convexPoolId The ID of the Convex pool
     * @param inputToken The token to deposit in Curve
     * @param tokenPosition The token position in Curve
     */
    function registerPool (
        string memory poolName, 
        address curvePoolAddr, 
        IMinLpToken curveLpTokenAddr, 
        address curveDepositAddr,
        bool useZap, 
        uint8 totalParams,
        address convexPoolAddr, 
        address convexRewardsAddr,
        uint256 convexPoolId,
        IERC20NonCompliant inputToken,
        uint8 tokenPosition
    ) public onlyOwner {
        // Checks
        require(curvePoolAddr != ZERO_ADDRESS, "non-zero address required");
        require(curveDepositAddr != ZERO_ADDRESS, "non-zero address required");
        require(convexPoolAddr != ZERO_ADDRESS, "non-zero address required");
        require(convexRewardsAddr != ZERO_ADDRESS, "non-zero address required");
        require(address(curveLpTokenAddr) != ZERO_ADDRESS, "non-zero address required");
        require(address(inputToken) != ZERO_ADDRESS, "non-zero address required");
        require((totalParams == 2) || (totalParams == 4), "Invalid number of parameters");
        require(tokenPosition < totalParams, "Invalid target index");

        // Make sure the deposit address is a smart contract.
        // Query the exact code hash of the deposit contract. We don't want to deposit funds in an unknown contract implementation.
        bytes32 depositContractCodeHash = Utils.getCodeHash(curveDepositAddr);
        bool depositAddrIsContract = (depositContractCodeHash != Utils.EOA_HASH && depositContractCodeHash != 0x0);
        require(depositAddrIsContract, "Invalid Deposit address");

        // Define the record
        _records[_seed] = Record(
                            keccak256(abi.encode(poolName)), 
                            curvePoolAddr, 
                            address(curveLpTokenAddr), 
                            curveDepositAddr, 
                            address(inputToken), 
                            convexPoolAddr,
                            convexRewardsAddr,
                            convexPoolId,
                            totalParams, 
                            tokenPosition,
                            useZap,
                            _getAddLiquiditySignature(useZap, totalParams)
                        );

        // Increase the seed
        _seed++;
    }

    function getCurveDepositInfo (uint256 recordId) public view returns (
        address curveDepositAddress, 
        address inputTokenAddress, 
        address curveLpTokenAddress
    ) {
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        inputTokenAddress = _records[recordId].inputTokenAddress;
    }

    function getConvexDepositInfo (uint256 recordId) public view returns (
        uint256 convexPoolId,
        address curveLpTokenAddress, 
        address convexRewardsAddress,
        address convexPoolAddress
    ) {
        convexPoolId = _records[recordId].convexPoolId;
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        convexRewardsAddress = _records[recordId].convexRewardsAddress;
        convexPoolAddress = _records[recordId].convexPoolAddress;
    }

    function getCurveAddLiquidityInfo (uint256 recordId) public view returns (
        uint8 totalParams,
        uint8 tokenPosition,
        bool useZap,
        address curveDepositAddress,
        bytes4 addLiquidityFnSig
    ) {
        totalParams = _records[recordId].totalParams;
        tokenPosition = _records[recordId].tokenPosition;
        useZap = _records[recordId].useZap;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        addLiquidityFnSig = _records[recordId].addLiquidityFnSig;
    }

    function getRecord (uint256 recordId) public view returns (
        bytes32 curvePoolHash,
        address curvePoolAddress,
        address curveLpTokenAddress,
        address curveDepositAddress,
        address inputTokenAddress,
        address convexPoolAddress, 
        address convexRewardsAddress,
        uint8 totalParams,
        uint8 tokenPosition,
        bool useZap,
        bytes4 addLiquidityFnSig
    ) {
        curvePoolHash = _records[recordId].curvePoolHash;
        curvePoolAddress = _records[recordId].curvePoolAddress;
        curveLpTokenAddress = _records[recordId].curveLpTokenAddress;
        curveDepositAddress = _records[recordId].curveDepositAddress;
        inputTokenAddress = _records[recordId].inputTokenAddress;
        convexPoolAddress = _records[recordId].convexPoolAddress;
        convexRewardsAddress = _records[recordId].convexRewardsAddress;
        totalParams = _records[recordId].totalParams;
        tokenPosition = _records[recordId].tokenPosition;
        useZap = _records[recordId].useZap;
        addLiquidityFnSig = _records[recordId].addLiquidityFnSig;
    }

    function _getAddLiquiditySignature (bool useZap, uint8 totalParams) private pure returns (bytes4) {
        if (totalParams == 4) {
            return (useZap) ? ADD_LIQUIDITY_4_ZAP : ADD_LIQUIDITY_4_POOL;
        }
        else if (totalParams == 2) {
            return (useZap) ? ADD_LIQUIDITY_2_ZAP : ADD_LIQUIDITY_2_POOL;
        }
        else revert("Invalid parameters");
    }
}

interface IConvexPool {
    function withdrawAll(bool claim) external;
}

interface IConvexRewards {
    function balanceOf(address addr) external view returns(uint256);
    function stakingToken() external returns (address);
    function earned(address account) external view returns (uint256);
}

interface IConvexBooster {
    function deposit(uint256 poolId, uint256 amount, bool stake) external returns(bool);
    function withdrawAll(uint256 poolId) external returns(bool);
}

contract CurveConvexWallet is Ownable {
    address constant internal ZERO_ADDRESS = address(0);
    address constant internal CONVEX_BOOSTER_ADDRESS = 0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    CurveConvexRegistry internal _registry;

    // The reentrancy guard
    bool private _reentrancyGuard;

    constructor (address newOwner, CurveConvexRegistry registryInterface) Ownable(newOwner) {
        _registry = registryInterface;
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

    function depositInCurve (uint256 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees) public onlyOwner ifNotReentrant {
        require(depositAmount > 0, "Invalid deposit amount");
        require(expectedLpTokensAmountAfterFees > 0, "Invalid LP tokens amount");
        
        // Get the required info
        (
            address curveDepositAddress, 
            address inputTokenAddress, 
            address curveLpTokenAddress
        ) = _registry.getCurveDepositInfo(recordId);

        // Make sure the record is valid
        require(inputTokenAddress != ZERO_ADDRESS, "Zero address not allowed");

        // Notice that the input token, which is usually an ERC20, is not necessarily compliant with the EIP20 interface. It is partially compliant instead.
        IERC20NonCompliant inputTokenInterface = IERC20NonCompliant(inputTokenAddress);

        // Approve the Curve pool as a valid spender, if needed.
        _approveSpenderIfNeeded(address(this), curveDepositAddress, depositAmount, inputTokenInterface);

        // Build the TX call data for making a deposit
        bytes memory curveDepositTxData = _buildAddLiquidityCallData(recordId, depositAmount, expectedLpTokensAmountAfterFees);

        // This is the LP token we will get in exchange for our deposit
        IMinLpToken curveLpTokenInterface = IMinLpToken(curveLpTokenAddress);
        uint256 lpTokenBalanceBefore = curveLpTokenInterface.balanceOf(address(this));

        // Deposit in the Curve pool
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = address(curveDepositAddress).call(curveDepositTxData);
        require(success, "Curve deposit failed");

        // Check the amount of LP tokens we received in exchange for our deposit
        uint256 lpTokenBalanceAfter = curveLpTokenInterface.balanceOf(address(this));
        //uint256 lpTokensReceived = lpTokenBalanceAfter - lpTokenBalanceBefore;
        //require(lpTokensReceived >= expectedLpTokensAmountAfterFees, "LP Balance verification failed");
        require(lpTokenBalanceAfter > lpTokenBalanceBefore, "LP Balance verification failed");
    }

    function depositInConvex (uint256 recordId) public onlyOwner ifNotReentrant {
        // Get the required info
        (uint256 convexPoolId, address curveLpTokenAddress, address convexRewardsAddress,) = _registry.getConvexDepositInfo(recordId);

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

        // This is the LP token we will get from Convex in exchange for our deposit
        //IERC20NonCompliant convexLpTokenInterface = IERC20NonCompliant(convexPoolAddress);

        // ERC20 approval
        _approveSpenderIfNeeded(address(this), CONVEX_BOOSTER_ADDRESS, depositAmount, curveLpTokenInterface);

        // Deposit and stake in Convex
        IConvexBooster convexBoosterInterface = IConvexBooster(CONVEX_BOOSTER_ADDRESS);
        require(convexBoosterInterface.deposit(convexPoolId, depositAmount, true), "Convex deposit failed");

        uint256 convexBalanceAfter = rewardsInterface.balanceOf(address(this));
        uint256 tokensReceivedFromConvex = convexBalanceAfter - convexBalanceBefore;
        require(tokensReceivedFromConvex >= depositAmount, "Convex balance mismatch");
    }

    function withdrawFromConvex (uint256 recordId) public onlyOwner ifNotReentrant {
        (, , address convexRewardsAddress, address convexPoolAddress) = _registry.getConvexDepositInfo(recordId);
        require(convexPoolAddress != ZERO_ADDRESS, "Invalid record");

        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);

        // This is the token we are staking in Convex
        address convexStakingToken = rewardsInterface.stakingToken();
        require(convexStakingToken != ZERO_ADDRESS, "Invalid staking token");

        IConvexPool p = IConvexPool(convexPoolAddress);
        p.withdrawAll(true);

        //(uint256 convexPoolId, , , address convexPoolAddress) = _registry.getConvexDepositInfo(recordId);
        // This is the LP token we received from Convex in exchange for our deposit
        //IERC20NonCompliant convexLpTokenInterface = IERC20NonCompliant(convexPoolAddress);

        //IConvexBooster convexBoosterInterface = IConvexBooster(CONVEX_BOOSTER_ADDRESS);
        //require(convexBoosterInterface.withdrawAll(convexPoolId), "Convex withdrawal failed");
    }

    function getEarnedRewards (uint256 recordId) public view returns (uint256) {
        (, , address convexRewardsAddress, address convexPoolAddress) = _registry.getConvexDepositInfo(recordId);
        require(convexPoolAddress != ZERO_ADDRESS, "Invalid record");

        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);
        return rewardsInterface.earned(address(this));
    }

    function getBalanceInCurve (uint256 recordId) public view returns (uint256) {
        (, , address curveLpTokenAddress) = _registry.getCurveDepositInfo(recordId);

        IMinLpToken curveLpTokenInterface = IMinLpToken(curveLpTokenAddress);
        return curveLpTokenInterface.balanceOf(address(this));
    }

    function getBalanceInConvex (uint256 recordId) public view returns (uint256) {
        (, , address convexRewardsAddress,) = _registry.getConvexDepositInfo(recordId);
        IConvexRewards rewardsInterface = IConvexRewards(convexRewardsAddress);
        return rewardsInterface.balanceOf(address(this));
    }

    function _approveSpenderIfNeeded (address tokenOwnerAddr, address spenderAddr, uint256 spenderAmount, IERC20NonCompliant tokenInterface) private {
        uint256 currentAllowance = tokenInterface.allowance(tokenOwnerAddr, spenderAddr);

        if (spenderAmount > currentAllowance) {
            tokenInterface.approve(spenderAddr, spenderAmount);
            uint256 newAllowance = tokenInterface.allowance(tokenOwnerAddr, spenderAddr);
            require(newAllowance >= spenderAmount, "Spender approval failed");
        }
    }

    function _buildAddLiquidityCallData (uint256 recordId, uint256 depositAmount, uint256 expectedLpTokensAmountAfterFees) private view returns (bytes memory) {
        // Get the parameters
        (
            uint8 totalParams,
            uint8 tokenPosition,
            bool useZap,
            address curveDepositAddress,
            bytes4 addLiquidityFnSig
        ) = _registry.getCurveAddLiquidityInfo(recordId);

        require((totalParams == 2) || (totalParams == 4), "Invalid number of parameters");

        // Get the resulting payload
        if (totalParams == 4) {
            return useZap 
                    ? abi.encodeWithSelector(addLiquidityFnSig, curveDepositAddress, _buildFixedArrayOf4(tokenPosition, depositAmount), expectedLpTokensAmountAfterFees, address(this))
                    : abi.encodeWithSelector(addLiquidityFnSig, _buildFixedArrayOf4(tokenPosition, depositAmount), expectedLpTokensAmountAfterFees);
        }
        else if (totalParams == 2) {
            return useZap 
                    ? abi.encodeWithSelector(addLiquidityFnSig, curveDepositAddress, _buildFixedArrayOf2(tokenPosition, depositAmount), expectedLpTokensAmountAfterFees, address(this))
                    : abi.encodeWithSelector(addLiquidityFnSig, _buildFixedArrayOf2(tokenPosition, depositAmount), expectedLpTokensAmountAfterFees);
        }
        else revert("Invalid parameters");
    }

    function _buildFixedArrayOf2 (uint8 targetIndex, uint256 targetValue) private pure returns (uint256[2] memory) {
        require(targetIndex < 2, "Invalid target index");
        return (targetIndex == 0) ? [targetValue, 0] : [0, targetValue];
    }

    function _buildFixedArrayOf4 (uint8 targetIndex, uint256 targetValue) private pure returns (uint256[4] memory) {
        require(targetIndex < 4, "Invalid target index");
        if (targetIndex == 0) return uint256[4]([targetValue, 0, 0, 0]);
        else if (targetIndex == 1) return uint256[4]([0, targetValue, 0, 0]);
        else if (targetIndex == 2) return uint256[4]([0, 0, targetValue, 0]);
        else return uint256[4]([0, 0, 0, targetValue]);
    }
}