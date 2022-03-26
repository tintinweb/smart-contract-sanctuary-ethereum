// SPDX-License-Identifier: No License
/**
 * @title Vendor Factory Contract
 * @author JeffX
 * The legend says that you'r pipi shrinks and boobs get saggy if you fork this contract.
 */
pragma solidity ^0.8.11;

import "./interfaces/IPoolFactory.sol";

contract VendorFeesManager {
    /// @notice Error for if address is not a pool
    error NotAPool();
    /// @notice Error for if address is not the deployer
    error NotDeployer();
    /// @notice Error for if factory has already been set
    error FactoryAlreadySet();
    /// @notice Error for if pool is closed
    error PoolClosed();
    /// @notice Error for if address is not the pool factory or the pool address that is being modified
    error NotPoolFactoryOrPoolItself();
    /// @notice Error for if array length is invalid
    error InvalidArray();

    /// @notice Address of the deployer
    address public deployer;
    /// @notice Pool Factory
    IPoolFactory public factory;
    /// @notice If an address has constant fee or linear decaying fee
    mapping(address => bool) public rateFunction; // false for constant and true for linear decay
    /// @notice A pool address to its starting fee and floor fee, if decaying fee
    mapping(address => uint256[]) public feeRates;

    constructor() {
        deployer = msg.sender;
    }

    /// @notice          Sets the address of the factory
    /// @param _factory  Address of the Vendor Pool Factory
    function initialize(IPoolFactory _factory) external {
        if (deployer != msg.sender) revert NotDeployer();
        if (address(factory) != address(0)) revert FactoryAlreadySet();
        factory = _factory;
    }

    /// @notice           During deployment of pool sets fee details
    /// @param _pool      Address of pool
    /// @param _feeRates  Array for starting fee and floor fee, if decaying fee
    function setPoolFees(address _pool, uint256[] calldata _feeRates) external {
        if (_feeRates.length != feeRates[_pool].length) revert InvalidArray();
        if (msg.sender == address(factory) || _pool == msg.sender) {
            feeRates[_pool] = _feeRates;
        } else {
            revert NotPoolFactoryOrPoolItself();
        }
    }

    /// @notice                  Returns the fee for a pool for a given amount
    /// @param _pool             Address of pool
    /// @param _rawPayoutAmount  Raw amount of payout tokens before fee
    /// @param _startTime        Start time of `_pool`
    /// @param _expiry           End time of `_pool`
    /// @return                  Fee owed
    function getFee(
        address _pool,
        uint256 _rawPayoutAmount,
        uint256 _startTime,
        uint256 _expiry
    ) external view returns (uint256) {
        if (!factory.pools(_pool)) revert NotAPool();
        if (block.timestamp > _expiry) revert PoolClosed();

        if (!rateFunction[_pool]) {
            return (_rawPayoutAmount * feeRates[_pool][0]) / 10000;
        } else {
            return getLinearFee(_pool, _rawPayoutAmount, _startTime, _expiry);
        }
    }

    /// @notice                  Returns the fee for a pool for a given amount
    /// @param _pool             Address of pool
    /// @param _rawPayoutAmount  Raw amount of payout tokens before fee
    /// @param _startTime        Start time of `_pool`
    /// @param _expiry           End time of `_pool`
    /// @return                  Fee owed
    function getLinearFee(
        address _pool,
        uint256 _rawPayoutAmount,
        uint256 _startTime,
        uint256 _expiry
    ) private view returns (uint256) {
        uint256 poolLength = _expiry - _startTime;
        uint256 timeRemaining = _expiry - block.timestamp;
        uint256 feeRate = (timeRemaining * feeRates[_pool][0]) / poolLength;
        uint256 endFee = feeRates[_pool][1];
        return
            (feeRate > endFee)
                ? (_rawPayoutAmount * feeRate) / 10000
                : (_rawPayoutAmount * endFee) / 10000;
    }

    function getCurrentRate(
        address _pool,
        uint256 _startTime,
        uint256 _expiry
    ) external view returns (uint256) {
        if (!rateFunction[_pool]) {
            return feeRates[_pool][0];
        } else {
            uint256 poolLength = _expiry - _startTime;
            uint256 timeRemaining = _expiry - block.timestamp;
            return (timeRemaining * feeRates[_pool][0]) / poolLength;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPoolFactory {
   
    function pools(address _pool) external view returns (bool);

    function poolImplementationAddress() external view returns (address);

    function rollBackImplementation() external view returns (address);

    function allowUpgrade() external view returns (bool);

    function isPaused(address _pool) external view returns (bool);
}