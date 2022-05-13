// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@rari-capital/solmate/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "base64-sol/base64.sol";
import "./libraries/SVG.sol";
import "./libraries/Utils.sol";
import "./external/layerzero/NonblockingLzApp.sol";

/// @title Omnispace ERC721 token
/// @author luax.eth
contract Omnispace is ERC721, Ownable, Pausable, NonblockingLzApp, IERC2981 {
    using Strings for uint256;

    /// Counter to keep a track of the total supply
    uint256 public totalSupply;

    // Starting token id index
    uint16 public immutable startIndex;

    // Max supply of tokens
    uint16 public immutable limit;

    // Gas used for LayerZero
    uint256 internal gasForDestinationLzReceive = 350_000;

    struct Planet {
        bytes12 name;
        bytes12 color;
    }

    // Mapping of planets name by (chain) id
    mapping(uint256 => Planet) public planets;

    // Stucture to define spaceship specificities
    struct Spaceship {
        uint16 planetId;
        uint8 color;
        uint8 attack;
        uint8 defense;
        uint8 speed;
        uint8 cargo;
        uint8 crew;
        uint8 booster;
    }

    // Mapping of spaceship by tokenId
    mapping(uint256 => Spaceship) public spaceships;

    /// @dev constructor to initialize the contract
    /// @param startIndex_ starting token id index
    /// @param limit_ max supply of tokens
    /// @param lzEndpoint_ LayerZero endpoint
    constructor(
        uint16 startIndex_,
        uint16 limit_,
        address lzEndpoint_
    ) ERC721("Omnispace", "OMNSP") NonblockingLzApp(lzEndpoint_) {
        startIndex = startIndex_;
        limit = limit_;

        planets[1] = Planet("Ethereum", "3c3c3d");
        planets[56] = Planet("Binance", "fcd535");
        planets[43114] = Planet("Avalanche", "e84142");
        planets[137] = Planet("Polygon", "7b3fe4");
        planets[42161] = Planet("Arbitrum", "2d374b");
        planets[10] = Planet("Optimism", "ff0420");
        planets[250] = Planet("Fantom", "1969ff");

        planets[4] = Planet("Rinkeby", "3c3c3d");
        planets[97] = Planet("BinanceTest", "fcd535");
        planets[43113] = Planet("Fuji", "e84142");
        planets[14465] = Planet("Mumbai", "7b3fe4");
        planets[421611] = Planet("ArbitrumRin", "2d374b");
        planets[69] = Planet("OptiKovan", "ff0420");
        planets[4002] = Planet("FantomTest", "1969ff");

        planets[31337] = Planet("Hardhat", "fff100");
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /// @notice build a new spaceship
    /// @dev the function is payable to allow any donation.
    function build() external payable whenNotPaused {
        // Check if sender is transaction origin, to prevent reentrancy attacks
        // solhint-disable-next-line avoid-tx-origin
        if (msg.sender != tx.origin) revert SenderIsNotTxOrigin();

        // Check if gas price is 50 gwei or below to avoid gas war
        // if (tx.gasprice > 50_000_000_000) revert GasPriceTooHigh();

        // Check if the limit is not exceeded
        if (totalSupply > limit) revert AllSpaceshipBuilt();

        uint256 index;
        // Increment the tokenId counter and get current index
        unchecked {
            totalSupply++;
            index = startIndex + totalSupply;
        }

        // Generate insecure random number to use as specs for the spaceship
        // solhint-disable-next-line not-rely-on-time
        uint256 specs = uint256(
            keccak256(abi.encode(blockhash(block.number - 1), block.timestamp))
        );

        // Store the spaceship specs
        spaceships[index] = _buildSpaceship(specs);

        // Mint the spaceship to the sender
        _mint(_msgSender(), index);
    }

    function _buildSpaceship(uint256 specs_)
        internal
        view
        returns (Spaceship memory)
    {
        uint8[7] memory specs = Utils.splitNumber(specs_);

        return
            Spaceship({
                planetId: uint16(block.chainid),
                color: uint8(specs_),
                attack: specs[1] + 1,
                defense: specs[2] + 1,
                speed: specs[3] + 1,
                cargo: specs[4] + 1,
                crew: specs[5] + 1,
                booster: specs[6]
            });
    }

    // TODO: document
    function estimateHyperspaceJump(uint16 planetId_, uint256 spaceshipId_)
        public
        view
        returns (uint256)
    {
        // Create payload with spaceship details
        bytes memory payload = abi.encode(
            _msgSender(),
            spaceshipId_,
            spaceships[spaceshipId_]
        );

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // Estimate gas for sending to destination
        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            planetId_,
            address(this),
            payload,
            false,
            adapterParams
        );

        return messageFee;
    }

    /// @notice Send a spaceship to another planet using hyperspace jump
    /// @dev a message to LayerZero is sent to the destination planet with the spaceship info
    /// @param planetId_ the destination planet id
    /// @param spaceshipId_ the tokenId of the spaceship to send
    function hyperspaceJump(uint16 planetId_, uint256 spaceshipId_)
        external
        payable
        whenNotPaused
    {
        // Check spaceship ownership
        if (ownerOf[spaceshipId_] != _msgSender()) revert NotTokenOwner();

        // Check if planetId (chainId) is present in trusted source
        if (trustedRemoteLookup[planetId_].length == 0) revert PlanetNotFound();

        // Create payload with spaceship details
        bytes memory payload = abi.encode(
            _msgSender(),
            spaceshipId_,
            spaceships[spaceshipId_]
        );

        // Burn the spaceship on current chain
        _burn(spaceshipId_);
        delete spaceships[spaceshipId_];

        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(
            version,
            gasForDestinationLzReceive
        );

        // Estimate gas for sending to destination
        (uint256 messageFee, ) = lzEndpoint.estimateFees(
            planetId_,
            address(this),
            payload,
            false,
            adapterParams
        );

        // Check if enough ether is available to pay for the message
        if (msg.value < messageFee) revert InsufficientGasFees();

        // Send the spaceship to the new chain
        // solhint-disable-next-line check-send-result
        lzEndpoint.send{value: msg.value}(
            planetId_, // destination chainId
            trustedRemoteLookup[planetId_], // destination address
            payload, // payload
            payable(msg.sender), // refund address
            address(0x0), // unused param
            adapterParams // lz adapter params
        );
    }

    /// @notice token URI for a given tokenId
    /// @param spaceshipId_ tokenId of the token
    function tokenURI(uint256 spaceshipId_)
        public
        view
        override
        returns (string memory)
    {
        if (ownerOf[spaceshipId_] == address(0)) revert TokenNotFound();

        return _generateTokenURI(spaceshipId_);
    }

    // TODO: doc
    function _generateTokenURI(uint256 spaceshipId_)
        internal
        view
        returns (string memory)
    {
        Spaceship memory spaceship = spaceships[spaceshipId_];
        string memory attributes;

        attributes = string.concat(
            attributes,
            '{"trait_type":"Planet","value":"',
            Utils.bytes12ToString(planets[spaceship.planetId].name),
            '"},{"trait_type":"Attack","value":',
            uint256(spaceship.attack).toString(),
            '},{"trait_type":"Defense","value":',
            uint256(spaceship.defense).toString(),
            '},{"trait_type":"Speed","value":',
            uint256(spaceship.speed).toString(),
            '},{"trait_type":"Cargo","value":',
            uint256(spaceship.cargo).toString(),
            '},{"trait_type":"Crew","value":',
            uint256(spaceship.crew).toString(),
            '},{"trait_type":"Booster","display_type":"boost_number","value":',
            uint256(spaceship.booster).toString(), // TODO: rarity
            "}"
        );

        return
            string.concat(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '{"name": "Omniship #',
                            spaceshipId_.toString(),
                            '","description": "TODO","image_data": "',
                            _generateImageData(spaceshipId_),
                            // '","external_url": "https://omnispace.luax.dev/ship/', // TODO: URL
                            // spaceshipId_.toString(),
                            // '","animation_url": "https://omnispace.luax.dev/viwer/',
                            // spaceshipId_.toString(),
                            '","attributes": [',
                            attributes,
                            "]}"
                        )
                    )
                )
            );
    }

    // TODO: doc
    function _generateImageData(uint256 spaceshipId_)
        internal
        view
        returns (string memory)
    {
        Spaceship memory spaceship = spaceships[spaceshipId_];
        uint256 color = (uint256(spaceship.color) * 360) / 255;

        return
            string.concat(
                "data:image/svg+xml;base64,",
                Base64.encode(
                    bytes(
                        string.concat(
                            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 300 300" preserveAspectRatio="xMinYMin meet">',
                            // Weapons
                            SVG.path(
                                string.concat(
                                    SVG.prop(
                                        "d",
                                        "M219.528 114.316h.205l2.629 2.226v13.578h2.823v-11.187l2.834 2.401v8.786h2.612v-6.574l2.834 2.4v58.719h-13.937v-70.349zM81.465 184.665H67.528v-58.719l2.834-2.4v6.574h2.612v-8.786l2.834-2.401v11.187h2.823v-13.578l2.629-2.226h.205v70.349z"
                                    ),
                                    SVG.prop("stroke", "black"),
                                    SVG.prop("fill", "#8f8e8e")
                                )
                            ),
                            // Spaceship
                            SVG.path(
                                string.concat(
                                    SVG.prop(
                                        "d",
                                        "M158.938 29.732c0-3.351.552-5.89 1.46-7.598.909-1.708 2.174-2.585 3.6-2.611 1.425-.026 3.011.799 4.562 2.494 1.551 1.695 3.068 4.26 4.353 7.715 0 0 87.738 190.591 88.195 191.987.457 1.397.656 2.559.623 3.552-.034.994-.3 1.818-.774 2.54-.474.721-1.155 1.34-2.019 1.921l-73.009 50.892h-70.538l-73.009-50.892c-.864-.581-1.546-1.2-2.019-1.921-.474-.722-.741-1.546-.774-2.54-.034-.993.166-2.155.623-3.552.457-1.396 88.195-191.987 88.195-191.987 1.285-3.455 2.801-6.02 4.352-7.715 1.551-1.695 3.138-2.52 4.563-2.494 1.426.026 2.691.903 3.599 2.611.909 1.708 1.461 4.247 1.461 7.598v113.517l16.585.031-.029-113.548z"
                                    ),
                                    SVG.prop("stroke", SVG.hsl(color, 100, 20)),
                                    SVG.prop("fill", SVG.hsl(color, 100, 40))
                                )
                            ),
                            // Tower
                            SVG.path(
                                string.concat(
                                    SVG.prop(
                                        "d",
                                        "M188.453 235.377s-12.511-7.417-23.048-13.652h-28.54l-23.286 13.741.462-34.832a42.228 42.228 0 0 1-5.023-20.037c0-23.421 18.986-42.407 42.407-42.407 23.42 0 42.406 18.986 42.406 42.407a42.209 42.209 0 0 1-5.144 20.261l-.234 34.519z"
                                    ),
                                    SVG.prop("stroke", SVG.hsl(color, 100, 20)),
                                    SVG.prop(
                                        "fill",
                                        string.concat(
                                            "#",
                                            Utils.bytes12ToString(
                                                planets[spaceship.planetId]
                                                    .color
                                            )
                                        )
                                    )
                                )
                            ),
                            // Front
                            SVG.path(
                                string.concat(
                                    SVG.prop(
                                        "d",
                                        "M142.392 56.497v-.006h.001l-.001.006zm-26.243-.119 12.258-26.646s1.343-3.232 2.076-4.517c.734-1.285 1.501-2.35 2.276-3.198.776-.847 1.56-1.477 2.329-1.892.769-.415 1.522-.615 2.234-.602a3.482 3.482 0 0 1 1.994.675c.608.436 1.151 1.082 1.605 1.936.455.854.82 1.916 1.071 3.183.252 1.267.39 2.74.39 4.415l.01 26.759-26.243-.113zm42.865.113h.001v.006l-.001-.006zm.001 0 .01-26.759c0-1.675.138-3.148.39-4.415.251-1.267.616-2.329 1.071-3.183.454-.854.997-1.5 1.605-1.936a3.482 3.482 0 0 1 1.994-.675c.712-.013 1.465.187 2.234.602.769.415 1.553 1.045 2.329 1.892.775.848 1.542 1.913 2.276 3.198.733 1.285 2.076 4.517 2.076 4.517l12.258 26.646-26.243.113z"
                                    ),
                                    SVG.prop("stroke", SVG.hsl(color, 100, 20)),
                                    SVG.prop("fill", "#ececec")
                                )
                            ),
                            "</svg>"
                        )
                    )
                )
            );
    }

    // TODO: pause transfer

    // TODO: doc
    function _nonblockingLzReceive(
        uint16, /*srcChainId_*/
        bytes memory, /*srcAddress_*/
        uint64, /*nonce_*/
        bytes memory payload_
    ) internal override {
        (address user, uint256 spaceshipId, Spaceship memory spaceship) = abi
            .decode(payload_, (address, uint256, Spaceship));
        spaceships[spaceshipId] = spaceship;
        _mint(user, spaceshipId);
    }

    /// @dev update gas for destination lz receive
    function setGasForDestinationLzReceive(uint256 newValue_)
        external
        onlyOwner
    {
        gasForDestinationLzReceive = newValue_;
    }

    /// @notice royalties information
    /// 5% of the sale price, to the contract
    function royaltyInfo(
        uint256, /*spaceshipId_*/
        uint256 salePrice_
    ) external view returns (address, uint256) {
        return (address(_msgSender()), (salePrice_ / 100) * 5);
    }

    /// @notice receiver method for donations
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {
        // Thank you :)
    }

    /// @notice withdraw all funds to the owner wallet
    function withdraw() external onlyOwner {
        // solhint-disable-next-line avoid-low-level-calls
        (bool sent, ) = payable(_msgSender()).call{
            value: address(this).balance
        }("");
        if (!sent) revert WithdrawFailed();
    }

    error SenderIsNotTxOrigin();
    error GasPriceTooHigh();
    error AllSpaceshipBuilt();
    error NotTokenOwner();
    error TokenNotFound();
    error PlanetNotFound();
    error InsufficientGasFees();
    error WithdrawFailed();
}

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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library SVG {
    function path(string memory _props) internal pure returns (string memory) {
        return el("path", _props);
    }

    function hsl(
        uint256 _h,
        uint256 _s,
        uint256 _l
    ) internal pure returns (string memory) {
        return
            string.concat(
                "hsl(",
                uint2str(_h),
                ",",
                uint2str(_s),
                "%,",
                uint2str(_l),
                "%)"
            );
    }

    // A generic element, can be used to construct any SVG (or HTML) element without children
    function el(string memory _tag, string memory _props)
        internal
        pure
        returns (string memory)
    {
        return string.concat("<", _tag, " ", _props, "/>");
    }

    // an SVG attribute
    function prop(string memory _key, string memory _val)
        internal
        pure
        returns (string memory)
    {
        return string.concat(_key, "=", '"', _val, '" ');
    }

    // converts an unsigned integer to a string
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Utils {
    // TODO: document
    function splitNumber(uint256 number_)
        internal
        pure
        returns (uint8[7] memory)
    {
        uint8[7] memory numbers;

        for (uint256 i = 0; i < numbers.length; i++) {
            numbers[i] = uint8(number_ % 10);
            number_ /= 10;
        }

        return numbers;
    }

    // TODO: doc
    function bytes12ToString(bytes12 bytes12_)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 12 && bytes12_[i] != 0) {
            i++;
        }

        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 12 && bytes12_[i] != 0; i++) {
            bytesArray[i] = bytes12_[i];
        }

        return string(bytesArray);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./LzApp.sol";

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint64 => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        // try-catch all errors/exceptions
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual {
        // only internal transaction
        require(_msgSender() == address(this), "LzReceiver: caller must be LzApp");
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) public payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), "LzReceiver: no stored message");
        require(keccak256(_payload) == payloadHash, "LzReceiver: invalid payload");
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/ILayerZeroReceiver.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint public immutable lzEndpoint;

    mapping(uint16 => bytes) public trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint));

        bytes memory trustedRemote = trustedRemoteLookup[_srcChainId];
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemote.length && keccak256(_srcAddress) == keccak256(trustedRemote), "LzReceiver: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParams
    ) internal virtual {
        bytes memory trustedRemote = trustedRemoteLookup[_dstChainId];
        require(trustedRemote.length != 0, "LzSend: destination chain is not a trusted source.");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemote, _payload, _refundAddress, _zroPaymentAddress, _adapterParams);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return lzEndpoint.getConfig(_version, _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
}