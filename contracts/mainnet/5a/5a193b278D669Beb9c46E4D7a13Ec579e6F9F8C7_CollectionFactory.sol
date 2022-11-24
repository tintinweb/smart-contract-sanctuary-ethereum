// SPDX-License-Identifier: MIT
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "../interfaces/ICollectionsRepository.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import { CreateParams } from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title CollectionFactory
 * @author Omnisea
 * @custom:version 1.0
 * @notice CollectionFactory is ERC721 collection creation service.
 *         Contract is responsible for validating and executing the function that creates ERC721 collection.
 *         Enables delegation of cross-chain collection creation via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         With the TokenFactory contract, it is designed to avoid burn & mint mechanism to keep NFT's non-fungibility,
 *         on-chain history, and references to contracts. It supports cross-chain actions instead of ERC721 "transfer",
 *         and allows simultaneous actions from many chains, without requiring the NFT presence on the same chain as
 *         the user performing the action (e.g. mint).
 */
contract CollectionFactory is IOmniApp, Ownable {
    event OmReceived(string srcChain, address srcOA);

    address public repository;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    ICollectionsRepository private _collectionsRepository;
    IOmnichainRouter public omnichainRouter;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        chainName = "Ethereum";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    /**
     * @notice Sets the Collection Repository responsible for creating ERC721 contract and storing reference.
     *
     * @param repo The CollectionsRepository contract address.
     */
    function setRepository(address repo) external onlyOwner {
        _collectionsRepository = ICollectionsRepository(repo);
        repository = repo;
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
    }

    /**
     * @notice Handles the ERC721 collection creation logic.
     *         Validates data and delegates contract creation to repository.
     *         Delegates task to the Omnichain Router based on the varying chainName and dstChainName.
     *
     * @param params See CreateParams struct in ERC721Structs.sol.
     */
    function create(CreateParams calldata params) public payable {
        require(bytes(params.name).length >= 2);
        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) {
            _collectionsRepository.create(params, msg.sender);
            return;
        }
        omnichainRouter.send{value : msg.value}(
            params.dstChainName,
            remoteChainToOA[params.dstChainName],
            abi.encode(params, msg.sender),
            params.gas,
            msg.sender,
            params.redirectFee
        );
    }

    /**
     * @notice Handles the incoming ERC721 collection creation task from other chains received from Omnichain Router.
     *         Validates User Application.

     * @param _payload Encoded CreateParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA));
        (CreateParams memory params, address creator) = abi.decode(_payload, (CreateParams, address));
        _collectionsRepository.create(
            params,
            creator
        );
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string calldata remoteChainName, address remoteOA) external onlyOwner {
        remoteChainToOA[remoteChainName] = remoteOA;
    }

    /**
     * @notice Checks the presence of the selected remote User Application ("OA").
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function isOA(string memory remoteChainName, address remoteOA) public view returns (bool) {
        return remoteChainToOA[remoteChainName] == remoteOA;
    }

    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import {CreateParams} from "../structs/erc721/ERC721Structs.sol";

interface ICollectionsRepository {
    /**
     * @notice Creates ERC721 collection contract and stores the reference to it with relation to a creator.
     *
     * @param params See CreateParams struct in ERC721Structs.sol.
     * @param creator The address of the collection creator.
     */
    function create(CreateParams calldata params, address creator) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmniApp {
    /**
     * @notice Handles the incoming tasks from other chains received from Omnichain Router.
     *
     * @param _payload Encoded MintParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IOmnichainRouter {
    /**
     * @notice Delegates the cross-chain task to the Omnichain Router.
     *
     * @param dstChainName Name of the remote chain.
     * @param dstUA Address of the remote User Application ("UA").
     * @param fnData Encoded payload with a data for a target function execution.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param user Address of the user initiating the cross-chain task (for gas refund)
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function send(string memory dstChainName, address dstUA, bytes memory fnData, uint gas, address user, uint256 redirectFee) external payable;

    /**
     * @notice Router on source chain receives redirect fee on payable send() function call. This fee is accounted to srcUARedirectBudget.
     *         here, msg.sender is that srcUA. srcUA contract should implement this function and point the address below which manages redirection budget.
     *
     * @param redirectionBudgetManager Address pointed by the srcUA (msg.sender) executing this function.
     *        Responsible for funding srcUA redirection budget.
     */
    function withdrawOARedirectFees(address redirectionBudgetManager) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
     * @notice Parameters for ERC721 collection creation.
     *
     * @param dstChainName Name of the destination chain.
     * @param name Name of the collection.
     * @param uri URI to collection's metadata.
     * @param fileURI URI of the file linked with the collection.
     * @param price Price for a single ERC721 mint.
     * @param assetName Mapping name of the ERC20 being a currency for the minting price.
     * @param from Minting start date.
     * @param to Minting end date.
     * @param tokensURI CID of the NFTs metadata directory.
     * @param maxSupply Collection's max supply. Unlimited if 0.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
struct CreateParams {
    string dstChainName;
    string name;
    string uri;
    uint256 price;
    string assetName;
    uint256 from;
    uint256 to;
    string tokensURI;
    uint256 maxSupply;
    uint gas;
    uint256 redirectFee;
}

/**
     * @notice Parameters for ERC721 mint.
     *
     * @param dstChainName Name of the destination (NFT's) chain.
     * @param coll Address of the collection.
     * @param mintPrice Price for the ERC721 mint. Used during cross-chain mint for locking purpose. Validated on the dstChain.
     * @param assetName Mapping name of the ERC20 being a currency for the minting price.
     * @param creator Address of the creator.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
struct MintParams {
    string dstChainName;
    address coll;
    uint256 mintPrice;
    string assetName;
    uint256 quantity;
    address creator;
    uint256 gas;
    uint256 redirectFee;
}

/**
  * @notice Asset supported for omnichain minting.
  *
  * @param dstChainName Name of the destination (NFT's) chain.
  * @param coll Address of the collection.
*/
struct Asset {
    IERC20 token;
    uint256 decimals;
}

struct Allowlist {
    uint256 maxPerAddress;
    uint256 maxPerAddressPublic;
    uint256 publicFrom;
    bool isEnabled;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address sender,
        address recipient,
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