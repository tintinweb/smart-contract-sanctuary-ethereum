// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Library for converting between addresses and bytes32 values.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/Bytes32AddressLib.sol)
library Bytes32AddressLib {
    function fromLast20Bytes(bytes32 bytesValue) internal pure returns (address) {
        return address(uint160(uint256(bytesValue)));
    }

    function fillLast12Bytes(address addressValue) internal pure returns (bytes32) {
        return bytes32(bytes20(addressValue));
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.4;

library Errors {
    // Auth
    error CombineRestricted();
    error IssuanceRestricted();
    error NotAuthorized();
    error OnlyYT();
    error OnlyDivider();
    error OnlyPeriphery();
    error OnlyPermissionless();
    error RedeemRestricted();
    error Untrusted();

    // Adapters
    error TokenNotSupported();
    error FlashCallbackFailed();
    error SenderNotEligible();
    error TargetMismatch();
    error TargetNotSupported();
    error InvalidAdapterType();
    error PriceOracleNotFound();

    // Divider
    error AlreadySettled();
    error CollectNotSettled();
    error GuardCapReached();
    error IssuanceFeeCapExceeded();
    error IssueOnSettle();
    error NotSettled();

    // Input & validations
    error AlreadyInitialized();
    error DuplicateSeries();
    error ExistingValue();
    error InvalidAdapter();
    error InvalidMaturity();
    error InvalidParam();
    error NotImplemented();
    error OutOfWindowBoundaries();
    error SeriesDoesNotExist();
    error SwapTooSmall();
    error TargetParamsNotSet();
    error PoolParamsNotSet();
    error PTParamsNotSet();
    error AttemptFailed();
    error InvalidPrice();
    error BadContractInteration();

    // Periphery
    error FactoryNotSupported();
    error FlashBorrowFailed();
    error FlashUntrustedBorrower();
    error FlashUntrustedLoanInitiator();
    error UnexpectedSwapAmount();
    error TooMuchLeftoverTarget();

    // Fuse
    error AdapterNotSet();
    error FailedBecomeAdmin();
    error FailedAddTargetMarket();
    error FailedToAddPTMarket();
    error FailedAddLpMarket();
    error OracleNotReady();
    error PoolAlreadyDeployed();
    error PoolNotDeployed();
    error PoolNotSet();
    error SeriesNotQueued();
    error TargetExists();
    error TargetNotInFuse();

    // Tokens
    error MintFailed();
    error RedeemFailed();
    error TransferFailed();
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

// Internal references
// import { Divider } from "../../../Divider.sol";
// import { ERC4626Adapter } from "../erc4626/ERC4626Adapter.sol";
// import { BaseAdapter } from "../../abstract/BaseAdapter.sol";
// import { ExtractableReward } from "../../abstract/extensions/ExtractableReward.sol";
// import { BaseFactory } from "./BaseFactory.sol";
import { Errors } from "@sense-finance/v1-utils/libs/Errors.sol";

// External references
import { Bytes32AddressLib } from "solmate/utils/Bytes32AddressLib.sol";

contract ERC4626Factory {
    using Bytes32AddressLib for address;

    mapping(address => bool) public supportedTargets;

    constructor(
        address _divider,
        address _restrictedAdmin,
        address _rewardsRecipient   
        // FactoryParams memory _factoryParams
    ) {}
    //  BaseFactory(_divider, _restrictedAdmin, _rewardsRecipient, _factoryParams) {}

    // / @notice Deploys an ERC4626Adapter contract
    // / @param _target The target address
    // / @param data ABI encoded reward tokens address array
    // function deployAdapter(address _target, bytes memory data) external virtual override returns (address adapter) {
    //     /// Sanity checks
    //     if (Divider(divider).periphery() != msg.sender) revert Errors.OnlyPeriphery();
    //     if (!Divider(divider).permissionless() && !supportedTargets[_target]) revert Errors.TargetNotSupported();

    //     BaseAdapter.AdapterParams memory adapterParams = BaseAdapter.AdapterParams({
    //         oracle: factoryParams.oracle,
    //         stake: factoryParams.stake,
    //         stakeSize: factoryParams.stakeSize,
    //         minm: factoryParams.minm,
    //         maxm: factoryParams.maxm,
    //         mode: factoryParams.mode,
    //         tilt: factoryParams.tilt,
    //         level: DEFAULT_LEVEL
    //     });

    //     // Use the CREATE2 opcode to deploy a new Adapter contract.
    //     // This will revert if an ERC4626 adapter with the provided target has already
    //     // been deployed, as the salt would be the same and we can't deploy with it twice.
    //     adapter = address(
    //         new ERC4626Adapter{ salt: _target.fillLast12Bytes() }(
    //             divider,
    //             _target,
    //             rewardsRecipient,
    //             factoryParams.ifee,
    //             adapterParams
    //         )
    //     );

    //     _setGuard(adapter);

    //     ExtractableReward(adapter).setIsTrusted(restrictedAdmin, true);
    // }

    // /// @notice (Un)support target
    // /// @param _target The target address
    // /// @param supported Whether the target should be supported or not
    // function supportTarget(address _target, bool supported) external {
    //     supportedTargets[_target] = supported;
    //     emit TargetSupported(_target, supported);
    // }

    // /// @notice (Un)support multiple target at once
    // /// @param _targets Array of target addresses
    // /// @param supported Whether the targets should be supported or not
    // function supportTargets(address[] memory _targets, bool supported) external {
    //     for (uint256 i = 0; i < _targets.length; i++) {
    //         supportedTargets[_targets[i]] = supported;
    //         emit TargetSupported(_targets[i], supported);
    //     }
    // }

    // /* ========== LOGS ========== */

    event TargetSupported(address indexed target, bool indexed supported);
}