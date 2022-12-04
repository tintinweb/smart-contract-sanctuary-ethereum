// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import {ERC721Initializable} from "./ERC721Initializable.sol";
import {IENS} from "./interfaces/IENS.sol";
import {IENSBoundBadge} from "./interfaces/IENSBoundBadge.sol";

error NotPermitted(); // ENSBound
error OnlyIssuer(); // Can be called only by issuer
error Initialized(); // Already initialized
error NotIssued(); // Badge not yet issed
error SupplyLimitReached(); // Total supply is minted
error AlreadyIssued(); // The Badge is already minted to the ENS domain

contract ENSBoundBadge is IENSBoundBadge, ERC721Initializable {
    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    ///@notice Address of ENS contract to resolve underlying address
    IENS public ensAddress;

    ///@notice Address of the badge issuer
    address public issuer;

    ///@notice Latest BadgeID
    uint256 public badgeId;

    ///@notice Max supply for the badge
    uint256 public supply;

    ///@notice Maps badgeId with BadgeInfo
    mapping(uint256 => BadgeInfo) public badgeInfo;

    ///@notice Used to specify if one ENS domain can hold multiple badges
    bool public canHoldMultiple;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/
    event Issued(
        string _recipient,
        address indexed _recipientAddress,
        uint256 _badgeId
    );
    event Revoked(address indexed _revokedFrom, uint256 _badgeId);

    /*//////////////////////////////////////////////////////////////
                                 INITIALIZER
    //////////////////////////////////////////////////////////////*/

    /// @notice Initializer
    /// @param _name Name of the badge
    /// @param _symbol Symbol for the badge
    /// @param _ensAddress Address of ENS contract
    /// @param _issuer Address of the Badge issuer
    /// @param _supply Max supply for the badge
    /// @param _canHoldMultiple Used to specify if an ENS domain can hold multiple badges
    function initialize(
        string memory _name,
        string memory _symbol,
        address _ensAddress,
        address _issuer,
        uint256 _supply,
        bool _canHoldMultiple
    ) public {
        if (address(ensAddress) != address(0)) revert Initialized();
        name = _name;
        symbol = _symbol;
        issuer = _issuer;
        ensAddress = IENS(_ensAddress);
        supply = _supply;
        canHoldMultiple = _canHoldMultiple;
    }

    /*//////////////////////////////////////////////////////////////
                                 PUBLIC METHODS
    //////////////////////////////////////////////////////////////*/
    /// @notice Returns the metadata uri for the given `_badgeId`
    function tokenURI(uint256 _badgeId)
        public
        view
        override
        returns (string memory)
    {
        return badgeInfo[_badgeId].metadataURI;
    }

    /// @notice Used to issue a new badge
    /// @param _ensName ENS name of the recipient
    /// @param _ensNodeHash NodeHash of the ENS name
    /// @param _badgeInfo Additional info for the Badge
    function issueBadge(
        string memory _ensName,
        bytes32 _ensNodeHash,
        BadgeInfo memory _badgeInfo
    ) external {
        if (msg.sender != issuer) revert OnlyIssuer();
        uint256 _badgeId = badgeId++;
        if (_badgeId > supply) revert SupplyLimitReached();
        address _resolvedAddress = resolveENS(_ensNodeHash);
        if (!canHoldMultiple && _balanceOf[_resolvedAddress] > 0)
            revert AlreadyIssued();

        _mint(_resolvedAddress, _badgeId);
        badgeInfo[_badgeId] = _badgeInfo;
        emit Issued(_ensName, _resolvedAddress, _badgeId);
    }

    /// @notice Used to revoke any issued badge
    /// @param _badgeId Id of the badge to revoke
    function revokeBadge(uint256 _badgeId) external {
        if (msg.sender != issuer) revert OnlyIssuer();
        _burn(_badgeId);
    }

    /// @notice Used to get the underlying address for a given ENS domain
    /// @param _ensNodeHash Nodehash for the ens domain
    /// @return The associated address for the given Nodehash
    function resolveENS(bytes32 _ensNodeHash) public view returns (address) {
        address resolver = ensAddress.resolver(_ensNodeHash);
        return IENS(resolver).addr(_ensNodeHash);
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL METHODS
    //////////////////////////////////////////////////////////////*/
    function _mint(address to, uint256 id) internal virtual {
        _balanceOf[to] += 1;
        _ownerOf[id] = to;
        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        if (id > badgeId) revert NotIssued();
        address holder = _ownerOf[id];
        if (holder == address(0)) revert NotIssued();

        _balanceOf[holder] -= 1;
        _ownerOf[id] = address(0);

        emit Revoked(holder, id);

        emit Transfer(holder, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                                 RESTRICTED METHODS
    //////////////////////////////////////////////////////////////*/
    function approve(address spender, uint256 id) public virtual override {
        revert NotPermitted();
    }

    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        revert NotPermitted();
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        revert NotPermitted();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual override {
        revert NotPermitted();
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual override {
        revert NotPermitted();
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient initializatble ERC-721 implementation.
/// @notice Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721Initializable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed id
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 indexed id
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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

    //////////////////////////////////////////////////////////////*/

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];

        require(
            msg.sender == owner || isApprovedForAll[owner][msg.sender],
            "NOT_AUTHORIZED"
        );

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
            msg.sender == from ||
                isApprovedForAll[from][msg.sender] ||
                msg.sender == getApproved[id],
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    ""
                ) ==
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
                ERC721TokenReceiver(to).onERC721Received(
                    msg.sender,
                    from,
                    id,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        returns (bool)
    {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
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
pragma solidity 0.8.17;

/// @notice Interface for ENS Resolver

interface IENS {
    function resolver(bytes32 nodeHash) external view returns (address);

    function addr(bytes32 nodeHash) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @notice Interface for ENSBoundBadge contract
interface IENSBoundBadge {
    struct BadgeInfo {
        string title; /// Title of the Badge
        string description; /// Description for the badge
        string metadataURI; /// Metadata URI for the badge
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _ensAddress,
        address _issuer,
        uint256 _supply,
        bool _canHoldMultiple
    ) external;
}