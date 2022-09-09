// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "./URIManager.sol";
import "./ERC2981GlobalRoyalties.sol";
import "./ERC721Lending.sol";

//                                       .,*.                                   
//                                      *(//*                                   
//                              .      .//&/                                    
//                  .*.       (*/// , *(/,*  ,,,                                
//               ./&#*,(*.,   ,/((%./#(//#.//((#(###/**///#%#%(%(**             
//               //*/%&*#&/*/,.*/,*%##/*,(/*(/*#,,,*(#&(//                      
//                        (*#/(#/(*,        */%(/*/.#,,                         
//                      /#(.&(* //(/,/        ,,./**                            
//                    ./(%//,         .,*(/(((*/%%*.,                           
//                    */,.(/.   ,#%%,.      */.(*/*.                            
//                     *&%(%&%#&%(##%&(#   %*,(#&@/                             
//                      *#(/%*%(/*(%,*#%%(%%/##(%*.                             
//                        *.*/%,/,/*(,//%(#/#%,#*,                              
//                         . %/(%(#*##%#%(*,/(**                                
//                         ,(@##*&**##**/#/(/,                                  
//                          (,%#((/%((//(%/%.                                   
//                          , **,(/**/*/**((,                                   
//                           / (,..  ../*.*#,                                   
//                            ,(*##((%((#(/@,                                   
//                             (.%*( * .*(.&,                                   
//                              (/#%#/%#%(*%,                                   
//                             */,###(%%(*%#/                                   
//                           ,//#%**(//,,(((*.                                  
//                          ((*..**((#%/*(*//*,                                 
//                         ..%#,*((#.  ,.(,(/**                                 
//                          /...**,     .,/((/,                                 
//                          /. %*/(,     /.((%.*                                
//                            *#/,%./     ( #/,                                 
//                             */**       /.//#,                                
//                         (*#**,*#.      (**#&,                                
//                                     *,,/##,       

/**
 * @title Affe mit Waffe NFT smart contract.
 * @notice Implementation of ERC-721 standard for the genesis NFT of the Monkeyverse DAO.
 *   "Affe mit Waffe" is a symbiosis of artificial intelligence and the human mind. The
 *   artwork is a stencil inspired by graffiti culture and lays the foundation for creative
 *   development. The colors were decided by our AI – the Real Vision Bot. It determines
 *   the colors based on emotions obtained via natural language processing from the Real
 *   Vision interviews. Human creativity completes the piece for the finishing touch. Each
 *   Affe wants to connect, contrast, and stand out. Like the different colors and emotions
 *   of the day, the Affen are born to connect people, minds and ideas, countries, racesand
 *   genders through comparison and contrast.Despite their bossy appearance they are a
 *   happy hungry bunch at heart. They may look tough on the outside but are soft on the
 *   inside – and are easy to win over with a few bananas. The raised gun symbolizes our
 *   own strength and talents; it shall motivate us to use them wisely to overcome our
 *   differences for tolerance and resolve our conflicts peacefully.
 */

contract AffeMitWaffe is ERC721, ERC721Enumerable, Pausable, AccessControl,
                   ERC721Burnable, ERC2981GlobalRoyalties, URIManager, ERC721Lending {
    // Create the hashes that identify various roles. Note that the naming below diverges
    // from the naming of the DEFAULT_ADMIN_ROLE, whereby OpenZeppelin chose to put
    // the 'ROLE' part of the variable name at the end. Here, instead, all other roles are  named
    // with 'ROLE' at the beginning of the name, because this makes them much easier to
    // find and identify (they naturally get grouped together) in graphical tools like Remix
    // or Etherscan.
    bytes32 public constant ROLE_PAUSER = keccak256("ROLE_PAUSER");
    bytes32 public constant ROLE_MINTER = keccak256("ROLE_MINTER");
    bytes32 public constant ROLE_ROYALTY_SETTING = keccak256("ROLE_ROYALTY_SETTING");
    bytes32 public constant ROLE_METADATA_UPDATER = keccak256("ROLE_METADATA_UPDATER");
    bytes32 public constant ROLE_METADATA_FREEZER = keccak256("ROLE_METADATA_FREEZER");

    /**
     * @notice The owner variable below is 'honorary' in the sense that it serves no purpose
     *   as far as the smart contract itself is concerned. The only reason for implementing
     *   this variable, is that OpenSea queries owner() (according to an article in their Help
     *   Center) in order to decide who can login to the OpenSea interface and change
     *   collection-wide settings, such as the collection banner, or more importantly, royalty
     *   amount and destination (as of this writing, OpenSea implements their own royalty
     *   settings, rather than EIP-2981.)
     *   Semantically, for our purposes (because this contract uses AccessControl rather than
     *   Ownable) it would be more accurate to call this variable something like
     *   'openSeaCollectionAdmin' (but sadly OpenSea is looking for 'owner' specifically.)
     */
    address public owner;

    uint8 constant MAX_SUPPLY = 250;
    /**
     * @dev The variable below keeps track of the number of Affen that have been minted.
     *   HOWEVER, note that the variable is never decreased. Therefore, if an Affe is burned
     *   this does not allow for a new Affe to be minted. There will ever only be 250 MINTED.
     */
    uint8 public numTokensMinted;
    
    /**
     * @dev From our testing, it seems OpenSea will only honor a new collection-level administrator
     *   (the person who can login to the interface and, for example, change royalty
     *   amount/destination), if an event is emmitted (as coded in the OpenZeppelin Ownable contract)
     *   announcing the ownership transfer. Therefore, in order to ensure the OpenSea collection
     *   admin can be updated if ever needed, the following event has been included in this smart
     *   contract.
     */
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @notice Constructor of the Affe mit Waffe ERC-721 NFT smart contract.
     * @param name is the name of the ERC-721 smart contract and NFT collection.
     * @param symbol is the symbol for the collection.
     * @param initialBaseURI is the base URI string that will concatenated with the tokenId to create
     *   the URI where each token's metadata can be found.
     * @param initialContractURI is the location where metadata about the collection as a whole
     *   can be found. For the most part it is an OpenSea-specific requirement (they will try
     *   to find metadata about the collection at this URI when the collecitons is initially
     *   imported into OpenSea.)
     */
    constructor(string memory name, string memory symbol, string memory initialBaseURI, string memory initialContractURI)
    ERC721(name, symbol)
    URIManager(initialBaseURI, initialContractURI) {
        // To start with we will only grant the DEFAULT_ADMIN_ROLE role to the msg.sender
        // The DEFAULT_ADMIN_ROLE is not granted any rights initially. The only privileges
        // the DEFAULT_ADMIN_ROLE has at contract deployment time are: the ability to grant other
        // roles, and the ability to set the 'honorary' contract owner (see comments above.)
        // For any functionality to be enabled, the DEFAULT_ADMIN_ROLE must explicitly grant those roles to
        // other accounts or to itself.
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        setHonoraryOwner(msg.sender);
    }

    /**
     * @notice The 'honorary' portion of this function's name refers to the fact that the 'owner' variable
     *   serves no purpose in this smart contract itself. 'Ownership' is mostly meaningless in the context
     *   of a smart contract that implements security with RBAC (Role Based Access Control); so 'owndership'
     *   is only implemented here to allow for certain collection-wide admin functionality within the
     *   OpenSea web interface.
     * @param honoraryOwner is the address that one would like to designate as the 'owner' of this contract
     *   (most likely with the sole purpose of being able to login to OpenSea as an administrator of the
     *   collection.)
     */
    function setHonoraryOwner(address honoraryOwner) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(honoraryOwner != address(0), "New owner cannot be the zero address.");
        address priorOwner = owner;
        owner = honoraryOwner;
        emit OwnershipTransferred(priorOwner, honoraryOwner);
    }


    // Capabilities of ROLE_PAUSER

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of (in the case of an emergency) pausing all transfers
     *   of tokens in the contract (which includes minting/burning/transferring.)
     * @dev This function calls the internal _pause() function from
     *   OpenZeppelin's Pausable contract.
     */
    function pause() external onlyRole(ROLE_PAUSER) {
        _pause();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of UNpausing all transfers
     *   of tokens in the contract (which includes minting/burning/transferring.)
     * @dev This function calls the internal _unpause() function from
     *   OpenZeppelin's Pausable contract.
     */
    function unpause() external onlyRole(ROLE_PAUSER) {
        _unpause();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of pausing all token lending. When loans
     *   are paused, new loans cannot be made, but existing loans can be recalled.
     * @dev This function calls the internal _pauseLending() function of the
     *   ERC721Lending contract.
     */
    function pauseLending() external onlyRole(ROLE_PAUSER) {
        _pauseLending();
    }

    /**
     * @notice A function which can be called externally by an acount with the
     *   ROLE_PAUSER, with the purpose of UNpausing all token lending.
     * @dev This function calls the internal _unpauseLending() function of the
     *   ERC721Lending contract.
     */
    function unpauseLending() external onlyRole(ROLE_PAUSER) {
        _unpauseLending();
    }


    // Capabilities of ROLE_MINTER

    // the main minting function
    function safeMint(address to, uint256 tokenId) external onlyRole(ROLE_MINTER) {
        require(numTokensMinted < MAX_SUPPLY, "The maximum number of tokens that can ever be minted has been reached.");
        numTokensMinted += 1;
        _safeMint(to, tokenId);
    }


    // Capabilities of ROLE_ROYALTY_SETTING
    
    function setRoyaltyAmountInBips(uint16 newRoyaltyInBips) external onlyRole(ROLE_ROYALTY_SETTING) {
        _setRoyaltyAmountInBips(newRoyaltyInBips);
    }

    function setRoyaltyDestination(address newRoyaltyDestination) external onlyRole(ROLE_ROYALTY_SETTING) {
        _setRoyaltyDestination(newRoyaltyDestination);
    }


    // Capabilities of ROLE_METADATA_UPDATER

    function setBaseURI(string calldata newURI) external onlyRole(ROLE_METADATA_UPDATER) allowIfNotFrozen {
        _setBaseURI(newURI);
    }

    function setContractURI(string calldata newContractURI) external onlyRole(ROLE_METADATA_UPDATER) allowIfNotFrozen {
        _setContractURI(newContractURI);
    }

    
    // Capabilities of ROLE_METADATA_FREEZER

    function freezeURIsForever() external onlyRole(ROLE_METADATA_FREEZER) allowIfNotFrozen {
        _freezeURIsForever();
    }


    // Information fetching - external/public

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "URI query for nonexistent token");
        return _buildTokenURI(tokenId);
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        public
        view
        override
        returns (address, uint256)
    {
        require(_exists(tokenId), "Royalty requested for non-existing token");
        return _globalRoyaltyInfo(salePrice);
    }

    /**
     * @notice Returns all the token IDs owned by a given address. NOTE that 'owner',
     *   in this context, is the meaning as stipulated in EIP-721, which is the address
     *   returned by the ownerOf function. Therefore this function will enumerate the
     *   borrower as the current owner of a token on loan, rather than the original owner.
     * @param tokenOwner is the address to request ownership information about.
     * @return an array that has all the tokenIds owned by an address.
     */
    function ownedTokensByAddress(address tokenOwner) external view returns (uint256[] memory) {
        uint256 totalTokensOwned = balanceOf(tokenOwner);
        uint256[] memory allTokenIdsOfOwner = new uint256[](totalTokensOwned);
        for (uint256 i = 0; i < totalTokensOwned; i++) {
            allTokenIdsOfOwner[i] = (tokenOfOwnerByIndex(tokenOwner, i));
        }
        return allTokenIdsOfOwner;
    }

    /**
     * @notice Function retrieves the specific token ids on loan by a given address.
     * @param rightfulOwner is the original/rightful owner for whom one wishes to find the
     *   tokenIds on loan.
     * @return an array with the tokenIds currently on loan by the origina/rightful owner.
     */
    function loanedTokensByAddress(address rightfulOwner) external view returns (uint256[] memory) {
        require(rightfulOwner != address(0), "ERC721Lending: Balance query for the zero address");
        uint256 numTokensLoanedByRightfulOwner = loanedBalanceOf(rightfulOwner);
        uint256 numGlobalTotalTokens = totalSupply();
        uint256 nextTokenIdToQuery;

        uint256[] memory theTokenIDsOfRightfulOwner = new uint256[](numTokensLoanedByRightfulOwner);
        // If the address in question hasn't lent any tokens, there is no reason to enter the loop.
        if (numTokensLoanedByRightfulOwner > 0) {
            uint256 numMatchingTokensFound = 0;
            // Continue searching in the loop until either all tokens in the collection have been examined
            // or the number of tokens being searched for (the number owned originally by the rightful
            // owner) have been found.
            for (uint256 i = 0; numMatchingTokensFound < numTokensLoanedByRightfulOwner && i < numGlobalTotalTokens; i++) {
                // TokenIds may not be sequential or even within a specific range, so we get the next tokenId (to 
                // lookup in the mapping) from the global array holding all tokens.
                nextTokenIdToQuery = tokenByIndex(i);
                if (mapFromTokenIdToRightfulOwner[nextTokenIdToQuery] == rightfulOwner) {
                    theTokenIDsOfRightfulOwner[numMatchingTokensFound] = nextTokenIdToQuery;
                    numMatchingTokensFound++;
                }
            }
        }
        return theTokenIDsOfRightfulOwner;
    }


    // Hook overrides

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override(ERC721, ERC721Enumerable, ERC721Lending)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }


    // The following functions are overrides required by Solidity.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, AccessControl, ERC2981GlobalRoyalties)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.13;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @notice Implementation of ERC-721 NFT lending. The code below was written by using, as a
 *   starting point, the code made public by the Meta Angels NFT team (thank you to that team
 *   for making their code available for other projects to use!)
 *   The code has been modified in several ways, most importantly, that in the original
 *   implementation it was included in the main contract, whereas here we have abstracted the
 *   functionality into its own parent contract. Also, some additional events have been added,
 *   and checking whether loans are paused has been moved to a Modifier. In addition a function
 *   has been added to allow a borrower to initiate the return of a loan (rather than only 
 *   allowing for the original lender to 'recall' the loan.)
 *   Note that when lending, the meaning of terms like 'owner' become ambiguous, particularly
 *   because once a token is lent, as far as the ERC721 standard is concerned, the borrower is
 *   technically the owner. (In other words, the function 'ownerOf()' reqired by EIP-721 will
 *   return the address of the borrower while a token is lent. In the comments and variable names
 *   below we have tried to disambiguate by refering wherever possible to the original/rightful
 *   owner as the address that truly owns the NFT (the address that is able to recall the loan
 *   whenever they want.) However it is important to understand that once a token is loaned, to
 *   the outside world it will appear to be 'owned' by the borrower. From that perspective, the
 *   'owner' is the current borrower.
 * @dev if you would like to use this code and add a function that enumerates the tokens
 *   loaned out by a particular address (eg. it could be a function called
 *   loanedTokensByAddress(address rightfulOwner) ), you'll need to modify this contract so it
 *   inherits from ERC721Enumerable (because such a function will need access to the
 *   'totalSupply()' provided by the Enumerable contract. For the sake of simplicity, this
 *   contract does not currently implement a function that generates the enumeration of loaned
 *   tokens. However, note that a child contract can readily implement such a function, if it
 *   inherits from ERC721Enumerable.
 */
abstract contract ERC721Lending is ERC721, ReentrancyGuard {
    using Strings for uint256;

    mapping (address => uint256) public totalLoanedPerAddress;
    /**
    * @notice The mapping below keeps track of the original/rightful owner of each token, in other words,
    *   the address that truly owns the token (and has simply lent it out.) This is the address
    *   that is allowed to retrieve the token (to end the loan.)
    */
    mapping (uint256 => address) public mapFromTokenIdToRightfulOwner;
    uint256 internal counterGlobalLoans = 0;

    /**
     * @notice A variable that servers two purposes. 1) To allow the 'outside world' to easily query
     *   whether lendig is currently paused (or not), and 2) to hold the current state so that
     *   certain parts of the code can make decisons about the actions that are allowed (or not.)
     *   NOTE that when lending is paused, this restricts NEW loans from happening, but it does not
     *   restrict owners from reclaiming their loans, or from borrowers returning their borrowed tokens.
     */
    bool public loansAreCurrentlyPaused = false;

    /**
     * @notice Emitted when a loan is made.
     * @param from is the owner of the token (who is making the loan.)
     * @param to is the recipient of the loan.
     * @param item is the tokenID representing the token being lent.
     */
    event Loan(address indexed from, address indexed to, uint item);
    /**
     * @notice Emitted when a loan is recalled by its rightful/original owner.
     * @param byOriginalOwner is the original and rightful owner of the token.
     * @param fromBorrower is the address the token was lent out to.
     * @param item is the tokenID representing the token that was lent.
     */
    event LoanReclaimed(address indexed byOriginalOwner, address indexed fromBorrower, uint item);
    /**
     * @notice Emitted when a loan is returned by the borrower.
     * @param byBorrower is the address that token has been lent to.
     * @param toOriginalOwner is the original and rightful owner of the token.
     * @param item is the tokenID representing the token that was lent.
     */
    event LoanReturned(address indexed byBorrower, address indexed toOriginalOwner, uint item);
    /**
     * @notice Emitted when the pausing of loans is triggered.
     * @param account is the address that paused lending.
     */
    event LendingPaused(address account);
    /**
     * @notice Emitted when UNpausing of loans is triggered.
     * @param account is the address that UNpaused lending.
     */
    event LendingUnpaused(address account);


    /**
     * @notice Enables an owner to loan one of their tokens to another address. The loan is effectively
     *   a complete transfer of ownership. However, what makes it a 'loan' are a set of checks that do
     *   not allow the new owner to do certain things (such as further transfers of the token), and the
     *   ability of the lender to recall the token back into their ownership.
     * @param tokenId is the integer ID of the token to loan.
     * @param receiver is the address that the token will be loaned to.
     */
    function loan(address receiver, uint256 tokenId) external nonReentrant allowIfLendingNotPaused {
        require(msg.sender == ownerOf(tokenId), "ERC721Lending: Trying to lend a token that is not owned.");
        require(msg.sender != receiver, "ERC721Lending: Lending to self (the current owner's address) is not permitted.");
        require(receiver != address(0), "ERC721Lending: Loans to the zero 0x0 address are not permitted.");
        require(mapFromTokenIdToRightfulOwner[tokenId] == address(0), "ERC721Lending: Trying to lend a token that is already on loan.");

        // Transfer the token
        safeTransferFrom(msg.sender, receiver, tokenId);

        // Add it to the mapping (of loaned tokens, and who their original/rightful owners are.)
        mapFromTokenIdToRightfulOwner[tokenId] = msg.sender;

        // Add to the owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[msg.sender];
        totalLoanedPerAddress[msg.sender] = loansByAddress + 1;
        counterGlobalLoans = counterGlobalLoans + 1;

        emit Loan(msg.sender, receiver, tokenId);
    }

    /**
     * @notice Allow the rightful owner of a token to reclaim it, if it is currently on loan.
     * @dev Notice that (in contrast to the loan() function), this function has to use the _safeTransfer()
     *   function as opposed to safeTransferFrom(). The difference between these functions is that
     *   safeTransferFrom requires taht msg.sender _isApprovedOrOwner, whereas _sefTransfer() does not. In
     *   this case, the current owner as far as teh ERC721 contract is concerned is the borrower, so
     *   safeTransferFrom() cannot be used.
     * @param tokenId is the integer ID of the token that should be retrieved.
     */
    function reclaimLoan(uint256 tokenId) external nonReentrant {
        address rightfulOwner = mapFromTokenIdToRightfulOwner[tokenId];
        require(msg.sender == rightfulOwner, "ERC721Lending: Only the original/rightful owner can recall a loaned token.");

        address borrowerAddress = ownerOf(tokenId);

        // Remove it from the array of loaned out tokens
        delete mapFromTokenIdToRightfulOwner[tokenId];

        // Subtract from the rightful owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[rightfulOwner];
        totalLoanedPerAddress[rightfulOwner] = loansByAddress - 1;

        // Decrease the global counter
        counterGlobalLoans = counterGlobalLoans - 1;
        
        // Transfer the token back. (_safeTransfer() requires four parameters, so it is necessary to
        // pass an empty string as the 'data'.)
        _safeTransfer(borrowerAddress, rightfulOwner, tokenId, "");

        emit LoanReclaimed(rightfulOwner, borrowerAddress, tokenId);
    }

    /**
     * @notice Allow the borrower to return the loaned token.
     * @param tokenId is the integer ID of the token that should be retrieved.
     */
    function returnLoanByBorrower(uint256 tokenId) external nonReentrant {
        address borrowerAddress = ownerOf(tokenId);
        require(msg.sender == borrowerAddress, "ERC721Lending: Only the borrower can return the token.");

        address rightfulOwner = mapFromTokenIdToRightfulOwner[tokenId];

        // Remove it from the array of loaned out tokens
        delete mapFromTokenIdToRightfulOwner[tokenId];

        // Subtract from the rightful owner's loan balance
        uint256 loansByAddress = totalLoanedPerAddress[rightfulOwner];
        totalLoanedPerAddress[rightfulOwner] = loansByAddress - 1;

        // Decrease the global counter
        counterGlobalLoans = counterGlobalLoans - 1;
        
        // Transfer the token back
        safeTransferFrom(borrowerAddress, rightfulOwner, tokenId);

        emit LoanReturned(borrowerAddress, rightfulOwner, tokenId);
    }

    /**
     * @notice Queries the number of tokens that are currently on loan.
     * @return The total number of tokens presently loaned.
     */
    function totalLoaned() public view returns (uint256) {
        return counterGlobalLoans;
    }

    /**
     * @notice Function retrieves the number of tokens that an address currently has on loan.
     * @param rightfulOwner is the original/rightful owner of a token or set of tokens.
     * @return The total number of tokens presently loaned by a specific original owner.
     */
    function loanedBalanceOf(address rightfulOwner) public view returns (uint256) {
        require(rightfulOwner != address(0), "ERC721Lending: Balance query for the zero address");
        return totalLoanedPerAddress[rightfulOwner];
    }

    /**
     * @notice Function to pause lending.
     * @dev The function is internal, so it should be called by child contracts, which allows
     *   them to implement their own restrictions, such as Access Control.
     */
    function _pauseLending() internal allowIfLendingNotPaused {
        loansAreCurrentlyPaused = true;
        emit LendingPaused(msg.sender);
    }

    /**
     * @notice Function to UNpause lending.
     * @dev The function is internal, so it should be called by child contracts, which allows
     *   them to implement their own restrictions, such as Access Control.
     */
    function _unpauseLending() internal {
        require(loansAreCurrentlyPaused, "ERC721Lending: Lending of tokens is already in unpaused state.");
        loansAreCurrentlyPaused = false;
        emit LendingUnpaused(msg.sender);
    }

    /**
     * @notice This hook is arguably the most important part of this contract. It is the piece
     *   of code that ensures a borrower cannot transfer the token.
     * @dev Hook that is called before any token transfer. This includes minting
     *   and burning.
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        virtual
        override(ERC721)
    {
        super._beforeTokenTransfer(from, to, tokenId);
        require(mapFromTokenIdToRightfulOwner[tokenId] == address(0), "ERC721Lending: Cannot transfer token on loan.");
    }

    /**
     * @dev Modifier to make a function callable only if lending is not paused.
     */
    modifier allowIfLendingNotPaused() {
        require(!loansAreCurrentlyPaused, "ERC721Lending: Lending of tokens is currently paused.");
        _;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Contract module which abstracts some aspects of URI management away from the main contract.
 *   This contract:
 *
 *      - Provides an adjustable 'default' URI for the location of the metadata (of tokens
 *        in the collection). Typically this is a folder in IPFS or some sort of web server.
 *
 *      - Enables eventual freezing of all metadata, which is useful if a project wants to start
 *        with centralized metadata and eventually move it to a decentralized location and then 'freeze'
 *        it there for posterity.
 */
abstract contract URIManager {
    using Strings for uint256;

    string private _defaultBaseURI;
    string private _contractURI;
    bool private _URIsAreForeverFrozen;

    /**
     * @dev Initializes the contract in unfrozen state with a particular
     * baseURI (a location containing the matadata for each NFT) and a particular
     * contractURI (a file containing collection-wide data, such as the description,
     * name, image, etc. of the collection.)
     */
    constructor(string memory initialBaseURI, string memory initialContractURI) {
        _setBaseURI(initialBaseURI);
        _setContractURI(initialContractURI);
        _URIsAreForeverFrozen = false;
    }
    
    function _setBaseURI(string memory _uri) internal {
        _defaultBaseURI = _uri;
    }

    function _setContractURI(string memory _newContractURI) internal {
        _contractURI = _newContractURI;
    }

    function _getBaseURI() internal view returns (string memory) {
        return _defaultBaseURI;
    }

    function _buildTokenURI(uint256 tokenId) internal view returns (string memory) {
        // return a concatenation of the baseURI (of the collection), with the tokenID, and the file extension.
        return string(abi.encodePacked(_getBaseURI(), tokenId.toString(), ".json"));
    }

    /**
     * @dev Opensea states that a contract may have a contractURI() function, which
     *  returns metadata for the contract as a whole.
     */
    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    /**
     * @dev Returns true if the metadata URIs have been finalized forever.
     */
    function areURIsForeverFrozen() public view virtual returns (bool) {
        return _URIsAreForeverFrozen;
    }

    /**
     * @dev Modifier to make a function callable only if the URIs have not been frozen forever.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier allowIfNotFrozen() {
        require(!areURIsForeverFrozen(), "URIManager: URIs have been frozen forever");
        _;
    }

    /**
     * @dev Freezes all future changes of the URIs.
     *
     * Requirements:
     *
     * - The URIs must not be frozen already.
     */
    function _freezeURIsForever() internal virtual allowIfNotFrozen {
        _URIsAreForeverFrozen = true;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/**
 * @title Implementation ERC2981 Ethereum NFT Royalty Standard
 * @notice Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *   Implementation based off of OpenZeppelin's ERC2981.sol, with some customization by Real Vision's web3
 *   team. (The customization primarily revolves around simplifying the contract so that royalties are only
 *   set for all tokens in the collection, rather than allowing for specific tokens to have custom royalties.)
 *   Our sincere Affen gratitude to the hard work, and collaborative spirit of both OpenZeppelin and Real Vision.
 *   IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 *   https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are
 *   expected to voluntarily pay royalties together with sales, but note that this standard is not yet
 *   widely supported.
 * @dev The 'Global' word in the name of this contract is there to signify that this contract deliberately does
 *   not implement royalties at the level of each token - it only allows for royalty destination and amount to
 *   be set for ALL tokens in the collection. ALSO NOTE that this contract is IERC2981, and yet, it does not
 *   implement the only function that is required by IERC2981: royaltyInfo(). This task is left to the descendants
 *   of this contract to implement.
 */
abstract contract ERC2981GlobalRoyalties is IERC2981, ERC165 {

    address private _royaltyDestination;
    uint16 private _royaltyInBips;
    uint16 private _bipsBasedFeeDenominator = 10000;
    
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @notice Function to set the royalty amount using Basis Points.
     * @dev See OpenZeppelin's docuentation for explanation of their choice of basis points and denominator.
     * @param _newRoyaltyInBips is the amount (as basis points) that the royalty will be set to. For
     *   example, make this parameter 200, to set a royalty of 2%)
     */
    function _setRoyaltyAmountInBips(uint16 _newRoyaltyInBips) internal {
        require(_newRoyaltyInBips <= _bipsBasedFeeDenominator, "Royalty fee will exceed salePrice");
        _royaltyInBips = _newRoyaltyInBips;
    }

    /**
     * @notice Function to set the royalty destination.
     * @param _newRoyaltyDestination is the address that royalties should be sent to.
     */
    function _setRoyaltyDestination(address _newRoyaltyDestination) internal {
        _royaltyDestination = _newRoyaltyDestination;
    }


    /**
     * @notice 
     * @dev The two functions below (royaltyInfo() and _globalRoyaltyInfo() offer the developer a
     *   choice of ways to implement the compulsory (to meet the requirements of the Interface of EIP2981)
     *   function called royaltyInfo() in descendant contracts.
     *   (Both options require overriding the royaltyInfo() declaration of this contract.)
     *   1 - the first option is to override royaltyInfo() and implement the contents of the
     *       function (in the child contract) from scratch in whatever way the developer sees fit.
     *   2 - the second option is to override, but instead of implementing from scratch, 
     *       inside the override (in the child), simply call the internal function _globalRoyaltyInfo()
     *       which already has a working implementation coded below.
     *   As for the parameters and return value, please refer to the official documentation of
     *   eip-2981 for the best explanation.
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual
        returns (address, uint256);

    /**
     * @notice An internal function that can optionally be used by descendant contracts as a ready-made
     *   way to implement the mandatory royaltyInfo() function. The function calculates where and how
     *   much royalty should be sent based on the current global settings of the collection.
     * @dev A descendant contract, in the implementation of royaltyInfo() can simply call this function
     *   if it suits the intended purposes. HOWEVER please NOTE those contracts
     *   (that inherit from this contract) should make sure that the 'royaltyInfo()' function they
     *   implement includes a 'tokenId' parameter in order to comply with EIP2981.
     *   To understand why (within the function) the denominator is 10,000, please see the definition of
     *   the unambiguous financial term: 'basis points' (bips)
     * @param _salePrice is the price that a token is being sold for. A tokenId is not required for this
     *   function because this implementation of eip-2981 only keeps 'global' settings of royalties
     *   for the collections as whole (rather than keeping settings for individual tokens.)
     * @return two values: 1) the royalty destination, and 2) the royalty amount, as required by eip-2981
     */
    function _globalRoyaltyInfo(uint256 _salePrice)
        internal
        view
        returns (address, uint256)
    {
        uint256 royaltyAmount = (_salePrice * _royaltyInBips) / _bipsBasedFeeDenominator;
        return (_royaltyDestination, royaltyAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../utils/Context.sol";

/**
 * @title ERC721 Burnable Token
 * @dev ERC721 Token that can be burned (destroyed).
 */
abstract contract ERC721Burnable is Context, ERC721 {
    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - The caller must own `tokenId` or be an approved operator.
     */
    function burn(uint256 tokenId) public virtual {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _burn(tokenId);
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}