pragma solidity ^0.8.0;

import {IExchange} from "../../interfaces/IExchange.sol";
import {TokenVaultExchangeProxy} from "./../proxy/TokenVaultExchangeProxy.sol";

library TokenVaultExchangeLogic {
    //
    function newExchangeInstance(address settings, address vaultToken)
        external
        returns (address)
    {
        bytes memory _initializationCalldata = abi.encodeWithSignature(
            "initialize(address)",
            vaultToken
        );
        address exchange = address(
            new TokenVaultExchangeProxy(settings, _initializationCalldata)
        );
        return exchange;
    }

    function addRewardToken(address exchange, address token) external {
        IExchange(exchange).addRewardToken(token);
    }
}

pragma solidity ^0.8.0;

import {InitializedProxy} from "./InitializedProxy.sol";
import {IImpls} from "../../interfaces/IImpls.sol";

/**
 * @title InitializedProxy
 */
contract TokenVaultExchangeProxy is InitializedProxy {
    constructor(address _settings, bytes memory _initializationCalldata)
        InitializedProxy(_settings, _initializationCalldata)
    {}

    function getImpl() public view override returns (address) {
        return IImpls(settings).exchangeImpl();
    }
}

pragma solidity ^0.8.0;

/**
 * @title SettingStorage
 * @author 0xkongamoto
 */
contract SettingStorage {
    // address of logic contract
    address public immutable settings;

    // ======== Constructor =========

    constructor(address _settings) {
        require(_settings != address(0), "no zero address");
        settings = _settings;
    }
}

pragma solidity ^0.8.0;

import {SettingStorage} from "./SettingStorage.sol";

/**
 * @title InitializedProxy
 * @author 0xkongamoto
 */
contract InitializedProxy is SettingStorage {
    // ======== Constructor =========
    constructor(address _settings, bytes memory _initializationCalldata)
        SettingStorage(_settings)
    {
        // Delegatecall into the logic contract, supplying initialization calldata
        (bool _ok, bytes memory returnData) = getImpl().delegatecall(
            _initializationCalldata
        );
        // Revert if delegatecall to implementation reverts
        require(_ok, string(returnData));
    }

    function getImpl() public view virtual returns (address) {
        return settings;
    }

    // ======== Fallback =========

    fallback() external payable {
        address _impl = getImpl();
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }

    // ======== Receive =========

    receive() external payable {} // solhint-disable-line no-empty-blocks
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IImpls {
    function vaultImpl() external view returns (address);

    function stakingImpl() external view returns (address);

    function treasuryImpl() external view returns (address);

    function governmentImpl() external view returns (address);

    function exchangeImpl() external view returns (address);
}

pragma solidity ^0.8.0;

interface IExchange {
    //
    function shareExchangeFeeRewardToken() external;

    function getNewShareExchangeFeeRewardToken(address token)
        external
        view
        returns (uint256);

    function addRewardToken(address _addr) external;
}