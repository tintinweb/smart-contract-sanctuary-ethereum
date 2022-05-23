// SPDX-License-Identifier: MIT
// NFTZero Contracts v0.0.1

pragma solidity ^0.8.7;

import "../interfaces/IOmniERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./NonblockingLzApp.sol";

contract TokenFactory is NonblockingLzApp {

    event Minted(address collAddr, address rec);
    event Paid(address rec);
    event Locked(address rec, uint256 amount, address asset);
    event Refunded(address rec);
    event OnResponse(address rec, address cre, uint256 amount);
    event NewRefund(address collAddr, address spender);
    event InvalidPrice(address collAddr, address spender, uint256 paid);
    event InvalidCreator(address collAddr, address cre);
    event FailedResponse(string reason, uint256 chId);

    address[] public assets;
    mapping(string => uint256) private _chToId;
    mapping (address => mapping (uint16 => mapping (address => uint256))) public refunds; // coll -> chId -> spender -> price
    mapping (address => mapping (uint16 => uint256)) public mints; // coll -> chId -> count
    address private _owner;
    uint256 private _contractChainId;
    address private _treasury;

    constructor(address _lzEndpoint) NonblockingLzApp(_lzEndpoint) {
        _contractChainId = 10001;
        _owner = msg.sender;
        _treasury = address(0x2fAAAa87963fdE26B42FB5CedB35a502d3ee09B3);
    }

    function addBaseAsset(address asset) onlyOwner external {
        assets.push(asset);
    }

    function setChain(string memory symbol, uint256 id) onlyOwner external {
        _chToId[symbol] = id;
    }

    function mintToken(
        string memory chSym,
        address coll,
        uint256 mintPrice,
        address creator,
        uint256 gas,
        uint256 nativeGas
    ) public payable {
        require(bytes(chSym).length > 0 && coll != address(0));
        require(_chToId[chSym] > 0);
        uint16 chId = uint16(_chToId[chSym]);
        if (_chToId[chSym] == _contractChainId) {
            IOmniERC721 omniNft = IOmniERC721(coll);
            uint256 price = omniNft.getMintPrice();
            if (price > 0) {
                payOnMint(price, msg.sender, omniNft.getCreator(), false);
            }
            omniNft.mint(msg.sender);
            emit Minted(coll, msg.sender);
            return;
        }
        if (mintPrice > 0) {
            payOnMint(mintPrice, msg.sender, address(this), true);
        }
        bytes memory payload = _getMintPayload(coll, mintPrice, creator);
        _lzAction(payload, chId, gas, nativeGas);
    }

    function _nonblockingLzReceive(
        uint16 srcId,
        bytes memory src,
        uint64,
        bytes memory _payload
    ) internal override {
        require(this.isTrustedRemote(srcId, src));
        (uint256 act, address coll, bool minted, uint256 paid, address rec, address cre) = abi.decode(_payload, (uint256, address, bool, uint256, address, address));
        if (act != 1) {
            pay(rec, cre, paid, minted);
            return;
        }
        IOmniERC721 nft = IOmniERC721(coll);
        uint256 price = nft.getMintPrice();
        uint256 supply = nft.getMaxSupply();
        if (price > 0 && (supply > 0 && nft.getMintedCount() >= supply)) {
            emit NewRefund(coll, rec);
            refunds[coll][srcId][rec] += price;
            return;
        }
        if (cre != nft.getCreator()) {
            emit InvalidCreator(coll, cre);
            return;
        }

        if (price > 0 && paid < price) {
            emit InvalidPrice(coll, rec, paid);
            return;
        }

        nft.mint(rec);
        emit Minted(coll, rec);
        mints[coll][srcId]++;
    }

    function refund(address coll, uint16 chId, uint256 gas) external payable {
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 amount = refunds[coll][chId][msg.sender];
        require(collection.getMintPrice() > 0 && amount > 0);
        refunds[coll][chId][msg.sender] = 0;
        _resAction(_getResPayload(coll, false, amount), chId, gas);
    }

    function getEarned(address coll, uint16 chId, uint256 gas) external payable {
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.getMintPrice();
        uint256 amount = mints[coll][chId] * price;
        require(price > 0 && amount > 0 && msg.sender == collection.getCreator());
        mints[coll][chId] = 0;
        _resAction(_getResPayload(coll, true, amount), chId, gas);
    }

    function _lzAction(bytes memory pload, uint16 chId, uint256 gas, uint256 nativeGas) private {
        bytes memory remote = this.getTrustedRemote(chId);
        bytes memory adapter = _getAdapter(gas, nativeGas, remote);

        lzEndpoint.send{value : msg.value}(
            chId,
            remote,
            pload,
            payable(msg.sender),
            address(0x0),
            adapter
        );
    }

    function _resAction(bytes memory payload, uint16 chId, uint256 gas) private {
        _lzAction(payload, chId, gas, 0);
    }

    function payOnMint(uint256 price, address spender, address rec, bool locked) internal {
        address asset = assets[0]; // TODO: Set asset per collection
        bool isSupported = isAssetSupported(asset);
        require(isSupported);
        IERC20 erc = IERC20(asset);
        require(erc.allowance(spender, address(this)) >= price);

        if (locked) {
            erc.transferFrom(spender, rec, price);
            emit Locked(rec, price, asset);
            return;
        }
        erc.transferFrom(spender, rec, price * 98 / 100);
        erc.transferFrom(spender, _treasury, price * 2 / 100);
        emit Paid(rec);
    }

    function pay(address rec, address cre, uint256 price, bool minted) private {
        emit OnResponse(rec, cre, price);

        if (price == 0) {
            return;
        }

        IERC20 erc = IERC20(assets[0]); // TODO: Set asset per collection and get from it
        if (minted) {
            erc.transfer(cre, price * 98 / 100);
            erc.transfer(_treasury, price * 2 / 100);
            emit Paid(cre);
            return;
        }
        erc.transfer(rec, price);
        emit Refunded(rec);
    }

    function unlockPayment(address coll, uint16 chId, bool minted, address rec) onlyOwner external {
        address asset = assets[0]; // TODO: Asset per collection
        bool isSupported = isAssetSupported(asset);
        IOmniERC721 collection = IOmniERC721(coll);
        uint256 price = collection.getMintPrice();
        uint256 amount = minted ? (mints[coll][chId] * price) : (refunds[coll][chId][rec]);
        uint256 startDate = collection.getFrom() > 0 ? collection.getFrom() : collection.getCreatedAt();
        require(isSupported && price > 0 && amount > 0 && startDate <= (block.timestamp - 14 days));
        IERC20 erc = IERC20(asset);
        erc.transferFrom(_treasury, rec, amount);

        if (minted) {
            emit Paid(rec);
            return;
        }
        emit Refunded(rec);
    }

    function isAssetSupported(address asset) public view returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            if (asset == assets[i]) {
                return true;
            }
        }
        return false;
    }

    function estimateFees(string memory chSym, uint256 price, uint256 gas, uint256 nativeGas) external view returns (uint) {
        address mockAddr = address(this);
        bytes memory payload = _getMintPayload(mockAddr, price, mockAddr);
        uint16 chId = uint16(_chToId[chSym]);
        bytes memory remote = this.getTrustedRemote(chId);
        bytes memory adapter = _getAdapter(gas, nativeGas, remote);
        (uint fee,) = lzEndpoint.estimateFees(chId, mockAddr, payload, false, adapter);

        return fee;
    }

    function _getMintPayload(address coll, uint256 price, address cre) private view returns (bytes memory) {
        return abi.encode(1, coll, true, price, msg.sender, cre);
    }

    function _getResPayload(address coll, bool minted, uint256 amount) private view returns (bytes memory) {
        return abi.encode(2, coll, minted, amount, msg.sender, msg.sender);
    }

    function _getAdapter(uint gas, uint256 nativeGas, bytes memory remote) private pure returns (bytes memory) {
        if (gas == 0) {
            return bytes("");
        }

        if (nativeGas == 0) {
            uint16 v1 = 1;
            return abi.encodePacked(v1, gas);
        }

        uint16 v2 = 2;
        return abi.encodePacked(v2, gas, nativeGas, remote);
    }

    receive() external payable {}
}

pragma solidity ^0.8.7;

interface IOmniERC721 {
    function mint(address owner) external;
    function getMintPrice() external view returns (uint256);
    function getMaxSupply() external view returns (uint256);
    function getMintedCount() external view returns (uint256);
    function getCreator() external view returns (address);
    function getCreatedAt() external view returns (uint256);
    function getFrom() external view returns (uint256);
    function getAddress() external view returns (address);
    function getDetails() external view returns (string memory, address, uint256, uint256, uint256);
    function setFileURI(string memory fileURI) external;
    function setDates(uint256 _from, uint256 _to) external;
    function addMetadataURIs(string[] memory _metadataURIs) external;
    function setHidden(bool _hidden) external;
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

pragma solidity ^0.8.0;

import "./LzApp.sol";

abstract contract NonblockingLzApp is LzApp {
    constructor(address _endpoint) LzApp(_endpoint) {}

    mapping(uint16 => mapping(bytes => mapping(uint => bytes32))) public failedMessages;

    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);

    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual override {
        try this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
        } catch {
            failedMessages[_srcChainId][_srcAddress][_nonce] = keccak256(_payload);
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public virtual {
        require(_msgSender() == address(this));
        _nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function _nonblockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable virtual {
        bytes32 payloadHash = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(payloadHash != bytes32(0));
        require(keccak256(_payload) == payloadHash);
        failedMessages[_srcChainId][_srcAddress][_nonce] = bytes32(0);
        this.nonblockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/ILayerZeroReceiver.sol";
import "../interfaces/ILayerZeroUserApplicationConfig.sol";
import "../interfaces/ILayerZeroEndpoint.sol";

/*
 * a generic LzReceiver implementation
 */
abstract contract LzApp is Ownable, ILayerZeroReceiver, ILayerZeroUserApplicationConfig {
    ILayerZeroEndpoint internal immutable lzEndpoint;

    mapping(uint16 => bytes) internal trustedRemoteLookup;

    event SetTrustedRemote(uint16 _srcChainId, bytes _srcAddress);

    constructor(address _endpoint) {
        lzEndpoint = ILayerZeroEndpoint(_endpoint);
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external override {
        // lzReceive must be called by the endpoint for security
        require(_msgSender() == address(lzEndpoint));
        // if will still block the message pathway from (srcChainId, srcAddress). should not receive message from untrusted remote.
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), "LzReceiver: invalid source sending contract");

        _blockingLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    // abstract function - the default behaviour of LayerZero is blocking. See: NonblockingLzApp if you dont need to enforce ordered messaging
    function _blockingLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) internal virtual;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _adapterParam) internal {
        require(trustedRemoteLookup[_dstChainId].length != 0, "LzSend: destination chain is not a trusted source.");
        lzEndpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _adapterParam);
    }

    //---------------------------UserApplication config----------------------------------------
    function getConfig(uint16, uint16 _chainId, address, uint _configType) external view returns (bytes memory) {
        return lzEndpoint.getConfig(lzEndpoint.getSendVersion(address(this)), _chainId, address(this), _configType);
    }

    // generic config for LayerZero user Application
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external override onlyOwner {
        lzEndpoint.setConfig(_version, _chainId, _configType, _config);
    }

    function setSendVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setSendVersion(_version);
    }

    function setReceiveVersion(uint16 _version) external override onlyOwner {
        lzEndpoint.setReceiveVersion(_version);
    }

    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external override onlyOwner {
        lzEndpoint.forceResumeReceive(_srcChainId, _srcAddress);
    }

    // allow owner to set it multiple times.
    function setTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external onlyOwner {
        trustedRemoteLookup[_srcChainId] = _srcAddress;
        emit SetTrustedRemote(_srcChainId, _srcAddress);
    }

    function isTrustedRemote(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool) {
        bytes memory trustedSource = trustedRemoteLookup[_srcChainId];
        return keccak256(trustedSource) == keccak256(_srcAddress);
    }

    //--------------------------- VIEW FUNCTION ----------------------------------------
    // interacting with the LayerZero Endpoint and remote contracts

    function getTrustedRemote(uint16 _chainId) external view returns (bytes memory) {
        return trustedRemoteLookup[_chainId];
    }

    function getLzEndpoint() external view returns (address) {
        return address(lzEndpoint);
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

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroReceiver {
    // @notice LayerZero endpoint will invoke this function to deliver the message on the destination
    // @param _srcChainId - the source endpoint identifier
    // @param _srcAddress - the source sending contract address from the source chain
    // @param _nonce - the ordered message nonce
    // @param _payload - the signed payload is the UA bytes has encoded to be sent
    function lzReceive(uint16 _srcChainId, bytes calldata _srcAddress, uint64 _nonce, bytes calldata _payload) external;
}

// SPDX-License-Identifier: BUSL-1.1

pragma solidity >=0.5.0;

interface ILayerZeroUserApplicationConfig {
    // @notice set the configuration of the LayerZero messaging library of the specified version
    // @param _version - messaging library version
    // @param _chainId - the chainId for the pending config change
    // @param _configType - type of configuration. every messaging library has its own convention.
    // @param _config - configuration in the bytes. can encode arbitrary content.
    function setConfig(uint16 _version, uint16 _chainId, uint _configType, bytes calldata _config) external;

    // @notice set the send() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setSendVersion(uint16 _version) external;

    // @notice set the lzReceive() LayerZero messaging library version to _version
    // @param _version - new messaging library version
    function setReceiveVersion(uint16 _version) external;

    // @notice Only when the UA needs to resume the message flow in blocking mode and clear the stored payload
    // @param _srcChainId - the chainId of the source chain
    // @param _srcAddress - the contract address of the source contract at the source chain
    function forceResumeReceive(uint16 _srcChainId, bytes calldata _srcAddress) external;
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
    function send(uint16 _dstChainId, bytes calldata _destination, bytes calldata _payload, address payable _refundAddress, address _zroPaymentAddress, bytes calldata _adapterParams) external payable;

    // @notice used by the messaging library to publish verified payload
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source contract (as bytes) at the source chain
    // @param _dstAddress - the address on destination chain
    // @param _nonce - the unbound message ordering nonce
    // @param _gasLimit - the gas limit for external contract execution
    // @param _payload - verified payload to send to the destination contract
    function receivePayload(uint16 _srcChainId, bytes calldata _srcAddress, address _dstAddress, uint64 _nonce, uint _gasLimit, bytes calldata _payload) external;

    // @notice get the inboundNonce of a receiver from a source chain which could be EVM or non-EVM chain
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function getInboundNonce(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (uint64);

    // @notice get the outboundNonce from this source chain which, consequently, is always an EVM
    // @param _srcAddress - the source chain contract address
    function getOutboundNonce(uint16 _dstChainId, address _srcAddress) external view returns (uint64);

    // @notice gets a quote in source native gas, for the amount that send() requires to pay for message delivery
    // @param _dstChainId - the destination chain identifier
    // @param _userApplication - the user app address on this EVM chain
    // @param _payload - the custom message to send over LayerZero
    // @param _payInZRO - if false, user app pays the protocol fee in native token
    // @param _adapterParam - parameters for the adapter service, e.g. send some dust native token to dstChain
    function estimateFees(uint16 _dstChainId, address _userApplication, bytes calldata _payload, bool _payInZRO, bytes calldata _adapterParam) external view returns (uint nativeFee, uint zroFee);

    // @notice get this Endpoint's immutable source identifier
    function getChainId() external view returns (uint16);

    // @notice the interface to retry failed message on this Endpoint destination
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    // @param _payload - the payload to be retried
    function retryPayload(uint16 _srcChainId, bytes calldata _srcAddress, bytes calldata _payload) external;

    // @notice query if any STORED payload (message blocking) at the endpoint.
    // @param _srcChainId - the source chain identifier
    // @param _srcAddress - the source chain contract address
    function hasStoredPayload(uint16 _srcChainId, bytes calldata _srcAddress) external view returns (bool);

    // @notice query if the _libraryAddress is valid for sending msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getSendLibraryAddress(address _userApplication) external view returns (address);

    // @notice query if the _libraryAddress is valid for receiving msgs.
    // @param _userApplication - the user app address on this EVM chain
    function getReceiveLibraryAddress(address _userApplication) external view returns (address);

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
    function getConfig(uint16 _version, uint16 _chainId, address _userApplication, uint _configType) external view returns (bytes memory);

    // @notice get the send() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getSendVersion(address _userApplication) external view returns (uint16);

    // @notice get the lzReceive() LayerZero messaging library version
    // @param _userApplication - the contract address of the user application
    function getReceiveVersion(address _userApplication) external view returns (uint16);
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