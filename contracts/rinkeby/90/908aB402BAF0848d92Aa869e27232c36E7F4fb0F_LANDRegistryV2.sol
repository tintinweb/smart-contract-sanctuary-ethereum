// // SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./estate/IEstateRegistry.sol";
import "./ERC721Base.sol";
import "./ILANDRegistry.sol";
import "./LANDStorage.sol";
import "./metadata/IMetadataHolder.sol";
import "./ERC721Metadata.sol";

contract LANDRegistryV2 is
    OwnableUpgradeable,
    ERC721Base,
    ILANDRegistry,
    LANDStorage,
    ERC721Metadata
{
    function initialize() public initializer {
        _name = "Orare LAND";
        _symbol = "OLAND";
        _description = "Contract that stores the Orare LAND registry";
        OwnableUpgradeable.__Ownable_init();
    }

    modifier onlyOwnerOf(uint256 assetId) {
        require(
            msg.sender == _ownerOf(assetId),
            "This function can only be called by the owner of the asset"
        );
        _;
    }

    modifier onlyDeployer() {
        require(
            msg.sender == owner() || authorizedDeploy[msg.sender],
            "This function can only be called by an authorized deployer"
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

    modifier canSetUpdateOperator(uint256 tokenId) {
        address owner = _ownerOf(tokenId);
        require(
            _isAuthorized(msg.sender, tokenId) ||
                updateManager[owner][msg.sender],
            "unauthorized user"
        );
        _;
    }

    /**
     * @notice Authorize new address to assign parcels
     * @param beneficiary - To be authorized address
     */
    function authorizeDeploy(address beneficiary) external onlyOwner {
        require(beneficiary != address(0), "invalid address");
        require(
            authorizedDeploy[beneficiary] == false,
            "address is already authorized"
        );

        authorizedDeploy[beneficiary] = true;
        emit DeployAuthorized(msg.sender, beneficiary);
    }

    /**
     * @notice Remove authorization from address to assign parcels
     * @param beneficiary - Address to remove authorization from
     */
    function forbidDeploy(address beneficiary) external onlyOwner {
        require(beneficiary != address(0), "invalid address");
        require(authorizedDeploy[beneficiary], "address is already forbidden");

        authorizedDeploy[beneficiary] = false;
        emit DeployForbidden(msg.sender, beneficiary);
    }

    /**
     * @notice Assign new parcel to an address
     * @param x - x coordinate of parcel
     * @param y - y coordinate of parcel
     * @param beneficiary - Address to assign parcel
     */
    function assignNewParcel(
        int256 x,
        int256 y,
        address beneficiary
    ) external override onlyDeployer {
        _generate(_encodeTokenId(x, y), beneficiary, x, y, true);
    }

    /**
     * @notice Assign multiple parcels to an address
     * @param x - x coordinates of parcels
     * @param y - y coordinates of parcels
     * @param beneficiary - Address to assign parcels
     */
    function assignMultipleParcels(
        int256[] memory x,
        int256[] memory y,
        address beneficiary
    ) external override onlyDeployer {
        for (uint256 i = 0; i < x.length; i++) {
            _generate(
                _encodeTokenId(x[i], y[i]),
                beneficiary,
                x[i],
                y[i],
                true
            );
        }
    }

    function encodeTokenId(int256 x, int256 y)
        external
        pure
        override
        returns (uint256)
    {
        return _encodeTokenId(x, y);
    }

    function _encodeTokenId(int256 x, int256 y)
        internal
        pure
        returns (uint256 result)
    {
        require(
            -6 < x && x < 6 && -6 < y && y < 6, //-6 to 6 for testing
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
        override
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
            -6 < x && x < 6 && -6 < y && y < 6,
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

    function ownerOfLand(int256 x, int256 y)
        external
        view
        override
        returns (address)
    {
        return _ownerOfLand(x, y);
    }

    function _ownerOfLand(int256 x, int256 y) internal view returns (address) {
        return _ownerOf(_encodeTokenId(x, y));
    }

    function ownerOfLandMany(int256[] memory x, int256[] memory y)
        external
        view
        override
        returns (address[] memory)
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

    function landOf(address owner)
        external
        view
        override
        returns (int256[] memory, int256[] memory)
    {
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

    function tokenURI(uint256 assetId) external view returns (string memory) {
        return _tokenMetadata(assetId);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function _tokenMetadata(uint256 assetId)
        internal
        view
        returns (string memory)
    {
        require(_ownerOf(assetId) != address(0), "Id does not exist");
        return
            string(
                abi.encodePacked(
                    "https://api.decentraland.org/v2/contracts/0xf87e31492faf9a91b02ee0deaad50d51d56d5d4d/tokens/",
                    toString(assetId)
                )
            ); //using decentraland metadata api for testing.
    }

    function landData(int256 x, int256 y)
        external
        view
        returns (string memory)
    {
        return _tokenMetadata(_encodeTokenId(x, y));
    }

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external override {
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
    ) external override {
        uint256 tokenId = _encodeTokenId(x, y);
        _doTransferFrom(_ownerOf(tokenId), to, tokenId, "", true);
    }

    function transferManyLand(
        int256[] memory x,
        int256[] memory y,
        address to
    ) external override {
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

    function setUpdateOperator(uint256 assetId, address operator)
        public
        canSetUpdateOperator(assetId)
    {
        updateOperator[assetId] = operator;
        emit UpdateOperator(assetId, operator);
    }

    function setManyUpdateOperator(
        uint256[] memory _assetIds,
        address _operator
    ) public {
        for (uint256 i = 0; i < _assetIds.length; i++) {
            setUpdateOperator(_assetIds[i], _operator);
        }
    }

    /**
     * @notice Set update manager for land
     * @param _owner - The owner of land
     * @param _operator - Address to make manager
     * @param _approved - true or false
     */
    function setUpdateManager(
        address _owner,
        address _operator,
        bool _approved
    ) external override {
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

    function setEstateRegistry(address registry) external onlyOwner {
        estateRegistry = IEstateRegistry(registry);
        emit EstateRegistrySet(registry);
    }

    /**
     * @notice Create an estate by combining land parcels
     * @param x - Array of x coordinates of parcels
     * @param y - Array of y coordinates of parcels
     * @param beneficiary - Address to assign estate to
     */
    function createEstate(
        int256[] memory x,
        int256[] memory y,
        address beneficiary
    ) external returns (uint256) {
        // solium-disable-next-line arg-overflow
        return _createEstate(x, y, beneficiary, "", "");
    }

    /**
     * @notice Create an estate with metadata by combining land parcels
     * @param x - Array of x coordinates of parcels
     * @param y - Array of y coordinates of parcels
     * @param beneficiary - Address to assign estate to
     * @param name - Name of the estate
     * @param description - Description of estate
     */
    function createEstateWithMetadata(
        int256[] memory x,
        int256[] memory y,
        address beneficiary,
        string memory name,
        string memory description
    ) external returns (uint256) {
        // solium-disable-next-line arg-overflow
        return _createEstate(x, y, beneficiary, name, description);
    }

    function _createEstate(
        int256[] memory x,
        int256[] memory y,
        address beneficiary,
        string memory name,
        string memory description
    ) internal returns (uint256) {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );
        require(
            address(estateRegistry) != address(0),
            "The Estate registry should be set"
        );

        uint256 estateTokenId = estateRegistry.mint(
            beneficiary,
            name,
            description
        );
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

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function updateLandData(
        int256 x,
        int256 y,
        string memory name,
        string memory description
    ) external override {
        return _updateLandData(x, y, name, description);
    }

    function _updateLandData(
        int256 x,
        int256 y,
        string memory name,
        string memory description
    ) internal onlyUpdateAuthorized(_encodeTokenId(x, y)) {
        uint256 assetId = _encodeTokenId(x, y);
        address owner = _holderOf[assetId];

        changeData(assetId, name, description);

        emit UpdateLand(assetId, owner, msg.sender, name, description);
    }

    function updateManyLandData(
        int256[] memory x,
        int256[] memory y,
        string memory name,
        string memory description
    ) external override {
        require(x.length > 0, "You should supply at least one coordinate");
        require(
            x.length == y.length,
            "The coordinates should have the same length"
        );
        for (uint256 i = 0; i < x.length; i++) {
            _updateLandData(x[i], y[i], name, description);
        }
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes memory userData,
        bool doCheck
    ) internal override {
        updateOperator[assetId] = address(0);
        super._doTransferFrom(from, to, assetId, userData, doCheck);
    }

    function _isContract(address addr) internal view override returns (bool) {
        uint256 size;
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }

    function getAllAssignedParcels()
        public
        view
        returns (int256[] memory, int256[] memory)
    {
        uint256 len = _count1;
        int256[] memory xx = new int256[](len);
        int256[] memory yy = new int256[](len);

        for (uint256 i = 0; i < len; i++) {
            assgParcels storage asp = assignedParcels[i];
            xx[i] = asp.x;
            yy[i] = asp.y;
        }
        return (xx, yy);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.8.0;

abstract contract IEstateRegistry {
    function mint(
        address to,
        string memory name,
        string memory description
    ) external virtual returns (uint256);

    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        returns (address _owner); // from ERC721

    event CreateEstate(
        address indexed _owner,
        uint256 indexed _estateId,
        string name,
        string description
    );

    event DissolveEstate(uint256 _estateId);

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
        string name,
        string description
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./AssetRegistryStorage.sol";
import "./IERC721Base.sol";
import "./ERC165.sol";
import "./SafeMath.sol";
import "./IERC721Receiver.sol";

contract ERC721Base is AssetRegistryStorage, IERC721Base, ERC165 {
    using SafeMath for uint256;

    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    bytes4 private constant InterfaceId_ERC165 = 0x01ffc9a7;

    bytes4 private constant Old_InterfaceId_ERC721 = 0x7c0633c6;
    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;

    function totalSupply() external view override returns (uint256) {
        return _totalSupply();
    }

    function _totalSupply() internal view returns (uint256) {
        return _count;
    }

    function ownerOf(uint256 assetId) external view override returns (address) {
        return _ownerOf(assetId);
    }

    function _ownerOf(uint256 assetId) internal view returns (address) {
        return _holderOf[assetId];
    }

    function balanceOf(address owner) external view override returns (uint256) {
        return _balanceOf(owner);
    }

    function _balanceOf(address owner) internal view returns (uint256) {
        return _assetsOf[owner].length;
    }

    function isApprovedForAll(address assetHolder, address operator)
        external
        view
        override
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
        override
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
        override
        returns (bool)
    {
        return _isAuthorized(operator, assetId);
    }

    function _isAuthorized(address operator, uint256 assetId)
        internal
        view
        returns (bool)
    {
        require(operator != address(0));
        address owner = _ownerOf(assetId);
        if (operator == owner) {
            return true;
        }
        return
            _isApprovedForAll(owner, operator) ||
            _getApprovedAddress(assetId) == operator;
    }

    function setApprovalForAll(address operator, bool authorized)
        external
        override
    {
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

    function approve(address operator, uint256 assetId) external override {
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

    function _addAssetTo(
        address to,
        uint256 assetId,
        int256 x,
        int256 y,
        bool add
    ) internal {
        _holderOf[assetId] = to;

        uint256 length = _balanceOf(to);

        _assetsOf[to].push(assetId);

        _indexOfAsset[assetId] = length;

        _count = _count.add(1);

        //delete
        if (add) {
            assignedParcels[_count1] = assgParcels(x, y);
            _count1 = _count1.add(1);
        }
    }

    function _removeAssetFrom(address from, uint256 assetId) internal {
        uint256 assetIndex = _indexOfAsset[assetId];
        uint256 lastAssetIndex = _balanceOf(from).sub(1);
        uint256 lastAssetId = _assetsOf[from][lastAssetIndex];

        _holderOf[assetId] = address(0);

        _assetsOf[from][assetIndex] = lastAssetId;

        _assetsOf[from][lastAssetIndex] = 0;
        _assetsOf[from].pop();

        if (_assetsOf[from].length == 0) {
            delete _assetsOf[from];
        }

        // _indexOfAsset[assetId] = 0;
        _indexOfAsset[lastAssetId] = assetIndex;

        _count = _count.sub(1);
    }

    function _clearApproval(address holder, uint256 assetId) internal {
        if (_ownerOf(assetId) == holder && _approval[assetId] != address(0)) {
            _approval[assetId] = address(0);
            emit Approval(holder, address(0), assetId);
        }
    }

    function _generate(
        uint256 assetId,
        address beneficiary,
        int256 x,
        int256 y,
        bool add
    ) internal {
        require(_holderOf[assetId] == address(0));

        _addAssetTo(beneficiary, assetId, x, y, add);

        emit Transfer(address(0), beneficiary, assetId);
    }

    function _destroy(uint256 assetId) internal {
        address holder = _holderOf[assetId];
        require(holder != address(0));

        _removeAssetFrom(holder, assetId);

        emit Transfer(holder, address(0), assetId);
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
        require(destinatary != address(0));
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
    ) external override {
        return _doTransferFrom(from, to, assetId, "", true);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes memory userData
    ) external override {
        return _doTransferFrom(from, to, assetId, userData, true);
    }

    function transferFrom(
        address from,
        address to,
        uint256 assetId
    ) external virtual override {
        return _doTransferFrom(from, to, assetId, "", false);
    }

    function _doTransferFrom(
        address from,
        address to,
        uint256 assetId,
        bytes memory userData,
        bool doCheck
    ) internal virtual onlyAuthorized(assetId) {
        _moveToken(from, to, assetId, userData, doCheck);
    }

    function _moveToken(
        address from,
        address to,
        uint256 assetId,
        bytes memory userData,
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
        _addAssetTo(to, assetId, 1, 1, false);
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
        pure
        override
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

    function _isContract(address addr) internal view virtual returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ILANDRegistry {
    function assignNewParcel(
        int256 x,
        int256 y,
        address beneficiary
    ) external;

    function assignMultipleParcels(
        int256[] memory x,
        int256[] memory y,
        address beneficiary
    ) external;

    // function ping() external;

    function encodeTokenId(int256 x, int256 y) external pure returns (uint256);

    function decodeTokenId(uint256 value)
        external
        pure
        returns (int256, int256);

    function ownerOfLand(int256 x, int256 y) external view returns (address);

    function ownerOfLandMany(int256[] memory x, int256[] memory y)
        external
        view
        returns (address[] memory);

    function landOf(address owner)
        external
        view
        returns (int256[] memory, int256[] memory);

    // function landData(int256 x, int256 y) external view returns (string memory);

    function transferLand(
        int256 x,
        int256 y,
        address to
    ) external;

    function transferManyLand(
        int256[] memory x,
        int256[] memory y,
        address to
    ) external;

    function updateLandData(
        int256 x,
        int256 y,
        string memory name,
        string memory description
    ) external;

    function updateManyLandData(
        int256[] memory x,
        int256[] memory y,
        string memory name,
        string memory description
    ) external;

    function setUpdateManager(
        address _owner,
        address _operator,
        bool _approved
    ) external;

    event UpdateLand(
        uint256 indexed assetId,
        address indexed holder,
        address indexed operator,
        string name,
        string description
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./estate/IEstateRegistry.sol";
import "./minime/IMiniMeToken.sol";

contract LANDStorage {
    // mapping(address => uint256) public latestPing;

    uint256 constant clearLow =
        0xffffffffffffffffffffffffffffffff00000000000000000000000000000000;
    uint256 constant clearHigh =
        0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    uint256 constant factor = 0x100000000000000000000000000000000;

    // mapping(address => bool) internal _deprecated_authorizedDeploy;

    mapping(uint256 => address) public updateOperator;

    IEstateRegistry public estateRegistry;

    mapping(address => bool) public authorizedDeploy;

    mapping(address => mapping(address => bool)) public updateManager;

    // IMiniMeToken public landBalance;

    mapping(address => bool) public registeredBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "../ERC165.sol";

abstract contract IMetadataHolder is ERC165 {
    function getMetadata(
        uint256 /* assetId */
    ) external virtual returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./AssetRegistryStorage.sol";
import "./IERC721Metadata.sol";

contract ERC721Metadata is AssetRegistryStorage, IERC721Metadata {
    function name() external view override returns (string memory) {
        return _name;
    }

    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    function description() external view override returns (string memory) {
        return _description;
    }

    function changeData(
        uint256 _tokenId,
        string memory _name,
        string memory _description
    ) public {
        meta[_tokenId].name = _name;
        meta[_tokenId].description = _description;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

contract AssetRegistryStorage {
    string internal _name;
    string internal _symbol;
    string internal _description;

    uint256 internal _count;

    uint256 internal _count1;

    struct assgParcels {
        int256 x;
        int256 y;
    }

    mapping(uint256 => assgParcels) internal assignedParcels;

    struct assetData {
        string name;
        string description;
    }

    mapping(uint256 => assetData) public meta;

    mapping(address => uint256[]) internal _assetsOf;

    mapping(uint256 => address) internal _holderOf;

    mapping(uint256 => uint256) internal _indexOfAsset;

    // mapping(uint256 => string) internal tokenURI;

    mapping(address => mapping(address => bool)) internal _operators;

    mapping(uint256 => address) internal _approval;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

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
        bytes memory userData
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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IERC721Receiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _userData
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

abstract contract IERC721Metadata {
    function name() external virtual returns (string memory);

    function symbol() external virtual returns (string memory);

    function description() external virtual returns (string memory);
}