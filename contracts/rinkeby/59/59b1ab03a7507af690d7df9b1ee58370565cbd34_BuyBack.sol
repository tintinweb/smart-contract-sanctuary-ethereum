// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./lib/Manageable.sol";
import "./lib/Ecrecovery.sol";
import "./lib/Strings.sol";
import "./interfaces/BuyBackInterface.sol";
import "./interfaces/NFTInterface.sol";
import "./interfaces/FTInterface.sol";
import "./interfaces/CofferInterface.sol";

/**
 * @title BuyBack
 * @author lixin
 * @notice BuyBack Processing of guarantor repurchase NFT.
 */
contract BuyBack is BuyBackInterface, Manageable {

    using Strings for uint256;

    using Strings for address;

    uint256 public constant INVERSE_BASIS_POINT = 10000;

    // General coffer contract
    address public coffer;

    // bytes32 id = keccak256(abi.encode(NFTAddr, NFTId));
    // string memory receiptNum = string(abi.encodePacked(address(this).toHexString(), "#", uint256(id).toString()));
    mapping(string => ICoffer.Receipt) private receipts;


    /**
     * @notice Constructor of BuyBack NFT module
     *
     * @param coffer_ General coffer contract contract address
     */
    constructor(address coffer_){
        _setCoffer(coffer_);
    }

    /**
    * @notice set new coffer contract address. Only manager can call this function.
     *
     * @param newCoffer The new coffer contract address.
     */
    function setCoffer(
        address newCoffer
    ) external onlyManager {
        _setCoffer(newCoffer);
    }

    /**
    * @notice set new coffer contract address. internal function, only setCoffer function and constructor call this function.
     *
     * @param newCoffer The new coffer contract address.
     */
    function _setCoffer(
        address newCoffer
    ) internal {
        address oldCoffer = coffer;
        coffer = newCoffer;
        emit CofferChanged(oldCoffer, newCoffer);
    }

    /**
    * @notice Guarantor repurchase user NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr Address of NFT contract to be repurchased.
     * @param NFTId Id of NFT to be repurchased.
     */
    function confirmGuarantor(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata ownerSign,
        bytes calldata managerSign
    ) external returns (bool){

        uint256 deadline = NFTInterface(NFTAddr).checkRepurchaseDeadline();
        if (deadline < _blockTimestamp()) {
            revert RepurchasePeriodExpired();
        }

        require(verify(NFTAddr, NFTId, serviceRatio, ownerSign));

        require(verify(businessId, NFTAddr, NFTId, serviceRatio, managerSign));

        require(_transfer(businessId, NFTAddr, NFTId, serviceRatio));

        return true;
    }

    function verify(
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata ownerSign
    ) internal view returns (bool){
        address NFTOwner = NFTInterface(NFTAddr).ownerOf(NFTId);
        bytes memory message = abi.encode(NFTAddr, NFTId, serviceRatio, NFTOwner);
        bytes32 hash = keccak256(message);
        address owner_ = Ecrecovery.ecrecovery(hash, ownerSign);
        if (owner_ != NFTOwner) {
            revert IllegalNFTOwnerSign();
        }
        return true;
    }

    function verify(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata managerSign
    ) internal view returns (bool){

        bytes memory message = abi.encode(businessId, NFTAddr, NFTId, serviceRatio, _msgSender());
        bytes32 hash = keccak256(message);
        address manager_ = Ecrecovery.ecrecovery(hash, managerSign);
        if (manager_ != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }

    function _transfer(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio
    ) internal returns (bool){
        uint256 deadline = NFTInterface(NFTAddr).checkRepurchaseDeadline();
        if (deadline < _blockTimestamp()) {
            revert RepurchasePeriodExpired();
        }
        (address FTAddr, uint256 FTAmount) = NFTInterface(NFTAddr).checkPrice(NFTId);
        uint256 repurchaseRatio = NFTInterface(NFTAddr).repurchaseRatio();
        uint256 repurchAmount = FTAmount * repurchaseRatio / INVERSE_BASIS_POINT;
        address owner = NFTInterface(NFTAddr).ownerOf(NFTId);
        uint256 serviceFee = FTAmount * serviceRatio / INVERSE_BASIS_POINT;
        uint256 userAmount = repurchAmount - serviceFee;

        NFTInterface(NFTAddr).safeTransferFrom(owner, _msgSender(), NFTId, "0x");
        if (NFTInterface(NFTAddr).ownerOf(NFTId) != _msgSender()) {
            revert NFTTransferFailed();
        }

        bool success = FTInterface(FTAddr).transferFrom(_msgSender(), owner, userAmount);
        if (!success) {
            revert FTTransferFailed();
        }

        require(_transferCoffer(_msgSender(), NFTAddr, NFTId, FTAddr, serviceFee));


        emit GuarantorBuyBack(businessId, NFTAddr, NFTId, FTAddr, userAmount, serviceFee);

        return true;
    }


    function _transferCoffer(
        address FTFrom,
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 serviceFee
    ) internal returns (bool){
        bool success = FTInterface(FTAddr).transferFrom(FTFrom, coffer, serviceFee);
        if (!success) {
            revert FTTransferFailed();
        }

        bytes32 id = keccak256(abi.encode(NFTAddr, NFTId));
        string memory receiptNum = string(abi.encodePacked(address(this).toHexString(), "#", uint256(id).toString()));

        ICoffer.Receipt storage receipt;
        receipt = receipts[receiptNum];
        receipt.receiptNum = receiptNum;
        receipt.operator = _msgSender();
        receipt.NFTAddr = address(this);
        receipt.NFTId = uint256(id);
        receipt.tokenAddr = FTAddr;
        receipt.tokenAmount = serviceFee;
        receipt.timestamp = block.timestamp;

        success = ICoffer(coffer).sendReceipt(receipt);
        if (!success) {
            revert CofferCallFailed();
        }

        return true;
    }


    /**
    * @notice Guarantor repurchase user NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr Address of NFT contract to be repurchased.
     * @param NFTId Id of NFT to be repurchased.
     * @param calldatas Manager's signature on and call parameters.
     */
    function confirmProject(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata calldatas,
        bytes calldata ownerSign,
        bytes calldata managerSign
    ) external returns (bool){

        uint256 deadline = NFTInterface(NFTAddr).checkRepurchaseDeadline();
        if (deadline < _blockTimestamp()) {
            revert RepurchasePeriodExpired();
        }

        require(verify(NFTAddr, NFTId, serviceRatio, ownerSign));

        require(verify(businessId, NFTAddr, NFTId, serviceRatio, calldatas, managerSign));

        require(_confirmProject(businessId, NFTAddr, NFTId, serviceRatio, calldatas));

        return true;
    }

    function verify(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata calldatas,
        bytes calldata managerSign
    ) internal view returns (bool){
        bytes memory message = abi.encode(businessId, NFTAddr, NFTId, serviceRatio, calldatas, _msgSender());
        bytes32 hash = keccak256(message);
        address manager_ = Ecrecovery.ecrecovery(hash, managerSign);
        if (manager_ != manager()) {
            revert IllegalManagerSign();
        }
        return true;
    }

    function _confirmProject(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata calldatas
    ) internal returns (bool){
        (address FTAddr, uint256 FTAmount) = NFTInterface(NFTAddr).checkPrice(NFTId);
        uint256 repurchaseRatio = NFTInterface(NFTAddr).repurchaseRatio();
        uint256 repurchAmount = FTAmount * repurchaseRatio / INVERSE_BASIS_POINT;
        uint256 serviceFee = FTAmount * serviceRatio / INVERSE_BASIS_POINT;
        uint256 userAmount = repurchAmount - serviceFee;

        require(_transfer(NFTAddr, NFTId, FTAddr, serviceFee, userAmount, calldatas));

        emit ProjectBuyBack(businessId, NFTAddr, NFTId, FTAddr, userAmount, serviceFee);
        return true;
    }

    function _transfer(
        address NFTAddr,
        uint256 NFTId,
        address FTAddr,
        uint256 serviceFee,
        uint256 userAmount,
        bytes calldata calldatas
    ) internal returns (bool){
        address NFTOwner = NFTInterface(NFTAddr).ownerOf(NFTId);

        uint256 oldBalance = FTInterface(FTAddr).balanceOf(address(this));
        (bool success,) = coffer.call(calldatas);
        if (!success) {
            revert CofferCallFailed();
        }
        uint256 newBalance = FTInterface(FTAddr).balanceOf(address(this));
        if (oldBalance + serviceFee + userAmount > newBalance) {
            revert FTTransferFailed();
        }

        NFTInterface(NFTAddr).safeTransferFrom(NFTOwner, _msgSender(), NFTId, "0x");
        if (NFTInterface(NFTAddr).ownerOf(NFTId) != _msgSender()) {
            revert NFTTransferFailed();
        }

        success = FTInterface(FTAddr).transferFrom(address(this), NFTOwner, userAmount);
        if (!success) {
            revert FTTransferFailed();
        }

        require(_transferCoffer(address(this), NFTAddr, NFTId, FTAddr, serviceFee));

        return true;
    }

    function checkReceipt(string memory receiptNum_)
    public
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    ){
        ICoffer.Receipt memory receipt = receipts[receiptNum_];
        receiptNum = receipt.receiptNum;
        operator = receipt.operator;
        NFTAddr = receipt.NFTAddr;
        NFTId = receipt.NFTId;
        tokenAddr = receipt.tokenAddr;
        tokenAmount = receipt.tokenAmount;
        serviceFee = receipt.serviceFee;
        timestamp = receipt.timestamp;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface CofferStructs {
    struct Receipt {
        string receiptNum;
        address operator;
        address NFTAddr;
        uint256 NFTId;
        address tokenAddr;
        uint256 tokenAmount;
        uint256 serviceFee;
        uint256 timestamp;
    }

}

interface ICoffer is CofferStructs {

    function sendReceipt(
        Receipt calldata receipt
    ) external returns (bool);

    function userWithdraw(
        string memory businessId,
        address payable payee,
        address tokenAddr,
        uint256 amount,
        bytes memory sign
    ) external returns (bool);


    function checkReceipt(string memory receiptNum_)
    external
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 slipPoint,
        uint256 timestamp
    );


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface FTInterface {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface NFTInterface {
    function loanRatio() external view returns (uint256 loanRatio);

    function repurchaseRatio() external view returns (uint256 repurchaseRatio);

    function checkRepurchaseDeadline() external view returns (uint256 deadline);

    function checkPrice(uint256 tokenId) external view returns (address tokenAddr, uint256 tokenAmount);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title BuyBackInterface
 * @author lixin
 * @notice BuyBackInterface contains all external function interfaces, events,
 *         and errors for BuyBack contracts.
 */

interface BuyBackInterface{

    /**
     * @dev Emit an event when coffer contract address changed.
     *
     * @param oldCoffer The old coffer contract address.
     * @param newCoffer The new coffer contract address.
     */
    event CofferChanged(address oldCoffer, address newCoffer);

    event GuarantorBuyBack(string businessId, address NFTAddr, uint256 NFTId, address FTAddr, uint256 userAmount, uint256 serviceFee);
     
    event ProjectBuyBack(string businessId, address NFTAddr, uint256 NFTId, address FTAddr, uint256 userAmount, uint256 serviceFee);

    error NFTTransferFailed();

    error FTTransferFailed();

    error IllegalManagerSign();

    error IllegalNFTOwnerSign();

    error CofferCallFailed();

    error RepurchasePeriodExpired();



    /**
     * @notice set new coffer contract address. Only manager can call this function.
     *
     * @param newCoffer The new coffer contract address.
     */
    function setCoffer(
        address newCoffer
    ) external;

    /**
    * @notice Guarantor repurchase user NFT.
     *
     * @param businessId Used as business differentiation.
     * @param NFTAddr Address of NFT contract to be repurchased.
     * @param NFTId Id of NFT to be repurchased.
     */
    function confirmGuarantor(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata ownerSign,
        bytes calldata managerSign
    ) external returns(bool);

    function confirmProject(
        string calldata businessId,
        address NFTAddr,
        uint256 NFTId,
        uint256 serviceRatio,
        bytes calldata calldatas,
        bytes calldata ownerSign,
        bytes calldata managerSign
    ) external returns(bool);

    function checkReceipt(string memory receiptNum_)
    external
    view
    returns (
        string memory receiptNum,
        address operator,
        address NFTAddr,
        uint256 NFTId,
        address tokenAddr,
        uint256 tokenAmount,
        uint256 serviceFee,
        uint256 timestamp
    );

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
pragma solidity ^0.8.0;

library Ecrecovery{

function ecrecovery(
        bytes32 hash,
        bytes memory sig
    )
    internal
    pure
    returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        if (sig.length != 65) {
            return address(0);
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := and(mload(add(sig, 65)), 255)
        }

        // https://github.com/ethereum/go-ethereum/issues/2053
        if (v < 27) {
            v += 27;
        }

        if (v != 27 && v != 28) {
            return address(0);
        }

        /* prefix might be needed for geth only
        * https://github.com/ethereum/go-ethereum/issues/3731
        */
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";

        bytes32 Hash = keccak256(abi.encodePacked(prefix, hash));

        return ecrecover(Hash, v, r, s);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Ownable.sol";

abstract contract Manageable is Ownable {
    address private _manager;

    event ManagershipTransferred(address indexed previousManager, address indexed newManager);

    /**
     * @dev Initializes the contract setting the deployer as the initial manager.
     */
    constructor() {
        _transferManagership(_txOrigin());
    }

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        _checkManager();
        _;
    }

    /**
     * @dev Returns the address of the current manager.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @dev Throws if the sender is not the manager.
     */
    function _checkManager() internal view virtual {
        require(manager() == _txOrigin(), "Managerable: caller is not the manager");
    }

    /**
     * @dev Transfers managership of the contract to a new account (`newManager`).
     * Can only be called by the current owner.
     */
    function transferManagership(address newManager) public virtual onlyOwner {
        require(newManager != address(0), "Managerable: new manager is the zero address");
        _transferManagership(newManager);
    }

    /**
     * @dev Transfers Managership of the contract to a new account (`newManager`).
     * Internal function without access restriction.
     */
    function _transferManagership(address newManager) internal virtual {
        address oldManager = _manager;
        _manager = newManager;
        emit ManagershipTransferred(oldManager, newManager);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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
        _transferOwnership(_txOrigin());
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

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _txOrigin() internal view virtual returns (address) {
        return tx.origin;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }

    function _blockTimestamp() internal view virtual returns (uint256) {
        return block.timestamp;
    }

}