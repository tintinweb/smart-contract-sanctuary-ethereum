// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.9;

import "hardhat-deploy/solc_0.8/proxy/Proxied.sol";

/// @title Contract that receives both ETH staking rewards and unstaked ETH
/// @author Golem Foundation
/// @notice
/// @dev This one is written to be upgradeable (hardhat-deploy variant).
/// Despite that, it can be deployed as-is without a proxy.
contract WithdrawalsTargetV3 {
    // This contract uses Proxy pattern.
    // Please read more here about limitations:
    //   https://docs.openzeppelin.com/upgrades-plugins/1.x/writing-upgradeable
    // Note that this contract uses hardhat's upgradeable, not OpenZeppelin's!

    /// @notice Octant address will receive rewards ETH
    address public octant;

    /// @notice Golem Foundation multisig address
    address public multisig;

    event OctantSet(address oldValue, address newValue);
    event MultisigSet(address oldValue, address newValue);
    event GotEth(uint amount, address sender);

    constructor () {
    }

    function setOctant(address newOctant) public onlyMultisig {
        emit OctantSet(octant, newOctant);
        octant = newOctant;
    }

    function setMultisig(address newMultisig) public {
        require((multisig == address(0x0)) || (msg.sender == multisig),
                "HN:WithdrawalsTarget/unauthorized-caller");
        emit MultisigSet(multisig, newMultisig);
        multisig = newMultisig;
    }

    function withdrawRewards(address payable rewardsVault) public onlyOctant {
        rewardsVault.transfer(address(this).balance);
    }

    function withdrawUnstaked(uint256 amount) public onlyMultisig {
        payable(multisig).transfer(amount);
    }

    /// @dev This will be removed before mainnet launch.
    /// Was added as a work-around for EIP173Proxy reverting bare ETH transfers.
    function sendETH() public payable {
        emit GotEth(msg.value, msg.sender);
    }

    modifier onlyOctant() {
        require(msg.sender == octant, "HN:WithdrawalsTarget/unauthorized-caller");
        _;
    }

    modifier onlyMultisig() {
        require(msg.sender == multisig, "HN:WithdrawalsTarget/unauthorized-caller");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Proxied {
    /// @notice to be used by initialisation / postUpgrade function so that only the proxy's admin can execute them
    /// It also allows these functions to be called inside a contructor
    /// even if the contract is meant to be used without proxy
    modifier proxied() {
        address proxyAdminAddress = _proxyAdmin();
        // With hardhat-deploy proxies
        // the proxyAdminAddress is zero only for the implementation contract
        // if the implementation contract want to be used as a standalone/immutable contract
        // it simply has to execute the `proxied` function
        // This ensure the proxyAdminAddress is never zero post deployment
        // And allow you to keep the same code for both proxied contract and immutable contract
        if (proxyAdminAddress == address(0)) {
            // ensure can not be called twice when used outside of proxy : no admin
            // solhint-disable-next-line security/no-inline-assembly
            assembly {
                sstore(
                    0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103,
                    0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
                )
            }
        } else {
            require(msg.sender == proxyAdminAddress);
        }
        _;
    }

    modifier onlyProxyAdmin() {
        require(msg.sender == _proxyAdmin(), "NOT_AUTHORIZED");
        _;
    }

    function _proxyAdmin() internal view returns (address ownerAddress) {
        // solhint-disable-next-line security/no-inline-assembly
        assembly {
            ownerAddress := sload(0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103)
        }
    }
}