// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/**
 * @title Liquid staking pool
 *
 * For the high-level description of the pool operation please refer to the paper.
 * Pool manages withdrawal keys and fees. It receives ether submitted by users on the ETH 1 side
 * and stakes it via the validator_registration.vy contract. It doesn't hold ether on it's balance,
 * only a small portion (buffer) of it.
 * It also mints new tokens for rewards generated at the ETH 2.0 side.
 */
interface ILido {
    /**
     * @notice Stop pool routine operations
     */
    function stop() external;

    /**
     * @notice Resume pool routine operations
     */
    function resume() external;

    event Stopped();
    event Resumed();

    /**
     * @notice Set fee rate to `_feeBasisPoints` basis points. The fees are accrued when oracles report staking results
     * @param _feeBasisPoints Fee rate, in basis points
     */
    function setFee(uint16 _feeBasisPoints) external;

    /**
     * @notice Set fee distribution: `_treasuryFeeBasisPoints` basis points go to the treasury, `_insuranceFeeBasisPoints` basis points go to the insurance fund, `_operatorsFeeBasisPoints` basis points go to node operators. The sum has to be 10 000.
     */
    function setFeeDistribution(
        uint16 _treasuryFeeBasisPoints,
        uint16 _insuranceFeeBasisPoints,
        uint16 _operatorsFeeBasisPoints
    ) external;

    /**
     * @notice Returns staking rewards fee rate
     */
    function getFee() external view returns (uint16 feeBasisPoints);

    /**
     * @notice Returns fee distribution proportion
     */
    function getFeeDistribution()
        external
        view
        returns (
            uint16 treasuryFeeBasisPoints,
            uint16 insuranceFeeBasisPoints,
            uint16 operatorsFeeBasisPoints
        );

    event FeeSet(uint16 feeBasisPoints);

    event FeeDistributionSet(
        uint16 treasuryFeeBasisPoints,
        uint16 insuranceFeeBasisPoints,
        uint16 operatorsFeeBasisPoints
    );

    event WithdrawalCredentialsSet(bytes withdrawalCredentials);

    /**
     * @notice Ether on the ETH 2.0 side reported by the oracle
     * @param _epoch Epoch id
     * @param _eth2balance Balance in wei on the ETH 2.0 side
     */
    function reportEther2(uint256 _epoch, uint256 _eth2balance) external;

    // User functions

    /**
     * @notice Adds eth to the pool
     * @return StETH Amount of StETH generated
     */
    function submit(address _referral) external payable returns (uint256 StETH);

    // Records a deposit made by a user
    event Submitted(address indexed sender, uint256 amount, address referral);

    // The `_amount` of ether was sent to the validator_registration.deposit function.
    event Unbuffered(uint256 amount);

    /**
     * @notice Issues withdrawal request. Large withdrawals will be processed only after the phase 2 launch.
     * @param _amount Amount of StETH to burn
     * @param _pubkeyHash Receiving address
     */
    function withdraw(uint256 _amount, bytes32 _pubkeyHash) external;

    // Requested withdrawal of `etherAmount` to `pubkeyHash` on the ETH 2.0 side, `tokenAmount` burned by `sender`,
    // `sentFromBuffer` was sent on the current Ethereum side.
    event Withdrawal(
        address indexed sender,
        uint256 tokenAmount,
        uint256 sentFromBuffer,
        bytes32 indexed pubkeyHash,
        uint256 etherAmount
    );

    // Info functions

    /**
     * @notice Gets the amount of Ether controlled by the system
     */
    function getTotalControlledEther() external view returns (uint256);

    /**
     * @notice Gets the amount of Ether temporary buffered on this contract balance
     */
    function getBufferedEther() external view returns (uint256);

    /**
     * @notice Gets the stat of the system's Ether on the Ethereum 2 side
     * @return deposited Amount of Ether deposited from the current Ethereum
     * @return remote Amount of Ether currently present on the Ethereum 2 side (can be 0 if the Ethereum 2 is yet to be launched)
     */
    function getEther2Stat()
        external
        view
        returns (uint256 deposited, uint256 remote);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ILido.sol";

contract LidoProxy {
    ILido public lido;
    address owner;
    uint256 public feeRate;
    event FeeRateUpdated(uint256 _feeRate);
    address payable public feeReceiver;
    address public referral;

    constructor(ILido _lido, uint256 _feeRate, address payable _feeReceiver) {
        lido = _lido;
        feeRate = _feeRate;
        feeReceiver = _feeReceiver;
    }

    function updateFeeRate(uint256 _feeRate) public onlyOwner {
        feeRate = _feeRate;
        emit FeeRateUpdated(_feeRate);
    }

    function updateReferral(address _referral) public {
        referral = _referral;
    }

    //    function deposit(address _referral) external payable returns (uint256 StETH) {
    //        uint256 stMount = lido.submit.value(msg.value)(_referral);
    //        require(stMount > 0, "deposit failed");
    //        return stMount;
    //    }

    function getFees() external view returns (uint16) {
        uint16 fee = lido.getFee();
        return fee;
    }

    fallback() external payable {
        uint256 fee = (msg.value * feeRate) / 100;
        feeReceiver.transfer(fee);
        // stake
        uint256 stMount = lido.submit{value: msg.value - fee}(referral);
        require(stMount > 0, "deposit failed");
    }

    function unstake(uint256 amount) external {
        lido.withdraw(amount, bytes32(uint256(uint160(msg.sender)) << 96));
        // payable(msg.sender).transfer(amount);
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
}