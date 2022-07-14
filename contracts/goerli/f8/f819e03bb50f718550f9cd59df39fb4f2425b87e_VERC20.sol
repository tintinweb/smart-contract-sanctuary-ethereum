/**
 *Submitted for verification at Etherscan.io on 2022-07-12
*/

// SPDX-License-Identifier:MIT
pragma solidity ^0.8.10;

interface IERC20 {
    function totalSupply(
    ) external view returns (uint256);

    function balanceOf(
        address who
    ) external view returns (uint256);

    function decimals(
    ) external view returns (uint8);

    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

    function transfer(
        address to,
        uint256 value
    ) external returns (bool);

    function approve(
        address spender,
        uint256 value
    ) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function symbol(
    ) external view returns (string memory);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IVBase {

    enum Network { ETHEREUM, POLYGON }

    enum Role { USER, ADMIN, AUDITOR, SUPER_ADMIN }

    struct User {
        string id;
        string institutionId;
        address signingAddress;
        Role role;
        uint256 dailyLimit;
    }

    function name(
    ) external view returns (string memory);

    function version(
    ) external pure returns (string memory);

    function initialized(
    ) external view returns (bool);
}

interface IFxTunnel {

    function receiveMessage(
        bytes memory payload
    ) external;
}



interface IVERC20 is IERC20, IFxTunnel, IVBase {

    enum SyncKind { MINT, REDEEM, PAYOUT }

    struct Sync {
        SyncKind kind;
        string id;
        address who;
        uint256 amount;
        uint256 underlyingAmount;
    }

    // Used because stack is too deep.
    struct InitializeParameters {
        string name;
        string symbol;
        uint8 decimals;
        address underlyingAddress;
        uint256 underlyingSupplyLimit;
        string institutionId;
    }

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses,
        InitializeParameters memory initializeParameters
    ) external;

    function institutionId(
    ) external view returns (string memory);

    function underlying(
    ) external view returns (IERC20);

    function totalUnderlyingSupplyLimit(
    ) external view returns (uint256);

    function setTotalUnderlyingSupplyLimit(
        uint256 limit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function balancesOf(
       address who
    ) external view returns (uint256, uint256);

    function totalSupplies(
    ) external view returns (uint256, uint256);

    function pricePerToken(
    ) external view returns(uint256);

    function toAmount(
        uint256 underlyingAmount
    ) external view returns (uint256);

    function toUnderlyingAmount(
        uint256 amount
    ) external view returns (uint256);

    function hasSyncs(
        bytes32 _key
    ) external view returns (bool);

    function drainUnderlying(
        uint256 underlyingAmount,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function mintAndSync(
        string[] memory ids,
        address[] memory who,
        uint256[] memory underlyingAmounts,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function payoutAndSync(
        uint256 underlyingAmount
    ) external;

    function redeem(
        string memory id,
        uint256 underlyingAmount
    ) external;

    function sync(
        bool onlyPolygonSyncs,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    event Minted(
        uint256 amount,
        uint256 underlyingAmount
    );

    // Event uses arrays vs. Sync struct due to a bug in Web3j generating wrappers.
    event Synced(
        Network destination,
        string error,
        SyncKind[] kinds,
        string[] ids,
        address[] who,
        uint256[] amounts,
        uint256[] underlyingAmounts
    );

    // TODO: Next release.
    //    function transferAndSync(
    //        string memory id,
    //        uint256 underlyingAmount,
    //        address who
    //    ) external;
    //
    //    function mint(
    //        uint256 underlyingAmount
    //    ) external;
}

interface IVUser is IVBase {

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses,
        User[] memory _superAdmins,
        User[] memory _auditors
    ) external;

    function superAdmins(
    ) external view returns (User[] memory);

    function auditors(
    ) external view returns (User[] memory);

    function admins(
        string memory institutionId
    ) external view returns (User[] memory);

    function vWalletAddresses(
        string memory userId
    ) external view returns (address[] memory);

    function byId(
        string memory id
    ) external view returns (User memory);

    function byAddress(
        address who
    ) external view returns (User memory);

    function add(
        string memory id,
        string memory institutionId,
        address signingAddress,
        uint256 dailyLimit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function addOrPromote(
        string memory id,
        Role role,
        string memory institutionId,
        address signingAddress,
        uint256 dailyLimit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function demote(
        string memory id,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function swapSigningAddress(
        string memory userId,
        address signingAddress,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function mapVWallet(
        address who,
        string memory userId
    ) external;

    function isWithinDailyLimit(
        string memory userId,
        uint256 amount
    ) external returns (bool);

    function setDailyLimit(
        string memory id,
        uint256 dailyLimit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;
}

interface IVBridge is IVBase {

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses
    ) external;

    function validateAndExtractMessage(
        bytes memory payload
    ) external returns (bytes memory);
}

interface IVSwap is IVBase {

    struct Price {
        string symbol;
        uint256 vYieldPercent;
        uint256 institutionYieldPercent;
        uint256 pricePerToken;
        uint256 timestamp;
    }

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses
    ) external;

    function price(
        string memory symbol
    ) external view returns (Price memory);

    function syncYieldPercents(
        address[] memory vERC20Addresses,
        uint256[] memory vYieldPercents,
        uint256[] memory institutionYieldPercents,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function readyToSyncPricePerTokens(
    ) external view returns (bool);

    function syncPricePerTokens(
        bool shouldPayout,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    event PricePerTokensSynced(
        string[] symbols,
        uint256[] vYieldPercents,
        uint256[] institutionYieldPercents,
        uint256[] pricePerTokens,
        uint256 timestamp
    );
}

interface IYearnVault is IERC20 {
    function name(
    ) external pure returns (string memory);

    function deposit(
        uint256 underlyingAmount,
        address recipientAddress
    ) external returns (uint256);

    function withdraw(
        uint256 amount,
        address recipientAddress,
        uint256 maxLoss
    ) external returns (uint256);

    function token(
    ) external pure returns (address);

    function pricePerShare(
    ) external view returns (uint256);

    function totalAssets(
    ) external view returns (uint256);

    function apiVersion(
    ) external pure returns (string memory);

    // Goerli testnet only.
    function syncPricePerToken(
    ) external;
}

interface IVDeFi is IVBase {

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses
    ) external;

    function balances(
        address underlyingAddress
    ) external view returns (uint256, uint256);

    function balancesOf(
        address who
    ) external view returns (uint256, uint256);

    function yearnVault(
        address underlyingAddress
    ) external view returns (IYearnVault);

    function addYearnVault(
        address yVaultAddress,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function deposit(
        uint256 underlyingAmount
    ) external;

    function withdraw(
        uint256 underlyingAmount,
        address recipientAddress
    ) external;

    function payout(
    ) external;

    event YearnVaultAdded(
        string name,
        string symbol,
        uint8 decimals,
        string underlyingSymbol
    );
}


interface IVLighthouse is IVBase {

    function vERC20s(
    ) external view returns (IVERC20[] memory);

    function vERC20BySymbol(
        string memory symbol
    ) external view returns (IVERC20);

    function vERC20ByInstitutionIdAndUnderlyingAddress(
        string memory institutionId,
        address underlyingAddress
    ) external view returns (IVERC20);

    function isVSwap(
        address who
    ) external view returns (bool);

    function isVDeFi(
        address who
    ) external view returns (bool);

    function isVWallet(
        address who
    ) external view returns (bool);

    function isVERC20(
        address who
    ) external view returns (bool);

    function initialize(
        uint256 _chainId,
        User[] memory superAdmins,
        User[] memory auditors,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function deployVERC20Proxy(
        uint256 _chainId,
        IVERC20.InitializeParameters memory initializeParameters,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function deployVWalletProxy(
        uint256 _chainId,
        string memory userId,
        string memory salt,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function chainId(
    ) external view returns (uint256);

    function vInstitutionId(
    ) external view returns (string memory);

    function requiredSignatures(
        Role role
    ) external view returns (uint256);

    function maxSyncs(
    ) external view returns (uint256);

    function setMaxSyncs(
        uint256 _maxSyncs,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function addressByKey(
        bytes32 _key
    ) external view returns (address);

    function redeemAddress(
        string memory symbol
    ) external view returns (address);

    function payoutAddress(
        string memory institutionId
    ) external view returns (address);

    function operationalAddress(
        string memory institutionId
    ) external view returns (address);

    function syncImplementationAddresses(
        uint256 _chainId,
        string[] memory keys,
        address[] memory addresses,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function syncAddresses(
        uint256 _chainId,
        string[] memory keys,
        address[] memory addresses,
        string[] memory nestedKeys1,
        string[] memory nestedKeys2,
        address[] memory nestedAddresses,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    function swapVSigningAddress(
        uint256 _chainId,
        address signingAddress,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) external;

    // Stubbed for Web3j generating wrappers bug.
    function stubbedForWeb3jGenerationBug(
    ) external pure returns (User memory);

    event Initialized(
        address vUserProxyAddress,
        address vBridgeProxyAddress,
        address vDeFiProxyAddress,
        address vExchangeProxyAdddress
    );

    event Deployed(
        address who
    );
}

abstract contract AVBase is IVBase {

    struct Signatures {
        string nonce;
        bytes32 hash;
        uint8[] v;
        bytes32[] r;
        bytes32[] s;
    }

    // Chain IDs.
    uint256 internal constant ETHEREUM_MAINNET = 1;
    uint256 internal constant ETHEREUM_GOERLI = 5;
    uint256 internal constant POLYGON_MAINNET = 137;
    uint256 internal constant POLYGON_MUMBAI = 80001;

    // 10,000 basis points.
    uint256 internal constant BPS = 10000;

    // Keys.
    bytes32 internal constant INITIALIZED = keccak256("INITIALIZED");
    bytes32 internal constant SUPER_ADMIN_REQUIRED_SIGNATURES = keccak256("SUPER_ADMIN_REQUIRED_SIGNATURES");
    bytes32 internal constant AUDITOR_REQUIRED_SIGNATURES = keccak256("AUDITOR_REQUIRED_SIGNATURES");
    bytes32 internal constant ADMIN_REQUIRED_SIGNATURES = keccak256("ADMIN_REQUIRED_SIGNATURES");
    bytes32 internal constant VLIGHTHOUSE_PROXY_ADDRESS = keccak256("VLIGHTHOUSE_PROXY_ADDRESS");
    bytes32 internal constant VLIGHTHOUSE_ADDRESS = keccak256("VLIGHTHOUSE_ADDRESS");
    bytes32 internal constant VUSER_PROXY_ADDRESS = keccak256("VUSER_PROXY_ADDRESS");
    bytes32 internal constant VUSER_ADDRESS = keccak256("VUSER_ADDRESS");
    bytes32 internal constant VBRIDGE_PROXY_ADDRESS = keccak256("VBRIDGE_PROXY_ADDRESS");
    bytes32 internal constant VBRIDGE_ADDRESS = keccak256("VBRIDGE_ADDRESS");
    bytes32 internal constant VDEFI_PROXY_ADDRESS = keccak256("VDEFI_PROXY_ADDRESS");
    bytes32 internal constant VDEFI_ADDRESS = keccak256("VDEFI_ADDRESS");
    bytes32 internal constant VSWAP_PROXY_ADDRESS = keccak256("VSWAP_PROXY_ADDRESS");
    bytes32 internal constant VSWAP_ADDRESS = keccak256("VSWAP_ADDRESS");
    bytes32 internal constant VERC20_ADDRESS = keccak256("VERC20_ADDRESS");
    bytes32 internal constant VWALLET_ADDRESS = keccak256("VWALLET_ADDRESS");
    bytes32 internal constant VSIGNING_ADDRESS = keccak256("VSIGNING_ADDRESS");
    bytes32 internal constant NAME = keccak256("NAME");
    bytes32 internal constant CHAIN_ID = keccak256("CHAIN_ID");
    bytes32 internal constant VINSTITUTION_ID = keccak256("VINSTITUTION_ID");
    bytes32 internal constant NONCES = keccak256("NONCES");

    // Base storage using a hashmap style for dynamic use and to protect against storage collision, which should always be appended!
    mapping(bytes32 => bytes32) internal bytes32Map;
    mapping(bytes32 => bytes) internal bytesMap;
    mapping(bytes32 => uint8) internal uint8Map;
    mapping(bytes32 => uint256) internal uintMap;
    mapping(bytes32 => bool) internal boolMap;
    mapping(bytes32 => string) internal stringMap;
    mapping(bytes32 => address) internal addressMap;
    mapping(bytes32 => address[]) internal addressArrayMap;
    mapping(bytes32 => mapping(bytes32 => address[])) internal bytes32ToAddressArrayMap;
    mapping(bytes32 => mapping(bytes32 => bytes)) internal bytes32ToBytesMap;
    mapping(bytes32 => mapping(address => uint256)) internal addressToUintMap;
    mapping(bytes32 => mapping(address => mapping(address => uint256))) internal addressToAddressToUnitMap;
    mapping(bytes32 => mapping(bytes32 => address)) internal bytes32ToAddressMap;
    mapping(bytes32 => mapping(address => bytes32)) internal addressToBytes32Map;
    mapping(bytes32 => mapping(bytes32 => bool)) internal bytes32ToBoolMap;

    function version(
    ) override public pure returns (string memory) {
        return "Lime Kiln";
    }

    function initialized(
    ) override public view returns (bool) {
        return boolMap[INITIALIZED];
    }

    function vLighthouse(
    ) internal view returns (IVLighthouse) {
        return IVLighthouse(addressMap[VLIGHTHOUSE_PROXY_ADDRESS]);
    }

    function vUser(
    )  internal view returns (IVUser) {
        return IVUser(addressMap[VUSER_PROXY_ADDRESS]);
    }

    function vSigningAddress(
    ) virtual internal view returns (address) {
        return vLighthouse().addressByKey(VSIGNING_ADDRESS);
    }
    
    function key(
        string memory _key
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_key));
    }

    function key(
        address _address
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_address));
    }

    function isEthereum(
    ) internal view returns (bool) {
        return vLighthouse().chainId() == ETHEREUM_MAINNET || vLighthouse().chainId() == ETHEREUM_GOERLI;
    }

    function isPolygon(
    ) internal view returns (bool) {
        return vLighthouse().chainId() == POLYGON_MUMBAI || vLighthouse().chainId() == POLYGON_MAINNET;
    }

    modifier onlyEthereum(
    ) {
        require(isEthereum(), "AVBase:ONLY_ETHEREUM");
        _;
    }

    modifier onlyPolygon(
    ) {
        require(isPolygon(), "AVBase:ONLY_POLYGON");
        _;
    }

    modifier onlyVesto(
        Signatures memory signatures
    ) {
        address[] memory addresses = recoverAddresses(signatures);
        require(containsVSigningAddress(addresses), "AVBase:ACCESS_DENIED");
        _;
    }

    modifier onlyRole(
        Role role,
        string memory institutionId,
        Signatures memory signatures
    ) {
        address[] memory addresses = recoverAddresses(signatures);
        if (role == Role.ADMIN) {
            require(containsAdminSigningAddresses(institutionId, addresses) && containsVSigningAddress(addresses), "AVBase:ACCESS_DENIED");
        } else {
            require(containsSigningAddresses(role, institutionId, addresses) && containsVSigningAddress(addresses), "AVBase:ACCESS_DENIED");
        }
        _;
    }

    modifier onlyVLighthouse(
        address who
    ) {
        require(addressMap[VLIGHTHOUSE_PROXY_ADDRESS] == who, "AVBase:ONLY_VLIGHTHOUSE");
        _;
    }

    modifier onlyVSwap(
        address who
    ) {
        require(vLighthouse().isVSwap(who), "AVBase:ONLY_VSWAP");
        _;
    }

    modifier onlyVDeFi(
        address who
    ) {
        require(vLighthouse().isVDeFi(who), "AVBase:ONLY_VDEFI");
        _;
    }

    modifier onlyVERC20(
        address who
    ) {
        require(vLighthouse().isVERC20(who), "AVBase:ONLY_VERC20");
        _;
    }

    modifier onlyVWallet(
        address who
    ) {
        require(vLighthouse().isVWallet(who), "AVBase:ONLY_VWALLET");
        _;
    }

    /**
    @param signatures - Signatures of the addresses to recover.
    @return signedBy - Returns the recovered addresses.
    */
    function recoverAddresses(
        Signatures memory signatures
    ) internal returns (address[] memory signedBy) {
        (uint256 begin, uint256 end) = spliceTimestamps(signatures.nonce);
        require(begin <= block.timestamp && end >= block.timestamp, "AVBase:INVALID_TIMESTAMPS");
        require(!bytes32ToBoolMap[NONCES][key(signatures.nonce)], "AVBase:POSSIBLE_REPLAY_ATTACK");

        address[] memory addresses = new address[](signatures.v.length);
        for (uint i = 0; i < addresses.length; i++) {
            // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
            uint8 csv = signatures.v[i];
            if (csv < 27) {
                csv += 27;
            }
            require(csv == 27 || csv == 28, "AVBase:INVALID_SIGNATURE_VERSION");
            addresses[i] = ecrecover(signatures.hash, csv, signatures.r[i], signatures.s[i]);
            require(addresses[i] != address(0x0), "AVBase:INVALID_SIGNATURE");
        }
        require(!hasDuplicate(addresses), "AVBase:DUPLICATE_RECOVERED_ADDRESSES");
        bytes32ToBoolMap[NONCES][key(signatures.nonce)] = true;
        return addresses;
    }

    function spliceTimestamps(
        string memory nonce
    ) private pure returns (uint256 begin, uint256 end) {
        bytes memory _bytes = bytes(nonce);
        require(_bytes.length == 56, "AVBase:INVALID_NONCE_LENGTH");

        uint256 result = 0;
        for (uint256 i = 36; i < _bytes.length; i++) {
            uint256 b = uint(uint8(_bytes[i]));
            if (b >= 48 && b <= 57) {
                result = result * 10 + (b - 48);
            }
        }
        begin = result / 1e10;
        end = result % 1e10;
    }

    function hasDuplicate(
        address[] memory addresses
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < addresses.length - 1; i++) {
            for (uint256 j = i + 1; j < addresses.length; j++) {
                if (addresses[i] == addresses[j]) {
                    return true;
                }
            }
        }
        return false;
    }

    function containsVSigningAddress(
        address[] memory addresses
    ) internal view returns (bool) {
        address _vSigningAddress = vSigningAddress();
        for (uint i = 0; i < addresses.length; i++) {
            if (_vSigningAddress == addresses[i]) {
                return true;
            }
        }
        return false;
    }

    function containsSigningAddresses(
        Role role,
        string memory institutionId,
        address[] memory addresses
    ) internal view returns (bool) {
        uint256 requiredSignatures = vLighthouse().requiredSignatures(role);
        uint256 signatures = 0;
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == vSigningAddress()) {
                continue;
            }

            User memory user = vUser().byAddress(addresses[i]);
            if (user.signingAddress != address(0x0) && user.role == role && compare(user.institutionId, institutionId) && ++signatures >= requiredSignatures) {
                return true;
            }
        }
        return false;
    }

    function containsAdminSigningAddresses(
        string memory institutionId,
        address[] memory addresses
    ) private view returns (bool) {
        uint256 requiredSignatures = vLighthouse().requiredSignatures(Role.ADMIN);
        uint256 signatures = 0;
        for (uint i = 0; i < addresses.length; i++) {
            if (addresses[i] == vSigningAddress()) {
                continue;
            }

            User memory user = vUser().byAddress(addresses[i]);
            if (user.signingAddress != address(0x0) && (user.role == Role.ADMIN || user.role == Role.SUPER_ADMIN) && compare(user.institutionId, institutionId) && ++signatures >= requiredSignatures) {
                return true;
            }
        }
        return false;
    }

    function compare(
        string memory a,
        string memory b
    ) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }
}

interface IFxStateSender {
    function sendMessageToChild(
        address _receiver,
        bytes calldata _data
    ) external;
}

interface IFxMessageProcessor {
    function processMessageFromRoot(
        uint256 stateId,
        address rootMessageSender,
        bytes calldata data
    ) external;
}

abstract contract AFxTunnel is IFxMessageProcessor, IFxTunnel, AVBase {

    event MessageSent(
        bytes message
    );

    // Keys.
    bytes32 internal constant FX_ROOT_ADDRESS = keccak256("FX_ROOT_ADDRESS");
    bytes32 internal constant FX_CHILD_ADDRESS = keccak256("FX_CHILD_ADDRESS");
    bytes32 internal constant PROCESSED_EXITS = keccak256("PROCESSED_EXITS");

    function vBridge(
    ) internal view returns (IVBridge) {
        return IVBridge(addressMap[VBRIDGE_PROXY_ADDRESS]);
    }

    function fxChild(
    ) internal view returns (address) {
        return vLighthouse().addressByKey(FX_CHILD_ADDRESS);
    }

    function fxRoot(
    ) internal view returns (IFxStateSender) {
        return IFxStateSender(vLighthouse().addressByKey(FX_ROOT_ADDRESS));
    }

    function sendMessageToChild(
        bytes memory message
    ) onlyEthereum(
    ) internal {
        fxRoot().sendMessageToChild(address(this), message);
    }

    function sendMessageToRoot(
        bytes memory message
    ) onlyPolygon(
    ) internal {
        emit MessageSent(message);
    }

    function processMessageFromRoot(
        //uint256 stateId,
        uint256 ,
        address rootMessageSender,
        bytes calldata message
    ) onlyPolygon(
    ) external override {
        require(msg.sender == fxChild() && rootMessageSender == address(this), "AFxTunnel:INVALID_SENDER");
        processMessageFromRoot(message);
    }

    function processMessageFromRoot(
        bytes memory message
    ) virtual internal;

    /**
     * @notice receive message from L2 to L1, validated by proof
     * @dev This function verifies if the transaction actually happened on child chain
     *
     * @param payload RLP encoded data of the reference tx containing following list of fields
     *  0 - headerNumber - Checkpoint header block number containing the reference tx
     *  1 - blockProof - Proof that the block header (in the child chain) is a leaf in the submitted merkle root
     *  2 - blockNumber - Block number containing the reference tx on child chain
     *  3 - blockTime - Reference tx block time
     *  4 - txRoot - Transactions root of block
     *  5 - receiptRoot - Receipts root of block
     *  6 - receipt - Receipt of the reference transaction
     *  7 - receiptProof - Merkle proof of the reference receipt
     *  8 - branchMask - 32 bits denoting the path of receipt in merkle tree
     *  9 - receiptLogIndex - Log Index to read from the receipt
     */
    function receiveMessage(
        bytes memory payload
    ) onlyEthereum(
    ) override public virtual {
        bytes memory message = vBridge().validateAndExtractMessage(payload);
        processMessageFromChild(message);
    }

    /**
     * @notice Process message received from Child Tunnel
     * @dev function needs to be implemented to handle message as per requirement
     * This is called by onStateReceive function.
     * Since it is called via a system call, any event will not be emitted during its execution.
     * @param message bytes message that was sent from Child Tunnel
     */
    function processMessageFromChild(
        bytes memory message
    ) virtual internal;
}

abstract contract AERC20 is IERC20, AFxTunnel {

    // Keys.
    bytes32 internal constant SYMBOL = keccak256("SYMBOL");
    bytes32 internal constant DECIMALS = keccak256("DECIMALS");
    bytes32 internal constant BALANCES = keccak256("BALANCES");
    bytes32 internal constant SUPPLY = keccak256("SUPPLY");
    bytes32 internal constant ALLOWANCES = keccak256("ALLOWANCES");

    function symbol(
    ) override public view returns (string memory) {
        return stringMap[SYMBOL];
    }

    function decimals(
    ) override public view returns (uint8) {
        return uint8Map[DECIMALS];
    }

    function totalSupply(
    ) override public view returns (uint256) {
        return uintMap[SUPPLY];
    }

    function balanceOf(
        address who
    ) override public view returns (uint256) {
        return addressToUintMap[BALANCES][who];
    }

    function allowance(
        address account,
        address spender
    ) override public view returns (uint256) {
        return addressToAddressToUnitMap[ALLOWANCES][account][spender];
    }

    function approve(
        address spender,
        uint256 amount
    ) override public returns (bool) {
        return approve(msg.sender, spender, amount);
    }

    function transfer(
        address to,
        uint256 amount
    ) override public returns (bool) {
        transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) override public returns (bool) {
        require(msg.sender != from, "AERC20:SPENDER_IS_FROM");
        require(allowance(from,  msg.sender) >= amount, "AERC20:EXCEEDS_SPENDER_ALLOWANCE");
        addressToAddressToUnitMap[ALLOWANCES][from][msg.sender] -= amount;
        transfer(from, to, amount);
        return true;
    }

    function approve(
        address account,
        address spender,
        uint256 amount
    ) internal returns (bool) {
        addressToAddressToUnitMap[ALLOWANCES][account][spender] = amount;
        emit Approval(account, spender, amount);
        return true;
    }

    function transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != to, "AERC20:FROM_IS_TO");
        require(from != address(0x0), "AERC20:FROM_ADDRESS_IS_ZERO");
        require(to != address(0x0), "AERC20:TO_ADDRESS_IS_ZERO");
        require(addressToUintMap[BALANCES][from] >= amount, "AERC20:INSUFFICIENT_BALANCE");

        addressToUintMap[BALANCES][from] -= amount;
        addressToUintMap[BALANCES][to] += amount;
        emit Transfer(from, to, amount);
    }
}


/**
 * @notice Redeem on Ethereum and transferAndSync ( SyncKind.TRANSFER) in next release.
 */
contract VERC20 is IVERC20, AERC20 {

    // Keys.
    bytes32 internal constant UNDERLYING_ADDRESS = keccak256("UNDERLYING_ADDRESS");
    bytes32 internal constant POLYGON_SYNCS = keccak256("POLYGON_SYNCS");
    bytes32 internal constant ETHEREUM_SYNCS = keccak256("ETHEREUM_SYNCS");
    bytes32 internal constant INSTITUTION_ID = keccak256("INSTITUTION_ID");
    bytes32 internal constant TOTAL_UNDERLYING_SUPPLY_LIMIT = keccak256("TOTAL_UNDERLYING_SUPPLY_LIMIT");

    // Sync size.
    uint internal constant SYNCS_TO_POLYGON_SIZE = 5;

    function name(
    ) override public pure returns (string memory) {
        return "Vesto VERC20";
    }

    function initialize(
        bytes32[] memory proxyKeys,
        address[] memory proxyAddresses,
        InitializeParameters memory initializeParameters
    ) onlyVLighthouse(
        msg.sender
    ) override public {
        require(!boolMap[INITIALIZED], "VERC20:ALREADY_INITIALIZED");
        for (uint i = 0; i < proxyKeys.length; i++) {
            addressMap[proxyKeys[i]] = proxyAddresses[i];
        }
        stringMap[NAME] = initializeParameters.name;
        stringMap[SYMBOL] = initializeParameters.symbol;
        uint8Map[DECIMALS] = initializeParameters.decimals;
        addressMap[UNDERLYING_ADDRESS] = initializeParameters.underlyingAddress;
        uintMap[TOTAL_UNDERLYING_SUPPLY_LIMIT] = initializeParameters.underlyingSupplyLimit;
        stringMap[INSTITUTION_ID] = initializeParameters.institutionId;
        boolMap[INITIALIZED] = true;
    }

    function vDeFi(
    ) internal view returns (IVDeFi) {
        return IVDeFi(addressMap[VDEFI_PROXY_ADDRESS]);
    }

    function vSwap(
    ) internal view returns (IVSwap) {
        return IVSwap(addressMap[VSWAP_PROXY_ADDRESS]);
    }

    function institutionId(
    ) override public view returns (string memory) {
        return stringMap[INSTITUTION_ID];
    }

    function underlying(
    ) override public view returns (IERC20) {
        return IERC20(addressMap[UNDERLYING_ADDRESS]);
    }

    function totalUnderlyingSupplyLimit(
    ) override public view returns (uint256) {
        return uintMap[TOTAL_UNDERLYING_SUPPLY_LIMIT];
    }

    function setTotalUnderlyingSupplyLimit(
        uint256 limit,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) onlyEthereum(
    ) onlyRole(
        Role.SUPER_ADMIN, vLighthouse().vInstitutionId(), Signatures(nonce, keccak256(abi.encode(address(this), "setTotalUnderlyingSupplyLimit", limit, nonce)), v, r, s)
    ) override public {
        uintMap[TOTAL_UNDERLYING_SUPPLY_LIMIT] = limit;
    }

    function balancesOf(
        address who
    ) override public view returns (uint256, uint256) {
        uint256 balance = balanceOf(who);
        return (balance, toUnderlyingAmount(balance));
    }

    function totalSupplies(
    ) override public view returns (uint256, uint256) {
        uint256 totalSupply = totalSupply();
        return (totalSupply, toUnderlyingAmount(totalSupply));
    }

    function pricePerToken(
    ) override public view returns (uint256) {
        uint256 _pricePerToken = vSwap().price(symbol()).pricePerToken;
        return _pricePerToken == 0 ? 10 ** decimals() : _pricePerToken;
    }

    /**
    @notice Converts the underlying tokens to VERC20 tokens based on the price per token (underlying tokens / price per token).
            The VERC20 price per token increases every 24 hours based on the APY.
    @param underlyingAmount - Amount of the underlying tokens to convert to VERC20 tokens.
    */
    function toAmount(
        uint256 underlyingAmount
    ) override public view returns (uint256) {
        return (underlyingAmount * (10 ** decimals())) / pricePerToken();
    }

    /**
    @notice Converts VERC20 tokens to underlying tokens based on the price per token (VERC20 tokens * price per token).
            The VERC20 price per token increases every 24 hours based on the APY.
    @param amount - Amount of VERC20 tokens to convert to underlying tokens.
    */
    function toUnderlyingAmount(
        uint256 amount
    ) override public view returns (uint256) {
        return (amount * pricePerToken()) / (10 ** decimals());
    }

    function syncs(
        bytes32 _key
    ) private view returns (Sync[] memory) {
        return bytesMap[_key].length == 0 ? new Sync[](0) : abi.decode(bytesMap[_key], (Sync[]));
    }

    function hasSyncs(
        bytes32 _key
    ) override public view returns (bool) {
        return syncs(_key).length > 0 ? true : false;
    }

    /**
    @notice Transfers underlying to the redeem address (i.e., Circle's wallet) in the event the institution does
            not want to mint the underlying tokens (e.g., USDC).
    @param underlyingAmount - Amount of the underlying tokens to drain.
    */
    function drainUnderlying(
        uint256 underlyingAmount,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) onlyEthereum (
    ) onlyRole(
        Role.ADMIN, institutionId(), Signatures(nonce, keccak256(abi.encode(address(this), "drainUnderlying", underlyingAmount, nonce)), v, r, s)
    ) override public {
        address redeemAddress = vLighthouse().redeemAddress(underlying().symbol());
        require(redeemAddress != address(0x0), "VERC20:REDEEM_ADDRESS_IS_ZERO");

        (, uint256 underlyingBalance) = balancesOf(address(this));
        require(underlyingAmount <= underlyingBalance, "VERC20:INSUFFICIENT_UNDERLYING_BALANCE");
        underlying().transfer(redeemAddress, underlyingAmount);
    }

    /**
    @notice Deposits underlying tokens into DeFi, mints VERC20 tokens, and syncs minted tokens to Polygon.
    @param ids - Off chain unique identifiers of the respective transactions.
    @param who - Addresses of VWallets to mint VERC20 tokens to on Polygon.
    @param underlyingAmounts - Underlying token amounts to deposit into DeFi and mint VERC20 tokens.
    */
    function mintAndSync(
        string[] memory ids,
        address[] memory who,
        uint256[] memory underlyingAmounts,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) onlyEthereum (
    ) onlyRole(
        Role.ADMIN, institutionId(), Signatures(nonce, keccak256(abi.encode(address(this), "mintAndSync", ids, who, underlyingAmounts, nonce)), v, r, s)
    ) override public {
        require(
            ids.length == who.length &&
            who.length == underlyingAmounts.length &&
            underlyingAmounts.length > 0,
            "VERC20:MISMATCHED_OR_EMPTY_ARRAYS"
        );

        uint256 totalAmount;
        uint256 totalUnderlyingAmount;
        for (uint i = 0; i < ids.length; i++) {
            require(who[i] != address(0x0), "VERC20:WHO_ADDRESS_IS_ZERO");
            //require(vLighthouse().isVWallet(who[i]), "VERC20:WHO_ADDRESS_IS_NOT_VWALLET"); // TODO: VWallet addresses are not stored on Ethereum just Polygon...maybe batch from Ethereum
            require(underlyingAmounts[i] > 0, "VERC20:UNDERLYING_AMOUNT_IS_ZERO");

            totalAmount += toAmount(underlyingAmounts[i]);
            totalUnderlyingAmount += underlyingAmounts[i];
        }
        require(underlying().balanceOf(address(this)) >= totalUnderlyingAmount, "VERC20:INSUFFICIENT_UNDERLYING_BALANCE");

        // Check underlying limit.
        (, uint256 underlyingSupply) = totalSupplies();
        require((underlyingSupply + totalUnderlyingAmount) < totalUnderlyingSupplyLimit(), "VERC20:EXCEEDS_UNDERLYING_LIMIT");

        // Transfer underlying tokens to VDeFi.
        underlying().transfer(address(vDeFi()), totalUnderlyingAmount);

        // Deposit underlying tokens into Yearn vault, mint VERC20 tokens to vBridge for lockup until returned from Polygon,
        // and sync VERC20 tokens to Polygon.
        vDeFi().deposit(totalUnderlyingAmount);
        mint(address(vBridge()), totalAmount, totalUnderlyingAmount);

        // Send syncs to Polygon.
        sendSyncsToPolygon(ids, who, underlyingAmounts);
    }

    /**
    @notice Mints VERC20 tokens for payouts and syncs them to Polygon. Payout VERC20 tokens are based on the yield
            generated and not the deposit of underlying tokens.
    @param underlyingAmount - Amount of underlying tokens to payout in VERC20 tokens.
    */
    function payoutAndSync(
        uint256 underlyingAmount
    ) onlyEthereum(
    ) onlyVDeFi(
        msg.sender
    ) override public {
        address payoutAddress = vLighthouse().payoutAddress(institutionId());
        require(payoutAddress != address(0x0), "VERC20:PAYOUT_ADDRESS_IS_ZERO");

        uint256 amount = toAmount(underlyingAmount);
        Sync[] memory _syncs = new Sync[](1);
        _syncs[0].kind = SyncKind.PAYOUT;
        _syncs[0].who = payoutAddress;
        _syncs[0].amount = amount;
        _syncs[0].underlyingAmount = underlyingAmount;

        // Mint amount to vBridge to lockup until returned from Polygon and sync to Polygon.
        mint(address(vBridge()), amount, underlyingAmount);
        sendMessageToChild(abi.encode(_syncs));
    }

    /**
    @notice Redeems VERC20 tokens (wrapped position) for underlying tokens (e.g., USDC) by syncing VERC20 tokens to Ethereum and
            then withdrawing them from A Yearn vault.
    @param id - Unique identifier for the transaction used off-chain (optional).
    @param underlyingAmount - Amount of underlying tokens to redeem.
    */
    function redeem(
        string memory id,
        uint256 underlyingAmount
    ) onlyVWallet(
        msg.sender
    ) onlyPolygon(
    ) override public {
        require(syncs(ETHEREUM_SYNCS).length+1 <= vLighthouse().maxSyncs(), "VERC20:EXCEEDS_MAX_SYNCS");

        uint256 amount = toAmount(underlyingAmount);
        require(amount <= balanceOf(msg.sender), "VERC20:INSUFFICIENT_BALANCE");
        IVERC20(address(this)).transferFrom(msg.sender, address(this), amount);

        Sync memory _sync;
        _sync.kind = SyncKind.REDEEM;
        _sync.id = id;
        _sync.who = msg.sender;
        _sync.amount = amount;
        _sync.underlyingAmount = underlyingAmount;
        push(ETHEREUM_SYNCS, _sync);
    }

    function sync(
        bool onlyPolygonSyncs,
        string memory nonce,
        uint8[] memory v,
        bytes32[] memory r,
        bytes32[] memory s
    ) onlyPolygon(
    ) onlyVesto(
        Signatures(nonce, keccak256(abi.encode(address(this), "sync", onlyPolygonSyncs, nonce)), v, r, s)
    ) override public {
        require(hasSyncs(POLYGON_SYNCS) || hasSyncs(ETHEREUM_SYNCS), "VERC20:NO_SYNCS");

        if (hasSyncs(POLYGON_SYNCS)) {
            emitSyncEvent(Network.POLYGON, syncs(POLYGON_SYNCS));
            delete bytesMap[POLYGON_SYNCS];
        }

        if (!onlyPolygonSyncs && hasSyncs(ETHEREUM_SYNCS)) {
            sendMessageToRoot(abi.encode(syncs(ETHEREUM_SYNCS)));
            (uint256 totalAmount,) = emitSyncEvent(Network.ETHEREUM, syncs(ETHEREUM_SYNCS));
            delete bytesMap[ETHEREUM_SYNCS];
            burn(address(this), totalAmount);
        }
    }

    function processMessageFromRoot(
        bytes memory message
    ) override internal {
        Sync[] memory _syncs = abi.decode(message, (Sync[]));
        for (uint i = 0; i < _syncs.length; i++) {
            require(_syncs[i].kind == SyncKind.MINT || _syncs[i].kind == SyncKind.PAYOUT, "VERC20:INVALID_SYNC_KIND");
            mint(_syncs[i].who, _syncs[i].amount, _syncs[i].underlyingAmount);
            push(POLYGON_SYNCS, _syncs[i]);
        }
    }

    function processMessageFromChild(
        bytes memory message
    ) override internal {
        Sync[] memory _syncs = abi.decode(message, (Sync[]));
        uint256 totalRedeemAmount;
        uint256 totalRedeemUnderlyingAmount;

        for (uint i = 0; i < _syncs.length; i++) {
            require(_syncs[i].kind == SyncKind.REDEEM, "VERC20:INVALID_SYNC_KIND");
            totalRedeemAmount += _syncs[i].amount;
            totalRedeemUnderlyingAmount += _syncs[i].underlyingAmount;
        }

        // If withdrawing underlying tokens fails, VERC20 tokens are synced back to Polygon.
        if (totalRedeemUnderlyingAmount > 0) {
            try vDeFi().withdraw(totalRedeemUnderlyingAmount, vLighthouse().redeemAddress(underlying().symbol())) {
                burn(address(vBridge()), totalRedeemAmount);
                emitSyncEvent(Network.ETHEREUM, _syncs);
            } catch Error(string memory reason) {
                emitSyncEvent(Network.ETHEREUM, _syncs, reason);
                for (uint i = 0; i < _syncs.length; i++) {
                    _syncs[i].kind = SyncKind.MINT;
                    _syncs[i].amount = _syncs[i].amount;
                    _syncs[i].underlyingAmount = _syncs[i].underlyingAmount;
                }
                sendMessageToChild(abi.encode(_syncs));
            }
        }
    }

    /**
    @notice Sends syncs to Polygon in smaller amounts due to errors with larger payloads. This is also a separate
            function due to stack too deep.
    @param ids - Off chain unique identifiers of the respective transactions.
    @param who - Addresses of VWallets to mint VERC20 tokens to on Polygon.
    @param underlyingAmounts - Underlying token amounts.
    */
    function sendSyncsToPolygon(
        string[] memory ids,
        address[] memory who,
        uint256[] memory underlyingAmounts
    ) private {
        Sync[] memory _syncs = new Sync[](ids.length < SYNCS_TO_POLYGON_SIZE ? ids.length : SYNCS_TO_POLYGON_SIZE);
        uint j = 0;
        for (uint i = 0; i < ids.length; i++) {
            _syncs[j].kind = SyncKind.MINT;
            _syncs[j].id = ids[i];
            _syncs[j].who = who[i];
            _syncs[j].amount = toAmount(underlyingAmounts[i]);
            _syncs[j].underlyingAmount = underlyingAmounts[i];

            if (++j == SYNCS_TO_POLYGON_SIZE || i == ids.length - 1) {
                sendMessageToChild(abi.encode(_syncs));
                _syncs = new Sync[](ids.length - (i + 1) >= SYNCS_TO_POLYGON_SIZE ? SYNCS_TO_POLYGON_SIZE : ids.length - (i + 1));
                j = 0;
            }
        }
    }

    function emitSyncEvent(
        Network destination,
        Sync[] memory _syncs
    ) private returns (uint256, uint256) {
        return emitSyncEvent(destination, _syncs, "");
    }

    /**
    @notice Populates and emits a Sync event. This function uses arrays vs. Sync struct due to a bug in Web3j generating wrappers.
    */
    function emitSyncEvent(
        Network destination,
        Sync[] memory _syncs,
        string memory error
    ) private returns (uint256, uint256) {
        SyncKind[] memory kinds = new SyncKind[](_syncs.length);
        string[] memory ids = new string[](_syncs.length);
        address[] memory who = new address[](_syncs.length);
        uint256[] memory amounts = new uint256[](_syncs.length);
        uint256[] memory underlyingAmounts = new uint256[](_syncs.length);
        uint256 totalAmount;
        uint256 totalUnderlyingAmount;
        for (uint i = 0; i < _syncs.length; i++) {
            kinds[i] = _syncs[i].kind;
            ids[i] = _syncs[i].id;
            who[i] = _syncs[i].who;
            amounts[i] = _syncs[i].amount;
            underlyingAmounts[i] = _syncs[i].underlyingAmount;
            totalAmount += _syncs[i].amount;
            totalUnderlyingAmount += _syncs[i].underlyingAmount;
        }

        emit Synced(destination, error, kinds, ids, who, amounts, underlyingAmounts);
        return (totalAmount, totalUnderlyingAmount);
    }

    function push(
        bytes32 _key,
        Sync memory _sync
    ) private {
        Sync[] memory persistedSyncs = syncs(_key);
        Sync[] memory _syncs = new Sync[](persistedSyncs.length + 1);
        for (uint i = 0; i < persistedSyncs.length; i++) {
            _syncs[i] = persistedSyncs[i];
        }
        _syncs[_syncs.length - 1] = _sync;
        bytesMap[_key] = abi.encode(_syncs);
    }

    function mint(
        address who,
        uint256 amount,
        uint256 underlyingAmount
    ) private {
        addressToUintMap[BALANCES][who] += amount;
        uintMap[SUPPLY] += amount;
        emit Minted(amount, underlyingAmount);
        emit Transfer(address(0x0), who, amount);
    }

    function burn(
        address who,
        uint256 amount
    ) private {
        addressToUintMap[BALANCES][who] -= amount;
        uintMap[SUPPLY] -= amount;
        emit Transfer(who, address(0x0), amount);
    }
}