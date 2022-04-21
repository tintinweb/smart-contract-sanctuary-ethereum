pragma solidity ^0.5.0;

import "ManualApproval.sol";
import "Whitelisted.sol";

import "Ownable.sol";

//import "Ownable.sol";
import "ITransferRules.sol";
import "ITransferRestrictions.sol";

/*
 * @title TransferRules contract
 * @dev Contract that is checking if on-chain rules for token transfers are concluded.
 * It implements whitelist and grey list.
 */
contract TransferRules is ITransferRules, ManualApproval, Whitelisted {

    modifier onlySRC20 {
        require(msg.sender == address(_src20));
        _;
    }

    constructor(address owner) public {
        _transferOwnership(owner);
        _whitelisted[owner] = true;
    }

    /**
    * @dev Set for what contract this rules are.
    *
    * @param src20 - Address of SRC20 contract.
    */
    function setSRC(address src20) external returns (bool) {
        require(address(_src20) == address(0), "SRC20 already set");
        _src20 = ISRC20(src20);
        return true;
    }

    /**
    * @dev Checks if transfer passes transfer rules.
    *
    * @param from The address to transfer from.
    * @param to The address to send tokens to.
    * @param value The amount of tokens to send.
    */
    function authorize(address from, address to, uint256 value) public view returns (bool) {
        uint256 v; v = value; // eliminate compiler warning
        return (isWhitelisted(from) || isGreyListed(from)) &&
        (isWhitelisted(to) || isGreyListed(to));
    }

    /**
    * @dev Do transfer and checks where funds should go. If both from and to are
    * on the whitelist funds should be transferred but if one of them are on the
    * grey list token-issuer/owner need to approve transfer.
    *
    * @param from The address to transfer from.
    * @param to The address to send tokens to.
    * @param value The amount of tokens to send.
    */
    function doTransfer(address from, address to, uint256 value) external onlySRC20 returns (bool) {
        require(authorize(from, to, value), "Transfer not authorized");

        if (isGreyListed(from) || isGreyListed(to)) {
            _transferRequest(from, to, value);
            return true;
        }

        require(ISRC20(_src20).executeTransfer(from, to, value), "SRC20 transfer failed");

        return true;
    }
}

pragma solidity ^0.5.0;

import "ITransferRules.sol";
import "ISRC20.sol";

import "Ownable.sol";
//import "Ownable.sol";

/*
 * @title ManualApproval contract
 * @dev On-chain transfer rule that is handling transfer request/execution for
 * grey-listed account
 */
contract ManualApproval is Ownable {
    struct TransferReq {
        address from;
        address to;
        uint256 value;
    }

    uint256 public _reqNumber;
    ISRC20 public _src20;

    mapping(uint256 => TransferReq) public _transferReq;
    mapping(address => bool) public _greyList;

    event TransferRequest(
        uint256 indexed requestNumber,
        address from,
        address to,
        uint256 value
    );

    event TransferApproval(
        uint256 indexed requestNumber,
        address indexed from,
        address indexed to,
        uint256 value
    );

    event TransferRequestCanceled(
        uint256 indexed requestNumber,
        address indexed from,
        address indexed to,
        uint256 value
    );

    constructor () public {
    }

    /**
     * @dev Owner of this contract have authority to approve tx which are valid.
     *
     * @param reqNumber - transfer request number.
     */
    function transferApproval(uint256 reqNumber) external onlyOwner returns (bool) {
        TransferReq memory req = _transferReq[reqNumber];

        require(_src20.executeTransfer(address(this), req.to, req.value), "SRC20 transfer failed");

        delete _transferReq[reqNumber];
        emit TransferApproval(reqNumber, req.from, req.to, req.value);
        return true;
    }

    /**
     * @dev Canceling transfer request and returning funds to from.
     *
     * @param reqNumber - transfer request number.
     */
    function cancelTransferRequest(uint256 reqNumber) external returns (bool) {
        TransferReq memory req = _transferReq[reqNumber];
        require(req.from == msg.sender, "Not owner of the transfer request");

        require(_src20.executeTransfer(address(this), req.from, req.value), "SRC20: External transfer failed");

        delete _transferReq[reqNumber];
        emit TransferRequestCanceled(reqNumber, req.from, req.to, req.value);

        return true;
    }

    // Handling grey listing
    function isGreyListed(address account) public view returns (bool){
        return _greyList[account];
    }

    function greyListAccount(address account) external onlyOwner returns (bool) {
        _greyList[account] = true;
        return true;
    }

    function bulkGreyListAccount(address[] calldata accounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            _greyList[account] = true;
        }
        return true;
    }

    function unGreyListAccount(address account) external onlyOwner returns (bool) {
        delete _greyList[account];
        return true;
    }

    function bulkUnGreyListAccount(address[] calldata accounts) external onlyOwner returns (bool) {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            delete _greyList[account];
        }
        return true;
    }

    function _transferRequest(address from, address to, uint256 value) internal returns (bool) {
        require(_src20.executeTransfer(from, address(this), value), "SRC20 transfer failed");

        _transferReq[_reqNumber] = TransferReq(from, to, value);

        emit TransferRequest(_reqNumber, from, to, value);
        _reqNumber = _reqNumber + 1;

        return true;
    }
}

pragma solidity ^0.5.0;

/**
 * @title ITransferRules interface
 * @dev Represents interface for any on-chain SRC20 transfer rules
 * implementation. Transfer Rules are expected to follow
 * same interface, managing multiply transfer rule implementations with
 * capabilities of managing what happens with tokens.
 *
 * This interface is working with ERC20 transfer() function
 */
interface ITransferRules {
    function setSRC(address src20) external returns (bool);
    function doTransfer(address from, address to, uint256 value) external returns (bool);
}

pragma solidity ^0.5.0;

/**
 * @title SRC20 public interface
 */
interface ISRC20 {

    event RestrictionsAndRulesUpdated(address restrictions, address rules);

    function transferToken(address to, uint256 value, uint256 nonce, uint256 expirationTime,
        bytes32 msgHash, bytes calldata signature) external returns (bool);
    function transferTokenFrom(address from, address to, uint256 value, uint256 nonce,
        uint256 expirationTime, bytes32 hash, bytes calldata signature) external returns (bool);
    function getTransferNonce() external view returns (uint256);
    function getTransferNonce(address account) external view returns (uint256);
    function executeTransfer(address from, address to, uint256 value) external returns (bool);
    function updateRestrictionsAndRules(address restrictions, address rules) external returns (bool);

    // ERC20 part-like interface
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 value) external returns (bool);
    function transfer(address to, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function increaseAllowance(address spender, uint256 value) external returns (bool);
    function decreaseAllowance(address spender, uint256 value) external returns (bool);

    function fundRaiserAddr() external returns (address);
}

pragma solidity ^0.5.0;

import "Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

pragma solidity ^0.5.0;

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
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

pragma solidity ^0.5.0;

import "Ownable.sol";

//import "Ownable.sol";
import "ISRC20.sol";

/**
 * @title Whitelisted transfer restriction example
 * @dev Example of simple transfer rule, having a list
 * of whitelisted addresses manged by owner, and checking
 * that from and to address in src20 transfer are whitelisted.
 */
contract Whitelisted is Ownable {
    mapping (address => bool) public _whitelisted;

    function whitelistAccount(address account) external onlyOwner {
        _whitelisted[account] = true;
    }

    function bulkWhitelistAccount(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            _whitelisted[account] = true;
        }
    }

    function unWhitelistAccount(address account) external onlyOwner {
         delete _whitelisted[account];
    }

    function bulkUnWhitelistAccount(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length ; i++) {
            address account = accounts[i];
            delete _whitelisted[account];
        }
    }

    function isWhitelisted(address account) public view returns (bool) {
        return _whitelisted[account];
    }
}

pragma solidity ^0.5.0;

/**
 * @title ITransferRestrictions interface
 * @dev Represents interface for any on-chain SRC20 transfer restriction
 * implementation. Transfer Restriction registries are expected to follow
 * same interface, managing multiply transfer restriction implementations.
 *
 * It is intended to implementation of this interface be used for transferToken()
 */
interface ITransferRestrictions {
    function authorize(address from, address to, uint256 value) external returns (bool);
}