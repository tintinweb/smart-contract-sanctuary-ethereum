/**
 *Submitted for verification at Etherscan.io on 2022-06-12
*/

// SPDX-License-Identifier: MIT
// Made with love by Mai
pragma solidity >=0.8.14;

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

error CallerNotOwner();
error NewOwnerAddressZero();

abstract contract ERC721Omni {
    using Address for address;
    using Strings for uint256;

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event MessageFailed(uint16 _srcChainId, bytes _srcAddress, uint64 _nonce, bytes _payload);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    string public name;
    string public symbol;
    address public owner;
    ILayerZeroEndpoint internal endpoint;

    struct FailedMessages {
        uint payloadLength;
        bytes32 payloadHash;
    }

    struct addressData {
        uint128 balance;
        uint128 huntlistMinted;
    }

    struct tokenData {
        address tokenHolder;
        uint96 timestampHolder;//Maybe if you guys like your hunters we can do cool stuff with this
    }

    mapping(uint256 => tokenData) internal _ownerOf;
    mapping(address => addressData) internal _addressData;

    mapping(uint16 => mapping(bytes => mapping(uint => FailedMessages))) public failedMessages;
    mapping(uint16 => bytes) public trustedRemoteLookup;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        _transferOwnership(msg.sender);
    }

    function ownerOf(uint256 id) public view virtual returns (address) {
        require(_ownerOf[id].tokenHolder != address(0), "Nonexistent Token");
        return _ownerOf[id].tokenHolder;
    }

    function balanceOf(address _owner) public view virtual returns (uint256) {
        require(_owner != address(0), "Zero Address");
        return _addressData[_owner].balance;
    }

    function durationTimestamp(uint256 tokenId) public view virtual returns (uint256) {
        return _ownerOf[tokenId].timestampHolder;
    }

    function huntlistMinted(address _owner) public view virtual returns (uint256) {
        require(_owner != address(0), "Zero Address");
        return _addressData[_owner].huntlistMinted;
    }

    function transferFrom(address from, address to, uint256 tokenId) public {
        require(from == _ownerOf[tokenId].tokenHolder, "Non Owner");
        require(to != address(0), "Zero Address");

        require(msg.sender == from || isApprovedForAll[from][msg.sender] || msg.sender == getApproved[tokenId],
            "Lacks Permissions"
        );

        unchecked {
            _addressData[from].balance--;
            _addressData[to].balance++;
        }

        _ownerOf[tokenId].tokenHolder = to;
        _ownerOf[tokenId].timestampHolder = uint96(block.timestamp);
        delete getApproved[tokenId];
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        transferFrom(from, to, tokenId);

        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "Unsafe Transfer"
        );
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) public {
        transferFrom(from, to, tokenId);

        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, from, tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "Unsafe Transfer"
        );
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function approve(address spender, uint256 tokenId) public {
        address _owner = _ownerOf[tokenId].tokenHolder;
        require(msg.sender == _owner || isApprovedForAll[_owner][msg.sender], "Lacks Permissions");

        getApproved[tokenId] = spender;
        emit Approval(_owner, spender, tokenId);
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "Zero Address");
        require(_ownerOf[tokenId].tokenHolder == address(0), "Already Exists");

        unchecked {
            _addressData[to].balance++;
        }

        _ownerOf[tokenId].tokenHolder = to;
        _ownerOf[tokenId].timestampHolder = uint96(block.timestamp);
        emit Transfer(address(0), to, tokenId);
    }

    function _safeMint(address to, uint256 tokenId) internal {
        _mint(to, tokenId);

        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "Unsafe Mint"
        );
    }

    function _safeMint(address to, uint256 tokenId, bytes memory data) internal {
        _mint(to, tokenId);

        require(to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(msg.sender, address(0), tokenId, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "Unsafe Mint"
        );
    }

    function _burn(uint256 tokenId) internal {
        address _owner = _ownerOf[tokenId].tokenHolder;
        require(_owner != address(0), "Nonexistent Token");

        unchecked {
            _addressData[_owner].balance--;
        }

        delete _ownerOf[tokenId];
        delete getApproved[tokenId];

        emit Transfer(_owner, address(0), tokenId);
    }

    function baseURI() public view virtual returns (string memory) {
        return '';
    }

    function tokenURI(uint256 tokenId) public view returns (string memory) {
        require(_ownerOf[tokenId].tokenHolder != address(0), "Nonexistent Token");
        string memory _baseURI = baseURI();
        return bytes(_baseURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenId.toString())) : '';
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x5b5e139f;
    }

    function lzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) external {
        require(msg.sender == address(endpoint)); 
        require(_srcAddress.length == trustedRemoteLookup[_srcChainId].length && keccak256(_srcAddress) == keccak256(trustedRemoteLookup[_srcChainId]), 
            "NonblockingReceiver: invalid source sending contract");

        try this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload) {
        } catch {
            failedMessages[_srcChainId][_srcAddress][_nonce] = FailedMessages(_payload.length, keccak256(_payload));
            emit MessageFailed(_srcChainId, _srcAddress, _nonce, _payload);
        }
    }

    function onLzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) public {
        require(msg.sender == address(this), "NonblockingReceiver: caller must be Bridge.");
        _LzReceive( _srcChainId, _srcAddress, _nonce, _payload);
    }

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) virtual internal;

    function _lzSend(uint16 _dstChainId, bytes memory _payload, address payable _refundAddress, address _zroPaymentAddress, bytes memory _txParam) internal {
        endpoint.send{value: msg.value}(_dstChainId, trustedRemoteLookup[_dstChainId], _payload, _refundAddress, _zroPaymentAddress, _txParam);
    }

    function retryMessage(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes calldata _payload) external payable {
        FailedMessages storage failedMsg = failedMessages[_srcChainId][_srcAddress][_nonce];
        require(failedMsg.payloadHash != bytes32(0), "NonblockingReceiver: no stored message");
        require(_payload.length == failedMsg.payloadLength && keccak256(_payload) == failedMsg.payloadHash, "LayerZero: invalid payload");
        failedMsg.payloadLength = 0;
        failedMsg.payloadHash = bytes32(0);
        this.onLzReceive(_srcChainId, _srcAddress, _nonce, _payload);
    }

    function setTrustedRemote(uint16 _chainId, bytes calldata _trustedRemote) external onlyOwner {
        trustedRemoteLookup[_chainId] = _trustedRemote;
    }

    function renounceOwnership() public onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) revert NewOwnerAddressZero();
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        address oldOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    modifier onlyOwner() {
        if (owner != msg.sender) revert CallerNotOwner();
        _;
    }

}

abstract contract ERC721TokenReceiver {
    function onERC721Received(address, address, uint256, bytes calldata) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

contract Cyber is ERC721Omni {

    string private _baseURI = "ipfs://QmS84uLAUvGLverNnvyU8YhsHKJi6E3WnfvuD7qmRmBos2/";
    uint256 private constant maximumSupply = 6600;
    uint256 public publicMintedCap = 1980;

    uint256 public totalSupply;
    uint256 public publicMinted;
    uint256 public gasForLzReceive = 350000;
    bool public depreciatedMint;
    bool public publicStatus;
    bool public huntlistStatus;
    bytes32 public merkleRoot = 0xd6fbbe52742f9b344f0cec438e6e560e182c4aec6a42bbf8e944f227632ba0b3;

    constructor(address _lzEndpoint) ERC721Omni("Cyber", "Hunters") { 
        endpoint = ILayerZeroEndpoint(_lzEndpoint); 
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, "Contract Caller");
        _;
    }

    function donate() external payable {
        // thank you friend!
    }

    function traverseChains(uint16 _chainId, uint tokenId) public payable {
        require(msg.sender == ownerOf(tokenId), "You must own the token to traverse");
        require(trustedRemoteLookup[_chainId].length > 0, "This chain is currently unavailable for travel");

        _burn(tokenId);
        totalSupply--;

        bytes memory payload = abi.encode(msg.sender, tokenId);
        uint16 version = 1;
        bytes memory adapterParams = abi.encodePacked(version, gasForLzReceive);

        (uint messageFee, ) = endpoint.estimateFees(_chainId, address(this), payload, false, adapterParams);
        
        require(msg.value >= messageFee, "msg.value cannot cover messageFee. Requires additional gas");

        endpoint.send{value: msg.value}(
            _chainId,                           // Endpoint chainId
            trustedRemoteLookup[_chainId],      // Endpoint contract
            payload,                            // Encoded bytes
            payable(msg.sender),                // Excess fund destination address
            address(0x0),                       // Unused
            adapterParams                       // Transaction Parameters 
        );
    }

    function _LzReceive(uint16 _srcChainId, bytes memory _srcAddress, uint64 _nonce, bytes memory _payload) override internal {
        (address toAddr, uint tokenId) = abi.decode(_payload, (address, uint));
        _mint(toAddr, tokenId);
        totalSupply++;
    }

    function publicMint() external callerIsUser {
        require(publicStatus, "Public mint not active");
        require(totalSupply < maximumSupply, "Will exceed maximum supply");

        unchecked {
            require(publicMinted++ < publicMintedCap, "Public supply depleted");
            _mint(msg.sender, totalSupply++);
        }
   }

   function huntlistMint(bytes32[] calldata _proof) external callerIsUser {
       require(huntlistStatus, "Huntlist mint not active");
        require(verifyProof(_proof, merkleRoot, keccak256(abi.encodePacked(msg.sender))), "Not on Huntlist");
        uint256 temporarySupply = totalSupply;
        unchecked {
            require(temporarySupply + 1 < maximumSupply, "Will exceed max supply");
            require(_addressData[msg.sender].huntlistMinted == 0, "Insufficient Mints Remaining");
            _addressData[msg.sender].huntlistMinted += uint128(2);
        }
        _mint(msg.sender, temporarySupply++);
        _mint(msg.sender, temporarySupply++);
        totalSupply = temporarySupply;
   }

   function verifyProof(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        uint256 iterations = proof.length;
        for (uint256 i; i < iterations; ) {
            bytes32 proofElement = proof[i++];

            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }

        }
        return computedHash == root;
    }

    function burnHunter(uint256 tokenId) external {
       require(depreciatedMint, "Mint is still active.");
       require(msg.sender == ownerOf(tokenId) || isApprovedForAll[ownerOf(tokenId)][msg.sender] || msg.sender == getApproved[tokenId], "Lacks Permissions");
       _burn(tokenId);
       totalSupply--;
   }

   function setPublicState(bool _state) external onlyOwner {
       require(!depreciatedMint, "Mint is depreciated.");
       publicStatus = _state;
   }

   function setHuntlistState(bool _state) external onlyOwner {
       require(!depreciatedMint, "Mint is depreciated.");
       huntlistStatus = _state;
   }

   function setPublicMintSupply(uint256 _supply) external onlyOwner {
       require(!depreciatedMint, "Mint is depreciated.");
       require(_supply > publicMintedCap, "Cannot reduce mint supply");
       require(_supply <= maximumSupply, "Cannot exceed maximum supply");
       publicMintedCap = _supply;
   }

  function setRoot(bytes32 _newROOT) external onlyOwner {
        merkleRoot = _newROOT;
    }

  function depreciateMint() external onlyOwner {
      require(!depreciatedMint, "Mint is already depreciated.");
      delete publicStatus;
      delete huntlistStatus;
      depreciatedMint = true;
      address deployer = msg.sender;
      uint256 timestamp = block.timestamp;

        for (uint256 i; i < 66; ){
            _ownerOf[i].tokenHolder = deployer;
            _ownerOf[i].timestampHolder = uint96(timestamp);
            unchecked {
                emit Transfer(address(0), deployer, i++);
            }
        }

        unchecked {
            _addressData[deployer].balance += 66;
            totalSupply += 66;
        }
  }

  function setBaseURI(string memory _newURI) external onlyOwner {
      _baseURI = _newURI;
  }

  function setGasForDestinationLzReceive(uint _newGasValue) external onlyOwner {
      gasForLzReceive = _newGasValue;
  }

  function setLzEndpoint(address _lzEndpoint) external onlyOwner {
      endpoint = ILayerZeroEndpoint(_lzEndpoint);
  }

  function baseURI() override public view returns (string memory) {
      return _baseURI;
  }

  function withdrawDonations() external onlyOwner {
      uint256 currentBalance = address(this).balance;
      (bool sent, ) = address(msg.sender).call{value: currentBalance}('');
      require(sent, "Transfer Error");    
  }

}