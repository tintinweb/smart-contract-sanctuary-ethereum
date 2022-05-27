// SPDX-License-Identifier: UNLICENCED
pragma solidity ^0.8.11;

import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";
import { IERC20 } from "./IERC20.sol";
import { IStakingContractV1 } from "./IStakingContractV1.sol";
import { Pausable } from "./Pausable.sol";
import { StakeStructs } from "./StakeStructs.sol";
import { StakeOpsController } from "./StakeOpsController.sol";
import { Context } from "./Context.sol";

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
        require(block.timestamp >= (stkData[_addr].unstakeTimestamp + (7*24*60*60)), "StakingContractV1:checkWithdrawalConditions: 7 days need to pass before you can withdraw");
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
    /// @param _rewardWallet The wallet the POWR rewards will be paid from
    constructor(
        address _powrToken,
        uint256 _minPowrDeposit,
        uint256 _maxPowrPerValidator,
        address _stakeOpsAdmin,
        address _balanceUpdater,
        address _pauser,
        address _powrEthPoolAddress,
        uint256 _unlockGasCost,
        address _rewardWallet)
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
        stkOpsData.unlockGasCost = _unlockGasCost;
        stkOpsData.rewardWallet = _rewardWallet;
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
                stkData[stakerEthAddress].ethFee = stkOpsData.unlockGasCost*tx.gasprice;
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
    /// @dev If the rewards are enough to cover the fee, this function tranfers the stake from the contract and the rewards from the admin account
    function withdraw()
        external
        whenNotPaused
        checkWithdrawalConditions(_msgSender()){
            address stakerEthAddress = _msgSender();
            uint256 stakeAmount = stkData[stakerEthAddress].stake;
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
                require(powrToken.transfer(stkOpsData.rewardWallet, stakeAmount - remainingStake), "StakingContractV1:withdraw Can't transfer POWR fee from staking contract");

            } else {
                require(powrToken.transfer(stakerEthAddress, stakeAmount), "StakingContractV1:withdraw Can't transfer POWR tokens from staking contract");
                require(powrToken.transferFrom(stkOpsData.rewardWallet, stakerEthAddress, rewardAmount - powrFee), "StakingContractV1:withdraw Can't transfer POWR tokens from admin account");
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

    /// @dev This function takes an integer between 0 and 100000 and updates the powrRatio for reward distribution.
    /// @dev This function can only be called by STAKE_OPS_ADMIN_ROLE
    /// @param _newRatio an integer between 0 and 100000 that represents between 0 and 1000.00% of powr conversion ratio
    function setRatio(
        uint256 _newRatio)
        external
        onlyRole(STAKE_OPS_ADMIN_ROLE)
            {
                require(_newRatio <= 100000, "New Ratio must be <= 100000");
                stkOpsData.powrRatio = _newRatio;
            }

    /// @dev This function returns the current vavlue of stkOpsData.powrRatio
    /// @return currentRatio an integer between 0 and 100000 that represents between 0 and 100.00% of powr conversion ratio
    function getRatio()
        external
        view
        returns (uint256 currentRatio)
            {
                currentRatio = stkOpsData.powrRatio;
                return(currentRatio);
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

    /// @dev This function allows the admin role to change the reward wallet
    /// @param _newRewardWallet address of new reward wallet
    function changeRewardWallet(address _newRewardWallet)
        external
        onlyRole(STAKE_OPS_ADMIN_ROLE){
            stkOpsData.rewardWallet = _newRewardWallet;
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