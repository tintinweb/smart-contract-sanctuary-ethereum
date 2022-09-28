// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import {IERC165} from "@openzeppelin/contracts/interfaces/IERC165.sol";
import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";
import {CantBeEvil, LicenseVersion} from "@a16z/contracts/licenses/CantBeEvil.sol";

import {ERC721Checkpointable} from "src/base/ERC721Checkpointable.sol";
import {IBBOTSRenderer} from "src/interface/BBOTSRenderer.interface.sol";
import {IBBOTS, MintPhase, Ticket} from "src/interface/BBOTS.interface.sol";
import {ExternalRenderer} from "src/metadata/ExternalRenderer.sol";

//_/\\\\\\\\\\\\\__________________/\\\\\\\\\\\\\_________/\\\\\_______/\\\\\\\\\\\\\\\_____/\\\\\\\\\\\___
//_\/\\\/////////\\\_______________\/\\\/////////\\\_____/\\\///\\\____\///////\\\/////____/\\\/////////\\\_
// _\/\\\_______\/\\\_______________\/\\\_______\/\\\___/\\\/__\///\\\________\/\\\________\//\\\______\///__
//  _\/\\\\\\\\\\\\\\___/\\\\\\\\\\\_\/\\\\\\\\\\\\\\___/\\\______\//\\\_______\/\\\_________\////\\\_________
//   _\/\\\/////////\\\_\///////////__\/\\\/////////\\\_\/\\\_______\/\\\_______\/\\\____________\////\\\______
//    _\/\\\_______\/\\\_______________\/\\\_______\/\\\_\//\\\______/\\\________\/\\\_______________\////\\\___
//     _\/\\\_______\/\\\_______________\/\\\_______\/\\\__\///\\\__/\\\__________\/\\\________/\\\______\//\\\__
//      _\/\\\\\\\\\\\\\/________________\/\\\\\\\\\\\\\/_____\///\\\\\/___________\/\\\_______\///\\\\\\\\\\\/___
//       _\/////////////__________________\/////////////_________\/////_____________\///__________\///////////_____

/// @title B-BOTS: CC0 Media Model
/// @author ghard.eth
contract BBOTS is
    IBBOTS,
    ERC721Checkpointable,
    Ownable,
    ExternalRenderer,
    CantBeEvil
{
    /*///////////////////////////////////////////////////////////////
                            MINT STORAGE
    //////////////////////////////////////////////////////////////*/

    /** Total supply that can ever be minted */
    uint256 public immutable MAX_SUPPLY;
    /** Cost to mint (not applicable to admin) */
    uint256 public immutable MINT_COST;
    /** Max per address that can be minted (not applicable to admin) */
    uint256 public MAX_PER_ADDRESS;
    /** Total supply that is available to mint currently (not applicable to admin) */
    uint256 public AVAILABLE_SUPPLY;
    /** Next tokenId to be minted */
    uint256 public nextId;

    bytes32 public constant TICKET_TYPEHASH =
        keccak256("Ticket(address buyer)");

    mapping(address => uint256) public numMinted;

    MintPhase public mintPhase = MintPhase.Locked;
    address public gatekeeper;

    /*///////////////////////////////////////////////////////////////
                              ROYALTIES
    //////////////////////////////////////////////////////////////*/

    address recipient;
    uint256 royaltyBps;

    constructor(
        IBBOTSRenderer _renderer,
        address _gatekeeper,
        address _recipient,
        uint256 _royaltyBps,
        uint256 _maxSupply,
        uint256 _maxPerAddress,
        uint256 _availableSupply,
        uint256 _mintCost,
        string memory _name,
        string memory _symbol
    )
        ERC721Checkpointable(_name, _symbol)
        ExternalRenderer(_renderer)
        CantBeEvil(LicenseVersion.CBE_CC0)
    {
        gatekeeper = _gatekeeper;

        recipient = _recipient;
        royaltyBps = _royaltyBps;

        if (_availableSupply > _maxSupply) revert InvalidAvailableSupply();

        MAX_SUPPLY = _maxSupply;
        MAX_PER_ADDRESS = _maxPerAddress;
        AVAILABLE_SUPPLY = _availableSupply;
        MINT_COST = _mintCost;
    }

    /*///////////////////////////////////////////////////////////////
                        		MINTING
    //////////////////////////////////////////////////////////////*/

    /// @dev validates payment exceeds minting costs
    modifier validatePayment(uint256 _amt) {
        if (msg.value != _amt * MINT_COST) revert InvalidPayment();
        _;
    }

    /// @dev validates that contract is in the expected phase
    modifier validatePhase(MintPhase _expected) {
        if (mintPhase != _expected) revert InvalidMintPhase();
        _;
    }

    /// @dev validates that call wont exceed available supply
    modifier validateAvailableSupply(uint256 _amt) {
        if (nextId + _amt > AVAILABLE_SUPPLY) revert AvailableSupplyExceeded();
        _;
    }

    /// @dev validates that call wont exceed total supply
    modifier validateTotalSupply(uint256 _amt) {
        if (nextId + _amt > MAX_SUPPLY) revert TotalSupplyExceeded();
        _;
    }

    /// @dev validates address cant mint more than MAX_PER_ADDRESS
    modifier validateAddressSupply(uint256 _amt) {
        numMinted[msg.sender] += _amt;
        if (numMinted[msg.sender] > MAX_PER_ADDRESS) revert MaxMintsExceeded();
        _;
    }

    /// @dev validates that the ticket was signed by the gatekeeper for the caller
    modifier validateTicket(Ticket calldata _ticket) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(abi.encode(TICKET_TYPEHASH, msg.sender));

        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );

        address signatory = ecrecover(digest, _ticket.v, _ticket.r, _ticket.s);

        if (signatory != gatekeeper) revert InvalidTicket();
        _;
    }

    /**
     * @notice Sets the phase which allows who can mint
     * @dev Only callable by owner
     */
    function setMintPhase(MintPhase _phase) external onlyOwner {
        mintPhase = _phase;

        emit MintPhaseSet(_phase);
    }

    /**
     * @notice Sets supply available for public and allowlist minting
     * @dev only callable by owner
     */
    function setAvailableSupply(uint256 _amt) external onlyOwner {
        // Available supply can never be more than max supply
        if (_amt > MAX_SUPPLY) revert InvalidAvailableSupply();
        // Available supply can never be less than current supply
        if (_amt < nextId) revert InvalidAvailableSupply();

        AVAILABLE_SUPPLY = _amt;
        emit AvailableSupplySet(_amt);
    }

    /**
     * @notice Sets how many can be minted per address
     * @dev only callable by owner
     */
    function setMaxPerAddress(uint256 _amt) external onlyOwner {
        MAX_PER_ADDRESS = _amt;
        emit MaxPerAddressSet(_amt);
    }

    /**
     * @notice Allows owner to mint directly `_amt` of B-BOTS to `_to`. Cant exceed total supply.
     * @dev Only callable by owner
     */
    function mintTo(address _to, uint256 _amt) external onlyOwner {
        _processMint(_to, _amt);
    }

    /**
     * @notice Allows an address on the allowlist to mint with a signed ticket.
     * @dev To be called during the allowlist minting phase
     */
    function mint(uint256 _amt, Ticket calldata _ticket)
        external
        payable
        validatePayment(_amt)
        validatePhase(MintPhase.Allow)
        validateTicket(_ticket)
        validateAddressSupply(_amt)
        validateAvailableSupply(_amt)
    {
        _processMint(msg.sender, _amt);
    }

    /**
     * @notice Allows anyone to mint up to `MAX_PER_ADDRESS`.
     * @dev To be called during the public minting phase
     */
    function mint(uint256 _amt)
        external
        payable
        validatePayment(_amt)
        validatePhase(MintPhase.Public)
        validateAddressSupply(_amt)
        validateAvailableSupply(_amt)
    {
        _processMint(msg.sender, _amt);
    }

    /// @dev validate total supply and call internal mint function
    function _processMint(address _to, uint256 _amt)
        internal
        validateTotalSupply(_amt)
    {
        for (uint256 i; i < _amt; i++) {
            // Assume minter can receive to save gas
            _mint(_to, nextId);
            nextId++;
        }
    }

    /*///////////////////////////////////////////////////////////////
                        		ROYALTIES
    //////////////////////////////////////////////////////////////*/

    /// @dev returns royalty info according to EIP-2981 standard
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (recipient, (salePrice * royaltyBps) / 10_000);
    }

    function updateRoyaltyRecipient(address _recipient) external onlyOwner {
        recipient = _recipient;
    }

    /// @dev send funds to recipient
    function sweep() external {
        (bool success, ) = recipient.call{
            value: address(this).balance
        }(new bytes(0));
        require(success);
    }

    /*///////////////////////////////////////////////////////////////
                        	   METADATA
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Get the metadata address for token `_id`. Will be updated after the reveal of each tranche
     */
    function tokenURI(uint256 id)
        public
        view
        override
        returns (string memory metadataUri)
    {
        return renderer.tokenURI(id);
    }

    function updateMetadataRenderer(address _renderer)
        external
        override
        onlyOwner
    {
        _updateMetadataRenderer(_renderer);
    }

    function lockMetadata() external override onlyOwner {
        _lockMetadata();
    }

    /*///////////////////////////////////////////////////////////////
                                UTILS
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(IERC165, ERC721, CantBeEvil)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            ERC721.supportsInterface(interfaceId) ||
            CantBeEvil.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// a16z Contracts v0.0.1 (CantBeEvil.sol)
pragma solidity ^0.8.13;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./ICantBeEvil.sol";

enum LicenseVersion {
    CBE_CC0,
    CBE_ECR,
    CBE_NECR,
    CBE_NECR_HS,
    CBE_PR,
    CBE_PR_HS
}

contract CantBeEvil is ERC165, ICantBeEvil {
    using Strings for uint;
    string internal constant _BASE_LICENSE_URI = "ar://_D9kN1WrNWbCq55BSAGRbTB4bS3v8QAPTYmBThSbX3A/";
    LicenseVersion public licenseVersion; // return string
    constructor(LicenseVersion _licenseVersion) {
        licenseVersion = _licenseVersion;
    }

    function getLicenseURI() public view returns (string memory) {
        return string.concat(_BASE_LICENSE_URI, uint(licenseVersion).toString());
    }

    function getLicenseName() public view returns (string memory) {
        return _getLicenseVersionKeyByValue(licenseVersion);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return
            interfaceId == type(ICantBeEvil).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getLicenseVersionKeyByValue(LicenseVersion _licenseVersion) internal pure returns (string memory) {
        require(uint8(_licenseVersion) <= 6);
        if (LicenseVersion.CBE_CC0 == _licenseVersion) return "CBE_CC0";
        if (LicenseVersion.CBE_ECR == _licenseVersion) return "CBE_ECR";
        if (LicenseVersion.CBE_NECR == _licenseVersion) return "CBE_NECR";
        if (LicenseVersion.CBE_NECR_HS == _licenseVersion) return "CBE_NECR_HS";
        if (LicenseVersion.CBE_PR == _licenseVersion) return "CBE_PR";
        else return "CBE_PR_HS";
    }
}

//SPDX-License-Identifier: BSD-3-Clause
pragma solidity ^0.8.13;

import {ERC721} from "@rari-capital/solmate/src/tokens/ERC721.sol";

/// @notice This is port of the Nouns ERC721Checkpointable.sol using solmate as a base. For licensing information please check original implementation:
/// @notice https://github.com/nounsDAO/nouns-monorepo/blob/1.0.0/packages/nouns-contracts/contracts/base/ERC721Checkpointable.sol
abstract contract ERC721Checkpointable is ERC721 {
    /// @notice Defines decimals as per ERC-20 convention to make integrations with 3rd party governance platforms easier
    uint8 public constant decimals = 0;

    /// @notice A record of each accounts delegate
    mapping(address => address) private _delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping(address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,uint256 chainId,address verifyingContract)"
        );

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping(address => uint256) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(
        address indexed delegator,
        address indexed fromDelegate,
        address indexed toDelegate
    );

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(
        address indexed delegate,
        uint256 previousBalance,
        uint256 newBalance
    );

    constructor(string memory _name, string memory _symbol)
        ERC721(_name, _symbol)
    {}

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public override {
        _beforeTokenTransfer(from, to, id);
        super.transferFrom(from, to, id);
    }

    function _mint(address to, uint256 id) internal virtual override {
        _beforeTokenTransfer(address(0), to, id);
        super._mint(to, id);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 id
    ) internal virtual {
        /// @notice Differs from `_transferTokens()` to use `delegates` override method to simulate auto-delegation
        _moveDelegates(delegates(from), delegates(to), 1);
    }

    /**
     * @notice The votes a delegator can delegate, which is the current balance of the delegator.
     * @dev Used when calling `_delegate()`
     */
    function votesToDelegate(address delegator) public view returns (uint96) {
        return
            safe96(
                balanceOf(delegator),
                "ERC721Checkpointable::votesToDelegate: amount exceeds 96 bits"
            );
    }

    /**
     * @notice Overrides the standard `Comp.sol` delegates mapping to return
     * the delegator's own address if they haven't delegated.
     * This avoids having to delegate to oneself.
     */
    function delegates(address delegator) public view returns (address) {
        address current = _delegates[delegator];
        return current == address(0) ? delegator : current;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        if (delegatee == address(0)) delegatee = msg.sender;
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                getChainId(),
                address(this)
            )
        );

        bytes32 structHash = keccak256(
            abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry)
        );
        bytes32 digest = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
        address signatory = ecrecover(digest, v, r, s);
        require(
            signatory != address(0),
            "ERC721Checkpointable::delegateBySig: invalid signature"
        );
        require(
            nonce == nonces[signatory]++,
            "ERC721Checkpointable::delegateBySig: invalid nonce"
        );
        require(
            block.timestamp <= expiry,
            "ERC721Checkpointable::delegateBySig: signature expired"
        );

        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return
            nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint256 blockNumber)
        public
        view
        returns (uint96)
    {
        require(
            blockNumber < block.number,
            "ERC721Checkpointable::getPriorVotes: not yet determined"
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        /// @notice differs from `_delegate()` in `Comp.sol` to use `delegates` override method to simulate auto-delegation
        address currentDelegate = delegates(delegator);

        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        uint96 amount = votesToDelegate(delegator);

        _moveDelegates(currentDelegate, delegatee, amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0
                    ? checkpoints[srcRep][srcRepNum - 1].votes
                    : 0;
                uint96 srcRepNew = sub96(
                    srcRepOld,
                    amount,
                    "ERC721Checkpointable::_moveDelegates: amount underflows"
                );
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0
                    ? checkpoints[dstRep][dstRepNum - 1].votes
                    : 0;
                uint96 dstRepNew = add96(
                    dstRepOld,
                    amount,
                    "ERC721Checkpointable::_moveDelegates: amount overflows"
                );
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = safe32(
            block.number,
            "ERC721Checkpointable::_writeCheckpoint: block number exceeds 32 bits"
        );

        if (
            nCheckpoints > 0 &&
            checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber
        ) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(
                blockNumber,
                newVotes
            );
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint32)
    {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint256 n, string memory errorMessage)
        internal
        pure
        returns (uint96)
    {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal view returns (uint256) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BBOTSRendererEvents} from "./BBOTSRenderer.events.sol";
import {IMetadataRenderer} from "./MetadataRenderer.interface.sol";

interface IBBOTSRenderer is BBOTSRendererEvents, IMetadataRenderer {
    error TooMuchEntropy();

    /*///////////////////////////////////////////////////////////////
                        	   RANDOMNESS
    //////////////////////////////////////////////////////////////*/

    function requestEntropy(bytes32 _keyHash, uint32 _callbackGasLimit)
        external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IERC2981} from "@openzeppelin/contracts/interfaces/IERC2981.sol";
import {BBOTSEvents, MintPhase, Ticket} from "./BBOTS.events.sol";

interface IBBOTS is IERC2981, BBOTSEvents {
    /*///////////////////////////////////////////////////////////////
                            ERRORS
    //////////////////////////////////////////////////////////////*/

    error InvalidMintPhase();
    error InvalidPayment();
    error InvalidTicket();
    error TotalSupplyExceeded();
    error AvailableSupplyExceeded();
    error MaxMintsExceeded();
    error InvalidAvailableSupply();

    /*///////////////////////////////////////////////////////////////
                        	MINTING
    //////////////////////////////////////////////////////////////*/

    function setMintPhase(MintPhase _phase) external;

    function mintTo(address _to, uint256 _amt) external;

    function mint(uint256 _amt, Ticket calldata _ticket) external payable;

    function mint(uint256 _amt) external payable;

    /*///////////////////////////////////////////////////////////////
                        	UTILS
    //////////////////////////////////////////////////////////////*/

    function updateMetadataRenderer(address _renderer) external;

    function lockMetadata() external;

    function sweep() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {IMetadataRenderer} from "../interface/MetadataRenderer.interface.sol";

contract ExternalRenderer {
    error MetadataLocked();

    IMetadataRenderer public renderer;
    bool public metadataLocked;

    constructor(IMetadataRenderer _renderer) {
        renderer = _renderer;
    }

    modifier requireMetadataUnlocked() {
        if (metadataLocked) revert MetadataLocked();
        _;
    }

    function _updateMetadataRenderer(address _renderer)
        internal
        virtual
        requireMetadataUnlocked
    {
        renderer = IMetadataRenderer(_renderer);
    }

    function _lockMetadata() internal virtual requireMetadataUnlocked {
        metadataLocked = true;
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
// a16z Contracts v0.0.1 (ICantBeEvil.sol)
pragma solidity ^0.8.13;

interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);
    function getLicenseName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface BBOTSRendererEvents {
    event EntropyRequested();
    event EntropyReceived(uint256 entropy);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface IMetadataRenderer {
    /*///////////////////////////////////////////////////////////////
                        	   RENDERING
    //////////////////////////////////////////////////////////////*/

    function tokenURI(uint256 id) external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

enum MintPhase {
    Locked,
    Allow,
    Public
}

struct Ticket {
    uint8 v;
    bytes32 r;
    bytes32 s;
}

interface BBOTSEvents {
    /*///////////////////////////////////////////////////////////////
                            EVENTS
    //////////////////////////////////////////////////////////////*/

    event MintPhaseSet(MintPhase phase);
    event AvailableSupplySet(uint256 amt);
    event MaxPerAddressSet(uint256 amt);
}