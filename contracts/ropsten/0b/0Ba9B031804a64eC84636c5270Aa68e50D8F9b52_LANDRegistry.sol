pragma solidity ^0.4.24;

import "../Storage.sol";
import "../upgradable/Ownable.sol";
import "../erc821/contracts/FullAssetRegistry.sol";
import "./ILANDRegistry.sol";
import "../metadata/IMetadataHolder.sol";

contract LANDRegistry is Storage, Ownable, FullAssetRegistry, ILANDRegistry {
    bytes4 public constant GET_METADATA =
        bytes4(keccak256("getMetadata(uint256)"));

    function initialize(bytes) external {
        _name = "Decentraland LAND";
        _symbol = "LAND";
        _description = "Contract that stores the Decentraland LAND registry";
    }

    modifier onlyProxyOwner() {
        require(
            msg.sender == proxyOwner,
            "This function can only be called by the proxy owner"
        );
        _;
    }

    modifier onlyDeployer() {
        require(
            msg.sender == proxyOwner || authorizedDeploy[msg.sender],
            "This function can only be called by an authorized deployer"
        );
        _;
    }

    modifier onlyOwnerOf(uint256 assetId) {
        require(
            msg.sender == _ownerOf(assetId),
            "This function can only be called by the owner of the asset"
        );
        _;
    }

    modifier onlyUpdateAuthorized(uint256 tokenId) {
        require(
            msg.sender == _ownerOf(tokenId) ||
                _isAuthorized(msg.sender, tokenId) ||
                _isUpdateAuthorized(msg.sender, tokenId),
            "msg.sender is not authorized to update"
        );
        _;
    }

    modifier canSetUpdateOperator(uint256 tokenId) {
        address owner = _ownerOf(tokenId);
        require(
            _isAuthorized(msg.sender, tokenId) ||
                updateManager[owner][msg.sender],
            "unauthorized user"
        );
        _;
    }

    function isUpdateAuthorized(address operator, uint256 assetId)
        external
        view
        returns (bool)
    {
        return _isUpdateAuthorized(operator, assetId);
    }

    function _isUpdateAuthorized(address operator, uint256 assetId)
        internal
        view
        returns (bool)
    {
        address owner = _ownerOf(assetId);

        return
            owner == operator ||
            updateOperator[assetId] == operator ||
            updateManager[owner][operator];
    }

    function authorizeDeploy(address beneficiary) external onlyProxyOwner {
        require(beneficiary != address(0), "invalid address");
        require(
            authorizedDeploy[beneficiary] == false,
            "address is already authorized"
        );

        authorizedDeploy[beneficiary] = true;
        emit DeployAuthorized(msg.sender, beneficiary);
    }

    function forbidDeploy(address beneficiary) external onlyProxyOwner {
        require(beneficiary != address(0), "invalid address");
        require(authorizedDeploy[beneficiary], "address is already forbidden");

        authorizedDeploy[beneficiary] = false;
        emit DeployForbidden(msg.sender, beneficiary);
    }

    function assignNewParcel(
        int256 x,
        int256 y,
        address beneficiary
    ) external onlyDeployer {
        _generate(_encodeTokenId(x, y), beneficiary);
        _updateLandBalance(address(0), beneficiary);
    }

    function assignMultipleParcels(
        int256[] x,
        int256[] y,
        address beneficiary
    ) external onlyDeployer {
        for (uint256 i = 0; i < x.length; i++) {
            _generate(_encodeTokenId(x[i], y[i]), beneficiary);
            _updateLandBalance(address(0), beneficiary);
        }
    }

    function ping() external {
        // solium-disable-next-line security/no-block-members
        latestPing[msg.sender] = block.timestamp;
    }

    function setLatestToNow(address user) external {
        require(
            msg.sender == proxyOwner || _isApprovedForAll(user, msg.sender),
            "Unauthorized user"
        );
        // solium-disable-next-line security/no-block-members
        latestPing[user] = block.timestamp;
    }

    function encodeTokenId(int256 x, int256 y) external pure returns (uint256) {
        return _encodeTokenId(x, y);
    }

    function _encodeTokenId(int256 x, int256 y)
        internal
        pure
        returns (uint256 result)
    {
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
        return _unsafeEncodeTokenId(x, y);
    }

    function _unsafeEncodeTokenId(int256 x, int256 y)
        internal
        pure
        returns (uint256)
    {
        return ((uint256(x) * factor) & clearLow) | (uint256(y) & clearHigh);
    }

    function decodeTokenId(uint256 value)
        external
        pure
        returns (int256, int256)
    {
        return _decodeTokenId(value);
    }

    function _unsafeDecodeTokenId(uint256 value)
        internal
        pure
        returns (int256 x, int256 y)
    {
        x = expandNegative128BitCast((value & clearLow) >> 128);
        y = expandNegative128BitCast(value & clearHigh);
    }

    function _decodeTokenId(uint256 value)
        internal
        pure
        returns (int256 x, int256 y)
    {
        (x, y) = _unsafeDecodeTokenId(value);
        require(
            -1000000 < x && x < 1000000 && -1000000 < y && y < 1000000,
            "The coordinates should be inside bounds"
        );
    }

    function expandNegative128BitCast(uint256 value)
        internal
        pure
        returns (int256)
    {
        if (value & (1 << 127) != 0) {
            return int256(value | clearLow);
        }
        return int256(value);
    }

    function exists(int256 x, int256 y) external view returns (bool) {
        return _exists(x, y);
    }

    function _exists(int256 x, int256 y) internal view returns (bool) {
        return _exists(_encodeTokenId(x, y));
    }

    function ownerOfLand(int256 x, int256 y) external view returns (address) {
        return _ownerOfLand(x, y);
    }

    function _ownerOfLand(int256 x, int256 y) internal view returns (address) {
        return _ownerOf(_encodeTokenId(x, y));
    }

    function ownerOfLandMany(int256[] x, int256[] y)
        external
        view
        returns (address[])
    {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );

        address[] memory addrs = new address[](x.length);
        for (uint256 i = 0; i < x.length; i++) {
            addrs[i] = _ownerOfLand(x[i], y[i]);
        }

        return addrs;
    }

    function landOf(address owner) external view returns (int256[], int256[]) {
        uint256 len = _assetsOf[owner].length;
        int256[] memory x = new int256[](len);
        int256[] memory y = new int256[](len);

        int256 assetX;
        int256 assetY;
        for (uint256 i = 0; i < len; i++) {
            (assetX, assetY) = _decodeTokenId(_assetsOf[owner][i]);
            x[i] = assetX;
            y[i] = assetY;
        }

        return (x, y);
    }

    function tokenMetadata(uint256 assetId) external view returns (string) {
        return _tokenMetadata(assetId);
    }

    function _tokenMetadata(uint256 assetId) internal view returns (string) {
        address _owner = _ownerOf(assetId);
        if (_isContract(_owner) && _owner != address(estateRegistry)) {
            if ((ERC165(_owner)).supportsInterface(GET_METADATA)) {
                return IMetadataHolder(_owner).getMetadata(assetId);
            }
        }
        return _assetData[assetId];
    }

    function landData(int256 x, int256 y) external view returns (string) {
        return _tokenMetadata(_encodeTokenId(x, y));
    }

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external {
        require(
            to != address(estateRegistry),
            "EstateRegistry unsafe transfers are not allowed"
        );
        return _doTransferFrom(from, to, assetId, "", false);
    }

    function transferLand(
        int256 x,
        int256 y,
        address to
    ) external {
        uint256 tokenId = _encodeTokenId(x, y);
        _doTransferFrom(_ownerOf(tokenId), to, tokenId, "", true);
    }

    function transferManyLand(
        int256[] x,
        int256[] y,
        address to
    ) external {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );

        for (uint256 i = 0; i < x.length; i++) {
            uint256 tokenId = _encodeTokenId(x[i], y[i]);
            _doTransferFrom(_ownerOf(tokenId), to, tokenId, "", true);
        }
    }

    function transferLandToEstate(
        int256 x,
        int256 y,
        uint256 estateId
    ) external {
        require(
            estateRegistry.ownerOf(estateId) == msg.sender,
            "You must own the Estate you want to transfer to"
        );

        uint256 tokenId = _encodeTokenId(x, y);
        _doTransferFrom(
            _ownerOf(tokenId),
            address(estateRegistry),
            tokenId,
            toBytes(estateId),
            true
        );
    }

    function transferManyLandToEstate(
        int256[] x,
        int256[] y,
        uint256 estateId
    ) external {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );
        require(
            estateRegistry.ownerOf(estateId) == msg.sender,
            "You must own the Estate you want to transfer to"
        );

        for (uint256 i = 0; i < x.length; i++) {
            uint256 tokenId = _encodeTokenId(x[i], y[i]);
            _doTransferFrom(
                _ownerOf(tokenId),
                address(estateRegistry),
                tokenId,
                toBytes(estateId),
                true
            );
        }
    }

    function setUpdateOperator(uint256 assetId, address operator)
        public
        canSetUpdateOperator(assetId)
    {
        updateOperator[assetId] = operator;
        emit UpdateOperator(assetId, operator);
    }

    function setManyUpdateOperator(uint256[] _assetIds, address _operator)
        public
    {
        for (uint256 i = 0; i < _assetIds.length; i++) {
            setUpdateOperator(_assetIds[i], _operator);
        }
    }

    function setUpdateManager(
        address _owner,
        address _operator,
        bool _approved
    ) external {
        require(
            _operator != msg.sender,
            "The operator should be different from owner"
        );
        require(
            _owner == msg.sender || _isApprovedForAll(_owner, msg.sender),
            "Unauthorized user"
        );

        updateManager[_owner][_operator] = _approved;

        emit UpdateManager(_owner, _operator, msg.sender, _approved);
    }

    event EstateRegistrySet(address indexed registry);

    function setEstateRegistry(address registry) external onlyProxyOwner {
        estateRegistry = IEstateRegistry(registry);
        emit EstateRegistrySet(registry);
    }

    function createEstate(
        int256[] x,
        int256[] y,
        address beneficiary
    ) external returns (uint256) {
        // solium-disable-next-line arg-overflow
        return _createEstate(x, y, beneficiary, "");
    }

    function createEstateWithMetadata(
        int256[] x,
        int256[] y,
        address beneficiary,
        string metadata
    ) external returns (uint256) {
        // solium-disable-next-line arg-overflow
        return _createEstate(x, y, beneficiary, metadata);
    }

    function _createEstate(
        int256[] x,
        int256[] y,
        address beneficiary,
        string metadata
    ) internal returns (uint256) {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );
        require(
            address(estateRegistry) != 0,
            "The Estate registry should be set"
        );

        uint256 estateTokenId = estateRegistry.mint(beneficiary, metadata);
        bytes memory estateTokenIdBytes = toBytes(estateTokenId);

        for (uint256 i = 0; i < x.length; i++) {
            uint256 tokenId = _encodeTokenId(x[i], y[i]);
            _doTransferFrom(
                _ownerOf(tokenId),
                address(estateRegistry),
                tokenId,
                estateTokenIdBytes,
                true
            );
        }

        return estateTokenId;
    }

    function toBytes(uint256 x) internal pure returns (bytes b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function updateLandData(
        int256 x,
        int256 y,
        string data
    ) external {
        return _updateLandData(x, y, data);
    }

    function _updateLandData(
        int256 x,
        int256 y,
        string data
    ) internal onlyUpdateAuthorized(_encodeTokenId(x, y)) {
        uint256 assetId = _encodeTokenId(x, y);
        address owner = _holderOf[assetId];

        _update(assetId, data);

        emit Update(assetId, owner, msg.sender, data);
    }

    function updateManyLandData(
        int256[] x,
        int256[] y,
        string data
    ) external {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );
        for (uint256 i = 0; i < x.length; i++) {
            _updateLandData(x[i], y[i], data);
        }
    }

    function setLandBalanceToken(address _newLandBalance)
        external
        onlyProxyOwner
    {
        require(
            _newLandBalance != address(0),
            "New landBalance should not be zero address"
        );
        emit SetLandBalanceToken(landBalance, _newLandBalance);
        landBalance = IMiniMeToken(_newLandBalance);
    }

    function registerBalance() external {
        require(
            !registeredBalance[msg.sender],
            "Register Balance::The user is already registered"
        );

        uint256 currentBalance = landBalance.balanceOf(msg.sender);
        if (currentBalance > 0) {
            require(
                landBalance.destroyTokens(msg.sender, currentBalance),
                "Register Balance::Could not destroy tokens"
            );
        }

        registeredBalance[msg.sender] = true;

        uint256 newBalance = _balanceOf(msg.sender);

        require(
            landBalance.generateTokens(msg.sender, newBalance),
            "Register Balance::Could not generate tokens"
        );
    }

    function unregisterBalance() external {
        require(
            registeredBalance[msg.sender],
            "Unregister Balance::The user not registered"
        );

        registeredBalance[msg.sender] = false;

        uint256 currentBalance = landBalance.balanceOf(msg.sender);

        require(
            landBalance.destroyTokens(msg.sender, currentBalance),
            "Unregister Balance::Could not destroy tokens"
        );
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    ) internal {
        updateOperator[assetId] = address(0);
        _updateLandBalance(from, to);
        super._doTransferFrom(from, to, assetId, userData, doCheck);
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function _updateLandBalance(address _from, address _to) internal {
        if (registeredBalance[_from]) {
            landBalance.destroyTokens(_from, 1);
        }

        if (registeredBalance[_to]) {
            landBalance.generateTokens(_to, 1);
        }
    }
}

pragma solidity ^0.4.24;

import "./upgradable/ProxyStorage.sol";
import "./upgradable/OwnableStorage.sol";

import "./erc821/contracts/AssetRegistryStorage.sol";

import "./land/LANDStorage.sol";

contract Storage is
    ProxyStorage,
    OwnableStorage,
    AssetRegistryStorage,
    LANDStorage
{}

pragma solidity ^0.4.24;

import "../Storage.sol";

contract Ownable is Storage {
    event OwnerUpdate(address _prevOwner, address _newOwner);

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner, "Cannot transfer to yourself");
        owner = _newOwner;
    }
}

pragma solidity ^0.4.24;

import "./ERC721Base.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

contract FullAssetRegistry is ERC721Base, ERC721Enumerable, ERC721Metadata {
    constructor() public {}

    function exists(uint256 assetId) external view returns (bool) {
        return _exists(assetId);
    }

    function _exists(uint256 assetId) internal view returns (bool) {
        return _holderOf[assetId] != 0;
    }

    function decimals() external pure returns (uint256) {
        return 0;
    }
}

pragma solidity ^0.4.24;

interface ILANDRegistry {
    function assignNewParcel(
        int256 x,
        int256 y,
        address beneficiary
    ) external;

    function assignMultipleParcels(
        int256[] x,
        int256[] y,
        address beneficiary
    ) external;

    function ping() external;

    function encodeTokenId(int256 x, int256 y) external pure returns (uint256);

    function decodeTokenId(uint256 value)
        external
        pure
        returns (int256, int256);

    function exists(int256 x, int256 y) external view returns (bool);

    function ownerOfLand(int256 x, int256 y) external view returns (address);

    function ownerOfLandMany(int256[] x, int256[] y)
        external
        view
        returns (address[]);

    function landOf(address owner) external view returns (int256[], int256[]);

    function landData(int256 x, int256 y) external view returns (string);

    function transferLand(
        int256 x,
        int256 y,
        address to
    ) external;

    function transferManyLand(
        int256[] x,
        int256[] y,
        address to
    ) external;

    function updateLandData(
        int256 x,
        int256 y,
        string data
    ) external;

    function updateManyLandData(
        int256[] x,
        int256[] y,
        string data
    ) external;

    function setUpdateManager(
        address _owner,
        address _operator,
        bool _approved
    ) external;

    event Update(
        uint256 indexed assetId,
        address indexed holder,
        address indexed operator,
        string data
    );

    event UpdateOperator(uint256 indexed assetId, address indexed operator);

    event UpdateManager(
        address indexed _owner,
        address indexed _operator,
        address indexed _caller,
        bool _approved
    );

    event DeployAuthorized(address indexed _caller, address indexed _deployer);

    event DeployForbidden(address indexed _caller, address indexed _deployer);

    event SetLandBalanceToken(
        address indexed _previousLandBalance,
        address indexed _newLandBalance
    );
}

pragma solidity ^0.4.24;

import "../erc821/contracts/ERC165.sol";

contract IMetadataHolder is ERC165 {
    function getMetadata(
        uint256 /* assetId */
    ) external view returns (string);
}

pragma solidity ^0.4.24;

contract ProxyStorage {
    address public currentContract;
    address public proxyOwner;
}

pragma solidity ^0.4.24;

contract OwnableStorage {
    address public owner;

    constructor() internal {
        owner = msg.sender;
    }
}

pragma solidity ^0.4.24;

contract AssetRegistryStorage {
    string internal _name;
    string internal _symbol;
    string internal _description;

    uint256 internal _count;

    mapping(address => uint256[]) internal _assetsOf;

    mapping(uint256 => address) internal _holderOf;

    mapping(uint256 => uint256) internal _indexOfAsset;

    mapping(uint256 => string) internal _assetData;

    mapping(address => mapping(address => bool)) internal _operators;

    mapping(uint256 => address) internal _approval;
}

pragma solidity ^0.4.24;

import "../estate/IEstateRegistry.sol";
import "../minimeToken/IMinimeToken.sol";

contract LANDStorage {
    mapping(address => uint256) public latestPing;

    uint256 constant clearLow =
        0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant clearHigh =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant factor = 0x100000000000000000000000000000000;

    mapping(address => bool) internal _deprecated_authorizedDeploy;

    mapping(uint256 => address) public updateOperator;

    IEstateRegistry public estateRegistry;

    mapping(address => bool) public authorizedDeploy;

    mapping(address => mapping(address => bool)) public updateManager;

    IMiniMeToken public landBalance;

    mapping(address => bool) public registeredBalance;
}

pragma solidity ^0.4.24;

contract IEstateRegistry {
    function mint(address to, string metadata) external returns (uint256);

    function ownerOf(uint256 _tokenId) public view returns (address _owner); // from ERC721

    event CreateEstate(
        address indexed _owner,
        uint256 indexed _estateId,
        string _data
    );

    event AddLand(uint256 indexed _estateId, uint256 indexed _landId);

    event RemoveLand(
        uint256 indexed _estateId,
        uint256 indexed _landId,
        address indexed _destinatary
    );

    event Update(
        uint256 indexed _assetId,
        address indexed _holder,
        address indexed _operator,
        string _data
    );

    event UpdateOperator(uint256 indexed _estateId, address indexed _operator);

    event UpdateManager(
        address indexed _owner,
        address indexed _operator,
        address indexed _caller,
        bool _approved
    );

    event SetLANDRegistry(address indexed _registry);

    event SetEstateLandBalanceToken(
        address indexed _previousEstateLandBalance,
        address indexed _newEstateLandBalance
    );
}

pragma solidity ^0.4.24;

interface IMiniMeToken {
    function generateTokens(address _owner, uint256 _amount)
        external
        returns (bool);

    function destroyTokens(address _owner, uint256 _amount)
        external
        returns (bool);

    function balanceOf(address _owner) external view returns (uint256 balance);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}

pragma solidity ^0.4.24;

import "./AssetRegistryStorage.sol";
import "./IERC721Base.sol";
import "./ERC165.sol";
import "../../openzeppelin-solidity/contracts/math/SafeMath.sol";
import "./IERC721Receiver.sol";

contract ERC721Base is AssetRegistryStorage, IERC721Base, ERC165 {
    using SafeMath for uint256;

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant InterfaceId_ERC165 = 0x01ffc9a7;

    bytes4 private constant Old_InterfaceId_ERC721 = 0x7c0633c6;
    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;

    function totalSupply() external view returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

    function ownerOf(uint256 assetId) external view returns (address) {
        return _ownerOf(assetId);
    }

    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

    function balanceOf(address owner) external view returns (uint256) {
        return _balanceOf(owner);
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

    function isApprovedForAll(address assetHolder, address operator)
        external
        view
        returns (bool)
    {
        return _isApprovedForAll(assetHolder, operator);
    }

    function _isApprovedForAll(address assetHolder, address operator)
        internal
        view
        returns (bool)
    {
        return _operators[assetHolder][operator];
    }

    function getApproved(uint256 assetId) external view returns (address) {
        return _getApprovedAddress(assetId);
    }

    function getApprovedAddress(uint256 assetId)
        external
        view
        returns (address)
    {
        return _getApprovedAddress(assetId);
    }

    function _getApprovedAddress(uint256 assetId)
        internal
        view
        returns (address)
    {
        return _approval[assetId];
    }

    function isAuthorized(address operator, uint256 assetId)
        external
        view
        returns (bool)
    {
        return _isAuthorized(operator, assetId);
    }

    function _isAuthorized(address operator, uint256 assetId)
        internal
        view
        returns (bool)
    {
        require(operator != 0);
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return
            _isApprovedForAll(owner, operator) ||
            _getApprovedAddress(assetId) == operator;
    }

    function setApprovalForAll(address operator, bool authorized) external {
        return _setApprovalForAll(operator, authorized);
    }

    function _setApprovalForAll(address operator, bool authorized) internal {
        if (authorized) {
            require(!_isApprovedForAll(msg.sender, operator));
            _addAuthorization(operator, msg.sender);
        } else {
            require(_isApprovedForAll(msg.sender, operator));
            _clearAuthorization(operator, msg.sender);
        }
        emit ApprovalForAll(msg.sender, operator, authorized);
    }

    function approve(address operator, uint256 assetId) external {
        address holder = _ownerOf(assetId);
        require(msg.sender == holder || _isApprovedForAll(holder, msg.sender));
        require(operator != holder);

        if (_getApprovedAddress(assetId) != operator) {
            _approval[assetId] = operator;
            emit Approval(holder, operator, assetId);
        }
    }

    function _addAuthorization(address operator, address holder) private {
        _operators[holder][operator] = true;
    }

    function _clearAuthorization(address operator, address holder) private {
        _operators[holder][operator] = false;
    }

    function _addAssetTo(address to, uint256 assetId) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = 0;

        _assetsOf[from][assetIndex] = lastAssetId;

        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].length--;

        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

        _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != 0) {
            _approval[assetId] = 0;
            emit Approval(holder, 0, assetId);
        }
    }

    function _generate(uint256 assetId, address beneficiary) internal {
        require(_holderOf[assetId] == 0);

        _addAssetTo(beneficiary, assetId);

        emit Transfer(0, beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != 0);

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, 0, assetId);
    }

    modifier onlyHolder(uint256 assetId) {
        require(_ownerOf(assetId) == msg.sender);
        _;
    }

    modifier onlyAuthorized(uint256 assetId) {
        require(_isAuthorized(msg.sender, assetId));
        _;
    }

    modifier isCurrentOwner(address from, uint256 assetId) {
        require(_ownerOf(assetId) == from);
        _;
    }

    modifier isDestinataryDefined(address destinatary) {
        require(destinatary != 0);
        _;
    }

    modifier destinataryIsNotHolder(uint256 assetId, address to) {
        require(_ownerOf(assetId) != to);
        _;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId
    ) external {
        return _doTransferFrom(from, to, assetId, "", true);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData
    ) external {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external {
        return _doTransferFrom(from, to, assetId, "", false);
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    ) internal onlyAuthorized(assetId) {
        _moveToken(from, to, assetId, userData, doCheck);
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes userData,
        bool doCheck
    )
        private
        isDestinataryDefined(to)
        destinataryIsNotHolder(assetId, to)
        isCurrentOwner(from, assetId)
    {
        address holder = _holderOf[assetId];
        _clearApproval(holder, assetId);
        _removeAssetFrom(holder, assetId);
        _addAssetTo(to, assetId);
        emit Transfer(holder, to, assetId);

        if (doCheck && _isContract(to)) {
            require(
                IERC721Receiver(to).onERC721Received(
                    msg.sender,
                    holder,
                    assetId,
                    userData
                ) == ERC721_RECEIVED
            );
        }
    }

    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
        if (_interfaceID == 0xffffffff) {
            return false;
        }
        return
            _interfaceID == InterfaceId_ERC165 ||
            _interfaceID == Old_InterfaceId_ERC721 ||
            _interfaceID == InterfaceId_ERC721;
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

pragma solidity ^0.4.24;

import "./AssetRegistryStorage.sol";
import "./IERC721Enumerable.sol";

contract ERC721Enumerable is AssetRegistryStorage, IERC721Enumerable {
    function tokensOf(address owner) external view returns (uint256[]) {
        return _assetsOf[owner];
    }

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 assetId)
    {
        require(index < _assetsOf[owner].length);
        require(index < (1 << 127));
        return _assetsOf[owner][index];
    }
}

pragma solidity ^0.4.24;

import "./AssetRegistryStorage.sol";
import "./IERC721Metadata.sol";

contract ERC721Metadata is AssetRegistryStorage, IERC721Metadata {
    function name() external view returns (string) {
        return _name;
    }

    function symbol() external view returns (string) {
        return _symbol;
    }

    function description() external view returns (string) {
        return _description;
    }

    function tokenMetadata(uint256 assetId) external view returns (string) {
        return _assetData[assetId];
    }

    function _update(uint256 assetId, string data) internal {
        _assetData[assetId] = data;
    }
}

pragma solidity ^0.4.24;

interface IERC721Base {
    function totalSupply() external view returns (uint256);

    function ownerOf(uint256 assetId) external view returns (address);

    function balanceOf(address holder) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes userData
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external;

    function approve(address operator, uint256 assetId) external;

    function setApprovalForAll(address operator, bool authorized) external;

    function getApprovedAddress(uint256 assetId)
        external
        view
        returns (address);

    function isApprovedForAll(address assetHolder, address operator)
        external
        view
        returns (bool);

    function isAuthorized(address operator, uint256 assetId)
        external
        view
        returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed assetId,
        address operator,
        bytes userData,
        bytes operatorData
    );

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed assetId,
        address operator,
        bytes userData
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed assetId
    );
    event ApprovalForAll(
        address indexed holder,
        address indexed operator,
        bool authorized
    );
    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed assetId
    );
}

pragma solidity ^0.4.24;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

pragma solidity ^0.4.24;

library SafeMath {
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        if (_a == 0) {
            return 0;
        }

        c = _a * _b;
        assert(c / _a == _b);
        return c;
    }

    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        return _a / _b;
    }

    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        assert(_b <= _a);
        return _a - _b;
    }

    function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
        c = _a + _b;
        assert(c >= _a);
        return c;
    }
}

pragma solidity ^0.4.24;

interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _userData
    ) external returns (bytes4);
}

pragma solidity ^0.4.24;

contract IERC721Enumerable {
    function tokensOf(address owner) external view returns (uint256[]);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);
}

pragma solidity ^0.4.24;

contract IERC721Metadata {
    function name() external view returns (string);

    function symbol() external view returns (string);

    function description() external view returns (string);

    function tokenMetadata(uint256 assetId) external view returns (string);
}