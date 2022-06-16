// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/interfaces/IERC2981.sol';
import '@openzeppelin/contracts/interfaces/IERC20.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import './lz/lz-app/non-blocking-lz-app.sol';
import './lz/interfaces/IONFT721.sol';

import {IOmegaMetadata} from './interfaces/IOmegaMetadata.sol';

/*
                        ██▜█▟███████████████▜▛▙▛▛▛▟▜▟▞▛▛▛▛█▞▙▙█▜▜▜▙███████
                        ████████▜█▛█▙██▟█▟█▟▜▝▖▞▖▌▞▄▗▐▗▚▐▗▖▞▖▖▖▘▚▜▛██▜█▛██
                        █▛████▜▟████████▛█▟▜▗▚▛▙▛▛▙▜▜▚▛▙▛▙▜▜▟▜▚▚▜▜████████
                        ████▙████████▛▙██▜▞▚▐▚▛▟▝▀▞▀▞▀▞▚▀▞▜▚▙▀▖▟▜█▙███████
                        ███████████▜▟███▟▜▝▞▟▜▞▖▌▙▐▐▗▚▞▄▝▗▛▙▀▞▟▜█▙██▙█▙███
                        ██▟█▜█████▜████▟▜▘▚▛▙▛▖▄▝▖▞▖▚▖▄▗▚▛▟▚▚▟▟▛▙█████████
                        ██████▛██▟███▙█▞▚▐▜▟▙▜▜▟▛█▟▜▙▜▟▚▛▟▚▘▟▟▙████▛███▜▙█
                        █▙██████████▙█▟▝▄▜▙▙▜▜▛▙█▙▛▙▜▙▜▜▜▚▚▟▙█▟███████▟███
                        ████▜███▜█▜▟▙▙▘▞▟▙▚▌▚▘▜▜▟▙█▜▚▝▝▝▝▖▟▟▟▛███▜▟███████
                        ██▜███▟█████▟▝▐▟▚▙▀▖▙▜▗▜▟▟▙▛▙▝▜▜▛▛▙█▜███▟████▟████
                        ████████▛▙█▟▝▐▚▛▙▌▚▟▟▜▖▚▙▙▙█▟▐▐▜▟█████████████████
                        █▛██▛█▛▙██▙▘▞▙▜▞▌▞▟▟▟▜▟▗▚▙▚▙▚▙▗▜▙█▙██▛▙█████▜█▛▙██
                        █████████▙▚▘▞▗▘▚▘▟▟▟▙█▙▌▖▞▝▖▚▗▘▟▟▙██▙█████▜███████
                        ███▛█████▟█▜▟▛█▙█▛█▙█▙▛█▜▟▛█▜▙█▙██████████████████

*/

/**
 * @notice Contract for Omega runner NFT drop
 */
contract Omega is Ownable, ERC721, IONFT721, IERC2981, NonblockingLzApp {
    /* -------------------------------------------------------------------------- */
    /*                                   Config                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Mint price in ether (default 0.0001) (TEMP price)
     */
    uint256 public constant MINT_PRICE = 0.0001 ether;

    /**
     * @notice Constant for max mints per wallet
     */
    uint256 public constant MAX_MINTS_PER_WALLET = 4;

    /**
     * @notice Max supply of tokens
     */
    uint256 public immutable maxSupply;

    /**
     * @notice Amount of tokens which will be minted when devMint function is
     * called
     */
    uint256 public immutable amountForDevelopers;

    /**
     * @notice NFT royalties (ERC2981)
     * 10% = 1000 bps
     * (royaltyBps * _salePrice) / 10000
     */
    uint256 public royaltyBps;

    /**
     * @notice current token id - this ID will be used for next minted token
     */
    uint256 public currentTokenId = 1;

    /**
     * @notice Royalty fee receiver address
     * this address will received royalty fee from second market sales
     */
    address public royaltyReceiver;

    /**
     * @notice Omega metadata contract address (used for updating rendering metadata)
     */
    address public omegaMetadataAddress;

    /**
     * @notice mapping of tokenId -> bytes
     * this array contains metadata for tokens in bytes encoded format
     * indexed by tokenId
     */
    mapping(uint256 => bytes) public metadata;

    /**
     * @notice mapping between owner address -> number of tokens minted per phase
     * example : 0x123 -> 2 = address 0x123 - minted two times
     */
    mapping(address => uint256) public accountMintedStats;

    /**
     * @notice Merkle root tree hash used for priority mint
     */
    bytes32 public priorityListMerkleTree;

    /**
     * @notice Merkle root hash used for allowlist mint
     */
    bytes32 public allowListMerkleTree;

    /**
     * @notice flag if dev mint already happened
     */
    bool public devTokensMint;

    /**
     * @notice flag if layer zero integration is enabled
     */
    bool public isLayerZeroEnabled;

    /**
     * @notice Is public sale opened - flag true / false
     */
    bool public isPublicSaleOpen;

    /**
     * @notice Is priority mint opened - flag true / false
     */
    bool public isPriorityMintOpen;

    /**
     * @notice Is allow list mint opened - flag true / false
     */
    bool public isAllowlistMintOpen;

    /* -------------------------------------------------------------------------- */
    /*                                   EVENTS                                   */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Emitted when royalty BPS is updated
     */
    event RoyaltyBpsUpdated(uint256 royaltyBps);

    /**
     * @notice Emitted when mint phases state is updated
     */
    event MintPhasesStateUpdated(
        bool isPriorityMintOpen,
        bool isAllowlistMintOpen,
        bool isPublicSaleOpen
    );

    /**
     * @notice Emitted when new merkle root is updated
     */
    event MerkleRootUpdated(
        bytes32 newPriorityListMerkleTree,
        bytes32 newAllowListMerkleTree
    );

    /**
     * @notice Emitted when royalty receiver is updated
     */
    event RoyaltyReceiverUpdated(address newRoyaltyReceiver);

    /**
     * @notice Emitted when omega metadata address is updated
     */
    event OmegaMetadataAddressUpdated(address newOmegaMetadataAddress);

    /**
     * @notice Emitted when Layer Zero integration settings is updated
     */
    event LayerZeroIntegrationUpdated(bool isLayerZeroEnabled);

    /**
     * @notice Emitted when dev tokens are minted
     */
    event DevTokensMinted();

    /* ---------------------------------------------------------------------------- */
    /*                                   ERRORS                                     */
    /* ---------------------------------------------------------------------------- */

    /**
     * @notice Thrown if user is trying mint more token than allowed
     */
    error MaxNumberOfMintsExceeded();

    /**
     * @notice Thrown if combination of user address / number of tokens is not in merkle tree root
     */
    error NotInWhitelist();

    /**
     * @notice Thrown if address is 0x
     */
    error AddressCannotBe0();

    /**
     * @notice Thrown if token is not found
     */
    error TokenNotFound();

    /**
     * @notice Thrown if wrong amount is sent
     */
    error WrongAmount();

    /**
     * @notice Thrown if max supply of tokens reached
     */
    error MaxSupplyReached();

    /**
     * @notice Transfer failed
     */
    error TransferFailed();

    /**
     * @notice Priority mint is not open yet
     */
    error PriorityListNotOpen();

    /**
     * @notice Allow mint is not open yet
     */
    error AllowListNotOpen();

    /**
     * @notice Public sale is not open yet
     */
    error PublicMintNotOpen();

    /**
     * @notice Dev tokens already minted
     */
    error DevTokensAlreadyMinted();

    /**
     * @notice Thrown if Layer zero function is called but Layer Zero integration
     * is not enabled
     */
    error LayerZeroIsNotEnabled();

    /* -------------------------------------------------------------------------- */
    /*                                   MODIFIERS                                */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev check if Layer zero integration is enabled
     */
    modifier enabledLayerZero() {
        if (!isLayerZeroEnabled) revert LayerZeroIsNotEnabled();
        _;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   CONSTRUCTOR                              */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev Initializes the Omega contract by
     * @param initialMaxSupply - Max supply of tokens
     * @param initialName - Initial name of the token
     * @param initialSymbol - Initial symbol of the token
     * @param initialRoyaltyBps - Initial royalty BPS of the token
     * @param initialRoyaltyReceiverAddress - Initial royalty receiver address of the token
     * @param initialPriorityMerkleRoot - Initial merkle root of the token
     * @param initialAllowlistMerkleRoot - Initial allowlist merkle root of the token
     * @param initialAmountForDevelopers - Initial reserved supply of tokens
     * @param initialOmegaMetadataAddress - Initial omega metadata contract address
     * @param lzEndpointAddress - LZ endpoint address
     */
    constructor(
        uint256 initialMaxSupply,
        string memory initialName,
        string memory initialSymbol,
        uint256 initialRoyaltyBps,
        address initialRoyaltyReceiverAddress,
        bytes32 initialPriorityMerkleRoot,
        bytes32 initialAllowlistMerkleRoot,
        uint256 initialAmountForDevelopers,
        address initialOmegaMetadataAddress,
        address lzEndpointAddress
    ) ERC721(initialName, initialSymbol) NonblockingLzApp(lzEndpointAddress) {
        if (initialRoyaltyReceiverAddress == address(0))
            revert AddressCannotBe0();

        if (initialOmegaMetadataAddress == address(0))
            revert AddressCannotBe0();

        maxSupply = initialMaxSupply;
        royaltyBps = initialRoyaltyBps;
        royaltyReceiver = initialRoyaltyReceiverAddress;
        priorityListMerkleTree = initialPriorityMerkleRoot;
        allowListMerkleTree = initialAllowlistMerkleRoot;
        amountForDevelopers = initialAmountForDevelopers;
        omegaMetadataAddress = initialOmegaMetadataAddress;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Private functions                        */
    /* -------------------------------------------------------------------------- */

    /**
     * @dev function will mint new token to caller and increment currentTokenId
     * @param amount - amount of tokens to mint
     */
    function mintTokens(uint256 amount) private {
        uint256 tokenId = currentTokenId;

        for (uint256 i = 0; i < amount; i++) {
            _safeMint(msg.sender, tokenId);

            unchecked {
                tokenId += 1;
            }
        }

        currentTokenId = tokenId;
    }

    /**
     * @dev Check generic mint requirements
     * @param amount - amount of tokens to mint
     */
    function checkMintRequirements(uint256 amount) private {
        if (msg.value != (MINT_PRICE * amount) || amount == 0)
            revert WrongAmount();

        if (((currentTokenId - 1) + amount) > maxSupply)
            revert MaxSupplyReached();
    }

    /**
     * @notice Check whitelist requirements
     * generic requirements for priority and whitelist sale
     * @param merkleRoot - merkle tree root
     * @param merkleProof - merkle tree proof
     * @param amount - amount of tokens to mint
     */
    function checkWhitelistRequirements(
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof,
        uint256 amount
    ) private view {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));

        bool isValidLeaf = MerkleProof.verify(merkleProof, merkleRoot, leaf);

        if (!isValidLeaf) revert NotInWhitelist();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   External functions                       */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Interface for the NFT Royalty Standard.
     *
     * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
     * support for royalty payments across all NFT marketplaces and ecosystem participants.
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     *
     * @param salePrice Sale price of the token
     * @return receiver receiver address for royalty fee
     * @return royaltyAmount Royalty amount
     */
    function royaltyInfo(uint256, uint256 salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        receiver = royaltyReceiver;
        royaltyAmount = (salePrice * royaltyBps) / 10_000;
    }

    /**
     * @notice Set new royalty bps settings
     * @param newRoyaltyBps New BPS settings (10% = 1000 bps)
     */
    function setRoyaltyBps(uint256 newRoyaltyBps) external onlyOwner {
        royaltyBps = newRoyaltyBps;

        emit RoyaltyBpsUpdated(newRoyaltyBps);
    }

    /**
     * @notice Set mint phases state
     * this function is used for opening & closing phases of omega mint
     * @param priorityListSaleIsOpen Priority list sale is opened
     * @param allowListSaleIsOpen Allow list sale is opened
     * @param publicSaleIsOpen Public sale is opened
     */
    function setMintPhasesState(
        bool priorityListSaleIsOpen,
        bool allowListSaleIsOpen,
        bool publicSaleIsOpen
    ) external onlyOwner {
        isPriorityMintOpen = priorityListSaleIsOpen;
        isAllowlistMintOpen = allowListSaleIsOpen;
        isPublicSaleOpen = publicSaleIsOpen;

        emit MintPhasesStateUpdated(
            priorityListSaleIsOpen,
            allowListSaleIsOpen,
            publicSaleIsOpen
        );
    }

    /**
     * @notice Set new merkle tree root for whitelisted mints
     * @param newPriorityListMerkleTree new priority list merkle tree root
     * @param newAllowListMerkleTree new allow list merkle tree root
     */
    function setWhitelistMerkleTree(
        bytes32 newPriorityListMerkleTree,
        bytes32 newAllowListMerkleTree
    ) external onlyOwner {
        priorityListMerkleTree = newPriorityListMerkleTree;
        allowListMerkleTree = newAllowListMerkleTree;

        emit MerkleRootUpdated(
            newPriorityListMerkleTree,
            newAllowListMerkleTree
        );
    }

    /**
     * @notice Set new royalty receiver address
     * @param newRoyaltyReceiver New royalty receiver address
     */
    function setRoyaltyReceiver(address newRoyaltyReceiver) external onlyOwner {
        if (newRoyaltyReceiver == address(0)) revert AddressCannotBe0();

        royaltyReceiver = newRoyaltyReceiver;

        emit RoyaltyReceiverUpdated(newRoyaltyReceiver);
    }

    /**
     * @notice Set new metadata address contract
     * @param newOmegaMetadataAddress New omega metadata address
     */
    function setOmegaMetadataAddress(address newOmegaMetadataAddress)
        external
        onlyOwner
    {
        if (newOmegaMetadataAddress == address(0)) revert AddressCannotBe0();

        omegaMetadataAddress = newOmegaMetadataAddress;

        emit OmegaMetadataAddressUpdated(newOmegaMetadataAddress);
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId ID of token
     * @return URI for token
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenNotFound();

        return
            IOmegaMetadata(omegaMetadataAddress).tokenURI(
                tokenId,
                metadata[tokenId]
            );
    }

    /**
     * @notice One time mint of reserved tokens for dev team
     * those tokens will be minted to the called address
     */
    function devMint() external onlyOwner {
        if (devTokensMint) revert DevTokensAlreadyMinted();

        uint256 tokenId = currentTokenId;

        if (((tokenId - 1) + 200) > maxSupply) revert MaxSupplyReached();

        devTokensMint = true;

        for (uint256 i = tokenId; i < (tokenId + 200); i++) {
            _safeMint(msg.sender, i);
        }

        unchecked {
            tokenId += 200;
        }

        currentTokenId = tokenId;

        emit DevTokensMinted();
    }

    /**
     * @notice Priority list mint - number of allowed mints are determined
     * by number of bought comics
     * @param merkleProof - merkle proof for priority allowlist
     * @param merkleProofAmount - amount of tokens from merkle proof mint
     * @param mintingAmount - number of tokens to mint
     */
    function priorityListPurchase(
        bytes32[] calldata merkleProof,
        uint256 merkleProofAmount,
        uint256 mintingAmount
    ) external payable {
        if (!isPriorityMintOpen) revert PriorityListNotOpen();

        checkMintRequirements(mintingAmount);

        checkWhitelistRequirements(
            priorityListMerkleTree,
            merkleProof,
            merkleProofAmount
        );

        unchecked {
            uint256 newAccountMintedStats = accountMintedStats[msg.sender] +
                mintingAmount;

            if (
                newAccountMintedStats > merkleProofAmount ||
                newAccountMintedStats > MAX_MINTS_PER_WALLET
            ) revert MaxNumberOfMintsExceeded();

            accountMintedStats[msg.sender] = newAccountMintedStats;
        }

        mintTokens(mintingAmount);
    }

    /**
     * @notice Main mint (purchase) function
     * each allow list spot is allowed to mint a 4 tokens
     * @param merkleProof - merkle proof for allowlist
     * @param amount - number of tokens to mint
     */
    function allowListPurchase(bytes32[] calldata merkleProof, uint256 amount)
        external
        payable
    {
        if (!isAllowlistMintOpen) revert AllowListNotOpen();

        checkMintRequirements(amount);

        // everyone on allow list is allowed to mint 4 tokens
        checkWhitelistRequirements(
            allowListMerkleTree,
            merkleProof,
            MAX_MINTS_PER_WALLET
        );

        unchecked {
            uint256 newAccountMintedStats = accountMintedStats[msg.sender] +
                amount;

            if (newAccountMintedStats > MAX_MINTS_PER_WALLET)
                revert MaxNumberOfMintsExceeded();

            accountMintedStats[msg.sender] = newAccountMintedStats;
        }

        mintTokens(amount);
    }

    /**
     * @notice Public mint (purchase) function
     * @param amount - number of tokens to mint
     */
    function publicPurchase(uint256 amount) external payable {
        checkMintRequirements(amount);

        if (!isPublicSaleOpen) revert PublicMintNotOpen();

        unchecked {
            uint256 newAccountMintedStats = accountMintedStats[msg.sender] +
                amount;

            if (newAccountMintedStats > MAX_MINTS_PER_WALLET)
                revert MaxNumberOfMintsExceeded();

            accountMintedStats[msg.sender] = newAccountMintedStats;
        }

        mintTokens(amount);
    }

    /**
     * @notice Withdraw all ETH to owner contract
     */
    function withdraw() external {
        // after slither releases update, rename detector to arbitrary-send-eth
        // slither-disable-next-line arbitrary-send
        payable(owner()).transfer(address(this).balance);
    }

    /**
     * @notice Withdraw all ETH to owner contract
     * @param erc20Token ERC20 token contract address
     */
    function withdrawAllERC20(IERC20 erc20Token) external {
        bool success = erc20Token.transfer(
            owner(),
            erc20Token.balanceOf(address(this))
        );

        if (!success) revert TransferFailed();
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Public functions                         */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Returns if contract supports interface
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, IERC165)
        returns (bool)
    {
        return
            super.supportsInterface(interfaceId) ||
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC2981).interfaceId;
    }

    /* -------------------------------------------------------------------------- */
    /*                                   Layer zero                               */
    /* -------------------------------------------------------------------------- */

    /**
     * @notice Enable / Disable Layer zero integration
     * @param isEnabled Enable / Disable Layer zero integration
     */
    function setLayerZeroIntegration(bool isEnabled) external onlyOwner {
        isLayerZeroEnabled = isEnabled;

        emit LayerZeroIntegrationUpdated(isEnabled);
    }

    /**
     * @notice Decode address from bytes
     * @param addressToDecode bytes encoded address
     */
    function decodeAddress(bytes memory addressToDecode)
        private
        pure
        returns (address)
    {
        address decodedAddress;

        /* solhint-disable no-inline-assembly */
        assembly {
            decodedAddress := mload(add(addressToDecode, 20))
        }
        /* solhint-enable no-inline-assembly */
        return decodedAddress;
    }

    /**
     * @notice estimate send token `tokenId` to (`dstChainId`, `toAddress`)
     * dstChainId - L0 defined chain id to send tokens too
     * toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * tokenId - token Id to transfer
     * useZro - indicates to use zro to pay L0 fees
     * adapterParams - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        bool useZro,
        bytes calldata adapterParams
    )
        external
        view
        override
        enabledLayerZero
        returns (uint256 nativeFee, uint256 zroFee)
    {
        bytes memory payload = IOmegaMetadata(omegaMetadataAddress).getPayload(
            decodeAddress(toAddress),
            tokenId,
            metadata[tokenId]
        );

        return
            lzEndpoint.estimateFees(
                dstChainId,
                address(this),
                payload,
                useZro,
                adapterParams
            );
    }

    /**
     * @notice send token `tokenId` to (`dstChainId`, `toAddress`) from `from`
     * `toAddress` can be any size depending on the `dstChainId`.
     * `zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address from,
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable override enabledLayerZero {
        _send(
            from,
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    /**
     * @notice send token `tokenId` to (`dstChainId`, `toAddress`)
     * `toAddress` can be any size depending on the `dstChainId`.
     * `zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function send(
        uint16 dstChainId,
        bytes calldata toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable override enabledLayerZero {
        _send(
            _msgSender(),
            dstChainId,
            toAddress,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    /**
     * @notice send token `tokenId` to (`dstChainId`, `toAddress`) from `from`
     * `toAddress` can be any size depending on the `dstChainId`.
     * `zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function _send(
        address from,
        uint16 dstChainId,
        bytes memory toAddress,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) internal enabledLayerZero {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            'caller is not owner nor approved'
        );
        require(ERC721.ownerOf(tokenId) == from, 'send from incorrect owner');
        _beforeSend(from, dstChainId, toAddress, tokenId);

        bytes memory payload = IOmegaMetadata(omegaMetadataAddress).getPayload(
            decodeAddress(toAddress),
            tokenId,
            metadata[tokenId]
        );

        _lzSend(
            dstChainId,
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );

        uint64 nonce = lzEndpoint.getOutboundNonce(dstChainId, address(this));
        emit SendToChain(from, dstChainId, toAddress, tokenId, nonce);
    }

    function _nonblockingLzReceive(
        uint16 srcChainId,
        bytes memory, /* srcAddress */
        uint64 nonce,
        bytes memory payload
    ) internal virtual override enabledLayerZero {
        (
            address toAddress,
            uint256 tokenId,
            bytes memory parsedMetadata
        ) = IOmegaMetadata(omegaMetadataAddress).parsePayload(payload);

        metadata[tokenId] = parsedMetadata;

        _afterReceive(srcChainId, toAddress, tokenId);

        emit ReceiveFromChain(srcChainId, toAddress, tokenId, nonce);
    }

    function _beforeSend(
        address, /* from */
        uint16, /* dstChainId */
        bytes memory, /* toAddress */
        uint256 tokenId
    ) internal virtual enabledLayerZero {
        _burn(tokenId);
    }

    function _afterReceive(
        uint16, /* srcChainId */
        address toAddress,
        uint256 tokenId
    ) internal virtual enabledLayerZero {
        _safeMint(toAddress, tokenId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

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
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
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
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
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
        address owner = ERC721.ownerOf(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

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
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
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
        require(owner != operator, "ERC721: approve to caller");
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
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
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
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be payed in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = _efficientHash(computedHash, proofElement);
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = _efficientHash(proofElement, computedHash);
            }
        }
        return computedHash;
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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

pragma solidity 0.8.9;

import './lz-app.sol';

/*
 * the default LayerZero messaging behaviour is blocking, i.e. any failed message will block the channel
 * this abstract class try-catch all fail messages and store locally for future retry. hence, non-blocking
 * NOTE: if the srcAddress is not configured properly, it will still block the message pathway from (srcChainId, srcAddress)
 */
abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes32)))
        public failedMessages;

    event MessageFailed(
        uint16 _srcChainId,
        bytes _srcAddress,
        uint64 _nonce,
        bytes _payload
    );

    // overriding the virtual function in LzReceiver
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual override {
        // try-catch all errors/exceptions
        try
            this.nonblockingLzReceive(
                _srcChainId,
                _srcAddress,
                _nonce,
                _payload
            )
        {
            // do nothing
        } catch {
            // error / exception
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(
                _payload
            );
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) public virtual {
        // only internal transaction
        require(
            _msgSender() == address(this),
            'LzReceiver: caller must be LzApp'
        );
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    //@notice override this function
    function _nonblockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function retryMessage(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external payable virtual {
        // assert there is message to retry
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0), 'LzReceiver: no stored message');
        require(
            keccak256(_payload) == payloadHash,
            'LzReceiver: invalid payload'
        );
        // clear the stored message
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        // execute the message. revert if it fails again
        this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';

/**
 * @dev Interface of the ONFT standard
 */
interface IONFT721 is IERC721 {
    /**
     * @dev estimate send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * _dstChainId - L0 defined chain id to send tokens too
     * _toAddress - dynamic bytes array which contains the address to whom you are sending tokens to on the dstChain
     * _tokenId - token Id to transfer
     * _useZro - indicates to use zro to pay L0 fees
     * _adapterParams - flexible bytes array to indicate messaging adapter services in L0
     */
    function estimateSendFee(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        bool _useZro,
        bytes calldata _adapterParams
    ) external returns (uint256 nativeFee, uint256 zroFee);

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`)
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function send(
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev send token `_tokenId` to (`_dstChainId`, `_toAddress`) from `_from`
     * `_toAddress` can be any size depending on the `dstChainId`.
     * `_zroPaymentAddress` set to address(0x0) if not paying in ZRO (LayerZero Token)
     * `_adapterParams` is a flexible bytes array to indicate messaging adapter services
     */
    function sendFrom(
        address _from,
        uint16 _dstChainId,
        bytes calldata _toAddress,
        uint256 _tokenId,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    /**
     * @dev Emitted when `_tokenId` are moved from the `_sender` to (`_dstChainId`, `_toAddress`)
     * `_nonce` is the outbound nonce from
     */
    event SendToChain(
        address indexed _sender,
        uint16 indexed _dstChainId,
        bytes indexed _toAddress,
        uint256 _tokenId,
        uint64 _nonce
    );

    /**
     * @dev Emitted when `_tokenId` are sent from `_srcChainId` to the `_toAddress` at this chain. `_nonce` is the inbound nonce.
     */
    event ReceiveFromChain(
        uint16 _srcChainId,
        address _toAddress,
        uint256 _tokenId,
        uint64 _nonce
    );
}

// SPDX-License-Identifier: Unlicensed

pragma solidity 0.8.9;

/**
 * @notice Interface of Omega metadata contract
 * this contract is used for managing and updating logic of rendering
 * metadata for the omega NFT tokens
 */
interface IOmegaMetadata {
    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     * @param tokenId ID of token
     * @param metadata encoded metadata for token
     * @return URI for token
     */
    function tokenURI(uint256 tokenId, bytes memory metadata)
        external
        view
        returns (string memory);

    /**
     * @notice Returns payload for token id with metadata
     * metadata are used for storing and updating information about token while
     * token is moved thru chains or modified on chain
     * @param toAddress address of token receiver
     * @param tokenId ID of token
     * @param metadata encoded metadata for token
     * @return encoded payload for token & metadata
     */
    function getPayload(
        address toAddress,
        uint256 tokenId,
        bytes memory metadata
    ) external pure returns (bytes memory);

    /**
     * @notice Decode payload for token with metadata
     * @param payload encoded payload for token & metadata
     * @return toAddress decoded address of token receiver
     * @return tokenId decoded ID of token
     * @return metadata decoded metadata for token
     */
    function parsePayload(bytes memory payload)
        external
        pure
        returns (
            address toAddress,
            uint256 tokenId,
            bytes memory metadata
        );
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

pragma solidity 0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import '../interfaces/ILayer-zero-receiver.sol';
import '../interfaces/ILayer-zero-user-application-config.sol';
import '../interfaces/ILayer-zero-endpoint.sol';

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is
    Ownable,
    ILayerZeroReceiver,
    ILayerZeroUserApplicationConfig
{
    ILayerZeroEndpoint internal immutable lzEndpoint;

    mapping(uint16 => bytes) internal trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) external override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint));
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(
            _srcAddress.length == trustedRemoteLookup[_srcChainId].length &&
                keccak256(_srcAddress) ==
                keccak256(trustedRemoteLookup[_srcChainId]),
            'LzReceiver: invalid source sending contract'
        );

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(
        uint16 _srcChainId,
        bytes memory _srcAddress,
        uint64 _nonce,
        bytes memory _payload
    ) internal virtual;

    function _lzSend(
        uint16 _dstChainId,
        bytes memory _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes memory _adapterParam
    ) internal {
        require(
            trustedRemoteLookup[_dstChainId].length != 0,
            'LzSend: destination chain is not a trusted source.'
        );
        lzEndpoint.send{value: msg.value}(
            _dstChainId,
            trustedRemoteLookup[_dstChainId],
            _payload,
            _refundAddress,
            _zroPaymentAddress,
            _adapterParam
        );
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(
        uint16,
        uint16 _chainId,
        address,
        uint256 _configType
    ) external view returns (bytes memory) {
        return
            lzEndpoint.getConfig(
                lzEndpoint.getSendVersion(address(this)),
                _chainId,
                address(this),
                _configType
            );
    }

    // generic config for LayerZero user Application
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        override
        onlyOwner
    {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        onlyOwner
    {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool)
    {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    // interacting with the LayerZero Endpoint and remote contracts

    function getTrustedRemote(uint16 _chainId)
        external
        view
        returns (bytes memory)
    {
        return trustedRemoteLookup[_chainId];
    }

    function getLzEndpoint() external view returns (address) {
        return address(lzEndpoint);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        uint64 _nonce,
        bytes calldata _payload
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import './ILayer-zero-user-application-config.sol';

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a lzApp from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}