/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// Verified using https://dapp.tools

// hevm: flattened sources of src/RelayerGuard.sol
// SPDX-License-Identifier: Apache-2.0 AND Unlicensed AND AGPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0 >=0.8.4 <0.9.0;

////// lib/delphi/src/relayer/IRelayer.sol
/* pragma solidity ^0.8.0; */

interface IRelayer {
    enum RelayerType {
        DiscountRate,
        SpotPrice
    }

    function execute() external returns (bool);

    function executeWithRevert() external;

    function oracleCount() external view returns (uint256);

    function oracleAdd(
        address oracle_,
        bytes32 encodedToken_,
        uint256 minimumPercentageDeltaValue_
    ) external;

    function oracleRemove(address oracle_) external;

    function oracleExists(address oracle_) external view returns (bool);

    function oracleAt(uint256 index_) external view returns (address);
}

////// lib/fiat/src/interfaces/IGuarded.sol
/* pragma solidity ^0.8.4; */

interface IGuarded {
    function ANY_SIG() external view returns (bytes32);

    function ANY_CALLER() external view returns (address);

    function allowCaller(bytes32 sig, address who) external;

    function blockCaller(bytes32 sig, address who) external;

    function canCall(bytes32 sig, address who) external view returns (bool);
}

////// lib/guards/src/Delayed.sol
/* pragma solidity ^0.8.4; */

contract Delayed {
    error Delayed__setParam_notDelayed();
    error Delayed__delay_invalidEta();
    error Delayed__execute_unknown();
    error Delayed__execute_stillDelayed();
    error Delayed__execute_executionError();

    mapping(bytes32 => bool) public queue;
    uint256 public delay;

    event SetParam(bytes32 param, uint256 data);
    event Queue(address target, bytes data, uint256 eta);
    event Unqueue(address target, bytes data, uint256 eta);
    event Execute(address target, bytes data, uint256 eta);

    constructor(uint256 delay_) {
        delay = delay_;
        emit SetParam("delay", delay_);
    }

    function _setParam(bytes32 param, uint256 data) internal {
        if (param == "delay") delay = data;
        emit SetParam(param, data);
    }

    function _delay(
        address target,
        bytes memory data,
        uint256 eta
    ) internal {
        if (eta < block.timestamp + delay) revert Delayed__delay_invalidEta();
        queue[keccak256(abi.encode(target, data, eta))] = true;
        emit Queue(target, data, eta);
    }

    function _skip(
        address target,
        bytes memory data,
        uint256 eta
    ) internal {
        queue[keccak256(abi.encode(target, data, eta))] = false;
        emit Unqueue(target, data, eta);
    }

    function execute(
        address target,
        bytes calldata data,
        uint256 eta
    ) external returns (bytes memory out) {
        bytes32 callHash = keccak256(abi.encode(target, data, eta));

        if (!queue[callHash]) revert Delayed__execute_unknown();
        if (block.timestamp < eta) revert Delayed__execute_stillDelayed();

        queue[callHash] = false;

        bool ok;
        (ok, out) = target.call(data);
        if (!ok) revert Delayed__execute_executionError();

        emit Execute(target, data, eta);
    }
}

////// lib/guards/src/interfaces/IGuard.sol
/* pragma solidity ^0.8.4; */

interface IGuard {
    function isGuard() external view returns (bool);
}

////// lib/guards/src/BaseGuard.sol
/* pragma solidity ^0.8.4; */

/* import {IGuard} from "./interfaces/IGuard.sol"; */

/* import {Delayed} from "./Delayed.sol"; */

abstract contract BaseGuard is Delayed, IGuard {
    /// ======== Custom Errors ======== ///

    error BaseGuard__isSenatus_notSenatus();
    error BaseGuard__isGuardian_notGuardian();
    error BaseGuard__isDelayed_notSelf(address, address);
    error BaseGuard__inRange_notInRange();

    /// ======== Storage ======== ///

    /// @notice Address of the DAO
    address public immutable senatus;
    /// @notice Address of the guardian
    address public guardian;

    constructor(
        address senatus_,
        address guardian_,
        uint256 delay
    ) Delayed(delay) {
        senatus = senatus_;
        guardian = guardian_;
    }

    modifier isSenatus() {
        if (msg.sender != senatus) revert BaseGuard__isSenatus_notSenatus();
        _;
    }

    modifier isGuardian() {
        if (msg.sender != guardian) revert BaseGuard__isGuardian_notGuardian();
        _;
    }

    modifier isDelayed() {
        if (msg.sender != address(this)) revert BaseGuard__isDelayed_notSelf(msg.sender, address(this));
        _;
    }

    /// @notice Callback method which allows Guard to check if he has sufficient rights over the corresponding contract
    /// @return bool True if he has sufficient rights
    function isGuard() external view virtual override returns (bool);

    /// @notice Updates the address of the guardian
    /// @dev Can only be called by Senatus
    /// @param guardian_ Address of the new guardian
    function setGuardian(address guardian_) external isSenatus {
        guardian = guardian_;
    }

    /// ======== Capabilities ======== ///

    /// @notice Updates the time which has to elapse for certain parameter updates
    /// @dev Can only be called by Senatus
    /// @param delay Time which has to elapse before parameter can be updated [seconds]
    function setDelay(uint256 delay) external isSenatus {
        _setParam("delay", delay);
    }

    /// @notice Schedule method call for methods which have to be delayed
    /// @dev Can only be called by the guardian
    /// @param data Call data
    function schedule(bytes calldata data) external isGuardian {
        _delay(address(this), data, block.timestamp + delay);
    }

    /// ======== Helper Methods ======== ///

    /// @notice Checks if `value` is at least equal to `min_` or at most equal to `max`
    /// @dev Revers if check failed
    /// @param value Value to check
    /// @param min_ Min. value for `value`
    /// @param max Max. value for `value`
    function _inRange(
        uint256 value,
        uint256 min_,
        uint256 max
    ) internal pure {
        if (max < value || value < min_) revert BaseGuard__inRange_notInRange();
    }
}

////// src/RelayerGuard.sol
/* pragma solidity ^0.8.4; */

/* import {IRelayer} from "delphi/relayer/IRelayer.sol"; */
/* import {IGuarded} from "fiat/interfaces/IGuarded.sol"; */
/* import {Delayed} from "guards/Delayed.sol"; */
/* import {BaseGuard} from "guards/BaseGuard.sol"; */

/// @title RelayerGuard
/// @notice Contract which guards parameter updates for a `Relayer`
contract RelayerGuard is BaseGuard {
    /// ======== Custom Errors ======== ///
    error RelayerGuard__isGuardForRelayer_cantCall(address relayer);
    
    constructor(
        address senatus,
        address guardian,
        uint256 delay
    ) BaseGuard(senatus, guardian, delay) {}

    /// ======== Storage ======== ///
    /// @notice See `BaseGuard`
    function isGuard() external pure override returns (bool) {
        return true;
    }

    /// @notice Method that checks if the Guard has sufficient rights over a relayer.
    /// @param relayer Address of the relayer.
    function isGuardForRelayer(address relayer) public view returns (bool) {
        if (!IGuarded(relayer).canCall(IGuarded(relayer).ANY_SIG(), address(this))) revert RelayerGuard__isGuardForRelayer_cantCall(relayer);
        return true;
    }

    /// @notice Allows for a trusted third party to trigger an Relayer execute.
    /// The execute will update all oracles and will push the data to Collybus.
    /// @dev Can only be called by the guardian. After `delay` has passed it can be `execute`'d.
    /// @param relayer Address of the relayer that needs to whitelist the keeper
    /// @param keeperAddress Address of the keeper contract
    function setKeeperService(address relayer, address keeperAddress) external isDelayed {
        if (isGuardForRelayer(relayer))
            IGuarded(relayer).allowCaller(IRelayer.execute.selector, keeperAddress);
    }

    /// @notice Removes the permission to call execute on the Relayer.
    /// @param relayer Address of the relayer that needs to remove permissions for the keeper
    /// @dev Can only be called by the guardian.
    /// @param keeperAddress Address of the removed keeper contract
    function unsetKeeperService(address relayer, address keeperAddress) isGuardian external {
        if (isGuardForRelayer(relayer))
            IGuarded(relayer).blockCaller(IRelayer.execute.selector, keeperAddress);
    }
}