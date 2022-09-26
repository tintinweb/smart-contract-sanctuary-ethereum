// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./ERC721ABurnable.sol";
import "./ERC721AQueryable.sol";
import "./ECDSA.sol";
import "./LibString.sol";

contract Testoxxed is ERC721A, ERC721ABurnable, ERC721AQueryable, Ownable {
    using ECDSA for bytes32;
    /**
     * @dev Mapping of `_mintedKey(minter, wlRound)` to number of
     * tokens minted for the whitelist sale.
     */
    mapping(uint256 => uint256) internal _wlMinted;

    /**
     * @dev Mapping of `_mintedKey(minter, imageId)` to the number minted.
     */
    mapping(uint256 => uint256) internal _imageIdsMinted;

    /**
     * @dev The base URI, in the format of "ipfs://<CID>/{id}.json",
     * where "{id}" is replaced with the ASCII decimal string of `tokenImageId`.
     */
    string public baseURI;

    /**
     * The salt for the signatures.
     */
    uint256 public salt;

    /**
     * @dev The signer for the signatures.
     */
    address public signer;

    /**
     * @dev The max amount of tokens that can be minted.
     */
    uint32 public maxSupply;

    /**
     * @dev The current whitelist's round.
     */
    uint24 public wlRound;

    /**
     * @dev The amount of tokens that can be minted per address
     * for the current whitelist's round.
     */
    uint16 public wlLimit;

    /**
     * @dev The current sale state.
     * 0: sale closed.
     * 1: whitelist sale.
     * 2: public sale.
     */
    uint8 public saleState;

    /**
     * @dev The max amount of tokens that can be minted per transaction.
     */
    uint8 public maxBatchSize;

    /**
     * @dev Locks the mint forever.
     * No more tokens can be minted.
     */
    bool public mintLocked;

    constructor() ERC721A("TestoxxedCO", "TCO") {}

    /**
     * @dev Retuns the key into `_wlMinted` or `_imageIdsMinted`.
     */
    function _mintedKey(address minter, uint24 subId)
        internal
        pure
        returns (uint256 result)
    {
        assembly {
            result := or(shl(96, minter), and(subId, sub(shl(24, 1), 1)))
        }
    }

    /**
     * @dev Helper function for minting.
     */
    function _mintBatch(
        address to,
        uint256 quantity,
        uint24 imageId
    ) internal {
        unchecked {
            if (mintLocked) revert("Mint locked!");
            require(_totalMinted() + quantity <= maxSupply, "Out of stock!");

            uint256 startTokenId = _nextTokenId();
            _mint(to, quantity);

            _setExtraDataAt(startTokenId, imageId);
        }
    }

    /**
     * @dev For preserving the `imageId`.
     */
    function _extraData(
        address,
        address,
        uint24 previousExtraData
    ) internal view virtual override returns (uint24) {
        return previousExtraData;
    }

    /**
     * @dev Public mint function.
     *
     * `imageIdLimit` - maximum number of `imageId` that can be
     *     minted across all accounts.
     *
     * `imageIdMaxSupply` - maximum number of `imageId` that can be
     *     minted by each address.
     *
     * Automatically switches mode depending on whether
     * public or whitelist sale is on.
     */
    function mint(
        uint8 quantity,
        uint24 imageId,
        uint256 imageIdLimit,
        uint256 imageIdMaxSupply,
        uint256 imageIdPrice,
        bytes calldata imageIdSignature,
        bytes calldata wlSignature
    ) external payable {
        unchecked {
            require(tx.origin == msg.sender, "Minter must be EOA.");
            require(quantity <= maxBatchSize, "Exceeded tokens per mint.");
            bytes32 hash;

            if (saleState == 1) {
                // Check if whitelisted.
                hash = keccak256(abi.encode(msg.sender, salt));
                require(
                    hash.toEthSignedMessageHash().recover(wlSignature) ==
                        signer,
                    "Invalid whitelist signature."
                );
                // Check if there is whitelist mint slots,
                // and update the number of whitelist tokens minted.
                uint256 wlMintedKey = _mintedKey(msg.sender, wlRound);
                uint256 wlMinted = _wlMinted[wlMintedKey];
                wlMinted += quantity;
                require(wlMinted <= wlLimit, "Not enough whitelist slots.");
                _wlMinted[wlMintedKey] = wlMinted;
            } else if (saleState == 2) {
                // Do nothing.
            } else {
                revert("Not open.");
            }

            require(msg.value == imageIdPrice * quantity, "Wrong Ether value.");

            // Check if the `imageId`, `imageIdLimit`, `imageIdMaxSupply`, `imageIdPrice` are correct.
            hash = keccak256(
                abi.encode(
                    imageId,
                    imageIdLimit,
                    imageIdMaxSupply,
                    imageIdPrice,
                    salt
                )
            );
            require(
                hash.toEthSignedMessageHash().recover(imageIdSignature) ==
                    signer,
                "Invalid image ID signature."
            );

            // Checks and updates `_imageIdsMinted[_mintedKey(address(0), imageId)]`.
            uint256 imageIdTotalMinted = _imageIdsMinted[
                _mintedKey(address(0), imageId)
            ];
            imageIdTotalMinted += quantity;
            require(
                imageIdTotalMinted <= imageIdMaxSupply,
                "Image ID out of stock."
            );
            _imageIdsMinted[
                _mintedKey(address(0), imageId)
            ] = imageIdTotalMinted;

            // Checks and updates `_imageIdsMinted[_mintedKey(msg.sender, imageId)]`.
            uint256 imageIdNumberMinted = _imageIdsMinted[
                _mintedKey(msg.sender, imageId)
            ];
            imageIdNumberMinted += quantity;
            require(
                imageIdNumberMinted <= imageIdLimit,
                "Image ID per address exceeded."
            );
            _imageIdsMinted[
                _mintedKey(msg.sender, imageId)
            ] = imageIdNumberMinted;
        }
        _mintBatch(msg.sender, quantity, imageId);
    }

    /**
     * @dev Returns the token URI for `tokenId`.
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        uint256 imageId = uint256(explicitOwnershipOf(tokenId).extraData);
        if (bytes(baseURI).length != 0) {
            return LibString.replace(baseURI, "{id}", _toString(imageId));
        }
        revert("Base URI not set.");
    }

    /**
     * @dev Returns an array of the number minted for each of the `imageIds`.
     */
    function imageIdsMinted(uint24[] memory imageIds)
        public
        view
        returns (uint256[] memory)
    {
        unchecked {
            uint256 n = imageIds.length;
            uint256[] memory a = new uint256[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = _imageIdsMinted[imageIds[i]];
            }
            return a;
        }
    }

    /**
     * @dev Returns an array of image IDs for each of the `tokenIds`.
     */
    function imageIdsOf(uint256[] memory tokenIds)
        public
        view
        returns (uint24[] memory)
    {
        unchecked {
            uint256 n = tokenIds.length;
            uint24[] memory a = new uint24[](n);
            for (uint256 i; i != n; ++i) {
                a[i] = explicitOwnershipOf(tokenIds[i]).extraData;
            }
            return a;
        }
    }

    // -------------------------------------------------
    // Admin functions for contract owner.
    // -------------------------------------------------

    function forceMint(address[] calldata to, uint24 imageId)
        external
        onlyOwner
    {
        unchecked {
            uint256 n = to.length;
            for (uint256 i; i < n; ++i) {
                _mintBatch(to[i], 1, imageId);
            }
        }
    }

    function selfMint(uint256 quantity, uint24 imageId) external onlyOwner {
        _mintBatch(msg.sender, quantity, imageId);
    }

    function setBaseURI(string calldata value) external onlyOwner {
        baseURI = value;
    }

    function setSigner(address value) external onlyOwner {
        signer = value;
    }

    function setSalt(uint256 value) external onlyOwner {
        salt = value;
    }

    function setMaxSupply(uint32 value) external onlyOwner {
        maxSupply = value;
    }

    function setWLRound(uint24 value) external onlyOwner {
        wlRound = value;
    }

    function setWLLimit(uint16 value) external onlyOwner {
        wlLimit = value;
    }

    function setSaleState(uint8 value) external onlyOwner {
        saleState = value;
    }

    function setMaxBatchSize(uint8 value) external onlyOwner {
        maxBatchSize = value;
    }

    function lockMint() external onlyOwner {
        mintLocked = true;
    }

    function withdrawETH() external payable onlyOwner {
        uint256 amount = address(this).balance;
        payable(msg.sender).transfer(amount);
    }
}