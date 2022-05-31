// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./AppType.sol";
import "./Utils.sol";

library BatchFactory {
    using LeafUtils for AppType.NFT;
    using LeafUtils for AppType.Pass;
    using MerkleProof for bytes32[];

    event BatchCreated(
        uint256 batchId,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event BatchUpdated(
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    );
    event ExcludedLeaf(bytes32 leaf, uint256 batchId, bool isExcluded);
    event AuthorizedMint(
        uint256 nftBatchId,
        uint256 passBatchId,
        string nftUri,
        uint256 tierId,
        address swapToken,
        uint256 swapAmount,
        address account,
        uint256 newTokenId
    );

    function createBatch(
        AppType.State storage state,
        AppType.BatchKind kind,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );
        uint256 newBatchId = ++state.id[AppType.Model.BATCH];
        state.batches[newBatchId] = AppType.Batch({
            id: newBatchId,
            kind: kind,
            isOpenAt: isOpenAt,
            disabled: disabled,
            root: root,
            collection: collection
        });
        emit BatchCreated(
            newBatchId,
            kind,
            isOpenAt,
            disabled,
            root,
            collection
        );
    }

    function updateBatch(
        AppType.State storage state,
        uint256 batchId,
        uint256 isOpenAt,
        bool disabled,
        bytes32 root,
        address collection
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        require(state.batches[batchId].id == batchId, "E001");
        AppType.Batch storage batch = state.batches[batchId];
        batch.isOpenAt = isOpenAt;
        batch.disabled = disabled;
        batch.root = root;
        batch.collection = collection;
        emit BatchUpdated(batchId, isOpenAt, disabled, root, collection);
    }

    function readBatch(AppType.State storage state, uint256 batchId)
        public
        view
        returns (
            AppType.BatchKind kind,
            uint256 isOpenAt,
            bool disabled,
            bytes32 root
        )
    {
        require(state.batches[batchId].id == batchId, "E001");
        return (
            state.batches[batchId].kind,
            state.batches[batchId].isOpenAt,
            state.batches[batchId].disabled,
            state.batches[batchId].root
        );
    }

    function excludeNFTLeaf(
        AppType.State storage state,
        AppType.NFT memory nft,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = nft.nftLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, nft.batchId, isExcluded);
    }

    function excludePassLeaf(
        AppType.State storage state,
        AppType.Pass memory pass,
        bool isExcluded
    ) public {
        require(
            msg.sender == state.config.addresses[AppType.AddressConfig.DAO],
            "E012"
        );

        bytes32 leaf = pass.passLeaf(state);
        state.excludedLeaves[leaf] = isExcluded;
        emit ExcludedLeaf(leaf, pass.batchId, isExcluded);
    }

    function authorizeMint(
        AppType.State storage state,
        AppType.NFT memory nft,
        AppType.Pass memory pass,
        AppType.Proof memory proof
    ) public returns (uint256 newTokenId) {
        require(!state.config.bools[AppType.BoolConfig.PAUSED], "E013");

        if (!state.config.bools[AppType.BoolConfig.ALLOW_MINT_WITHOUT_PASS]) {
            AppType.Batch storage passBatch = state.batches[pass.batchId];

            require(
                passBatch.id == pass.batchId &&
                    passBatch.kind == AppType.BatchKind.PASS &&
                    passBatch.isOpenAt <= block.timestamp &&
                    !passBatch.disabled,
                "E002"
            );

            bytes32 passLeaf = pass.passLeaf(state);
            require(state.usedLeaves[passLeaf] < pass.balance, "E003");

            require(proof.pass.verify(passBatch.root, passLeaf), "E004");
            require(state.excludedLeaves[passLeaf] == false, "E005");
            ++state.usedLeaves[passLeaf];
        }

        {
            AppType.Batch storage nftBatch = state.batches[nft.batchId];

            require(
                nftBatch.id == nft.batchId &&
                    nftBatch.kind == AppType.BatchKind.NFT &&
                    nftBatch.isOpenAt <= block.timestamp &&
                    !nftBatch.disabled,
                "E006"
            );

            bytes32 nftLeaf = nft.nftLeaf(state);
            require(state.usedLeaves[nftLeaf] == 0, "E007");
            require(proof.nft.verify(nftBatch.root, nftLeaf), "E008");
            require(state.excludedLeaves[nftLeaf] == false, "E009");
            ++state.usedLeaves[nftLeaf];
        }

        uint256 swapAmount = state.tierSwapAmounts[nft.tierId][nft.swapToken];

        {
            require(swapAmount > 0, "E010");

            if (nft.swapToken == address(0)) {
                require(msg.value >= swapAmount, "E011");
                payable(
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET]
                ).transfer(swapAmount);
            } else {
                IERC20(nft.swapToken).transferFrom(
                    msg.sender,
                    state.config.addresses[AppType.AddressConfig.FEE_WALLET],
                    swapAmount
                );
            }
        }

        newTokenId = uint256(keccak256(abi.encode(nft.uri)));

        emit AuthorizedMint(
            nft.batchId,
            pass.batchId,
            nft.uri,
            nft.tierId,
            nft.swapToken,
            swapAmount,
            msg.sender,
            newTokenId
        );
    }
}

// Error Codes

// E001 - Batch not found
// E002 - Pass Batch not found
// E003 - Pass already used
// E004 - Pass not found
// E005 - Pass is excluded
// E006 - NFT Batch not found
// E007 - NFT already Minted
// E008 - NFT not found
// E009 - NFT is excluded
// E010 - swapAmount is 0
// E011 - Insufficient swap amount sent to mint
// E012 - Only DAO can perform this operation
// E013 - Minting is PAUSED

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

library AppType {
    enum BatchKind {
        PASS,
        NFT
    }

    enum Model {
        BATCH
    }

    enum AddressConfig {
        NONE,
        DAO,
        FEE_WALLET
    }

    enum UintConfig {
        NONE,
        CHAIN_ID
    }

    enum BoolConfig {
        NONE,
        ALLOW_MINT_WITHOUT_PASS,
        PAUSED
    }

    enum StringConfig {
        NONE,
        APP_NAME
    }

    struct IConfigKey {
        AddressConfig addressK;
        UintConfig uintK;
        BoolConfig boolK;
        StringConfig stringK;
    }

    struct IConfigValue {
        address addressV;
        uint256 uintV;
        bool boolV;
        string stringV;
    }

    struct Config {
        mapping(AddressConfig => address) addresses;
        mapping(UintConfig => uint256) uints;
        mapping(BoolConfig => bool) bools;
        mapping(StringConfig => string) strings;
    }

    struct NFT {
        uint256 batchId;
        uint256 tierId;
        string uri;
        address swapToken;
        uint96 royaltyPercent;
    }

    struct Pass {
        uint256 batchId;
        uint256 balance;
    }

    struct Proof {
        bytes32[] pass;
        bytes32[] nft;
    }

    struct Batch {
        BatchKind kind;
        uint256 id;
        uint256 isOpenAt;
        bool disabled;
        bytes32 root;
        address collection;
    }

    struct State {
        mapping(Model => uint256) id;
        mapping(uint256 => Batch) batches;
        mapping(bytes32 => bool) excludedLeaves;
        mapping(bytes32 => uint256) usedLeaves;
        mapping(uint256 => mapping(address => uint256)) tierSwapAmounts;
        Config config;
    }
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity 0.8.14;

import "./AppType.sol";

library LeafUtils {
    function nftLeaf(AppType.NFT memory nft, AppType.State storage state)
        public
        view
        returns (bytes32 leaf)
    {
        leaf = keccak256(
            abi.encodePacked(
                nft.batchId,
                uint256(AppType.BatchKind.NFT),
                nft.uri,
                nft.royaltyPercent,
                nft.tierId,
                state.config.strings[AppType.StringConfig.APP_NAME],
                state.config.uints[AppType.UintConfig.CHAIN_ID]
            )
        );
        return leaf;
    }

    function passLeaf(AppType.Pass memory pass, AppType.State storage state)
        public
        view
        returns (bytes32 leaf)
    {
        leaf = keccak256(
            abi.encodePacked(
                pass.batchId,
                uint256(AppType.BatchKind.PASS),
                msg.sender,
                pass.balance,
                state.config.strings[AppType.StringConfig.APP_NAME],
                state.config.uints[AppType.UintConfig.CHAIN_ID]
            )
        );
        return leaf;
    }
}