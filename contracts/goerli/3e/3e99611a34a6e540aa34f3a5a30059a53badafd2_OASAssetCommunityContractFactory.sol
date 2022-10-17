/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

// File: IOASCommunityContractFactoryInterfaces.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOASTemplateOwnable {
    function transferOwnership(address newOwner) external;

}
interface IOASERC721CounterTemplate {
    function initialize(string calldata inputContractURI, string calldata baseURI, string calldata tokenURISuffix, string calldata tokenName, string calldata tokenSymbol) external;
}
interface IOASERC721Template {
    function initialize(string calldata inputContractURI, string calldata baseURI, string calldata tokenURISuffix, string calldata tokenName, string calldata tokenSymbol) external;
}

interface IOASERC721CounterTemplateHosted {
    function initialize(string calldata tokenName, string calldata tokenSymbol,bytes32 _storageKey) external;
}
interface IOASERC721TemplateHosted {
    function initialize(string calldata tokenName, string calldata tokenSymbol,bytes32 _storageKey) external;
}
// File: @openzeppelin/contracts/proxy/Clones.sol


// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)



/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// File: OASAssetCommunityContractFactory.sol





contract OASAssetCommunityContractFactory  {
    using Clones for address;
    address public erc721_template;
    address public erc721_counter_template;
    address public erc721_template_hosted;
    address public erc721_counter_template_hosted;
    event ContractCreated(address contractAddress);
    constructor(address _erc721_template, address _erc721_counter_template,address _erc721_template_hosted, address _erc721_counter_template_hosted) {
        erc721_template = _erc721_template;
        erc721_counter_template = _erc721_counter_template;
        erc721_template_hosted = _erc721_template_hosted;
        erc721_counter_template_hosted = _erc721_counter_template_hosted;
    }


    function createOASERC721Clone(address contractOwner, bytes12 salt, string calldata inputContractURI, string calldata baseURI, string calldata tokenURISuffix, string calldata tokenName, string calldata tokenSymbol) external {
        IOASERC721Template clone = IOASERC721Template(erc721_template.cloneDeterministic(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(msg.sender)))));
        clone.initialize(inputContractURI, baseURI, tokenURISuffix, tokenName, tokenSymbol);
        IOASTemplateOwnable(address(clone)).transferOwnership(contractOwner);
    }

    function getOASERC721CloneDeterministicAddress(address sender, bytes12 salt) external view returns (address) {
        
        return erc721_template.predictDeterministicAddress(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(sender))));

    }


    function createOASERC721CounterClone(address contractOwner, bytes12 salt, string calldata inputContractURI, string calldata baseURI, string calldata tokenURISuffix, string calldata tokenName, string calldata tokenSymbol) external {
        IOASERC721CounterTemplate clone = IOASERC721CounterTemplate(erc721_counter_template.cloneDeterministic(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(msg.sender)))));
        clone.initialize(inputContractURI, baseURI, tokenURISuffix, tokenName, tokenSymbol);
        IOASTemplateOwnable(address(clone)).transferOwnership(contractOwner);

    }

    function getOASERC721CounterCloneDeterministicAddress(address sender, bytes12 salt) external view returns (address) {
        return erc721_counter_template.predictDeterministicAddress(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(sender))));
    }

    function createOASERC721HostedClone(address contractOwner, bytes12 salt, bytes32 _storageKey, string calldata tokenName, string calldata tokenSymbol) external {
        IOASERC721TemplateHosted clone = IOASERC721TemplateHosted(erc721_template_hosted.cloneDeterministic(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(msg.sender)))));
        clone.initialize( tokenName, tokenSymbol,_storageKey);
        IOASTemplateOwnable(address(clone)).transferOwnership(contractOwner);
    }

    function getOASERC721HostedCloneDeterministicAddress(address sender, bytes12 salt) external view returns (address) {
        return erc721_template_hosted.predictDeterministicAddress(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(sender))));
    }


    function createOASERC721CounterHostedClone(address contractOwner, bytes12 salt, bytes32 _storageKey, string calldata tokenName, string calldata tokenSymbol) external {
        IOASERC721CounterTemplateHosted clone = IOASERC721CounterTemplateHosted(erc721_counter_template_hosted.cloneDeterministic(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(msg.sender)))));
        clone.initialize( tokenName, tokenSymbol,_storageKey);
        IOASTemplateOwnable(address(clone)).transferOwnership(contractOwner);

    }

    function getOASERC721CounterHostedCloneDeterministicAddress(address sender, bytes12 salt) external view returns (address) {
        return erc721_counter_template_hosted.predictDeterministicAddress(bytes32((uint256(uint96(salt))<<160) | uint256(uint160(sender))));
    }

}

//OASAssetCommunityContractFactory