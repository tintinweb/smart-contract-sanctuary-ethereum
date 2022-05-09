// SPDX-License-Identifier: MIT

/**


         /\
        _\/_
        \__/
       /    \
      ○      ○
     /   v    \
    /          \


 */

pragma solidity >=0.8.0 <0.9.0;

import "erc721a/contracts/ERC721A.sol";
import "erc721a/contracts/extensions/ERC721AQueryable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {IFeedToken} from "./FeedToken.sol";
import {ITokenURIManager} from "./TokenURIManager.sol";
import {ITraitsManager} from "./CustomTraitsManager.sol";

contract ChonkyChkns is ERC721A, ERC721AQueryable, Ownable, ReentrancyGuard {
    using MerkleProof for bytes32[];

    // MINTING STATE
    enum MintState {
        PRESALE,
        PUBLIC,
        CLOSED
    }
    MintState public mintState;

    // MintState-based variables. Index 0 = PRESALE, 1 = PUBLIC.
    uint256[2] mintCosts;

    // Membership lists with restricted access
    enum ExclusiveList {
        GENESIS,
        CHONKLIST
    }
    // ExclusiveList-based variables. . Index 0 = GENESIS, 1 = CHONKLIST.
    bytes32[2] private merkleRoots;

    uint256 public MAX_GENESIS_MINT_AMOUNT_PER_WALLET;
    uint256 public MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET;

    // Supply specs by token type
    uint256 public MAX_SUPPLY;
    uint256 public MAX_GENESIS_SUPPLY;
    // Records the number of genesis tokens that have been minted.
    uint256 public totalGenesisSupply;

    // Mapping of tokenId to whether it's a genesis token.
    mapping(uint256 => bool) public isGenesis;

    // Map of wallet address -> number of genesis/chonklist tokens minted.
    // Used to enforce max mints per wallet.
    mapping(address => uint256) public numGenesisMinted;
    mapping(address => uint256) public numChonklistMinted;

    // Maps of wallet addresses => number of Genesis/Standard NFTs they own.
    // Used for feed balance calculations.
    mapping(address => uint256) public numGenesisOwned;
    mapping(address => uint256) public numStandardOwned;

    // Related contracts, for FEED token generation, user-customized traits,
    // and tokenURI construction based on custom traits
    IFeedToken public feedToken;
    ITraitsManager public customTraitsManager;
    ITokenURIManager public tokenURIManager;

    constructor() ERC721A("ChonkyChkns", "CHONKYCHKNS") {
        MAX_SUPPLY = 4994;
        MAX_GENESIS_SUPPLY = 250;

        MAX_GENESIS_MINT_AMOUNT_PER_WALLET = 1;
        MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET = 3;

        mintCosts = [0.03 ether, 0.03 ether];

        mintState = MintState.CLOSED;
    }

    // GETTERS / QUERY FUNCTIONS

    function totalStandardSupply() external view returns (uint256) {
        // totalGenesisSupply will never exceed totalSupply minted.
        unchecked {
            return totalSupply() - totalGenesisSupply;
        }
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        // Role of determining tokenURI per token is delegated to tokenURIManager.
        // This allows the tokenURI format to flexibly change as new features
        // are added to the project, e.g. new traits that may affect metadata.
        return tokenURIManager.tokenURI(tokenId);
    }

    // CHECKS

    function mintPrechecks(uint256 _mintAmount, MintState _mintState)
        internal
        view
    {
        require(mintState == _mintState, "Mint stage not open");
        require(
            msg.value >= mintCosts[uint256(_mintState)] * _mintAmount,
            "Insufficient funds"
        );
    }

    function restrictedMintPrechecks(
        uint256 _mintAmount,
        MintState _mintState,
        ExclusiveList _exclusiveList,
        bytes32[] calldata proof
    ) internal view {
        mintPrechecks(_mintAmount, _mintState);

        require(
            proof.verify(
                merkleRoots[uint256(_exclusiveList)],
                keccak256(abi.encodePacked(_msgSender()))
            ),
            "Not authorized"
        );
    }

    // MINT FUNCTIONS

    function genesisPresaleMint(uint256 _mintAmount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        restrictedMintPrechecks(
            _mintAmount,
            MintState.PRESALE,
            ExclusiveList.GENESIS,
            proof
        );
        uint256 genesisQty = _calculateAndRegisterGenesisQuantity(_mintAmount);
        _registerPresaleStandardQuantity(_mintAmount - genesisQty);
        _mintAndUpdateBalance(_mintAmount, genesisQty);
    }

    function presaleMint(uint256 _mintAmount, bytes32[] calldata proof)
        external
        payable
        nonReentrant
    {
        restrictedMintPrechecks(
            _mintAmount,
            MintState.PRESALE,
            ExclusiveList.CHONKLIST,
            proof
        );
        _registerPresaleStandardQuantity(_mintAmount);
        _mintAndUpdateBalance(_mintAmount, 0);
    }

    // Call this function if/when MintState = PUBLIC and there are still remaining genesis tokens.
    // All users (including non-OG roles) will be able to mint up to the max per wallet of
    // genesis tokens on a first-come first-serve basis.
    // This function shouldn't be called after all genesis tokens have been minted -
    // it will function the same as publicMint but cost additional gas.
    function genesisPublicMint(uint256 _mintAmount)
        external
        payable
        nonReentrant
    {
        mintPrechecks(_mintAmount, MintState.PUBLIC);
        uint256 genesisQty = _calculateAndRegisterGenesisQuantity(_mintAmount);
        _mintAndUpdateBalance(_mintAmount, genesisQty);
    }

    function publicMint(uint256 _mintAmount) external payable nonReentrant {
        mintPrechecks(_mintAmount, MintState.PUBLIC);
        _mintAndUpdateBalance(_mintAmount, 0);
    }

    // TRANFER FUNCTION

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        ERC721A.transferFrom(from, to, tokenId);
        _updateBalancesOnTransfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        ERC721A.safeTransferFrom(from, to, tokenId, _data);
        _updateBalancesOnTransfer(from, to, tokenId);
    }

    // OWNER UTILITIES

    function mintForAddresses(
        address[] calldata _receivers,
        uint256[] calldata _amounts
    ) external onlyOwner {
        for (uint256 i; i < _receivers.length; ) {
            _safeMint(_receivers[i], _amounts[i]);
            _updateBalancesOnStandardMint(_receivers[i], _amounts[i]);
            unchecked {
                ++i;
            }
        }
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdraw failed!");
    }

    // SETTERS

    function setFeedToken(address _yield) external onlyOwner {
        feedToken = IFeedToken(_yield);
    }

    function setCustomTraitsManager(address _traitsManager) external onlyOwner {
        customTraitsManager = ITraitsManager(_traitsManager);
    }

    function setTokenURIManager(address _tokenURIManager) external onlyOwner {
        ITokenURIManager newTokenURIManager = ITokenURIManager(
            _tokenURIManager
        );
        // If there was a pre-existing TokenURIManager, record the previous base URI
        // and set it in the new manager
        if (address(tokenURIManager) != address(0)) {
            newTokenURIManager.setBaseUri(tokenURIManager.baseURI());
        }
        tokenURIManager = newTokenURIManager;
    }

    function setBaseUri(string calldata _baseUri) external onlyOwner {
        if (address(tokenURIManager) != address(0)) {
            tokenURIManager.setBaseUri(_baseUri);
        }
    }

    function setMintState(MintState _state) external onlyOwner {
        mintState = _state;
    }

    function setMerkleRootForExclusiveList(
        bytes32 _root,
        ExclusiveList _exclusiveList
    ) external onlyOwner {
        merkleRoots[uint256(_exclusiveList)] = _root;
    }

    // NOTE: UNIT IS WEI!
    function setMintCostForMintState(uint256 _cost, MintState _mintState)
        external
        onlyOwner
    {
        mintCosts[uint256(_mintState)] = _cost;
    }

    function setMaxSupply(uint256 _supply) external onlyOwner {
        MAX_SUPPLY = _supply;
    }

    function setMaxGenesisSupply(uint256 _supply) external onlyOwner {
        MAX_GENESIS_SUPPLY = _supply;
    }

    function setMaxGenesisMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external
        onlyOwner
    {
        MAX_GENESIS_MINT_AMOUNT_PER_WALLET = _maxMintAmountPerWallet;
    }

    function setMaxChonklistMintAmountPerWallet(uint256 _maxMintAmountPerWallet)
        external
        onlyOwner
    {
        MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET = _maxMintAmountPerWallet;
    }

    // INTERNAL FUNCTIONS

    // Mint helpers

    function _calculateAndRegisterGenesisQuantity(uint256 _maxMintAmount)
        internal
        returns (uint256)
    {
        // Allocate as many of _maxMintAmount as possible to be genesis tokens,
        // under wallet and supply constraints.
        unchecked {
            uint256 genesisQty = Math.min(
                Math.min(
                    MAX_GENESIS_MINT_AMOUNT_PER_WALLET -
                        numGenesisMinted[_msgSender()],
                    _maxMintAmount
                ),
                MAX_GENESIS_SUPPLY - totalGenesisSupply
            );

            // If any genesis tokens are being minted in this transaction, perform pre-mint
            // registration steps for them (set isGenesis status for each tokenId,
            // increment numGenesisMinted for user, increment totalGenesisSupply)
            if (genesisQty > 0) {
                uint256 tokenId = _currentIndex;
                for (uint256 i = 0; i < genesisQty; ++i) {
                    isGenesis[tokenId + i] = true;
                }
                numGenesisMinted[_msgSender()] += genesisQty;
                totalGenesisSupply += genesisQty;
            }
            return genesisQty;
        }
    }

    function _registerPresaleStandardQuantity(uint256 _standardTokenQuantity)
        internal
    {
        // If any standard tokens are being minted in this presale transaction,
        // verify that the total minted quantity for the user is within max per wallet constraints,
        // then increment numChonkListMinted for user.
        if (_standardTokenQuantity > 0) {
            require(
                _standardTokenQuantity + numChonklistMinted[_msgSender()] <=
                    MAX_CHONKLIST_MINT_AMOUNT_PER_WALLET,
                "Exceeded max per wallet"
            );
            numChonklistMinted[_msgSender()] += _standardTokenQuantity;
        }
    }

    function _mintAndUpdateBalance(
        uint256 _mintAmount,
        uint256 _genesisMintAmount
    ) internal {
        _safeMint(_msgSender(), _mintAmount);

        _updateBalancesOnGenesisMint(_msgSender(), _genesisMintAmount);
        _updateBalancesOnStandardMint(
            _msgSender(),
            _mintAmount - _genesisMintAmount
        );
    }

    // Balance updates on transfers/mints

    function _updateBalancesOnTransfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        feedToken.updateFeedCountOnTransfer(from, to);
        // No risk of overflow or underflow:
        // num{Genesis,Standard}Owned[from] will always be > 0
        // All num{Genesis,Standard}Owned balances are <= MAX_SUPPLY
        unchecked {
            if (isGenesis[tokenId]) {
                numGenesisOwned[from]--;
                numGenesisOwned[to]++;
            } else {
                numStandardOwned[from]--;
                numStandardOwned[to]++;
            }
        }
    }

    function _updateBalancesOnGenesisMint(address _to, uint256 _mintAmount)
        private
    {
        if (_mintAmount > 0) {
            feedToken.updateFeedCountOnMint(_to);
            // No risk of overflow
            unchecked {
                numGenesisOwned[_to] += _mintAmount;
            }
        }
    }

    function _updateBalancesOnStandardMint(address _to, uint256 _mintAmount)
        private
    {
        if (_mintAmount > 0) {
            feedToken.updateFeedCountOnMint(_to);
            // No risk of overflow
            unchecked {
                numStandardOwned[_to] += _mintAmount;
            }
        }
    }

    // Before mint hook
    function _beforeTokenTransfers(
        address from,
        address,
        uint256 startTokenId,
        uint256 quantity
    ) internal view override {
        // Check for sufficient supply available before mints
        if (from == address(0)) {
            require(
                startTokenId + quantity <= MAX_SUPPLY,
                "Max supply exceeded"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {ChonkyChkns} from "./ChonkyChkns.sol";
import {IFeedToken} from "./FeedToken.sol";

interface ITraitsManager {
    function getNumericalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (uint256);

    function getCategoricalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32);

    function getFreeFormTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32);

    function getNumericalTraitIncreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getNumericalTraitDecreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getCategoricalTraitAddPrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128);

    function getCategoricalTraitRemovePrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128);

    function getFreeFormTraitAddPrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function getFreeFormTraitRemovePrice(bytes32 _traitName)
        external
        view
        returns (uint128);

    function increaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToAdd
    ) external;

    function decreaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToSubtract
    ) external;

    function setCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external;

    function removeCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName
    ) external;

    function setFreeFormTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external;

    function removeFreeFormTraitForToken(uint256 _tokenId, bytes32 _traitName)
        external;
}

contract CustomTraitsManager is Ownable {
    // Mapping of (token id => (trait name => trait value))
    mapping(uint256 => mapping(bytes32 => uint256)) public numericalTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) public categoricalTraits;
    mapping(uint256 => mapping(bytes32 => bytes32)) public freeFormTraits;

    // Mappings of (numerical/categorical trait type => (price to add a unit, price to remove a unit)).
    struct Prices {
        uint128 addPrice;
        uint128 removePrice;
    }
    mapping(bytes32 => Prices) public traitPrices;
    mapping(bytes32 => mapping(bytes32 => Prices))
        public categoricalTraitPrices;

    // ===============================

    // Map of contracts that have the ability to modify trait values on tokens,
    // to perform tasks such as:
    //  - trait boosts/giveaways
    //  - affiliated NFTs that get linked to ChonkyChkns through traits
    mapping(address => bool) public traitModifiersList;

    ChonkyChkns public chonkyContract;
    IFeedToken public feedToken;

    constructor(address _chonkyChkns) {
        chonkyContract = ChonkyChkns(_chonkyChkns);
        feedToken = chonkyContract.feedToken();
    }

    function addTrustedContract(address _contract) external onlyOwner {
        traitModifiersList[_contract] = true;
    }

    function removeTrustedContract(address _contract) external onlyOwner {
        traitModifiersList[_contract] = false;
    }

    function addNewNumericalTrait(
        bytes32 _traitName,
        uint128 _traitPriceToIncrease,
        uint128 _traitPriceToDecrease
    ) external virtual onlyOwner {
        require(!_isValidTrait(_traitName), "Trait already exists");
        traitPrices[_traitName] = Prices(
            _traitPriceToIncrease,
            _traitPriceToDecrease
        );
    }

    function addNewCategoricalTrait(
        bytes32 _traitName,
        bytes32[] calldata _traitValues,
        uint128[] calldata _addPrices,
        uint128[] calldata _removePrices
    ) external virtual onlyOwner {
        require(
            _traitValues.length == _addPrices.length,
            "Trait value and Prices should be the same length."
        );
        require(
            _traitValues.length == _removePrices.length,
            "Trait value and Prices should be the same length."
        );
        unchecked {
            for (uint256 i; i < _traitValues.length; ++i) {
                bytes32 traitValue = _traitValues[i];
                require(
                    !_isValidCategoricalTrait(_traitName, traitValue),
                    "Categorical trait already exists"
                );
                categoricalTraitPrices[_traitName][traitValue] = Prices(
                    _addPrices[i],
                    _removePrices[i]
                );
            }
        }
    }

    function addNewFreeFormTrait(
        bytes32 _traitName,
        uint128 _addPrice,
        uint128 _removePrice
    ) external virtual onlyOwner {
        require(!_isValidTrait(_traitName), "Trait already exists");
        traitPrices[_traitName] = Prices(_addPrice, _removePrice);
    }

    function updateNumericalTraitPrice(
        bytes32 _traitName,
        uint128 _traitIncreaseUnitPrice,
        uint128 _traitDecreaseUnitPrice
    ) external virtual onlyOwner {
        _requireValidTrait(_traitName);
        traitPrices[_traitName] = Prices(
            _traitIncreaseUnitPrice,
            _traitDecreaseUnitPrice
        );
    }

    function updateCategoricalTraitPrice(
        bytes32 _traitName,
        bytes32 _traitValue,
        uint128 _traitAddPrice,
        uint128 _traitRemovePrice
    ) external virtual onlyOwner {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        categoricalTraitPrices[_traitName][_traitValue] = Prices(
            _traitAddPrice,
            _traitRemovePrice
        );
    }

    function updateFreeFormTraitPrice(
        bytes32 _traitName,
        uint128 _traitIncreaseUnitPrice,
        uint128 _traitDecreaseUnitPrice
    ) external virtual onlyOwner {
        _requireValidTrait(_traitName);
        traitPrices[_traitName] = Prices(
            _traitIncreaseUnitPrice,
            _traitDecreaseUnitPrice
        );
    }

    // GETTERS
    function getNumericalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (uint256)
    {
        _requireValidTrait(_traitName);
        return numericalTraits[_tokenId][_traitName];
    }

    function getCategoricalTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32)
    {
        bytes32 traitValue = categoricalTraits[_tokenId][_traitName];
        _requireValidCategoricalTrait(_traitName, traitValue);
        return traitValue;
    }

    function getFreeFormTrait(uint256 _tokenId, bytes32 _traitName)
        external
        view
        returns (bytes32)
    {
        _requireValidTrait(_traitName);
        return freeFormTraits[_tokenId][_traitName];
    }

    function getSortedTokenIdsByTrait(bytes32 _traitName, bool ascending)
        external
        view
        returns (uint256[2][] memory)
    {
        _requireValidTrait(_traitName);
        uint256 numTokens = chonkyContract.totalSupply();
        uint256[2][] memory ranks = new uint256[2][](numTokens);

        unchecked {
            uint256 ranksLength = 0;
            for (uint256 i = 0; i < numTokens; ++i) {
                uint256 traitValue = numericalTraits[i][_traitName];
                if (traitValue > 0) {
                    ranks[ranksLength] = [i, traitValue];
                    ranksLength++;
                }
            }
            if (ranksLength > 0) {
                _quickSortArrayOfTuples(ranks, 0, ranksLength - 1);
            }
            uint256[2][] memory sortedTokens = new uint256[2][](ranksLength);
            if (ascending) {
                for (uint256 i = 0; i < ranksLength; ++i) {
                    sortedTokens[i] = ranks[i];
                }
            } else {
                for (uint256 i = 0; i < ranksLength; ++i) {
                    sortedTokens[i] = ranks[ranksLength - i - 1];
                }
            }
            return sortedTokens;
        }
    }

    function getNumericalTraitIncreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].addPrice;
    }

    function getNumericalTraitDecreasePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].removePrice;
    }

    function getCategoricalTraitAddPrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128) {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        return categoricalTraitPrices[_traitName][_traitValue].addPrice;
    }

    function getCategoricalTraitRemovePrice(
        bytes32 _traitName,
        bytes32 _traitValue
    ) external view returns (uint128) {
        _requireValidCategoricalTrait(_traitName, _traitValue);
        return categoricalTraitPrices[_traitName][_traitValue].removePrice;
    }

    function getFreeFormTraitAddPrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].addPrice;
    }

    function getFreeFormTraitRemovePrice(bytes32 _traitName)
        external
        view
        returns (uint128)
    {
        _requireValidTrait(_traitName);
        return traitPrices[_traitName].removePrice;
    }

    // SETTERS

    function setFeedToken(address _feedToken) external onlyOwner {
        feedToken = IFeedToken(_feedToken);
    }

    function increaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToAdd
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, _countToAdd * uint256(traitPrice.addPrice));
        numericalTraits[_tokenId][_traitName] += _countToAdd;
    }

    function decreaseNumericalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        uint256 _countToSubtract
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(
            tokenOwner,
            _countToSubtract * uint256(traitPrice.removePrice)
        );
        numericalTraits[_tokenId][_traitName] -= _countToSubtract;
    }

    function setCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = categoricalTraitPrices[_traitName][
            _traitValue
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.addPrice));
        categoricalTraits[_tokenId][_traitName] = _traitValue;
    }

    function removeCategoricalTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );

        Prices memory traitPrice = categoricalTraitPrices[_traitName][
            categoricalTraits[_tokenId][_traitName]
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.removePrice));
        categoricalTraits[_tokenId][_traitName] = 0;
    }

    function setFreeFormTraitForToken(
        uint256 _tokenId,
        bytes32 _traitName,
        bytes32 _traitValue
    ) external {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );
        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.addPrice));
        freeFormTraits[_tokenId][_traitName] = _traitValue;
    }

    function removeFreeFormTraitForToken(uint256 _tokenId, bytes32 _traitName)
        external
    {
        address tokenOwner = chonkyContract.ownerOf(_tokenId);
        require(
            tokenOwner == _msgSender() || _isTrustedCaller(),
            "Caller is not a trusted contract nor the owner of the given tokenId"
        );

        Prices memory traitPrice = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            require(
                traitPrice.addPrice + traitPrice.removePrice > 0,
                "Invalid trait"
            );
        }
        feedToken.spend(tokenOwner, uint256(traitPrice.removePrice));
        freeFormTraits[_tokenId][_traitName] = 0;
    }

    // INTERNAL FUNCTIONS

    function _isTrustedCaller() internal view returns (bool) {
        return traitModifiersList[_msgSender()];
    }

    function _quickSortArrayOfTuples(
        uint256[2][] memory arr,
        uint256 left,
        uint256 right
    ) internal pure {
        unchecked {
            uint256 i = left;
            uint256 j = right;
            if (i == j) return;
            uint256 pivot = arr[uint256(left + (right - left) / 2)][1];
            while (i <= j) {
                while (arr[uint256(i)][1] < pivot) i++;
                while (pivot < arr[uint256(j)][1]) j--;
                if (i <= j) {
                    (arr[uint256(i)], arr[uint256(j)]) = (
                        arr[uint256(j)],
                        arr[uint256(i)]
                    );
                    i++;
                    if (j == 0) break;
                    j--;
                }
            }
            if (left < j) _quickSortArrayOfTuples(arr, left, j);
            if (i < right) _quickSortArrayOfTuples(arr, i, right);
        }
    }

    function _requireValidTrait(bytes32 _traitName) internal view {
        require(_isValidTrait(_traitName), "This trait does not exist");
    }

    function _requireValidCategoricalTrait(
        bytes32 _traitName,
        bytes32 _traitValue
    ) internal view {
        require(
            _isValidCategoricalTrait(_traitName, _traitValue),
            "This trait does not exist"
        );
    }

    function _isValidTrait(bytes32 _traitName) internal view returns (bool) {
        Prices memory existingPrices = traitPrices[_traitName];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            return existingPrices.addPrice + existingPrices.removePrice > 0;
        }
    }

    function _isValidCategoricalTrait(bytes32 _traitName, bytes32 _traitValue)
        internal
        view
        returns (bool)
    {
        Prices memory existingPrices = categoricalTraitPrices[_traitName][
            _traitValue
        ];
        // addPrice and removePrice are set by contract owner, will never overflow
        unchecked {
            return existingPrices.addPrice + existingPrices.removePrice > 0;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import {ChonkyChkns} from "./ChonkyChkns.sol";

interface ITokenURIManager {
    function setBaseUri(string calldata _baseUri) external;

    function baseURI() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ChonkyChknsTokenURIManager {
    using Strings for uint256;

    ChonkyChkns public chonkyContract;
    string private _baseURI;

    constructor(address _chonkyChkns) {
        chonkyContract = ChonkyChkns(_chonkyChkns);
    }

    modifier onlyContract() {
        require(
            msg.sender == address(chonkyContract),
            "Only callable by ChonkyChkns contract"
        );
        _;
    }

    function setBaseUri(string calldata _newBaseURI) external onlyContract {
        _baseURI = _newBaseURI;
    }

    function baseURI() external view onlyContract returns (string memory) {
        return _baseURI;
    }

    function tokenURI(uint256 tokenId)
        external
        view
        onlyContract
        returns (string memory)
    {
        // TokenURI branches off depending on token type of tokenId
        string memory tokenType = chonkyContract.isGenesis(tokenId)
            ? "genesis"
            : "standard";

        return
            bytes(_baseURI).length != 0
                ? string(
                    abi.encodePacked(
                        _baseURI,
                        tokenType,
                        "/",
                        tokenId.toString()
                    )
                )
                : "";
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {ChonkyChkns} from "./ChonkyChkns.sol";

interface IFeedToken {
    function updateFeedCountOnMint(address _user) external;

    function updateFeedCountOnTransfer(address _from, address _to) external;

    function updateFeedCount(address _user) external;

    function getTotalClaimable(address _user) external view returns (uint256);

    function burn(address _from, uint256 _amount) external;

    function reward(address _user, uint256 _amount) external;

    function spend(address _user, uint256 _amount) external;
}

contract FeedToken is ERC20("Feed", "FEED"), Ownable {
    // CONSTANTS
    uint256 public constant SECONDS_IN_DAY = 86400;

    // settable configs
    uint256 public GENESIS_RATE = 5 ether; // feed / day generated by genesis tokens
    uint256 public STANDARD_RATE = 1 ether; // feed per day generated by normal tokens
    uint256 public FEED_PRODUCTION_END_DATE; // date feed production ends

    mapping(address => uint256) public feedCount;
    mapping(address => uint256) public lastUpdate;

    ChonkyChkns public chonkyContract;

    // Map of contracts that have the ability to modify feed balances on tokens,
    // to perform tasks such as:
    // - FEED giveaways
    // - spending FEED to buy ChonkyChkns traits (ChonkyChkns's CustomTraitManager will be on the list)
    mapping(address => bool) public balanceModifiersList;

    constructor(address _chonkyChkns) {
        chonkyContract = ChonkyChkns(_chonkyChkns);
        addTrustedContract(_chonkyChkns);
        FEED_PRODUCTION_END_DATE = block.timestamp + 5 * 365 * 24 * 60 * 60;
    }

    function addTrustedContract(address _contract) public onlyOwner {
        balanceModifiersList[_contract] = true;
    }

    function removeTrustedContract(address _contract) external onlyOwner {
        balanceModifiersList[_contract] = false;
    }

    // FEED COUNT UPDATE FUNCTIONS

    // Called specifically when minting tokens.
    function updateFeedCountOnMint(address _user) external {
        require(_msgSender() == address(chonkyContract), "Can't call this");
        uint256 time = Math.min(block.timestamp, FEED_PRODUCTION_END_DATE);
        _updateFeedCountAtTime(_user, time);
    }

    // Called specfically when a token is transferring ownership
    function updateFeedCountOnTransfer(address _from, address _to) external {
        require(_msgSender() == address(chonkyContract), "Can't call this");
        uint256 time = Math.min(block.timestamp, FEED_PRODUCTION_END_DATE);
        _updateFeedCountAtTime(_from, time);
        if (_to != address(0)) {
            _updateFeedCountAtTime(_to, time);
        }
    }

    // Can be called at any time to have getTotalClaimable() amount reflected in feedCount() balance.
    function updateFeedCount(address _user) external {
        uint256 time = Math.min(block.timestamp, FEED_PRODUCTION_END_DATE);
        _updateFeedCountAtTime(_user, time);
    }

    // WITHDRAW FUNCTION

    // Withdraw (mint) the current feed balance of a particular address to that address.
    // Pending claimable portion of feed balance is withdrawn as well.
    function withdrawFeed(address _to) external {
        require(_msgSender() == _to, "Can only be called by owner of withdrawing address");
        uint256 feedToBeClaimed = getTotalClaimable(_to);
        if (feedToBeClaimed > 0) {
            feedCount[_to] = 0;
            lastUpdate[_to] = Math.min(
                block.timestamp,
                FEED_PRODUCTION_END_DATE
            );
            _mint(_to, feedToBeClaimed);
        }
    }

    // FUNCTIONS CALLABLE BY TRUSTED CONTRACTS (used for FEED gamification features)

    function reward(address _user, uint256 _amount) external {
        require(_isTrustedCaller(), "Can only be called by trusted address");
        feedCount[_user] = getTotalClaimable(_user) + _amount;
        lastUpdate[_user] = Math.min(block.timestamp, FEED_PRODUCTION_END_DATE);
    }

    function spend(address _user, uint256 _amount) external {
        require(_isTrustedCaller(), "Can only be called by trusted address");

        uint256 currentBalance = getTotalClaimable(_user);
        // Amount in excess of user's feedCount balance that needs to be burned from their wallet.
        uint256 feedCountDiff = _amount - Math.min(_amount, currentBalance);
        if (feedCountDiff > 0) {
            _burn(_user, feedCountDiff);
        }
        // Set feed count based on remaining amount that needs to be spent from balance
        feedCount[_user] = currentBalance + feedCountDiff - _amount;
        lastUpdate[_user] = Math.min(block.timestamp, FEED_PRODUCTION_END_DATE);
    }

    function burn(address _from, uint256 _amount) external {
        require(_isTrustedCaller(), "Can only be called by trusted address");
        _burn(_from, _amount);
    }

    // VIEW FUNCTIONS

    function getTotalClaimable(address _user) public view returns (uint256) {
        // lastUpdate[_user] is upper bounded by FEED_PRODUCTION_END_DATE - this will not underflow
        uint256 timeSinceLastUpdate;
        unchecked {
            timeSinceLastUpdate =
                Math.min(block.timestamp, FEED_PRODUCTION_END_DATE) -
                lastUpdate[_user];
        }

        uint256 numGenesisOwned = chonkyContract.numGenesisOwned(_user);
        uint256 numStandardOwned = chonkyContract.numStandardOwned(_user);
        uint256 genesisPending = numGenesisOwned > 0
            ? _getPendingFeed(
                numGenesisOwned,
                GENESIS_RATE,
                timeSinceLastUpdate
            )
            : 0;
        uint256 normalPending = numStandardOwned > 0
            ? _getPendingFeed(
                numStandardOwned,
                STANDARD_RATE,
                timeSinceLastUpdate
            )
            : 0;
        return feedCount[_user] + genesisPending + normalPending;
    }

    // INTERNAL FUNCTIONS

    function _isTrustedCaller() internal view returns (bool) {
        return balanceModifiersList[_msgSender()];
    }

    function _updateFeedCountAtTime(address _user, uint256 time) internal {
        uint256 lastUpdateTime = lastUpdate[_user];
        if (lastUpdateTime > 0) {
            uint256 numGenesisOwned = chonkyContract.numGenesisOwned(_user);
            uint256 numStandardOwned = chonkyContract.numStandardOwned(_user);
            uint256 timeSinceLastUpdate = time - lastUpdateTime;
            uint256 totalPending;
            // Non-zero conditionals - Slight optimization for those only holding one token type
            if (numGenesisOwned > 0) {
                totalPending += _getPendingFeed(
                    numGenesisOwned,
                    GENESIS_RATE,
                    timeSinceLastUpdate
                );
            }
            if (numStandardOwned > 0) {
                totalPending += _getPendingFeed(
                    numStandardOwned,
                    STANDARD_RATE,
                    timeSinceLastUpdate
                );
            }
            feedCount[_user] += totalPending;
        }
        lastUpdate[_user] = time;
    }

    // get number of feed pending given number of chkn tokens, feed rate per day, time elapsed
    function _getPendingFeed(
        uint256 _numTokens,
        uint256 _rate,
        uint256 _timeElapsed
    ) internal pure returns (uint256) {
        return _numTokens * ((_rate * _timeElapsed) / SECONDS_IN_DAY);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
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
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
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
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721AQueryable.sol';
import '../ERC721A.sol';

/**
 * @title ERC721A Queryable
 * @dev ERC721A subclass with convenience query functions.
 */
abstract contract ERC721AQueryable is ERC721A, IERC721AQueryable {
    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) public view override returns (TokenOwnership memory) {
        TokenOwnership memory ownership;
        if (tokenId < _startTokenId() || tokenId >= _currentIndex) {
            return ownership;
        }
        ownership = _ownerships[tokenId];
        if (ownership.burned) {
            return ownership;
        }
        return _ownershipOf(tokenId);
    }

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view override returns (TokenOwnership[] memory) {
        unchecked {
            uint256 tokenIdsLength = tokenIds.length;
            TokenOwnership[] memory ownerships = new TokenOwnership[](tokenIdsLength);
            for (uint256 i; i != tokenIdsLength; ++i) {
                ownerships[i] = explicitOwnershipOf(tokenIds[i]);
            }
            return ownerships;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view override returns (uint256[] memory) {
        unchecked {
            if (start >= stop) revert InvalidQueryRange();
            uint256 tokenIdsIdx;
            uint256 stopLimit = _currentIndex;
            // Set `start = max(start, _startTokenId())`.
            if (start < _startTokenId()) {
                start = _startTokenId();
            }
            // Set `stop = min(stop, _currentIndex)`.
            if (stop > stopLimit) {
                stop = stopLimit;
            }
            uint256 tokenIdsMaxLength = balanceOf(owner);
            // Set `tokenIdsMaxLength = min(balanceOf(owner), stop - start)`,
            // to cater for cases where `balanceOf(owner)` is too big.
            if (start < stop) {
                uint256 rangeLength = stop - start;
                if (rangeLength < tokenIdsMaxLength) {
                    tokenIdsMaxLength = rangeLength;
                }
            } else {
                tokenIdsMaxLength = 0;
            }
            uint256[] memory tokenIds = new uint256[](tokenIdsMaxLength);
            if (tokenIdsMaxLength == 0) {
                return tokenIds;
            }
            // We need to call `explicitOwnershipOf(start)`,
            // because the slot at `start` may not be initialized.
            TokenOwnership memory ownership = explicitOwnershipOf(start);
            address currOwnershipAddr;
            // If the starting slot exists (i.e. not burned), initialize `currOwnershipAddr`.
            // `ownership.address` will not be zero, as `start` is clamped to the valid token ID range.
            if (!ownership.burned) {
                currOwnershipAddr = ownership.addr;
            }
            for (uint256 i = start; i != stop && tokenIdsIdx != tokenIdsMaxLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            // Downsize the array to fit.
            assembly {
                mstore(tokenIds, tokenIdsIdx)
            }
            return tokenIds;
        }
    }

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view override returns (uint256[] memory) {
        unchecked {
            uint256 tokenIdsIdx;
            address currOwnershipAddr;
            uint256 tokenIdsLength = balanceOf(owner);
            uint256[] memory tokenIds = new uint256[](tokenIdsLength);
            TokenOwnership memory ownership;
            for (uint256 i = _startTokenId(); tokenIdsIdx != tokenIdsLength; ++i) {
                ownership = _ownerships[i];
                if (ownership.burned) {
                    continue;
                }
                if (ownership.addr != address(0)) {
                    currOwnershipAddr = ownership.addr;
                }
                if (currOwnershipAddr == owner) {
                    tokenIds[tokenIdsIdx++] = i;
                }
            }
            return tokenIds;
        }
    }
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import './IERC721A.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 *
 * Assumes that an owner cannot have more than 2**64 - 1 (max value of uint64) of supply.
 *
 * Assumes that the maximum token id cannot exceed 2**256 - 1 (max value of uint256).
 */
contract ERC721A is Context, ERC165, IERC721A {
    using Address for address;
    using Strings for uint256;

    // The tokenId of the next token to be minted.
    uint256 internal _currentIndex;

    // The number of tokens burned.
    uint256 internal _burnCounter;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) internal _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) private _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    /**
     * To change the starting tokenId, please override this function.
     */
    function _startTokenId() internal view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Burned tokens are calculated here, use _totalMinted() if you want to count just minted tokens.
     */
    function totalSupply() public view override returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex - _startTokenId() times
        unchecked {
            return _currentIndex - _burnCounter - _startTokenId();
        }
    }

    /**
     * Returns the total amount of tokens minted in the contract.
     */
    function _totalMinted() internal view returns (uint256) {
        // Counter underflow is impossible as _currentIndex does not decrement,
        // and it is initialized to _startTokenId()
        unchecked {
            return _currentIndex - _startTokenId();
        }
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
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    /**
     * Gas spent here starts off proportional to the maximum mint batch size.
     * It gradually moves to O(1) as tokens get transferred around in the collection over time.
     */
    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

        unchecked {
            if (_startTokenId() <= curr) if (curr < _currentIndex) {
                TokenOwnership memory ownership = _ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = _ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
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
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();

        string memory baseURI = _baseURI();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return '';
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721A.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner) if(!isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
        safeTransferFrom(from, to, tokenId, '');
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
        _transfer(from, to, tokenId);
        if (to.isContract()) if(!_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    /**
     * @dev Equivalent to `_safeMint(to, quantity, '')`.
     */
    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    /**
     * @dev Safely mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement
     *   {IERC721Receiver-onERC721Received}, which is called for each safe transfer.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            if (to.isContract()) {
                do {
                    emit Transfer(address(0), to, updatedIndex);
                    if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                        revert TransferToNonERC721ReceiverImplementer();
                    }
                } while (updatedIndex < end);
                // Reentrancy protection
                if (_currentIndex != startTokenId) revert();
            } else {
                do {
                    emit Transfer(address(0), to, updatedIndex++);
                } while (updatedIndex < end);
            }
            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 quantity) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        unchecked {
            _addressData[to].balance += uint64(quantity);
            _addressData[to].numberMinted += uint64(quantity);

            _ownerships[startTokenId].addr = to;
            _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;
            uint256 end = updatedIndex + quantity;

            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex < end);

            _currentIndex = updatedIndex;
        }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
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
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender());

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            _addressData[from].balance -= 1;
            _addressData[to].balance += 1;

            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = to;
            currSlot.startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
     * @dev Equivalent to `_burn(tokenId, false)`.
     */
    function _burn(uint256 tokenId) internal virtual {
        _burn(tokenId, false);
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
    function _burn(uint256 tokenId, bool approvalCheck) internal virtual {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
                isApprovedForAll(from, _msgSender()) ||
                getApproved(tokenId) == _msgSender());

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, from);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            AddressData storage addressData = _addressData[from];
            addressData.balance -= 1;
            addressData.numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            TokenOwnership storage currSlot = _ownerships[tokenId];
            currSlot.addr = from;
            currSlot.startTimestamp = uint64(block.timestamp);
            currSlot.burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            TokenOwnership storage nextSlot = _ownerships[nextTokenId];
            if (nextSlot.addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId != _currentIndex) {
                    nextSlot.addr = from;
                    nextSlot.startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            _burnCounter++;
        }
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '../IERC721A.sol';

/**
 * @dev Interface of an ERC721AQueryable compliant contract.
 */
interface IERC721AQueryable is IERC721A {
    /**
     * Invalid query range (`start` >= `stop`).
     */
    error InvalidQueryRange();

    /**
     * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
     *
     * If the `tokenId` is out of bounds:
     *   - `addr` = `address(0)`
     *   - `startTimestamp` = `0`
     *   - `burned` = `false`
     *
     * If the `tokenId` is burned:
     *   - `addr` = `<Address of owner before token was burned>`
     *   - `startTimestamp` = `<Timestamp when token was burned>`
     *   - `burned = `true`
     *
     * Otherwise:
     *   - `addr` = `<Address of owner>`
     *   - `startTimestamp` = `<Timestamp of start of ownership>`
     *   - `burned = `false`
     */
    function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

    /**
     * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
     * See {ERC721AQueryable-explicitOwnershipOf}
     */
    function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`,
     * in the range [`start`, `stop`)
     * (i.e. `start <= tokenId < stop`).
     *
     * This function allows for tokens to be queried if the collection
     * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
     *
     * Requirements:
     *
     * - `start` < `stop`
     */
    function tokensOfOwnerIn(
        address owner,
        uint256 start,
        uint256 stop
    ) external view returns (uint256[] memory);

    /**
     * @dev Returns an array of token IDs owned by `owner`.
     *
     * This function scans the ownership mapping and is O(totalSupply) in complexity.
     * It is meant to be called off-chain.
     *
     * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
     * multiple smaller scans if the collection is large enough to cause
     * an out-of-gas error (10K pfp collections should be fine).
     */
    function tokensOfOwner(address owner) external view returns (uint256[] memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721A is IERC721, IERC721Metadata {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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