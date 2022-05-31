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