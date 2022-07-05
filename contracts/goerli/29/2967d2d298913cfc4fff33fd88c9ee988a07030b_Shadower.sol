// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./SoulBoundToken.sol";

contract Shadower is SoulBoundToken {
    uint256 public totalShadowers;
    uint256 public totalContributions;

    enum ContributionType { PULL_REQUEST_OPENED, PULL_REQUEST_MERGED, ISSUE_OPENED }

    struct Shad {
        uint256 id;
        uint256 totalRepositoriesContributed;
        uint256 totalPullRequestsOpened;
        uint256 totalPullRequestsMerged;
        uint256 totalIssuesOpened;
        address addr;
        string username;
        string handle;
    }

    struct Contribution {
        uint256 id; // PR/Issue Id
        address contributor;
        string repoUrl;
        ContributionType contributionType;
    }

    mapping(address => Shad) public shadowers;
    mapping(address => mapping(string => bool)) public contributedTo;
    mapping(address => Contribution[]) public shadToContributions;

    event NewShad(uint256 indexed id, string indexed username, string indexed handle);
    event NewContribution(address indexed shad, string indexed url, ContributionType indexed contributionType);

    constructor(address repository) SoulBoundToken("Shadower", "SHAD") {}

    function isAShad(address addr) public view returns (bool) {
        return shadowers[addr].addr != address(0);
    }

    function becomeAShad(string memory username, string memory handle) public returns (uint256) {
        require(!isAShad(msg.sender), "Already a big Shad");
        uint256 newTotalShadowers = ++totalShadowers;

        _safeMint(msg.sender, newTotalShadowers);
        shadowers[msg.sender] = Shad(newTotalShadowers, 0, 0, 0, 0, msg.sender, username, handle);

        emit NewShad(newTotalShadowers, username, handle);

        return newTotalShadowers;
    }

    function registerContribution(string memory repoUrl, ContributionType contributionType, uint256 id) public {
        if (!isAShad(msg.sender)) revert();

        Shad storage shad = shadowers[msg.sender];

        if (contributionType == ContributionType.PULL_REQUEST_OPENED) shad.totalPullRequestsOpened++;
        if (contributionType == ContributionType.PULL_REQUEST_MERGED) shad.totalPullRequestsMerged++;
        if (contributionType == ContributionType.ISSUE_OPENED) shad.totalIssuesOpened++;

        if (!contributedTo[msg.sender][repoUrl]) {
            contributedTo[msg.sender][repoUrl] = true;
            shad.totalRepositoriesContributed++;
        }

        ++totalContributions;
        Contribution memory contribution = Contribution(id, msg.sender, repoUrl, contributionType);
        shadToContributions[msg.sender].push(contribution);

        emit NewContribution(msg.sender, repoUrl, contributionType);
    }

    function tokenURI(uint256 id) public view virtual override returns (string memory) {
        return "Hello";
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "solmate/tokens/ERC721.sol";

abstract contract SoulBoundToken is ERC721 {
	constructor(string memory name, string memory symbol) ERC721(name, symbol) {}

	function approve(address spender, uint256 id) public virtual override {
		revert("Approval not supported");
	}

    function setApprovalForAll(address operator, bool approved) public virtual override {
		revert("Approval not supported");
    }

    function transferFrom(address from, address to, uint256 id) public virtual override {
		revert("Transfer not supported");
	}

    function safeTransferFrom(address from, address to, uint256 id) public virtual override {
		revert("Transfer not supported");
	}

    function safeTransferFrom( address from, address to, uint256 id, bytes calldata data) public virtual override {
		revert("Transfer not supported");
	}
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
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