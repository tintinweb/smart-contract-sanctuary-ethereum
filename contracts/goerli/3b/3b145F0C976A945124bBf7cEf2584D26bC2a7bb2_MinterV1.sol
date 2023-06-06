// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import "./interfaces/IPRTCLCollections721V1.sol";

/// @title Minter contract version 1
/// @author Particle Collection - valdi.eth
/// @notice Mint tokens for any collection in the core ERC721 contract
/// @dev Based on Artblock's Minter suite of contracts: https://github.com/ArtBlocks/artblocks-contracts/tree/main/contracts/minter-suite/Minters
/// Modifications to the original design:
/// - Max mints per wallet functionality
/// - Added pre sale and live sale minting phases
/// - Modified allowed currencies design
/// @dev The MinterV1 contract contains the following privileged access for the following functions:
/// - The owner can update pricePerToken using updatePricePerToken().
/// - The owner can update the maximum mint per wallet using updateMaxMints().
/// - The owner can update the minting phase using holderPreMintDone().
/// - The owner can update the payment currency of collection using updateCollectionCurrencyInfo().
/// - The owner can add or remove holders of collections using setAllowedHoldersofCollections().
/// - The owner can add or remove holders of external tokens using setAllowedExternalHolders().
/// - The owner can update update the whitelist signer through setSigner().
/// @custom:security-contact [email protected]
contract MinterV1 is Ownable, ReentrancyGuard {
    using ECDSA for bytes32;
    using SafeERC20 for IERC20;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    /**
     * @notice Price per token updated for collection `_collectionId` to
     * `_pricePerToken`.
     */
    event PricePerTokenUpdated(
        uint256 indexed _collectionId,
        uint256 indexed _pricePerToken
    );

    /**
     * @notice Max mints per wallet for collection `_collectionId` 
     * updated to `_maxMints`.
     */
    event MaxMintsUpdated(
        uint256 indexed _collectionId,
        uint24 indexed _maxMints
    );

    /**
     * @notice Currency updated for collection `_collectionId` to symbol
     * `_currencySymbol` and address `_currencyAddress`.
     */
    event CollectionCurrencyInfoUpdated(
        uint256 indexed _collectionId,
        address indexed _currencyAddress,
        string _currencySymbol
    );

    /**
     * @notice Allow holders of NFTs at addresses `collCoreContract`, collection
     * IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     */
    event AllowedHoldersOfCollections(
        uint256 indexed _collectionId,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Allow holders of NFTs at addresses `_tokenAddresses to mint on collection `_collectionId`.
     */
    event AllowedExternalHolders721(
        uint256 indexed _collectionId,
        address[] _tokenAddresses
    );

    /**
     * @notice Removed holders of NFTs at collection IDs `_ownedNFTCollectionIds` 
     * from allowlist to mint on collection `_collectionId`.
     */
    event RemovedHoldersOfCollections(
        uint256 indexed _collectionId,
        uint256[] _ownedNFTCollectionIds
    );

    /**
     * @notice Allow holders of NFTs at addresses `_tokenAddresses to mint on collection `_collectionId`.
     */
    event AllowedExternalHolders1155(
        uint256 indexed _collectionId,
        address[] _tokenAddresses,
        uint256[][] _tokenIds
    );

    /**
     * @notice Removed holders of NFTs at addresses `_tokenAddresses`,from allowlist to mint on collection `_collectionId`.
     */
    event RemovedExternalHolders721(
        uint256 indexed _collectionId,
        address[] _tokenAddresses
    );

    /**
     * @notice Removed holders of NFTs at addresses `_tokenAddresses`,from allowlist to mint on collection `_collectionId`.
     */
    event RemovedExternalHolders1155(
        uint256 indexed _collectionId,
        address[] _tokenAddresses,
        uint256[][] _tokenIds
    );

    /**
     * @notice Pre mint done status updated to true for
     * collection `_collectionId`.
     */
    event HolderPreMintDone(uint256 indexed _collectionId);

    /**
     * @dev Emitted when the signer address is updated.
     */
    event SignerUpdated(address signer);

    /// This contract handles cores with interface IPRTCLCollections721V1
    IPRTCLCollections721V1 public immutable collCoreContract;

    /// Collection configuration
    struct CollectionConfig {
        address currencyAddress;
        uint256 pricePerToken;
        string currencySymbol;
        uint24 maxMintsPerWallet;
        bool hasMaxPerWallet;
        bool holderPreMintDone;
    }

    mapping(uint256 => CollectionConfig) public collectionConfigs;

    // Number of tokens minted by a given wallet in a collection
    // CollectionId => wallet address => number of minted tokens
    mapping(uint256 => mapping(address => uint256)) public walletMintedPerCollection;

    /// @notice Used to validate whitelist addresses
    address public whitelistSigner;

    /**
     * collectionId => allowedCollectionIds
     * collections whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.UintSet) private allowedCollectionIds;

    /**
     * collectionId => address set
     * token addresses whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.AddressSet) private allowedExternalHolders721;

    /**
     * collectionId => address set
     * token addresses whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => EnumerableSet.AddressSet) private allowedExternalHolders1155;

    /**
     * collectionId => address => token id set
     * token ids in a ERC1155 token address, whose holders are allowed to purchase a token on `collectionId`
     */
    mapping(uint256 => mapping (address => EnumerableSet.UintSet)) private allowedTokenIds1155;

    modifier onlyValidCollectionId(uint256 _collectionId) {
        require(
            collCoreContract.collectionExists(_collectionId),
            "Collection ID does not exist"
        );
        _;
    }

    modifier onlyNonZeroAddress(address _address) {
        require(_address != address(0), "Must input non-zero address");
        _;
    }

    modifier onlyERC20Collection(uint256 _collectionId) {
        require(collectionConfigs[_collectionId].currencyAddress != address(0), "Collection uses ETH");
        _;
    }

    /**
     * @notice Initializes contract to be a Minter
     * integrated with Particle's core contract at 
     * address `_collCore721Address`.
     * @param _collCore721Address Particle's core contract for which this
     * contract will be a minter.
     */
    constructor(address _collCore721Address, address _signer)
        onlyNonZeroAddress(_collCore721Address)
        onlyNonZeroAddress(_signer)
        ReentrancyGuard()
    {
        collCoreContract = IPRTCLCollections721V1(_collCore721Address);
        whitelistSigner = _signer;
    }

    /**
     * @notice Gets the _address's balance of the ERC-20 token currently set
     * as the payment currency for collection `_collectionId`.
     * @param _address Address to be queried.
     * @param _collectionId Collection ID to be queried.
     * @return balance Balance of ERC-20
     */
    function balanceOfCollectionERC20(address _address, uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        onlyERC20Collection(_collectionId)
        returns (uint256 balance)
    {
        balance = IERC20(collectionConfigs[_collectionId].currencyAddress).balanceOf(
            _address
        );
    }

    /**
     * @notice Gets the _address's allowance for this minter of the ERC-20
     * token currently set as the payment currency for collection
     * `_collectionId`.
     * @param _address Address to be queried.
     * @param _collectionId Collection ID to be queried.
     * @return remaining Remaining allowance of ERC-20
     */
    function allowanceOfCollectionERC20(address _address, uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        onlyERC20Collection(_collectionId)
        returns (uint256 remaining)
    {
        remaining = IERC20(collectionConfigs[_collectionId].currencyAddress).allowance(
            _address,
            address(this)
        );
    }

    /**
     * @notice Updates this minter's price per token of collection `_collectionId`
     * to be '_pricePerToken`.
     */
    function updatePricePerToken(
        uint256 _collectionId,
        uint256 _pricePerToken
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        require(_pricePerToken > 0, "Price must be > 0");
        collectionConfigs[_collectionId].pricePerToken = _pricePerToken;
        emit PricePerTokenUpdated(_collectionId, _pricePerToken);
    }

    /**
     * @notice Updates this minter's max mints per wallet 
     * of collection `_collectionId` to be '_maxMints`
     */
    function updateMaxMints(
        uint256 _collectionId,
        uint24 _maxMints
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        // 0 max mints == no limit
        // (max token ids enforced by core contract)
        (,uint256 maxParticles,,,,,) = collCoreContract.collectionData(_collectionId);
        require(_maxMints < maxParticles, "Max mints must be < max particles for collection");
        collectionConfigs[_collectionId].maxMintsPerWallet = _maxMints;
        collectionConfigs[_collectionId].hasMaxPerWallet = true;
        emit MaxMintsUpdated(_collectionId, _maxMints);
    }

    /**
     * @notice Updates this minter's minting phase 
     * of collection `_collectionId` to be past pre mint
     */
    function holderPreMintDone(
        uint256 _collectionId
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        collectionConfigs[_collectionId].holderPreMintDone = true;
        emit HolderPreMintDone(_collectionId);
    }

    /**
     * @notice Updates payment currency of collection `_collectionId` to be
     * `_currencySymbol` at address `_currencyAddress`.
     * @param _collectionId Collection ID to update.
     * @param _currencySymbol Currency symbol.
     * @param _currencyAddress Currency address.
     */
    function updateCollectionCurrencyInfo(
        uint256 _collectionId,
        string memory _currencySymbol,
        address _currencyAddress
    ) external onlyValidCollectionId(_collectionId) onlyOwner {
        require(bytes(_currencySymbol).length != 0, "Symbol must be non-empty");

        // require null address if symbol is "ETH"
        require(
            (keccak256(abi.encodePacked(_currencySymbol)) ==
                keccak256(abi.encodePacked("ETH"))) ==
                (_currencyAddress == address(0)),
            "ETH is only null address"
        );
        collectionConfigs[_collectionId].currencySymbol = _currencySymbol;
        collectionConfigs[_collectionId].currencyAddress = _currencyAddress;
        emit CollectionCurrencyInfoUpdated(
            _collectionId,
            _currencyAddress,
            _currencySymbol
        );
    }

    /**
     * @dev Update signer address.
     * Can only be called by owner.
     */
    function setSigner(address _signer) external onlyNonZeroAddress(_signer) onlyOwner {
        whitelistSigner = _signer;
        emit SignerUpdated(_signer);
    }

    /**
     * @notice Verify signature
     */
    function verifyAddressSigner(bytes memory _signature, uint256 _collectionId, address _address, uint256 _expirationBlock) public 
    view returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(_collectionId, _address, _expirationBlock));
        return block.number < _expirationBlock && whitelistSigner == messageHash.toEthSignedMessageHash().recover(_signature);
    }

    /**
     * @notice Allows holders of NFTs from
     * collection IDs `_ownedNFTCollectionIds` to mint on collection `_collectionId`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _ownedNFTCollectionIds Collection IDs on `collCoreContract`
     * whose holders shall be allowlisted to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of `_ownedNFTCollectionIds`
     */
    function setAllowedHoldersOfCollections(
        uint256 _collectionId,
        uint256[] memory _ownedNFTCollectionIds,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_ownedNFTCollectionIds.length > 0, "Must send at least one collection ID");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 ownedIdsLength = _ownedNFTCollectionIds.length;
        // for each approved collection
        for (uint256 i = 0; i < ownedIdsLength;) {
            uint256 toAllowCollectionId = _ownedNFTCollectionIds[i];

            require(
                collCoreContract.collectionExists(toAllowCollectionId),
                "Collection ID does not exist"
            );

            if (_isAllowed) {
                // add to allowed collection holders
                allowedCollectionIds[_collectionId].add(toAllowCollectionId);
            } else {
                // remove from allowed collection holders
                allowedCollectionIds[_collectionId].remove(toAllowCollectionId);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedHoldersOfCollections(
                _collectionId,
                _ownedNFTCollectionIds
            );
        } else {
            // emit disapprove event
            emit RemovedHoldersOfCollections(
                _collectionId,
                _ownedNFTCollectionIds
            );
        }
    }

    /**
     * @notice Allows or disallows holders of NFTs from
     * `_tokenAddresses` to mint on collection `_collectionId`,
     * depending on `_isAllowed`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _tokenAddresses Tokens whose holders shall be allowlisted 
     * to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of tokens `_tokenAddresses`
     */
    function setAllowedExternalHolders721(
        uint256 _collectionId,
        address[] memory _tokenAddresses,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_tokenAddresses.length > 0, "Must send at least one token address");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 tokenAddressesLength = _tokenAddresses.length;

        // for each approved token
        for (uint256 i = 0; i < tokenAddressesLength;) {
            address tokenAddress = _tokenAddresses[i];

            require(tokenAddress != address(0), "Must input non-zero address");
            require(IERC721(tokenAddress).supportsInterface(type(IERC721).interfaceId), "Address is not ERC721");


            if (_isAllowed) {
                // add to allowed token holders
                allowedExternalHolders721[_collectionId].add(tokenAddress);
            } else {
                // remove from allowed token holders
                allowedExternalHolders721[_collectionId].remove(tokenAddress);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedExternalHolders721(
                _collectionId,
                _tokenAddresses
            );
        } else {
            // emit disapprove event
            emit RemovedExternalHolders721(
                _collectionId,
                _tokenAddresses
            );
        }
    }

    /**
     * @notice Allows or disallows holders of NFTs from
     * `_tokenAddresses` and `_tokenIds` to mint on collection `_collectionId`,
     * depending on `_isAllowed`.
     * @param _collectionId Collection ID to enable minting on.
     * @param _tokenAddresses Tokens whose holders shall be allowlisted 
     * to mint collection `_collectionId`.
     * @param _tokenIds Tokens ids whose holders shall be allowlisted
     * to mint collection `_collectionId`.
     * @param _isAllowed Whether to allow or disallow holders of tokens `_tokenAddresses`
     */
    function setAllowedExternalHolders1155(
        uint256 _collectionId,
        address[] memory _tokenAddresses,
        uint256[][] memory _tokenIds,
        bool _isAllowed
    ) public onlyValidCollectionId(_collectionId) onlyOwner {
        require(_tokenAddresses.length > 0, "Must send at least one token address");
        require(_tokenAddresses.length == _tokenIds.length, "Must send same amount of token addresses and token ids arrays");
        require(!collectionConfigs[_collectionId].holderPreMintDone, "Pre mint done");

        uint256 tokenAddressesLength = _tokenAddresses.length;

        // for each approved token
        for (uint256 i = 0; i < tokenAddressesLength;) {
            address tokenAddress = _tokenAddresses[i];

            require(tokenAddress != address(0), "Must input non-zero address");
            require(IERC1155(tokenAddress).supportsInterface(type(IERC1155).interfaceId), "Address is not ERC1155");
            
            uint256 tokenIdsLength = _tokenIds[i].length;
            require(tokenIdsLength > 0, "Must send at least one token id");

            for (uint256 j = 0; j < tokenIdsLength;) {
                uint256 tokenId = _tokenIds[i][j];
                if (_isAllowed) {
                    // add to allowed token holders
                    allowedTokenIds1155[_collectionId][tokenAddress].add(tokenId);
                } else {
                    // remove from allowed token holders
                    allowedTokenIds1155[_collectionId][tokenAddress].remove(tokenId);
                }

                unchecked { j++; }
            }

            if (_isAllowed) {
                // add to allowed token holders
                allowedExternalHolders1155[_collectionId].add(tokenAddress);
            } else if (allowedTokenIds1155[_collectionId][tokenAddress].length() == 0) {
                // remove from allowed token holders
                allowedExternalHolders1155[_collectionId].remove(tokenAddress);
            }

            unchecked { i++; }
        }

        if (_isAllowed) {
            // emit approve event
            emit AllowedExternalHolders1155(
                _collectionId,
                _tokenAddresses,
                _tokenIds
            );
        } else {
            // emit disapprove event
            emit RemovedExternalHolders1155(
                _collectionId,
                _tokenAddresses,
                _tokenIds
            );
        }
    }

    /**
     * @notice Returns true if user holds an allowlisted NFT for collection `_collectionId`.
     * @param _collectionId Collection ID to be checked.
     * @return bool User is allowlisted
     * @dev does not check if held token has been used to purchase a token from `_collectionId`
     */
    function isAllowlistedFor(
        address _address,
        uint256 _collectionId
    ) public view onlyValidCollectionId(_collectionId) returns (bool) {
        uint256 numAllowedCollectionIds = allowedCollectionIds[_collectionId].length();
        for (uint256 i = 0; i < numAllowedCollectionIds; i++) {
            if (collCoreContract.balanceOf(_address, allowedCollectionIds[_collectionId].at(i)) > 0) {
                return true;
            }
        }

        uint256 numAllowedExternalHolders721 = allowedExternalHolders721[_collectionId].length();
        for (uint256 i = 0; i < numAllowedExternalHolders721; i++) {
            if (IERC721(allowedExternalHolders721[_collectionId].at(i)).balanceOf(_address) > 0) {
                return true;
            }
        }

        uint256 numAllowedExternalHolders1155 = allowedExternalHolders1155[_collectionId].length();
        for (uint256 i = 0; i < numAllowedExternalHolders1155; i++) {
            address tokenAddress = allowedExternalHolders1155[_collectionId].at(i);
            uint256 numAllowedTokenIds1155 = allowedTokenIds1155[_collectionId][tokenAddress].length();
            for (uint256 j = 0; j < numAllowedTokenIds1155; j++) {
                uint256 tokenId = allowedTokenIds1155[_collectionId][tokenAddress].at(j);
                if (IERC1155(tokenAddress).balanceOf(_address, tokenId) > 0) {
                    return true;
                }
            }
        }

        return false;
    }

    /**
     * @notice Purchase a token from a collection during minting.
     * @param _to Receiver of the purchased token.
     * @param _collectionId Collection ID to be minted from.
     * @param _signature Signature to verify buyer is whitelisted.
     * @param _signatureExpirationBlock Signature expiration block.
     * @return tokenId First token id purchased.
     */
    function purchase(
        address _to,
        uint256 _collectionId,
        uint24 _amount,
        bytes memory _signature,
        uint256 _signatureExpirationBlock
    )
        external
        payable
        nonReentrant
        onlyValidCollectionId(_collectionId)
        returns (uint256 tokenId)
    {
        // CHECKS
        require(_amount > 0, "Must purchase at least one token");

        // require valid signature for minting in any phase
        require(verifyAddressSigner(_signature, _collectionId, msg.sender, _signatureExpirationBlock), "Invalid signature");

        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        uint256 _pricePerToken = _collectionConfig.pricePerToken;

        // require price of token to be configured on this minter
        require(_pricePerToken > 0 && _collectionConfig.hasMaxPerWallet, "Collection not configured");

        // require user to hold an allowlisted token during holder pre mint phase
        require(_collectionConfig.holderPreMintDone || (isAllowlistedFor(msg.sender, _collectionId)),
            "Only allowlisted NFT holders"
        );

        uint256 newMintedAmount = walletMintedPerCollection[_collectionId][msg.sender] + _amount;
        uint256 maxMints = _collectionConfig.maxMintsPerWallet;
        require(maxMints == 0 || newMintedAmount <= maxMints, "Maximum amount exceeded");

        // EFFECTS
        walletMintedPerCollection[_collectionId][msg.sender] = newMintedAmount;
        tokenId = collCoreContract.mint(_to, _collectionId, _amount);

        // INTERACTIONS
        // Moving money after mint to pass core checks first
        uint256 _totalPrice = _pricePerToken * _amount;
        address _currencyAddress = _collectionConfig.currencyAddress;
        if (_currencyAddress != address(0)) {
            require(
                msg.value == 0,
                "This collection accepts a different currency and cannot accept ETH"
            );
            require(
                IERC20(_currencyAddress).allowance(msg.sender, address(this)) >=
                    _totalPrice,
                "Insufficient Funds Approved for TX"
            );
            require(
                IERC20(_currencyAddress).balanceOf(msg.sender) >=
                    _totalPrice,
                "Insufficient balance"
            );
            _splitFundsERC20(_collectionId, _totalPrice, _currencyAddress);
        } else {
            require(
                msg.value >= _totalPrice,
                "Must send minimum value to mint"
            );
            _splitFundsETH(_collectionId, _totalPrice);
        }

        return tokenId;
    }

    /**
     * @dev splits ETH funds between sender (if refund), 4JM,
     * DAO, and artist for a token purchased on
     * collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsETH(uint256 _collectionId, uint256 _totalPrice)
        internal
    {
        if (msg.value > 0) {
            bool success_;
            // send refund to sender
            uint256 refund = msg.value - _totalPrice;
            if (refund > 0) {
                (success_, ) = msg.sender.call{value: refund}("");
                require(success_, "Refund failed");
            }
            // split remaining funds between 4JM, DAO and artist
            (
                uint256 fjmRevenue_,
                address payable fjmAddress_,
                uint256 daoRevenue_,
                address payable daoAddress_,
                uint256 artistRevenue_,
                address payable artistAddress_
            ) = collCoreContract.getPrimaryRevenueSplits(
                    _collectionId,
                    _totalPrice
                );
            // 4JM payment
            if (fjmRevenue_ > 0) {
                (success_, ) = fjmAddress_.call{value: fjmRevenue_}(
                    ""
                );
                require(success_, "Particle payment failed");
            }
            // Particle DAO payment
            if (daoRevenue_ > 0) {
                (success_, ) = daoAddress_.call{
                    value: daoRevenue_
                }("");
                require(success_, "DAO payment failed");
            }
            // artist payment
            if (artistRevenue_ > 0) {
                (success_, ) = artistAddress_.call{value: artistRevenue_}("");
                require(success_, "Artist payment failed");
            }
        }
    }

    /**
     * @dev splits ERC-20 funds between 4JM, Particle DAO and artist, for a token purchased on collection `_collectionId`.
     * @dev possible DoS during splits is acknowledged, and mitigated by
     * admin-accepted artist payment addresses.
     */
    function _splitFundsERC20(
        uint256 _collectionId,
        uint256 _totalPrice,
        address _currencyAddress
    ) internal {
        // split remaining funds between 4JM, Particle DAO and artist
        (
            uint256 fjmRevenue_,
            address payable fjmAddress_,
            uint256 daoRevenue_,
            address payable daoAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        ) = collCoreContract.getPrimaryRevenueSplits(
                _collectionId,
                _totalPrice
            );
        IERC20 _collectionCurrency = IERC20(_currencyAddress);
        // 4JM payment
        if (fjmRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                fjmAddress_,
                fjmRevenue_
            );
        }
        // Particle DAO payment
        if (daoRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                daoAddress_,
                daoRevenue_
            );
        }
        // artist payment
        if (artistRevenue_ > 0) {
            _collectionCurrency.safeTransferFrom(
                msg.sender,
                artistAddress_,
                artistRevenue_
            );
        }
    }

    /**
     * @notice collectionId => maximum mints per allowlisted address. 
     * If a value of 0 is returned, there is no limit on the number of mints per allowlisted address.
     * Default behavior is no limit mint per address.
     */
    function collectionMaxMintsPerAddress(
        uint256 _collectionId
    ) public view onlyValidCollectionId(_collectionId) returns (uint256) {
        return uint256(collectionConfigs[_collectionId].maxMintsPerWallet);
    }

    /**
     * @notice Returns remaining mints for a given address.
     * Returns 0 if no maximum per address is set for collection `_collectionId`.
     * Note that max mints per address can be changed at any time by the owner.
     * Also note that all max mints per address are limited by a 
     * collections's maximum mints as defined on the core contract. 
     * This function may return a value greater than the collection's remaining mints.
     */
    function collectionRemainingMintsForAddress(
        uint256 _collectionId,
        address _address
    )
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            uint256 mintsRemaining,
            bool hasLimit
        )
    {
        uint256 maxMintsPerAddress = collectionMaxMintsPerAddress(
            _collectionId
        );
        if (maxMintsPerAddress == 0) {
            // project does not limit mint invocations per address, so leave `mintsRemaining` at
            // solidity initial value of zero, and hasLimit as false
        } else {
            hasLimit = true;
            uint256 walletMints = walletMintedPerCollection[
                _collectionId
            ][_address];
            // if user has not reached max mints per address, return
            // remaining mints
            if (maxMintsPerAddress > walletMints) {
                unchecked {
                    // will never underflow due to the check above
                    mintsRemaining = maxMintsPerAddress - walletMints;
                }
            }
            // else user has reached their maximum invocations, so leave
            // `mintsRemaining` at solidity initial value of zero
        }
    }

    /**
     * @notice If price of token is configured, returns price of minting a
     * token on collection `_collectionId`, and currency symbol and address 
     * to be used as payment.
     * @param _collectionId Collection ID to get price information for.
     * @return isConfigured true only if token price has been configured on
     * this minter
     * @return tokenPrice current price of token on this minter - invalid
     * if price has not yet been configured
     * @return currencySymbol currency symbol for purchases of collection on this
     * minter. "ETH" reserved for ether.
     * @return currencyAddress currency address for purchases of collection on
     * this minter. Null address reserved for ether.
     */
    function getPriceInfo(uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (
            bool isConfigured,
            uint256 tokenPrice,
            string memory currencySymbol,
            address currencyAddress
        )
    {
        CollectionConfig storage _collectionConfig = collectionConfigs[_collectionId];
        tokenPrice = _collectionConfig.pricePerToken;
        isConfigured = tokenPrice > 0 && _collectionConfig.hasMaxPerWallet;
        currencyAddress = _collectionConfig.currencyAddress;
        if (currencyAddress == address(0)) {
            currencySymbol = "ETH";
        } else {
            currencySymbol = _collectionConfig.currencySymbol;
        }
    }

    /**
     * @notice Returns true if collection `_collectionId` has ended it's pre-mint phase.
     */
    function getCollectionPreMintDone(uint256 _collectionId)
        external
        view
        onlyValidCollectionId(_collectionId)
        returns (bool)
    {
        return collectionConfigs[_collectionId].holderPreMintDone;
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

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
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

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
        InvalidSignatureV // Deprecated in v4.8
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/// @title ERC721Multi collection interface
/// @author Particle Collection - valdi.eth
/// @notice Adds public facing and multi collection balanceOf and collectionId to tokenId functions
/// @dev This implements an optional extension of {ERC721} that adds
/// support for multiple collections and enumerability of all the
/// token ids in the contract as well as all token ids owned by each account per collection.
interface IERC721MultiCollection is IERC721 {
    /// @notice Collection ID `_collectionId` added
    event CollectionAdded(uint256 indexed collectionId);

    /// @notice New collections forbidden
    event NewCollectionsForbidden();

    // @dev Determine if a collection exists.
    function collectionExists(uint256 collectionId) external view returns (bool);

    /// @notice Balance for `owner` in `collectionId`
    function balanceOf(address owner, uint256 collectionId) external view returns (uint256);

    /// @notice Get the collection ID for a given token ID
    function tokenIdToCollectionId(uint256 tokenId) external view returns (uint256 collectionId);

    /// @notice returns the total number of collections.
    function numberOfCollections() external view returns (uint256);

    /// @dev Returns the total amount of tokens stored by the contract for `collectionId`.
    function tokenTotalSupply(uint256 collectionId) external view returns (uint256);

    /// @dev Returns a token ID owned by `owner` at a given `index` of its token list on `collectionId`.
    /// Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
    function tokenOfOwnerByIndex(address owner, uint256 index, uint256 collectionId) external view returns (uint256);

    /// @notice returns maximum size for collections.
    function MAX_COLLECTION_SIZE() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

/// @author: manifold.xyz

/**
 * @dev Royalty interface for creator core classes
 */
interface IManifold {

    /**
     * @dev Get royalites of a token.  Returns list of receivers and basisPoints
     *
     *  bytes4(keccak256('getRoyalties(uint256)')) == 0xbb3bafd6
     *
     *  => 0xbb3bafd6 = 0xbb3bafd6
     */
    function getRoyalties(uint256 tokenId) external view returns (address payable[] memory, uint256[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// use the Royalty Registry's IManifold interface for token royalties
import "./IManifold.sol";
import "./IERC721MultiCollection.sol";

/// @title Interface for Core ERC721 contract for multiple collections
/// @author Particle Collection - valdi.eth
/// @notice Manages all collections tokens
/// @dev Exposes all public functions and events needed by the Particle Collection's smart contracts
/// @dev Adheres to the ERC721 standard, ERC721MultiCollection extension and Manifold for secondary royalties
interface IPRTCLCollections721V1 is IERC721, IERC721MultiCollection, IManifold {
    /// @notice Collection ID `_collectionId` updated
    event CollectionDataUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` size updated
    event CollectionSizeUpdated(uint256 indexed _collectionId, uint256 _size);

    /// @notice Collection ID `_collectionId` sold through governance
    event CollectionSold(uint256 indexed _collectionId, address _buyer);

    /// @notice Collection ID `_collectionId` active
    event CollectionActive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` not active
    event CollectionInactive(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` royalties updated
    event CollectionRoyaltiesUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` primary split updated
    event CollectionPrimarySplitUpdated(uint256 indexed _collectionId);

    /// @notice Collection ID `_collectionId` fully minted
    event CollectionFullyMinted(uint256 indexed _collectionId);

    /// @notice Updated base uri
    event BaseURIUpdated(string _baseURI);

    /// @notice Royalties addresses updated
    event RoyaltiesAddressesUpdated(address _FJMAddress, address _DAOAddress);

    /// @notice Randomizer contract updated
    event RandomizerUpdated(address _randomizer);

    /// @notice Collection seeds set
    event CollectionSeedsSet(uint256 _collectionId, uint24 _seed1, uint24 _seed2);

    ///
    /// Collection data
    ///

    /// @notice Artist address for collection ID `_collectionId`
    function collectionIdToArtistAddress(uint256 _collectionId) external view returns (address payable);

    /// @notice Get the primary revenue splits for a given collection ID and sale price
    /// @dev Used by minter contract
    function getPrimaryRevenueSplits(uint256 _collectionId, uint256 _price) external view
        returns (
            uint256 FJMRevenue_,
            address payable FJMAddress_,
            uint256 DAORevenue_,
            address payable DAOAddress_,
            uint256 artistRevenue_,
            address payable artistAddress_
        );

    /// @notice Main collection data
    function collectionData(uint256 _collectionId) external view returns (
        uint256 nParticles,
        uint256 maxParticles,
        bool active,
        string memory collectionName,
        bool sold,
        uint24[] memory seeds,
        uint256 setSeedsAfterBlock
    );

    /// @notice Check if the collection can be sold
    /// @dev Used by governance contract
    function collectionCanBeSold(uint256 _collectionId) external view returns (bool);

    /// @notice Get the proceeds for a given collection ID, sale price and number of tokens
    /// @dev Used by governance contract
    function proceeds(uint256 _collectionId, uint256 _salePrice, uint256 _tokens) external view returns (uint256);

    /// @notice Get coordinates within an artwork for a given token ID
    function getCoordinate(uint256 _tokenId) external view returns (uint256);

    ///
    /// Collection interactions
    ///

    /// @notice Mark a collection as sold
    /// @dev Only callable by the governance role
    function markCollectionSold(uint256 _collectionId, address _buyer) external;
    
    /// @notice Mint a new token.
    /// Used by minter contract and BE infrastructure when handling fiat payments
    /// @dev Only callable by the minter role
    function mint(address _to, uint256 _collectionId, uint24 _amount) external returns (uint256 tokenId);

    /// @notice Burn tokensToRedeem tokens owned by `owner` in collection `_collectionId`
    /// Used when redeeming tokens for sale proceeds
    /// @dev Only callable by the governance role
    function burn(address owner, uint256 collectionId, uint256 tokensToRedeem) external returns (uint256 tokensBurnt);

    /// @notice Set the random prime seeds for a given collection ID, used to calculate token coordinates
    /// @dev Only callable by the Randomizer contract
    function setCollectionSeeds(uint256 _collectionId, uint24[2] calldata _seeds) external;
}