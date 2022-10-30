// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {Owned} from "solmate/src/auth/Owned.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {YoSifuStargateVault} from "./YoSifuStargateVault.sol";
import {Bytes32AddressLib} from "solmate/src/utils/Bytes32AddressLib.sol";

import {IStargatePool} from "./interfaces/IStargatePool.sol";

/// @title Yield Optimized Sifu Factory (Stargate Vault)
contract YoSifuStargateVaultFactory is Owned {
    using Bytes32AddressLib for bytes32;

    /*//////////////////////////////////////////////////////////////
                                ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice address of the Stargate Staking contract
    address public immutable stargateStaking;

    /// @notice address of the Stargate Router contract
    address public immutable stargateRouter;

    /// @notice address of the Stargate Token contract
    ERC20 public immutable STG;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogVaultCreated(
        YoSifuStargateVault indexed vault,
        ERC20 indexed asset,
        ERC20 indexed underlyingAsset
    );

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the Factory parameters, Stargate Staking, Router, Token and the Owner
    /// @param _stargateStaking Address of the Stargate Staking contract
    /// @param _stargateRouter Address of the Stargate Router contract
    /// @param _STG Address of the Stargate Token
    /// @param _owner Address of the Owner of this Factory
    constructor(
        address _stargateStaking,
        address _stargateRouter,
        ERC20 _STG,
        address _owner
    ) Owned(_owner) {
        stargateStaking = _stargateStaking;
        stargateRouter = _stargateRouter;
        STG = _STG;
    }

    /// @notice Deploys a new YoSifuStargate vault for the given asset
    /// @dev The asset should be supported by the stargate. Only owner can deploy new vaults
    /// @param asset The Base Asset which will be used in the vault i.e. Stargate Pool Tokens
    /// @param pid The pid of the asset in the staking contract
    /// @param feeTo Address of the fee receiver for this vault
    /// @param owner Address of the owner of this vault
    function createVault(
        ERC20 asset,
        uint256 pid,
        address feeTo,
        address owner
    ) external onlyOwner returns (YoSifuStargateVault vault) {
        ERC20 underlyingAsset = ERC20(IStargatePool(address(asset)).token());
        uint256 poolId = IStargatePool(address(asset)).poolId();

        vault = new YoSifuStargateVault{salt: bytes32(0)}(
            asset,
            underlyingAsset,
            stargateStaking,
            stargateRouter,
            STG,
            poolId,
            pid,
            feeTo,
            owner
        );

        emit LogVaultCreated(vault, asset, underlyingAsset);
    }

    function computeVaultAddress(
        ERC20 asset,
        uint256 pid,
        address feeTo,
        address owner
    ) external view returns (YoSifuStargateVault vault) {
        ERC20 underlyingAsset = ERC20(IStargatePool(address(asset)).token());
        uint256 poolId = IStargatePool(address(asset)).poolId();

        vault = YoSifuStargateVault(
            _computeCreate2Address(
                keccak256(
                    abi.encodePacked(
                        type(YoSifuStargateVault).creationCode,
                        abi.encode(
                            asset,
                            underlyingAsset,
                            stargateStaking,
                            stargateRouter,
                            STG,
                            poolId,
                            pid,
                            feeTo,
                            owner
                        )
                    )
                )
            )
        );
    }

    function _computeCreate2Address(bytes32 bytecodeHash)
        internal
        view
        virtual
        returns (address)
    {
        return
            keccak256(
                abi.encodePacked(
                    bytes1(0xFF),
                    address(this),
                    bytes32(0),
                    bytecodeHash
                )
            ).fromLast20Bytes();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ERC4626} from "solmate/src/mixins/ERC4626.sol";
import {ERC20} from "solmate/src/tokens/ERC20.sol";
import {Owned} from "solmate/src/auth/Owned.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {SafeTransferLib} from "solmate/src/utils/SafeTransferLib.sol";

import {ILPStaking} from "./interfaces/ILPStaking.sol";
import {IStargateRouter} from "./interfaces/IStargateRouter.sol";
import {IStargatePool} from "./interfaces/IStargatePool.sol";
import {ISwapper} from "./interfaces/ISwapper.sol";

/// @notice Vault to auto-compound rewards from Stargate LP
contract YoSifuStargateVault is ERC4626, Owned {
    using FixedPointMathLib for uint256;
    using SafeTransferLib for ERC20;

    /*//////////////////////////////////////////////////////////////
                        ADDRESSES
    //////////////////////////////////////////////////////////////*/

    /// @notice Address of Stargate Staking Contract
    ILPStaking public immutable stargateStaking;

    /// @notice Address of Stargate Router
    IStargateRouter public immutable stargateRouter;

    /// @notice Reward Token issued by Stargate i.e. STG Token
    ERC20 public immutable rewardToken;

    /// @notice Underlying Asset in the Stargate Pool
    ERC20 public immutable underlyingAsset;

    /// @notice Address of the Fee Receiver
    address public feeTo;

    /*//////////////////////////////////////////////////////////////
                        STARGATE STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Pool Id of the Stargate Pool
    uint256 public immutable poolId;

    /// @notice Pid in the Staking Contract
    uint256 public immutable pid;

    /*//////////////////////////////////////////////////////////////
                        VAULT STATE
    //////////////////////////////////////////////////////////////*/

    /// @notice Total Stargate Pool Asssets held by the vault
    uint256 private totalBaseAssets;

    /// @notice Fee for the Vault FEE_PRECISION - 1e18
    /// @dev 1e17 - 10%, 20e16 - 20%, can't set 100%
    uint256 public fee;

    /// @notice profit locked in between harvest
    uint256 public totalLockedProfit;

    /// @notice last harvest block
    uint256 public lastHarvestBlock;

    /// @notice Executor Address status
    mapping(address => bool) public executors;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event LogFeeClaimed(address feeTo, uint256 feeAmount);
    event LogHarvested(uint256 amount);
    event LogStakedAllAssets(uint256 assets);
    event LogEmergencyWithdraw(uint256 pid, uint256 assets);
    event LogSetExecutorStatus(address executor, bool status);
    event LogSetFeeTo(address owner);
    event LogSetFees(uint256 fee);

    /*//////////////////////////////////////////////////////////////
                                 ERRORS
    //////////////////////////////////////////////////////////////*/

    error YoSifuStargateVault__InsufficientOut();
    error YoSifuStargateVault__NotExecutor();
    error YoSifuStargateVault__InvalidFee();
    error YoSifuStargateVault__HarvestAtSameBlock();

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the vault configurations
    /// @param _asset Address of Stargate Pool Tokens
    /// @param _underlyingAsset Address of underlying tokens of the Stargate Pool
    /// @param _stargateStaking Address of the Stargate Staking contract
    /// @param _stargateRouter Address of the Stargate Router contract
    /// @param _rewardToken Address of the Reward Token
    /// @param _poolId Pool Id of the Stargate Pool Token
    /// @param _pid PID of the asset in Staking Contract
    /// @param _feeTo Address of the Fee Receiver
    /// @param _owner Address of the Onwer of the vault
    constructor(
        ERC20 _asset,
        ERC20 _underlyingAsset,
        address _stargateStaking,
        address _stargateRouter,
        ERC20 _rewardToken,
        uint256 _poolId,
        uint256 _pid,
        address _feeTo,
        address _owner
    )
        ERC4626(
            _asset,
            // ex: Yield Optimized Sifu - S*USDC - Stargate Vault
            string(
                abi.encodePacked(
                    "Yield Optimized Sifu -",
                    _asset.name(),
                    "- Stargate Vault"
                )
            ),
            // ex: yoSifu_Stargate_S*USDC
            string(abi.encodePacked("yoSifu_Stargate_", _asset.symbol()))
        )
        Owned(_owner)
    {
        executors[_owner] = true;
        stargateStaking = ILPStaking(_stargateStaking);
        stargateRouter = IStargateRouter(_stargateRouter);
        rewardToken = _rewardToken;
        pid = _pid;
        feeTo = _feeTo;
        poolId = _poolId;
        underlyingAsset = _underlyingAsset;

        _underlyingAsset.safeApprove(
            address(stargateRouter),
            type(uint256).max
        );
        _asset.safeApprove(address(stargateStaking), type(uint256).max);
    }

    /*//////////////////////////////////////////////////////////////
                    ERC4626 OVERRIDES FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function afterDeposit(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets += assets;
        stargateStaking.deposit(pid, assets);
    }

    function beforeWithdraw(
        uint256 assets,
        uint256 /*shares*/
    ) internal virtual override {
        totalBaseAssets -= assets;
        if (asset.balanceOf(address(this)) < assets) {
            stargateStaking.withdraw(pid, assets);
        }
    }

    // TODO: Add delayed harvest logic
    function totalAssets() public view override returns (uint256) {
        return totalBaseAssets - lockedProfit();
    }

    function lockedProfit() public view returns (uint256) {
        if (block.number <= lastHarvestBlock) {
            return totalLockedProfit;
        }

        return 0;
    }

    /*//////////////////////////////////////////////////////////////
                        HARVEST FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    // TODO: Add delayed harvest logic

    /// @notice Harvests the yield
    /// @dev Can only be called by the executor
    /// @param swapper Address of the Swapper
    /// @param amountOutMin Minimum amount of underlying tokens received
    /// @param data Data to be passed for the swapper
    function harvest(
        address swapper,
        uint256 amountOutMin,
        bytes calldata data
    ) public {
        if (executors[msg.sender] != true)
            revert YoSifuStargateVault__NotExecutor();

        if (lastHarvestBlock == block.number)
            revert YoSifuStargateVault__HarvestAtSameBlock();

        uint256 baseAssetBalanceBefore = asset.balanceOf(address(this));

        stargateStaking.deposit(pid, 0);

        uint256 rewardTokenBalance = rewardToken.balanceOf(address(this));
        rewardToken.safeTransfer(swapper, rewardTokenBalance);
        ISwapper(swapper).onSwapReceived(data);

        uint256 underlyingAssetBalance = underlyingAsset.balanceOf(
            address(this)
        );

        if (underlyingAssetBalance < amountOutMin)
            revert YoSifuStargateVault__InsufficientOut();

        stargateRouter.addLiquidity(
            poolId,
            underlyingAssetBalance,
            address(this)
        );

        uint256 baseAssetBalance = asset.balanceOf(address(this)) -
            baseAssetBalanceBefore;

        uint256 totalFee = baseAssetBalance.mulDivDown(fee, 1e18);

        asset.safeTransfer(feeTo, totalFee);

        stargateStaking.deposit(pid, baseAssetBalance - totalFee);

        totalLockedProfit = baseAssetBalance - totalFee;
        totalBaseAssets += baseAssetBalance - totalFee;

        lastHarvestBlock = block.number;

        emit LogFeeClaimed(feeTo, totalFee);

        emit LogHarvested(baseAssetBalance);
    }

    /// @notice Stake all the base tokens, ideally there shouldn't be any left
    function stakeAllBaseAsset() public onlyOwner {
        uint256 balance = asset.balanceOf(address(this));
        stargateStaking.deposit(pid, balance);
        emit LogStakedAllAssets(balance);
    }

    /// @notice Emergency Withdraw
    /// @dev This would forfeit the rewards but would withdraw all tokens
    /// from the staking contract
    function emergencyWithdraw() public onlyOwner {
        stargateStaking.emergencyWithdraw(pid);
        emit LogEmergencyWithdraw(pid, asset.balanceOf(address(this)));
    }

    /*//////////////////////////////////////////////////////////////
                        VAULT ADMIN FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Sets the status of the executor
    /// @dev Only owner of the vault can set this
    /// @param _executor Address of the Executor
    /// @param _status Status of the Executor
    function setExecutorsStatus(address _executor, bool _status)
        external
        onlyOwner
    {
        executors[_executor] = _status;
        emit LogSetExecutorStatus(_executor, _status);
    }

    /// @notice Sets the new fee receiver
    /// @dev Only owner of the vault can set this
    /// @param _newFeeTo Address of the New Fee Receiver
    function setFeeTo(address _newFeeTo) external onlyOwner {
        feeTo = _newFeeTo;
        emit LogSetFeeTo(_newFeeTo);
    }

    /// @notice Sets the Fees
    /// @dev Only owner of the vault can set this
    /// @param _newFees New Fee Vaule
    function setFees(uint256 _newFees) external onlyOwner {
        // can't set it to 100%
        if (_newFees >= 1e18) revert YoSifuStargateVault__InvalidFee();
        fee = _newFees;
        emit LogSetFees(_newFees);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStargatePool {
    function deltaCredit() external view returns (uint256);

    function totalLiquidity() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint256);

    function poolId() external view returns (uint256);

    function localDecimals() external view returns (uint256);

    function token() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function convertRate() external view returns (uint256);

    function mintFeeBP() external view returns (uint256);

    function BP_DENOMINATOR() external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern and gas efficient ERC20 + EIP-2612 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC20.sol)
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v2-core/blob/master/contracts/UniswapV2ERC20.sol)
/// @dev Do not manually set balances without updating totalSupply, as the sum of all user balances must not exceed it.
abstract contract ERC20 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 amount);

    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /*//////////////////////////////////////////////////////////////
                            METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    uint8 public immutable decimals;

    /*//////////////////////////////////////////////////////////////
                              ERC20 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;

    mapping(address => mapping(address => uint256)) public allowance;

    /*//////////////////////////////////////////////////////////////
                            EIP-2612 STORAGE
    //////////////////////////////////////////////////////////////*/

    uint256 internal immutable INITIAL_CHAIN_ID;

    bytes32 internal immutable INITIAL_DOMAIN_SEPARATOR;

    mapping(address => uint256) public nonces;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        INITIAL_CHAIN_ID = block.chainid;
        INITIAL_DOMAIN_SEPARATOR = computeDomainSeparator();
    }

    /*//////////////////////////////////////////////////////////////
                               ERC20 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 amount) public virtual returns (bool) {
        allowance[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);

        return true;
    }

    function transfer(address to, uint256 amount) public virtual returns (bool) {
        balanceOf[msg.sender] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual returns (bool) {
        uint256 allowed = allowance[from][msg.sender]; // Saves gas for limited approvals.

        if (allowed != type(uint256).max) allowance[from][msg.sender] = allowed - amount;

        balanceOf[from] -= amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(from, to, amount);

        return true;
    }

    /*//////////////////////////////////////////////////////////////
                             EIP-2612 LOGIC
    //////////////////////////////////////////////////////////////*/

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        require(deadline >= block.timestamp, "PERMIT_DEADLINE_EXPIRED");

        // Unchecked because the only math done is incrementing
        // the owner's nonce which cannot realistically overflow.
        unchecked {
            address recoveredAddress = ecrecover(
                keccak256(
                    abi.encodePacked(
                        "\x19\x01",
                        DOMAIN_SEPARATOR(),
                        keccak256(
                            abi.encode(
                                keccak256(
                                    "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
                                ),
                                owner,
                                spender,
                                value,
                                nonces[owner]++,
                                deadline
                            )
                        )
                    )
                ),
                v,
                r,
                s
            );

            require(recoveredAddress != address(0) && recoveredAddress == owner, "INVALID_SIGNER");

            allowance[recoveredAddress][spender] = value;
        }

        emit Approval(owner, spender, value);
    }

    function DOMAIN_SEPARATOR() public view virtual returns (bytes32) {
        return block.chainid == INITIAL_CHAIN_ID ? INITIAL_DOMAIN_SEPARATOR : computeDomainSeparator();
    }

    function computeDomainSeparator() internal view virtual returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                    keccak256(bytes(name)),
                    keccak256("1"),
                    block.chainid,
                    address(this)
                )
            );
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 amount) internal virtual {
        totalSupply += amount;

        // Cannot overflow because the sum of all user
        // balances can't exceed the max uint256 value.
        unchecked {
            balanceOf[to] += amount;
        }

        emit Transfer(address(0), to, amount);
    }

    function _burn(address from, uint256 amount) internal virtual {
        balanceOf[from] -= amount;

        // Cannot underflow because a user's balance
        // will never be larger than the total supply.
        unchecked {
            totalSupply -= amount;
        }

        emit Transfer(from, address(0), amount);
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IStargateRouter {
    struct lzTxObj {
        uint256 dstGasForCall;
        uint256 dstNativeAmount;
        bytes dstNativeAddr;
    }

    function addLiquidity(
        uint256 _poolId,
        uint256 _amountLD,
        address _to
    ) external;

    function swap(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLD,
        uint256 _minAmountLD,
        lzTxObj memory _lzTxParams,
        bytes calldata _to,
        bytes calldata _payload
    ) external payable;

    function redeemRemote(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        uint256 _minAmountLD,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function instantRedeemLocal(
        uint16 _srcPoolId,
        uint256 _amountLP,
        address _to
    ) external returns (uint256);

    function redeemLocal(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress,
        uint256 _amountLP,
        bytes calldata _to,
        lzTxObj memory _lzTxParams
    ) external payable;

    function sendCredits(
        uint16 _dstChainId,
        uint256 _srcPoolId,
        uint256 _dstPoolId,
        address payable _refundAddress
    ) external payable;

    function quoteLayerZeroFee(
        uint16 _dstChainId,
        uint8 _functionType,
        bytes calldata _toAddress,
        bytes calldata _transferAndCallPayload,
        lzTxObj memory _lzTxParams
    ) external view returns (uint256, uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface ISwapper {
    function onSwapReceived(bytes calldata data) external;
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity >=0.8.0;

interface ILPStaking {
    function deposit(uint256 _pid, uint256 _amount) external;

    function emergencyWithdraw(uint256 _pid) external;

    function poolInfo(uint256)
        external
        view
        returns (
            address lpToken,
            uint256 allocPoint,
            uint256 lastRewardBlock,
            uint256 accEmissionPerShare
        );

    function userInfo(uint256, address)
        external
        view
        returns (uint256 amount, uint256 rewardDebt);

    function withdraw(uint256 _pid, uint256 _amount) external;

    function pendingStargate(uint256 _pid, address _user)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";
import {SafeTransferLib} from "../utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "../utils/FixedPointMathLib.sol";

/// @notice Minimal ERC4626 tokenized Vault implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/mixins/ERC4626.sol)
abstract contract ERC4626 is ERC20 {
    using SafeTransferLib for ERC20;
    using FixedPointMathLib for uint256;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Deposit(address indexed caller, address indexed owner, uint256 assets, uint256 shares);

    event Withdraw(
        address indexed caller,
        address indexed receiver,
        address indexed owner,
        uint256 assets,
        uint256 shares
    );

    /*//////////////////////////////////////////////////////////////
                               IMMUTABLES
    //////////////////////////////////////////////////////////////*/

    ERC20 public immutable asset;

    constructor(
        ERC20 _asset,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol, _asset.decimals()) {
        asset = _asset;
    }

    /*//////////////////////////////////////////////////////////////
                        DEPOSIT/WITHDRAWAL LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit(uint256 assets, address receiver) public virtual returns (uint256 shares) {
        // Check for rounding error since we round down in previewDeposit.
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function mint(uint256 shares, address receiver) public virtual returns (uint256 assets) {
        assets = previewMint(shares); // No need to check for rounding error, previewMint rounds up.

        // Need to transfer before minting or ERC777s could reenter.
        asset.safeTransferFrom(msg.sender, address(this), assets);

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);

        afterDeposit(assets, shares);
    }

    function withdraw(
        uint256 assets,
        address receiver,
        address owner
    ) public virtual returns (uint256 shares) {
        shares = previewWithdraw(assets); // No need to check for rounding error, previewWithdraw rounds up.

        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    function redeem(
        uint256 shares,
        address receiver,
        address owner
    ) public virtual returns (uint256 assets) {
        if (msg.sender != owner) {
            uint256 allowed = allowance[owner][msg.sender]; // Saves gas for limited approvals.

            if (allowed != type(uint256).max) allowance[owner][msg.sender] = allowed - shares;
        }

        // Check for rounding error since we round down in previewRedeem.
        require((assets = previewRedeem(shares)) != 0, "ZERO_ASSETS");

        beforeWithdraw(assets, shares);

        _burn(owner, shares);

        emit Withdraw(msg.sender, receiver, owner, assets, shares);

        asset.safeTransfer(receiver, assets);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCOUNTING LOGIC
    //////////////////////////////////////////////////////////////*/

    function totalAssets() public view virtual returns (uint256);

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivDown(supply, totalAssets());
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivDown(totalAssets(), supply);
    }

    function previewDeposit(uint256 assets) public view virtual returns (uint256) {
        return convertToShares(assets);
    }

    function previewMint(uint256 shares) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? shares : shares.mulDivUp(totalAssets(), supply);
    }

    function previewWithdraw(uint256 assets) public view virtual returns (uint256) {
        uint256 supply = totalSupply; // Saves an extra SLOAD if totalSupply is non-zero.

        return supply == 0 ? assets : assets.mulDivUp(supply, totalAssets());
    }

    function previewRedeem(uint256 shares) public view virtual returns (uint256) {
        return convertToAssets(shares);
    }

    /*//////////////////////////////////////////////////////////////
                     DEPOSIT/WITHDRAWAL LIMIT LOGIC
    //////////////////////////////////////////////////////////////*/

    function maxDeposit(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxMint(address) public view virtual returns (uint256) {
        return type(uint256).max;
    }

    function maxWithdraw(address owner) public view virtual returns (uint256) {
        return convertToAssets(balanceOf[owner]);
    }

    function maxRedeem(address owner) public view virtual returns (uint256) {
        return balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                          INTERNAL HOOKS LOGIC
    //////////////////////////////////////////////////////////////*/

    function beforeWithdraw(uint256 assets, uint256 shares) internal virtual {}

    function afterDeposit(uint256 assets, uint256 shares) internal virtual {}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Arithmetic library with operations for fixed-point numbers.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/FixedPointMathLib.sol)
/// @author Inspired by USM (https://github.com/usmfum/USM/blob/master/contracts/WadMath.sol)
library FixedPointMathLib {
    /*//////////////////////////////////////////////////////////////
                    SIMPLIFIED FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    uint256 internal constant WAD = 1e18; // The scalar of ETH and most ERC20s.

    function mulWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, y, WAD); // Equivalent to (x * y) / WAD rounded down.
    }

    function mulWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, y, WAD); // Equivalent to (x * y) / WAD rounded up.
    }

    function divWadDown(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivDown(x, WAD, y); // Equivalent to (x * WAD) / y rounded down.
    }

    function divWadUp(uint256 x, uint256 y) internal pure returns (uint256) {
        return mulDivUp(x, WAD, y); // Equivalent to (x * WAD) / y rounded up.
    }

    /*//////////////////////////////////////////////////////////////
                    LOW LEVEL FIXED POINT OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function mulDivDown(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // Divide z by the denominator.
            z := div(z, denominator)
        }
    }

    function mulDivUp(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 z) {
        assembly {
            // Store x * y in z for now.
            z := mul(x, y)

            // Equivalent to require(denominator != 0 && (x == 0 || (x * y) / x == y))
            if iszero(and(iszero(iszero(denominator)), or(iszero(x), eq(div(z, x), y)))) {
                revert(0, 0)
            }

            // First, divide z - 1 by the denominator and add 1.
            // We allow z - 1 to underflow if z is 0, because we multiply the
            // end result by 0 if z is zero, ensuring we return 0 if z is zero.
            z := mul(iszero(iszero(z)), add(div(sub(z, 1), denominator), 1))
        }
    }

    function rpow(
        uint256 x,
        uint256 n,
        uint256 scalar
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    // 0 ** 0 = 1
                    z := scalar
                }
                default {
                    // 0 ** n = 0
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    // If n is even, store scalar in z for now.
                    z := scalar
                }
                default {
                    // If n is odd, store x in z for now.
                    z := x
                }

                // Shifting right by 1 is like dividing by 2.
                let half := shr(1, scalar)

                for {
                    // Shift n right by 1 before looping to halve it.
                    n := shr(1, n)
                } n {
                    // Shift n right by 1 each iteration to halve it.
                    n := shr(1, n)
                } {
                    // Revert immediately if x ** 2 would overflow.
                    // Equivalent to iszero(eq(div(xx, x), x)) here.
                    if shr(128, x) {
                        revert(0, 0)
                    }

                    // Store x squared.
                    let xx := mul(x, x)

                    // Round to the nearest number.
                    let xxRound := add(xx, half)

                    // Revert if xx + half overflowed.
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }

                    // Set x to scaled xxRound.
                    x := div(xxRound, scalar)

                    // If n is even:
                    if mod(n, 2) {
                        // Compute z * x.
                        let zx := mul(z, x)

                        // If z * x overflowed:
                        if iszero(eq(div(zx, x), z)) {
                            // Revert if x is non-zero.
                            if iszero(iszero(x)) {
                                revert(0, 0)
                            }
                        }

                        // Round to the nearest number.
                        let zxRound := add(zx, half)

                        // Revert if zx + half overflowed.
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }

                        // Return properly scaled zxRound.
                        z := div(zxRound, scalar)
                    }
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                        GENERAL NUMBER UTILITIES
    //////////////////////////////////////////////////////////////*/

    function sqrt(uint256 x) internal pure returns (uint256 z) {
        assembly {
            // Start off with z at 1.
            z := 1

            // Used below to help find a nearby power of 2.
            let y := x

            // Find the lowest power of 2 that is at least sqrt(x).
            if iszero(lt(y, 0x100000000000000000000000000000000)) {
                y := shr(128, y) // Like dividing by 2 ** 128.
                z := shl(64, z) // Like multiplying by 2 ** 64.
            }
            if iszero(lt(y, 0x10000000000000000)) {
                y := shr(64, y) // Like dividing by 2 ** 64.
                z := shl(32, z) // Like multiplying by 2 ** 32.
            }
            if iszero(lt(y, 0x100000000)) {
                y := shr(32, y) // Like dividing by 2 ** 32.
                z := shl(16, z) // Like multiplying by 2 ** 16.
            }
            if iszero(lt(y, 0x10000)) {
                y := shr(16, y) // Like dividing by 2 ** 16.
                z := shl(8, z) // Like multiplying by 2 ** 8.
            }
            if iszero(lt(y, 0x100)) {
                y := shr(8, y) // Like dividing by 2 ** 8.
                z := shl(4, z) // Like multiplying by 2 ** 4.
            }
            if iszero(lt(y, 0x10)) {
                y := shr(4, y) // Like dividing by 2 ** 4.
                z := shl(2, z) // Like multiplying by 2 ** 2.
            }
            if iszero(lt(y, 0x8)) {
                // Equivalent to 2 ** z.
                z := shl(1, z)
            }

            // Shifting right by 1 is like dividing by 2.
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))
            z := shr(1, add(z, div(x, z)))

            // Compute a rounded down version of z.
            let zRoundDown := div(x, z)

            // If zRoundDown is smaller, use it.
            if lt(zRoundDown, z) {
                z := zRoundDown
            }
        }
    }

    function unsafeMod(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Mod x by y. Note this will return
            // 0 instead of reverting if y is zero.
            z := mod(x, y)
        }
    }

    function unsafeDiv(uint256 x, uint256 y) internal pure returns (uint256 r) {
        assembly {
            // Divide x by y. Note this will return
            // 0 instead of reverting if y is zero.
            r := div(x, y)
        }
    }

    function unsafeDivUp(uint256 x, uint256 y) internal pure returns (uint256 z) {
        assembly {
            // Add 1 to x * y if x % y > 0. Note this will
            // return 0 instead of reverting if y is zero.
            z := add(gt(mod(x, y), 0), div(x, y))
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import {ERC20} from "../tokens/ERC20.sol";

/// @notice Safe ETH and ERC20 transfer library that gracefully handles missing return values.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol)
/// @dev Use with caution! Some functions in this library knowingly create dirty bits at the destination of the free memory pointer.
/// @dev Note that none of the functions in this library check that a token has code at all! That responsibility is delegated to the caller.
library SafeTransferLib {
    /*//////////////////////////////////////////////////////////////
                             ETH OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferETH(address to, uint256 amount) internal {
        bool success;

        assembly {
            // Transfer the ETH and store if it succeeded or not.
            success := call(gas(), to, amount, 0, 0, 0, 0)
        }

        require(success, "ETH_TRANSFER_FAILED");
    }

    /*//////////////////////////////////////////////////////////////
                            ERC20 OPERATIONS
    //////////////////////////////////////////////////////////////*/

    function safeTransferFrom(
        ERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), from) // Append the "from" argument.
            mstore(add(freeMemoryPointer, 36), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 68), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 100 because the length of our calldata totals up like so: 4 + 32 * 3.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 100, 0, 32)
            )
        }

        require(success, "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0xa9059cbb00000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "TRANSFER_FAILED");
    }

    function safeApprove(
        ERC20 token,
        address to,
        uint256 amount
    ) internal {
        bool success;

        assembly {
            // Get a pointer to some free memory.
            let freeMemoryPointer := mload(0x40)

            // Write the abi-encoded calldata into memory, beginning with the function selector.
            mstore(freeMemoryPointer, 0x095ea7b300000000000000000000000000000000000000000000000000000000)
            mstore(add(freeMemoryPointer, 4), to) // Append the "to" argument.
            mstore(add(freeMemoryPointer, 36), amount) // Append the "amount" argument.

            success := and(
                // Set success to whether the call reverted, if not we check it either
                // returned exactly 1 (can't just be non-zero data), or had no return data.
                or(and(eq(mload(0), 1), gt(returndatasize(), 31)), iszero(returndatasize())),
                // We use 68 because the length of our calldata totals up like so: 4 + 32 * 2.
                // We use 0 and 32 to copy up to 32 bytes of return data into the scratch space.
                // Counterintuitively, this call must be positioned second to the or() call in the
                // surrounding and() call or else returndatasize() will be zero during the computation.
                call(gas(), token, 0, freeMemoryPointer, 68, 0, 32)
            )
        }

        require(success, "APPROVE_FAILED");
    }
}