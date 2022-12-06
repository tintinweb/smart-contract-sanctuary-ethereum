//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

interface ILinksmenRenderer {
    function tokenURI(uint256 tokenId, uint256 dna)
        external
        view
        returns (string memory);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.15;

import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";

import "lib/ERC721A/contracts/ERC721A.sol";
import "./interfaces/ILinksmenRenderer.sol";

error MintLimitReached();
error PriceTooLow();
error MaxSupplyReached();
error BatchLimitReached();
error SaleNotStarted(string expected);
error TransferFailed();
error NotOwner();
error RefundUnavailable();
error InvalidSkill();
error CantTransferWhilePlaying();
error PlayingNotAllowed();
error LengthMismatch();

/* 
 * Basic NFT implementation
   TODO: Tests, add random skill mint, 
 */

contract MVCC is ERC721A, Ownable, ReentrancyGuard {
    using ECDSA for bytes32;

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event MaxPublicMintUpdated(uint256 prevMax, uint256 newMax);
    event MaxWhitelistMintUpdated(uint256 prevMax, uint256 newMax);
    event BatchSizeUpdated(uint256 prevAmount, uint256 newAmount);
    event RenderingContractUpdated(address _renderingContract);
    event UnrevealedURIUpdated(string newURI);
    event SaleStateChanged(Period state);
    event PublicPriceUpdated(uint256 prevPrice, uint256 newPrice);
    event WhitelistPriceUpdated(uint256 prevPrice, uint256 newPrice);
    event FundsWithdrawn(address receiver);
    event Playing(uint256 tokenId);
    event StoppedPlaying(uint256 tokenId);
    event Expelled(uint256 tokenId);
    event PlayingOpenUpdated(bool prevState, bool newState);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    enum Period {
        PAUSED,
        WHITELIST,
        PUBLIC
    }

    struct TokenInfo {
        uint256 dna;
        uint120 mintedAt;
        uint120 mintPrice;
        bool refunded;
    }

    Period public saleState;

    // @note change to private in production
    address public _signerAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266; // TESTING ADDRESS
    address public renderingContract;
    address private dev;

    uint256 public price = 0.001 ether; // TESTING VALUES
    uint256 public whitelistPrice = 0.005 ether; // TESTING VALUES
    uint256 public maxSupply = 10000; // TESTING VALUES
    uint256 public publicMintLimit = 5;
    uint256 public whitelistMintLimit = 2;
    uint256 public batchLimit = 5;
    uint256 public num_layers = 6;

    uint256 public totalRefunded;
    uint256 public refundChance = 10; // 10%
    uint256 public maxRefundBasis = 1000; // 10%
    uint256 public denominator = 10000; // 100%

    mapping(uint256 => uint256) public numSkillsPerTrait;
    mapping(address => uint256) public publicMinted;
    mapping(address => uint256) public whitelistMinted;
    mapping(uint256 => TokenInfo) public tokenInfo;

    // Playing info
    bool playingOpen = true;
    mapping(uint256 => uint256) private playingStarted;
    mapping(uint256 => uint256) private playingTotal;

    /*//////////////////////////////////////////////////////////////
                                 MODIFIERS
    //////////////////////////////////////////////////////////////*/

    modifier supplyLimit(uint256 amount) {
        if (totalSupply() + amount > maxSupply) revert MaxSupplyReached();
        _;
    }

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        address newOwner,
        address _renderingContract,
        uint256[] memory skillsPerTrait
    ) ERC721A(_name, _symbol) {
        renderingContract = _renderingContract;

        for (uint256 i; i < skillsPerTrait.length; i++) {
            numSkillsPerTrait[i] = skillsPerTrait[i];
        }

        _transferOwnership(newOwner);
    }

    /*//////////////////////////////////////////////////////////////
                                 EXTERNAL
    //////////////////////////////////////////////////////////////*/

    // @audit - DOESN'T LIMIT MAX SKILL POINTS
    /*
     * @notice mint a quantity of NFTs to the caller
     * @param quantity - the amount of NFTs to mint
     */
    function mint(uint256 quantity, uint256[6][] calldata skills)
        external
        payable
        nonReentrant
        supplyLimit(quantity)
    {
        if (saleState != Period.PUBLIC) revert SaleNotStarted("public");
        if (publicMinted[msg.sender] + quantity > publicMintLimit) {
            revert MintLimitReached();
        }
        if (quantity != skills.length) revert LengthMismatch();
        if (msg.value < quantity * price) revert PriceTooLow();
        if (quantity > batchLimit) revert BatchLimitReached();

        /* Effects */
        publicMinted[msg.sender] += quantity;

        uint256 nextId = _nextTokenId();
        for (uint256 i; i < quantity; ) {
            _setTokenData(msg.sender, nextId, price, true);
            _setSkills(skills[i], nextId);

            unchecked {
                ++nextId;
                ++i;
            }
        }

        /* Interactions */
        _safeMint(msg.sender, quantity);
    }

    // @audit - DOESN'T LIMIT MAX SKILL POINTS

    /*
     * @notice mints a quantity of NFTs to the caller
     * @param _signature - bytes signature that is used to verify the user is whitelisted
     * @param quantity - the amount of NFTs to mint
     */
    function whitelistMint(
        bytes memory _signature,
        uint256 quantity,
        uint256[6][] calldata skills
    ) external payable nonReentrant supplyLimit(quantity) {
        /* Checks */
        if (saleState != Period.WHITELIST) revert SaleNotStarted("whitelist");
        if (whitelistMinted[msg.sender] + quantity > whitelistMintLimit)
            revert MintLimitReached();
        if (quantity != skills.length) revert LengthMismatch();
        if (msg.value < quantity * whitelistPrice) revert PriceTooLow();
        if (quantity > batchLimit) revert BatchLimitReached();

        bytes32 msgHash = keccak256(
            abi.encode(address(this), uint256(saleState), msg.sender)
        );

        require(
            msgHash.toEthSignedMessageHash().recover(_signature) ==
                _signerAddress,
            "INCORRECT_SIGNATURE"
        );

        /* Effects */
        whitelistMinted[msg.sender] += quantity;

        uint256 nextId = _nextTokenId();

        for (uint256 i; i < quantity; ) {
            _setTokenData(msg.sender, nextId, whitelistPrice, false);
            _setSkills(skills[i], nextId);

            unchecked {
                ++nextId;
                ++i;
            }
        }

        /* Interactions */
        _safeMint(msg.sender, quantity);
    }

    /*//////////////////////////////////////////////////////////////
                                 REFUNDS
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice refunds the mint price of the token
     * @param id - the ID of the token
     * @dev only tokens that have won a refund and claim it within 255 blocks of minting can get paid
     */
    function getRefund(uint256 id) external nonReentrant {
        if (ownerOf(id) != msg.sender) revert NotOwner();

        TokenInfo storage info = tokenInfo[id];
        uint256 hashValue = uint256(blockhash(info.mintedAt));

        if (hashValue == 0 || info.refunded) revert RefundUnavailable();
        if (totalRefunded >= (maxSupply * maxRefundBasis) / denominator) {
            revert RefundUnavailable();
        }

        if (hashValue % 100 < refundChance) {
            info.refunded = true;
            totalRefunded += 1;

            (bool success, ) = payable(msg.sender).call{value: info.mintPrice}(
                ""
            );
            require(success, "Transfer failed");
        } else {
            revert RefundUnavailable();
        }
    }

    /*
     * @notice checks if a token is eligible for a refund
     * @param id - the ID of the token
     * @returns refundAvailable - if the refund is available or not
     */
    function checkRefund(uint256 id)
        public
        view
        returns (bool refundAvailable)
    {
        TokenInfo memory info = tokenInfo[id];
        bytes32 hash = blockhash(info.mintedAt);

        if (
            !info.refunded &&
            uint256(hash) != 0 &&
            totalRefunded < (maxSupply * maxRefundBasis) / denominator
        ) {
            refundAvailable = uint256(hash) % 100 < refundChance ? true : false;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 SKILLS
    //////////////////////////////////////////////////////////////*/

    function getSkills(uint256 tokenId)
        public
        view
        returns (uint256[6] memory skills)
    {
        TokenInfo storage info = tokenInfo[tokenId];
        uint256 dna = info.dna;

        for (uint256 i; i < skills.length; ) {
            uint256 shift = 14 * num_layers + 4 * i;
            skills[i] = (dna >> shift) & 0xF;

            unchecked {
                ++i;
            }
        }
    }

    function getSkill(uint256 typeIndex, uint256 tokenId)
        public
        view
        returns (uint256 index)
    {
        TokenInfo storage info = tokenInfo[tokenId];
        uint256 dna = info.dna;

        uint256 shift = 14 * num_layers + 4 * typeIndex;
        index = (dna >> shift) & 0xF;
    }

    /*
     * @notice sets all the skills of the token
     * @param skills - an array of skill indexes
     * @param tokenId - the ID of the token
     */
    function _setSkills(uint256[6] memory skills, uint256 tokenId) internal {
        TokenInfo storage info = tokenInfo[tokenId];
        uint256 dna = info.dna;

        for (uint256 i; i < skills.length; i++) {
            dna = _setSkill(i, skills[i], dna);
        }

        info.dna = dna;
    }

    /*
     * @notice internal function to set a single skill
     * @param typeIndex - the index of the skill trait type (0 - 5)
     * @param skillIndex - the index of the skill name
     * @param tokenId - the ID of the token
     * @returns newDNA - the updated dna of the token
     */
    function _setSkill(
        uint256 typeIndex,
        uint256 skillIndex,
        uint256 dna
    ) internal view returns (uint256 newDNA) {
        if (skillIndex > numSkillsPerTrait[typeIndex]) revert InvalidSkill();

        uint256 shift = 14 * num_layers + 4 * typeIndex;
        uint256 mask = ~(0xF << shift); // shift 0b11 in position, then flip the bits to create the mask

        // zero out the position we want. Shift the value to the position. Combine the two
        newDNA = (dna & mask) | (skillIndex << shift);
    }

    /*//////////////////////////////////////////////////////////////
                                 PLAYING
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice toggles playing for multiple tokens
     * @param tokenIds - an array of token IDs
     */
    function togglePlaying(uint256[] calldata tokenIds) external {
        uint256 n = tokenIds.length;

        for (uint256 i = 0; i < n; ++i) {
            togglePlaying(tokenIds[i]);
        }
    }

    /*
     * @notice toggles playing for a single token
     * @param tokenId - the ID of the token
     */
    function togglePlaying(uint256 tokenId) internal {
        uint256 start = playingStarted[tokenId];

        if (start == 0) {
            if (!playingOpen) revert PlayingNotAllowed();

            playingStarted[tokenId] = block.timestamp;

            emit Playing(tokenId);
        } else {
            playingTotal[tokenId] += block.timestamp - start;
            playingStarted[tokenId] = 0;

            emit StoppedPlaying(tokenId);
        }
    }

    /*
     * @notice returns the playing statistics for a token ID
     * @param tokenId - the ID of the token
     * @returns playing - if the token is currently in play
     * @returns current - the amount of play time in current round
     * @returns total - the total amount of play time for the token
     */
    function playingPeriod(uint256 tokenId)
        external
        view
        returns (
            bool playing,
            uint256 current,
            uint256 total
        )
    {
        uint256 start = playingStarted[tokenId];
        if (start != 0) {
            playing = true;
            current = block.timestamp - start;
        }
        total = current + playingTotal[tokenId];
    }

    /*//////////////////////////////////////////////////////////////
                                 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @dev Override from ERC721A
     */
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        if (renderingContract == address(0)) {
            return "";
        }

        TokenInfo storage info = tokenInfo[tokenId];

        ILinksmenRenderer renderer = ILinksmenRenderer(renderingContract);

        return renderer.tokenURI(tokenId, info.dna);
    }

    /*
     * @notice stops transfers if the token is playing
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        if (from != address(0)) {
            for (uint256 i; i < quantity; i++) {
                if (playingStarted[startTokenId + i] != 0) {
                    revert CantTransferWhilePlaying();
                }
            }
        }
    }

    /*
     * @notice Returns the starting token ID
     * @dev Override from ERC721A
     */
    function _startTokenId() internal view override returns (uint256) {
        return 1;
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function _setTokenData(
        address user,
        uint256 id,
        uint256 tokenPrice,
        bool refundable
    ) internal {
        uint256 tokenDNA = uint256(
            keccak256(
                abi.encodePacked(id, user, block.difficulty, block.timestamp)
            )
        );

        tokenInfo[id] = TokenInfo({
            dna: tokenDNA,
            mintedAt: uint120(block.number),
            mintPrice: refundable ? uint120(tokenPrice) : 0,
            refunded: !refundable
        });
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    /*
     * @notice sets if playing is allowed or not
     * @param state - true or false
     */
    function setPlayingOpen(bool state) external onlyOwner {
        bool prevState = playingOpen;
        playingOpen = state;

        emit PlayingOpenUpdated(prevState, state);
    }

    /*
     * @notice expels a token from the golf course
     * @param tokenId - the token ID
     */
    function expelFromCourse(uint256 tokenId) external onlyOwner {
        require(playingStarted[tokenId] != 0, "Not playing");
        playingTotal[tokenId] += block.timestamp - playingStarted[tokenId];
        playingStarted[tokenId] = 0;

        emit StoppedPlaying(tokenId);
        emit Expelled(tokenId);
    }

    // @audit - DOESN'T HANDLE SKILLS
    /*
     * @notice mints a quantity of tokens to an address
     * @param _user - the address of the receiver
     * @param _quantity - the amount of tokens to mint
     */
    function airdrop(address _user, uint256 _quantity)
        external
        onlyOwner
        supplyLimit(_quantity)
    {
        uint256 nextId = _nextTokenId();

        for (uint256 i; i < _quantity; ) {
            uint256 tokenDNA = uint256(
                keccak256(
                    abi.encodePacked(
                        nextId,
                        _user,
                        block.difficulty,
                        block.timestamp
                    )
                )
            );

            tokenInfo[nextId] = TokenInfo({
                dna: tokenDNA,
                mintedAt: uint80(block.number),
                mintPrice: uint80(0),
                refunded: true
            });

            unchecked {
                ++nextId;
                ++i;
            }
        }

        _safeMint(_user, _quantity);
    }

    // @audit - DOESN'T HANDLE SKILLS

    /*
     * @notice mints a quantity of tokens to each user in the users array
     * @param users - array of receiver addresses
     * @param - amount of tokens to be minted to each address
     * @dev each address gets the same amount of tokens, defined by `quantity`
     */
    function airdropBatch(address[] calldata users, uint256 quantity)
        external
        onlyOwner
        supplyLimit(users.length * quantity)
    {
        for (uint256 i; i < users.length; ) {
            uint256 nextId = _nextTokenId();

            for (uint256 j; j < quantity; ) {
                uint256 tokenDNA = uint256(
                    keccak256(
                        abi.encodePacked(
                            nextId,
                            users[i],
                            block.difficulty,
                            block.timestamp
                        )
                    )
                );

                tokenInfo[nextId] = TokenInfo({
                    dna: tokenDNA,
                    mintedAt: uint80(block.number),
                    mintPrice: uint80(0),
                    refunded: true
                });

                unchecked {
                    ++nextId;
                    ++j;
                }
            }

            _safeMint(users[i], quantity);

            unchecked {
                ++i;
            }
        }
    }

    /*
     * @notice sets price per token for the public mint
     * @param _price - the price in wei
     */
    function setPublicPrice(uint256 _price) external onlyOwner {
        uint256 prevPrice = price;
        price = _price;

        emit PublicPriceUpdated(prevPrice, _price);
    }

    /*
     * @notice sets price per token for the whitelist mint
     * @param _price - the price in wei
     */
    function setWhitelistPrice(uint256 _price) external onlyOwner {
        uint256 prevPrice = whitelistPrice;
        whitelistPrice = _price;

        emit WhitelistPriceUpdated(prevPrice, _price);
    }

    /*
     * @notice sets maximum mint limit per wallet for public mint
     * @param newMax - non-zero number as the new limit
     */
    function setMaxPublicMint(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Can't be zero");
        uint256 prevMax = publicMintLimit;
        publicMintLimit = newMax;

        emit MaxPublicMintUpdated(prevMax, newMax);
    }

    /*
     * @notice sets maximum mint limit per wallet for whitelist mint
     */
    function setMaxWhitelistMint(uint256 newMax) external onlyOwner {
        require(newMax > 0, "Can't be zero");
        uint256 prevMax = whitelistMintLimit;
        whitelistMintLimit = newMax;

        emit MaxWhitelistMintUpdated(prevMax, newMax);
    }

    /*
     * @notice sets the maximum quantity that can be minted per transaction
     * @param _amount - non-zero number as the batch limit
     */
    function setBatchSize(uint256 _amount) external onlyOwner {
        require(_amount > 0, "Can't be zero");
        uint256 prevAmount = batchLimit;
        batchLimit = _amount;

        emit BatchSizeUpdated(prevAmount, _amount);
    }

    /*
     * @notice sets the signer address used for verifying WL signatures
     * @param _signer - address of the new signer
     */
    function setSignerAddress(address _signer) external onlyOwner {
        _signerAddress = _signer;
    }

    /*
     * @notice sets the baseURI that points to the metadata
     * @param baseURI_ - new URI ending in `/` (example: `ipfs://CID/`)
     */
    function setRenderingContract(address _renderingContract)
        external
        onlyOwner
    {
        renderingContract = _renderingContract;

        emit RenderingContractUpdated(_renderingContract);
    }

    /*
     * @notice sets the current sale period
     * @param _state - the Period to set
     * 0 - PAUSED
     * 1 - WHITELIST
     * 2 - PUBLIC
     */
    function setSaleState(uint256 _state) external onlyOwner {
        require(_state < 3, "Incorrect state");
        saleState = Period(_state);

        emit SaleStateChanged(Period(_state));
    }

    /*
     * @notice withdraws the contract balance to the owner and developer
     * @dev using .call to support multisigs
     */
    function withdraw() external onlyOwner nonReentrant {
        uint256 devPerc = 250;
        uint256 devShare = (address(this).balance * devPerc) / denominator;
        uint256 rest = address(this).balance - devShare;

        (bool success1, ) = payable(dev).call{value: devShare}("");
        (bool success2, ) = payable(owner()).call{value: rest}("");
        require(success1 && success2, "Withdraw failed");

        emit FundsWithdrawn(owner());
    }
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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev Interface of ERC721 token receiver.
 */
interface ERC721A__IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

/**
 * @title ERC721A
 *
 * @dev Implementation of the [ERC721](https://eips.ethereum.org/EIPS/eip-721)
 * Non-Fungible Token Standard, including the Metadata extension.
 * Optimized for lower gas during batch mints.
 *
 * Token IDs are minted in sequential order (e.g. 0, 1, 2, 3, ...)
 * starting from `_startTokenId()`.
 *
 * Assumptions:
 *
 * - An owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 * - The maximum token ID cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Reference type for token approval.
    struct TokenApprovalRef {
        address value;
    }

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    // Mask of an entry in packed address data.
    uint256 private constant _BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant _BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant _BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant _BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant _BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant _BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant _BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant _BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant _BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant _BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant _BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with {_mintERC2309}.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to {_mintERC2309}
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant _MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The `Transfer` event signature is given by:
    // `keccak256(bytes("Transfer(address,address,uint256)"))`.
    bytes32 private constant _TRANSFER_EVENT_SIGNATURE =
        0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

    // =============================================================
    //                            STORAGE
    // =============================================================

    // The next token ID to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See {_packedOwnershipOf} implementation for details.
    //
    // Bits Layout:
    // - [0..159]   `addr`
    // - [160..223] `startTimestamp`
    // - [224]      `burned`
    // - [225]      `nextInitialized`
    // - [232..255] `extraData`
    mapping(uint256 => uint256) private _packedOwnerships;

    // Mapping owner address to address data.
    //
    // Bits Layout:
    // - [0..63]    `balance`
    // - [64..127]  `numberMinted`
    // - [128..191] `numberBurned`
    // - [192..255] `aux`
    mapping(address => uint256) private _packedAddressData;

    // Mapping from token ID to approved address.
    mapping(uint256 => TokenApprovalRef) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    // =============================================================
    //                   TOKEN COUNTING OPERATIONS
    // =============================================================

    /**
     * @dev Returns the starting token ID.
     * To change the starting token ID, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Returns the next token ID to be minted.
     */
    function _nextTokenId() internal view virtual returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view virtual returns (uint256) {
        // Counter underflow is impossible as `_currentIndex` does not decrement,
        // and it is initialized to `_startTokenId()`.
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view virtual returns (uint256) {
        return _burnCounter;
    }

    // =============================================================
    //                    ADDRESS DATA OPERATIONS
    // =============================================================

    /**
     * @dev Returns the number of tokens in `owner`'s account.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_MINTED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> _BITPOS_NUMBER_BURNED) & _BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> _BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal virtual {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & _BITMASK_AUX_COMPLEMENT) | (auxCasted << _BITPOS_AUX);
        _packedAddressData[owner] = packed;
    }

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes
        // of the XOR of all function selectors in the interface.
        // See: [ERC165](https://eips.ethereum.org/EIPS/eip-165)
        // (e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`)
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

    /**
     * @dev Returns the token collection name.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, _toString(tokenId))) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, it can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    // =============================================================
    //                     OWNERSHIPS OPERATIONS
    // =============================================================

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
    }

    /**
     * @dev Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around over time.
     */
    function _ownershipOf(uint256 tokenId) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view virtual returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal virtual {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Returns the packed ownership data of `tokenId`.
     */
    function _packedOwnershipOf(uint256 tokenId) private view returns (uint256) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr)
                if (curr < _currentIndex) {
                    uint256 packed = _packedOwnerships[curr];
                    // If not burned.
                    if (packed & _BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an initialized ownership slot
                        // (i.e. `ownership.addr != address(0) && ownership.burned == false`)
                        // before an unintialized ownership slot
                        // (i.e. `ownership.addr == address(0) && ownership.burned == false`)
                        // Hence, `curr` will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed will be zero.
                        while (packed == 0) {
                            packed = _packedOwnerships[--curr];
                        }
                        return packed;
                    }
                }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> _BITPOS_START_TIMESTAMP);
        ownership.burned = packed & _BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> _BITPOS_EXTRA_DATA);
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // `owner | (block.timestamp << _BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(_BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << _BITPOS_NEXT_INITIALIZED`.
            result := shl(_BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    // =============================================================
    //                      APPROVAL OPERATIONS
    // =============================================================

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId].value = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId].value;
    }

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted. See {_mint}.
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & _BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Returns whether `msgSender` is equal to `approvedAddress` or `owner`.
     */
    function _isSenderApprovedOrOwner(
        address approvedAddress,
        address owner,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, _BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, _BITMASK_ADDRESS)
            // `msgSender == owner || msgSender == approvedAddress`.
            result := or(eq(msgSender, owner), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedSlotAndAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        TokenApprovalRef storage tokenApproval = _tokenApprovals[tokenId];
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId].value`.
        assembly {
            approvedAddressSlot := tokenApproval.slot
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    // =============================================================
    //                      TRANSFER OPERATIONS
    // =============================================================

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        if (address(uint160(prevOwnershipPacked)) != from) revert TransferFromIncorrectOwner();

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
            if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();

        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // We can directly increment and decrement the balances.
            --_packedAddressData[from]; // Updates: `balance -= 1`.
            ++_packedAddressData[to]; // Updates: `balance += 1`.

            // Updates:
            // - `address` to the next owner.
            // - `startTimestamp` to the timestamp of transfering.
            // - `burned` to `false`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                to,
                _BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token IDs
     * are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token IDs
     * have been transferred. This includes minting.
     * And also called after one token has been burned.
     *
     * `startTokenId` - the first token ID to be transferred.
     * `quantity` - the amount to be transferred.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Private function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * `from` - Previous owner of the given token ID.
     * `to` - Target address that will receive the token.
     * `tokenId` - Token ID to be transferred.
     * `_data` - Optional data to send along with the call.
     *
     * Returns whether the call correctly returned the expected magic value.
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try ERC721A__IERC721Receiver(to).onERC721Received(_msgSenderERC721A(), from, tokenId, _data) returns (
            bytes4 retval
        ) {
            return retval == ERC721A__IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    // =============================================================
    //                        MINT OPERATIONS
    // =============================================================

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // `balance` and `numberMinted` have a maximum limit of 2**64.
        // `tokenId` has a maximum limit of 2**256.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 toMasked;
            uint256 end = startTokenId + quantity;

            // Use assembly to loop and emit the `Transfer` event for gas savings.
            // The duplicated `log4` removes an extra check and reduces stack juggling.
            // The assembly, together with the surrounding Solidity code, have been
            // delicately arranged to nudge the compiler into producing optimized opcodes.
            assembly {
                // Mask `to` to the lower 160 bits, in case the upper bits somehow aren't clean.
                toMasked := and(to, _BITMASK_ADDRESS)
                // Emit the `Transfer` event.
                log4(
                    0, // Start of data (0, since no data).
                    0, // End of data (0, since no data).
                    _TRANSFER_EVENT_SIGNATURE, // Signature.
                    0, // `address(0)`.
                    toMasked, // `to`.
                    startTokenId // `tokenId`.
                )

                for {
                    let tokenId := add(startTokenId, 1)
                } iszero(eq(tokenId, end)) {
                    tokenId := add(tokenId, 1)
                } {
                    // Emit the `Transfer` event. Similar to above.
                    log4(0, 0, _TRANSFER_EVENT_SIGNATURE, 0, toMasked, tokenId)
                }
            }
            if (toMasked == 0) revert MintToZeroAddress();

            _currentIndex = end;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * This function is intended for efficient minting only during contract creation.
     *
     * It emits only one {ConsecutiveTransfer} as defined in
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309),
     * instead of a sequence of {Transfer} event(s).
     *
     * Calling this function outside of contract creation WILL make your contract
     * non-compliant with the ERC721 standard.
     * For full ERC721 compliance, substituting ERC721 {Transfer} event(s) with the ERC2309
     * {ConsecutiveTransfer} event is only permissible during contract creation.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {ConsecutiveTransfer} event.
     */
    function _mintERC2309(address to, uint256 quantity) internal virtual {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > _MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << _BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            emit ConsecutiveTransfer(startTokenId, startTokenId + quantity - 1, address(0), to);

            _currentIndex = startTokenId + quantity;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * See {_mint}.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal virtual {
        _mint(to, quantity);

        unchecked {
            if (to.code.length != 0) {
                uint256 end = _currentIndex;
                uint256 index = end - quantity;
                do {
                    if (!_checkContractOnERC721Received(address(0), to, index++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (index < end);
                // Reentrancy protection.
                if (_currentIndex != end) revert();
            }
        }
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal virtual {
        _safeMint(to, quantity, '');
    }

    // =============================================================
    //                        BURN OPERATIONS
    // =============================================================

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        uint256 prevOwnershipPacked = _packedOwnershipOf(tokenId);

        address from = address(uint160(prevOwnershipPacked));

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedSlotAndAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isSenderApprovedOrOwner(approvedAddress, from, _msgSenderERC721A()))
                if (!isApprovedForAll(from, _msgSenderERC721A())) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner.
        assembly {
            if approvedAddress {
                // This is equivalent to `delete _tokenApprovals[tokenId]`.
                sstore(approvedAddressSlot, 0)
            }
        }

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as `tokenId` would have to be 2**256.
        unchecked {
            // Updates:
            // - `balance -= 1`.
            // - `numberBurned += 1`.
            //
            // We can directly decrement the balance, and increment the number burned.
            // This is equivalent to `packed -= 1; packed += 1 << _BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << _BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (_BITMASK_BURNED | _BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & _BITMASK_NEXT_INITIALIZED == 0) {
                uint256 nextTokenId = tokenId + 1;
                // If the next slot's address is zero and not burned (i.e. packed value is zero).
                if (_packedOwnerships[nextTokenId] == 0) {
                    // If the next slot is within bounds.
                    if (nextTokenId != _currentIndex) {
                        // Initialize the next slot to maintain correctness for `ownerOf(tokenId + 1)`.
                        _packedOwnerships[nextTokenId] = prevOwnershipPacked;
                    }
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    // =============================================================
    //                     EXTRA DATA OPERATIONS
    // =============================================================

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal virtual {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & _BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << _BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Called during each token transfer to set the 24bit `extraData` field.
     * Intended to be overridden by the cosumer contract.
     *
     * `previousExtraData` - the value of `extraData` before transfer.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _extraData(
        address from,
        address to,
        uint24 previousExtraData
    ) internal view virtual returns (uint24) {}

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> _BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << _BITPOS_EXTRA_DATA;
    }

    // =============================================================
    //                       OTHER OPERATIONS
    // =============================================================

    /**
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a uint256 to its ASCII string decimal representation.
     */
    function _toString(uint256 value) internal pure virtual returns (string memory str) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 0x80 bytes to keep the free memory pointer 32-byte word aligned.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 0x20 + 3 * 0x20 = 0x80.
            str := add(mload(0x40), 0x80)
            // Update the free memory pointer to allocate.
            mstore(0x40, str)

            // Cache the end of the memory to calculate the length later.
            let end := str

            // We write the string from rightmost digit to leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // prettier-ignore
            for { let temp := value } 1 {} {
                str := sub(str, 1)
                // Write the character to the pointer.
                // The ASCII index of the '0' character is 48.
                mstore8(str, add(48, mod(temp, 10)))
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
                // prettier-ignore
                if iszero(temp) { break }
            }

            let length := sub(end, str)
            // Move the pointer 32 bytes leftwards to make room for the length.
            str := sub(str, 0x20)
            // Store the length.
            mstore(str, length)
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
// ERC721A Contracts v4.2.2
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "lib/openzeppelin-contracts/contracts/utils/Strings.sol";
import "lib/openzeppelin-contracts/contracts/utils/Base64.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

// TODO natspec

contract MVCCOnChainMetadata is Ownable {
    using Strings for uint256;

    enum Races {
        HUMAN,
        ALIEN,
        ROBOT,
        GHOST,
        TIGER,
        UNIQUE
    }

    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event UriPrefixChanges(string previousUri, string newUri);

    /*//////////////////////////////////////////////////////////////
                                 STORAGE
    //////////////////////////////////////////////////////////////*/

    // 38 max traits
    // Background, Clubs, Body, Clothes, Mouth, Eyes, Hat,
    // 8,          22,    32,   38,      24,
    uint256 public constant NUM_LAYERS = 6;
    uint256 public constant NUM_SKILLS = 6;
    string public _uriPrefix = "baseURI.com/";

    //uint16[][NUM_LAYERS] WEIGHTS;
    uint16[] RACES;
    mapping(uint256 => string[]) public layers;
    mapping(uint256 => string[]) public skillLayers;
    mapping(Races => mapping(uint16 => uint16[])) public RACEWEIGHT;
    string[NUM_LAYERS] public traitTypes;
    string[NUM_SKILLS] public skillTypes;

    // 0         , 1   , 2      , 3    , 4  , 5
    // Background, Body, Clothes, Mouth, Eyes, Hat

    /*//////////////////////////////////////////////////////////////
                                 CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor() {
        // RACEWEIGHT
        RACES = [
            // Humans
            1650,
            1650,
            1650,
            1650,
            1650,
            30, // Gold human
            // Alien
            485,
            // Ghost
            485,
            // Robot
            485,
            20, // Gold robot
            // Tiger
            200,
            15, // Gold tiger
            // Unique
            10,
            10,
            10
        ];

        // -- HUMAN --

        // Background
        RACEWEIGHT[Races.HUMAN][0] = [
            1400,
            1400,
            1400,
            900,
            700,
            700,
            600,
            700,
            300,
            400,
            600,
            300,
            300,
            300
        ];

        // Clothes
        RACEWEIGHT[Races.HUMAN][2] = [
            749,
            721,
            549,
            524,
            499,
            449,
            424,
            399,
            374,
            374,
            349,
            349,
            300,
            300,
            275,
            300,
            275,
            300,
            300,
            290,
            250,
            275,
            250,
            275,
            200,
            200,
            200,
            100,
            100,
            50
        ];

        // Mouth
        RACEWEIGHT[Races.HUMAN][3] = [
            750,
            649,
            649,
            549,
            499,
            499,
            474,
            449,
            424,
            424,
            399,
            399,
            399,
            374,
            374,
            325,
            349,
            300,
            300,
            300,
            250,
            300,
            200,
            140,
            125,
            100
        ];

        // Eyes
        RACEWEIGHT[Races.HUMAN][4] = [
            899,
            899,
            899,
            699,
            674,
            623,
            599,
            499,
            474,
            449,
            399,
            399,
            399,
            374,
            325,
            300,
            300,
            275,
            250,
            140,
            125
        ];

        // Hats
        RACEWEIGHT[Races.HUMAN][5] = [
            824,
            724,
            649,
            524,
            499,
            474,
            424,
            399,
            399,
            374,
            374,
            399,
            349,
            349,
            349,
            315,
            300,
            300,
            275,
            275,
            250,
            250,
            200,
            150,
            150,
            150,
            125,
            100,
            50
        ];

        // -- ALIEN --

        // Background
        RACEWEIGHT[Races.ALIEN][0] = [
            1400,
            1400,
            1400,
            900,
            700,
            700,
            600,
            700,
            300,
            400,
            600,
            300,
            300,
            300
        ];

        // Clothes
        RACEWEIGHT[Races.ALIEN][2] = [
            749,
            721,
            549,
            524,
            499,
            449,
            424,
            399,
            374,
            374,
            349,
            349,
            300,
            300,
            275,
            300,
            275,
            300,
            300,
            290,
            250,
            275,
            250,
            275,
            200,
            200,
            200,
            100,
            100,
            50
        ];
        // Mouth
        RACEWEIGHT[Races.ALIEN][3] = [
            879,
            763,
            763,
            663,
            613,
            613,
            588,
            0,
            538,
            538,
            513,
            0,
            0,
            488,
            0,
            0,
            0,
            414,
            414,
            414,
            364,
            414,
            314,
            254,
            239,
            214
        ];

        // Eyes
        RACEWEIGHT[Races.ALIEN][4] = [
            899,
            899,
            899,
            699,
            674,
            623,
            599,
            499,
            474,
            449,
            399,
            399,
            399,
            374,
            325,
            300,
            300,
            275,
            250,
            140,
            125
        ];

        // Hat
        RACEWEIGHT[Races.ALIEN][5] = [
            1019,
            919,
            0,
            719,
            694,
            669,
            619,
            0,
            0,
            569,
            0,
            0,
            544,
            544,
            544,
            0,
            495,
            0,
            0,
            470,
            0,
            445,
            395,
            345,
            345,
            345,
            320,
            0,
            0
        ];

        // -- ROBOT --

        // Background
        RACEWEIGHT[Races.ROBOT][0] = [
            1400,
            1400,
            1400,
            900,
            700,
            700,
            600,
            700,
            300,
            400,
            600,
            300,
            300,
            300
        ];

        // Clothes
        RACEWEIGHT[Races.ROBOT][2] = [
            777,
            768,
            577,
            552,
            527,
            477,
            452,
            427,
            402,
            402,
            377,
            377,
            328,
            328,
            303,
            0,
            303,
            328,
            328,
            318,
            278,
            0,
            278,
            303,
            228,
            228,
            0,
            128,
            128,
            78
        ];
        // Mouth
        RACEWEIGHT[Races.ROBOT][3] = [
            879,
            763,
            763,
            663,
            613,
            613,
            588,
            0,
            538,
            538,
            513,
            0,
            0,
            488,
            0,
            0,
            0,
            414,
            414,
            414,
            364,
            414,
            314,
            254,
            239,
            214
        ];
        // Eyes
        RACEWEIGHT[Races.ROBOT][4] = [
            923,
            923,
            923,
            742,
            698,
            647,
            623,
            0,
            498,
            473,
            423,
            423,
            423,
            398,
            349,
            324,
            324,
            299,
            274,
            164,
            149
        ];
        // Hat
        RACEWEIGHT[Races.ROBOT][5] = [
            1046,
            942,
            0,
            742,
            717,
            692,
            642,
            0,
            0,
            592,
            0,
            0,
            567,
            567,
            567,
            0,
            518,
            0,
            0,
            493,
            0,
            468,
            0,
            368,
            368,
            368,
            343,
            0,
            0
        ];

        // -- GHOST --
        RACEWEIGHT[Races.GHOST][0] = [
            1487,
            1483,
            1483,
            983,
            0,
            783,
            683,
            783,
            0,
            483,
            683,
            383,
            383,
            383
        ];

        // Clothes
        RACEWEIGHT[Races.GHOST][2] = [
            749,
            721,
            549,
            524,
            499,
            449,
            424,
            399,
            374,
            374,
            349,
            349,
            300,
            300,
            275,
            300,
            275,
            300,
            300,
            290,
            250,
            275,
            250,
            275,
            200,
            200,
            200,
            100,
            100,
            50
        ];

        RACEWEIGHT[Races.GHOST][3] = [
            879,
            763,
            763,
            663,
            613,
            613,
            588,
            0,
            538,
            538,
            513,
            0,
            0,
            488,
            0,
            0,
            0,
            414,
            414,
            414,
            364,
            414,
            314,
            254,
            239,
            214
        ];
        RACEWEIGHT[Races.GHOST][4] = [
            923,
            923,
            923,
            742,
            698,
            647,
            623,
            0,
            498,
            473,
            423,
            423,
            423,
            398,
            349,
            324,
            324,
            299,
            274,
            164,
            149
        ];

        // Hats
        RACEWEIGHT[Races.GHOST][5] = [
            824,
            724,
            649,
            524,
            499,
            474,
            424,
            399,
            399,
            374,
            374,
            399,
            349,
            349,
            349,
            315,
            300,
            300,
            275,
            275,
            250,
            250,
            200,
            150,
            150,
            150,
            125,
            100,
            50
        ];

        // -- TIGER --

        // Background
        RACEWEIGHT[Races.TIGER][0] = [
            1400,
            1400,
            1400,
            900,
            700,
            700,
            600,
            700,
            300,
            400,
            600,
            300,
            300,
            300
        ];

        RACEWEIGHT[Races.TIGER][2] = [
            828,
            776,
            604,
            579,
            554,
            504,
            479,
            454,
            429,
            429,
            0,
            404,
            355,
            355,
            330,
            0,
            330,
            355,
            355,
            345,
            305,
            0,
            305,
            0,
            255,
            255,
            0,
            155,
            155,
            105
        ];
        RACEWEIGHT[Races.TIGER][3] = [
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0,
            0
        ];
        RACEWEIGHT[Races.TIGER][4] = [
            980,
            980,
            980,
            780,
            769,
            704,
            0,
            0,
            555,
            530,
            480,
            480,
            480,
            0,
            406,
            381,
            381,
            356,
            331,
            221,
            206
        ];

        RACEWEIGHT[Races.TIGER][5] = [
            1115,
            1011,
            0,
            811,
            786,
            761,
            711,
            0,
            0,
            661,
            0,
            0,
            0,
            636,
            636,
            0,
            587,
            0,
            0,
            562,
            0,
            0,
            0,
            437,
            437,
            437,
            412,
            0,
            0
        ];

        traitTypes[0] = "Background"; // Background
        traitTypes[1] = "Body"; // Body
        traitTypes[2] = "Clothes"; // Clothes
        traitTypes[3] = "Mouth"; // Mouth
        traitTypes[4] = "Eyes"; // Eyes
        traitTypes[5] = "Hat"; // Hat

        skillTypes[0] = "Golf IQ";
        skillTypes[1] = "Luck";
        skillTypes[2] = "Avg. Driving Distance";
        skillTypes[3] = "Short Game";
        skillTypes[4] = "Club Preference";
        skillTypes[5] = "Playing Style";

        // Background
        layers[0] = [
            "Sandtrap",
            "The Front Tee's",
            "Clear Sky",
            "Tee Box",
            "Country Club",
            "Golf Green",
            "Coastal",
            "Woods",
            "Grandstand",
            "Island Green",
            "Sunset",
            "Desert",
            "Volcano",
            "Bridge"
        ];
        // TODO the 3 uniques are unaccounted for
        // Body
        layers[1] = [
            "Human 1",
            "Human 2",
            "Human 3",
            "Human 4",
            "Human 5",
            "Gold Human",
            "Alien",
            "Ghost",
            "Robot",
            "Gold Robot",
            "Tiger",
            "Gold Tiger",
            // @note UNIQUES!
            "Tiger Green Jacket",
            "Lefty",
            "Bear"
        ];

        // Clothes
        layers[2] = [
            "White Polo",
            "Khaki T",
            "Red Frocket",
            "Black T",
            "Mint Q-Zip",
            "Gray Crewneck",
            "Horizontal Striped Polo",
            "Purple Frocket",
            "Black Vest",
            "White Checker Polo",
            "Gray Hoodie",
            "Purple Q-Zip",
            "Peach Crewneck",
            "Olive Turtleneck",
            "Gray Vest",
            "Yellow Puffer Jacket",
            "Suit",
            "Hawaiian Polo",
            "Yellow Checker Polo",
            "Maroon Q-Zip",
            "Paint Splatter Polo",
            "Black Puffer Jacket",
            "White T w/ Chain",
            "Midnight Hoodie",
            "Green Polo w/ Birb",
            "Blue Q-Zip w/ Ape",
            "Red Hoodie w/ Bean",
            "Gold Polo",
            "Sunday Red",
            "Green Jacket"
        ];
        // Mouth
        layers[3] = [
            "Frown",
            "Smile",
            "Meh",
            "Anger",
            "Shocked",
            "Ecstatic",
            "Smirk",
            "Blonde Caterpillar",
            "Toothgap",
            "Cheesin'",
            "Full",
            "Red Beard",
            "5 O'Clock Shadow",
            "White Tee",
            "Brown Beard",
            "Brown Caterpillar",
            "Wizard Beard",
            "Toothpick",
            "Wood Tee",
            "Joint",
            "Stoge",
            "Pipe",
            "Bubblegum",
            "Glizzy",
            "Gold Tee",
            "Diamond Tee"
        ];

        // Eyes
        layers[4] = [
            "Green",
            "Blue",
            "Brown",
            "Glasses",
            "Transparent Shades",
            "Semi-Rimless Glasses",
            "Brown Circle Sunnies",
            "Dazed",
            "Squint",
            "Gray Aviators",
            "Black Shades",
            "Red Shades",
            "RBF",
            "Black Circle Sunnies",
            "Green Aviators",
            "Heart",
            "Cyborg",
            "Rainbow",
            "Ethies",
            "Golf Ball",
            "Laser"
        ];

        // Hat
        layers[5] = [
            "White Hat - Blue Crest",
            "Graphite Hat",
            "White Visor",
            "Driving Cap",
            "Purple Hat",
            "Gray Rope Hat",
            "White Hat - Green Crest",
            "Black Visor w/ White Tee",
            "Gray Aussie Hat",
            "Black Hat",
            "White Hat w/ Wood Tee",
            "Backwards Hat",
            "Black Beanie",
            "Captain Hat",
            "Peach Hat",
            "White Aussie Hat",
            "Halo Hat",
            "Khaki Hat w/ Earring",
            "Pink Visor",
            "Crown",
            "Black Hat w/ Earring",
            "Winter Beanie",
            "Hoodie Up",
            "Black Hat w/ Ghost",
            "Midnight Hat w/ Gutter Cat",
            "Chromie Hat",
            "Galaxy Hat",
            "White Hat w/ Golden Tee",
            "Gold Visor"
        ];

        skillLayers[0] = [
            "Dialed in",
            "Stinger Specialist",
            "Fairway Finder",
            "Average",
            "Drives for Show",
            "In Shambles"
        ];
        skillLayers[1] = [
            "Tree Assistance",
            "Rolls Towards Pin",
            "Cart Path Help",
            "Lucky Underwear",
            "At The Beach",
            "YHTSI"
        ];
        skillLayers[2] = ["303", "269", "254", "237", "221", "207"];
        skillLayers[3] = [
            "Flop Shot Expert",
            "Bunker Warrior",
            "Bump N' Run",
            "Texas Wedge",
            "Lipout King",
            "Topper"
        ];
        skillLayers[4] = ["Driver", "Irons", "Wedges", "Putter"];
        skillLayers[5] = [
            "Energizer",
            "Technician",
            "Magician",
            "Aggressor",
            "Strategist"
        ];
    }

    /*//////////////////////////////////////////////////////////////
                                 VIEW
    //////////////////////////////////////////////////////////////*/

    function getSkill(uint256 skillIndex, uint256 itemIndex)
        public
        view
        returns (string memory)
    {
        return skillLayers[skillIndex][itemIndex];
    }

    function getSkills(uint256 skillIndex)
        public
        view
        returns (string[] memory)
    {
        uint256 totalItems = skillLayers[skillIndex].length;
        string[] memory items = new string[](totalItems);

        for (uint256 i; i < totalItems; i++) {
            items[i] = skillLayers[skillIndex][i];
        }

        return items;
    }

    function getSkillsLength(uint256 skillIndex) public view returns (uint256) {
        return skillLayers[skillIndex].length;
    }

    function getLayersLength(uint256 layerIndex) public view returns (uint256) {
        return layers[layerIndex].length;
    }

    function getLayer(uint256 layerIndex, uint256 itemIndex)
        public
        view
        returns (string memory)
    {
        return layers[layerIndex][itemIndex];
    }

    function getLayers(uint256 layerIndex)
        public
        view
        returns (string[] memory)
    {
        uint256 totalItems = layers[layerIndex].length;
        string[] memory items = new string[](totalItems);

        for (uint256 i; i < totalItems; i++) {
            items[i] = layers[layerIndex][i];
        }

        return items;
    }

    function tokenURI(uint256 tokenId, uint256 _dna)
        external
        view
        returns (string memory)
    {
        (
            string[NUM_LAYERS] memory traits,
            string[NUM_SKILLS] memory skills,
            string memory indexes
        ) = getTokenData(_dna);
        string memory attributes;

        for (uint8 i; i < NUM_LAYERS; i++) {
            if (bytes(traits[i]).length > 0) {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        bytes(attributes).length == 0 ? "{" : ", {",
                        '"trait_type": "',
                        traitTypes[i],
                        '","value": "',
                        traits[i],
                        '" }'
                    )
                );
            }
        }

        for (uint8 i; i < NUM_SKILLS; i++) {
            if (bytes(skills[i]).length > 0) {
                attributes = string(
                    abi.encodePacked(
                        attributes,
                        bytes(attributes).length == 0 ? "{" : ", {",
                        '"trait_type": "',
                        skillTypes[i],
                        '","value": "',
                        skills[i],
                        '" }'
                    )
                );
            }
        }
        bytes memory data = abi.encodePacked("?dna=", indexes);

        string memory imageLink = string(
            abi.encodePacked(_uriPrefix, tokenId.toString(), data, '", ')
        );

        bytes memory dataURI = abi.encodePacked(
            '{ "animation_url": "',
            imageLink, // baseURI/tokenId?dna=123456
            '"attributes": [',
            attributes,
            '],   "name": "Linksman #',
            tokenId.toString(),
            '", "description": "Linksmen NFT"}'
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function getTokenData(uint256 _dna)
        public
        view
        returns (
            string[NUM_LAYERS] memory traits,
            string[NUM_SKILLS] memory skills,
            string memory indexes
        )
    {
        uint16[NUM_LAYERS] memory dna = splitNumber(_dna);
        uint8[NUM_SKILLS] memory skillDNA = splitSkills(_dna);

        // Get race index
        uint256 raceIndex = getRaceIndex(dna[1]);
        Races race = getRace(raceIndex);

        for (uint8 i; i < NUM_LAYERS; i++) {
            if (i == 1) {
                indexes = string(
                    abi.encodePacked(indexes, raceIndex.toString(), ",")
                );
                traits[i] = layers[1][raceIndex];
            } else {
                uint256 index = getLayerIndex(dna[i], i, race);
                indexes = bytes(indexes).length == 0
                    ? string(abi.encodePacked(index.toString(), ","))
                    : i == NUM_LAYERS - 1
                    ? string(abi.encodePacked(indexes, index.toString()))
                    : string(abi.encodePacked(indexes, index.toString(), ","));

                if (index == RACEWEIGHT[race][i].length) {
                    traits[i] = "";
                } else {
                    traits[i] = layers[i][index];
                }
            }
        }

        uint256 clothesIndex = getLayerIndex(dna[2], 2, race);
        uint256 hatIndex = getLayerIndex(dna[5], 5, race);
        uint256 mouthIndex = getLayerIndex(dna[3], 3, race);

        // @audit - I should change the indexes string in these cases
        if (clothesIndex == 26 && hatIndex != 22) {
            traits[5] = "";
        }

        if (
            hatIndex == 22 &&
            (mouthIndex == 11 ||
                mouthIndex == 12 ||
                mouthIndex == 14 ||
                mouthIndex == 16)
        ) {
            traits[3] = mouthIndex == 11
                ? layers[3][10]
                : layers[3][mouthIndex + 1];
        }

        for (uint256 i; i < NUM_SKILLS; i++) {
            //indexes = string(abi.encodePacked(indexes, skillDNA[i]));
            skills[i] = skillLayers[i][skillDNA[i]];
        }
    }

    function getRaceIndex(uint16 _dna) public view returns (uint256) {
        uint16 lowerBound;
        uint16 percentage;
        for (uint8 i; i < RACES.length; i++) {
            percentage = RACES[i];
            if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                return i;
            }
            lowerBound += percentage;
        }
        // If not found, return human
        return lowerBound % 5;
    }

    function getLayerIndex(
        uint16 _dna,
        uint8 _index,
        Races race
    ) public view returns (uint256) {
        if (race == Races.UNIQUE) {
            return RACEWEIGHT[race][_index].length;
        } else {
            uint16 lowerBound;
            uint16 percentage;
            for (uint8 i; i < RACEWEIGHT[race][_index].length; i++) {
                percentage = RACEWEIGHT[race][_index][i];
                if (_dna >= lowerBound && _dna < lowerBound + percentage) {
                    return i;
                }
                lowerBound += percentage;
            }
            // If not found, return index higher than available layers.  Will get filtered out.
            return RACEWEIGHT[race][_index].length;
        }
    }

    /*//////////////////////////////////////////////////////////////
                                 ADMIN
    //////////////////////////////////////////////////////////////*/

    function setLayer(
        uint256 layerIndex,
        uint256 itemIndex,
        string calldata name
    ) external onlyOwner {
        layers[layerIndex][itemIndex] = name;
    }

    function setLayers(uint256 index, string[] calldata toSet)
        external
        onlyOwner
    {
        uint256 length = toSet.length;

        for (uint16 i = 0; i < length; i++) {
            layers[index][i] = toSet[i];
        }
    }

    function setURI(string memory _uri) external onlyOwner {
        string memory oldUri = _uriPrefix;
        _uriPrefix = _uri;

        emit UriPrefixChanges(oldUri, _uri);
    }

    /*//////////////////////////////////////////////////////////////
                                 INTERNAL
    //////////////////////////////////////////////////////////////*/

    function getRace(uint256 index) internal pure returns (Races) {
        if (index < 6) {
            return Races.HUMAN;
        } else if (index == 6) {
            return Races.ALIEN;
        } else if (index == 7) {
            return Races.GHOST;
        } else if (index < 10) {
            return Races.ROBOT;
        } else if (index < 12) {
            return Races.TIGER;
        } else {
            return Races.UNIQUE;
        }
    }

    function splitNumber(uint256 _number)
        internal
        pure
        returns (uint16[NUM_LAYERS] memory numbers)
    {
        for (uint256 i = 0; i < numbers.length; i++) {
            uint256 mask = 16383; // 14 bits set to 1

            numbers[i] = uint16((_number & mask) % 10000);
            _number >>= 14;
        }
        return numbers;
    }

    function splitSkills(uint256 _number)
        internal
        view
        returns (uint8[NUM_SKILLS] memory numbers)
    {
        _number >>= (14 * NUM_LAYERS);

        for (uint256 i; i < numbers.length; i++) {
            numbers[i] = uint8((_number & 0xF) % skillLayers[i].length);
            _number >>= 4;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}