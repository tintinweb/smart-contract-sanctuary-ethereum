// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IVCPool.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketplace.sol";
import "../interfaces/IVCMarketManager.sol";

contract VCGovernance {
    error GovNotWhitelistedLab();
    error GovOnlyAdmin();
    error GovInvalidAdmin();
    error GovInvalidQuorumPoll();
    error GovInvalidArtnft();

    event ProtocolSetup(
        address indexed vcPool,
        address indexed vcStarter,
        IERC20 currency,
        address marketManager,
        address artNft1155,
        address artNft721,
        address pocNft
    );

    event GovProjectCreated(address indexed lab, address indexed project, uint256 amountToRaise);
    event GovWhitelistedLab(address indexed lab);
    event GovBlacklistedLab(address indexed lab);
    event GovCurrencyListed(IERC20 indexed currency);
    event GovCurrencyUnlisted(IERC20 indexed currency);
    event GovSetMinCampaignDuration(uint256 minCampaignDuration);
    event GovSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event GovSetMaxCampaignOffset(uint256 maxCampaignOffset);
    event GovSetMinCampaignTarget(uint256 minCampaignTarget);
    event GovSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event GovSetSoftTargetBps(uint256 softTargetBps);
    event GovPoCNftSet(IPoCNft indexed poCNft);

    enum MarketPlace {
        FixedPrice1155,
        FixedPrice721,
        Auction721
    }

    enum ArtNft {
        ERC1155,
        ERC721
    }

    address public admin;
    IERC20 public currency;
    IERC20 public cure;
    IVCPool public pool;
    IVCStarter public starter;
    IVCMarketManager public marketManager;
    IArtNft public artNft1155;
    IArtNft public artNft721;
    IPoCNft public pocNft;

    mapping(address => bool) public isWhitelistedLab;

    constructor(IERC20 _cure, address _admin) {
        _setAdmin(_admin);
        cure = _cure;
    }

    modifier onlyWhitelistedLab(address _lab) {
        if (!isWhitelistedLab[_lab]) {
            revert GovNotWhitelistedLab();
        }
        _;
    }

    function _onlyAdmin() private view {
        if (msg.sender != admin) {
            revert GovOnlyAdmin();
        }
    }

    function setupProtocol(
        IERC20 _currency,
        address _vcPool,
        address _vcStarter,
        address _artNft1155,
        address _artNft721,
        address _pocNft,
        address _marketplaceFixedPrice1155,
        address _marketplaceFixedPrice721,
        address _marketplaceAuction721,
        address _marketManager
    ) external {
        _onlyAdmin();

        pool = IVCPool(_vcPool);
        starter = IVCStarter(_vcStarter);
        artNft1155 = IArtNft(_artNft1155);
        artNft721 = IArtNft(_artNft721);
        pocNft = IPoCNft(_pocNft);
        marketManager = IVCMarketManager(_marketManager);

        _setMarketManagerToMarketplace(_marketplaceFixedPrice1155);
        _setMarketManagerToMarketplace(_marketplaceFixedPrice721);
        _setMarketManagerToMarketplace(_marketplaceAuction721);

        _setPoCNft(_pocNft);
        _listCurrency(_currency);
        pool.setStarter(_vcStarter);

        _setMinterRoleArtNft(ArtNft.ERC1155, _marketplaceFixedPrice1155);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceFixedPrice721);
        _setMinterRoleArtNft(ArtNft.ERC721, _marketplaceAuction721);

        emit ProtocolSetup(_vcPool, _vcStarter, _currency, _marketManager, _artNft1155, _artNft721, _pocNft);
    }

    function setAdmin(address _newAdmin) external {
        _onlyAdmin();
        _setAdmin(_newAdmin);
    }

    function _setAdmin(address _newAdmin) private {
        if (_newAdmin == address(0) || _newAdmin == admin) {
            revert GovInvalidAdmin();
        }
        admin = _newAdmin;
    }

    function marketplaceWithdrawTo(
        MarketPlace _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external {
        _onlyAdmin();
        marketManager.marketplaceWithdrawTo(uint256(_marketplace), _token, _to, _amount);
    }

    function _setPoCNft(address _pocNft) internal {
        _onlyAdmin();
        pool.setPoCNft(_pocNft);
        starter.setPoCNft(_pocNft);
        marketManager.setPoCNft(_pocNft);
    }

    //////////////////////////////////////////
    // MARKETPLACE SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////////

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external {
        _onlyAdmin();
        marketManager.setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external {
        _onlyAdmin();
        marketManager.setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external {
        _onlyAdmin();
        marketManager.setMarketplaceFeeBps(_marketplaceFeeBps);
    }

    /////////////////////////////////////////
    // ART NFT SETUP THROUGH GOVERNANCE    //
    /////////////////////////////////////////

    function setMinterRoleArtNft(ArtNft _artNft, address _minter) external {
        _onlyAdmin();
        _setMinterRoleArtNft(_artNft, _minter);
    }

    function _setMinterRoleArtNft(ArtNft _artNft, address _minter) private {
        if (_artNft == ArtNft.ERC1155) {
            artNft1155.grantMinterRole(_minter);
        } else if (_artNft == ArtNft.ERC721) {
            artNft721.grantMinterRole(_minter);
        } else {
            revert GovInvalidArtnft();
        }
    }

    function setRoyaltyInfoArtNft(address _receiver, uint96 _royaltyFeeBps) external {
        _onlyAdmin();
        artNft1155.setRoyaltyInfo(_receiver, _royaltyFeeBps);
        artNft721.setRoyaltyInfo(_receiver, _royaltyFeeBps);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external {
        _onlyAdmin();
        artNft1155.setMaxRoyalty(_maxRoyaltyBps);
        artNft721.setMaxRoyalty(_maxRoyaltyBps);
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external {
        _onlyAdmin();
        artNft1155.setMaxBatchSize(_maxBatchSize);
        artNft721.setMaxBatchSize(_maxBatchSize);
    }

    //////////////////////////////////////
    // STARTER SETUP THROUGH GOVERNANCE //
    //////////////////////////////////////

    // function createProjectStarter(address _lab, uint256 _amountToRaise) external returns (address projectAddress) {
    //     _onlyAdmin();
    //     projectAddress = starter.createProject(_lab, _amountToRaise);
    //     emit GovProjectCreated(_lab, projectAddress, _amountToRaise);
    // }

    function changeAdminStarter(address starterAdmin) external {
        _onlyAdmin();
        starter.changeAdmin(starterAdmin);
    }

    function whitelistLabStarter(address lab) external {
        _onlyAdmin();
        starter.whitelistLab(lab);
        emit GovWhitelistedLab(lab);
    }

    function blacklistLabStarter(address lab) external {
        _onlyAdmin();
        starter.blacklistLab(lab);
        emit GovBlacklistedLab(lab);
    }

    // function forceNotFundedCampaignsStarter(address project, uint256[] calldata campaignIds) external {
    //     _onlyAdmin();
    //     starter.forceNotFundedCampaigns(project, campaignIds);
    // }

    function setMinCampaignDurationStarter(uint256 minCampaignDuration) external {
        _onlyAdmin();
        starter.setMinCampaignDuration(minCampaignDuration);
        emit GovSetMinCampaignDuration(minCampaignDuration);
    }

    function setMaxCampaignDurationStarter(uint256 maxCampaignDuration) external {
        _onlyAdmin();
        starter.setMaxCampaignDuration(maxCampaignDuration);
        emit GovSetMaxCampaignDuration(maxCampaignDuration);
    }

    function setMaxCampaignOffsetStarter(uint256 maxCampaignOffset) external {
        _onlyAdmin();
        starter.setMaxCampaignOffset(maxCampaignOffset);
        emit GovSetMaxCampaignOffset(maxCampaignOffset);
    }

    function setMinCampaignTargetStarter(uint256 minCampaignTarget) external {
        _onlyAdmin();
        starter.setMinCampaignTarget(minCampaignTarget);
        emit GovSetMinCampaignTarget(minCampaignTarget);
    }

    function setMaxCampaignTargetStarter(uint256 maxCampaignTarget) external {
        _onlyAdmin();
        starter.setMaxCampaignTarget(maxCampaignTarget);
        emit GovSetMaxCampaignTarget(maxCampaignTarget);
    }

    function setSoftTargetBpsStarter(uint256 softTargetBps) external {
        _onlyAdmin();
        starter.setSoftTargetBps(softTargetBps);
        emit GovSetSoftTargetBps(softTargetBps);
    }

    ////////////////
    // GOVERNANCE //
    ////////////////

    function votePower(address _account) external view returns (uint256 userVotePower) {
        uint256 userCureBalance = cure.balanceOf(_account);
        uint256 boost = pocNft.getVotingPowerBoost(_account);

        userVotePower = (userCureBalance * (10000 + boost)) / 10000;
    }

    function listCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _listCurrency(_currency);
        emit GovCurrencyListed(_currency);
    }

    function _listCurrency(IERC20 _currency) private {
        currency = _currency;
        starter.listCurrency(_currency);
        pool.setCurrency(_currency);
        marketManager.setCurrency(_currency);
    }

    function unlistCurrency(IERC20 _currency) external {
        _onlyAdmin();
        _unlistCurrency(_currency);
        emit GovCurrencyUnlisted(_currency);
    }

    function _unlistCurrency(IERC20 _currency) private {
        starter.unlistCurrency(_currency);
    }

    function _setMarketManagerToMarketplace(address _marketPlace) private {
        IVCMarketplace(_marketPlace).setMarketManager(marketManager);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCPool {
    function setPoCNft(address _poolNFT) external;

    function setCurrency(IERC20 _currency) external;

    function setStarter(address _starter) external;

    function supportPoolFromStarter(address _supporter, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct Project {
    address _projectAddress;
    address _lab;
}

interface IVCStarter {
    function changeAdmin(address admin) external;

    function whitelistLab(address lab) external;

    function blacklistLab(address lab) external;

    function listCurrency(IERC20 currency) external;

    function unlistCurrency(IERC20 currency) external;

    function setMinCampaignDuration(uint256 minCampaignDuration) external;

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external;

    function setMaxCampaignOffset(uint256 maxCampaignOffset) external;

    function setMinCampaignTarget(uint256 minCampaignTarget) external;

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external;

    function setSoftTargetBps(uint256 softTargetBps) external;

    function setPoCNft(address _pocNft) external;

    function createProject(address _lab) external returns (address);

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory);

    function fundProjectOnBehalf(
        address _user,
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external;
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPoCNft {
    function mint(address _user, uint256 _amount) external;

    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IArtNft {
    function exists(uint256 _tokenId) external returns (bool);

    function grantMinterRole(address _address) external;

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external;

    function setMaxBatchSize(uint256 _maxBatchSize) external;

    function setRoyaltyInfo(address _receiver, uint96 _royaltyFeeBps) external;

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IArtNft.sol";
import "../interfaces/IVCMarketManager.sol";

interface IVCMarketplace {
    function whitelistTokens(address[] memory _tokens) external;

    function blacklistTokens(address[] memory _tokens) external;

    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFee(uint256 _marketplaceFee) external;

    function calculateMarketplaceFee(uint256 _price) external;

    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMarketManager(IVCMarketManager _marketManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../contracts/marketplace/VCMarketplaceBase.sol";

enum ListStatus {
    NOT_LISTED,
    FIXED_PRICE,
    AUCTION
}

interface IVCMarketManager {
    function setPoCNft(address _pocNft) external;

    function setCurrency(IERC20 _currency) external;

    function setMinterRoles() external;

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external;

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external;

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external;

    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external;

    function marketplaceWithdrawTo(
        uint256 _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external;

    function setListStatusERC721(uint256 _tokenId, bool listed) external;

    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus);
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";
import "./FeeBeneficiary.sol";
import "../interfaces/IVCStarter.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNft.sol";

abstract contract VCMarketplaceBase is FeeBeneficiary, Pausable {
    error MktCallerNotSeller();
    error MktTokenNotListed();
    error MktInsufficientBalance();
    error MktWithdrawFailed();
    error MktCallerNotManager();
    error MktAccrRoyaltiesFailed();
    error MktSettleFailed();
    error MktPurchaseFailed();
    error MktAlreadyListedOnAuction();
    error MktAlreadyListedOnFixedPrice();

    event PoCNftSet(address indexed oldPoCNft, address indexed newPoCNft);

    /// @notice The Viral(Cure) Proof of Collaboration Non-Fungible Token
    IPoCNft public pocNft;

    /// @notice The Viral(Cure) Art Non-Fungible Token
    IArtNft public artNft;

    /**
     * @dev Sets the whitelisted tokens to be traded at the Marketplace.
     */
    constructor(address _artNft) {
        artNft = IArtNft(_artNft);
    }

    /**
     * @dev Pauses or unpauses the Marketplace
     */
    function pause(bool _paused) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_paused) _pause();
        else _unpause();
    }

    // IDEA: we left this function just in case, there is no real use for the moment.
    /**
     * @dev Allows the withdrawal of any `ERC20` token from the Marketplace to
     * any account. Can only be called by the owner.
     *
     * Requirements:
     *
     * - Contract balance has to be equal or greater than _amount
     *
     * @param _token: ERC20 token address to withdraw
     * @param _to: Address that will receive the transfer
     * @param _amount: Amount to withdraw
     */
    function withdrawTo(
        address _token,
        address _to,
        uint256 _amount
    ) public onlyManager {
        uint256 totalBalance = IERC20(_token).balanceOf(address(this));
        uint256 _balanceWithdrawable = IERC20(_token) == currency
            ? totalBalance - _balanceNoTWithdrawable
            : totalBalance;

        if (_balanceWithdrawable < _amount) {
            revert MktInsufficientBalance();
        }
        if (!IERC20(_token).transfer(_to, _amount)) {
            revert MktWithdrawFailed();
        }
    }

    /**
     * @dev Sets the Proof of Collaboration Non-Fungible Token.
     */
    function setPoCNft(address _pocNft) external onlyManager {
        pocNft = IPoCNft(_pocNft);
        emit PoCNftSet(address(pocNft), _pocNft);
    }

    // this function will be changed -> transferFrom(buyer, project, amount);
    // function _fundProject(uint256 _projectId, uint256 _amount) internal override {
    //     IVCStarter(starter).fundProjectFromMarketplace(_projectId, _amount);
    // }

    /**
     * @dev Computes the royalty amount for the given tokenId and its price.
     *
     * @param _tokenId: Non-fungible token identifier
     * @param _amount: A pertinent amount used to compute the royalty.
     */
    function checkRoyalties(uint256 _tokenId, uint256 _amount)
        public
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        (receiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _amount);
    }

    function _setFeesAndCheckRoyalty(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal {
        uint256 totalFeeBps = _setFees(_tokenId, _poolFeeBps, _projects, _projectFeesBps);
        (, uint256 royaltyBps) = checkRoyalties(_tokenId, FEE_DENOMINATOR); // It should be _feeDenominator() instead of FEE_DENOMINATOR
        if (totalFeeBps + royaltyBps > FEE_DENOMINATOR) {
            //revert MktTotalFeeTooHigh();
            revert MktTotalFeeError();
        }
    }

    function _settle(
        uint256 _tokenId,
        address _seller,
        uint256 _highestBid,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        _transferFee(_tokenId, _seller, _highestBid, _starterFee, _marketFee + _poolFee);
        uint256 amountToSeller = _highestBid - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktSettleFailed();
        }
    }

    function _purchase(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketFee,
        uint256 _starterFee,
        uint256 _poolFee,
        address _royaltyReceiver,
        uint256 _royaltyAmount
    ) internal {
        if (!currency.transferFrom(msg.sender, address(this), _listPrice + _marketFee)) {
            revert MktPurchaseFailed();
        }
        _transferFee(_tokenId, _seller, _listPrice, _starterFee, _marketFee + _poolFee);
        uint256 amountToSeller = _listPrice - _starterFee - _poolFee;

        if (_royaltyReceiver != address(0) && _royaltyAmount != 0) {
            if (!currency.transfer(marketManager, _royaltyAmount)) {
                revert MktAccrRoyaltiesFailed();
            }
            IVCMarketManager(marketManager).accrueRoyalty(_royaltyReceiver, _royaltyAmount);
            amountToSeller -= _royaltyAmount;
        }
        if (!currency.transfer(_seller, amountToSeller)) {
            revert MktPurchaseFailed();
        }
    }

    function _checkAddressZero(address _address) internal pure {
        if (_address == address(0)) {
            revert MktTokenNotListed();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../utils/FeeManager.sol";
import "../interfaces/IVCMarketManager.sol";
import "../interfaces/IVCStarter.sol";

struct TokenFeesData {
    uint256 poolFeeBps;
    uint256 starterFeeBps;
    address[] projects;
    uint256[] projectFeesBps;
}

error MktFeesDataError();
error MktAddProjectFailed();
error MktRemoveProjectFailed();
error MktTotalFeeError();
// error MktTotalFeeTooLow();
// error MktTotalFeeTooHigh();
error MktVCPoolTransferFailed();
error MktVCStarterTransferFailed();
error MktUnexpectedAddress();
error MktInactiveProject();
error MktInvalidMarketManager();
error MktOnlyMktManagerAllowed();

contract FeeBeneficiary is FeeManager, AccessControl {
    bytes32 public constant STARTER_ROLE = keccak256("STARTER_ROLE");
    bytes32 public constant POOL_ROLE = keccak256("POOL_ROLE");

    /// @notice The Marketplace currency
    IERC20 public currency;
    uint256 internal _balanceNoTWithdrawable;

    /// @notice The VC Pool contract address
    address public pool;

    /// @notice The VC Starter contract address
    address public starter;

    /// @notice The Marketplace marketManager
    address public marketManager;

    /// @notice The minimum fee in basis points to distribute amongst VC Pool and VC Starter Projects
    uint256 public minTotalFeeBps;

    /// @notice The VC Marketplace fee in basis points
    uint256 public marketplaceFeeBps;

    /// @notice The maximum amount of projects a token seller can support
    uint96 public maxBeneficiaryProjects;

    event ProjectAdded(address indexed project, uint256 time);
    event ProjectRemoved(address indexed project, uint256 time);
    event CurrencySet(address indexed oldCurrency, address indexed newCurrency);

    /**
     * @dev Maps a token and seller to its TokenFeesData struct.
     */
    mapping(uint256 => mapping(address => TokenFeesData)) _tokenFeesData;

    /**
     * @dev Maps a project id to its beneficiary status.
     */
    //mapping(address => bool) internal _isActiveProject;

    modifier onlyManager() {
        if (msg.sender != marketManager) {
            revert MktOnlyMktManagerAllowed();
        }
        _;
    }

    /**
     * @dev Constructor
     */
    constructor(
        address _pool,
        address _starter,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFeeBps,
        uint96 _maxBeneficiaryProjects
    ) {
        _checkAddress(_pool);
        _checkAddress(_starter);

        _setMinTotalFeeBps(_minTotalFeeBps);
        _setMarketplaceFeeBps(_marketplaceFeeBps);
        _setMaxBeneficiaryProjects(_maxBeneficiaryProjects);

        _grantRole(POOL_ROLE, _pool);
        _grantRole(STARTER_ROLE, _starter);

        pool = _pool;
        starter = _starter;
    }

    function setMarketManager(address _marketManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        marketManager = _marketManager;
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyManager {
        _setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFee) external onlyManager {
        _setMarketplaceFeeBps(_marketplaceFee);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) public onlyManager {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Removes a project as a beneficiary candidate.
     *
     * @param _project the project address to remove.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    // function removeProject(address _project) public onlyRole(STARTER_ROLE) {
    //     if (!_isActiveProject[_project]) {
    //         revert MktRemoveProjectFailed();
    //     }
    //     _isActiveProject[_project] = false;
    //     emit ProjectRemoved(_project, block.timestamp);
    // }

    /**
     * @dev Adds a project as a beneficiary candidate.
     *
     * @param _project the project address to add.
     *
     * NOTE: can only be called by starter or admin.
     */
    // THIS RIGHT NOW CAN BE CALLED ONLY BY STARTER
    // function addProject(address _project) public onlyRole(STARTER_ROLE) {
    //     if (_isActiveProject[_project]) {
    //         revert MktAddProjectFailed();
    //     }
    //     _isActiveProject[_project] = true;
    //     emit ProjectAdded(_project, block.timestamp);
    // }

    /**
     * @dev Returns True if the project is active or False if is not.
     *
     * @param _project the project address.
     */
    // function isActiveProject(address _project) public view returns (bool) {
    //     return _isActiveProject[_project];
    // }

    /**
     * @dev Returns the struct TokenFeesData corresponding to the _token and _tokenId
     *
     * @param _tokenId: Non-fungible token identifier
     */
    function getFeesData(uint256 _tokenId, address _seller) public view returns (TokenFeesData memory result) {
        return _tokenFeesData[_tokenId][_seller];
    }

    /**
     * @dev Constructs a `TokenFeesData` struct which stores the total fees in
     * bips that will be transferred to both the pool and the starter smart
     * contracts.
     *
     * @param _tokenId NFT token ID
     * @param _projects Array of Project addresses to support
     * @param _projectFeesBps Array of fees to support each project ID
     */
    function _setFees(
        uint256 _tokenId,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) internal returns (uint256) {
        if (_projects.length != _projectFeesBps.length || _projects.length > maxBeneficiaryProjects) {
            revert MktFeesDataError();
        }

        uint256 starterFeeBps;
        for (uint256 i = 0; i < _projectFeesBps.length; i++) {
            // if (!_isActiveProject[_projects[i]]) {
            //     revert MktInactiveProject();
            // }
            starterFeeBps += _projectFeesBps[i];
        }

        uint256 totalFeeBps = _poolFeeBps + starterFeeBps;

        if (totalFeeBps < minTotalFeeBps || totalFeeBps > FEE_DENOMINATOR) {
            //revert MktTotalFeeTooLow();
            revert MktTotalFeeError();
        }

        // if (totalFeeBps > FEE_DENOMINATOR) {
        //     revert MktTotalFeeTooHigh();
        // }

        _tokenFeesData[_tokenId][msg.sender] = TokenFeesData(_poolFeeBps, starterFeeBps, _projects, _projectFeesBps);

        return totalFeeBps;
    }

    /**
     * @dev Computes and transfers fees to both the Pool and the Starter smart contracts when the token is bought.
     *
     * @param _tokenId Non-fungible token identifier
     * @param _price Token price
     *
     * NOTE: Transfer fee from contract (Marketplace) itself.
     */
    function _transferFee(
        uint256 _tokenId,
        address _seller,
        uint256 _price,
        uint256 _starterFee,
        uint256 _poolFee
    ) internal {
        if (_starterFee > 0) {
            TokenFeesData storage feesData = _tokenFeesData[_tokenId][_seller];
            _poolFee += _fundProjects(feesData, _price);
        }
        if (_poolFee > 0 && !currency.transfer(pool, _poolFee)) {
            revert MktVCPoolTransferFailed();
        }
    }

    /**
     * @dev Computes individual fees for each beneficiary project and performs
     * the pertinent accounting at the Starter smart contract.
     */
    function _fundProjects(TokenFeesData storage _feesData, uint256 _listPrice) internal returns (uint256 toPool) {

        bool[] memory activeProjects = IVCStarter(starter).areActiveProjects(_feesData.projects);

        for (uint256 i = 0; i < activeProjects.length; i++) {
            uint256 amount = _toFee(_listPrice, _feesData.projectFeesBps[i]);
            if (amount > 0) {
                if (activeProjects[i] == true) {
                    IVCStarter(starter).fundProjectOnBehalf(msg.sender, _feesData.projects[i], currency, amount);
                } else {
                    toPool += amount;
                }
            }
        }
    }

    function _checkAddress(address _address) internal view {
        if (_address == address(this) || _address == address(0)) {
            revert MktUnexpectedAddress();
        }
    }

    /**
     * @dev Sets the Marketplace currency.
     */
    function setCurrency(IERC20 _currency) external onlyManager {
        currency = _currency;
        emit CurrencySet(address(currency), address(_currency));
    }

    function _setMinTotalFeeBps(uint256 _minTotalFeeBps) private {
        minTotalFeeBps = _minTotalFeeBps;
    }

    function _setMarketplaceFeeBps(uint256 _marketplaceFeeBps) private {
        marketplaceFeeBps = _marketplaceFeeBps;
    }

    function _setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) private {
        maxBeneficiaryProjects = _maxBeneficiaryProjects;
    }

    /**
     * @dev Splits an amount into fees for both Pool and Starter smart
     * contracts and a resulting amount to be transferred to the token
     * owner (i.e. the token seller).
     */
    function _splitListPrice(TokenFeesData memory _feesData, uint256 _listPrice)
        internal
        pure
        returns (
            uint256 starterFee,
            uint256 poolFee,
            uint256 resultingAmount
        )
    {
        starterFee = _toFee(_listPrice, _feesData.starterFeeBps);
        poolFee = _toFee(_listPrice, _feesData.poolFeeBps);
        resultingAmount = _listPrice - starterFee - poolFee;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

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
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract FeeManager {
    /// @notice Used to translate from basis points to amounts
    uint96 public constant FEE_DENOMINATOR = 10_000;

    /**
     * @dev Translates a fee in basis points to a fee amount.
     */
    function _toFee(uint256 _amount, uint256 _feeBps) internal pure returns (uint256) {
        return (_amount * _feeBps) / FEE_DENOMINATOR;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

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
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

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
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

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
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

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
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
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
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
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
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

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
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
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
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
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
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
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
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
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
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
pragma solidity ^0.8.9;

import "./IArtNft.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IArtNftERC721 is IERC721, IArtNft {
    function mintTo(uint256 _tokenId, address _to) external;

    function requireCanRequestMint(address _by, uint256 _tokenId) external;

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./VCMarketplaceBase.sol";
import "../interfaces/IArtNftERC721.sol";
import "../interfaces/IVCStarter.sol";

contract VCMarketplaceFixedPriceERC721 is VCMarketplaceBase, ERC721Holder {
    struct FixedPriceListing {
        bool minted;
        address seller;
        uint256 price;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address royaltyReceiver;
        uint256 royaltyAmount;
    }

    event ListedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event UpdatedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event UnlistedFixedPrice(address indexed token, uint256 indexed tokenId, address indexed seller);
    event Purchased(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    /// @notice Maps a token Id to its listing
    mapping(uint256 => FixedPriceListing) public fixedPriceListings;

    constructor(
        address _artNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows a token owner, i.e. msg.sender, to list an ERC721 artNft with a given fixed price to the Marketplace.
     * It can also be used to update a listing, such as its price, fees and/or royalty data.
     *
     * @param _tokenId the token identifier
     * @param _listPrice the listing price
     * @param _poolFeeBps the fee transferred to the VC Pool on purchases
     * @param _projects Array of project addresses to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        ListStatus status = IVCMarketManager(marketManager).getListStatusERC721(_tokenId);
        if (status == ListStatus.AUCTION) {
            revert MktAlreadyListedOnAuction();
        }

        _setFeesAndCheckRoyalty(_tokenId, _poolFeeBps, _projects, _projectFeesBps);

        if (status == ListStatus.NOT_LISTED) {
            _newList(_tokenId, _listPrice);
        } else {
            _updateList(_tokenId, _listPrice);
        }
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to remove a token from being listed at the Marketplace.
     *
     * @param _tokenId the token identifier
     */
    function unlistFixedPrice(uint256 _tokenId) public {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        delete fixedPriceListings[_tokenId];
        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, false);

        if (listing.minted) {
            IArtNftERC721(address(artNft)).safeTransferFrom(address(this), listing.seller, _tokenId, "");
        }

        emit UnlistedFixedPrice(address(artNft), _tokenId, msg.sender);
    }

    /**
     * @dev Allows a buyer, i.e. msg.sender, to purchase a token at a fixed price in the Marketplace. Tokens must be
     * purchased for the price set by the seller plus the market fee.
     *
     * @param _tokenId the token identifier
     *
     */
    function purchase(uint256 _tokenId) public whenNotPaused {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId];

        _checkAddressZero(listing.seller);
        delete fixedPriceListings[_tokenId];
        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, false);

        _purchase(
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
        _minting(listing, _tokenId);

        emit Purchased(
            msg.sender,
            address(artNft),
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
    }

    // function listed(uint256 _tokenId) public view returns (bool) {
    //     return fixedPriceListings[_tokenId].seller != address(0);
    // }

    function _newList(uint256 _tokenId, uint256 _listPrice) internal {
        bool minted = artNft.exists(_tokenId);
        if (!minted) {
            IArtNftERC721(address(artNft)).requireCanRequestMint(msg.sender, _tokenId);
        } else {
            IArtNftERC721(address(artNft)).safeTransferFrom(msg.sender, address(this), _tokenId, "");
        }

        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, _listPrice);

        fixedPriceListings[_tokenId] = FixedPriceListing(
            minted,
            msg.sender,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );

        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, true);

        emit ListedFixedPrice(
            address(artNft),
            _tokenId,
            msg.sender,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _updateList(uint256 _tokenId, uint256 _listPrice) internal {
        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, _listPrice);

        FixedPriceListing memory listing = fixedPriceListings[_tokenId];
        listing.price = _listPrice;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        listing.royaltyReceiver = royaltyReceiver;
        listing.royaltyAmount = royaltyAmount;
        fixedPriceListings[_tokenId] = listing;

        emit UpdatedFixedPrice(
            address(artNft),
            _tokenId,
            msg.sender,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _getFeesAndRoyalty(uint256 _tokenId, uint256 _listPrice)
        internal
        view
        returns (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        )
    {
        marketFee = _toFee(_listPrice, marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][msg.sender];
        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
        (royaltyReceiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _listPrice);
    }

    function _minting(FixedPriceListing memory listing, uint256 _tokenId) internal {
        if (!listing.minted) {
            IArtNftERC721(address(artNft)).mintTo(_tokenId, address(this));
            fixedPriceListings[_tokenId].minted = true;
        }
        IArtNftERC721(address(artNft)).safeTransferFrom(address(this), msg.sender, _tokenId, "");

        pocNft.mint(msg.sender, listing.marketFee);
        pocNft.mint(listing.seller, listing.starterFee + listing.poolFee);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./VCMarketplaceBase.sol";
import "../interfaces/IArtNftERC721.sol";
import "../interfaces/IVCStarter.sol";

contract VCMarketplaceAuctionERC721 is VCMarketplaceBase, ERC721Holder {
    error MktAlreadyListed();
    error MktExistingBid();
    error MktBidderNotAllowed();
    error MktBidTooLate();
    error MktBidTooLow();
    error MktSettleTooEarly();

    struct AuctionListing {
        bool minted;
        address seller;
        uint256 initialPrice;
        uint256 maturity;
        address highestBidder;
        uint256 highestBid;
        uint256 marketplaceFeeBps;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address royaltyReceiver;
        uint256 royaltyAmount;
    }

    event ListedAuction(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 maturity,
        uint256 initialPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event UnlistedAuction(address indexed seller, address indexed token, uint256 indexed tokenId);
    event Bid(
        address indexed bidder,
        address indexed seller,
        uint256 indexed tokenId,
        address token,
        uint256 amount,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event Settled(
        address indexed buyer,
        address indexed seller,
        address indexed token,
        uint256 tokenId,
        uint256 endPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    mapping(uint256 => AuctionListing) public auctionListings;

    constructor(
        address _artNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows a token owner, i.e. msg.sender, to auction an ERC721 artNft with a given initial price and duration.
     *
     * @param _tokenId the token identifier
     * @param _initialPrice minimum price set by the seller
     * @param _biddingDuration duration of the auction in seconds
     * @param _projects Array of project addresses to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listAuction(
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _biddingDuration,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        ListStatus status = IVCMarketManager(marketManager).getListStatusERC721(_tokenId);
        if (status == ListStatus.FIXED_PRICE) {
            revert MktAlreadyListedOnFixedPrice();
        } else if (status == ListStatus.AUCTION) {
            revert MktAlreadyListedOnAuction();
        }

        _setFeesAndCheckRoyalty(_tokenId, _poolFeeBps, _projects, _projectFeesBps);

        bool minted = artNft.exists(_tokenId);
        uint256 maturity = block.timestamp + _biddingDuration;

        _newList(minted, _tokenId, _initialPrice, maturity);
    }

    /**
     * @dev Cancels the token auction from the Marketplace and sends back the
     * asset to the seller.
     *
     * Requirements:
     *
     * - The token must not have a bid placed, if there is a bid the transaction will fail
     *
     * @param _tokenId the token identifier
     */
    function unlistAuction(uint256 _tokenId) public {
        AuctionListing memory listing = auctionListings[_tokenId];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        if (listing.highestBid != 0) {
            revert MktExistingBid();
        }

        delete auctionListings[_tokenId];
        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, false);

        if (listing.minted) {
            IArtNftERC721(address(artNft)).safeTransferFrom(address(this), listing.seller, _tokenId, "");
        }

        emit UnlistedAuction(msg.sender, address(artNft), _tokenId);
    }

    /**
     * @dev Places a bid for a token listed in the Marketplace. If the bid is valid,
     * previous bid amount and its market fee gets returned back to previous bidder,
     * while current bid amount and market fee is charged to current bidder.
     *
     * @param _tokenId the token identifier
     * @param _amount the bid amount
     */
    function bid(uint256 _tokenId, uint256 _amount) public whenNotPaused {
        AuctionListing memory listing = auctionListings[_tokenId];

        _checkBeforeBid(listing, _amount);

        if (listing.highestBid != 0) {
            uint256 amountBack = listing.highestBid + listing.marketFee;
            currency.transfer(listing.highestBidder, amountBack);
            _balanceNoTWithdrawable -= amountBack;
        }

        // use the marketplace fee bps fixed at the moment of listing
        (uint256 marketFee, uint256 starterFee, uint256 poolFee, , uint256 royaltyAmount) = _getFeesAndRoyalty(
            _tokenId,
            listing.seller,
            _amount,
            listing.marketplaceFeeBps
        );

        uint256 amountCharged = _amount + marketFee;
        currency.transferFrom(msg.sender, address(this), _amount + marketFee);
        _balanceNoTWithdrawable += amountCharged;

        listing.highestBidder = msg.sender;
        listing.highestBid = _amount;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        // listing.royaltyReceiver = royaltyReceiver;
        listing.royaltyAmount = royaltyAmount;
        auctionListings[_tokenId] = listing;

        emit Bid(
            msg.sender,
            listing.seller,
            _tokenId,
            address(artNft),
            _amount,
            marketFee,
            starterFee,
            poolFee,
            listing.royaltyReceiver,
            royaltyAmount
        );
    }

    /**
     * @dev Allows anyone to settle the auction. If there are no bids, the seller
     * receives back the NFT
     *
     * @param _tokenId the token identifier
     */
    function settle(uint256 _tokenId) public {
        AuctionListing memory listing = auctionListings[_tokenId];

        _checkBeforeSettle(listing);

        delete auctionListings[_tokenId];
        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, false);

        if (listing.highestBid != 0) {
            _settle(
                _tokenId,
                listing.seller,
                listing.highestBid,
                listing.marketFee,
                listing.starterFee,
                listing.poolFee,
                listing.royaltyReceiver,
                listing.royaltyAmount
            );
            _minting(listing, _tokenId);
        } else {
            if (listing.minted) {
                IArtNftERC721(address(artNft)).safeTransferFrom(address(this), listing.seller, _tokenId, "");
            }
        }

        emit Settled(
            listing.highestBidder,
            listing.seller,
            address(artNft),
            _tokenId,
            listing.highestBid,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
    }

    function _getFeesAndRoyalty(
        uint256 _tokenId,
        address _seller,
        uint256 _listPrice,
        uint256 _marketplaceFeeBps
    )
        internal
        view
        returns (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        )
    {
        marketFee = _toFee(_listPrice, _marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][_seller];
        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
        (royaltyReceiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _listPrice);
    }

    function _newList(
        bool minted,
        uint256 _tokenId,
        uint256 _initialPrice,
        uint256 _maturity
    ) internal {
        if (!minted) {
            IArtNftERC721(address(artNft)).requireCanRequestMint(msg.sender, _tokenId);
        } else {
            IArtNftERC721(address(artNft)).safeTransferFrom(msg.sender, address(this), _tokenId, "");
        }

        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, msg.sender, _initialPrice, marketplaceFeeBps);

        auctionListings[_tokenId] = AuctionListing(
            minted,
            msg.sender,
            _initialPrice,
            _maturity,
            address(0),
            0,
            marketplaceFeeBps,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );

        IVCMarketManager(marketManager).setListStatusERC721(_tokenId, true);

        emit ListedAuction(
            address(artNft),
            _tokenId,
            msg.sender,
            _maturity,
            _initialPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _minting(AuctionListing memory listing, uint256 _tokenId) internal {
        if (!listing.minted) {
            IArtNftERC721(address(artNft)).mintTo(_tokenId, address(this));
            auctionListings[_tokenId].minted = true;
        }
        IArtNftERC721(address(artNft)).safeTransferFrom(address(this), listing.highestBidder, _tokenId, "");

        pocNft.mint(listing.highestBidder, listing.marketFee);
        pocNft.mint(listing.seller, listing.starterFee + listing.poolFee);
    }

    function _checkBeforeBid(AuctionListing memory listing, uint256 _amount) internal view {
        _checkAddressZero(listing.seller);
        if (listing.seller == msg.sender) {
            revert MktBidderNotAllowed();
        }
        if (block.timestamp > listing.maturity) {
            revert MktBidTooLate();
        }
        if (_amount <= listing.highestBid || _amount < listing.initialPrice) {
            revert MktBidTooLow();
        }
    }

    function _checkBeforeSettle(AuctionListing memory listing) internal view {
        _checkAddressZero(listing.seller);
        if (!(block.timestamp > listing.maturity)) {
            revert MktSettleTooEarly();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "./VCMarketplaceBase.sol";
import "../interfaces/IArtNftERC1155.sol";

contract VCMarketplaceFixedPriceERC1155 is VCMarketplaceBase, ERC1155Holder {
    error MktNotEnoughTokens();

    struct FixedPriceListing {
        bool minted;
        address seller;
        uint256 amount;
        uint256 price;
        uint256 marketFee;
        uint256 starterFee;
        uint256 poolFee;
        address royaltyReceiver;
        uint256 royaltyAmount;
    }

    event ListedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event UpdatedFixedPrice(
        address indexed token,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 amount,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );
    event UnlistedFixedPrice(address indexed token, uint256 indexed tokenId, address indexed seller, uint256 amount);
    event Purchased(
        address indexed buyer,
        address indexed token,
        uint256 indexed tokenId,
        address seller,
        uint256 listPrice,
        uint256 marketFee,
        uint256 starterFee,
        uint256 poolFee,
        address royaltyReceiver,
        uint256 royaltyAmount
    );

    /// @notice Maps a token Id and seller to its listing
    mapping(uint256 => mapping(address => FixedPriceListing)) public fixedPriceListings;

    constructor(
        address _artNft,
        address _pool,
        address _starter,
        address _admin,
        uint256 _minTotalFeeBps,
        uint256 _marketplaceFee,
        uint96 _maxBeneficiaryProjects
    )
        VCMarketplaceBase(_artNft)
        FeeBeneficiary(_pool, _starter, _minTotalFeeBps, _marketplaceFee, _maxBeneficiaryProjects)
    {
        _checkAddress(_admin);
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    /**
     * @dev Allows a token owner, i.e. msg.sender, to list an amount of ERC1155 artNfts with a given fixed price to the
     * Marketplace. It can also be used to update a listing, such as its price, amount, fees and/or royalty data.
     *
     * @param _tokenId the token identifier
     * @param _listPrice the listing price
     * @param _amount the amount of tokens to list
     * @param _poolFeeBps the fee transferred to the VC Pool on purchases
     * @param _projects Array of project addresses to support on purchases
     * @param _projectFeesBps Array of project fees in basis points on purchases
     */
    function listFixedPrice(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice,
        uint256 _poolFeeBps,
        address[] calldata _projects,
        uint256[] calldata _projectFeesBps
    ) public whenNotPaused {
        _setFeesAndCheckRoyalty(_tokenId, _poolFeeBps, _projects, _projectFeesBps);
        if (!listed(_tokenId, msg.sender)) {
            _newList(_tokenId, _amount, _listPrice);
        } else {
            _updateList(_tokenId, _amount, _listPrice);
        }
    }

    /**
     * @dev Allows the seller, i.e. msg.sender, to remove a specific amount of token from being listed at the Marketplace.
     *
     * @param _tokenId the token identifier
     */
    function unlistFixedPrice(uint256 _tokenId, uint256 _amount) public {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][msg.sender];

        if (listing.seller != msg.sender) {
            revert MktCallerNotSeller();
        }

        _updateFixedPriceListing(_tokenId, msg.sender, _amount);

        if (listing.minted) {
            IArtNftERC1155(address(artNft)).safeTransferFrom(address(this), listing.seller, _tokenId, _amount, "");
        }

        emit UnlistedFixedPrice(address(artNft), _tokenId, msg.sender, _amount);
    }

    /**
     * @dev Allows a buyer, i.e. msg.sender, to purchase a token at a fixed price in the Marketplace. Tokens must be
     * purchased for the price set by the seller plus the market fee.
     *
     * @param _tokenId the token identifier
     *
     */
    function purchase(uint256 _tokenId, address _seller) public whenNotPaused {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][_seller];

        _checkAddressZero(listing.seller);
        _updateFixedPriceListing(_tokenId, _seller, 1);

        _purchase(
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
        _minting(listing, _tokenId);

        emit Purchased(
            msg.sender,
            address(artNft),
            _tokenId,
            listing.seller,
            listing.price,
            listing.marketFee,
            listing.starterFee,
            listing.poolFee,
            listing.royaltyReceiver,
            listing.royaltyAmount
        );
    }

    function listed(uint256 _tokenId, address seller) public view returns (bool) {
        return fixedPriceListings[_tokenId][seller].seller != address(0);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(AccessControl, ERC1155Receiver)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function _newList(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice
    ) internal {
        bool minted = artNft.exists(_tokenId);
        if (!minted) {
            IArtNftERC1155(address(artNft)).requireCanRequestMint(msg.sender, _tokenId, _amount);
        } else {
            IArtNftERC1155(address(artNft)).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }

        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, _listPrice);

        fixedPriceListings[_tokenId][msg.sender] = FixedPriceListing(
            minted,
            msg.sender,
            _amount,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );

        emit ListedFixedPrice(
            address(artNft),
            _tokenId,
            msg.sender,
            _amount,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _updateList(
        uint256 _tokenId,
        uint256 _amount,
        uint256 _listPrice
    ) internal {
        (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        ) = _getFeesAndRoyalty(_tokenId, _listPrice);

        FixedPriceListing memory listing = fixedPriceListings[_tokenId][msg.sender];
        listing.price = _listPrice;
        listing.marketFee = marketFee;
        listing.starterFee = starterFee;
        listing.poolFee = poolFee;
        listing.royaltyReceiver = royaltyReceiver;
        listing.royaltyAmount = royaltyAmount;
        listing.amount += _amount;
        fixedPriceListings[_tokenId][msg.sender] = listing;

        if (!listing.minted) {
            IArtNftERC1155(address(artNft)).requireCanRequestMint(msg.sender, _tokenId, listing.amount);
        } else {
            IArtNftERC1155(address(artNft)).safeTransferFrom(msg.sender, address(this), _tokenId, _amount, "");
        }

        emit UpdatedFixedPrice(
            address(artNft),
            _tokenId,
            msg.sender,
            _amount,
            _listPrice,
            marketFee,
            starterFee,
            poolFee,
            royaltyReceiver,
            royaltyAmount
        );
    }

    function _getFeesAndRoyalty(uint256 _tokenId, uint256 _listPrice)
        internal
        view
        returns (
            uint256 marketFee,
            uint256 starterFee,
            uint256 poolFee,
            address royaltyReceiver,
            uint256 royaltyAmount
        )
    {
        marketFee = _toFee(_listPrice, marketplaceFeeBps);
        TokenFeesData memory feesData = _tokenFeesData[_tokenId][msg.sender];
        (starterFee, poolFee, ) = _splitListPrice(feesData, _listPrice);
        (royaltyReceiver, royaltyAmount) = IERC2981(address(artNft)).royaltyInfo(_tokenId, _listPrice);
    }

    function _updateFixedPriceListing(
        uint256 _tokenId,
        address _seller,
        uint256 _amount
    ) internal {
        FixedPriceListing memory listing = fixedPriceListings[_tokenId][_seller];

        if (listing.amount == _amount) {
            delete fixedPriceListings[_tokenId][_seller];
        } else if (listing.amount > _amount) {
            fixedPriceListings[_tokenId][_seller].amount -= _amount;
        } else {
            revert MktNotEnoughTokens();
        }
    }

    function _minting(FixedPriceListing memory listing, uint256 _tokenId) internal {
        if (!listing.minted) {
            IArtNftERC1155(address(artNft)).mintTo(_tokenId, address(this), listing.amount);
            fixedPriceListings[_tokenId][listing.seller].minted = true;
        }
        IArtNftERC1155(address(artNft)).safeTransferFrom(address(this), msg.sender, _tokenId, 1, "");
        pocNft.mint(msg.sender, listing.marketFee);
        pocNft.mint(listing.seller, listing.starterFee + listing.poolFee);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./IArtNft.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface IArtNftERC1155 is IERC1155, IArtNft {
    function lazyTotalSupply(uint256 _tokenId) external returns (uint256);

    function totalSupply(uint256 _tokenId) external returns (uint256);

    function mintTo(
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) external;

    function requireCanRequestMint(
        address _by,
        uint256 _tokenId,
        uint256 _amount
    ) external;

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./VCMarketplaceBase.sol";
import "../utils/FeeManager.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IArtNftERC1155.sol";
import "../interfaces/IArtNftERC721.sol";

contract VCMarketManager is FeeManager, AccessControl {
    error MktNoRoyalties();
    error MktMgrOnlyMarketplaceAllowed();
    error MktMgrInvalidPoolAmount();
    error MktMgrInvalidMarketplace();
    error MktMgrFailedToClaim();

    event RoyaltiesAccrued(address indexed creator, uint256 amount);
    event RoyaltiesClaimed(address indexed creator, address indexed receiver, uint256 amount);
    event TransfersApproved(address indexed user);

    address public marketplaceFixedPriceERC1155;
    address public marketplaceFixedPriceERC721;
    address public marketplaceAuctionERC721;
    address public pool;

    /// @notice Accrues royalties for royalty beneficiaries
    mapping(address => uint256) public royalties;
    mapping(uint256 => ListStatus) private _listStatusERC721;

    IArtNftERC1155 public artNftERC1155;
    IArtNftERC721 public artNftERC721;
    IERC20 public currency;
    IPoCNft public pocNft;

    uint256 private constant _MAX_UINT = 2**256 - 1;

    modifier onlyMarketplaces() {
        if (
            msg.sender != marketplaceFixedPriceERC1155 &&
            msg.sender != marketplaceFixedPriceERC721 &&
            msg.sender != marketplaceAuctionERC721
        ) {
            revert MktMgrOnlyMarketplaceAllowed();
        }
        _;
    }

    constructor(
        address _admin,
        address _marketplaceFixedPriceERC1155,
        address _marketplaceFixedPriceERC721,
        address _marketplaceAuctionERC721,
        address _artNftERC1155,
        address _artNftERC721,
        address _pool
    ) {
        marketplaceFixedPriceERC1155 = _marketplaceFixedPriceERC1155;
        marketplaceFixedPriceERC721 = _marketplaceFixedPriceERC721;
        marketplaceAuctionERC721 = _marketplaceAuctionERC721;

        artNftERC1155 = IArtNftERC1155(_artNftERC1155);
        artNftERC721 = IArtNftERC721(_artNftERC721);

        pool = _pool;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    // IDEA:
    // Governance should call these ones only, not the ones at each marketplace smart contract.
    // function setCurrency() onlyAdmin() {};
    // function all_other_sets() onlyAdmin {};

    function approveForAllMarketplaces() external {
        artNftERC1155.setApprovalForAllCustom(msg.sender, marketplaceFixedPriceERC1155, true);
        artNftERC721.setApprovalForAllCustom(msg.sender, marketplaceFixedPriceERC721, true);
        artNftERC721.setApprovalForAllCustom(msg.sender, marketplaceAuctionERC721, true);

        emit TransfersApproved(msg.sender);
    }

    function accrueRoyalty(address _receiver, uint256 _royaltyAmount) external onlyMarketplaces {
        royalties[_receiver] += _royaltyAmount;
        emit RoyaltiesAccrued(_receiver, _royaltyAmount);
    }

    // Desing:
    // - at each purchase or settlement, update a mapping here, mapping(address => uint256) royalties;
    // - send from either buyer or marketplace the amount to this smart contract
    // - remove claimRoyalty from each market
    function claimRoyalties(address _to, uint256 _poolAmount) external {
        uint256 claimAmount = royalties[msg.sender];
        if (claimAmount == 0) {
            revert MktNoRoyalties();
        }
        if (_poolAmount > claimAmount) {
            revert MktMgrInvalidPoolAmount();
        }

        royalties[msg.sender] = 0;

        currency.transfer(_to, claimAmount - _poolAmount);

        if (_poolAmount > 0) {
            if (!currency.transfer(pool, _poolAmount)) {
                revert MktMgrFailedToClaim();
            }
            pocNft.mint(msg.sender, _poolAmount);
        }

        emit RoyaltiesClaimed(msg.sender, _to, claimAmount);
    }

    // CAREFULL WITH AUCTION
    function marketplaceWithdrawTo(
        uint256 _marketplace,
        address _token,
        address _to,
        uint256 _amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (_marketplace == 0) {
            VCMarketplaceBase(marketplaceFixedPriceERC1155).withdrawTo(_token, _to, _amount);
        } else if (_marketplace == 1) {
            VCMarketplaceBase(marketplaceFixedPriceERC721).withdrawTo(_token, _to, _amount);
        } else if (_marketplace == 2) {
            VCMarketplaceBase(marketplaceAuctionERC721).withdrawTo(_token, _to, _amount);
        } else {
            revert MktMgrInvalidMarketplace();
        }
    }

    function setCurrency(IERC20 _currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = _currency;
        VCMarketplaceBase(marketplaceAuctionERC721).setCurrency(_currency);
        VCMarketplaceBase(marketplaceFixedPriceERC1155).setCurrency(_currency);
        VCMarketplaceBase(marketplaceFixedPriceERC721).setCurrency(_currency);
    }

    function setPoCNft(address _pocNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pocNft = IPoCNft(_pocNft);
        VCMarketplaceBase(marketplaceAuctionERC721).setPoCNft(_pocNft);
        VCMarketplaceBase(marketplaceFixedPriceERC1155).setPoCNft(_pocNft);
        VCMarketplaceBase(marketplaceFixedPriceERC721).setPoCNft(_pocNft);
    }

    function setMinTotalFeeBps(uint96 _minTotalFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VCMarketplaceBase(marketplaceFixedPriceERC1155).setMinTotalFeeBps(_minTotalFeeBps);
        VCMarketplaceBase(marketplaceFixedPriceERC721).setMinTotalFeeBps(_minTotalFeeBps);
        VCMarketplaceBase(marketplaceAuctionERC721).setMinTotalFeeBps(_minTotalFeeBps);
    }

    function setMarketplaceFeeBps(uint256 _marketplaceFeeBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VCMarketplaceBase(marketplaceFixedPriceERC1155).setMarketplaceFeeBps(_marketplaceFeeBps);
        VCMarketplaceBase(marketplaceFixedPriceERC721).setMarketplaceFeeBps(_marketplaceFeeBps);
        VCMarketplaceBase(marketplaceAuctionERC721).setMarketplaceFeeBps(_marketplaceFeeBps);
    }

    function setMaxBeneficiaryProjects(uint96 _maxBeneficiaryProjects) external onlyRole(DEFAULT_ADMIN_ROLE) {
        VCMarketplaceBase(marketplaceFixedPriceERC1155).setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        VCMarketplaceBase(marketplaceFixedPriceERC721).setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
        VCMarketplaceBase(marketplaceAuctionERC721).setMaxBeneficiaryProjects(_maxBeneficiaryProjects);
    }

    function setListStatusERC721(uint256 _tokenId, bool listed) external {
        if (msg.sender == marketplaceFixedPriceERC721) {
            if (listed) {
                _listStatusERC721[_tokenId] = ListStatus.FIXED_PRICE;
            } else {
                _listStatusERC721[_tokenId] = ListStatus.NOT_LISTED;
            }
        } else if (msg.sender == marketplaceAuctionERC721) {
            if (listed) {
                _listStatusERC721[_tokenId] = ListStatus.AUCTION;
            } else {
                _listStatusERC721[_tokenId] = ListStatus.NOT_LISTED;
            }
        } else {
            revert MktMgrOnlyMarketplaceAllowed();
        }
    }

    function getListStatusERC721(uint256 _tokenId) external view returns (ListStatus) {
        return _listStatusERC721[_tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";

contract VotingPowerBoost is AccessControl {
    event NewModelCreated(uint256 timestamp);

    error InvalidModelParams();
    error MktUnexpectedGovernanceAddress();
    error MktUnexpectedPoolAddress();
    error MktUnexpectedStarterAddress();

    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    uint256 private _boostDuration;

    uint256[] private _contributionLimits;
    uint256[] private _weightLimits;

    constructor(
        address _admin,
        uint256 _boostTime,
        uint128[] memory _cMax,
        uint128[] memory _wMax
    ) {
        if (_admin == address(this) || _admin == address(0)) {
            revert MktUnexpectedGovernanceAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);

        _checkAndCreateModel(_cMax, _wMax);
        _boostDuration = _boostTime;
    }

    function getBoostDuration() public view returns (uint256) {
        return _boostDuration;
    }

    function createModel(uint128[] memory _cMax, uint128[] memory _wMax) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _deletePreviousModel();
        _checkAndCreateModel(_cMax, _wMax);
        emit NewModelCreated(block.timestamp);
    }

    function calculateVotingPowerBoost(uint256 _contribution) public view returns (uint256 votingPowerBoost) {
        if (_contribution == 0) {
            return 0;
        }
        uint256 maxLength = _weightLimits.length - 1;

        for (uint256 i = 0; i < _contributionLimits.length - 1; i++) {
            if (_contribution < _contributionLimits[i]) {
                uint256 m = (_weightLimits[i] - _weightLimits[i - 1]) /
                    (_contributionLimits[i] - _contributionLimits[i - 1]);
                uint256 b = _weightLimits[i - 1] - (m * _contributionLimits[i - 1]);
                votingPowerBoost = m * _contribution + b;
                break;
            } else if (_contribution > _contributionLimits[maxLength]) {
                uint256 m = (_weightLimits[maxLength] - _weightLimits[maxLength - 1]) /
                    (_contributionLimits[maxLength] - _contributionLimits[maxLength - 1]);
                uint256 b = _weightLimits[maxLength - 1] - (m * _contributionLimits[maxLength - 1]);
                votingPowerBoost = m * _contribution + b;
            }
        }
    }

    function getContributionLimits() external view returns (uint256[] memory) {
        return _contributionLimits;
    }

    function getWeightLimits() external view returns (uint256[] memory) {
        return _weightLimits;
    }

    function _checkAndCreateModel(uint128[] memory _cMax, uint128[] memory _wMax) private {
        if (_cMax.length != _wMax.length) {
            revert InvalidModelParams();
        }
        for (uint256 i = 0; i < _cMax.length; i++) {
            if (i == 0) {
                if (_cMax[i] == 0 || _wMax[i] == 0) {
                    revert InvalidModelParams();
                } else {
                    _contributionLimits.push(_cMax[i]);
                    _weightLimits.push(_wMax[i]);
                }
            } else {
                if (_cMax[i] == 0 || _cMax[i - 1] > _cMax[i]) {
                    revert InvalidModelParams();
                }
                _contributionLimits.push(_cMax[i]);
                if (_wMax[i] == 0 || _wMax[i - 1] > _wMax[i]) {
                    revert InvalidModelParams();
                }
                _weightLimits.push(_wMax[i]);
            }
        }
    }

    function _deletePreviousModel() private {
        if (_contributionLimits.length > 0) {
            delete _contributionLimits;
            delete _weightLimits;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IVotingPowerBoost.sol";

struct Contribution {
    uint256 amount;
    uint256 timestamp;
}

/**
 * @title Mints an NFT to the user that funded a project and the campaign succeeds, the NFT
 * gives the user a multiplier that helps boosting the voting power.
 * @notice Mint function can be called only by VCStarter
 */
contract PoCNft is ERC721, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    event ContributionNFTMinted(address indexed user, uint256 tokenId);

    error MktUnexpectedStarterAddress();
    error MktUnexpectedPoolAddress();

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    IVotingPowerBoost private _iVotingPowerBoost;

    /// @notice Maps the user to all the donations the user has made.
    mapping(address => Contribution[]) private _contributions;

    constructor(
        string memory name,
        string memory symbol,
        address _starter,
        address _pool,
        address _marketManager,
        address _marketplaceFixedPrice1155,
        address _marketplaceFixedPrice721,
        address _marketplaceAuction721,
        address _votingPowerBoost
    ) ERC721(name, symbol) {
        // starter can change??
        if (_starter == address(this) || _starter == address(0)) {
            revert MktUnexpectedStarterAddress();
        }
        // pool can change?
        if (_pool == address(this) || _pool == address(0)) {
            revert MktUnexpectedPoolAddress();
        }

        _grantRole(MINTER_ROLE, _starter);
        _grantRole(MINTER_ROLE, _pool);
        _grantRole(MINTER_ROLE, _marketManager);
        _grantRole(MINTER_ROLE, _marketplaceFixedPrice1155);
        _grantRole(MINTER_ROLE, _marketplaceFixedPrice721);
        _grantRole(MINTER_ROLE, _marketplaceAuction721);
        _iVotingPowerBoost = IVotingPowerBoost(_votingPowerBoost);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    /**
     *@dev Mints a Contribution NFT to the given user
     *
     * @param _user User which will receive the NFT
     * @param _amount The total amount the user has contributed
     */

    // puede ser llamada por starter en caso de que la campaña gane directamente
    //
    function mint(address _user, uint256 _amount) public onlyRole(MINTER_ROLE) {
        uint256 tokenId = _tokenId.current();
        _mint(_user, tokenId);
        _tokenId.increment();
        _contributions[_user].push(Contribution(_amount, block.timestamp));
        emit ContributionNFTMinted(_user, tokenId);
    }

    /**
     *@dev Calculates the voting power boost for the given user
     *
     *@param _user User to calculate its voting power boost
     */
    function getVotingPowerBoost(address _user) external view returns (uint256 votingPowerBoost) {
        Contribution[] memory userContributions = _contributions[_user];
        uint256 numberOfContributions = userContributions.length;
        uint256 boostDuration = _iVotingPowerBoost.getBoostDuration();

        uint256 totalEffectiveContributions;

        for (uint256 i = numberOfContributions; i > 0; i--) {
            Contribution memory _contribution = userContributions[i - 1];
            if (block.timestamp > _contribution.timestamp + boostDuration) {
                break;
            }
            totalEffectiveContributions +=
                _contribution.amount *
                (1 - (block.timestamp - _contribution.timestamp) / boostDuration);
        }
        votingPowerBoost = _iVotingPowerBoost.calculateVotingPowerBoost(totalEffectiveContributions);
    }

    function getContribution(address _user) external view returns (Contribution[] memory) {
        return _contributions[_user];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IVotingPowerBoost {
    function getBoostDuration() external view returns (uint256);

    function calculateVotingPowerBoost(uint256 _contribution) external view returns (uint256 votingPowerBoost);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/// @notice A batch represents a collection of assets, each one with only one copy
struct Batch {
    string cid;
    string name;
    address creator;
    uint256 firstTokenId;
    uint256 size;
}

contract ArtNftERC721 is ERC2981, AccessControl, ERC721 {
    error ArtOnlyCreatorCanRequest();
    error ArtBatchSizeError();
    error ArtExceededMaxRoyalty();
    error ArtAlreadyMinted();
    error ArtTokenNotYetCreated();
    error ArtRoyaltyBeneficaryZeroAddress();

    using Strings for uint256;

    /// @notice Anyone can lazy mint, but only Minters can mint
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Only Marketplace Manager can approve transfers for anyone
    bytes32 public constant MARKET_MANAGER_ROLE = keccak256("MARKET_MANAGER_ROLE");

    /// @notice Maps a token Id to its batch.
    Batch[] public tokenBatch;
    /// @notice Maps from tokenId to its batchId. Batchs ids run from 1, batchId=0 means that token was not yet created.
    mapping(uint256 => uint256) private _tokenIdToBatchId;

    uint256 public maxRoyaltyBps;
    uint256 public maxBatchSize;

    event BatchCreated(address indexed creator, uint256 batchId, Batch batch, uint96 royaltyBps);

    modifier onlyTokenCreator(uint256 _tokenId) {
        require(msg.sender == creatorOf(_tokenId));
        _;
    }

    constructor(
        uint256 _maxRoyaltyBps,
        uint256 _maxBatchSize,
        address _admin
    ) ERC721("VC-ArtNFT", "VCART") {
        maxRoyaltyBps = _maxRoyaltyBps;
        maxBatchSize = _maxBatchSize;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function grantMinterRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _address);
    }

    function setManager(address _marketplaceManager) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MARKET_MANAGER_ROLE, _marketplaceManager);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxRoyaltyBps = _maxRoyaltyBps;
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBatchSize = _maxBatchSize;
    }

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external onlyRole(MARKET_MANAGER_ROLE) {
        _setApprovalForAll(caller, operator, approved);
    }

    function lazyMintBatch(
        string calldata _cid,
        string calldata _name,
        uint256 _batchSize,
        address _receiver,
        uint96 _royaltyFeeBps
    ) external {
        if (0 == _batchSize || _batchSize > maxBatchSize) {
            revert ArtBatchSizeError();
        }
        if (_royaltyFeeBps > maxRoyaltyBps) {
            revert ArtExceededMaxRoyalty();
        }
        if (_receiver == address(0)) {
            revert ArtRoyaltyBeneficaryZeroAddress();
        }

        // batchId starts at one
        uint256 currentBatchId = tokenBatch.length + 1;
        uint256 firstTokenId = currentBatchId == 1
            ? 0
            : tokenBatch[currentBatchId - 2].firstTokenId + tokenBatch[currentBatchId - 2].size;

        address creator = msg.sender;
        Batch memory newBatch = Batch(_cid, _name, creator, firstTokenId, _batchSize);

        tokenBatch.push(newBatch);

        for (uint256 tokenId = firstTokenId; tokenId < firstTokenId + _batchSize; tokenId++) {
            _tokenIdToBatchId[tokenId] = currentBatchId;
            _setTokenRoyalty(tokenId, _receiver, _royaltyFeeBps);
        }

        emit BatchCreated(creator, currentBatchId, newBatch, _royaltyFeeBps);
    }

    function requireCanRequestMint(address _by, uint256 _tokenId) public view {
        if (_exists(_tokenId)) {
            revert ArtAlreadyMinted();
        }
        if (_by != creatorOf(_tokenId)) {
            revert ArtOnlyCreatorCanRequest();
        }
    }

    function mint(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        address creator = creatorOf(_tokenId);
        _mint(creator, _tokenId);
    }

    function mintTo(uint256 _tokenId, address _to) external onlyRole(MINTER_ROLE) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        _mint(_to, _tokenId);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        Batch memory batch = tokenBatch[batchId - 1];
        uint256 batchTokenId = _tokenId - batch.firstTokenId;
        return string(abi.encodePacked(_baseURI(), batch.cid, "/", batchTokenId.toString()));
    }

    function creatorOf(uint256 _tokenId) public view virtual returns (address) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        address creator = tokenBatch[batchId - 1].creator;
        return creator;
    }

    function setTokenRoyaltyReceiver(uint256 _tokenId, address _receiver) external onlyTokenCreator(_tokenId) {
        if (_receiver == address(0)) {
            revert ArtRoyaltyBeneficaryZeroAddress();
        }
        (, uint256 royaltyFeeBps) = royaltyInfo(_tokenId, uint256(_feeDenominator()));
        _setTokenRoyalty(_tokenId, _receiver, uint96(royaltyFeeBps));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, AccessControl, ERC721)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function exists(uint256 _tokenId) public view returns (bool) {
        return _exists(_tokenId);
    }

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io/ipfs/";
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

/// @notice A batch represents a collection of assets, each one with a given number of copies (i.e. `totalSupplies`)
struct Batch {
    string cid;
    string name;
    address creator;
    uint256 firstTokenId;
    uint256[] totalSupplies;
}

contract ArtNftERC1155 is ERC2981, AccessControl, ERC1155Supply {
    error ArtOnlyCreatorCanRequest();
    error ArtBatchSizeError();
    error ArtExceededMaxRoyalty();
    error ArtAlreadyMinted();
    error ArtExceededTotalSupply();
    error ArtTokenNotYetCreated();
    error ArtTokenAlreadyMinted();
    error ArtTotalSupplyZero();
    error ArtRoyaltyBeneficaryZeroAddress();

    using Strings for uint256;

    /// @notice Anyone can lazy mint, but only Minters can mint
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @notice Maps from batchId to its batch.
    Batch[] public tokenBatch;

    /// @notice Maps from tokenId to its batchId. Batchs ids run from 1, batchId=0 means that token was not yet created.
    mapping(uint256 => uint256) private _tokenIdToBatchId;

    uint256 public maxRoyaltyBps;
    uint256 public maxBatchSize;

    event BatchCreated(address indexed creator, uint256 batchId, Batch batch, uint96 royaltyBps);

    modifier onlyTokenCreator(uint256 _tokenId) {
        require(msg.sender == creatorOf(_tokenId));
        _;
    }

    constructor(
        uint256 _maxRoyaltyBps,
        uint256 _maxBatchSize,
        address _admin
    ) ERC1155("https://ipfs.io/ipfs/") {
        maxRoyaltyBps = _maxRoyaltyBps;
        maxBatchSize = _maxBatchSize;
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function grantMinterRole(address _address) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(MINTER_ROLE, _address);
    }

    function setMaxRoyalty(uint256 _maxRoyaltyBps) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxRoyaltyBps = _maxRoyaltyBps;
    }

    function setMaxBatchSize(uint256 _maxBatchSize) external onlyRole(DEFAULT_ADMIN_ROLE) {
        maxBatchSize = _maxBatchSize;
    }

    function setApprovalForAllCustom(
        address caller,
        address operator,
        bool approved
    ) external {
        _setApprovalForAll(caller, operator, approved);
    }

    function lazyMintBatch(
        string calldata _cid,
        string calldata _name,
        uint256[] calldata _totalSupplies,
        address _receiver,
        uint96 _royaltyFeeBps
    ) external {
        uint256 batchSize = _totalSupplies.length;

        if (0 == batchSize || batchSize > maxBatchSize) {
            revert ArtBatchSizeError();
        }
        if (_royaltyFeeBps > maxRoyaltyBps) {
            revert ArtExceededMaxRoyalty();
        }
        if (_receiver == address(0)) {
            revert ArtRoyaltyBeneficaryZeroAddress();
        }

        // batchId starts at one
        uint256 currentBatchId = tokenBatch.length + 1;
        uint256 firstTokenId = currentBatchId == 1
            ? 0
            : tokenBatch[currentBatchId - 2].firstTokenId + tokenBatch[currentBatchId - 2].totalSupplies.length;

        address creator = msg.sender;
        Batch memory newBatch = Batch(_cid, _name, creator, firstTokenId, _totalSupplies);

        tokenBatch.push(newBatch);

        for (uint256 i = 0; i < batchSize; i++) {
            if (_totalSupplies[i] == 0) {
                revert ArtTotalSupplyZero();
            }
            uint256 tokenId = firstTokenId + i;
            _tokenIdToBatchId[tokenId] = currentBatchId;
            _setTokenRoyalty(tokenId, _receiver, _royaltyFeeBps);
        }

        emit BatchCreated(creator, currentBatchId, newBatch, _royaltyFeeBps);
    }

    function requireCanRequestMint(
        address _by,
        uint256 _tokenId,
        uint256 _amount
    ) public view {
        if (exists(_tokenId)) {
            revert ArtAlreadyMinted();
        }
        if (_by != creatorOf(_tokenId)) {
            revert ArtOnlyCreatorCanRequest();
        }
        if (_amount > lazyTotalSupply(_tokenId)) {
            revert ArtExceededTotalSupply();
        }
    }

    function lazyTotalSupply(uint256 _tokenId) public view returns (uint256) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        Batch memory batch = tokenBatch[batchId - 1];
        uint256 batchTokenId = _tokenId - batch.firstTokenId;
        uint256 totalSupply = batch.totalSupplies[batchTokenId];
        return totalSupply;
    }

    function mint(uint256 _tokenId) external onlyRole(MINTER_ROLE) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        if (exists(_tokenId)) {
            revert ArtAlreadyMinted();
        }

        uint256 totalSupply = lazyTotalSupply(_tokenId);
        address creator = creatorOf(_tokenId);

        _mint(creator, _tokenId, totalSupply, "");
    }

    function mintTo(
        uint256 _tokenId,
        address _to,
        uint256 _amount
    ) external onlyRole(MINTER_ROLE) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        if (exists(_tokenId)) {
            revert ArtTokenAlreadyMinted();
        }

        uint256 totalSupply = lazyTotalSupply(_tokenId);

        if (_amount > totalSupply) {
            revert ArtExceededTotalSupply();
        }

        address creator = creatorOf(_tokenId);

        if (totalSupply != _amount) {
            _mint(creator, _tokenId, totalSupply - _amount, "");
        }
        _mint(_to, _tokenId, _amount, "");
    }

    function tokenURI(uint256 _tokenId) public view virtual returns (string memory) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        Batch memory batch = tokenBatch[batchId - 1];
        uint256 batchTokenId = _tokenId - batch.firstTokenId;
        return string(abi.encodePacked(uri(_tokenId), batch.cid, "/", batchTokenId.toString()));
    }

    function creatorOf(uint256 _tokenId) public view virtual returns (address) {
        uint256 batchId = _tokenIdToBatchId[_tokenId];
        if (batchId == 0) {
            revert ArtTokenNotYetCreated();
        }
        address creator = tokenBatch[batchId - 1].creator;
        return creator;
    }

    function setTokenRoyaltyReceiver(uint256 _tokenId, address _receiver) external onlyTokenCreator(_tokenId) {
        if (_receiver == address(0)) {
            revert ArtRoyaltyBeneficaryZeroAddress();
        }
        (, uint256 royaltyFeeBps) = royaltyInfo(_tokenId, uint256(_feeDenominator()));
        _setTokenRoyalty(_tokenId, _receiver, uint96(royaltyFeeBps));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC2981, AccessControl, ERC1155)
        returns (bool)
    {
        return
            interfaceId == type(IERC2981).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC1155/extensions/ERC1155Supply.sol)

pragma solidity ^0.8.0;

import "../ERC1155.sol";

/**
 * @dev Extension of ERC1155 that adds tracking of total supply per id.
 *
 * Useful for scenarios where Fungible and Non-fungible tokens have to be
 * clearly identified. Note: While a totalSupply of 1 might mean the
 * corresponding is an NFT, there is no guarantees that no other token with the
 * same id are not going to be minted.
 */
abstract contract ERC1155Supply is ERC1155 {
    mapping(uint256 => uint256) private _totalSupply;

    /**
     * @dev Total amount of tokens in with a given id.
     */
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    /**
     * @dev Indicates whether any token exist with a given id, or not.
     */
    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

    /**
     * @dev See {ERC1155-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                uint256 id = ids[i];
                uint256 amount = amounts[i];
                uint256 supply = _totalSupply[id];
                require(supply >= amount, "ERC1155: burn amount exceeds totalSupply");
                unchecked {
                    _totalSupply[id] = supply - amount;
                }
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "../interfaces/IPoCNft.sol";

contract VCPool is AccessControl {
    error PoolContributionFailed();
    error PoolUnexpectedGovernanceAddress();

    event UserContributed(address indexed user, uint256 amount);

    // bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @notice Protocol currency
    IERC20 public currency;
    /// @notice Proof of Collaboration NFT
    IPoCNft public pocNft;
    address public starter;

    modifier onlyStarter() {
        if (msg.sender != starter) {
            revert(); // add custom error
        }
        _;
    }

    /**
     * @notice constructor of the contract
     *
     * @param _currency The protocol's ERC20 token used as currency.
     * @param _admin The VC Governance address.
     */
    constructor(IERC20 _currency, address _admin) {
        if (_admin == address(this) || _admin == address(0)) {
            revert PoolUnexpectedGovernanceAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        currency = _currency;
    }

    function supportPool(uint256 _amount) external {
        if (!currency.transferFrom(msg.sender, address(this), _amount)) {
            revert PoolContributionFailed();
        }
        pocNft.mint(msg.sender, _amount);
        emit UserContributed(msg.sender, _amount);
    }

    function supportPoolFromStarter(address _supporter, uint256 _amount) external onlyStarter {
        pocNft.mint(_supporter, _amount);
        emit UserContributed(_supporter, _amount);
    }

    // this is set during deployment, so far can not be changed again
    function setStarter(address _starter) external onlyRole(DEFAULT_ADMIN_ROLE) {
        starter = _starter;
    }

    function setPoCNft(address _pocNft) external onlyRole(DEFAULT_ADMIN_ROLE) {
        pocNft = IPoCNft(_pocNft);
    }

    function setCurrency(IERC20 _currency) external onlyRole(DEFAULT_ADMIN_ROLE) {
        currency = _currency;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IPoCNft.sol";
import "../interfaces/IVCPool.sol";
import "./VCProject.sol";

import {Errors} from "./Errors.sol";

contract VCStarter {
    event SttrWhitelistedLab(address indexed lab);
    event SttrBlacklistedLab(address indexed lab);
    event SttrWhitelistedResearcher(address indexed researcher);
    event SttrBlacklistedResearcher(address indexed researcher);
    event SttrCurrencyListed(IERC20 indexed currency);
    event SttrCurrencyUnlisted(IERC20 indexed currency);
    event SttrSetMinCampaignDuration(uint256 minCampaignDuration);
    event SttrSetMaxCampaignDuration(uint256 maxCampaignDuration);
    event SttrSetMinCampaignTarget(uint256 minCampaignTarget);
    event SttrSetMaxCampaignTarget(uint256 maxCampaignTarget);
    event SttrSetSoftTargetBps(uint256 softTargetBps);
    event SttrPoCNftSet(IPoCNft indexed poCNft);
    event SttrCampaignStarted(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        uint256 startTime,
        uint256 endTime,
        uint256 backersDeadline,
        uint256 target,
        uint256 softTarget
    );
    event SttrCampaignFunding(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        IERC20 currency,
        address user,
        uint256 amount
    );
    event SttrCampaignFunded(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrCampaignSucceded(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrCampaignDefeated(address indexed lab, address indexed project, uint256 indexed campaignId);
    event SttrLabCampaignWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaignId,
        IERC20 currency,
        uint256 amount
    );
    event SttrLabWithdrawal(address indexed lab, address indexed project, IERC20 currency, uint256 amount);
    event SttrwithdrawToPool(address indexed project, IERC20 indexed currency, uint256 amount);
    event SttrBackerMintPoCNft(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrBackerWithdrawal(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrUnclaimedFundsTransferredToPool(
        address indexed lab,
        address indexed project,
        uint256 indexed campaign,
        IERC20 currency,
        uint256 amount
    );
    event SttrProjectFunded(
        address indexed lab,
        address indexed project,
        address indexed backer,
        IERC20 currency,
        uint256 amount
    );
    event SttrProjectActivated(address indexed project);
    event SttrProjectClosed(address indexed lab, address indexed project);
    event SttrProjectRequest(address indexed lab);
    event SttrProjectCreated(address indexed lab, address indexed project);
    event SttrProjectCreationRejected(address indexed lab);
    event SttrCampaingClosed(address indexed lab, address indexed project, uint256 campaignId);

    /// @notice A project contract template cloned for each project
    address _projectTemplate;
    address _admin;
    address _coreTeam; // multisig of the VC CORE team
    address _pool;
    address _txValidator;
    uint256 _starterFeeBps;
    IPoCNft _poCNft;

    /// @notice The list of laboratories
    mapping(address => bool) _isWhitelistedLab;

    mapping(address => bool) _pendingProjectRequest;
    mapping(address => address) _projectToLab;
    mapping(address => bool) _activeProjects;

    mapping(IERC20 => bool) _allowedCurrencies;

    uint256 _minCampaignDuration;
    uint256 _maxCampaignDuration;
    uint256 _minCampaignTarget;
    uint256 _maxCampaignTarget;
    uint256 _softTargetBps;

    uint256 constant _FEE_DENOMINATOR = 10_000;

    /// @notice amount of seconds to wait for lab operation
    uint256 _backersTimeout = 15 days;

    constructor(
        address pool,
        address admin,
        address coreTeam,
        address txValidator,
        address projectTemplate,
        uint256 minCampaignDuration,
        uint256 maxCampaignDuration,
        uint256 minCampaignTarget,
        uint256 maxCampaignTarget,
        uint256 softTargetBps,
        uint256 starterFeeBps
    ) {
        _admin = admin;
        _pool = pool;
        _coreTeam = coreTeam;
        _projectTemplate = projectTemplate;
        _txValidator = txValidator;

        _minCampaignDuration = minCampaignDuration;
        _maxCampaignDuration = maxCampaignDuration;
        _minCampaignTarget = minCampaignTarget;
        _maxCampaignTarget = maxCampaignTarget;
        _softTargetBps = softTargetBps;
        _starterFeeBps = starterFeeBps;
    }

    /*********** ONLY-ADMIN / ONLY-CORE_TEAM FUNCTIONS ***********/

    function changeAdmin(address admin) external {
        _onlyAdmin();
        _admin = admin;
    }

    function whitelistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == true) {
            revert Errors.SttrLabAlreadyWhitelisted();
        }
        _isWhitelistedLab[lab] = true;
        emit SttrWhitelistedLab(lab);
    }

    function blacklistLab(address lab) external {
        _onlyCoreTeam();

        if (_isWhitelistedLab[lab] == false) {
            revert Errors.SttrLabAlreadyBlacklisted();
        }
        _isWhitelistedLab[lab] = false;
        emit SttrBlacklistedLab(lab);
    }

    // add struct to store decimals of each currency
    function listCurrency(IERC20 currency) external {
        _onlyAdmin();
        if (_allowedCurrencies[currency] == true) {
            revert Errors.SttrCurrencyAlreadyListed();
        }
        _allowedCurrencies[currency] = true;
        emit SttrCurrencyListed(currency);
    }

    function unlistCurrency(IERC20 currency) external {
        _onlyAdmin();
        if (_allowedCurrencies[currency] == false) {
            revert Errors.SttrCurrencyAlreadyUnlisted();
        }
        _allowedCurrencies[currency] = false;
        emit SttrCurrencyUnlisted(currency);
    }

    function setMinCampaignDuration(uint256 minCampaignDuration) external {
        _onlyAdmin();
        if (_minCampaignDuration == minCampaignDuration || minCampaignDuration >= _maxCampaignDuration) {
            revert Errors.SttrMinCampaignDurationError();
        }
        _minCampaignDuration = minCampaignDuration;
        emit SttrSetMinCampaignDuration(_minCampaignDuration);
    }

    function setMaxCampaignDuration(uint256 maxCampaignDuration) external {
        _onlyAdmin();
        if (_maxCampaignDuration == maxCampaignDuration || maxCampaignDuration <= _minCampaignDuration) {
            revert Errors.SttrMaxCampaignDurationError();
        }
        _maxCampaignDuration = maxCampaignDuration;
        emit SttrSetMaxCampaignDuration(_maxCampaignDuration);
    }

    function setMinCampaignTarget(uint256 minCampaignTarget) external {
        _onlyAdmin();
        if (_minCampaignTarget == minCampaignTarget || minCampaignTarget >= _maxCampaignTarget) {
            revert Errors.SttrMinCampaignTargetError();
        }
        _minCampaignTarget = minCampaignTarget;
        emit SttrSetMinCampaignTarget(minCampaignTarget);
    }

    function setMaxCampaignTarget(uint256 maxCampaignTarget) external {
        _onlyAdmin();
        if (_maxCampaignTarget == maxCampaignTarget || maxCampaignTarget <= _minCampaignTarget) {
            revert Errors.SttrMaxCampaignTargetError();
        }
        _maxCampaignTarget = maxCampaignTarget;
        emit SttrSetMaxCampaignTarget(_maxCampaignTarget);
    }

    function setSoftTargetBps(uint256 softTargetBps) external {
        _onlyAdmin();
        if (_softTargetBps == softTargetBps || softTargetBps > _FEE_DENOMINATOR) {
            revert Errors.SttrSoftTargetBpsError();
        }
        _softTargetBps = softTargetBps;
        emit /*Events.*/
        SttrSetSoftTargetBps(_softTargetBps);
    }

    function setPoCNft(address _pocNft) external {
        _onlyAdmin();
        _poCNft = IPoCNft(_pocNft);
        emit SttrPoCNftSet(_poCNft);
    }

    function createProject(address _lab, bool _accepted) external returns (address newProject) {
        _onlyCoreTeam();

        if (!_pendingProjectRequest[_lab]) {
            revert Errors.SttrNonExistingProjectRequest();
        }
        _pendingProjectRequest[_lab] = false;

        if (_accepted) {
            newProject = Clones.clone(_projectTemplate);
            _activeProjects[newProject] = true;
            VCProject(newProject).init(address(this), _lab);
            _projectToLab[newProject] = _lab;
            emit SttrProjectCreated(_lab, newProject);
        } else {
            emit SttrProjectCreationRejected(_lab);
        }
    }

    /*********** EXTERNAL AND PUBLIC METHODS ***********/

    function createProjectRequest() external {
        _onlyWhitelistedLab();

        if (_pendingProjectRequest[msg.sender]) {
            revert Errors.SttrExistingProjectRequest();
        }
        _pendingProjectRequest[msg.sender] = true;
        emit SttrProjectRequest(msg.sender);
    }

    function fundProject(
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external {
        address lab = _fundProject(_project, _currency, _amount);
        _poCNft.mint(msg.sender, _amount);
        emit SttrProjectFunded(lab, _project, msg.sender, _currency, _amount);
    }

    function fundProjectOnBehalf(
        address _user,
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) external {
        address lab = _fundProject(_project, _currency, _amount);
        _poCNft.mint(_user, _amount);
        emit SttrProjectFunded(lab, _project, _user, _currency, _amount);
    }

    function closeProject(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        _verifyCloseProject(_project, _sig);
        VCProject(_project).closeProject();
        _activeProjects[_project] = false;
        emit SttrProjectClosed(msg.sender, _project);
    }

    function startCampaign(
        address _project,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) external returns (uint256) {
        _onlyWhitelistedLab();
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = VCProject(_project).getNumberOfCampaigns();
        _verifyStartCampaign(_project, numberOfCampaigns, _target, _duration, _sig);

        if (_target < _minCampaignTarget || _target > _maxCampaignTarget) {
            revert Errors.SttrCampaignTargetError();
        }
        if (_duration < _minCampaignDuration || _duration > _maxCampaignDuration) {
            revert Errors.SttrCampaignDurationError();
        }
        uint256 softTarget = (_target * _softTargetBps) / _FEE_DENOMINATOR;
        uint256 campaignId = VCProject(_project).startCampaign(
            _target,
            softTarget,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout
        );
        emit SttrCampaignStarted(
            msg.sender,
            _project,
            campaignId,
            block.timestamp,
            block.timestamp + _duration,
            block.timestamp + _duration + _backersTimeout,
            _target,
            softTarget
        );
        return campaignId;
    }

    function publishCampaignResults(address _project, bytes memory _sig) external {
        _onlyLabOwner(_project);

        uint256 numberOfCampaigns = VCProject(_project).getNumberOfCampaigns();
        if (numberOfCampaigns == 0) {
            revert Errors.SttrResultsCannotBePublished();
        }

        uint256 currentCampaignId = numberOfCampaigns - 1;
        _verifyPublishCampaignResults(_project, currentCampaignId, _sig);
        VCProject(_project).publishCampaignResults();
        emit SttrCampaingClosed(msg.sender, _project, currentCampaignId);
    }

    function fundCampaign(
        address _project,
        uint256 _amount,
        IERC20 _currency
    ) external {
        address lab = _checkBeforeFund(_project, _amount, _currency);

        (uint256 campaignId, uint256 amountToCampaign, uint256 amountToPool, bool isFunded) = VCProject(_project)
            .getFundingAmounts(_amount);
        if (!_currency.transferFrom(msg.sender, _project, amountToCampaign)) {
            revert Errors.SttrERC20TransferError();
        }
        VCProject(_project).fundCampaign(_currency, msg.sender, amountToCampaign);
        emit SttrCampaignFunding(lab, _project, campaignId, _currency, msg.sender, amountToCampaign);

        if (amountToPool > 0) {
            if (!_currency.transferFrom(msg.sender, _pool, amountToPool)) {
                revert Errors.SttrERC20TransferError();
            }
            IVCPool(_pool).supportPoolFromStarter(msg.sender, amountToPool);
        }
        if (isFunded) {
            emit SttrCampaignFunded(lab, _project, campaignId);
        }
    }

    function backerMintPoCNft(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        uint256 amount = VCProject(_project).validateMint(_campaignId, _currency, msg.sender);
        _poCNft.mint(msg.sender, amount);
        emit SttrBackerMintPoCNft(_projectToLab[_project], _project, _campaignId, _currency, amount);
    }

    function backerWithdrawDefeated(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        (uint256 backerAmount, bool campaignDefeated) = VCProject(_project).backerWithdrawDefeated(
            _campaignId,
            msg.sender,
            _currency
        );
        emit SttrBackerWithdrawal(_projectToLab[_project], _project, _campaignId, _currency, backerAmount);
        if (campaignDefeated) {
            emit SttrCampaignDefeated(_projectToLab[_project], _project, _campaignId);
        }
    }

    function labCampaignWithdraw(address _project, IERC20 _currency) external {
        _onlyLabOwner(_project);

        (uint256 campaignId, uint256 withdrawAmount, bool campaignSucceeded) = VCProject(_project).labCampaignWithdraw(
            _currency
        );
        emit SttrLabCampaignWithdrawal(msg.sender, _project, campaignId, _currency, withdrawAmount);
        if (campaignSucceeded) {
            emit SttrCampaignSucceded(_projectToLab[_project], _project, campaignId);
        }
    }

    function labWithraw(address _project, IERC20 _currency) external {
        _onlyLabOwner(_project);

        uint256 amount = VCProject(_project).labWithdraw(_currency);
        emit SttrLabWithdrawal(msg.sender, _project, _currency, amount);
    }

    function transferUnclaimedFunds(
        address _project,
        uint256 _campaignId,
        IERC20 _currency
    ) external {
        address lab = _projectToLab[_project];
        (uint256 amountToPool, bool statusDefeated) = VCProject(_project).transferUnclaimedFunds(
            _campaignId,
            _currency,
            _pool
        );
        emit SttrUnclaimedFundsTransferredToPool(lab, _project, _campaignId, _currency, amountToPool);
        if (statusDefeated) {
            emit SttrCampaignDefeated(lab, _project, _campaignId);
        }
    }

    function withdrawToPool(address _project, IERC20 _currency) external {
        uint256 transferedAmount = VCProject(_project).withdrawToPool(_currency, _pool);
        emit SttrwithdrawToPool(_project, _currency, transferedAmount);
    }

    /*********** VIEW FUNCTIONS ***********/

    function getAdmin() external view returns (address) {
        return _admin;
    }

    function getCampaignStatus(address _project, uint256 _campaignId)
        public
        view
        returns (CampaignStatus currentStatus)
    {
        return VCProject(_project).getCampaignStatus(_campaignId);
    }

    function isValidProject(address _lab, address _project) external view returns (bool) {
        return _projectToLab[_project] == _lab;
    }

    function isWhitelistedLab(address _lab) external view returns (bool) {
        return _isWhitelistedLab[_lab];
    }

    function areActiveProjects(address[] memory _projects) external view returns (bool[] memory) {
        bool[] memory areActive = new bool[](_projects.length);
        for (uint256 i = 0; i < _projects.length; i++) {
            areActive[i] = _activeProjects[_projects[i]];
        }
        return areActive;
    }

    /*********** INTERNAL AND PRIVATE FUNCTIONS ***********/

    function _onlyAdmin() internal view {
        if (msg.sender != _admin) {
            revert Errors.SttrNotAdmin();
        }
    }

    function _onlyLabOwner(address _project) private view {
        if (msg.sender != _projectToLab[_project]) {
            revert Errors.SttrNotLabOwner();
        }
    }

    function _onlyWhitelistedLab() private view {
        if (_isWhitelistedLab[msg.sender] == false) {
            revert Errors.SttrNotWhitelistedLab();
        }
    }

    function _onlyCoreTeam() private view {
        if (msg.sender != _coreTeam) {
            revert Errors.SttrNotCoreTeam();
        }
    }

    function _checkBeforeFund(
        address _project,
        uint256 _amount,
        IERC20 _currency
    ) internal view returns (address lab) {
        lab = _projectToLab[_project];

        if (_amount == 0) {
            revert Errors.SttrFundingAmountIsZero();
        }
        if (_activeProjects[_project] == false) {
            revert Errors.SttrProjectIsNotActive();
        }
        if (lab == msg.sender) {
            revert Errors.SttrLabCannotFundOwnProject();
        }
        if (!_allowedCurrencies[_currency]) {
            revert Errors.SttrCurrencyNotWhitelisted();
        }
        if (!_isWhitelistedLab[lab]) {
            revert Errors.SttrBlacklistedLab();
        }
    }

    function _fundProject(
        address _project,
        IERC20 _currency,
        uint256 _amount
    ) private returns (address lab) {
        lab = _checkBeforeFund(_project, _amount, _currency);

        if (!_currency.transferFrom(msg.sender, _project, _amount)) {
            revert Errors.SttrERC20TransferError();
        }
        VCProject(_project).fundProject(_amount, _currency);
    }

    function _verifyPublishCampaignResults(
        address _project,
        uint256 _campaignId,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _campaignId));
        _verify(messageHash, _sig);
    }

    function _verifyStartCampaign(
        address _project,
        uint256 _numberOfCampaigns,
        uint256 _target,
        uint256 _duration,
        bytes memory _sig
    ) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project, _numberOfCampaigns, _target, _duration));
        _verify(messageHash, _sig);
    }

    function _verifyCloseProject(address _project, bytes memory _sig) internal view {
        bytes32 messageHash = keccak256(abi.encodePacked(msg.sender, _project));
        _verify(messageHash, _sig);
    }

    function _verify(bytes32 _messageHash, bytes memory _sig) private view {
        // this can change later - "\x19Ethereum Signed Message:\n32"
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));

        if (_recover(ethSignedMessageHash, _sig) != _txValidator) {
            revert Errors.SttrInvalidSignature();
        }
    }

    function _recover(bytes32 _ethSignedMessageHash, bytes memory _sig) internal pure returns (address signer) {
        (bytes32 r, bytes32 s, uint8 v) = _split(_sig);
        signer = ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        if (_sig.length != 65) {
            revert Errors.SttrInvalidSignature();
        }

        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Errors} from "./Errors.sol";

struct CampaignData {
    uint256 target;
    uint256 softTarget;
    uint256 raisedAmount;
    uint256 balance;
    uint256 startTime;
    uint256 endTime;
    uint256 backersDeadline;
    bool resultsPublished;
}

enum CampaignStatus {
    ACTIVE,
    NOTFUNDED,
    FUNDED,
    SUCCEEDED,
    DEFEATED
}

contract VCProject is Initializable {
    address _starter;
    address _lab;
    uint256 _numberOfCampaigns;
    bool _projectStatus;

    mapping(uint256 => CampaignData) _campaigns;
    mapping(uint256 => mapping(address => mapping(IERC20 => uint256))) _backers;
    mapping(uint256 => mapping(IERC20 => uint256)) _campaignBalance;

    // Project balances: increase after funding and decrease after deposit
    mapping(IERC20 => uint256) _totalCampaignsBalance;
    mapping(IERC20 => uint256) _totalOutsideCampaignsBalance;
    uint256 _projectBalance; // en USD

    // Raised amounts: only increase after funding, never decrease
    uint256 _raisedAmountOutsideCampaigns; // en USD

    constructor() {}

    function init(address starter, address lab) external initializer {
        _starter = starter;
        _lab = lab;
        _numberOfCampaigns = 0;
        _raisedAmountOutsideCampaigns = 0;
        _projectStatus = true;
    }

    ///////////////////////
    // PROJECT FUNCTIONS //
    ///////////////////////

    function fundProject(uint256 _amount, IERC20 _currency) external {
        _onlyStarter();

        _raisedAmountOutsideCampaigns += _amount;
        _totalOutsideCampaignsBalance[_currency] += _amount;
        _projectBalance += _amount;
    }

    function closeProject() external {
        _onlyStarter();

        bool canBeClosed = _projectStatus && _projectBalance == 0;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canBeClosed =
                canBeClosed &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canBeClosed) {
            revert Errors.ProjCannotBeClosed();
        }
        _projectStatus = false;
    }

    ////////////////////////
    // CAMPAIGN FUNCTIONS //
    ////////////////////////

    function startCampaign(
        uint256 _target,
        uint256 _softTarget,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _backersDeadline
    ) external returns (uint256) {
        _onlyStarter();

        bool canStartCampaign = _projectStatus;
        if (_numberOfCampaigns > 0) {
            uint256 lastCampaignId = _numberOfCampaigns - 1;
            CampaignStatus lastCampaignStatus = getCampaignStatus(lastCampaignId);
            bool lastResultsPublished = _campaigns[lastCampaignId].resultsPublished;

            canStartCampaign =
                canStartCampaign &&
                (lastCampaignStatus == CampaignStatus.DEFEATED ||
                    (lastCampaignStatus == CampaignStatus.SUCCEEDED && lastResultsPublished));
        }

        if (!canStartCampaign) {
            revert Errors.ProjCampaignCannotStart();
        }

        uint256 currentId = _numberOfCampaigns;
        _numberOfCampaigns++;

        _campaigns[currentId] = CampaignData(_target, _softTarget, 0, 0, _startTime, _endTime, _backersDeadline, false);
        return currentId;
    }

    function publishCampaignResults() external {
        _onlyStarter();

        uint256 currentCampaignId = _numberOfCampaigns - 1;
        CampaignStatus campaignStatus = getCampaignStatus(currentCampaignId);
        bool resultsPublished = _campaigns[currentCampaignId].resultsPublished;

        if (campaignStatus != CampaignStatus.SUCCEEDED || resultsPublished == true) {
            revert Errors.ProjResultsCannotBePublished();
        }

        _campaigns[currentCampaignId].resultsPublished = true;
    }

    function fundCampaign(
        IERC20 _currency,
        address _user,
        uint256 _amount
    ) external {
        _onlyStarter();
        uint256 currentCampaignId = _numberOfCampaigns - 1;

        _backers[currentCampaignId][_user][_currency] += _amount;
        _updateBalances(currentCampaignId, _currency, _amount, true);
    }

    function validateMint(
        uint256 _campaignId,
        IERC20 _currency,
        address _user
    ) external returns (uint256 backerBalance) {
        _onlyStarter();
        CampaignStatus currentCampaignStatus = getCampaignStatus(_campaignId);

        if (currentCampaignStatus == CampaignStatus.ACTIVE || currentCampaignStatus == CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotSucceededNorFundedNorDefeated();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }
        _backers[_campaignId][_user][_currency] = 0;
    }

    function backerWithdrawDefeated(
        uint256 _campaignId,
        address _user,
        IERC20 _currency
    ) external returns (uint256 backerBalance, bool statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.NOTFUNDED) {
            revert Errors.ProjCampaignNotNotFunded();
        }

        backerBalance = _backers[_campaignId][_user][_currency];
        if (backerBalance == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _backers[_campaignId][_user][_currency] = 0;
        _updateBalances(_campaignId, _currency, backerBalance, false);
        if (_campaigns[_campaignId].balance == 0) {
            statusDefeated = true;
        }

        if (!_currency.transfer(_user, backerBalance)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labCampaignWithdraw(IERC20 _currency)
        external
        returns (
            uint256 currentCampaignId,
            uint256 withdrawAmount,
            bool statusSucceeded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.FUNDED) {
            revert Errors.ProjCampaignNotFunded();
        }

        withdrawAmount = _campaignBalance[currentCampaignId][_currency];

        if (withdrawAmount == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(currentCampaignId, _currency, withdrawAmount, false);
        if (_campaigns[currentCampaignId].balance == 0) {
            statusSucceeded = true;
        }

        if (!_currency.transfer(_lab, withdrawAmount)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function labWithdraw(IERC20 _currency) external returns (uint256 _amount) {
        _onlyStarter();

        _amount = _totalOutsideCampaignsBalance[_currency];

        if (_totalOutsideCampaignsBalance[_currency] == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        if (!_currency.transfer(_lab, _amount)) {
            revert Errors.ProjERC20TransferError();
        }
        _totalOutsideCampaignsBalance[_currency] = 0;
        _projectBalance -= _amount;
    }

    function withdrawToPool(IERC20 _currency, address _receiver) external returns (uint256 amountAvailable) {
        _onlyStarter();
        amountAvailable =
            _currency.balanceOf(address(this)) -
            _totalCampaignsBalance[_currency] -
            _totalOutsideCampaignsBalance[_currency];
        if (amountAvailable == 0) {
            revert Errors.ProjZeroAmountToWithdraw();
        }
        if (!_currency.transfer(_receiver, amountAvailable)) {
            revert Errors.ProjERC20TransferError();
        }
    }

    function transferUnclaimedFunds(
        uint256 _campaignId,
        IERC20 _currency,
        address _pool
    ) external returns (uint256 _amountToPool, bool _statusDefeated) {
        _onlyStarter();

        if (getCampaignStatus(_campaignId) != CampaignStatus.DEFEATED) {
            revert Errors.ProjCampaignNotDefeated();
        }
        _amountToPool = _campaignBalance[_campaignId][_currency];
        if (_amountToPool == 0) {
            revert Errors.ProjBalanceIsZero();
        }

        _updateBalances(_campaignId, _currency, _amountToPool, false);
        if (_campaigns[_campaignId].balance == 0) {
            _statusDefeated = true;
        }

        if (!_currency.transfer(_pool, _amountToPool)) {
            revert Errors.SttrERC20TransferError();
        }
    }

    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////

    function getNumberOfCampaigns() external view returns (uint256) {
        return _numberOfCampaigns;
    }

    function getCampaignRaisedAmount(uint256 _campaignId) external view returns (uint256) {
        return _campaigns[_campaignId].raisedAmount;
    }

    function getRaisedAmountFromCampaigns() public view returns (uint256 raisedAmount) {
        for (uint256 i = 0; i <= _numberOfCampaigns; i++) {
            if (getCampaignStatus(i) == CampaignStatus.SUCCEEDED) {
                raisedAmount += _campaigns[i].raisedAmount;
            }
        }
    }

    function getRaisedAmountOutsideCampaigns() public view returns (uint256 raisedAmount) {
        return _raisedAmountOutsideCampaigns;
    }

    function getTotalRaisedAmount() external view returns (uint256) {
        return getRaisedAmountFromCampaigns() + _raisedAmountOutsideCampaigns;
    }

    function campaignBalance(uint256 _campaignId, IERC20 _currency) external view returns (uint256) {
        return _campaignBalance[_campaignId][_currency];
    }

    function totalCampaignBalance(IERC20 _currency) external view returns (uint256) {
        return _totalCampaignsBalance[_currency];
    }

    function totalOutsideCampaignsBalance(IERC20 _currency) external view returns (uint256) {
        return _totalOutsideCampaignsBalance[_currency];
    }

    function projectBalance() external view returns (uint256) {
        return _projectBalance;
    }

    function getCampaignStatus(uint256 _campaignId) public view returns (CampaignStatus currentStatus) {
        CampaignData memory campaignData = _campaigns[_campaignId];

        uint256 target = campaignData.target;
        uint256 softTarget = campaignData.softTarget;
        uint256 raisedAmount = campaignData.raisedAmount;
        uint256 balance = campaignData.balance;
        uint256 endTime = campaignData.endTime;
        uint256 backersDeadline = campaignData.backersDeadline;

        uint256 currentTime = block.timestamp;

        if (raisedAmount == target || (raisedAmount >= softTarget && currentTime > endTime)) {
            if (balance > 0) {
                return CampaignStatus.FUNDED;
            } else {
                return CampaignStatus.SUCCEEDED;
            }
        } else if (currentTime <= endTime) {
            return CampaignStatus.ACTIVE;
        } else if (currentTime <= backersDeadline && balance > 0) {
            return CampaignStatus.NOTFUNDED;
        } else {
            return CampaignStatus.DEFEATED;
        }
    }

    function getProjectStatus() external view returns (bool) {
        return _projectStatus;
    }

    function getFundingAmounts(uint256 _amount)
        external
        view
        returns (
            uint256 currentCampaignId,
            uint256 amountToCampaign,
            uint256 amountToPool,
            bool isFunded
        )
    {
        _onlyStarter();
        currentCampaignId = _numberOfCampaigns - 1;

        if (getCampaignStatus(currentCampaignId) != CampaignStatus.ACTIVE) {
            revert Errors.ProjCampaignNotActive();
        }

        uint256 amountToTarget = _campaigns[currentCampaignId].target - _campaigns[currentCampaignId].balance;

        if (amountToTarget > _amount) {
            amountToCampaign = _amount;
            amountToPool = 0;
            isFunded = false;
        } else {
            amountToCampaign = amountToTarget;
            amountToPool = _amount - amountToCampaign;
            isFunded = true;
        }
    }

    function _onlyStarter() private view {
        if (msg.sender != _starter) {
            revert Errors.ProjOnlyStarter();
        }
    }

    ////////////////////////////////
    // PRIVATE/INTERNAL FUNCTIONS //
    ////////////////////////////////

    function _updateBalances(
        uint256 _campaignId,
        IERC20 _currency,
        uint256 _amount,
        bool _fund
    ) private {
        if (_fund) {
            _campaigns[_campaignId].balance += _amount;
            _campaigns[_campaignId].raisedAmount += _amount;
            _campaignBalance[_campaignId][_currency] += _amount;
            _totalCampaignsBalance[_currency] += _amount;
            _projectBalance += _amount;
        } else {
            _campaigns[_campaignId].balance -= _amount;
            _campaignBalance[_campaignId][_currency] -= _amount;
            _totalCampaignsBalance[_currency] -= _amount;
            _projectBalance -= _amount;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

library Errors {
    // Starter Errors
    error SttrNotAdmin();
    error SttrNotWhitelistedLab();
    error SttrNotLabOwner();
    error SttrNotCoreTeam();
    error SttrLabAlreadyWhitelisted();
    error SttrLabAlreadyBlacklisted();
    error SttrFundingAmountIsZero();
    error SttrCurrencyAlreadyListed();
    error SttrCurrencyAlreadyUnlisted();
    error SttrMinCampaignDurationError();
    error SttrMaxCampaignDurationError();
    error SttrMinCampaignTargetError();
    error SttrMaxCampaignTargetError();
    error SttrSoftTargetBpsError();
    error SttrLabCannotFundOwnProject();
    error SttrCurrencyNotWhitelisted();
    error SttrBlacklistedLab();
    error SttrCampaignTargetError();
    error SttrCampaignDurationError();
    error SttrERC20TransferError();
    error SttrExistingProjectRequest();
    error SttrNonExistingProjectRequest();
    error SttrInvalidSignature();
    error SttrProjectIsNotActive();
    error SttrResultsCannotBePublished();

    // Project Errors
    error ProjOnlyStarter();
    error ProjBalanceIsZero();
    error ProjCampaignNotActive();
    error ProjERC20TransferError();
    error ProjZeroAmountToWithdraw();
    error ProjCampaignNotDefeated();
    error ProjCampaignNotNotFunded();
    error ProjCampaignNotFunded();
    error ProjCampaignNotSucceededNorFundedNorDefeated();
    error ProjResultsCannotBePublished();
    error ProjCampaignCannotStart();
    error ProjCannotBeClosed();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CURE is ERC20 {
    constructor() ERC20("CURE", "CURE") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    constructor() ERC20("USDT", "USDT") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20 {
    constructor() ERC20("USDC", "USDC") {}

    function mint(address account, uint256 amount) public {
        _mint(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IVCProject {
    function fundProjectFromMarketplace(
        address _user,
        IERC20 _currency,
        uint256 _amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGovernance {
    function currency() external returns (IERC20);
}