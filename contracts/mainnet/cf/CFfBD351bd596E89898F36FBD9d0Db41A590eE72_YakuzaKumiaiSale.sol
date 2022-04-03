// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

interface IYakuzaKummiai {
    function mintTo(address _to, uint256 tokenId) external;
    function setBaseTokenURI(string memory _baseTokenURI) external;
}

contract YakuzaKumiaiSale is AccessControl {
    using Strings for string;

    uint256 constant public totalSales = 8930;
    uint256 constant public preSale1Count = 1024;
    uint256 constant public preSale2Count = 30;
    
    uint256 public maxPreSale1MintPerWallet = 2;
    uint256 public maxPreSale2MintPerWallet = 1;
    uint256 public maxPreSale3MintPerWallet = 20;
    uint256 constant public maxPublicSaleMintPerWallet = 25;

    uint256 constant public preSale1Start = 1648954800; // 4.3, 12 pm JST
    uint256 constant public preSale1End = 1649127600; // 4.5, 12 pm JST
    uint256 constant public preSale2Start = 1649170800; // 4.6, 12 am JST
    uint256 constant public preSale2End = 1649214000; // 4.6, 12 pm JST
    uint256 constant public preSale3Start = 1649257200; // 4.7, 12 am JST
    uint256 constant public preSale3End = 1649390400;   // 4.8, 12 pm JST
    uint256 constant public publicSaleStart = 1649516400; // 4.10 12 am JST


    uint256 constant public preSale1MintFee = 0.01 ether;
    uint256 constant public preSale2MintFee = 0.02 ether;
    uint256 constant public publicSaleMintFee = 0.07 ether;

    // roles
    bytes32 public constant WITHDRAWER_ROLE = keccak256("WITHDRAWER"); 
    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public merkleRootWL1 = 0xb5d235c7dc95984c578f696a365fc833e64459b72a1c5304d1c105ec6822d59b;
    bytes32 public merkleRootWL2 = 0xb5d235c7dc95984c578f696a365fc833e64459b72a1c5304d1c105ec6822d59b;

    address payable public wallet1 = payable(0x192F6CCD0b9bd54bdA1A7e3776b718F908028EC4);   // wallet address for accounts payable and marketing
    address payable public wallet2 = payable(0x8d6AE8FE3A583A0B60cF7670332726b9bb30A507);   // wallet address for giveaway
    address payable public wallet3 = payable(0xd5a5c1B25EdB13ED2737247B0a7E0578705bEBe9);   // wallet address for tool development
    address payable public wallet4 = payable(0x8C06E7617575576a26954779fbB58a467faa6f16);   // wallet address for anime studio
    address payable public wallet5 = payable(0x80c1c51dD714d42A93E70e4544007984079EBE0B);   // wallet address for dev team
    address payable public wallet6 = payable(0x7b62AC97F6a9Fb98Ec7F48EAA109014C1B685A95);   // wallet address for addy (lead developer)

    address public nftAddress;
    mapping (address => uint256) public mintedTokens;

    uint256 totalMints = 0;

    uint256 marketWithdrawlAmount = 0 ether;

    modifier onlyAdmin() {
        require(hasRole(ADMIN, msg.sender), "Access is allowed for only ADMIN");
        _;
    }

    constructor(address _nftAddress) {
        nftAddress = _nftAddress;
        _grantRole(ADMIN, msg.sender);
    }

    /// @notice Update the base Uri
    /// @param _baseTokenURI baseTokenURI
    function setBaseTokenURI(string memory _baseTokenURI) external onlyAdmin {
        IYakuzaKummiai(nftAddress).setBaseTokenURI(_baseTokenURI);
    }

    /// @notice Update the whitelist1 
    function updateMerkleRootWL1(bytes32 _merkleRootWl) external onlyAdmin {
        merkleRootWL1 = _merkleRootWl;
    }

    /// @notice Update the whitelist2 
    function updateMerkleRootWL2(bytes32 _merkleRootWl) external onlyAdmin {
        merkleRootWL2 = _merkleRootWl;
    }

    /// @notice Update the wallet address of funders
    /// @param _walletName wallet name to update
    /// @param _address wallet address
    function updateWalletAddress(string memory _walletName, address _address) external onlyAdmin {
        
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet1")) ) {
            wallet1 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet2"))) {
            wallet2 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet3"))) {
            wallet3 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet4"))) {
            wallet4 = payable(_address);
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet5"))) {
            wallet5 = payable(_address);
        }
    }

    /// @notice get the wallet list 
    function getWalletList(string memory _walletName) public view onlyAdmin returns (address) {
        
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet1")) ) {
            return wallet1;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet2"))) {
            return wallet2;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet3"))) {
            return wallet3;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet4"))) {
            return wallet4;
        }
        if (keccak256(abi.encodePacked(_walletName)) == keccak256(abi.encodePacked("wallet5"))) {
            return wallet5;
        }
        return wallet2;
    }

    /// @notice Get max count per wallet for presale
    function getPreSaleMintAmount() public view returns (uint256) {
        return maxPreSale1MintPerWallet;
    }

    /// @notice Main mint function
    /// @param _to mint address
    /// @param _count nft count to mint
    function _mint(address _to, uint256 _count) internal {
        require(totalMints + _count <= totalSales, "PS: Exceeds total sales");
        totalMints += _count;
        IYakuzaKummiai(nftAddress).mintTo(_to, _count);
        mintedTokens[_to] += _count;
    }

    /// @notice Check if presale is finished
    function isPresale1Finished() public view returns (bool) {
        return block.timestamp > preSale1End || totalMints >= preSale1Count;
    }

    /// @notice Check if presale is finished
    function isPresale2Finished() public view returns (bool) {
        return block.timestamp > preSale2End || totalMints >= preSale1Count + preSale2Count;
    }

    /// @notice Check if presale is finished
    function isPresale3Finished() public view returns (bool) {
        return block.timestamp > preSale3End || totalMints >= preSale1Count + preSale2Count;
    }

    /// @notice Check if balance is available for withdrawal 
    function isWithdraw() internal view returns (bool) {
        uint256 total = address(this).balance;
        if (total < 0) {
            return false;
        }
        return true;
    }
    
    /// @notice Mint function for public sale
    /// @param _to mint address
    /// @param _count token count to mint
    function mint(address _to, uint256 _count) external payable {
        require(block.timestamp >= publicSaleStart, "PS: Public sale is not started");
        require(msg.value >= publicSaleMintFee * _count, "PS: Not enough funds sent");
        require(mintedTokens[_to] + _count <= maxPublicSaleMintPerWallet, "PS: Max limited per wallet");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale1
    function whiteListMint1(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale1Start, "PS: Presale1 is not started yet" );
        require(!isPresale1Finished(), "PS: Presale1 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale1MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale1MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL1, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale2
    function whiteListMint2(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale2Start, "PS: Presale2 is not started yet" );
        require(!isPresale2Finished(), "PS: Presale2 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale2MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale2MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL2, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Mint function for presale2
    function whiteListMint3(bytes32[] calldata _merkleProof, address _to, uint256 _count) external payable{
        require(block.timestamp >= preSale3Start, "PS: Presale3 is not started yet" );
        require(!isPresale3Finished(), "PS: Presale3 Finished");
        require(mintedTokens[_to] + _count <= maxPreSale3MintPerWallet, "PS: Max limited per wallet");
        require(msg.value >= preSale2MintFee * _count, "PS: Not enough funds sent");
        bytes32 leaf = keccak256(abi.encodePacked(_to));
        require(MerkleProof.verify(_merkleProof, merkleRootWL1, leaf) || MerkleProof.verify(_merkleProof, merkleRootWL2, leaf), "PS: Failed to verify WhiteList");
        _mint(_to, _count);
    }

    /// @notice Withdraw funds for marketing 
    function withdrawToMarketingFunder() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to widthdraw");
        require( marketWithdrawlAmount < 50 ether, "PS: Marketing funds has already been finished");
        uint256 total = address(this).balance;
        // wallet1.transfer(total);
        uint256 restAmount = 50 ether - marketWithdrawlAmount;
        if (total > restAmount) {
            marketWithdrawlAmount += restAmount;
            wallet1.transfer(restAmount);
        }
        else {
            marketWithdrawlAmount += total;
            wallet1.transfer(total);
        }
    }

    /// @notice Distribute the funds to team members
    function withdrawToFounders() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to split");
        require( marketWithdrawlAmount >= 50 ether, "PS: Marketing funds is not finished yet!");
        uint256 total = address(this).balance;

        wallet2.transfer(total * 1967 / 10000);
        wallet3.transfer(total * 2951 / 10000);
        wallet4.transfer(total * 2951 / 10000);
        wallet5.transfer(total * 1948 / 10000);
        wallet6.transfer(total * 184 / 10000);
    }

    /// @notice Grants the withdrawer role
    /// @param _role Role which needs to be assigned
    /// @param _user Address of the new withdrawer
    function grantRole(bytes32 _role, address _user) public override onlyAdmin {
        _grantRole(_role, _user);
    }

    /// @notice Revokes the withdrawer role
    /// @param _role Role which needs to be revoked
    /// @param _user Address which we want to revoke
    function revokeRole(bytes32 _role, address _user) public override onlyAdmin {
        _revokeRole(_role, _user);
    }

    function withdrawl() public payable onlyAdmin {
        require(isWithdraw(), "PS: Not enough funds to split");
        uint256 total = address(this).balance;
        wallet1.transfer(total);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

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
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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