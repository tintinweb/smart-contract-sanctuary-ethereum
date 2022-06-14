// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./Ownable.sol";
import "./Pausable.sol";
import "./ReentrancyGuard.sol";
import "./ECDSA.sol";
import "./IMintableUpgradeable.sol";


/**
 * @dev Developed to facilitate the sales of GLVT NFT tokens.
 *
 * The contract components should be pretty straightforward, with the exception
 * of `authorizedMint`, which is the primary feature supporting any form of pre-public
 * sale of the NFTs. Essentially, an address will be designated as the `mintAuthority`
 * and will be used to sign authorisations for minting ahead of the public sales
 * period.
 */
contract GLVTSaleUpgradeableToken is Ownable, Pausable, ReentrancyGuard {
    IMintableUpgradeable internal _tokenContract;
    address public mintAuthority;
    uint256 public whitelistSaleTimestamp;
    uint256 public publicSaleTimestamp;
    uint256 public publicSalePrice;
    uint256 public totalMinted = 0;
    uint256 public totalSupply;
    bool public ended = false;
    uint256 public constant maxTokensPerMint = 3;

    /// @dev Tracking attributes for authorized minting
    mapping (bytes32 => uint256) internal _nonces;
    bytes32 internal _hashedContractName;
    bytes32 internal _hashedContractVersion;
    bytes32 internal constant _typeHash = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    /**
     * @dev Typehash for generating authorized mint signatures
     *
     * The components of the typehash and their definitions is given as follows:
     * @custom:param to Address authorized to mint (i.e. the caller of the mint operation).
     * @custom:param quantity Total quantity that `to` is allowed to mint using this signature.
     * @custom:param timestamp Earliest timestamp minting is permitted.
     * @custom:param price Price-per-token in ETH.
     * @custom:param nonce Nonce word used to add uniqueness to the signature.
     * @custom:param type Mint type, emitted with the {Mint} event for downstream use.
     */
    bytes32 internal constant authorizedMintTypehash = keccak256(
        "AuthorizedMint(address to,uint256 quantity,uint256 timestamp,uint256 price,bytes32 nonce,uint256 type)"
    );

    /// @dev Event for downstream use
    event Mint(address to, uint256 mintType, uint256 tokenId);

    /**
     * Throws if the caller is not an externally owned address.
     */
    modifier onlyEOA() {
        require(tx.origin == msg.sender, "Caller cannot be another contract");
        _;
    }

    /**
     * @param tokenContract GLVT token address.
     * @param mintAuthority_ Address of authorized mint authority.
     * @param whitelistSaleTimestamp_ Minimum timestamp for commencement of whitelist sales.
     * @param publicSaleTimestamp_ Minimum timestamp for commencement of public sale.
     * @param publicSalePrice_ Price for public sale minting in ETH.
     * @param totalSupply_ Total number of tokens up for sale.
     * @param contractName Contract name (used for authorized mint validation).
     * @param contractVersion Contract version (used for authorized mint validation).
     */
    constructor(
        address tokenContract,
        address mintAuthority_,
        uint256 whitelistSaleTimestamp_,
        uint256 publicSaleTimestamp_,
        uint256 publicSalePrice_,
        uint256 totalSupply_,
        string memory contractName,
        string memory contractVersion
    ) {
        _tokenContract = IMintableUpgradeable(tokenContract);
        mintAuthority = mintAuthority_;
        whitelistSaleTimestamp = whitelistSaleTimestamp_;
        publicSaleTimestamp = publicSaleTimestamp_;
        publicSalePrice = publicSalePrice_;
        totalSupply = totalSupply_;

        // setting up for authorized minting
        _hashedContractName = keccak256(bytes(contractName));
        _hashedContractVersion = keccak256(bytes(contractVersion));
    }

    /**
     * Authorized mint (i.e. non-public channel for minting).
     *
     * @param quantity Number of tokens to mint.
     * @param mintableQuantity Total number of tokens mintable with this authorization.
     * @param mintTimestamp Minimum timestamp for minting with this authorization.
     * @param mintPrice Authorized per-token price in ETH.
     * @param nonceWord Unique authorization qualifier.
     * @param mintType Mint type (used to emit {Mint} event for downstream use).
     * @param signature Authorization signature.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Mint `quantity` must not exceed `mintableQuantity`.
     * - Block timestamp must be equal or greater than `mintTimestamp`.
     * - Total number of tokens minted (including the current attempt) for the specified
     *   `nonceWord` must not exceed `mintableQuantity`.
     * - Amount of ETH sent must be equal to or more than `quantity` * `mintPrice`.
     * - The number of tokens minted so far plus `quantity` must not exceed the total sale supply.
     */
    function authorizedMint(
        uint256 quantity,
        uint256 mintableQuantity,
        uint256 mintTimestamp,
        uint256 mintPrice,
        bytes32 nonceWord,
        uint256 mintType,
        bytes memory signature
    ) external payable virtual whenNotPaused nonReentrant returns (uint256) {
        require(quantity <= mintableQuantity, "GLVT: Exceeds authorized quantity.");
        require(block.timestamp >= mintTimestamp, "GLVT: Authorized mint timestamp not reached.");
        // writing ```_nonces[nonceWord] + quantity <= mintableQuantity``` may be more readable,
        // but we risk an overflow if the nonce has been invalidated (i.e. set to the max value)
        uint256 noncesUsed = _nonces[nonceWord];
        require(
            mintableQuantity > noncesUsed && mintableQuantity - noncesUsed >= quantity,
            "GLVT: Authorized mint quantity exceeded."
        );

        bytes32 structHash = keccak256(
            abi.encode(
                authorizedMintTypehash,
                msg.sender,
                mintableQuantity,
                mintTimestamp,
                mintPrice,
                nonceWord,
                mintType
            )
        );
        bytes32 domainSeparatorV4 = keccak256(
            abi.encode(
                _typeHash,
                _hashedContractName,
                _hashedContractVersion,
                block.chainid,
                address(this)
            )
        );
        bytes32 digest = ECDSA.toTypedDataHash(domainSeparatorV4, structHash);
        _validateSignature(signature, digest, mintAuthority);

        _nonces[nonceWord] += quantity;
        return _mint(msg.sender, quantity, mintPrice, mintType);
    }

    /**
     * Flip the end state of the sale.
     *
     * If sale is ongoing, it will be set to ended. If sale has ended, it will
     * be set to ongoing.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function flipEndState() external virtual onlyOwner {
        ended = !ended;
    }

    /**
     * Invalidates the specified nonce, rendering it unusable for authorized minting.
     *
     * @param nonceWord Nonce to invalidate.
     */
    function invalidateAuthorizedMintNonce(bytes32 nonceWord) external virtual onlyOwner {
        _nonces[nonceWord] = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
    }

    /**
     * Public sale.
     *
     * @param quantity Number of tokens to mint.
     *
     * Requirements:
     * - Contract must not be paused.
     * - Public sale must have commenced.
     * - Amount of ETH sent must be equal to or more than `quantity` * public sale price.
     * - The number of tokens minted so far plus `quantity` must not exceed the total sale supply.
     * - Value for `quantity` must not exceed `maxTokensPerMint`.
     */
    function mint(uint256 quantity) external payable virtual whenNotPaused nonReentrant onlyEOA returns (uint256) {
        require(isPublicSale(), "GLVT: Public sale has not begun.");
        require(quantity > 0, "GLVT: Quantity must be greater than zero.");
        require(quantity <= maxTokensPerMint, "GLVT: Exceeds max tokens per mint");
        // type 2 for public sale
        return _mint(msg.sender, quantity, publicSalePrice, 2);
    }

    /**
     * Pause the contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function pause() external virtual onlyOwner {
        _pause();
    }

    /**
     * Set the address of the authorized mint authority.
     *
     * @param authority Address of the new authority.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setMintAuthority(address authority) external onlyOwner {
        require(authority != address(0), "GLVT: Mint authority cannot be zero address.");
        mintAuthority = authority;
    }

    /**
     * Set the public sale price.
     *
     * @param price Public sale price in ETH.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setPublicSalePrice(uint256 price) external virtual onlyOwner {
        publicSalePrice = price;
    }

    /**
     * Set the timestamp for commencement of public sale.
     *
     * @param timestamp Timestamp for commencement of public sale.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setPublicSaleTimestamp(uint256 timestamp) external virtual onlyOwner {
        publicSaleTimestamp = timestamp;
    }

    /**
     * Set the timestamp for commencement of whitelist sale.
     *
     * @param timestamp Timestamp for commencement of whitelist sale.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function setWhitelistSaleTimestamp(uint256 timestamp) external virtual onlyOwner {
        whitelistSaleTimestamp = timestamp;
    }

    /**
     * Pause the contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function unpause() external virtual onlyOwner {
        _unpause();
    }

    /**
     * Withdraw all available ETH held by this contract.
     *
     * Requirements:
     * - Caller must be the contract owner.
     */
    function withdraw() external virtual onlyOwner nonReentrant {
        // send and transfer both have a hard dependency of 2300 on gas costs, so
        // there's a risk of future failure
        (bool success, ) = msg.sender.call{ value: address(this).balance }("");
        require(success, "GLVT: Transfer failed.");
    }

    /**
     * Returns the number of tokens an authorized mint nonce has been used for.
     *
     * @return uses Quantity of tokens nonce has been used for.
     */
    function nonceUses(bytes32 nonceWord) external view virtual returns (uint256) {
        return _nonces[nonceWord];
    }

    /**
     * Returns the address of the NFT smart contract.
     *
     * @return tokenContractAddress Address of the NFT smart contract.
     */
    function tokenContractAddress() external view virtual returns (address) {
        return address(_tokenContract);
    }

    /**
     * Checks if public sale has commenced.
     *
     * @return commenced True if public sale has commenced.
     */
    function isPublicSale() public view virtual returns (bool) {
        return block.timestamp >= publicSaleTimestamp;
    }

    /**
     * Checks if whitelist sale has commenced.
     *
     * @return commenced True if whitelist sale has commenced.
     */
    function isWhitelistSale() public view virtual returns (bool) {
        return block.timestamp >= whitelistSaleTimestamp;
    }

    /**
     * Mint tokens by calling upon the GLVT token contract.
     *
     * Any excess ETH is refunded to the caller.
     *
     * @param to Recipient address.
     * @param quantity Number of tokens to mint.
     * @param price Per-token price in ETH.
     * @param mintType Mint type.
     *
     * Emits a {Mint} event.
     */
    function _mint(address to, uint256 quantity, uint256 price, uint256 mintType) internal virtual returns (uint256) {
        require(!ended, "GLVT: Sale ended");
        uint256 requiredEth = price * quantity;
        require(msg.value >= requiredEth, "GLVT: Insufficient ETH for minting.");
        require(totalMinted + quantity <= totalSupply, "GLVT: Total supply exceeded.");

        totalMinted += quantity;
        uint256 startTokenId = _tokenContract.safeMint(to, quantity);
        for (uint i = 0; i < quantity; i++) {
            emit Mint(to, mintType, startTokenId + i);
        }

        if (msg.value > requiredEth) {
            payable(msg.sender).transfer(msg.value - requiredEth);
        }

        return startTokenId;
    }

    /**
     * Disassembles a signature into its (v, r, s) components.
     *
     * @param signature Signature.
     * @return (v, r, s) components of the signature.
     */
    function _disassembleSignature(bytes memory signature) internal view virtual returns (uint8, bytes32, bytes32) {
        require(signature.length == 65, "GLVT: Invalid signature length.");
        // taken from OpenZeppelin {ECDSA-tryRecover}
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return (v, r, s);
    }

    /**
     * @dev Validates a signature.
     *
     * Given a signature and the original message digest, this function disassembles
     * the signature and recovers the address of the original signatory. The address
     * of the original signatory is compared against the given signatory to ensure
     * its validity.
     *
     * @param signature Signature.
     * @param digest Message body.
     * @param signatory Expected address of signatory.
     */
    function _validateSignature(bytes memory signature, bytes32 digest, address signatory) internal view virtual {
        (uint8 v, bytes32 r, bytes32 s) = _disassembleSignature(signature);
        address recovered = ECDSA.recover(digest, v, r, s);
        require(recovered != address(0), "GLVT: Invalid signature.");
        require(recovered == signatory, "GLVT: Unauthorized.");
    }
}