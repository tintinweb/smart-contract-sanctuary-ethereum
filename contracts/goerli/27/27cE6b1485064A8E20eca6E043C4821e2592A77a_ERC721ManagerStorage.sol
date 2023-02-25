// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { StorageBase } from '../StorageBase.sol';
import { ERC721ManagerAutoProxy } from './ERC721ManagerAutoProxy.sol';
import { ERC165 } from './ERC165.sol';
import { Pausable } from '../Pausable.sol';
import { NonReentrant } from '../NonReentrant.sol';

import { ICollectionStorage } from '../interfaces/ICollectionStorage.sol';
import { ICollectionProxy_ManagerFunctions } from '../interfaces/ICollectionProxy_ManagerFunctions.sol';
import { IERC721ManagerProxy } from '../interfaces/IERC721ManagerProxy.sol';
import { IERC721 } from '../interfaces/IERC721.sol';
import { IERC721Receiver } from '../interfaces/IERC721Receiver.sol';
import { IERC721Metadata } from '../interfaces/IERC721Metadata.sol';
import { IERC2981 } from '../interfaces/IERC2981.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';
import { IERC20 } from '../interfaces/IERC20.sol';

import { Address } from '../libraries/Address.sol';
import { Strings } from '../libraries/Strings.sol';

contract ERC721ManagerStorage is StorageBase {
address public test;
    // CollectionProxy --> CollectionStorage
    mapping(address => address) private collectionStorage;

    address[] private allCollectionProxies;

    function getCollectionStorage(address collectionProxy)
        external
        view
        returns (address _collectionStorage)
    {
        _collectionStorage = collectionStorage[collectionProxy];
    }

    function getCollectionProxy(uint256 index) external view returns (address _collectionProxy) {
        _collectionProxy = allCollectionProxies[index];
    }

    function getCollectionsLength() external view returns (uint256 _length) {
        _length = allCollectionProxies.length;
    }

    function setCollectionStorage(address collectionProxy, address _collectionStorage)
        external
        requireOwner
    {
        collectionStorage[collectionProxy] = _collectionStorage;
    }

    function pushCollectionProxy(address collectionProxy) external requireOwner {
        allCollectionProxies.push(collectionProxy);
    }

    function popCollectionProxy() external requireOwner {
        allCollectionProxies.pop();
    }

    function setCollectionProxy(uint256 index, address collectionProxy) external requireOwner {
        allCollectionProxies[index] = collectionProxy;
    }
}

contract ERC721Manager is Pausable, NonReentrant, ERC721ManagerAutoProxy, ERC165 {
address public test;
    using Strings for uint256;
    using Address for address;

    address public factoryProxy;
    address public mintFeeRecipient;
    address public weth;

    ERC721ManagerStorage public _storage;

    constructor(
        address _proxy,
        address _factoryProxy,
        address _mintFeeRecipient,
        address _weth
    ) ERC721ManagerAutoProxy(_proxy, address(this)) {
        _storage = new ERC721ManagerStorage();
        factoryProxy = _factoryProxy;
        mintFeeRecipient = _mintFeeRecipient;
        weth = _weth;
    }

    modifier requireCollectionProxy() {
        require(
            _storage.getCollectionStorage(msg.sender) != address(0),
            'ERC721Manager: FORBIDDEN, not a Collection proxy'
        );
        _;
    }

    function setSporkProxy(address payable _sporkProxy) external onlyOwner {
        IERC721ManagerProxy(proxy).setSporkProxy(_sporkProxy);
    }

    // This function is called by Factory implementation at a new collection creation
    // Register a new Collection's proxy address, and Collection's storage address
    function register(address _collectionProxy, address _collectionStorage)
        external
        whenNotPaused
    {
        require(
            msg.sender ==
            address(
                IGovernedProxy(payable(address(uint160(factoryProxy))))
                .implementation()
            ),
            'ERC721Manager: Not factory implementation!'
        );
        _storage.setCollectionStorage(_collectionProxy, _collectionStorage);
        _storage.pushCollectionProxy(_collectionProxy);
    }

    // This function is called in order to upgrade to a new ERC721Manager implementation
    function destroy(address _newImpl) external requireProxy {
        StorageBase(address(_storage)).setOwner(address(_newImpl));
        // Self destruct
        _destroy(_newImpl);
    }

    // This function (placeholder) would be called on the new implementation if necessary for the upgrade
    function migrate(address _oldImpl) external requireProxy {
        _migrate(_oldImpl);
    }

    function getCollectionStorage(address collectionProxy)
        public
        view
        returns (ICollectionStorage)
    {
        return ICollectionStorage(_storage.getCollectionStorage(collectionProxy));
    }

    function airdrop(
        address collectionProxy,
        address[] calldata recipients,
        uint256[] calldata numbers
    ) external onlyOwner {
        require(
            recipients.length == numbers.length,
            'ERC721Manager: recipients and numbers arrays must have the same length'
        );

        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        for (uint256 j = 0; j < recipients.length; j++) {
            for (uint256 i = 0; i < numbers[j]; i++) {
                _safeMint(collectionProxy, collectionStorage, msg.sender, recipients[j], '');
            }
        }
    }

    function safeMint(
        address collectionProxy,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH // If set to true, minting fee will be paid in WETH in case msg.value == 0, otherwise minting
        // fee will be paid in mintFeeERC20Asset
    ) external payable noReentry requireCollectionProxy whenNotPaused {
        require(quantity > 0, 'ERC721Manager: mint at least one NFT');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        if (
            block.number > collectionStorage.getBlockStartPublicPhase() &&
            block.number < collectionStorage.getBlockEndPublicPhase()
        ) {
            // Public-sale phase (anyone can mint)
            require(
                quantity <=
                    collectionStorage.getMAX_PUBLIC_MINT_PER_ADDRESS() -
                        collectionStorage.getMinted(minter),
                'ERC721Manager: Exceeds address allowance'
            );
            processSafeMint(collectionProxy, collectionStorage, minter, to, quantity, payWithWETH);
        } else {
            revert('ERC721Manager: Minting is not open');
        }
    }

    function processSafeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        uint256 quantity,
        bool payWithWETH
    ) private {
        // Make sure mint won't exceed max supply
        uint256 _totalSupply = collectionStorage.getTotalSupply();
        require(
            _totalSupply + quantity <= collectionStorage.getMAX_SUPPLY(),
            'ERC721Manager: Purchase would exceed max supply'
        );
        // Process mint fee payment
        processMintFee(collectionProxy, collectionStorage, minter, quantity, payWithWETH);
        // Mint
        for (uint256 i = 0; i < quantity; i++) {
            _safeMint(collectionProxy, collectionStorage, minter, to, '');
        }
    }

    function processMintFee(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        uint256 quantity,
        bool payWithWETH
    ) private {
        if(msg.value > 0 || payWithWETH) {
            // If msg.value > 0 or payWithWETH == true, we attempt to process ETH/WETH mint fee payment
            // Calculate total ETH/WETH mint fee to mint quantity
            (
                uint256 totalMintFeeETH,
                uint256 lastETHMintFeeAboveThreshold,
                uint256 ethMintsCount
            ) = getTotalMintFeeETH(collectionStorage, quantity);
            // Record lastETHMintFeeAboveThreshold into collection storage
            if(lastETHMintFeeAboveThreshold > 0) {
                collectionStorage.setLastETHMintFeeAboveThreshold(lastETHMintFeeAboveThreshold);
            }
            // Update collection's eth mints count
            collectionStorage.setETHMintsCount(ethMintsCount + quantity);
            if(msg.value > 0) {
                // Attempt to process ETH mint fee payment
                // Transfer mint fee
                if(msg.value >= totalMintFeeETH) {
                    // Transfer totalMintFeeETH to mintFeeRecipient
                    (bool _success, bytes memory _data) = mintFeeRecipient.call{
                    value: totalMintFeeETH
                    }('');
                    require(
                        _success && (_data.length == 0 || abi.decode(_data, (bool))),
                        'ERC721Manager: failed to transfer ETH mint fee'
                    );
                } else {
                    revert('ERC721Manager: msg.value is too small to pay mint fee');
                }
                // Resend excess funds to user
                uint256 balance = address(this).balance;
                (bool success, bytes memory data) = minter.call{ value: balance }('');
                require(
                    success && (data.length == 0 || abi.decode(data, (bool))),
                    'ERC721Manager: failed to transfer excess ETH back to minter'
                );
            } else {
                // Attempt to process ERC20 mint fee payment using WETH
                ICollectionProxy_ManagerFunctions(collectionProxy).safeTransferERC20From(
                    weth,
                    minter,
                    mintFeeRecipient,
                    totalMintFeeETH
                );
            }
        } else {
            // Attempt to process ERC20 mint fee payment using mintFeeERC20Asset
            address mintFeeERC20AssetProxy = collectionStorage.getMintFeeERC20AssetProxy();
            uint256 mintFeeERC20 = collectionStorage.getMintFeeERC20() * quantity;
            // Burn mintFeeERC20Asset from minter
            IERC20(IGovernedProxy(payable(address(uint160(mintFeeERC20AssetProxy)))).impl()).burn(minter, mintFeeERC20);
        }
    }

    function getTotalMintFeeETH(
        ICollectionStorage collectionStorage,
        uint256 quantity
    ) public view returns(uint256 totalMintFeeETH, uint256 lastETHMintFeeAboveThreshold, uint256 ethMintsCount){
        ethMintsCount = collectionStorage.getETHMintsCount();
        uint256 ethMintsCountThreshold = collectionStorage.getETHMintsCountThreshold();
        if(ethMintsCount >= ethMintsCountThreshold) {
            (totalMintFeeETH, lastETHMintFeeAboveThreshold) = calculateOverThresholdMintFeeETH(collectionStorage, quantity);
        } else if(ethMintsCount + quantity <= ethMintsCountThreshold) {
            uint256 baseMintFeeETH = collectionStorage.getBaseMintFeeETH();
            totalMintFeeETH = calculateSubThresholdMintFeeETH(baseMintFeeETH, ethMintsCount, quantity);
            lastETHMintFeeAboveThreshold = 0;
        } else {
            // Calculate ETH mint fee for mints below ethMintsCountThreshold
            uint256 subThresholdQuantity = ethMintsCountThreshold - ethMintsCount;
            uint256 baseMintFeeETH = collectionStorage.getBaseMintFeeETH();
            uint256 subThresholdMintFeeETH = calculateSubThresholdMintFeeETH(baseMintFeeETH, ethMintsCount, subThresholdQuantity);
            // Calculate ETH mint fee for mints above ethMintsCountThreshold
            uint256 overThresholdQuantity = quantity - subThresholdQuantity;
            uint256 overThresholdMintFeeETH;
            (overThresholdMintFeeETH, lastETHMintFeeAboveThreshold) = calculateOverThresholdMintFeeETH(collectionStorage, overThresholdQuantity);
            totalMintFeeETH = subThresholdMintFeeETH + overThresholdMintFeeETH;
        }
    }

    function calculateSubThresholdMintFeeETH(
        uint256 baseMintFeeETH,
        uint256 ethMintsCount,
        uint256 quantity
    ) private pure returns(uint256 totalMintFeeETH){
        // ETH minting starts at baseMintFeeETH and increases by baseMintFeeETH for every ETH mint for the first
        // ethMintsCountThreshold tokens minted with ETH
        uint256 lastMintFeeETH = baseMintFeeETH * ethMintsCount; // Mint fee of last ETH mint
        uint256 nextMintFeeETH;
        totalMintFeeETH = 0;
        for(uint256 i = 0; i < quantity; i++) {
            nextMintFeeETH = lastMintFeeETH + baseMintFeeETH;
            totalMintFeeETH = totalMintFeeETH + nextMintFeeETH;
            lastMintFeeETH = nextMintFeeETH;
        }
    }

    function calculateOverThresholdMintFeeETH(
        ICollectionStorage collectionStorage,
        uint256 quantity
    ) private view returns(uint256 totalMintFeeETH, uint256 lastETHMintFeeAboveThreshold){
        // After ethMintCountThreshold ETH mints, the ETH mint price will increase by ethMintFeeGrowthRateBps bps
        // for every mint
        uint256 ethMintFeeGrowthRateBps = collectionStorage.getETHMintFeeGrowthRateBps();
        uint256 feeDenominator = collectionStorage.getFeeDenominator();
        totalMintFeeETH = 0;
        lastETHMintFeeAboveThreshold = collectionStorage.getLastETHMintFeeAboveThreshold();
        for(uint256 i = 1; i <= quantity; i++) {
            uint256 mintFeeETHAtIndex = lastETHMintFeeAboveThreshold *
                (feeDenominator + ethMintFeeGrowthRateBps) / feeDenominator;
            totalMintFeeETH = totalMintFeeETH + mintFeeETHAtIndex;
            lastETHMintFeeAboveThreshold = mintFeeETHAtIndex;
        }
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC2981).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function royaltyInfo(
        address collectionProxy,
        uint256, // Royalties are identical for all tokenIds
        uint256 salePrice
    ) external view returns (address, uint256) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        address receiver = collectionStorage.getRoyaltyReceiver();
        uint256 royaltyAmount;
        if (receiver != address(0)) {
            uint96 fraction = collectionStorage.getRoyaltyFraction();
            royaltyAmount = (salePrice * fraction) / collectionStorage.getFeeDenominator();
        } else {
            royaltyAmount = 0;
        }

        return (receiver, royaltyAmount);
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(address collectionProxy, uint256 tokenId)
    public
    view
    virtual
    returns (address)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        address owner = collectionStorage.getOwner(tokenId);
        require(owner != address(0), 'ERC721Manager: owner query for nonexistent token');
        return owner;
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address collectionProxy, address owner)
        public
        view
        virtual
        returns (uint256)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(owner != address(0), 'ERC721Manager: balance query for the zero address');
        return collectionStorage.getBalance(owner);
    }

    /**
     * @dev See {IERC721-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address collectionProxy, address owner, uint256 index) external view returns (uint256 tokenId) {
        require(owner != address(0), 'ERC721Manager: tokenOfOwnerByIndex query for the zero address');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(collectionStorage.getBalance(owner) > index, 'ERC721Manager: index must be less than address balance');
        tokenId = collectionStorage.getTokenOfOwnerByIndex(owner, index);
    }

    /**
     * @dev See {IERC721-tokenByIndex}.
     */
    function tokenByIndex(address collectionProxy, uint256 index) external view returns (uint256 tokenId) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(index < collectionStorage.getTotalSupply(), 'ERC721Manager: index must be less than total supply');
        tokenId = collectionStorage.getTokenIdByIndex(index);
    }

    /**
     * @dev See {IERC721-totalSupply}.
     */
    function totalSupply(address collectionProxy)
        public
        view
        virtual
        returns (uint256)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getTotalSupply();
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(address collectionProxy, uint256 tokenId)
    public
    view
    virtual
    returns (address)
    {
        require(
            exists(collectionProxy, tokenId),
            'ERC721Manager: approved query for nonexistent token'
        );

        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);

        return collectionStorage.getTokenApproval(tokenId);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(
        address collectionProxy,
        address owner,
        address operator
    ) public view virtual returns (bool) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getOperatorApproval(owner, operator);
    }

    /**
     * @dev See {IERC721Metadata-baseURI}.
     */
    function baseURI(address collectionProxy)
    external
    view
    virtual
    returns (string memory)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return baseURI_local;
    }


    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(address collectionProxy, uint256 tokenId)
    external
    view
    virtual
    returns (string memory)
    {
        require(
            exists(collectionProxy, tokenId),
            'ERC721Manager: URI query for nonexistent token'
        );

        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        if (collectionStorage.getCollectionMoved()) {
            return collectionStorage.getMovementNoticeURI();
        }

        string memory baseURI_local = collectionStorage.getBaseURI();
        return
        bytes(baseURI_local).length > 0
        ? string(abi.encodePacked(baseURI_local, tokenId.toString()))
        : '';
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name(address collectionProxy) external view virtual returns (string memory) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getName();
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol(address collectionProxy) external view virtual returns (string memory) {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getSymbol();
    }

    /**
     * @dev Burns `tokenId`. See {ERC721-_burn}.
     *
     * Requirements:
     *
     * - `burner` must own `tokenId` or be an approved operator.
     */
    function burn(
        address collectionProxy,
        address burner,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused {
        require(
            _isApprovedOrOwner(collectionProxy, burner, tokenId),
            'ERC721Manager: caller is not owner nor approved'
        );
        _burn(collectionProxy, tokenId);
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(
        address collectionProxy,
        address msgSender,
        address spender,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused {
        address owner = ownerOf(collectionProxy, tokenId);
        require(spender != owner, 'ERC721Manager: approval to current owner');

        require(
            msgSender == owner || isApprovedForAll(collectionProxy, owner, msgSender),
            'ERC721Manager: approve caller is not owner nor approved for all'
        );

        _approve(collectionProxy, spender, tokenId);
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId
    ) external requireCollectionProxy whenNotPaused {
        require(
            _isApprovedOrOwner(collectionProxy, spender, tokenId),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _transfer(collectionProxy, from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external requireCollectionProxy whenNotPaused {
        require(
            _isApprovedOrOwner(collectionProxy, spender, tokenId),
            'ERC721Manager: transfer caller is not owner nor approved'
        );

        _safeTransferFrom(collectionProxy, spender, from, to, tokenId, _data);
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) external requireCollectionProxy whenNotPaused {
        _setApprovalForAll(collectionProxy, owner, operator, approved);
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
    function _safeTransferFrom(
        address collectionProxy,
        address spender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(collectionProxy, from, to, tokenId);
        require(
            _checkOnERC721Received(spender, from, to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
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
    function exists(address collectionProxy, uint256 tokenId)
        public
        view
        virtual
        returns (bool)
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        return collectionStorage.getOwner(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(
        address collectionProxy,
        address spender,
        uint256 tokenId
    ) internal view virtual returns (bool) {
        require(
            exists(collectionProxy, tokenId),
            'ERC721Manager: operator query for nonexistent token'
        );
        address owner = ownerOf(collectionProxy, tokenId);
        return (spender == owner ||
            getApproved(collectionProxy, tokenId) == spender ||
            isApprovedForAll(collectionProxy, owner, spender));
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to,
        bytes memory _data
    ) internal virtual {
        uint256 tokenId = _mint(collectionProxy, collectionStorage, minter, to);
        require(
            _checkOnERC721Received(minter, address(0), to, tokenId, _data),
            'ERC721Manager: transfer to non ERC721Receiver implementer'
        );
    }

    /**
     * @dev Mints token and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        address collectionProxy,
        ICollectionStorage collectionStorage,
        address minter,
        address to
    ) internal virtual returns (uint256) {
        require(to != address(0), 'ERC721Manager: mint to the zero address');
        // Calculate tokenId
        uint256 tokenId = collectionStorage.getTokenIdsCount() + 1;
        // Register tokenId
        collectionStorage.pushTokenId(tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() + 1);
        // Update minted count for minter
        collectionStorage.setMinted(minter, collectionStorage.getMinted(minter) + 1);
        // Register tokenId ownership
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(address(0), to, tokenId);

        return tokenId;
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
    function _burn(address collectionProxy, uint256 tokenId) internal virtual {
        ICollectionStorage collectionStorage = ICollectionStorage(
            _storage.getCollectionStorage(collectionProxy)
        );
        // Get owner of tokenId
        address owner = ownerOf(collectionProxy, tokenId);
        // Clear approvals
        _approve(collectionProxy, address(0), tokenId);
        // Update totalSupply
        collectionStorage.setTotalSupply(collectionStorage.getTotalSupply() - 1);
        // Update tokenIds array (set value to 0 at tokenId index to signal that token was burned)
        collectionStorage.setTokenIdByIndex(0, tokenId);
        // Update tokenId ownership
        uint256 ownerBalance = collectionStorage.getBalance(owner);
        for(uint256 i = 0; i < ownerBalance; i++) {
            if(collectionStorage.getTokenOfOwnerByIndex(owner, i) == tokenId) {
                // Replace burned tokenId with last tokenId in tokenOfOwner array, and pop last tokenId from
                // tokenOfOwner array
                uint256 lastTokenIdOfOwner = collectionStorage.getTokenOfOwnerByIndex(owner, ownerBalance - 1);
                collectionStorage.setTokenOfOwnerByIndex(owner, i, lastTokenIdOfOwner);
                collectionStorage.popTokenOfOwner(owner);
                break;
            }
        }
        collectionStorage.setOwner(tokenId, address(0));
        // Emit Transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(owner, address(0), tokenId);
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
        address collectionProxy,
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(
            ownerOf(collectionProxy, tokenId) == from,
            'ERC721Manager: transfer from incorrect owner'
        );
        require(to != address(0), 'ERC721Manager: transfer to the zero address');
        ICollectionStorage collectionStorage = ICollectionStorage(
            _storage.getCollectionStorage(collectionProxy)
        );
        // Clear approvals from the previous owner
        _approve(collectionProxy, address(0), tokenId);
        // Update tokenId ownership
        uint256 fromBalance = collectionStorage.getBalance(from);
        for(uint256 i = 0; i < fromBalance; i++) {
            if(collectionStorage.getTokenOfOwnerByIndex(from, i) == tokenId) {
                // Replace transferred tokenId with last tokenId in tokenOfOwner array, and pop last tokenId from
                // tokenOfOwner array
                uint256 lastTokenIdOfFrom = collectionStorage.getTokenOfOwnerByIndex(from, fromBalance - 1);
                collectionStorage.setTokenOfOwnerByIndex(from, i, lastTokenIdOfFrom);
                collectionStorage.popTokenOfOwner(from);
                break;
            }
        }
        collectionStorage.pushTokenOfOwner(to, tokenId);
        collectionStorage.setOwner(tokenId, to);
        // Emit transfer event
        ICollectionProxy_ManagerFunctions(collectionProxy).emitTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address collectionProxy,
        address spender,
        uint256 tokenId
    ) internal virtual {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);

        collectionStorage.setTokenApproval(tokenId, spender);
        ICollectionProxy_ManagerFunctions(collectionProxy).emitApproval(
            ownerOf(collectionProxy, tokenId),
            spender,
            tokenId
        );
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address collectionProxy,
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, 'ERC721Manager: approve to caller');
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);

        collectionStorage.setOperatorApproval(owner, operator, approved);

        ICollectionProxy_ManagerFunctions(collectionProxy).emitApprovalForAll(owner, operator, approved);
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
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (
                bytes4 retval
            ) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert('ERC721Manager: transfer to non ERC721Receiver implementer');
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

    function setBaseURI(address collectionProxy, string calldata baseURI_) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setBaseURI(baseURI_);
    }

    function setName(address collectionProxy, string calldata newName) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setName(newName);
    }

    function setSymbol(address collectionProxy, string calldata newSymbol) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setSymbol(newSymbol);
    }

    function setMAX_PUBLIC_MINT_PER_ADDRESS(address collectionProxy, uint256 _value)
        external
        onlyOwner
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMAX_PUBLIC_MINT_PER_ADDRESS(_value);
    }

    function setMAX_SUPPLY(address collectionProxy, uint256 _value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMAX_SUPPLY(_value);
    }

    function setPublicPhase(
        address collectionProxy,
        uint256 _blockStartPublicPhase,
        uint256 _blockEndPublicPhase
    ) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setPublicPhase(_blockStartPublicPhase, _blockEndPublicPhase);
    }

    function setCollectionMoved(address collectionProxy, bool _collectionMoved) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setCollectionMoved(_collectionMoved);
    }

    function setMovementNoticeURI(address collectionProxy, string calldata _movementNoticeURI)
        external
        onlyOwner
    {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMovementNoticeURI(_movementNoticeURI);
    }

    function setMintFeeRecipient(address _mintFeeRecipient) external onlyOwner {
        mintFeeRecipient = _mintFeeRecipient;
    }

    function setRoyalty(
        address collectionProxy,
        address receiver,
        uint96 feeNumerator
    ) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        require(
            feeNumerator <= collectionStorage.getFeeDenominator(),
            'ERC721Manager: royalty fee will exceed salePrice'
        );
        collectionStorage.setRoyaltyInfo(receiver, feeNumerator);
    }

    function setFeeDenominator(address collectionProxy, uint96 value) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setFeeDenominator(value);
    }

    function setMintFeeERC20AssetProxy(address collectionProxy, address _mintFeeERC20AssetProxy) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMintFeeERC20AssetProxy(_mintFeeERC20AssetProxy);
    }

    function setMintFeeERC20(address collectionProxy, uint256 _mintFeeERC20) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setMintFeeERC20(_mintFeeERC20);
    }

    function setBaseMintFeeETH(address collectionProxy, uint256 _baseMintFeeETH) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setBaseMintFeeETH(_baseMintFeeETH);
    }

    function setETHMintFeeGrowthRateBps(address collectionProxy, uint256 _ethMintFeeGrowthRateBps) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setETHMintFeeGrowthRateBps(_ethMintFeeGrowthRateBps);
    }

    function setETHMintsCountThreshold(address collectionProxy, uint256 _ethMintsCountThreshold) external onlyOwner {
        ICollectionStorage collectionStorage = getCollectionStorage(collectionProxy);
        collectionStorage.setETHMintsCountThreshold(_ethMintsCountThreshold);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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

        (bool success, ) = recipient.call{ value: amount }('');
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
        return
            functionCallWithValue(target, data, value, 'Address: low-level call with value failed');
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

        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
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
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionDelegateCall(target, data, 'Address: low-level delegate call failed');
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
        require(isContract(target), 'Address: delegate call to non-contract');

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IProposal } from './IProposal.sol';
import { IGovernedContract } from './IGovernedContract.sol';

/**
 * Interface of UpgradeProposal
 */
interface IUpgradeProposal is IProposal {
    function implementation() external view returns (IGovernedContract);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IProposal {
    function parent() external view returns (address);

    function created_block() external view returns (uint256);

    function deadline() external view returns (uint256);

    function fee_payer() external view returns (address payable);

    function fee_amount() external view returns (uint256);

    function accepted_weight() external view returns (uint256);

    function rejected_weight() external view returns (uint256);

    function total_weight() external view returns (uint256);

    function quorum_weight() external view returns (uint256);

    function isFinished() external view returns (bool);

    function isAccepted() external view returns (bool);

    function withdraw() external;

    function destroy() external;

    function collect() external;

    function voteAccept() external;

    function voteReject() external;

    function setFee() external payable;

    function canVote(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './IGovernedContract.sol';
import { IUpgradeProposal } from './IUpgradeProposal.sol';

interface IGovernedProxy {
    event UpgradeProposal(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    event Upgraded(IGovernedContract indexed implementation, IUpgradeProposal proposal);

    function spork_proxy() external view returns (address);

    function impl() external returns(address);

    function implementation() external view returns (IGovernedContract);

    function initialize(address _implementation) external;

    function proposeUpgrade(IGovernedContract _newImplementation, uint256 _period)
        external
        payable
        returns (IUpgradeProposal);

    function upgrade(IUpgradeProposal _proposal) external;

    function upgradeProposalImpl(IUpgradeProposal _proposal)
        external
        view
        returns (IGovernedContract newImplementation);

    function listUpgradeProposals() external view returns (IUpgradeProposal[] memory proposals);

    function collectUpgradeProposal(IUpgradeProposal _proposal) external;

    fallback() external;

    receive() external payable;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IGovernedContract {
    // Return actual proxy address for secure validation
    function proxy() external view returns (address);
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import '../eRC721Manager/IERC165.sol';

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC165 {
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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface IERC721ManagerProxy {
    function setSporkProxy(address payable _sporkProxy) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import '../eRC721Manager/IERC165.sol';

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
     * @dev Returns an owner's token Id by index.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns the total number of tokens.
     */
    function totalSupply() external view returns (uint256);

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import '../eRC721Manager/IERC165.sol';

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function burn(address recipient, uint256 amount) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionStorage {
    function getFeeDenominator() external view returns (uint96 _feeDenominator);

    function getRoyaltyReceiver() external view returns (address _royaltyReceiver);

    function getRoyaltyFraction() external view returns (uint96 _royaltyFraction);

    function getRoyaltyInfo() external view returns (address _royaltyReceiver, uint96 _royaltyFraction);

    function getCollectionManagerProxyAddress() external view returns (address _collectionManagerProxyAddress);

    function getMovementNoticeURI() external view returns (string memory _movementNoticeURI);

    function getCollectionMoved() external view returns (bool _collectionMoved);

    function getMAX_PUBLIC_MINT_PER_ADDRESS()
        external
        view
        returns (uint256 _MAX_PUBLIC_MINT_PER_ADDRESS);

    function getMAX_SUPPLY() external view returns (uint256 _MAX_SUPPLY);

    function getBlockStartPublicPhase() external view returns (uint256 _blockStartPublicPhase);

    function getBlockEndPublicPhase() external view returns (uint256 _blockEndPublicPhase);

    function getOperatorApproval(address _owner, address _operator)
        external
        view
        returns (bool _approved);

    function getBalance(address _address) external view returns (uint256 _amount);

    function getMinted(address _address) external view returns (uint256 _amount);

    function getTotalSupply() external view returns (uint256 _totalSupply);

    function getTokenIdsCount() external view returns (uint256 _tokenIdsCount);

    function getTokenIdByIndex(uint256 _index) external view returns(uint256 _tokenId);

    function getTokenOfOwnerByIndex(address _owner, uint256 _index) external view returns(uint256 _tokenId);

    function getTokenApproval(uint256 _tokenId) external view returns (address _address);

    function getOwner(uint256 tokenId) external view returns (address _owner);

    function getName() external view returns (string memory _name);

    function getSymbol() external view returns (string memory _symbol);

    function getBaseURI() external view returns (string memory _baseURI);

    function getMintFeeERC20AssetProxy() external view returns (address _mintFeeERC20AssetProxy);

    function getMintFeeERC20() external view returns (uint256 _mintFeeERC20);

    function getBaseMintFeeETH() external view returns (uint256 _baseMintFeeETH);

    function getETHMintFeeGrowthRateBps() external view returns (uint256 _ethMintFeeGrowthRateBps);

    function getETHMintsCountThreshold() external view returns (uint256 _ethMintFeeThreshold);

    function getETHMintsCount() external view returns (uint256 _ethMintsCount);

    function getLastETHMintFeeAboveThreshold() external view returns (uint256 _lastETHMintFeeAboveThreshold);

    function setFeeDenominator(uint96 value) external;

    function setRoyaltyInfo(address receiver, uint96 fraction) external;

    function setMAX_PUBLIC_MINT_PER_ADDRESS(uint256 _value) external;

    function setMAX_SUPPLY(uint256 _value) external;

    function setPublicPhase(uint256 _blockStartPublicPhase, uint256 _blockEndPublicPhase) external;

    function setName(string calldata _name) external;

    function setSymbol(string calldata _symbol) external;

    function setBaseURI(string calldata _baseURI) external;

    function setMinted(address _address, uint256 _amount) external;

    function setTotalSupply(uint256 _value) external;

    function setTokenIdByIndex(uint256 _tokenId, uint256 _index) external;

    function pushTokenId(uint256 _tokenId) external;

    function popTokenId() external;

    function setTokenOfOwnerByIndex(address _owner, uint256 _index, uint256 _tokenId) external;

    function pushTokenOfOwner(address _owner, uint256 _tokenId) external;

    function popTokenOfOwner(address _owner) external;

    function setOwner(uint256 tokenId, address owner) external;

    function setTokenApproval(uint256 _tokenId, address _address) external;

    function setOperatorApproval(
        address _owner,
        address _operator,
        bool _approved
    ) external;

    function setCollectionMoved(bool _collectionMoved) external;

    function setCollectionManagerProxyAddress(address _collectionManagerProxyAddress) external;

    function setMovementNoticeURI(string calldata _movementNoticeURI) external;

    function setMintFeeERC20AssetProxy(address _mintFeeERC20AssetProxy) external;

    function setMintFeeERC20(uint256 _mintFeeERC20) external;

    function setBaseMintFeeETH(uint256 _baseMintFeeETH) external;

    function setETHMintFeeGrowthRateBps(uint256 _ethMintFeeGrowthRateBps) external;

    function setETHMintsCountThreshold(uint256 _ethMintFeeThreshold) external;

    function setETHMintsCount(uint256 _ethMintsCount) external;

    function setLastETHMintFeeAboveThreshold(uint256 _lastETHMintFeeAboveThreshold) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

interface ICollectionProxy_ManagerFunctions {

    function safeTransferERC20From(
        address token,
        address from,
        address to,
        uint256 value
    ) external;

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    function emitTransfer(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    function emitApproval(
        address owner,
        address approved,
        uint256 tokenId
    ) external;

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    function emitApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { GovernedContract } from '../GovernedContract.sol';
import { IGovernedProxy } from '../interfaces/IGovernedProxy.sol';

/**
 * ERC721ManagerAutoProxy is a version of GovernedContract which initializes its own proxy.
 * This is useful to avoid a circular dependency between GovernedContract and GovernedProxy
 * wherein they need each other's address in the constructor.
 */

contract ERC721ManagerAutoProxy is GovernedContract {
    constructor(address _proxy, address _implementation) GovernedContract(_proxy) {
        proxy = _proxy;
        IGovernedProxy(payable(proxy)).initialize(_implementation);
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import './IERC165.sol';

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

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Base for contract storage (SC-14).
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */

contract StorageBase {
    address payable internal owner;

    modifier requireOwner() {
        require(msg.sender == address(owner), 'StorageBase: Not owner!');
        _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    function setOwner(address _newOwner) external requireOwner {
        owner = payable(_newOwner);
    }

    function kill() external requireOwner {
        selfdestruct(payable(msg.sender));
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { Context } from './Context.sol';
import { Ownable } from './Ownable.sol';

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Context, Ownable {
    /**
     * @dev Emitted when pause() is called.
     * @param account of contract owner issuing the event.
     * @param unpauseBlock block number when contract will be unpaused.
     */
    event Paused(address account, uint256 unpauseBlock);

    /**
     * @dev Emitted when pause is lifted by unpause() by
     * @param account.
     */
    event Unpaused(address account);

    /**
     * @dev state variable
     */
    uint256 public blockNumberWhenToUnpause = 0;

    /**
     * @dev Modifier to make a function callable only when the contract is not
     *      paused. It checks whether the current block number
     *      has already reached blockNumberWhenToUnpause.
     */
    modifier whenNotPaused() {
        require(
            block.number >= blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is still paused'
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(
            block.number < blockNumberWhenToUnpause,
            'Pausable: Revert - Code execution is not paused'
        );
        _;
    }

    /**
     * @dev Triggers or extends pause state.
     *
     * Requirements:
     *
     * - @param blocks needs to be greater than 0.
     */
    function pause(uint256 blocks) external onlyOwner {
        require(
            blocks > 0,
            'Pausable: Revert - Pause did not activate. Please enter a positive integer.'
        );
        blockNumberWhenToUnpause = block.number + blocks;
        emit Paused(_msgSender(), blockNumberWhenToUnpause);
    }

    /**
     * @dev Returns to normal code execution.
     */
    function unpause() external onlyOwner {
        blockNumberWhenToUnpause = block.number;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of 'user permissions'.
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner, 'Ownable: Not owner');
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), 'Ownable: Zero address not allowed');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/**
 * A little helper to protect contract from being re-entrant in state
 * modifying functions.
 */

contract NonReentrant {
    uint256 private entry_guard;

    modifier noReentry() {
        require(entry_guard == 0, 'NonReentrant: Reentry');
        entry_guard = 1;
        _;
        entry_guard = 0;
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

import { IGovernedContract } from './interfaces/IGovernedContract.sol';

/**
 * Genesis version of GovernedContract common base.
 *
 * Base Consensus interface for upgradable contracts.
 * Unlike common approach, the implementation is NOT expected to be
 * called through delegatecall() to minimize risks of shared storage.
 *
 * NOTE: it MUST NOT change after blockchain launch!
 */
contract GovernedContract {
    address public proxy;

    constructor(address _proxy) {
        proxy = _proxy;
    }

    modifier requireProxy() {
        require(msg.sender == proxy, 'Governed Contract: Not proxy');
        _;
    }

    function getProxy() internal view returns (address _proxy) {
        _proxy = proxy;
    }

    // solium-disable-next-line no-empty-blocks
    function _migrate(address) internal {}

    function _destroy(address _newImpl) internal {
        selfdestruct(payable(_newImpl));
    }

    function _callerAddress() internal view returns (address payable) {
        if (msg.sender == proxy) {
            // This is guarantee of the GovernedProxy
            // solium-disable-next-line security/no-tx-origin
            return payable(tx.origin);
        } else {
            return payable(msg.sender);
        }
    }
}

// SPDX-License-Identifier: MIT

// Copyright 2023 Energi Core

pragma solidity 0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _txOrigin() internal view returns (address payable) {
        return payable(tx.origin);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}