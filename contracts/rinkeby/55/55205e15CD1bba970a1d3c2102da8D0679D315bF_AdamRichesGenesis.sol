// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "../../core/OmmgArtistContract.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'
//               _                   _____  _      _                  _____                      _
//      /\      | |                 |  __ \(_)    | |                / ____|                    (_)
//     /  \   __| | __ _ _ __ ___   | |__) |_  ___| |__   ___  ___  | |  __  ___ _ __   ___  ___ _ ___
//    / /\ \ / _` |/ _` | '_ ` _ \  |  _  /| |/ __| '_ \ / _ \/ __| | | |_ |/ _ \ '_ \ / _ \/ __| / __|
//   / ____ \ (_| | (_| | | | | | | | | \ \| | (__| | | |  __/\__ \ | |__| |  __/ | | |  __/\__ \ \__ \
//  /_/    \_\__,_|\__,_|_| |_| |_| |_|  \_\_|\___|_| |_|\___||___/  \_____|\___|_| |_|\___||___/_|___/

/// @title AdamRichesGenesis
/// @author NotAMeme aka nxlogixnick
/// @notice Adam Riches is an emerging British painter and draughtsman who primarily works in monochromatic color palette.
/// The characteristically stylized portraits and figurative works he creates are based on a sensitive response to the human condition,
/// ranging from furious expressive moments to poignant, melancholy reflections.
/// This is his NFT genesis collection. It contains excellent and rare pieces made in his famous drawing style.
/// Riches has taken part in numerous international exhibitions and artist residencies.
/// His works can be found in private collections around the world. Learn more at http://adamrichesartist.com/
contract AdamRichesGenesis is OmmgArtistContract {
    string public constant Artist = "Adam Riches";

    constructor(ArtistContractConfig memory config)
        OmmgArtistContract(config)
    {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// implementations
import "./impl/ERC721OmmgSnapshottable.sol";
import "./impl/OmmgAccessControl.sol";
import "./impl/ERC721Ommg.sol";

// interfaces
import "./interfaces/IERC721OmmgEnumerable.sol";
import "./interfaces/IERC721OmmgMetadata.sol";
import "./interfaces/IERC721OmmgMetadataFreezable.sol";

import "./interfaces/IOmmgAcquirable.sol";
import "./interfaces/IOmmgAcquirableWithToken.sol";
import "./interfaces/IOmmgEmergencyTokenRecoverable.sol";
import "./interfaces/IOmmgWithdrawable.sol";

import "./interfaces/IOmmgProvenanceHash.sol";
import "./interfaces/IOmmgMutablePrice.sol";
import "./interfaces/IOmmgSalePausable.sol";
import "./interfaces/IOmmgSupplyCap.sol";

import "./def/ArtistContractConfig.sol";
import "./def/CustomErrors.sol";

// utility
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

contract OmmgArtistContract is
    OmmgAccessControl,
    ERC721Ommg,
    ERC721OmmgSnapshottable,
    IERC721OmmgEnumerable,
    IERC721OmmgMetadata,
    IERC721OmmgMetadataFreezable,
    IOmmgSalePausable,
    IOmmgSupplyCap,
    IOmmgMutablePrice,
    IOmmgProvenanceHash,
    IOmmgAcquirable,
    IOmmgAcquirableWithToken,
    IOmmgEmergencyTokenRecoverable,
    IOmmgWithdrawable
{
    using Strings for uint256;
    using SafeERC20 for IERC20;

    /// @notice The identifying hash of the state administrator role. The state
    /// administrator role empowers the accounts that hold it to change state variables.
    /// @dev is just keccak256("CONTRACT_STATE_ADMIN")
    bytes32 public constant CONTRACT_STATE_ADMIN_ROLE =
        0x7e69b879a040173b938f56bb64bfa62bcd758c08ae6ed7cfdf7da6d7dba92708;

    /// @notice The identifying hash of the withdrawal administrator role. The
    /// role empowers the accounts that hold it to withdraw eth.
    /// @dev is just keccak256("CONTRACT_WITHDRAW_ADMIN")
    bytes32 public constant CONTRACT_WITHDRAW_ADMIN_ROLE =
        0x7c13537556c77ef3fb98601c3356887ddbe5991e86dc065741ce77e1dd2554a3;

    /// @notice The identifying hash of the free acquire role. The role empowers
    /// the accounts that hold it to mint tokens for free, for example for marketing purposes.
    /// @dev is just keccak256("CONTRACT_FREE_ACQUIRE")
    bytes32 public constant CONTRACT_FREE_ACQUIRE_ROLE =
        0xfdd7b2ba629c0a0b84029cda831836222e5708c95d3e782c0762066b472dad0e;

    /// @dev the immutable max supply cap of this token
    uint256 private immutable _supplyCap;
    /// @dev the mutable public mint price of this token
    uint256 private _price;
    /// @dev the total number of shares held by all shareholders
    uint256 private _totalShares;

    /// @dev indicates whether the token metadata is revealed
    bool private _revealed;
    /// @dev indicates whether the public sale is active
    bool private _saleIsActive;
    /// @dev indicates whether the token metadata is frozen
    bool private _metadataFrozen;
    /// @dev indicates whether the provenance hash is frozen
    bool private _provenanceFrozen;

    /// @dev the name of the token contract
    string private _name;
    /// @dev the symbol of the token contract
    string private _symbol;
    /// @dev the base URI of the token metadata which is prepended to the tokenID,
    /// unless overridden for a token. Only shows when the token is revealed
    string private _baseURI;
    /// @dev the URI of the token metadata for the unrevealed state
    string private _unrevealedTokenURI;
    /// @dev the provenance hash
    string private _provenanceHash;

    /// @dev optional mapping for token URIs to override the default behavior
    mapping(uint256 => string) private _tokenURIs;
    /// @dev whether the token URI for this item is a full override or simply gets appended to the `_baseURI`
    mapping(uint256 => bool) private _overrideFullURI;
    /// @dev Optional mapping for token reveal override, to indicate if an individual token has been revealed
    mapping(uint256 => bool) private _tokenRevealed;

    /// @dev the list of all shareholders who will receive eth when `withdraw` is called
    Shareholder[] private _shareholders;

    /// @dev the list of all configured tokens for the token discount mechanic
    IERC721[] private _configuredTokens;
    /// @dev a shorthand way to check if a token is configured
    mapping(IERC721 => bool) _tokenConfigured;
    /// @dev a mapping per configured token to indicate whether a specific token of that token contract has been used as
    /// a discount token already or not. It goes as follows: `_tokenIdsUsed[address][version][tokenId]`
    mapping(IERC721 => mapping(uint256 => mapping(uint256 => bool))) _tokenIdsUsed;
    /// @dev a mapping per configured token to its tokenIdsUsed version, needed for resets.
    mapping(IERC721 => uint256) _tokensUsedVersion;
    /// @dev a mapping per configured token to its used number.
    mapping(IERC721 => uint256) _tokensUsedNumber;
    /// @dev the configurations (price, active state) of a token discount
    mapping(IERC721 => TokenDiscountInfo) _tokenConfigurations;

    /// @notice Initializes the contract with the given configuration.
    /// @dev The config is the 'magic' behind this contract and the core of it's flexibility
    /// @param config the config of this contract as an {ArtistContractConfig} struct
    /// `config.name` will be the name of the contract.
    /// `config.symbol` will be the symbol.
    /// `config.withdrawAdmins` can be a list of users who will be assigned the `CONTRACT_WITHDRAW_ADMIN_ROLE` on construction.
    /// `config.stateAdmins` can be a list of users who will be assigned the `CONTRACT_STATE_ADMIN_ROLE` on construction.
    /// `config.mintForFree` can be a list of users who will be assigned the `CONTRACT_FREE_ACQUIRE_ROLE` on construction.
    /// `config.initialPrice` is the initial value assigned to the mutable price property.
    /// `config.supplyCap` is the immutable supply cap.
    /// `config.maxBatchSize` is the maximum number of tokens mintable in one transaction.
    /// `config.shareholders` is a list of the shareholders (see {Shareholder} struct).
    /// `config.tokenDiscounts` is a list of token discounts (see {TokenDiscount} struct) which will be usable to mint tokens.
    constructor(ArtistContractConfig memory config)
        ERC721Ommg(config.maxBatchSize)
    {
        _name = config.name;
        _symbol = config.symbol;
        _price = config.initialPrice;
        _supplyCap = config.supplyCap;

        _addRoleToAll(config.withdrawAdmins, CONTRACT_WITHDRAW_ADMIN_ROLE);
        _addRoleToAll(config.stateAdmins, CONTRACT_STATE_ADMIN_ROLE);
        _addRoleToAll(config.mintForFree, CONTRACT_FREE_ACQUIRE_ROLE);

        uint256 amount = config.shareholders.length;
        for (uint256 i = 0; i < config.shareholders.length; i++) {
            _addShareholder(config.shareholders[i]);
        }

        amount = config.tokenDiscounts.length;
        for (uint256 i = 0; i < amount; i++) {
            _addTokenDiscount(
                config.tokenDiscounts[i].tokenAddress,
                config.tokenDiscounts[i].config
            );
        }
    }

    /// @dev little helper function to add `role` to all accounts supplied
    function _addRoleToAll(address[] memory accounts, bytes32 role) private {
        uint256 len = accounts.length;
        if (len > 0) {
            for (uint256 i = 0; i < len; i++) {
                grantRole(role, accounts[i]);
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgWithdrawable //////////////////////////////////////////////

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function addShareholder(address walletAddress, uint256 shares)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _addShareholder(Shareholder(walletAddress, shares));
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function removeShareholder(address walletAddress)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (walletAddress == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                _removeShareholderAt(i);
                return;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`.
    /// @inheritdoc IOmmgWithdrawable
    function updateShareholder(address walletAddress, uint256 updatedShares)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (walletAddress == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                _shareholders[i].shares = updatedShares;
                emit ShareholderUpdated(walletAddress, updatedShares);
                return;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @dev Only callable by the contract owner or someone with the
    /// `CONTRACT_STATE_ADMIN_ROLE`. Reverts if the address is the null address,
    /// or if a shareholder with this address does not exist.
    /// @inheritdoc IOmmgWithdrawable
    function shares(address walletAddress)
        external
        view
        override
        returns (uint256)
    {
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == walletAddress) {
                return _shareholders[i].shares;
            }
        }
        revert ShareholderDoesNotExist(walletAddress);
    }

    /// @inheritdoc IOmmgWithdrawable
    function shareholders()
        external
        view
        override
        returns (Shareholder[] memory)
    {
        return _shareholders;
    }

    /// @inheritdoc IOmmgWithdrawable
    function totalShares() external view override returns (uint256) {
        return _totalShares;
    }

    function emergencyWithdraw()
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
        emit EmergencyWithdrawn(msg.sender, balance);
    }

    /// @inheritdoc IOmmgWithdrawable
    function withdraw()
        external
        override
        onlyOwnerOrRole(CONTRACT_WITHDRAW_ADMIN_ROLE)
    {
        uint256 balance = address(this).balance;
        uint256 totalShares_ = _totalShares;
        uint256 length = _shareholders.length;
        if (totalShares_ == 0 || length == 0) revert ZeroShares();
        uint256 amountPerShare = balance / totalShares_;
        for (uint256 i = 0; i < length; i++) {
            Shareholder memory sh = _shareholders[i];
            uint256 shareholderAmount = sh.shares * amountPerShare;
            payable(sh.addr).transfer(shareholderAmount);
            emit PaidOut(_msgSender(), sh.addr, shareholderAmount);
        }
        emit Withdrawn(_msgSender(), amountPerShare * _totalShares);
    }

    function _removeShareholderAt(uint256 index) private {
        uint256 length = _shareholders.length;
        Shareholder memory sh = _shareholders[index];
        for (uint256 i = index; i < length - 1; i++) {
            _shareholders[i] = _shareholders[i + 1];
        }
        _shareholders.pop();
        _totalShares -= sh.shares;
        emit ShareholderRemoved(sh.addr, sh.shares);
    }

    function _addShareholder(Shareholder memory shareholder) internal {
        if (shareholder.shares == 0) revert ZeroShares();
        if (shareholder.addr == address(0)) revert NullAddress();
        uint256 length = _shareholders.length;
        for (uint256 i = 0; i < length; i++) {
            if (_shareholders[i].addr == shareholder.addr)
                revert ShareholderAlreadyExists(shareholder.addr);
        }
        _shareholders.push(shareholder);
        _totalShares += shareholder.shares;
        emit ShareholderAdded(shareholder.addr, shareholder.shares);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgEmergencyTokenRecoverable /////////////////////////////////

    /// @inheritdoc IOmmgEmergencyTokenRecoverable
    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) public virtual override onlyOwnerOrRole(CONTRACT_WITHDRAW_ADMIN_ROLE) {
        if (receiver == address(0)) revert NullAddress();
        token.safeTransfer(receiver, amount);
        emit TokensRecovered(token, receiver, amount);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgAcquirableWithToken //////////////////////////////////////

    /// @inheritdoc IOmmgAcquirableWithToken
    function acquireWithToken(IERC721 token, uint256[] memory tokenIds)
        external
        payable
        override
    {
        uint256 amount = tokenIds.length;
        if (amount == 0) revert InvalidAmount(0, 1, maxBatchSize());
        _checkSupplyCapAndMaxBatch(amount);
        _revertIfTokenNotActive(token);
        uint256 price_ = _getTokenDiscountInfo(token).price;
        if (msg.value != price_ * amount) {
            revert InvalidMessageValue(msg.value, price_ * amount);
        }
        _checkTokenElegibility(msg.sender, token, tokenIds);
        _setTokensUsedForDiscount(token, tokenIds);
        _safeMint(msg.sender, amount);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokenDiscounts() external view returns (TokenDiscount[] memory) {
        uint256 len = _configuredTokens.length;
        IERC721[] memory localCopy = _configuredTokens;
        TokenDiscount[] memory td = new TokenDiscount[](len);
        for (uint256 i = 0; i < len; i++) {
            td[i] = TokenDiscount(
                localCopy[i],
                _tokenConfigurations[localCopy[i]]
            );
        }
        return td;
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountInfo memory config
    ) public onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE) {
        _addTokenDiscount(tokenAddress, config);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function setTokenDiscountActive(IERC721 tokenAddress, bool active)
        external
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        if (_tokenConfigurations[tokenAddress].active != active) {
            _tokenConfigurations[tokenAddress].active = active;
            emit TokenDiscountUpdated(
                tokenAddress,
                _tokenConfigurations[tokenAddress]
            );
        }
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokensUsedForDiscount(
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    ) external view virtual override returns (bool[] memory used) {
        _revertIfTokenNotConfigured(tokenAddress);
        uint256 length = tokenIds.length;
        bool[] memory arr = new bool[](length);
        for (uint256 i = 0; i < length; i++) {
            arr[i] = _tokenIdsUsed[tokenAddress][
                _tokensUsedVersion[tokenAddress]
            ][tokenIds[i]];
        }
        return arr;
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokenAmountUsedForDiscount(IERC721 tokenAddress)
        external
        view
        returns (uint256 amount)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        return _tokensUsedNumber[tokenAddress];
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function removeTokenDiscount(IERC721 tokenAddress)
        external
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        uint256 length = _configuredTokens.length;
        for (uint256 i = 0; i < length; i++) {
            if (_configuredTokens[i] == tokenAddress) {
                _tokenConfigured[tokenAddress] = false;
                _popTokenConfigAt(i);
                emit TokenDiscountRemoved(tokenAddress);
                return;
            }
        }
        revert TokenNotConfigured(tokenAddress);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountInfo memory)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        return _getTokenDiscountInfo(tokenAddress);
    }

    function _getTokenDiscountInfo(IERC721 tokenAddress)
        internal
        view
        returns (TokenDiscountInfo memory)
    {
        return _tokenConfigurations[tokenAddress];
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountInfo memory config
    ) external override onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE) {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokenConfigurations[tokenAddress] = config;
        emit TokenDiscountUpdated(tokenAddress, config);
    }

    /// @inheritdoc IOmmgAcquirableWithToken
    function resetTokenDiscountUsed(IERC721 tokenAddress)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revertIfTokenNotConfigured(tokenAddress);
        _tokensUsedVersion[tokenAddress]++;
        _tokensUsedNumber[tokenAddress] = 0;
        emit TokenDiscountReset(tokenAddress);
    }

    function _checkTokenElegibility(
        address account,
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    ) internal view {
        uint256 length = tokenIds.length;
        if (
            _tokensUsedNumber[tokenAddress] + length >
            _tokenConfigurations[tokenAddress].supply
        )
            revert TokenSupplyExceeded(
                tokenAddress,
                _tokenConfigurations[tokenAddress].supply
            );
        for (uint256 i = 0; i < length; i++) {
            uint256 tokenId = tokenIds[i];
            // try catch for reverts in ownerOf
            try tokenAddress.ownerOf(tokenId) returns (address owner) {
                if (owner != account)
                    revert TokenNotOwned(tokenAddress, tokenId);
            } catch {
                revert TokenNotOwned(tokenAddress, tokenId);
            }
            if (
                _tokenIdsUsed[tokenAddress][_tokensUsedVersion[tokenAddress]][
                    tokenId
                ]
            ) revert TokenAlreadyUsed(tokenAddress, tokenId);
        }
    }

    function _popTokenConfigAt(uint256 index) private {
        uint256 length = _configuredTokens.length;
        if (index >= length) return;
        for (uint256 i = index; i < length - 1; i++) {
            _configuredTokens[i] = _configuredTokens[i + 1];
        }
        _configuredTokens.pop();
    }

    // no checks
    function _setTokensUsedForDiscount(
        IERC721 token,
        uint256[] memory tokenIds
    ) internal {
        uint256 length = tokenIds.length;
        for (uint256 i = 0; i < length; i++) {
            _tokenIdsUsed[token][_tokensUsedVersion[token]][
                tokenIds[i]
            ] = true;
            emit TokenUsedForDiscount(msg.sender, token, tokenIds[i]);
        }
        _tokensUsedNumber[token] += length;
    }

    function _addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountInfo memory config
    ) internal {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (_tokenConfigured[tokenAddress])
            revert TokenAlreadyConfigured(tokenAddress);
        _tokenConfigured[tokenAddress] = true;
        _tokensUsedVersion[tokenAddress]++;
        _tokenConfigurations[tokenAddress] = config;
        _configuredTokens.push(tokenAddress);
        emit TokenDiscountAdded(tokenAddress, config);
    }

    function _revertIfTokenNotConfigured(IERC721 tokenAddress) internal view {
        if (address(tokenAddress) == address(0)) revert NullAddress();
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
    }

    function _revertIfTokenNotActive(IERC721 tokenAddress) internal view {
        if (!_tokenConfigured[tokenAddress])
            revert TokenNotConfigured(tokenAddress);
        if (!_tokenConfigurations[tokenAddress].active)
            revert TokenNotActive(tokenAddress);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgProvenanceHash ///////////////////////////////////////////

    function whenProvenanceIsNotFrozen() private view {
        if (_provenanceFrozen) revert ProvenanceHashIsFrozen();
    }

    /// @inheritdoc IOmmgProvenanceHash
    function provenanceHash() public view override returns (string memory) {
        return _provenanceHash;
    }

    /// @inheritdoc IOmmgProvenanceHash
    function provenanceFrozen() public view override returns (bool) {
        return _provenanceFrozen;
    }

    /// @inheritdoc IOmmgProvenanceHash
    function setProvenanceHash(string memory provenanceHash_)
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        whenProvenanceIsNotFrozen();
        _provenanceHash = provenanceHash_;
        emit ProvenanceHashSet(_provenanceHash);
    }

    /// @inheritdoc IOmmgProvenanceHash
    function freezeProvenance()
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        whenProvenanceIsNotFrozen();
        _provenanceFrozen = true;
        emit ProvenanceHashFrozen();
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgMutablePrice //////////////////////////////////////////////

    /// @inheritdoc IOmmgMutablePrice
    function price() public view override returns (uint256) {
        return _price;
    }

    /// @inheritdoc IOmmgMutablePrice
    function setPrice(uint256 price)
        public
        virtual
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _price = price;
        emit PriceChanged(_price);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgSupplyCap /////////////////////////////////////////////////

    /// @inheritdoc IOmmgSupplyCap
    function supplyCap() public view virtual override returns (uint256) {
        return _supplyCap;
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgSalePausable //////////////////////////////////////////////

    /// @inheritdoc IOmmgSalePausable
    function saleIsActive() public view override returns (bool) {
        return _saleIsActive;
    }

    /// @inheritdoc IOmmgSalePausable
    function setSaleIsActive(bool newValue)
        public
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _saleIsActive = newValue;
        emit SaleIsActiveSet(_saleIsActive);
    }

    modifier whenSaleIsActive() {
        if (!_saleIsActive) {
            revert SaleNotActive();
        }
        _;
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IOmmgAcquirable ////////////////////////////////////////////////

    /// @inheritdoc IOmmgAcquirable
    function acquireForCommunity(address receiver, uint256 amount)
        external
        override
        onlyOwnerOrRole(CONTRACT_FREE_ACQUIRE_ROLE)
    {
        _checkSupplyCapAndMaxBatch(amount);
        _safeMint(receiver, amount);
    }

    /// @inheritdoc IOmmgAcquirable
    function acquire(uint256 amount)
        external
        payable
        override
        whenSaleIsActive
    {
        _checkSupplyCapAndMaxBatch(amount);
        if (msg.value != price() * amount) {
            revert InvalidMessageValue(msg.value, price() * amount);
        }

        _safeMint(msg.sender, amount);
    }

    function _checkSupplyCapAndMaxBatch(uint256 amount) private view {
        if (amount > maxBatchSize() || amount == 0) {
            revert InvalidAmount(amount, 1, maxBatchSize());
        }
        if (_currentIndex() + amount > supplyCap()) {
            // +1 because 0 based index
            revert AmountExceedsCap(
                amount,
                supplyCap() - _currentIndex(),
                supplyCap()
            );
        }
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgEnumerable //////////////////////////////////////////

    /// @inheritdoc IERC721Enumerable
    function totalSupply() public view override returns (uint256) {
        return _currentIndex() - _burned();
    }

    /// @inheritdoc IERC721Enumerable
    function tokenByIndex(uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index >= totalSupply())
            revert IndexOutOfBounds(index, totalSupply());
        if (_burned() == 0) return index + 1;
        uint256 j = 0;
        uint256 maxIndex = _currentIndex();
        for (uint256 i = 0; i < maxIndex; i++) {
            if (j == index) return i;
            if (_exists(i)) j++;
        }
        revert OperationFailed();
    }

    /// @inheritdoc IERC721Enumerable
    function tokenOfOwnerByIndex(address owner, uint256 index)
        public
        view
        override
        returns (uint256)
    {
        if (index > balanceOf(owner))
            revert IndexOutOfBounds(index, balanceOf(owner));

        uint256 limit = _currentIndex();
        uint256 tokenIdsIdx = 0;
        for (uint256 i = 0; i < limit; i++) {
            if (_exists(i)) {
                if (_ownershipOf(i).addr == owner) {
                    if (tokenIdsIdx == index) {
                        return i;
                    }
                    tokenIdsIdx++;
                }
            }
        }
        revert OperationFailed();
    }

    /// @inheritdoc IERC721OmmgEnumerable
    function exists(uint256 tokenId) public view override returns (bool) {
        return _exists(tokenId);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgMetadata ////////////////////////////////////////////

    /// @inheritdoc IERC721Metadata
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /// @inheritdoc IERC721Metadata
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function revealed() public view returns (bool) {
        return _revealed;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function tokenRevealed(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenRevealed[tokenId] || _revealed;
    }

    /// @inheritdoc IERC721OmmgMetadata
    function overridesFullURI(uint256 tokenId)
        public
        view
        override
        returns (bool)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _overrideFullURI[tokenId];
    }

    /// @inheritdoc IERC721Metadata
    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory _base = _baseURI;

        if (!_revealed && !_tokenRevealed[tokenId]) {
            return _unrevealedTokenURI;
        } else {
            if (bytes(_tokenURI).length > 0) {
                if (_overrideFullURI[tokenId]) return _tokenURI;
                else return string(abi.encodePacked(_base, _tokenURI));
            } else {
                if (bytes(_baseURI).length > 0)
                    return string(abi.encodePacked(_base, tokenId.toString()));
                else return _tokenURI;
            }
        }
    }

    /// @inheritdoc IERC721OmmgMetadata
    function reveal()
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _revealed = true;
        emit Revealed();
    }

    /// @inheritdoc IERC721OmmgMetadata
    function revealToken(uint256 tokenId)
        external
        override
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        _tokenRevealed[tokenId] = true;
        emit TokenRevealed(tokenId);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setTokenURI(
        uint256 tokenId,
        bool overrideBaseURI,
        bool overrideReveal,
        string memory _tokenURI
    )
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        _tokenURIs[tokenId] = _tokenURI;
        _overrideFullURI[tokenId] = overrideBaseURI;
        if (overrideReveal && !_tokenRevealed[tokenId]) {
            _tokenRevealed[tokenId] = true;
            emit TokenRevealed(tokenId);
        }
        emit SetTokenUri(tokenId, false, false, _tokenURI);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setUnrevealedTokenURI(string memory unrevealedTokenURI)
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _unrevealedTokenURI = unrevealedTokenURI;
        emit UnrevealedTokenUriSet(_unrevealedTokenURI);
    }

    /// @inheritdoc IERC721OmmgMetadata
    function setBaseURI(string memory baseURI)
        external
        override
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _baseURI = baseURI;
        emit SetBaseUri(baseURI);
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC721OmmgMetadataFreezable ///////////////////////////////////

    modifier whenMetadataIsNotFrozen() {
        if (_metadataFrozen) revert MetadataIsFrozen();
        _;
    }

    /// @inheritdoc IERC721OmmgMetadataFreezable
    function metadataFrozen() public view returns (bool) {
        return _metadataFrozen;
    }

    /// @inheritdoc IERC721OmmgMetadataFreezable
    function freezeMetadata()
        public
        virtual
        whenMetadataIsNotFrozen
        onlyOwnerOrRole(CONTRACT_STATE_ADMIN_ROLE)
    {
        _metadataFrozen = true;
        emit MetadataFrozen();
    }

    ////////////////////////////////////////////////////////////////////////////
    /////////// IERC165 ////////////////////////////////////////////////////////

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(
            IERC165,
            ERC721Ommg,
            ERC721OmmgSnapshottable,
            OmmgAccessControl
        )
        returns (bool)
    {
        return
            interfaceId == type(IOmmgEmergencyTokenRecoverable).interfaceId ||
            interfaceId == type(IERC721OmmgMetadataFreezable).interfaceId ||
            interfaceId == type(IOmmgAcquirableWithToken).interfaceId ||
            interfaceId == type(IERC721OmmgEnumerable).interfaceId ||
            interfaceId == type(IERC721OmmgMetadata).interfaceId ||
            interfaceId == type(IOmmgProvenanceHash).interfaceId ||
            interfaceId == type(IOmmgMutablePrice).interfaceId ||
            interfaceId == type(IOmmgWithdrawable).interfaceId ||
            interfaceId == type(IOmmgSalePausable).interfaceId ||
            interfaceId == type(IERC721Enumerable).interfaceId ||
            interfaceId == type(IOmmgAcquirable).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IOmmgSupplyCap).interfaceId ||
            interfaceId == type(IOmmgOwnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

import "./ERC721Ommg.sol";
import "../interfaces/IOmmgSnapshottable.sol";

abstract contract ERC721OmmgSnapshottable is IOmmgSnapshottable, ERC721Ommg {
    function snapshot() external view returns (TokenInfo[] memory) {
        uint256 curIndex = _currentIndex();
        TokenInfo[] memory tokenInfo = new TokenInfo[](curIndex);
        for (uint256 i = 1; i <= curIndex; i++) {
            if (_exists(i)) {
                tokenInfo[i - 1] = TokenInfo(i, TokenStatus.OWNED, ownerOf(i));
            } else {
                tokenInfo[i - 1] = TokenInfo(
                    i,
                    TokenStatus.BURNED,
                    address(this)
                );
            }
        }
        return tokenInfo;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgSnapshottable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

import "./OmmgOwnable.sol";
import "../interfaces/IOmmgAccessControl.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

/// @dev custom role access / ownable
abstract contract OmmgAccessControl is OmmgOwnable, IOmmgAccessControl {
    mapping(bytes32 => RoleData) private _roles;

    /// @dev Reverts if called by any account other than the owner or `role`
    /// @param role The role which is allowed access
    modifier onlyOwnerOrRole(bytes32 role) {
        if (owner() != _msgSender() && !_roles[role].members[_msgSender()])
            revert Unauthorized(_msgSender(), role);
        _;
    }

    /// @dev Reverts if called by any account other than the owner or `role`
    /// @param role The role which is allowed access
    modifier onlyRole(bytes32 role) {
        if (!_roles[role].members[_msgSender()])
            revert Unauthorized(_msgSender(), role);
        _;
    }

    /// @dev Returns `true` if `account` has been granted `role`.
    function hasRole(bytes32 role, address account)
        external
        view
        override
        returns (bool)
    {
        return _roles[role].members[account];
    }

    /// @dev Grants `role` to `account`.
    function grantRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _grantRole(role, account);
    }

    /// @dev Revokes `role` from `account`
    function revokeRole(bytes32 role, address account)
        public
        override
        onlyOwner
    {
        _revokeRole(role, account);
    }

    /// @dev Revokes `role` from the calling account.
    function renounceRole(bytes32 role) public override {
        _revokeRole(role, _msgSender());
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal {
        if (!_roles[role].members[account]) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal {
        if (_roles[role].members[account]) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "../def/CustomErrors.sol";

abstract contract ERC721Ommg is Context, ERC165, IERC721 {
    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
    }

    struct AddressData {
        uint128 balance;
        uint128 numberMinted;
    }

    uint256 private currentIndex = 1;
    uint256 private burned;

    uint256 private immutable _maxBatchSize;
    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See _ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) private _ownerOf;
    // Mapping owner address to address data
    mapping(address => AddressData) private _balanceOf;
    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;
    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(uint256 maxBatchSize_) {
        _maxBatchSize = maxBatchSize_;
    }

    function _currentIndex() internal view returns (uint256) {
        return currentIndex - 1;
    }

    function _burned() internal view returns (uint256) {
        return burned;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165, IERC165)
        returns (bool)
    {
        return
            interfaceId == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function maxBatchSize() public view returns (uint256) {
        return _maxBatchSize;
    }

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert NullAddress();
        return _balanceOf[owner].balance;
    }

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function _ownershipOf(uint256 tokenId)
        internal
        view
        returns (TokenOwnership memory)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        uint256 lowestTokenToCheck;
        if (tokenId >= _maxBatchSize) {
            lowestTokenToCheck = tokenId - _maxBatchSize + 1;
        }

        for (uint256 curr = tokenId; curr >= lowestTokenToCheck; curr--) {
            TokenOwnership memory ownership = _ownerOf[curr];
            if (ownership.addr != address(0)) return ownership;
        }
        revert OperationFailed();
    }

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
    ) public override {
        safeTransferFrom(from, to, tokenId, "");
    }

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
        bytes memory data
    ) public override {
        _transfer(from, to, tokenId);
        if (!_checkOnERC721Received(from, to, tokenId, data))
            revert SafeTransferFailed(from, to, tokenId);
    }

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
    ) public override {
        _transfer(from, to, tokenId);
    }

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
    function approve(address to, uint256 tokenId) external {
        address owner = ownerOf(tokenId);
        // is in ownerOf
        // if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        if (to == owner) revert ApprovalInvalid(_msgSender(), tokenId);

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender()))
            revert ApprovalUnauthorized(owner, to, tokenId, _msgSender());

        _approve(to, tokenId, owner);
    }

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId)
        public
        view
        returns (address operator)
    {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);
        return _tokenApprovals[tokenId];
    }

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
    function setApprovalForAll(address operator, bool approved)
        public
        override
    {
        if (operator == _msgSender())
            revert ApprovalForAllInvalid(_msgSender(), approved);

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator)
        public
        view
        override
        returns (bool)
    {
        return _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return
            tokenId > 0 &&
            tokenId < currentIndex &&
            _ownerOf[tokenId].addr != address(this);
    }

    // function _hasBeenMinted(uint256 tokenId) internal view returns (bool) {
    //     return tokenId < currentIndex;
    // }

    // function _ownerAddress(uint256 tokenId) internal view returns (address) {
    //     return _ownerOf[tokenId].addr;
    // }

    function _burn(uint256 tokenId) internal {
        if (!_exists(tokenId)) revert TokenDoesNotExist(tokenId);

        TokenOwnership memory owner = _ownershipOf(tokenId);

        _beforeTokenTransfers(owner.addr, address(this), tokenId, 1);

        // Clear approvals
        _approve(address(0), tokenId, owner.addr);

        _balanceOf[owner.addr].balance -= 1;
        _ownerOf[tokenId].addr = address(this);
        burned++;
        uint256 nextTokenId = tokenId + 1;
        if (_ownerOf[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerOf[nextTokenId] = TokenOwnership(
                    owner.addr,
                    owner.startTimestamp
                );
            }
        }
        emit Transfer(owner.addr, address(this), tokenId);

        _afterTokenTransfers(owner.addr, address(this), tokenId, 1);
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, "");
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` cannot be larger than the max batch size.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory data
    ) internal {
        uint256 startTokenId = currentIndex;
        if (to == address(0)) revert NullAddress();
        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
        // TODO can this even happen?
        // if (_exists(startTokenId)) revert TokenAlreadyExists(startTokenId);

        if (quantity > _maxBatchSize || quantity == 0)
            revert InvalidAmount(quantity, 1, _maxBatchSize);

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

        AddressData memory oldData = _balanceOf[to];
        _balanceOf[to] = AddressData(
            oldData.balance + uint128(quantity),
            oldData.numberMinted + uint128(quantity)
        );
        _ownerOf[startTokenId] = TokenOwnership(to, uint64(block.timestamp));
        uint256 updatedIndex = startTokenId;
        for (uint256 i = 0; i < quantity; i++) {
            emit Transfer(address(0), to, updatedIndex);
            if (!_checkOnERC721Received(address(0), to, updatedIndex, data))
                revert SafeTransferFailed(address(0), to, updatedIndex);
            updatedIndex++;
        }
        currentIndex = updatedIndex;
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
        if (to == address(0)) revert NullAddress();

        TokenOwnership memory prevOwner = _ownershipOf(tokenId);

        if (prevOwner.addr != from)
            revert TransferUnauthorized(
                _msgSender(),
                from,
                to,
                tokenId,
                prevOwner.addr
            );

        if (
            _msgSender() != prevOwner.addr &&
            getApproved(tokenId) != _msgSender() &&
            !isApprovedForAll(prevOwner.addr, _msgSender())
        )
            revert TransferUnauthorized(
                _msgSender(),
                from,
                to,
                tokenId,
                prevOwner.addr
            );

        _beforeTokenTransfers(from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId, prevOwner.addr);

        _balanceOf[from].balance -= 1;
        _balanceOf[to].balance += 1;
        _ownerOf[tokenId] = TokenOwnership(to, uint64(block.timestamp));

        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
        uint256 nextTokenId = tokenId + 1;
        if (_ownerOf[nextTokenId].addr == address(0)) {
            if (_exists(nextTokenId)) {
                _ownerOf[nextTokenId] = TokenOwnership(
                    prevOwner.addr,
                    prevOwner.startTimestamp
                );
            }
        }
        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
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
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TargetNonERC721Receiver(to);
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
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     */
    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        address from,
        address to,
        uint256 tokenId,
        uint256 quantity
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IERC721OmmgEnumerable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721Enumerable} and adds
/// functionality to check if a token exists.
interface IERC721OmmgEnumerable is IERC721Enumerable {
    /// @notice Returns whether the token `tokenId` exists.
    /// @param tokenId the token id to check
    /// @return exists whether the token exists
    function exists(uint256 tokenId) external view returns (bool exists);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IERC721OmmgMetadata
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721Metadata} and adds
/// functionality to reveal tokens as well as add more logic to the token uri.
interface IERC721OmmgMetadata is IERC721Metadata {
    /// @notice Triggers when the base uri is updated.
    /// @param baseURI the new base uri
    event SetBaseUri(string indexed baseURI);

    /// @notice Triggers when the URI for a token is overridden.
    /// @param tokenId the token where the URI is overridden
    /// @param fullOverride fullOverride whether the override overrides the base URI or is appended
    /// @param tokenRevealedOverride whether the token should be individually revealed
    /// @param tokenURI the override token URI
    event SetTokenUri(
        uint256 indexed tokenId,
        bool fullOverride,
        bool tokenRevealedOverride,
        string indexed tokenURI
    );
    /// @notice Triggers when the unrevealed token uri is updated.
    /// @param unrevealedTokenURI the new unrevealed token uri
    event UnrevealedTokenUriSet(string indexed unrevealedTokenURI);

    /// @notice Triggers when the collection is revealed.
    event Revealed();

    /// @notice Triggers when a singular token is revealed.
    /// @param tokenId the token which is revealed
    event TokenRevealed(uint256 indexed tokenId);

    /// @notice Returns whether the collection as a whole is revealed.
    /// @param revealed whether the collection is revealed
    function revealed() external view returns (bool revealed);

    /// @notice Reveals the collection. Emits {Revealed}.
    function reveal() external;

    /// @notice Reveals an individual token. Fails if the token does not exist.
    /// Emits {TokenRevealed}.
    /// @param tokenId the id of the revealed token
    function revealToken(uint256 tokenId) external;

    /// @notice Overrides the token URI for an individual token and optionally sets whether the base uri
    /// should be overridden too, and whether the token should be revealed individually. Emits {SetTokenUri}
    /// and {TokenRevealed} if it is revealed in the process.
    /// @param tokenId the id of the token to override these things for
    /// @param overrideBaseURI whether the base URI should be overridden or `_tokenURI` should be
    /// appended to it
    /// @param overrideReveal whether the token should be individually revealed
    /// @param _tokenURI the new token URI
    function setTokenURI(
        uint256 tokenId,
        bool overrideBaseURI,
        bool overrideReveal,
        string memory _tokenURI
    ) external;

    /// @notice Sets the unrevealed token uri. Emits {UnrevealedTokenUriSet}.
    /// @param unrevealedTokenURI the new unrevealed token URI
    function setUnrevealedTokenURI(string memory unrevealedTokenURI) external;

    /// @notice Sets the base URI. Emits {SetBaseURI}.
    /// @param baseURI the new base uri
    function setBaseURI(string memory baseURI) external;

    /// @notice Returns whether the token `tokenId` overrides the full base URI.
    /// @param tokenId the id of the token to check
    /// @return overridesBaseURI whether the token overrides the full base URI
    function overridesFullURI(uint256 tokenId)
        external
        view
        returns (bool overridesBaseURI);

    /// @notice Returns whether the token `tokenId` is revealed.
    /// @param tokenId the id of the token to check
    /// @return revealed whether the token is revealed
    function tokenRevealed(uint256 tokenId)
        external
        view
        returns (bool revealed);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IERC721OmmgMetadataFreezable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves as an extension to {IERC721OmmgMetadata} and adds
/// functionality to freeze the metadata, effectively making it immutable.
interface IERC721OmmgMetadataFreezable {
    error MetadataIsFrozen();
    /// @notice Triggers when the metadata is frozen
    event MetadataFrozen();

    /// @notice Returns whether the metadata is frozen.
    /// @return frozen whether the metadata is frozen or not
    function metadataFrozen() external view returns (bool frozen);

    /// @notice Freezes the metadata to effectively turn it immutable. Emits {MetadataFrozen}.
    /// Fails if the metadata is already frozen.
    function freezeMetadata() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAcquirable
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for the simple minting functionality of the OMMG Artist Contracts.
interface IOmmgAcquirable {
    /// @notice Mints `amount` NFTs of this contract. The more minted at once, the cheaper gas is for each token.
    /// However, the upper limit for `amount` can be queried via `maxBatchSize`. Fails if the user does not provide
    /// the correct amount of eth, if sale is paused, if the supply catch is reached, or if `maxBatchSize` is exceeded.
    /// @param amount the amount of NFTs to mint.
    function acquire(uint256 amount) external payable;

    /// @notice Mints `amount` NFTs of this contract to `receiver`. The more minted at once, the cheaper gas is for each token.
    /// However, the upper limit for `amount` can be queried via `maxBatchSize`. Fails if the supply catch is reached,
    /// or if `maxBatchSize` is exceeded.
    /// @param receiver the receiver of the NFTs.
    /// @param amount the amount of NFTs to mint.
    function acquireForCommunity(address receiver, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../def/TokenDiscount.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAcquirableWithToken
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for the extended minting functionality of the Ommg Artist Contracts.
/// The general functionality is that special prices can be configured for users to mint if they hold other
/// NFTs. Each NFT can only be used once to receive this discount, unless specifically reset.
interface IOmmgAcquirableWithToken {
    error TokenNotOwned(IERC721 token, uint256 tokenIds);
    error TokenAlreadyUsed(IERC721 token, uint256 tokenId);
    error TokenNotConfigured(IERC721 token);
    error TokenNotActive(IERC721 token);
    error TokenAlreadyConfigured(IERC721 token);
    error TokenSupplyExceeded(IERC721 token, uint256 supplyCap);

    /// @notice Triggers when a token discount is added.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the configuration for
    /// the discount
    event TokenDiscountAdded(
        IERC721 indexed tokenAddress,
        TokenDiscountInfo config
    );
    /// @notice Triggers when a token discount is updated.
    /// @param tokenAddress the addres of the added NFT contract for discounts
    /// @param config a tuple [uint256 price, uint256 limit, bool active] that represents the new configuration for
    /// the discount
    event TokenDiscountUpdated(
        IERC721 indexed tokenAddress,
        TokenDiscountInfo config
    );
    /// @notice Triggers when a token discount is removed.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountRemoved(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is reset - meaning all token usage data is reset and all tokens
    /// are marked as unused again.
    /// @param tokenAddress the addres of the NFT contract
    event TokenDiscountReset(IERC721 indexed tokenAddress);
    /// @notice Triggers when a token discount is used for a discount and then marked as used
    /// @param sender the user who used the token
    /// @param tokenAddress the addres of the NFT contract
    /// @param tokenId the id of the NFT used for the discount
    event TokenUsedForDiscount(
        address indexed sender,
        IERC721 indexed tokenAddress,
        uint256 indexed tokenId
    );

    /// @notice Adds an NFT contract and thus all of it's tokens to the discount list.
    /// Emits a {TokenDiscountAdded} event and fails if `tokenAddress` is the zero address
    /// or is already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the initial configuration as [uint256 price, uint256 limit, bool active]
    function addTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountInfo memory config
    ) external;

    /// @notice Removes an NFT contract from the discount list.
    /// Emits a {TokenDiscountRemoved} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function removeTokenDiscount(IERC721 tokenAddress) external;

    /// @notice Updates an NFT contracts configuration of the discount.
    /// Emits a {TokenDiscountUpdated} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    /// @param config the new configuration as [uint256 price, uint256 limit, bool active]
    function updateTokenDiscount(
        IERC721 tokenAddress,
        TokenDiscountInfo memory config
    ) external;

    /// @notice Resets the usage state of all NFTs of the contract at `tokenAddress`. This allows all token ids
    /// to be used again.
    /// Emits a {TokenDiscountReset} event and fails if `tokenAddress` is the zero address
    /// or is not already configured.
    /// @param tokenAddress the address of the NFT contract
    function resetTokenDiscountUsed(IERC721 tokenAddress) external;

    /// @notice Returns the current configuration of the token discount of `tokenAddress`
    /// @return config the configuration as [uint256 price, uint256 limit, bool active]
    function tokenDiscountInfo(IERC721 tokenAddress)
        external
        view
        returns (TokenDiscountInfo memory config);

    /// @notice Returns a list of all current tokens configured for discounts and their configurations.
    /// @return discounts the configuration as [IERC721 tokenAddress, [uint256 price, uint256 limit, bool active]]
    function tokenDiscounts()
        external
        view
        returns (TokenDiscount[] memory discounts);

    /// @notice Acquires an NFT of this contract by proving ownership of the tokens in `tokenIds` belonging to
    /// a contract `tokenAddress` that has a configured discount. This way cheaper prices can be achieved for OMMG holders
    /// and potentially other partners. Emits {TokenUsedForDiscount} and requires the user to send the correct amount of
    /// eth as well as to own the tokens within `tokenIds` from `tokenAddress`, and for `tokenAddress` to be a configured token for discounts.
    /// @param tokenAddress the address of the contract which is the reference for `tokenIds`
    /// @param tokenIds the token ids which are to be used to get the discount
    function acquireWithToken(IERC721 tokenAddress, uint256[] memory tokenIds)
        external
        payable;

    /// @notice Sets the active status of the token discount of `tokenAddress`.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the configured token address
    /// @param active the new desired activity state
    function setTokenDiscountActive(IERC721 tokenAddress, bool active)
        external;

    /// @notice Returns whether the tokens `tokenIds` of `tokenAddress` have already been used for a discount.
    /// Fails if `tokenAddress` is the zero address or is not already configured.
    /// @param tokenAddress the address of the token contract
    /// @param tokenIds the ids to check
    /// @return used if the tokens have already been used, each index corresponding to the
    /// token id index in the array
    function tokensUsedForDiscount(
        IERC721 tokenAddress,
        uint256[] memory tokenIds
    ) external view returns (bool[] memory used);

    /// @notice Returns the number of tokens already used for `tokenAddress`
    /// @param tokenAddress the address of the token contract
    /// @return amount the amount of tokens already used for this discount partner
    function tokenAmountUsedForDiscount(IERC721 tokenAddress)
        external
        view
        returns (uint256 amount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgEmergencyTokenRecoverable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for emergency ERC20 token recovery. This is needed
/// in the case that someone accidentally sent ERC20 tokens to this contract.
interface IOmmgEmergencyTokenRecoverable {
    /// @notice Triggers when ERC20 tokens are recovered
    /// @param token The address of the ERC20 token contract
    /// @param receiver The recipient of the tokens
    /// @param amount the amount of tokens recovered
    event TokensRecovered(
        IERC20 indexed token,
        address indexed receiver,
        uint256 amount
    );

    /// @notice Recovers ERC20 tokens
    /// @param token The address of the ERC20 token contract
    /// @param receiver The recipient of the tokens
    /// @param amount the amount of tokens to recover
    function emergencyRecoverTokens(
        IERC20 token,
        address receiver,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
import "../def/Shareholder.sol";

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgWithdrawable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for automatic distribution of the contract balance
/// to shareholders based on their held shares
interface IOmmgWithdrawable {
    /// @notice triggers whenever a shareholder is added to the contract
    /// @param addr the address of the shareholder
    /// @param shares the number of shares held by the holder
    event ShareholderAdded(address indexed addr, uint256 shares);
    /// @notice triggers whenever a shareholder is added to the contract
    /// @param addr the address of the former shareholder
    /// @param shares the number of shares that was held by the former holder
    event ShareholderRemoved(address indexed addr, uint256 shares);
    /// @notice triggers whenever a shareholder is updated
    /// @param addr the address of the shareholder
    /// @param shares the new number of shares held by the holder
    event ShareholderUpdated(address indexed addr, uint256 shares);
    /// @notice triggers whenever funds are withdrawn
    /// @param txSender the sender of the transaction
    /// @param amount the amount of eth withdrawn
    event Withdrawn(address indexed txSender, uint256 amount);
    /// @notice triggers whenever an emergency withdraw is executed
    /// @param txSender the transaction sender
    /// @param amount the amount of eth withdrawn
    event EmergencyWithdrawn(address indexed txSender, uint256 amount);
    /// @notice triggers whenever a shareholder receives their share of a withdrawal
    /// @param txSender the address that initiated the withdrawal
    /// @param to the address of the shareholder receiving this part of the withdrawal
    /// @param amount the amount of eth received by `to`
    event PaidOut(
        address indexed txSender,
        address indexed to,
        uint256 amount
    );
    /// @notice fires whenever a shareholder already exists but is attempted to be added
    /// @param addr the address already added
    error ShareholderAlreadyExists(address addr);
    /// @notice fires whenever a shareholder does not exist but an access is attempted
    /// @param addr the address of the attempted shareholder acces
    error ShareholderDoesNotExist(address addr);

    /// @notice withdraws the current balance from this contract and distributes it to shareholders
    /// according to their held shares. Triggers a {Withdrawn} event and a {PaidOut} event per shareholder.
    function withdraw() external;

    /// @notice withdraws the current balance from this contract and sends it to the
    /// initiator of the transaction. Triggers an {EmergencyWithdrawn} event.
    function emergencyWithdraw() external;

    /// @notice Adds a shareholder to the contract. When `withdraw` is called,
    /// the shareholder will receive an amount of native tokens proportional to
    /// their shares. Triggers a {ShareholderAdded} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to not already exist,
    /// as well as for `shares` to be greater than 0.
    /// @param walletAddress the address of the shareholder
    /// @param shares the number of shares assigned to that shareholder
    function addShareholder(address walletAddress, uint256 shares) external;

    /// @notice Removes a shareholder from the contract. Triggers a {ShareholderRemoved} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to exist.
    /// @param walletAddress the address of the shareholder to remove
    function removeShareholder(address walletAddress) external;

    /// @notice Updates a shareholder of the contract. Triggers a {ShareholderUpdated} event.
    /// Requires `walletAddress` to not be the ZeroAddress and for the shareholder to exist.
    /// @param walletAddress the address of the shareholder to remove
    /// @param updatedShares the new amount of shares the shareholder will have
    function updateShareholder(address walletAddress, uint256 updatedShares)
        external;

    /// @notice returns a list of all shareholders with their shares
    /// @return shareholders An array of tuples [address, shares], see the {Shareholder} struct
    function shareholders()
        external
        view
        returns (Shareholder[] memory shareholders);

    /// @notice returns the total amount of shares that exist
    /// @return shares the total number of shares in the contract
    function totalShares() external view returns (uint256 shares);

    /// @notice returns the number of shares held by `shareholderAddress`
    /// @return shares the number of shares held by `shareholderAddress`
    function shares(address shareholderAddress)
        external
        view
        returns (uint256 shares);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgProvenanceHash
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a freezable provenance hash, to enable full trust that
/// the metadata of the underlying token is not predetermined or tampered with.
interface IOmmgProvenanceHash {
    /// @notice Triggers when an attempt is made to change the provenance
    /// hash after it has been frozen
    error ProvenanceHashIsFrozen();
    /// @notice Triggers when the provenance hash is set to a new value.
    /// @param provenanceHash the new provenance hash.
    event ProvenanceHashSet(string indexed provenanceHash);
    /// @notice Triggers when the provenance hash is frozen.
    event ProvenanceHashFrozen();

    /// @notice Returns the current provenance hash. The idea is for this to be
    /// the proof that the order of token metada has not been tampered with and
    /// that it has not been predetermined.
    /// @return provenanceHash the provenance hash
    function provenanceHash()
        external
        view
        returns (string memory provenanceHash);

    /// @notice Returns a boolean value indicating whether the provenance hash
    /// has been frozen or not. A frozen provenance hash is immutable.
    /// @return isFrozen whether it is frozen or not
    function provenanceFrozen() external view returns (bool isFrozen);

    /// @notice Updates the provenance hash to the new value `provenanceHash`.
    /// Also triggers the event {ProvenanceHashSet} and reverts if the provenance
    /// hash has already been frozen.
    function setProvenanceHash(string memory provenanceHash) external;

    /// @notice freezes the provenance hash and thus makes it immutable.
    /// Triggers a {ProvenanceHashFrozen} event and reverts if the hash is already frozen.
    function freezeProvenance() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgMutablePrice
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a simple mutable price implementation.
interface IOmmgMutablePrice {
    /// @notice Triggers when the price gets changes.
    /// @param newPrice the new price
    event PriceChanged(uint256 newPrice);

    /// @notice Returns the current price.
    /// @return price the current price
    function price() external view returns (uint256 price);

    /// @notice Sets the price to `price`.
    function setPrice(uint256 price) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgSalePausable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a simple mutable sale state on any contract
interface IOmmgSalePausable {
    error SaleNotActive();
    /// @notice This event gets triggered whenever the sale state changes
    /// @param newValue the new sale state
    event SaleIsActiveSet(bool newValue);

    /// @notice This function returns a boolean value indicating whether
    /// the public sale is currently active or not
    /// returns currentState whether the sale is active or not
    function saleIsActive() external view returns (bool currentState);

    /// @notice This function can be used to change the sale state to `newValue`.
    /// Triggers a {SaleIsActiveSet} event.
    /// @param newValue the desired new value for the sale state
    function setSaleIsActive(bool newValue) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgSupplyCap
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a supply cap on any contract
interface IOmmgSupplyCap {
    /// @notice this returns the supply cap of the token
    /// @return supplyCap the supply cap of the token
    function supplyCap() external view returns (uint256 supplyCap);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../def/Shareholder.sol";
import "../def/TokenDiscount.sol";

struct ArtistContractConfig {
    string name;
    string symbol;
    address[] withdrawAdmins;
    address[] stateAdmins;
    address[] mintForFree;
    uint256 initialPrice;
    uint256 supplyCap;
    uint256 maxBatchSize;
    Shareholder[] shareholders;
    TokenDiscount[] tokenDiscounts;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

/// @dev triggered when an address is the null address
error NullAddress();

error TokenDoesNotExist(uint256 tokenId);
error TokenAlreadyExists(uint256 tokenId);

error SafeTransferFailed(address from, address to, uint256 tokenId);

error TargetNonERC721Receiver(address target);

error TransferUnauthorized(
    address sender,
    address from,
    address to,
    uint256 tokenId,
    address tokenOwner
);

error IndexOutOfBounds(uint256 index, uint256 max);

error ApprovalForAllInvalid(address target, bool targetState);
error ApprovalInvalid(address account, uint256 tokenId);
error ApprovalUnauthorized(
    address from,
    address to,
    uint256 tokenId,
    address sender
);
error OperationFailed();

error InvalidAmount(uint256 amount, uint256 minAmount, uint256 maxAmount);
error AmountExceedsCap(uint256 amount, uint256 available, uint256 cap);
error InvalidMessageValue(uint256 value, uint256 needed);
error ZeroShares();

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// SPDX-License-Identifier: BSD-3-Clause

pragma solidity ^0.8.0;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title ISnapshottable
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for simple snapshots of all tokens
interface IOmmgSnapshottable {
    enum TokenStatus {
        OWNED,
        BURNED
    }
    struct TokenInfo {
        uint256 tokenId;
        TokenStatus status;
        address owner;
    }

    /// @notice Returns an array of tuples [tokenId, tokenStatus, owner] with the
    /// current state of each minted token. A tokenStatus of 0 means it exists, 1 signals that
    /// the token has been burned.
    /// @return tokenStates the states of all minted tokens
    function snapshot() external view returns (TokenInfo[] memory tokenStates);
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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

import "@openzeppelin/contracts/utils/Context.sol";
import "../interfaces/IOmmgOwnable.sol";
import "../def/CustomErrors.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

pragma solidity ^0.8.11;

abstract contract OmmgOwnable is IOmmgOwnable, Context, ERC165 {
    address private _owner;

    /// @dev Initializes the contract setting the deployer as the initial owner.
    constructor() {
        _setOwner(_msgSender());
    }

    ///@dev Reverts if called by any account other than the owner
    modifier onlyOwner() {
        if (owner() != _msgSender())
            revert OwnershipUnauthorized(_msgSender());
        _;
    }

    /// @dev Returns the address of the current owner.
    function owner() public view override returns (address) {
        return _owner;
    }

    /// @dev Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner
    function renounceOwnershipPermanently() public override onlyOwner {
        _setOwner(address(0));
    }

    /// @dev Transfers ownership of the contract to a new account (`newOwner`).
    /// Can only be called by the current owner.
    function transferOwnership(address newOwner) public override onlyOwner {
        if (newOwner == address(0)) revert NullAddress();
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IOmmgOwnable).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgAccessControl
/// @author NotAMeme aka nxlogixnick
/// @notice This interface serves for a lightweight custom implementation of role based permissions.
interface IOmmgAccessControl {
    struct RoleData {
        mapping(address => bool) members;
    }

    /// @notice Triggers when an unauthorized address attempts
    /// a restricted action
    /// @param account initiated the unauthorized action
    /// @param missingRole the missing role identifier
    error Unauthorized(address account, bytes32 missingRole);

    /// @notice Emitted when `account` is granted `role`
    /// @param role the role granted
    /// @param account the account that is granted `role`
    /// @param sender the address that initiated this action
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when `account` is revoked `role`
    /// @param role the role revoked
    /// @param account the account that is revoked `role`
    /// @param sender the address that initiated this action
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Returns `true` if `account` has been granted `role`.
    /// @param role the role identifier
    /// @param account the account to check
    /// @return hasRole whether `account` has `role` or not.
    function hasRole(bytes32 role, address account)
        external
        view
        returns (bool hasRole);

    /// @notice Grants `role` to `account`. Emits {RoleGranted}.
    /// @param role the role identifier
    /// @param account the account to grant `role` to
    function grantRole(bytes32 role, address account) external;

    /// @notice Grants `role` to `account`. Emits {RoleRevoked}.
    /// @param role the role identifier
    /// @param account the account to revoke `role` from
    function revokeRole(bytes32 role, address account) external;

    /// @notice Rennounces `role` from the calling account. Emits {RoleRevoked}.
    /// @param role the role identifier of the role to rennounce
    function renounceRole(bytes32 role) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

//  .----------------.  .----------------.  .----------------.  .----------------.
// | .--------------. || .--------------. || .--------------. || .--------------. |
// | |     ____     | || | ____    ____ | || | ____    ____ | || |    ______    | |
// | |   .'    `.   | || ||_   \  /   _|| || ||_   \  /   _|| || |  .' ___  |   | |
// | |  /  .--.  \  | || |  |   \/   |  | || |  |   \/   |  | || | / .'   \_|   | |
// | |  | |    | |  | || |  | |\  /| |  | || |  | |\  /| |  | || | | |    ____  | |
// | |  \  `--'  /  | || | _| |_\/_| |_ | || | _| |_\/_| |_ | || | \ `.___]  _| | |
// | |   `.____.'   | || ||_____||_____|| || ||_____||_____|| || |  `._____.'   | |
// | |              | || |              | || |              | || |              | |
// | '--------------' || '--------------' || '--------------' || '--------------' |
//  '----------------'  '----------------'  '----------------'  '----------------'

/// @title IOmmgProvenanceHash
/// @author NotAMeme aka nxlogixnick
/// @notice An interface for a custom implementation of Ownable contracts.
interface IOmmgOwnable {
    /// @dev Triggers when an unauthorized address attempts
    /// a restricted action
    /// @param account initiated the unauthorized action
    error OwnershipUnauthorized(address account);
    /// @dev Triggers when the ownership is transferred
    /// @param previousOwner the previous owner of the contract
    /// @param newOwner the new owner of the contract
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /// @notice Returns the current owner address.
    /// @return owner the address of the current owner
    function owner() external view returns (address owner);

    /// @notice Leaves the contract without owner. It will not be possible to call
    /// `onlyOwner` functions anymore. Can only be called by the current owner.
    /// Triggers the {OwnershipTransferred} event.
    function renounceOwnershipPermanently() external;

    /// @notice Transfers the ownership to `newOwner`.
    /// Triggers the {OwnershipTransferred} event.
    /// `newOwner` can not be the zero address.
    /// @param newOwner the new owner of the contract
    function transferOwnership(address newOwner) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

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
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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
pragma solidity ^0.8.11;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

struct TokenDiscountInfo {
    uint256 price;
    uint256 supply;
    bool active;
}
struct TokenDiscount {
    IERC721 tokenAddress;
    TokenDiscountInfo config;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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
pragma solidity ^0.8.11;

struct Shareholder {
    address addr;
    uint256 shares;
}