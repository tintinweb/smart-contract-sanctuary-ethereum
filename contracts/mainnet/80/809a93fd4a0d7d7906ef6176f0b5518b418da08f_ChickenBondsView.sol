/**
 *Submitted for verification at Etherscan.io on 2022-10-13
*/

// SPDX-License-Identifier: MIT

pragma solidity =0.8.10;





interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint256 digits);
    function totalSupply() external view returns (uint256 supply);

    function balanceOf(address _owner) external view returns (uint256 balance);

    function transfer(address _to, uint256 _value) external returns (bool success);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);

    function approve(address _spender, uint256 _value) external returns (bool success);

    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}





abstract contract IWETH {
    function allowance(address, address) public virtual view returns (uint256);

    function balanceOf(address) public virtual view returns (uint256);

    function approve(address, uint256) public virtual;

    function transfer(address, uint256) public virtual returns (bool);

    function transferFrom(
        address,
        address,
        uint256
    ) public virtual returns (bool);

    function deposit() public payable virtual;

    function withdraw(uint256) public virtual;
}





library Address {
    //insufficient balance
    error InsufficientBalance(uint256 available, uint256 required);
    //unable to send value, recipient may have reverted
    error SendingValueFail();
    //insufficient balance for call
    error InsufficientBalanceForCall(uint256 available, uint256 required);
    //call to non-contract
    error NonContractCall();
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        uint256 balance = address(this).balance;
        if (balance < amount){
            revert InsufficientBalance(balance, amount);
        }

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        if (!(success)){
            revert SendingValueFail();
        }
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        uint256 balance = address(this).balance;
        if (balance < value){
            revert InsufficientBalanceForCall(balance, value);
        }
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        if (!(isContract(target))){
            revert NonContractCall();
        }

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
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




library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}







library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
    }

    /// @dev Edited so it always first approves 0 and then the value, because of non standard tokens
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, newAllowance)
        );
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}






library TokenUtils {
    using SafeERC20 for IERC20;

    address public constant WETH_ADDR = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function approveToken(
        address _tokenAddr,
        address _to,
        uint256 _amount
    ) internal {
        if (_tokenAddr == ETH_ADDR) return;

        if (IERC20(_tokenAddr).allowance(address(this), _to) < _amount) {
            IERC20(_tokenAddr).safeApprove(_to, _amount);
        }
    }

    function pullTokensIfNeeded(
        address _token,
        address _from,
        uint256 _amount
    ) internal returns (uint256) {
        // handle max uint amount
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, _from);
        }

        if (_from != address(0) && _from != address(this) && _token != ETH_ADDR && _amount != 0) {
            IERC20(_token).safeTransferFrom(_from, address(this), _amount);
        }

        return _amount;
    }

    function withdrawTokens(
        address _token,
        address _to,
        uint256 _amount
    ) internal returns (uint256) {
        if (_amount == type(uint256).max) {
            _amount = getBalance(_token, address(this));
        }

        if (_to != address(0) && _to != address(this) && _amount != 0) {
            if (_token != ETH_ADDR) {
                IERC20(_token).safeTransfer(_to, _amount);
            } else {
                (bool success, ) = _to.call{value: _amount}("");
                require(success, "Eth send fail");
            }
        }

        return _amount;
    }

    function depositWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).deposit{value: _amount}();
    }

    function withdrawWeth(uint256 _amount) internal {
        IWETH(WETH_ADDR).withdraw(_amount);
    }

    function getBalance(address _tokenAddr, address _acc) internal view returns (uint256) {
        if (_tokenAddr == ETH_ADDR) {
            return _acc.balance;
        } else {
            return IERC20(_tokenAddr).balanceOf(_acc);
        }
    }

    function getTokenDecimals(address _token) internal view returns (uint256) {
        if (_token == ETH_ADDR) return 18;

        return IERC20(_token).decimals();
    }
}






interface ITroveManager {
    
    // --- Events ---

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LQTYTokenAddressChanged(address _lqtyTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _LUSDGasCompensation);
    event Redemption(uint _attemptedLUSDAmount, uint _actualLUSDAmount, uint _ETHSent, uint _ETHFee);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event TroveLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event SystemSnapshotsUpdated(uint _totalStakesSnapshot, uint _totalCollateralSnapshot);
    event LTermsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveSnapshotsUpdated(uint _L_ETH, uint _L_LUSDDebt);
    event TroveIndexUpdated(address _borrower, uint _newIndex);

    function getTroveOwnersCount() external view returns (uint);

    function getTroveFromTroveOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);
    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateTroves(uint _n) external;

    function batchLiquidateTroves(address[] calldata _troveArray) external;

    function redeemCollateral(
        uint _LUSDAmount,
        address _firstRedemptionHint,
        address _upperPartialRedemptionHint,
        address _lowerPartialRedemptionHint,
        uint _partialRedemptionHintNICR,
        uint _maxIterations,
        uint _maxFee
    ) external; 

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function updateTroveRewardSnapshots(address _borrower) external;

    function addTroveOwnerToArray(address _borrower) external returns (uint index);

    function applyPendingRewards(address _borrower) external;

    function getPendingETHReward(address _borrower) external view returns (uint);

    function getPendingLUSDDebtReward(address _borrower) external view returns (uint);

     function hasPendingRewards(address _borrower) external view returns (bool);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll, 
        uint pendingLUSDDebtReward, 
        uint pendingETHReward
    );

    function closeTrove(address _borrower) external;

    function removeStake(address _borrower) external;

    function getRedemptionRate() external view returns (uint);
    function getRedemptionRateWithDecay() external view returns (uint);

    function getRedemptionFeeWithDecay(uint _ETHDrawn) external view returns (uint);

    function getBorrowingRate() external view returns (uint);
    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint LUSDDebt) external view returns (uint);
    function getBorrowingFeeWithDecay(uint _LUSDDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getTroveStatus(address _borrower) external view returns (uint);
    
    function getTroveStake(address _borrower) external view returns (uint);

    function getTroveDebt(address _borrower) external view returns (uint);

    function getTroveColl(address _borrower) external view returns (uint);

    function setTroveStatus(address _borrower, uint num) external;

    function increaseTroveColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseTroveColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseTroveDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseTroveDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);
}





interface IBorrowerOperations {

    // --- Events ---

    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event DefaultPoolAddressChanged(address _defaultPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedTrovesAddressChanged(address _sortedTrovesAddress);
    event LUSDTokenAddressChanged(address _lusdTokenAddress);
    event LQTYStakingAddressChanged(address _lqtyStakingAddress);

    event TroveCreated(address indexed _borrower, uint arrayIndex);
    event TroveUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event LUSDBorrowingFeePaid(address indexed _borrower, uint _LUSDFee);

    // --- Functions ---

    function openTrove(uint _maxFee, uint _LUSDAmount, address _upperHint, address _lowerHint) external payable;

    function addColl(address _upperHint, address _lowerHint) external payable;

    function moveETHGainToTrove(address _user, address _upperHint, address _lowerHint) external payable;

    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;

    function withdrawLUSD(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;

    function repayLUSD(uint _amount, address _upperHint, address _lowerHint) external;

    function closeTrove() external;

    function adjustTrove(uint _maxFee, uint _collWithdrawal, uint _debtChange, bool isDebtIncrease, address _upperHint, address _lowerHint) external payable;

    function claimCollateral() external;

    function getCompositeDebt(uint _debt) external pure returns (uint);
}





interface IPriceFeed {
    function lastGoodPrice() external pure returns (uint256);
    function fetchPrice() external returns (uint);
}





interface IHintHelpers {

    function getRedemptionHints(
        uint _LUSDamount, 
        uint _price,
        uint _maxIterations
    )
        external
        view
        returns (
            address firstRedemptionHint,
            uint partialRedemptionHintNICR,
            uint truncatedLUSDamount
        );

    function getApproxHint(uint _CR, uint _numTrials, uint _inputRandomSeed)
        external
        view
        returns (address hintAddress, uint diff, uint latestRandomSeed);

    function computeNominalCR(uint _coll, uint _debt) external pure returns (uint);

    function computeCR(uint _coll, uint _debt, uint _price) external pure returns (uint);
}





interface ISortedTroves {

    // --- Events ---
    
    event SortedTrovesAddressChanged(address _sortedDoublyLLAddress);
    event BorrowerOperationsAddressChanged(address _borrowerOperationsAddress);
    event NodeAdded(address _id, uint _NICR);
    event NodeRemoved(address _id);

    // --- Functions ---
    
    function setParams(uint256 _size, address _TroveManagerAddress, address _borrowerOperationsAddress) external;

    function insert(address _id, uint256 _ICR, address _prevId, address _nextId) external;

    function remove(address _id) external;

    function reInsert(address _id, uint256 _newICR, address _prevId, address _nextId) external;

    function contains(address _id) external view returns (bool);

    function isFull() external view returns (bool);

    function isEmpty() external view returns (bool);

    function getSize() external view returns (uint256);

    function getMaxSize() external view returns (uint256);

    function getFirst() external view returns (address);

    function getLast() external view returns (address);

    function getNext(address _id) external view returns (address);

    function getPrev(address _id) external view returns (address);

    function validInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (bool);

    function findInsertPosition(uint256 _ICR, address _prevId, address _nextId) external view returns (address, address);
}




interface ICollSurplusPool {

    // --- Events ---
    
    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);

    event CollBalanceUpdated(address indexed _account, uint _newBalance);
    event EtherSent(address _to, uint _amount);

    // --- Contract setters ---

    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress
    ) external;

    function getETH() external view returns (uint);

    function getCollateral(address _account) external view returns (uint);

    function accountSurplus(address _account, uint _amount) external;

    function claimColl(address _account) external;
}




interface IStabilityPool {

    // --- Events ---
    
    event StabilityPoolETHBalanceUpdated(uint _newBalance);
    event StabilityPoolLUSDBalanceUpdated(uint _newBalance);

    event BorrowerOperationsAddressChanged(address _newBorrowerOperationsAddress);
    event TroveManagerAddressChanged(address _newTroveManagerAddress);
    event ActivePoolAddressChanged(address _newActivePoolAddress);
    event DefaultPoolAddressChanged(address _newDefaultPoolAddress);
    event LUSDTokenAddressChanged(address _newLUSDTokenAddress);
    event SortedTrovesAddressChanged(address _newSortedTrovesAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event CommunityIssuanceAddressChanged(address _newCommunityIssuanceAddress);

    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);

    event FrontEndRegistered(address indexed _frontEnd, uint _kickbackRate);
    event FrontEndTagSet(address indexed _depositor, address indexed _frontEnd);

    event DepositSnapshotUpdated(address indexed _depositor, uint _P, uint _S, uint _G);
    event FrontEndSnapshotUpdated(address indexed _frontEnd, uint _P, uint _G);
    event UserDepositChanged(address indexed _depositor, uint _newDeposit);
    event FrontEndStakeChanged(address indexed _frontEnd, uint _newFrontEndStake, address _depositor);

    event ETHGainWithdrawn(address indexed _depositor, uint _ETH, uint _LUSDLoss);
    event LQTYPaidToDepositor(address indexed _depositor, uint _LQTY);
    event LQTYPaidToFrontEnd(address indexed _frontEnd, uint _LQTY);
    event EtherSent(address _to, uint _amount);

    // --- Functions ---

    /*
     * Called only once on init, to set addresses of other Liquity contracts
     * Callable only by owner, renounces ownership at the end
     */
    function setAddresses(
        address _borrowerOperationsAddress,
        address _troveManagerAddress,
        address _activePoolAddress,
        address _lusdTokenAddress,
        address _sortedTrovesAddress,
        address _priceFeedAddress,
        address _communityIssuanceAddress
    ) external;

    /*
     * Initial checks:
     * - Frontend is registered or zero address
     * - Sender is not a registered frontend
     * - _amount is not zero
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Tags the deposit with the provided front end tag param, if it's a new deposit
     * - Sends depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Increases deposit and tagged front end's stake, and takes new snapshots for each.
     */
    function provideToSP(uint _amount, address _frontEndTag) external;

    /*
     * Initial checks:
     * - _amount is zero or there are no under collateralized troves left in the system
     * - User has a non zero deposit
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Removes the deposit's front end tag if it is a full withdrawal
     * - Sends all depositor's accumulated gains (LQTY, ETH) to depositor
     * - Sends the tagged front end's accumulated LQTY gains to the tagged front end
     * - Decreases deposit and tagged front end's stake, and takes new snapshots for each.
     *
     * If _amount > userDeposit, the user withdraws all of their compounded deposit.
     */
    function withdrawFromSP(uint _amount) external;

    /*
     * Initial checks:
     * - User has a non zero deposit
     * - User has an open trove
     * - User has some ETH gain
     * ---
     * - Triggers a LQTY issuance, based on time passed since the last issuance. The LQTY issuance is shared between *all* depositors and front ends
     * - Sends all depositor's LQTY gain to  depositor
     * - Sends all tagged front end's LQTY gain to the tagged front end
     * - Transfers the depositor's entire ETH gain from the Stability Pool to the caller's trove
     * - Leaves their compounded deposit in the Stability Pool
     * - Updates snapshots for deposit and tagged front end stake
     */
    function withdrawETHGainToTrove(address _upperHint, address _lowerHint) external;

    /*
     * Initial checks:
     * - Frontend (sender) not already registered
     * - User (sender) has no deposit
     * - _kickbackRate is in the range [0, 100%]
     * ---
     * Front end makes a one-time selection of kickback rate upon registering
     */
    function registerFrontEnd(uint _kickbackRate) external;

    /*
     * Initial checks:
     * - Caller is TroveManager
     * ---
     * Cancels out the specified debt against the LUSD contained in the Stability Pool (as far as possible)
     * and transfers the Trove's ETH collateral from ActivePool to StabilityPool.
     * Only called by liquidation functions in the TroveManager.
     */
    function offset(uint _debt, uint _coll) external;

    /*
     * Returns the total amount of ETH held by the pool, accounted in an internal variable instead of `balance`,
     * to exclude edge cases like ETH received from a self-destruct.
     */
    function getETH() external view returns (uint);

    /*
     * Returns LUSD held in the pool. Changes when users deposit/withdraw, and when Trove debt is offset.
     */
    function getTotalLUSDDeposits() external view returns (uint);

    /*
     * Calculates the ETH gain earned by the deposit since its last snapshots were taken.
     */
    function getDepositorETHGain(address _depositor) external view returns (uint);

    /*
     * Calculate the LQTY gain earned by a deposit since its last snapshots were taken.
     * If not tagged with a front end, the depositor gets a 100% cut of what their deposit earned.
     * Otherwise, their cut of the deposit's earnings is equal to the kickbackRate, set by the front end through
     * which they made their deposit.
     */
    function getDepositorLQTYGain(address _depositor) external view returns (uint);

    /*
     * Return the LQTY gain earned by the front end.
     */
    function getFrontEndLQTYGain(address _frontEnd) external view returns (uint);

    /*
     * Return the user's compounded deposit.
     */
    function getCompoundedLUSDDeposit(address _depositor) external view returns (uint);

    /*
     * Return the front end's compounded stake.
     *
     * The front end's compounded stake is equal to the sum of its depositors' compounded deposits.
     */
    function getCompoundedFrontEndStake(address _frontEnd) external view returns (uint);
}





interface ILQTYStaking {

    // --- Events --
    
    event LQTYTokenAddressSet(address _lqtyTokenAddress);
    event LUSDTokenAddressSet(address _lusdTokenAddress);
    event TroveManagerAddressSet(address _troveManager);
    event BorrowerOperationsAddressSet(address _borrowerOperationsAddress);
    event ActivePoolAddressSet(address _activePoolAddress);

    event StakeChanged(address indexed staker, uint newStake);
    event StakingGainsWithdrawn(address indexed staker, uint LUSDGain, uint ETHGain);
    event F_ETHUpdated(uint _F_ETH);
    event F_LUSDUpdated(uint _F_LUSD);
    event TotalLQTYStakedUpdated(uint _totalLQTYStaked);
    event EtherSent(address _account, uint _amount);
    event StakerSnapshotsUpdated(address _staker, uint _F_ETH, uint _F_LUSD);

    // --- Functions ---

    function setAddresses
    (
        address _lqtyTokenAddress,
        address _lusdTokenAddress,
        address _troveManagerAddress, 
        address _borrowerOperationsAddress,
        address _activePoolAddress
    )  external;

    function stake(uint _LQTYamount) external;

    function unstake(uint _LQTYamount) external;

    function increaseF_ETH(uint _ETHFee) external; 

    function increaseF_LUSD(uint _LQTYFee) external;  

    function getPendingETHGain(address _user) external view returns (uint);

    function getPendingLUSDGain(address _user) external view returns (uint);

    function stakes(address) external view returns (uint256);
}






interface IChickenBondManager {
    // Valid values for `status` returned by `getBondData()`
    enum BondStatus {
        nonExistent,
        active,
        chickenedOut,
        chickenedIn
    }

    struct BondData {
        uint256 lusdAmount;
        uint64 claimedBLUSD; // In BLUSD units without decimals
        uint64 startTime;
        uint64 endTime; // Timestamp of chicken in/out event
        BondStatus status;
    }

    function lusdToken() external view returns (address);
    function bLUSDToken() external view returns (address);
    function curvePool() external view returns (address);
    function bammSPVault() external view returns (address);
    function yearnCurveVault() external view returns (address);

    function countChickenIn() external view returns (uint256);
    function countChickenOut() external view returns (uint256);

    // constants
    function INDEX_OF_LUSD_TOKEN_IN_CURVE_POOL() external pure returns (int128);
    function CHICKEN_IN_AMM_FEE() external view returns (uint256);

    function createBond(uint256 _lusdAmount) external returns (uint256);
    function createBondWithPermit(
        address owner, 
        uint256 amount, 
        uint256 deadline, 
        uint8 v, 
        bytes32 r, 
        bytes32 s
    ) external  returns (uint256);
    function chickenOut(uint256 _bondID, uint256 _minLUSD) external;
    function chickenIn(uint256 _bondID) external;
    function redeem(uint256 _bLUSDToRedeem, uint256 _minLUSDFromBAMMSPVault) external returns (uint256, uint256);

    // getters
    function calcRedemptionFeePercentage(uint256 _fractionOfBLUSDToRedeem) external view returns (uint256);
    function getBondData(uint256 _bondID) external view returns (BondData memory);
    function getLUSDToAcquire(uint256 _bondID) external view returns (uint256);
    function calcAccruedBLUSD(uint256 _bondID) external view returns (uint256);
    function calcBondBLUSDCap(uint256 _bondID) external view returns (uint256);
    function getLUSDInBAMMSPVault() external view returns (uint256);
    function calcTotalYearnCurveVaultShareValue() external view returns (uint256);
    function calcTotalLUSDValue() external view returns (uint256);
    function getPendingLUSD() external view returns (uint256);
    function getAcquiredLUSDInSP() external view returns (uint256);
    function getAcquiredLUSDInCurve() external view returns (uint256);
    function getTotalAcquiredLUSD() external view returns (uint256);
    function getPermanentLUSD() external view returns (uint256);
    function getOwnedLUSDInSP() external view returns (uint256);
    function getOwnedLUSDInCurve() external view returns (uint256);
    function calcSystemBackingRatio() external view returns (uint256);
    function calcUpdatedAccrualParameter() external view returns (uint256);
    function getBAMMLUSDDebt() external view returns (uint256);
    function getOpenBondCount() external view returns (uint256);
    function getTreasury()
        external
        view
        returns (
            uint256 _pendingLUSD,
            uint256 _totalAcquiredLUSD,
            uint256 _permanentLUSD
        );
}




contract MainnetLiquityAddresses {
    address internal constant LUSD_TOKEN_ADDRESS = 0x5f98805A4E8be255a32880FDeC7F6728C6568bA0;
    address internal constant LQTY_TOKEN_ADDRESS = 0x6DEA81C8171D0bA574754EF6F8b412F2Ed88c54D;
    address internal constant PRICE_FEED_ADDRESS = 0x4c517D4e2C851CA76d7eC94B805269Df0f2201De;
    address internal constant BORROWER_OPERATIONS_ADDRESS = 0x24179CD81c9e782A4096035f7eC97fB8B783e007;
    address internal constant TROVE_MANAGER_ADDRESS = 0xA39739EF8b0231DbFA0DcdA07d7e29faAbCf4bb2;
    address internal constant SORTED_TROVES_ADDRESS = 0x8FdD3fbFEb32b28fb73555518f8b361bCeA741A6;
    address internal constant HINT_HELPERS_ADDRESS = 0xE84251b93D9524E0d2e621Ba7dc7cb3579F997C0;
    address internal constant COLL_SURPLUS_POOL_ADDRESS = 0x3D32e8b97Ed5881324241Cf03b2DA5E2EBcE5521;
    address internal constant STABILITY_POOL_ADDRESS = 0x66017D22b0f8556afDd19FC67041899Eb65a21bb;
    address internal constant LQTY_STAKING_ADDRESS = 0x4f9Fbb3f1E99B56e0Fe2892e623Ed36A76Fc605d;
    address internal constant LQTY_FRONT_END_ADDRESS = 0x76720aC2574631530eC8163e4085d6F98513fb27;
    
    address internal constant CB_MANAGER_ADDRESS = 0x57619FE9C539f890b19c61812226F9703ce37137;
    address internal constant BLUSD_ADDRESS = 0xB9D7DdDca9a4AC480991865EfEf82E01273F79C3;
    address internal constant BOND_NFT_ADDRESS = 0xa8384862219188a8f03c144953Cf21fc124029Ee;
}















contract LiquityHelper is MainnetLiquityAddresses {
    using TokenUtils for address;

    uint constant public LUSD_GAS_COMPENSATION = 200e18;

    IPriceFeed constant public PriceFeed = IPriceFeed(PRICE_FEED_ADDRESS);
    IBorrowerOperations constant public BorrowerOperations = IBorrowerOperations(BORROWER_OPERATIONS_ADDRESS);
    ITroveManager constant public TroveManager = ITroveManager(TROVE_MANAGER_ADDRESS);
    ISortedTroves constant public SortedTroves = ISortedTroves(SORTED_TROVES_ADDRESS);
    IHintHelpers constant public HintHelpers = IHintHelpers(HINT_HELPERS_ADDRESS);
    ICollSurplusPool constant public CollSurplusPool = ICollSurplusPool(COLL_SURPLUS_POOL_ADDRESS);
    IStabilityPool constant public StabilityPool = IStabilityPool(STABILITY_POOL_ADDRESS);
    ILQTYStaking constant public LQTYStaking = ILQTYStaking(LQTY_STAKING_ADDRESS);
    IChickenBondManager constant public CBManager = IChickenBondManager(CB_MANAGER_ADDRESS);

    function withdrawStaking(uint256 _ethGain, uint256 _lusdGain, address _wethTo, address _lusdTo) internal {
        if (_ethGain > 0) {
            TokenUtils.depositWeth(_ethGain);
            TokenUtils.WETH_ADDR.withdrawTokens(_wethTo, _ethGain);
        }
        if (_lusdGain > 0) {
            LUSD_TOKEN_ADDRESS.withdrawTokens(_lusdTo, _lusdGain);
        }
    }
    
    function withdrawStabilityGains(uint256 _ethGain, uint256 _lqtyGain, address _wethTo, address _lqtyTo) internal {
        if (_ethGain > 0) {
            TokenUtils.depositWeth(_ethGain);
            TokenUtils.WETH_ADDR.withdrawTokens(_wethTo, _ethGain);
        }      
        if (_lqtyGain > 0) {
            LQTY_TOKEN_ADDRESS.withdrawTokens(_lqtyTo, _lqtyGain);
        }
    }
}





interface IERC721 {
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool _approved) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}





interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
}





interface IBondNFT is IERC721Enumerable {
    
    struct BondExtraData {
        uint80 initialHalfDna;
        uint80 finalHalfDna;
        uint32 troveSize;         // Debt in LUSD
        uint32 lqtyAmount;        // Holding LQTY, staking or deposited into Pickle
        uint32 curveGaugeSlopes;  // For 3CRV and Frax pools combined
    }

    function getBondAmount(uint256 _tokenID) external view returns (uint256 amount);
    function getBondStartTime(uint256 _tokenID) external view returns (uint256 startTime);
    function getBondEndTime(uint256 _tokenID) external view returns (uint256 endTime);
    function getBondInitialHalfDna(uint256 _tokenID) external view returns (uint80 initialHalfDna);
    function getBondInitialDna(uint256 _tokenID) external view returns (uint256 initialDna);
    function getBondFinalHalfDna(uint256 _tokenID) external view returns (uint80 finalHalfDna);
    function getBondFinalDna(uint256 _tokenID) external view returns (uint256 finalDna);
    function getBondStatus(uint256 _tokenID) external view returns (uint8 status);
    function getBondExtraData(uint256 _tokenID) external view returns (BondExtraData memory);
    function tokenURI(uint256 _tokenID) external view returns (string memory);
}





interface IBondNFTArtwork {
    function tokenURI(uint256 _tokenID, IBondNFT.BondExtraData calldata _bondExtraData) external view returns (string memory);
}









contract ChickenBondsView is LiquityHelper {

    struct BondDataFull {
        uint256 bondID; // ERC721 token id
        uint256 lusdAmount; // Lusd amount entered in the bond
        uint64 claimedBLUSD; // In BLUSD units without decimals
        uint256 accruedBLUSD; // Amount of blusd accrued when in active phase
        uint256 maxAmountBLUSD; // Max cap amount of blusd the bond can accrue
        uint64 startTime; // Timestamp when bond is created
        uint64 endTime; // Timestamp of chicken in/out event
        IChickenBondManager.BondStatus status; // [nonExistent = 0, active = 1, chickenedOut = 2, chickenedIn = 3]
        string tokenURI; // json data of token image
    }

    struct ChickenBondsSystemInfo {
        uint256 totalPendingLUSD;
        uint256 totalReserveLUSD;
        uint256 totalPermanentLUSD;
        uint256 ownedLUSDInSP; // protocolOwnedLusdInStabilityPool
        uint256 ownedLUSDInCurve; // protocolLusdInCurve
        uint256 systemBackingRatio;
        uint256 accrualParameter;
        uint256 chickenInAMMFee;
        uint256 numPendingBonds;
        uint256 numChickenInBonds;
        uint256 numChickenOutBonds;
        uint256 bLUSDSupply;
    }

    function getBondFullInfo(uint256 _bondID) public view returns (BondDataFull memory bond) {
        IBondNFT bondNFT = IBondNFT(BOND_NFT_ADDRESS);

        IChickenBondManager.BondData memory bondData = CBManager.getBondData(_bondID);

        string memory tokenUri = bondNFT.tokenURI(_bondID);

        bond = BondDataFull({
            bondID: _bondID,
            lusdAmount: bondData.lusdAmount,
            claimedBLUSD: bondData.claimedBLUSD,
            accruedBLUSD: CBManager.calcAccruedBLUSD(_bondID),
            maxAmountBLUSD: CBManager.calcBondBLUSDCap(_bondID),
            startTime: bondData.startTime,
            endTime: bondData.endTime,
            status: bondData.status,
            tokenURI: tokenUri
        });
    }

    function getUsersBonds(address _userAddr) public view returns (BondDataFull[] memory bonds) {
        IBondNFT bondNFT = IBondNFT(BOND_NFT_ADDRESS);

        uint numTokens = bondNFT.balanceOf(_userAddr);
        bonds = new BondDataFull[](numTokens);

        for (uint256 i = 0; i < numTokens; ++i) {
            uint256 bondID = bondNFT.tokenOfOwnerByIndex(_userAddr, i);

            bonds[i] = getBondFullInfo(bondID);
        }
    }

    function getSystemInfo() public view returns (ChickenBondsSystemInfo memory systemInfo) {
        (uint256 totalPendingLUSD, uint256 totalReserveLUSD, uint256 totalPermanentLUSD) = CBManager.getTreasury();

        systemInfo = ChickenBondsSystemInfo({
            totalPendingLUSD: totalPendingLUSD,
            totalReserveLUSD: totalReserveLUSD,
            totalPermanentLUSD: totalPermanentLUSD,
            ownedLUSDInSP: CBManager.getOwnedLUSDInSP(),
            ownedLUSDInCurve: CBManager.getOwnedLUSDInCurve(),
            systemBackingRatio: CBManager.calcSystemBackingRatio(),
            accrualParameter: CBManager.calcUpdatedAccrualParameter(),
            chickenInAMMFee: CBManager.CHICKEN_IN_AMM_FEE(),
            numPendingBonds: CBManager.getOpenBondCount(),
            numChickenInBonds: CBManager.countChickenIn(),
            numChickenOutBonds: CBManager.countChickenOut(),
            bLUSDSupply: IERC20(BLUSD_ADDRESS).totalSupply()
        });
    }
}