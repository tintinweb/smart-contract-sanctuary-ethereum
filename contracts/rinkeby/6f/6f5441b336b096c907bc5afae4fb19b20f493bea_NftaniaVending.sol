// SPDX-License-Identifier: MIT

pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NftaniaVending is Pausable, Ownable, ReentrancyGuard {

    address payable public wallet;  
    address contractOwner;// = owner(); 
    // address private owner;   
    IERC20 public token;
    IERC1155 public eggs; 
    IERC1155 public nftanians; 

    uint256 public orderId;
    uint256 private maxEggs = 100; 
    uint256 private maxHeroes = 10; 
    uint256 private maxChamps = 50; 

    uint256 private heroPrice = 100000;
    uint256 private champPrice = 250000;
    uint256 private eggPrice = 750000;

    uint256 private heroesId = 0;
    uint256 private champsId = 1;
    uint256 private eggsId = 0;

    uint256 private heroesBalance;
    uint256 private champsBalance;
    uint256 private eggsBalance;

    mapping ( address => uint256) public walletEggs;
    mapping ( address => uint256) public walletHeroes;
    mapping ( address => uint256) public walletChamps;

    event NftanianOrder (address indexed buyer, uint256 tokensAmount, uint256 indexed _orderId, uint256 _heroAmount, uint256 _champAmount, uint indexed date);
    event EggOrder (address indexed buyer, uint256 tokensAmount, uint256 indexed _orderId, uint256 _eggAmount, uint indexed date);
    event NftanianBalance (uint256 _heroesBalance, uint256 _champsBalance, uint indexed date);
    event EggsBalance (uint256 eggsBalance, uint indexed date);
    event ContractIsPaused (bool status);
    event Balances (uint256 EggsBalance,uint256 heroesBalance,uint256 champsBalance, uint indexed date);

    constructor (
        // address payable _wallet,         
        // address tokenAddress, 
        // address EggsAddress, 
        // address nftaniansAddress,
        // uint256 _heroesId, 
        // uint256 _champsId, 
        // uint256 _eggsId,
        // uint256 _maxEggs, 
        // uint256 _maxHeroes, 
        // uint256 _maxChamps
        ) {

        // wallet = _wallet;
        // token = IERC20(tokenAddress);
        // eggs = IERC1155(EggsAddress);
        // nftanians = IERC1155(nftaniansAddress);
        // wallet = _wallet; 
        contractOwner = msg.sender;
        wallet = payable(0xf57D028fFC876E021510102d00DF116f46eDbcE7); // recieving wallet
        // address public constant ADDR_DAO = 0x06bB1467b38d726b3eb39eB2FBAE6021feAE935F;
        token = IERC20(0xe282AFD61Df95BdD9B07111Ae30F3D90DD682C87); //tokenAddress
        eggs = IERC1155(0xb90fb8a9c38275dE5765Cf3089901bb7621dAb12); //EggsAddress
        nftanians = IERC1155(0xf98C579aEA0F221C990BeC8f532F19B73Ca62a70); //nftaniansAddress
        // heroesId = _heroesId;
        // champsId = _champsId;
        // eggsId = _eggsId;  
                // heroesId = 0;
                // champsId = 1;
                // eggsId = 0;     
                // maxEggs = 100;
                // maxHeroes = 10; 
                // maxChamps = 50;
        // setMaxes ( _maxEggs, _maxHeroes, _maxChamps);
        getBalances();
        // eggPrice = 100000; 
        // heroPrice = 750000;
        // champPrice = 250000;
    }

    function setPrices (uint256 _eggPrice, uint256 _heroPrice, uint256 _champPrice) public onlyOwner {
        eggPrice = _eggPrice; 
        heroPrice = _heroPrice;
        champPrice = _champPrice;
    }

    function getPrices () public view returns (string memory, uint256 _eggPrice,uint256 _heroPrice,uint256 _champPrice) {
        return ("Egg Price, Hero Price,Champ Price",eggPrice, heroPrice, champPrice);
    }

    function getBalances() public returns(string memory,uint256 _eggsBalance,uint256 _heroesBalance,uint256 _champsBalance) {
        eggsBalance = eggs.balanceOf(contractOwner, eggsId);
        heroesBalance = nftanians.balanceOf(contractOwner, heroesId);
        champsBalance = nftanians.balanceOf(contractOwner, champsId);
        emit Balances ( eggsBalance, heroesBalance, champsBalance, block.timestamp); 
        return ("Eggs Balance, Heroes Balance,Champs Balance", eggsBalance, heroesBalance, champsBalance);
    }

    function setMaxes (uint _maxEggs, uint256 _maxHeroes, uint256 _maxChamps) public onlyOwner {
        maxEggs = _maxEggs;
        maxHeroes = _maxHeroes; 
        maxChamps = _maxChamps;
    }

    function getMaxes () public view returns (string memory, uint _maxEggs, uint256 _maxHeroes, uint256 _maxChamps) {
        return ("max Eggs, max Heroes, max Champs",maxEggs, maxHeroes, maxChamps);
    }


   //////////////////////// Fallback //////////////////////////////////////   
    receive() external payable { }

   //////////////////////// Order Nftanians /////////////////////   
    function orderNftanians (uint256 tokensAmount, uint256 heroesAmount, uint256 champsAmount) public whenNotPaused() nonReentrant() {
        require (heroPrice > 0 && champPrice > 0, "price is not set yet" );
        require (tokensAmount >= champPrice,"Tokens amount below minimum");
        require (heroesAmount <= heroesBalance,"requested hero amount is more than remaining heroes");
        require (champsAmount <= champsBalance,"requested champ amount is more than remaining champs");
        uint256 orderValue = heroesAmount * heroPrice + champsAmount * champPrice;
        require (tokensAmount ==  orderValue,"NFT2 tokens is not equal to the total order price");
        require (heroesAmount+walletHeroes[msg.sender] <= maxHeroes,"This Wallet Reached the max qouta for purchased Heroes");
        require (champsAmount+walletChamps[msg.sender] <= maxChamps,"This Wallet Reached the max qouta for purchased Champs");
        orderId += 1;
        token.transferFrom(msg.sender, wallet, tokensAmount);
        // nftanians.safeBatchTransferFrom(contractOwner, msg.sender, [heroesId,champsId], [heroesAmount,champsAmount], ""); //======================= Why not working?
        nftanians.safeTransferFrom(contractOwner, msg.sender, heroesId, heroesAmount, "");
        nftanians.safeTransferFrom(contractOwner, msg.sender, champsId, champsAmount, "");
        walletHeroes[msg.sender] += heroesAmount; 
        walletChamps[msg.sender] += champsAmount;   
        heroesBalance = nftanians.balanceOf(contractOwner, heroesId); // =======================how to get balance of batch?
        champsBalance = nftanians.balanceOf(contractOwner, champsId);   
        emit NftanianOrder(msg.sender, tokensAmount, orderId, heroesAmount, champsAmount, block.timestamp);
        emit NftanianBalance (heroesBalance, champsBalance, block.timestamp);
    }

   //////////////////////// Order Eggs ///////////////////// 
    function orderEggs (uint256 tokensAmount, uint256 eggsAmount)  public whenNotPaused() nonReentrant() {
        require (eggPrice > 0, "price is not set yet" );
        require (tokensAmount >= eggPrice,"Tokens amount below minimum");
        require (eggsBalance != 0,"All Egg supply is alreay minted");
        require (eggsAmount <= eggsBalance,"requested amount is more than remaining eggs");
        uint256 orderValue = eggsAmount * eggPrice;
        require (tokensAmount == orderValue,"NFT2 tokens is not equal to the total order price");
        require (eggsAmount+walletEggs[msg.sender] <= maxEggs,"This Wallet Reached the max qouta for purchased Eggs");
        orderId += 1;
        token.transferFrom(msg.sender, wallet, tokensAmount);
        eggs.safeTransferFrom(contractOwner, msg.sender, eggsId, eggsAmount, "");
        walletEggs[msg.sender] += eggsAmount; 
        eggsBalance = eggs.balanceOf(contractOwner, eggsId);
        emit EggOrder(msg.sender, tokensAmount, orderId, eggsAmount, block.timestamp);
        emit EggsBalance (eggsBalance, block.timestamp);
    }

   //////////////////////// Get eth Balance //////////////////////// 
    function getEthBalance () external view returns (uint _balance) {
        return address (this).balance;
    }

   //////////////////////// Withdraw Funds ////////////////////////////////     
    function withdraw(uint amount, address payable receivingWallet) public onlyOwner {
        require(amount <= address (this).balance, "Insufficient funds");
        receivingWallet.transfer(amount);
    }

   //////////////////////// Pause/UnPause Smart Contract ///////////////////// 
    function pause() public onlyOwner {
        _pause();
        emit ContractIsPaused (true);        
    }
    
    function unpause() public onlyOwner {
        _unpause();
        emit ContractIsPaused (false);
    }

   /////////////////////// Disable Renounce Ownership //////////////////////////////////// 
    function renounceOwnership() public view override onlyOwner {
        revert("Nftania Vending: ownership cannot be renounced");  
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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