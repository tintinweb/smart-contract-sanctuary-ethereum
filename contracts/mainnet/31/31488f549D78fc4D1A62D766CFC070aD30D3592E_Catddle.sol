// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./extensions/ERC721OSafeRemote.sol";

import "./game/IGameStatus.sol";
import "./game/IDNAManager.sol";
import "./game/IFriendship.sol";

import "./IMinted.sol";

error TokenLocked();
error InvalidMinter();

contract Catddle is IMinted, ERC721OSafeRemote {

    string public _baseTokenURI;

    address public minter;

    // Token will be locked when transfer to other chains, then transfer, approve, burn and moveFrom actions will be frozen
    mapping(uint256 => bool) public isLocked;
    
    // Catddle game parts

    // encode attributes, status and friendship into 256 bits
    IGameStatus public gameStatus;
    // encode catddle's DNA and rarity into 256 bits;
    IDNAManager public dnaManager;
    // helper of Catddle friendship
    IFriendship public friendshipManager;


    constructor(string memory baseURI, address endpoint) ERC721O("Catddle", "CAT", endpoint) {
        _baseTokenURI = baseURI;
    }
  
   /**
    * Authorized functions
    */

    function authorizedMint(address user, uint256 tokenId) public override {
        if (msg.sender != minter) revert InvalidMinter();
        _safeMint(user, tokenId);
    }

    /**
     * @dev Invoked by internal transcation to handle lzReceive logic
     */
    function onLzReceive(
        uint16 srcChainId,
        uint64 nonce,
        bytes memory payload
    ) public override {
        
        // only allow internal transaction
        require(
            msg.sender == address(this),
            "ERC721-O: only internal transcation allowed"
        );

        // decode the payload
        (bytes memory to, uint256 tokenId, uint256 dna, uint256 encode) = abi.decode(
            payload,
            (bytes, uint256, uint256, uint256)
        );

        // distributed gameStatus to game managers on local chain
        gameStatus.resolveEncodes(tokenId, encode);

        // write dna to local chain
        dnaManager.setDNA(tokenId, dna);

        address toAddress = _bytes2address(to);

        _afterMoveIn(srcChainId, toAddress, tokenId);

        emit MoveIn(srcChainId, toAddress, tokenId, nonce);
    }


    /**
        OnlyOwner functions
     */

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setMinter(address minter_) public onlyOwner {
        minter = minter_;
    }

    function setDnaManager(address dnaManager_) public onlyOwner {
        dnaManager = IDNAManager(dnaManager_);
    }

    function setFriendshipManager(address friendshipManager_) public onlyOwner {
        friendshipManager = IFriendship(friendshipManager_);
    }

    function setGameStatus(address gameStatus_) public onlyOwner {
        gameStatus = IGameStatus(gameStatus_);
    }

    /**
     * Private pure functions
     */

    function _bytes2address(bytes memory to) private pure returns(address) {
        address toAddress;
        // get toAddress from bytes
        assembly {
            toAddress := mload(add(to, 20))
        }
        return toAddress;
    }

    /**
     * Internal functions   
    */

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    /**
     * @dev  Move `tokenId` token from `from` address on the current chain to `to` address on the `dstChainId` chain.
     * Internal function of {moveFrom}
     * See {IERC721_O-moveFrom}
     */
    function _move(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) internal override {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721-O: move caller is not owner or approved"
        );
        // only send message to exist remote contract`
        require(
            _remotes[dstChainId].length > 0,
            "ERC721-O: no remote contract on destination chain"
        );

        // revert if the destination gas limit is lower than `_minDestinationGasLimit`
        _gasGuard(adapterParams);

        _beforeMoveOut(from, dstChainId, to, tokenId);

        // send tokenId, dna, and game status
        bytes memory payload = abi.encode(
            to,
            tokenId,
            dnaManager.dnas(tokenId),
            gameStatus.generateEncodes(tokenId));


        // send message via LayerZero
        _endpoint.send{value: msg.value}(
            dstChainId,
            _remotes[dstChainId],
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );

        // track the LayerZero nonce
        uint64 nonce = _endpoint.getOutboundNonce(dstChainId, address(this));

        emit MoveOut(dstChainId, from, to, tokenId, nonce);
    }

    /**
     * @dev See {ERC721O-_beforeMoveOut}.
     */
    function _beforeMoveOut(
        address from,
        uint16 dstChainId,
        bytes memory to,
        uint256 tokenId
    ) internal virtual override {
        require(
            !_pauses[dstChainId],
            "ERC721OSafeRemote: cannot move token to a paused chain"
        );

        if(isLocked[tokenId]) revert TokenLocked();

        // Clear approvals even send to self
        _approve(address(0), tokenId);

        // reset friendship when transfer to other address
        if (from != _bytes2address(to)) {
            friendshipManager.resetFriendship(tokenId);
        }

        // lock token when move out
        isLocked[tokenId] = true;
    }

    /**
     * @dev See {ERC721O-_afterMoveIn}.
     */
    function _afterMoveIn(
        uint16, // srcChainId
        address to,
        uint256 tokenId
    ) internal virtual override {
        if (_exists(tokenId)) {
            // clear all approvals
            _approve(address(0), tokenId);
            // if the token came current chain before, unlock token
            isLocked[tokenId] = false;
            // then transfer token to address(to)
            address owner = ownerOf(tokenId);
            if (owner != to) {
                _transfer(owner, to, tokenId);
            }
        } else {
            // erc721 cannot mint to zero address
            if (to == address(0x0)) {
                to = address(0xdEaD);
            }
            // mint if the token never come to current chain
            _safeMint(to, tokenId);
        }
    }

    // override function in ERC721
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override {
        if (isLocked[tokenId]) {
            revert TokenLocked();
        }
        // include transfer and burn, exlucde mint (when token from other chain move in the friendship should keep)
        if (from != to && from != address(0) && address(friendshipManager) != address(0)) {
            // reset friendship to zero
            friendshipManager.resetFriendship(tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IMinted {
   function authorizedMint(address user, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IFriendship {
   function resetFriendship(uint256 tokenId) external;
   function friendships(uint256 tokenId) external view returns (uint16);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IDNAManager {
   function setDNA(uint256 tokenId, uint256 dna) external;
   function dnas(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


interface IGameStatus {
   function resolveEncodes(uint256 tokenId, uint256 encode) external;
   function generateEncodes(uint256 tokenId) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721O.sol";

/**
 * @dev Implementation of ERC721-O (Omnichain Non-Fungible Token standard) SafeRemote Extension.
 * Using the `safeSetRemote` mechanism to avoid potential fund loss during remote changes
 */
abstract contract ERC721OSafeRemote is ERC721O {
    /**
     * @dev Emitted when moving token to `chainId` chain is paused
     */
    event Paused(uint16 chainId);

    /**
     * @dev Emitted when moving token to `chainId` on `chainId` chain is unpaused
     */
    event Unpaused(uint16 chainId);

    // Mapping from chainId to whether move() function is paused
    mapping(uint16 => bool) internal _pauses;

    /**
     * @dev Returns whether moving token to `chainId` chain is paused
     */
    function pauses(uint16 chainId) public view virtual returns (bool) {
        return _pauses[chainId];
    }

    /**
     * @dev See {ERC721_O-_beforeMoveOut}.
     */
    function _beforeMoveOut(
        address, // from
        uint16 dstChainId,
        bytes memory, // to
        uint256 tokenId
    ) internal virtual override {
        require(
            !_pauses[dstChainId],
            "ERC721OSafeRemote: cannot move token to a paused chain"
        );
        _burn(tokenId);
    }

    /**
     * @dev Disallow moving token to `chainId` chain
     *
     * Requirements:
     *
     * - The state is unpaused
     */
    function pauseMove(uint16 chainId) public virtual onlyOwner {
        require(_pauses[chainId] == false, "ERC721OSafeRemote: already paused");
        _pauses[chainId] = true;
    }

    /**
     * @dev Permit moving token to `chainId` chain
     * @notice Only unpause when remote contract on `chainId` has invoked `setRemote()` for current contract, or fund may LOST permanently
     *
     * Requirements:
     *
     * - The state is paused
     */
    function unpauseMove(uint16 chainId) public virtual onlyOwner {
        require(_pauses[chainId] == true, "ERC721OSafeRemote: unpaused");
        _pauses[chainId] = false;
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
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ILayerZeroEndpoint.sol";
import "./interfaces/ILayerZeroUserApplicationConfig.sol";
import "./interfaces/IERC721OReceiver.sol";
import "./extensions/IERC721OMetadata.sol";
import "./IERC721O.sol";

/**
 * @dev Implementation of ERC721-O (Omnichain Non-Fungible Token standard)
 */
contract ERC721O is
    ERC721,
    Ownable,
    IERC721OMetadata,
    IERC721OReceiver,
    ILayerZeroUserApplicationConfig,
    IERC721O
{
    /**
     * @dev Emitted when trusted remote contract of `remoteAddress` set on `chainId` chain
     */
    event RemoteSet(uint16 chainId, bytes remoteAddress);

    /**
     * @dev Emitted when message execution failed
     */
    event MoveInFailed(
        uint16 srcChainId,
        bytes srcAddress,
        uint64 nonce,
        bytes payload
    );

    // LayerZero endpoint used to send message cross chian
    ILayerZeroEndpoint internal _endpoint;

    // Minimum gas limit for cross chain operation, exceeding fees will refund to users
    uint256 internal _minDestinationGasLimit;

    // Mapping from chainId to trusted remote contract address
    mapping(uint16 => bytes) internal _remotes;

    /**
     * @dev failed payload hash located by source chainId, source contract address, and nonce together
     */
    mapping(uint16 => mapping(bytes => mapping(uint256 => bytes32)))
        internal _failedPayloadHashs;

    /**
     * @dev Returns the address of cross chain endpoint
     */
    function endpoint() public view virtual override returns (address) {
        return address(_endpoint);
    }

    /**
     * @dev Returns the remote trusted contract address on chain `chainId`.
     */
    function remotes(uint16 chainId)
        public
        view
        virtual
        override
        returns (bytes memory)
    {
        return _remotes[chainId];
    }

    /**
     * @dev Returns the failed payload hash located by source chainId, source contract address, and nonce together
     */
    function failedPayloadHashs(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint256 nonce
    ) public view virtual returns (bytes32) {
        return _failedPayloadHashs[srcChainId][srcAddress][nonce];
    }

    /**
     * @dev Returns the minimum gas limit for cross chain operation
     */
    function minDestinationGasLimit() public view virtual returns (uint256) {
        return _minDestinationGasLimit;
    }

    /**
     * @dev Set the trusted remote contract of `remoteAddress` on `chainId` chain
     * @notice When remote contract has not invoked `setRemote()` for this contract,
     * invoke `pauseMove(chainId)` method before `setRemote()` to avoid avoid possible fund loss
     *
     * Requirements:
     *
     * - The remote contract must be ready to receive command
     *
     * Emits a {RemoteSet} event.
     */
    function setRemote(uint16 chainId, bytes calldata remoteAddress)
        external
        virtual
        onlyOwner
    {
        _remotes[chainId] = remoteAddress;
        emit RemoteSet(chainId, remoteAddress);
    }

    /**
     * @dev Set the minimum gas limit for cross chain operation
     */
    function setMinDestinationGasLimit(uint256 minDestinationGasLimit_)
        external
        virtual
        onlyOwner
    {
        _minDestinationGasLimit = minDestinationGasLimit_;
    }

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection,
     * and setting address of LayerZero endpoint on current chain
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address endpoint_
    ) ERC721(name_, symbol_) {
        _endpoint = ILayerZeroEndpoint(endpoint_);
    }

    /**
     * @dev Local action before move `tokenId` token to `dstChainId` chain
     */
    function _beforeMoveOut(
        address, // from
        uint16, // dstChainId
        bytes memory, // to
        uint256 tokenId
    ) internal virtual {
        // burn if move to other chain
        _burn(tokenId);
    }

    /**
     * @dev Local action after `tokenId` token from `srcChainId` chain send to `to`
     */
    function _afterMoveIn(
        uint16, // srcChainId
        address to,
        uint256 tokenId
    ) internal virtual {
        // erc721 cannot mint to zero address
        if (to == address(0x0)) {
            to = address(0xdEaD);
        }
        // mint when receive from other chain
        _safeMint(to, tokenId);
    }

    /**
     * @dev check whether the destination gas limit set by users is too low
     * if do not check the adapterParams, users can stuck the receiver by input low destination gas limit even with nonBlocking extension
     */
    function _gasGuard(bytes memory adapterParams) internal virtual {
        require(
            adapterParams.length == 34 || adapterParams.length > 66,
            "ERC721-O: wrong adapterParameters size"
        );
        uint16 txType;
        uint256 extraGas;
        assembly {
            txType := mload(add(adapterParams, 2))
            extraGas := mload(add(adapterParams, 34))
        }
        require(
            extraGas >= _minDestinationGasLimit,
            "ERC721-O: destination gas limit too low"
        );
    }

    /**
     * @dev See {IERC721_O-moveFrom}.
     */
    function moveFrom(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) external payable virtual override {
        _move(
            from,
            dstChainId,
            to,
            tokenId,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );
    }

    /**
     * @dev  Move `tokenId` token from `from` address on the current chain to `to` address on the `dstChainId` chain.
     * Internal function of {moveFrom}
     * See {IERC721_O-moveFrom}
     */
    function _move(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address zroPaymentAddress,
        bytes calldata adapterParams
    ) internal virtual {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721-O: move caller is not owner or approved"
        );
        // only send message to exist remote contract`
        require(
            _remotes[dstChainId].length > 0,
            "ERC721-O: no remote contract on destination chain"
        );
        // revert if the destination gas limit is lower than `_minDestinationGasLimit`
        _gasGuard(adapterParams);

        _beforeMoveOut(from, dstChainId, to, tokenId);

        // abi.encode() the payload
        bytes memory payload = abi.encode(to, tokenId);

        // send message via LayerZero
        _endpoint.send{value: msg.value}(
            dstChainId,
            _remotes[dstChainId],
            payload,
            refundAddress,
            zroPaymentAddress,
            adapterParams
        );

        // track the LayerZero nonce
        uint64 nonce = _endpoint.getOutboundNonce(dstChainId, address(this));

        emit MoveOut(dstChainId, from, to, tokenId, nonce);
    }

    /**
     * @dev  See {IERC721OReceiver - lzReceive}
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes memory payload
    ) external virtual override {
        // lzReceive must only be called by the endpoint
        require(msg.sender == address(_endpoint));
        // only receive message from `_remotes`
        require(
            srcAddress.length == _remotes[srcChainId].length &&
                keccak256(srcAddress) == keccak256(_remotes[srcChainId]),
            "ERC721-O: invalid source contract"
        );

        // catch all exceptions to avoid failed messages blocking message path
        try this.onLzReceive(srcChainId, nonce, payload) {
            // pass if succeed
        } catch {
            _failedPayloadHashs[srcChainId][srcAddress][nonce] = keccak256(
                payload
            );
            emit MoveInFailed(srcChainId, srcAddress, nonce, payload);
        }
    }

    /**
     * @dev Invoked by internal transcation to handle lzReceive logic
     */
    function onLzReceive(
        uint16 srcChainId,
        uint64 nonce,
        bytes memory payload
    ) public virtual {
        // only allow internal transaction
        require(
            msg.sender == address(this),
            "ERC721-O: only internal transcation allowed"
        );

        // decode the payload
        (bytes memory to, uint256 tokenId) = abi.decode(
            payload,
            (bytes, uint256)
        );

        address toAddress;
        // get toAddress from bytes
        assembly {
            toAddress := mload(add(to, 20))
        }

        _afterMoveIn(srcChainId, toAddress, tokenId);

        emit MoveIn(srcChainId, toAddress, tokenId, nonce);
    }

    /**
     * @dev Retry local stored failed messages
     */
    function retryMessage(
        uint16 srcChainId,
        bytes memory srcAddress,
        uint64 nonce,
        bytes calldata payload
    ) external payable {
        // assert there is message to retry
        bytes32 payloadHash = _failedPayloadHashs[srcChainId][srcAddress][
            nonce
        ];
        require(payloadHash != bytes32(0), "ERC721-O: no stored message");
        require(keccak256(payload) == payloadHash, "ERC721-O: invalid payload");
        // clear the stored message
        _failedPayloadHashs[srcChainId][srcAddress][nonce] = bytes32(0);
        // execute the message. revert if it fails again
        this.onLzReceive(srcChainId, nonce, payload);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setConfig}.
     */
    function setConfig(
        uint16 version,
        uint16 chainId,
        uint256 configType,
        bytes calldata config
    ) external virtual override onlyOwner {
        _endpoint.setConfig(version, chainId, configType, config);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setSendVersion}.
     */
    function setSendVersion(uint16 version)
        external
        virtual
        override
        onlyOwner
    {
        _endpoint.setSendVersion(version);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-setReceiveVersion}.
     */
    function setReceiveVersion(uint16 version)
        external
        virtual
        override
        onlyOwner
    {
        _endpoint.setReceiveVersion(version);
    }

    /**
     * @dev See {ILayerZeroUserApplicationConfig-forceResumeReceive}.
     * Warning: force resume will clear the failed payload and may cause fund loss
     */
    function forceResumeReceive(
        uint16 srcChainId,
        bytes calldata srcContractAddress
    ) external virtual override onlyOwner {
        _endpoint.forceResumeReceive(srcChainId, srcContractAddress);
    }
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

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @dev Interface of the ERC721-O (Omnichain Non-Fungible Token standard)
 */
interface IERC721O is IERC721 {
    /**
     * @dev Emitted when `tokenId` token is sent from `from` on current chain to `to` on `dstChainId` chain.
     */
    event MoveOut(
        uint16 dstChainId,
        address indexed from,
        bytes indexed to,
        uint256 indexed tokenId,
        uint64 nouce
    );

    /**
     * @dev Emitted when `tokenId` token on `srcChainId` chain send to `to` on current chain.
     */
    event MoveIn(
        uint16 srcChainId,
        address indexed to,
        uint256 indexed tokenId,
        uint64 nouce
    );

    /**
     * @dev Move `tokenId` token from `from` address on the current chain to `to` address on the `dstChainId` chain.

     * WARNING:  This action will BURN/Lock the token on the current chain,
     * and then message to the contract on destination chain to MINT/UNLOCK one. 
     * If the contract on destination chain is not ready to receive the command, fund can LOST permanently.
     *
     * Requirements:
     *
     * -  Receiver contract on the `dstChainId` chain must be ready to receive the move command on the destination chain.
     * - `dstChainId` and receiver contract address must be setted in `remotes`.
     * -  msg.value must equal or bigger than the total gas fee for cross chain operation.
     * - `tokenId` must exist.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * @param from the owner of `tokenId`
     * @param dstChainId the destination chain identifier (use the chainId defined in endpoint rather than general EVM chainId)
     * @param to the address on destination chain (in bytes). address length/format may vary by chains
     * @param tokenId uint256 ID of the token to be moved
     * @param refundAddress if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
     * @param tokenPaymentAddress the address of payment token (eg. ZRO) holder who would pay for the transaction
     * (use address(0x0) to pay by native gas token (eg. ether) only)
     * @param adapterParams parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
     *
     * Emits a {MoveOut} event.
     */
    function moveFrom(
        address from,
        uint16 dstChainId,
        bytes calldata to,
        uint256 tokenId,
        address payable refundAddress,
        address tokenPaymentAddress,
        bytes calldata adapterParams
    ) external payable;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Metadata extension of the ERC721-O (Omnichain Non-Fungible Token standard)
 */
interface IERC721OMetadata {
    /**
     * @dev Returns the address of cross chain endpoint
     */
    function endpoint() external view returns (address);

    /**
     * @dev Returns the remote trusted contract address on chain `chainId`.
     */
    function remotes(uint16 chainId) external view returns (bytes memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.5.0;

interface IERC721OReceiver {
    /**
     * @dev Receive message with `payload` from `from` on `srcChainId` chain.
     *
     * LayerZero endpoint will invoke this function to deliver the message on the destination.
     * When source sending contract invoke move(), destination contract handle the MINT/UNLOCK logic here.
     *
     * Requirements:
     *
     * - `srcChainId` and source sending contract must be setted in `remotes`
     *
     *
     * @param srcChainId the source chain identifier (use the chainId defined in LayerZero rather than general EVM chainId)
     * @param from the source sending contract address from the source chain
     * @param nonce the ordered message nonce of LayerZero endpoint
     * @param payload a custom bytes payload sent by the source sending contract
     *
     * Emits a {MoveIn} event.
     */
    function lzReceive(
        uint16 srcChainId,
        bytes memory from,
        uint64 nonce,
        bytes memory payload
    ) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(
        uint16 _version,
        uint16 _chainId,
        uint256 _configType,
        bytes calldata _config
    ) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress)
        external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

import "./ILayerZeroUserApplicationConfig.sol";

interface ILayerZeroEndpoint is ILayerZeroUserApplicationConfig {
    // @notice send a LayerZero message to the specified address at a LayerZero endpoint.
    // @param _dstChainId - the destination chain identifier
    // @param _destination - the address on destination chain (in bytes). address length/format may vary by chains
    // @param _payload - a custom bytes payload to send to the destination contract
    // @param _refundAddress - if the source transaction is cheaper than the amount of value passed, refund the additional amount to this address
    // @param _zroPaymentAddress - the address of the ZRO token holder who would pay for the transaction
    // @param _adapterParams - parameters for custom functionality. e.g. receive airdropped native gas from the relayer on destination
    function send(
        uint16 _dstChainId,
        bytes calldata _destination,
        bytes calldata _payload,
        address payable _refundAddress,
        address _zroPaymentAddress,
        bytes calldata _adapterParams
    ) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        address _dstAddress,
        uint64 _nonce,
        uint256 _gasLimit,
        bytes calldata _payload
    ) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress)
        external
        view
        returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(
        uint16 _dstChainId,
        address _userApplication,
        bytes calldata _payload,
        bool _payInZRO,
        bytes calldata _adapterParam
    ) external view returns (uint256 nativeFee, uint256 zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(
        uint16 _srcChainId,
        bytes calldata _srcAddress,
        bytes calldata _payload
    ) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress)
        external
        view
        returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication)
        external
        view
        returns (address);

    // @notice query if the non-reentrancy guard for send() is on
    // @return true if the guard is on. false otherwise
    function isSendingPayload() external view returns (bool);

    // @notice query if the non-reentrancy guard for receive() is on
    // @return true if the guard is on. false otherwise
    function isReceivingPayload() external view returns (bool);

    // @notice get the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _userApplication - the contract address of the user application
    // @param _configType - type of configuration. every messaging library has its own convention.
    function getConfig(
        uint16 _version,
        uint16 _chainId,
        address _userApplication,
        uint256 _configType
    ) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication)
        external
        view
        returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication)
        external
        view
        returns (uint16);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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