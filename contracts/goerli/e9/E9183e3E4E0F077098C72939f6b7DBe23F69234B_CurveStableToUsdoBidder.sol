// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    // transfer and tranferFrom have been removed, because they don't work on all tokens (some aren't ERC20 complaint).
    // By removing them you can't accidentally use them.
    // name, symbol and decimals have been removed, because they are optional and sometimes wrongly implemented (MKR).
    // Use BoringERC20 with `using BoringERC20 for IERC20` and call `safeTransfer`, `safeTransferFrom`, etc instead.
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

interface IStrictERC20 {
    // This is the strict ERC20 interface. Don't use this, certainly not if you don't control the ERC20 token you're calling.
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import './usd0/IUSD0.sol';
import './swappers/IMultiSwapper.sol';

interface IBeachBar {
    /// @notice swap extra data
    struct SwapData {
        uint256 minAssetAmount;
    }

    /// @notice Used to define the MasterContract's type
    enum ContractType {
        lowRisk,
        mediumRisk,
        highRisk
    }

    /// @notice MasterContract address and type
    struct MasterContract {
        address location;
        ContractType risk;
    }

    function swappers(IMultiSwapper swapper) external view returns (bool);

    function yieldBox() external view returns (address payable);

    function tapToken() external view returns (address);

    function tapAssetId() external view returns (uint256);

    function usdoToken() external view returns (address);

    function usdoAssetId() external view returns (uint256);

    function feeTo() external view returns (address);

    function feeVeTap() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable func-name-mixedcase
// solhint-disable var-name-mixedcase

interface ICurvePool {
    function coins(uint256 i) external view returns (address);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@boringcrypto/boring-solidity/contracts/BoringOwnable.sol';

import '../../IBeachBar.sol';
import '../ILiquidationQueue.sol';
import '../../libraries/ICurvePool.sol';
import '../../swappers/ICurveSwapper.sol';
import '../../singularity/interfaces/ISingularity.sol';
import '../../../yieldbox/contracts/interfaces/IYieldBox.sol';

/*

__/\\\\\\\\\\\\\\\_____/\\\\\\\\\_____/\\\\\\\\\\\\\____/\\\\\\\\\\\_______/\\\\\_____________/\\\\\\\\\_____/\\\\\\\\\____        
 _\///////\\\/////____/\\\\\\\\\\\\\__\/\\\/////////\\\_\/////\\\///______/\\\///\\\________/\\\////////____/\\\\\\\\\\\\\__       
  _______\/\\\________/\\\/////////\\\_\/\\\_______\/\\\_____\/\\\_______/\\\/__\///\\\____/\\\/____________/\\\/////////\\\_      
   _______\/\\\_______\/\\\_______\/\\\_\/\\\\\\\\\\\\\/______\/\\\______/\\\______\//\\\__/\\\_____________\/\\\_______\/\\\_     
    _______\/\\\_______\/\\\\\\\\\\\\\\\_\/\\\/////////________\/\\\_____\/\\\_______\/\\\_\/\\\_____________\/\\\\\\\\\\\\\\\_    
     _______\/\\\_______\/\\\/////////\\\_\/\\\_________________\/\\\_____\//\\\______/\\\__\//\\\____________\/\\\/////////\\\_   
      _______\/\\\_______\/\\\_______\/\\\_\/\\\_________________\/\\\______\///\\\__/\\\_____\///\\\__________\/\\\_______\/\\\_  
       _______\/\\\_______\/\\\_______\/\\\_\/\\\______________/\\\\\\\\\\\____\///\\\\\/________\////\\\\\\\\\_\/\\\_______\/\\\_ 
        _______\///________\///________\///__\///______________\///////////_______\/////_____________\/////////__\///________\///__

*/

/// @title Swaps Stable to USD0 through Curve
/// @dev Performs a swap operation between stable and USD0 through 3CRV+USD0 pool
contract CurveStableToUsdoBidder is BoringOwnable {
    // ************ //
    // *** VARS *** //
    // ************ //

    /// @notice 3Crv+USD0 swapper
    ICurveSwapper public curveSwapper;
    /// @notice Curve pool assets number
    uint256 curveAssetsLength;

    // ************** //
    // *** EVENTS *** //
    // ************** //
    event CurveSwapperUpdated(address indexed _old, address indexed _new);

    /// @notice creates a new CurveStableToUsdoBidder
    /// @param curveSwapper_ CurveSwapper address
    /// @param curvePoolAssetCount_ Curve pool assets number
    constructor(ICurveSwapper curveSwapper_, uint256 curvePoolAssetCount_) {
        curveSwapper = curveSwapper_;
        curveAssetsLength = curvePoolAssetCount_;
    }

    // ********************** //
    // *** VIEW FUNCTIONS *** //
    // ********************** //
    /// @notice returns the unique name
    function name() external pure returns (string memory) {
        return 'stable -> USD0 (3Crv+USD0)';
    }

    /// @notice returns the amount of collateral
    /// @param amountIn Stablecoin amount
    function getOutputAmount(
        ISingularity mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata
    ) external view returns (uint256) {
        require(
            IBeachBar(mixologist.beachBar()).usdoToken() != address(0),
            'USD0 not set'
        );

        uint256 usdoAssetId = IBeachBar(mixologist.beachBar()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountIn;
        }

        return
            _getOutput(
                IYieldBox(mixologist.yieldBox()),
                tokenInId,
                usdoAssetId,
                amountIn
            );
    }

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    function getInputAmount(
        ISingularity mixologist,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata
    ) external view returns (uint256) {
        require(
            IBeachBar(mixologist.beachBar()).usdoToken() != address(0),
            'USD0 not set'
        );

        uint256 usdoAssetId = IBeachBar(mixologist.beachBar()).usdoAssetId();
        if (tokenInId == usdoAssetId) {
            return amountOut;
        }

        return
            _getOutput(
                IYieldBox(mixologist.yieldBox()),
                usdoAssetId,
                tokenInId,
                amountOut
            );
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice swaps stable to collateral
    /// @param tokenInId Stablecoin asset id
    /// @param amountIn Stablecoin amount
    /// @param data extra data used for the swap operation
    function swap(
        ISingularity mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256) {
        require(
            IBeachBar(mixologist.beachBar()).usdoToken() != address(0),
            'USD0 not set'
        );
        IYieldBox yieldBox = IYieldBox(mixologist.yieldBox());
        ILiquidationQueue liquidationQueue = ILiquidationQueue(
            mixologist.liquidationQueue()
        );

        uint256 usdoAssetId = IBeachBar(mixologist.beachBar()).usdoAssetId();
        require(msg.sender == address(liquidationQueue), 'only LQ');
        if (tokenInId == usdoAssetId) {
            yieldBox.transfer(
                address(this),
                address(liquidationQueue),
                tokenInId,
                yieldBox.toShare(tokenInId, amountIn, false)
            );
            return amountIn;
        }

        uint256 _usdoMin = 0;
        if (data.length > 0) {
            //should always be sent
            _usdoMin = abi.decode(data, (uint256));
        }
        yieldBox.transfer(
            address(this),
            address(curveSwapper),
            tokenInId,
            yieldBox.toShare(tokenInId, amountIn, false)
        );
        return
            _swap(
                yieldBox,
                tokenInId,
                usdoAssetId,
                amountIn,
                _usdoMin,
                address(liquidationQueue)
            );
    }

    // *********************** //
    // *** OWNER FUNCTIONS *** //
    // *********************** //
    /// @notice sets the Curve swapper
    /// @dev used for USD0 to WETH swap
    /// @param _swapper The curve pool swapper address
    function setCurveSwapper(ICurveSwapper _swapper) external onlyOwner {
        emit CurveSwapperUpdated(address(curveSwapper), address(_swapper));
        curveSwapper = _swapper;
    }

    // ************************* //
    // *** PRIVATE FUNCTIONS *** //
    // ************************* //
    function _getCurveIndex(address token) private view returns (uint256) {
        int256 index = -1;
        for (uint256 i = 0; i < curveAssetsLength; i++) {
            address tokenAtIndex = ICurvePool(curveSwapper.curvePool()).coins(
                i
            );
            if (tokenAtIndex == token) {
                index = int256(i);
            }
        }
        require(index > -1, 'asset not found');
        return uint256(index);
    }

    function _getOutput(
        IYieldBox yieldBox,
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountIn
    ) private view returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(tokenInId);
        (, address tokenOutAddress, , ) = yieldBox.assets(tokenOutId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);
        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;

        uint256 share = yieldBox.toShare(tokenInId, amountIn, false);
        return curveSwapper.getOutputAmount(tokenInId, indexes, share);
    }

    function _swap(
        IYieldBox yieldBox,
        uint256 stableAssetId,
        uint256 usdoAssetId,
        uint256 amountIn,
        uint256 minAmount,
        address to
    ) private returns (uint256) {
        (, address tokenInAddress, , ) = yieldBox.assets(stableAssetId);
        (, address tokenOutAddress, , ) = yieldBox.assets(usdoAssetId);

        uint256 tokenInCurveIndex = _getCurveIndex(tokenInAddress);
        uint256 tokenOutCurveIndex = _getCurveIndex(tokenOutAddress);

        uint256[] memory indexes = new uint256[](2);
        indexes[0] = tokenInCurveIndex;
        indexes[1] = tokenOutCurveIndex;
        uint256 tokenInShare = yieldBox.toShare(stableAssetId, amountIn, false);

        (uint256 amountOut, ) = curveSwapper.swap(
            stableAssetId,
            usdoAssetId,
            indexes,
            tokenInShare,
            minAmount,
            to
        );

        return amountOut;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

/// @notice Used for performing swap operations when bidding on LiquidationQueue
interface IBidder {
    /// @notice returns the unique name
    function name() external view returns (string memory);

    /// @notice returns the amount of collateral
    /// @param mixologist Market to query for
    /// @param tokenInId Token in YieldBox asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for retrieving the ouput
    function getOutputAmount(
        address mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external view returns (uint256);

    /// @notice swap USD0 to collateral
    /// @param mixologist Market to swap for
    /// @param tokenInId Token in asset id
    /// @param amountIn Token in amount
    /// @param data extra data used for the swap operation
    function swap(
        address mixologist,
        uint256 tokenInId,
        uint256 amountIn,
        bytes calldata data
    ) external returns (uint256);

    /// @notice returns token tokenIn amount based on tokenOut amount
    /// @param mixologist Market to query for
    /// @param tokenInId Token in asset id
    /// @param amountOut Token out amount
    /// @param data extra data used for retrieving the ouput
    function getInputAmount(
        address mixologist,
        uint256 tokenInId,
        uint256 amountOut,
        bytes calldata data
    ) external view returns (uint256);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import './bidders/IBidder.sol';

interface ILiquidationQueue {
    enum MODE {
        ADD,
        SUB
    }

    struct Bidder {
        bool isUsdo;
        bool swapOnExecute;
        uint256 usdoAmount;
        uint256 liquidatedAssetAmount;
        uint256 timestamp; // Timestamp in second of the last bid.
    }

    struct OrderBookPoolEntry {
        address bidder;
        Bidder bidInfo;
    }

    struct OrderBookPoolInfo {
        uint32 poolId;
        uint32 nextBidPull; // Next position in `entries` to start pulling bids from
        uint32 nextBidPush; // Next position in `entries` to start pushing bids to
    }

    struct LiquidationQueueMeta {
        uint256 activationTime; // Time needed before a bid can be activated for execution
        uint256 minBidAmount; // Minimum bid amount
        address feeCollector; // Address of the fee collector
        IBidder bidExecutionSwapper; //Allows swapping USD0 to collateral when a bid is executed
        IBidder usdoSwapper; //Allows swapping any other stablecoin to USD0
    }
    
    struct BidExecutionData {
        uint256 curPoolId;
        bool isBidAvail;
        OrderBookPoolInfo poolInfo;
        OrderBookPoolEntry orderBookEntry;
        OrderBookPoolEntry orderBookEntryCopy;
        uint256 totalPoolAmountExecuted;
        uint256 totalPoolCollateralLiquidated;
        uint256 totalUsdoAmountUsed;
        uint256 exchangeRate;
        uint256 discountedBidderAmount;
    }

    function init(LiquidationQueueMeta calldata, address mixologist) external;

    function onlyOnce() external view returns (bool);

    function setBidExecutionSwapper(address swapper) external;

    function setUsdoSwapper(address swapper) external;

    function getNextAvailBidPool()
        external
        view
        returns (uint256 i, bool available);

    function executeBids(
        uint256 collateralAmountToLiquidate,
        bytes calldata swapData
    ) external returns (uint256 amountExecuted, uint256 collateralLiquidated);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data)
        external
        returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data)
        external
        view
        returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './IOracle.sol';
import '../../IBeachBar.sol';
import '../../swappers/IMultiSwapper.sol';

interface ISingularity {
    struct AccrueInfo {
        uint64 interestPerSecond;
        uint64 lastAccrued;
        uint128 feesEarnedFraction;
    }

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );
    event LogAccrue(
        uint256 accruedAmount,
        uint256 feeFraction,
        uint64 rate,
        uint256 utilization
    );
    event LogAddAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogAddCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogBorrow(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 feeAmount,
        uint256 part
    );
    event LogExchangeRate(uint256 rate);
    event LogFeeTo(address indexed newFeeTo);
    event LogRemoveAsset(
        address indexed from,
        address indexed to,
        uint256 share,
        uint256 fraction
    );
    event LogRemoveCollateral(
        address indexed from,
        address indexed to,
        uint256 share
    );
    event LogRepay(
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 part
    );
    event LogWithdrawFees(address indexed feeTo, uint256 feesEarnedFraction);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event LogFlashLoan(
        address indexed borrower,
        uint256 amount,
        uint256 feeAmount,
        address indexed receiver
    );
    event LogYieldBoxFeesDeposit(uint256 feeShares, uint256 tapAmount);
    event LogApprovalForAll(
        address indexed _from,
        address indexed _operator,
        bool _approved
    );
    error NotApproved(address _from, address _operator);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function accrue() external;

    function accrueInfo()
        external
        view
        returns (
            uint64 interestPerSecond,
            uint64 lastBlockAccrued,
            uint128 feesEarnedFraction
        );

    function setApprovalForAll(address operator, bool approved) external;

    function addAsset(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external returns (uint256 fraction);

    function addCollateral(
        address from,
        address to,
        bool skim,
        uint256 share
    ) external;

    function allowance(address, address) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function asset() external view returns (address);

    function assetId() external view returns (uint256);

    function balanceOf(address) external view returns (uint256);

    function beachBar() external view returns (address);

    function borrow(
        address from,
        address to,
        uint256 amount
    ) external returns (uint256 part, uint256 share);

    function claimOwnership() external;

    function collateral() external view returns (address);

    function collateralId() external view returns (uint256);

    /// @notice Allows batched call to Singularity.
    /// @param calls An array encoded call data.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    function execute(bytes[] calldata calls, bool revertOnFail)
        external
        returns (bool[] memory successes, string[] memory results);

    function decimals() external view returns (uint8);

    function exchangeRate() external view returns (uint256);

    function feeTo() external view returns (address);

    function getInitData(
        address collateral_,
        address asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) external pure returns (bytes memory data);

    function init(bytes calldata data) external payable;

    function isSolvent(address user, bool open) external view returns (bool);

    function liquidate(
        address[] calldata users,
        uint256[] calldata borrowParts,
        address to,
        IMultiSwapper swapper,
        bool open
    ) external;

    function masterContract() external view returns (address);

    function name() external view returns (string memory);

    function nonces(address) external view returns (uint256);

    function oracle() external view returns (IOracle);

    function oracleData() external view returns (bytes memory);

    function owner() external view returns (address);

    function pendingOwner() external view returns (address);

    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function removeAsset(
        address from,
        address to,
        uint256 fraction
    ) external returns (uint256 share);

    function removeCollateral(
        address from,
        address to,
        uint256 share
    ) external;

    function repay(
        address from,
        address to,
        bool skim,
        uint256 part
    ) external returns (uint256 amount);

    function setFeeTo(address newFeeTo) external;

    function setSwapper(IMultiSwapper swapper, bool enable) external;

    function swappers(IMultiSwapper) external view returns (bool);

    function symbol() external view returns (string memory);

    function totalAsset() external view returns (uint128 elastic, uint128 base);

    function totalBorrow()
        external
        view
        returns (uint128 elastic, uint128 base);

    function totalCollateralShare() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) external;

    function updateExchangeRate() external returns (bool updated, uint256 rate);

    function userBorrowPart(address) external view returns (uint256);

    function userCollateralShare(address) external view returns (uint256);

    function withdrawFees() external;

    function depositFeesToYieldBox(IMultiSwapper, IBeachBar.SwapData calldata)
        external;

    function yieldBox() external view returns (address payable);

    function liquidationQueue() external view returns (address payable);

    function withdrawTo(
        uint16 dstChainId,
        bytes memory receiver,
        uint256 amount,
        bytes calldata adapterParams,
        address payable refundAddress
    ) external payable;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface ICurveSwapper {
    function curvePool() external view returns (address);

    function yieldBox() external view returns (address);

    /// @notice returns the possible output amount for input share
    /// @param tokenInId YieldBox asset id
    /// @param tokenIndexes The input and the output Curve's pool indexes
    /// @param shareIn Shares to get the amount for
    function getOutputAmount(
        uint256 tokenInId,
        uint256[] calldata tokenIndexes,
        uint256 shareIn
    ) external view returns (uint256 amountOut);

    /// @notice swaps token in with token out
    /// @dev returns both amount and shares
    /// @param tokenInId YieldBox asset id
    /// @param tokenOutId YieldBox asset id
    /// @param tokenIndexes The input and the output Curve's pool indexes
    /// @param shareIn Shares to be swapped
    /// @param amountOutMin Minimum amount to be received
    /// @param to Receiver address
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256[] calldata tokenIndexes,
        uint256 shareIn,
        uint256 amountOutMin,
        address to
    ) external returns (uint256 amountOut, uint256 shareOut);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IMultiSwapper {
    function swap(
        uint256 tokenInId,
        uint256 tokenOutId,
        uint256 amountMinOut,
        address to,
        address[] calldata path,
        uint256 shareIn
    ) external returns (uint256 amountOut, uint256 shareOut);

    function getOutputAmount(
        uint256 tokenInId,
        address[] calldata path,
        uint256 shareIn
    ) external view returns (uint256 amountOut);

    function getInputAmount(
        uint256 tokenOutId,
        address[] calldata path,
        uint256 shareOut
    ) external view returns (uint256 amountIn);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import '@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol';

interface IUSD0 is IStrictERC20 {
    function mint(address _to, uint256 _amount) external;

    function burn(address _from, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../enums/YieldBoxTokenType.sol";

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(uint256 assetId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        );

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}