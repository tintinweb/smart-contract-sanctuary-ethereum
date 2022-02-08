// SPDX-License-Identifier: UNLICENCED
pragma solidity =0.8.11;

import { IUniswapV2Pair } from "./IUniswapV2Pair.sol";
import { IERC20 } from "./IERC20.sol";
import { IStakingContractV1 } from "./IStakingContractV1.sol";
import { Pausable } from "./Pausable.sol";
import { StakeDefinitions } from "./StakeStructs.sol";
import { Ownable } from "./Ownable.sol";
import { StakeOpsController } from "./StakeOpsController.sol";

contract StakingContractV1 is StakeDefinitions, IStakingContractV1, StakeOpsController, Pausable {

    IERC20 public immutable powrToken;

    // Same decimal precision as the POWR ERC20 Token
    uint256 public constant unit = 1000000;

    StakeDefinitions.StakingOpsInfo public stkOpsData;

    mapping(address => StakeDefinitions.StakeInfo) public stkData;

    mapping(string => uint256) public validatorTotalStake;

    mapping (string =>  address) public stakeAddressToEthAddress;

    /// @dev payable fallback function that ensures no ETH is sent to the contract accidentally
    receive() external payable {
        revert("StakingContractV1: Rejecting ETH deposits.");
    }

    /// @dev non-payable fallback function that ensures any attempt to call a function that does not exist will fail
    fallback () external {
        revert("StakingContractV1: Rejecting fallback executions.");
    }

    /// @dev Verifies the following conditions:
    /// 1) The amount being deposited must be > 0
    /// 2) The amount being deposited must be > minimum POWR tokens deposit limit
    /// 3) The amount being deposited will not cause the chosen validator to exceed the maximum allowed stake
    /// 4) The address has not been used for staking before
    modifier checkDepositConditions(
        address _addr,
        uint256 _amount,
        string memory _validatorPubKey) {
        require(_amount > 0, "StakingContractV1:checkDepositConditions: Amount must be > 0");
        require(_amount >= stkOpsData.minPowrDeposit, "StakingContractV1:checkDepositConditions: Amount must be at least the min deposit requirement");
        require(validatorTotalStake[_validatorPubKey] + _amount <= stkOpsData.maxPowrPerValidator, "StakingContractV1:checkDepositConditions: Total stake cannot exceed max stake per validator");
        require(stkData[_addr].stakeStatus == StakeStatus.NeverStaked, "StakingContractV1:checkDepositConditions: Address can only stake once");
        _;
    }

    /// @dev Verifies the following conditions:
    /// 1) User has stake + rewards 
    /// 2) stakeStatus is equal to Unstaked
    modifier checkWithdrawalConditions(address _addr) {
        require(stkData[_addr].stakeStatus != StakeStatus.Withdrawn, "StakingContractV1:checkWithdrawalConditions: Stake already withdrawn");
        require(stkData[_addr].stakeStatus == StakeStatus.Unstaked, "StakingContractV1:checkWithdrawalConditions: Stake has not been unstaked or cannot be found");
        require(stkData[_addr].stake + stkData[_addr].stakeRewards > 0, "StakingContractV1:checkWithdrawalConditions: No stake to withdraw");
        require(block.timestamp >= (stkData[_addr].unstakeTimestamp + (7*24*60*60)), "StakingContractV1:checkWithdrawalConditions: 7 days need to pass before you can withdraw");
        require(stkData[_addr].stake + stkData[_addr].stakeRewards > uint(convertEthToPOWR(stkData[_addr].ethFee)), "StakingContractV1:checkWithdrawalConditions: your staking rewards and stake amount do not cover the transaction fee");
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
        address _powrEthPoolAddress)
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
    }

    /// @dev The First step into staking, wanna-be staker must sent POWR tokens to this contract using this deposit function.
    /// @param _amount The amount of POWR tokens to stake. If the amount to stake is 1 POWR token then the value of this parameter should be 1x10^6
    /// @param _stakerPubKey The solana public key
    /// @param _validatorPubKey The public key from the PLChain Node
    function deposit(
        uint256 _amount, 
        string memory _stakerPubKey,
        string memory _validatorPubKey)
            external
            override
            whenNotPaused
            checkDepositConditions(_msgSender(), _amount, _validatorPubKey)
            {
                address stakerEthAddress = _msgSender();
                /// require amount of tokens in account ready to deposit
                require(powrToken.transferFrom(stakerEthAddress, address(this), _amount), "StakingContractV1:deposit: Can't transfer the POWR tokens");

                // First deposit
                stkData[stakerEthAddress] = StakeDefinitions.StakeInfo({
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
    /// @param _stakerEthAddress The eth address of the staker that has unstaked their POWR and it has finished unstaking on the plchain
    /// @param _rewardAmount The amount of rewards accrued (in base units i.e. 1 POWR = 10^6)
    function unlockStake(
        address _stakerEthAddress, 
        uint256 _rewardAmount)
            external
            whenNotPaused
            onlyRole(BALANCE_UPDATER_ROLE)
            {
                require(stkData[_stakerEthAddress].stakeStatus == StakeStatus.Deposited, "StakingContractV1:unlockStake Stake must be in 'deposited' state");
                //set status to unstaked, set reward amount
                uint256 contractBalance = powrToken.balanceOf(address(this));
                require(_rewardAmount <= (contractBalance - stkOpsData.totalStaked), "StakingContractV1:unlockStake cannot set reward amount to more rewards than available");
                stkData[_stakerEthAddress].stakeStatus = StakeStatus.Unstaked;
                stkData[_stakerEthAddress].stakeRewards = _rewardAmount;
                stkData[_stakerEthAddress].ethFee = 117582*tx.gasprice;
                stkData[_stakerEthAddress].unstakeTimestamp = block.timestamp;


                //update contract stats
                stkOpsData.stakeCount = stkOpsData.stakeCount - 1;
                stkOpsData.totalStaked = stkOpsData.totalStaked - stkData[_stakerEthAddress].stake;
                validatorTotalStake[stkData[_stakerEthAddress].registeredStakerValidatorPubKey] = validatorTotalStake[stkData[_stakerEthAddress].registeredStakerValidatorPubKey] - stkData[_stakerEthAddress].stake;

                //emit event
                emit UnlockStake(_stakerEthAddress, stkData[_stakerEthAddress].stake, stkData[_stakerEthAddress].registeredStaker);
    }

    /// @dev This function can be called after the unlockStake transaction has been sent by the bridge
    /// @dev This function ensures that the fee collection is not greater than withdrawal amount
    /// @dev This function tranfers the stake and rewards minus the fee in POWR back to eth address.
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

            // attempt to transfer powr back
            require(powrToken.transfer(stakerEthAddress, stakeAmount + rewardAmount - powrFee), "StakingContractV1:withdraw Can't transfer POWR tokens");

            // emit event
            emit StakeWithdrawn(stakerEthAddress, stakeAmount, rewardAmount);
    }
    
    /// @dev This function is called in an emergency to force a user to unstake their POWR. This is called by the STAKE_OPS_ADMIN_ROLE and updates the reward amounts
    /// @dev This function sets the rewards + stake minus the fee to be withdrawn by the user using the withdraw() function
    /// @param _stakerEthAddress The eth address of the staker that has unstaked their POWR and it has finished unstaking on the plchain
    /// @param _rewardAmount The amount of rewards accrued (in base units i.e. 1 POWR = 10^6)
    function forceUnlockStake(
        address _stakerEthAddress, 
        uint256 _rewardAmount)
            external
            onlyRole(STAKE_OPS_ADMIN_ROLE) 
            {
                require(stkData[_stakerEthAddress].stakeStatus == StakeStatus.Deposited || stkData[_stakerEthAddress].stakeStatus == StakeStatus.Unstaked, "StakingContractV1:forceUnlockStake: Stake must be in 'deposited' or 'unstaked' state");
                //set status to unstaked, set reward amount
                uint256 contractBalance = powrToken.balanceOf(address(this));
                require(_rewardAmount <= (contractBalance - stkOpsData.totalStaked), "StakingContractV1:forceUnlockStake cannot set reward amount to more rewards than available");
                stkData[_stakerEthAddress].stakeStatus = StakeStatus.Unstaked;
                stkData[_stakerEthAddress].stakeRewards = _rewardAmount;
                stkData[_stakerEthAddress].ethFee = 117582*tx.gasprice;
                stkData[_stakerEthAddress].unstakeTimestamp = block.timestamp;

                //update internal contract status
                stkOpsData.stakeCount = stkOpsData.stakeCount - 1;
                stkOpsData.totalStaked = stkOpsData.totalStaked - stkData[_stakerEthAddress].stake;
                validatorTotalStake[stkData[_stakerEthAddress].registeredStakerValidatorPubKey] = validatorTotalStake[stkData[_stakerEthAddress].registeredStakerValidatorPubKey] - stkData[_stakerEthAddress].stake;


                //emit event
                emit UnlockStake(_stakerEthAddress, stkData[_stakerEthAddress].stake, stkData[_stakerEthAddress].registeredStaker);
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
    /// @param _ethAmount The amount of ether (in wei) to convert to usdc
    /// @return powrAmount the amount of powr in base units (6 decimals)
    function convertEthToPOWR(uint256 _ethAmount) 
        public 
        view 
        returns(uint256 powrAmount)
        {
            IUniswapV2Pair pair = IUniswapV2Pair(stkOpsData.powrEthPool);
            (uint112 res0, uint112 res1,) = pair.getReserves();
            powrAmount = (_ethAmount*res0)/(res1); // return amount of POWR needed to buy _ethAmount in base unit (i.e. 1 POWR = 10^6)
            return(powrAmount);
        }

    /// @dev This function takes an integer between 0 and 10000 and updates the powrRatio for reward distribution.
    /// @dev This function can only be called by STAKE_OPS_ADMIN_ROLE
    /// @param _newRatio an integer between 0 and 10000 that represents between 0 and 100.00% of powr conversion ratio
    function setRatio(
        uint256 _newRatio)
        external
        whenNotPaused
        onlyRole(STAKE_OPS_ADMIN_ROLE)
            {
                require(_newRatio >= 0, "New Ratio must be above zero");
                require(_newRatio <= 10000, "New Ratio must be below 10000");
                stkOpsData.powrRatio = _newRatio;
            }

    /// @dev This function takes an integer between 0 and 10000 and updates the powrRatio for reward distribution.
    /// @dev This function can only be called by STAKE_OPS_ADMIN_ROLE
    /// @return newRatio an integer between 0 and 10000 that represents between 0 and 100.00% of powr conversion ratio
    function getRatio()
        external
        view
        returns (uint256 newRatio)                            
            {
                newRatio = stkOpsData.powrRatio;
                return(newRatio);
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