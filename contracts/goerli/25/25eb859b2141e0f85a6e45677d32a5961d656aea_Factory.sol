/**
 *Submitted for verification at Etherscan.io on 2022-08-23
*/

pragma solidity 0.8.11;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(
        uint256 amount,
        bytes32 salt,
        bytes memory bytecode
    ) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        /// @solidity memory-safe-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(
        bytes32 salt,
        bytes32 bytecodeHash,
        address deployer
    ) internal pure returns (address) {
        bytes32 _data = keccak256(abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash));
        return address(uint160(uint256(_data)));
    }
}


/**
    @author Rotcivegaf <[email protected]>
*/
contract Factory {
    bytes code = hex"5860208158601c335a63aaf10f428752fa158151803b80938091923cf3";

    address public getImplementation;
    address public addr;

    function deploy() external {
        deploy(type(TakeMyOwnership).creationCode);
    }

    function deploy(bytes memory _code) public {
        address x;
        assembly {
            x := create(0, add(0x20, _code), mload(_code))
        }
        getImplementation = x;

        addr = Create2.deploy(0, bytes32(0), code);
        TakeMyOwnership(addr).init();
    }

    function won() external view returns(bool) {
        return TakeMyOwnership(addr).own() == msg.sender;
    }
}

contract TakeMyOwnership {
    address public own;
    bool private _isInit;

    function init() external {
        if (_isInit) return;
        _isInit = true;

        own = msg.sender;
    }

    function setOwn(string calldata _newOwn) external {
        if (!_isInit) return;
        address newOwn = address(uint160(uint256(keccak256(abi.encodePacked((_newOwn))))));
        if (msg.sender != tx.origin) return;
        own = newOwn;
        if (newOwn != msg.sender) selfdestruct(payable(msg.sender));
    }
}