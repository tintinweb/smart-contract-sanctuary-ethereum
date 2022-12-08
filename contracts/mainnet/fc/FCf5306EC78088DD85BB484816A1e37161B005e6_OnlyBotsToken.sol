// SPDX-License-Identifier: MIT

/**
       ###    ##    ## #### ##     ##    ###
      ## ##   ###   ##  ##  ###   ###   ## ##
     ##   ##  ####  ##  ##  #### ####  ##   ##
    ##     ## ## ## ##  ##  ## ### ## ##     ##
    ######### ##  ####  ##  ##     ## #########
    ##     ## ##   ###  ##  ##     ## ##     ##
    ##     ## ##    ## #### ##     ## ##     ##
*/

pragma solidity ^0.8.15;
pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./SafeCast.sol";
import "./base64.sol";
import "./UpdatableOperatorFilterer.sol";

import "./OnlyBotsData.sol";
import "./OnlyBotsDeserializerV1.sol";

interface IERC2981 {
    // ERC165 bytes to add to interface array - set in parent contract
    // implementing this standard
    //
    // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
    // bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
    // _registerInterface(_INTERFACE_ID_ERC2981);

    // @notice Called with the sale price to determine how much royalty
    //  is owed and to whom.
    // @param _tokenId - the NFT asset queried for royalty information
    // @param _salePrice - the sale price of the NFT asset specified by _tokenId
    // @return receiver - address of who should be sent the royalty payment
    // @return royaltyAmount - the royalty payment amount for _salePrice
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

contract OnlyBotsToken is
    UpdatableOperatorFilterer,
    Ownable,
    AccessControlEnumerable,
    Pausable,
    ERC721Enumerable,
    IERC2981
{
    error InvalidMintValue(uint256 required, uint256 given);
    error InvalidTokenId(uint256 tokenId);
    error AddressAlreadyMinted(address addr);
    error InvalidSignature(address authSigner, address recoveredSigner);
    error AddressNotAuthorized(address addr);
    error ConsecutiveNotSupported(uint256 givenBatchSize);
    error InvalidMintAddress(address sender, address to);
    error InvalidBurnAddress(address sender, address from);
    error InvalidRNGMax(uint256 max);
    error InvalidRNGRoll(uint256 random);
    error InvalidBotId(uint256 botId);
    error BrokenBotAssignment(uint256 botId, uint256 expectedTokenId, uint256 unexpectedTokenId);
    error MissingBotAssignment(uint256 tokenId);
    error BatchHasRemainingSupply(uint256 supply, uint256 batchOffset, uint256 lastBatchSize);
    error BatchNotAirdropEligible(uint256 batchId);
    error NoDataContracts();
    error InvalidBatchIndex(uint256 given, uint256 currentLength);
    error UnknownBot(uint128 batchIndedx, uint128 relativeBotId);

    event Mint(address indexed recipient, uint256 indexed tokenId, uint256 indexed relativeBotId);

    struct MintStatus {
        bool authorized;
        uint128 lastBatchMinted; // uint128 so entire struct is less than one word
    }

    struct BotId {
        uint128 batchIndex; // zero-indexed
        uint128 relativeBotId; // one-indexed
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant WITHDRAW_ROLE = keccak256("WITHDRAW_ROLE");
    uint128 private constant ROYALTY_SCALE = 1000;
    uint128 private constant ROYALTY_PERCENTAGE = 100; // 10%

    mapping(address => MintStatus) public statuses;
    mapping(uint256 => uint256) private randomBotIdHelper;
    mapping(uint256 => BotId) public tokenIdToBotId;

    OnlyBotsDeserializer public deserializer;
    bool capMint;
    address public authSigner;
    string public openSeaContractURI;
    address public royaltyRecipient;

    DataContract[] public dataContracts;
    uint256 batchOffset;

    constructor(OnlyBotsDeserializer _deserializer, bool _capMint)
        // https://github.com/ProjectOpenSea/operator-filter-registry#deployments
        UpdatableOperatorFilterer(
            0x000000000000AAeB6D7670E522A718067333cd4E,
            0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6,
            true
        )
        ERC721("Onlybots", "ONLYBOTS")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        deserializer = _deserializer;
        capMint = _capMint;
        batchOffset = 0;
    }

    receive() external payable {}

    fallback() external {}

    function owner() public view override(Ownable, UpdatableOperatorFilterer) returns (address) {
        return Ownable.owner();
    }

    function withdraw() public payable onlyRole(WITHDRAW_ROLE) {
        payable(msg.sender).transfer(address(this).balance);
    }

    function appendDataContract(
        OnlyBotsData _onlyBotsAddress,
        uint256 _expectedIndex,
        string calldata _cid
    ) external onlyRole(ADMIN_ROLE) {
        if (_expectedIndex != dataContracts.length) {
            revert InvalidBatchIndex(_expectedIndex, dataContracts.length);
        }

        if (dataContracts.length > 0) {
            uint256 lastBatchSize = dataContracts[dataContracts.length - 1].size;
            uint256 supply = totalSupply();
            if (supply != (batchOffset + lastBatchSize)) {
                revert BatchHasRemainingSupply(supply, batchOffset, lastBatchSize);
            }

            // reset batchOffset
            batchOffset = supply;
        }

        uint256 batchSize = _onlyBotsAddress.getBatchSize();
        uint256 price = _onlyBotsAddress.getPrice();

        // append new data contract
        dataContracts.push(DataContract(_onlyBotsAddress, batchSize, price, _cid));
    }

    function setPaused(bool _value) external onlyRole(ADMIN_ROLE) {
        if (_value) {
            _pause();
        } else {
            _unpause();
        }
    }

    function setAuthSigner(address _signer) external onlyRole(ADMIN_ROLE) {
        authSigner = _signer;
    }

    function setRoyaltyRecipient(address _royaltyRecipient) external onlyRole(ADMIN_ROLE) {
        royaltyRecipient = _royaltyRecipient;
    }

    function setDeserializer(OnlyBotsDeserializer _deserializer) external onlyRole(ADMIN_ROLE) {
        deserializer = _deserializer;
    }

    function setDataContractCID(uint256 _index, string calldata _cid) external onlyRole(ADMIN_ROLE) {
        if (_index >= dataContracts.length) {
            revert InvalidBatchIndex(_index, dataContracts.length);
        }

        dataContracts[_index].cid = _cid;
    }

    function setOpenSeaURI(string calldata _uri) external onlyRole(ADMIN_ROLE) {
        openSeaContractURI = _uri;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 _interfaceId)
        public
        view
        virtual
        override(AccessControlEnumerable, ERC721Enumerable)
        returns (bool)
    {
        return _interfaceId == type(IERC2981).interfaceId || super.supportsInterface(_interfaceId);
    }

    function airdrop(address _airdropRecipient) external onlyRole(ADMIN_ROLE) {
        // airdrops only for the first (0th) batch
        if (dataContracts.length > 1) {
            revert BatchNotAirdropEligible(dataContracts.length - 1);
        }

        DataContract storage dataContract = dataContracts[0];
        uint256 tokenId = totalSupply() + 1;
        uint256 batchSize = dataContract.size;

        if (tokenId < 1 || tokenId > batchSize) {
            revert InvalidTokenId(tokenId);
        }

        BotId memory botId = BotId({batchIndex: uint128(0), relativeBotId: SafeCast.toUint128(tokenId)});

        _safeMint(_airdropRecipient, tokenId);
        tokenIdToBotId[tokenId] = botId;
        emit Mint(_airdropRecipient, tokenId, botId.relativeBotId);
    }

    function mint() public payable whenNotPaused {
        if (dataContracts.length < 1) {
            revert NoDataContracts();
        }
        uint128 batchIndex = SafeCast.toUint128(dataContracts.length - 1);
        DataContract storage dataContract = dataContracts[batchIndex];
        uint256 batchPrice = dataContract.price;
        uint256 batchSize = dataContract.size;

        if (msg.value != batchPrice) {
            revert InvalidMintValue(batchPrice, msg.value);
        }

        uint256 tokenId = totalSupply() + 1;
        if (tokenId < 1 || tokenId > (batchOffset + batchSize)) {
            revert InvalidTokenId(tokenId);
        }
        _safeMint(msg.sender, tokenId);
        BotId memory botId = assignBot(tokenId, batchIndex, batchSize);
        emit Mint(msg.sender, tokenId, botId.relativeBotId);
    }

    function authorize(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public whenNotPaused {
        // verify that message passed as argument was signed by our mint auth
        // wallet and contained our msg.sender in the message
        bytes32 hash = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked("onlybots mint authorization|", msg.sender))
            )
        );
        address recoveredSigner = ecrecover(hash, _v, _r, _s);
        if (recoveredSigner != authSigner) {
            revert InvalidSignature(authSigner, recoveredSigner);
        }

        MintStatus storage status = statuses[msg.sender];
        status.authorized = true;
    }

    function authorizeAndMint(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external payable whenNotPaused {
        authorize(_v, _r, _s);
        mint();
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        _requireMinted(_tokenId);

        BotId memory botId = tokenIdToBotId[_tokenId];
        if (botId.relativeBotId == 0) {
            revert MissingBotAssignment(_tokenId);
        }

        if (botId.batchIndex >= dataContracts.length) {
            revert InvalidBatchIndex(botId.batchIndex, dataContracts.length);
        }

        return
            string.concat(
                "ipfs://",
                dataContracts[botId.batchIndex].cid,
                "/",
                Strings.toString(botId.relativeBotId),
                ".json"
            );
    }

    function getWalletAuthorization() external view returns (bool) {
        return statuses[msg.sender].authorized;
    }

    function getBotData(uint256 _tokenId) public view returns (string memory) {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId(_tokenId);
        }

        BotId memory botId = tokenIdToBotId[_tokenId];
        if (botId.relativeBotId == 0) {
            revert MissingBotAssignment(_tokenId);
        }

        return deserializer.deserialize(dataContracts[botId.batchIndex], botId.batchIndex, botId.relativeBotId);
    }

    function findTokenId(uint128 _batchIndex, uint128 _relativeBotId) public view returns (uint256) {
        uint256 supply = totalSupply();
        uint256 tokenId = 1;

        // Skip tokens that are not part of this batch
        for (uint256 currentBatchIndex = 0; currentBatchIndex < _batchIndex; currentBatchIndex++) {
            tokenId += dataContracts[currentBatchIndex].size;
        }

        for (; tokenId <= supply; tokenId++) {
            if (
                tokenIdToBotId[tokenId].batchIndex == _batchIndex &&
                tokenIdToBotId[tokenId].relativeBotId == _relativeBotId
            ) {
                return tokenId;
            }
        }

        revert UnknownBot(_batchIndex, _relativeBotId);
    }

    function getCurrentBatchInfo()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        if (dataContracts.length < 1) {
            revert NoDataContracts();
        }
        uint256 batchIndex = dataContracts.length - 1;
        DataContract storage dataContract = dataContracts[batchIndex];
        return (batchIndex, dataContract.price, dataContract.size - (totalSupply() - batchOffset));
    }

    function assignBot(
        uint256 _tokenId,
        uint128 _batchIndex,
        uint256 _batchSize
    ) private returns (BotId memory) {
        uint256 maxMintId = batchOffset + _batchSize;
        uint256 max = maxMintId - (_tokenId - 1);
        if (max < 1 || max > maxMintId) {
            revert InvalidRNGMax(max);
        }

        uint256 random = getPseudoRandomOneToN(_tokenId, block.timestamp, msg.sender, max);
        if (random < 1 || random > max) {
            revert InvalidRNGRoll(random);
        }

        // This pattern emulates a ONE-INDEXED list of length MAX_MINT_ID where each element value is the same is its index (a bot ID from 1 to MAX_MINT_ID).

        // We randomly roll an element of the list, then "delete" that element by replacing the rolled index by `max`
        //   * Since we "delete" an element every mint, `max` will never be able to roll naturally after this
        //   * If `max` value has been replaced (randomBotIdHelper[max] != 0), use that value instead of `max` when replacing the rolled value
        //   * If we rolled `max`, no need to update since a mapping of randomBotIdHelper[max] would never be accessible again
        //   * If this value has already been replaced (randomBotIdHelper[random] != 0), we still want to replace that value with the new `max` (or its replaced value) to prevent it from being rolled again
        //   * If randomBotIdHelper[max] has a value, set it to 0 after potentially copying it to the new location.  After all bots in this batch are minted, randomBotIdHelper will be empty and ready for use with the next batch
        uint256 relativeBotId = randomBotIdHelper[random] != 0 ? randomBotIdHelper[random] : random;
        if (random != max) {
            randomBotIdHelper[random] = randomBotIdHelper[max] != 0 ? randomBotIdHelper[max] : max;
        }
        if (randomBotIdHelper[max] != 0) {
            randomBotIdHelper[max] = 0;
        }

        if (relativeBotId < 1 || relativeBotId > _batchSize) {
            revert InvalidBotId(relativeBotId);
        }

        BotId memory botId = BotId({batchIndex: _batchIndex, relativeBotId: SafeCast.toUint128(relativeBotId)});
        tokenIdToBotId[_tokenId] = botId;
        return botId;
    }

    function getPseudoRandomOneToN(
        uint256 _tokenId,
        uint256 _blockTimestamp,
        address _sender,
        uint256 _n
    ) private pure returns (uint256) {
        // rand % n => 0..(n - 1)
        // (rand % n) + 1 => 1..n
        return (uint256(keccak256(abi.encodePacked(_tokenId, _sender, _blockTimestamp))) % _n) + 1;
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
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);

        if (batchSize != 1) {
            revert ConsecutiveNotSupported(batchSize);
        }

        // first batch (dataContracts.length = 1) is for airdrops and shouldn't use
        // the same checks as subsequent batches
        if (from == address(0) && dataContracts.length > 1) {
            if (msg.sender != to) {
                revert InvalidMintAddress(msg.sender, to);
            }

            MintStatus storage status = statuses[to];
            if (!status.authorized) {
                revert AddressNotAuthorized(to);
            }
            if (capMint && status.lastBatchMinted == dataContracts.length - 1) {
                revert AddressAlreadyMinted(to);
            }
            status.lastBatchMinted = SafeCast.toUint128(dataContracts.length - 1);
        } else if (dataContracts.length == 1) {
            // only admin may airdrop
            if (!hasRole(ADMIN_ROLE, msg.sender)) {
                revert AddressNotAuthorized(msg.sender);
            }
        }

        if (to == address(0)) {
            if (msg.sender != from) {
                revert InvalidBurnAddress(msg.sender, from);
            }
        }
    }

    // Operator filtering
    function setApprovalForAll(address operator, bool approved)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.setApprovalForAll(operator, approved);
    }

    function approve(address operator, uint256 tokenId)
        public
        override(ERC721, IERC721)
        onlyAllowedOperatorApproval(operator)
    {
        super.approve(operator, tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public override(ERC721, IERC721) onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        return (royaltyRecipient, percentage(_salePrice, ROYALTY_PERCENTAGE, ROYALTY_SCALE));
    }

    // Calculate base * ratio / scale rounding down.
    // https://ethereum.stackexchange.com/a/79736
    // NOTE: As of solidity 0.8, SafeMath is no longer required
    function percentage(
        uint256 base,
        uint256 ratio,
        uint128 scale
    ) internal pure returns (uint256) {
        uint256 baseDiv = base / scale;
        uint256 baseMod = base % scale;
        uint256 ratioDiv = ratio / scale;
        uint256 ratioMod = ratio % scale;

        return
            (baseDiv * ratioDiv * scale) + (baseDiv * ratioMod) + (baseMod * ratioDiv) + ((baseMod * ratioMod) / scale);
    }
}