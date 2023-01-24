import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ISwapRouter.sol";
import "./interfaces/IWETH.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/IFees.sol";
import "./interfaces/ISwapHelper.sol";
import "./interfaces/IRibbonVault.sol";
import "./proxies/S9Proxy.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S9Strategy is Ownable {
    address immutable swapRouter;
    address immutable feeContract;
    address constant wethAddress = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;

    constructor(address swapRouter_, address feeContract_) {
        swapRouter = swapRouter_;
        feeContract = feeContract_;
    }

    uint256 public constant strategyId = 14;

    //modifiers
    modifier whitelistedToken(address token) {
        require(
            IFees(feeContract).whitelistedDepositCurrencies(strategyId, token),
            "whitelistedToken: Invalid token"
        );
        _;
    }

    //mappings
    //user => user proxy
    mapping(address => address) public depositors;

    //vault address => whitelist status
    mapping(address => bool) public vaultWhitelist;

    //valutAsset => vaultAssetSwapHelper
    mapping(address => address) public swapHelper;

    //events
    event Deposit(
        address user,
        address tokenIn,
        address vault,
        uint256 amountIn
    );

    event QueueWithdraw(address user, address vault, uint256 amount);

    event Withdraw(
        address user,
        address tokenOut,
        address vault,
        uint256 amount,
        uint256 fee
    );

    event Claim(address user, address vault, uint256 amonut);

    event Stake(address user, address vault, uint256 amount);

    event ProxyCreation(address user, address proxy);

    //getters

    //returns the amounts in the different deposit states
    //@dev return amounts are in shares except avaliableInstant, multiply with pricePerShare to get USDC amount

    //locked amount currently generating yield
    //pending amount not generating yield, waiting to be available
    //avaliableClaim is amount that has gone through an epoch and has been initiateWithdraw
    //availableInstant amount are deposits that have not gone through an epoch that can be withdrawn
    function getDepositData(address user, address vault)
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        address vaultAsset;
        uint256 locked;
        uint256 pending;
        uint256 avaliableInstant;
        uint256 avaliableClaim;
        uint256 pricePerShare;
        uint256 withdrawPricePerShare;
        uint256 vaultRound;
        uint256 currentLoanTermLength;

        IRibbonVault rv = IRibbonVault(vault);
        (, vaultAsset, , ) = rv.vaultParams();
        //depositReciept is only updated when initiateWithdraw is called
        //In native token
        (vaultRound, , , , , , , , ) = getVaultState(vault);
        avaliableInstant = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[user]
        );
        (
            ,
            pending,
            avaliableClaim,
            withdrawPricePerShare
        ) = _getWithdrawReciepts(vault, vaultRound, depositors[user]);
        pricePerShare = rv.pricePerShare();
        (uint256 heldByAccount, uint256 heldByVault) = rv.shareBalances(
            depositors[user]
        );
        uint256 stakedInGauge = IERC20(IRibbonVault(vault).liquidityGauge())
            .balanceOf(depositors[user]);
        locked = heldByAccount + heldByVault + stakedInGauge;
        (, , currentLoanTermLength, , , , , ) = rv.allocationState();
        return (
            //asset token used by the vault
            vaultAsset,
            //generating yield denotes shares are currently locked in round
            //shares generating yield, before initateWithdraw
            locked,
            //shares generating yield, after initiateWithdraw before completeWithdraw
            pending,
            //token not generating yield, pending instantWithdraw
            avaliableInstant,
            //shares not generating yield, after round end before comepleteWithdraw
            //@dev to only take this parameter for v1
            avaliableClaim,
            //the price per share of the last round, used to calculate token value for locked
            pricePerShare,
            //the price per share of the initiate withdraw round, used to calculate token value for avaliableClaim
            withdrawPricePerShare,
            currentLoanTermLength,
            //can user stake
            heldByAccount + heldByVault
        );
    }

    //direct proxy method to vaultState
    function getVaultState(address vault)
        public
        view
        returns (
            uint16,
            uint104,
            uint104,
            uint128,
            uint128,
            uint64,
            uint64,
            uint128,
            uint256
        )
    {
        (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares,
            uint64 lastEpochTime,
            uint64 lastOptionPurchaseTime,
            uint128 optionsBoughtInRound,
            uint256 amtFundsReturned
        ) = IRibbonVault(vault).vaultState();
        return (
            round,
            lockedAmount,
            lastLockedAmount,
            totalPending,
            queuedWithdrawShares,
            lastEpochTime,
            lastOptionPurchaseTime,
            optionsBoughtInRound,
            amtFundsReturned
        );
    }

    //write
    function depositToken(
        address tokenIn,
        address vault,
        uint256 amount,
        uint256 minAmountOut
    ) public payable whitelistedToken(tokenIn) {
        require(
            IFees(feeContract).depositStatus(strategyId),
            "depositToken: depositsStopped"
        );
        require(vaultWhitelist[vault], "depositToken: vaultWhitelist");
        address proxy = depositors[msg.sender];
        if (proxy == address(0)) {
            //mint proxy if not exists
            S9Proxy newProxy = new S9Proxy(msg.sender);
            proxy = address(newProxy);
            depositors[msg.sender] = proxy;
            emit ProxyCreation(msg.sender, proxy);
        }
        address vaultAsset;
        (, vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        emit Deposit(msg.sender, tokenIn, vault, amount);
        //swap
        if (tokenIn != vaultAsset) {
            if (msg.value == 0) {
                IERC20(tokenIn).transferFrom(msg.sender, address(this), amount);
            } else {
                //convert eth to weth
                (bool success, ) = payable(wethAddress).call{value: msg.value}(
                    ""
                );
                require(success, "depositToken: Send ETH fail");
                tokenIn = wethAddress;
            }
            
            //swap
            if(swapHelper[vaultAsset]!=address(0)){                
                IERC20(tokenIn).approve(swapRouter, amount);
                amount=ISwapRouter(swapRouter).swapTokenForToken(
                    tokenIn,
                    wethAddress,
                    amount,
                    1,
                    address(this));
                //swap to vaultAsset
                IERC20(wethAddress).approve(swapHelper[vaultAsset], amount);                                
                amount=ISwapHelper(swapHelper[vaultAsset]).swap(
                    wethAddress,
                    vaultAsset,
                    amount,
                    minAmountOut,
                    proxy
                );
            }else{                
                IERC20(tokenIn).approve(swapRouter, amount);
                amount = ISwapRouter(swapRouter).swapTokenForToken(
                    tokenIn,
                    vaultAsset,
                    amount,
                    minAmountOut,
                    proxy
                );
            }
        } else {
            IERC20(vaultAsset).transferFrom(msg.sender, proxy, amount);
        }
        S9Proxy(depositors[msg.sender]).deposit(vault, vaultAsset, amount);
    }

    //@dev only the amount here should be in shares
    function queueWithdraw(address vault, uint256 amount) external {
        S9Proxy(depositors[msg.sender]).queueWithdraw(vault, amount);
        emit QueueWithdraw(msg.sender, vault, amount);
    }

    //@dev pass address(0) for ETH
    function withdrawToken(
        address tokenOut,
        address vault,
        uint256 requestAmtToken,
        uint256 minAmountOut,
        address feeToken
    ) external whitelistedToken(tokenOut) {
        address _tokenOut = tokenOut != address(0) ? tokenOut : wethAddress;
        address vaultAsset;

        (, vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        (uint256 vaultRound, , , , , , , , ) = getVaultState(vault);
        uint256 instantAmt = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[msg.sender]
        );
        S9Proxy(depositors[msg.sender]).withdraw(
            vault,
            vaultAsset,
            requestAmtToken,
            instantAmt
        );
        uint256 result = IERC20(vaultAsset).balanceOf(address(this));
        //We redeposit if there is excess
        if (result > requestAmtToken) {
            uint256 redepositAmt = result - requestAmtToken;
            //We transfer to proxy
            IERC20(vaultAsset).transfer(depositors[msg.sender], redepositAmt);
            S9Proxy(depositors[msg.sender]).deposit(
                vault,
                vaultAsset,
                redepositAmt
            );
            result = requestAmtToken;
        }
        uint256 fee = (IFees(feeContract).calcFee(
            strategyId,
            msg.sender,
            feeToken
        ) * result) / 1000;
        IERC20(vaultAsset).transfer(
            IFees(feeContract).feeCollector(strategyId),
            fee
        );
        result = IERC20(vaultAsset).balanceOf(address(this));
        if (swapHelper[vaultAsset] != address(0)) {
            //expected to always swap to weth
            IERC20(vaultAsset).approve(swapHelper[vaultAsset], result);
            result = ISwapHelper(swapHelper[vaultAsset]).swap(
                vaultAsset,
                wethAddress,
                result,
                minAmountOut,
                address(this)
            );
            vaultAsset = wethAddress;
        }
        if (_tokenOut != vaultAsset) {
            //swap
            IERC20(vaultAsset).approve(swapRouter, result);
            result = ISwapRouter(swapRouter).swapTokenForToken(
                vaultAsset,
                _tokenOut,
                result,
                1,
                address(this)
            );
        }
        require(result >= minAmountOut, "withdrawToken: minAmountOut");
        if (tokenOut != address(0)) {
            IERC20(tokenOut).transfer(
                msg.sender,
                IERC20(tokenOut).balanceOf(address(this))
            );
        } else {
            IWETH(wethAddress).withdraw(result);
            (bool success, ) = payable(msg.sender).call{value: result}("");
            require(success, "withdrawToken: Send ETH fail");
        }
        //fee is in valutAsset
        emit Withdraw(msg.sender, tokenOut, vault, result, fee);
    }

    function stake(address vault) external {
        (uint256 heldByAccount, uint256 heldByVault) = IRibbonVault(vault)
            .shareBalances(depositors[msg.sender]);
        S9Proxy(depositors[msg.sender]).stake(
            vault,
            heldByAccount + heldByVault
        );
        emit Stake(msg.sender, vault, heldByAccount + heldByVault);
    }

    //@dev pass tokenOut as rbn to avoid swap
    function claim(
        address vault,
        address tokenOut,
        uint256 minAmountOut
    ) external whitelistedToken(tokenOut){
        address gauge = IRibbonVault(vault).liquidityGauge();
        address to = tokenOut == rbn ? msg.sender : address(this);
        uint256 claimed = S9Proxy(depositors[msg.sender]).claim(gauge, to);
        emit Claim(msg.sender, vault, claimed);
        if (tokenOut != rbn) {
            IERC20(rbn).approve(swapRouter, claimed);
            //swap to token
            ISwapRouter(swapRouter).swapTokenForToken(
                rbn,
                tokenOut,
                claimed,
                minAmountOut,
                msg.sender
            );
        }
    }

    function emergencyWithdraw(address vault) external {
        require(!IFees(feeContract).depositStatus(strategyId));
        (, address vaultAsset, , ) = IRibbonVault(vault).vaultParams();
        (uint256 vaultRound, , , , , , , , ) = getVaultState(vault);
        uint256 amount = _getDepositReciepts(
            vault,
            vaultRound,
            depositors[msg.sender]
        );
        S9Proxy(depositors[msg.sender]).emergencyWithdraw(
            vault,
            vaultAsset,
            amount
        );
    }

    function toggleVaultWhitelist(address[] calldata vaults, bool state)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < vaults.length; i++) {
            vaultWhitelist[vaults[i]] = state;
        }
    }

    function setHelper(address token, address helper) external onlyOwner {
        swapHelper[token] = helper;
    }

    //internal reads
    function _getDepositReciepts(
        address vault,
        uint256 vaultRound,
        address user
    ) internal view returns (uint256) {
        uint256 available;
        (uint256 round, uint256 depositAmount, ) = IRibbonVault(vault)
            .depositReceipts(user);
        if (vaultRound == round) {
            available += depositAmount;
        }
        return available;
    }

    function _getWithdrawReciepts(
        address vault,
        uint256 vaultRound,
        address user
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 pending;
        uint256 avaliableClaim;
        IRibbonVault rv = IRibbonVault(vault);
        (uint256 round, uint256 withdrawAmount) = rv.withdrawals(user);
        //only pending or avaliableClaim will be possible
        //initiating withdraw when avaliableClaim > 0 will revert
        if (vaultRound > round) {
            avaliableClaim += withdrawAmount;
        }
        if (vaultRound == round) {
            pending += withdrawAmount;
        }
        uint256 withdrawPricePerShare = rv.roundPricePerShare(round);
        return (round, pending, avaliableClaim, withdrawPricePerShare);
    }

    receive() external payable {}
}

pragma solidity >=0.8.17;

// SPDX-License-Identifier: MIT

interface IFees {
    struct FeeTokenData {
        uint256 minBalance;
        uint256 fee;
    }

    //read functions

    function defaultFee() external view returns (uint256);

    function feeCollector(uint256 strategyId) external view returns (address);

    function feeTokenMap(uint256 strategyId, address feeToken)
        external
        view
        returns (FeeTokenData memory);    

    function depositStatus(uint256 strategyId) external view returns (bool);

    function whitelistedDepositCurrencies(uint256, address)
        external
        view
        returns (bool);

    function calcFee(
        uint256 strategyId,
        address user,
        address feeToken
    ) external view returns (uint256);

    //write functions    

    function setTokenFee(
        uint256 strategyId,
        address feeToken,
        uint256 minBalance,
        uint256 fee
    ) external;

    function setTokenMulti(
        uint256 strategyId,
        address[] calldata feeTokens,
        uint256[] calldata minBalance,
        uint256[] calldata fee) external;

    function setDepositStatus(uint256 strategyId, bool status) external;

    function setFeeCollector(address newFeeCollector) external;

    function setDefaultFee(uint newDefaultFee) external;

    function toggleWhitelistTokens(
        uint256 strategyId,
        address[] calldata tokens,
        bool state
    ) external;
}

pragma solidity >=0.8.17;
// SPDX-License-Identifier: MIT

interface ISwapRouter {
    function swapTokenForToken(address _tokenIn, address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapTokenForETH(address _tokenIn, uint256 _amount, uint256 _amountOutMin, address _to) external returns(uint256);
    function swapETHForToken(address _tokenOut, uint256 _amount, uint256 _amountOutMin, address _to) external payable returns(uint256);
    // function swap(address tokenIn, address tokenOut, uint amount, uint minAmountOut, address to) external;
    function _swapV2(address _router, address _tokenIn, uint256 _amount, address _to) external returns(uint256);
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT
interface IWETH {
    function withdraw(uint wad) external;
}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transfer(address recipient, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;

    function decimals() external view returns (uint256);
}

pragma solidity >=0.8.4;

// SPDX-License-Identifier: MIT

interface IRibbonVault {
    //read
    //returns heldByAccount, heldByValut
    //heldByAccount: locked
    //heldByVault: avaliable
    function shareBalances(address account)
        external
        view
        returns (uint256 heldByAccount, uint256 heldByVault);

    //shares: amount pending
    function withdrawals(address account)
        external
        view
        returns (uint256 round, uint256 shares);

    //amount in native token available for withdraw
    function depositReceipts(address account)
        external
        view
        returns (
            uint16 round,
            uint104 amount,
            uint128 unredeemedShares
        );

    //multiplied on UI to show amount staked
    function pricePerShare() external view returns (uint256);

    function vaultState()
        external
        view
        returns (
            uint16 round,
            uint104 lockedAmount,
            uint104 lastLockedAmount,
            uint128 totalPending,
            uint128 queuedWithdrawShares,
            uint64 lastEpochTime,
            uint64 lastOptionPurchaseTime,
            uint128 optionsBoughtInRound,
            uint256 amtFundsReturned
        );

    function allocationState()
        external
        view
        returns (
            uint32 nextLoanTermLength,
            uint32 nextOptionPurchaseFreq,
            uint32 currentLoanTermLength,
            uint32 currentOptionPurchaseFreq,
            uint32 loanAllocationPCT,
            uint32 optionAllocationPCT,
            uint256 loanAllocation,
            uint256 optionAllocation
        );
    
    function vaultParams() external view returns(
        uint8 decimals,
        address asset, 
        uint56 minimumSupply,
        uint104 cap
    );

    function roundPricePerShare(uint round) external view returns(uint pricePerShare);
    function balanceOf(address user) external view returns(uint balanace);
    function decimals() external view returns(uint decimals);
    function liquidityGauge() external view returns(address gaugeAddress);

    //write functions
    function deposit(uint256 amount) external;

    function initiateWithdraw(uint256 numShares) external;

    function withdrawInstantly(uint256 numShares) external;

    function maxRedeem() external;

    function stake(uint amount) external;

    //Used for tests
    function rollToNextRound() external;

    function buyOption() external;

    function completeWithdraw() external;

}

pragma solidity 0.8.17;
// SPDX-License-Identifier: MIT

interface ISwapHelper {
        function swap(
        address tokenIn,
        address tokenOut,
        uint256 amount,
        uint256 minAmountOut,
        address to
    ) external returns (uint256 result);
}

import "../interfaces/IERC20.sol";
import "../interfaces/IRibbonVault.sol";
import "../interfaces/IGauge.sol";
import "../interfaces/IMinter.sol";

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

contract S9Proxy {
    address deployer;
    address user;
    address minter = 0x5B0655F938A72052c46d2e94D206ccB6FF625A3A;
    address rbn = 0x6123B0049F904d730dB3C36a31167D9d4121fA6B;

    constructor(address user_) {
        deployer = msg.sender;
        user = user_;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "onlyDeployer: Unauthorized");
        _;
    }

    function deposit(
        address vault,
        address inputToken,
        uint256 amount
    ) external onlyDeployer {
        IERC20(inputToken).approve(vault, amount);
        IRibbonVault(vault).deposit(amount);
    }

    function queueWithdraw(address vault, uint256 amount)
        external
        onlyDeployer
    {
        address gauge = IRibbonVault(vault).liquidityGauge();
        (uint256 heldByAccount, uint256 heldByVault) = IRibbonVault(vault)
            .shareBalances(address(this));
        uint256 balance = heldByAccount + heldByVault;
        if (amount > balance) {
            uint256 gaugeBalance = IERC20(gauge).balanceOf(address(this));
            if (gaugeBalance > 0) {
                uint256 withdrawAmt = gaugeBalance > amount - balance
                    ? amount - balance
                    : gaugeBalance;
                IGauge(gauge).withdraw(withdrawAmt);
                balance += withdrawAmt;
            }
        } else {
            balance = amount;
        }
        //max redeem done internally
        IRibbonVault(vault).initiateWithdraw(balance);
    }

    function withdraw(
        address vault,
        address vaultAsset,
        //in token
        uint256 requestAmtToken,
        uint256 instantAvaliable
    ) external onlyDeployer returns (uint256) {
        uint256 balance = _withdraw(
            vault,
            vaultAsset,
            requestAmtToken,
            instantAvaliable
        );
        IERC20(vaultAsset).transfer(deployer, balance);
        return balance;
    }

    function stake(address vault, uint256 shares) external onlyDeployer {
        IRibbonVault(vault).stake(shares);
    }

    function claim(address gauge, address to)
        external
        onlyDeployer
        returns (uint256)
    {
        IMinter(minter).mint(gauge);
        uint256 balance = IERC20(rbn).balanceOf(address(this));
        IERC20(rbn).transfer(to, balance);
        return balance;
    }

    function emergencyWithdraw(
        address vault,
        address vaultAsset,
        uint256 instantAvaliable
    ) external onlyDeployer {
        uint256 balance = _withdraw(
            vault,
            vaultAsset,
            2**256 - 1,
            instantAvaliable
        );
        IERC20(vaultAsset).transfer(user, balance);
    }

    function _withdraw(
        address vault,
        address vaultAsset,
        //in token
        uint256 requestAmtToken,
        uint256 instantAvaliable
    ) internal returns (uint256) {
        uint256 balance;
        //Prioritize withdrawing non yielding funds
        //withdraws vaultAsset that was previously initiateWithdraw
        IRibbonVault(vault).completeWithdraw();
        balance = IERC20(vaultAsset).balanceOf(address(this));
        //Withdraw from current deposit that has not been sent to vault
        if (balance < requestAmtToken && instantAvaliable > 0) {
            //withdraw the difference, up to the requested amount
            //will revert R32 if withdrawInstantly round is current round
            //will revert R33 if insufficient
            uint256 withdrawInstantAmt = instantAvaliable >
                requestAmtToken - balance
                ? requestAmtToken - balance
                : instantAvaliable;
            IRibbonVault(vault).withdrawInstantly(withdrawInstantAmt);
            balance = IERC20(vaultAsset).balanceOf(address(this));
        }
        return balance;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IGauge {

    struct CalculateClaimableRbn{
        uint currentDate;
        uint periodTimestamp;
        uint integrateInvSupply;
        uint integrateFraction;
        uint integrateInvSupplyOf;
        uint futureEpochTime;
        uint inflationRate;
        uint rate;
        bool isKilled;
        uint workingSupply;
        uint workingBalance;
        uint mintedRbn;
        address gaugeContractAddress;
        address gaugeControllerContract;
    }

    function period() external view returns(uint128 period);

    function is_killed() external view returns(bool isKilled);

    function totalSupply() external view returns(uint totalSupply);

    function working_balances(address user) external view returns(uint externalBalances);

    function working_supply() external view returns(uint workingSupply);

    function period_timestamp(uint period) external view returns(uint periodTimestamp);    

    function integrate_inv_supply(uint period) external view returns(uint integrateInvSupply);

    function integrate_fraction(address user) external view returns(uint integrateFraction);

    function integrate_inv_supply_of(address user) external view returns(uint integrateSupplyOf);

    function future_epoch_time() external view returns(uint futureEpochTime);

    function inflation_rate() external view returns(uint inflationRate);

    function controller() external view returns(address controller);

    function claim() external;    

    function withdraw(uint amount) external;

}

pragma solidity ^0.8.17;

// SPDX-License-Identifier: MIT

interface IMinter {
    function rate() external view returns(uint rate);
    
    function mint(address toGauge) external;
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