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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import { MintParams, Asset } from "../structs/erc721/ERC721Structs.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TokenFactory
 * @author Omnisea
 * @custom:version 1.0
 * @notice TokenFactory is ERC721 minting service.
 *         Contract is responsible for validating and executing the function that creates (mints) a NFT.
 *         Enables delegation of cross-chain minting via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         It is designed to avoid burn & mint mechanism to keep NFT's non-fungibility, on-chain history, and references to contracts.
 *         It supports cross-chain actions instead of ERC721 "transfer", and allows simultaneous actions from many chains,
 *         without requiring the NFT presence on the same chain as the user performing the action (e.g. mint).
 */
contract TokenFactory is IOmniApp, Ownable, ReentrancyGuard {

    event OmReceived(string srcChain, address srcOA);
    event Minted(address collAddr, address rec, uint256 quantity);
    event Paid(address rec);
    event Locked(address rec, uint256 amount, address asset);
    event Refunded(address rec);
    event NewRefund(address collAddr, address spender, uint256 sum);

    error InvalidPrice(address collAddr, address spender, uint256 paid, uint256 quantity);
    error InvalidCreator(address collAddr, address cre);
    error InvalidAsset(string collAsset, string paidAsset);

    uint256 private constant ACTION_MINT = 1;
    uint256 private constant ACTION_WITHDRAW = 2;

    IOmnichainRouter public omnichainRouter;
    mapping(address => mapping(string => mapping(address => uint256))) public refunds;
    mapping(address => mapping(string => uint256)) public mints;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    mapping(string => Asset) public assets;
    uint256 private _fee;
    address private _feeManager;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, feeManager address, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        chainName = "Ethereum";
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        omnichainRouter = _router;
    }

    function setRouter(IOmnichainRouter _router) external onlyOwner {
        omnichainRouter = _router;
    }

    function setFee(uint256 fee) external onlyOwner {
        require(fee <= 5);
        _fee = fee;
    }

    function setFeeManager(address _newManager) external onlyOwner {
        _feeManager = _newManager;
    }

    function setRedirectionsBudgetManager(address _newManager) external onlyOwner {
        _redirectionsBudgetManager = _newManager;
    }

    function setChainName(string memory _chainName) external onlyOwner {
        chainName = _chainName;
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string memory remoteChainName, address remoteOA) external onlyOwner {
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

    /**
     * @notice Adds ERC20 (asset) support as the minting payment currency.
     *
     * @param asset Address of the supported ERC20.
     * @param assetName Name of the asset used for the mapping purpose.
     * @param decimals Token decimals.
     */
    function addAsset(address asset, string memory assetName, uint256 decimals) external onlyOwner {
        require(asset != address(0));
        assets[assetName] = Asset(IERC20(asset), decimals);
    }

    /**
     * @notice Handles the ERC721 minting logic.
     *         Validates data and checks if minting is allowed.
     *         If price for mint is set, it initiates payment processing.
     *         Delegates task to the Omnichain Router based on the varying chainName and dstChainName.
     *
     * @param params See MintParams struct in ERC721Structs.sol.
     */
    function mintToken(MintParams calldata params) public payable nonReentrant {
        require(params.quantity > 0, "!quantity");
        require(bytes(params.dstChainName).length > 0 && params.coll != address(0));

        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) {
            IOmniERC721 omniNft = IOmniERC721(params.coll);
            uint256 price = omniNft.mintPrice();
            uint256 quantityPrice = price * params.quantity;
            if (price > 0) {
                processMintPayment(quantityPrice, msg.sender, omniNft.creator(), false, assets[omniNft.assetName()]);
            }
            omniNft.mint(msg.sender, params.quantity);
            emit Minted(params.coll, msg.sender, params.quantity);
            return;
        }
        if (params.mintPrice > 0) {
            processMintPayment((params.mintPrice * params.quantity), msg.sender, address(this), true, assets[params.assetName]);
        }
        bytes memory payload = _getMintPayload(params.coll, params.mintPrice, params.creator, params.assetName, params.quantity);
        _omniAction(payload, params.dstChainName, params.gas, params.redirectFee);
    }

    /**
     * @notice Handles the incoming tasks from other chains received from Omnichain Router.
     *         Validates User Application.
     *         actionType == 1: mint.
     *         actionType != 1: withdraw (See payout / refund).

     * @notice Prevents throwing supply exceeded error when mint transactions from at least 2 chains are racing.
     *         srcChain isn't aware of supply exceeding risk when initiating a transaction because it doesn't know about
     *         pending cross-chain transactions from other chains. If a price for mint is specified and funds were locked
     *         on the srcChain, the minting user will be eligible for a refund (unlocking and return of the funds).
     *         This way, it syncs the minting logic state between each chain.
     *
     * @param _payload Encoded MintParams data.
     * @param srcOA Address of the remote OA.
     * @param srcChain Name of the remote OA chain.
     */
    function omReceive(bytes calldata _payload, address srcOA, string memory srcChain) external override {
        emit OmReceived(srcChain, srcOA);
        require(isOA(srcChain, srcOA));
        (uint256 actionType, address coll, bool minted, uint256 paid, address rec, address cre, string memory assetName, uint256 quantity)
        = abi.decode(_payload, (uint256, address, bool, uint256, address, address, string, uint256));

        if (actionType == ACTION_WITHDRAW) {
            withdraw(rec, cre, paid, assetName, minted);
            return;
        }
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.mintPrice();
        uint256 quantityPrice = price * quantity;
        uint256 maxSupply = collection.maxSupply();

        if (cre != collection.creator()) revert InvalidCreator(coll, cre);

        if (price > 0) {
            if (paid != quantityPrice) revert InvalidPrice(coll, rec, paid, quantity);
            if (keccak256(bytes(assetName)) != keccak256(bytes(collection.assetName()))) revert InvalidAsset(collection.assetName(), assetName);

            if (maxSupply > 0 && (collection.totalMinted() + quantity) > maxSupply) {
                refunds[coll][srcChain][rec] += quantityPrice;
                emit NewRefund(coll, rec, quantityPrice);
                return;
            }
        }

        collection.mint(rec, quantity);
        mints[coll][srcChain] += quantity;
        emit Minted(coll, rec, quantity);
    }

    /**
     * @notice Refund if mint failed due to supply exceeded on cross-chain mint (funds locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function refund(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable nonReentrant {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 amount = refunds[collectionAddress][dstChainName][msg.sender];
        require(collection.mintPrice() > 0 && amount > 0);
        refunds[collectionAddress][dstChainName][msg.sender] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, false, amount, collection.assetName()), dstChainName, gas, redirectFee);
    }

    /**
     * @notice Payout creator earnings (funds from minting locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function getEarned(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable nonReentrant {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 price = collection.mintPrice();
        uint256 amount = mints[collectionAddress][dstChainName] * price;
        require(price > 0 && amount > 0 && msg.sender == collection.creator());
        mints[collectionAddress][dstChainName] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, true, amount, collection.assetName()), dstChainName, gas, redirectFee);
    }

    function withdrawOARedirectFees() external onlyOwner {
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    /**
     * @notice Delegates cross-chain task to the Omnichain Router.
     *
     * @param payload Data required for the task execution on the dstChain.
     * @param dstChainName Name of the remote chain.
     * @param gas Gas limit set for the function execution on the dstChain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function _omniAction(bytes memory payload, string memory dstChainName, uint256 gas, uint256 redirectFee) private {
        omnichainRouter.send{value : msg.value}(dstChainName, remoteChainToOA[dstChainName], payload, gas, msg.sender, redirectFee);
    }

    /**
     * @notice If same chain, pays creator immediately. If different chains, locks funds for future payout/refund action.
     *
     * @param price Price for a quantity of ERC721 tokens to mint.
     * @param spender The spender address.
     * @param receiver The collection creator address.
     * @param isLock Cross-chain minting requires locking funds for the future withdraw action.
     * @param asset Asset used for minting.
     */
    function processMintPayment(uint256 price, address spender, address receiver, bool isLock, Asset memory asset) internal {
        IERC20 token = asset.token;
        uint256 inWei = (price * 10**asset.decimals);
        require(token.allowance(spender, address(this)) >= inWei);

        if (isLock) {
            token.transferFrom(spender, receiver, inWei);
            emit Locked(receiver, inWei, address(token));
            return;
        }

        token.transferFrom(spender, receiver, inWei * (100 - _fee) / 100);
        if (_fee > 0) {
            token.transferFrom(spender, _feeManager, inWei * _fee / 100);
        }
        emit Paid(receiver);
    }

    /**
     * @notice Withdraws funds locked during cross-chain mint. Payout creator if minted, refund spender if failed.
     *
     * @param refundee The refundee address.
     * @param creator The creator address.
     * @param price The price for single ERC721 mint.
     * @param assetName ERC20 minting price currency name.
     * @param isPayout If true pay creator, if false refund spender.
     */
    function withdraw(address refundee, address creator, uint256 price, string memory assetName, bool isPayout) private nonReentrant {
        Asset memory asset = assets[assetName];
        IERC20 token = asset.token;
        uint256 inWei = (price * 10**asset.decimals);

        if (inWei == 0) {
            return;
        }

        if (isPayout) {
            token.transfer(creator, inWei * (100 - _fee) / 100);
            if (_fee > 0) {
                token.transfer(_feeManager, inWei * _fee / 100);
            }
            emit Paid(creator);

            return;
        }
        token.transfer(refundee, inWei);
        emit Refunded(refundee);
    }

    /**
     * @notice Encodes data for cross-chain minting execution.
     *
     * @param collectionAddress The collection address.
     * @param price The price for single ERC721 mint.
     * @param creator The creator address.
     * @param assetName ERC20 minting price currency name.
     */
    function _getMintPayload(address collectionAddress, uint256 price, address creator, string memory assetName, uint256 quantity) private view returns (bytes memory) {
        return abi.encode(ACTION_MINT, collectionAddress, true, (price * quantity), msg.sender, creator, assetName, quantity);
    }

    /**
     * @notice Encodes data for cross-chain withdraw (payout/refund) execution.
     *
     * @param collectionAddress The collection address.
     * @param isPayout If true payout creator, if false refund spender.
     * @param amount The ERC20 amount to withdraw.
     */
    function _getWithdrawPayload(address collectionAddress, bool isPayout, uint256 amount, string memory assetName) private view returns (bytes memory) {
        return abi.encode(ACTION_WITHDRAW, collectionAddress, isPayout, amount, msg.sender, msg.sender, assetName);
    }

    receive() external payable {}
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

interface IOmniERC721 {
    function mint(address owner, uint256 quantity) external;
    function maxSupply() external view returns (uint256);
    function mintPrice() external view returns (uint256);
    function totalMinted() external view returns (uint256);
    function creator() external view returns (address);
    function createdAt() external view returns (uint256);
    function dropFrom() external view returns (uint256);
    function assetName() external view returns (string memory);
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
     * @param isZeroIndexed First token ID.
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
    bool isZeroIndexed;
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
    uint256 price;
    bool isEnabled;
}