/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./access/AccessControl.sol";
import "./token/common/ERC2981CommunalEditions.sol";
import "./token/ERC1155/extensions/ERC1155Burnable.sol";
import "./token/ERC1155/extensions/ERC1155URIStorage.sol";
import "./token/ERC1155/extensions/ERC1155Supply.sol";

/************************************************************
 * @title NinfaERC1155                                      *
 *                                                          *
 * @notice Communal Ninfa ERC-1155 collection               *
 *                                                          *
 * @dev {ERC1155} token implements lazy minting             *
 *      in order to guarantee primary market fee payments   *
 *                                                          *
 * @custom:security-contact [email protected]                   *
 ***********************************************************/

contract NinfaERC1155 is
    AccessControl,
    ERC2981CommunalEditions,
    ERC1155Burnable,
    ERC1155URIStorage,
    ERC1155Supply
{
    // EIP-712
    bytes32 private immutable DOMAIN_SEPARATOR;
    bytes32 private immutable VOUCHER_TYPEHASH;

    // Acces Control
    bytes32 private constant MINTER_ROLE =
        0x9f2df0fed2c77648de5860a4cc508cd0818c85b8b8a1ab4ceeef8d981c8956a6; // keccak256("MINTER_ROLE"); one or more smart contracts allowed to call the mint function, eg. the Marketplace contract
    bytes32 private constant CURATOR_ROLE =
        0x850d585eb7f024ccee5e68e55f2c26cc72e1e6ee456acf62135757a5eb9d4a10; // keccak256("CURATOR_ROLE")

    // Market fees
    uint24 private _primaryFeeBps;
    address private _marketFeeRecipient;

    // Metadata (OPTIONAL non-standard, see https://eips.ethereum.org/EIPS/eip-1155#metadata-choices)
    string public name = "NINFA";
    string public symbol = "NINFA";

    /**
     * @param totalValue maximum tokenId editions cap, if unlimited supply use `type(uint256).max` i.e. 2**256 - 1
     * @param endTime timestamp for when the signed voucher should expire,
     *      if no expiration is needed, timestamp should be `type(uint256).max` i.e. 2**256 - 1,
     *      or anything above 2^32, i.e. 4294967296, i.e. voucher expires after 2106 (in 83 years time)
     */
    struct Voucher {
        bytes32 tokenUri;
        uint256 unitPrice;
        uint256 totalValue;
        uint256 endTime;
        uint256 saleCommissionBps;
        address saleCommissionRecipient;
    }

    /*----------------------------------------------------------*|
    |*  # MINTER FUNCTIONS                                      *|
    |*----------------------------------------------------------*/

    /**
     * @param _tokenId may correspond to an already existing tokenId, if so, the corresponding tokenUri at `_tokenURIs[_tokenId]` MUST equal `voucher.tokenUri`,
     *      or it may be an inexisting tokenId such as 2^256-1 in which case a new token will be minted, provided that `voucher.tokenUri` has never been minted before.
     * @param _value the amount/supply of `tokenId` to be minted, provided that the total tokenId's circulating supply does not exceed the one (if any) specified in `voucher.totalValue`.
     * @param _to buyer, needed if using a external payment gateway, so that the minted tokenId value is sent to the address specified insead of `msg.sender`
     * @param _data data bytes are passed to `onErc1155Received` function if the `_to` address is a contract, for example a marketplace.
     *      `onErc1155Received` is not being called on the minter's address when a new tokenId is minted however, even if it was contract.
     */
    function lazyMint(
        Voucher calldata _voucher,
        uint256 _tokenId,
        uint256 _value,
        address _to,
        bytes memory _signature,
        bytes calldata _data
    ) external payable {
        /*----------------------------------------------------------*|
        |*  # EIP-712 TYPED DATA SIGNATURE VERIFICATION             *|
        |*----------------------------------------------------------*/

        address signer = _recover(_voucher, _signature);

        uint256 sellerAmount = _voucher.unitPrice * _value;

        require(
            // `msg.value` MUST equal ETH unit price multiplied by token value/amount
            msg.value == sellerAmount &&
                // _voucher MUST not be expired
                block.timestamp < _voucher.endTime
        );

        /*----------------------------------------------------------*|
        |*  # MINT                                                  *|
        |*----------------------------------------------------------*/

        if (exists(_tokenId)) {
            /**
             * @dev since `_tokenId` is a user-supplied parameter it can't be trusted, therefore if increasing supply fot an existing token,
             *      the `tokenUri` contained in the `_voucher` MUST match the one stored at `_tokenURIs[_tokenId]`.
             */
            require(
                _voucher.tokenUri == _tokenURIs[_tokenId] &&
                    (_totalSupply[_tokenId] += _value) <= _voucher.totalValue &&
                    /**
                     * @dev The `_voucher` signer MUST be the original artist or at least a royalty recipient for the user-supplied `_tokenId`,
                     *      otherwise a malicious artist could sign a _voucher with the same URI of another artist's token they want to mint and set price to 0,
                     *      alowing them to mint new tokens for free; although minter's address will result as the malicious signer, it is still a risk as these "fake" tokens may still be traded.
                     *      this check is only needed for communal ERC-1155 editions where there are multiple artists,
                     *      as opposed to self-sovreign ERC-1155 editions where there is a single deployer/artist
                     */
                    (signer == _royaltyRecipients[_tokenId] ||
                        signer == artists[_tokenId])
            );
        } else {
            require(
                _value <= _voucher.totalValue && hasRole(MINTER_ROLE, signer)
            );
            /// @dev since `_tokenId` is user-supplied it MUST be reassigned the correct value for the rest of the function work correctly
            _tokenId = _totalSupply.length;
            _totalSupply.push(_value);
            _tokenURIs[_tokenId] = _voucher.tokenUri;
            _royaltyRecipients[_tokenId] = payable(signer);
        }

        /**
         * @dev the following is the net state change after tokenId `_value` has been minted and transferred to a buyer,
         *      rather than calling the internal `_mint` function which whould increase balance of minter, followed by `safeTransferFrom`, which would decrease it.
         *      I.e. minter balance is not updated as it would cancel out anyway after sending the newly minted tokenId `_value` to buyer.
         *      Additionally `safeTransferFrom` function has been omitted otherwise `msg.sender` would have to be an authorized operator by the seller/minter.
         */
        unchecked {
            _balanceOf[_to][_tokenId] += _value;
        }

        // event is needed in order to signal to DApps that a mint has occurred
        emit TransferSingle(msg.sender, address(0), signer, _tokenId, _value);
        // event is needed in order to signal to DApps that a token transfer has occurred
        emit TransferSingle(msg.sender, signer, _to, _tokenId, _value);

        /*----------------------------------------------------------*|
        |*  # PAY MARKET FEES                                       *|
        |*----------------------------------------------------------*/

        uint256 marketFeeAmount = (msg.value * _primaryFeeBps) / 10000;
        sellerAmount -= marketFeeAmount;
        _sendValue(_marketFeeRecipient, marketFeeAmount);

        /*----------------------------------------------------------*|
        |*  # CHECK-EFFECTS-INTERACTIONS                            *|
        |*----------------------------------------------------------*/
        /// @dev perform external calls to untrusted addresses last

        /*----------------------------------------------------------*|
        |*  # PAY SELLER (AND COMMISSIONS)                          *|
        |*----------------------------------------------------------*/

        if (_voucher.saleCommissionBps > 0) {
            uint256 commissionAmount = (msg.value *
                _voucher.saleCommissionBps) / 10000;
            sellerAmount -= commissionAmount;
            _sendValue(_voucher.saleCommissionRecipient, commissionAmount);
        }

        _sendValue(signer, sellerAmount);

        /*----------------------------------------------------------*|
        |*  # SAFE TRANSFER                                         *|
        |*----------------------------------------------------------*/
        /// @dev onERC1155Received is not called on the minter's account

        if (_to.code.length > 0)
            require(
                IERC1155Receiver(_to).onERC1155Received(
                    msg.sender, // operator
                    signer, // from
                    _tokenId, // token id
                    _value, // value
                    _data
                ) == 0xf23a6e61, // IERC1155Receiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    /*----------------------------------------------------------*|
    |*  # BURN                                                  *|
    |*----------------------------------------------------------*/

    function burn(address _from, uint256 _id, uint256 _value) public override {
        super.burn(_from, _id, _value);
        /// @dev since balance has already been decremented without underflow,
        // `_totalSupply` may be safely decremented. See {ERC1155-_burn}
        unchecked {
            _totalSupply[_id] -= _value;
        }
        // if all supply has been burned, _tokenURIs[_id] is deleted from storage
        if (_totalSupply[_id] == 0) delete _tokenURIs[_id];
    }

    /*----------------------------------------------------------*|
    |*  # PRIVATE FUNCTIONS                                     *|
    |*----------------------------------------------------------*/

    function _recover(
        Voucher calldata _voucher,
        bytes memory _signature
    ) private view returns (address _signer) {
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        VOUCHER_TYPEHASH,
                        _voucher.tokenUri,
                        _voucher.unitPrice,
                        _voucher.totalValue,
                        _voucher.endTime,
                        _voucher.saleCommissionBps,
                        _voucher.saleCommissionRecipient
                    )
                )
            )
        );

        bytes32 r;
        bytes32 s;
        uint8 v;

        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        _signer = ecrecover(digest, v, r, s);
        if (_signer == address(0)) revert();
    }

    function _sendValue(address _receiver, uint256 _amount) private {
        (bool success, ) = payable(_receiver).call{value: _amount}("");
        require(success);
    }

    /*----------------------------------------------------------*|
    |*  # ERC-165 LOGIC                                         *|
    |*----------------------------------------------------------*/

    function supportsInterface(
        bytes4 interfaceId
    ) external pure returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // Interface ID for IERC165
            interfaceId == 0xd9b67a26 || // Interface ID for IERC1155
            interfaceId == 0x0e89341c || // Interface ID for IERC1155MetadataURI
            interfaceId == 0x2a55205a || // Interface ID for IERC2981
            interfaceId == 0x7965db0b; // Interface ID for IAccessControl
    }

    /*----------------------------------------------------------*|
    |*  # ADMIN FUNCTIONS                                       *|
    |*----------------------------------------------------------*/

    function setFeeAccount(
        address feeAccount_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _marketFeeRecipient = feeAccount_;
    }

    function setPrimaryFeeBps(
        uint24 primaryFeeBps_
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _primaryFeeBps = primaryFeeBps_;
    }

    /**
     * @notice creates `DOMAIN_SEPARATOR` and `VOUCHER_TYPEHASH`,
     *      Grants `DEFAULT_ADMIN_ROLE` to the account that deploys the contract,
     *      assigns `CURATOR_ROLE` as the admin role for `MINTER_ROLE`,
     *      sets fee account address and fee BPS to 10% on primary market sales.
     * @param feeAccount_ admin multisig contract for receiving market fees on sales.
     */
    constructor(address feeAccount_) {
        /**
         * @dev The EIP712Domain fields should be the order as above, skipping any absent fields.
         *      Protocol designers only need to include the fields that make sense for their signing domain. Unused fields are left out of the struct type.
         * @param name the user readable name of signing domain, i.e. the name of the DApp or the protocol.
         * @param chainId the EIP-155 chain id. The user-agent should refuse signing if it does not match the currently active chain.
         * @param verifyingContract the address of the contract that will verify the signature. The user-agent may do contract specific phishing prevention.
         *      verifyingContract is the only variable parameter in the DOMAIN_SEPARATOR in order to avoid signature replay across different contracts
         *      therefore the DOMAIN_SEPARATOR MUST be calculated inside of the `initialize` function rather than the constructor.
         */
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                0x8cad95687ba82c2ce50e74f7b754645e5117c3a5bec8151c0726d5857980a866, // hardcoded value for keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)"), DOMAIN_TYPEHASH
                0xdb3dd9b854cdb7551722584c7e89b5df9798432c0c9ee9bc6f62a8edfed5dac4, // hardcoded value for keccak256(bytes("ninfa.io")),
                block.chainid,
                address(this)
            )
        );
        VOUCHER_TYPEHASH = keccak256(
            "Voucher(bytes32 tokenUri,uint256 unitPrice,uint256 totalValue,uint256 endTime,uint256 saleCommissionBps,address saleCommissionRecipient)"
        );

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(MINTER_ROLE, CURATOR_ROLE);

        _marketFeeRecipient = feeAccount_;
        _primaryFeeBps = 1000; // 10% marketplace fees on primary market sales
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity 0.8.17;

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
    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
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

pragma solidity 0.8.17;

/// @dev stripped down version of https://github.com/MrChico/verifyIPFS/
library DecodeTokenURI {
    bytes constant ALPHABET =
        "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

    /**
     * @dev Converts hex string to base 58
     */
    function toBase58(bytes memory source)
        internal
        pure
        returns (bytes memory)
    {
        if (source.length == 0) return new bytes(0);
        uint8[] memory digits = new uint8[](64);
        digits[0] = 0;
        uint8 digitlength = 1;
        for (uint256 i = 0; i < source.length; ++i) {
            uint256 carry = uint8(source[i]);
            for (uint256 j = 0; j < digitlength; ++j) {
                carry += uint256(digits[j]) * 256;
                digits[j] = uint8(carry % 58);
                carry = carry / 58;
            }

            while (carry > 0) {
                digits[digitlength] = uint8(carry % 58);
                digitlength++;
                carry = carry / 58;
            }
        }
        return toAlphabet(reverse(truncate(digits, digitlength)));
    }

    function toAlphabet(uint8[] memory indices)
        private
        pure
        returns (bytes memory)
    {
        bytes memory output = new bytes(indices.length);
        for (uint256 i = 0; i < indices.length; i++) {
            output[i] = ALPHABET[indices[i]];
        }
        return output;
    }

    function truncate(uint8[] memory array, uint8 length)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](length);
        for (uint256 i = 0; i < length; i++) {
            output[i] = array[i];
        }
        return output;
    }

    function reverse(uint8[] memory input)
        private
        pure
        returns (uint8[] memory)
    {
        uint8[] memory output = new uint8[](input.length);
        for (uint256 i = 0; i < input.length; i++) {
            output[i] = input[input.length - 1 - i];
        }
        return output;
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/*************************************************************
 * @title ERC2981CommunalEditions                            *
 *                                                           *
 * @notice Adds ERC-2981 support to {ERC1155}                *
 *                                                           *
 * @dev {ERC2981} royalties for communal collections         *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC2981CommunalEditions {
    /**
     * @notice `_royaltyRecipients` maps token ID to original artist, used for sending royalties to _royaltyRecipients on all secondary sales.
     *      This is meant for communal editions; in self-sovreign editions there is a single contract-wide royalty recipient
     * @dev "If you plan on having a contract where NFTs are created by multiple authors AND they can update royalty details after minting,
     *      you will need to record the original author of each token." - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
     */
    mapping(uint256 => address payable) internal _royaltyRecipients; // internal as used by child contract
    mapping(uint256 => address) internal artists; // tokenId to original creator address
    /// @dev "For precision purposes, it's better to express the royalty percentage as "basis points" (points per 10_000, e.g., 10% = 1000 bps) and compute the amount is `(royaltyBps[_tokenId] * _salePrice) / 10000`" - https://forum.openzeppelin.com/t/setting-erc2981/16065/2
    uint24 internal constant ROYALTY_BPS = 1000; // 10% fixed royalties
    uint24 private constant TOTAL_SHARES = 10000; // 10,000 = 100% (total sale price)

    /**
     * @notice Called with the sale price to determine how much royalty
     *          is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return recipient - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address recipient, uint256 royaltyAmount) {
        recipient = _royaltyRecipients[_tokenId];
        royaltyAmount = (_salePrice * ROYALTY_BPS) / TOTAL_SHARES;
    }

    /**
     * @notice This function is used when the artist decides to set the royalty recipient to an address other than its own.
     * It adds the artist address to the `artists` mapping in {ERC2981Communal}, in order to use it for access control in `setRoyaltyRecipient()`. This removes the burden of setting this mapping in the `mint()` function as it will rarely be needed.
     * @param _royaltyRecipient (likely a payment splitter contract) may be 0x0 although it is not intended as ETH would be burnt if sent to 0x0. If the user only wants to mint it should call mint() instead, so that the roy
     *
     * Require:
     *
     * - If the `artists` for `_tokenId` mapping is empty, the minter's address is equal to `_royaltyRecipients[_tokenId]`. I.e. the caller must correspond to `_royaltyRecipients[_tokenId]`, i.e. the token minter/artist
     * - Else, the caller must correspond to the `_tokenId`'s minter address set in `artists[_tokenId]`, i.e. if `artists[_tokenId]` is not 0x0. Note that the artist address cannot be reset.
     *
     * Allow:
     *
     * - the minter may (re)set `_royaltyRecipients[_tokenId]` to the same address as `artists[_tokenId]`, i.e. the minter/artist. This would be quite useless, but not dangerous. The frontend should disallow it.
     *
     */
    function setRoyaltyRecipient(
        address _royaltyRecipient,
        uint256 _tokenId
    ) external {
        if (artists[_tokenId] == address(0)) {
            require(msg.sender == _royaltyRecipients[_tokenId]); // require that the token has already been minted and that the caller is the minter
            artists[_tokenId] = msg.sender;
        } else {
            require(msg.sender == artists[_tokenId]);
        }

        _royaltyRecipients[_tokenId] = payable(_royaltyRecipient);
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";
import "../../../utils/DecodeTokenURI.sol";

/**
 * @dev ERC1155 token with storage based token URI management.
 */
abstract contract ERC1155URIStorage is ERC1155 {
    using DecodeTokenURI for bytes;

    /**
     * @dev _baseURI is hardcoded and cannot be modified, as the expected token URI MUST be an IPFSv1 hash
     */
    string private _baseURI = "ipfs://";
    /**
     * @dev Optional mapping for token URIs. Internal as needs to be read by child implementation
     *      returns bytes32 IPFS hash
     */
    mapping(uint256 => bytes32) internal _tokenURIs;

    /**
     * @dev Returns the URI for token type `id`.
     */
    function uri(uint256 tokenId) public view returns (string memory) {
        require(_tokenURIs[tokenId] != 0x00, "ERC1155: nonexistent token");
        return
            string( // once hex decoded base58 is converted to string, we get the initial IPFS hash
                abi.encodePacked(
                    _baseURI,
                    abi
                    .encodePacked( // full bytes of base58 + hex encoded IPFS hash example.
                        bytes2(0x1220), // prepending 2 bytes IPFS hash identifier that was removed before storing the hash in order to fit in bytes32. 0x1220 is "Qm" base58 and hex encoded
                        _tokenURIs[tokenId] // bytes32(tokenId) // tokenURI (IPFS hash) with its first 2 bytes truncated, base58 and hex encoded returned as bytes32
                    ).toBase58()
                )
            );
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 *
 */
abstract contract ERC1155Supply is ERC1155 {
    /**
     * @dev keeps track of per-token id's total supply, as well as overall supply.
     *      also used as a counter when minting, by reading the .length property of the array.
     * @dev toalSupply MUST be incremented by the implementing contract, as `_beforeTokenTransfer` function
     *      has been removed in order to make normal (non-mint) transfers cheaper.
     */
    uint256[] internal _totalSupply;

    /**
     * @dev Total amount of tokens in with a given _id.
     * @dev > The total value transferred from address 0x0 minus the total value transferred to 0x0 observed via the TransferSingle and TransferBatch events MAY be used by clients and exchanges to determine the “circulating supply” for a given token ID.
     */
    function totalSupply(uint256 _id) public view returns (uint256) {
        return _totalSupply[_id];
    }

    /**
     * @dev Amount of unique token ids in this collection, required in order to
     *      enumerate `_totalSupply` (or `_tokenURIs`, see {ERC1155URIStorage-uri}) from a client
     */
    function totalSupply() external view returns (uint256) {
        return _totalSupply.length;
    }

    /**
     * @dev Indicates whether any token exist with a given _id, or not.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function exists(uint256 _id) public view returns (bool) {
        return _totalSupply.length > _id;
    }
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155.sol";

/*************************************************************
 * @title ERC1155Burnable                                    *
 *                                                           *
 * @notice  ERC-1155 burnable extension                      *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC1155Burnable is ERC1155 {
    function burn(address _from, uint256 _id, uint256 _value) public virtual {
        require(msg.sender == _from || isApprovedForAll[_from][msg.sender]);

        _burn(_from, _id, _value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

interface IERC1155Receiver {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

/*----------------------------------------------------------*|
|*          ███    ██ ██ ███    ██ ███████  █████           *|
|*          ████   ██ ██ ████   ██ ██      ██   ██          *|
|*          ██ ██  ██ ██ ██ ██  ██ █████   ███████          *|
|*          ██  ██ ██ ██ ██  ██ ██ ██      ██   ██          *|
|*          ██   ████ ██ ██   ████ ██      ██   ██          *|
|*----------------------------------------------------------*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./IERC1155Receiver.sol";

/*************************************************************
 * @title ERC1155                                            *
 *                                                           *
 * @notice Gas efficient standard ERC1155 implementation.    *
 *                                                           *
 * @author Fork of solmate ERC1155                           *
 *      https://github.com/Rari-Capital/solmate/             *
 *                                                           *
 * @dev includes `_totalSupply` array needed in order to     *
 *      implement a maxSupply limit for lazy minting         *
 *                                                           *
 * @custom:security-contact [email protected]                    *
 ************************************************************/

contract ERC1155 {
    /*----------------------------------------------------------*|
    |*  # EVENTS                                                *|
    |*----------------------------------------------------------*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 value
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    event URI(string value, uint256 indexed id);

    /*----------------------------------------------------------*|
    |*  # ERC-1155 STORAGE LOGIC                                *|
    |*----------------------------------------------------------*/

    mapping(address => mapping(uint256 => uint256)) internal _balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll; // Mapping from account to operator approvals

    /*----------------------------------------------------------*|
    |*  # ERC-1155 LOGIC                                        *|
    |*----------------------------------------------------------*/

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public {
        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "ERC1155: NOT_AUTHORIZED"
        );

        _balanceOf[from][id] -= amount;
        _balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : IERC1155Receiver(to).onERC1155Received(
                    msg.sender,
                    from,
                    id,
                    amount,
                    data
                ) == IERC1155Receiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(
            msg.sender == from || isApprovedForAll[from][msg.sender],
            "NOT_AUTHORIZED"
        );

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            _balanceOf[from][id] -= amount;
            _balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    from,
                    ids,
                    amounts,
                    data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(
        address[] calldata owners,
        uint256[] calldata ids
    ) external view returns (uint256[] memory balances) {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = _balanceOf[owners[i]][ids[i]];
            }
        }
    }

    function balanceOf(
        address _owner,
        uint256 _id
    ) external view returns (uint256 balance) {
        balance = _balanceOf[_owner][_id];
    }

    /*----------------------------------------------------------*|
    |*  # INTERNAL MINT/BURN LOGIC                              *|
    |*----------------------------------------------------------*/

    function _mint(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) internal {
        _balanceOf[_to][_id] += _amount;

        emit TransferSingle(msg.sender, address(0), _to, _id, _amount);

        if (_to.code.length > 0)
            require(
                IERC1155Receiver(_to).onERC1155Received(
                    msg.sender,
                    address(0),
                    _id,
                    _amount,
                    _data
                ) == IERC1155Receiver.onERC1155Received.selector,
                "UNSAFE_RECIPIENT"
            );
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            _balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : IERC1155Receiver(to).onERC1155BatchReceived(
                    msg.sender,
                    address(0),
                    ids,
                    amounts,
                    data
                ) == IERC1155Receiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _burn(address _from, uint256 _id, uint256 _value) internal {
        // `require(fromBalance >= _value)` is implicitly enforced
        _balanceOf[_from][_id] -= _value;

        emit TransferSingle(msg.sender, _from, address(0), _id, _value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity 0.8.17;

import "../utils/Strings.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, msg.sender);
        _;
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external {
        require(
            account == msg.sender,
            "AccessControl: can only renounce roles for self"
        );

        _revokeRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, msg.sender);
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, msg.sender);
        }
    }
}