// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../license/erc721/ILicense.sol";
import "../interfaces/IWETH.sol";

contract Escrow is Ownable, ReentrancyGuard {
    /// @dev Connect cryptography library
    using ECDSA for bytes32;

    /**
     * @dev Minting data
     * @param collection ERC721 token collection address
     * @param tokenId ID of the token in ERC721 collection
     * @param buyer Person who buys
     * @param seller Owner of the original ERC721 token from collection
     * @param price Deal price in wei
     * @param duration License duration in seconds
     * @param uuid Unique id
     * @param tokenUri Metadata uri
     * @param signature Admin signature
     */
    struct MintLicense {
        address collection;
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 price;
        uint96 duration;
        bytes uuid;
        string tokenUri;
        bytes signature;
    }

    /**
     * @dev License transfer data
     * @param licenseId License tokenId
     * @param collection ERC721 token collection address
     * @param tokenId ID of the token in ERC721 collection
     * @param buyer Person who buys
     * @param seller Owner of the original ERC721 token from collection
     * @param price Deal price in wei
     * @param uuid Unique id
     * @param signature Admin signature
     */
    struct SellLicense {
        uint256 licenseId;
        address collection;
        uint256 tokenId;
        address buyer;
        address seller;
        uint256 price;
        bytes uuid;
        bytes signature;
    }

    /// @dev License token
    ILicense internal license;

    /// @dev Weth token
    IWETH internal immutable weth;

    /// @dev To make fractional part
    uint256 internal constant DENOMINATOR = 10000; // 100.00%

    /// @dev Max fee
    uint256 internal constant MAX_FEE = 2000; // 20.00%

    /// @notice Service fee
    uint256 public fee;

    /// @dev Tx signer
    address public admin;

    /// @dev Fee receiver
    address payable internal feeAddress;

    /// @notice Minimal license duration
    uint96 public minDuration = 182 days;

    /// @notice Maximal license duration
    uint96 public maxDuration = 1825 days;

    /// @dev Used order hashes
    mapping(bytes32 => bool) internal alreadyExecuted;

    /// @dev When admin changed
    event AdminChanged(address admin);

    /// @dev Minimal duration changed
    event MinimalDurationChanged(uint96 minimalDuration);

    /// @dev Maximal duration changed
    event MaximalDurationChanged(uint96 maximalDuration);

    /// @dev Service fee changed
    event ServiceFeeChanged(uint256 fee);

    /// @dev Fees collector changed
    event FeesCollector(address feesCollector);

    /// @dev License contract changed
    event LicenseContractChanged(address license);

    /// @dev New license issued
    event NewLicense(
        address indexed collection,
        uint256 indexed collectionTokenId,
        uint256 indexed licenseTokenId
    );

    /**
     * @dev Check is zero address
     * @param _address Address to check
     */
    modifier notZeroAddress(address _address) {
        require(_address != address(0), "zero address");
        _;
    }

    /// @dev Check if the license NFT contract is set
    modifier licenseTokenSet() {
        require(address(license) != address(0), "set license token first");
        _;
    }

    /**
     * @dev Check service fee rate
     * @param _fee Service fee
     */
    modifier checkServiceFee(uint256 _fee) {
        require(_fee <= MAX_FEE, "fee too big");
        _;
    }

    /**
     * @dev Check duration
     * @param _duration License duration
     */
    modifier checkDuration(uint256 _duration) {
        require(_duration >= minDuration, "duration too short");
        require(_duration <= maxDuration, "duration too long");
        _;
    }

    /**
     * @dev Check is license already exists
     * @param _collection NFT collection
     * @param _tokenId ID of the token in NFT collection
     */
    modifier haveNoLicense(address _collection, uint256 _tokenId) {
        require(!_hasActiveLicense(_collection, _tokenId), "License exists");
        _;
    }

    /**
     * @dev Check is license exists
     * @param _collection NFT collection
     * @param _tokenId ID of the token in NFT collection
     */
    modifier haveLicense(address _collection, uint256 _tokenId) {
        require(
            _hasActiveLicense(_collection, _tokenId),
            "License doesn't exists"
        );
        _;
    }

    /**
     * @dev Check WETH allowance to this contract
     */
    modifier checkAllowance(address _buyer, uint256 _price) {
        require(
            weth.allowance(_buyer, address(this)) >= _price,
            "check allowance"
        );
        _;
    }

    /**
     * @dev This contract must be able to transfer license
     */
    modifier checkLicenseAllowance(uint256 _tokenId) {
        require(
            license.getApproved(_tokenId) == address(this),
            "check license allowance"
        );
        _;
    }

    /**
     * @dev Execute on deploy
     * @param _admin Server address that signs messages
     * @param _fee Service fee amount
     * @param _feeAddress Receiver of service fee
     */
    constructor(
        address _admin,
        uint256 _fee,
        address payable _feeAddress,
        IWETH _weth
    ) checkServiceFee(_fee) {
        admin = _admin;
        fee = _fee;
        feeAddress = _feeAddress;
        weth = _weth;
    }

    /**
     * @notice Change signer address
     * @param _admin New signer address
     */
    function setAdmin(address _admin)
        external
        onlyOwner
        notZeroAddress(_admin)
    {
        admin = _admin;
        emit AdminChanged(admin);
    }

    /**
     * @notice Minimal license duration
     * @param _minDuration New minimal duration
     */
    function setMinDuration(uint96 _minDuration) external onlyOwner {
        minDuration = _minDuration;
        emit MinimalDurationChanged(minDuration);
    }

    /**
     * @notice Maximal license duration
     * @param _maxDuration New maximal duration
     */
    function setMaxDuration(uint96 _maxDuration) external onlyOwner {
        maxDuration = _maxDuration;
        emit MaximalDurationChanged(maxDuration);
    }

    /**
     * @notice Change service fee
     * @param _fee New service fee
     */
    function setServiceFee(uint256 _fee)
        external
        onlyOwner
        checkServiceFee(_fee)
    {
        fee = _fee;
        emit ServiceFeeChanged(fee);
    }

    /**
     * @notice Change fee collector address
     * @param _feeAddress New fee address
     */
    function setFeeAddress(address payable _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
        emit FeesCollector(feeAddress);
    }

    /**
     * @notice Set license token
     * @dev License deployed after this contract
     * @param _license License token address
     */
    function setLicenseContract(ILicense _license) external onlyOwner {
        license = _license;
        emit LicenseContractChanged(address(license));
    }

    /**
     * @notice Buy license for ether
     *
     * @dev Only buyer can call this function
     *
     * @param _params Data for minting
     */
    function executeTakerBid(MintLicense memory _params)
        external
        payable
        nonReentrant
        haveNoLicense(_params.collection, _params.tokenId)
        notZeroAddress(_params.collection)
        notZeroAddress(_params.buyer)
        notZeroAddress(_params.seller)
        checkDuration(_params.duration)
    {
        require(_params.price == msg.value, "price != msg.value");
        require(_params.buyer == msg.sender, "unauthorized");
        require(
            _sellerIsOwner(_params.collection, _params.tokenId, _params.seller),
            "unauthorized seller"
        );

        _checkCollectionSignature(_params);

        _distributeEther(_params.seller, _params.price);

        _mintLicense(
            _params.buyer,
            _params.collection,
            _params.tokenId,
            _params.duration,
            _params.tokenUri
        );
    }

    /**
     * @notice Buy/Sell license with WETH
     *
     * @dev Only Buyer and Seller can call this function!
     *
     * @param _params Data for minting
     */
    function executeTakerAsk(MintLicense memory _params)
        external
        nonReentrant
        checkAllowance(_params.buyer, _params.price)
        haveNoLicense(_params.collection, _params.tokenId)
        notZeroAddress(_params.collection)
        notZeroAddress(_params.buyer)
        notZeroAddress(_params.seller)
        checkDuration(_params.duration)
    {
        require(
            _params.seller == msg.sender || _params.buyer == msg.sender,
            "unauthorized"
        );

        _checkCollectionSignature(_params);

        _distributeWeth(_params.buyer, _params.seller, _params.price);

        _mintLicense(
            _params.buyer,
            _params.collection,
            _params.tokenId,
            _params.duration,
            _params.tokenUri
        );
    }

    /**
     * @notice Buy/Sell minted license with ether
     *
     * @dev Only Buyer is able to call this function!
     *
     * @param _params Data for minting
     */
    function licenseTakerBid(SellLicense memory _params)
        external
        payable
        nonReentrant
        haveLicense(_params.collection, _params.tokenId)
        checkLicenseAllowance(_params.licenseId)
        notZeroAddress(_params.collection)
        notZeroAddress(_params.buyer)
        notZeroAddress(_params.seller)
    {
        // Checking params
        require(_params.buyer == msg.sender, "unauthorized");
        require(_params.price == msg.value, "_price != msg.value");
        require(
            _sellerIsOwner(address(license), _params.licenseId, _params.seller),
            "unauthorized seller"
        );

        _checkLicenseSignature(_params);

        _distributeEther(_params.seller, _params.price);

        license.safeTransferFrom(
            _params.seller,
            _params.buyer,
            _params.tokenId
        );
    }

    /**
     * @notice Buy/Sell minted license with WETH
     *
     * @dev Only Buyer or Seller are able to call this function!
     *
     * @param _params Data for minting
     */
    function licenseTakerAsk(SellLicense memory _params)
        external
        haveLicense(_params.collection, _params.tokenId)
        checkAllowance(_params.buyer, _params.price)
        checkLicenseAllowance(_params.licenseId)
        notZeroAddress(_params.collection)
        notZeroAddress(_params.buyer)
        notZeroAddress(_params.seller)
    {
        require(
            _params.seller == msg.sender || _params.buyer == msg.sender,
            "unauthorized"
        );

        _checkLicenseSignature(_params);

        _distributeWeth(_params.buyer, _params.seller, _params.price);

        license.safeTransferFrom(
            _params.seller,
            _params.buyer,
            _params.tokenId
        );
    }

    /**
     * @dev Is token have active license?
     * @param _collection ERC721 address
     * @param _tokenId ID of the token in ERC721 collection
     * @return True if token have active license
     */
    function _hasActiveLicense(address _collection, uint256 _tokenId)
        internal
        view
        returns (bool)
    {
        return license.isLicenseActive(_collection, _tokenId);
    }

    /**
     * @dev Check ownership of address
     * @param _collection ERC721 address
     * @param _tokenId ID of the token in ERC721 collection
     * @param _owner Check ownership of this address
     */
    function _sellerIsOwner(
        address _collection,
        uint256 _tokenId,
        address _owner
    ) internal view returns (bool) {
        return IERC721(_collection).ownerOf(_tokenId) == _owner;
    }

    /**
     * @dev Check signature for collection
     *
     * @param _params License mint data
     */
    function _checkCollectionSignature(MintLicense memory _params) internal {
        bytes32 _msgHash = keccak256(
            abi.encode(
                _params.collection,
                _params.tokenId,
                _params.buyer,
                _params.seller,
                _params.price,
                _params.duration,
                _params.uuid,
                _params.tokenUri
            )
        );

        _checkSignature(_msgHash, _params.signature);
    }

    /**
     * @dev Check signature for license token
     *
     * @param _params License transfer data
     */
    function _checkLicenseSignature(SellLicense memory _params) internal {
        bytes32 _msgHash = keccak256(
            abi.encode(
                _params.licenseId,
                _params.collection,
                _params.tokenId,
                _params.buyer,
                _params.seller,
                _params.price,
                _params.uuid
            )
        );

        _checkSignature(_msgHash, _params.signature);
    }

    /**
     * @dev Is admin sign this transaction?
     * @param _msgHash Hash from user
     * @param _signature Hash from admin
     */
    function _checkSignature(bytes32 _msgHash, bytes memory _signature)
        internal
    {
        require(!alreadyExecuted[_msgHash], "hash already used");
        require(
            _msgHash.toEthSignedMessageHash().recover(_signature) == admin,
            "fake signature"
        );

        alreadyExecuted[_msgHash] = true;
    }

    /**
     * @dev Distribute ether between seller and fees collector
     * @param _seller Token/license owner
     * @param _price License price
     */
    function _distributeEther(address _seller, uint256 _price) internal {
        uint256 _fee = _calcFee(_price);

        payable(_seller).transfer(_price - _fee);
        feeAddress.transfer(_fee);
    }

    /**
     * @dev Distribute ether between seller and fees collector
     * @param _payer License buyer
     * @param _receiver License seller
     * @param _price License price
     */
    function _distributeWeth(
        address _payer,
        address _receiver,
        uint256 _price
    ) internal {
        uint256 _fee = _calcFee(_price);

        weth.transferFrom(_payer, _receiver, _price - _fee);
        weth.transferFrom(_payer, _receiver, _fee);
    }

    /**
     * @dev Mint new license NFT
     * @param _buyer Person who buys
     * @param _collection ERC721 token collection address
     * @param _tokenId ID of the token in ERC721 collection
     * @param _tokenUri Metadata uri
     */
    function _mintLicense(
        address _buyer,
        address _collection,
        uint256 _tokenId,
        uint96 _duration,
        string memory _tokenUri
    ) internal {
        uint256 _licenseId = license.safeMint(
            _buyer,
            _collection,
            _tokenId,
            _duration,
            _tokenUri
        );
        emit NewLicense(_collection, _tokenId, _licenseId);
    }

    /**
     * @dev Calculate service fee
     * @param _price License cost
     * @return Service fee in wei
     */
    function _calcFee(uint256 _price) internal view returns (uint256) {
        return (_price * fee) / DENOMINATOR;
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV
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
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
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
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
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
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
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
pragma solidity ^0.8.4;

interface ILicense {
    function safeMint(
        address _to,
        address _collection,
        uint256 _collectionTokenId,
        uint96 _duration,
        string memory _uri
    ) external returns (uint256 _tokenId);

    function isLicenseActive(address _collection, uint256 _tokenId)
        external
        view
        returns (bool _isLicenseActive);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: GNU
pragma solidity >=0.5.0;

interface IWETH {
    function name() external view returns (string memory);

    function approve(address guy, uint256 wad) external returns (bool);

    function totalSupply() external view returns (uint256);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function withdraw(uint256 wad) external;

    function decimals() external view returns (uint8);

    function balanceOf(address) external view returns (uint256);

    function symbol() external view returns (string memory);

    function transfer(address dst, uint256 wad) external returns (bool);

    function deposit() external payable;

    function allowance(address, address) external view returns (uint256);

    fallback() external payable;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);
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