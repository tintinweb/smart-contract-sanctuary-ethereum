/**
 *Submitted for verification at Etherscan.io on 2022-11-21
*/

// Sources flattened with hardhat v2.10.2 https://hardhat.org

// File contracts/libraries/Constants.sol

// SPDX-License-Identifier: MIT
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


// File contracts/src/vaults/PrivateVault.sol

pragma solidity >=0.8.12;

contract PrivateVault {
    address private signer;
    address public caller;

    // Each vault can only participate in the mint seed behavior once
    bool public minted;

    //Used to determine whether a label already exists
    mapping(address => bool) private labelExist;

    // Used to indicate where a label is stored
    mapping(uint64 => address) private labels;

    // The mapping relationship between the hash value used to indicate the label and the true value of the label
    mapping(address => string) private hashToLabel;

    // Used to store real encrypted data
    mapping(address => string) private store;

    uint64 public total;

    bytes32 public DOMAIN_SEPARATOR;

    address private privateValidator;

    modifier auth() {
        require(msg.sender == caller, "vault:auth");
        _;
    }

    constructor(
        address _signer,
        address _caller
    ) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                PrivateVaultTypeHashs.PRIVATE_DOMAIN_TYPE_HASH,
                keccak256(bytes(PrivateVaultTypeHashs.PRIVATE_DOMAIN_NAME)),
                keccak256(bytes(PrivateVaultTypeHashs.PRIVATE_DOMAIN_VERSION)),
                chainId,
                address(this)
            )
        );

        signer = _signer;
        caller = _caller;
        total = 0;
        minted = false;
    }

    //cryptoLabel is encrypt message from Label value
    function saveWithMinting(
        string calldata data,
        string calldata cryptoLabel,
        address labelHash
    ) external auth {
        require(minted == false, "vault:minted");

        //label was unused
        require(labelExist[labelHash] == false, "vault:exist");

        store[labelHash] = data;
        labels[total] = labelHash;
        hashToLabel[labelHash] = cryptoLabel;
        total++;
        labelExist[labelHash] = true;

        minted = true;
    }

    function saveWithoutMinting(
        string calldata data,
        string calldata cryptoLabel,
        address labelHash
    ) external auth {
        //label was unused
        require(labelExist[labelHash] == false, "vault:exist");
        store[labelHash] = data;
        labels[total] = labelHash;
        hashToLabel[labelHash] = cryptoLabel;
        total++;
        labelExist[labelHash] = true;
    }

    function getPrivateDataByIndex(uint64 index) external view auth returns (string memory) {
        require(total > index, "vault:overflow");
        return store[labels[index]];
    }

    function getPrivateDataByName(address name) external view auth returns (string memory) {
        require(labelExist[name] == true, "vault:no exist");

        return store[name];
    }

    function labelName(uint64 index) external view auth returns (string memory) {
        require(index < total);
        return hashToLabel[labels[index]];
    }

    function labelIsExist(address labelHash) external view auth returns (bool) {
        bool exist = labelExist[labelHash];
        return exist;
    }
}


// File contracts/interfaces/treasury/ITreasury.sol

pragma solidity >=0.8.12;

interface ITreasury {
    function mint(address receiver) external returns (uint256);
}


// File contracts/interfaces/vaults/IVaultHub.sol


pragma solidity >=0.8.12;

interface IVaultHub {
    function vaultHasRegister(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function initPrivateVault(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool);

    function savePrivateDataWithMinting(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function savePrivateDataWithoutMinting(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable;

    function queryPrivateDataByIndex(
        address addr,
        uint64 index,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory);

    function queryPrivateDataByName(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory);

    function hasMinted(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);

    function totalSavedItems(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (uint64);

    function getLabelNameByIndex(
        address addr,
        uint256 deadline,
        uint64 index,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory);

    function queryPrivateVaultAddress(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (address);

    function labelExist(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool);
}


// File contracts/src/vaults/VaultHub.sol

pragma solidity >=0.8.12;




contract VaultHub is IVaultHub {
    event SaveMint(uint256 indexed mintSeedAmount, uint256 indexed gasPrice, uint256 indexed timestamp);
    event Save(uint256 indexed gasPrice, uint256 indexed timestamp);

    address public treasury;
    address public owner;
    bool private stopable;
    uint256 public fee =3000000000000000;
    bytes32 public DOMAIN_SEPARATOR;

    address public vaultHubPermissionLib;

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                VaultHubTypeHashs.VAULTHUB_DOMAIN_TYPE_HASH,
                keccak256(bytes(VaultHubTypeHashs.VAULTHUB_DOMAIN_NAME)),
                keccak256(bytes(VaultHubTypeHashs.VAULTHUB_DOMAIN_VERSION)),
                chainId,
                address(this)
            )
        );

        owner = msg.sender;
    }

    function setFee(uint256 _fee) external {
        require(msg.sender == owner);
        fee = _fee;
    }

    function setStopable(bool _stopable) external {
        require(msg.sender == owner);
        stopable = _stopable;
    }

    function transferOwnership(address newOwner) external {
        require(msg.sender == owner);
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setTreasuryAddress(address _treasury) external {
        require(msg.sender == owner);
        treasury = _treasury;
    }

    function setPermissionLib(address permissionLib) external {
        require(msg.sender == owner);
        vaultHubPermissionLib = permissionLib;
    }

    function calculateVaultAddress(bytes32 salt, bytes memory bytecode) internal view returns (address) {
        return
            address(
                uint160(
                    uint256(
                        keccak256(
                            abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(abi.encodePacked(bytecode)))
                        )
                    )
                )
            );
    }

    function vaultHasRegister(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(VaultHubCallee.HAS_REGISTER_PERMIT, addr, deadline, v, r, s, DOMAIN_SEPARATOR)
        );
        require(res == true);
        (bool done, ) = _vaultHasRegister(addr);
        return done;
    }

    // Determine whether a vault-name and password are registered
    function _vaultHasRegister(address addr) internal view returns (bool, address) {
        bytes32 salt = keccak256(abi.encodePacked(addr,DOMAIN_SEPARATOR));
        bytes memory bytecode = abi.encodePacked(
            type(PrivateVault).creationCode,
            abi.encode(addr, this)
        );

        //Calculate the address of the private vault, record it as vaultAddr
        address vault = calculateVaultAddress(salt, bytecode);

        if (vault.code.length > 0) {
            return (true, vault);
        }

        return (false, address(0));
    }

    function initPrivateVault(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (bool) {
        require(stopable==false);
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(VaultHubCallee.INIT_PERMIT, addr, deadline, v, r, s, DOMAIN_SEPARATOR)
        );
        require(res == true);

        bytes32 salt = keccak256(abi.encodePacked(addr, DOMAIN_SEPARATOR));
        bytes memory bytecode = abi.encodePacked(
            type(PrivateVault).creationCode,
            abi.encode(addr, this)
        );

        (bool done, ) = _vaultHasRegister(addr);
        require(done == false, "vHub:existed");
        //create2: deploy contract
        address vault;
        assembly {
            vault := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }

        if (vault == address(0)) {
            revert("vHub:create2 ERROR");
        }

        return true;
    }

    function requireVaultRegistered(bool done) internal pure {
        require(done == true, "vHub:undeploy");
    }

    function savePrivateDataWithMinting(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        address receiver,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(stopable==false);
        require(treasury != address(0));
        require(msg.value >= fee, "vHub:fee");
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.MINT_SAVE_PERMIT,
                addr,
                data,
                cryptoLabel,
                labelHash,
                receiver,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        require(PrivateVault(vault).minted() == false, "vHub:has mint");

        uint256 amount = ITreasury(treasury).mint(receiver);

        PrivateVault(vault).saveWithMinting(data, cryptoLabel, labelHash);
        emit SaveMint(amount, tx.gasprice, block.timestamp);
    }

    function savePrivateDataWithoutMinting(
        address addr,
        string calldata data,
        string calldata cryptoLabel,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(stopable==false);
        require(msg.value >= fee, "vHub:fee");
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.SAVE_WITHOUT_MINT_PERMIT,
                addr,
                data,
                cryptoLabel,
                labelHash,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);

        PrivateVault(vault).saveWithoutMinting(data, cryptoLabel, labelHash);
        emit Save(tx.gasprice, block.timestamp);
    }

    function queryPrivateDataByIndex(
        address addr,
        uint64 index,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.QUERY_BY_INDEX_PERMIT,
                addr,
                index,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);

        return PrivateVault(vault).getPrivateDataByIndex(index);
    }

    function queryPrivateDataByName(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.QUERY_BY_NAME_PERMIT,
                addr,
                labelHash,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);

        return PrivateVault(vault).getPrivateDataByName(labelHash);
    }

    function queryPrivateVaultAddress(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (address) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.QUERY_PRIVATE_VAULT_ADDRESS_PERMIT,
                addr,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        return vault;
    }

    function hasMinted(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(VaultHubCallee.HAS_MINTED_PERMIT, addr, deadline, v, r, s, DOMAIN_SEPARATOR)
        );
        require(res == true);
        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        return PrivateVault(vault).minted();
    }

    function totalSavedItems(
        address addr,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (uint64) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(VaultHubCallee.TOTAL_SAVED_ITEMS_PERMIT, addr, deadline, v, r, s, DOMAIN_SEPARATOR)
        );
        require(res == true);

        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        return PrivateVault(vault).total();
    }

    function getLabelNameByIndex(
        address addr,
        uint256 deadline,
        uint64 index,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (string memory) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.GET_LABEL_NAME_PERMIT,
                addr,
                deadline,
                index,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);
        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        return PrivateVault(vault).labelName(index);
    }

    function labelExist(
        address addr,
        address labelHash,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external view returns (bool) {
        (bool res, ) = vaultHubPermissionLib.staticcall(
            abi.encodeWithSelector(
                VaultHubCallee.GET_LABEL_EXIST_PERMIT,
                addr,
                labelHash,
                deadline,
                v,
                r,
                s,
                DOMAIN_SEPARATOR
            )
        );
        require(res == true);
        (bool done, address vault) = _vaultHasRegister(addr);
        requireVaultRegistered(done);
        return PrivateVault(vault).labelIsExist(labelHash);
    }

    function withdrawETH(address payable receiver, uint256 amount) external returns (bool) {
        require(msg.sender == owner);
        receiver.transfer(amount);
        return true;
    }
}