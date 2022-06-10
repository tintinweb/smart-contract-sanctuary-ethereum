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

pragma solidity ^0.8.13;
pragma abicoder v2;

import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./AccessControlEnumerable.sol";
import "./Pausable.sol";
import "./Strings.sol";
import "./base64.sol";

import "./OnlyBotsData.sol";
import "./OnlyBotsDeserializerV1.sol";

contract OnlyBotsToken is Ownable, AccessControlEnumerable, ERC721Enumerable, Pausable {
    error InvalidDataContractSizes(uint256 given, uint256 expected);
    error InvalidTokenId(uint256 tokenId);
    error AddressAlreadyMinted(address addr);
    error InvalidSignature(address authSigner, address recoveredSigner);
    error AddressNotAuthorized(address addr);
    error InvalidMintAddress(address sender, address to);
    error InvalidBurnAddress(address sender, address from);
    error InvalidRNGMax(uint256 max);
    error InvalidRNGRoll(uint256 random);
    error InvalidBotId(uint256 botId);
    error BrokenBotAssignment(uint256 botId, uint256 expectedTokenId, uint256 unexpectedTokenId);
    error MissingBotAssignment(uint256 tokenId);

    event Mint(address indexed recipient, uint256 indexed tokenId, uint256 indexed botId);

    struct MintStatus {
        bool authorized;
        bool minted;
    }

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    uint256 private constant MAX_MINT_ID = 256;

    mapping(address => MintStatus) public statuses;
    mapping(uint256 => uint256) private randomBotIdHelper;
    mapping(uint256 => uint256) public tokenIdToBotId;
    mapping(uint256 => uint256) public botIdToTokenId;

    OnlyBotsDeserializer public deserializer;
    OnlyBotsDeserializer.DataContract[] public dataContracts;

    address public authSigner;
    string public openSeaContractURI;
    string baseTokenURI;

    constructor(OnlyBotsDeserializer.DataContract[] memory _dataContracts, OnlyBotsDeserializer _deserializer)
        ERC721("Only Bots", "ONLYBOTS")
    {
        _setupRole(DEFAULT_ADMIN_ROLE, owner());

        deserializer = _deserializer;

        uint256 dataCount = 0;
        for (uint256 i = 0; i < _dataContracts.length; i++) {
            dataCount += _dataContracts[i].size;
            dataContracts.push(_dataContracts[i]);
        }

        if (dataCount != MAX_MINT_ID) {
            revert InvalidDataContractSizes(dataCount, MAX_MINT_ID);
        }
    }

    receive() external payable {}

    fallback() external {}

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

    function setDeserializer(OnlyBotsDeserializer _deserializer) external onlyRole(ADMIN_ROLE) {
        deserializer = _deserializer;
    }

    function setOpenSeaURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        openSeaContractURI = _uri;
    }

    function setBaseTokenURI(string memory _uri) external onlyRole(ADMIN_ROLE) {
        baseTokenURI = _uri;
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
        return super.supportsInterface(_interfaceId);
    }

    function mintWithAuthorization(
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external whenNotPaused {
        uint256 tokenId = totalSupply() + 1;

        if (tokenId < 1 || tokenId > MAX_MINT_ID) {
            revert InvalidTokenId(tokenId);
        }

        MintStatus storage status = statuses[msg.sender];
        if (status.minted) {
            revert AddressAlreadyMinted(msg.sender);
        }

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

        status.authorized = true;
        _safeMint(msg.sender, tokenId);
        uint256 botId = assignBot(tokenId);
        emit Mint(msg.sender, tokenId, botId);
    }

    // TODO: add external method to decode tokenId => botId

    // TODO: Generate this on-chain?
    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        uint256 botId = tokenIdToBotId[_tokenId];
        if (botId == 0) {
            revert MissingBotAssignment(_tokenId);
        }

        return string.concat(baseTokenURI, Strings.toString(botId));
    }

    function getBotData(uint256 _tokenId) public view returns (uint256, string memory) {
        if (!_exists(_tokenId)) {
            revert InvalidTokenId(_tokenId);
        }

        uint256 botId = tokenIdToBotId[_tokenId];
        if (botId == 0) {
            revert MissingBotAssignment(_tokenId);
        }

        return (botId, deserializer.deserialize(dataContracts, botId));
    }

    function assignBot(uint256 _tokenId) private returns (uint256) {
        uint256 max = MAX_MINT_ID - totalSupply();
        if (max < 1 || max > MAX_MINT_ID) {
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
        //   * If randomBotIdHelper[max] has a value, set it to 0 after potentially copying it to the new location.  Not required but nice to gas and the blockchain - after all bots are minted, randomBotIdHelper will be empty
        uint256 botId = randomBotIdHelper[random] != 0 ? randomBotIdHelper[random] : random;
        if (random != max) {
            randomBotIdHelper[random] = randomBotIdHelper[max] != 0 ? randomBotIdHelper[max] : max;
        }
        if (randomBotIdHelper[max] != 0) {
            randomBotIdHelper[max] = 0;
        }

        if (botId < 1 || botId > MAX_MINT_ID) {
            revert InvalidBotId(botId);
        }

        if (botIdToTokenId[botId] != 0) {
            revert BrokenBotAssignment(botId, _tokenId, botIdToTokenId[botId]);
        }

        botIdToTokenId[botId] = _tokenId;
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
        uint256 tokenId
    ) internal virtual override whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            if (msg.sender != to) {
                revert InvalidMintAddress(msg.sender, to);
            }

            MintStatus storage status = statuses[to];
            if (!status.authorized) {
                revert AddressNotAuthorized(to);
            }
            if (status.minted) {
                revert AddressAlreadyMinted(to);
            }
            status.minted = true;
        }

        if (to == address(0)) {
            if (msg.sender != from) {
                revert InvalidBurnAddress(msg.sender, from);
            }
        }
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }
}