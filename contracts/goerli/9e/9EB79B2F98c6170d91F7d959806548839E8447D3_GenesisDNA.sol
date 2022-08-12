// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "contracts/interfaces/IRegensZero.sol";
import "contracts/interfaces/IGenesisDNAVault.sol";
import "contracts/interfaces/IGenesisCollection.sol";
import "contracts/interfaces/ITokenUri.sol";

contract GenesisDNA is Ownable, ReentrancyGuard, ERC2981, IGenesisDNAVault {
    uint256 constant MAX_TRAIT_SUPPLY = 1000000;
    uint256 constant MAX_TRAITS = 20;
    uint256 constant INITIAL_TRAITS_AMOUNT = 6;
    uint256 constant MAX_PER_TX = 15;
    uint256 constant MAX_NUMBER_OF_TOKENS = 10000;

    uint256 public immutable price;
    uint256 public immutable mintStart;
    address public artyfex;
    address public immutable regensZero;
    IGenesisCollection public immutable genesisTraits;

    uint256 public reserveClaimed;
    uint256 public totalSupply;
    address public publicGoods1;
    address public publicGoods2;

    ITokenUri public tokenUriContract;

    string public override DNAImageUri = "";
    string public override previewImageUri = "";

    address[] public override contractsArray;

    mapping(uint256 => Trait[MAX_TRAITS]) public tokenIdToTrait;

    mapping(uint256 => uint256) private tokenIdSalt;

    mapping(address => uint256) public contractsMapping;

    mapping(uint256 => bool) public traitsMinted;

    event traitsClaimed(uint256 indexed tokenId);

    event traitsChanged(
        uint256 indexed tokenId,
        uint256[] layers,
        uint256[] contracts,
        uint256[] newTraits,
        uint256[] changeMade
    );

    event contractAllowlisted(
        address indexed _contract,
        uint256 indexed number
    );

    event contractRemovedFromAllowlist(
        address indexed _contract,
        uint256 indexed number
    );

    constructor(
        address _regensZero,
        address _genesisTraits,
        uint256 _mintStart,
        uint256 _price,
        address _artyfex,
        address _publicGoods1,
        address _publicGoods2
    ) {
        regensZero = _regensZero;
        genesisTraits = IGenesisCollection(_genesisTraits);
        mintStart = _mintStart;
        price = _price;
        artyfex = _artyfex;
        publicGoods1 = _publicGoods1;
        publicGoods2 = _publicGoods2;

        contractsArray.push(_genesisTraits);
        contractsMapping[_genesisTraits] = 1;
    }

    function getTraits(uint256 tokenId)
        public
        view
        override
        returns (Trait[MAX_TRAITS] memory traits)
    {
        require(
            traitsMinted[tokenId],
            "DNA: Token has not minted traits, does not belong to genesisDNA or does not exist."
        );
        traits = tokenIdToTrait[tokenId];
    }

    function hasMintedTraits(uint256 tokenId)
        external
        view
        override
        returns (bool)
    {
        return traitsMinted[tokenId];
    }

    function setDNAImageUri(string memory _DNAImageUri) public onlyOwner {
        DNAImageUri = _DNAImageUri;
    }

    function setPreviewImageUri(string memory _previewImageUri)
        public
        onlyOwner
    {
        previewImageUri = _previewImageUri;
    }

    function setTokenUriContract(address _tokenUriContract) public onlyOwner {
        tokenUriContract = ITokenUri(_tokenUriContract);
    }

    function setArtyfex(address _artyfex) public {
        require(
            _msgSender() == artyfex,
            "DNA: Only Artyfex can call this function"
        );
        artyfex = _artyfex;
    }

    function setPublicGoods1(address _publicGoods1) public {
        require(
            _msgSender() == publicGoods1,
            "DNA: Only Public Goods 1 can call this function"
        );
        publicGoods1 = _publicGoods1;
    }

    function setPublicGoods2(address _publicGoods2) public {
        require(
            _msgSender() == publicGoods2,
            "DNA: Only Public Goods 2 can call this function"
        );
        publicGoods2 = _publicGoods2;
    }

    function getTokenIdSalt(uint256 tokenId)
        public
        view
        override
        returns (uint256)
    {
        require(
            tokenId <= totalSupply,
            "TraitVault: TokenId does not exist or does not belong to this DNA"
        );
        return
            tokenIdSalt[tokenId] > 0
                ? tokenIdSalt[tokenId]
                : getTokenIdSalt(tokenId + 1);
    }

    function addContractToAllowlist(address _address) public onlyOwner {
        contractsArray.push(_address);
        uint256 number = contractsArray.length;
        contractsMapping[_address] = number;

        emit contractAllowlisted(_address, number);
    }

    function removeContractFromAllowlist(address _address) public onlyOwner {
        require(
            _address != address(genesisTraits),
            "TraitVault: Cannot remove GenesisTraits"
        );
        uint256 number = contractsMapping[_address];
        contractsMapping[_address] = 0;

        emit contractRemovedFromAllowlist(_address, number);
    }

    function mintTraits(uint256 tokenId) public {
        require(
            IRegensZero(regensZero).tokenIdDNA(tokenId) == address(this),
            "TraitVault: The DNA does not correspond to this vault"
        );
        require(
            IERC721(regensZero).ownerOf(tokenId) == _msgSender(),
            "TraitVault: Only token owner can mint traits."
        );
        require(!traitsMinted[tokenId], "TraitVault: Traits already minted");
        traitsMinted[tokenId] = true;
        for (uint256 j = 0; j < INITIAL_TRAITS_AMOUNT; j++) {
            tokenIdToTrait[tokenId][j * 2].traitId =
                tokenId +
                (MAX_TRAIT_SUPPLY * j * 2);
        }
        genesisTraits.mintTraits(tokenId);

        emit traitsClaimed(tokenId);
    }

    function mint(uint256 amount) public payable nonReentrant {
        require(
            _msgSender() != address(0),
            "DNA: Buyer cannot be address zero."
        );
        require(mintStart < block.number, "DNA: Mint has not started.");
        require(amount > 0, "DNA: Cannot mint 0 tokens.");
        require(
            msg.value >= price * amount,
            "DNA: Ether amount is not enough to mint."
        );
        require(
            totalSupply + amount <= MAX_NUMBER_OF_TOKENS,
            "DNA: Amount exceeds available tokens for mint."
        );
        require(
            amount <= MAX_PER_TX,
            "DNA: You have exceeded mint limit per call."
        );
        totalSupply += amount;
        IRegensZero(regensZero).genesisMint(amount, _msgSender());
        tokenIdSalt[totalSupply] = block.timestamp;
    }

    function changeTraits(
        uint256 tokenId,
        uint256[] memory layers,
        uint256[] memory contracts,
        uint256[] memory newTraits
    ) public nonReentrant returns (uint256[] memory) {
        require(
            IRegensZero(regensZero).tokenIdDNA(tokenId) == address(this),
            "TraitVault: The DNA does not correspond to this vault"
        );
        require(
            IRegensZero(regensZero).getTokenTimelock(tokenId) < block.timestamp,
            "TraitVault: Token is locked."
        );
        require(traitsMinted[tokenId], "TraitVault: Traits not minted yet.");
        require(
            IERC721(regensZero).ownerOf(tokenId) == _msgSender() ||
                IRegensZero(regensZero).getController(tokenId) == _msgSender(),
            "TraitVault: Only token owner or controller can change traits."
        );
        require(
            layers.length == contracts.length,
            "TraitVault: Contracts amount does not equal layers amount."
        );
        require(
            layers.length == newTraits.length,
            "TraitVault: Traits amount does not equal layers amount."
        );
        require(
            layers.length <= MAX_TRAITS,
            "TraitVault: Layers amount exceeds max layers."
        );
        IRegensZero(regensZero).changeLastTraitModification(tokenId);
        address owner = IERC721(regensZero).ownerOf(tokenId);
        uint256[] memory changed = new uint256[](layers.length);
        for (uint256 i = 0; i < layers.length; i++) {
            uint256 layer = layers[i];
            uint256 layerContract = contracts[i];
            uint256 traitId = newTraits[i];

            if (
                (traitId > 0 || layerContract > 0) &&
                ((layerContract >= contractsArray.length) ||
                    (contractsMapping[contractsArray[layerContract]] == 0) ||
                    (traitId == 0) ||
                    ((IERC721(contractsArray[layerContract]).ownerOf(traitId) !=
                        owner) &&
                        (IERC721(contractsArray[layerContract]).ownerOf(
                            traitId
                        ) != _msgSender())) ||
                    (layer * MAX_TRAIT_SUPPLY >= traitId) ||
                    (traitId >= (layer + 1) * MAX_TRAIT_SUPPLY))
            ) continue;

            Trait[MAX_TRAITS] storage traits = tokenIdToTrait[tokenId];
            Trait memory oldTrait = traits[layer];
            traits[layer].layer1 = layerContract;
            traits[layer].traitId = traitId;
            if (traitId > 0) {
                ITraitCollection(contractsArray[layerContract]).transferSpecial(
                        traitId,
                        owner
                    );
            }

            if (oldTrait.traitId > 0) {
                IERC721(contractsArray[oldTrait.layer1]).safeTransferFrom(
                    address(this),
                    owner,
                    oldTrait.traitId
                );
            }
            changed[i] = 1;
        }
        emit traitsChanged(tokenId, layers, contracts, newTraits, changed);
        return changed;
    }

    function withdraw() public nonReentrant {
        require(
            owner() == _msgSender() ||
                _msgSender() == artyfex ||
                _msgSender() == publicGoods1 ||
                _msgSender() == publicGoods2
        );
        uint256 balance = address(this).balance;
        uint256 oneThird = balance/3;
        Address.sendValue(payable(publicGoods1), oneThird);
        Address.sendValue(payable(publicGoods2), oneThird);
        uint256 newBalance = address(this).balance;
        Address.sendValue(payable(artyfex), newBalance);
    }

    function reserve(uint256 amount) public {
        require(reserveClaimed < 100 && _msgSender() == artyfex);
        reserveClaimed += amount;
        totalSupply += amount;
        IRegensZero(regensZero).genesisMint(amount, artyfex);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory uri)
    {
        require(
            tokenId <= totalSupply && tokenId > 0,
            "TraitVault: TokenId does not exist or does not belong to this DNA"
        );
        return tokenUriContract.tokenURI(tokenId);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override(ERC2981, IDNAVault) returns (address, uint256) {
        return ERC2981.royaltyInfo(_tokenId, _salePrice);
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function deleteDefaultRoyalty() public onlyOwner {
        _deleteDefaultRoyalty();
    }

    function setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) public onlyOwner {
        _setTokenRoyalty(tokenId, receiver, feeNumerator);
    }

    function resetTokenRoyalty(uint256 tokenId) public onlyOwner {
        _resetTokenRoyalty(tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
        return functionCall(target, data, "Address: low-level call failed");
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

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
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IRegensZero {
    function getController(uint256 tokenId) external returns(address);
    function getSigner(uint256 tokenId) external returns(address);
    function getTokenTimelock(uint256 tokenId) external returns(uint256);
    function setNewDNA(address _DNA) external;
    function changeLastTraitModification(uint256 tokenId) external;
    function removeDNA(address _DNA) external;
    function genesisMint(uint256 amount, address _address) external;
    function postGenesisMint(uint256 amount, address _address) external;
    function tokenIdDNA(uint256) external returns(address);
    function genesisSupply() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "contracts/interfaces/IDNAVault.sol";

interface IGenesisDNAVault is IDNAVault {
    function getTraits(uint256 tokenId)
        external
        view
        returns (Trait[20] memory traits);

    function hasMintedTraits(uint256 tokenId) external view returns (bool);

    function contractsArray(uint256) external view returns (address);

    function DNAImageUri() external view returns (string memory);

    function previewImageUri() external view returns (string memory);

    function getTokenIdSalt(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "contracts/interfaces/ITraitCollection.sol";

interface IGenesisCollection is ITraitCollection {
    function mintTraits(uint256 tokenId) external;
    function generalSalt() external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ITokenUri {
    function tokenURI(uint256 tokenId) external view returns (string memory uri);
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

pragma solidity ^0.8.2;

struct Trait {
    uint256 layer1;
    uint256 traitId;
}

interface IDNAVault {
    function tokenURI(uint256) external view returns (string memory);

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface ITraitCollection {
    function transferSpecial(uint256 tokenId, address _address) external;
    function tokenImage(uint256 tokenId) external view returns(string memory);
    function collectionName() external view returns(string memory);
    function traitName(uint256 tokenId) external view returns(string memory);
}