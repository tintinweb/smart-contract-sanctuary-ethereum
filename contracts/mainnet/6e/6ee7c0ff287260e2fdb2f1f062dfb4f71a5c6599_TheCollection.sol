// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC721} from "openzeppelin/token/ERC721/IERC721.sol";
import {ERC721A} from "ERC721A/ERC721A.sol";
import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProof} from "openzeppelin/utils/cryptography/MerkleProof.sol";
import {Strings} from "openzeppelin/utils/Strings.sol";
import "./Banker.sol";

error InvalidFunds();
error InvalidQuantity();
error InvalidProof();
error InvalidToken();
error MaxQuantityReached();
error MaxQuantityPerTxReached();
error NotEnoughSupply();
error SaleIsNotOpen();
error ContractPaused();

enum Rank {
    GM,
    AGM,
    FO,
    Gold
}

enum Phase {
    Closed,
    One,
    Two
}

enum Sale {
    Allowlist,
    Public
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract TheCollection is Owned, ERC721A, Banker {
    using Strings for uint256;

    event RankedMint(Rank indexed rank, address indexed account, uint256 startId, uint256 quantity);

    struct CountTracker {
        bool phase1ExternalClaim;
        uint32 phase1Allowlist;
        uint32 phase1Public;
        uint32 phase2DraftClaim;
        uint32 phase2Allowlist;
        uint32 phase2Public;
    }

    uint16 public constant MaxMintPhase1Allowlist = 1;
    uint16 public constant MaxMintPhase1Total = 5;
    uint16 public constant MaxMintPhase2Allowlist = 2;

    uint256 public draftPriceGM = 1 ether;
    uint256 public draftPriceAGM = 0.5 ether;
    uint256 public draftPriceFO = 0.19 ether;
    uint256 public phase2AllowlistPrice = 0.1 ether;
    uint256 public phase2PublicPrice = 0.15 ether;

    uint16 public totalSupplyLimit = 6699;

    /// @dev Total remaining supply of ranks (after external presale has ended) to be minted during phase1
    uint16 public mintableTotalSupplyGM;
    uint16 public mintableTotalSupplyAGM;
    uint16 public mintableTotalSupplyFO;

    /// @dev Same as for phase 1, but modifiable by the owner
    uint16 public maxMintPhase2Total = 10;

    /// @dev Keep under 10 mint per tx to avoid running into issues with OpenSea + ERC721A
    /// Modifiable by the owner
    uint16 public maxMintPerTx = 9;

    /// @dev Totals of mints for each rank in phase 1.
    /// Doesn't take in account claims from external presale
    uint16 public totalMintedGM;
    uint16 public totalMintedAGM;
    uint16 public totalMintedFO;

    /// @dev Must be set by admin once phase 1 has ended.
    /// It's used to differenciate between revealed tokens of phase 1 and unrevealed tokens of phase 2.
    /// See {tokenURI(uint256)}.
    uint16 public phase1EndTokenId;

    bool public phase1Revealed;
    bool public phase2Revealed;

    Phase public phase;
    Sale public sale;
    bool public paused;

    /// @dev Not required to be hosted on IPFS and doesn't change between mainnet and testnets.
    /// Except for the royalties recipient address, which will always point to the mainnet wallet.
    string public contractUri = "https://lipsweater.io/collection/collection-metadata.json";

    /// @dev Not required to be hosted on IPFS and doesn't change between mainnet and testnets
    string public unrevealedUri = "ipfs://QmNQyexUM4H2ohxqm91HvFfqYP4hoRqKNE4YSR4BKSqBQC";

    string public phase1RevealedBaseUri;
    string public phase2RevealedBaseUri;

    mapping(address => CountTracker) _counters;

    /// @dev Accounts from external presale before phase1, that can claim `AGM quantity` and `FO quantity`
    /// Structure is <address, AGM quantity, FO quantity>
    bytes32 public phase1ExternalClaimsMerkle;

    /// @dev Allowlist of accounts for phase1
    bytes32 public phase1AllowlistMerkle;

    /// @dev Accounts from phase1 that can claim up to `total claimable quantity` depending on the ranks they own
    /// Structure is <address, total claimable quantity>
    bytes32 public phase2DraftClaimsMerkle;

    /// @dev Allowlist of accounts for phase2
    bytes32 public phase2AllowlistMerkle;

    /// @dev Addresses of marketplaces contracts for pre-approuved transfers.
    /// Modifiable by the owner
    address[] public approvedProxies;

    constructor(
        uint16 supplyGM,
        uint16 supplyAGM,
        uint16 supplyFO,
        address owner,
        address vault,
        uint256 vaultGoldsQuantity,
        address[] memory airdropAccountsGold,
        address[] memory proxies,
        Payee memory teamPayee,
        Payee memory devPayee,
        Payee memory royalties
    ) Owned(owner) ERC721A("Lipsweater", "LST") Banker(teamPayee, devPayee, royalties) {
        mintableTotalSupplyGM = supplyGM;
        mintableTotalSupplyAGM = supplyAGM;
        mintableTotalSupplyFO = supplyFO;
        approvedProxies = proxies;

        // Cheaper batch airdrop on contract creation
        // We don't emit `RankedBatchMint` as in airdropXXX() because those accounts and associated ids are known (ids from 1 to length)
        for (uint256 i = 0; i < airdropAccountsGold.length; ++i) {
            _mintERC2309(airdropAccountsGold[i], 1);
        }
        if (vaultGoldsQuantity > 0) {
            _mintERC2309(vault, vaultGoldsQuantity);
        }
    }

    /// COLLECTION SETTINGS

    function _startTokenId() internal pure override returns (uint256) {
        return 1;
    }

    /// @dev See https://docs.opensea.io/docs/contract-level-metadata
    function contractURI() public view returns (string memory) {
        return contractUri;
    }

    /// @dev Override default behavior to handle an unrevealed phase where all token URIs point to the same image.
    /// The format of URI is: {BASE}{id} which has following implications:
    ///   - BASE must have a trailing slash;
    ///   - URI must not have an extension
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if (!_exists(tokenId)) revert InvalidToken();

        if (phase1Revealed) {
            if (tokenId <= phase1EndTokenId) {
                return string(abi.encodePacked(phase1RevealedBaseUri, tokenId.toString()));
            } else if (phase2Revealed) {
                return string(abi.encodePacked(phase2RevealedBaseUri, tokenId.toString()));
            }
        }

        return unrevealedUri;
    }

    /// PHASE 1 (= draft)

    /// Claim free-mint for users who reserved their AGMs and FOs using the external presale.
    /// Each user can only claim once, so it needs to claim all available tokens at once.
    ///
    /// Can be claimed at any point during phase 1.
    function claimFromExternalPresale(
        uint256 quantityAGM,
        uint256 quantityFO,
        bytes32[] calldata proof
    ) external isPhase(Phase.One) {
        // The leaf must match encoded form of <address, quantityAGM, quantityFO>
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, quantityAGM, quantityFO));
        if (!MerkleProof.verifyCalldata(proof, phase1ExternalClaimsMerkle, leaf)) {
            revert InvalidProof();
        }

        if (_counters[msg.sender].phase1ExternalClaim) {
            revert MaxQuantityReached();
        }
        _counters[msg.sender].phase1ExternalClaim = true;

        /// Do not increment totalMintedXXX, as those are externally presold NFTs before contract creation,
        /// thus the contract will already have adjusted Supply to match those.
        if (quantityAGM > 0) {
            _mintRanked(Rank.AGM, msg.sender, quantityAGM);
        }

        if (quantityFO > 0) {
            _mintRanked(Rank.FO, msg.sender, quantityFO);
        }
    }

    /// Mint of phase 1 for allowlisted users.
    /// No difference in price with the public mint.
    /// Quantity is fixed to `MaxMintPhase1Allowlist`, regardless of the choosen rank.
    /// User can mint up to `MaxMintPhase1Total` tokens in total (not including claims).
    ///
    /// Can be minted only during allowlist sale of phase 1.
    function mintDraftAllowlist(bytes32[] calldata proof)
        external
        payable
        isPhase(Phase.One)
        isSale(Sale.Allowlist)
    {
        if (
            !MerkleProof.verifyCalldata(
                proof,
                phase1AllowlistMerkle,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        CountTracker memory tracker = _counters[msg.sender];

        if (
            tracker.phase1Allowlist >= MaxMintPhase1Allowlist ||
            (tracker.phase1Public + MaxMintPhase1Allowlist > MaxMintPhase1Total)
        ) {
            revert MaxQuantityReached();
        }

        _counters[msg.sender].phase1Allowlist = MaxMintPhase1Allowlist;

        _mintDraft(msg.sender, MaxMintPhase1Allowlist);
    }

    /// Public mint of phase 1.
    /// Until supplies of GM, AGM and FO run out.
    ///
    /// User can mint up to `MaxMintPhase1Total` tokens in total (not including claims).
    ///
    /// Token is minted and transfered `to` account.
    /// Expected to be called by USDT API.
    ///
    /// Can be minted only during public sale of phase 1.
    function crossmintDraft(address to, uint16 quantity)
        external
        payable
        isPhase(Phase.One)
        isSale(Sale.Public)
    {
        CountTracker memory tracker = _counters[to];

        if (tracker.phase1Allowlist + tracker.phase1Public + quantity > MaxMintPhase1Total) {
            revert MaxQuantityReached();
        }

        _counters[to].phase1Public += quantity;

        _mintDraft(to, quantity);
    }

    function _mintDraft(address to, uint16 quantity) internal {
        if (msg.value == draftPriceGM * quantity) {
            if (quantity + totalMintedGM > mintableTotalSupplyGM) {
                revert NotEnoughSupply();
            }

            totalMintedGM += quantity;
            _mintRanked(Rank.GM, to, quantity);
        } else if (msg.value == draftPriceAGM * quantity) {
            if (quantity + totalMintedAGM > mintableTotalSupplyAGM) {
                revert NotEnoughSupply();
            }

            totalMintedAGM += quantity;
            _mintRanked(Rank.AGM, to, quantity);
        } else if (msg.value == draftPriceFO * quantity) {
            if (quantity + totalMintedFO > mintableTotalSupplyFO) {
                revert NotEnoughSupply();
            }

            totalMintedFO += quantity;
            _mintRanked(Rank.FO, to, quantity);
        } else {
            revert InvalidFunds();
        }
    }

    function _mintRanked(
        Rank rank,
        address to,
        uint256 quantity
    ) internal {
        emit RankedMint(rank, to, _nextTokenId(), quantity);
        _mint(to, quantity);
    }

    /// PHASE 2

    /// Claim free-mint for users who own ranked tokens from phase 1.
    /// User can claim as many time as they want, however they cannot exceed the total claimable quantity,
    /// which is defined off-chain when phase 1 is finished, based on what & how many ranks each user owns.
    ///
    /// Can be claimed at any point during phase 2, until total supply runs out.
    function claimFromDraft(
        uint32 quantity,
        uint256 totalClaimableQuantity,
        bytes32[] calldata proof
    )
        external
        isPhase(Phase.Two)
        maxQuantityPerTxNotReached(quantity)
        totalSupplyNotReached(quantity)
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, totalClaimableQuantity));
        if (!MerkleProof.verifyCalldata(proof, phase2DraftClaimsMerkle, leaf)) {
            revert InvalidProof();
        }

        if (_counters[msg.sender].phase2DraftClaim + quantity > totalClaimableQuantity) {
            revert MaxQuantityReached();
        }
        _counters[msg.sender].phase2DraftClaim += quantity;

        _mint(msg.sender, quantity);
    }

    /// Mint of phase 2 for allowlisted users.
    /// Price is cheaper than the public mint.
    /// Total minted quantity in allowlist cannot exceed `MaxMintPhase2Allowlist`.
    /// User can mint up to `maxMintPhase2Total` tokens in total (not including claims).
    ///
    /// Can be minted only during allowlist sale of phase 2.
    function mintPhase2Allowlist(uint32 quantity, bytes32[] calldata proof)
        external
        payable
        isPhase(Phase.Two)
        isSale(Sale.Allowlist)
        totalSupplyNotReached(quantity)
        withProperFunds(quantity, phase2AllowlistPrice)
    {
        if (
            !MerkleProof.verifyCalldata(
                proof,
                phase2AllowlistMerkle,
                keccak256(abi.encodePacked(msg.sender))
            )
        ) {
            revert InvalidProof();
        }

        CountTracker memory tracker = _counters[msg.sender];

        if (
            tracker.phase2Allowlist + quantity > MaxMintPhase2Allowlist ||
            (tracker.phase2Allowlist + tracker.phase2Public + quantity > maxMintPhase2Total)
        ) {
            revert MaxQuantityReached();
        }

        _counters[msg.sender].phase2Allowlist += quantity;

        _mint(msg.sender, quantity);
    }

    /// Public cross-mint of phase 2.
    /// Until total supply runs out.
    ///
    /// User can mint up to `maxMintPhase2Total` tokens in total (not including claims).
    ///
    /// Token is minted and transfered `to` account.
    /// Expected to be called by USDT API.
    ///
    /// Can be minted only during public sale of phase 2.
    function crossmintPhase2(address to, uint32 quantity)
        external
        payable
        isPhase(Phase.Two)
        isSale(Sale.Public)
        maxQuantityPerTxNotReached(quantity)
        totalSupplyNotReached(quantity)
        withProperFunds(quantity, phase2PublicPrice)
    {
        CountTracker memory tracker = _counters[to];

        if (tracker.phase2Allowlist + tracker.phase2Public + quantity > maxMintPhase2Total) {
            revert MaxQuantityReached();
        }

        _counters[to].phase2Public += quantity;

        _mint(to, quantity);
    }

    /// AIR DROP

    /// Airdrop 1 or more GMs to provided accounts
    /// `accounts` length must match `quantities` length
    /// @dev Owner should respect the `maxQuantityPerTx` limit, we don't enforce it as it's impractical and gas costly
    function airdropGM(address[] memory accounts, uint256[] memory quantities) external onlyOwner {
        if (accounts.length != quantities.length) {
            revert();
        }

        for (uint256 i = 0; i < accounts.length; ++i) {
            _mintRanked(Rank.GM, accounts[i], quantities[i]);
        }
    }

    /// Airdrop 1 Gold to each provided accounts
    /// @dev Limited to `maxQuantityPerTx`
    function airdropGold(address[] memory accounts)
        external
        onlyOwner
        maxQuantityPerTxNotReached(accounts.length)
    {
        for (uint256 i = 0; i < accounts.length; ++i) {
            _mintRanked(Rank.Gold, accounts[i], 1);
        }
    }

    /// Mint and transfer `quantity` of golds to `vault`
    /// @dev Limited to `maxQuantityPerTx`
    function airdropGoldsToVault(address vault, uint256 quantity)
        external
        onlyOwner
        maxQuantityPerTxNotReached(quantity)
    {
        _mintRanked(Rank.Gold, vault, quantity);
    }

    /// GETTERS

    function getCountTracker(address account) external view returns (CountTracker memory) {
        return _counters[account];
    }

    function totalMinted() external view returns (uint256) {
        return _totalMinted();
    }

    /// ADMIN

    function setStatus(Phase phase_, Sale sale_) external onlyOwner {
        phase = phase_;
        sale = sale_;
    }

    /// Reveal the phase 1 and provide the real URI of the IPFS folder
    /// @param revealed allowing to unreveal in case you revealed too soon by mistake
    /// @param uri pointing to the metadata folder hosted on IPFS. **Don't forget the trailing slash!**
    /// @param endTokenId the last token id minted in phase 1
    function setPhase1Reveal(
        bool revealed,
        string memory uri,
        uint16 endTokenId
    ) external onlyOwner {
        phase1Revealed = revealed;
        phase1RevealedBaseUri = uri;
        phase1EndTokenId = endTokenId;
    }

    /// @dev Allows to only update base URI when partial phase 1 data is revealed, without having to provide the same values for other params.
    function setPhase1RevealedUri(string memory uri) external onlyOwner {
        phase1RevealedBaseUri = uri;
    }

    /// Reveal the phase 2 and provide the real URI of the IPFS folder
    /// @param revealed allowing to unreveal in case you revealed too soon by mistake
    /// @param uri pointing to the metadata folder hosted on IPFS. **Don't forget the trailing slash!**
    function setPhase2Reveal(bool revealed, string memory uri) external onlyOwner {
        phase2Revealed = revealed;
        phase2RevealedBaseUri = uri;
    }

    function setMaxMintPhase2Total(uint16 total) external onlyOwner {
        maxMintPhase2Total = total;
    }

    function setMaxMintPerTx(uint16 value) external onlyOwner {
        maxMintPerTx = value;
    }

    function setPhase1ExternalClaimsMerkle(bytes32 root) external onlyOwner {
        phase1ExternalClaimsMerkle = root;
    }

    function setPhase1AllowlistMerkle(bytes32 root) external onlyOwner {
        phase1AllowlistMerkle = root;
    }

    function setPhase2DraftClaimsMerkle(bytes32 root) external onlyOwner {
        phase2DraftClaimsMerkle = root;
    }

    function setPhase2AllowlistMerkle(bytes32 root) external onlyOwner {
        phase2AllowlistMerkle = root;
    }

    function burn(uint256 tokenId) external onlyOwner {
        _burn(tokenId, true);
    }

    function setPaused(bool paused_) external onlyOwner {
        paused = paused_;
    }

    function setContractUri(string memory uri) external onlyOwner {
        contractUri = uri;
    }

    function setUnrevealedUri(string memory uri) external onlyOwner {
        unrevealedUri = uri;
    }

    function setApprovedProxies(address[] memory proxies) external onlyOwner {
        approvedProxies = proxies;
    }

    function setMintableTotalSupplyGM(uint16 total) external onlyOwner {
        mintableTotalSupplyGM = total;
    }

    function setMintableTotalSupplyAGM(uint16 total) external onlyOwner {
        mintableTotalSupplyAGM = total;
    }

    function setMintableTotalSupplyFO(uint16 total) external onlyOwner {
        mintableTotalSupplyFO = total;
    }

    function setTotalSupplyLimit(uint16 total) external onlyOwner {
        totalSupplyLimit = total;
    }

    function setDraftPriceGM(uint256 price) external onlyOwner {
        draftPriceGM = price;
    }

    function setDraftPriceAGM(uint256 price) external onlyOwner {
        draftPriceAGM = price;
    }

    function setDraftPriceFO(uint256 price) external onlyOwner {
        draftPriceFO = price;
    }

    function setPhase2AllowlistPrice(uint256 price) external onlyOwner {
        phase2AllowlistPrice = price;
    }

    function setPhase2PublicPrice(uint256 price) external onlyOwner {
        phase2PublicPrice = price;
    }

    /// PAUSABLE

    /// @dev Override to handle the pause state. No using OZ Pausable because it adds event logging which is not needed.
    /// See {ERC721A-_beforeTokenTransfers}.
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual override {
        super._beforeTokenTransfers(from, to, startTokenId, quantity);
        if (paused) revert ContractPaused();
    }

    /// GASLESS PROXIES

    /// @dev Override to approve OpenSea and Rarible proxy contracts for gas-less trading
    function isApprovedForAll(address owner, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        for (uint256 i = 0; i < approvedProxies.length; ++i) {
            ProxyRegistry proxyRegistry = ProxyRegistry(approvedProxies[i]);
            if (address(proxyRegistry.proxies(owner)) == operator) {
                return true;
            }
        }

        return super.isApprovedForAll(owner, operator);
    }

    /// OVERRIDES

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC721A, Banker)
        returns (bool)
    {
        return ERC721A.supportsInterface(interfaceId) || Banker.supportsInterface(interfaceId);
    }

    /// MODIFIERS

    modifier isPhase(Phase phase_) {
        if (phase != phase_) {
            revert SaleIsNotOpen();
        }

        _;
    }

    modifier isSale(Sale sale_) {
        if (sale != sale_) {
            revert SaleIsNotOpen();
        }

        _;
    }

    modifier totalSupplyNotReached(uint256 quantity) {
        if (_totalMinted() + quantity > totalSupplyLimit) {
            revert NotEnoughSupply();
        }

        _;
    }

    modifier maxQuantityPerTxNotReached(uint256 quantity) {
        if (quantity > maxMintPerTx) {
            revert MaxQuantityPerTxReached();
        }

        _;
    }

    modifier withProperFunds(uint256 quantity, uint256 price) {
        if (msg.value != quantity * price) {
            revert InvalidFunds();
        }

        _;
    }
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';

/**
 * @dev ERC721 token receiver interface.
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
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard,
 * including the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at `_startTokenId()`
 * (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is IERC721A {
    // Mask of an entry in packed address data.
    uint256 private constant BITMASK_ADDRESS_DATA_ENTRY = (1 << 64) - 1;

    // The bit position of `numberMinted` in packed address data.
    uint256 private constant BITPOS_NUMBER_MINTED = 64;

    // The bit position of `numberBurned` in packed address data.
    uint256 private constant BITPOS_NUMBER_BURNED = 128;

    // The bit position of `aux` in packed address data.
    uint256 private constant BITPOS_AUX = 192;

    // Mask of all 256 bits in packed address data except the 64 bits for `aux`.
    uint256 private constant BITMASK_AUX_COMPLEMENT = (1 << 192) - 1;

    // The bit position of `startTimestamp` in packed ownership.
    uint256 private constant BITPOS_START_TIMESTAMP = 160;

    // The bit mask of the `burned` bit in packed ownership.
    uint256 private constant BITMASK_BURNED = 1 << 224;

    // The bit position of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITPOS_NEXT_INITIALIZED = 225;

    // The bit mask of the `nextInitialized` bit in packed ownership.
    uint256 private constant BITMASK_NEXT_INITIALIZED = 1 << 225;

    // The bit position of `extraData` in packed ownership.
    uint256 private constant BITPOS_EXTRA_DATA = 232;

    // Mask of all 256 bits in a packed ownership except the 24 bits for `extraData`.
    uint256 private constant BITMASK_EXTRA_DATA_COMPLEMENT = (1 << 232) - 1;

    // The mask of the lower 160 bits for addresses.
    uint256 private constant BITMASK_ADDRESS = (1 << 160) - 1;

    // The maximum `quantity` that can be minted with `_mintERC2309`.
    // This limit is to prevent overflows on the address data entries.
    // For a limit of 5000, a total of 3.689e15 calls to `_mintERC2309`
    // is required to cause an overflow, which is unrealistic.
    uint256 private constant MAX_MINT_ERC2309_QUANTITY_LIMIT = 5000;

    // The tokenId of the next token to be minted.
    uint256 private _currentIndex;

    // The number of tokens burned.
    uint256 private _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned.
    // See `_packedOwnershipOf` implementation for details.
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
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

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
    function _nextTokenId() internal view returns (uint256) {
        return _currentIndex;
    }

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see `_totalMinted`.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than `_currentIndex - _startTokenId()` times.
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * @dev Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to `_startTokenId()`
        unchecked {
            return _currentIndex - _startTokenId();
        }
    }

    /**
     * @dev Returns the total number of tokens burned.
     */
    function _totalBurned() internal view returns (uint256) {
        return _burnCounter;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        // The interface IDs are constants representing the first 4 bytes of the XOR of
        // all function selectors in the interface. See: https://eips.ethereum.org/EIPS/eip-165
        // e.g. `bytes4(i.functionA.selector ^ i.functionB.selector ^ ...)`
        return
            interfaceId == 0x01ffc9a7 || // ERC165 interface ID for ERC165.
            interfaceId == 0x80ac58cd || // ERC165 interface ID for ERC721.
            interfaceId == 0x5b5e139f; // ERC165 interface ID for ERC721Metadata.
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return _packedAddressData[owner] & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_MINTED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return (_packedAddressData[owner] >> BITPOS_NUMBER_BURNED) & BITMASK_ADDRESS_DATA_ENTRY;
    }

    /**
     * Returns the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return uint64(_packedAddressData[owner] >> BITPOS_AUX);
    }

    /**
     * Sets the auxiliary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        uint256 packed = _packedAddressData[owner];
        uint256 auxCasted;
        // Cast `aux` with assembly to avoid redundant masking.
        assembly {
            auxCasted := aux
        }
        packed = (packed & BITMASK_AUX_COMPLEMENT) | (auxCasted << BITPOS_AUX);
        _packedAddressData[owner] = packed;
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
                    if (packed & BITMASK_BURNED == 0) {
                        // Invariant:
                        // There will always be an ownership that has an address and is not burned
                        // before an ownership that does not have an address and is not burned.
                        // Hence, curr will not underflow.
                        //
                        // We can directly compare the packed value.
                        // If the address is zero, packed is zero.
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
     * Returns the unpacked `TokenOwnership` struct from `packed`.
     */
    function _unpackedOwnership(uint256 packed) private pure returns (TokenOwnership memory ownership) {
        ownership.addr = address(uint160(packed));
        ownership.startTimestamp = uint64(packed >> BITPOS_START_TIMESTAMP);
        ownership.burned = packed & BITMASK_BURNED != 0;
        ownership.extraData = uint24(packed >> BITPOS_EXTRA_DATA);
    }

    /**
     * Returns the unpacked `TokenOwnership` struct at `index`.
     */
    function _ownershipAt(uint256 index) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnerships[index]);
    }

    /**
     * @dev Initializes the ownership slot minted at `index` for efficiency purposes.
     */
    function _initializeOwnershipAt(uint256 index) internal {
        if (_packedOwnerships[index] == 0) {
            _packedOwnerships[index] = _packedOwnershipOf(index);
        }
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        return _unpackedOwnership(_packedOwnershipOf(tokenId));
    }

    /**
     * @dev Packs ownership data into a single uint256.
     */
    function _packOwnershipData(address owner, uint256 flags) private view returns (uint256 result) {
        assembly {
            // Mask `owner` to the lower 160 bits, in case the upper bits somehow aren't clean.
            owner := and(owner, BITMASK_ADDRESS)
            // `owner | (block.timestamp << BITPOS_START_TIMESTAMP) | flags`.
            result := or(owner, or(shl(BITPOS_START_TIMESTAMP, timestamp()), flags))
        }
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return address(uint160(_packedOwnershipOf(tokenId)));
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

    /**
     * @dev Returns the `nextInitialized` flag set if `quantity` equals 1.
     */
    function _nextInitializedFlag(uint256 quantity) private pure returns (uint256 result) {
        // For branchless setting of the `nextInitialized` flag.
        assembly {
            // `(quantity == 1) << BITPOS_NEXT_INITIALIZED`.
            result := shl(BITPOS_NEXT_INITIALIZED, eq(quantity, 1))
        }
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ownerOf(tokenId);

        if (_msgSenderERC721A() != owner)
            if (!isApprovedForAll(owner, _msgSenderERC721A())) {
                revert ApprovalCallerNotOwnerNorApproved();
            }

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSenderERC721A()) revert ApproveToCaller();

        _operatorApprovals[_msgSenderERC721A()][operator] = approved;
        emit ApprovalForAll(_msgSenderERC721A(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, '');
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
        transferFrom(from, to, tokenId);
        if (to.code.length != 0)
            if (!_checkContractOnERC721Received(from, to, tokenId, _data)) {
                revert TransferToNonERC721ReceiverImplementer();
            }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            _startTokenId() <= tokenId &&
            tokenId < _currentIndex && // If within bounds,
            _packedOwnerships[tokenId] & BITMASK_BURNED == 0; // and not burned.
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
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
    ) internal {
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
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event for each mint.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
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
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

            // Updates:
            // - `address` to the owner.
            // - `startTimestamp` to the timestamp of minting.
            // - `burned` to `false`.
            // - `nextInitialized` to `quantity == 1`.
            _packedOwnerships[startTokenId] = _packOwnershipData(
                to,
                _nextInitializedFlag(quantity) | _nextExtraData(address(0), to, 0)
            );

            uint256 tokenId = startTokenId;
            uint256 end = startTokenId + quantity;
            do {
                emit Transfer(address(0), to, tokenId++);
            } while (tokenId < end);

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
    function _mintERC2309(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();
        if (quantity > MAX_MINT_ERC2309_QUANTITY_LIMIT) revert MintERC2309QuantityExceedsLimit();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are unrealistic due to the above check for `quantity` to be below the limit.
        unchecked {
            // Updates:
            // - `balance += quantity`.
            // - `numberMinted += quantity`.
            //
            // We can directly add to the `balance` and `numberMinted`.
            _packedAddressData[to] += quantity * ((1 << BITPOS_NUMBER_MINTED) | 1);

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
     * @dev Returns the storage slot and value for the approved address of `tokenId`.
     */
    function _getApprovedAddress(uint256 tokenId)
        private
        view
        returns (uint256 approvedAddressSlot, address approvedAddress)
    {
        mapping(uint256 => address) storage tokenApprovalsPtr = _tokenApprovals;
        // The following is equivalent to `approvedAddress = _tokenApprovals[tokenId]`.
        assembly {
            // Compute the slot.
            mstore(0x00, tokenId)
            mstore(0x20, tokenApprovalsPtr.slot)
            approvedAddressSlot := keccak256(0x00, 0x40)
            // Load the slot's value from storage.
            approvedAddress := sload(approvedAddressSlot)
        }
    }

    /**
     * @dev Returns whether the `approvedAddress` is equals to `from` or `msgSender`.
     */
    function _isOwnerOrApproved(
        address approvedAddress,
        address from,
        address msgSender
    ) private pure returns (bool result) {
        assembly {
            // Mask `from` to the lower 160 bits, in case the upper bits somehow aren't clean.
            from := and(from, BITMASK_ADDRESS)
            // Mask `msgSender` to the lower 160 bits, in case the upper bits somehow aren't clean.
            msgSender := and(msgSender, BITMASK_ADDRESS)
            // `msgSender == from || msgSender == approvedAddress`.
            result := or(eq(msgSender, from), eq(msgSender, approvedAddress))
        }
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        // The nested ifs save around 20+ gas over a compound boolean condition.
        if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
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
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
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
                BITMASK_NEXT_INITIALIZED | _nextExtraData(from, to, prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
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

        (uint256 approvedAddressSlot, address approvedAddress) = _getApprovedAddress(tokenId);

        if (approvalCheck) {
            // The nested ifs save around 20+ gas over a compound boolean condition.
            if (!_isOwnerOrApproved(approvedAddress, from, _msgSenderERC721A()))
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
            // This is equivalent to `packed -= 1; packed += 1 << BITPOS_NUMBER_BURNED;`.
            _packedAddressData[from] += (1 << BITPOS_NUMBER_BURNED) - 1;

            // Updates:
            // - `address` to the last owner.
            // - `startTimestamp` to the timestamp of burning.
            // - `burned` to `true`.
            // - `nextInitialized` to `true`.
            _packedOwnerships[tokenId] = _packOwnershipData(
                from,
                (BITMASK_BURNED | BITMASK_NEXT_INITIALIZED) | _nextExtraData(from, address(0), prevOwnershipPacked)
            );

            // If the next slot may not have been initialized (i.e. `nextInitialized == false`) .
            if (prevOwnershipPacked & BITMASK_NEXT_INITIALIZED == 0) {
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

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
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

    /**
     * @dev Directly sets the extra data for the ownership data `index`.
     */
    function _setExtraDataAt(uint256 index, uint24 extraData) internal {
        uint256 packed = _packedOwnerships[index];
        if (packed == 0) revert OwnershipNotInitializedForExtraData();
        uint256 extraDataCasted;
        // Cast `extraData` with assembly to avoid redundant masking.
        assembly {
            extraDataCasted := extraData
        }
        packed = (packed & BITMASK_EXTRA_DATA_COMPLEMENT) | (extraDataCasted << BITPOS_EXTRA_DATA);
        _packedOwnerships[index] = packed;
    }

    /**
     * @dev Returns the next extra data for the packed ownership data.
     * The returned result is shifted into position.
     */
    function _nextExtraData(
        address from,
        address to,
        uint256 prevOwnershipPacked
    ) private view returns (uint256) {
        uint24 extraData = uint24(prevOwnershipPacked >> BITPOS_EXTRA_DATA);
        return uint256(_extraData(from, to, extraData)) << BITPOS_EXTRA_DATA;
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred.
     * This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred.
     * This includes minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
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
     * @dev Returns the message sender (defaults to `msg.sender`).
     *
     * If you are writing GSN compatible contracts, you need to override this function.
     */
    function _msgSenderERC721A() internal view virtual returns (address) {
        return msg.sender;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function _toString(uint256 value) internal pure returns (string memory ptr) {
        assembly {
            // The maximum value of a uint256 contains 78 digits (1 byte per digit),
            // but we allocate 128 bytes to keep the free memory pointer 32-byte word aliged.
            // We will need 1 32-byte word to store the length,
            // and 3 32-byte words to store a maximum of 78 digits. Total: 32 + 3 * 32 = 128.
            ptr := add(mload(0x40), 128)
            // Update the free memory pointer to allocate.
            mstore(0x40, ptr)

            // Cache the end of the memory to calculate the length later.
            let end := ptr

            // We write the string from the rightmost digit to the leftmost digit.
            // The following is essentially a do-while loop that also handles the zero case.
            // Costs a bit more than early returning for the zero case,
            // but cheaper in terms of deployment and overall runtime costs.
            for {
                // Initialize and perform the first pass without check.
                let temp := value
                // Move the pointer 1 byte leftwards to point to an empty character slot.
                ptr := sub(ptr, 1)
                // Write the character to the pointer. 48 is the ASCII index of '0'.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
            } temp {
                // Keep dividing `temp` until zero.
                temp := div(temp, 10)
            } {
                // Body of the for loop.
                ptr := sub(ptr, 1)
                mstore8(ptr, add(48, mod(temp, 10)))
            }

            let length := sub(end, ptr)
            // Move the pointer 32 bytes leftwards to make room for the length.
            ptr := sub(ptr, 32)
            // Store the length.
            mstore(ptr, length)
        }
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be proved to be a part of a Merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] calldata leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and the sibling nodes in `proof`,
     * consuming from one or the other at each step according to the instructions given by
     * `proofFlags`.
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] calldata leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.13;

import {Owned} from "solmate/auth/Owned.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {IERC165} from "openzeppelin/utils/introspection/IERC165.sol";
import {IERC2981} from "openzeppelin/interfaces/IERC2981.sol";

error InvalidPayees();
error InvalidAccount();
error NoFundsAvailable();
error WithdrawalFailed();

struct Payee {
    address payable account;
    uint64 shares;
}

abstract contract Banker is IERC2981, Owned, ReentrancyGuard {
    uint256 constant TOTAL_SHARES = 10_000;
    address payable _teamAccount;
    uint64 _teamShares;
    address payable _devAccount;
    uint64 _devShares;
    address payable _royaltiesAccount;
    uint64 _royalties;

    constructor(
        Payee memory team,
        Payee memory dev,
        Payee memory royalties
    ) {
        if ((team.shares + dev.shares != TOTAL_SHARES) || royalties.shares > TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _teamAccount = team.account;
        _teamShares = team.shares;
        _devAccount = dev.account;
        _devShares = dev.shares;
        _royaltiesAccount = royalties.account;
        _royalties = royalties.shares;
    }

    function withdraw() external nonReentrant {
        if (address(this).balance < 10_000) {
            revert NoFundsAvailable();
        }

        // Shares are verified in constructor to accumulate to 10_000,
        // the possibility of an overflow is unrealistic
        uint256 devFunds;
        uint256 teamFunds;
        unchecked {
            devFunds = (address(this).balance * _devShares) / TOTAL_SHARES;
            teamFunds = (address(this).balance * _teamShares) / TOTAL_SHARES;
        }

        /// Transfer the amount to the account
        (bool devSuccess, ) = _devAccount.call{value: devFunds}("");
        (bool teamSuccess, ) = _teamAccount.call{value: teamFunds}("");
        if (!devSuccess || !teamSuccess) revert WithdrawalFailed();
    }

    /// @inheritdoc IERC2981
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        virtual
        override
        returns (address, uint256)
    {
        return (_royaltiesAccount, (_salePrice * _royalties) / TOTAL_SHARES);
    }

    /// ADMIN

    function setDevAccount(address payable account) external onlyOwner {
        _devAccount = account;
    }

    function setTeamAccount(address payable account) external onlyOwner {
        _teamAccount = account;
    }

    function setRoyaltiesAccount(address payable account) external onlyOwner {
        _royaltiesAccount = account;
    }

    function setShares(uint64 team, uint64 dev) external onlyOwner {
        if (team + dev != TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _teamShares = team;
        _devShares = dev;
    }

    function setRoyalties(uint64 royalties) external onlyOwner {
        if (royalties > TOTAL_SHARES) {
            revert InvalidPayees();
        }

        _royalties = royalties;
    }

    /// @dev See {IERC165-supportsInterface}.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId || interfaceId == type(IERC165).interfaceId;
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
// ERC721A Contracts v4.1.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of an ERC721A compliant contract.
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
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

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
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
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

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set through `_extraData`.
        uint24 extraData;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     *
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);

    // ==============================
    //            IERC165
    // ==============================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // ==============================
    //            IERC721
    // ==============================

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

    // ==============================
    //        IERC721Metadata
    // ==============================

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

    // ==============================
    //            IERC2309
    // ==============================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId` (inclusive) is transferred from `from` to `to`,
     * as defined in the ERC2309 standard. See `_mintERC2309` for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Gas optimized reentrancy protection for smart contracts.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/utils/ReentrancyGuard.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol)
abstract contract ReentrancyGuard {
    uint256 private locked = 1;

    modifier nonReentrant() virtual {
        require(locked == 1, "REENTRANCY");

        locked = 2;

        _;

        locked = 1;
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