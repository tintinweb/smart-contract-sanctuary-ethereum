// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "Ownable.sol";

import "ILendingPool.sol";
import "IUSDCToken.sol";
import "IoUSDCToken.sol";
import "IVaultManager.sol";
import "ICommunityIssuance.sol";
import "IActivePool.sol";
import "IBorrowerOps.sol";
import "IStakingInterface.sol";
import "IBufferPool.sol";
import "OrumBase.sol";

contract LendingPool is ILendingPool, Ownable, OrumBase{
    address borrowerOpsAddress;
    address rewardsPoolAddress;
    address externalStakingAddress;

    IUSDCToken public usdc_token;
    IVaultManager public vaultManager;
    ICommunityIssuance public communityIssuance;
    IBorrowerOps public borrowerOps;
    IoUSDCToken public oUSDCToken;
    IStakingInterface stackingInterface;
    IBufferPool bufferPool;

    // Token tracking variables
    uint256 public USDC_Lent;
    uint256 internal ETH;

    // Constants
    uint public MIN_USDC_REQUIRED = USDC_GAS_COMPENSATION + MIN_NET_DEBT;
    uint256 public constant SCALE_FACTOR = 1e9;

    // Error trackers for the error correction in the offset calculation
    uint256 public lastOrumError;

    // Rewards tracker
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

    struct BufferRatio {
        uint Staking;
        uint Buffer;
    }

    BufferRatio public bufferRatio;

    function setAddresses(
        address _usdcTokenAddress,
        address _borrowerOpsAddress,
        address _oETHToken,
        address _vaultManagerAddress,
        address _communityIssuanceAddress,
        address _rewardsPoolAddress,
        address _oUSDCToken,
        address _bufferPoolAddress
    ) 
    external 
    onlyOwner
    {
        usdc_token = IUSDCToken(_usdcTokenAddress);
        vaultManager = IVaultManager(_vaultManagerAddress);
        borrowerOpsAddress = _borrowerOpsAddress;
        communityIssuance = ICommunityIssuance(_communityIssuanceAddress);
        rewardsPoolAddress = _rewardsPoolAddress;
        borrowerOps = IBorrowerOps(_borrowerOpsAddress);
        oUSDCToken = IoUSDCToken(_oUSDCToken);
        bufferPool = IBufferPool(_bufferPoolAddress);

        emit USDCTokenAddressChanged(_usdcTokenAddress);
    }

     function setBuffer(uint _buffer, uint _staking) external onlyOwner {
        require((_buffer + _staking) == 100, "Lending Pool: Buffer ratios provided is invalid");

        bufferRatio.Buffer = _buffer;
        bufferRatio.Staking = _staking;
        emit BufferRatioUpdated(_buffer, _staking);
    }

    // --- Getters for public variables. ---


    function getUSDCDeposits() external override view returns (uint) {
        return stackingInterface.getTotalUSDC();
    }

    function getMaxWithdrawalAmount(address _user) external view returns (uint) {
        return (oUSDCToken.balanceOf(_user) * getConversionRate()) / USDC_DECIMAL_PRECISION;
    } 

    // --- External USDC staking address ---
    function setExternalStaker(address _address) external onlyOwner {
        stackingInterface = IStakingInterface(_address);
        externalStakingAddress = _address;
    }

    // LendingPool interaction functions

    function withdrawFromLendingPool(uint _amount) external override {
        uint oUSDCAmount = convertUSDCToOUSDC(_amount);
        require(oUSDCToken.balanceOf(msg.sender) >= oUSDCAmount, "LendingPool: Insufficient oUSDC balance");

        uint oUSDCBalance = oUSDCToken.balanceOf(msg.sender);
        uint initialDeposit = convertOUSDCToUSDC(oUSDCBalance);
        require(initialDeposit > 0, "LendingPool: Initial deposit is 0");

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);
        _payOutOrumGains(communityIssuanceCached, msg.sender);

        // Transfer of USDC to depositor
        _sendUSDCToDepositor(msg.sender, _amount);

        // Update deposit
        uint newDeposit = initialDeposit - _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        // oUSDC token burn
        oUSDCToken.burn(msg.sender, oUSDCAmount);
        stackingInterface.USDCWitdrawFromLendingPool(_amount);
    }

    function provideToLendingPool(uint256 _amount) external override {
        bool allow = _allowDeposit();
        require(allow, "LendingPool: Stable coin deposit not allowed");
        require(usdc_token.balanceOf(msg.sender) >= _amount, "LendingPol: Insufficient USDC balance");

        // Current USDC deposit based on updated CR
        uint oUSDCBalance = oUSDCToken.balanceOf(msg.sender);
        uint initialDeposit = convertOUSDCToUSDC(oUSDCBalance);

        ICommunityIssuance communityIssuanceCached = communityIssuance;

        _triggerOrumIssuance(communityIssuanceCached);
        _payOutOrumGains(communityIssuanceCached, msg.sender);

        // Transfer of oUSDC to depositor
        uint oUSDCAmount = convertUSDCToOUSDC(_amount);
        oUSDCToken.mint(msg.sender, oUSDCAmount);

        // Update deposit
        uint newDeposit = initialDeposit + _amount;
        _updateDepositAndSnapshots(msg.sender, newDeposit);

        uint stakingAmount = (_amount * bufferRatio.Staking)/100;
        uint bufferAmount = (_amount * bufferRatio.Buffer)/100;

        //Stable coin transfer from lender to SP
        _sendUSDCtoLendingPool(msg.sender, externalStakingAddress, stakingAmount);
        _sendUSDCtoLendingPool(msg.sender, address(bufferPool), bufferAmount);
        stackingInterface.USDCProvidedToLendingPool(_amount);

    }

    // Borrowing related functions

    function sendUSDCtoBorrower(
        address _to,
        uint256 _amount
    ) external override {
        _requireCallerIsBorrowerOps();
        emit USDCSent(_to, _amount);
        if (_amount > 0) {
            bool success = bufferPool.sendUSDC(msg.sender, _amount);
            require(success, "Lending pool: USDC transfer failed from BufferPool");
            USDC_Lent += _amount;

            emit sendUSDCtoBorrowerEvent(_to, _amount);
        }
    }

    function decreaseLentAmount(uint256 _amount) external override {
        _requireCallerIsBorrowerOps();
        USDC_Lent -= _amount;
    }

    // Send USDC to user and decrease USDC in Pool
    function _sendUSDCToDepositor(address _depositor, uint USDCWithdrawal) internal {
        if (USDCWithdrawal == 0) {return;}
        bool success = bufferPool.sendUSDC(_depositor, USDCWithdrawal);
        require(success, "Lending pool: USDC transfer failed from BufferPool");
    }

    // Transfer the USDC tokens from the user to the Lending Pool's address, and update its recorded USDC
    function _sendUSDCtoLendingPool(address _sender, address _address, uint _amount) internal {
        if(_address == address(bufferPool)){
            bufferPool.receiveUSDC(_amount);
        }
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
        uint totalUSDC = stackingInterface.getTotalUSDC();
        uint totalOUSDC = oUSDCToken.totalSupply();

        uint CR = totalUSDC == 0 || totalOUSDC == 0 ? USDC_DECIMAL_PRECISION : (totalUSDC * USDC_DECIMAL_PRECISION) / totalOUSDC;
        return CR;  
    }

    // Utilisation ratio functions
    function getUtilisationRatio() external view override returns (uint) {
        return _getUtilisationRatio();
    }

    function _getUtilisationRatio() internal view returns (uint) {
        uint totalUSDC = stackingInterface.getTotalUSDC();
        uint utilisationRatio = totalUSDC == 0 ? 100 * DECIMAL_PRECISION : (USDC_Lent * 100 * DECIMAL_PRECISION) / totalUSDC;
        return utilisationRatio;
    }

    function allowBorrow() external view override returns (bool) {
        bool allowed;
        uint256 utilisationRatio;

        utilisationRatio = _getUtilisationRatio();
        allowed = utilisationRatio >= (borrowingUTR * DECIMAL_PRECISION) || usdc_token.balanceOf(address(bufferPool)) < MIN_USDC_REQUIRED ? false : true;

        return allowed;
    }

    function allowDeposit() external view returns (bool) {
        return _allowDeposit();
    }

    function _allowDeposit() internal view returns (bool) {
        uint256 utilisationRatio;
        bool allow;
        utilisationRatio = _getUtilisationRatio();

        allow = utilisationRatio >= (depositorUTR * DECIMAL_PRECISION) || usdc_token.balanceOf(address(bufferPool)) < MIN_USDC_REQUIRED ? true : false;
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
        uint256 totalUSDC = stackingInterface.getTotalUSDC(); // cached to save an SLOAD
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
            "LendingPool: Caller is not VaultManager"
        );
    }

    // Utilisation ratio setter functions
    function setBorrowingUtilisationRatio(uint _ratio) external onlyOwner {
        require(_ratio >= 0 && _ratio <= 100, "LendingPool: Borrowing utilisation ratio change invalid");
        borrowingUTR = _ratio;
    }

    function setDepositUtilisationRatio(uint _ratio) external onlyOwner {
        require(_ratio >= 0 && _ratio <= 100, "LendingPool: Deposit utilisation ratio change invalid");
        depositorUTR = _ratio;
    }

    function _requireCallerIsVaultManagerOrRewardsPool() internal view {
        require(
            msg.sender == address(vaultManager) || msg.sender == address(rewardsPoolAddress),
            "LendingPool: Caller is not VaultManager or RewardsPool"
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

    // --- Lending Pool Deposit Functionality ---
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
            "LendingPool: Caller is not BorrowerOps"
        );
    }

    function _requireCallerIsRewardsPool() internal view {
        require(
            msg.sender == rewardsPoolAddress,
            "LendingPool: Caller is not BorrowerOps"
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

interface ILendingPool {
    // Events
    event P_Updated(uint _P);
    event S_Updated(uint _S, uint128 _epoch, uint128 _scale);
    event G_Updated(uint _G, uint128 _epoch, uint128 _scale);
    event EpochUpdated(uint128 _currentEpoch);
    event ScaleUpdated(uint128 _currentScale);
    event LendingPoolUSDCBalanceUpdated(uint _newBalance);
    event LendingPoolReceivedETH(uint value);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event sendUSDCtoBorrowerEvent(address _to,uint _amount);
    event USDCSent(address _to,uint _amount);
    event DepositSnapshotUpdated(address _depositor, uint _P, uint _G);
    event BufferRatioUpdated(uint _buffer, uint _staking);

    // Functions

    function provideToLendingPool(uint _amount) external;
    
    function decreaseLentAmount(uint _amount) external;

    function allowBorrow() external returns (bool);

    function withdrawFromLendingPool(uint _amount) external;

    function sendUSDCtoBorrower(address _to, uint _amount) external;

    function getDepositorOrumGain(address _depositor) external returns (uint);

    function getUSDCDeposits() external returns (uint);

    function getUtilisationRatio() external view returns (uint);

    function convertOUSDCToUSDC(uint _amount) external view returns (uint);

    function convertUSDCToOUSDC(uint _amount) external view returns (uint);

    function rewardsOffset(uint _rewards) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IUSDCToken is IERC20, IERC2612 { 
    
    // --- Events ---

    event LendingPoolAddressChanged(address _newLendingPoolAddress);

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

import "IOrumBase.sol";


// Common interface for the Vault Manager.
interface IVaultManager is IOrumBase {
    
    // --- Events ---

    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event PriceFeedAddressChanged(address _newPriceFeedAddress);
    event USDCTokenAddressChanged(address _newUSDCTokenAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oETHTokenAddressChanged(address _newoETHTokenAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);

    event Liquidation(uint _liquidatedDebt, uint _liquidatedColl, uint _collGasCompensation, uint _USDCGasCompensation);
    event Test_LiquidationoETHFee(uint _oETHFee);
    event Redemption(uint _attemptedUSDCAmount, uint _actualUSDCAmount, uint _oETHSent, uint _oETHFee);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event VaultLiquidated(address indexed _borrower, uint _debt, uint _coll, uint8 operation);
    event BaseRateUpdated(uint _baseRate);
    event LastFeeOpTimeUpdated(uint _lastFeeOpTime);
    event TotalStakesUpdated(uint _newTotalStakes);
    event VaultIndexUpdated(address _borrower, uint _newIndex);
    event TEST_error(uint _debtInoETH, uint _collToSP, uint _collToOrum, uint _totalCollProfits);
    event TEST_liquidationfee(uint _totalCollToSendToSP, uint _totalCollToSendToOrumRevenue);
    event TEST_account(address _borrower, uint _amount);
    event TEST_normalModeCheck(bool _mode, address _borrower, uint _amount, uint _coll, uint _debt, uint _price);
    event TEST_debt(uint _debt);
    event TEST_offsetValues(uint _debtInoETH, uint debtToOffset, uint collToSendToSP, uint collToSendToOrumRevenue, uint _totalCollProfit, uint _stakingRToRedistribute);
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

    function getPendingStakingoethReward(address _borrower) external view returns (uint);

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
    event LendingPoolAddressSet(address _lendingPoolAddress);
    event TotalOrumIssuedUpdated(uint _totalOrumIssued);

    // --- Functions ---

    function setAddresses(address _orumTokenAddress, address _lendingPoolAddress) external;

    function issueOrum() external returns (uint);

    function sendOrum(address _account, uint _orumAmount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IActivePool {
    // --- Events ---
    event BorrowerOpsAddressChanged(address _newBorrowerOpsAddress);
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolUSDCDebtUpdated(uint _USDCDebt);
    event ActivePooloETHBalanceUpdated(uint oETH);
    event SentoETHActiveVault(address _to,uint _amount );
    event ActivePoolReceivedETH(uint _ETH);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event oETHSent(address _to, uint _amount);

    // --- Functions ---
    function sendoETH(address _account, uint _amount) external;
    function receiveoETH(uint new_coll) external;
    function getoETH() external view returns (uint);
    function getUSDCDebt() external view returns (uint);
    function increaseUSDCDebt(uint _amount) external;
    function decreaseUSDCDebt(uint _amount) external;
    function offsetLiquidation(uint _collAmount) external;

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IERC20.sol";
import "IERC2612.sol";

interface IoETHToken is IERC20, IERC2612 { 
    
    // --- Events ---


    // --- Functions ---

    function mint(address _account, uint256 _amount) external;

    function burn(address _account, uint256 _amount) external;

    function sendToPool(address _sender,  address poolAddress, uint256 _amount) external;

    function returnFromPool(address poolAddress, address user, uint256 _amount ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";

interface IBorrowerOps {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event ActivePoolAddressChanged(address _activePoolAddress);
    event BorrowersRewardsPoolAddressChanged(address _borrowersRewardsPoolAddress);
    event LendingPoolAddressChanged(address _lendingPoolAddress);
    event GasPoolAddressChanged(address _gasPoolAddress);
    event CollSurplusPoolAddressChanged(address _collSurplusPoolAddress);
    event PriceFeedAddressChanged(address  _newPriceFeedAddress);
    event SortedVaultsAddressChanged(address _sortedVaultsAddress);
    event USDCTokenAddressChanged(address _usdcTokenAddress);
    event OrumRevenueAddressChanged(address _orumRevenueAddress);
    event oETHTokenAddressChanged(address _oETHTokenAddress);

    event VaultCreated(address indexed _borrower, uint arrayIndex);
    event VaultUpdated(address indexed _borrower, uint _debt, uint _coll, uint stake, uint8 operation);
    event BorrowFeeInoETH(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToTreasury(address indexed _borrower, uint _borrowFee);
    event TEST_BorrowFeeSentToOrumRevenue(address indexed _borrower, uint _borrowFee);

    // --- Functions ---
    function openVault(uint _maxFee, uint _debtAmount, uint _colloETHamount, address _upperHint, address _lowerHint) external payable;
    // function addColl(address _upperHint, address _lowerHint) external payable;
    function addColl(uint _collAddition, address _upperHint, address _lowerHint) external payable;
    function moveoETHGainToVault(address _upperHint, address _lowerHint) external payable;
    function moveoETHGainToVaultFromLendingPool(address _borrower, uint depositorROSEGain, address _upperHint, address _lowerHint) external payable;
    function withdrawColl(uint _amount, address _upperHint, address _lowerHint) external;
    function withdrawUSDC(uint _maxFee, uint _amount, address _upperHint, address _lowerHint) external;
    function repayUSDC(uint _amount, address _upperHint, address _lowerHint) external;
    function closeVault() external;
    function claimCollateral() external;
    function getCompositeDebt(uint _debt) external view returns (uint);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;


interface IStakingInterface  {
    // --- Events ---


    // --- Functions ---

    function getTotalUSDC() external view returns (uint);

    function USDCWitdrawFromLendingPool(uint _amount) external;

    function USDCProvidedToLendingPool(uint _amount) external;
    
    // --- ETH Functions ---

    function getTotalETHDeposited() external returns (uint);

    function transferETH(uint _amount, address _to) external returns (uint);


}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

interface IBufferPool {
    // --- Events ---
    event BufferPoolETHUpdated(uint deposit);
    event BufferPoolUSDCUpdated(uint amount);

    // --- Functions ---
    function sendETH(address _receiver, uint _amount) external payable returns (bool);
    function receiveUSDC(uint _amount) external ;
    function sendUSDC(address _receiver, uint _amount) external payable returns (bool);

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "OrumMath.sol";
import "IActivePool.sol";
import "IPriceFeed.sol";
import "IOrumBase.sol";
import "IBorrowersRewardsPool.sol";


/* 
* Base contract for VaultManager, BorrowerOps and LendingPool. Contains global system constants and
* common functions. 
*/
contract OrumBase is IOrumBase {
    using SafeMath for uint;

    uint constant public DECIMAL_PRECISION = 1e18;

    uint constant public USDC_DECIMAL_PRECISION = 1e6;

    uint constant public _100pct = 1000000000000000000; // 1e18 == 100%

    // Minimum collateral ratio for individual Vaults
    uint public MCR = 1100000000000000000; // 110%;

    // Critical system collateral ratio. If the system's total collateral ratio (TCR) falls below the CCR, Recovery Mode is triggered.
    uint public CCR = 1500000000000000000; // 150%

    // Amount of USDC to be locked in gas pool on opening vaults
    uint public USDC_GAS_COMPENSATION = 200e6;

    // Minimum amount of net USDC debt a vault must have
    uint public MIN_NET_DEBT = 2000e6;

    uint public PERCENT_DIVISOR = 200; // dividing by 200 yields 0.5%

    uint public BORROWING_FEE_FLOOR = DECIMAL_PRECISION / 10000 * 75 ; // 0.75%

    uint public TREASURY_LIQUIDATION_PROFIT = DECIMAL_PRECISION / 100 * 20; // 20%
    


    address public contractOwner;

    IActivePool public activePool;

    IBorrowersRewardsPool public borrowersRewardsPool; 


    IPriceFeed public override priceFeed;

    constructor() {
        contractOwner = msg.sender;
    }
    // --- Gas compensation functions ---

    // Returns the composite debt (drawn debt + gas compensation) of a vault, for the purpose of ICR calculation
    function _getCompositeDebt(uint _debt) internal view  returns (uint) {
        return _debt.add(USDC_GAS_COMPENSATION);
    }
    function _getNetDebt(uint _debt) internal view returns (uint) {
        return _debt.sub(USDC_GAS_COMPENSATION);
    }
    // Return the amount of oETH to be drawn from a vault's collateral and sent as gas compensation.
    function _getCollGasCompensation(uint _entireColl) internal view returns (uint) {
        return _entireColl / PERCENT_DIVISOR;
    }
    
    function getEntireSystemColl() public view returns (uint entireSystemColl) {
        uint activeColl = activePool.getoETH();
        uint borrowerRewards = borrowersRewardsPool.getBorrowersoETHRewards();
        return activeColl.add(borrowerRewards);
    }

    function getEntireSystemDebt() public view returns (uint entireSystemDebt) {
        uint activeDebt = activePool.getUSDCDebt();
        return activeDebt;
    }
    function _getTreasuryLiquidationProfit(uint _amount) internal view returns (uint){
        return _amount.mul(TREASURY_LIQUIDATION_PROFIT).div(DECIMAL_PRECISION);
    }
    function _getTCR(uint _price) internal view returns (uint TCR) {
        uint entireSystemColl = getEntireSystemColl();
        uint entireSystemDebt = getEntireSystemDebt();

        TCR = OrumMath._computeCR(entireSystemColl, entireSystemDebt, _price);
        return TCR;
    }

    function _checkRecoveryMode(uint _price) internal view returns (bool) {
        uint TCR = _getTCR(_price);

        return TCR < CCR;
    }

    function _requireUserAcceptsFee(uint _fee, uint _amount, uint _maxFeePercentage) internal pure {
        uint feePercentage = _fee.mul(DECIMAL_PRECISION).div(_amount);
        require(feePercentage <= _maxFeePercentage, "Fee exceeded provided maximum");
    }

    function _requireCallerIsOwner() internal view {
        require(msg.sender == contractOwner, "OrumBase: caller not owner");
    }

    function changeOwnership(address _newOwner) external {
        require(msg.sender == contractOwner, "OrumBase: Caller not owner");
        contractOwner = _newOwner;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "SafeMath.sol";

library OrumMath {
    using SafeMath for uint;

    uint internal constant DECIMAL_PRECISION = 1e18;

    uint internal constant USDC_DECIMAL_PRECISION = 1e6;

    /* Precision for Nominal ICR (independent of price). Rationale for the value:
    *
    * - Making it "too high" could lead to overflows.
    * - Making it "too low" could lead to an ICR equal to zero, due to truncation from Solidity floor division.
    *
    * This value of 1e20 is chosen for safety: the NICR will only overflow for numerator > ~1e39 oETH,
    * and will only truncate to 0 if the denominator is at least 1e20 times greater than the numerator.
    *
    */

    uint internal constant NICR_PRECISION = 1e20;

    function _min(uint _a, uint _b) internal pure returns (uint) {
        return (_a < _b) ? _a : _b;
    }
    function _max(int _a, int _b) internal pure returns (uint) {
        return (_a >= _b) ? uint(_a) : uint(_b);
    }

    /*
    * Multiply two decimal numbers and use normal rounding rules
    * - round product up if 19'th mantissa digit >= 5
    * - round product down if 19'th mantissa digit < 5
    * 
    * Used only inside exponentiation, _decPow().
    */

    function decMul(uint x, uint y) internal pure returns (uint decProd) {
        uint prod_xy = x.mul(y);
        decProd = prod_xy.add(DECIMAL_PRECISION/2).div(DECIMAL_PRECISION);
    }
    
    function _decPow(uint _base, uint _minutes) internal pure returns (uint) {
       
        if (_minutes > 525600000) {_minutes = 525600000;}  // cap to avoid overflow
    
        if (_minutes == 0) {return DECIMAL_PRECISION;}

        uint y = DECIMAL_PRECISION;
        uint x = _base;
        uint n = _minutes;

        // Exponentiation-by-squaring
        while (n > 1) {
            if (n % 2 == 0) {
                x = decMul(x, x);
                n = n.div(2);
            } else { // if (n % 2 != 0)
                y = decMul(x, y);
                x = decMul(x, x);
                n = (n.sub(1)).div(2);
            }
        }

        return decMul(x, y);
  }

    function _getAbsoluteDifference(uint _a, uint _b) internal pure returns (uint) {
        return (_a >= _b) ? _a.sub(_b) : _b.sub(_a);
    }

    function _computeNominalCR(uint _coll, uint _debt) internal pure returns (uint) {
        if (_debt > 0) {
            return _coll.mul(NICR_PRECISION).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1;
        }
    }

    function _computeCR(uint _coll, uint _debt, uint _price) internal pure returns (uint) {
        if (_debt > 0) {
            uint newCollRatio = _coll.mul(_price).div(_debt).mul(USDC_DECIMAL_PRECISION).div(DECIMAL_PRECISION);

            return newCollRatio;
        }
        // Return the maximal value for uint256 if the Vault has a debt of 0. Represents "infinite" CR.
        else { // if (_debt == 0)
            return 2**256 - 1; 
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 * 
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "IoETHToken.sol";


interface IBorrowersRewardsPool  {
    // --- Events ---
    event VaultManagerAddressChanged(address _newVaultManagerAddress);
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated(uint _borrowersoETHRewards);
    event BorrowersRewardsPoolborrowersoETHRewardsBalanceUpdated_before(uint _borrowersoETHRewards);
    event borrowersoETHRewardsSent(address activePool, uint _amount);
    event BorrowersRewardsPooloETHBalanceUpdated(uint _OrumwithdrawalborrowersoETHRewards);
    event  ActivePoolAddressChanged(address _activePoolAddress);

    // --- Functions ---
    function sendborrowersoETHRewardsToActivePool(uint _amount) external;
    function receiveoETHBorrowersRewardsPool(uint new_coll) external;
    function getBorrowersoETHRewards() external view returns (uint);
}