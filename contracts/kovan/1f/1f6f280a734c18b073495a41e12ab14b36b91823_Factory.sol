/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.7;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
interface ControllerInterface {
    function mint(address to, uint256 amount) external returns (bool);

    function burn(address from, uint256 value) external returns (bool);

    function isCustodian(address addr) external view returns (bool);

    function isMerchant(address addr) external view returns (bool);

    function getToken() external view returns (address);
}
interface FactoryInterface {
    function setCustodianDepositAddress(address merchant, string memory depositAddress) external returns (bool);

    function setMerchantDepositAddress(string memory depositAddress) external returns (bool);

    function setMerchantMintLimit(address merchant, uint256 amount) external returns (bool);

    function setMerchantBurnLimit(address merchant, uint256 amount) external returns (bool);

    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) external returns (bool);

    function cancelMintRequest(bytes32 requestHash) external returns (bool);

    function confirmMintRequest(bytes32 requestHash) external returns (bool);

    function rejectMintRequest(bytes32 requestHash) external returns (bool);

    function burn(uint256 amount) external returns (bool);

    function confirmBurnRequest(bytes32 requestHash, string memory txid) external returns (bool);

    function getMintRequestsLength() external view returns (uint256 length);

    function getBurnRequestsLength() external view returns (uint256 length);

    function getBurnRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        );

    function getMintRequest(uint256 nonce)
        external
        view
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        );
}
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)





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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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

contract Factory is FactoryInterface, Ownable, Pausable {
    ///======================================================================================================================================
    /// Events
    ///======================================================================================================================================

    event CustodianDepositAddressSet(address indexed merchant, address indexed sender, string depositAddress);

    event MerchantDepositAddressSet(address indexed merchant, string depositAddress);

    event MintRequestAdd(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event MintRequestCancel(uint256 indexed nonce, address indexed requester, bytes32 requestHash);

    event MintConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event MintRejected(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 requestHash
    );

    event Burned(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        uint256 timestamp,
        bytes32 requestHash
    );

    event BurnConfirmed(
        uint256 indexed nonce,
        address indexed requester,
        uint256 amount,
        string depositAddress,
        string txid,
        uint256 timestamp,
        bytes32 inputRequestHash
    );

    ///======================================================================================================================================
    /// Data Structres
    ///======================================================================================================================================

    enum RequestStatus {
        PENDING,
        CANCELED,
        APPROVED,
        REJECTED
    }

    struct Request {
        address requester; // sender of the request.
        uint256 amount; // amount of token to mint/burn.
        string depositAddress; // custodian's asset address in mint, merchant's asset address in burn.
        string txid; // asset txid for sending/redeeming asset in the mint/burn process.
        uint256 nonce; // serial number allocated for each request.
        uint256 timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    ///======================================================================================================================================
    /// State Variables
    ///======================================================================================================================================

    ControllerInterface public controller;

    // mapping between merchant to its per-mint limit.
    mapping(address => uint256) public merchantMintLimit;

    // mapping between merchant to its per-burn limit.
    mapping(address => uint256) public merchantBurnLimit;

    // mapping between merchant to the corresponding custodian deposit address, used in the minting process.
    // by using a different deposit address per merchant the custodian can identify which merchant deposited.
    mapping(address => string) public custodianDepositAddress;

    // mapping between merchant to the its deposit address where the asset should be moved to, used in the burning process.
    mapping(address => string) public merchantDepositAddress;

    // mapping between a mint request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public mintRequestNonce;

    // mapping between a burn request hash and the corresponding request nonce.
    mapping(bytes32 => uint256) public burnRequestNonce;

    Request[] public mintRequests;
    Request[] public burnRequests;

    ///======================================================================================================================================
    /// Constructor
    ///======================================================================================================================================

    constructor(address _controller) {
        controller = ControllerInterface(_controller);
        transferOwnership(address(_controller));
    }

    ///======================================================================================================================================
    /// Modifiers
    ///======================================================================================================================================

    modifier onlyMerchant() {
        require(controller.isMerchant(msg.sender), "sender not a merchant.");
        _;
    }

    modifier onlyCustodian() {
        require(controller.isCustodian(msg.sender), "sender not a custodian.");
        _;
    }

    ///======================================================================================================================================
    /// Setters
    ///======================================================================================================================================

    function setCustodianDepositAddress(address merchant, string memory depositAddress)
        external
        override
        onlyCustodian
        returns (bool)
    {
        require(merchant != address(0), "invalid merchant address");
        require(controller.isMerchant(merchant), "merchant address is not a real merchant.");
        require(!isEmptyString(depositAddress), "invalid asset deposit address");

        custodianDepositAddress[merchant] = depositAddress;
        emit CustodianDepositAddressSet(merchant, msg.sender, depositAddress);
        return true;
    }

    function setMerchantDepositAddress(string memory depositAddress) external override onlyMerchant returns (bool) {
        require(!isEmptyString(depositAddress), "invalid asset deposit address");

        merchantDepositAddress[msg.sender] = depositAddress;
        emit MerchantDepositAddressSet(msg.sender, depositAddress);
        return true;
    }

    function setMerchantMintLimit(address merchant, uint256 amount) external override onlyCustodian returns (bool) {
        merchantMintLimit[merchant] = amount;
        return true;
    }

    function setMerchantBurnLimit(address merchant, uint256 amount) external override onlyCustodian returns (bool) {
        merchantBurnLimit[merchant] = amount;
        return true;
    }

    ///======================================================================================================================================
    /// Merchant Mint Logic
    ///======================================================================================================================================

    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) external override onlyMerchant whenNotPaused returns (bool) {
        require(!isEmptyString(depositAddress), "invalid asset deposit address");
        require(compareStrings(depositAddress, custodianDepositAddress[msg.sender]), "wrong asset deposit address");
        require(amount <= merchantMintLimit[msg.sender], "exceeds mint limit");
        uint256 nonce = mintRequests.length;
        uint256 timestamp = getTimestamp();

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            depositAddress: depositAddress,
            txid: txid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        mintRequestNonce[requestHash] = nonce;
        mintRequests.push(request);

        emit MintRequestAdd(nonce, msg.sender, amount, depositAddress, txid, timestamp, requestHash);
        return true;
    }

    function cancelMintRequest(bytes32 requestHash) external override onlyMerchant whenNotPaused returns (bool) {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        require(msg.sender == request.requester, "cancel sender is different than pending request initiator");
        mintRequests[nonce].status = RequestStatus.CANCELED;

        emit MintRequestCancel(nonce, msg.sender, requestHash);
        return true;
    }

    ///======================================================================================================================================
    /// Custodian Mint Logic
    ///======================================================================================================================================

    function confirmMintRequest(bytes32 requestHash) external override onlyCustodian whenNotPaused returns (bool) {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.APPROVED;
        require(controller.mint(request.requester, request.amount), "mint failed");

        emit MintConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    function rejectMintRequest(bytes32 requestHash) external override onlyCustodian whenNotPaused returns (bool) {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingMintRequest(requestHash);

        mintRequests[nonce].status = RequestStatus.REJECTED;

        emit MintRejected(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            request.txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    ///======================================================================================================================================
    /// Merchant Burn Logic
    ///======================================================================================================================================

    function burn(uint256 amount) external override onlyMerchant whenNotPaused returns (bool) {
        require(amount <= merchantBurnLimit[msg.sender], "exceeds burn limit");
        string memory depositAddress = merchantDepositAddress[msg.sender];
        require(!isEmptyString(depositAddress), "merchant asset deposit address was not set");

        uint256 nonce = burnRequests.length;
        uint256 timestamp = getTimestamp();

        // set txid as empty since it is not known yet.
        string memory txid = "";

        Request memory request = Request({
            requester: msg.sender,
            amount: amount,
            depositAddress: depositAddress,
            txid: txid,
            nonce: nonce,
            timestamp: timestamp,
            status: RequestStatus.PENDING
        });

        bytes32 requestHash = calcRequestHash(request);
        burnRequestNonce[requestHash] = nonce;
        burnRequests.push(request);

        require(controller.burn(msg.sender, amount), "burn failed");

        emit Burned(nonce, msg.sender, amount, depositAddress, timestamp, requestHash);
        return true;
    }

    ///======================================================================================================================================
    /// Custodian Burn Logic
    ///======================================================================================================================================

    function confirmBurnRequest(bytes32 requestHash, string memory txid)
        external
        override
        onlyCustodian
        whenNotPaused
        returns (bool)
    {
        uint256 nonce;
        Request memory request;

        (nonce, request) = getPendingBurnRequest(requestHash);

        burnRequests[nonce].txid = txid;
        burnRequests[nonce].status = RequestStatus.APPROVED;
        burnRequestNonce[calcRequestHash(burnRequests[nonce])] = nonce;

        emit BurnConfirmed(
            request.nonce,
            request.requester,
            request.amount,
            request.depositAddress,
            txid,
            request.timestamp,
            requestHash
        );
        return true;
    }

    ///======================================================================================================================================
    /// Pause Logic
    ///======================================================================================================================================

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    ///======================================================================================================================================
    /// Non Mutable
    ///======================================================================================================================================

    function getBurnRequestsLength() external view override returns (uint256 length) {
        return burnRequests.length;
    }

    // possibly remove
    function getBurnRequest(uint256 nonce)
        external
        view
        override
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request storage request = burnRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    // possibly remove
    function getMintRequest(uint256 nonce)
        external
        view
        override
        returns (
            uint256 requestNonce,
            address requester,
            uint256 amount,
            string memory depositAddress,
            string memory txid,
            uint256 timestamp,
            string memory status,
            bytes32 requestHash
        )
    {
        Request memory request = mintRequests[nonce];
        string memory statusString = getStatusString(request.status);

        requestNonce = request.nonce;
        requester = request.requester;
        amount = request.amount;
        depositAddress = request.depositAddress;
        txid = request.txid;
        timestamp = request.timestamp;
        status = statusString;
        requestHash = calcRequestHash(request);
    }

    function getTimestamp() internal view returns (uint256) {
        // timestamp is only used for data maintaining purpose, it is not relied on for critical logic.
        return block.timestamp; // solhint-disable-line not-rely-on-time
    }

    function getPendingMintRequest(bytes32 requestHash) internal view returns (uint256 nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = mintRequestNonce[requestHash];
        request = mintRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getPendingBurnRequest(bytes32 requestHash) internal view returns (uint256 nonce, Request memory request) {
        require(requestHash != 0, "request hash is 0");
        nonce = burnRequestNonce[requestHash];
        request = burnRequests[nonce];
        validatePendingRequest(request, requestHash);
    }

    function getMintRequestsLength() external view override returns (uint256 length) {
        return mintRequests.length;
    }

    function validatePendingRequest(Request memory request, bytes32 requestHash) internal pure {
        require(request.status == RequestStatus.PENDING, "request is not pending");
        require(requestHash == calcRequestHash(request), "given request hash does not match a pending request");
    }

    function calcRequestHash(Request memory request) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    request.requester,
                    request.amount,
                    request.depositAddress,
                    request.txid,
                    request.nonce,
                    request.timestamp
                )
            );
    }

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
        return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
    }

    function isEmptyString(string memory a) internal pure returns (bool) {
        return (compareStrings(a, ""));
    }

    function getStatusString(RequestStatus status) internal pure returns (string memory) {
        if (status == RequestStatus.PENDING) {
            return "pending";
        } else if (status == RequestStatus.CANCELED) {
            return "canceled";
        } else if (status == RequestStatus.APPROVED) {
            return "approved";
        } else if (status == RequestStatus.REJECTED) {
            return "rejected";
        } else {
            // this fallback can never be reached.
            return "unknown";
        }
    }
}