// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/CapitalPoolInterface.sol";
import "../interfaces/NFTInterface.sol";
import "../interfaces/FTInterface.sol";
import "./Manageable.sol";
import "./ReentrancyGuard.sol";

/**
 * @title CapitalPool
 * @author lixin
 * @notice CapitalPool Handle reception and transfer of NFT and FT.
 */

contract CapitalPool is CapitalPoolInterface, Manageable, ReentrancyGuard {
    //the loan pledge address
    address public pledge;
    //the loan contract address
    address public loan;

    mapping(address => uint256) public balanceOf;

    mapping(string => bool) businessBook;

    /**
     * @dev Throws if called by any account other than the loan.
     */
    modifier onlyLoan() {
        require(msg.sender == loan, "caller not the loan contract");
        _;
    }

    /**
     * @dev Throws if called by any account other than the pledge.
     */
    modifier onlyPledge() {
        require(msg.sender == pledge, "caller not the pledge contract");
        _;
    }

    /**
     * @notice Constructor CapitalPool
     *
     */
    constructor() {
        // setLoan(newLoan);
        // setPledge(newPledge);
    }

    function setPledge(address newPledge) public onlyManager {
        address oldPledge = pledge;
        pledge = newPledge;
        emit PledgeChanged(oldPledge, newPledge);
    }

    function setLoan(address newLoan) public onlyManager {
        address oldLoan = loan;
        loan = newLoan;
        emit LoanChanged(oldLoan, newLoan);
    }

    /**
     * @notice receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function depositFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    ) external nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        uint256 oldBalance = balanceOf[tokenAddr];
        uint256 newBalance = FTInterface(tokenAddr).balanceOf(address(this));
        if (oldBalance + tokenAmount > newBalance) {
            revert NoFTReceived();
        }
        balanceOf[tokenAddr] = newBalance;
        emit ReceiveFT(businessId, tokenAddr, tokenAmount);
        return true;
    }

    /**
     * @notice Only loan contract can withdraw a FT.Only the loan contract can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    ) external onlyLoan nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        require(FTInterface(tokenAddr).transfer(recipient, tokenAmount));
        balanceOf[tokenAddr] = FTInterface(tokenAddr).balanceOf(address(this));
        emit WithdrawFT(businessId, tokenAddr, tokenAmount, recipient);
        return true;
    }

    /**
     * @notice Only pledge can withdraw a NFT. Only the pledge contract can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    ) external onlyPledge nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        NFTInterface(tokenAddr).safeTransferFrom(address(this), recipient, tokenId, "0x");
        emit WithdrawNFT(businessId, tokenAddr, tokenId, recipient);
        return true;
    }

    /**
    * @notice Only manager can withdraw a FT. Only the manager can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive NFT.
     */
    function withdrawFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    ) external onlyManager onlyLoan nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        require(FTInterface(tokenAddr).transfer(recipient, tokenAmount));
        balanceOf[tokenAddr] = FTInterface(tokenAddr).balanceOf(address(this));
        emit WithdrawFT(businessId, tokenAddr, tokenAmount, recipient);
        return true;
    }

    /**
     * @notice Only manager withdraw a NFT. Only the manager can call this function.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive NFT.
     */
    function withdrawNFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    ) external onlyManager onlyPledge nonReentrant returns (bool){
        if(businessBook[businessId]){
            revert BusinessIdUsed();
        }
        NFTInterface(tokenAddr).safeTransferFrom(address(this), recipient, tokenId, "0x");
        emit WithdrawNFT(businessId, tokenAddr, tokenId, recipient);
        return true;
    }

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * IERC721Receiver.onERC721Received.selector == 0x150b7a02;
     */
    function onERC721Received(
        address,
        address,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        if(businessBook[string(data)]){
            revert BusinessIdUsed();
        }
        emit ReceiveNFT(string(data), _msgSender(), tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

    error ReentrantCall();

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _notEntered will be true
        //require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        if(_status == _ENTERED){
            revert ReentrantCall();
        }

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
pragma solidity ^0.8.0;


interface FTInterface {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface NFTInterface {
    function loanRatio() external returns (uint256 loanRatio);

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
import "./IERC721Receiver.sol";

/**
 * @title CapitalPoolInterface
 * @author lixin
 * @notice CapitalPoolInterface contains all external function interfaces, events,
 *         and errors for CapitalPool contracts.
 */

interface CapitalPoolInterface is IERC721Receiver {

    /**
     * @dev Emit an event when receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    event ReceiveFT(string businessId, address tokenAddr, uint256 tokenAmount);

    /**
     * @dev Emit an event when Withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    event WithdrawFT(string businessId, address tokenAddr, uint256 tokenAmount, address recipient);

    /**
     * @dev Emit an event when receive a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     */
    event ReceiveNFT(string businessId, address tokenAddr, uint256 tokenId);

    /**
     * @dev Emit an event when Withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive NFT.
     */
    event WithdrawNFT(string businessId, address tokenAddr, uint256 tokenId, address recipient);

    /**
     * @dev Emit an event when pledge contract changed.
     *
     * @param oldPledge The old pledge contract address.
     * @param newPledge The new pledge contract address.
     */
    event PledgeChanged(address oldPledge, address newPledge);

    /**
     * @dev Emit an event when pledge loan changed.
     *
     * @param oldLoan The old loan contract address.
     * @param newLoan The new loan contract address.
     */
    event LoanChanged(address oldLoan, address newLoan);

    error NoFTReceived();

    error BusinessIdUsed();

    /**
     * @dev Revert with an error when run failed.
     */
    error failed();

    /**
     * @notice receive a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     */
    function depositFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount
    )external returns (bool);

    /**
     * @notice Only loan contract can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    )external returns (bool);

    /**
     * @notice Only manager can withdraw a FT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC20 contract address.
     * @param tokenAmount The amount of ERC20 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenAmount,
        address recipient
    )external returns (bool);

    // /**
    //  * @notice receive a NFT.
    //  *
    //  * @param businessId Used as business differentiation.
    //  * @param tokenAddr The ERC721 contract address.
    //  * @param tokenId The id of ERC721 tokens.
    //  */
    // function depositNFT(
    //     string calldata businessId,
    //     address tokenAddr,
    //     uint256 tokenId
    // )external returns (bool);

    /**
     * @notice Only pledge can withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive FT.
     */
    function withdrawNFT(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    )external returns (bool);

    /**
     * @notice Only manager withdraw a NFT.
     *
     * @param businessId Used as business differentiation.
     * @param tokenAddr The ERC721 contract address.
     * @param tokenId The id of ERC721 tokens.
     * @param recipient The Address to receive NFT.
     */
    function withdrawNFTManager(
        string calldata businessId,
        address tokenAddr,
        uint256 tokenId,
        address recipient
    )external returns (bool);
    
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
        require(owner() == _txOrigin(), "Ownable: caller is not the owner");
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