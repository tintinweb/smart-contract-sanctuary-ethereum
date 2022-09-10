/**
 *Submitted for verification at Etherscan.io on 2022-09-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

// AirdropperV1 Contract
//
//        {}..{}
//        (~~~~)
//       ( s__s )
//       ^^ ~~ ^^
//
// A Fragments DAO Construction

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IHashes is IERC721Enumerable {
    function deactivateTokens(
        address _owner,
        uint256 _proposalId,
        bytes memory _signature
    ) external returns (uint256);

    function deactivated(uint256 _tokenId) external view returns (bool);

    function activationFee() external view returns (uint256);

    function verify(
        uint256 _tokenId,
        address _minter,
        string memory _phrase
    ) external view returns (bool);

    function getHash(uint256 _tokenId) external view returns (bytes32);

    function getPriorVotes(address account, uint256 blockNumber) external view returns (uint256);

    function governanceCap() external view returns (uint256);
}

interface ICollectionNFTMintFeePredicate {
    function getTokenMintFee(uint256 _tokenId, uint256 _hashesTokenId) external view returns (uint256);
}

interface ICollectionNFTEligibilityPredicate {
    function isTokenEligibleToMint(uint256 _tokenId, uint256 _hashesTokenId) external view returns (bool);
}

interface ICollectionNFTCloneableV1 {
    function mint(uint256 _hashesTokenId) external payable;

    function burn(uint256 _tokenId) external;

    function completeSignatureBlock() external;

    function setBaseTokenURI(string memory _baseTokenURI) external;

    function setRoyaltyBps(uint16 _royaltyBps) external;

    function transferCreator(address _creatorAddress) external;

    function setSignatureBlockAddress(address _signatureBlockAddress) external;

    function withdraw() external;

    function hashesIdToCollectionTokenIdMapping(uint256 _hashesTokenId)
        external
        view
        returns (bool exists, uint128 tokenId);

    function nonce() external view returns (uint256);

    function cap() external view returns (uint256);

    function mintEligibilityPredicateContract() external view returns (ICollectionNFTEligibilityPredicate);

    function mintFeePredicateContract() external view returns (ICollectionNFTMintFeePredicate);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IAirdropperV1 {

    function mintAndAirdropHashesERC721sToRecipients(
        ICollectionNFTCloneableV1 _collection,
        address[] memory _recipients
    ) external payable;

    function withdraw() external;
}

contract ReentrancyGuard {
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
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
 * @title  AirdropperV1
 * @author Cooki.eth
 * @notice This contract has three core use-cases and functions. Firstly, the
 *         mintAndAirdropHashesERC721sToRecipients function allows anyone to
 *         mass mint and distribute a Hashes NFT to a specified set of recipient
 *         addresses. Secondly, the airdropERC721sToRecipients function allows
 *         anyone to distribute the NFTs from a specified collection that they
 *         hold in their wallet to a specified set of recipient addresses. Thirdly,
 *         the sendAllERC721sToAddress function allows anyone to send all of the
 *         NFTs from a specified collection that they hold in their wallet to
 *         another specified address. In order to use any of these functions the
 *         user must pay a flat fee of 0.01ETH. This fee is then distributed in
 *         three ways. 0.0045ETH is distributed to each of the Hashes DAO and the
 *         creator of this contract, while the remaining 0.001ETH is held by the
 *         contract as a bounty for anyone to claim in exchange for depositing
 *         Hashes NFTs to the contract. WARNING: DEPOSITED HASHES NFTS ARE LOCKED
 *         FOREVER! This contract requires Hashes NFTs in order for the
 *         mintAndAirdropHashesERC721sToRecipients function to work.
 */
contract AirdropperV1 is IAirdropperV1, Ownable, ReentrancyGuard, IERC721Receiver {
    /// @notice The combined balance of the Owner and the Hashes DAO.
    uint256 public ownerAndHashesBalance;

    /// @notice The bounty that can be claimed by anyone for depositing a hashes NFT to this contract.
    uint256 public NFTbounty;

    /// @notice The cap on the number of NFTs that can be minted/sent with any function call. Hashes NFT depositors have this cap permanently raised to 100 for the airdropERC721sToRecipients and sendAllERC721sToAddress functions.
    uint256 public cap = 25;

    /// @notice This mapping tracks Hashes NFT depositors to the AirdropperV1 contract. They are permanetly entitled to the perk of a raised cap on sending and airdropping NFTs to 100.
    mapping(address => bool) public depositor;

    /// @notice The flat fee that is charged in order to use any of the three core functions of this contract.
    uint256 public fee = 0.01e18;

    /// @notice The array of hashes NFT ids owned by this contract. These are locked permanently!
    uint256[] public hashesOwnedByAirdropperV1;

    /// @notice The Hashes NFT token address.
    IHashes public hashesToken;

    /// @notice The Hashes DAO address that will recieve revenue from this contract.
    address public hashesDAO = 0xbD3Af18e0b7ebB30d49B253Ab00788b92604552C;

    /// @notice An array of hashes that have been deposited.
    event HashDeposited(uint256 indexed _hashesId);

    /// @notice The total ammount withdrawn to both the Hashes DAO and the Owner.
    event Withdrawal(uint256 indexed _ammount);

    /**
     * @notice Constructor for the AirdropperV1 contract. The Hashes NFT token address
     *         is specified when the contract is deployed.
     */
    constructor(IHashes _hashesToken) {
        hashesToken = _hashesToken;
    }

    /**
     * @notice This function allows anyone to mass mint and distribute a Hashes NFT to a specified set
     *         of recipient addresses.
     * @param _collection The address of the Hashes NFT collection (either CollectionNFTCloneableV1
     *         or V2 format accepted).
     * @param _recipients An array recipient (reciever) addresses. Each recipient address will recieve
     *         one NFT each.
     */
    function mintAndAirdropHashesERC721sToRecipients(
        ICollectionNFTCloneableV1 _collection,
        address[] memory _recipients
    ) external payable override nonReentrant {
        //this keeps track of collection position to mint
        uint256 tokenNonce = _collection.nonce();
        //this keeps track of the number of NFTs minted
        uint256 numberMinted = 0;
        //Index used in the while-loop to iterate over the hashesowned array
        uint256 index = 0;
        //the mint fee for any given NFT
        uint256 mintFeeTemp = 0;
        //the cumulative mint fee for every NFT to be minted
        uint256 mintFeeCumulative = 0;

        require(_recipients.length > 0, "AirdropperV1: no recipient addresses provided.");

        require(_recipients.length <= cap, "AirdropperV1: too many recipients. The maximum is 25.");

        require(
            (tokenNonce + _recipients.length) < _collection.cap(),
            "AirdropperV1: ineligible to mint to all recipients."
        );

        require(
            _recipients.length <= hashesOwnedByAirdropperV1.length,
            "AirdropperV1: insufficient number of Hashes NFTs held by the AirdropperV1 contract. Please deposit additional Hashes NFTs."
        );

        while ((numberMinted < _recipients.length) && (index < hashesOwnedByAirdropperV1.length)) {
            if (
                !getMappingExists(hashesOwnedByAirdropperV1[index], _collection) &&
                _collection.mintEligibilityPredicateContract().isTokenEligibleToMint(
                    tokenNonce,
                    hashesOwnedByAirdropperV1[index]
                )
            ) {
                mintFeeTemp = _collection.mintFeePredicateContract().getTokenMintFee(
                    tokenNonce,
                    hashesOwnedByAirdropperV1[index]
                );

                mintFeeCumulative += mintFeeTemp;

                require(msg.value >= uint256(fee + mintFeeCumulative), "AirdropperV1: must pass sufficient mint fee.");

                _collection.mint{ value: (1 wei) * mintFeeTemp }(hashesOwnedByAirdropperV1[index]);

                _collection.safeTransferFrom(address(this), _recipients[numberMinted], tokenNonce);

                tokenNonce++;
                numberMinted++;
            }

            index++;
        }

        //This makes sure that there was the correct number of NFTs minted and distrubuted (no more, or less)
        require(
            numberMinted == _recipients.length,
            "AirdropperV1: either some airdropperV1 Hashes NFTs have already been used to mint this collection, or some airdropperV1 Hashes NFTs are ineligible for minting this collection. Either way, please deposit additional Hashes NFTs."
        );
        //Updates internal balance metrics
        updateBalances();
    }

    /**
     * @notice This function allows anyone to distribute the NFTs from a specified collection that they
     *         hold in their wallet to a specified set of recipient addresses.
     * @param _collection The address of the ERC721 collection (either Hashes or non-Hashes collections
     *         are accepted).
     * @param _nftIDs The array of NFT ids that will be distributed. The order of the ids in this array
     *         will correspond to the order of the recipients (e.g. the first NFT id will go to the first
     *         recipient, the second id will go to the second recipient, etc.).
     * @param _recipients An array recipient (reciever) addresses. Each recipient address will recieve
     *         one NFT each.
     */
    function airdropERC721sToRecipients(
        IERC721 _collection,
        uint256[] memory _nftIDs,
        address[] memory _recipients
    ) external payable nonReentrant {
        require(
            _collection.isApprovedForAll(msg.sender, address(this)),
            "AirdropperV1: has not been approved to send these NFTs from your wallet. Please approve the AirdropperV1 contract for all first."
        );

        require(msg.value >= fee, "AirdropperV1: must pass sufficient mint fee.");

        require(_recipients.length > 0, "AirdropperV1: no recipient addresses provided.");

        uint256 perk = 0;

        if (depositor[msg.sender]) {
            perk = 75;
        }

        require(
            _recipients.length <= (cap + perk),
            "AirdropperV1: too many recipients. The maximum is 25 (Unless you have deposited a hashes NFT, then it's 100)."
        );

        require(
            _nftIDs.length == _recipients.length,
            "AirdropperV1: Ids and recipient arrays provided are of unequal length."
        );

        for (uint256 j = 0; j < _recipients.length; j++) {
            _collection.safeTransferFrom(msg.sender, _recipients[j], _nftIDs[j]);
        }

        updateBalances();
    }

    /**
     * @notice This function allows anyone to send all of the NFTs from a specified collection that
     *         they hold in their wallet to another specified address.
     * @param _collection The address of the ERC721 collection (either Hashes or non-Hashes collections
     *         are accepted).
     * @param _nftIDs The array of NFT ids that will be distributed.
     * @param _recipient The address that will recieve the NFTs.
     */
    function sendAllERC721sToAddress(
        IERC721 _collection,
        uint256[] memory _nftIDs,
        address _recipient
    ) external payable nonReentrant {
        require(
            _collection.isApprovedForAll(msg.sender, address(this)),
            "AirdropperV1: has not been approved to send these NFTs from your wallet. Please approve the AirdropperV1 contract for all first."
        );

        require(msg.value >= fee, "AirdropperV1: must pass sufficient mint fee.");

        require(_nftIDs.length > 0, "AirdropperV1: no NFT Ids provided.");

        uint256 perk = 0;

        if (depositor[msg.sender]) {
            perk = 75;
        }

        require(
            _nftIDs.length <= (cap + perk),
            "AirdropperV1: too many NFTs. The maximum is 25 (Unless you have deposited a hashes NFT, then it's 100)."
        );

        for (uint256 j = 0; j < _nftIDs.length; j++) {
            _collection.safeTransferFrom(msg.sender, _recipient, _nftIDs[j]);
        }

        updateBalances();
    }

    /**
     * @notice WARNING: DEPOSITED HASHES NFTS ARE LOCKED FOREVER! This function allows anyone to
     *         deposit Hashes NFTs to the AirdropperV1 contract, thereby improving the functionality of
     *         this contract. If there is a bounty that has accrued from past usage the depositor will
     *         be paid the bounty in full.
     * @param _hashesIds An array of Hashes NFT ids that
     */
    function depositHashes(uint256[] memory _hashesIds) external nonReentrant {
        require(_hashesIds.length > 0, "AirdropperV1: no Hashes NFT Ids provided.");

        require(
            hashesToken.isApprovedForAll(msg.sender, address(this)),
            "AirdropperV1: has not been approved to send these NFTs from your wallet. Please approve the AirdropperV1 contract for all first."
        );

        for (uint256 i = 0; i < _hashesIds.length; i++) {
            hashesToken.safeTransferFrom(msg.sender, address(this), _hashesIds[i]);
            hashesOwnedByAirdropperV1.push(_hashesIds[i]);
            emit HashDeposited(_hashesIds[i]);
        }

        if (NFTbounty > 0) {
            (bool success, ) = (msg.sender).call{ value: NFTbounty }("");
            require(success, "AirdropperV1: transfer to depositer failed.");

            NFTbounty = 0;
        }

        depositor[msg.sender] = true;
    }

    /**
     * @notice This function allows the owner to claim and distribute the revenue generated from this contract.
     */
    function withdraw() external override onlyOwner nonReentrant {
        require(ownerAndHashesBalance > 0, "AirdropperV1: no funds to withdraw.");

        (bool success, ) = (msg.sender).call{ value: (ownerAndHashesBalance / 2) }("");
        require(success, "AirdropperV1: transfer to owner failed.");

        (bool success1, ) = (hashesDAO).call{ value: (ownerAndHashesBalance / 2) }("");
        require(success1, "AirdropperV1: transfer to HashesDAO failed.");

        emit Withdrawal(ownerAndHashesBalance);

        ownerAndHashesBalance = 0;
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function updateBalances() private {
        ownerAndHashesBalance += 0.009e18;
        NFTbounty += 0.001e18;
    }

    function getMappingExists(uint256 _hashesID, ICollectionNFTCloneableV1 _address) private view returns (bool) {
        (bool exists, ) = _address.hashesIdToCollectionTokenIdMapping(_hashesID);
        return exists;
    }
}