// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

import "./IMintBurnToken.sol";
import "./IWormhole.sol";
import "./LnAdminUpgradeable.sol";

/**
 * @title LnErc20Bridge
 *
 * @dev An upgradeable contract for moving ERC20 tokens across blockchains. It makes use of the
 * Wormhole messaging functionality for verifying deposit proofs. Before Wormhole was integrated,
 * the contract uses a centralized relayer for deposit verification.
 *
 * @dev The bridge can operate in two different modes for each token: transfer mode and mint/burn
 * mode, depending on the nature of the token.
 *
 * @dev Note that transaction hashes shall NOT be used for re-entrance prevention as doing
 * so will result in false negatives when multiple transfers are made in a single
 * transaction (with the use of contracts).
 *
 * @dev Chain IDs in this contract currently refer to the ones introduced in EIP-155. However,
 * a list of custom IDs might be used instead when non-EVM compatible chains are added.
 */
contract LnErc20Bridge is LnAdminUpgradeable {
    /**
     * These events are no longer used. Archiving them here for reference but they won't show up in
     * ABI. You need to manually edit the ABI if you want to index old events in subgraphs, for
     * example.
     *
     * event TokenDeposited(
     *     uint256 srcChainId,
     *     uint256 destChainId,
     *     uint256 depositId,
     *     bytes32 depositor,
     *     bytes32 recipient,
     *     bytes32 currency,
     *     uint256 amount
     * );
     * event ForcedWithdrawal(uint256 srcChainId, uint256 depositId, address actualRecipient);
     * event RelayerChanged(address oldRelayer, address newRelayer);
     */

    /**
     * @dev Emits when a deposit is made.
     *
     * @dev Addresses are represented with bytes32 to maximize compatibility with
     * non-Ethereum-compatible blockchains.
     *
     * @param srcChainId Chain ID of the source blockchain (current chain)
     * @param destChainId Chain ID of the destination blockchain
     * @param depositId Unique ID of the deposit on the current chain
     * @param depositor Address of the account on the current chain that made the deposit
     * @param recipient Address of the account on the destination chain that will receive the amount
     * @param currency A bytes32-encoded universal currency key
     * @param amount Amount of tokens being deposited to recipient's address.
     * @param wormholeSequence Wormhole message sequence.
     */
    event TokenDeposited(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount,
        uint64 wormholeSequence
    );
    event TokenWithdrawn(
        uint256 srcChainId,
        uint256 destChainId,
        uint256 depositId,
        bytes32 depositor,
        bytes32 recipient,
        bytes32 currency,
        uint256 amount
    );
    event TokenAdded(bytes32 tokenKey, address tokenAddress, uint8 lockType);
    event TokenRemoved(bytes32 tokenKey);
    event ChainSupportForTokenAdded(bytes32 tokenKey, uint256 chainId);
    event ChainSupportForTokenDropped(bytes32 tokenKey, uint256 chainId);
    event WormholeSetup(address coreContract, uint8 consistencyLevel);
    event BridgeAddressForChainUpdated(uint256 chainId, address bridgeAddress);
    event WormholeNetworkIdUpdated(uint256 chainId, uint16 wormholeNetworkId);

    struct TokenInfo {
        address tokenAddress;
        uint8 lockType;
    }

    struct WormholeConfig {
        IWormhole coreContract;
        uint8 consistencyLevel;
    }

    uint256 public currentChainId;

    // This storage slot used to be named `relayer` for storing the address of the centralized
    // relayer, and was removed after Wormhole integration.
    address private DEPRECATED_DO_NOT_USE_0;

    uint256 public depositCount;
    mapping(bytes32 => TokenInfo) public tokenInfos;
    mapping(bytes32 => mapping(uint256 => bool)) public tokenSupportedOnChain;
    mapping(uint256 => mapping(uint256 => bool)) public withdrawnDeposits;

    // This storage slot used to be named `DOMAIN_SEPARATOR` for EIP-712 signature verification,
    // and was removed after Wormhole integration.
    bytes32 private DEPRECATED_DO_NOT_USE_1;

    WormholeConfig public wormhole;
    mapping(uint256 => bytes32) public bridgeContractsByChainId;
    mapping(uint256 => uint16) public wormholeNetworkIdsByChainId;

    uint8 public constant TOKEN_LOCK_TYPE_TRANSFER = 1;
    uint8 public constant TOKEN_LOCK_TYPE_MINT_BURN = 2;

    bytes4 private constant TRANSFER_SELECTOR = bytes4(keccak256(bytes("transfer(address,uint256)")));
    bytes4 private constant TRANSFERFROM_SELECTOR = bytes4(keccak256(bytes("transferFrom(address,address,uint256)")));

    function getTokenAddress(bytes32 tokenKey) public view returns (address) {
        return tokenInfos[tokenKey].tokenAddress;
    }

    function getTokenLockType(bytes32 tokenKey) public view returns (uint8) {
        return tokenInfos[tokenKey].lockType;
    }

    function isTokenSupportedOnChain(bytes32 tokenKey, uint256 chainId) public view returns (bool) {
        return tokenSupportedOnChain[tokenKey][chainId];
    }

    function __LnErc20Bridge_init(address _admin) public initializer {
        __LnAdminUpgradeable_init(_admin);

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        currentChainId = chainId;
    }

    // This function must be called after the wormhole upgrade for the bridge to be functional.
    function setUpWormhole(address _coreContract, uint8 _consistencyLevel) external onlyAdmin {
        require(address(wormhole.coreContract) == address(0), "LnErc20Bridge: already set up");

        require(_coreContract != address(0), "LnErc20Bridge: zero address");

        wormhole = WormholeConfig({coreContract: IWormhole(_coreContract), consistencyLevel: _consistencyLevel});

        // Clean up the deprecated slots so that we can reuse them in a future upgrade.
        DEPRECATED_DO_NOT_USE_0 = address(0);
        DEPRECATED_DO_NOT_USE_1 = bytes32(0);

        emit WormholeSetup(_coreContract, _consistencyLevel);
    }

    function setBridgeAddressForChain(uint256 chainId, address bridgeAddress) external onlyAdmin {
        require(chainId != 0, "LnErc20Bridge: zero chain id");
        require(bridgeAddress != address(0), "LnErc20Bridge: zero address");

        bridgeContractsByChainId[chainId] = bytes32(uint256(bridgeAddress));

        emit BridgeAddressForChainUpdated(chainId, bridgeAddress);
    }

    function setWormholeNetworkIdForChain(uint256 chainId, uint16 wormholeNetworkId) external onlyAdmin {
        require(chainId != 0, "LnErc20Bridge: zero chain id");
        require(wormholeNetworkId != 0, "LnErc20Bridge: zero network id");

        wormholeNetworkIdsByChainId[chainId] = wormholeNetworkId;

        emit WormholeNetworkIdUpdated(chainId, wormholeNetworkId);
    }

    function addToken(
        bytes32 tokenKey,
        address tokenAddress,
        uint8 lockType
    ) external onlyAdmin {
        require(tokenInfos[tokenKey].tokenAddress == address(0), "LnErc20Bridge: token already exists");
        require(tokenAddress != address(0), "LnErc20Bridge: zero address");
        require(
            lockType == TOKEN_LOCK_TYPE_TRANSFER || lockType == TOKEN_LOCK_TYPE_MINT_BURN,
            "LnErc20Bridge: unknown token lock type"
        );

        tokenInfos[tokenKey] = TokenInfo({tokenAddress: tokenAddress, lockType: lockType});
        emit TokenAdded(tokenKey, tokenAddress, lockType);
    }

    function removeToken(bytes32 tokenKey) external onlyAdmin {
        require(tokenInfos[tokenKey].tokenAddress != address(0), "LnErc20Bridge: token does not exists");
        delete tokenInfos[tokenKey];
        emit TokenRemoved(tokenKey);
    }

    function addChainSupportForToken(bytes32 tokenKey, uint256 chainId) external onlyAdmin {
        require(!tokenSupportedOnChain[tokenKey][chainId], "LnErc20Bridge: already supported");
        tokenSupportedOnChain[tokenKey][chainId] = true;
        emit ChainSupportForTokenAdded(tokenKey, chainId);
    }

    function dropChainSupportForToken(bytes32 tokenKey, uint256 chainId) external onlyAdmin {
        require(tokenSupportedOnChain[tokenKey][chainId], "LnErc20Bridge: not supported");
        tokenSupportedOnChain[tokenKey][chainId] = false;
        emit ChainSupportForTokenDropped(tokenKey, chainId);
    }

    function deposit(
        bytes32 token,
        uint256 amount,
        uint256 destChainId,
        bytes32 recipient
    ) external {
        require(address(wormhole.coreContract) != address(0), "LnErc20Bridge: wormhole not set up");

        TokenInfo memory tokenInfo = tokenInfos[token];
        require(tokenInfo.tokenAddress != address(0), "LnErc20Bridge: token not found");

        require(amount > 0, "LnErc20Bridge: amount must be positive");
        require(destChainId != currentChainId, "LnErc20Bridge: dest must be different from src");
        require(isTokenSupportedOnChain(token, destChainId), "LnErc20Bridge: token not supported on chain");
        require(recipient != 0, "LnErc20Bridge: zero address");

        depositCount = depositCount + 1;

        if (tokenInfo.lockType == TOKEN_LOCK_TYPE_TRANSFER) {
            safeTransferFrom(tokenInfo.tokenAddress, msg.sender, address(this), amount);
        } else if (tokenInfo.lockType == TOKEN_LOCK_TYPE_MINT_BURN) {
            IMintBurnToken(tokenInfo.tokenAddress).burn(msg.sender, amount);
        } else {
            require(false, "LnErc20Bridge: unknown token lock type");
        }

        bytes memory wormholeMessage =
            abi.encode(currentChainId, destChainId, depositCount, bytes32(uint256(msg.sender)), recipient, token, amount);
        uint64 wormholeSequence = wormhole.coreContract.publishMessage(0, wormholeMessage, wormhole.consistencyLevel);

        emit TokenDeposited(
            currentChainId,
            destChainId,
            depositCount,
            bytes32(uint256(msg.sender)),
            recipient,
            token,
            amount,
            wormholeSequence
        );
    }

    function withdraw(bytes calldata encodedWormholeMessage) external {
        require(address(wormhole.coreContract) != address(0), "LnErc20Bridge: wormhole not set up");

        (IWormhole.VM memory wormholeMessage, bool isWormholeMessageValid, ) =
            wormhole.coreContract.parseAndVerifyVM(encodedWormholeMessage);
        require(isWormholeMessageValid, "LnErc20Bridge: wormhole message verification failed");

        (
            uint256 srcChainId,
            uint256 destChainId,
            uint256 depositId,
            bytes32 depositor,
            bytes32 recipient,
            bytes32 currency,
            uint256 amount
        ) = abi.decode(wormholeMessage.payload, (uint256, uint256, uint256, bytes32, bytes32, bytes32, uint256));

        uint16 expectedWormholeNetwork = wormholeNetworkIdsByChainId[srcChainId];
        require(expectedWormholeNetwork != 0, "LnErc20Bridge: network id not set");
        require(expectedWormholeNetwork == wormholeMessage.emitterChainId, "LnErc20Bridge: network id mismatch");

        bytes32 srcChainBridgeAddress = bridgeContractsByChainId[srcChainId];
        require(srcChainBridgeAddress != bytes32(0), "LnErc20Bridge: bridge address not set");
        require(srcChainBridgeAddress == wormholeMessage.emitterAddress, "LnErc20Bridge: emitter mismatch");

        require(destChainId == currentChainId, "LnErc20Bridge: wrong chain");
        require(!withdrawnDeposits[srcChainId][depositId], "LnErc20Bridge: already withdrawn");
        require(recipient != 0, "LnErc20Bridge: zero address");
        require(amount > 0, "LnErc20Bridge: amount must be positive");

        TokenInfo memory tokenInfo = tokenInfos[currency];
        require(tokenInfo.tokenAddress != address(0), "LnErc20Bridge: token not found");

        withdrawnDeposits[srcChainId][depositId] = true;

        address decodedRecipient = address(uint160(uint256(recipient)));

        if (tokenInfo.lockType == TOKEN_LOCK_TYPE_TRANSFER) {
            safeTransfer(tokenInfo.tokenAddress, decodedRecipient, amount);
        } else if (tokenInfo.lockType == TOKEN_LOCK_TYPE_MINT_BURN) {
            IMintBurnToken(tokenInfo.tokenAddress).mint(decodedRecipient, amount);
        } else {
            require(false, "LnErc20Bridge: unknown token lock type");
        }

        emit TokenWithdrawn(srcChainId, destChainId, depositId, depositor, recipient, currency, amount);
    }

    function safeTransfer(
        address token,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(TRANSFER_SELECTOR, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "LnErc20Bridge: transfer failed");
    }

    function safeTransferFrom(
        address token,
        address sender,
        address recipient,
        uint256 amount
    ) private {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(TRANSFERFROM_SELECTOR, sender, recipient, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "LnErc20Bridge: transfer from failed");
    }
}