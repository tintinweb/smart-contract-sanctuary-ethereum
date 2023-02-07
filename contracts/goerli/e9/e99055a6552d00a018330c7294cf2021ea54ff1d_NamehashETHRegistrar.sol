// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// ====================================================================
// |     __      __                       __   __             __      |
// |    /  \    / / ____   ______  ___   / /  / / ____  ____ / /_     |
// |   / /\ \  / // __  // _  _  // _ \ / /__/ // __  //   // __ \    |
// |  / /  \ \/ // /_/ // // // //  __// /  / // /_/ /  \  / / / /    |
// | /_/    \__/ \__,_//_//_//_/ \___//_/  /_/ \__,_//___//_/ /_/     |
// |                                                                  |
// ====================================================================
// ====================== NamehashETHRegistrar ========================
// ====================================================================
// NameHash Dapp: https://namehash.io/
// NameHash repo: https://github.com/namehash

import "./interfaces/IETHRegistrarController.sol";

/**
 * @title NameHash ETH Registrar
 * @author @alextnetto - https://github.com/alextnetto
 */
contract NamehashETHRegistrar {
    /// @notice Address where collected balance is sent
    address public immutable treasury;
    /// @notice ENS ETHRegistrarController address
    IETHRegistrarController public immutable ETHRegistrarController;

    constructor(address _treasury, address _ETHRegistrarController) {
        treasury = _treasury;
        ETHRegistrarController = IETHRegistrarController(
            _ETHRegistrarController
        );
    }

    /// @dev Enable collection of refund
    receive() external payable {}

    /// @dev Enable collection of refund
    fallback() external payable {}

    function requestPermissionToRegister(bytes32 commitment) public {
        ETHRegistrarController.commit(commitment);
    }

    /**
     * @notice Register a .eth domain
     * @dev label param is the name param on ENS ETHRegistrarController
     * @param label Label to be registered under .eth top level domain. Ex.: exampleregistration would register exampleregistration.eth
     * @param owner Address to receive the domain
     * @param duration Time in seconds that the domain will be registered
     * @param secret The salt that gave randomness on commitment hash
     * @param resolver The resolver smart contract address that will be used to resolve ENS records
     * @param addr Address that will be initialized as owner and controller of the domain
     */
    function completeRegistration(
        string calldata label,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) public payable {
        ETHRegistrarController.registerWithConfig{value: msg.value}(
            label,
            owner,
            duration,
            secret,
            resolver,
            addr
        );
    }

    /// @notice Send any Ether balance on this contract to the treasury
    function withdraw() public {
        treasury.call{value: address(this).balance}("");
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IETHRegistrarController {
    function commit(bytes32 commitment) external;

    function registerWithConfig(
        string memory name,
        address owner,
        uint256 duration,
        bytes32 secret,
        address resolver,
        address addr
    ) external payable;

    function renew(string calldata, uint256) external payable;
}