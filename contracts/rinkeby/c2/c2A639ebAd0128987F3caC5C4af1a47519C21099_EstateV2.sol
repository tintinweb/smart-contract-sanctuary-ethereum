// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./IEstateRegistry.sol";
import "./ERC721Token.sol";
import "./EstateStorage.sol";
import "./LANDRegistry.sol";
import "./SafeMath.sol";

contract EstateV2 is
    IEstateRegistry,
    OwnableUpgradeable,
    ERC721Token,
    ERC721Receiver,
    EstateStorage
{
    using SafeMath for uint256;

    function initialize(address _registry) public initializer {
        _name = "OneRare ESTATE";
        _symbol = "OEST";
        OwnableUpgradeable.__Ownable_init();
        registry = LANDRegistry(_registry);
    }

    modifier canTransfer(uint256 estateId) override {
        require(
            isApprovedOrOwner(msg.sender, estateId),
            "Only owner or operator can transfer"
        );
        _;
    }

    modifier onlyRegistry() {
        require(
            msg.sender == address(registry),
            "Only the registry can make this operation"
        );
        _;
    }

    modifier onlyUpdateAuthorized(uint256 estateId) {
        require(_isUpdateAuthorized(msg.sender, estateId), "Unauthorized user");
        _;
    }

    modifier onlyLandUpdateAuthorized(uint256 estateId, uint256 landId) {
        require(
            _isLandUpdateAuthorized(msg.sender, estateId, landId),
            "unauthorized user"
        );
        _;
    }

    modifier canSetUpdateOperator(uint256 estateId) {
        address owner = ownerOf(estateId);
        require(
            isApprovedOrOwner(msg.sender, estateId) ||
                updateManager[owner][msg.sender],
            "unauthorized user"
        );
        _;
    }

    /**
     * @dev Mint a new Estate with some metadata
     * @param to The address that will own the minted token
     * @param metadata Set an initial metadata
     * @return An uint256 representing the new token id
     */
    function mint(address to, string memory metadata)
        external
        override
        onlyRegistry
        returns (uint256)
    {
        return _mintEstate(to, metadata);
    }

    /**
     * @notice Transfer a LAND owned by an Estate to a new owner
     * @param estateId Current owner of the token
     * @param landId LAND to be transfered
     * @param destinatary New owner
     */
    function transferLand(
        uint256 estateId,
        uint256 landId,
        address destinatary
    ) external canTransfer(estateId) {
        return _transferLand(estateId, landId, destinatary);
    }

    /**
     * @notice Transfer many tokens owned by an Estate to a new owner
     * @param estateId Current owner of the token
     * @param landIds LANDs to be transfered
     * @param destinatary New owner
     */
    function transferManyLands(
        uint256 estateId,
        uint256[] memory landIds,
        address destinatary
    ) external canTransfer(estateId) {
        uint256 length = landIds.length;
        for (uint256 i = 0; i < length; i++) {
            _transferLand(estateId, landIds[i], destinatary);
        }
    }

    /**
     * @notice Dissolves an estate nad transfers all it's LANDs to an address
     * @param estateId Current owner of the token
     * @param destinatary New owner
     */
    function dissolveEstate(uint256 estateId, address destinatary)
        external
        canTransfer(estateId)
    {
        require(exists(estateId), "Estate does not exist.");
        uint256[] memory landIds = estateLandIds[estateId];
        uint256 length = landIds.length;
        for (uint256 i = 0; i < length; i++) {
            _transferLand(estateId, landIds[i], destinatary);
        }
    }

    /**
     * @notice Get the Estate id for a given LAND id
     * @dev This information also lives on estateLandIds,
     *   but it being a mapping you need to know the Estate id beforehand.
     * @param landId LAND to search
     * @return The corresponding Estate id
     */
    function getLandEstateId(uint256 landId) external view returns (uint256) {
        return landIdEstate[landId];
    }

    function setLANDRegistry(address _registry) external onlyOwner {
        require(
            issContract(_registry),
            "The LAND registry address should be a contract"
        );
        require(
            _registry != address(0),
            "The LAND registry address should be valid"
        );
        registry = LANDRegistry(_registry);
        emit SetLANDRegistry(address(registry));
    }

    function issContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly {
            size := extcodesize(addr)
        } // solium-disable-line security/no-inline-assembly
        return size > 0;
    }

    function ping() external {
        registry.ping();
    }

    /**
     * @notice Return the amount of tokens for a given Estate
     * @param estateId Estate id to search
     * @return Tokens length
     */
    function getEstateSize(uint256 estateId) external view returns (uint256) {
        return estateLandIds[estateId].length;
    }

    /**
     * @notice Return the amount of LANDs inside the Estates for a given address
     * @param _owner of the estates
     * @return the amount of LANDs
     */
    function getLANDsSize(address _owner) public view returns (uint256) {
        // Avoid balanceOf to not compute an unnecesary require
        uint256 landsSize;
        uint256 balance = ownedTokensCount[_owner];
        for (uint256 i; i < balance; i++) {
            uint256 estateId = ownedTokens[_owner][i];
            landsSize += estateLandIds[estateId].length;
        }
        return landsSize;
    }

    /**
     * @notice Update the metadata of an Estate
     * @dev Reverts if the Estate does not exist or the user is not authorized
     * @param estateId Estate id to update
     * @param metadata string metadata
     */
    function updateMetadata(uint256 estateId, string memory metadata)
        external
        onlyUpdateAuthorized(estateId)
    {
        _updateMetadata(estateId, metadata);

        emit Update(estateId, ownerOf(estateId), msg.sender, metadata);
    }

    function getMetadata(uint256 estateId)
        external
        view
        returns (string memory)
    {
        return estateData[estateId];
    }

    function isUpdateAuthorized(address operator, uint256 estateId)
        external
        view
        returns (bool)
    {
        return _isUpdateAuthorized(operator, estateId);
    }

    /**
     * @dev Set an updateManager for an account
     * @param _owner - address of the account to set the updateManager
     * @param _operator - address of the account to be set as the updateManager
     * @param _approved - bool whether the address will be approved or not
     */
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
            _owner == msg.sender || operatorApprovals[_owner][msg.sender],
            "Unauthorized user"
        );

        updateManager[_owner][_operator] = _approved;

        emit UpdateManager(_owner, _operator, msg.sender, _approved);
    }

    /**
     * @notice Set Estate updateOperator
     * @param estateId - Estate id
     * @param operator - address of the account to be set as the updateOperator
     */
    function setUpdateOperator(uint256 estateId, address operator)
        public
        canSetUpdateOperator(estateId)
    {
        updateOperator[estateId] = operator;
        emit UpdateOperator(estateId, operator);
    }

    /**
     * @notice Set Estates updateOperator
     * @param _estateIds - Estate ids
     * @param _operator - address of the account to be set as the updateOperator
     */
    function setManyUpdateOperator(
        uint256[] memory _estateIds,
        address _operator
    ) public {
        for (uint256 i = 0; i < _estateIds.length; i++) {
            setUpdateOperator(_estateIds[i], _operator);
        }
    }

    /**
     * @notice Set LAND updateOperator
     * @param estateId - Estate id
     * @param landId - LAND to set the updateOperator
     * @param operator - address of the account to be set as the updateOperator
     */
    function setLandUpdateOperator(
        uint256 estateId,
        uint256 landId,
        address operator
    ) public canSetUpdateOperator(estateId) {
        require(
            landIdEstate[landId] == estateId,
            "The LAND is not part of the Estate"
        );
        registry.setUpdateOperator(landId, operator);
    }

    /**
     * @notice Set many LAND updateOperator
     * @param _estateId - Estate id
     * @param _landIds - LANDs to set the updateOperator
     * @param _operator - address of the account to be set as the updateOperator
     */
    function setManyLandUpdateOperator(
        uint256 _estateId,
        uint256[] memory _landIds,
        address _operator
    ) public canSetUpdateOperator(_estateId) {
        for (uint256 i = 0; i < _landIds.length; i++) {
            require(
                landIdEstate[_landIds[i]] == _estateId,
                "The LAND is not part of the Estate"
            );
        }
        registry.setManyUpdateOperator(_landIds, _operator);
    }

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safetransfer`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transferred
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public override onlyRegistry returns (bytes4) {
        uint256 estateId = _bytesToUint(_data);
        _pushLandId(estateId, _tokenId);
        return ERC721_RECEIVED;
    }

    /**
     * @dev Creates a checksum of the contents of the Estate
     * @param estateId the estateId to be verified
     */
    function getFingerprint(uint256 estateId)
        public
        view
        returns (bytes32 result)
    {
        result = keccak256(abi.encodePacked("estateId", estateId));

        uint256 length = estateLandIds[estateId].length;
        for (uint256 i = 0; i < length; i++) {
            result ^= keccak256(abi.encodePacked(estateLandIds[estateId][i]));
        }
        return result;
    }

    /**
     * @dev Verifies a checksum of the contents of the Estate
     * @param estateId the estateid to be verified
     * @param fingerprint the user provided identification of the Estate contents
     */
    function verifyFingerprint(uint256 estateId, bytes memory fingerprint)
        public
        view
        returns (bool)
    {
        return getFingerprint(estateId) == _bytesToBytes32(fingerprint);
    }

    /**
     * @dev Safely transfers the ownership of multiple Estate IDs to another address
     * @dev Delegates to safeTransferFrom for each transfer
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param estateIds uint256 array of IDs to be transferred
     */
    function safeTransferManyFrom(
        address from,
        address to,
        uint256[] memory estateIds
    ) public {
        safeTransferManyFrom(from, to, estateIds, "");
    }

    /**
     * @dev Safely transfers the ownership of multiple Estate IDs to another address
     * @dev Delegates to safeTransferFrom for each transfer
     * @dev Requires the msg sender to be the owner, approved, or operator
     * @param from current owner of the token
     * @param to address to receive the ownership of the given token ID
     * @param estateIds uint256 array of IDs to be transferred
     * @param data bytes data to send along with a safe transfer check
     */
    function safeTransferManyFrom(
        address from,
        address to,
        uint256[] memory estateIds,
        bytes memory data
    ) public {
        for (uint256 i = 0; i < estateIds.length; i++) {
            safeTransferFrom(from, to, estateIds[i], data);
        }
    }

    /**
     * @dev update LAND data owned by an Estate
     * @param estateId Estate
     * @param landId LAND to be updated
     * @param data string metadata
     */
    function updateLandData(
        uint256 estateId,
        uint256 landId,
        string memory data
    ) public {
        _updateLandData(estateId, landId, data);
    }

    /**
     * @dev update LANDs data owned by an Estate
     * @param estateId Estate id
     * @param landIds LANDs to be updated
     * @param data string metadata
     */
    function updateManyLandData(
        uint256 estateId,
        uint256[] memory landIds,
        string memory data
    ) public {
        uint256 length = landIds.length;
        for (uint256 i = 0; i < length; i++) {
            _updateLandData(estateId, landIds[i], data);
        }
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override {
        updateOperator[_tokenId] = address(0);
        // _updateEstateLandBalance(_from, _to, estateLandIds[_tokenId].length);
        super.transferFrom(_from, _to, _tokenId);
    }

    // // check the supported interfaces via ERC165
    // function _supportsInterface(bytes4 _interfaceId)
    //     internal
    //     view
    //     returns (bool)
    // {
    //     // solium-disable-next-line operator-whitespace
    //     return
    //         super._supportsInterface(_interfaceId) ||
    //         _interfaceId == InterfaceId_GetMetadata ||
    //         _interfaceId == InterfaceId_VerifyFingerprint;
    // }

    /**
     * @dev Internal function to mint a new Estate with some metadata
     * @param to The address that will own the minted token
     * @param metadata Set an initial metadata
     * @return An uint256 representing the new token id
     */
    function _mintEstate(address to, string memory metadata)
        internal
        returns (uint256)
    {
        require(to != address(0), "You can not mint to an empty address");
        uint256 estateId = _getNewEstateId();
        _mint(to, estateId);
        _updateMetadata(estateId, metadata);
        emit CreateEstate(to, estateId, metadata);
        return estateId;
    }

    /**
     * @dev Internal function to update an Estate metadata
     * @dev Does not require the Estate to exist, for a public interface use `updateMetadata`
     * @param estateId Estate id to update
     * @param metadata string metadata
     */
    function _updateMetadata(uint256 estateId, string memory metadata)
        internal
    {
        estateData[estateId] = metadata;
    }

    /**
     * @notice Return a new unique id
     * @dev It uses totalSupply to determine the next id
     * @return uint256 Representing the new Estate id
     */
    function _getNewEstateId() internal view returns (uint256) {
        return totalSupply().add(1);
    }

    /**
     * @dev Appends a new LAND id to an Estate updating all related storage
     * @param estateId Estate where the LAND should go
     * @param landId Transfered LAND
     */
    function _pushLandId(uint256 estateId, uint256 landId) internal {
        require(exists(estateId), "The Estate id should exist");
        require(
            landIdEstate[landId] == 0,
            "The LAND is already owned by an Estate"
        );
        require(
            registry.ownerOf(landId) == address(this),
            "The EstateRegistry cannot manage the LAND"
        );

        estateLandIds[estateId].push(landId);

        landIdEstate[landId] = estateId;

        estateLandIndex[estateId][landId] = estateLandIds[estateId].length;

        address owner = ownerOf(estateId);
        // _updateEstateLandBalance(address(registry), owner, 1);

        emit AddLand(estateId, landId);
    }

    /**
     * @dev Removes a LAND from an Estate and transfers it to a new owner
     * @param estateId Current owner of the LAND
     * @param landId LAND to be transfered
     * @param destinatary New owner
     */
    function _transferLand(
        uint256 estateId,
        uint256 landId,
        address destinatary
    ) internal {
        require(
            destinatary != address(0),
            "You can not transfer LAND to an empty address"
        );

        uint256[] storage landIds = estateLandIds[estateId];
        mapping(uint256 => uint256) storage landIndex = estateLandIndex[
            estateId
        ];

        /**
         * Using 1-based indexing to be able to make this check
         */
        require(landIndex[landId] != 0, "The LAND is not part of the Estate");

        uint256 lastIndexInArray = landIds.length.sub(1);

        uint256 indexInArray = landIndex[landId].sub(1);

        uint256 tempTokenId = landIds[lastIndexInArray];

        /**
         * Store the last token in the position previously occupied by landId
         */
        landIndex[tempTokenId] = indexInArray.add(1);
        landIds[indexInArray] = tempTokenId;

        /**
         * Delete the landIds[last element]
         */
        estateLandIds[estateId].pop();
        // landIds.length = lastIndexInArray;

        /**
         * Drop this landId from both the landIndex and landId list
         */
        landIndex[landId] = 0;

        /**
         * Drop this landId Estate
         */
        landIdEstate[landId] = 0;

        address owner = ownerOf(estateId);
        // _updateEstateLandBalance(owner, address(registry), 1);

        registry.safeTransferFrom(address(this), destinatary, landId);

        emit RemoveLand(estateId, landId, destinatary);

        if (landIds.length == 0) {
            delete estateData[estateId];
            _burn(owner, estateId);
        }
    }

    function _isUpdateAuthorized(address operator, uint256 estateId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(estateId);

        return
            isApprovedOrOwner(operator, estateId) ||
            updateOperator[estateId] == operator ||
            updateManager[owner][operator];
    }

    function _isLandUpdateAuthorized(
        address operator,
        uint256 estateId,
        uint256 landId
    ) internal returns (bool) {
        return
            _isUpdateAuthorized(operator, estateId) ||
            registry.updateOperator(landId) == operator;
    }

    function _bytesToUint(bytes memory b) internal pure returns (uint256) {
        return uint256(_bytesToBytes32(b));
    }

    function _bytesToBytes32(bytes memory b) internal pure returns (bytes32) {
        bytes32 out;

        for (uint256 i = 0; i < b.length; i++) {
            out |= bytes32(b[i] & 0xFF) >> i.mul(8);
        }

        return out;
    }

    function _updateLandData(
        uint256 estateId,
        uint256 landId,
        string memory data
    ) internal onlyLandUpdateAuthorized(estateId, landId) {
        require(
            landIdEstate[landId] == estateId,
            "The LAND is not part of the Estate"
        );
        int256 x;
        int256 y;
        (x, y) = registry.decodeTokenId(landId);
        registry.updateLandData(x, y, data);
    }

    /**
     * @dev Set a new estate land balance minime token
     * @param _newEstateLandBalance address of the new estate land balance token
     */
    // function _setEstateLandBalanceToken(address _newEstateLandBalance)
    //     internal
    // {
    //     require(
    //         _newEstateLandBalance != address(0),
    //         "New estateLandBalance should not be zero address"
    //     );
    //     emit SetEstateLandBalanceToken(
    //         address(estateLandBalance),
    //         _newEstateLandBalance
    //     );
    //     estateLandBalance = IMiniMeToken(_newEstateLandBalance);
    // }

    /**
     * @dev Register an account balance
     * @notice Register land Balance
     */
    // function registerBalance() external {
    //     require(
    //         !registeredBalance[msg.sender],
    //         "Register Balance::The user is already registered"
    //     );

    //     // Get balance of the sender
    //     uint256 currentBalance = estateLandBalance.balanceOf(msg.sender);
    //     if (currentBalance > 0) {
    //         require(
    //             estateLandBalance.destroyTokens(msg.sender, currentBalance),
    //             "Register Balance::Could not destroy tokens"
    //         );
    //     }

    //     // Set balance as registered
    //     registeredBalance[msg.sender] = true;

    //     // Get LAND balance
    //     uint256 newBalance = getLANDsSize(msg.sender);

    //     // Generate Tokens
    //     require(
    //         estateLandBalance.generateTokens(msg.sender, newBalance),
    //         "Register Balance::Could not generate tokens"
    //     );
    // }

    /**
     * @dev Unregister an account balance
     * @notice Unregister land Balance
     */
    // function unregisterBalance() external {
    //     require(
    //         registeredBalance[msg.sender],
    //         "Unregister Balance::The user not registered"
    //     );

    //     // Set balance as unregistered
    //     registeredBalance[msg.sender] = false;

    //     // Get balance
    //     uint256 currentBalance = estateLandBalance.balanceOf(msg.sender);

    //     // Destroy Tokens
    //     require(
    //         estateLandBalance.destroyTokens(msg.sender, currentBalance),
    //         "Unregister Balance::Could not destroy tokens"
    //     );
    // }

    /**
     * @dev Update account balances
     * @param _from account
     * @param _to account
     * @param _amount to update
     */
    // function _updateEstateLandBalance(
    //     address _from,
    //     address _to,
    //     uint256 _amount
    // ) internal {
    //     if (registeredBalance[_from]) {
    //         estateLandBalance.destroyTokens(_from, _amount);
    //     }

    //     if (registeredBalance[_to]) {
    //         estateLandBalance.generateTokens(_to, _amount);
    //     }
    // }

    /**
     * @dev Set a estate land balance minime token hardcoded because of the
     * contraint of the proxy for using an owner
     * Mainnet: 0x8568f23f343694650370fe5e254b55bfb704a6c7
     */
    // function setEstateLandBalanceToken() external {
    //     require(estateLandBalance == address(0), "estateLandBalance was set");
    //     _setEstateLandBalanceToken(
    //         address(0x8568f23f343694650370fe5e254b55bfb704a6c7)
    //     );
    // }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function mint(address to, string memory metadata)
        external
        virtual
        returns (uint256);

    // function ownerOf(uint256 _tokenId)
    //     public
    //     view
    //     virtual
    //     returns (address _owner); // from ERC721

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

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC165Support.sol";
import "./ERC721BasicToken.sol";
import "./ERC721.sol";
import "./SafeMath.sol";

contract ERC721Token is ERC165Support, ERC721BasicToken, ERC721 {
    bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;

    bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
    using SafeMath for uint256;
    // Token name
    string internal _name;

    // Token symbol
    string internal _symbol;

    // Mapping from owner to list of owned token IDs
    mapping(address => uint256[]) internal ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) internal ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] internal allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) internal allTokensIndex;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal tokenURIs;

    // function _supportsInterface(bytes4 _interfaceId)
    //     internal
    //     view
    //     override
    //     returns (bool)
    // {
    //     return
    //         super._supportsInterface(_interfaceId) ||
    //         _interfaceId == InterfaceId_ERC721Enumerable ||
    //         _interfaceId == InterfaceId_ERC721Metadata;
    // }

    /**
     * @dev Gets the token name
     * @return string representing the token name
     */
    function name() external view override returns (string memory) {
        return _name;
    }

    /**
     * @dev Gets the token symbol
     * @return string representing the token symbol
     */
    function symbol() external view override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns an URI for a given token ID
     * Throws if the token ID does not exist. May return an empty string.
     * @param _tokenId uint256 ID of the token to query
     */
    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(exists(_tokenId));
        return tokenURIs[_tokenId];
    }

    /**
     * @dev Gets the token ID at a given index of the tokens list of the requested owner
     * @param _owner address owning the tokens list to be accessed
     * @param _index uint256 representing the index to be accessed of the requested tokens list
     * @return uint256 token ID at the given index of the tokens list owned by the requested address
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        require(_index < balanceOf(_owner));
        return ownedTokens[_owner][_index];
    }

    /**
     * @dev Gets the total amount of tokens stored by the contract
     * @return uint256 representing the total amount of tokens
     */
    function totalSupply() public view override returns (uint256) {
        return allTokens.length;
    }

    /**
     * @dev Gets the token ID at a given index of all the tokens in this contract
     * Reverts if the index is greater or equal to the total number of tokens
     * @param _index uint256 representing the index to be accessed of the tokens list
     * @return uint256 token ID at the given index of the tokens list
     */
    function tokenByIndex(uint256 _index)
        public
        view
        override
        returns (uint256)
    {
        require(_index < totalSupply());
        return allTokens[_index];
    }

    /**
     * @dev Internal function to set the token URI for a given token
     * Reverts if the token ID does not exist
     * @param _tokenId uint256 ID of the token to set its URI
     * @param _uri string URI to assign
     */
    function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
        require(exists(_tokenId));
        tokenURIs[_tokenId] = _uri;
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal override {
        super.addTokenTo(_to, _tokenId);
        uint256 length = ownedTokens[_to].length;
        ownedTokens[_to].push(_tokenId);
        ownedTokensIndex[_tokenId] = length;
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId)
        internal
        override
    {
        super.removeTokenFrom(_from, _tokenId);

        uint256 tokenIndex = ownedTokensIndex[_tokenId];
        uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
        uint256 lastToken = ownedTokens[_from][lastTokenIndex];

        ownedTokens[_from][tokenIndex] = lastToken;
        ownedTokens[_from][lastTokenIndex] = 0;
        // Note that this will handle single-element arrays. In that case, both tokenIndex and lastTokenIndex are going to
        // be zero. Then we can make sure that we will remove _tokenId from the ownedTokens list since we are first swapping
        // the lastToken to the first position, and then dropping the element placed in the last position of the list

        ownedTokens[_from].pop();
        // ownedTokensIndex[_tokenId] = 0;
        ownedTokensIndex[lastToken] = tokenIndex;
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param _to address the beneficiary that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal override {
        super._mint(_to, _tokenId);

        allTokensIndex[_tokenId] = allTokens.length;
        allTokens.push(_tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param _owner owner of the token to burn
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address _owner, uint256 _tokenId) internal override {
        super._burn(_owner, _tokenId);

        // Clear metadata (if any)
        if (bytes(tokenURIs[_tokenId]).length != 0) {
            delete tokenURIs[_tokenId];
        }

        // Reorg all tokens array
        uint256 tokenIndex = allTokensIndex[_tokenId];
        uint256 lastTokenIndex = allTokens.length.sub(1);
        uint256 lastToken = allTokens[lastTokenIndex];

        allTokens[tokenIndex] = lastToken;
        allTokens[lastTokenIndex] = 0;

        allTokens.pop();
        // allTokensIndex[_tokenId] = 0;
        allTokensIndex[lastToken] = tokenIndex;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./LANDRegistry.sol";
import "./IMiniMeToken.sol";

contract EstateStorage {
    bytes4 internal constant InterfaceId_GetMetadata =
        bytes4(keccak256("getMetadata(uint256)"));
    bytes4 internal constant InterfaceId_VerifyFingerprint =
        bytes4(keccak256("verifyFingerprint(uint256,bytes)"));

    LANDRegistry public registry;

    // From Estate to list of owned LAND ids (LANDs)
    mapping(uint256 => uint256[]) public estateLandIds;

    // From LAND id (LAND) to its owner Estate id
    mapping(uint256 => uint256) public landIdEstate;

    // From Estate id to mapping of LAND id to index on the array above (estateLandIds)
    mapping(uint256 => mapping(uint256 => uint256)) public estateLandIndex;

    // Metadata of the Estate
    mapping(uint256 => string) internal estateData;

    // Operator of the Estate
    mapping(uint256 => address) public updateOperator;

    // From account to mapping of operator to bool whether is allowed to update content or not
    mapping(address => mapping(address => bool)) public updateManager;

    // Land balance minime token
    IMiniMeToken public estateLandBalance;

    // Registered balance accounts
    mapping(address => bool) public registeredBalance;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

abstract contract LANDRegistry {
    function decodeTokenId(uint256 value)
        external
        pure
        virtual
        returns (int256, int256);

    function updateLandData(
        int256 x,
        int256 y,
        string memory data
    ) external virtual;

    function setUpdateOperator(uint256 assetId, address operator)
        external
        virtual;

    function setManyUpdateOperator(uint256[] memory landIds, address operator)
        external
        virtual;

    function ping() public virtual;

    function ownerOf(uint256 tokenId) public virtual returns (address);

    function safeTransferFrom(
        address,
        address,
        uint256
    ) public virtual;

    function updateOperator(uint256 landId) public virtual returns (address);
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

pragma solidity >=0.6.2 <0.8.0;

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

import "./ERC165.sol";

contract ERC165Support is ERC165 {
    bytes4 internal constant InterfaceId_ERC165 = 0x01ffc9a7;

    /**
     * 0x01ffc9a7 ===
     *   bytes4(keccak256('supportsInterface(bytes4)'))
     */

    function supportsInterface(bytes4 _interfaceId)
        external
        view
        override
        returns (bool)
    {
        return _supportsInterface(_interfaceId);
    }

    function _supportsInterface(bytes4 _interfaceId)
        internal
        view
        virtual
        returns (bool)
    {
        return _interfaceId == InterfaceId_ERC165;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC165Support.sol";
import "./ERC721Basic.sol";
import "./SafeMath.sol";
import "./AddressUtils.sol";
import "./ERC721Receiver.sol";

contract ERC721BasicToken is ERC165Support, ERC721Basic {
    bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
    /*
     * 0x80ac58cd ===
     *   bytes4(keccak256('balanceOf(address)')) ^
     *   bytes4(keccak256('ownerOf(uint256)')) ^
     *   bytes4(keccak256('approve(address,uint256)')) ^
     *   bytes4(keccak256('getApproved(uint256)')) ^
     *   bytes4(keccak256('setApprovalForAll(address,bool)')) ^
     *   bytes4(keccak256('isApprovedForAll(address,address)')) ^
     *   bytes4(keccak256('transferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256)')) ^
     *   bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)'))
     */

    bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
    /*
     * 0x4f558e79 ===
     *   bytes4(keccak256('exists(uint256)'))
     */

    using SafeMath for uint256;
    using AddressUtils for address;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant ERC721_RECEIVED = 0x150b7a02;

    // Mapping from token ID to owner
    mapping(uint256 => address) internal tokenOwner;

    // Mapping from token ID to approved address
    mapping(uint256 => address) internal tokenApprovals;

    // Mapping from owner to number of owned token
    mapping(address => uint256) internal ownedTokensCount;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) internal operatorApprovals;

    /**
     * @dev Guarantees msg.sender is owner of the given token
     * @param _tokenId uint256 ID of the token to validate its ownership belongs to msg.sender
     */
    modifier onlyOwnerOf(uint256 _tokenId) {
        require(ownerOf(_tokenId) == msg.sender);
        _;
    }

    /**
     * @dev Checks msg.sender can transfer a token, by being owner, approved, or operator
     * @param _tokenId uint256 ID of the token to validate
     */
    modifier canTransfer(uint256 _tokenId) virtual {
        require(isApprovedOrOwner(msg.sender, _tokenId));
        _;
    }

    // function _supportsInterface(bytes4 _interfaceId)
    //     internal
    //     view
    //     override
    //     returns (bool)
    // {
    //     return
    //         super._supportsInterface(_interfaceId) ||
    //         _interfaceId == InterfaceId_ERC721 ||
    //         _interfaceId == InterfaceId_ERC721Exists;
    // }

    /**
     * @dev Gets the balance of the specified address
     * @param _owner address to query the balance of
     * @return uint256 representing the amount owned by the passed address
     */
    function balanceOf(address _owner) public view override returns (uint256) {
        require(_owner != address(0));
        return ownedTokensCount[_owner];
    }

    /**
     * @dev Gets the owner of the specified token ID
     * @param _tokenId uint256 ID of the token to query the owner of
     * @return owner address currently marked as the owner of the given token ID
     */
    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        address owner = tokenOwner[_tokenId];
        require(owner != address(0));
        return owner;
    }

    /**
     * @dev Returns whether the specified token exists
     * @param _tokenId uint256 ID of the token to query the existence of
     * @return whether the token exists
     */
    function exists(uint256 _tokenId) public view override returns (bool) {
        address owner = tokenOwner[_tokenId];
        return owner != address(0);
    }

    /**
     * @dev Approves another address to transfer the given token ID
     * The zero address indicates there is no approved address.
     * There can only be one approved address per token at a given time.
     * Can only be called by the token owner or an approved operator.
     * @param _to address to be approved for the given token ID
     * @param _tokenId uint256 ID of the token to be approved
     */
    function approve(address _to, uint256 _tokenId) public override {
        address owner = ownerOf(_tokenId);
        require(_to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        tokenApprovals[_tokenId] = _to;
        emit Approval(owner, _to, _tokenId);
    }

    /**
     * @dev Gets the approved address for a token ID, or zero if no address set
     * @param _tokenId uint256 ID of the token to query the approval of
     * @return address currently approved for the given token ID
     */
    function getApproved(uint256 _tokenId)
        public
        view
        override
        returns (address)
    {
        return tokenApprovals[_tokenId];
    }

    /**
     * @dev Sets or unsets the approval of a given operator
     * An operator is allowed to transfer all tokens of the sender on their behalf
     * @param _to operator address to set the approval
     * @param _approved representing the status of the approval to be set
     */
    function setApprovalForAll(address _to, bool _approved) public override {
        require(_to != msg.sender);
        operatorApprovals[msg.sender][_to] = _approved;
        emit ApprovalForAll(msg.sender, _to, _approved);
    }

    /**
     * @dev Tells whether an operator is approved by a given owner
     * @param _owner owner address which you want to query the approval of
     * @param _operator operator address which you want to query the approval of
     * @return bool whether the given operator is approved by the given owner
     */
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        override
        returns (bool)
    {
        return operatorApprovals[_owner][_operator];
    }

    /**
     * @dev Transfers the ownership of a given token ID to another address
     * Usage of this method is discouraged, use `safeTransferFrom` whenever possible
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual override canTransfer(_tokenId) {
        require(_from != address(0));
        require(_to != address(0));

        clearApproval(_from, _tokenId);
        removeTokenFrom(_from, _tokenId);
        addTokenTo(_to, _tokenId);

        emit Transfer(_from, _to, _tokenId);
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     *
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public override canTransfer(_tokenId) {
        // solium-disable-next-line arg-overflow
        safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Safely transfers the ownership of a given token ID to another address
     * If the target address is a contract, it must implement `onERC721Received`,
     * which is called upon a safe transfer, and return the magic value
     * `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`; otherwise,
     * the transfer is reverted.
     * Requires the msg sender to be the owner, approved, or operator
     * @param _from current owner of the token
     * @param _to address to receive the ownership of the given token ID
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes data to send along with a safe transfer check
     */
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public override canTransfer(_tokenId) {
        transferFrom(_from, _to, _tokenId);
        // solium-disable-next-line arg-overflow
        require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
    }

    /**
     * @dev Returns whether the given spender can transfer a given token ID
     * @param _spender address of the spender to query
     * @param _tokenId uint256 ID of the token to be transferred
     * @return bool whether the msg.sender is approved for the given token ID,
     *  is an operator of the owner, or is the owner of the token
     */
    function isApprovedOrOwner(address _spender, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        address owner = ownerOf(_tokenId);
        // Disable solium check because of
        // https://github.com/duaraghav8/Solium/issues/175
        // solium-disable-next-line operator-whitespace
        return (_spender == owner ||
            getApproved(_tokenId) == _spender ||
            isApprovedForAll(owner, _spender));
    }

    /**
     * @dev Internal function to mint a new token
     * Reverts if the given token ID already exists
     * @param _to The address that will own the minted token
     * @param _tokenId uint256 ID of the token to be minted by the msg.sender
     */
    function _mint(address _to, uint256 _tokenId) internal virtual {
        require(_to != address(0));
        addTokenTo(_to, _tokenId);
        emit Transfer(address(0), _to, _tokenId);
    }

    /**
     * @dev Internal function to burn a specific token
     * Reverts if the token does not exist
     * @param _tokenId uint256 ID of the token being burned by the msg.sender
     */
    function _burn(address _owner, uint256 _tokenId) internal virtual {
        clearApproval(_owner, _tokenId);
        removeTokenFrom(_owner, _tokenId);
        emit Transfer(_owner, address(0), _tokenId);
    }

    /**
     * @dev Internal function to clear current approval of a given token ID
     * Reverts if the given address is not indeed the owner of the token
     * @param _owner owner of the token
     * @param _tokenId uint256 ID of the token to be transferred
     */
    function clearApproval(address _owner, uint256 _tokenId) internal {
        require(ownerOf(_tokenId) == _owner);
        if (tokenApprovals[_tokenId] != address(0)) {
            tokenApprovals[_tokenId] = address(0);
        }
    }

    /**
     * @dev Internal function to add a token ID to the list of a given address
     * @param _to address representing the new owner of the given token ID
     * @param _tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function addTokenTo(address _to, uint256 _tokenId) internal virtual {
        require(tokenOwner[_tokenId] == address(0));
        tokenOwner[_tokenId] = _to;
        ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
    }

    /**
     * @dev Internal function to remove a token ID from the list of a given address
     * @param _from address representing the previous owner of the given token ID
     * @param _tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function removeTokenFrom(address _from, uint256 _tokenId) internal virtual {
        require(ownerOf(_tokenId) == _from);
        ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
        tokenOwner[_tokenId] = address(0);
    }

    /**
     * @dev Internal function to invoke `onERC721Received` on a target address
     * The call is not executed if the target address is not a contract
     * @param _from address representing the previous owner of the given token ID
     * @param _to target address that will receive the tokens
     * @param _tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return whether the call correctly returned the expected magic value
     */
    function checkAndCallSafeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (!_to.issContract()) {
            return true;
        }
        bytes4 retval = ERC721Receiver(_to).onERC721Received(
            msg.sender,
            _from,
            _tokenId,
            _data
        );
        return (retval == ERC721_RECEIVED);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC721Basic.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Metadata.sol";

abstract contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface ERC165 {
    /**
     * @notice Query if a contract implements an interface
     * @param _interfaceId The interface identifier, as specified in ERC-165
     * @dev Interface identification is specified in ERC-165. This function
     * uses less than 30,000 gas.
     */
    function supportsInterface(bytes4 _interfaceId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC165.sol";

abstract contract ERC721Basic is ERC165 {
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    function balanceOf(address _owner)
        public
        view
        virtual
        returns (uint256 _balance);

    function ownerOf(uint256 _tokenId)
        public
        view
        virtual
        returns (address _owner);

    function exists(uint256 _tokenId)
        public
        view
        virtual
        returns (bool _exists);

    function approve(address _to, uint256 _tokenId) public virtual;

    function getApproved(uint256 _tokenId)
        public
        view
        virtual
        returns (address _operator);

    function setApprovalForAll(address _operator, bool _approved)
        public
        virtual;

    function isApprovedForAll(address _owner, address _operator)
        public
        view
        virtual
        returns (bool);

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) public virtual;

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

library AddressUtils {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     *  as the code is not actually created until after the constructor finishes.
     * @param addr address to check
     * @return whether the target address is a contract
     */
    function issContract(address addr) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        assembly {
            size := extcodesize(addr)
        } // solium-disable-line security/no-inline-assembly
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

abstract contract ERC721Receiver {
    /**
     * @dev Magic value to be returned upon successful reception of an NFT
     *  Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`,
     *  which can be also obtained as `ERC721Receiver(0).onERC721Received.selector`
     */
    bytes4 internal constant ERC721_RECEIVED = 0x150b7a02;

    /**
     * @notice Handle the receipt of an NFT
     * @dev The ERC721 smart contract calls this function on the recipient
     * after a `safetransfer`. This function MAY throw to revert and reject the
     * transfer. Return of other than the magic value MUST result in the
     * transaction being reverted.
     * Note: the contract address is always the message sender.
     * @param _operator The address which called `safeTransferFrom` function
     * @param _from The address which previously owned the token
     * @param _tokenId The NFT identifier which is being transfered
     * @param _data Additional data with no specified format
     * @return `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
     */
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) public virtual returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC721Basic.sol";

abstract contract ERC721Enumerable is ERC721Basic {
    function totalSupply() public view virtual returns (uint256);

    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        public
        view
        virtual
        returns (uint256 _tokenId);

    function tokenByIndex(uint256 _index) public view virtual returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

import "./ERC721Basic.sol";

abstract contract ERC721Metadata is ERC721Basic {
    function name() external view virtual returns (string memory _name);

    function symbol() external view virtual returns (string memory _symbol);

    function tokenURI(uint256 _tokenId)
        public
        view
        virtual
        returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;

interface IMiniMeToken {
    ////////////////
    // Generate and destroy tokens
    ////////////////

    /// @notice Generates `_amount` tokens that are assigned to `_owner`
    /// @param _owner The address that will be assigned the new tokens
    /// @param _amount The quantity of tokens generated
    /// @return True if the tokens are generated correctly
    function generateTokens(address _owner, uint256 _amount)
        external
        returns (bool);

    /// @notice Burns `_amount` tokens from `_owner`
    /// @param _owner The address that will lose the tokens
    /// @param _amount The quantity of tokens to burn
    /// @return True if the tokens are burned correctly
    function destroyTokens(address _owner, uint256 _amount)
        external
        returns (bool);

    /// @param _owner The address that's balance is being requested
    /// @return balance The balance of `_owner` at the current block
    function balanceOf(address _owner) external view returns (uint256 balance);

    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
}