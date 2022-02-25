// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.11;

import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";
import { IERC20 } from "./IERC20.sol";
import { IStakingContractV1 } from "./IStakingContractV1.sol";
import { Pausable } from "./Pausable.sol";
import { StakeStructs } from "./StakeStructs.sol";
import { StakeOpsController } from "./StakeOpsController.sol";

contract StakingContractV1 is StakeStructs, IStakingContractV1, StakeOpsController, Pausable {

    IERC20 public immutable powrToken;

    // Same decimal precision as the POWR ERC20 Token
    uint256 public constant unit = 1000000;

    StakeStructs.StakingOpsInfo public stkOpsData;

    mapping(address => StakeStructs.StakeInfo) public stkData;

    mapping(string => uint256) public validatorTotalStake;

    mapping (string =>  address) public stakeAddressToEthAddress;

    /// @dev Verifies the following conditions:
    /// 1) The amount being deposited must be > 0
    /// 2) The amount being deposited must be > minimum POWR tokens deposit limit
    /// 3) The amount being deposited will not cause the chosen validator to exceed the maximum allowed stake
    /// 4) The address has not been used for staking before
    modifier checkDepositConditions(
        address _addr,
        uint256 _amount,
        string memory _stakerPubKey,
        string memory _validatorPubKey) {
        require(_amount > 0, "StakingContractV1:checkDepositConditions: Amount must be > 0");
        require(_amount >= stkOpsData.minPowrDeposit, "StakingContractV1:checkDepositConditions: Amount must be at least the min deposit requirement");
        require(validatorTotalStake[_validatorPubKey] + _amount <= stkOpsData.maxPowrPerValidator, "StakingContractV1:checkDepositConditions: Total stake cannot exceed max stake per validator");
        require(stkData[_addr].stakeStatus == StakeStatus.NeverStaked, "StakingContractV1:checkDepositConditions: Address can only stake once");
        require(stakeAddressToEthAddress[_stakerPubKey] == address(0), "StakingContractV1:checkDepositConditions: Solana wallet can only stake once");
        _;
    }

    /// @dev Verifies the following conditions:
    /// 1) Stake has not already been withdrawn
    /// 2) stakeStatus is equal to Unstaked
    /// 3) Stake + rewards > 0
    /// 4) Require 7 days have passed since undelegating/unlocking stake
    modifier checkWithdrawalConditions(address _addr) {
        require(stkData[_addr].stakeStatus != StakeStatus.Withdrawn, "StakingContractV1:checkWithdrawalConditions: Stake already withdrawn");
        require(stkData[_addr].stakeStatus == StakeStatus.Unstaked, "StakingContractV1:checkWithdrawalConditions: Stake has not been unstaked or cannot be found");
        require(stkData[_addr].stake + stkData[_addr].stakeRewards > 0, "StakingContractV1:checkWithdrawalConditions: No stake to withdraw");
        require(block.timestamp >= (stkData[_addr].unstakeTimestamp + (12*60*60)), "StakingContractV1:checkWithdrawalConditions: 7 days need to pass before you can withdraw");
        _;
    }

    /// @dev Setting initial parameters.
    /// @param _powrToken The address of the POWR ERC20 token. Mainnet address: 0x595832F8FC6BF59c85C527fEC3740A1b7a361269
    /// @param _minPowrDeposit The minimum amount of POWR tokens that are going to be required in order to become a Staker.
    /// @param _maxPowrPerValidator The maxinum POWR that can be delegated to each validator
    /// @param _stakeOpsAdmin The account that is going to be granted the STAKE_OPS_ADMIN_ROLE.
    /// @param _balanceUpdater The account that is going to be granted the BALANCE_UPDATER_ROLE.
    /// @param _pauser The account that is going to be granted the PAUSER_ROLE.
    /// @param _powrEthPoolAddress The POWR-ETH uniswap v2 pool
    constructor(
        address _powrToken,
        uint256 _minPowrDeposit,
        uint256 _maxPowrPerValidator,
        address _stakeOpsAdmin,
        address _balanceUpdater,
        address _pauser,
        address _powrEthPoolAddress,
        uint256 _unlockGasCost)
            StakeOpsController(
                _stakeOpsAdmin,
                _balanceUpdater,
                _pauser){

        require(_powrToken != address(0), "StakingContractV1: _powrToken address is incorrect");

        powrToken = IERC20(_powrToken);
        stkOpsData.minPowrDeposit = _minPowrDeposit * unit;
        stkOpsData.maxPowrPerValidator = _maxPowrPerValidator * unit;
        stkOpsData.powrRatio = 10000; //initial ratio set to 100.00%
        stkOpsData.powrEthPool = _powrEthPoolAddress;
        stkOpsData.stakeOpsAdmin = _stakeOpsAdmin;
        stkOpsData.unlockGasCost = _unlockGasCost;
    }

    /// @dev The First step into staking, wanna-be staker must sent POWR tokens to this contract using this deposit function.
    /// @param _amount The amount of POWR tokens to stake. If the amount to stake is 1 POWR token then the value of this parameter should be 1x10^6
    /// @param _stakerPubKey The solana public key of the user
    /// @param _validatorPubKey The public key from the PLChain Node
    function deposit(
        uint256 _amount, 
        string memory _stakerPubKey,
        string memory _validatorPubKey)
            external
            whenNotPaused
            checkDepositConditions(_msgSender(), _amount, _stakerPubKey, _validatorPubKey)
            {
                address stakerEthAddress = _msgSender();
                /// require amount of tokens in account ready to deposit
                require(powrToken.transferFrom(stakerEthAddress, address(this), _amount), "StakingContractV1:deposit: Can't transfer the POWR tokens");

                // First deposit
                stkData[stakerEthAddress] = StakeStructs.StakeInfo({
                    stake: _amount,
                    stakeRewards: 0,
                    registeredStaker: _stakerPubKey,
                    registeredStakerValidatorPubKey: _validatorPubKey,
                    stakeStatus: StakeStatus.Deposited,
                    ethFee: 0,
                    unstakeTimestamp: 0
                });
                stakeAddressToEthAddress[_stakerPubKey] = stakerEthAddress;
                validatorTotalStake[_validatorPubKey] = validatorTotalStake[_validatorPubKey] + _amount;
                stkOpsData.stakeCount = stkOpsData.stakeCount + 1;
                stkOpsData.totalStaked = stkOpsData.totalStaked + _amount;
                emit StakeDeposited(stakerEthAddress, _amount, _stakerPubKey, _validatorPubKey);
    }

    /// @dev This function is called after the user has requested an unstake. This is called by the BALANCE_UPDATER_ROLE and updates the reward amounts
    /// @dev This function sets the rewards + stake to be withdrawn by the user using the withdraw() function
    /// @param _stakerPubKey The solana pubkey of the staker that has unstaked their POWR and it has finished unstaking on the plchain
    /// @param _rewardAmount The amount of rewards accrued (in base units i.e. 1 POWR = 10^6)
    function unlockStake(
        string memory _stakerPubKey, 
        uint256 _rewardAmount)
            external
            whenNotPaused
            onlyRole(BALANCE_UPDATER_ROLE)
            {
                // get eth address from sol address
                address stakerEthAddress = stakeAddressToEthAddress[_stakerPubKey];
                require(stkData[stakerEthAddress].stakeStatus == StakeStatus.Deposited, "StakingContractV1:unlockStake Stake must be in 'deposited' state");
                //set status to unstaked, set reward amount
                stkData[stakerEthAddress].stakeStatus = StakeStatus.Unstaked;
                stkData[stakerEthAddress].stakeRewards = _rewardAmount;
                stkData[stakerEthAddress].ethFee = stkOpsData.unlockGasCost*tx.gasprice;     // 130000 avg gas price of unlock tx
                stkData[stakerEthAddress].unstakeTimestamp = block.timestamp;


                //update contract stats
                stkOpsData.stakeCount = stkOpsData.stakeCount - 1;
                stkOpsData.totalStaked = stkOpsData.totalStaked - stkData[stakerEthAddress].stake;
                validatorTotalStake[stkData[stakerEthAddress].registeredStakerValidatorPubKey] = validatorTotalStake[stkData[stakerEthAddress].registeredStakerValidatorPubKey] - stkData[stakerEthAddress].stake;

                //emit event
                emit UnlockStake(stakerEthAddress, stkData[stakerEthAddress].stake, stkData[stakerEthAddress].registeredStaker);
    }

    /// @dev This function can be called after the unlockStake transaction has been sent by the bridge
    /// @dev This function ensures that the fee collection is not greater than withdrawal amount
    /// @dev if the fee is greater than reward amount, we transfer no rewards from the admin account 
    /// @dev If the fee is greater than rewards we subtract the remaining fee from the principal stake and transfer it back from the contract
    /// @dev If the rewards are enough to co er the fee, this function tranfers the stake from the contract and the rewards from the admin account
    function withdraw()
        external
        whenNotPaused
        checkWithdrawalConditions(_msgSender()){
            address stakerEthAddress = _msgSender();
            uint256 stakeAmount = stkData[stakerEthAddress].stake * stkOpsData.powrRatio / 10000;
            uint256 rewardAmount = stkData[stakerEthAddress].stakeRewards * stkOpsData.powrRatio / 10000;
            uint256 powrFee = uint(convertEthToPOWR(stkData[stakerEthAddress].ethFee));
            // sets stake and reward to 0 and updates status
            stkData[stakerEthAddress].stake = 0;
            stkData[stakerEthAddress].stakeRewards = 0;
            stkData[stakerEthAddress].stakeStatus = StakeStatus.Withdrawn;

            // Checks if the fee will cover the rewarded amount, if not, the rewards are zeroed out and the remaining fee subtracted from principal
            // If the fee does cover the reward amount, transfer full stake from staking contract, and rewards are transferred from admin account
            if(powrFee >= rewardAmount) {
                uint256 remainingFee = powrFee - rewardAmount;
                require(stakeAmount >= remainingFee, "StakingContractV1:withdraw Not enough POWR in stake to cover withdrawal fee");
                uint256 remainingStake = stakeAmount - remainingFee;
                require(powrToken.transfer(stakerEthAddress, remainingStake), "StakingContractV1:withdraw Can't transfer remaining POWR tokens staking contract");
                require(powrToken.transfer(stkOpsData.stakeOpsAdmin, (stakeAmount*10000/stkOpsData.powrRatio) - remainingStake), "StakingContractV1:withdraw Can't transfer POWR fee from staking contract");
                
            } else {
                require(powrToken.transfer(stakerEthAddress, stakeAmount), "StakingContractV1:withdraw Can't transfer POWR tokens from staking contract");
                require(powrToken.transferFrom(stkOpsData.stakeOpsAdmin, stakerEthAddress, rewardAmount - powrFee), "StakingContractV1:withdraw Can't transfer POWR tokens from admin account");
            }

           // emit event
            emit StakeWithdrawn(stakerEthAddress, stakeAmount, rewardAmount);
    }
    
    /// @dev This function is called in an emergency to force a user to unstake their POWR. This is called by the STAKE_OPS_ADMIN_ROLE and updates the reward amounts
    /// @dev This function sets the rewards + stake minus the fee to be withdrawn by the user using the withdraw() function
    /// @param _stakerPubKey The sol address of the staker that has unstaked their POWR and it has finished unstaking on the plchain
    /// @param _rewardAmount The amount of rewards accrued (in base units i.e. 1 POWR = 10^6)
    function forceUnlockStake(
        string memory _stakerPubKey, 
        uint256 _rewardAmount)
            external
            onlyRole(STAKE_OPS_ADMIN_ROLE) 
            {
                // get eth address from sol address
                address stakerEthAddress = stakeAddressToEthAddress[_stakerPubKey];
                require(stkData[stakerEthAddress].stakeStatus == StakeStatus.Deposited || stkData[stakerEthAddress].stakeStatus == StakeStatus.Unstaked, "StakingContractV1:forceUnlockStake: Stake must be in 'deposited' or 'unstaked' state");
                //set status to unstaked, set reward amount
                stkData[stakerEthAddress].stakeStatus = StakeStatus.Unstaked;
                stkData[stakerEthAddress].stakeRewards = _rewardAmount;
                stkData[stakerEthAddress].ethFee = stkOpsData.unlockGasCost*tx.gasprice;
                stkData[stakerEthAddress].unstakeTimestamp = block.timestamp;

                //update internal contract status
                stkOpsData.stakeCount = stkOpsData.stakeCount - 1;
                stkOpsData.totalStaked = stkOpsData.totalStaked - stkData[stakerEthAddress].stake;
                validatorTotalStake[stkData[stakerEthAddress].registeredStakerValidatorPubKey] = validatorTotalStake[stkData[stakerEthAddress].registeredStakerValidatorPubKey] - stkData[stakerEthAddress].stake;

                //emit event
                emit ForceUnlockStake(stakerEthAddress, stkData[stakerEthAddress].stake, stkData[stakerEthAddress].registeredStaker);
    }

    /// @dev Getter function to return the status of a stake
    /// @param _stakerEthAddress The eth address of the staker 
    /// @return currentStatus The current status of the staker
    function getStatus(address _stakerEthAddress)
        external
        view
        returns(uint currentStatus)
        {
            currentStatus = uint(stkData[_stakerEthAddress].stakeStatus);
            return(currentStatus);
        }


    /// @dev This function takes an amount of eth and using the current uniswap pool rate, returns a powr amount
    /// @param _ethAmount The amount of ether (in wei) to convert to powr
    /// @return powrAmount the amount of powr in base units (6 decimals)
    function convertEthToPOWR(uint256 _ethAmount) 
        public 
        view 
        returns(uint256 powrAmount)
        {
            IUniswapV2Pair pair = IUniswapV2Pair(stkOpsData.powrEthPool);
            (uint112 powrReserves, uint112 ethReserves,) = pair.getReserves();
            powrAmount = (_ethAmount*powrReserves)/(ethReserves); // return amount of POWR needed to buy _ethAmount in base unit (i.e. 1 POWR = 10^6)
            return(powrAmount);
        }

    /// @dev This function takes an integer between 0 and 10000 and updates the powrRatio for reward distribution.
    /// @dev This function can only be called by STAKE_OPS_ADMIN_ROLE
    /// @param _newRatio an integer between 0 and 10000 that represents between 0 and 100.00% of powr conversion ratio
    function setRatio(
        uint256 _newRatio)
        external
        onlyRole(STAKE_OPS_ADMIN_ROLE)
            {
                require(_newRatio <= 10000, "New Ratio must be below 10000");
                stkOpsData.powrRatio = _newRatio;
            }

    /// @dev This function returns the current vavlue of stkOpsData.powrRatio
    /// @return newRatio an integer between 0 and 10000 that represents between 0 and 100.00% of powr conversion ratio
    function getRatio()
        external
        view
        returns (uint256 newRatio)                            
            {
                newRatio = stkOpsData.powrRatio;
                return(newRatio);
            }

    /// @dev This function allows the admin role to change the minimum deposit required to stake from the initial amount set
    /// @param _newAmount new minimum amount of POWR to deposit. in POWR units (i.e. enter 5000 POWR for 5000000000 base units)
    function changeMinDeposit(uint256 _newAmount)
        external
        onlyRole(STAKE_OPS_ADMIN_ROLE){
            stkOpsData.minPowrDeposit = _newAmount * unit;
        }

    /// @dev This function allows the admin role to change the gas cost of an unlock transaction from 130000
    /// @param _newGasCost new gas cost of the unlock transactions
    function changeUnlockGasCost(uint256 _newGasCost)
        external
        onlyRole(STAKE_OPS_ADMIN_ROLE){
            stkOpsData.unlockGasCost = _newGasCost;
        }

    /// @dev Pauses the contract. Can only be called by user with PAUSER_ROLE
    function pause()
        external
        onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /// @dev If the contract is Paused, it unpauses it, only called by user with PAUSER_ROLE
    function unPause()
        external
        onlyRole(PAUSER_ROLE) {
        _unpause();
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity =0.8.11;

import { AccessControl } from "./AccessControl.sol";

/// @title StakeOpsController
/// 3 roles are defined:
/// STAKE_OPS_ADMIN_ROLE: Accounts with this role have unrestricted execution permissions to all protected functions.
/// BALANCE_UPDATER_ROLE:  Accounts with this role have execution permissions over unlockStake function which applies rewards
/// PAUSER_ROLE: Accounts with this role can Pause or UnPause (see Pausable.sol) the PowerLedgerStakingV1 contract
/// STAKE_OPS_ADMIN_ROLE can be PAUSER_ROLE, but not BALANCE_UPDATER_ROLE
/// PAUSER_ROLE and BALANCE_UPDATER_ROLE must be different
contract StakeOpsController is AccessControl {

    bytes32 public constant STAKE_OPS_ADMIN_ROLE = keccak256("STAKE_OPS_ADMIN_ROLE");
    bytes32 public constant BALANCE_UPDATER_ROLE = keccak256("BALANCE_UPDATER_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Construction of this contract requires the .
    /// @param _stakeOpsAdmin Admin account. Has all 3 permissions.
    /// @param _balanceUpdater Updater account. Can only execute stats update functionality
    /// @param _pauser Pauser account. Can only pause / unpause the contract.
    constructor(
        address _stakeOpsAdmin,
        address _balanceUpdater,
        address _pauser) {

        require(_stakeOpsAdmin != _balanceUpdater, "StakeOpsController: Accounts must be different");
        require(_balanceUpdater != _pauser, "StakeOpsController: Accounts must be different");

        _setRoleAdmin(STAKE_OPS_ADMIN_ROLE, STAKE_OPS_ADMIN_ROLE);
        _setRoleAdmin(BALANCE_UPDATER_ROLE, STAKE_OPS_ADMIN_ROLE);
        _setRoleAdmin(PAUSER_ROLE, STAKE_OPS_ADMIN_ROLE);

        _setupRole(STAKE_OPS_ADMIN_ROLE, _stakeOpsAdmin);
        _setupRole(BALANCE_UPDATER_ROLE, _stakeOpsAdmin);
        _setupRole(PAUSER_ROLE, _stakeOpsAdmin);

        _setupRole(BALANCE_UPDATER_ROLE, _balanceUpdater);
        _setupRole(PAUSER_ROLE, _pauser);
    }

    /// @dev Modifier to make a function callable only by a certain role. In
    /// addition to checking the sender's role, `address(0)` 's role is also
    /// considered. Granting a role to `address(0)` is equivalent to enabling
    /// this role for everyone.
    modifier onlyRole(bytes32 role) override {
        require(hasRole(role, _msgSender()) || hasRole(role, address(0)), "StakeOpsController: sender requires permission");
        _;
    }
}

// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.11;

/// GENERAL STAKING DATA
///     └─ StakingOpsInfo
/// STAKER
///     └─ StakeInfo

contract StakeStructs {
    
    enum StakeStatus { NeverStaked, Deposited, Unstaked, Withdrawn }

    /// General Staking Info & Parameters
    struct StakingOpsInfo {
        uint256 stakeCount;             // Total number of stakers, activated and not activated
        uint256 totalStaked;            // The total amount of POWR tokens staked regardless of the status
        uint256 minPowrDeposit;         // The min amount of POWR tokens required for staking
        uint256 maxPowrPerValidator;     // The max amount of POWR to be delegated to each validator
        uint256 powrRatio;              // From 0 to 10000, the 000.00% of penaties that will be applied
        address powrEthPool;            // address of the uniswap v2 POWR-ETH pool
        address stakeOpsAdmin;          // the address of the stake OPS admin
        uint256 unlockGasCost;         // gas price of unlock transaction
    }

    /// Stake information. Per Staker.
    struct StakeInfo {
        uint256 stake;                              // The amount of POWR tokens staked
        uint256 stakeRewards;                       // Amount of POWR tokens rewards
        string registeredStaker;                   // Address of the wallet used for staking
        string registeredStakerValidatorPubKey;    // The public key of the PLChain Node to delegate to
        StakeStatus stakeStatus;                     // Enum storing status of stake Stake
        uint256 ethFee;                                   // eth fee charged to subsidize unlock stake tx
        uint256 unstakeTimestamp;                    //timestamp for storing when the user requested an unstake
    }
}

// SPDX-License-Identifier: MIT

pragma solidity =0.8.11;

import { Context } from "./Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor () {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.11;


interface IStakingContractV1 {

    event StakeDeposited(
        address indexed staker,
        uint256 amount,
        string stakerPubKey,
        string validatorPubKey);

    event UnlockStake(
        address indexed staker,
        uint256 amount,
        string validatorPubKey);

    event ForceUnlockStake(
        address indexed staker,
        uint256 amount,
        string validatorPubKey);

    event StakeWithdrawn(
        address indexed staker,
        uint256 stake,
        uint256 rewards);

    function deposit(
        uint256 _amount, 
        string memory _stakerPubKey,
        string memory _validatorPubKey)
            external;

    function unlockStake(
        string memory _stakerPubKey, 
        uint256 _rewardAmount)
            external;

    function forceUnlockStake(
        string memory _stakerPubKey, 
        uint256 _rewardAmount)
            external;

    function withdraw()
            external;

    function getStatus(
        address _stakerEthAddress)
            external
            returns(uint currentStatus);

    function setRatio(
        uint256 _newRatio)
        external;

    function getRatio()
        external
        view
        returns (uint256 newRatio);

    function changeMinDeposit(
        uint256 _newAmount)
        external;

    function changeUnlockGasCost(
        uint256 _newGasCost)
        external;

    function pause()
        external;

    function unPause()
        external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.10;

/**
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

// SPDX-License-Identifier: GPL-3.0
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (access/AccessControl.sol)

pragma solidity ^0.8.10;

import { IAccessControl } from "./IAccessControl.sol";
import { Context } from "./Context.sol";
import { Strings } from "./Strings.sol";
import { ERC165 } from "./ERC165.sol";
import { Ownable } from "./Ownable.sol";

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
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
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
 * accounts that have been granted it.
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
    modifier onlyRole(bytes32 role) virtual {
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/Context.sol)

pragma solidity ^0.8.10;

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

pragma solidity ^0.8.10;

import { Context } from "./Context.sol";

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
    modifier onlyOwner() virtual {
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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