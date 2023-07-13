// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "./FixedPoint.sol";
import "./ICivFund.sol";
import "./UniswapV2OracleLibrary.sol";

/// @title  Civ Vault
/// @author Ren / Frank

contract CivVaultGetter is ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for ICivFundRT;
    using FixedPoint for *;

    ICivVault civVault;
    /// @notice Uniswap Factory address
    address public constant UNISWAP_FACTORY =
        0x7E0987E5b3a30e3f2828572Bb659A548460a3003;
    /// @notice Wrapped ETH Address
    address public constant WETH_ADDRESS =
        0x7b79995e5f793A07Bc00c21412e50Ecae098E7f9;
    /// @notice Dead Address
    address public constant NULL_ADDRESS =
        0x0000000000000000000000000000000000000000;
    /// @notice Uniswap TWAP Period
    uint public constant PERIOD = 24 hours;

    /// @notice Each Pools Uniswap Pair Info List
    mapping(uint256 => PairInfo[]) public pairInfo;

    modifier onlyVault() {
        require(msg.sender == address(civVault), "not owner");
        _;
    }

    constructor(address _civVaultAddress) {
        civVault = ICivVault(_civVaultAddress);
    }

    /// @notice Add new uniswap pair info to pairInfo list
    /// @dev Interal function
    /// @param _pid Pool Id
    /// @param _pair Uniswap Pair Interface
    function addPair(uint256 _pid, IUniswapV2Pair _pair) internal {
        (, , uint32 blockTimestampLast) = _pair.getReserves();
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(_pair));
        uint32 timeElapsed = blockTimestamp - blockTimestampLast; // overflow is desired
        FixedPoint.uq112x112 memory price0Average = FixedPoint.uq112x112(
            uint224(
                (price0Cumulative - _pair.price0CumulativeLast()) / timeElapsed
            )
        );
        FixedPoint.uq112x112 memory price1Average = FixedPoint.uq112x112(
            uint224(
                (price1Cumulative - _pair.price1CumulativeLast()) / timeElapsed
            )
        );
        pairInfo[_pid].push(
            PairInfo({
                pair: _pair,
                price0CumulativeLast: price0Cumulative,
                price1CumulativeLast: price1Cumulative,
                token0: _pair.token0(),
                token1: _pair.token1(),
                price0Average: price0Average,
                price1Average: price1Average,
                blockTimestampLast: blockTimestamp
            })
        );
    }

    /// @notice Add new uniswap pair info to pairInfo list from token pair address
    /// @dev Interal function
    /// @param _pid Pool Id
    /// @param _token0 Token0 Address
    /// @param _token1 Token1 Address
    function addUniPair(
        uint256 _pid,
        address _token0,
        address _token1
    ) external onlyVault {
        IUniswapV2Factory factory = IUniswapV2Factory(UNISWAP_FACTORY);
        address pairAddress = factory.getPair(_token1, _token0);

        if (pairAddress == NULL_ADDRESS) {
            pairAddress = factory.getPair(_token1, WETH_ADDRESS);
            require(pairAddress != NULL_ADDRESS, "can't get first pair");
            IUniswapV2Pair _pairA = IUniswapV2Pair(pairAddress);
            addPair(_pid, _pairA);
            pairAddress = factory.getPair(_token0, WETH_ADDRESS);
            require(pairAddress != NULL_ADDRESS, "can't get second pair");
            IUniswapV2Pair _pairB = IUniswapV2Pair(pairAddress);
            addPair(_pid, _pairB);
        } else {
            IUniswapV2Pair _pair = IUniswapV2Pair(pairAddress);
            addPair(_pid, _pair);
        }
    }

    /// @notice Update Uniswap LP token price
    /// @dev Anyone can call this function but we update price after PERIOD of time
    /// @param _pid Pool Id
    /**
     * @param index PairInfo index
     *              We can have 1 or 2 index
     *              If Deposit/Guarantee Token Pair exists on uniswap there's only 1 pairInfo
     *              If Deposit/Guarantee Token Pair does not exist on uniswap, we have 2 pairInfo
     *              Deposit/WETH Pair and Guarantee/WETH token pair to get price
     */
    function update(uint256 _pid, uint256 index) public {
        PairInfo storage info = pairInfo[_pid][index];
        (
            uint price0Cumulative,
            uint price1Cumulative,
            uint32 blockTimestamp
        ) = UniswapV2OracleLibrary.currentCumulativePrices(address(info.pair));
        uint32 timeElapsed = blockTimestamp - info.blockTimestampLast; // overflow is desired

        // ensure that at least one full period has passed since the last update
        if (timeElapsed < PERIOD) return;

        // overflow is desired, casting never truncates
        // cumulative price is in (uq112x112 price * seconds) units so we simply wrap it after division by time elapsed
        info.price0Average = FixedPoint.uq112x112(
            uint224(
                (price0Cumulative - info.price0CumulativeLast) / timeElapsed
            )
        );
        info.price0CumulativeLast = price0Cumulative;
        info.price1Average = FixedPoint.uq112x112(
            uint224(
                (price1Cumulative - info.price1CumulativeLast) / timeElapsed
            )
        );
        info.price1CumulativeLast = price1Cumulative;
        info.blockTimestampLast = blockTimestamp;
    }

    /// @notice Update Uniswap LP token price for all pairs
    /// @dev Anyone can call this function but we update price after PERIOD of time
    /// @param _pid Pool Id
    function updateAll(uint256 _pid) public {
        for (uint i = 0; i < pairInfo[_pid].length; i++) update(_pid, i);
    }

    /**
     * @dev Determines if a user is new to a given pool based on the isActive property in userInfo.
     * @param _pid The ID of the pool to check the user status for.
     * @param _user The address of the user to check.
     * @return A boolean value indicating if the user is new. Returns true if the user is not active, indicating they are new.
     */
    function getIsNewUser(
        uint256 _pid,
        address _user
    ) public view returns (bool) {
        return !civVault.getUserInfo(_pid, _user).isActive;
    }

    /// @dev Get Guarantee amount for deposit to the vault
    /// @param _pid Pool Id
    /// @param amount Amount to deposit in the vault
    /// @return amount Guarantee Token Amount needs for deposit in a given pool
    function getDepositGuarantee(
        uint256 _pid,
        uint256 amount
    ) external view returns (uint) {
        return
            (getPrice(_pid, amount) * civVault.guarantee_fee()) /
            civVault.feeBase();
    }

    /// @dev Get a given Epoch deposit info on a given pool
    /// @param _pid Pool Id
    /// @param _user userAddress
    /// @return _epoch epoch value
    function getDepositParams(
        uint256 _pid,
        address _user,
        uint256 _epoch
    ) external view returns (DepositParams memory) {
        return civVault.getDepositParams(_pid, _user, _epoch);
    }

    /// @dev Get available deposit amount based of user's guarantee amount
    /// @param _pid Pool Id
    /// @return amount Current Available Deposit amount regarding users's current guarantee token balance in a given pool
    function getAllowedDeposit(
        uint256 _pid
    ) external view returns (uint) {
        IERC20Extended guarantee = IERC20Extended(
            address(civVault.getPoolInfo(_pid).guaranteeToken)
        );
        uint256 balance = guarantee.balanceOf(msg.sender);
        return
            (getReversePrice(_pid, balance) * civVault.feeBase()) /
            civVault.guarantee_fee();
    }

    /// @dev Get Guarantee Token symbol and decimal
    /// @param _pid Pool Id
    /// @return symbol Guarantee Token Symbol in a given pool
    /// @return decimals Guarantee Token Decimal in a given pool
    function getGuaranteeTokenInfo(
        uint256 _pid
    )
        external
        view
        returns (string memory symbol, uint decimals)
    {
        IERC20Extended guarantee = IERC20Extended(
            address(civVault.getPoolInfo(_pid).guaranteeToken)
        );
        symbol = guarantee.symbol();
        decimals = guarantee.decimals();
    }

    /// @dev Get claimable guarantee token amount
    /// @param _pid Pool Id
    /// @param _user userAddress
    /// @return amount Current claimable guarantee token amount
    function getClaimableGuaranteeToken(
        uint256 _pid,
        address _user
    ) external view returns (uint256) {
        VaultInfo memory vault = civVault.getVaultInfo(_pid);
        UserInfo memory user = civVault.getUserInfo(_pid, _user);
        uint256 curEpoch = civVault.getCurrentEpoch(_pid);
        uint256 unLocked;
        for (uint256 i = user.startingEpochGuarantee; i < curEpoch; i++) {
            if (
                block.timestamp >=
                civVault.getEpochInfo(_pid, i).epochStartTime + vault.lockPeriod
            ) {
                unLocked += civVault.getDepositParams(_pid, _user, i).guaranteeDepositQuantity;
            }
        }

        return unLocked;
    }

    /// @notice get net values for new VPS for a certain epoch
    /// @param _pid Pool Id
    /// @param _newVPS New Value Per Share
    /// @param _epochId Epoch Id
    /// @return _epochs array of unclaimed epochs
    function getNetValues(
        uint256 _pid,
        uint256 _newVPS,
        uint256 _epochId
    ) public view returns (uint256, uint256) {
        EpochInfo memory epoch = civVault.getEpochInfo(_pid, _epochId);
        require(
            block.timestamp < epoch.epochStartTime + civVault.getVaultInfo(_pid).epochDuration,
            "ERR_24"
        );
        uint256 currentWithdraw = _newVPS * epoch.totWithdrawals;
        uint256 newShares = epoch.totDeposits / _newVPS;

        return (currentWithdraw, newShares);
    }

    /// @notice get unclaimed withdrawed token epochs
    /// @param _pid Pool Id
    /// @return _epochs array of unclaimed epochs
    function getUnclaimedTokenEpochs(
        uint256 _pid,
        address _user
    ) public view returns (uint256) {
        uint256 curEpoch = civVault.getVaultInfo(_pid).lastProcessedEpoch;
        if (!civVault.getEpochInfo(_pid, curEpoch).withdrawalsEnabled)
            curEpoch - 1;
        uint256 availableToClaim;
        for (
            uint i = civVault.getUserInfo(_pid, _user).startingEpoch;
            i < curEpoch;
            i++
        ) {
            if (civVault.getDepositParams(_pid, _user, i).withdrawInfo > 0) {
                availableToClaim += civVault.getDepositParams(_pid, _user, i).withdrawInfo;
            }
        }
        return availableToClaim;
    }

    /// @notice Get Price of the each pool's guarantee token amount based on deposit token amount
    /// @dev Public Function
    /// @param _pid Pool Id
    /// @param amountIn deposit token amount
    /// @return amountOut Price of the token1 in a given pool
    function getPrice(
        uint256 _pid,
        uint256 amountIn
    ) public view virtual returns (uint amountOut) {
        PoolInfo memory poolInfo = civVault.getPoolInfo(_pid);
        PairInfo[] memory curPairInfo = pairInfo[_pid];
        if (curPairInfo.length == 1) {
            if (address(poolInfo.lpToken) == curPairInfo[0].token0)
                amountOut = curPairInfo[0]
                    .price0Average
                    .mul(amountIn)
                    .decode144();
            else
                amountOut = curPairInfo[0]
                    .price1Average
                    .mul(amountIn)
                    .decode144();
        } else {
            FixedPoint.uq112x112 memory value;
            if (address(poolInfo.guaranteeToken) == curPairInfo[0].token0) {
                value = curPairInfo[0].price1Average;
            } else {
                value = curPairInfo[0].price0Average;
            }
            if (address(poolInfo.lpToken) == curPairInfo[1].token0) {
                value = value.muluq(curPairInfo[1].price1Average.reciprocal());
            } else {
                value = value.muluq(curPairInfo[1].price0Average.reciprocal());
            }
            amountOut = value.mul(amountIn).decode144();
        }
    }

    /// @notice Get Price of the each pool's deposit token amount based on guarantee token amount
    /// @dev Public Function
    /// @param _pid Pool Id
    /// @param amountIn guarantee token amount
    /// @return amountOut Price of the token0 in a given pool
    function getReversePrice(
        uint256 _pid,
        uint256 amountIn
    ) public view virtual returns (uint amountOut) {
        PoolInfo memory poolInfo = civVault.getPoolInfo(_pid);
        PairInfo[] memory curPairInfo = pairInfo[_pid];
        if (curPairInfo.length == 1) {
            if (address(poolInfo.guaranteeToken) == curPairInfo[0].token0)
                amountOut = curPairInfo[0]
                    .price0Average
                    .mul(amountIn)
                    .decode144();
            else
                amountOut = curPairInfo[0]
                    .price1Average
                    .mul(amountIn)
                    .decode144();
        } else {
            FixedPoint.uq112x112 memory value;
            if (address(poolInfo.lpToken) == curPairInfo[0].token0) {
                value = curPairInfo[0].price1Average;
            } else {
                value = curPairInfo[0].price0Average;
            }
            if (address(poolInfo.guaranteeToken) == curPairInfo[1].token0) {
                value = value.muluq(curPairInfo[1].price1Average.reciprocal());
            } else {
                value = value.muluq(curPairInfo[1].price0Average.reciprocal());
            }
            amountOut = value.mul(amountIn).decode144();
        }
    }
}

contract CIVVault is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeERC20 for ICivFundRT;
    using FixedPoint for *;

    /// @notice Guarantee Fee Amount
    uint256 public guarantee_fee = 1000; //10% of $ value equivalent, expressed in bps
    /// @notice Fee Base Amount(Fee calculated like this guarantee_fee / feeBase)
    uint256 public constant feeBase = 10000;
    /// @notice Safety Factor to avoid out of Gas in loops
    uint256 private gasBuffer = 100000;

    /// @notice vault getter contract
    ICivVaultGetter public vaultGetter;
    /// @notice structure with info on each pool
    PoolInfo[] private poolInfo;
    /// @notice structure with info on each pool
    VaultInfo[] private vaultInfo;
    /// @notice structure with each epoch info
    mapping(uint256 => EpochInfo[]) private epochInfo;
    /// @notice Info of each user that enters the fund
    mapping(uint256 => mapping(address => UserInfo)) private userInfo;
    /// @notice Info if represent token is already added to the pool
    mapping(address => bool) private fundRepresentTokenAdded;
    /// @notice Each Pools deposit informations
    mapping(uint256 => mapping(address => mapping(uint256 => DepositParams))) private depositParams;

    ////////////////// EVENTS //////////////////

    /// @notice Event emitted when user deposit fund to our vault or vault deposit fund to strategy
    event Deposit(
        address indexed user,
        address receiver,
        uint256 indexed pid,
        uint256 amount
    );
    /// @notice Event emitted when user request withdraw fund from our vault or vault withdraw fund to user
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    /// @notice Event emitted when owner sets new fee
    event SetFee(uint256 pid, uint256 oldFee, uint256 newFee);
    /// @notice Event emitted when owner sets new guarantee fee
    event SetGuaranteeFee(uint256 oldFee, uint256 newFee);
    /// @notice Event emitted when owner sets new fee duration
    event SetFeeDuration(uint256 pid, uint256 oldDuration, uint256 newDuration);
    /// @notice Event emitted when owner sets new deposit duration
    event SetEpochDuration(
        uint256 pid,
        uint256 oldDuration,
        uint256 newDuration
    );
    /// @notice Event emitted when owner sets new guarantee token lock time
    event SetPoolLockTime(
        uint256 pid,
        uint256 oldLocktime,
        uint256 newLockTime
    );
    /// @notice Event emitted when owner sets new treasury addresses
    event SetWithdrawAddress(
        uint256 pid,
        address[] oldAddress,
        address[] newAddress
    );
    /// @notice Event emitted when owner sets new invest address
    event SetInvestAddress(
        uint256 pid,
        address oldAddress,
        address newAddress
    );
    /// @notice Event emitted when send fee to our treasury
    event SendFeeWithOwner(
        uint256 pid,
        address treasuryAddress,
        uint256 feeAmount
    );
    /// @notice Event emitted when owner update new VPS
    event UpdateVPS(uint256 pid, uint256 lastEpoch, uint256 VPS);
    /// @notice Event emitted when owner paused deposit
    event SetPaused(uint256 pid, bool paused);
    /// @notice Event emitted when owner set new Max & Min Deposit Amount
    event SetLimits(
        uint256 pid,
        uint256 oldMaxAmount,
        uint256 newMaxAmount,
        uint256 oldMinAmount,
        uint256 newMinAmount
    );
    /// @notice Event emitted when owner set new Max User Count for Deposit/Withdraw
    event SetMaxUsers(uint256 _pid, uint256 oldMaxUsers, uint256 newMaxUsers);
    /// @notice Event emitted when user cancel pending deposit from vault
    event CancelDeposit(address user, uint256 pid, uint256 amount);
    /// @notice Event emitted when user cancel withdraw request from vault
    event CancelWithdraw(address user, uint256 pid, uint256 amount);
    /// @notice Event emitted when Uniswap Token Price Updated
    event Update(uint256 _pid, uint256 index);
    /// @notice Event emitted when user claim guarantee token
    event ClaimGuarantee(uint256 pid, address user, uint256 rewardAmount);
    /// @notice Event emitted when user claim LP token for each epoch
    event ClaimWithdrawedToken(
        uint256 pid,
        address user,
        uint256 epoch,
        uint256 lpAmount
    );
    /// @notice Event emitted when user claim LP token
    event WithdrawedToken(uint256 pid, address user, uint256 lpAmount);
    /// @notice Event emitted when owner adds new pool
    event AddPool(
        uint256 indexed pid,
        uint256 indexed fee,
        uint256 maxDeposit,
        uint256 minDeposit,
        bool paused,
        address[] withdrawAddress,
        address lpToken,
        address guaranteeToken,
        uint256 lockPeriod,
        uint256 feeDuration
    );

    ////////////////// ERROR CODES //////////////////
    /*
    ERR_1 = "Pool does not exist";
    ERR_2 = "Deposit paused";
    ERR_3 = "Treasury Address Length must be 2";
    ERR_4 = "Fund Represent Token address cannot be null address";
    ERR_5 = "Guarantee Token address cannot be null address";
    ERR_6 = "First Treasury address cannot be null address";
    ERR_7 = "Second Treasury address cannot be null address";
    ERR_8 = "Represent token already added";
    ERR_9 = "Pool already initialized";
    ERR_10 = "No epochs exist";
    ERR_11 = "Pool is not initialized";
    ERR_12 = "Insufficient contract balance";
    ERR_13 = "Not enough amount to withdraw";
    ERR_14 = "Strategy address cannot be null address";
    ERR_15 = "Enable withdraw for previous epoch";
    ERR_16 = "Distribute all shares for previous epoch";
    ERR_17 = "Epoch does not exist";
    ERR_18 = "Epoch not yet expired";
    ERR_19 = "Nothing to withdraw";
    ERR_20 = "Amount can't be 0";
    ERR_21 = "Insufficient User balance";
    ERR_22 = "No more users are allowed";
    ERR_23 = "Deposit amount exceeds epoch limit";
    ERR_24 = "Epoch expired";
    ERR_25 = "Current balance not enough";
    ERR_26 = "Not enough total withdrawals";
    ERR_27 = "VPS not yet updated";
    ERR_28 = "Already started distribution";
    ERR_29 = "Not yet distributed";
    ERR_30 = "Already distributed";
    ERR_31 = "Fee duration not yet passed";
    ERR_32 = "Smartcontract doesn't hold enough tokens";
    ERR_33 = "Transfer Failed";
    ERR_34 = "Withdraw Token cannot be deposit token";
    */


    ////////////////// MODIFIER //////////////////

    modifier whenDepositNotPaused(uint256 _pid) {
        require(vaultInfo.length > _pid, "ERR_1");
        require(vaultInfo[_pid].paused == false, "ERR_2");
        _;
    }

    modifier checkPoolExistence(uint256 _pid) {
        require(poolInfo.length > _pid, "ERR_1");
        _;
    }

    ////////////////// CONSTRUCTOR //////////////////

    constructor() {
        CivVaultGetter getterContract = new CivVaultGetter(address(this));
        vaultGetter = ICivVaultGetter(address(getterContract));
    }

    ////////////////// INITIALIZATION //////////////////

    /// @notice Add new pool to our vault
    /// @dev Only Owner can call this function
    /// @param addPoolParam Parameters for new pool
    function addPool(
        AddPoolParam memory addPoolParam
    ) external virtual onlyOwner {
        require(
            addPoolParam._withdrawAddresses.length == 2,
            "ERR_3"
        );
        require(
            address(addPoolParam._fundRepresentToken) != address(0),
            "ERR_4"
        );
        require(
            address(addPoolParam._guaranteeToken) != address(0),
            "ERR_5"
        );
        require(
            addPoolParam._withdrawAddresses[0] != address(0),
            "ERR_6"
        );
        require(
            addPoolParam._withdrawAddresses[1] != address(0),
            "ERR_7"
        );
        require(
            !fundRepresentTokenAdded[address(addPoolParam._fundRepresentToken)],
            "ERR_8"
        );
        poolInfo.push(
            PoolInfo({
                lpToken: addPoolParam._lpToken, // Rewardable contract: token for staking, LP for Funding, or NFT for NFT staking
                fundRepresentToken: addPoolParam._fundRepresentToken,
                guaranteeToken: addPoolParam._guaranteeToken,
                fee: addPoolParam._fee,
                withdrawAddress: addPoolParam._withdrawAddresses,
                investAddress: addPoolParam._investAddress,
                initialized: false
            })
        );
        vaultInfo.push(
            VaultInfo({
                maxDeposit: addPoolParam._maxDeposit,
                maxUsers: addPoolParam._maxUsers,
                minDeposit: addPoolParam._minAmount,
                paused: addPoolParam._paused,
                epochDuration: addPoolParam._epochDuration,
                lockPeriod: addPoolParam._lockPeriod,
                feeDuration: addPoolParam._feeDuration,
                lastFeeDistribution: 0,
                lastProcessedEpoch: 0,
                watermark: 0,
                currentUsers: 0
            })
        );

        uint256 pid = poolInfo.length - 1;
        vaultGetter.addUniPair(
            pid,
            address(addPoolParam._lpToken),
            address(addPoolParam._guaranteeToken)
        );
        fundRepresentTokenAdded[
            address(addPoolParam._fundRepresentToken)
        ] = true;
        emit AddPool(
            pid,
            addPoolParam._fee,
            addPoolParam._maxDeposit,
            addPoolParam._minAmount,
            addPoolParam._paused,
            addPoolParam._withdrawAddresses,
            address(addPoolParam._lpToken),
            address(addPoolParam._guaranteeToken),
            addPoolParam._lockPeriod,
            addPoolParam._feeDuration
        );
    }

    /// @notice Delayied pool start
    /// @dev Only Owner can call this function
    /// @param _pid pool id
    function initializePool(
        uint256 _pid
    ) external onlyOwner checkPoolExistence(_pid) {
        require(!poolInfo[_pid].initialized, "ERR_9");

        poolInfo[_pid].initialized = true;

        epochInfo[_pid].push(
            EpochInfo({
                depositors: new address[](0),
                totDeposits: 0,
                totWithdrawals: 0,
                VPS: 0,
                newShares: 0,
                currentWithdraw: 0,
                epochStartTime: block.timestamp,
                lastDepositorProcessed: 0,
                withdrawalsEnabled: false
            })
        );
    }

    ////////////////// SETTER //////////////////

    /// @notice Sets new fee
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newFee New Fee Percent
    function setFee(
        uint256 _pid,
        uint256 _newFee
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetFee(_pid, poolInfo[_pid].fee, _newFee);
        poolInfo[_pid].fee = _newFee;
    }

    /// @notice Sets new collecting fee duration
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newDuration New Collecting Fee Duration
    function setFeeDuration(
        uint256 _pid,
        uint256 _newDuration
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetFeeDuration(_pid, vaultInfo[_pid].feeDuration, _newDuration);
        vaultInfo[_pid].feeDuration = _newDuration;
    }

    /// @notice Sets new Pool guarantee token lock time
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _lockTime New Guarantee token lock time
    function setPoolLockTime(
        uint256 _pid,
        uint256 _lockTime
    ) external onlyOwner checkPoolExistence(_pid) {
        uint256 previousLockTime = vaultInfo[_pid].lockPeriod;
        emit SetPoolLockTime(_pid, previousLockTime, _lockTime);
        vaultInfo[_pid].lockPeriod = _lockTime;
    }

    /// @notice Sets new deposit fund from vault to strategy duration
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newDuration New Duration for Deposit fund from vault to strategy
    function setEpochDuration(
        uint256 _pid,
        uint256 _newDuration
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetEpochDuration(
            _pid,
            vaultInfo[_pid].epochDuration,
            _newDuration
        );
        vaultInfo[_pid].epochDuration = _newDuration;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newAddress Address list to keep fee
    function setWithdrawAddress(
        uint256 _pid,
        address[] memory _newAddress
    ) external onlyOwner checkPoolExistence(_pid) {
        require(_newAddress.length == 2, "ERR_3");
        require(
            _newAddress[0] != address(0),
            "ERR_6"
        );
        require(
            _newAddress[1] != address(0),
            "ERR_7"
        );
        emit SetWithdrawAddress(
            _pid,
            poolInfo[_pid].withdrawAddress,
            _newAddress
        );
        poolInfo[_pid].withdrawAddress = _newAddress;
    }

    /// @notice Sets new treasury addresses to keep fee
    /// @dev Only Owner can call this function
    /// @param _pid Pool Id
    /// @param _newAddress Address list to keep fee
    function setInvestAddress(
        uint256 _pid,
        address _newAddress
    ) external onlyOwner checkPoolExistence(_pid) {
        require(_newAddress != address(0), "ERR_14");
        emit SetInvestAddress(
            _pid,
            poolInfo[_pid].investAddress,
            _newAddress
        );
        poolInfo[_pid].investAddress = _newAddress;
    }

    /// @notice Set Pause of Unpause for deposit to vault
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _paused paused or unpaused for deposit
    function setPaused(
        uint256 _pid,
        bool _paused
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetPaused(_pid, _paused);
        vaultInfo[_pid].paused = _paused;
    }

    /// @notice Set Max e Min Deposit Amount in the vault on a given pool
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _newMaxDeposit New Max Deposit Amount
    /// @param _newMinDeposit New Min Deposit Amount
    function setEpochLimits(
        uint256 _pid,
        uint256 _newMaxDeposit,
        uint256 _newMinDeposit
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetLimits(_pid, vaultInfo[_pid].maxDeposit, _newMaxDeposit, vaultInfo[_pid].minDeposit, _newMinDeposit);
        vaultInfo[_pid].maxDeposit = _newMaxDeposit;
        vaultInfo[_pid].minDeposit = _newMinDeposit;
    }

    /// @notice Set Max Deposit/Withdraw User Count in the vault on a given pool
    /// @dev Only Owner can change this status
    /// @param _pid Pool Id
    /// @param _newMaxUsers New Max User Count
    function setMaxUsers(
        uint256 _pid,
        uint256 _newMaxUsers
    ) external onlyOwner checkPoolExistence(_pid) {
        emit SetMaxUsers(_pid, vaultInfo[_pid].maxUsers, _newMaxUsers);
        vaultInfo[_pid].maxUsers = _newMaxUsers;
    }

    /// @notice Sets new guarantee fee
    /// @dev Only Owner can call this function
    /// @param _newFee new guarantee fee amount
    function setGuaranteeFee(uint256 _newFee) external onlyOwner {
        emit SetGuaranteeFee(guarantee_fee, _newFee);
        guarantee_fee = _newFee;
    }

    ////////////////// GETTER //////////////////

    /**
     * @dev Fetches the pool information for a given pool ID.
     * @param _pid The ID of the pool to fetch the information for.
     * @return pool The PoolInfo struct associated with the provided _pid.
     */
    function getPoolInfo(
        uint256 _pid
    ) external view checkPoolExistence(_pid) returns (PoolInfo memory pool) {
        pool = poolInfo[_pid];
    }

    /**
     * @dev Fetches the length of the pool array.
     * @return The length of poolInfo array.
     */
    function getPoolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @dev Fetches the vault information for a given pool ID.
     * @param _pid The ID of the pool to fetch the information for.
     * @return vault The VaultInfo struct associated with the provided _pid.
     */
    function getVaultInfo(
        uint256 _pid
    ) external view checkPoolExistence(_pid) returns (VaultInfo memory vault) {
        vault = vaultInfo[_pid];
    }

    /**
     * @dev Fetches the epoch information for a given pool ID.
     * @param _pid The ID of the pool to fetch the information for.
     * @param _index The index of the epoch to fetch the information for.
     * @return epoch The EpochInfo struct associated with the provided _pid and _index.
     */
    function getEpochInfo(
        uint256 _pid,
        uint256 _index
    ) external view checkPoolExistence(_pid) returns (EpochInfo memory epoch) {
        epoch = epochInfo[_pid][_index];
    }

    /**
     * @dev Fetches the current epoch number for a given pool ID.
     * The current epoch is determined as the last index of the epochInfo array for the pool.
     * @param _pid The ID of the pool to fetch the current epoch for.
     * @return The current epoch number for the given pool ID.
     */
    function getCurrentEpoch(
        uint256 _pid
    ) external view checkPoolExistence(_pid) returns (uint256) {
        require(epochInfo[_pid].length > 0, "ERR_10");
        return epochInfo[_pid].length - 1;
    }

    /**
     * @dev Fetches the user information for a given pool ID.
     * @param _pid The ID of the pool to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @return user The UserInfo struct associated with the provided _pid and _user.
     */
    function getUserInfo(
        uint256 _pid,
        address _user
    ) external view checkPoolExistence(_pid) returns (UserInfo memory user) {
        user = userInfo[_pid][_user];
    }

    /**
     * @dev Fetches the deposit parameters for a given pool ID.
     * @param _pid The ID of the pool to fetch the information for.
     * @param _user The address of the user to fetch the information for.
     * @param _index The index of the deposit to fetch the information for.
     * @return depositStruct The DepositParams struct associated with the provided _pid, _user and _index.
     */
    function getDepositParams(
        uint256 _pid,
        address _user,
        uint256 _index
    )
        external
        view
        checkPoolExistence(_pid)
        returns (DepositParams memory depositStruct)
    {
        depositStruct = depositParams[_pid][_user][_index];
    }

    ////////////////// UPDATE //////////////////

    function updateEpoch(
        uint256 _pid
    ) internal checkPoolExistence(_pid) returns (uint256) {
        require(poolInfo[_pid].initialized, "ERR_11");
        uint256 currentEpoch = epochInfo[_pid].length - 1;
        if (
            block.timestamp >=
            epochInfo[_pid][currentEpoch].epochStartTime +
                vaultInfo[_pid].epochDuration
        ) {
            epochInfo[_pid].push(
                EpochInfo({
                    depositors: new address[](0),
                    totDeposits: 0,
                    totWithdrawals: 0,
                    VPS: 0,
                    newShares: 0,
                    currentWithdraw: 0,
                    epochStartTime: block.timestamp,
                    lastDepositorProcessed: 0,
                    withdrawalsEnabled: false
                })
            );
        }

        return epochInfo[_pid].length - 1;
    }

    function processFund(uint256 _pid, uint256 _newVPS) private {
        // _newVPS is a value per share

        EpochInfo storage epoch = epochInfo[_pid][
            vaultInfo[_pid].lastProcessedEpoch
        ];
        PoolInfo memory pool = poolInfo[_pid];
        uint256 totalSupply = pool.fundRepresentToken.totalSupply();

        if (totalSupply > 0 || totalSupply > epoch.totWithdrawals) {
            uint256 currentWithdraw = _newVPS * epoch.totWithdrawals;
            uint256 newShares = epoch.totDeposits / _newVPS;

            epoch.newShares = newShares;
            epoch.currentWithdraw = currentWithdraw;

            if (newShares > epoch.totWithdrawals) {
                uint256 sharesToMint = newShares - epoch.totWithdrawals;
                pool.fundRepresentToken.mint(address(this), sharesToMint);
            } else {
                uint256 offSetShares = epoch.totWithdrawals - newShares;
                if (offSetShares > 0)
                    pool.fundRepresentToken.burn(offSetShares);
            }

            if (epoch.totDeposits >= currentWithdraw) {
                uint256 netDeposits = epoch.totDeposits - currentWithdraw;

                if (netDeposits > 0) {
                    require(
                        pool.lpToken.balanceOf(address(this)) >= netDeposits,
                        "ERR_12"
                    );
                    pool.lpToken.safeTransfer(pool.investAddress, netDeposits);
                    emit Deposit(
                        address(this),
                        pool.investAddress,
                        _pid,
                        netDeposits
                    );
                }
            } else {
                uint256 offSet = currentWithdraw - epoch.totDeposits;
                require(
                    pool.lpToken.balanceOf(pool.investAddress) >= offSet,
                    "ERR_13"
                );
                pool.lpToken.safeTransferFrom(
                    pool.investAddress,
                    address(this),
                    offSet
                );
            }
        } else {
            require(
                pool.lpToken.balanceOf(address(this)) >= epoch.totDeposits,
                "ERR_12"
            );
            pool.lpToken.safeTransfer(pool.investAddress, epoch.totDeposits);
            uint256 decimals = IERC20Extended(address(pool.fundRepresentToken))
                .decimals();
            epoch.newShares = decimals;
            pool.fundRepresentToken.mint(address(this), decimals);
        }
    }

    /// @notice Sets new NVPSAV of the pool.
    /**
     * @dev Only Owner can call this function.
     *      Owner must transfer fund to our vault before calling this function
     */
    /// @param _pid Pool Id
    /// @param _newVPS New VPS value
    function rebalancing(
        uint256 _pid,
        uint256 _newVPS
    ) external onlyOwner checkPoolExistence(_pid) {
        require(
            poolInfo[_pid].investAddress != address(0),
            "ERR_14"
        );

        VaultInfo storage vault = vaultInfo[_pid];
        if (vault.lastProcessedEpoch == 0) {
            EpochInfo storage initEpoch = epochInfo[_pid][0];
            if (initEpoch.VPS > 0) {
                require(
                    initEpoch.withdrawalsEnabled == true,
                    "ERR_15"
                );
                require(
                    initEpoch.lastDepositorProcessed ==
                        initEpoch.depositors.length - 1,
                    "ERR_16"
                );
                require(epochInfo[_pid].length > 1, "ERR_17");
                vault.lastProcessedEpoch++;
                EpochInfo storage newEpoch = epochInfo[_pid][1];
                require(
                    block.timestamp >=
                        newEpoch.epochStartTime + vault.epochDuration,
                    "ERR_18"
                );
                newEpoch.VPS = _newVPS;
            } else {
                require(
                    block.timestamp >=
                        initEpoch.epochStartTime + vault.epochDuration,
                    "ERR_18"
                );
                initEpoch.VPS = _newVPS;
            }
        } else {
            require(
                epochInfo[_pid][vault.lastProcessedEpoch].withdrawalsEnabled,
                "ERR_15"
            );
            require(
                epochInfo[_pid][vault.lastProcessedEpoch]
                    .lastDepositorProcessed ==
                    epochInfo[_pid][vault.lastProcessedEpoch]
                        .depositors
                        .length -
                        1,
                "ERR_16"
            );
            vault.lastProcessedEpoch++;
            require(
                epochInfo[_pid].length > vault.lastProcessedEpoch,
                "ERR_17"
            );
            EpochInfo storage subsequentEpoch = epochInfo[_pid][
                vault.lastProcessedEpoch
            ];
            require(
                block.timestamp >=
                    subsequentEpoch.epochStartTime + vault.epochDuration,
                "ERR_18"
            );
            subsequentEpoch.VPS = _newVPS;
        }

        processFund(_pid, _newVPS);

        EpochInfo storage epoch = epochInfo[_pid][vault.lastProcessedEpoch];
        epoch.withdrawalsEnabled = true;
        emit UpdateVPS(_pid, vault.lastProcessedEpoch, _newVPS);
    }

    ////////////////// MAIN //////////////////

    /// @notice Claim withdrawed token epochs
    /// @param _pid Pool Id
    function claimGuaranteeToken(
        uint256 _pid
    ) external checkPoolExistence(_pid) {
        VaultInfo memory vault = vaultInfo[_pid];
        PoolInfo memory pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        require(epochInfo[_pid].length > 0, "ERR_10");
        uint256 endEpoch = epochInfo[_pid].length - 1;
        uint256 _startingEpochFinal = user.startingEpochGuarantee;
        uint256 actualReward;
        for (uint256 i = user.startingEpochGuarantee; i < endEpoch; i++) {
            if (
                block.timestamp <
                epochInfo[_pid][i].epochStartTime + vault.lockPeriod
            ) {
                break;
            }
            actualReward += depositParams[_pid][_msgSender()][i]
                .guaranteeDepositQuantity;
            _startingEpochFinal = i + 1;
        }
        require(actualReward > 0, "ERR_19");
        user.startingEpochGuarantee = _startingEpochFinal;
        pool.guaranteeToken.safeTransfer(_msgSender(), actualReward);
        emit ClaimGuarantee(_pid, _msgSender(), actualReward);
    }

    /// @notice Users Deposit tokens to our vault
    /**
     * @dev Anyone can call this function if pool is not paused.
     *      Users must approve deposit token before calling this function
     *      We mint represent token to users so that we can calculate each users deposit amount outside
     */
    /// @param _pid Pool Id
    /// @param _amount Token Amount to deposit
    function deposit(
        uint256 _pid,
        uint256 _amount
    )
        external
        nonReentrant
        whenDepositNotPaused(_pid)
        checkPoolExistence(_pid)
    {
        VaultInfo storage vault = vaultInfo[_pid];
        require(_amount > vault.minDeposit, "ERR_20");
        require(
            poolInfo[_pid].lpToken.balanceOf(_msgSender()) >= _amount,
            "ERR_21"
        );
        uint256 curEpoch = updateEpoch(_pid);
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][
            curEpoch
        ];
        EpochInfo storage epoch = epochInfo[_pid][curEpoch];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        // transfer guarantee token to the vault
        vaultGetter.updateAll(_pid);
        uint256 guaranteeAmount = (vaultGetter.getPrice(_pid, _amount) *
            guarantee_fee) / feeBase;
        poolInfo[_pid].guaranteeToken.safeTransferFrom(
            _msgSender(),
            address(this),
            guaranteeAmount
        );
        depositParam.guaranteeDepositQuantity += guaranteeAmount;

        if (!user.isActive) {
            require(
                vault.currentUsers + 1 <= vault.maxUsers,
                "ERR_22"
            );
            vault.currentUsers++;
            user.isActive = true;
        }

        require(
            epoch.totDeposits + _amount <= vault.maxDeposit,
            "ERR_23"
        );

        if (!depositParam.hasDeposited) {
            epoch.depositors.push(_msgSender());
            depositParam.hasDeposited = true;
        }
        epoch.totDeposits += _amount;
        poolInfo[_pid].lpToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        depositParam.depositInfo += _amount;
        emit Deposit(_msgSender(), address(this), _pid, _amount);
    }

    /// @notice Immediately withdraw current pending deposit amount
    /// @param _pid Pool Id
    function cancelDeposit(
        uint256 _pid
    ) external nonReentrant checkPoolExistence(_pid) {
        PoolInfo memory pool = poolInfo[_pid];
        VaultInfo storage vault = vaultInfo[_pid];
        require(epochInfo[_pid].length > 0, "ERR_10");
        uint256 curEpoch = epochInfo[_pid].length - 1;
        EpochInfo storage epoch = epochInfo[_pid][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + vault.epochDuration,
            "ERR_24"
        );
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        uint256 amount = depositParam.depositInfo;
        require(amount > 0, "ERR_20");
        depositParam.depositInfo = 0;
        epoch.totDeposits -= amount;
        pool.lpToken.safeTransfer(_msgSender(), amount);
        uint256 guaranteeAmount = depositParam.guaranteeDepositQuantity;
        depositParam.guaranteeDepositQuantity = 0;
        pool.guaranteeToken.safeTransfer(_msgSender(), guaranteeAmount);
        if (pool.fundRepresentToken.balanceOf(_msgSender()) == 0) {
            vault.currentUsers--;
            user.isActive = false;
        }
        emit CancelDeposit(_msgSender(), _pid, amount);
    }

    /// @notice Sends Withdraw Request to vault
    /**
     * @dev Withdraw all users fund from vault
     */
    /// @param _pid Pool Id
    function withdrawAll(
        uint256 _pid
    ) external nonReentrant checkPoolExistence(_pid) {
        uint256 sharesBalance = poolInfo[_pid].fundRepresentToken.balanceOf(
            _msgSender()
        );
        require(sharesBalance > 0, "ERR_20");
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 curEpoch = updateEpoch(_pid);
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][
            curEpoch
        ];
        EpochInfo storage epoch = epochInfo[_pid][curEpoch];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        user.isActive = false;
        vault.currentUsers--;
        epoch.totWithdrawals += sharesBalance;
        depositParam.withdrawInfo += sharesBalance;
        poolInfo[_pid].fundRepresentToken.safeTransferFrom(
            _msgSender(),
            address(this),
            sharesBalance
        );
        emit Withdraw(_msgSender(), _pid, sharesBalance);
    }

    /// @notice Sends Withdraw Request to vault
    /**
     * @dev Withdraw amount user shares from vault
     */
    /// @param _pid Pool Id
    function withdraw(
        uint256 _pid,
        uint256 _amount
    ) external nonReentrant checkPoolExistence(_pid) {
        uint256 sharesBalance = poolInfo[_pid].fundRepresentToken.balanceOf(
            _msgSender()
        );
        require(sharesBalance >= _amount, "ERR_25");
        VaultInfo storage vault = vaultInfo[_pid];
        uint256 curEpoch = updateEpoch(_pid);
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][
            curEpoch
        ];
        EpochInfo storage epoch = epochInfo[_pid][curEpoch];
        UserInfo storage user = userInfo[_pid][_msgSender()];

        if (sharesBalance - _amount == 0) {
            user.isActive = false;
            vault.currentUsers--;
        }
        epoch.totWithdrawals += _amount;
        depositParam.withdrawInfo += _amount;
        poolInfo[_pid].fundRepresentToken.safeTransferFrom(
            _msgSender(),
            address(this),
            _amount
        );
        emit Withdraw(_msgSender(), _pid, _amount);
    }

    /// @notice Immediately withdraw current pending shares amount
    /// @param _pid Pool Id
    function cancelWithdraw(
        uint256 _pid
    ) external nonReentrant checkPoolExistence(_pid) {
        VaultInfo storage vault = vaultInfo[_pid];
        require(epochInfo[_pid].length > 0, "ERR_10");
        uint256 curEpoch = epochInfo[_pid].length - 1;
        EpochInfo storage epoch = epochInfo[_pid][curEpoch];
        require(
            block.timestamp < epoch.epochStartTime + vault.epochDuration,
            "ERR_24"
        );
        DepositParams storage depositParam = depositParams[_pid][_msgSender()][
            curEpoch
        ];
        UserInfo storage user = userInfo[_pid][_msgSender()];
        uint256 amount = depositParam.withdrawInfo;
        require(amount > 0, "ERR_20");
        depositParam.withdrawInfo = 0;
        require(epoch.totWithdrawals >= amount, "ERR_26");
        epoch.totWithdrawals -= amount;
        poolInfo[_pid].fundRepresentToken.safeTransfer(_msgSender(), amount);

        if (!user.isActive) {
            vault.currentUsers++;
            user.isActive = true;
        }

        emit CancelWithdraw(_msgSender(), _pid, amount);
    }

    /// @notice Get withdraw tokens from vault
    /**
     * @dev Withdraw my fund from vault
     */
    /// @param _pid Pool Id
    function claimWithdrawedTokens(
        uint256 _pid
    ) external nonReentrant checkPoolExistence(_pid) {
        UserInfo storage user = userInfo[_pid][_msgSender()];

        uint256 endEpoch = vaultInfo[_pid].lastProcessedEpoch;
        uint256 _startingEpochFinal = user.startingEpoch;
        if (!epochInfo[_pid][endEpoch].withdrawalsEnabled) endEpoch -= 1;
        uint256 availableToClaim;
        for (uint i = user.startingEpoch; i < endEpoch; i++) {
            if (depositParams[_pid][_msgSender()][i].withdrawInfo > 0) {
                uint256 valueWithdraw = epochInfo[_pid][i].currentWithdraw;
                uint256 totWithdrawals = epochInfo[_pid][i].totWithdrawals;
                uint256 userWithdraw = depositParams[_pid][_msgSender()][i]
                    .withdrawInfo;
                uint256 dueWithdraw = (userWithdraw * valueWithdraw) /
                    totWithdrawals;

                availableToClaim += dueWithdraw;
                _startingEpochFinal = i + 1;
                emit ClaimWithdrawedToken(_pid, _msgSender(), i, dueWithdraw);
            }
        }
        require(availableToClaim > 0, "ERR_19");
        user.startingEpoch = _startingEpochFinal;

        poolInfo[_pid].lpToken.safeTransfer(_msgSender(), availableToClaim);
        emit WithdrawedToken(_pid, _msgSender(), availableToClaim);
    }

    /// @notice Deposit vault fund to strategy address
    /**
     * @dev Only Owner can call this function if deposit duration is passed.
     *      Owner must setPaused(false)
     */
    /// @param _pid Pool Id
    function processDeposits(
        uint256 _pid
    ) external nonReentrant onlyOwner checkPoolExistence(_pid) {
        VaultInfo memory vault = vaultInfo[_pid];
        EpochInfo memory epoch = epochInfo[_pid][vault.lastProcessedEpoch];
        require(epoch.VPS > 0, "ERR_27");
        require(epoch.lastDepositorProcessed == 0, "ERR_28");
        uint256 currentDeposit = epoch.totDeposits;
        if (currentDeposit == 0) {
            return;
        }

        distributeShares(_pid);
    }

    /**
     * @dev Continues the process of distributing shares for a specific pool, if possible.
     * This function is only callable by the contract owner.
     * @param _pid The ID of the pool for which to continue distributing shares.
     */
    function continueDistributingShares(
        uint256 _pid
    ) external onlyOwner checkPoolExistence(_pid) {
        // Check if there's anything to distribute
        EpochInfo memory epoch = epochInfo[_pid][
            vaultInfo[_pid].lastProcessedEpoch
        ];
        require(epoch.VPS > 0, "ERR_27");
        require(epoch.lastDepositorProcessed != 0, "ERR_29");
        require(
            epoch.lastDepositorProcessed < epoch.depositors.length,
            "ERR_30"
        );
        distributeShares(_pid);
    }

    /**
     * @dev Distributes the newly minted shares among the depositors of a specific pool.
     * The function processes depositors until it runs out of gas.
     * @param _pid The ID of the pool for which to distribute shares.
     */
    function distributeShares(uint256 _pid) internal {
        EpochInfo storage epoch = epochInfo[_pid][
            vaultInfo[_pid].lastProcessedEpoch
        ];
        uint256 i = epoch.lastDepositorProcessed;
        uint256 sharesToDistribute = epoch.newShares;

        while (i < epoch.depositors.length && gasleft() > gasBuffer) {
            address investor = epoch.depositors[i];
            uint256 depositInfo = depositParams[_pid][investor][
                vaultInfo[_pid].lastProcessedEpoch
            ].depositInfo;
            uint256 dueShares = (sharesToDistribute * depositInfo) /
                epoch.totDeposits;

            if (dueShares > 0) {
                // Transfer the shares
                poolInfo[_pid].fundRepresentToken.transfer(investor, dueShares);
            }

            i++;
        }

        epoch.lastDepositorProcessed = i;
    }

    /// @notice Sends fee to the treasury address
    /**
     * @dev Internal function
     */
    /// @param _pid Pool Id
    /// @param _newVPS new Net Asset Value
    function sendFee(
        uint256 _pid,
        uint256 _newVPS
    ) external onlyOwner checkPoolExistence(_pid) {
        VaultInfo storage vault = vaultInfo[_pid];
        PoolInfo memory pool = poolInfo[_pid];
        require(
            block.timestamp >= vault.lastFeeDistribution + vault.feeDuration,
            "ERR_31"
        );
        require(
            pool.lpToken.balanceOf(address(this)) > 0,
            "ERR_32"
        );

        uint256 actualFee;
        if (vault.watermark < _newVPS) {
            actualFee = ((_newVPS - vault.watermark) * pool.fee) / feeBase;
            if (actualFee > 0) {
                vault.watermark = _newVPS;
                vault.lastFeeDistribution = block.timestamp;
            } else {
                revert("ERR_19");
            }
        }

        address addr0 = pool.withdrawAddress[0];
        address addr1 = pool.withdrawAddress[1];
        emit SendFeeWithOwner(_pid, addr0, actualFee / 2);
        emit SendFeeWithOwner(_pid, addr1, actualFee / 2);
        pool.lpToken.safeTransfer(addr0, actualFee / 2);
        pool.lpToken.safeTransfer(addr1, actualFee / 2);
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "ERR_33");
    }

    /// @notice Withdraw ETH to the owner
    /**
     * @dev Only Owner can call this function
     */
    function withdrawETH() external payable onlyOwner {
        safeTransferETH(_msgSender(), address(this).balance);
    }

    /// @notice Withdraw ERC-20 Token to the owner
    /**
     * @dev Only Owner can call this function
     */
    /// @param _tokenContract ERC-20 Token address
    function withdrawERC20(IERC20 _tokenContract) external onlyOwner {
        for (uint256 i = 0; i < poolInfo.length; i++) {
            require(
                poolInfo[i].guaranteeToken != _tokenContract,
                "ERR_34"
            );
            require(
                poolInfo[i].lpToken != _tokenContract,
                "ERR_34"
            );
        }
        _tokenContract.safeTransfer(
            _msgSender(),
            _tokenContract.balanceOf(address(this))
        );
    }

    /**
     * @dev allow the contract to receive ETH
     */
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```solidity
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```solidity
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it. We recommend using {AccessControlDefaultAdminRules}
 * to enforce additional security measures for this role.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(account),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

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
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
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
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
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
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
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
    function _transfer(address from, address to, uint256 amount) internal virtual {
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
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
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
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
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

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
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
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
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
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
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.4.0;

import "./FullMath.sol";

// a library for handling binary fixed point numbers (https://en.wikipedia.org/wiki/Q_(number_format))
library FixedPoint {
    // range: [0, 2**112 - 1]
    // resolution: 1 / 2**112
    struct uq112x112 {
        uint224 _x;
    }

    // range: [0, 2**144 - 1]
    // resolution: 1 / 2**112
    struct uq144x112 {
        uint256 _x;
    }

    uint8 public constant RESOLUTION = 112;
    uint256 public constant Q112 = 0x10000000000000000000000000000; // 2**112
    uint256 private constant Q224 = 0x100000000000000000000000000000000000000000000000000000000; // 2**224
    uint256 private constant LOWER_MASK = 0xffffffffffffffffffffffffffff; // decimal of UQ*x112 (lower 112 bits)

    // encode a uint112 as a UQ112x112
    function encode(uint112 x) internal pure returns (uq112x112 memory) {
        return uq112x112(uint224(x) << RESOLUTION);
    }

    // encodes a uint144 as a UQ144x112
    function encode144(uint144 x) internal pure returns (uq144x112 memory) {
        return uq144x112(uint256(x) << RESOLUTION);
    }

    // decode a UQ112x112 into a uint112 by truncating after the radix point
    function decode(uq112x112 memory self) internal pure returns (uint112) {
        return uint112(self._x >> RESOLUTION);
    }

    // decode a UQ144x112 into a uint144 by truncating after the radix point
    function decode144(uq144x112 memory self) internal pure returns (uint144) {
        return uint144(self._x >> RESOLUTION);
    }

    // multiply a UQ112x112 by a uint, returning a UQ144x112
    // reverts on overflow
    function mul(uq112x112 memory self, uint256 y) internal pure returns (uq144x112 memory) {
        uint256 z = 0;
        require(y == 0 || (z = self._x * y) / y == self._x, 'FixedPoint::mul: overflow');
        return uq144x112(z);
    }

    // multiply a UQ112x112 by an int and decode, returning an int
    // reverts on overflow
    function muli(uq112x112 memory self, int256 y) internal pure returns (int256) {
        uint256 z = FullMath.mulDiv(self._x, uint256(y < 0 ? -y : y), Q112);
        require(z < 2**255, 'FixedPoint::muli: overflow');
        return y < 0 ? -int256(z) : int256(z);
    }

    // multiply a UQ112x112 by a UQ112x112, returning a UQ112x112
    // lossy
    function muluq(uq112x112 memory self, uq112x112 memory other) internal pure returns (uq112x112 memory) {
        if (self._x == 0 || other._x == 0) {
            return uq112x112(0);
        }
        uint112 upper_self = uint112(self._x >> RESOLUTION); // * 2^0
        uint112 lower_self = uint112(self._x & LOWER_MASK); // * 2^-112
        uint112 upper_other = uint112(other._x >> RESOLUTION); // * 2^0
        uint112 lower_other = uint112(other._x & LOWER_MASK); // * 2^-112

        // partial products
        uint224 upper = uint224(upper_self) * upper_other; // * 2^0
        uint224 lower = uint224(lower_self) * lower_other; // * 2^-224
        uint224 uppers_lowero = uint224(upper_self) * lower_other; // * 2^-112
        uint224 uppero_lowers = uint224(upper_other) * lower_self; // * 2^-112

        // so the bit shift does not overflow
        require(upper <= type(uint112).max, 'FixedPoint::muluq: upper overflow');

        // this cannot exceed 256 bits, all values are 224 bits
        uint256 sum = uint256(upper << RESOLUTION) + uppers_lowero + uppero_lowers + (lower >> RESOLUTION);

        // so the cast does not overflow
        require(sum <= type(uint224).max, 'FixedPoint::muluq: sum overflow');

        return uq112x112(uint224(sum));
    }

    // returns a UQ112x112 which represents the ratio of the numerator to the denominator
    // can be lossy
    function fraction(uint256 numerator, uint256 denominator) internal pure returns (uq112x112 memory) {
        require(denominator > 0, 'FixedPoint::fraction: division by zero');
        if (numerator == 0) return FixedPoint.uq112x112(0);

        if (numerator <= type(uint144).max) {
            uint256 result = (numerator << RESOLUTION) / denominator;
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        } else {
            uint256 result = FullMath.mulDiv(numerator, Q112, denominator);
            require(result <= type(uint224).max, 'FixedPoint::fraction: overflow');
            return uq112x112(uint224(result));
        }
    }

    // take the reciprocal of a UQ112x112
    // reverts on overflow
    // lossy
    function reciprocal(uq112x112 memory self) internal pure returns (uq112x112 memory) {
        require(self._x != 0, 'FixedPoint::reciprocal: reciprocal of zero');
        require(self._x != 1, 'FixedPoint::reciprocal: overflow');
        return uq112x112(uint224(Q224 / self._x));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.0;

/// @title Contains 512-bit math functions
/// @notice Facilitates multiplication and division that can have overflow of an intermediate value without any loss of precision
/// @dev Handles "phantom overflow" i.e., allows multiplication and division where an intermediate value overflows 256 bits
library FullMath {
    /// @notice Calculates floor(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    /// @dev Credit to Remco Bloemen under MIT license https://xn--2-umb.com/21/muldiv
    function mulDiv(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        // 512-bit multiply [prod1 prod0] = a * b
        // Compute the product mod 2**256 and mod 2**256 - 1
        // then use the Chinese Remainder Theorem to reconstruct
        // the 512 bit result. The result is stored in two 256
        // variables such that product = prod1 * 2**256 + prod0
        uint256 prod0; // Least significant 256 bits of the product
        uint256 prod1; // Most significant 256 bits of the product
        assembly {
            let mm := mulmod(a, b, not(0))
            prod0 := mul(a, b)
            prod1 := sub(sub(mm, prod0), lt(mm, prod0))
        }

        // Handle non-overflow cases, 256 by 256 division
        if (prod1 == 0) {
            require(denominator > 0);
            assembly {
                result := div(prod0, denominator)
            }
            return result;
        }

        // Make sure the result is less than 2**256.
        // Also prevents denominator == 0
        require(denominator > prod1);

        ///////////////////////////////////////////////
        // 512 by 256 division.
        ///////////////////////////////////////////////

        // Make division exact by subtracting the remainder from [prod1 prod0]
        // Compute remainder using mulmod
        uint256 remainder;
        assembly {
            remainder := mulmod(a, b, denominator)
        }
        // Subtract 256 bit number from 512 bit number
        assembly {
            prod1 := sub(prod1, gt(remainder, prod0))
            prod0 := sub(prod0, remainder)
        }

        // Factor powers of two out of denominator
        // Compute largest power of two divisor of denominator.
        // Always >= 1.
        //uint256 twos = -denominator & denominator;
        uint256 twos = denominator & (~denominator + 1);
        // Divide denominator by power of two
        assembly {
            denominator := div(denominator, twos)
        }

        // Divide [prod1 prod0] by the factors of two
        assembly {
            prod0 := div(prod0, twos)
        }
        // Shift in bits from prod1 into prod0. For this we need
        // to flip `twos` such that it is 2**256 / twos.
        // If twos is zero, then it becomes one
        assembly {
            twos := add(div(sub(0, twos), twos), 1)
        }
        prod0 |= prod1 * twos;

        // Invert denominator mod 2**256
        // Now that denominator is an odd number, it has an inverse
        // modulo 2**256 such that denominator * inv = 1 mod 2**256.
        // Compute the inverse by starting with a seed that is correct
        // correct for four bits. That is, denominator * inv = 1 mod 2**4
        uint256 inv = (3 * denominator) ^ 2;
        // Now use Newton-Raphson iteration to improve the precision.
        // Thanks to Hensel's lifting lemma, this also works in modular
        // arithmetic, doubling the correct bits in each step.
        inv *= 2 - denominator * inv; // inverse mod 2**8
        inv *= 2 - denominator * inv; // inverse mod 2**16
        inv *= 2 - denominator * inv; // inverse mod 2**32
        inv *= 2 - denominator * inv; // inverse mod 2**64
        inv *= 2 - denominator * inv; // inverse mod 2**128
        inv *= 2 - denominator * inv; // inverse mod 2**256

        // Because the division is now exact we can divide by multiplying
        // with the modular inverse of denominator. This will give us the
        // correct result modulo 2**256. Since the precoditions guarantee
        // that the outcome is less than 2**256, this is the final result.
        // We don't need to compute the high bits of the result and prod1
        // is no longer required.
        result = prod0 * inv;
        return result;
    }

    /// @notice Calculates ceil(a×b÷denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
    /// @param a The multiplicand
    /// @param b The multiplier
    /// @param denominator The divisor
    /// @return result The 256-bit result
    function mulDivRoundingUp(
        uint256 a,
        uint256 b,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        result = mulDiv(a, b, denominator);
        if (mulmod(a, b, denominator) > 0) {
            require(result < type(uint256).max);
            result++;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

struct PoolInfo {
    // Info on each pool
    IERC20 lpToken; // Address of asset token (Staking Token) e.g. USDT
    ICivFundRT fundRepresentToken; // Fund Represent tokens for deposit in the strategy
    IERC20 guaranteeToken; // Guarantee Token address e.g. xStone
    uint256 fee; // Pool Fee Amount
    address[] withdrawAddress; // Pool Withdraw Address
    address investAddress; // Pool Invest Address
    bool initialized; // Is pool initialized?
}

struct VaultInfo {
    // Info on each pool
    // We Split Pool Struct into 2 struct cause of solidity deep
    uint256 maxDeposit; // Pool Max Deposit Amount
    uint256 maxUsers; // Pool Max User Count
    uint256 minDeposit; // Pool Min Deposit Amount
    bool paused; // Flag that deposit is paused or not
    uint256 epochDuration; // Timestamp of an Epoch
    uint256 lockPeriod; // Pool Guarantee Token Lock Period
    uint256 feeDuration; // Fee withdraw period
    uint256 lastFeeDistribution; // Last timestamp of distribution
    uint256 lastProcessedEpoch; // Last Epoch Processed
    uint256 watermark; // Fee watermark
    uint256 currentUsers; // Pool current users
}

struct EpochInfo {
    address[] depositors;
    uint256 totDeposits;
    uint256 totWithdrawals;
    uint256 VPS;
    uint256 newShares;
    uint256 currentWithdraw;
    uint256 epochStartTime;
    uint256 lastDepositorProcessed;
    bool withdrawalsEnabled;
}

/// we define a withdrawable counter balance for the user at each iteration so then user can claim. Once claimed the balance is reduced.
struct UserInfo {
    uint256 startingEpoch;
    bool isActive;
    uint256 startingEpochGuarantee; // Starting Epoch of guarantee lock time
}

struct DepositParams {
    uint256 depositInfo;
    uint256 withdrawInfo;
    uint256 guaranteeDepositQuantity;
    bool hasDeposited;
}

struct AddPoolParam {
    IERC20 _lpToken;
    ICivFundRT _fundRepresentToken;
    IERC20 _guaranteeToken;
    uint256 _maxDeposit;
    uint256 _maxUsers;
    uint256 _minAmount;
    address _investAddress;
    address[] _withdrawAddresses; // Withdraw Address ?? Why for each pool?
    uint256 _fee;
    //uint256 _feeDuration; // Why ?? it should be withdrawn at the same time as depositToVault
    uint256 _epochDuration;
    uint256 _lockPeriod;
    uint256 _feeDuration;
    bool _paused;
}

struct PairInfo {
    IUniswapV2Pair pair; //Uniswap Pair Address
    uint256 price0CumulativeLast;
    uint256 price1CumulativeLast;
    FixedPoint.uq112x112 price0Average; // First token average price
    FixedPoint.uq112x112 price1Average; // Second token average price
    uint32 blockTimestampLast; //Last time we calculate price
    address token0; // First token address
    address token1; // Second token address
}

interface ICivVault {
    function guarantee_fee() external view returns (uint256);
    function feeBase() external view returns (uint256);
    function getPoolInfo(uint256 _pid) external view returns (PoolInfo memory);
    function getPoolLength() external view returns (uint256);
    function getVaultInfo(uint256 _pid) external view returns (VaultInfo memory);
    function getEpochInfo(uint256 _pid, uint256 _index) external view returns (EpochInfo memory);
    function getCurrentEpoch(uint256 _pid) external view returns (uint256);
    function getUserInfo(uint256 _pid, address _user) external view returns (UserInfo memory);
    function getDepositParams(uint256 _pid, address _user, uint256 _index) external view returns (DepositParams memory);
}

interface ICivFundRT is IERC20, IAccessControl {
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
    function burnFrom(address account, uint256 amount) external;
}

interface ICivVaultGetter {
    function addUniPair(uint, address, address) external;
    function getPrice(uint, uint) external view returns (uint);
    function getReversePrice(uint, uint) external view returns (uint);
    function getBalanceOfUser(uint, address) external view returns (uint);
    function updateAll(uint) external;
}

interface IERC20Extended is IERC20 {
    function decimals() external view returns (uint256);
    function symbol() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.5.0;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./FixedPoint.sol";

// library with helper methods for oracles that are concerned with computing average prices
library UniswapV2OracleLibrary {
    using FixedPoint for *;

    // helper function that returns the current block timestamp within the range of uint32, i.e. [0, 2**32 - 1]
    function currentBlockTimestamp() internal view returns (uint32) {
        return uint32(block.timestamp % 2 ** 32);
    }

    // produces the cumulative price using counterfactuals to save gas and avoid a call to sync.
    function currentCumulativePrices(
        address pair
    ) internal view returns (uint price0Cumulative, uint price1Cumulative, uint32 blockTimestamp) {
        blockTimestamp = currentBlockTimestamp();
        price0Cumulative = IUniswapV2Pair(pair).price0CumulativeLast();
        price1Cumulative = IUniswapV2Pair(pair).price1CumulativeLast();

        // if time has elapsed since the last update on the pair, mock the accumulated price values
        (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast) = IUniswapV2Pair(pair).getReserves();
        if (blockTimestampLast != blockTimestamp) {
            // subtraction overflow is desired
            uint32 timeElapsed = blockTimestamp - blockTimestampLast;
            // addition overflow is desired
            // counterfactual
            price0Cumulative += uint(FixedPoint.fraction(reserve1, reserve0)._x) * timeElapsed;
            // counterfactual
            price1Cumulative += uint(FixedPoint.fraction(reserve0, reserve1)._x) * timeElapsed;
        }
    }
}