// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

import "../vault/interfaces/IExternalPositionVault.sol";
import "./IExternalPosition.sol";
import "./IExternalPositionProxy.sol";

/// @title ExternalPositionProxy Contract
/// @author Enzyme Council <[email protected]>
/// @notice A proxy for all external positions, modified from EIP-1822
contract ExternalPositionProxy is IExternalPositionProxy {
    uint256 private immutable EXTERNAL_POSITION_TYPE;
    address private immutable VAULT_PROXY;

    /// @dev Needed to receive ETH on external positions
    receive() external payable {}

    constructor(
        address _vaultProxy,
        uint256 _typeId,
        address _constructLib,
        bytes memory _constructData
    ) public {
        VAULT_PROXY = _vaultProxy;
        EXTERNAL_POSITION_TYPE = _typeId;

        (bool success, bytes memory returnData) = _constructLib.delegatecall(_constructData);

        require(success, string(returnData));
    }

    // solhint-disable-next-line no-complex-fallback
    fallback() external payable {
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        assembly {
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(
                sub(gas(), 10000),
                contractLogic,
                0x0,
                calldatasize(),
                0,
                0
            )
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
                case 0 {
                    revert(0, retSz)
                }
                default {
                    return(0, retSz)
                }
        }
    }

    /// @notice Delegates call to IExternalPosition.receiveCallFromVault
    /// @param _data The bytes data variable to be decoded at the External Position
    function receiveCallFromVault(bytes calldata _data) external {
        require(
            msg.sender == getVaultProxy(),
            "receiveCallFromVault: Only the vault can make this call"
        );
        address contractLogic = IExternalPositionVault(getVaultProxy())
            .getExternalPositionLibForType(getExternalPositionType());
        (bool success, bytes memory returnData) = contractLogic.delegatecall(
            abi.encodeWithSelector(IExternalPosition.receiveCallFromVault.selector, _data)
        );

        require(success, string(returnData));
    }

    ///////////////////
    // STATE GETTERS //
    ///////////////////

    /// @notice Gets the `EXTERNAL_POSITION_TYPE` variable
    /// @return externalPositionType_ The `EXTERNAL_POSITION_TYPE` variable value
    function getExternalPositionType()
        public
        view
        override
        returns (uint256 externalPositionType_)
    {
        return EXTERNAL_POSITION_TYPE;
    }

    /// @notice Gets the `VAULT_PROXY` variable
    /// @return vaultProxy_ The `VAULT_PROXY` variable value
    function getVaultProxy() public view override returns (address vaultProxy_) {
        return VAULT_PROXY;
    }
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.

    (c) Enzyme Council <[email protected]>

    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionVault interface
/// @author Enzyme Council <[email protected]>
/// Provides an interface to get the externalPositionLib for a given type from the Vault
interface IExternalPositionVault {
    function getExternalPositionLibForType(uint256) external view returns (address);
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPosition Contract
/// @author Enzyme Council <[email protected]>
interface IExternalPosition {
    function getDebtAssets() external returns (address[] memory, uint256[] memory);

    function getManagedAssets() external returns (address[] memory, uint256[] memory);

    function init(bytes memory) external;

    function receiveCallFromVault(bytes memory) external;
}

// SPDX-License-Identifier: GPL-3.0

/*
    This file is part of the Enzyme Protocol.
    (c) Enzyme Council <[email protected]>
    For the full license information, please view the LICENSE
    file that was distributed with this source code.
*/

pragma solidity 0.6.12;

/// @title IExternalPositionProxy interface
/// @author Enzyme Council <[email protected]>
/// @notice An interface for publicly accessible functions on the ExternalPositionProxy
interface IExternalPositionProxy {
    function getExternalPositionType() external view returns (uint256);

    function getVaultProxy() external view returns (address);
}