//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

/**
 *    ███████╗██╗   ██╗██████╗ ██████╗ ███████╗███╗   ███╗███████╗
 *    ██╔════╝██║   ██║██╔══██╗██╔══██╗██╔════╝████╗ ████║██╔════╝
 *    ███████╗██║   ██║██████╔╝██████╔╝█████╗  ██╔████╔██║█████╗
 *    ╚════██║██║   ██║██╔═══╝ ██╔══██╗██╔══╝  ██║╚██╔╝██║██╔══╝
 *    ███████║╚██████╔╝██║     ██║  ██║███████╗██║ ╚═╝ ██║███████╗
 *    ╚══════╝ ╚═════╝ ╚═╝     ╚═╝  ╚═╝╚══════╝╚═╝     ╚═╝╚══════╝
 *
 *    ███████╗██╗  ██╗██╗   ██╗██╗     ██╗     ███████╗
 *    ██╔════╝██║ ██╔╝██║   ██║██║     ██║     ██╔════╝
 *    ███████╗█████╔╝ ██║   ██║██║     ██║     ███████╗
 *    ╚════██║██╔═██╗ ██║   ██║██║     ██║     ╚════██║
 *    ███████║██║  ██╗╚██████╔╝███████╗███████╗███████║
 *    ╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝╚══════╝
 */

import "./ISupremeSkulls.sol";
import "./token/ERC721Enumerable.sol";
import "./token/ERC2981ContractWideRoyalties.sol";
import "./token/TokenRescuer.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Supreme Skulls
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract SupremeSkulls is
    ISupremeSkulls,
    ERC721Enumerable,
    ERC2981ContractWideRoyalties,
    TokenRescuer
{
    /// The maximum token supply.
    uint256 public constant MAX_SUPPLY = 6666;

    /// The maximum number of minted tokens per address in the whitelist phase.
    uint256 public constant MAX_WHITELIST_MINT = 2;

    /// The maximum number of minted tokens per transaction.
    uint256 public constant MAX_MINT_PER_TX = 2;

    /// The maximum ERC-2981 royalties percentage (two decimals).
    uint256 public constant MAX_ROYALTIES_PCT = 1000; // 10%

    /// The price per token mint (whitelist phase).
    uint256 public priceWhitelist;

    /// The price per token mint (public phase).
    uint256 public pricePublic;

    /// The base URI for token metadata.
    string public baseURI;

    /// The contract URI for contract-level metadata.
    string public contractURI;

    /// The provenance hash summarizing token order and content.
    bytes32 public provenanceHash;

    /// Whether the provenance hash has been locked forever.
    bool public provenanceIsLocked;

    /// Whether the tokenURI() method returns fully revealed tokenURIs
    bool public isRevealed;

    /// The token sale state (0=Paused, 1=Whitelist, 2=Public, 3=Open).
    SaleState public saleState;

    /// The address of the OpenSea proxy registry contract.
    address public proxyRegistry;

    /// The address which signs the mint coupons.
    address public couponSigner;

    /// Whether an address has revoked the automatic OpenSea proxy approval.
    mapping(address => bool) public userRevokedRegistryApproval;

    /// The total tokens minted by an address in whitelist phase.
    mapping(address => uint256) public whitelistMinted;

    /// Reverts if the current sale state is not `_saleState`.
    modifier onlyInSaleState(SaleState _saleState) {
        if (saleState != _saleState) revert SalePhaseNotActive();
        _;
    }

    /// Reverts if `_mintAmount` exceeds MAX_MINT_PER_TX.
    modifier onlyWithValidMintAmount(uint256 _mintAmount) {
        if (_mintAmount > MAX_MINT_PER_TX) revert ExceedsMaxMintPerTx();
        _;
    }

    /// Reverts if the correct ether value was not sent.
    modifier onlyWithCorrectPayment(uint256 _mintAmount, uint256 _price) {
        unchecked {
            if (msg.value != _mintAmount * _price)
                revert IncorrectPaymentAmount();
        }
        _;
    }

    /// Reverts if the signature is invalid.
    modifier onlyWithValidSignature(
        bytes calldata _signature,
        SaleState _saleState
    ) {
        if (!isValidSignature(
            _signature,
            _msgSender(),
            _saleState,
            block.chainid
        )) revert InvalidSignature();
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _startingTokenID,
        address _couponSigner,
        uint256 _priceWhitelist,
        uint256 _pricePublic,
        string memory _contractURI,
        string memory _baseURI,
        address _proxyRegistry,
        address _royaltiesReceiver,
        uint256 _royaltiesPercent
    )
        ERC721(_name, _symbol, _startingTokenID)
    {
        couponSigner = _couponSigner;
        priceWhitelist = _priceWhitelist;
        pricePublic = _pricePublic;
        contractURI = _contractURI;
        baseURI = _baseURI;
        proxyRegistry = _proxyRegistry;
        setRoyalties(
            _royaltiesReceiver,
            _royaltiesPercent
        );
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     * @param _signature The signature to be verified.
     */
    function mintWhitelist(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        payable
        onlyInSaleState(SaleState.Whitelist)
        onlyWithCorrectPayment(_mintAmount, priceWhitelist)
        onlyWithValidSignature(_signature, SaleState.Whitelist)
    {
        unchecked {
            whitelistMinted[_msgSender()] += _mintAmount;
        }
        if (whitelistMinted[_msgSender()] > MAX_WHITELIST_MINT)
            revert ExceedsMintPhaseAllocation();

        _mint(_mintAmount);
    }

    /**
     * @notice Mints `_mintAmount` tokens if the signature is valid.
     * @param _mintAmount The number of tokens to mint.
     * @param _signature The signature to be verified.
     */
    function mintPublic(
        uint256 _mintAmount,
        bytes calldata _signature
    )
        external
        payable
        onlyInSaleState(SaleState.Public)
        onlyWithValidMintAmount(_mintAmount)
        onlyWithCorrectPayment(_mintAmount, pricePublic)
        onlyWithValidSignature(_signature, SaleState.Public)
    {
        _mint(_mintAmount);
    }

    /**
     * @notice Mints `_mintAmount` tokens.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintOpen(
        uint256 _mintAmount
    )
        external
        payable
        onlyInSaleState(SaleState.Open)
        onlyWithValidMintAmount(_mintAmount)
        onlyWithCorrectPayment(_mintAmount, pricePublic)
    {
        _mint(_mintAmount);
    }

    /**
     * @notice Revokes the automatic approval of the caller's OpenSea proxy.
     */
    function revokeRegistryApproval()
        external
    {
        if (userRevokedRegistryApproval[_msgSender()])
            revert AlreadyRevokedRegistryApproval();

        userRevokedRegistryApproval[_msgSender()] = true;
    }

    /**
     * @notice (only owner) Mints `_mintAmount` free tokens to the caller.
     * @param _mintAmount The number of tokens to mint.
     */
    function mintPromo(
        uint256 _mintAmount
    )
        external
        onlyOwner
    {
        _mint(_mintAmount);
    }

    /**
     * @notice (only owner) Sets the saleState to `_newSaleState`.
     * @param _newSaleState The new sale state
     * (0=Paused, 1=Whitelist, 2=Presale, 3=Public).
     */
    function setSaleState(
        SaleState _newSaleState
    )
        external
        onlyOwner
    {
        saleState = _newSaleState;
        emit SaleStateChanged(_newSaleState);
    }

    /**
     * @notice (only owner) Sets the whitelist mint price.
     * @param _newPrice The new whitelist mint price.
     */
    function setPriceWhitelist(
        uint256 _newPrice
    )
        external
        onlyOwner
    {
        priceWhitelist = _newPrice;
    }

    /**
     * @notice (only owner) Sets the public mint price.
     * @param _newPrice The new public mint price.
     */
    function setPricePublic(
        uint256 _newPrice
    )
        external
        onlyOwner
    {
        pricePublic = _newPrice;
    }

    /**
     * @notice (only owner) Sets the OpenSea proxy registry contract address.
     * @param _newProxyRegistry The OpenSea proxy registry contract address.
     */
    function setProxyRegistry(
        address _newProxyRegistry
    )
        external
        onlyOwner
    {
        proxyRegistry = _newProxyRegistry;
    }

    /**
     * @notice (only owner) Sets the coupon signer address.
     * @param _newCouponSigner The new coupon signer address.
     */
    function setCouponSigner(
        address _newCouponSigner
    )
        external
        onlyOwner
    {
        couponSigner = _newCouponSigner;
    }

    /**
     * @notice (only owner) Sets the contract URI for contract metadata.
     * @param _newContractURI The new contract URI.
     */
    function setContractURI(
        string calldata _newContractURI
    )
        external
        onlyOwner
    {
        contractURI = _newContractURI;
    }

    /**
     * @notice (only owner) Sets the base URI for token metadata.
     * @param _newBaseURI The new base URI.
     * @param _doReveal If true, this reveals the full tokenURIs.
     */
    function setBaseURI(
        string calldata _newBaseURI,
        bool _doReveal
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
        isRevealed = _doReveal;
    }

    /**
     * @notice (only owner) Sets the provenance hash, optionally locking it.
     * @param _newProvenanceHash The new provenance hash.
     * @param _lockForever Whether to lock this new provenance hash forever.
     */
    function setProvenanceHash(
        bytes32 _newProvenanceHash,
        bool _lockForever
    )
        external
        onlyOwner
    {
        if (provenanceIsLocked) revert ProvenanceHashAlreadyLocked();

        provenanceHash = _newProvenanceHash;
        if (_lockForever) provenanceIsLocked = true;
    }

    /**
     * @notice (only owner) Withdraws all ether to the caller.
     */
    function withdrawAll()
        external
        onlyOwner
    {
        withdraw(address(this).balance);
    }

    /**
     * @notice (only owner) Withdraws `_weiAmount` wei to the caller.
     * @param _weiAmount The amount of ether (in wei) to withdraw.
     */
    function withdraw(
        uint256 _weiAmount
    )
        public
        onlyOwner
    {
        (bool success, ) = payable(_msgSender()).call{value: _weiAmount}("");
        if (!success) revert FailedToWithdraw();
    }

    /**
     * @notice (only owner) Sets ERC-2981 royalties recipient and percentage.
     * @param _recipient The address to which to send royalties.
     * @param _value The royalties percentage (two decimals, e.g. 1000 = 10%).
     */
    function setRoyalties(
        address _recipient,
        uint256 _value
    )
        public
        onlyOwner
    {
        if (_value > MAX_ROYALTIES_PCT) revert ExceedsMaxRoyaltiesPercentage();

        _setRoyalties(
            _recipient,
            _value
        );
    }

    /**
     * @notice Determines whether `_account` owns all token IDs `_tokenIDs`.
     * @param _account The account to be checked for token ownership.
     * @param _tokenIDs An array of token IDs to be checked for ownership.
     * @return True if `_account` owns all token IDs `_tokenIDs`, else false.
     */
    function isOwnerOf(
        address _account,
        uint256[] calldata _tokenIDs
    )
        external
        view
        returns (bool)
    {
        unchecked {
            for (uint256 i; i < _tokenIDs.length; ++i) {
                if (ownerOf(_tokenIDs[i]) != _account)
                    return false;
            }
        }

        return true;
    }

    /**
     * @notice Returns an array of all token IDs owned by `_owner`.
     * @param _owner The address for which to return all owned token IDs.
     * @return An array of all token IDs owned by `_owner`.
     */
    function walletOfOwner(
        address _owner
    )
        public
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) return new uint256[](0);

        uint256[] memory tokenIDs = new uint256[](tokenCount);
        unchecked {
            for (uint256 i; i < tokenCount; i++) {
                tokenIDs[i] = tokenOfOwnerByIndex(_owner, i);
            }
        }
        return tokenIDs;
    }

    /**
     * @notice Checks if `_operator` can transfer tokens owned by `_owner`.
     * @param _owner The address that may own tokens.
     * @param _operator The address that would transfer tokens of `_owner`.
     * @return True if `_operator` can transfer tokens of `_owner`, else false.
     */
    function isApprovedForAll(
        address _owner,
        address _operator
    )
        public
        view
        override (ERC721, IERC721)
        returns (bool)
    {
        if (!userRevokedRegistryApproval[_owner]) {
            OpenSeaProxyRegistry reg = OpenSeaProxyRegistry(proxyRegistry);
            if (address(reg.proxies(_owner)) == _operator) return true;
        }

        return super.isApprovedForAll(_owner, _operator);
    }

    /**
     * @notice Returns the token metadata URI for token ID `_tokenID`.
     * @param _tokenID The token ID whose metadata URI should be returned.
     * @return The metadata URI for token ID `_tokenID`.
     */
    function tokenURI(
        uint256 _tokenID
    )
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(_tokenID)) revert TokenDoesNotExist();
        if (!isRevealed) return baseURI;
        return string(
            abi.encodePacked(
                baseURI,
                Strings.toString(_tokenID),
                ".json"
            )
        );
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(
        bytes4 _interfaceId
    )
        public
        view
        override (ERC721Enumerable, ERC2981Base)
        returns (bool)
    {
        return super.supportsInterface(_interfaceId);
    }

    /**
     * @notice Checks validity of the signature, sender, and saleState.
     * @param _signature The signature to be verified.
     * @param _sender The address part of the signed message.
     * @param _saleState The saleState part of the signed message.
     * @param _chainId The chain ID part of the signed message.
     */
    function isValidSignature(
        bytes calldata _signature,
        address _sender,
        SaleState _saleState,
        uint256 _chainId
    )
        public
        view
        returns (bool)
    {
        bytes32 hash = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    _sender,
                    _saleState,
                    _chainId
                )
            )
        );
        return couponSigner == ECDSA.recover(hash, _signature);
    }

    /**
     * @notice Mints `_mintAmount` tokens to caller, emits actual token IDs.
     */
    function _mint(
        uint256 _mintAmount
    )
        internal
    {
        uint256 totalSupply = _owners.length;
        unchecked {
            if (totalSupply + _mintAmount > MAX_SUPPLY)
                revert ExceedsMaxSupply();
            for (uint256 i; i < _mintAmount; i++) {
                _owners.push(_msgSender());
                emit Transfer(
                    address(0),
                    _msgSender(),
                    _startingTokenID + totalSupply + i
                );
            }
        }
    }
}

/// Stub for OpenSea's per-user-address proxy contract.
contract OwnableDelegateProxy {}

/// Stub for OpenSea's proxy registry contract.
contract OpenSeaProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface ISupremeSkulls {
    enum SaleState {
        Paused,    // 0
        Whitelist, // 1
        Public,    // 2
        Open       // 3
    }

    event SaleStateChanged(
        SaleState newSaleState
    );

    error AlreadyRevokedRegistryApproval();
    error ExceedsMaxMintPerTx();
    error ExceedsMaxRoyaltiesPercentage();
    error ExceedsMaxSupply();
    error ExceedsMintPhaseAllocation();
    error FailedToWithdraw();
    error IncorrectPaymentAmount();
    error InvalidSignature();
    error ProvenanceHashAlreadyLocked();
    error SalePhaseNotActive();
    error TokenDoesNotExist();
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override (IERC165, ERC721)
        returns (bool)
    {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply()
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _owners.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(
            index < _owners.length,
            "ERC721Enumerable: global index out of bounds"
        );
        unchecked {
            return index + _startingTokenID;
        }
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    )
        public
        view
        virtual
        override
        returns (uint256 tokenId)
    {
        require(
            index < balanceOf(owner),
            "ERC721Enumerable: owner index out of bounds"
        );

        uint count;
        unchecked {
            for (uint i; i < _owners.length; i++) {
                if (owner == _owners[i]) {
                    if (count == index) return _startingTokenID + i;
                    else count++;
                }
            }
        }

        revert("ERC721Enumerable: owner index out of bounds");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./ERC2981Base.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
/// @dev This implementation has the same royalties for each and every tokens
abstract contract ERC2981ContractWideRoyalties is ERC2981Base {
    RoyaltyInfo private _royalties;

    /// @dev Sets token royalties
    /// @param _recipient recipient of the royalties
    /// @param _value percentage (using 2 decimals - 10000 = 100, 0 = 0)
    function _setRoyalties(
        address _recipient,
        uint256 _value
    )
        internal
    {
        // unneeded since the derived contract has a lower _value limit
        // require(_value <= 10000, "ERC2981Royalties: Too high");
        _royalties = RoyaltyInfo(_recipient, uint24(_value));
    }

    /// @inheritdoc	IERC2981Royalties
    function royaltyInfo(
        uint256,
        uint256 _value
    )
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        RoyaltyInfo memory royalties = _royalties;
        receiver = royalties.recipient;
        royaltyAmount = (_value * royalties.amount) / 10000;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./IStuckTokens.sol";
import "./SafeERC20.sol";
import "../utils/Ownable.sol";

error ArrayLengthMismatch();

/**
 * @title Token Rescuer
 * @notice Allows owner to transfer out any tokens accidentally sent in.
 * @author Aaron Hanson <[email protected]> @CoffeeConverter
 */
contract TokenRescuer is Ownable {
    using SafeERC20 for IStuckERC20;

    /**
     * @notice Transfers a set of ERC20 `_token` amounts to a set of receivers.
     * @param _token The contract address of the token to be transferred.
     * @param _receivers An array of addresses to receive the tokens.
     * @param _amounts An array of token amounts to transfer to each receiver.
     */
    function rescueBatchERC20(
        address _token,
        address[] calldata _receivers,
        uint256[] calldata _amounts
    )
        external
        onlyOwner
    {
        if (_receivers.length != _amounts.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                _rescueERC20(_token, _receivers[i], _amounts[i]);
            }
        }
    }

    /**
     * @notice Transfers an ERC20 `_token` amount to a single receiver.
     * @param _token The contract address of the token to be transferred.
     * @param _receiver The address to receive the tokens.
     * @param _amount The token amount to transfer to the receiver.
     */
    function rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        external
        onlyOwner
    {
        _rescueERC20(_token, _receiver, _amount);
    }

    /**
     * @notice Transfers sets of ERC721 `_token` IDs to a set of receivers.
     * @param _token The contract address of the token to be transferred.
     * @param _receivers An array of addresses to receive the tokens.
     * @param _tokenIDs Arrays of token IDs to transfer to each receiver.
     */
    function rescueBatchERC721(
        address _token,
        address[] calldata _receivers,
        uint256[][] calldata _tokenIDs
    )
        external
        onlyOwner
    {
        if (_receivers.length != _tokenIDs.length) revert ArrayLengthMismatch();
        unchecked {
            for (uint i; i < _receivers.length; i += 1) {
                uint256[] memory tokenIDs = _tokenIDs[i];
                for (uint j; j < tokenIDs.length; j += 1) {
                    _rescueERC721(_token, _receivers[i], tokenIDs[j]);
                }
            }
        }
    }

    /**
     * @notice Transfers a single ERC721 `_token` token to a single receiver.
     * @param _token The contract address of the token to be transferred.
     * @param _receiver The address to receive the token.
     * @param _tokenID The token ID to transfer to the receiver.
     */
    function rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        external
        onlyOwner
    {
        _rescueERC721(_token, _receiver, _tokenID);
    }

    function _rescueERC20(
        address _token,
        address _receiver,
        uint256 _amount
    )
        private
    {
        IStuckERC20(_token).safeTransfer(_receiver, _amount);
    }

    function _rescueERC721(
        address _token,
        address _receiver,
        uint256 _tokenID
    )
        private
    {
        IStuckERC721(_token).safeTransferFrom(
            address(this),
            _receiver,
            _tokenID
        );
    }
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
pragma solidity ^0.8.12;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "../utils/Context.sol";
import "../utils/Address.sol";

abstract contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    string private _name;
    string private _symbol;
    uint256 internal immutable _startingTokenID;

    // Mapping from token ID to owner address
    address[] internal _owners;

    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 startingTokenID_
    ) {
        _name = name_;
        _symbol = symbol_;
        _startingTokenID = startingTokenID_;
    }

    function _internalTokenID(
        uint256 externalTokenID_
    )
        private
        view
        returns (uint256)
    {
        require(
            externalTokenID_ >= _startingTokenID,
            "ERC721: owner query for nonexistent token"
        );

        unchecked {
            return externalTokenID_ - _startingTokenID;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override (ERC165, IERC165)
        returns (bool)
    {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
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
        returns (uint)
    {
        require(owner != address(0), "ERC721: balance query for the zero address");

        uint count;
        for (uint i; i < _owners.length; ++i) {
            if (owner == _owners[i]) ++count;
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
        address owner = _owners[_internalTokenID(tokenId)];
        require(
            owner != address(0),
            "ERC721: owner query for nonexistent token"
        );
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
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
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
            "ERC721: approved query for nonexistent token"
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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
            "ERC721: transfer caller is not owner nor approved"
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
            "ERC721: transfer caller is not owner nor approved"
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
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        if (tokenId < _startingTokenID) return false;

        uint256 internalID = _internalTokenID(tokenId);
        return internalID < _owners.length && _owners[internalID] != address(0);
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
            "ERC721: operator query for nonexistent token"
        );
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner ||
        getApproved(tokenId) == spender ||
        isApprovedForAll(owner, spender));
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
        _safeMint(to, tokenId, "");
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
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);
        _owners.push(to);

        emit Transfer(address(0), to, tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);
        _owners[_internalTokenID(tokenId)] = address(0);

        emit Transfer(owner, address(0), tokenId);
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
        require(
            ERC721.ownerOf(tokenId) == from,
            "ERC721: transfer of token that is not own"
        );
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);
        _owners[_internalTokenID(tokenId)] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
                    "ERC721: transfer to non ERC721Receiver implementer"
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
        address /*from*/,
        address /*to*/,
        uint256 /*tokenId*/
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

library Address {
    function isContract(address account) internal view returns (bool) {
        return account.code.length > 0;
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./IERC2981Royalties.sol";

/// @dev This is a contract used to add ERC2981 support to ERC721 and 1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    /// @inheritdoc	ERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
        interfaceId == type(IERC2981Royalties).interfaceId ||
        super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {
    /// @notice Called with the sale price to determine how much royalty
    ///         is owed and to whom.
    /// @param _tokenId The NFT asset queried for royalty information
    /// @param _value The sale price of the NFT asset specified by _tokenId
    /// @return _receiver Address of who should be sent the royalty payment
    /// @return _royaltyAmount The royalty payment amount for value sale price
    function royaltyInfo(uint256 _tokenId, uint256 _value)
        external
        view
        returns (address _receiver, uint256 _royaltyAmount);
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IStuckERC20 {
    function transfer(
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IStuckERC721 {
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "./IStuckTokens.sol";
import "./../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IStuckERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IStuckERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// Based on OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)
// With renounceOwnership() removed

pragma solidity ^0.8.12;

import "./Context.sol";

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