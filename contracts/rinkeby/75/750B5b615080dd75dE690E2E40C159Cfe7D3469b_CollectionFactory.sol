// SPDX-License-Identifier: BUSL-1.1
// omnisea-contracts v0.1

pragma solidity ^0.8.7;

import "../interfaces/ICollectionsRepository.sol";
import "../interfaces/IOmniApp.sol";
import "../interfaces/IOmnichainRouter.sol";
import { CreateParams } from "../structs/erc721/ERC721Structs.sol";

/**
 * @title CollectionFactory
 * @author Omnisea @MaciejCzypek
 * @custom:version 0.1
 * @notice CollectionFactory is ERC721 collection creation service.
 *         Contract is responsible for validating and executing the function that creates ERC721 collection.
 *         Enables delegation of cross-chain collection creation via Omnichain Router which abstracts underlying cross-chain messaging.
 *         messaging protocols such as LayerZero and Axelar Network.
 *         With the TokenFactory contract, it is designed to avoid burn & mint mechanism to keep NFT's non-fungibility,
 *         on-chain history, and references to contracts. It supports cross-chain actions instead of ERC721 "transfer",
 *         and allows simultaneous actions from many chains, without requiring the NFT presence on the same chain as
 *         the user performing the action (e.g. mint).
 */
contract CollectionFactory is IOmniApp {
    event OmReceived(string srcChain, address srcOA);

    address public repository;
    address private _owner;
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
        _owner = msg.sender;
        chainName = "Ethereum";
        omnichainRouter = _router;
        _redirectionsBudgetManager = address(0x61104fBe07ecc735D8d84422c7f045f8d29DBf15);
    }

    /**
     * @notice Sets the Collection Repository responsible for creating ERC721 contract and storing reference.
     *
     * @param repo The CollectionsRepository contract address.
     */
    function setRepository(address repo) external {
        require(msg.sender == _owner && repository == address(0));
        _collectionsRepository = ICollectionsRepository(repo);
        repository = repo;
    }

    // TODO: REMOVE! For faster testing only
    function setRouter(IOmnichainRouter _router) external {
        require(msg.sender == _owner);
        omnichainRouter = _router;
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
    function setOA(string calldata remoteChainName, address remoteOA) external {
        require(msg.sender == _owner);
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

    function withdrawOARedirectFees() external {
        require(msg.sender == _owner);
        omnichainRouter.withdrawOARedirectFees(_redirectionsBudgetManager);
    }

    receive() external payable {}
}

// SPDX-License-Identifier: BUSL-1.1
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