/**
 *Submitted for verification at Etherscan.io on 2022-09-18
*/

// Sources flattened with hardhat v2.11.2 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

// File @openzeppelin/contracts/utils/[email protected]
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

// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

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

// File @openzeppelin/contracts/token/ERC20/[email protected]
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
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
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
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
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
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
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(
            currentAllowance >= subtractedValue,
            'ERC20: decreased allowance below zero'
        );
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
        require(from != address(0), 'ERC20: transfer from the zero address');
        require(to != address(0), 'ERC20: transfer to the zero address');

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            'ERC20: transfer amount exceeds balance'
        );
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
        require(account != address(0), 'ERC20: mint to the zero address');

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
        require(account != address(0), 'ERC20: burn from the zero address');

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, 'ERC20: burn amount exceeds balance');
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
        require(owner != address(0), 'ERC20: approve from the zero address');
        require(spender != address(0), 'ERC20: approve to the zero address');

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
            require(
                currentAllowance >= amount,
                'ERC20: insufficient allowance'
            );
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

// File contracts/CertificateManagement.sol
pragma solidity ^0.8.7;

error InvalidOrganization(address sender);
error InvalidUniversity(address sender);
error InvalidCertifier(address sender);
error InvalidSuperior(address sender);
error InvalidRevoker(address sender);
error ExistentCertificate(bytes32 certificateId, uint256 issueDate);
error ExistentCertifier(address certifier);
error InvalidDates(uint256 issueDate, uint256 expirationDate);

contract CertificateManagement is ERC20 {
    struct CertificateStatus {
        bool invalid;
        string description;
    }

    struct University {
        bool active;
        string URI;
    }

    struct Certificate {
        address certifier;
        address university;
        uint256 issueDate;
        uint256 expirationDate;
    }

    struct CompleteCertificate {
        Certificate data;
        CertificateStatus status;
    }

    uint256 public constant MAX_ALLOWANCE = 2**256 - 1;

    mapping(bytes32 => Certificate) private s_certificates;
    mapping(bytes32 => CertificateStatus) private s_revokedCertificates;
    mapping(address => bool) private s_organizations;
    mapping(address => University) private s_universities;
    mapping(address => string) private s_universityDiscreditReason;
    mapping(address => string) private s_removedUniversities;
    mapping(address => address) private s_certifierToUniversity;

    event OrganizationMemberAdded(
        address indexed organization,
        address indexed newMember
    );

    event OrganizationMemberRemoved(
        address indexed organization,
        address indexed removedMember
    );

    event UniversityAdded(
        address indexed organization,
        address indexed university
    );

    event UniversityDiscredited(
        address indexed organization,
        address indexed university,
        string reason
    );

    event CertifierAdded(address indexed university, address indexed certifier);

    event CertifierRemoved(
        address indexed certifierSuperior,
        address indexed certifier
    );

    event CertificateRegistered(
        address indexed certifier,
        bytes32 indexed certificateId
    );

    event CertificateRevoked(
        address indexed revoker,
        bytes32 indexed certificateId,
        string reason
    );

    modifier onlyOrganization() {
        if (!s_organizations[msg.sender]) {
            revert InvalidOrganization(msg.sender);
        }

        _;
    }

    modifier validUniversity(address university) {
        if (!s_universities[university].active) {
            revert InvalidUniversity(university);
        }

        _;
    }

    modifier onlyCertifierOrSuperior(address certifier) {
        address adminUniversity = s_certifierToUniversity[certifier];

        if (adminUniversity == address(0x0)) {
            revert InvalidCertifier(certifier);
        }

        bool validOrganization = s_organizations[msg.sender];

        bool isSameAdmin = adminUniversity == msg.sender;

        bool validSuperior = validOrganization || isSameAdmin;

        bool isCertifierItself = msg.sender == certifier;

        if (!validSuperior && !isCertifierItself) {
            revert InvalidSuperior(msg.sender);
        }

        _;
    }

    modifier onlyCertifier() {
        if (s_certifierToUniversity[msg.sender] == address(0x0)) {
            revert InvalidCertifier(msg.sender);
        }

        _;
    }

    modifier onlyNewCertificate(bytes32 certificateId) {
        if (s_certificates[certificateId].issueDate != 0) {
            revert ExistentCertificate(
                certificateId,
                s_certificates[certificateId].issueDate
            );
        }

        _;
    }

    modifier onlyNewCertifiers(address certifierAddress) {
        if (s_certifierToUniversity[certifierAddress] != address(0x0)) {
            revert ExistentCertifier(certifierAddress);
        }

        _;
    }

    modifier validDates(uint256 issueDate, uint256 expirationDate) {
        bool hasInvalidDate = issueDate == 0 ||
            (expirationDate != 0 && expirationDate <= issueDate);

        if (hasInvalidDate) {
            revert InvalidDates(issueDate, expirationDate);
        }

        _;
    }

    modifier onlyValidRevoker(bytes32 certificateId) {
        address universityCertificate = s_certificates[certificateId]
            .university;

        bool validOrganizatizon = s_organizations[msg.sender];

        bool isSameAdmin = msg.sender == universityCertificate ||
            universityCertificate == s_certifierToUniversity[msg.sender];

        bool isValidUniversity = s_universities[universityCertificate].active;

        bool validRevoker = validOrganizatizon ||
            (isValidUniversity && isSameAdmin);

        if (!validRevoker) {
            revert InvalidRevoker(msg.sender);
        }

        _;
    }

    constructor() ERC20('CToken', 'CTK') {
        s_organizations[msg.sender] = true;
    }

    function addOrganization(address account) external onlyOrganization {
        s_organizations[account] = true;

        emit OrganizationMemberAdded(msg.sender, account);
    }

    function removeOrganization(address account) external onlyOrganization {
        delete s_organizations[account];

        emit OrganizationMemberRemoved(msg.sender, account);
    }

    function addUniversity(address account, string memory universityURI)
        external
        onlyOrganization
    {
        s_universities[account] = University(true, universityURI);

        emit UniversityAdded(msg.sender, account);
    }

    function discreditUniversity(address account, string memory reason)
        external
        onlyOrganization
    {
        s_universities[account].active = false;

        s_universityDiscreditReason[account] = reason;

        emit UniversityDiscredited(msg.sender, account, reason);
    }

    function addCertifier(address account)
        external
        validUniversity(msg.sender)
        onlyNewCertifiers(account)
    {
        s_certifierToUniversity[account] = msg.sender;

        approve(account, MAX_ALLOWANCE);

        emit CertifierAdded(msg.sender, account);
    }

    function removeCertifier(address account)
        external
        onlyCertifierOrSuperior(account)
    {
        delete s_certifierToUniversity[account];

        approve(account, 0);

        emit CertifierRemoved(msg.sender, account);
    }

    function registerCertificate(
        bytes32 certificateId,
        uint256 issueDate,
        uint256 expirationDate
    )
        external
        onlyCertifier
        onlyNewCertificate(certificateId)
        validDates(issueDate, expirationDate)
    {
        address universityAddress = s_certifierToUniversity[msg.sender];

        University memory certifierUniversity = s_universities[
            universityAddress
        ];

        if (!certifierUniversity.active) {
            revert InvalidUniversity(universityAddress);
        }

        s_certificates[certificateId] = Certificate(
            msg.sender,
            universityAddress,
            issueDate,
            expirationDate
        );

        emit CertificateRegistered(msg.sender, certificateId);
    }

    function revokeCertificate(bytes32 certificateId, string memory reason)
        external
        onlyValidRevoker(certificateId)
    {
        s_revokedCertificates[certificateId] = CertificateStatus(true, reason);

        emit CertificateRevoked(msg.sender, certificateId, reason);
    }

    function verifyCertificate(
        bytes32 certificateId,
        Certificate memory certificate
    ) internal view returns (CertificateStatus memory) {
        CertificateStatus memory revokedCertificate = s_revokedCertificates[
            certificateId
        ];

        bool isExpired = certificate.expirationDate != 0 &&
            block.timestamp >= certificate.expirationDate;

        bool isInvalid = certificate.issueDate == 0 ||
            revokedCertificate.invalid ||
            isExpired;

        string memory description = isExpired
            ? 'Certificado expirado'
            : revokedCertificate.description;

        return CertificateStatus(isInvalid, description);
    }

    function getCertificate(bytes32 certificateId)
        external
        view
        returns (CompleteCertificate memory)
    {
        Certificate memory certificate = s_certificates[certificateId];
        CertificateStatus memory status = verifyCertificate(
            certificateId,
            certificate
        );

        return CompleteCertificate(certificate, status);
    }

    function isOrganization(address account) external view returns (bool) {
        return s_organizations[account];
    }

    function getUniversityOfCertifier(address certifier)
        external
        view
        returns (address)
    {
        return s_certifierToUniversity[certifier];
    }

    function getUniversity(address university)
        external
        view
        returns (University memory)
    {
        return s_universities[university];
    }

    function getUniversityDiscreditReason(address university)
        external
        view
        returns (string memory)
    {
        return s_universityDiscreditReason[university];
    }
}