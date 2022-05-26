// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "../interfaces/IAssetTokenData.sol";

/// @author Swarm Markets
/// @title AssetToken
/// @notice Main Asset Token Contract
contract AssetToken is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    /// @dev Used to check access to functions as a kindof modifiers
    uint256 private constant ACTIVE_CONTRACT = 1 << 0;
    uint256 private constant UNFREEZED_CONTRACT = 1 << 1;
    uint256 private constant ONLY_ISSUER = 1 << 2;
    uint256 private constant ONLY_ISSUER_OR_GUARDIAN = 1 << 3;
    uint256 private constant ONLY_ISSUER_OR_AGENT = 1 << 4;

    /// @dev This is a RAY on DSMATH representing 1
    uint256 public constant DECIMALS = 10**27;
    /// @dev This is a proportion of 1 representing 100%, equal to a RAY
    uint256 public constant HUNDRED_PERCENT = 10**27;

    /// @notice AssetTokenData Address
    address public assetTokenDataAddress;

    /// @notice Structure to hold the Mint Requests
    struct MintRequest {
        address destination;
        uint256 amount;
        string referenceTo;
        bool completed;
    }
    /// @notice Mint Requests mapping and last ID
    mapping(uint256 => MintRequest) public mintRequests;
    uint256 public mintRequestID;

    /// @notice Structure to hold the Redemption Requests
    struct RedemptionRequest {
        address sender;
        string receipt;
        uint256 assetTokenAmount;
        uint256 underlyingAssetAmount;
        bool completed;
        bool fromStake;
        string approveTxID;
        address canceledBy;
    }
    /// @notice Redemption Requests mapping and last ID
    mapping(uint256 => RedemptionRequest) public redemptionRequests;
    uint256 public redemptionRequestID;

    /// @notice stakedRedemptionRequests is map from requester to request ID
    /// @notice exists to detect that sender already has request from stake function
    mapping(address => uint256) public stakedRedemptionRequests;

    /// @notice mapping to hold each user safeguardStake amoun
    mapping(address => uint256) public safeguardStakes;

    /// @notice sum of the total stakes amounts
    uint256 public totalStakes;

    /// @notice the percetage (on 27 digits)
    /// @notice if this gets overgrown the contract change state
    uint256 public statePercent;

    /// @notice know your asset string
    string public kya;

    /// @notice minimum Redemption Amount (in Asset token value)
    uint256 public minimumRedemptionAmount;

    /// @notice Emitted when the address of the asset token data is set
    event AssetTokenDataChanged(address indexed _oldAddress, address indexed _newAddress, address indexed _caller);

    /// @notice Emitted when kya string is set
    event KyaChanged(string _kya, address indexed _caller);

    /// @notice Emitted when minimumRedemptionAmount is set
    event MinimumRedemptionAmountChanged(uint256 _newAmount, address indexed _caller);

    /// @notice Emitted when a mint request is requested
    event MintRequested(
        uint256 indexed _mintRequestID,
        address indexed _destination,
        uint256 _amount,
        address indexed _caller
    );

    /// @notice Emitted when a mint request gets approved
    event MintApproved(
        uint256 indexed _mintRequestID,
        address indexed _destination,
        uint256 _amountMinted,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is requested
    event RedemptionRequested(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        bool _fromStake,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is canceled
    event RedemptionCanceled(
        uint256 indexed _redemptionRequestID,
        address indexed _requestReceiver,
        string _motive,
        address indexed _caller
    );

    /// @notice Emitted when a redemption request is approved
    event RedemptionApproved(
        uint256 indexed _redemptionRequestID,
        uint256 _assetTokenAmount,
        uint256 _underlyingAssetAmount,
        address indexed _requestReceiver,
        address indexed _caller
    );

    /// @notice Emitted when the token gets bruned
    event TokenBurned(uint256 _amount, address indexed _caller);

    /// @notice Emitted when the contract change to safeguard
    event SafeguardUnstaked(uint256 _amount, address indexed _caller);

    /// @notice Constructor: sets the state variables and provide proper checks to deploy
    /// @param _assetTokenData the asset token data contract address
    /// @param _statePercent the state percent to check the safeguard convertion
    /// @param _kya verification link
    /// @param _minimumRedemptionAmount less than this value is not allowed
    /// @param _name of the token
    /// @param _symbol of the token
    constructor(
        address _assetTokenData,
        uint256 _statePercent,
        string memory _kya,
        uint256 _minimumRedemptionAmount,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        require(_assetTokenData != address(0), "AssetTokenData 0x0");
        require(_statePercent > 0, "Err MIN StatePercent");
        require(_statePercent <= HUNDRED_PERCENT, "Err MAX StatePercent");
        require(bytes(_kya).length > 3, "Err KYA");

        // IT IS THE RAY EQUIVALENT USED IN DSMATH
        _setupDecimals(27);
        assetTokenDataAddress = _assetTokenData;
        statePercent = _statePercent;
        kya = _kya;
        minimumRedemptionAmount = _minimumRedemptionAmount;
    }

    /// @notice kindof modifier to frist-check data on functions
    /// @param modifiers an array containing the modifiers to check (the enums)
    function checkAccessToFunction(uint256 modifiers) internal view {
        bool found = false;
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (modifiers & ACTIVE_CONTRACT != 0) {
            assetTknDtaContract.onlyActiveContract(address(this));
            found = true;
        }
        if (modifiers & UNFREEZED_CONTRACT != 0) {
            assetTknDtaContract.onlyUnfreezedContract(address(this));
            found = true;
        }
        if (modifiers & ONLY_ISSUER != 0) {
            assetTknDtaContract.onlyIssuer(address(this), _msgSender());
            found = true;
        }
        if (modifiers & ONLY_ISSUER_OR_GUARDIAN != 0) {
            assetTknDtaContract.onlyIssuerOrGuardian(address(this), _msgSender());
            found = true;
        }
        if (modifiers & ONLY_ISSUER_OR_AGENT != 0) {
            assetTknDtaContract.onlyIssuerOrAgent(address(this), _msgSender());
            found = true;
        }
        require(found, "err modifiers");
    }

    /// @notice Hook to be executed before every transfer and mint
    /// @notice This overrides the ERC20 defined function
    /// @param _from the sender
    /// @param _to the receipent
    /// @param _amount the amount (it is not used  but needed to be defined to override)
    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _amount
    ) internal virtual override {
        //  on safeguard the only available transfers are from allowed addresses and guardian
        //  or from an authorized user to this contract
        //  address(this) is added as the _from for approving redemption (burn)
        //  address(this) is added as the _to for requesting redemption (transfer to this contract)
        //  address(0) is added to the condition to allow burn on safeguard
        checkAccessToFunction(UNFREEZED_CONTRACT);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (!assetTknDtaContract.isContractActive(address(this))) {
            /// @dev  State is SAFEGUARD
            if (
                // receiver is NOT this contract AND sender is NOT this contract AND sender is NOT guardian
                _to != address(this) &&
                _from != address(this) &&
                _from != assetTknDtaContract.getGuardian(address(this))
            ) {
                require(
                    assetTknDtaContract.isAllowedTransferOnSafeguard(address(this), _from),
                    "BTT safeguard Transfer not allowed"
                );
            } else {
                require(
                    assetTknDtaContract.mustBeAuthorizedHolders(address(this), _from, _to, _amount),
                    "BTT safeguard TX not auth"
                );
            }
        } else {
            /// @dev State is ACTIVE
            // this is mint or transfer
            // mint signature: ==> _beforeTokenTransfer(address(0), account, amount);
            // burn signature: ==> _beforeTokenTransfer(account, address(0), amount);
            require(
                assetTknDtaContract.mustBeAuthorizedHolders(address(this), _from, _to, _amount),
                "BTT active TX not auth"
            );
        }

        super._beforeTokenTransfer(_from, _to, _amount);
    }

    /// @notice Sets Asset Token Data Address
    /// @param _newAddress value to be set
    function setAssetTokenData(address _newAddress) external {
        checkAccessToFunction(UNFREEZED_CONTRACT | ONLY_ISSUER_OR_GUARDIAN);
        require(_newAddress != address(0), "SAT Err newAddress");
        emit AssetTokenDataChanged(assetTokenDataAddress, _newAddress, _msgSender());
        assetTokenDataAddress = _newAddress;
    }

    /// @notice Sets the verification link
    /// @param _kya value to be set
    function setKya(string calldata _kya) external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN | UNFREEZED_CONTRACT);
        require(bytes(_kya).length > 3, "SKY Err KYA");
        emit KyaChanged(_kya, _msgSender());
        kya = _kya;
    }

    /// @notice Sets the _minimumRedemptionAmount
    /// @param _minimumRedemptionAmount value to be set
    function setMinimumRedemptionAmount(uint256 _minimumRedemptionAmount) external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN | UNFREEZED_CONTRACT);
        emit MinimumRedemptionAmountChanged(_minimumRedemptionAmount, _msgSender());
        minimumRedemptionAmount = _minimumRedemptionAmount;
    }

    /// @notice Freeze the contract
    function freezeContract() external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        require(!assetTknDtaContract.isContractFreezed(address(this)), "FZC contract Freezed");
        bool success = assetTknDtaContract.freezeContract(address(this));
        require(success, "FZC err freezing");
    }

    /// @notice unfreeze the contract
    function unfreezeContract() external {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        require(assetTknDtaContract.isContractFreezed(address(this)), "UFZ contract not Freezed");
        bool success = assetTknDtaContract.unfreezeContract(address(this));
        require(success, "UFZ err unfreezing");
    }

    /// @notice Requests a mint to the caller
    /// @param _amount the amount to mint in asset token format
    /// @return uint256 request ID to be referenced in the mapping
    function requestMint(uint256 _amount) external returns (uint256) {
        return _requestMint(_amount, _msgSender());
    }

    /// @notice Requests a mint to the _destination address
    /// @param _amount the amount to mint in asset token format
    /// @param _destination the receiver of the tokens
    /// @return uint256 request ID to be referenced in the mapping
    function requestMint(uint256 _amount, address _destination) external returns (uint256) {
        return _requestMint(_amount, _destination);
    }

    /// @notice Performs the Mint Request to the destination address
    /// @param _amount entered in the external functions
    /// @param _destination the receiver of the tokens
    /// @return uint256 request ID to be referenced in the mapping
    function _requestMint(uint256 _amount, address _destination) private returns (uint256) {
        checkAccessToFunction(ACTIVE_CONTRACT | UNFREEZED_CONTRACT | ONLY_ISSUER_OR_AGENT);
        require(_amount > 0, "RQM Err amount");
        uint256 _mintRequestID = ++mintRequestID;
        mintRequests[_mintRequestID] = MintRequest(_destination, _amount, "", false);
        mintRequestID = _mintRequestID;
        emit MintRequested(_mintRequestID, _destination, _amount, _msgSender());

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (_msgSender() == assetTknDtaContract.getIssuer(address(this))) {
            approveMint(_mintRequestID, "IssuerMint");
        }
        return _mintRequestID;
    }

    /// @notice Approves the Mint Request
    /// @param _mintRequestID the ID to be referenced in the mapping
    /// @param _referenceTo reference comment for the issuer
    function approveMint(uint256 _mintRequestID, string memory _referenceTo) public nonReentrant {
        checkAccessToFunction(ACTIVE_CONTRACT | ONLY_ISSUER);
        require(mintRequests[_mintRequestID].destination != address(0), "APM Err RequestID");
        require(!mintRequests[_mintRequestID].completed, "APM completed");

        mintRequests[_mintRequestID].completed = true;
        mintRequests[_mintRequestID].referenceTo = _referenceTo;

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        assetTknDtaContract.update(address(this));
        uint256 currentRate = assetTknDtaContract.getCurrentRate(address(this));

        uint256 amountToMint = mintRequests[_mintRequestID].amount.mul(DECIMALS).div(currentRate);
        emit MintApproved(_mintRequestID, mintRequests[_mintRequestID].destination, amountToMint, _msgSender());

        _mint(mintRequests[_mintRequestID].destination, amountToMint);
    }

    /// @notice Requests an amount of assetToken Redemption
    /// @param _assetTokenAmount the amount of Asset Token to be redeemed
    /// @param _destination the off chain hash of the redemption transaction
    /// @return uint256 redemptionRequest ID to be referenced in the mapping
    function requestRedemption(uint256 _assetTokenAmount, string calldata _destination)
        external
        nonReentrant
        returns (uint256)
    {
        require(_assetTokenAmount > 0, "RRD Err amount");
        require(balanceOf(_msgSender()) >= _assetTokenAmount, "RRD not enough funds");

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        address issuer = assetTknDtaContract.getIssuer(address(this));
        address guardian = assetTknDtaContract.getGuardian(address(this));
        bool isActive = assetTknDtaContract.isContractActive(address(this));

        if ((isActive && _msgSender() != issuer) || (!isActive && _msgSender() != guardian)) {
            require(_assetTokenAmount >= minimumRedemptionAmount, "RRD minRedAmount not reached");
        }

        assetTknDtaContract.update(address(this));
        uint256 currentRate = assetTknDtaContract.getCurrentRate(address(this));
        uint256 underlyingAssetAmount = _assetTokenAmount.mul(currentRate).div(DECIMALS);

        redemptionRequestID = redemptionRequestID.add(1);
        emit RedemptionRequested(redemptionRequestID, _assetTokenAmount, underlyingAssetAmount, false, _msgSender());

        redemptionRequests[redemptionRequestID] = RedemptionRequest(
            _msgSender(),
            _destination,
            _assetTokenAmount,
            underlyingAssetAmount,
            false,
            false,
            "",
            address(0)
        );

        /// @dev make the transfer to the contract for the amount requested (27 digits)
        _transfer(_msgSender(), address(this), _assetTokenAmount);

        /// @dev approve instantly when called by issuer or guardian
        if ((isActive && _msgSender() == issuer) || (!isActive && _msgSender() == guardian)) {
            approveRedemption(redemptionRequestID, "AutomaticRedemptionApproval");
        }

        return redemptionRequestID;
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _motive motive of the cancelation
    function cancelRedemptionRequest(uint256 _redemptionRequestID, string calldata _motive) external {
        require(redemptionRequests[_redemptionRequestID].sender != address(0), "CRR: invalid ID provided");
        require(redemptionRequests[_redemptionRequestID].canceledBy == address(0), "CRR: redemption canceled");
        require(!redemptionRequests[_redemptionRequestID].completed, "CRR: already completed");
        require(!redemptionRequests[_redemptionRequestID].fromStake, "CRR: staked request - unstake to redeem");
        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (_msgSender() != redemptionRequests[_redemptionRequestID].sender) {
            // not owner of the redemption so guardian or issuer should be the caller
            assetTknDtaContract.onlyIssuerOrGuardian(address(this), _msgSender());
        }

        uint256 refundAmount = redemptionRequests[_redemptionRequestID].assetTokenAmount;
        emit RedemptionCanceled(
            _redemptionRequestID,
            redemptionRequests[_redemptionRequestID].sender,
            _motive,
            _msgSender()
        );

        redemptionRequests[_redemptionRequestID].assetTokenAmount = 0;
        redemptionRequests[_redemptionRequestID].underlyingAssetAmount = 0;
        redemptionRequests[_redemptionRequestID].canceledBy = _msgSender();

        _transfer(address(this), redemptionRequests[_redemptionRequestID].sender, refundAmount);
    }

    /// @notice Approves the Redemption Requests
    /// @param _redemptionRequestID redemption request ID to be referenced in the mapping
    /// @param _approveTxID the transaction ID
    function approveRedemption(uint256 _redemptionRequestID, string memory _approveTxID) public {
        checkAccessToFunction(ONLY_ISSUER_OR_GUARDIAN);
        require(redemptionRequests[_redemptionRequestID].canceledBy == address(0), "APR RD canceled");
        require(redemptionRequests[_redemptionRequestID].sender != address(0), "APR Err on ID");
        require(!redemptionRequests[_redemptionRequestID].completed, "APR RD completed");

        if (redemptionRequests[_redemptionRequestID].fromStake) {
            IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
            require(!assetTknDtaContract.isContractActive(address(this)), "APR not Safeguard");
        }

        emit RedemptionApproved(
            _redemptionRequestID,
            redemptionRequests[_redemptionRequestID].assetTokenAmount,
            redemptionRequests[_redemptionRequestID].underlyingAssetAmount,
            redemptionRequests[_redemptionRequestID].sender,
            _msgSender()
        );
        redemptionRequests[_redemptionRequestID].completed = true;
        redemptionRequests[_redemptionRequestID].approveTxID = _approveTxID;

        // burn tokens from the contract
        _burn(address(this), redemptionRequests[_redemptionRequestID].assetTokenAmount);
    }

    /// @notice Burns a certain amount of tokens
    /// @param _amount qty of assetTokens to be burned
    function burn(uint256 _amount) external {
        emit TokenBurned(_amount, _msgSender());
        _burn(_msgSender(), _amount);
    }

    /// @notice Performs the Safeguard Stake
    /// @param _amount the assetToken amount to be staked
    /// @param _receipt the off chain hash of the redemption transaction
    function safeguardStake(uint256 _amount, string calldata _receipt) external nonReentrant {
        checkAccessToFunction(ACTIVE_CONTRACT);
        require(balanceOf(_msgSender()) >= _amount, "SFS insufficient funds");

        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()].add(_amount);
        totalStakes = totalStakes.add(_amount);
        uint256 stakedPercent = totalStakes.mul(HUNDRED_PERCENT).div(totalSupply());

        IAssetTokenData assetTknDtaContract = IAssetTokenData(assetTokenDataAddress);
        if (stakedPercent >= statePercent) {
            require(assetTknDtaContract.setContractToSafeguard(address(this)), "SFS Err safeguard change");
            /// @dev now the contract is on safeguard
        }

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        if (_requestID == 0) {
            /// @dev zero means that it's new request
            redemptionRequestID = redemptionRequestID.add(1);
            redemptionRequests[redemptionRequestID] = RedemptionRequest(
                _msgSender(),
                _receipt,
                _amount,
                0,
                false,
                true,
                "",
                address(0)
            );

            stakedRedemptionRequests[_msgSender()] = redemptionRequestID;
            _requestID = redemptionRequestID;
        } else {
            /// @dev non zero means the request already exist and need only add amount
            redemptionRequests[_requestID].assetTokenAmount = redemptionRequests[_requestID].assetTokenAmount.add(
                _amount
            );
        }

        emit RedemptionRequested(
            _requestID,
            redemptionRequests[_requestID].assetTokenAmount,
            redemptionRequests[_requestID].underlyingAssetAmount,
            true,
            _msgSender()
        );
        _transfer(_msgSender(), address(this), _amount);
    }

    /// @notice Calls to UnStake all the funds
    function safeguardUnstake() external {
        _safeguardUnstake(safeguardStakes[_msgSender()]);
    }

    /// @notice Calls to UnStake with a certain amount
    /// @param _amount to be unStaked in asset token
    function safeguardUnstake(uint256 _amount) external {
        _safeguardUnstake(_amount);
    }

    /// @notice Performs the UnStake with a certain amount
    /// @param _amount to be unStaked in asset token
    function _safeguardUnstake(uint256 _amount) private {
        checkAccessToFunction(ACTIVE_CONTRACT | UNFREEZED_CONTRACT);
        require(_amount > 0, "SFU amount ZERO");
        require(safeguardStakes[_msgSender()] >= _amount, "SFU amount exceeds staked");

        emit SafeguardUnstaked(_amount, _msgSender());
        safeguardStakes[_msgSender()] = safeguardStakes[_msgSender()].sub(_amount);
        totalStakes = totalStakes.sub(_amount);

        uint256 _requestID = stakedRedemptionRequests[_msgSender()];
        redemptionRequests[_requestID].assetTokenAmount = redemptionRequests[_requestID].assetTokenAmount.sub(_amount);

        _transfer(address(this), _msgSender(), _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

import "../../GSN/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

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
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
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
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
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

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
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
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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

    constructor () {
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;

/// @author Swarm Markets
/// @title
/// @notice
/// @notice

interface IAssetTokenData {
    function getIssuer(address _tokenAddress) external view returns (address);

    function getGuardian(address _tokenAddress) external view returns (address);

    function setContractToSafeguard(address _tokenAddress) external returns (bool);

    function freezeContract(address _tokenAddress) external returns (bool);

    function unfreezeContract(address _tokenAddress) external returns (bool);

    function isContractActive(address _tokenAddress) external view returns (bool);

    function isContractFreezed(address _tokenAddress) external view returns (bool);

    function beforeTokenTransfer(address, address) external;

    function onlyStoredToken(address _tokenAddress) external view;

    function onlyActiveContract(address _tokenAddress) external view;

    function onlyUnfreezedContract(address _tokenAddress) external view;

    function onlyIssuer(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrGuardian(address _tokenAddress, address _functionCaller) external view;

    function onlyIssuerOrAgent(address _tokenAddress, address _functionCaller) external view;

    function checkIfTransactionIsAllowed(
        address _caller,
        address _from,
        address _to,
        address _tokenAddress,
        bytes4 _operation,
        bytes calldata _data
    ) external view returns (bool);

    function mustBeAuthorizedHolders(
        address _tokenAddress,
        address _from,
        address _to,
        uint256 _amount
    ) external returns (bool);

    function update(address _tokenAddress) external;

    function getCurrentRate(address _tokenAddress) external view returns (uint256);

    function hasRole(bytes32 role, address account) external view returns (bool);

    function isAllowedTransferOnSafeguard(address _tokenAddress, address _account) external view returns (bool);

    function registerAssetToken(
        address _tokenAddress,
        address _issuer,
        address _guardian
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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