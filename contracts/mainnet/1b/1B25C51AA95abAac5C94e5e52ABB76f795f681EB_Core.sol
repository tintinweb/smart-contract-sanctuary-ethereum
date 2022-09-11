// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


import "./interfaces/ICore.sol";
import "./interfaces/IOpenseaFactory.sol";
import "./interfaces/IRoyaltySplitter.sol";
import "./interfaces/INFT.sol";

import "@openzeppelin/contracts/proxy/Clones.sol";

contract Core is ICore {
    using Clones for address;

    bytes32 constant private SALTER = hex"10";

    address public immutable NFT_IMPLEMENTATION;
    address public immutable OPENSEA_MINTER_IMPLEMENTATION;
    address public immutable ROYALTY_SPLITTER_IMPLEMENTATION;

    constructor(address nftImp, address openseaImp, address splitterImp) {
        NFT_IMPLEMENTATION = nftImp;
        OPENSEA_MINTER_IMPLEMENTATION = openseaImp;
        ROYALTY_SPLITTER_IMPLEMENTATION = splitterImp;
    }

    function newNFT(NewNFTParams calldata params) external returns(address) {
        address nft = NFT_IMPLEMENTATION.cloneDeterministic(params.nftSalt);
        bytes32 salt = _salt(nft);
    
        address splitter = ROYALTY_SPLITTER_IMPLEMENTATION.cloneDeterministic(salt);
        address openseaMinter = OPENSEA_MINTER_IMPLEMENTATION.cloneDeterministic(salt);
        address splitterFirstSale = ROYALTY_SPLITTER_IMPLEMENTATION.cloneDeterministic(_alterSalt(salt));
    
        INFT(nft).initialize(
            params.metadata,
            params.totalSupply,
            params.royalties.royaltyInBasisPoints,
            openseaMinter,
            splitter
        );
        IRoyaltySplitter(splitter).initialize(
            params.royalties.royals.accounts, params.royalties.royals.shares
        );
        IOpenseaFactory(openseaMinter).initialize(
            params.owner,
            splitterFirstSale,
            params.royalties.royaltyInBasisPointsFirstSale,
            nft,
            params.premintStart,
            params.premintEnd,
            params.metadata.contractURIFirstSale
        );
        IRoyaltySplitter(splitterFirstSale).initialize(
            params.royalties.royalsFirstSale.accounts, params.royalties.royalsFirstSale.shares
        );

        emit NewNFT(nft, openseaMinter, splitter, splitterFirstSale, params);
        return nft;
    }

    function _salt(address nft) private pure returns(bytes32) {
        return bytes32(abi.encode(nft));
    }

    function _alterSalt(bytes32 salt) private pure returns(bytes32) {
        return salt | SALTER;
    }

    function getNFTBySalt(bytes32 salt) external view returns(address) {
        return NFT_IMPLEMENTATION.predictDeterministicAddress(salt);
    }

    function getOpenseaMinterByNFT(address nft) external view returns(address) {
        return OPENSEA_MINTER_IMPLEMENTATION.predictDeterministicAddress(_salt(nft));
    }

    function getRoyaltySplitterByNFT(address nft) external view returns(address) {
        return ROYALTY_SPLITTER_IMPLEMENTATION.predictDeterministicAddress(_salt(nft));
    }

    function getRoyaltySplitterFirstSaleByNFT(address nft) external view returns(address) {
        return ROYALTY_SPLITTER_IMPLEMENTATION.predictDeterministicAddress(_alterSalt(_salt(nft)));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IRoyaltySplitter {
    function initialize(address[] calldata royaltyRecipients, uint256[] calldata _shares) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IOpenseaFactory {
    
    function initialize(
        address _owner,
        address _splitter,
        uint256 royaltyInBasisPoints, 
        address _underlyingNFT, 
        uint256 premintStart,
        uint256 premintEnd,
        string calldata contractURI
    ) external;

    function emitEvents(uint256 start, uint256 end) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { NFTMetadata } from "./ICore.sol";

interface INFT {
    function initialize( 
        NFTMetadata calldata metadata,
        uint256 totalSupply,
        uint256 royaltyInBasisPoints,
        address _minter,
        address splitter
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
 //
    enum Imp {
        NONE,
        NFT,
        OPENSEA,
        SPLITTER
    }

    struct Royals {
        address[] accounts;
        uint256[] shares;
    }

    struct Royalties {
        Royals royals;
        uint256 royaltyInBasisPoints;
        Royals royalsFirstSale;
        uint256 royaltyInBasisPointsFirstSale;
    }

    struct NFTMetadata {
        string name;
        string symbol;
        string baseURI;
        string contractURI;
        string contractURIFirstSale;
    }

    struct NewNFTParams {
        NFTMetadata metadata;
        bytes32 nftSalt;
        address owner;
        uint256 totalSupply;
        uint256 premintStart;
        uint256 premintEnd;
        Royalties royalties;
    }

interface ICore {


    event NewNFT(
        address nft, 
        address openseaMinter, 
        address splitter, 
        address splitterFirstSale, 
        NewNFTParams params
    );

    function newNFT(NewNFTParams calldata params) external returns(address);
   
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

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