/**
 *Submitted for verification at Etherscan.io on 2022-07-28
*/

//SPDX-License-Identifier: MIT
// Copy from: https://github.com/0age/metamorphic/blob/master/contracts/MetamorphicContractFactory.sol
// Edited by [email protected]
pragma solidity 0.5.12;

/**
 * @title Immutable Create2 Contract Factory
 * @author 0age & ysqi
 * @notice This contract provides a safeCreate2 function that takes a salt value
 * and a block of initialization code as arguments and passes them into inline
 * assembly. The contract prevents redeploys by maintaining a mapping of all
 * contracts that have already been deployed, and prevents frontrunning or other
 * collisions by requiring that the first 20 bytes of the salt are equal to the
 * address of the caller (this can be bypassed by setting the first 20 bytes to
 * the null address). There is also a view function that computes the address of
 * the contract that will be created when submitting a given salt or nonce along
 * with a given block of initialization code.
 * @dev This contract has not yet been fully tested or audited - proceed with
 * caution and please share any exploits or optimizations you discover.
 */
contract LastCreate2Factory {
    // a new contract deployed event
    event Deployed(address addr, bytes32 salt);

    // mapping to track which addresses have already been deployed.
    mapping(address => bool) public deployed;

    /**
     * @notice create
     * @dev Create a contract using CREATE2 by submitting a given salt or nonce
     * along with the initialization code for the contract. Note that the first 20
     * bytes of the salt must match those of the calling address, which prevents
     * contract creation events from being submitted by unintended parties.
     * @param salt bytes32 The nonce that will be passed into the CREATE2 call.
     * @param initializationCode bytes The initialization code that will be passed
     * into the CREATE2 call.
     * @param callData If callData is not empty, the new contract will be called
     * with callData after the contract is created successfully.
     * You can use it to initialize contracts, transfer management roles, or otherwise.
     * @return deploymentAddress is Address of the contract that will be created, or the null address
     * if a contract already exists at that address.
     */
    function safeCreate2(
        bytes32 salt,
        bytes calldata initializationCode,
        bytes calldata callData
    ) external returns (address deploymentAddress) {
        // prevent contract submissions from being stolen from tx.pool by requiring
        // that the first 20 bytes of the submitted salt match msg.sender.
        require(
            (bytes20(salt) == bytes20(0)) ||
                (address(bytes20(salt)) == msg.sender),
            "E1" // - first 20 bytes of the salt must match calling address.
        );

        // determine the target address for contract deployment.
        address targetDeploymentAddress = _create2Address(
            salt,
            keccak256(abi.encodePacked(initializationCode))
        );

        // ensure that a contract hasn't been previously deployed to target address.
        require(!deployed[targetDeploymentAddress], "E2");

        // move the initialization code from calldata to memory.
        bytes memory initCode = initializationCode;

        // using inline assembly: load data and length of data, then call CREATE2.
        assembly {
            // solhint-disable-line
            deploymentAddress := create2(
                callvalue(), // forward any attached value.
                add(0x20, initCode), // pass in initialization code.
                mload(initCode), // pass in init code's length.
                salt // pass in the salt value.
            )
            if iszero(extcodesize(deploymentAddress)) {
                revert(0, 0)
            }
        }

        // check address against target to ensure that deployment was successful.
        require(deploymentAddress == targetDeploymentAddress, "E3");

        // record the deployment of the contract to prevent redeploys.
        deployed[deploymentAddress] = true;

        // call contract after created
        if (callData.length > 0) {
            (bool success, ) = deploymentAddress.call(callData);
            require(success, "E4");
        }

        emit Deployed(deploymentAddress, salt);
    }

    /**
     * @dev Compute the address of the contract that will be created when
     * submitting a given salt or nonce to the contract along with the contract's
     * initialization code. The CREATE2 address is computed in accordance with
     * EIP-1014, and adheres to the formula therein of
     * `keccak256( 0xff ++ address ++ salt ++ keccak256(init_code)))[12:]` when
     * performing the computation. The computed address is then checked for any
     * existing contract code - if so, the null address will be returned instead.
     * @param salt bytes32 The nonce passed into the CREATE2 address calculation.
     * @param initCode bytes The contract initialization code to be used.
     * that will be passed into the CREATE2 address calculation.
     * @return deploymentAddress is Address of the contract that will be created, or the null address
     * if a contract has already been deployed to that address.
     */
    function findCreate2Address(bytes32 salt, bytes calldata initCode)
        external
        view
        returns (address deploymentAddress)
    {
        // determine the address where the contract will be deployed.
        deploymentAddress = _create2Address(
            salt,
            keccak256(abi.encodePacked(initCode))
        );

        // return null address to signify failure if contract has been deployed.
        if (deployed[deploymentAddress]) {
            return address(0);
        }
    }

    // determine the target address for contract deployment.
    function _create2Address(bytes32 salt, bytes32 initCodeHash)
        private
        view
        returns (address)
    {
        return
            address(
                uint160( // downcast to match the address type.
                    uint256( // convert to uint to truncate upper digits.
                        keccak256( // compute the CREATE2 hash using 4 inputs.
                            abi.encodePacked( // pack all inputs to the hash together.
                                hex"ff", // start with 0xff to distinguish from RLP.
                                address(this), // this contract will be the caller.
                                salt, // pass in the supplied salt value.
                                initCodeHash // pass in the hash of initialization code.
                            )
                        )
                    )
                )
            );
    }
}