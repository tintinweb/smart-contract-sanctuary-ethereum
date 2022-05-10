// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

import "IStabilityPool.sol";
import "IUSDCToken.sol";
import "IoUSDCToken.sol";
import "IoMATICToken.sol";
import "IVaultManager.sol";
import "ICommunityIssuance.sol";
import "IActivePool.sol";
import "IBorrowerOps.sol";
import "IMockUSDCStaker.sol";

contract StabilityPool is IStabilityPool, Ownable {
    address borrowerOpsAddress;
    address rewardsPoolAddress;
    address externalStakingAddress;

    IUSDCToken public usdc_token;
    IoMATICToken public oMATICToken;
    IVaultManager public vaultManager;
    ICommunityIssuance public communityIssuance;
    IActivePool public activePool;
    IBorrowerOps public borrowerOps;
    IoUSDCToken public oUSDCToken;
    IMockUSDCStaker usdcStaker;

    // Token tracking variables
    uint256 public USDC_Lent;
    uint256 internal MATIC;
    uint256 internal oMATIC;

    // Constants
    uint constant public DECIMAL_PRECISION = 1e18;
    uint constant public USDC_DECIMAL_PRECISION = 1e6;
    uint constant public MIN_USDC_REQUIRED = 60e6;
    uint256 public constant SCALE_FACTOR = 1e9;

    // Error trackers for the error correction in the offset calculation
    uint256 public lastOrumError;

    // Rewards tracker
    mapping(address => uint256) rewards;
    mapping(uint128 => mapping(uint128 => uint256)) public epochToScaleToG;

    // Each time the scale of P shifts by SCALE_FACTOR, the scale is incremented by 1
    uint128 public currentScale;
    // With each offset that fully empties the Pool, the epoch is incremented by 1
    uint128 public currentEpoch;


    // Rewards snapshots
    struct Snapshots {
        uint P;
        uint G;
        uint128 scale;
        uint128 epoch;
    }
    uint256 public P = DECIMAL_PRECISION;
    mapping (address => uint) public deposits;  // depositor address -> deposited amount
    mapping (address => Snapshots) public depositSnapshots;  // depositor address -> snapshots struct

    // Utilisation ratios
    uint public borrowingUTR ;
    uint public depositorUTR ;

    function setAddresses(
        address _usdcTokenAddress,
        address _borrowerOpsAddress,
        address _oMATICToken,
        address _vaultManagerAddress,
        address _communityIssuanceAddress,
        address _activePoolAddress,
        address _rewardsPoolAddress,
        address _oUSDCToken
    ) 
    external 
    onlyOwner
    {
        usdc_token = IUSDCToken(_usdcTokenAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);
        oMATICToken = IoMATICToken(_oMATICToken);
        borrowerOpsAddress = _borrowerOpsAddress;
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        activePool = IActivePool(_activePoolAddress);
        rewardsPoolAddress = _rewardsPoolAddress;
        borrowerOps = IBorrowerOps(_borrowerOpsAddress);
        oUSDCToken = IoUSDCToken(_oUSDCToken);

        emit USDCTokenAddressChanged(_usdcTokenAddress);
    }

    // --- Getters for public variables. ---


    function getUSDCDeposits() external view override returns (uint) {
        return USDC_Lent + usdc_token.balanceOf(externalStakingAddress);
    }

    function getOMATICRewards() external view returns (uint) {
        return oMATIC;
    }

    // --- External USDC staking address ---
    function setExternalStaker(address _address) external {
        usdcStaker = IMockUSDCStaker(_address);
        externalStakingAddress = _address;
    }

    // StabilityPool interaction functions

    function withdrawFromStabilityPool(uint _amount) external override {
        require(oUSDCToken.balanceOf(msg.sender) >= _amount, "StabilityPool: Insufficient oUSDC balance");

        uint oUSDCBalance = oUSDCToken.balanceOf(msg.sender);
        uint initialDeposit = convertOUSDCToUSDC(oUSDCBalance);
        require(initialDeposit > 0, "StabilityPool: Initial deposit is 0");

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);
        _payOutOrumGains(communityIssuanceCached, msg.sender);

        // Transfer of USDC to depositor
        uint USDCAmount = convertOUSDCToUSDC(_amount);
        _sendUSDCToDepositor(msg.sender, USDCAmount);

        // Update deposit
        uint newDeposit = initialDeposit - USDCAmount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
    }

    function provideToStabilityPool(uint256 _amount) external override {
        bool allow = _allowDeposit();
        require(allow, "StabilityPool: Stable coin deposit not allowed");
        require(usdc_token.balanceOf(msg.sender) >= _amount, "StabilityPol: Insufficient USDC balance");

        // Current USDC deposit based on updated CR
        uint oUSDCBalance = oUSDCToken.balanceOf(msg.sender);
        uint initialDeposit = convertOUSDCToUSDC(oUSDCBalance);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);
        _payOutOrumGains(communityIssuanceCached, msg.sender);

        //Stable coin transfer from lender to SP
        _sendUSDCtoStabilityPool(msg.sender, externalStakingAddress, _amount);

        // Transfer of oUSDC to depositor
        uint oUSDCAmount = convertUSDCToOUSDC(_amount);
        oUSDCToken.mint(msg.sender, oUSDCAmount);

        // Update deposit
        uint newDeposit = initialDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);
    }

    // Borrowing related functions

    function sendUSDCtoBorrower(
        address _to,
        uint256 _amount
    ) external override {
        _requireCallerIsBorrowerOps();
        // emit ActivePooloMATICBalanceUpdated();
        emit USDCSent(_to, _amount);

        if (_amount > 0) {
            bool sucess = usdc_token.transferFrom(externalStakingAddress, _to, _amount);
            require(sucess, "Stability Pool: sendUSDCtoBorrower failed");
            USDC_Lent += _amount;
            emit SentoMATICStabilityPool(_to, _amount);
        }
    }

    function decreaseLentAmount(uint256 _amount) external override {
        USDC_Lent -= _amount;
    }

    // Send USDC to user and decrease USDC in Pool
    function _sendUSDCToDepositor(address _depositor, uint USDCWithdrawal) internal {
        if (USDCWithdrawal == 0) {return;}
        usdcStaker.transferUSDC(USDCWithdrawal, _depositor);
    }

    // Transfer the USDC tokens from the user to the Stability Pool's address, and update its recorded USDC
    function _sendUSDCtoStabilityPool(address _sender, address _address, uint _amount) internal {
        usdc_token.transferFrom(_sender, _address, _amount);
    }

    // USDC - oUSDC conversion functions
    function convertOUSDCToUSDC(uint _amount) public view override returns (uint) {
        uint CR = getConversionRate();

        uint USDCAmount = (_amount * CR) / USDC_DECIMAL_PRECISION;
        return USDCAmount;
    }

    function convertUSDCToOUSDC(uint _amount) public view override returns (uint) {
        uint CR = getConversionRate();

        uint oUSDCAmount = (_amount * USDC_DECIMAL_PRECISION) / CR;
        return oUSDCAmount;
    }

    function getConversionRate() public view returns (uint) {
        uint totalUSDC = USDC_Lent + usdc_token.balanceOf(externalStakingAddress);
        uint totalOUSDC = oUSDCToken.totalSupply();

        uint CR = totalUSDC == 0 || totalOUSDC == 0 ? USDC_DECIMAL_PRECISION : (totalUSDC * USDC_DECIMAL_PRECISION) / totalOUSDC;
        return CR;  
    }

    // Utilisation ratio functions
    function getUtilisationRatio() external view override returns (uint) {
        return _getUtilisationRatio();
    }

    function _getUtilisationRatio() internal view returns (uint) {
        uint totalUSDC = USDC_Lent + usdc_token.balanceOf(externalStakingAddress);
        uint utilisationRatio = totalUSDC == 0 ? 100 * DECIMAL_PRECISION : (USDC_Lent * 100 * DECIMAL_PRECISION) / totalUSDC;
        return utilisationRatio;
    }

    function allowBorrow() external view override returns (bool) {
        bool allowed;
        uint256 utilisationRatio;

        utilisationRatio = _getUtilisationRatio();
        allowed = utilisationRatio >= (borrowingUTR * DECIMAL_PRECISION) ? false : true;

        return allowed;
    }

    function allowDeposit() external view returns (bool) {
        return _allowDeposit();
    }

    function _allowDeposit() internal view returns (bool) {
        uint256 utilisationRatio;
        bool allow;
        utilisationRatio = _getUtilisationRatio();

        allow = utilisationRatio >= (depositorUTR * DECIMAL_PRECISION) || usdc_token.balanceOf(externalStakingAddress) < MIN_USDC_REQUIRED ? true : false;
        return allow;
    }

    // --- Rewards offset functions ---
    function rewardsOffset(uint _rewards) external override {
        // Transfer rewards to external staking address
        usdc_token.transfer(externalStakingAddress, _rewards);
    }

    // --- ORUM issuance functions ---

    function _triggerOrumIssuance(ICommunityIssuance _communityIssuance)
        internal
    {
        uint256 orumIssuance = _communityIssuance.issueOrum();
        _updateG(orumIssuance);
    }

    function _updateG(uint256 _orumIssuance) internal {
        uint256 totalUSDC = USDC_Lent + usdc_token.balanceOf(externalStakingAddress); // cached to save an SLOAD
        /*
         * When total deposits is 0, G is not updated. In this case, the ORUM issued can not be obtained by later
         * depositors - it is missed out on, and remains in the balanceof the CommunityIssuance contract.
         *
         */
        if (totalUSDC == 0 || _orumIssuance == 0) {
            return;
        }

        uint256 orumPerUnitStaked;
        orumPerUnitStaked = _computeOrumPerUnitStaked(_orumIssuance, totalUSDC);

        uint256 marginalOrumGain = orumPerUnitStaked * P;
        epochToScaleToG[currentEpoch][currentScale] = epochToScaleToG[currentEpoch][currentScale] + marginalOrumGain;

        emit G_Updated(
            epochToScaleToG[currentEpoch][currentScale],
            currentEpoch,
            currentScale
        );
    }

    function _computeOrumPerUnitStaked(
        uint256 _orumIssuance,
        uint256 _totalUSDCDeposits
    ) internal returns (uint256) {
        /*
         * Calculate the ORUM-per-unit staked.  Division uses a "feedback" error correction, to keep the
         * cumulative error low in the running total G:
         *
         * 1) Form a numerator which compensates for the floor division error that occurred the last time this
         * function was called.
         * 2) Calculate "per-unit-staked" ratio.
         * 3) Multiply the ratio back by its denominator, to reveal the current floor division error.
         * 4) Store this error for use in the next correction when this function is called.
         * 5) Note: static analysis tools complain about this "division before multiplication", however, it is intended.
         */
        uint256 orumNumerator = (_orumIssuance * DECIMAL_PRECISION) +
            lastOrumError;

        uint256 orumPerUnitStaked = (orumNumerator / _totalUSDCDeposits);
        lastOrumError =
            orumNumerator -
            (orumPerUnitStaked * _totalUSDCDeposits);

        return orumPerUnitStaked;
    }

    function _requireCallerIsVaultManager() internal view {
        require(
            msg.sender == address(vaultManager),
            "StabilityPool: Caller is not VaultManager"
        );
    }

    // Utilisation ratio setter functions
    function setBorrowingUtilisationRatio(uint _ratio) external onlyOwner {
        require(_ratio >= 0 && _ratio <= 100, "StabilityPool: Borrowing utilisation ratio change invalid");
        borrowingUTR = _ratio;
    }

    function setDepositUtilisationRatio(uint _ratio) external onlyOwner {
        require(_ratio >= 0 && _ratio <= 100, "StabilityPool: Deposit utilisation ratio change invalid");
        depositorUTR = _ratio;
    }

    function _requireCallerIsVaultManagerOrRewardsPool() internal view {
        require(
            msg.sender == address(vaultManager) || msg.sender == address(rewardsPoolAddress),
            "StabilityPool: Caller is not VaultManager or RewardsPool"
        );
    }

    function _payOutOrumGains(ICommunityIssuance _communityIssuance, address _depositor) internal {
        // Pay out depositor's ORUM gain
        uint depositorOrumGain = getDepositorOrumGain(_depositor);
        _communityIssuance.sendOrum(_depositor, depositorOrumGain);
    }

    /*
    * Calculate the ORUM gain earned by a deposit since its last snapshots were taken.
    * Given by the formula:  ORUM = d0 * (G - G(0))/P(0)
    * where G(0) and P(0) are the depositor's snapshots of the sum G and product P, respectively.
    * d0 is the last recorded deposit value.
    */
    function getDepositorOrumGain(address _depositor) public view override returns (uint) {
        uint initialDeposit = deposits[_depositor];
        if (initialDeposit == 0) {return 0;}

        Snapshots memory snapshots = depositSnapshots[_depositor];

        uint orumGain = _getOrumGainFromSnapshots(initialDeposit, snapshots);

        return orumGain;
    }

    function _getOrumGainFromSnapshots(uint initialStake, Snapshots memory snapshots) internal view returns (uint) {
       /*
        * Grab the sum 'G' from the epoch at which the stake was made. The ORUM gain may span up to one scale change.
        * If it does, the second portion of the ORUM gain is scaled by 1e9.
        * If the gain spans no scale change, the second portion will be 0.
        */
        uint128 epochSnapshot = snapshots.epoch;
        uint128 scaleSnapshot = snapshots.scale;
        uint G_Snapshot = snapshots.G;
        uint P_Snapshot = snapshots.P;

        uint firstPortion = epochToScaleToG[epochSnapshot][scaleSnapshot] - G_Snapshot;
        uint secondPortion = epochToScaleToG[epochSnapshot][scaleSnapshot + 1] / SCALE_FACTOR;

        uint orumGain = (initialStake * (firstPortion + secondPortion)) / P_Snapshot / DECIMAL_PRECISION;

        return orumGain;
    }

    // --- Stability Pool Deposit Functionality ---
    function _updateDepositAndSnapshots(address _depositor, uint _newValue) internal {
        deposits[_depositor] = _newValue;

        if (_newValue == 0) {
            delete depositSnapshots[_depositor];
            emit DepositSnapshotUpdated(_depositor, 0, 0);
            return;
        }
        uint128 currentScaleCached = currentScale;
        uint128 currentEpochCached = currentEpoch;
        uint currentP = P;

        // Get S and G for the current epoch and current scale
        uint currentG = epochToScaleToG[currentEpochCached][currentScaleCached];

        // Record new snapshots of the latest running product P and sum S for the depositor
        depositSnapshots[_depositor].P = currentP;
        depositSnapshots[_depositor].G = currentG;
        depositSnapshots[_depositor].scale = currentScaleCached;
        depositSnapshots[_depositor].epoch = currentEpochCached;

        emit DepositSnapshotUpdated(_depositor, currentP, currentG);
    }

    function _requireCallerIsBorrowerOps() internal view {
        require(
            msg.sender == borrowerOpsAddress,
            "StabilityPool: Caller is not BorrowerOps"
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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

pragma solidity >=0.8.0;

import "IUSDCToken.sol";

interface IStabilityPool {
    // Events
    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event StabilityPoolUSDCBalanceUpdated(uint _newBalance);
    event StabilityPoolReceivedMATIC(uint value);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event SentoMATICStabilityPool(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);

    // Functions

    function provideToStabilityPool(uint _amount) external;
    
    function decreaseLentAmount(uint _amount) external;

    function allowBorrow() external view returns (bool);

    function withdrawFromStabilityPool(uint _amount) external;

    function sendUSDCtoBorrower(address _to, uint _amount) external;

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUtilisationRatio() external view returns (uint);

    function convertOUSDCToUSDC(uint _amount) external returns (uint);

    function convertUSDCToOUSDC(uint _amount) external returns (uint);

    function rewardsOffset(uint _rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event StabilityPoolAddressChanged(address _newStabilityPoolAddress);

    event USDCTokenBalanceUpdated(address _user, uint _amount);

    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    
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
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @dev Interface of the ERC2612 standard as defined in the EIP.
 *
 * Adds the {permit} method, which can be used to change one's
 * {IERC20-allowance} without having to send a transaction, by signing a
 * message. This allows users to spend tokens without having to hold Ether.
 *
 * See https://eips.ethereum.org/EIPS/eip-2612.
 * 
 * Code adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/pull/2237/
 */
interface IERC2612 {
    /**
     * @dev Sets `amount` as the allowance of `spender` over `owner`'s tokens,
     * given `owner`'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
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
    function permit(address owner, address spender, uint256 amount, 
                    uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    
    /**
     * @dev Returns the current ERC2612 nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases `owner`'s nonce by one. This
     * prevents a signature from being used multiple times.
     *
     * `owner` can limit the time a Permit is valid for by setting `deadline` to 
     * a value in the near future. The deadline argument can be set to uint(-1) to 
     * create Permits that effectively never expire.
     */
    function nonces(address owner) external view returns (uint256);
    
    function version() external view returns (string memory);
    function permitTypeHash() external view returns (bytes32);
    function domainSeparator() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IoUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IoMATICToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IOrumBase.sol";


// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oMATICTokenAddressChanged(address _newoMATICTokenAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoMATICFee(uint _oMATICFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oMATICSent, uint _oMATICFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoMATIC, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoMATIC, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit, uint _stakingRToRedistribute);
    event Coll_getOffsetValues(uint _debt, uint _coll, uint _stakingRToRedistribute);
    event LTermsUpdated(uint _L_STAKINGR);
    event VaultSnapshotsUpdated(uint L_STAKINGR);
    event SystemSnapshotsUpdated(uint totalStakesSnapshot, uint totalCollateralSnapshot);
    // --- Functions ---
    function getVaultOwnersCount() external view returns (uint);

    function getVaultFromVaultOwnersArray(uint _index) external view returns (address);

    function getNominalICR(address _borrower) external view returns (uint);

    function getCurrentICR(address _borrower, uint _price) external view returns (uint);

    function liquidate(address _borrower) external;

    function liquidateVaults(uint _n) external;

    function batchLiquidateVaults(address[] calldata _VaultArray) external; 

    function addVaultOwnerToArray(address _borrower) external returns (uint index);

    function getEntireDebtAndColl(address _borrower) external view returns (
        uint debt, 
        uint coll,
        uint pendingStakingReward
    );

    function closeVault(address _borrower) external;

    function getBorrowingRate() external view returns (uint);

    function getBorrowingRateWithDecay() external view returns (uint);

    function getBorrowingFee(uint USDCDebt) external view returns (uint);

    function getBorrowingFeeWithDecay(uint _USDCDebt) external view returns (uint);

    function decayBaseRateFromBorrowing() external;

    function getVaultStatus(address _borrower) external view returns (uint);

    function getVaultDebt(address _borrower) external view returns (uint);

    function getVaultColl(address _borrower) external view returns (uint);

    function setVaultStatus(address _borrower, uint num) external;

    function increaseVaultColl(address _borrower, uint _collIncrease) external returns (uint);

    function decreaseVaultColl(address _borrower, uint _collDecrease) external returns (uint); 

    function increaseVaultDebt(address _borrower, uint _debtIncrease) external returns (uint); 

    function decreaseVaultDebt(address _borrower, uint _collDecrease) external returns (uint); 

    function getTCR(uint _price) external view returns (uint);

    function checkRecoveryMode(uint _price) external view returns (bool);

    function applyStakingRewards(address _borrower) external;

    function updateVaultRewardSnapshots(address _borrower) external;

    function getPendingStakingoMaticReward(address _borrower) external view returns (uint);

    function removeStake(address _borrower) external;

    function updateStakeAndTotalStakes(address _borrower) external returns (uint);

    function hasPendingRewards(address _borrower) external view returns (bool);

    function redistributeStakingRewards(uint _coll) external;

    
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IPriceFeed.sol";

interface IOrumBase {
    function priceFeed() external view returns (IPriceFeed);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IPriceFeed {
    // -- Events ---
    event LastGoodPriceUpdated(uint _lastGoodPrice);

    // ---Function---
    function fetchPrice() external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface ICommunityIssuance { 
    
    // --- Events ---
    
    event OrumTokenAddressSet(address _orumTokenAddress);
    event StabilityPoolAddressSet(address _stabilityPoolAddress);
    event TotalOrumIssuedUpdated(uint _totalOrumIssued);

    // --- Functions ---

    function setAddresses(address _orumTokenAddress, address _stabilityPoolAddress) external;

    function issueOrum() external returns (uint);

    function sendOrum(address _account, uint _orumAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoMATICToken.sol";


interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloMATICBalanceUpdated(uint oMATIC);
    event SentoMATICActiveVault(address _to,uint _amount );
    event ActivePoolReceivedMATIC(uint _MATIC);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event oMATICSent(address _to, uint _amount);

    // --- Functions ---
    function sendoMATIC(address _account, uint _amount) external;
    function receiveoMATIC(uint new_coll) external;
    function getoMATIC() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;
    function offsetLiquidation(uint _collAmount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoMATICToken.sol";

interface IBorrowerOps {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event StabilityPoolAddressChanged(address _stabilityPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oMATICTokenAddressChanged(address _oMATICTokenAddress);

    event VaultCreated(address indexed _borrower, uint arrayIndex);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event BorrowFeeInoMATIC(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToTreasury(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToOrumRevenue(address indexed _borrower, uint _borrowFee);

    // --- Functions ---
    function openVault(uint _maxFee, uint _debtAmount, uint _colloMATICamount, address _upperHint, address _lowerHint) external payable;
    // function addColl(address _upperHint, address _lowerHint) external payable;
    function addColl(uint _collAddition, address _upperHint, address _lowerHint) external payable;
    function moveoMATICGainToVault(address _upperHint, address _lowerHint) external payable;
    function moveoMATICGainToVaultFromStabilityPool(address _borrower, uint depositorROSEGain, address _upperHint, address _lowerHint) external payable;
    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;
    function withdrawUSDC(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;
    function repayUSDC(uint _amount, address _upperHint, address _lowerHint) external;
    function closeVault() external;
    function claimCollateral() external;
    function getCompositeDebt(uint _debt) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IMockUSDCStaker  {
    // --- Events ---


    // --- Functions ---

    function getTotalUSDCDeposited() external returns (uint);

    function transferUSDC(uint _amount, address _to) external returns (uint);

}