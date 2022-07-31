/**
 *Submitted for verification at Etherscan.io on 2020-03-30
*/
/* https://eips.ethereum.org/EIPS/eip-2470 */

pragma solidity ^0.8.0;


/**
 * @title Singleton Factory (EIP-2470)
 * @notice Exposes CREATE2 (EIP-1014) to deploy bytecode on deterministic addresses based on initialization code and salt.
 * @author Ricardo Guilherme Schmidt (Status Research & Development GmbH)
 */
contract SingletonFactory {
      event Deployed(address addr, uint256 salt);
    /**
     * @notice Deploys `_initCode` using `_salt` for defining the deterministic address.
     * @param _initCode Initialization code.
     * @param _salt Arbitrary value to modify resulting address.
     * @return createdContract Created contract address.
     */
    function deploy(bytes memory _initCode, uint256 _salt)
        public
        returns (address payable createdContract)
    {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            createdContract := create2(0, add(_initCode, 0x20), mload(_initCode), _salt)
        }
        emit Deployed(createdContract, _salt);
    }
}
// IV is a value changed to generate the vanity address.
// IV: 6583047