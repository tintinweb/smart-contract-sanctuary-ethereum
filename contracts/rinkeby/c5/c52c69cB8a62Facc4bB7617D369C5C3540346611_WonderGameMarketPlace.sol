pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./WonderGameMarketAccessControl.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "../interfaces/IOracle.sol";

contract WonderGameMarketPlace is WonderGameMarketAccessControl {

    struct Listing {
        uint256 id;
        uint256 tokenId;
        address nftAddress;
        address payable seller;
        uint256 price;
        uint256 listedTimestamp;
    }

    // increamenting id => listing struct
    mapping(uint256 => Listing) public marketRegistry;

    //address => nft contract inventory address => token id
    mapping(address => mapping(address => uint256[])) public userRegistry;

    // address => token id => listing id
    mapping(address => mapping(uint256 => uint256)) public listedId;

    uint256 public marketRegistrySize;
    uint256 public marketFee;

    //listing id => latest updated block number
    //mapping(uint256 => uint256) public listingLastBlockNumber;
    //uint256 public lastUpdatedBlock;

    // chainlink oracle interface
    IOracle public oracle;

    event UpdatedMarketFee(address updatedBy, uint256 prevMarketFee, uint256 newMarketFee);
    event TokenListed(uint256 indexed listingId, address seller, address indexed nftAddress,uint256 indexed tokenId, uint256 price);
    event TokenBought(uint256 indexed listingId, address indexed buyer, uint256 soldPrice, uint256 soldPriceUSD, uint256 fee);
    event TokenDelisted(uint256 indexed listingId, address delistedBy);
    event AllTokensDelisted(uint256[] listingIds, address seller, address delistedBy);
    event PriceUpdated(uint256 indexed listingId, uint256 oldPrice, uint256 newPrice, address updatedBy);

    constructor(uint256 _marketFee, IOracle _oracle)
        WonderGameMarketAccessControl()
    {
        marketFee = _marketFee;
        oracle = _oracle;
    }

    // market fee should be in 10^18 
    // eg: if 12% market fee then the parameter is 12 * 10^18
    // if 16.5% market fee then the parameter is 16.5 * 10^18
    function setMarketFee(uint256 _marketFee) public onlyRole(OWNER_ROLE){
        emit UpdatedMarketFee(msg.sender, marketFee, _marketFee);
        marketFee = _marketFee;
        //lastUpdatedBlock = block.number;
    }

    function setOracle(IOracle _oracle)public onlyRole(OWNER_ROLE){
        oracle = _oracle;
    }

    function updatePrice(uint256 _listingId, uint256 _newPrice) public whenNotPaused {
        Listing storage _listing = marketRegistry[_listingId];
        require(isListed(_listing.nftAddress, _listing.tokenId), "NFT is not listed");
        require(msg.sender == _listing.seller, "Only seller can update the price");

        emit PriceUpdated(
            _listingId, 
            _listing.price, 
            _newPrice, 
            msg.sender
        );

        _listing.price = _newPrice;
        require(_isListingValid(_listing),"Invalid Listing");

        //listingLastBlockNumber[_listingId] = block.number;
        //lastUpdatedBlock = block.number;
    }

    function _list(
        address payable _seller, 
        address _nftAddress, 
        uint256 _tokenId, 
        uint256 _price
    )
     internal 
     whenNotPaused 
    {
        Listing memory newListing;
        newListing.tokenId = _tokenId;
        newListing.nftAddress = _nftAddress;
        newListing.seller = _seller;
        newListing.price = _price;
        newListing.listedTimestamp = block.number;

        uint256 listingId = ++marketRegistrySize;
        newListing.id = listingId;

        if(isListed(_nftAddress, _tokenId)) {
            uint256 prevListingId = listedId[_nftAddress][_tokenId];
            _delist(marketRegistry[prevListingId]);
        }

        require(_isListingValid(newListing), "Invalid Listing");

        marketRegistry[listingId] = newListing;
        userRegistry[_seller][_nftAddress].push(listingId);
        listedId[_nftAddress][_tokenId] = listingId;
        
        emit TokenListed(listingId, _seller, _nftAddress, _tokenId, _price);

        //listingLastBlockNumber[listingId] = block.number;
        //lastUpdatedBlock = block.number;
    }

    function listToken(
        address _nftAddress, 
        uint256 _tokenId,
        uint256 _price
    ) public {
        _list(payable(msg.sender), _nftAddress, _tokenId, _price);
    }
    
    function buyToken(uint256 _listingId) external payable whenNotPaused {
        require(_listingId > 0, "Listing ID should not be zero");
        Listing storage _listing = marketRegistry[_listingId];
        address nftAddress = _listing.nftAddress;
        address payable seller = _listing.seller;
        uint256 tokenId = _listing.tokenId;
        uint256 listingPrice  = _listing.price;

        require(msg.value >= listingPrice, "Not enough funds to buy");
        require(isListed(nftAddress,tokenId),"Token is not listed");
        require(_isListingValid(_listing),"Invalid listing");
        require(seller != msg.sender, "Buyer is the token owner");

        
        uint256 serviceFee = (listingPrice * marketFee) / (10**20);
        uint256 value = msg.value - serviceFee;
        uint256 refundAmount = msg.value - listingPrice;
        uint256 soldPriceUSD = (listingPrice * getONEUSD())/ 10**18;
        emit TokenBought(
            _listingId, 
            msg.sender, 
            value, 
            soldPriceUSD,
            serviceFee
        );

        _delist(_listing);
        IERC721(nftAddress).safeTransferFrom(seller, msg.sender,tokenId);
        seller.transfer(value);
        if (refundAmount > 0){
            payable(msg.sender).transfer(refundAmount);
        }
        if(serviceFee > 0) {
            payable(defaultOwner).transfer(serviceFee);
        }
    }

    function _delist(Listing storage _listing) internal {
        uint256 listingId = _listing.id;

        delete listedId[_listing.nftAddress][_listing.tokenId];
        uint256[] storage _userRegistry = userRegistry[_listing.seller][_listing.nftAddress];
        uint256 userRegistryLength = _userRegistry.length;
        for(uint256 i=0;i<userRegistryLength;i++) {
            if(_userRegistry[i] == listingId) {
                _userRegistry[i] = _userRegistry[userRegistryLength-1];
                _userRegistry.pop();
                break;
            }
        }
        //listingLastBlockNumber[listingId] = block.number;
        //lastUpdatedBlock = block.number;
        delete marketRegistry[listingId];
    }

    function delistToken(uint256 _listingId) public {
        require(_listingId > 0, "DeListing Invalid");
        Listing storage _listing = marketRegistry[_listingId];
        require(listedId[_listing.nftAddress][_listing.tokenId] == _listingId, "Token is not listed");
        require(msg.sender == _listing.seller, "Delister should be token owner");
        _delist(_listing);
        emit TokenDelisted(
            _listingId, 
            msg.sender
            );
    }

    function _delistAll(address _seller, address _nftAddress) internal {
        uint256[] storage _userRegistry = userRegistry[_seller][_nftAddress];
        uint256 userRegistryLength = _userRegistry.length;
        require(userRegistryLength > 0, "NFTs are not listed");
        Listing memory listing;
        for(uint256 i=0;i<userRegistryLength;i++) {
            listing = marketRegistry[_userRegistry[i]];
            if(listedId[listing.nftAddress][listing.tokenId] == listing.id) {
                delete listedId[listing.nftAddress][listing.tokenId];
            }
            //listingLastBlockNumber[listing.id] = block.number;
            delete marketRegistry[_userRegistry[i]];
        }

        emit AllTokensDelisted(_userRegistry, _seller, msg.sender);
        delete userRegistry[_seller][_nftAddress];
        //lastUpdatedBlock = block.number;
    }

    function delistAllToken(address _nftAddress) public {
        _delistAll(msg.sender, _nftAddress);
    }

    function getONEUSD() public view returns (uint256) {
        (uint256 price,uint8 decimal) = oracle.getONEUSD();
       return (price * 10**18)/(10 ** uint256(decimal));
    }

    function isListed(address _nftAddress, uint256 _tokenId) public view returns (bool) {
        return listedId[_nftAddress][_tokenId] > 0;
    }

    /* @dev check if the account is the owner of this erc721 token
     */
    function _isTokenOwner(
        address erc721Address,
        uint256 tokenId,
        address account
    ) private view returns (bool) {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.ownerOf(tokenId) returns (address tokenOwner) {
            return tokenOwner == account;
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to transfer this erc721 token
     */
    function _isTokenApproved(address erc721Address, uint256 tokenId)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        try _erc721.getApproved(tokenId) returns (address tokenOperator) {
            return tokenOperator == address(this);
        } catch {
            return false;
        }
    }

    /**
     * @dev check if this contract has approved to all of this owner's erc721 tokens
     */
    function _isAllTokenApproved(address erc721Address, address owner)
        private
        view
        returns (bool)
    {
        IERC721 _erc721 = IERC721(erc721Address);
        return _erc721.isApprovedForAll(owner, address(this));
    }

    /**
     * @dev Check if a listing is valid or not
     * The seller must be the owner
     * The seller must have give this contract allowance
     * The sell price must be more than 0
     * The listing mustn't be expired
     */
    function _isListingValid(Listing memory _listing)
        private
        view
        returns (bool isValid)
    {
        address erc721Address = _listing.nftAddress;
        uint256 tokenId = _listing.tokenId;
        if (_isTokenOwner(erc721Address, tokenId, _listing.seller) &&
            (_isTokenApproved(erc721Address, tokenId) ||
                _isAllTokenApproved(erc721Address, _listing.seller)) &&
            _listing.price > 0
        ) {
            isValid = true;
        }
    }

    function isListingValid(uint256 _listingId) public view returns (bool) {
        return _isListingValid(marketRegistry[_listingId]);
    }

    function destroy() public onlyRole(OWNER_ROLE) {
        selfdestruct(payable(defaultOwner));
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

abstract contract WonderGameMarketAccessControl is AccessControl {
    bytes32 internal constant OWNER_ROLE = 0xb19546dff01e856fb3f010c267a7b1c60363cf8a4664e21cc89c26224620214e;

    //ToDo: change this owner address in mainnet
    address internal defaultOwner = 0x698c514c49C3E1C4285fc87674De84cd56A72646;
    
    bool public isPaused;

    modifier whenNotPaused {
        require(!isPaused, "Wonder Game Market Place is paused");
        _;
    }

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultOwner);
        _setupRole(OWNER_ROLE, defaultOwner);
    }

    function pause() public onlyRole(OWNER_ROLE) {
        isPaused = true;
    }

    function unpause() public onlyRole(OWNER_ROLE) {
        isPaused = false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IOracle  {
    function getONEUSD() external view returns (uint256,uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}