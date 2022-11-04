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
pragma solidity 0.8.7;

interface FactoryInterface {
    event IssuerDepositAddressSet(address indexed merchant, address indexed sender, string depositAddress);

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

    ///=============================================================================================
    /// Data Structres
    ///=============================================================================================

    enum RequestStatus {
        NULL,
        PENDING,
        CANCELED,
        APPROVED,
        REJECTED
    }

    struct Request {
        address requester; // sender of the request.
        uint256 amount; // amount of token to mint/burn.
        string depositAddress; // issuer's asset address in mint, merchant's asset address in burn.
        string txid; // asset txid for sending/redeeming asset in the mint/burn process.
        uint256 nonce; // serial number allocated for each request.
        uint256 timestamp; // time of the request creation.
        RequestStatus status; // status of the request.
    }

    function pause() external;

    function unpause() external;

    function setIssuerDepositAddress(address merchant, string memory depositAddress) external returns (bool);

    function setMerchantDepositAddress(string memory depositAddress) external returns (bool);

    function setMerchantMintLimit(address merchant, uint256 amount) external returns (bool);

    function setMerchantBurnLimit(address merchant, uint256 amount) external returns (bool);

    function addMintRequest(
        uint256 amount,
        string memory txid,
        string memory depositAddress
    ) external returns (uint256);

    function cancelMintRequest(bytes32 requestHash) external returns (bool);

    function confirmMintRequest(bytes32 requestHash) external returns (bool);

    function rejectMintRequest(bytes32 requestHash) external returns (bool);

    function burn(uint256 amount, string memory txid) external returns (bool);

    function confirmBurnRequest(bytes32 requestHash) external returns (bool);

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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../factory/FactoryInterface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract UserRedemption is Ownable {
    event UserBurn(address indexed who, uint256 indexed amount, uint256 indexed nonce);

    event Finalize(address indexed who, uint256 indexed amount, bool indexed completed);

    struct Req {
        uint256 amount;
        address requester;
        string _ipfsHash;
        bool completed;
    }

    FactoryInterface public immutable factory;
    IERC20 public immutable token;
    address public signer;
    address public approver;
    address public feeReceiver;
    uint256 public fee;
    mapping(bytes32 => bool) public used;
    mapping(address => uint256) public user_req_nonce;
    Req[] public req;

    string public constant version = "0";
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version)");
    bytes32 public constant WHITELIST_TYPEHASH = keccak256("Whitelist(address addr,uint256 amount,uint256 nonce)");

    modifier only(address who) {
        require(msg.sender == who, "incorrect permissions");
        _;
    }

    constructor(
        address _approver,
        address _signer,
        address _factory,
        address _token,
        address _feeReceiver,
        uint256 _fee
    ) {
        approver = _approver;
        signer = _signer;
        factory = FactoryInterface(_factory);
        token = IERC20(_token);
        feeReceiver = _feeReceiver;
        fee = _fee;
    }

    function burn(
        uint256 amount,
        string calldata ipfsHash,
        bytes calldata signature
    ) external {
        require(amount >= fee, "invalid amount");

        bytes32 _hash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(abi.encode(WHITELIST_TYPEHASH, msg.sender, amount, user_req_nonce[msg.sender]))
            )
        );

        require(signer == recoverSigner(_hash, signature), "invalid signer");

        user_req_nonce[msg.sender]++;

        req.push(Req({amount: amount, requester: msg.sender, completed: false, _ipfsHash: ipfsHash}));

        token.transferFrom(msg.sender, address(this), amount);

        emit UserBurn(msg.sender, amount, req.length - 1);
    }

    function finalizeBurn(uint256 nonce, bool completed) external only(approver) {
        Req memory _req = req[nonce];

        require(!_req.completed, "Nonce Already Used");

        if (completed) {
            req[nonce].completed = true;

            token.approve(address(factory), _req.amount);

            factory.burn(_req.amount - fee, _req._ipfsHash);

            token.transfer(feeReceiver, fee);
        } else {
            req[nonce].completed = true;

            token.transfer(_req.requester, _req.amount);
        }

        emit Finalize(msg.sender, _req.amount, completed);
    }

    function changeApprover(address _approver) external onlyOwner {
        approver = _approver;
    }

    function changeSigner(address _signer) external onlyOwner {
        signer = _signer;
    }

    function changeFeeReciever(address _receiver) external onlyOwner {
        feeReceiver = _receiver;
    }

    function changeFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function recoverSigner(bytes32 messageHash, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }

        return ecrecover(messageHash, v, r, s);
    }

    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256("User Redemption Contract"), keccak256(bytes(version))));
    }
}