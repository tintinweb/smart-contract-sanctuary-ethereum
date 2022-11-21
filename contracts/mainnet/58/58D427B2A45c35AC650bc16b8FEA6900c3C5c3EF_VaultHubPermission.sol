/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/libraries/Verifier.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.12;

library Verifier {
    function verifyPermit(
        address signer,
        bytes32 params,
        uint8 v,
        bytes32 r,
        bytes32 s,
        string memory notification
    ) internal pure {
        bytes32 paramsHash = keccak256(abi.encodePacked(params));
        bytes32 digest = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", paramsHash));

        //Determine whether the result address of ecrecover is equal to addr; if not, revert directly
        require(ecrecover(digest, v, r, s) == signer, notification);
    }
}


// File contracts/libraries/Constants.sol

pragma solidity >=0.8.12;

library VaultHubTypeHashs {
    string public constant VAULTHUB_DOMAIN_NAME = "[email protected]";
    string public constant VAULTHUB_DOMAIN_VERSION = "1.0.0";
    // keccak256('EIP712Domain(string name, string version, uint256 chainId, address VaultHubContract)');
    bytes32 public constant VAULTHUB_DOMAIN_TYPE_HASH =
        0x6c055b4eb43bcfe637041a3adda3d9f2b05d93fc3a54fc8c978e7d0d95e35b66;

    // keccak256('savePrivateDataWithMinting(address addr, string calldata data, string calldata cryptoLabel, address labelHash,
    // address receiver, uint256 deadline)');
    bytes32 public constant VAULTHUB_MINT_SAVE_PERMIT_TYPE_HASH =
        0xcdd3cc6eb42396c94a4d5d905327888ade5ae14c59a5d22ae3235b88283c0035;

    // keccak256('savePrivateDataWithoutMinting(address addr, string calldata data,
    // string calldata cryptoLabel, address labelHash, uint256 deadline)');
    bytes32 public constant VAULTHUB_SAVE_PERMIT_TYPE_HASH =
        0x50a5dca0d9658d6eb6282f2d7bdda2a899b962259e2708f7cce8c48021a63483;

    //keccak256('queryPrivateDataByIndex(address addr, uint64 index, uint256 deadline)')
    bytes32 public constant VAULTHUB_INDEX_QUERY_PERMIT_TYPE_HASH =
        0xbcb00634c612072a661bb64fa073e7806d31f3790f1c827cd20f95542b5af679;

    //keccak256('queryPrivateDataByName(address addr, address labelHash, uint256 deadline)')
    bytes32 public constant VAULTHUB_NAME_QUERY_PERMIT_TYPE_HASH =
        0xab4ac209d4a97678c29d0f2f4ef3539a24e0ce6dbd2dd481c818134b61d28ecc;

    //keccak256('initPrivateVault(address addr, uint256 deadline)')
    bytes32 public constant VAULTHUB_INIT_VAULT_PERMIT_TYPE_HASH =
        0xef93604cd5c5e7d35e7ef7d38e1cac9e1cc450e49bc931effd1f65a5a993121d;

    //keccak256('vaultHasRegister(address addr, uint256 deadline)')
    bytes32 public constant VAULTHUB_VAULT_HAS_REGISTER_PERMIT_TYPE_HASH =
        0x5a14c87645febe5840f128409acb12772ff89f3398b05142d7e039c76e0844e8;

    //keccak256('hasMinted(address addr, uint256 deadline)')
    bytes32 public constant VAULTHUB_HAS_MINTED_PERMIT_TYPE_HASH =
        0xdbd66a895de1fdf2e44b84c83cf1e4f482f647eb80397d069bf7763a583ce1a5;

    //keccak256('totalSavedItems(address addr, uint256 deadline)')
    bytes32 public constant VAULTHUB_TOTAL_SAVED_ITEMS_PERMIT_TYPE_HASH =
        0xf65e93839555276acb1b1c33eb49dff5fa6a88c6991b9b84b680dc961b85f847;

    //keccak256('getLabelNameByIndex(address addr, uint256 deadline, uint64 index)')
    bytes32 public constant VAULTHUB_GET_LABEL_NAME_BY_INDEX_TYPE_HASH =
        0xbd5bc3ca2c7ea773b900edfe638ad04ce3697bf85885abdbe90a2f7c1266d9ee;

    //keccak256('labelExist(address addr, address labelHash, uint256 deadline)')
    bytes32 public constant VAULTHUB_LABEL_EXIST_TYPE_HASH =
        0xac1275bd89417f307b1ae27de4967e4910dfab4abd173eb3e6a3352c21ae42fe;

    //keccak256('queryPrivateVaultAddress(address addr, uint256 deadline)')
    bytes32 public constant VAULTHUB_QUERY_PRIVATE_VAULT_ADDRESS_PERMIT_TYPE_HASH =
        0x21b7e085fb49739c78b83ddb0a8a7e4b469211d08958f57d52ff68325943de04;
}

library PrivateVaultTypeHashs {
    string public constant PRIVATE_DOMAIN_NAME = "[email protected]";
    string public constant PRIVATE_DOMAIN_VERSION = "1.0.0";
    // keccak256('EIP712Domain(string name, string version, uint256 chainId, address PrivateVaultContract)');
    bytes32 public constant PRIVATE_DOMAIN_TYPE_HASH =
        0xdad980a10e49615eb7fc5d7774307c8f04d959ac46349850121d52b1e409fc1e;
}

library VaultHubCallee {
    //vault hub used;  bytes4(keccak256(bytes(signature)))
    bytes4 public constant HAS_REGISTER_PERMIT = 0xf2ae01de;
    bytes4 public constant INIT_PERMIT = 0x560ee72b;
    bytes4 public constant GET_LABEL_EXIST_PERMIT = 0x15960843;
    bytes4 public constant GET_LABEL_NAME_PERMIT = 0x94f82d81;
    bytes4 public constant TOTAL_SAVED_ITEMS_PERMIT = 0x15b2755f;
    bytes4 public constant HAS_MINTED_PERMIT = 0x1a49dda4;
    bytes4 public constant QUERY_PRIVATE_VAULT_ADDRESS_PERMIT = 0x01c190bd;
    bytes4 public constant QUERY_BY_NAME_PERMIT = 0x79861a05;
    bytes4 public constant QUERY_BY_INDEX_PERMIT = 0xd5d76538;
    bytes4 public constant SAVE_WITHOUT_MINT_PERMIT = 0xdd181b56;
    bytes4 public constant MINT_SAVE_PERMIT = 0x95781f1f;
}


// File contracts/libraries/Permission.sol

pragma solidity >=0.8.12;


library VaultHubPermission {
    function hasRegisterPermit(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_VAULT_HAS_REGISTER_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:register permit");
    }

    function initPermit(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(addr, deadline, DOMAIN_SEPARATOR, VaultHubTypeHashs.VAULTHUB_INIT_VAULT_PERMIT_TYPE_HASH)
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:init permit");
    }

    function mintSavePermit(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                bytes(data),
                bytes(cryptoLabel),
                labelHash,
                receiver,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_MINT_SAVE_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:mint save");
    }

    function saveWithoutMintPermit(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                bytes(data),
                bytes(cryptoLabel),
                labelHash,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_SAVE_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:save permit");
    }

    function queryByIndexPermit(
        address addr,
        uint64 index,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                index,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_INDEX_QUERY_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:index query");
    }

    function queryByNamePermit(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                labelHash,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_NAME_QUERY_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:name query");
    }

    function queryPrivateVaultAddressPermit(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_QUERY_PRIVATE_VAULT_ADDRESS_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:query address");
    }

    function hasMintedPermit(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(addr, deadline, DOMAIN_SEPARATOR, VaultHubTypeHashs.VAULTHUB_HAS_MINTED_PERMIT_TYPE_HASH)
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:has minted");
    }

    function totalSavedItemsPermit(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_TOTAL_SAVED_ITEMS_PERMIT_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:total saved");
    }

    function getLabelNamePermit(
        address addr,
        uint256 deadline,
        uint64 index,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                deadline,
                index,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_GET_LABEL_NAME_BY_INDEX_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:lable name permit");
    }

    function getLabelExistPermit(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 DOMAIN_SEPARATOR
    ) external view {
        require(addr != address(0));
        require(deadline >= block.timestamp, "vHub:execute timeout");
        bytes32 params = keccak256(
            abi.encodePacked(
                addr,
                labelHash,
                deadline,
                DOMAIN_SEPARATOR,
                VaultHubTypeHashs.VAULTHUB_LABEL_EXIST_TYPE_HASH
            )
        );
        Verifier.verifyPermit(addr, params, v, r, s, "vHub:exist permit");
    }
}