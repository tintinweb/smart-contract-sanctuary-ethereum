// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**************************************
 *
 *             .-'||'-.
 *           .'   ||   '.
 *          /   __||__   \
 *          | /`-    -`\ |
 *          | | 6    6 | |
 *          \/\____7___/\/
 *  .--------:\:I:II:I:/;--------.
 * /          \`:I::I:`/          \
 *|            `------'            |
 *|             \____/             |
 *|      ,     __   _____   ,      |
 *|======|    / /  /  _  \  |======|
 *|======|   / /__ \ <_> /  |======|
 *|~~~~~|   | <_> \/ <_> \   |~~~~~|
 *|     |\   \____/\_____/  /|     |
 * \    \|                  |/    /
 * `\    \  _ _.-=""=-._ _  /    /'
 *   `\   '`_)\\-++++-//(_`'   /'
 *     ;   (__||      ||__)   ;
 *      ;   ___\      /___   ;
 *       '. ---/-=..=-\--- .'
 *         `""`        `""`
 * ------------------------------------
 *
 * On-Chain Fantasy
 * https://onchainfantasy.xyz
 *
 * Developed By: Absolabs.xyz / @sbmitchell.eth
 *
 **************************************************/

import "@openzeppelin/contracts/access/Ownable.sol";
import "base64-sol/base64.sol";
import "./ERC721PsiRandomSeedRevealBurnable.sol";
import "./OnChainFantasyRenderer.sol";

contract OnChainFantasy is ERC721PsiRandomSeedRevealBurnable, Ownable {
    using OnChainFantasyRenderer for *;

    bytes32 public constant REROLL_EVENT = keccak256("REROLL_EVENT");
    bytes32 public constant MINT_EVENT = keccak256("MINT_EVENT");

    // Chainlink
    bytes32 public immutable keyHash;
    uint64 public immutable subscriptionId;

    string constant NAME = "On-Chain Fantasy";
    string constant SYMBOL = "OCF";
    uint256 public publicPriceInWei = 0.001 ether;
    uint256 public reRollPriceInWei = 0.001 ether;
    uint256 public maxPerTransaction = 21;

    address public treasury =
        payable(0x593b94c059f37f1AF542c25A0F4B22Cd2695Fb68);
    uint256 public maxSupply = 5555;
    uint256 private mintNonce = 0;
    string public animationURI = "";
    bool public isReRollActive = false;
    bool public isMintPaused = true;

    string[] public teams = [
        "ARZ",
        "ATL",
        "BAL",
        "BUF",
        "CAR",
        "CHI",
        "CIN",
        "CLE",
        "DAL",
        "DEN",
        "DET",
        "GB",
        "HOU",
        "IND",
        "JAX",
        "JKR",
        "KC",
        "LV",
        "LAC",
        "LAR",
        "MIA",
        "MIN",
        "NE",
        "NO",
        "NYG",
        "NYJ",
        "PHI",
        "PIT",
        "SF",
        "SEA",
        "TB",
        "TEN",
        "WAS"
    ];

    /// @notice event emitted when card is re-rolled
    event ReRoll(uint256 indexed tokenId, uint256 indexed seed);

    constructor(
        address _vrfV2Coordinator,
        bytes32 keyHash_,
        uint64 subscriptionId_
    )
        ERC721Psi(NAME, SYMBOL)
        ERC721PsiRandomSeedReveal(_vrfV2Coordinator, 200000, 3)
    {
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
    }

    /**
     * @notice Sets public price in wei
     * @dev only owner call this function
     * @param _publicPriceInWei The new public price in wei
     */
    function setPublicPriceInWei(uint256 _publicPriceInWei) public onlyOwner {
        publicPriceInWei = _publicPriceInWei;
    }

    /**
     * @notice Sets re-roll price in wei
     * @dev only owner call this function
     * @param _reRollPriceInWei The new re-roll price in wei
     */
    function setReRollPriceInWei(uint256 _reRollPriceInWei) public onlyOwner {
        reRollPriceInWei = _reRollPriceInWei;
    }

    /**
     * @notice Sets max per transaction
     * @dev only owner call this function
     * @param _maxPerTransaction The new max transactions
     */
    function setsMaxPerTransaction(uint256 _maxPerTransaction)
        public
        onlyOwner
    {
        maxPerTransaction = _maxPerTransaction;
    }

    /**
     * @notice Sets teams THIS WILL RE-ESTABLISH THE RENDERER
     * @dev only owner call this function
     * @param _teams The new array of team strings
     */
    function setTeams(string[] memory _teams) public onlyOwner {
        teams = _teams;
    }

    /**
     * @notice Sets animation URI
     * @dev only owner call this function
     * @param _animationURI The new animation uri for interactive display purposes
     */
    function setAnimationURI(string memory _animationURI) public onlyOwner {
        animationURI = _animationURI;
    }

    /**
     * @notice Sets whether or not re-rolling is active
     * @dev only owner call this function
     * @param _isReRollActive The new price in wei
     */
    function setIsReRollActive(bool _isReRollActive) public onlyOwner {
        isReRollActive = _isReRollActive;
    }

    /**
     * @notice Sets whether or not the mint is paused
     * @dev only owner call this function
     * @param _isMintPaused The new price in wei
     */
    function setIsMintPaused(bool _isMintPaused) public onlyOwner {
        isMintPaused = _isMintPaused;
    }

    /**
     * @notice Sets the treasury recipient
     * @dev only owner call this function
     * @param _treasury The new price in wei
     */
    function setTreasury(address _treasury) public onlyOwner {
        treasury = payable(_treasury);
    }

    /**
     * @notice Sets max supply for the collection
     * @dev only owner call this function
     * @param _maxSupply The new max supply value
     */
    function setMaxSupply(uint256 _maxSupply) external onlyOwner {
        maxSupply = _maxSupply;
    }

    /**
     * @notice Reveal called by the governanace to reveal the seed of the NFT
     */
    function reveal() external onlyOwner {
        _reveal();
    }

    /**
     * @notice Public mint
     * @param quantity The number of mints
     */
    function mint(uint256 quantity, bytes memory _data) public payable {
        require(!isMintPaused, "Minting paused.");
        require(totalSupply() + quantity < maxSupply, "Excedes supply.");
        require(quantity < maxPerTransaction, "Exceeds max per tx.");
        require(quantity * publicPriceInWei == msg.value, "Invalid funds.");
        _safeMint(msg.sender, quantity, _data);
    }

    /**
     * @notice Re-roll for token owner
     * @param tokenId tokenId to re-roll
     */
    function reroll(uint256 tokenId) public payable {
        require(isReRollActive, "Re-roll not active.");
        require(!_exists(tokenId), "Token already minted.");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Not approved.");
        require(reRollPriceInWei >= msg.value, "Invalid funds.");
    }

    /**
     * @notice Withdraw from contract
     */
    function withdraw() public onlyOwner {
        (bool success, ) = treasury.call{value: address(this).balance}("");
        require(success, "Failed to send to treasury.");
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        require(_exists(tokenId), "Token does not exist.");
        return
            OnChainFantasyRenderer.base64TokenURI(
                animationURI,
                tokenId,
                seed(tokenId),
                teams
            );
    }

    function walletOfOwner(address _owner)
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);
        uint256[] memory tokensId = new uint256[](tokenCount);
        for (uint256 i; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function isOwnerOf(address account, uint256[] calldata _tokenIds)
        external
        view
        returns (bool)
    {
        for (uint256 i; i < _tokenIds.length; ++i) {
            if (_owners[_tokenIds[i]] != account) return false;
        }

        return true;
    }

    function _keyHash() internal view override returns (bytes32) {
        return keyHash;
    }

    function _subscriptionId() internal view override returns (uint64) {
        return subscriptionId;
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

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */
pragma solidity ^0.8.0;

import "./BitMaps.sol";
import "./ERC721PsiRandomSeedReveal.sol";

abstract contract ERC721PsiRandomSeedRevealBurnable is
    ERC721PsiRandomSeedReveal
{
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _burnedToken;

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
        address from = ownerOf(tokenId);
        _beforeTokenTransfers(from, address(0), tokenId, 1);
        _burnedToken.set(tokenId);
        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId)
        internal
        view
        virtual
        override
        returns (bool)
    {
        if (_burnedToken.get(tokenId)) {
            return false;
        }
        return super._exists(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted - _burned();
    }

    /**
     * @dev Returns number of token burned.
     */
    function _burned() internal view returns (uint256 burned) {
        uint256 totalBucket = (_minted >> 8) + 1;

        for (uint256 i = 0; i < totalBucket; i++) {
            uint256 bucket = _burnedToken.getBucket(i);
            burned += _popcount(bucket);
        }
    }

    /**
     * @dev Returns number of set bits.
     */
    function _popcount(uint256 x) private pure returns (uint256 count) {
        unchecked {
            for (count = 0; x != 0; count++) x &= x - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

/**************************************************
 *
 * On-Chain Fantasy
 * https://onchainfantasy.xyz
 * Developed By: @sbmitchell.eth
 *
 **************************************************/

import "@openzeppelin/contracts/utils/Strings.sol";
import "base64-sol/base64.sol";

library OnChainFantasyRenderer {
    struct Traits {
        string qb1;
        string qb2;
        string rb1;
        string rb2;
        string rb3;
        string rb4;
        string wr1;
        string wr2;
        string wr3;
        string wr4;
        string wr5;
        string te1;
        string te2;
        string def1;
        string def2;
    }

    struct Card {
        string name;
        string description;
        Traits trait;
    }

    function toJSONProperty(string memory key, string memory value)
        public
        pure
        returns (string memory)
    {
        return string(abi.encodePacked('"', key, '" : "', value, '"'));
    }

    function shuffle(uint256 size, uint256 entropy)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory result = new uint256[](size);

        // Initialize array.
        for (uint256 i = 0; i < size; i++) {
            result[i] = i + 1;
        }

        // Set the initial randomness based on the provided entropy.
        bytes32 random = keccak256(abi.encodePacked(entropy));

        // Set the last item of the array which will be swapped.
        uint256 last_item = size - 1;

        // We need to do `size - 1` iterations to completely shuffle the array.
        for (uint256 i = 1; i < size - 1; i++) {
            // Select a number based on the randomness.
            uint256 selected_item = uint256(random) % last_item;

            // Swap items `selected_item <> last_item`.
            uint256 aux = result[last_item];
            result[last_item] = result[selected_item];
            result[selected_item] = aux;

            // Decrease the size of the possible shuffle
            // to preserve the already shuffled items.
            // The already shuffled items are at the end of the array.
            last_item--;

            // Generate new randomness.
            random = keccak256(abi.encodePacked(random));
        }

        return result;
    }

    function getProperties(
        uint256 tokenId,
        uint256 seed,
        string[] memory teams
    ) internal view returns (Card memory) {
        Traits memory trait;

        uint256[] memory shuffledTeams = shuffle(teams.length, seed);

        uint256 qbIndex = uint256(
            keccak256(abi.encode(seed, keccak256("quarterback")))
        );

        trait.qb1 = teams[shuffledTeams[(qbIndex % teams.length) - 1]];
        trait.qb2 = teams[shuffledTeams[((qbIndex + 1) % teams.length) - 1]];

        uint256 rbIndex = uint256(
            keccak256(abi.encode(seed, keccak256("runningback")))
        );

        trait.rb1 = teams[shuffledTeams[(rbIndex % teams.length) - 1]];
        trait.rb2 = teams[shuffledTeams[((rbIndex + 1) % teams.length) - 1]];
        trait.rb3 = teams[shuffledTeams[((rbIndex + 2) % teams.length) - 1]];
        trait.rb4 = teams[shuffledTeams[((rbIndex + 3) % teams.length) - 1]];

        uint256 wrIndex = uint256(
            keccak256(abi.encode(seed, keccak256("widereceiver")))
        );

        trait.wr1 = teams[shuffledTeams[(wrIndex % teams.length) - 1]];
        trait.wr2 = teams[shuffledTeams[((wrIndex + 1) % teams.length) - 1]];
        trait.wr3 = teams[shuffledTeams[((wrIndex + 2) % teams.length) - 1]];
        trait.wr4 = teams[shuffledTeams[((wrIndex + 3) % teams.length) - 1]];
        trait.wr5 = teams[shuffledTeams[((wrIndex + 4) % teams.length) - 1]];

        uint256 teIndex = uint256(
            keccak256(abi.encode(seed, keccak256("tightend")))
        );

        trait.te1 = teams[shuffledTeams[(teIndex % teams.length) - 1]];
        trait.te2 = teams[shuffledTeams[((teIndex + 1) % teams.length) - 1]];

        uint256 defIndex = uint256(
            keccak256(abi.encode(seed, keccak256("defense")))
        );

        trait.def1 = teams[shuffledTeams[(defIndex % teams.length) - 1]];
        trait.def2 = teams[shuffledTeams[((defIndex + 1) % teams.length) - 1]];

        return
            Card({
                name: string(
                    abi.encodePacked("Card #", Strings.toString(tokenId))
                ),
                description: "The best on-chain fantasy football game and payout system.",
                trait: trait
            });
    }

    function toProperties(Card memory instance)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    string(
                        abi.encodePacked(
                            '{ "trait_type": "QB", "value": "',
                            instance.trait.qb1,
                            '"}',
                            ', { "trait_type": "QB", "value": "',
                            instance.trait.qb2,
                            '"}'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            ', { "trait_type": "RB", "value": "',
                            instance.trait.rb1,
                            '"}',
                            ', { "trait_type": "RB", "value": "',
                            instance.trait.rb2,
                            '"}',
                            ', { "trait_type": "RB", "value": "',
                            instance.trait.rb3,
                            '"}',
                            ', { "trait_type": "RB", "value": "',
                            instance.trait.rb4,
                            '"}'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            ', { "trait_type": "WR", "value": "',
                            instance.trait.wr1,
                            '"}',
                            ', { "trait_type": "WR", "value": "',
                            instance.trait.wr2,
                            '"}',
                            ', { "trait_type": "WR", "value": "',
                            instance.trait.wr3,
                            '"}',
                            ', { "trait_type": "WR", "value": "',
                            instance.trait.wr4,
                            '"}',
                            ', { "trait_type": "WR", "value": "',
                            instance.trait.wr5,
                            '"}'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            ', { "trait_type": "TE", "value": "',
                            instance.trait.te1,
                            '"}',
                            ', { "trait_type": "TE", "value": "',
                            instance.trait.te2,
                            '"}'
                        )
                    ),
                    string(
                        abi.encodePacked(
                            ', { "trait_type": "DEF", "value": "',
                            instance.trait.def1,
                            '"}',
                            ', { "trait_type": "DEF", "value": "',
                            instance.trait.def2,
                            '"}'
                        )
                    )
                )
            );
    }

    function generateSVG(uint256 tokenId, Card memory instance)
        public
        pure
        returns (string memory)
    {
        string memory svg = string(
            abi.encodePacked(
                "<svg viewBox='0 0 250 350' width='250' height='350' xmlns='http://www.w3.org/2000/svg'>",
                // Defs
                string(
                    abi.encodePacked(
                        "<defs>",
                        "<linearGradient gradientUnits='userSpaceOnUse' x1='126.51' y1='1.542' x2='126.51' y2='351.542' id='gradient-0'>",
                        "<stop offset='0' style='stop-color: rgba(35, 56, 78, 1)'/>",
                        "<stop offset='1' style='stop-color: rgba(3, 6, 8, 1)'/>",
                        "</linearGradient>",
                        "</defs>"
                    )
                ),
                "<rect x='1.51' y='1.542' width='250' height='350' style='fill-rule: nonzero; paint-order: fill; stroke-width: 4px; stroke-miterlimit: 1; fill: url(#gradient-0); stroke: rgb(15, 16, 18);'/>",
                "<text style='fill: rgb(207, 216, 228); font-family: Bangers; font-size: 20px; letter-spacing: 0.5px; stroke-width: 14.5183px; text-transform: uppercase; word-spacing: 4px; white-space: pre; text-decoration: underline overline solid rgba(0, 0, 0, 0.8);' transform='matrix(1.479633, 0, 0, 1, -227.664429, -52.744549)' x='170.021' y='85.711'>On-Chain Fantasy</text>",
                // QBs
                string(
                    abi.encodePacked(
                        "<text style='fill: rgb(241, 141, 141); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.015' y='111.989'>",
                        instance.trait.qb1,
                        "</text>",
                        "<text style='fill: rgb(241, 141, 141); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='221.392' y='132.243'>",
                        instance.trait.qb2,
                        "</text>"
                    )
                ),
                // RBs
                string(
                    abi.encodePacked(
                        "<text style='fill: rgb(135, 223, 165); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.336' y='153.43'>",
                        instance.trait.rb1,
                        "</text>",
                        "<text style='fill: rgb(135, 223, 165); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.335' y='172.062'>",
                        instance.trait.rb2,
                        "</text>",
                        "<text style='fill: rgb(135, 223, 165); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.506' y='190.45'>",
                        instance.trait.rb3,
                        "</text>",
                        "<text style='fill: rgb(135, 223, 165); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.505' y='209.082'>",
                        instance.trait.rb4,
                        "</text>"
                    )
                ),
                // WRs
                string(
                    abi.encodePacked(
                        "<text style='fill: rgb(151, 186, 235); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.421' y='229.579'>",
                        instance.trait.wr1,
                        "</text>",
                        "<text style='fill: rgb(151, 186, 235); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.42' y='248.211'>",
                        instance.trait.wr2,
                        "</text>",
                        "<text style='fill: rgb(151, 186, 235); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.591' y='266.599'>",
                        instance.trait.wr3,
                        "</text>",
                        "<text style='fill: rgb(151, 186, 235); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.59' y='287.231'>",
                        instance.trait.wr4,
                        "</text>",
                        "<text style='fill: rgb(151, 186, 235); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -236.217606, -52.031784)' x='222.184' y='308.065'>",
                        instance.trait.wr5,
                        "</text>"
                    )
                ),
                // TEs
                string(
                    abi.encodePacked(
                        "<text style='fill: rgb(231, 161, 63); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -237.217606, -52.031784)' x='223.156' y='330.055'>",
                        instance.trait.te1,
                        "</text>",
                        "<text style='fill: rgb(231, 161, 63); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -237.217606, -52.031784)' x='223.155' y='349.687'>",
                        instance.trait.te2,
                        "</text>"
                    )
                ),
                // DEFs
                string(
                    abi.encodePacked(
                        "<text style='fill: rgb(185, 50, 50); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -237.217606, -52.031784)' x='223.156' y='369.234'>",
                        instance.trait.def1,
                        "</text>",
                        "<text style='fill: rgb(185, 50, 50); font-family: Bangers; font-size: 14.4px; letter-spacing: 0.5px; stroke-width: 12px; text-transform: uppercase; word-spacing: 1.3px; white-space: pre;' transform='matrix(1.479633, 0, 0, 1, -237.217606, -52.031784)' x='222.533' y='388.866'>",
                        instance.trait.def2,
                        "</text>"
                    )
                ),
                "</svg>"
            )
        );

        return svg;
    }

    function base64TokenURI(
        string memory _animationURI,
        uint256 _tokenId,
        uint256 _seed,
        string[] memory _teams
    ) public view returns (string memory) {
        Card memory instance = getProperties(_tokenId, _seed, _teams);
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                "{",
                                toJSONProperty("name", instance.name),
                                ",",
                                toJSONProperty(
                                    "description",
                                    instance.description
                                ),
                                ",",
                                string(
                                    abi.encodePacked(
                                        '"attributes": ',
                                        string(
                                            abi.encodePacked(
                                                "[",
                                                string(
                                                    abi.encodePacked(
                                                        toProperties(instance)
                                                    )
                                                ),
                                                "]"
                                            )
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "image",
                                    generateSVG(_tokenId, instance)
                                ),
                                ",",
                                toJSONProperty(
                                    "external_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(_tokenId)
                                        )
                                    )
                                ),
                                ",",
                                toJSONProperty(
                                    "animation_url",
                                    string(
                                        abi.encodePacked(
                                            _animationURI,
                                            Strings.toString(_tokenId)
                                        )
                                    )
                                ),
                                "}"
                            )
                        )
                    )
                )
            );
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
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */
pragma solidity ^0.8.0;

import "./BitScan.sol";

/**
 * @dev This Library is a modified version of Openzeppelin's BitMaps library.
 * Functions of finding the index of the closest set bit from a given index are added.
 * The indexing of each bucket is modifed to count from the MSB to the LSB instead of from the LSB to the MSB.
 * The modification of indexing makes finding the closest previous set bit more efficient in gas usage.
 */

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largelly inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */

library BitMaps {
    using BitScan for uint256;
    uint256 private constant MASK_INDEX_ZERO = (1 << 255);
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (bool)
    {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = MASK_INDEX_ZERO >> (index & 0xff);
        bitmap._data[bucket] &= ~mask;
    }

    /**
     * @dev Find the closest index of the set bit before `index`.
     */
    function scanForward(BitMap storage bitmap, uint256 index)
        internal
        view
        returns (uint256)
    {
        uint256 bucket = index >> 8;
        uint256 bucketIndex = (index & 0xff);
        uint256 offset = 0xff ^ bucketIndex;
        uint256 bb = bitmap._data[bucket];
        bb = bb >> offset;
        if (bb > 0) {
            unchecked {
                return (bucket << 8) | (bucketIndex - bb.bitScanForward256());
            }
        } else {
            require(
                bucket > 0,
                "BitMaps: The set bit before the index doesn't exist."
            );
            unchecked {
                bucket--;
                bucketIndex = 255;
                offset = 0;
            }
            while (true) {
                bb = bitmap._data[bucket];
                if (bb > 0) {
                    unchecked {
                        return
                            (bucket << 8) |
                            (bucketIndex - bb.bitScanForward256());
                    }
                } else {
                    require(
                        bucket > 0,
                        "BitMaps: The set bit before the index doesn't exist."
                    );
                    unchecked {
                        bucket--;
                    }
                }
            }
        }
    }

    function getBucket(BitMap storage bitmap, uint256 bucket)
        internal
        view
        returns (uint256)
    {
        return bitmap._data[bucket];
    }
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|
 */
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./interfaces/IERC721RandomSeed.sol";
import "./BitMaps.sol";
import "./ERC721PsiBatchMetaData.sol";

abstract contract ERC721PsiRandomSeedReveal is
    IERC721RandomSeed,
    ERC721PsiBatchMetaData,
    VRFConsumerBaseV2
{
    // Chainklink VRF V2
    VRFCoordinatorV2Interface immutable COORDINATOR;
    uint32 immutable callbackGasLimit;
    uint16 immutable requestConfirmations;
    uint16 constant numWords = 1;

    // requestId => genId
    mapping(uint256 => uint256) private requestIdToGenId;

    // genId => seed
    mapping(uint256 => uint256) private genSeed;

    // batchHeadTokenId => genId
    mapping(uint256 => uint256) private _batchHeadtokenGen;

    // current genId for minting
    uint256 private currentGen;

    event RandomnessRequest(uint256 requestId);

    constructor(
        address coordinator,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(coordinator) {
        COORDINATOR = VRFCoordinatorV2Interface(coordinator);
        callbackGasLimit = _callbackGasLimit;
        requestConfirmations = _requestConfirmations;
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 randomness = randomWords[0];
        uint256 genId = requestIdToGenId[requestId];
        delete requestIdToGenId[genId];
        genSeed[genId] = randomness;
        _processRandomnessFulfillment(requestId, genId, randomness);
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        uint256 tokenIdHead = _minted;
        _batchHeadtokenGen[tokenIdHead] = currentGen;
        super._safeMint(to, quantity, _data);
    }

    /**
        @dev Query the generation of `tokenId`.
     */
    function _tokenGen(uint256 tokenId) internal view returns (uint256) {
        require(
            _exists(tokenId),
            "ERC721PsiRandomSeedReveal: generation query for nonexistent token"
        );
        return _batchHeadtokenGen[_getMetaDataBatchHead(tokenId)];
    }

    /**
        @dev Request the randomess for the tokens of the current generation.
     */
    function _reveal() internal virtual {
        uint256 requestId = COORDINATOR.requestRandomWords(
            _keyHash(),
            _subscriptionId(),
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        emit RandomnessRequest(requestId);
        requestIdToGenId[requestId] = currentGen;
        _processRandomnessRequest(requestId, currentGen);
        currentGen++;
    }

    /**
        @dev Return the random seed of `tokenId`.
        Revert when the randomness hasn't been fulfilled.
     */
    function seed(uint256 tokenId)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            _exists(tokenId),
            "ERC721PsiRandomSeedReveal: seed query for nonexistent token"
        );

        unchecked {
            uint256 _genSeed = genSeed[_tokenGen(tokenId)];
            require(
                _genSeed != 0,
                "ERC721PsiRandomSeedReveal: Randomness hasn't been fullfilled"
            );
            return uint256(keccak256(abi.encode(_genSeed, tokenId)));
        }
    }

    /** 
        @dev Override the function to provide the corrosponding keyHash for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/vrf-contracts/
     */
    function _keyHash() internal virtual returns (bytes32);

    /** 
        @dev Override the function to provide the corrosponding subscription id for the Chainlink VRF V2.

        see also: https://docs.chain.link/docs/get-a-random-number/#create-and-fund-a-subscription
     */
    function _subscriptionId() internal virtual returns (uint64);

    function _processRandomnessRequest(uint256 requestId, uint256 genId)
        internal
    {}

    function _processRandomnessFulfillment(
        uint256 requestId,
        uint256 genId,
        uint256 randomness
    ) internal {}
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */

pragma solidity ^0.8.0;

library BitScan {
    uint256 private constant DEBRUIJN_256 =
        0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff;
    bytes private constant LOOKUP_TABLE_256 =
        hex"0001020903110a19042112290b311a3905412245134d2a550c5d32651b6d3a7506264262237d468514804e8d2b95569d0d495ea533a966b11c886eb93bc176c9071727374353637324837e9b47af86c7155181ad4fd18ed32c9096db57d59ee30e2e4a6a5f92a6be3498aae067ddb2eb1d5989b56fd7baf33ca0c2ee77e5caf7ff0810182028303840444c545c646c7425617c847f8c949c48a4a8b087b8c0c816365272829aaec650acd0d28fdad4e22d6991bd97dfdcea58b4d6f29fede4f6fe0f1f2f3f4b5b6b607b8b93a3a7b7bf357199c5abcfd9e168bcdee9b3f1ecf5fd1e3e5a7a8aa2b670c4ced8bbe8f0f4fc3d79a1c3cde7effb78cce6facbf9f8";

    function isolateLSB256(uint256 bb) internal pure returns (uint256) {
        require(bb > 0);
        unchecked {
            return bb & (0 - bb);
        }
    }

    function isolateMSB256(uint256 bb) internal pure returns (uint256) {
        require(bb > 0);
        unchecked {
            bb |= bb >> 256;
            bb |= bb >> 128;
            bb |= bb >> 64;
            bb |= bb >> 32;
            bb |= bb >> 16;
            bb |= bb >> 8;
            bb |= bb >> 4;
            bb |= bb >> 2;
            bb |= bb >> 1;

            return (bb >> 1) + 1;
        }
    }

    function bitScanForward256(uint256 bb) internal pure returns (uint8) {
        unchecked {
            return
                uint8(
                    LOOKUP_TABLE_256[(isolateLSB256(bb) * DEBRUIJN_256) >> 248]
                );
        }
    }

    function bitScanReverse256(uint256 bb) internal pure returns (uint8) {
        unchecked {
            return
                255 -
                uint8(
                    LOOKUP_TABLE_256[
                        ((isolateMSB256(bb) * DEBRUIJN_256) >> 248)
                    ]
                );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC721RandomSeed {
    function seed(uint256 tokenId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _ 
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/ 
 | |____| | \ \| |____  / /   / /_ | |  | |   
 |______|_|  \_\\_____|/_/   |____||_|  |_|   
                                              
                                            
 */

pragma solidity ^0.8.0;

import "./ERC721Psi.sol";
import "./BitMaps.sol";

abstract contract ERC721PsiBatchMetaData is ERC721Psi {
    using BitMaps for BitMaps.BitMap;
    BitMaps.BitMap private _metaDataBatchHead;

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual override {
        uint256 tokenIdBatchHead = _minted;
        _metaDataBatchHead.set(tokenIdBatchHead);
        super._safeMint(to, quantity, _data);
    }

    /**
     *  @dev Return the batch head tokenId where the on-chain metadata is stored during minting.
     *
     *  The returned tokenId will remain the same after the token transfer.
     */
    function _getMetaDataBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdMetaDataBatchHead)
    {
        tokenIdMetaDataBatchHead = _metaDataBatchHead.scanForward(tokenId);
    }
}

// SPDX-License-Identifier: MIT
/**
  ______ _____   _____ ______ ___  __ _  _  _
 |  ____|  __ \ / ____|____  |__ \/_ | || || |
 | |__  | |__) | |        / /   ) || | \| |/ |
 |  __| |  _  /| |       / /   / / | |\_   _/
 | |____| | \ \| |____  / /   / /_ | |  | |
 |______|_|  \_\\_____|/_/   |____||_|  |_|


 */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./BitMaps.sol";
import "./Address.sol";

contract ERC721Psi is
    Context,
    ERC165,
    IERC721,
    IERC721Metadata,
    IERC721Enumerable
{
    using Address for address;
    using Strings for uint256;
    using BitMaps for BitMaps.BitMap;

    BitMaps.BitMap private _batchHead;

    string private _name;
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) internal _owners;
    uint256 internal _minted;

    mapping(uint256 => address) private _tokenApprovals;
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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            owner != address(0),
            "ERC721Psi: balance query for the zero address"
        );

        uint256 count;
        for (uint256 i; i < _minted; ++i) {
            if (_exists(i)) {
                if (owner == ownerOf(i)) {
                    ++count;
                }
            }
        }
        return count;
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );
        return owner;
    }

    function _ownerAndBatchHeadOf(uint256 tokenId)
        internal
        view
        returns (address owner, uint256 tokenIdBatchHead)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: owner query for nonexistent token"
        );
        tokenIdBatchHead = _getBatchHead(tokenId);
        owner = _owners[tokenIdBatchHead];
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
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "ERC721Psi: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString()))
                : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721Psi: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721Psi: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId)
        public
        view
        virtual
        override
        returns (address)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: approved query for nonexistent token"
        );

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(operator != _msgSender(), "ERC721Psi: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
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
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Psi: transfer caller is not owner nor approved"
        );

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
        bytes memory _data
    ) public virtual override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721Psi: transfer caller is not owner nor approved"
        );
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(
            _checkOnERC721Received(from, to, tokenId, _data),
            "ERC721Psi: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return tokenId < _minted;
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId)
        internal
        view
        virtual
        returns (bool)
    {
        require(
            _exists(tokenId),
            "ERC721Psi: operator query for nonexistent token"
        );
        address owner = ownerOf(tokenId);
        return (spender == owner ||
            getApproved(tokenId) == spender ||
            isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, "");
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        uint256 tokenIdBatchHead = _minted;

        require(quantity > 0, "ERC721Psi: quantity must be greater 0");
        require(to != address(0), "ERC721Psi: mint to the zero address");

        _beforeTokenTransfers(address(0), to, tokenIdBatchHead, quantity);
        for (uint256 i = 0; i < quantity; i++) {
            uint256 tokenId = tokenIdBatchHead + i;
            emit Transfer(address(0), to, tokenId);
            require(
                _checkOnERC721Received(address(0), to, tokenId, _data),
                "ERC721Psi: transfer to non ERC721Receiver implementer"
            );
        }

        _owners[tokenIdBatchHead] = to;
        _batchHead.set(tokenIdBatchHead);
        _minted += quantity;

        _afterTokenTransfers(address(0), to, tokenIdBatchHead, quantity);
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
        (address owner, uint256 tokenIdBatchHead) = _ownerAndBatchHeadOf(
            tokenId
        );

        require(owner == from, "ERC721Psi: transfer of token that is not own");
        require(to != address(0), "ERC721Psi: transfer to the zero address");

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        uint256 nextTokenId = tokenId + 1;

        if (!_batchHead.get(nextTokenId) && nextTokenId < _minted) {
            _owners[nextTokenId] = from;
            _batchHead.set(nextTokenId);
        }

        _owners[tokenId] = to;
        if (tokenId != tokenIdBatchHead) {
            _batchHead.set(tokenId);
        }

        emit Transfer(from, to, tokenId);

        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try
                IERC721Receiver(to).onERC721Received(
                    _msgSender(),
                    from,
                    tokenId,
                    _data
                )
            returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert(
                        "ERC721Psi: transfer to non ERC721Receiver implementer"
                    );
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    function _getBatchHead(uint256 tokenId)
        internal
        view
        returns (uint256 tokenIdBatchHead)
    {
        tokenIdBatchHead = _batchHead.scanForward(tokenId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _minted;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(index < totalSupply(), "ERC721Psi: global index out of bounds");

        uint256 count;
        for (uint256 i; i < _minted; i++) {
            if (_exists(i)) {
                if (count == index) return i;
                else count++;
            }
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        uint256 count;
        for (uint256 i; i < _minted; i++) {
            if (_exists(i) && owner == ownerOf(i)) {
                if (count == index) return i;
                else count++;
            }
        }

        revert("ERC721Psi: owner index out of bounds");
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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