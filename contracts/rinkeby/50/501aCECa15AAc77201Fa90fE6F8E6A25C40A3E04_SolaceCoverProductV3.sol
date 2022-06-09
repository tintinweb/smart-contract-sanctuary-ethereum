// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../utils/Governable.sol";
import "../interfaces/utils/IRegistry.sol";
import "../interfaces/risk/IRiskManager.sol";
import "../interfaces/payment/ICoverPaymentManager.sol";
import "../interfaces/products/ISolaceCoverProductV3.sol";

/**
 * @title SolaceCoverProductV3
 * @author solace.fi
 * @notice A Solace insurance product that allows users to insure all of their DeFi positions against smart contract risk through a single policy.
 *
 * Policies can be **purchased** via [`activatePolicy()`](#activatepolicy). Policies are represented as ERC721s, which once minted, cannot then be transferred or burned. Users can change the cover limit of their policy through [`updateCoverLimit()`](#updatecoverlimit).
 *
 * The policy will remain active until i.) the user cancels their policy or ii.) the user's account runs out of funds. The policy will be billed like a subscription, every epoch a fee will be charged from the user's account.
 *
 * Users can **deposit funds** into their account via [`deposit()`](#deposit). Currently the contract only accepts deposits in **FRAX**. Note that both [`activatePolicy()`](#activatepolicy) and [`deposit()`](#deposit) enables a user to perform these actions (activate a policy, make a deposit) on behalf of another user.
 *
 * Users can **cancel** their policy via [`deactivatePolicy()`](#deactivatepolicy). This will start a cooldown timer. Users can **withdraw funds** from their account via [`withdraw()`](#withdraw).
 *
 * Before the cooldown timer starts or passes, the user cannot withdraw their entire account balance. A minimum required account balance (to cover one epoch's fee) will be left in the user's account. After the cooldown has passed, a user will be able to withdraw their entire account balance.
 *
 * Users can enter a **referral code** with [`activatePolicy()`](#activatePolicy) or [`updateCoverLimit()`](#updatecoverlimit). A valid referral code will earn reward points to both the referrer and the referee. When the user's account is charged, reward points will be deducted before solace cover dollars.
 * Each account can only enter a valid referral code once, however there are no restrictions on how many times a referral code can be used for new accounts.
 */
contract SolaceCoverProductV3 is
    ISolaceCoverProductV3,
    ERC721,
    ReentrancyGuard,
    Governable
{
    /***************************************
    STATE VARIABLES
    ***************************************/

    /// @notice Registry contract.
    address public registry;

    /// @notice RiskManager contract.
    address public riskManager;

    /// @notice CoverPaymentManager contract.
    address public paymentManager;

    /// @notice Cannot buy new policies while paused. (Default is False)
    bool public paused;

    /// @notice The base token uri url for policies.
    string public baseURI;

    /// @notice The total policy count.
    uint256 public policyCount;

    /// @notice The maximum rate charged per second per 1e-18 (wei) of cover limit.
    /// @dev Default to charge 10% of cover limit annually = 1/315360000.
    uint256 public maxRateNum;

    /// @notice The maximum rate denomination value.
    /// @dev  Max premium rate of 10% of cover limit per annum.
    uint256 public maxRateDenom;

    /// @notice Maximum epoch duration over which premiums are charged (Default is one week).
    uint256 public chargeCycle; 

    /// @notice The latest premium charged timestamp.
    uint256 public latestChargedTime;

    /// @notice policyholder => policyID.
    mapping(address => uint256) public policyOf;

    /// @notice policyholder => policy debt.
    mapping(address => uint256) public debtOf;

    /// @notice policyID => coverLimit.
    mapping(uint256 => uint256) public coverLimitOf;

    /***************************************
    MODIFIERS
    ***************************************/

    modifier whileUnpaused() {
        require(!paused, "contract paused");
        _;
    }

    modifier onlyCollector() {
        require(
            msg.sender == IRegistry(registry).get("premiumCollector") ||
            msg.sender == governance(), "not premium collector"
        );
        _;
    }

    /**
     * @notice Constructs `Solace Cover Product`.
     * @param _governance The address of the governor.
     * @param _registry The [`Registry`](./Registry) contract address.
    */
    constructor(address _governance, address _registry) ERC721("Solace Wallet Coverage", "SWC") Governable(_governance) {
        // set registry
        _setRegistry(_registry);

        // set defaults
        maxRateNum = 1; 
        maxRateDenom = 315360000;
        chargeCycle = _getChargePeriodValue(ChargePeriod.WEEKLY);
        baseURI = string(abi.encodePacked("https://stats.solace.fi/policy/?chainID=", Strings.toString(block.chainid), "&policyID="));
    }

    /***************************************
    POLICY FUNCTIONS
    ***************************************/

    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @return policyID The ID of the newly minted policy.
    */
    function purchase(address _user, uint256 _coverLimit) external override nonReentrant whileUnpaused returns (uint256 policyID) {
       return _purchase(_user, _coverLimit);
    }

    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @return policyID The ID of the newly minted policy.
    */
    function purchaseWithStable(address _user, uint256 _coverLimit, address _token, uint256 _amount) external override nonReentrant whileUnpaused returns (uint256 policyID) {
        return _purchaseWithStable(msg.sender, _user, _coverLimit, _token, _amount);
    }

    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @param _price The `SOLACE` price in wei(usd).
     * @param _priceDeadline The `SOLACE` price in wei(usd).
     * @param _signature The `SOLACE` price signature.
     * @return policyID The ID of the newly minted policy.
    */
    function purchaseWithNonStable(
        address _user,
        uint256 _coverLimit,
        address _token, 
        uint256 _amount,
        uint256 _price, 
        uint256 _priceDeadline,
        bytes calldata _signature
    ) external override nonReentrant whileUnpaused returns (uint256 policyID) {
        return _purchaseWithNonStable(msg.sender, _user, _coverLimit, _token, _amount, _price, _priceDeadline, _signature);
    }

    /**
     * @notice Cancels the policy.
     * The function cancels the policy of the policyholder.
    */
    function cancel() external override {
        require(policyStatus(policyOf[msg.sender]), "invalid policy");
        _cancel(msg.sender);
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover that can be sold in **USD** to 18 decimals places.
     * @return cover The max amount of cover.
    */
    function maxCover() public view override returns (uint256 cover) {
        return IRiskManager(riskManager).maxCoverPerStrategy(address(this));
    }

    /**
     * @notice Returns the active cover limit in **USD** to 18 decimal places. In other words, the total cover that has been sold at the current time.
     * @return amount The active cover limit.
    */
    function activeCoverLimit() public view override returns (uint256 amount) {
        return IRiskManager(riskManager).activeCoverLimitPerStrategy(address(this));
    }

    /**
     * @notice Determine the available remaining capacity for new cover.
     * @return capacity The amount of available remaining capacity for new cover.
    */
    function availableCoverCapacity() public view override returns (uint256 capacity) {
        capacity = maxCover() - activeCoverLimit();
    }

    /**
     * @notice Returns true if the policy is active, false if inactive
     * @param _policyID The policy ID.
     * @return status True if policy is active. False otherwise.
    */
    function policyStatus(uint256 _policyID) public view override returns (bool status) {
        return coverLimitOf[_policyID] > 0 ? true : false;
    }

    /**
     * @notice Calculate minimum required account balance for a given cover limit. Equals the maximum chargeable fee for one epoch.
     * @param _coverLimit The maximum value to cover in **USD**.
    */
    function minRequiredAccountBalance(uint256 _coverLimit) public view override returns (uint256 mrab) {
        mrab = (maxRateNum * chargeCycle * _coverLimit) / maxRateDenom;
    }

    /**
     * @notice Calculates the minimum amount of Solace Credit Points required by this contract for the account to hold.
     * @param _policyholder The account to query.
     * @return amount The amount of SCP the account must hold.
    */
    function minScpRequired(address _policyholder) external view override returns (uint256 amount) {
        if (policyStatus(policyOf[_policyholder])) {
            return minRequiredAccountBalance(coverLimitOf[policyOf[_policyholder]]) + debtOf[_policyholder];
        }
        return debtOf[_policyholder];
    }

    /**
     * @notice Returns the Uniform Resource Identifier (URI) for `policyID`.
     * @param policyID The policy ID.
    */
    function tokenURI(uint256 policyID) public view virtual override returns (string memory uri) {
        require(_exists(policyID), "invalid policy");
        return string(abi.encodePacked(baseURI, Strings.toString(policyID)));
    }

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _registry The address of `Registry` contract.
    */
    function setRegistry(address _registry) external override onlyGovernance {
        _setRegistry(_registry);
    }

    /**
     * @notice Pauses or unpauses policies.
     * Deactivating policies are unaffected by pause.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _paused True to pause, false to unpause.
    */
    function setPaused(bool _paused) external override onlyGovernance {
        paused = _paused;
        emit PauseSet(_paused);
    }

    /**
     * @notice set _maxRate.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _maxRateNum The maximum rate charged per second per 1e-18 (wei) of cover limit. The default is to charge 10% of cover limit annually = 1/315360000.
     * @param _maxRateDenom The maximum rate denomination value. The default value is max premium rate of 10% of cover limit per annum.
    */
    function setMaxRate(uint256 _maxRateNum, uint256 _maxRateDenom) external override onlyGovernance {
        maxRateNum = _maxRateNum;
        maxRateDenom = _maxRateDenom;
        emit MaxRateSet(_maxRateNum, _maxRateDenom);
    }

    /**
     * @notice Sets maximum epoch duration over which premiums are charged.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _chargeCycle The premium charge period(Weekly, Monthly, Annually, Daily, Hourly) in seconds to set. The default is weekly(604800).
    */
    function setChargeCycle(ChargePeriod _chargeCycle) external override onlyGovernance {
        chargeCycle = _getChargePeriodValue(_chargeCycle);
        emit ChargeCycleSet(chargeCycle);
    }

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * @param _baseURI The new base URI.
    */
    function setBaseURI(string memory _baseURI) external override onlyGovernance {
        baseURI = _baseURI;
        emit BaseURISet(_baseURI);
    }

    /***************************************
    PREMIUM COLLECTOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the latest premium charged time.
     * @param _timestamp The timestamp value when the premiums are charged.
    */
    function setChargedTime(uint256 _timestamp) external override whileUnpaused onlyCollector {
        // solhint-disable-next-line not-rely-on-time
        require(_timestamp > 0 && _timestamp <= block.timestamp, "invalid charged timestamp");
        latestChargedTime = _timestamp;
        emit LatestChargedTimeSet(_timestamp);
    }

    /**
     * @notice Add debts for each policy holder. Can only be called by the **Premium Collector** role.
     * @param _policyholders The array of addresses of the policyholders to add debt.
     * @param _debts The array of debt amounts (in **USD** to 18 decimal places) for each policyholder.
    */
    function setDebts(address[] calldata _policyholders, uint256[] calldata _debts) external override whileUnpaused onlyCollector {
        uint256 count = _policyholders.length;
        require(count == _debts.length, "length mismatch");
        require(count <= policyCount, "policy count exceeded");

        address policyholder;
        uint256 debt;

        for (uint256 i = 0; i < count; i++) {
            policyholder = _policyholders[i];
            if (policyStatus(policyOf[policyholder])) {
                debt = _debts[i];
                debtOf[policyholder] += debt;
                emit DebtSet(policyholder, debt);
            }
        }
    }

    /***************************************
    INTERNAL FUNCTIONS
    ***************************************/

    /**
     * @notice Returns true if there is sufficient capacity to update a policy's cover limit, false if not.
     * @param _currentCoverLimit The current cover limit, 0 if policy has not previously been activated.
     * @param _newCoverLimit  The new cover limit requested.
     * @return acceptable True there is sufficient capacity for the requested new cover limit, false otherwise.
    */
    function _checkCapacity(uint256 _currentCoverLimit, uint256 _newCoverLimit) internal view returns (bool acceptable) {
        // return true if user is lowering cover limit
        if (_newCoverLimit <= _currentCoverLimit) return true;

        // check capacity
        uint256 diff = _newCoverLimit - _currentCoverLimit;
        if (diff < availableCoverCapacity()) return true;
        
        // no available capacity
        return false;
    }

    /**
     * @notice Purchases policy for user.
     * @param _user The account to purchase policy. 
     * @param _coverLimit The maximum value to cover in **USD**.
     * @return policyID The ID of the newly minted policy.
    */
    function _purchase(address _user, uint256 _coverLimit) internal returns (uint256 policyID) {
        require(_coverLimit > 0, "zero cover value");

        policyID = policyOf[_user];
        uint256 currentCoverlimit = coverLimitOf[policyID];
        require(_checkCapacity(currentCoverlimit, _coverLimit), "insufficient capacity");
        require(ICoverPaymentManager(paymentManager).getSCPBalance(_user) > minRequiredAccountBalance(_coverLimit), "insufficient scp balance");

        // mint policy if doesn't currently exist
        if (policyID == 0) {
            policyID = ++policyCount;
            policyOf[_user] = policyID;
            _mint(_user, policyID);
            emit PolicyCreated(policyID);
        } else {
            if (_coverLimit == currentCoverlimit) return policyID;
            emit PolicyUpdated(policyID);
        }

        // update cover amount
        _updateActiveCoverLimit(currentCoverlimit, _coverLimit);
        coverLimitOf[policyID] = _coverLimit;
        return policyID;
    }

    /**
     * @notice Purchases policy for user.
     * @param _purchaser The account that purchases the policy.
     * @param _user The account to purchase policy for. 
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @return policyID The ID of the newly minted policy.
    */
    function _purchaseWithStable(address _purchaser, address _user, uint256 _coverLimit, address _token, uint256 _amount) internal returns (uint256 policyID) {
        ICoverPaymentManager(paymentManager).depositStableFrom(_token, _purchaser, _user, _amount);
        return _purchase(_user, _coverLimit);
    }

    /**
     * @notice Purchases policy for user.
     * @param _purchaser The account that purchases the policy.
     * @param _user The account to purchase policy. 
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @param _price The `SOLACE` price in wei(usd).
     * @param _priceDeadline The `SOLACE` price in wei(usd).
     * @param _signature The `SOLACE` price signature.
     * @return policyID The ID of the newly minted policy.
    */
    function _purchaseWithNonStable(
        address _purchaser,
        address _user,
        uint256 _coverLimit,
        address _token,
        uint256 _amount,
        uint256 _price, 
        uint256 _priceDeadline,
        bytes calldata _signature
    ) internal returns (uint256 policyID) {
        ICoverPaymentManager(paymentManager).depositNonStableFrom(_token, _purchaser, _user, _amount, _price, _priceDeadline, _signature);
        return _purchase(_user, _coverLimit);
    } 

    /**
     * @notice Cancels the policy.
     * @param _policyholder The policyholder address.
    */
    function _cancel(address _policyholder) internal {
        uint256 policyID = policyOf[_policyholder];
        uint256 coverLimit = coverLimitOf[policyID];
        _updateActiveCoverLimit(coverLimit, 0);

        debtOf[_policyholder] += minRequiredAccountBalance(coverLimit);
        coverLimitOf[policyID] = 0;
        emit PolicyCanceled(policyID);
    }

    /**
     * @notice Updates the Risk Manager on the current total cover limit purchased by policyholders.
     * @param _currentCoverLimit The current policyholder cover limit (0 if activating policy).
     * @param _newCoverLimit The new policyholder cover limit.
    */
    function _updateActiveCoverLimit(uint256 _currentCoverLimit, uint256 _newCoverLimit) internal {
        IRiskManager(riskManager).updateActiveCoverLimitForStrategy(address(this), _currentCoverLimit, _newCoverLimit);
    }

    /**
     * @notice Override _beforeTokenTransfer hook from ERC721 standard to ensure policies are non-transferable, and only one can be minted per user.
     * @dev This hook is called on mint, transfer and burn.
     * @param from sending address.
     * @param to receiving address.
     * @param tokenId tokenId.
    */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);
        require(from == address(0), "only minting permitted");
    }

    /**
     * @notice Sets registry and related contract addresses.
     * @param _registry The registry address to set.
    */
    function _setRegistry(address _registry) internal {
        // set registry
        require(_registry != address(0x0), "zero address registry");
        registry = _registry;

        // set risk manager
        (, address riskManagerAddr) = IRegistry(_registry).tryGet("riskManager");
        require(riskManagerAddr != address(0x0), "zero address riskmanager");
        riskManager = riskManagerAddr;

        // set cover payment manager
        (, address paymentManagerAddr) = IRegistry(_registry).tryGet("coverPaymentManager");
        require(paymentManagerAddr != address(0x0), "zero address payment manager");
        paymentManager = paymentManagerAddr;
        emit RegistrySet(_registry);
    }

    function _getChargePeriodValue(ChargePeriod period) private pure returns (uint256 value) {
        if (period == ChargePeriod.WEEKLY) {
            return 604800;
        } else if (period == ChargePeriod.MONTHLY) {
            return 2629746;
        } else if (period == ChargePeriod.ANNUALLY) {
            return 31556952;
        } else if (period == ChargePeriod.DAILY) {
            return 86400;
        } else {
            // hourly
            return 3600;
        }
    }
}

// SPDX-License-Identifier: MIT

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
        require(operator != _msgSender(), "ERC721: approve to caller");

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

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
}

// SPDX-License-Identifier: MIT

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
     * by making the `nonReentrant` function external, and make it call a
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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../interfaces/utils/IGovernable.sol";

/**
 * @title Governable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
   * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./../interfaces/utils/ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
contract Governable is IGovernable {

    /***************************************
    GLOBAL VARIABLES
    ***************************************/

    // Governor.
    address private _governance;

    // governance to take over.
    address private _pendingGovernance;

    bool private _locked;

    /**
     * @notice Constructs the governable contract.
     * @param governance_ The address of the [governor](/docs/protocol/governance).
     */
    constructor(address governance_) {
        require(governance_ != address(0x0), "zero address governance");
        _governance = governance_;
        _pendingGovernance = address(0x0);
        _locked = false;
    }

    /***************************************
    MODIFIERS
    ***************************************/

    // can only be called by governor
    // can only be called while unlocked
    modifier onlyGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _governance, "!governance");
        _;
    }

    // can only be called by pending governor
    // can only be called while unlocked
    modifier onlyPendingGovernance() {
        require(!_locked, "governance locked");
        require(msg.sender == _pendingGovernance, "!pending governance");
        _;
    }

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() public view override returns (address) {
        return _governance;
    }

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view override returns (address) {
        return _pendingGovernance;
    }

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view override returns (bool) {
        return _locked;
    }

    /***************************************
    MUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external override onlyGovernance {
        _pendingGovernance = pendingGovernance_;
        emit GovernancePending(pendingGovernance_);
    }

    /**
     * @notice Accepts the governance role.
     * Can only be called by the pending governor.
     */
    function acceptGovernance() external override onlyPendingGovernance {
        // sanity check against transferring governance to the zero address
        // if someone figures out how to sign transactions from the zero address
        // consider the entirety of ethereum to be rekt
        require(_pendingGovernance != address(0x0), "zero governance");
        address oldGovernance = _governance;
        _governance = _pendingGovernance;
        _pendingGovernance = address(0x0);
        emit GovernanceTransferred(oldGovernance, _governance);
    }

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external override onlyGovernance {
        _locked = true;
        // intentionally not using address(0x0), see re-initialization exploit
        _governance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        _pendingGovernance = address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF);
        emit GovernanceTransferred(msg.sender, address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF));
        emit GovernanceLocked();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRegistry
 * @author solace.fi
 * @notice Tracks the contracts of the Solaverse.
 *
 * [**Governance**](/docs/protocol/governance) can set the contract addresses and anyone can look them up.
 *
 * A key is a unique identifier for each contract. Use [`get(key)`](#get) or [`tryGet(key)`](#tryget) to get the address of the contract. Enumerate the keys with [`length()`](#length) and [`getKey(index)`](#getkey).
 */
interface IRegistry {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a record is set.
    event RecordSet(string indexed key, address indexed value);

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice The number of unique keys.
    function length() external view returns (uint256);

    /**
     * @notice Gets the `value` of a given `key`.
     * Reverts if the key is not in the mapping.
     * @param key The key to query.
     * @param value The value of the key.
     */
    function get(string calldata key) external view returns (address value);

    /**
     * @notice Gets the `value` of a given `key`.
     * Fails gracefully if the key is not in the mapping.
     * @param key The key to query.
     * @param success True if the key was found, false otherwise.
     * @param value The value of the key or zero if it was not found.
     */
    function tryGet(string calldata key) external view returns (bool success, address value);

    /**
     * @notice Gets the `key` of a given `index`.
     * @dev Iterable [1,length].
     * @param index The index to query.
     * @return key The key at that index.
     */
    function getKey(uint256 index) external view returns (string memory key);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets keys and values.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param keys The keys to set.
     * @param values The values to set.
     */
    function set(string[] calldata keys, address[] calldata values) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;


/**
 * @title IRiskManager
 * @author solace.fi
 * @notice Calculates the acceptable risk, sellable cover, and capital requirements of Solace products and capital pool.
 *
 * The total amount of sellable coverage is proportional to the assets in the [**risk backing capital pool**](../Vault). The max cover is split amongst products in a weighting system. [**Governance**](/docs/protocol/governance). can change these weights and with it each product's sellable cover.
 *
 * The minimum capital requirement is proportional to the amount of cover sold to [active policies](../PolicyManager).
 *
 * Solace can use leverage to sell more cover than the available capital. The amount of leverage is stored as [`partialReservesFactor`](#partialreservesfactor) and is settable by [**governance**](/docs/protocol/governance).
 */
interface IRiskManager {

    /***************************************
    TYPE DEFINITIONS
    ***************************************/

    enum StrategyStatus {
       INACTIVE,
       ACTIVE
    }

    struct Strategy {
        uint256 id;
        uint32 weight;
        StrategyStatus status;
        uint256 timestamp;
    }

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when new strategy is created.
    event StrategyAdded(address strategy);

    /// @notice Emitted when strategy status is updated.
    event StrategyStatusUpdated(address strategy, uint8 status);

    /// @notice Emitted when strategy's allocation weight is increased.
    event RiskStrategyWeightAllocationIncreased(address strategy, uint32 weight);

    /// @notice Emitted when strategy's allocation weight is decreased.
    event RiskStrategyWeightAllocationDecreased(address strategy, uint32 weight);

    /// @notice Emitted when strategy's allocation weight is set.
    event RiskStrategyWeightAllocationSet(address strategy, uint32 weight);

    /// @notice Emitted when the partial reserves factor is set.
    event PartialReservesFactorSet(uint16 partialReservesFactor);

    /// @notice Emitted when the cover limit amount of the strategy is updated.
    event ActiveCoverLimitUpdated(address strategy, uint256 oldCoverLimit, uint256 newCoverLimit);

    /// @notice Emitted when the cover limit updater is set.
    event CoverLimitUpdaterAdded(address updater);

    /// @notice Emitted when the cover limit updater is removed.
    event CoverLimitUpdaterDeleted(address updater);

    /***************************************
    RISK MANAGER MUTUTATOR FUNCTIONS
    ***************************************/

    /**
     * @notice Adds a new `Risk Strategy` to the `Risk Manager`. The community votes the strategy for coverage weight allocation.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @return index The index of the risk strategy.
    */
    function addRiskStrategy(address strategy_) external returns (uint256 index);

    /**
     * @notice Sets the weight of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param weight_ The value to set.
    */
    function setWeightAllocation(address strategy_, uint32 weight_) external;

    /**
     * @notice Sets the status of the `Risk Strategy`.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param strategy_ The address of the risk strategy.
     * @param status_ The status to set.
    */
    function setStrategyStatus(address strategy_, uint8 status_) external;

   /**
     * @notice Updates the active cover limit amount for the given strategy. 
     * This function is only called by valid requesters when a new policy is bought or updated.
     * @dev The policy manager and soteria will call this function for now.
     * @param strategy The strategy address to add cover limit.
     * @param currentCoverLimit The current cover limit amount of the strategy's product.
     * @param newCoverLimit The new cover limit amount of the strategy's product.
    */
    function updateActiveCoverLimitForStrategy(address strategy, uint256 currentCoverLimit, uint256 newCoverLimit) external;

    /**
     * @notice Adds new address to allow updating cover limit amounts.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param updater The address that can update cover limit.
    */
    function addCoverLimitUpdater(address updater) external ;

    /**
     * @notice Removes the cover limit updater.
     * @param updater The address of updater to remove.
    */
    function removeCoverLimitUpdater(address updater) external;

    /***************************************
    RISK MANAGER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice Checks is an address is an active strategy.
     * @param strategy_ The risk strategy.
     * @return status True if the strategy is active.
    */
    function strategyIsActive(address strategy_) external view returns (bool status);

     /**
      * @notice Return the strategy at an index.
      * @dev Enumerable `[1, numStrategies]`.
      * @param index_ Index to query.
      * @return strategy The product address.
    */
    function strategyAt(uint256 index_) external view returns (address strategy);

    /**
     * @notice Returns the number of registered strategies..
     * @return count The number of strategies.
    */
    function numStrategies() external view returns (uint256 count);

    /**
     * @notice Returns the risk strategy information.
     * @param strategy_ The risk strategy.
     * @return id The id of the risk strategy.
     * @return weight The risk strategy weight allocation.
     * @return status The status of risk strategy.
     * @return timestamp The added time of the risk strategy.
     *
    */
    function strategyInfo(address strategy_) external view returns (uint256 id, uint32 weight, StrategyStatus status, uint256 timestamp);

    /**
     * @notice Returns the allocated weight for the risk strategy.
     * @param strategy_ The risk strategy.
     * @return weight The risk strategy weight allocation.
    */
    function weightPerStrategy(address strategy_) external view returns (uint32 weight);

    /**
     * @notice The maximum amount of cover for given strategy can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCoverPerStrategy(address strategy_) external view returns (uint256 cover);

    /**
     * @notice Returns the current amount covered (in wei).
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimit() external view returns (uint256 amount);

    /**
     * @notice Returns the current amount covered (in wei).
     * @param riskStrategy The risk strategy address.
     * @return amount The covered amount (in wei).
    */
    function activeCoverLimitPerStrategy(address riskStrategy) external view returns (uint256 amount);

    /***************************************
    MAX COVER VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover that Solace as a whole can sell.
     * @return cover The max amount of cover in wei.
     */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice Returns the sum of allocation weights for all strategies.
     * @return sum WeightSum.
     */
    function weightSum() external view returns (uint32 sum);

    /***************************************
    MIN CAPITAL VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirement() external view returns (uint256 mcr);

    /**
     * @notice The minimum amount of capital required to safely cover all policies.
     * @param strategy_ The risk strategy.
     * @return mcr The minimum capital requirement.
     */
    function minCapitalRequirementPerStrategy(address strategy_) external view returns (uint256 mcr);

    /**
     * @notice Multiplier for minimum capital requirement.
     * @return factor Partial reserves factor in BPS.
     */
    function partialReservesFactor() external view returns (uint16 factor);

    /**
     * @notice Sets the partial reserves factor.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param partialReservesFactor_ New partial reserves factor in BPS.
     */
    function setPartialReservesFactor(uint16 partialReservesFactor_) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "./../utils/IGovernable.sol";

/**
 * @title Cover Payment Manager
 * @author solace.fi
 * @notice A cover payment manager for [**Solace Cover Points**](./SCP) that accepts stablecoins  and `SOLACE` for payment.
 */
interface ICoverPaymentManager is IGovernable {
   
    /***************************************
    STRUCTS
    ***************************************/

    struct TokenInfo {
        address token;
        bool accepted;
        bool permittable;
        bool refundable;
        bool stable;
    }

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a token is deposited.
    event TokenDeposited(address indexed token, address indexed depositor, address indexed receiver, uint256 amount);
    
    /// @notice Emitted when a token is withdrawn.
    event TokenWithdrawn(address indexed depositor, address indexed receiver, uint256 amount);
   
    /// @notice Emitted when registry is set.
    event RegistrySet(address registry);

    /// @notice Emitted when a token is set.
    event TokenInfoSet(address token, bool accepted, bool permittable, bool refundable, bool stable);

    /// @notice Emitted when paused is set.
    event PauseSet(bool paused);


    /***************************************
    DEPOSIT FUNCTIONS
    ***************************************/

    /**
     * @notice Deposits tokens from msg.sender and credits them to recipient.
     * @param token The token to deposit.
     * @param from The depositor of the token.
     * @param recipient The recipient of Solace Cover Points.
     * @param amount Amount of token to deposit.
    */
    function depositStableFrom(
        address token,
        address from,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Deposits tokens from msg.sender and credits them to recipient.
     * @param token The token to deposit.
     * @param recipient The recipient of Solace Cover Points.
     * @param amount Amount of token to deposit.
    */
    function depositStable(
        address token,
        address recipient,
        uint256 amount
    ) external;

    /**
     * @notice Deposits tokens from depositor using permit.
     * @param token The token to deposit.
     * @param depositor The depositor and recipient of Solace Cover Points.
     * @param amount Amount of token to deposit.
     * @param deadline Time the transaction must go through before.
     * @param v secp256k1 signature
     * @param r secp256k1 signature
     * @param s secp256k1 signature
    */
    function depositSignedStable(
        address token,
        address depositor,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @notice Deposits tokens from msg.sender and credits them to recipient.
     * @param token The token to deposit.
     * @param from The depositor of the token.
     * @param recipient The recipient of Solace Cover Points.
     * @param amount Amount of token to deposit.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
    */
    function depositNonStableFrom(
        address token,
        address from,
        address recipient,
        uint256 amount,
        uint256 price,
        uint256 priceDeadline,
        bytes calldata signature
    ) external;

    /**
     * @notice Deposits tokens from msg.sender and credits them to recipient.
     * @param token The token to deposit.
     * @param recipient The recipient of Solace Cover Points.
     * @param amount Amount of token to deposit.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
    */
    function depositNonStable(
        address token,
        address recipient,
        uint256 amount,
        uint256 price,
        uint256 priceDeadline,
        bytes calldata signature
    ) external;

    /***************************************
    WITHDRAW FUNCTIONS
    ***************************************/

    /**
     * @notice Withdraws some of the user's deposit and sends it to `recipient`.
     * User must have deposited `SOLACE` in at least that amount in the past.
     * User must have sufficient Solace Cover Points to withdraw.
     * Token must be refundable.
     * Premium pool must have the tokens to return.
     * @param amount The amount of to withdraw.
     * @param recipient The receiver of funds.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
    */
    function withdraw(
        uint256 amount,
        address recipient,
        uint256 price,
        uint256 priceDeadline,
        bytes calldata signature
    ) external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/
    
    /**
     * @notice Returns account's `SCP` balance.
     * @param account The account to fetch.
     * @return amount The amount of `SCP`.
    */
    function getSCPBalance(address account) external view returns (uint256 amount);

    /**
     * @notice Returns to token information for given token index.
     * @param index The token index.
    */
    function getTokenInfo(
        uint256 index
    ) external view returns (address token, bool accepted, bool permittable, bool refundable, bool stable);

    /**
     * @notice Calculates the refundable `SOLACE` amount.
     * @param depositor The owner of funds.
     * @param price The `SOLACE` price in wei(usd).
     * @param priceDeadline The `SOLACE` price in wei(usd).
     * @param signature The `SOLACE` price signature.
     * @return solaceAmount
     *
    */
    function getRefundableSOLACEAmount(address depositor, uint256 price, uint256 priceDeadline, bytes calldata signature) external view returns (uint256 solaceAmount);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

   /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _registry The address of `Registry` contract.
    */
    function setRegistry(address _registry) external;

    /**
     * @notice Adds or removes a set of accepted tokens.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param tokens Tokens to set.
    */
    function setTokenInfo(TokenInfo[] calldata tokens) external;

    /**
     * @notice Pauses or unpauses contract..
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param _paused True to pause, false to unpause.
    */
    function setPaused(bool _paused) external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../payment/ISCPRetainer.sol";

interface ISolaceCoverProductV3 is IERC721, ISCPRetainer {
    
    /***************************************
    ENUMS
    ***************************************/
    
    enum ChargePeriod {
        HOURLY,
        DAILY,
        WEEKLY,
        MONTHLY,
        ANNUALLY
    }

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when a new Policy is created.
    event PolicyCreated(uint256 policyID);

    /// @notice Emitted when a Policy is updated.
    event PolicyUpdated(uint256 policyID);

    /// @notice Emitted when a Policy is deactivated.
    event PolicyCanceled(uint256 policyID);

    /// @notice Emitted when Registry address is updated.
    event RegistrySet(address registry);

    /// @notice Emitted when pause is set.
    event PauseSet(bool pause);

    /// @notice Emitted when latest charged time is set.
    event LatestChargedTimeSet(uint256 timestamp);

    /// @notice Emitted when maxRate is set.
    event MaxRateSet(uint256 maxRateNum, uint256 maxRateDenom);

    /// @notice Emitted when chargeCycle is set.
    event ChargeCycleSet(uint256 chargeCycle);

    /// @notice Emitted when baseURI is set
    event BaseURISet(string baseURI);

    /// @notice Emitted when debt is added for policyholder.
    event DebtSet(address policyholder, uint256 debtAmount);

    /***************************************
    POLICY FUNCTIONS
    ***************************************/

    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @return policyID The ID of the newly minted policy.
    */
    function purchase(address _user, uint256 _coverLimit) external returns (uint256 policyID);
    
    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @return policyID The ID of the newly minted policy.
     */
     function purchaseWithStable(address _user, uint256 _coverLimit, address _token, uint256 _amount) external returns (uint256 policyID);
    
    /**
     * @notice Purchases policy for the user.
     * @param _user The policy owner.
     * @param _coverLimit The maximum value to cover in **USD**.
     * @param _token The token to deposit.
     * @param _amount Amount of token to deposit.
     * @param _price The `SOLACE` price in wei(usd).
     * @param _priceDeadline The `SOLACE` price in wei(usd).
     * @param _signature The `SOLACE` price signature.
     * @return policyID The ID of the newly minted policy.
    */
    function purchaseWithNonStable(
        address _user,
        uint256 _coverLimit,
        address _token, 
        uint256 _amount,
        uint256 _price, 
        uint256 _priceDeadline,
        bytes calldata _signature
    ) external returns (uint256 policyID);

    /**
     * @notice Cancels the policy.
     * The function cancels the policy of the policyholder.
     */
    function cancel() external;

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /**
     * @notice The maximum amount of cover that can be sold in **USD** to 18 decimals places.
     * @return cover The max amount of cover.
     */
    function maxCover() external view returns (uint256 cover);

    /**
     * @notice Returns the active cover limit in **USD** to 18 decimal places. In other words, the total cover that has been sold at the current time.
     * @return amount The active cover limit.
     */
    function activeCoverLimit() external view returns (uint256 amount);

    /**
     * @notice Determine the available remaining capacity for new cover.
     * @return availableCoverCapacity_ The amount of available remaining capacity for new cover.
     */
    function availableCoverCapacity() external view returns (uint256 availableCoverCapacity_);

    /**
     * @notice Returns true if the policy is active, false if inactive
     * @param policyID_ The policy ID.
     * @return status True if policy is active. False otherwise.
     */
    function policyStatus(uint256 policyID_) external view returns (bool status);
  
    /**
     * @notice Calculate minimum required account balance for a given cover limit. Equals the maximum chargeable fee for one epoch.
     * @param coverLimit Cover limit.
     */
    function minRequiredAccountBalance(uint256 coverLimit) external view returns (uint256 minRequiredAccountBalance_);

    /***************************************
    GOVERNANCE FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the [`Registry`](./Registry) contract address.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param registry_ The address of `Registry` contract.
     */
    function setRegistry(address registry_) external;

    /**
     * @notice Pauses or unpauses policies.
     * Deactivating policies are unaffected by pause.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param paused_ True to pause, false to unpause.
     */
    function setPaused(bool paused_) external;

    /**
     * @notice set _maxRate.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param maxRateNum_ Desired maxRateNum.
     * @param maxRateDenom_ Desired maxRateDenom.
     */
    function setMaxRate(uint256 maxRateNum_, uint256 maxRateDenom_) external;

    /**
     * @notice set _chargeCycle.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param chargeCycle_ Desired chargeCycle.
     */
    function setChargeCycle(ChargePeriod chargeCycle_) external;

    /**
     * @notice Sets the base URI for computing `tokenURI`.
     * @param baseURI_ The new base URI.
     */
    function setBaseURI(string memory baseURI_) external;

    /***************************************
    PREMIUM COLLECTOR FUNCTIONS
    ***************************************/

    /**
     * @notice Sets the latest premium charged time.
     * @param _timestamp The timestamp value when the premiums are charged.
    */
    function setChargedTime(uint256 _timestamp) external;

     /**
     * @notice Add debts for each policy holder. Can only be called by the **Premium Collector** role.
     * @param _policyholders The array of addresses of the policyholders to add debt.
     * @param _debts The array of debt amounts (in **USD** to 18 decimal places) for each policyholder.
     */
    function setDebts(address[] calldata _policyholders, uint256[] calldata _debts) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title IGovernable
 * @author solace.fi
 * @notice Enforces access control for important functions to [**governor**](/docs/protocol/governance).
 *
 * Many contracts contain functionality that should only be accessible to a privileged user. The most common access control pattern is [OpenZeppelin's `Ownable`](https://docs.openzeppelin.com/contracts/4.x/access-control#ownership-and-ownable). We instead use `Governable` with a few key differences:
 * - Transferring the governance role is a two step process. The current governance must [`setPendingGovernance(pendingGovernance_)`](#setpendinggovernance) then the new governance must [`acceptGovernance()`](#acceptgovernance). This is to safeguard against accidentally setting ownership to the wrong address and locking yourself out of your contract.
 * - `governance` is a constructor argument instead of `msg.sender`. This is especially useful when deploying contracts via a [`SingletonFactory`](./ISingletonFactory).
 * - We use `lockGovernance()` instead of `renounceOwnership()`. `renounceOwnership()` is a prerequisite for the reinitialization bug because it sets `owner = address(0x0)`. We also use the `governanceIsLocked()` flag.
 */
interface IGovernable {

    /***************************************
    EVENTS
    ***************************************/

    /// @notice Emitted when pending Governance is set.
    event GovernancePending(address pendingGovernance);
    /// @notice Emitted when Governance is set.
    event GovernanceTransferred(address oldGovernance, address newGovernance);
    /// @notice Emitted when Governance is locked.
    event GovernanceLocked();

    /***************************************
    VIEW FUNCTIONS
    ***************************************/

    /// @notice Address of the current governor.
    function governance() external view returns (address);

    /// @notice Address of the governor to take over.
    function pendingGovernance() external view returns (address);

    /// @notice Returns true if governance is locked.
    function governanceIsLocked() external view returns (bool);

    /***************************************
    MUTATORS
    ***************************************/

    /**
     * @notice Initiates transfer of the governance role to a new governor.
     * Transfer is not complete until the new governor accepts the role.
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     * @param pendingGovernance_ The new governor.
     */
    function setPendingGovernance(address pendingGovernance_) external;

    /**
     * @notice Accepts the governance role.
     * Can only be called by the new governor.
     */
    function acceptGovernance() external;

    /**
     * @notice Permanently locks this contract's governance role and any of its functions that require the role.
     * This action cannot be reversed.
     * Before you call it, ask yourself:
     *   - Is the contract self-sustaining?
     *   - Is there a chance you will need governance privileges in the future?
     * Can only be called by the current [**governor**](/docs/protocol/governance).
     */
    function lockGovernance() external;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.6;

/**
 * @title Solace Cover Points Retainer
 * @author solace.fi
 * @notice An interface for contracts that require users to maintain a minimum balance of SCP.
 */
interface ISCPRetainer {

    /**
     * @notice Calculates the minimum amount of Solace Cover Points required by this contract for the account to hold.
     * @param account Account to query.
     * @return amount The amount of SCP the account must hold.
     */
    function minScpRequired(address account) external view returns (uint256 amount);
}