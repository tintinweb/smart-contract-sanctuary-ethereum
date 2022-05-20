// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity =0.8.9;

import '../interfaces/IERC721Upgradeable.sol';
import '../interfaces/IERC721ReceiverUpgradeable.sol';
import '../extensions/IERC721MetadataUpgradeable.sol';
import '../utils/AddressUpgradeable.sol';
import '../metatx/ERC2771ContextUpgradeable.sol';
import '../utils/StringsUpgradeable.sol';
import '../utils/introspection/ERC165Upgradeable.sol';
import '../proxy/Initializable.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */

contract ERC721Upgradeable is Initializable, ERC2771ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), 'ERC721: balance query for the zero address');
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), 'ERC721: owner query for nonexistent token');
        return owner;
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
        require(_exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, 'ERC721: approval to current owner');

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()), 'ERC721: approve caller is not owner nor approved for all');

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), 'ERC721: transfer caller is not owner nor approved');
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
        require(_checkOnERC721Received(from, to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, '');
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), 'ERC721: transfer to non ERC721Receiver implementer');
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), 'ERC721: mint to the zero address');
        require(!_exists(tokenId), 'ERC721: token already minted');

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
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
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, 'ERC721: transfer from incorrect owner');
        require(to != address(0), 'ERC721: transfer to the zero address');

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, 'ERC721: approve to caller');
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721: transfer to non ERC721Receiver implementer');
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

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    uint256[44] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {ERC721Upgradeable} from './ERC721/ERC721Upgradeable.sol';
import {OwnableUpgradeable} from './access/OwnableUpgradeable.sol';
import {Initializable} from './proxy/Initializable.sol';
import {IUnifarmNFTManagerUpgradeable} from './interfaces/IUnifarmNFTManagerUpgradeable.sol';
import {IUnifarmCohort} from './interfaces/IUnifarmCohort.sol';
import {TransferHelpers} from './library/TransferHelpers.sol';
import {IUnifarmNFTDescriptorUpgradeable} from './interfaces/IUnifarmNFTDescriptorUpgradeable.sol';
import {CohortHelper} from './library/CohortHelper.sol';
import {ReentrancyGuardUpgradeable} from './utils/ReentrancyGuardUpgradeable.sol';

/// @title UnifarmNFTManagerUpgradeable Contract
/// @author UNIFARM
/// @notice NFT manager handles Unifarm cohort Stake/Unstake/Claim

contract UnifarmNFTManagerUpgradeable is
    IUnifarmNFTManagerUpgradeable,
    Initializable,
    ERC721Upgradeable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable
{
    /// @notice reciveing ETH
    receive() external payable {}

    /// @notice struct to hold cohort fees configuration
    struct FeeConfiguration {
        // protocol fee wallet address
        address payable feeWalletAddress;
        // protocol fee amount
        uint256 feeAmount;
    }

    /// @notice global fees pointer for all cohorts
    FeeConfiguration public fees;

    /// @notice factory contract address
    address public factory;

    /// @dev next token Id that will be minted
    uint256 private _id;

    /// @notice nft descriptor contract address
    address public nftDescriptor;

    /// @notice store tokenId to cohortAddress
    mapping(uint256 => address) public tokenIdToCohortId;

    /**
    @notice initialize the NFT manager contract
    @param feeWalletAddress fee wallet address
    @param nftDescriptor_ nft descriptor contract address
    @param feeAmount protocol fee amount 
    */

    function __UnifarmNFTManagerUpgradeable_init(
        address payable feeWalletAddress,
        address nftDescriptor_,
        address factory_,
        address masterAddress,
        address trustedForwarder,
        uint256 feeAmount
    ) external initializer {
        __ERC721_init('Unifarm Staking Collection', 'UNIFARM-STAKES');
        __UnifarmNFTManagerUpgradeable_init_unchained(feeWalletAddress, nftDescriptor_, factory_, feeAmount);
        __Ownable_init(masterAddress, trustedForwarder);
    }

    function __UnifarmNFTManagerUpgradeable_init_unchained(
        address payable feeWalletAddress,
        address nftDescriptor_,
        address factory_,
        uint256 feeAmount
    ) internal {
        nftDescriptor = nftDescriptor_;
        factory = factory_;
        setFeeConfiguration(feeWalletAddress, feeAmount);
    }

    /**
     * @notice function to set fee configuration for protocol
     * @param  feeWalletAddress_ fee wallet address
     * @param feeAmount_ protocol fee amount
     */

    function setFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) internal {
        require(feeWalletAddress_ != address(0), 'IFWA');
        require(feeAmount_ > 0, 'IFA');
        fees = FeeConfiguration({feeWalletAddress: feeWalletAddress_, feeAmount: feeAmount_});
        emit FeeConfigurtionAdded(feeWalletAddress_, feeAmount_);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function updateFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) external override onlyOwner {
        setFeeConfiguration(feeWalletAddress_, feeAmount_);
    }

    /**
     * @notice tokenURI contains token metadata
     * @param tokenId NFT tokenId
     * @return base64 encoded token URI
     */

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        address cohortId = tokenIdToCohortId[tokenId];
        require(cohortId != address(0), 'ICI');
        return IUnifarmNFTDescriptorUpgradeable(nftDescriptor).generateTokenURI(cohortId, tokenId);
    }

    /**
     * @notice function handles stake on unifarm
     * @param cohortId cohort address
     * @param rAddress referral address
     * @param farmToken farmToken address
     * @param sAmount stake amount
     * @param fid farm id
     * @return tokenId minted NFT tokenId
     */

    function _stakeOnUnifarm(
        address cohortId,
        address rAddress,
        address farmToken,
        uint256 sAmount,
        uint32 fid
    ) internal returns (uint256 tokenId) {
        require(cohortId != address(0), 'ICI');
        _id++;
        _mint(_msgSender(), (tokenId = _id));
        tokenIdToCohortId[tokenId] = cohortId;
        TransferHelpers.safeTransferFrom(farmToken, _msgSender(), cohortId, sAmount);
        IUnifarmCohort(cohortId).stake(fid, tokenId, _msgSender(), rAddress);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function stakeOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 sAmount,
        uint32 farmId
    ) external override nonReentrant returns (uint256 tokenId) {
        (tokenId) = _stakeOnUnifarm(cohortId, referralAddress, farmToken, sAmount, farmId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function unstakeOnUnifarm(uint256 tokenId) external payable override nonReentrant {
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(msg.value >= fees.feeAmount, 'FAR');
        _burn(tokenId);
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).unStake(_msgSender(), tokenId, 0);
        TransferHelpers.safeTransferParentChainToken(fees.feeWalletAddress, fees.feeAmount);
        refundExcessEth((msg.value - fees.feeAmount));
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function claimOnUnifarm(uint256 tokenId) external payable override nonReentrant {
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(msg.value >= fees.feeAmount, 'FAR');
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).collectPrematureRewards(_msgSender(), tokenId);
        TransferHelpers.safeTransferParentChainToken(fees.feeWalletAddress, fees.feeAmount);
        refundExcessEth((msg.value - fees.feeAmount));
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function emergencyBurn(address user, uint256 tokenId) external onlyOwner {
        require(user == ownerOf(tokenId), 'INO');
        _burn(tokenId);
        address cohortId = tokenIdToCohortId[tokenId];
        IUnifarmCohort(cohortId).unStake(user, tokenId, 1);
    }

    /**
     * @notice refund excess fund
     * @param excess excess ETH value
     */

    function refundExcessEth(uint256 excess) internal {
        if (excess > 0) {
            TransferHelpers.safeTransferParentChainToken(_msgSender(), excess);
        }
    }

    /**
     * @notice buy booster pack for specific NFT tokenId
     * @param cohortId cohort Address
     * @param bpid booster pack Id
     * @param tokenId NFT tokenId for which booster pack to take
     */

    function _buyBooster(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) internal {
        (address registry, , ) = CohortHelper.getStorageContracts(factory);
        (, address paymentToken_, address boosterVault, uint256 boosterPackAmount) = CohortHelper.getBoosterPackDetails(registry, cohortId, bpid);
        require(_msgSender() == ownerOf(tokenId), 'INO');
        require(paymentToken_ != address(0), 'BNF');
        if (msg.value > 0) {
            require(msg.value >= boosterPackAmount, 'BAF');
            CohortHelper.depositWETH(paymentToken_, boosterPackAmount);
            TransferHelpers.safeTransfer(paymentToken_, boosterVault, boosterPackAmount);
            refundExcessEth((msg.value - boosterPackAmount));
        } else {
            TransferHelpers.safeTransferFrom(paymentToken_, _msgSender(), boosterVault, boosterPackAmount);
        }
        IUnifarmCohort(cohortId).buyBooster(_msgSender(), bpid, tokenId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function buyBoosterPackOnUnifarm(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) external payable override {
        require(cohortId != address(0), 'ICI');
        _buyBooster(cohortId, bpid, tokenId);
    }

    /**
     * @inheritdoc IUnifarmNFTManagerUpgradeable
     */

    function stakeAndBuyBoosterPackOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 bpid,
        uint256 sAmount,
        uint32 farmId
    ) external payable override returns (uint256 tokenId) {
        tokenId = _stakeOnUnifarm(cohortId, referralAddress, farmToken, sAmount, farmId);
        _buyBooster(cohortId, bpid, tokenId);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

abstract contract CohortFactory {
    /**
     * @notice factory owner
     * @return owner
     */
    function owner() public view virtual returns (address);

    /**
     * @notice derive storage contracts
     * @return registry contract address
     * @return nftManager contract address
     * @return rewardRegistry contract address
     */

    function getStorageContracts()
        public
        view
        virtual
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        );
}

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (access/Ownable.sol)

pragma solidity =0.8.9;

import {ERC2771ContextUpgradeable} from '../metatx/ERC2771ContextUpgradeable.sol';
import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner
 */

abstract contract OwnableUpgradeable is Initializable, ERC2771ContextUpgradeable {
    address private _owner;
    address private _master;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner
     */
    function __Ownable_init(address master, address trustedForwarder) internal initializer {
        __Ownable_init_unchained(master);
        __ERC2771ContextUpgradeable_init(trustedForwarder);
    }

    function __Ownable_init_unchained(address masterAddress) internal initializer {
        _transferOwnership(_msgSender());
        _master = masterAddress;
    }

    /**
     * @dev Returns the address of the current owner
     * @return _owner - _owner address
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), 'ONA');
        _;
    }

    /**
     * @dev Throws if called by any account other than the master
     */
    modifier onlyMaster() {
        require(_master == _msgSender(), 'OMA');
        _;
    }

    /**
     * @dev Transfering the owner ship to master role in case of emergency
     *
     * NOTE: Renouncing ownership will transfer the contract ownership to master role
     */

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(_master);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Can only be called by the current owner
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'INA');
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity =0.8.9;

import '../interfaces/IERC721Upgradeable.sol';

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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

// SPDX-License-Identifier: GNU GPLv3
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

pragma solidity =0.8.9;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GNU GPLv3

// OpenZeppelin Contracts v4.3.2 (token/ERC20/IERC20.sol)

pragma solidity =0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity =0.8.9;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: GNU GPLv3
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

pragma solidity =0.8.9;

import './IERC165Upgradeable.sol';

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmCohort Interface
/// @author UNIFARM
/// @notice unifarm cohort external functions
/// @dev All function calls are currently implemented without any side effects

interface IUnifarmCohort {
    /**
    @notice stake handler
    @dev function called by only nft manager
    @param fid farm id where you want to stake
    @param tokenId NFT token Id
    @param account user wallet Address
    @param referralAddress referral address for this stake
   */

    function stake(
        uint32 fid,
        uint256 tokenId,
        address account,
        address referralAddress
    ) external;

    /**
     * @notice unStake handler
     * @dev called by nft manager only
     * @param user user wallet Address
     * @param tokenId NFT Token Id
     * @param flag 1, if owner is caller
     */

    function unStake(
        address user,
        uint256 tokenId,
        uint256 flag
    ) external;

    /**
     * @notice allow user to collect rewards before cohort end
     * @dev called by NFT manager
     * @param user user address
     * @param tokenId NFT Token Id
     */

    function collectPrematureRewards(address user, uint256 tokenId) external;

    /**
     * @notice purchase a booster pack for particular token Id
     * @dev called by NFT manager or owner
     * @param user user wallet address who is willing to buy booster
     * @param bpid booster pack id to purchase booster
     * @param tokenId NFT token Id which booster to take
     */

    function buyBooster(
        address user,
        uint256 bpid,
        uint256 tokenId
    ) external;

    /**
     * @notice set portion amount for particular tokenId
     * @dev called by only owner access
     * @param tokenId NFT token Id
     * @param stakedAmount new staked amount
     */

    function setPortionAmount(uint256 tokenId, uint256 stakedAmount) external;

    /**
     * @notice disable booster for particular tokenId
     * @dev called by only owner access.
     * @param tokenId NFT token Id
     */

    function disableBooster(uint256 tokenId) external;

    /**
     * @dev rescue Ethereum
     * @param withdrawableAddress to address
     * @param amount to withdraw
     * @return Transaction status
     */

    function safeWithdrawEth(address withdrawableAddress, uint256 amount) external returns (bool);

    /**
     * @dev rescue all available tokens in a cohort
     * @param tokens list of tokens
     * @param amounts list of amounts to withdraw respectively
     */

    function safeWithdrawAll(
        address withdrawableAddress,
        address[] memory tokens,
        uint256[] memory amounts
    ) external;

    /**
     * @notice obtain staking details
     * @param tokenId - NFT Token id
     * @return fid the cohort farm id
     * @return nftTokenId the NFT token id
     * @return stakedAmount denotes staked amount
     * @return startBlock start block of particular user stake
     * @return endBlock end block of particular user stake
     * @return originalOwner wallet address
     * @return referralAddress the referral address of stake
     * @return isBooster denotes booster availability
     */

    function viewStakingDetails(uint256 tokenId)
        external
        view
        returns (
            uint32 fid,
            uint256 nftTokenId,
            uint256 stakedAmount,
            uint256 startBlock,
            uint256 endBlock,
            address originalOwner,
            address referralAddress,
            bool isBooster
        );

    /**
     * @notice emit on each booster purchase
     * @param nftTokenId NFT Token Id
     * @param user user wallet address who bought the booster
     * @param bpid booster pack id
     */

    event BoosterBuyHistory(uint256 indexed nftTokenId, address indexed user, uint256 bpid);

    /**
     * @notice emit on each claim
     * @param fid farm id.
     * @param tokenId NFT Token Id
     * @param userAddress NFT owner wallet address
     * @param referralAddress referral wallet address
     * @param rValue Aggregated R Value
     */

    event Claim(uint32 fid, uint256 indexed tokenId, address indexed userAddress, address indexed referralAddress, uint256 rValue);

    /**
     * @notice emit on each stake
     * @dev helps to derive referrals of unifarm cohort
     * @param tokenId NFT Token Id
     * @param referralAddress referral Wallet Address
     * @param stakedAmount user staked amount
     * @param fid farm id
     */

    event ReferedBy(uint256 indexed tokenId, address indexed referralAddress, uint256 stakedAmount, uint32 fid);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmCohortRegistryUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm Cohort Registry.

interface IUnifarmCohortRegistryUpgradeable {
    /**
     * @notice set tokenMetaData for a particular cohort farm
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param fid_ farm id
     * @param farmToken_ farm token address
     * @param userMinStake_ user minimum stake
     * @param userMaxStake_ user maximum stake
     * @param totalStakeLimit_ total stake limit
     * @param decimals_ token decimals
     * @param skip_ it can be skip or not during unstake
     */

    function setTokenMetaData(
        address cohortId,
        uint32 fid_,
        address farmToken_,
        uint256 userMinStake_,
        uint256 userMaxStake_,
        uint256 totalStakeLimit_,
        uint8 decimals_,
        bool skip_
    ) external;

    /**
     * @notice a function to set particular cohort details
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param cohortVersion_ cohort version
     * @param startBlock_ start block of a cohort
     * @param endBlock_ end block of a cohort
     * @param epochBlocks_ epochBlocks of a cohort
     * @param hasLiquidityMining_ true if lp tokens can be stake here
     * @param hasContainsWrappedToken_ true if wTokens exist in rewards
     * @param hasCohortLockinAvaliable_ cohort lockin flag
     */

    function setCohortDetails(
        address cohortId,
        string memory cohortVersion_,
        uint256 startBlock_,
        uint256 endBlock_,
        uint256 epochBlocks_,
        bool hasLiquidityMining_,
        bool hasContainsWrappedToken_,
        bool hasCohortLockinAvaliable_
    ) external;

    /**
     * @notice to add a booster pack in a particular cohort
     * @dev only called by owner access or multicall
     * @param cohortId_ cohort address
     * @param paymentToken_ payment token address
     * @param boosterVault_ booster vault address
     * @param bpid_ booster pack Id
     * @param boosterPackAmount_ booster pack amount
     */

    function addBoosterPackage(
        address cohortId_,
        address paymentToken_,
        address boosterVault_,
        uint256 bpid_,
        uint256 boosterPackAmount_
    ) external;

    /**
     * @notice update multicall contract address
     * @dev only called by owner access
     * @param newMultiCallAddress new multicall address
     */

    function updateMulticall(address newMultiCallAddress) external;

    /**
     * @notice lock particular cohort contract
     * @dev only called by owner access or multicall
     * @param cohortId cohort contract address
     * @param status true for lock vice-versa false for unlock
     */

    function setWholeCohortLock(address cohortId, bool status) external;

    /**
     * @notice lock particular cohort contract action. (`STAKE` | `UNSTAKE`)
     * @dev only called by owner access or multicall
     * @param cohortId cohort address
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortLockStatus(
        address cohortId,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice lock the particular farm action (`STAKE` | `UNSTAKE`) in a cohort
     * @param cohortSalt mixture of cohortId and tokenId
     * @param actionToLock magic value STAKE/UNSTAKE
     * @param status true for lock vice-versa false for unlock
     */

    function setCohortTokenLockStatus(
        bytes32 cohortSalt,
        bytes4 actionToLock,
        bool status
    ) external;

    /**
     * @notice validate cohort stake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice validate cohort unstake locking status
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(address cohortId, uint32 farmId) external view;

    /**
     * @notice get farm token details in a specific cohort
     * @param cohortId particular cohort address
     * @param farmId farmId of particular cohort
     * @return fid farm Id
     * @return farmToken farm Token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specific farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(address cohortId, uint32 farmId)
        external
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        );

    /**
     * @notice get specific cohort details
     * @param cohortId cohort address
     * @return cohortVersion specific cohort version
     * @return startBlock start block of a unifarm cohort
     * @return endBlock end block of a unifarm cohort
     * @return epochBlocks epoch blocks in particular cohort
     * @return hasLiquidityMining indicator for liquidity mining
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @return hasCohortLockinAvaliable denotes cohort lockin
     */

    function getCohort(address cohortId)
        external
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        );

    /**
     * @notice get booster pack details for a specific cohort
     * @param cohortId cohort address
     * @param bpid booster pack Id
     * @return cohortId_ cohort address
     * @return paymentToken_ payment token address
     * @return boosterVault booster vault address
     * @return boosterPackAmount booster pack amount
     */

    function getBoosterPackDetails(address cohortId, uint256 bpid)
        external
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        );

    /**
     * @notice emit on each farm token update
     * @param cohortId cohort address
     * @param farmToken farm token address
     * @param fid farm Id
     * @param userMinStake amount that user can minimum stake
     * @param userMaxStake amount that user can maximum stake
     * @param totalStakeLimit total stake limit for the specific farm
     * @param decimals farm token decimals
     * @param skip it can be skip or not during unstake
     */

    event TokenMetaDataDetails(
        address indexed cohortId,
        address indexed farmToken,
        uint32 indexed fid,
        uint256 userMinStake,
        uint256 userMaxStake,
        uint256 totalStakeLimit,
        uint8 decimals,
        bool skip
    );

    /**
     * @notice emit on each update of cohort details
     * @param cohortId cohort address
     * @param cohortVersion specific cohort version
     * @param startBlock start block of a unifarm cohort
     * @param endBlock end block of a unifarm cohort
     * @param epochBlocks epoch blocks in particular unifarm cohort
     * @param hasLiquidityMining indicator for liquidity mining
     * @param hasContainsWrappedToken true if contains wrapped token in cohort rewards
     * @param hasCohortLockinAvaliable denotes cohort lockin
     */

    event AddedCohortDetails(
        address indexed cohortId,
        string indexed cohortVersion,
        uint256 startBlock,
        uint256 endBlock,
        uint256 epochBlocks,
        bool indexed hasLiquidityMining,
        bool hasContainsWrappedToken,
        bool hasCohortLockinAvaliable
    );

    /**
     * @notice emit on update of each booster pacakge
     * @param cohortId the cohort address
     * @param bpid booster pack id
     * @param paymentToken the payment token address
     * @param boosterPackAmount the booster pack amount
     */

    event BoosterDetails(address indexed cohortId, uint256 indexed bpid, address paymentToken, uint256 boosterPackAmount);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;
pragma abicoder v2;

/// @title IUnifarmNFTDescriptorUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm NFT Manager Descriptor

interface IUnifarmNFTDescriptorUpgradeable {
    /**
     * @notice construct the Token Metadata
     * @param cohortId cohort address
     * @param tokenId NFT Token Id
     * @return base64 encoded Token Metadata
     */
    function generateTokenURI(address cohortId, uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

/// @title IUnifarmNFTManagerUpgradeable Interface
/// @author UNIFARM
/// @notice All External functions of Unifarm NFT Manager

interface IUnifarmNFTManagerUpgradeable {
    /**
     * @notice stake on unifarm
     * @dev make sure approve before calling this function
     * @dev minting NFT's
     * @param cohortId cohort contract address
     * @param referralAddress referral address
     * @param farmToken farm token address
     * @param sAmount staking amount
     * @param farmId cohort farm Id
     * @return tokenId the minted NFT Token Id
     */

    function stakeOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 sAmount,
        uint32 farmId
    ) external returns (uint256 tokenId);

    /**
     * @notice a payable function use to unstake farm tokens
     * @dev burn NFT's
     * @param tokenId NFT token Id
     */

    function unstakeOnUnifarm(uint256 tokenId) external payable;

    /**
     * @notice claim rewards without removing the pricipal staked amount
     * @param tokenId NFT tokenId
     */

    function claimOnUnifarm(uint256 tokenId) external payable;

    /**
     * @notice function is use to buy booster pack
     * @param cohortId cohort address
     * @param bpid  booster pack id to purchase booster
     * @param tokenId NFT tokenId
     */

    function buyBoosterPackOnUnifarm(
        address cohortId,
        uint256 bpid,
        uint256 tokenId
    ) external payable;

    /**
     * @notice use to stake + buy booster pack on unifarm cohort
     * @dev make sure approve before calling this function
     * @dev minting NFT's
     * @param cohortId cohort Address
     * @param referralAddress referral wallet address
     * @param farmToken farm token address
     * @param bpid booster package id
     * @param sAmount stake amount
     * @param farmId farm id
     */

    function stakeAndBuyBoosterPackOnUnifarm(
        address cohortId,
        address referralAddress,
        address farmToken,
        uint256 bpid,
        uint256 sAmount,
        uint32 farmId
    ) external payable returns (uint256 tokenId);

    /**
     * @notice use to burn portion on unifarm in very rare situation
     * @dev use by only owner access
     * @param user user wallet address
     * @param tokenId NFT tokenId
     */

    function emergencyBurn(address user, uint256 tokenId) external;

    /**
     * @notice update fee structure for protocol
     * @dev can only be called by the current owner
     * @param feeWalletAddress_ - new fee Wallet address
     * @param feeAmount_ - new fee amount for protocol
     */

    function updateFeeConfiguration(address payable feeWalletAddress_, uint256 feeAmount_) external;

    /**
     * @notice event triggered on each update of protocol fee structure
     * @param feeWalletAddress fee wallet address
     * @param feeAmount protocol fee Amount
     */

    event FeeConfigurtionAdded(address indexed feeWalletAddress, uint256 feeAmount);
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

interface IWETH {
    /**
     * @dev deposit eth to the contract
     */

    function deposit() external payable;

    /**
     * @dev transfer allows to transfer to a wallet or contract address
     * @param to recipient address
     * @param value amount to be transfered
     * @return Transfer status.
     */
    function transfer(address to, uint256 value) external returns (bool);

    /**
     * @dev allow to withdraw weth from contract
     */

    function withdraw(uint256) external;
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {CohortFactory} from '../abstract/CohortFactory.sol';
import {IERC20} from '../interfaces/IERC20.sol';
import {IUnifarmCohortRegistryUpgradeable} from '../interfaces/IUnifarmCohortRegistryUpgradeable.sol';
import {IWETH} from '../interfaces/IWETH.sol';

/// @title CohortHelper library
/// @author UNIFARM
/// @notice we have various util functions.which is used in protocol directly
/// @dev all the functions are internally used in the protocol.

library CohortHelper {
    /**
     * @dev getBlockNumber obtain current block from the chain.
     * @return current block number
     */

    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

    /**
     * @dev get current owner of the factory contract.
     * @param factory factory contract address.
     * @return factory owner address
     */

    function owner(address factory) internal view returns (address) {
        return CohortFactory(factory).owner();
    }

    /**
     * @dev validating the sender
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nft Manager contract address
     * @return rewardRegistry reward registry contract address
     */

    function verifyCaller(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = getStorageContracts(factory);
        require(msg.sender == nftManager, 'ONM');
    }

    /**
     * @dev get cohort details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @return cohortVersion specfic cohort version.
     * @return startBlock start block of a cohort.
     * @return endBlock end block of a cohort.
     * @return epochBlocks epoch blocks in particular cohort.
     * @return hasLiquidityMining indicator for liquidity mining.
     * @return hasContainsWrappedToken true if contains wrapped token in cohort rewards.
     * @return hasCohortLockinAvaliable denotes cohort lockin.
     */

    function getCohort(address registry, address cohortId)
        internal
        view
        returns (
            string memory cohortVersion,
            uint256 startBlock,
            uint256 endBlock,
            uint256 epochBlocks,
            bool hasLiquidityMining,
            bool hasContainsWrappedToken,
            bool hasCohortLockinAvaliable
        )
    {
        (
            cohortVersion,
            startBlock,
            endBlock,
            epochBlocks,
            hasLiquidityMining,
            hasContainsWrappedToken,
            hasCohortLockinAvaliable
        ) = IUnifarmCohortRegistryUpgradeable(registry).getCohort(cohortId);
    }

    /**
     * @dev obtain particular cohort farm token details
     * @param registry registry contract address
     * @param cohortId cohort contract address
     * @param farmId farm Id
     * @return fid farm Id
     * @return farmToken farm token Address
     * @return userMinStake amount that user can minimum stake
     * @return userMaxStake amount that user can maximum stake
     * @return totalStakeLimit total stake limit for the specfic farm
     * @return decimals farm token decimals
     * @return skip it can be skip or not during unstake
     */

    function getCohortToken(
        address registry,
        address cohortId,
        uint32 farmId
    )
        internal
        view
        returns (
            uint32 fid,
            address farmToken,
            uint256 userMinStake,
            uint256 userMaxStake,
            uint256 totalStakeLimit,
            uint8 decimals,
            bool skip
        )
    {
        (fid, farmToken, userMinStake, userMaxStake, totalStakeLimit, decimals, skip) = IUnifarmCohortRegistryUpgradeable(registry).getCohortToken(
            cohortId,
            farmId
        );
    }

    /**
     * @dev derive booster pack details available for a specfic cohort.
     * @param registry registry contract address
     * @param cohortId cohort contract Address
     * @param bpid booster pack id.
     * @return cohortId_ cohort address.
     * @return paymentToken_ payment token address.
     * @return boosterVault the booster vault address.
     * @return boosterPackAmount the booster pack amount.
     */

    function getBoosterPackDetails(
        address registry,
        address cohortId,
        uint256 bpid
    )
        internal
        view
        returns (
            address cohortId_,
            address paymentToken_,
            address boosterVault,
            uint256 boosterPackAmount
        )
    {
        (cohortId_, paymentToken_, boosterVault, boosterPackAmount) = IUnifarmCohortRegistryUpgradeable(registry).getBoosterPackDetails(
            cohortId,
            bpid
        );
    }

    /**
     * @dev calculate exact balance of a particular cohort.
     * @param token token address
     * @param totalStaking total staking of a token
     * @return cohortBalance current cohort balance
     */

    function getCohortBalance(address token, uint256 totalStaking) internal view returns (uint256 cohortBalance) {
        uint256 contractBalance = IERC20(token).balanceOf(address(this));
        cohortBalance = contractBalance - totalStaking;
    }

    /**
     * @dev get all storage contracts from factory contract.
     * @param factory factory contract address
     * @return registry registry contract address
     * @return nftManager nftManger contract address
     * @return rewardRegistry reward registry address
     */

    function getStorageContracts(address factory)
        internal
        view
        returns (
            address registry,
            address nftManager,
            address rewardRegistry
        )
    {
        (registry, nftManager, rewardRegistry) = CohortFactory(factory).getStorageContracts();
    }

    /**
     * @dev handle deposit WETH
     * @param weth WETH address
     * @param amount deposit amount
     */

    function depositWETH(address weth, uint256 amount) internal {
        IWETH(weth).deposit{value: amount}();
    }

    /**
     * @dev validate stake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateStakeLock(cohortId, farmId);
    }

    /**
     * @dev validate unstake lock status
     * @param registry registry address
     * @param cohortId cohort address
     * @param farmId farm Id
     */

    function validateUnStakeLock(
        address registry,
        address cohortId,
        uint32 farmId
    ) internal view {
        IUnifarmCohortRegistryUpgradeable(registry).validateUnStakeLock(cohortId, farmId);
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

// solhint-disable  avoid-low-level-calls

/// @title TransferHelpers library
/// @author UNIFARM
/// @notice handles token transfers and ethereum transfers for protocol
/// @dev all the functions are internally used in the protocol

library TransferHelpers {
    /**
     * @dev make sure about approval before use this function
     * @param target A ERC20 token address
     * @param sender sender wallet address
     * @param recipient receiver wallet Address
     * @param amount number of tokens to transfer
     */

    function safeTransferFrom(
        address target,
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0x23b872dd, sender, recipient, amount));
        require(success && data.length > 0, 'STFF');
    }

    /**
     * @notice transfer any erc20 token
     * @param target ERC20 token address
     * @param to receiver wallet address
     * @param amount number of tokens to transfer
     */

    function safeTransfer(
        address target,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = target.call(abi.encodeWithSelector(0xa9059cbb, to, amount));
        require(success && data.length > 0, 'STF');
    }

    /**
     * @notice transfer parent chain token
     * @param to receiver wallet address
     * @param value of eth to transfer
     */

    function safeTransferParentChainToken(address to, uint256 value) internal {
        (bool success, ) = to.call{value: uint128(value)}(new bytes(0));
        require(success, 'STPCF');
    }
}

// SPDX-License-Identifier: GNU GPLv3

pragma solidity =0.8.9;

import {Initializable} from '../proxy/Initializable.sol';

/**
 * @dev Context variant with ERC2771 support
 */

// solhint-disable
abstract contract ERC2771ContextUpgradeable is Initializable {
    /**
     * @dev holds the trust forwarder
     */

    address public trustedForwarder;

    /**
     * @dev context upgradeable initializer
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init(address tForwarder) internal initializer {
        __ERC2771ContextUpgradeable_init_unchained(tForwarder);
    }

    /**
     * @dev called by initializer to set trust forwarder
     * @param tForwarder trust forwarder
     */

    function __ERC2771ContextUpgradeable_init_unchained(address tForwarder) internal {
        trustedForwarder = tForwarder;
    }

    /**
     * @dev check if the given address is trust forwarder
     * @param forwarder forwarder address
     * @return isForwarder true/false
     */

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == trustedForwarder;
    }

    /**
     * @dev if caller is trusted forwarder will return exact sender.
     * @return sender wallet address
     */

    function _msgSender() internal view virtual returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    /**
     * @dev returns msg data for called function
     * @return function call data
     */

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity =0.8.9;

import '../utils/AddressUpgradeable.sol';

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered
        require(_initializing ? _isConstructor() : !_initialized, 'CIAI');

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly
     */
    modifier onlyInitializing() {
        require(_initializing, 'CINI');
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity =0.8.9;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, 'Address: insufficient balance');

        (bool success, ) = recipient.call{value: amount}('');
        require(success, 'Address: unable to send value, recipient may have reverted');
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, 'Address: low-level call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, 'Address: insufficient balance for call');
        require(isContract(target), 'Address: call to non-contract');

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, 'Address: low-level static call failed');
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), 'Address: static call to non-contract');

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity =0.8.9;
import '../proxy/Initializable.sol';

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, 'ReentrancyGuard: reentrant call');

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity =0.8.9;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
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
            return '0x00';
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
        buffer[0] = '0';
        buffer[1] = 'x';
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, 'Strings: hex length insufficient');
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity =0.8.9;

import '../../interfaces/IERC165Upgradeable.sol';
import '../../proxy/Initializable.sol';

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {}

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    uint256[50] private __gap;
}