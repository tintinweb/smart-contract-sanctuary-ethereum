// SPDX-License-Identifier: BUSL-1.1
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import { MintParams } from "../structs/erc721/ERC721Structs.sol";

/**
 * @title TokenFactory
 * @author Omnisea @MaciejCzypek
 * @custom:version 0.1
 * @notice TokenFactory is ERC721 minting service.
 *         Contract is responsible for validating and executing the function that creates (mints) a NFT.
 *         Enables delegation of cross-chain minting via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         It is designed to avoid burn & mint mechanism to keep NFT's non-fungibility, on-chain history, and references to contracts.
 *         It supports cross-chain actions instead of ERC721 "transfer", and allows simultaneous actions from many chains,
 *         without requiring the NFT presence on the same chain as the user performing the action (e.g. mint).
 */
contract TokenFactory is IOmniApp {

    event OmReceived(string srcChain, address srcOA);
    event Minted(address collAddr, address rec);
    event Paid(address rec);
    event Locked(address rec, uint256 amount, address asset);
    event Refunded(address rec);
    event NewRefund(address collAddr, address spender);

    error InvalidPrice(address collAddr, address spender, uint256 paid);
    error InvalidCreator(address collAddr, address cre);
    error InvalidAsset(string collAsset, string paidAsset);

    modifier isOwner {
        require(msg.sender == _owner);
        _;
    }

    IOmnichainRouter public omnichainRouter;
    mapping(address => mapping(string => mapping(address => uint256))) public refunds;
    mapping(address => mapping(string => uint256)) public mints;
    string public chainName;
    mapping(string => address) public remoteChainToOA;
    mapping(string => IERC20) public assets;
    address private _owner;
    address private _feeManager;
    address private _redirectionsBudgetManager;

    /**
     * @notice Sets the contract owner, feeManager address, router, and indicates source chain name for mappings.
     *
     * @param _router A contract that handles cross-chain messaging used to extend ERC721 with omnichain capabilities.
     */
    constructor(IOmnichainRouter _router) {
        _owner = msg.sender;
        chainName = "Ethereum";
        _feeManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
        omnichainRouter = _router;
    }

    function setRouter(IOmnichainRouter _router) external isOwner {
        omnichainRouter = _router;
    }

    function setFeeManager(address _newManager) external isOwner {
        _feeManager = _newManager;
    }

    function setRedirectionsBudgetManager(address _newManager) external isOwner {
        _redirectionsBudgetManager = _newManager;
    }

    /**
     * @notice Sets the remote Omnichain Applications ("OA") addresses to meet omReceive() validation.
     *
     * @param remoteChainName Name of the remote chain.
     * @param remoteOA Address of the remote OA.
     */
    function setOA(string memory remoteChainName, address remoteOA) external isOwner {
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
     */
    function addAsset(address asset, string memory assetName) external isOwner {
        require(asset != address(0));
        assets[assetName] = IERC20(asset);
    }

    /**
     * @notice Handles the ERC721 minting logic.
     *         Validates data and checks if minting is allowed.
     *         If price for mint is set, it initiates payment processing.
     *         Delegates task to the Omnichain Router based on the varying chainName and dstChainName.
     *
     * @param params See MintParams struct in ERC721Structs.sol.
     */
    function mintToken(MintParams calldata params) public payable {
        require(bytes(params.dstChainName).length > 0 && params.coll != address(0));
        if (keccak256(bytes(params.dstChainName)) == keccak256(bytes(chainName))) {
            IOmniERC721 omniNft = IOmniERC721(params.coll);
            uint256 price = omniNft.mintPrice();
            if (price > 0) {
                processMintPayment(price, msg.sender, omniNft.creator(), false, assets[omniNft.assetName()]);
            }
            omniNft.mint(msg.sender);
            emit Minted(params.coll, msg.sender);
            return;
        }
        if (params.mintPrice > 0) {
            processMintPayment(params.mintPrice, msg.sender, address(this), true, assets[params.assetName]);
        }
        bytes memory payload = _getMintPayload(params.coll, params.mintPrice, params.creator, params.assetName);
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
        (uint256 actionType, address coll, bool minted, uint256 paid, address rec, address cre, string memory assetName) = abi.decode(_payload, (uint256, address, bool, uint256, address, address, string));
        if (actionType != 1) {
            withdraw(rec, cre, paid, assetName, minted);
            return;
        }
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.mintPrice();
        uint256 supply = collection.totalSupply();
        if (price > 0 && (supply > 0 && collection.tokenIds() >= supply)) {
            refunds[coll][srcChain][rec] += price;
            emit NewRefund(coll, rec);
            return;
        }
        if (cre != collection.creator()) revert InvalidCreator(coll, cre);

        if (price > 0) {
            if (paid < price) revert InvalidPrice(coll, rec, paid);
            if (keccak256(bytes(assetName)) != keccak256(bytes(collection.assetName()))) revert InvalidAsset(collection.assetName(), assetName);
        }

        collection.mint(rec);
        mints[coll][srcChain]++;
        emit Minted(coll, rec);
    }

    /**
     * @notice Refund if mint failed due to supply exceeded on cross-chain mint (funds locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function refund(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 amount = refunds[collectionAddress][dstChainName][msg.sender];
        require(collection.mintPrice() > 0 && amount > 0);
        refunds[collectionAddress][dstChainName][msg.sender] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, false, amount), dstChainName, gas, redirectFee);
    }

    /**
     * @notice Payout creator earnings (funds from minting locked on dstChain).
     *
     * @param collectionAddress The address of the ERC721 collection.
     * @param dstChainName Name of the remote chain.
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
    function getEarned(address collectionAddress, string memory dstChainName, uint256 gas, uint256 redirectFee) external payable {
        IOmniERC721 collection = IOmniERC721(collectionAddress);
        uint256 price = collection.mintPrice();
        uint256 amount = mints[collectionAddress][dstChainName] * price;
        require(price > 0 && amount > 0 && msg.sender == collection.creator());
        mints[collectionAddress][dstChainName] = 0;
        _omniAction(_getWithdrawPayload(collectionAddress, true, amount), dstChainName, gas, redirectFee);
    }

    function withdrawOARedirectFees() external isOwner {
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
     * @param price Price for a single ERC721 mint.
     * @param spender The spender address.
     * @param creator The collection creator address.
     * @param isLock Cross-chain minting requires locking funds for the future withdraw action.
     * @param asset ERC20 minting price currency.
     */
    function processMintPayment(uint256 price, address spender, address creator, bool isLock, IERC20 asset) internal {
        require(asset.allowance(spender, address(this)) >= price);

        if (isLock) {
            asset.transferFrom(spender, creator, price);
            emit Locked(creator, price, address(asset));
            return;
        }
        asset.transferFrom(spender, creator, price * 98 / 100);
        asset.transferFrom(spender, _feeManager, price * 2 / 100);
        emit Paid(creator);
    }

    /**
     * @notice Withdraws funds locked during cross-chain mint. Payout creator if minted, refund spender if failed.
     *
     * @param receiver The receiver address.
     * @param creator The creator address.
     * @param price The price for single ERC721 mint.
     * @param assetName ERC20 minting price currency name.
     * @param isPayout If true pay creator, if false refund spender.
     */
    function withdraw(address receiver, address creator, uint256 price, string memory assetName, bool isPayout) private {
        if (price == 0) {
            return;
        }
        IERC20 asset = assets[assetName];

        if (isPayout) {
            asset.transfer(creator, price * 98 / 100);
            asset.transfer(_feeManager, price * 2 / 100);
            emit Paid(creator);
            return;
        }
        asset.transfer(receiver, price);
        emit Refunded(receiver);
    }

    /**
     * @notice Encodes data for cross-chain minting execution.
     *
     * @param collectionAddress The collection address.
     * @param price The price for single ERC721 mint.
     * @param creator The creator address.
     * @param assetName ERC20 minting price currency name.
     */
    function _getMintPayload(address collectionAddress, uint256 price, address creator, string memory assetName) private view returns (bytes memory) {
        return abi.encode(1, collectionAddress, true, price, msg.sender, creator, assetName);
    }

    /**
     * @notice Encodes data for cross-chain withdraw (payout/refund) execution.
     *
     * @param collectionAddress The collection address.
     * @param isPayout If true payout creator, if false refund spender.
     * @param amount The ERC20 amount to withdraw.
     */
    function _getWithdrawPayload(address collectionAddress, bool isPayout, uint256 amount) private view returns (bytes memory) {
        return abi.encode(2, collectionAddress, isPayout, amount, msg.sender, msg.sender);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner) external;
    function totalSupply() external view returns (uint256);
    function mintPrice() external view returns (uint256);
    function tokenIds() external view returns (uint256);
    function creator() external view returns (address);
    function createdAt() external view returns (uint256);
    function dropFrom() external view returns (uint256);
    function assetName() external view returns (string memory);
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

// SPDX-License-Identifier: BUSL-1.1
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

// SPDX-License-Identifier: BUSL-1.1
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

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.7;

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
     * @param totalSupply Collection's total supply. Unlimited if 0.
     * @param gas Cross-chain task (tx) execution gas limit
     * @param redirectFee Fee required to cover transaction fee on the redirectChain, if involved. OmnichainRouter-specific.
     *        Involved during cross-chain multi-protocol routing. For example, Optimism (LayerZero) to Moonbeam (Axelar).
     */
struct CreateParams {
    string dstChainName;
    string name;
    string uri;
    string fileURI;
    uint256 price;
    string assetName;
    uint256 from;
    uint256 to;
    string tokensURI;
    uint256 totalSupply;
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
    address creator;
    uint256 gas;
    uint256 redirectFee;
}