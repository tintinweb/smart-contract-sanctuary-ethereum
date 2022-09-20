// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "./Agreement.sol";
import "./IERC20.sol";
import "./ImexAccessControl.sol";

/**
 * @title Escrow Contract
 *
 * @notice Escrow smart contract is used to deploy a new agreement between
 * exporter and importer
 * @notice It acts as a factory for the agreement smart contract
 * @notice It stores the address of the newly deployed agreement against its order Id,
 *   so that anyone can access that agreement at anytime by it's order ID.
 *
 * @author ScytaleLabs
 */
contract Escrow is ContextUpgradeable, ImexAccessControl {
    address public admin;
    address public beneficiary;
    address public agreementContractImplementation;
    IERC20 public token;

    mapping(uint256 => address) public agreements;

    // solhint-disable-next-line func-name-mixedcase

    /**
     * @notice This function is called instead of constructor because contract is upgradeable
     * @notice grants DEFUALT_ADMIN_ROLE TO _admin
     * @notice revokes DEFUALT_ADMIN_ROLE From escrow contract
     *
     * @dev Requires _beneficiary to not be null
     *
     * @param _token address of erc20
     * @param _agreementContractImplementation implementation of agreement contract to create clones
     * @param _beneficiary address of beneficiary
     */
    function __Escrow_init(
        IERC20 _token,
        address _agreementContractImplementation,
        address _beneficiary,
        address _admin
    ) public initializer {
        ContextUpgradeable.__Context_init();
        ImexAccessControl.__ImexAccessControl_init();
        require(_beneficiary != address(0x0), "_beneficiary address is null.");
        beneficiary = _beneficiary;
        admin = _admin;
        token = _token;
        agreementContractImplementation = _agreementContractImplementation;
    }

    /* EVENTS */
    event NewOrder(uint256, address);

    //uint admin share (with total token)
    /**
     * @notice This function creates a new agreement contract against the orderId and
     * transfers tokens to it
     *
     * @dev
     *      Requirments
     *        - transaction sender to has agreementCreator Role
     *        - agreement does not exist against _orderId
     *        - _orderId is valid (_orderId >= 1)
     *        - _totalTokens is valid (_totalTokens >= 1)
     *        - _importer and _exporter addresses are not null
     *        - _adminShare is greater than 0
     *        - importer has enough tokens(_totalTokens + _adminShare)
     *        - Escrow Contract has enough approved tokens(_totalTokens + _adminShare)
     *        from importer
     * @dev Emits new order event
     *
     * @param _orderId Create new agreement against orderId
     * @param _importer address of importer for the agreement
     * @param _exporter address of exporter for the agreement
     * @param _totalTokens tokens from the importer for product
     * @param _adminShare tokens from importer for beneficiary
     * @param _documentHash documentHash of the agreement
     */
    function createNewAgreement(
        uint256 _orderId,
        address _importer,
        address _exporter,
        uint256 _totalTokens,
        uint256 _adminShare,
        bytes32[] memory _documentHash
    ) public onlyAgreementCreator {
        require(
            agreements[_orderId] == address(0x0),
            "An agreement exists for this Id"
        );

        require(_orderId >= 1, "Invalid order Id");
        require(_totalTokens >= 1, "Invalid _totalTokens");
        require(_importer != address(0x0), "_importer address is null.");
        require(_exporter != address(0x0), "_exporter address is null.");
        require(_adminShare > 0, "Invalid _adminShare");
        uint256 tokensFromImporter = _totalTokens + _adminShare;

        require(
            token.balanceOf(_importer) >= tokensFromImporter,
            "Not enough balance"
        );
        require(
            token.allowance(_importer, address(this)) >= tokensFromImporter,
            "Not enough approved tokens"
        );
        //admin share, admin of token address(beneficiary)
        address agreementClone = Clones.clone(agreementContractImplementation);
        Agreement(agreementClone).__Agreement_init(
            admin,
            _importer,
            _exporter,
            _totalTokens,
            _adminShare,
            beneficiary,
            _documentHash,
            token
        );

        agreements[_orderId] = agreementClone;

        eip20CompliantAndNonComplaintTransferFrom(
            _importer,
            address(agreementClone),
            tokensFromImporter
        );

        emit NewOrder(_orderId, address(agreementClone));
    }

    /**
     * @notice This function gets agreement contract against specific order ID
     *
     * @param _orderId specific orderId to get agreement against it
     *
     * @return the agreement Contract Address against the orderId
     */
    function getAgreementAddress(uint256 _orderId)
        public
        view
        returns (address)
    {
        return agreements[_orderId];
    }

    /**
     * @notice This function gets document hash against specific order ID
     *
     * @param _orderId specific orderId to get document hash against it
     * @return the hash of the document against the orderId
     */
    function getDocumentHash(uint256 _orderId)
        public
        view
        returns (bytes32[] memory)
    {
        require(
            agreements[_orderId] != address(0x0),
            "No order found for this orderID"
        );

        Agreement obj = Agreement(agreements[_orderId]);
        return obj.getDocumentHash();
    }

    /**
     * @notice This function is used to call transferFrom function to make sure
     * our contract supports both complaint eip20 and non-complaint eip20
     *
     * @param from address to transfer tokens from
     * @param to address to transfer tokens to
     * @param amount amount of tokens to transfer
     *
     */
    function eip20CompliantAndNonComplaintTransferFrom(
        address from,
        address to,
        uint256 amount
    ) private {
        token.transferFrom(from, to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of override external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./ImexAccessControl.sol";
import "./IERC20.sol";

/**
 * @title Agreement Contract
 *
 * @notice Agreement smart contract is the actual deal signed between an
 * importer and exporter.
 * @notice stores the data related to the agreement
 * @notice transfers tokens between importer,  exporter and beneficiary
 * @author ScytaleLabs
 */
contract Agreement is ImexAccessControl, PausableUpgradeable {
    address public admin;
    address public importer;
    address public exporter;
    uint256 public totalTokens;
    uint256 public adminShare;
    address public beneficiary;
    bytes32[] public documentHash;
    IERC20 public token;
    bool public isAgreementOpen;

    //modifiers
    modifier whenAgreementOpen() {
        require(isAgreementOpen == true, "Agreement is closed");
        _;
    }

    modifier hasEnoughTokensFromImporter() {
        require(
            token.balanceOf(address(this)) >= totalTokens + adminShare,
            "Not enough tokens from Importer"
        );
        _;
    }

    /* EVENTS */

    /**
     * @notice This event is emitted when funds are released using releaseFunds()
     *
     * @param exporter address of exporter
     * @param beneficiary address of beneficiary
     * @param totalTokens amount of tokens transferred to exporter
     * @param adminShare amount of tokens transferred to beneficiary
     */
    event FundReleased(
        address exporter,
        address beneficiary,
        uint256 totalTokens,
        uint256 adminShare
    );

    /**
     * @notice This event is emitted when dispute is solved using solveDispute()
     *
     * @param tokensToImporter amount of tokens transferred to importer
     * @param importer address of importer
     * @param tokensToExporter amount of tokens transferred to exporter
     * @param exporter address of exporter
     * @param adminShare amount of tokens transferred to beneficiary
     * @param beneficiary address of beneficiary
     */
    event DisputeSolved(
        uint256 tokensToImporter,
        address importer,
        uint256 tokensToExporter,
        address exporter,
        uint256 adminShare,
        address beneficiary
    );

    /**
     * @notice This event is emitted when funds are transferred to importer
     *
     * @param importer address of importer
     * @param totalTokens amount of tokens transferred to importer
     * @param beneficiary address of beneficiary
     * @param adminShare amount of tokens transferred to beneficiary
     */
    event FundsTransferredToImporter(
        address importer,
        uint256 totalTokens,
        address beneficiary,
        uint256 adminShare
    );

    /**
     * @notice This event is emitted when funds are transferred to exporter
     *
     * @param exporter address of importer
     * @param totalTokens amount of tokens transferred to exporter
     * @param beneficiary address of beneficiary
     * @param adminShare amount of tokens transferred to beneficiary
     */
    event FundsTransferredToExporter(
        address exporter,
        uint256 totalTokens,
        address beneficiary,
        uint256 adminShare
    );

    /**
     * @notice This event is emitted when extra funds are transferred to receipient
     *
     * @param admin address of receipient
     * @param extraBalance amount of extra tokens transferred to receipient
     */
    event ExtraFundsTransferredToAdmin(address admin, uint256 extraBalance);

    // handle admin share and beneficiary
    // solhint-disable-next-line func-name-mixedcase

    /**
     * @notice This function is called instead of constructor because contract is upgradeable
     * @notice grants DEFUALT_ADMIN_ROLE TO _admin
     * @notice revokes DEFUALT_ADMIN_ROLE From escrow contract
     *
     * @param _admin address of admin
     * @param _importer address of importer
     * @param _exporter address of exporter
     * @param _totalTokens amount of tokens from importer
     * @param _adminShare share of beneficiary from importer
     * @param _beneficiary address of beneficiary
     */
    function __Agreement_init(
        address _admin,
        address _importer,
        address _exporter,
        uint256 _totalTokens,
        uint256 _adminShare,
        address _beneficiary,
        bytes32[] memory _documentHash,
        IERC20 _token
    ) public initializer {
        PausableUpgradeable.__Pausable_init();
        ImexAccessControl.__ImexAccessControl_init();

        grantRole(DEFAULT_ADMIN_ROLE, _admin);

        admin = _admin;
        importer = _importer;
        exporter = _exporter;
        totalTokens = _totalTokens;
        adminShare = _adminShare;
        beneficiary = _beneficiary;
        documentHash = _documentHash;
        token = _token;
        isAgreementOpen = true;

        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /**
     * @notice This function release funds locked by importer.
     * @notice Importer sends its tokens to the agreement smart contract to lock the funds.
     * Once the conditions of the deal are fulfilled, fundsReleaser will call this function
     * and total tokens will be transferred to exporter and adminShare is transferred
     * to beneficiary
     *
     * @dev
     *      Requirments
     *        - transaction sender have a fundsReleaser Role
     *        - contract is not paused
     *        - isAgreementOpen variable is true
     * @dev Emits FundReleased Event
     *
     */
    function releaseFunds()
        public
        whenNotPaused
        whenAgreementOpen
        onlyFundsReleaser
        hasEnoughTokensFromImporter
    {
        isAgreementOpen = false;
        eip20CompliantAndNonComplaintTransfer(exporter, totalTokens);
        eip20CompliantAndNonComplaintTransfer(beneficiary, adminShare);
        emit FundReleased(exporter, beneficiary, totalTokens, adminShare);
    }

    /**
     * @notice This function solves the dispute in case importer or exporter has some issue,
     *  Dispute Solver will resolve the issue and check who is right and who is wrong.
     *  Depending on conclusion dispute solver will divide and send tokens to importer
     *  and exporter, and admin share to beneficiary
     *
     * @dev
     *      Requirments
     *        - transaction sender have a disputeSolver Role
     *        - contract is not paused
     *        - isAgreementOpen variable is true
     * @dev Emits DisputeSolved event
     *
     * @param _tokensToImporter importer's partition
     * @param _tokensToExporter exporter's partition
     */
    function solveDispute(uint256 _tokensToImporter, uint256 _tokensToExporter)
        public
        whenAgreementOpen
        onlyDisputeSolver
        whenNotPaused
        hasEnoughTokensFromImporter
    {
        require(
            _tokensToImporter + _tokensToExporter == totalTokens,
            "Invalid Token Partition"
        );

        isAgreementOpen = false;
        eip20CompliantAndNonComplaintTransfer(importer, _tokensToImporter);
        eip20CompliantAndNonComplaintTransfer(exporter, _tokensToExporter);
        eip20CompliantAndNonComplaintTransfer(beneficiary, adminShare);
        emit DisputeSolved(
            _tokensToImporter,
            importer,
            _tokensToExporter,
            exporter,
            adminShare,
            beneficiary
        );
    }

    /**
     * @notice This function transfers total tokens back to importer and admin share to beneficiary.
     * When there is a dispute, admin resolves the issue and decides to send
     * all the tokens back to importer.
     *
     * @dev
     *      Requirments
     *        - transaction sender is admin
     *        - contract is not paused
     *        - isAgreementOpen variable is true
     * @dev Emits FundsTransferredToImporter event
     *
     */
    function transferFundsBackToImporter()
        public
        onlyAdmin
        whenNotPaused
        whenAgreementOpen
        hasEnoughTokensFromImporter
    {
        isAgreementOpen = false;
        eip20CompliantAndNonComplaintTransfer(beneficiary, adminShare);
        eip20CompliantAndNonComplaintTransfer(importer, totalTokens);
        emit FundsTransferredToImporter(
            importer,
            totalTokens,
            beneficiary,
            adminShare
        );
    }

    /**
     * @notice This function transfers total tokens to exporter and admin share to beneficiary
     * When there is a dispute, admin resolves the issue and decides to send
     * all the tokens to exporter.
     * @dev
     *      Requirments
     *        - transaction sender is admin
     *        - contract is not paused
     *        - isAgreementOpen variable is true
     * @dev Emits FundsTransferredToExporter event
     *
     */
    function transferFundsToExporter()
        public
        onlyAdmin
        whenNotPaused
        whenAgreementOpen
        hasEnoughTokensFromImporter
    {
        isAgreementOpen = false;
        eip20CompliantAndNonComplaintTransfer(beneficiary, adminShare);
        eip20CompliantAndNonComplaintTransfer(exporter, totalTokens);
        emit FundsTransferredToExporter(
            exporter,
            totalTokens,
            beneficiary,
            adminShare
        );
    }

    /**
     * @notice This function transfers extra funds to receipient.
     * If there are some extra tokens locked in the contract other then
     * the desired total tokens and admin share, admin can send them to a recepient address
     *
     * @dev
     *      Requirments
     *        - transaction sender is admin
     *        - contract is not paused
     *        - isAgreementOpen variable is true
     * @dev Emits ExtraFundsTransferredToAdmin event
     *
     * @param _receipient address to send extra funds
     * @param _amount amount of extra funds to send
     */
    function transferExtraFundsToAdmin(address _receipient, uint256 _amount)
        public
        onlyAdmin
        whenNotPaused
    {
        require(_receipient != address(0x0), "_recepient is null");
        require(_amount > 0, "_amount is null");
        uint256 totalFundsLocked = token.balanceOf(address(this));
        uint256 actualFunds = totalTokens + adminShare;
        require(totalFundsLocked > actualFunds, "No extra funds from importer");
        uint256 extraFunds = totalFundsLocked - actualFunds;
        require(_amount <= extraFunds, "_amount exceeds extra funds");
        eip20CompliantAndNonComplaintTransfer(_receipient, _amount);
        emit ExtraFundsTransferredToAdmin(_receipient, _amount);
    }

    /**
     * @notice This function is used to get document hash of the contract
     *
     * @return the hash of the agreement document
     */
    function getDocumentHash() public view returns (bytes32[] memory) {
        return documentHash;
    }

    /**
     * @notice This function is used to get total balance of agreement contract
     *
     * @return the balance of the contract
     */
    function thisContractTotalBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    /**
     * @notice This function pauses the contract
     *
     * @dev Requires transaction sender to have a pauser role
     *
     */
    function pause() public onlyPauser {
        _pause();
    }

    /**
     * @notice This function unpauses the contract
     *
     * @dev Requires transaction sender to have a pauser role
     *
     */
    function unpause() public onlyPauser {
        _unpause();
    }

    /**
     * @notice This function is used to call transfer function to make sure
     * our contract supports both complaint eip20 and non-complaint eip20
     *
     * @param to address to transfer tokens to
     * @param amount amount of tokens to transfer
     *
     */
    function eip20CompliantAndNonComplaintTransfer(address to, uint256 amount)
        private
    {
        token.transfer(to, amount);

        bool success;
        assembly {
            switch returndatasize()
            case 0 {
                // This is a non-standard ERC-20
                success := not(0) // set success to true
            }
            case 32 {
                // This is a compliant ERC-20
                returndatacopy(0, 0, 32)
                success := mload(0) // Set `success = returndata` of override external call
            }
            default {
                // This is an excessively non-compliant ERC-20, revert.
                revert(0, 0)
            }
        }
        require(success, "TOKEN_TRANSFER_IN_FAILED");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external;

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external;

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external;
}

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.4;

import "./IAccessExtension.sol";

/**
 * @title Roles and features
 *
 * @notice Controls all roles in ChainVision
 * @notice Maintains whitelist of users which can access ChainVision Services
 * @notice The whitelist is local in scope
 * @author Zaid Munir
 */

contract ImexAccessControl is AccessExtension {
    //ROLES
    bytes32 public constant AGREEMENT_CREATOR_ROLE =
        keccak256("AGREEMENT_CREATOR_ROLE");

    bytes32 public constant FUNDS_RELEASER_ROLE =
        keccak256("FUNDS_RELEASER_ROLE");

    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    bytes32 public constant DISPUTE_SOLVER_ROLE =
        keccak256("DISPUTE_SOLVER_ROLE");

    bytes32 public constant KYC_MANAGER_ROLE = keccak256("KYC_MANAGER_ROLE");

    //MODIFIERS

    modifier onlyKYCManager() {
        require(
            hasRole(KYC_MANAGER_ROLE, _msgSender()),
            "User is not a KYCManager"
        );
        _;
    }
    modifier onlyAgreementCreator() {
        require(
            hasRole(AGREEMENT_CREATOR_ROLE, _msgSender()),
            "User is not a Agreement Creator"
        );
        _;
    }
    modifier onlyFundsReleaser() {
        require(
            hasRole(FUNDS_RELEASER_ROLE, _msgSender()),
            "User is not a Funds Releaser"
        );
        _;
    }
    modifier onlyPauser() {
        require(hasRole(PAUSER_ROLE, _msgSender()), "User is not a Pauser");
        _;
    }
    modifier onlyDisputeSolver() {
        require(
            hasRole(DISPUTE_SOLVER_ROLE, _msgSender()),
            "User is not a Dispute Solver"
        );
        _;
    }

    modifier onlyAdmin() {
        require(
            hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
            "User is not an Admin"
        );
        _;
    }

    // solhint-disable-next-line func-name-mixedcase
    function __ImexAccessControl_init() public onlyInitializing {
        AccessExtension.__AccessControlExtension_init();
        _setRoleAdmin(KYC_MANAGER_ROLE, DEFAULT_ADMIN_ROLE);

        _setRoleAdmin(FUNDS_RELEASER_ROLE, DEFAULT_ADMIN_ROLE);

        _setRoleAdmin(PAUSER_ROLE, DEFAULT_ADMIN_ROLE);

        _setRoleAdmin(DISPUTE_SOLVER_ROLE, DEFAULT_ADMIN_ROLE);

        _setRoleAdmin(AGREEMENT_CREATOR_ROLE, DEFAULT_ADMIN_ROLE);
    }

    //FUNCTIONS
    function grantRoleKYCManager(address _to) public {
        grantRole(KYC_MANAGER_ROLE, _to);
    }

    function revokeRoleKYCManager(address _to) public {
        revokeRole(KYC_MANAGER_ROLE, _to);
    }

    function grantRoleAgreementCreator(address _to) public {
        grantRole(AGREEMENT_CREATOR_ROLE, _to);
    }

    function revokeRoleAgreementCreator(address _to) public {
        revokeRole(AGREEMENT_CREATOR_ROLE, _to);
    }

    function grantRoleFundsReleaser(address _to) public {
        grantRole(FUNDS_RELEASER_ROLE, _to);
    }

    function revokeRoleFundsReleaser(address _to) public {
        revokeRole(FUNDS_RELEASER_ROLE, _to);
    }

    function grantRolePauser(address _to) public {
        grantRole(PAUSER_ROLE, _to);
    }

    function revokeRolePauser(address _to) public {
        revokeRole(PAUSER_ROLE, _to);
    }

    function grantRoleDisputeSolver(address _to) public {
        grantRole(DISPUTE_SOLVER_ROLE, _to);
    }

    function revokeRoleDisputeSolver(address _to) public {
        revokeRole(DISPUTE_SOLVER_ROLE, _to);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @title Access Control List Extension Interface
 *
 * @notice External interface of AccessExtension declared to support ERC165 detection.
 *      See Access Control List Extension documentation below.
 *
 * @author Zaid Munir
 */
interface IAccessExtension is IAccessControlUpgradeable {
    function removeFeature(bytes32 feature) external;

    function addFeature(bytes32 feature) external;

    function isFeatureEnabled(bytes32 feature) external view returns (bool);
}

/**
 * @title Access Control List Extension
 *
 * @notice Access control smart contract provides an API to check
 *      if specific operation is permitted globally and/or
 *      if particular user has a permission to execute it.
 *
 * @notice It deals with two main entities: features and roles.
 *
 * @notice Features are designed to be used to enable/disable specific
 *      functions (public functions) of the smart contract for everyone.
 * @notice User roles are designed to restrict access to specific
 *      functions (restricted functions) of the smart contract to some users.
 *
 * @notice Terms "role", "permissions" and "set of permissions" have equal meaning
 *      in the documentation text and may be used interchangeably.
 * @notice Terms "permission", "single permission" implies only one permission set.
 *
 * @dev OpenZeppelin AccessControl based implementation. Features are stored as
 *      "self"-roles: feature is a role assigned to the smart contract itself
 *
 * @dev Automatically assigns the deployer an admin permission
 *
 * @dev This smart contract is designed to be inherited by other
 *      smart contracts which require access control management capabilities.
 *
 * @author Zaid Munir
 */
contract AccessExtension is IAccessExtension, AccessControlUpgradeable {
    // constructor() {
    //  // setup admin role for smart contract deployer initially
    //  _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    // }
    // solhint-disable-next-line func-name-mixedcase
    function __AccessControlExtension_init() internal onlyInitializing {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        // reconstruct from current interface and super interface
        return
            interfaceId == type(IAccessExtension).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @notice Removes the feature from the set of the globally enabled features,
     *      taking into account sender's permissions
     *
     * @dev Requires transaction sender to have a permission to set the feature requested
     *
     * @param feature a feature to disable
     */
    function removeFeature(bytes32 feature) public override {
        // delegate to Zeppelin's `revokeRole`
        revokeRole(feature, address(this));
    }

    /**
     * @notice Adds the feature to the set of the globally enabled features,
     *      taking into account sender's permissions
     *
     * @dev Requires transaction sender to have a permission to set the feature requested
     *
     * @param feature a feature to enable
     */
    function addFeature(bytes32 feature) public override {
        // delegate to Zeppelin's `grantRole`
        grantRole(feature, address(this));
    }

    /**
     * @notice Checks if requested feature is enabled globally on the contract
     *
     * @param feature the feature to check
     * @return true if the feature requested is enabled, false otherwise
     */
    function isFeatureEnabled(bytes32 feature)
        public
        view
        override
        returns (bool)
    {
        // delegate to Zeppelin's `hasRole`
        return hasRole(feature, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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