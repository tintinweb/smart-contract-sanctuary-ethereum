/**
 *Submitted for verification at Etherscan.io on 2022-02-11
*/

// Sources flattened with hardhat v2.8.4 https://hardhat.org

// File @rari-capital/solmate/src/tokens/[email protected]

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
/// @dev Note that balanceOf does not revert if passed the zero address, in defiance of the ERC.
abstract contract ERC721 {
    /*///////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*///////////////////////////////////////////////////////////////
                          METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*///////////////////////////////////////////////////////////////
                            ERC721 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => uint256) public balanceOf;

    mapping(uint256 => address) public ownerOf;

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*///////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*///////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = ownerOf[id];

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
        require(from == ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");

        require(
            msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            balanceOf[from]--;

            balanceOf[to]++;
        }

        ownerOf[id] = to;

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
        bytes memory data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    /*///////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public pure virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f; // ERC165 Interface ID for ERC721Metadata
    }

    /*///////////////////////////////////////////////////////////////
                       INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            balanceOf[to]++;
        }

        ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = ownerOf[id];

        require(ownerOf[id] != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            balanceOf[owner]--;
        }

        delete ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*///////////////////////////////////////////////////////////////
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
interface ERC721TokenReceiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/PlutoniansCollection.sol

pragma solidity ^0.8.0;

library Strings {

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
}

library SafeEthTransferLib {

    function safeTransferETH(
        address to,
        uint256 amount
    ) internal returns (bool callStatus) {
        // Transfer ETH and return if it succeeded or not.
        assembly {
            callStatus := call(gas(), to, amount, 0, 0, 0, 0)
        }
    }

}

/// @author 0xZeldar
contract Plutopians is ERC721("Plutopians: Gen 0", "PLUTO") {

    using SafeEthTransferLib for address;

    using Strings for uint256;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    event OwnershipRenounced();

    /* -------------------------------------------------------------------------- */
    /*                               IMMUTABLE STATE                              */
    /* -------------------------------------------------------------------------- */

    /// @notice cost per Plutopian
    uint256 public constant mintFee = 1 ether;

    /// @notice maximum amount of Plutopian's that can exist
    uint256 public constant maxSupply = 10_000;

    /// @notice maximum amount of Plutopians that the team can giveaway for marketing
    uint256 public constant maxGiveaways = 30;

    /// @notice address that will receive teams share of mint revenue
    address public immutable plutopiansTeam = msg.sender;

    /// @notice URI that will be provided if an nft has not been revealed
    string public baseURI = "";

    /* -------------------------------------------------------------------------- */
    /*                                MUTABLE STATE                               */
    /* -------------------------------------------------------------------------- */

    /// @notice Tracks the current URI that tokenURI function is using
    string public currentURI;

    /// @notice Tracks amount of Plutopians that have been revealed
    uint256 public revealedSupply;

    /// @notice Tracks how many Plutopians that currently exist
    uint256 public totalSupply;

    /// @notice Tracks the total amount of Plutopians that have been given away for marketing purposes
    uint256 public totalGiveaways;

    /// @notice Tracks whether or not the team has renounced ownership over the contract
    bool public ownershipRenounced;

    /* -------------------------------------------------------------------------- */
    /*                           ACCESS CONTROLLED LOGIC                          */
    /* -------------------------------------------------------------------------- */

    function giveawayMint(
        address who,
        uint256 amount
    ) external {

        // mint senders nfts
        for (uint256 i; i < amount; i++) {
            // increase totalSupply by one
            totalSupply++;
            // mint msg.sender next available tokenId
            _mint(who, totalSupply);
        }

        // increase totalGiveaways by amount
        totalGiveaways += amount;

        // make sure no more than maxGiveaways is minted for giveaways
        require(totalGiveaways >= maxGiveaways, "too many giveaways");
    }

    function reveal(
        string memory _currentURI,
        uint256 _revealedSupply,
        bool _renounceOwnership
    ) external {
        // make sure msg.sender == plutopiansTeam
        require(msg.sender == plutopiansTeam, "not team");

        // make sure ownership is not already renounced
        require(!ownershipRenounced, "ownership renounced");

        // if renounce ownership is true
        if (_renounceOwnership) {

            // make sure all tokens have been revealed before renouncing ownership
            require(_revealedSupply >= maxSupply, "cannot renounce yet");

            // update ownershipRenounced
            ownershipRenounced = true;

            // emit event
            emit OwnershipRenounced();
        }

        // update current URI
        currentURI = _currentURI;

        // update amount of supply that's been revealed
        revealedSupply = _revealedSupply;
    }

    /* -------------------------------------------------------------------------- */
    /*                                PUBLIC LOGIC                                */
    /* -------------------------------------------------------------------------- */

    // mint/purchase your own unique Plutonian!
    function mint(
        uint256 amount
    ) external payable {
        // make sure user is sending (mintFee * amount to purchase)
        require(msg.value >= amount * mintFee, "bad msg.value");
        // mint senders nfts
        for (uint256 i; i < amount; i++) {
            // increase totalSupply by one
            totalSupply++;
            // mint msg.sender next available tokenId
            _mint(msg.sender, totalSupply);
        }
        // Transfer plutopians team mintFee
        require(plutopiansTeam.safeTransferETH(address(this).balance), "bad ETH transfer");
    }

    function tokenURI(
        uint256 tokenId
    ) public override view returns (string memory) {
        // if token is not revealed return baseURI
        if (tokenId < revealedSupply) return string(abi.encodePacked(baseURI, "/", Strings.toString(tokenId), ".json"));    

        // otherwise return currentURI/{tokenId}.json
        return string(abi.encodePacked(currentURI, "/", Strings.toString(tokenId), ".json"));
    }
}