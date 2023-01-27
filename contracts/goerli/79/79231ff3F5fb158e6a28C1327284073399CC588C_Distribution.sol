// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/utils/auth/ImmutableALCB.sol";
import "contracts/utils/auth/ImmutablePublicStaking.sol";
import "contracts/utils/auth/ImmutableValidatorStaking.sol";
import "contracts/utils/auth/ImmutableLiquidityProviderStaking.sol";
import "contracts/utils/auth/ImmutableFoundation.sol";
import "contracts/interfaces/IDistribution.sol";
import "contracts/utils/MagicEthTransfer.sol";
import "contracts/utils/EthSafeTransfer.sol";
import "contracts/libraries/errors/DistributionErrors.sol";

/// @custom:salt Distribution
/// @custom:deploy-type deployUpgradeable
/// @custom:deploy-group alcb
/// @custom:deploy-group-index 1
contract Distribution is
    IDistribution,
    MagicEthTransfer,
    EthSafeTransfer,
    ImmutableFactory,
    ImmutableALCB,
    ImmutablePublicStaking,
    ImmutableValidatorStaking,
    ImmutableLiquidityProviderStaking,
    ImmutableFoundation
{
    // Scaling factor to get the staking percentages
    uint256 public constant PERCENTAGE_SCALE = 1000;

    // Value of the percentages that will send to each staking contract. Divide
    // this value by PERCENTAGE_SCALE = 1000 to get the corresponding percentages.
    // These values must sum to 1000.
    uint256 internal immutable _protocolFeeSplit;
    uint256 internal immutable _publicStakingSplit;
    uint256 internal immutable _liquidityProviderStakingSplit;
    uint256 internal immutable _validatorStakingSplit;

    constructor(
        uint256 validatorStakingSplit_,
        uint256 publicStakingSplit_,
        uint256 liquidityProviderStakingSplit_,
        uint256 protocolFeeSplit_
    )
        ImmutableFactory(msg.sender)
        ImmutableALCB()
        ImmutablePublicStaking()
        ImmutableValidatorStaking()
        ImmutableLiquidityProviderStaking()
        ImmutableFoundation()
    {
        if (
            validatorStakingSplit_ +
                publicStakingSplit_ +
                liquidityProviderStakingSplit_ +
                protocolFeeSplit_ !=
            PERCENTAGE_SCALE
        ) {
            revert DistributionErrors.SplitValueSumError();
        }
        _validatorStakingSplit = validatorStakingSplit_;
        _publicStakingSplit = publicStakingSplit_;
        _liquidityProviderStakingSplit = liquidityProviderStakingSplit_;
        _protocolFeeSplit = protocolFeeSplit_;
    }

    function depositEth(uint8 magic_) public payable checkMagic(magic_) onlyALCB {
        _distribute();
    }

    /// Gets the value of the percentages that will send to each staking contract.
    /// Divide this value by PERCENTAGE_SCALE = 1000 to get the corresponding
    /// percentages.
    function getSplits() public view returns (uint256, uint256, uint256, uint256) {
        return (
            _validatorStakingSplit,
            _publicStakingSplit,
            _liquidityProviderStakingSplit,
            _protocolFeeSplit
        );
    }

    /// Distributes the yields from the ALCB minting to all stake holders.
    function _distribute() internal returns (bool) {
        uint256 excess = address(this).balance;
        // take out protocolFeeShare from excess and decrement excess
        uint256 protocolFeeShare = (excess * _protocolFeeSplit) / PERCENTAGE_SCALE;
        // split remaining between validators, stakers and lp stakers
        uint256 publicStakingShare = (excess * _publicStakingSplit) / PERCENTAGE_SCALE;
        uint256 lpStakingShare = (excess * _liquidityProviderStakingSplit) / PERCENTAGE_SCALE;
        // then give validators the rest
        uint256 validatorStakingShare = excess -
            (protocolFeeShare + publicStakingShare + lpStakingShare);

        if (protocolFeeShare != 0) {
            _safeTransferEthWithMagic(IMagicEthTransfer(_foundationAddress()), protocolFeeShare);
        }
        if (publicStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_publicStakingAddress()),
                publicStakingShare
            );
        }
        if (lpStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_liquidityProviderStakingAddress()),
                lpStakingShare
            );
        }
        if (validatorStakingShare != 0) {
            _safeTransferEthWithMagic(
                IMagicEthTransfer(_validatorStakingAddress()),
                validatorStakingShare
            );
        }
        // invariants hold
        return true;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IAliceNetFactory {
    function lookup(bytes32 salt_) external view returns (address);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IDistribution {
    function getSplits() external view returns (uint256, uint256, uint256, uint256);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

interface IMagicEthTransfer {
    function depositEth(uint8 magic_) external payable;
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library DistributionErrors {
    error SplitValueSumError();
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library ETHSafeTransferErrors {
    error CannotTransferToZeroAddress();
    error EthTransferFailed(address from, address to, uint256 amount);
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

library MagicValueErrors {
    error BadMagic(uint256 magic);
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";
import "contracts/interfaces/IAliceNetFactory.sol";

abstract contract ImmutableALCB is ImmutableFactory {
    address private immutable _alcb;
    error OnlyALCB(address sender, address expected);

    modifier onlyALCB() {
        if (msg.sender != _alcb) {
            revert OnlyALCB(msg.sender, _alcb);
        }
        _;
    }

    constructor() {
        _alcb = IAliceNetFactory(_factoryAddress()).lookup(_saltForALCB());
    }

    function _alcbAddress() internal view returns (address) {
        return _alcb;
    }

    function _saltForALCB() internal pure returns (bytes32) {
        return 0x414c434200000000000000000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";

abstract contract ImmutableFactory is DeterministicAddress {
    address private immutable _factory;
    error OnlyFactory(address sender, address expected);

    modifier onlyFactory() {
        if (msg.sender != _factory) {
            revert OnlyFactory(msg.sender, _factory);
        }
        _;
    }

    constructor(address factory_) {
        _factory = factory_;
    }

    function _factoryAddress() internal view returns (address) {
        return _factory;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableFoundation is ImmutableFactory {
    address private immutable _foundation;
    error OnlyFoundation(address sender, address expected);

    modifier onlyFoundation() {
        if (msg.sender != _foundation) {
            revert OnlyFoundation(msg.sender, _foundation);
        }
        _;
    }

    constructor() {
        _foundation = getMetamorphicContractAddress(
            0x466f756e646174696f6e00000000000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _foundationAddress() internal view returns (address) {
        return _foundation;
    }

    function _saltForFoundation() internal pure returns (bytes32) {
        return 0x466f756e646174696f6e00000000000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableLiquidityProviderStaking is ImmutableFactory {
    address private immutable _liquidityProviderStaking;
    error OnlyLiquidityProviderStaking(address sender, address expected);

    modifier onlyLiquidityProviderStaking() {
        if (msg.sender != _liquidityProviderStaking) {
            revert OnlyLiquidityProviderStaking(msg.sender, _liquidityProviderStaking);
        }
        _;
    }

    constructor() {
        _liquidityProviderStaking = getMetamorphicContractAddress(
            0x4c697175696469747950726f76696465725374616b696e670000000000000000,
            _factoryAddress()
        );
    }

    function _liquidityProviderStakingAddress() internal view returns (address) {
        return _liquidityProviderStaking;
    }

    function _saltForLiquidityProviderStaking() internal pure returns (bytes32) {
        return 0x4c697175696469747950726f76696465725374616b696e670000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutablePublicStaking is ImmutableFactory {
    address private immutable _publicStaking;
    error OnlyPublicStaking(address sender, address expected);

    modifier onlyPublicStaking() {
        if (msg.sender != _publicStaking) {
            revert OnlyPublicStaking(msg.sender, _publicStaking);
        }
        _;
    }

    constructor() {
        _publicStaking = getMetamorphicContractAddress(
            0x5075626c69635374616b696e6700000000000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _publicStakingAddress() internal view returns (address) {
        return _publicStaking;
    }

    function _saltForPublicStaking() internal pure returns (bytes32) {
        return 0x5075626c69635374616b696e6700000000000000000000000000000000000000;
    }
}

// This file is auto-generated by hardhat generate-immutable-auth-contract task. DO NOT EDIT.
// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/DeterministicAddress.sol";
import "contracts/utils/auth/ImmutableFactory.sol";

abstract contract ImmutableValidatorStaking is ImmutableFactory {
    address private immutable _validatorStaking;
    error OnlyValidatorStaking(address sender, address expected);

    modifier onlyValidatorStaking() {
        if (msg.sender != _validatorStaking) {
            revert OnlyValidatorStaking(msg.sender, _validatorStaking);
        }
        _;
    }

    constructor() {
        _validatorStaking = getMetamorphicContractAddress(
            0x56616c696461746f725374616b696e6700000000000000000000000000000000,
            _factoryAddress()
        );
    }

    function _validatorStakingAddress() internal view returns (address) {
        return _validatorStaking;
    }

    function _saltForValidatorStaking() internal pure returns (bytes32) {
        return 0x56616c696461746f725374616b696e6700000000000000000000000000000000;
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

abstract contract DeterministicAddress {
    function getMetamorphicContractAddress(
        bytes32 _salt,
        address _factory
    ) public pure returns (address) {
        // byte code for metamorphic contract
        // 6020363636335afa1536363636515af43d36363e3d36f3
        bytes32 metamorphicContractBytecodeHash_ = 0x1c0bf703a3415cada9785e89e9d70314c3111ae7d8e04f33bb42eb1d264088be;
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(
                                hex"ff",
                                _factory,
                                _salt,
                                metamorphicContractBytecodeHash_
                            )
                        )
                    )
                )
            );
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/ETHSafeTransferErrors.sol";

abstract contract EthSafeTransfer {
    /// @notice _safeTransferEth performs a transfer of Eth using the call
    /// method / this function is resistant to breaking gas price changes and /
    /// performs call in a safe manner by reverting on failure. / this function
    /// will return without performing a call or reverting, / if amount_ is zero
    function _safeTransferEth(address to_, uint256 amount_) internal {
        if (amount_ == 0) {
            return;
        }
        if (to_ == address(0)) {
            revert ETHSafeTransferErrors.CannotTransferToZeroAddress();
        }
        address payable caller = payable(to_);
        (bool success, ) = caller.call{value: amount_}("");
        if (!success) {
            revert ETHSafeTransferErrors.EthTransferFailed(address(this), to_, amount_);
        }
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;

import "contracts/utils/MagicValue.sol";
import "contracts/interfaces/IMagicEthTransfer.sol";

abstract contract MagicEthTransfer is MagicValue {
    function _safeTransferEthWithMagic(IMagicEthTransfer to_, uint256 amount_) internal {
        to_.depositEth{value: amount_}(_getMagic());
    }
}

// SPDX-License-Identifier: MIT-open-group
pragma solidity ^0.8.16;
import "contracts/libraries/errors/MagicValueErrors.sol";

abstract contract MagicValue {
    // _MAGIC_VALUE is a constant that may be used to prevent
    // a user from calling a dangerous method without significant
    // effort or ( hopefully ) reading the code to understand the risk
    uint8 internal constant _MAGIC_VALUE = 42;

    modifier checkMagic(uint8 magic_) {
        if (magic_ != _getMagic()) {
            revert MagicValueErrors.BadMagic(magic_);
        }
        _;
    }

    // _getMagic returns the magic constant
    function _getMagic() internal pure returns (uint8) {
        return _MAGIC_VALUE;
    }
}