/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

contract Owned is Initializable{
    address public _owner;
    function __Owned_init(address owner) public initializer{
        _owner = owner;
    }
    event SetOwner(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner {
        require(msg.sender == _owner);
        _;
    }
    function setOwner(address newOwner) public onlyOwner {
        emit SetOwner(_owner, newOwner);
        _owner = newOwner;
    }
}

library LiteralStrings {
    function toLiteralString(bytes memory input) internal pure returns (string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory output = new bytes(2 + input.length * 2);
        output[0] = "0";
        output[1] = "x";
        for (uint256 i = 0; i < input.length; i++) {
            output[2 + i * 2] = alphabet[uint256(uint8(input[i] >> 4))];
            output[3 + i * 2] = alphabet[uint256(uint8(input[i] & 0x0f))];
        }
        return string(output);
    }
}



/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

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
            buffer[i] = alphabet[value & 0xf];
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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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


// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------
// -------------------------------------------------------------------------------------------------

contract JPNFTIpNetworkPoc is Owned {
    using Address for address;
    using LiteralStrings for bytes;
    using StringsUpgradeable for uint256;

    enum EntityType{
        GROUP, PERSON, MAX
    }
    enum NFTAuthenticationType{
        NONE, REQUEST, LINK, REJECT, UNLINK, CANCEL
    }

    struct IP {
        uint256 id;
        string name;
        bytes32 hash;
        string metaData;
        address owner;
        address operator;
        mapping(uint256 => Link[]) parent;        // k: parent IP id, v:link info. link info between current and parents.
        uint256 [] parentIds;                // parents array for find out parents collection.
        mapping(uint256 => Link[]) child;      // k: child IP id,  v:link info. link info between current and children.
        uint256 [] childIds;                 // children array for find out child collection.
        address [] nftContracts;
        mapping(address => ContractChain) nftContract; // k: erc721 smartcontract address,  v:erc721 smartcontract chain ids.
    }

    struct Signature {
        address singer;
        string func;
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Link {
        uint256 targetId;
        string metaData;
        bool isRequested;
        bool isSigned;
        uint256 fee;
        Signature signature;
    }

    struct NFTAuthentication {
        uint256 [] ips;
        mapping(uint256 => NFTAuthenticationUnit) ipAuthenticatedMapping; // k:IP v:Authentication.
    }

    struct NFTAuthenticationUnit {
        address applicant;
        NFTAuthenticationType authenticationType;
        uint256 fee;
    }

    struct ContractChain {
        bool isExists;
        uint256 [] chains;
        mapping(uint256 => bool) chainMap; 
    }

    uint256 _maxEntityId;

    // address _implNft;
    address _proxyAdmin;

    mapping(uint256 => IP) public _ipMapping;    // k:IP id, v:IP.
    mapping(bytes32 => NFTAuthentication) private _nftAuthenticationMapping;

    // event
    event Created(uint256 id, string name, string metaData);
    event Requested(uint256 from, uint256 to, uint256 linkId, string metaData, uint256 weiAmount);
    event Canceled(uint256 from, uint256 to, uint256 linkId, uint256 weiAmount);
    event Linked(uint256 from, uint256 to, uint256 linkId, uint256 weiAmount);
    event Rejected(uint256 from, uint256 to, uint256 linkId, uint256 weiAmount);
    event Unlinked(uint256 from, uint256 to, uint256 linkId);
    event LinkSignatureAdded(uint256 from, uint256 to, uint256 linkId);
    event RequestSignatureAdded(uint256 from, uint256 to, uint256 linkId);
    event NFTAuthenticate(uint256 chainId, address nftContract, uint256 nftId, uint256 ip, uint256 authenticateType);
    //    event Withdraw(bytes32 from, bytes32 to, uint256 weiAmount);

    modifier hasIp(uint256 _ip) {
        require((_ipMapping[_ip].id != 0), "this ip is not exists");
        _;
    }

    function initialize(address owner, address proxyAdmin) public initializer{
        __Owned_init(owner);
        _maxEntityId = 0;
        _proxyAdmin = proxyAdmin;
    }
    //
    function getParentCount(uint256 id) public view returns (uint){
        return (_ipMapping[id].parentIds.length);
    }

    function getParentLinkCountById(uint256 id, uint256 parentId) public view returns (uint){
        return (_ipMapping[id].parent[parentId].length);
    }

    function getParentLinkCountByIndex(uint256 id, uint index) public view returns (uint){
        uint256 parentId = _ipMapping[id].parentIds[index];
        return (_ipMapping[id].parent[parentId].length);
    }

    function getParentLinkById(uint256 id, uint256 parentId, uint256 linkId) public view returns (bool, bool, uint256, string memory){
        return (_ipMapping[id].parent[parentId][linkId].isRequested,
        _ipMapping[id].parent[parentId][linkId].isSigned,
        _ipMapping[id].parent[parentId][linkId].fee,
        _ipMapping[id].parent[parentId][linkId].metaData);
    }

    function getParentLinkByIndex(uint256 id, uint index, uint256 linkId) public view returns (uint256, bool, bool, uint256, string memory){
        uint256 parentId = _ipMapping[id].parentIds[index];
        return (parentId,
        _ipMapping[id].parent[parentId][linkId].isRequested,
        _ipMapping[id].parent[parentId][linkId].isSigned,
        _ipMapping[id].parent[parentId][linkId].fee,
        _ipMapping[id].parent[parentId][linkId].metaData);
    }

    function getChildCount(uint256 id) public view returns (uint){
        return (_ipMapping[id].childIds.length);
    }

    function getChildLinkCountById(uint256 id, uint256 childId) public view returns (uint){
        return (_ipMapping[id].child[childId].length);
    }

    function getChildLinkCountByIndex(uint256 id, uint index) public view returns (uint){
        uint256 childId = _ipMapping[id].childIds[index];
        return (_ipMapping[id].child[childId].length);
    }

    function getChildLinkById(uint256 id, uint256 childId, uint256 linkId) public view returns (bool, bool, uint256, string memory){
        return (_ipMapping[id].child[childId][linkId].isRequested,
        _ipMapping[id].child[childId][linkId].isSigned,
        _ipMapping[id].child[childId][linkId].fee,
        _ipMapping[id].child[childId][linkId].metaData);
    }

    function getChildLinkByIndex(uint256 id, uint index, uint256 linkId) public view returns (uint256, bool, bool, uint256, string memory){
        uint256 childId = _ipMapping[id].childIds[index];
        return (childId,
        _ipMapping[id].child[childId][linkId].isRequested,
        _ipMapping[id].child[childId][linkId].isSigned,
        _ipMapping[id].child[childId][linkId].fee,
        _ipMapping[id].child[childId][linkId].metaData);
    }

    function getIP(uint256 id) public view returns (bytes32, uint256, string memory, address, string memory, address, uint, uint){
        IP storage ip = _ipMapping[id];
        string memory name = ip.name;
        return (ip.hash, ip.id, name, ip.owner, ip.metaData, ip.operator, ip.parentIds.length, ip.childIds.length);
    }

    function getNftContractCount(uint256 id) public view returns (uint){
        return (_ipMapping[id].nftContracts.length);
    }

    function getNftContractByIndex(uint256 id, uint256 index) public view returns (address){
        return (_ipMapping[id].nftContracts[index]);
    }

    function getNftContractChainCount(uint256 id, address nftContract) public view returns (uint){
        return _ipMapping[id].nftContract[nftContract].chains.length;
    }

    function getNftContractChainId(uint256 id, address nftContract, uint256 index) public view returns (uint256){
        uint256 chainId = _ipMapping[id].nftContract[nftContract].chains[index];
        if (_ipMapping[id].nftContract[nftContract].chainMap[chainId]){
            return chainId;
        }
        return 0;
    }

    function createIP(uint256 ipId, bytes32 hash, string memory name, string memory metaData, address operator) public returns (uint256){
        require(_ipMapping[ipId].owner == address(0), "ip already exists");

        _ipMapping[ipId].hash = hash;
        _ipMapping[ipId].id = ipId;
        _ipMapping[ipId].name = name;
        _ipMapping[ipId].owner = msg.sender;
        _ipMapping[ipId].operator = operator;
        _ipMapping[ipId].metaData = metaData;
        emit Created(ipId, name, metaData);
        return ipId;

    }
    function createIP(uint256 ipId, bytes32 hash, string memory name, string memory metaData, address owner ,address operator) public returns (uint256){
        require(_ipMapping[ipId].owner == address(0), "ip already exists");
        require(owner != address(0), "owner is not set");
      
        _ipMapping[ipId].hash = hash;
        _ipMapping[ipId].id = ipId;
        _ipMapping[ipId].name = name;
        _ipMapping[ipId].owner = owner;
        _ipMapping[ipId].operator = operator;
        _ipMapping[ipId].metaData = metaData;
        emit Created(ipId, name, metaData);
        return ipId;

    }

    function addNFTContract(
        uint256 _id,
        address _nftContract
        ) public returns (address){
        return addNFTContract(_id, block.chainid, _nftContract);
    }

    function addNFTContract(
        uint256 _id,
        uint256 _chainid,
        address _nftContract
        ) public returns (address){
        require(_ipMapping[_id].id != 0, "ip not exist");
        isOwnerOrOperator(_ipMapping[_id]);

        IP storage ip = _ipMapping[_id];

        ContractChain storage contractChain = ip.nftContract[_nftContract];
        if (!contractChain.isExists){
            ip.nftContracts.push(_nftContract);
            contractChain.isExists = true;
            contractChain.chains.push(_chainid);
            contractChain.chainMap[_chainid] = true;
        } else {
            if (!contractChain.chainMap[_chainid]){
                contractChain.chains.push(_chainid);
                contractChain.chainMap[_chainid] = true;
            }
        }

        return _nftContract;
    }


    function updateIP(uint256 id, string memory name, string memory metaData) public {
        require(_ipMapping[id].id != 0, "ip not exist");
        isOwnerOrOperator(_ipMapping[id]);

        _ipMapping[id].name = name;
        _ipMapping[id].metaData = metaData;
    }

    function isOwnerOrOperator(IP storage ip) private view {
        require((ip.owner == msg.sender) || (ip.operator == msg.sender), "sender dos not own IP or operator IP.");
    }

    function updateOperator(uint256 id, address operator) public {
        isOwnerOrOperator(_ipMapping[id]);
        _ipMapping[id].operator = operator;
    }

    function request(address targetContract, uint256 id, uint256 parentId, string memory metaData) public payable returns (bool){
        // judge whether connect to other contract
        // not connect to others: callFromCurrent=true, callToCurrent=true
        // connect to others: A contract(callFromCurrent=true, callToCurrent=false) -> B contract(callFromCurrent=false, callToCurrent=true)

        bool callFromCurrent = false;
        bool callToCurrent = false;
        if (!Address.isContract(msg.sender)) {callFromCurrent = true;}
        if (targetContract == address(0) || address(this) == targetContract) {callToCurrent = true;}

        if (callFromCurrent) {
            require(_ipMapping[id].id != 0, "child id dos not exists.");
            isOwnerOrOperator(_ipMapping[id]);
        }
        if (callToCurrent) {
            require(_ipMapping[parentId].id != 0, "parent id dos not exists.");
        }

        // make link from current to parent
        uint256 linkId = 0;
        if (callFromCurrent) {
            linkId = _ipMapping[id].parent[parentId].length;
            Link memory link;
            link.targetId = parentId;
            link.isRequested = true;
            link.fee = msg.value;
            link.metaData = metaData;
            _ipMapping[id].parent[parentId].push(link);
        }
        _ipMapping[id].parentIds.push(parentId);


        // make link from parent to current
        if (callToCurrent) {
            linkId = _ipMapping[parentId].child[id].length;
            Link memory link;
            link.targetId = id;
            link.isRequested = true;
            link.fee = msg.value;
            link.metaData = metaData;
            _ipMapping[parentId].child[id].push(link);
        }
        _ipMapping[parentId].childIds.push(id);

        if (callFromCurrent && !callToCurrent) {
            require(JPNFTIpNetworkPoc(targetContract).request{value:msg.value}(address(0), id, parentId, metaData));
        }

        if (callFromCurrent) {
            emit Requested(id, parentId, linkId, metaData, msg.value);
        }
        return true;
    }

    function cancel(address targetContract, uint256 id, uint256 parentId, uint256 linkId) public returns (bool){
        // judge whether connect to other contract
        // not connect to others: callFromCurrent=true, callToCurrent=true
        // connect to others: A contract(callFromCurrent=true, callToCurrent=false) -> B contract(callFromCurrent=false, callToCurrent=true)

        bool callFromCurrent = false;
        bool callToCurrent = false;
        if (!Address.isContract(msg.sender)) {callFromCurrent = true;}
        if (targetContract == address(0) || address(this) == targetContract) {callToCurrent = true;}

        if (callFromCurrent) {
            require(_ipMapping[id].id != 0, "child id dos not exists.");
            isOwnerOrOperator(_ipMapping[id]);
            require(_ipMapping[id].parent[parentId][linkId].targetId == parentId, "link info not made.");
            require(_ipMapping[id].parent[parentId][linkId].isRequested == true, "not requested.");
            require(_ipMapping[id].parent[parentId][linkId].isSigned == false, "already linked.");
        }

        if (callToCurrent) {
            require(_ipMapping[parentId].id != 0, "parent id dos not exists.");
        }

        uint256 fee = 0;

        // revert isRequest to false and refund fee.
        if (callFromCurrent) {
            _ipMapping[id].parent[parentId][linkId].isRequested = false;
            fee = _ipMapping[id].parent[parentId][linkId].fee;
            _ipMapping[id].parent[parentId][linkId].fee = 0;
        }

        if (callToCurrent) {
            _ipMapping[parentId].child[id][linkId].isRequested = false;
            fee = _ipMapping[parentId].child[id][linkId].fee;
            _ipMapping[parentId].child[id][linkId].fee = 0;
        }

        if (callFromCurrent && !callToCurrent) {
            require(JPNFTIpNetworkPoc(targetContract).cancel(address(0), id, parentId, linkId));
            // refund to sender
            require(payable(msg.sender).send(fee));
        }

        if (!callFromCurrent && callToCurrent) {
            // refund to previous contract
            require(payable(msg.sender).send(fee));
        }

        if (callFromCurrent && callToCurrent) {
            require(payable(msg.sender).send(fee));
        }

        if (callFromCurrent) {
            emit Canceled(id, parentId, linkId, fee);
        }
        return true;
    }

    // link by parent
    function accept(address targetContract, uint256 id, uint256 childId, uint256 linkId) public returns (bool){
        // judge whether connect to other contract
        // not connect to others: callFromCurrent=true, callToCurrent=true
        // connect to others: A contract(callFromCurrent=true, callToCurrent=false) -> B contract(callFromCurrent=false, callToCurrent=true)

        bool callFromCurrent = false;
        bool callToCurrent = false;
        if (!Address.isContract(msg.sender)) {callFromCurrent = true;}
        if (targetContract == address(0) || address(this) == targetContract) {callToCurrent = true;}

        if (callFromCurrent) {
            require(_ipMapping[id].id != 0, "parent id dos not exists.");
            isOwnerOrOperator(_ipMapping[id]);
            require(_ipMapping[id].child[childId][linkId].targetId == childId, "link info not made.");
            require(_ipMapping[id].child[childId][linkId].isRequested == true, "not requested.");
            require(_ipMapping[id].child[childId][linkId].isSigned == false, "already linked.");
        }
        if (callToCurrent) {
            require(_ipMapping[childId].id != 0, "child id dos not exists.");
        }

        if (callFromCurrent) {
            _ipMapping[id].child[childId][linkId].isSigned = true;
        }
        if (callToCurrent) {
            _ipMapping[childId].parent[id][linkId].isSigned = true;
        }

        uint256 fee = _ipMapping[id].child[childId][linkId].fee;
        if (callFromCurrent) {
            _ipMapping[id].child[childId][linkId].fee = 0;
            if (fee > 0) {
                require(payable(msg.sender).send(fee));
            }
        }
        if (callFromCurrent && !callToCurrent) {
            require(JPNFTIpNetworkPoc(targetContract).accept(address(0), id, childId, linkId));
        }

        if (callFromCurrent) {
            emit Linked(id, childId, linkId, fee);
        }
        return true;
    }

    // reject link by parent
    function reject(address targetContract, uint256 id, uint256 childId, uint256 linkId) public payable returns (bool){
        // judge whether connect to other contract
        // not connect to others: callFromCurrent=true, callToCurrent=true
        // connect to others: A contract(callFromCurrent=true, callToCurrent=false) -> B contract(callFromCurrent=false, callToCurrent=true)

        bool callFromCurrent = false;
        bool callToCurrent = false;
        if (!Address.isContract(msg.sender)) {callFromCurrent = true;}
        if (targetContract == address(0) || address(this) == targetContract) {callToCurrent = true;}

        if (callFromCurrent) {
            require(_ipMapping[id].id != 0, "parent id dos not exists.");
            isOwnerOrOperator(_ipMapping[id]);
            require(_ipMapping[id].child[childId][linkId].targetId == childId, "link info not made.");
            require(_ipMapping[id].child[childId][linkId].isRequested == true, "not requested.");
            require(_ipMapping[id].child[childId][linkId].isSigned == false, "already linked.");
            require(msg.value == 0, "should not pay back from parent account");
        }
        if (callToCurrent) {
            require(_ipMapping[childId].id != 0, "child id dos not exists.");
        }

        uint256 fee = 0;
        if (callFromCurrent) {
            fee = _ipMapping[id].child[childId][linkId].fee;
            _ipMapping[id].child[childId][linkId].fee = 0;
            _ipMapping[id].child[childId][linkId].isRequested = false;
            _ipMapping[id].child[childId][linkId].isSigned = false;
        }
        if (callToCurrent) {
            if (callFromCurrent) {
                fee = _ipMapping[childId].parent[id][linkId].fee;
            } else {
                fee = msg.value;
            }

            _ipMapping[childId].parent[id][linkId].fee = 0;
            _ipMapping[childId].parent[id][linkId].isRequested = false;
            _ipMapping[childId].parent[id][linkId].isSigned = false;
            if (fee > 0) {
                address addr = address(uint160(_ipMapping[childId].owner));
                require(payable(addr).send(msg.value));
            }
        }

        if (callFromCurrent && !callToCurrent) {
            require(JPNFTIpNetworkPoc(targetContract).reject{value:fee}(address(0), id, childId, linkId));
        }

        if (callFromCurrent) {
            emit Rejected(id, childId, linkId, fee);
        }
        return true;

    }

    // unlink by parent
    function unlink(address targetContract, uint256 id, uint256 childId, uint256 linkId) public returns (bool) {
        // judge whether connect to other contract
        // not connect to others: callFromCurrent=true, callToCurrent=true
        // connect to others: A contract(callFromCurrent=true, callToCurrent=false) -> B contract(callFromCurrent=false, callToCurrent=true)

        bool callFromCurrent = false;
        bool callToCurrent = false;
        if (!Address.isContract(msg.sender)) {callFromCurrent = true;}
        if (targetContract == address(0) || address(this) == targetContract) {callToCurrent = true;}

        if (callFromCurrent) {
            require(_ipMapping[id].id != 0, "parent id dos not exists.");
            isOwnerOrOperator(_ipMapping[id]);
            require(_ipMapping[id].child[childId][linkId].targetId == childId, "link info not made.");
            require(_ipMapping[id].child[childId][linkId].isSigned == true, "not linked yet.");
        }

        if (callToCurrent) {
            require(_ipMapping[childId].id != 0, "child id dos not exists.");
        }

        if (callFromCurrent) {
            _ipMapping[id].child[childId][linkId].isRequested = false;
            _ipMapping[id].child[childId][linkId].isSigned = false;
        }

        if (callToCurrent) {
            _ipMapping[childId].parent[id][linkId].isRequested = false;
            _ipMapping[childId].parent[id][linkId].isSigned = false;
        }

        if (callFromCurrent && !callToCurrent) {
            require(JPNFTIpNetworkPoc(targetContract).unlink(address(0), id, childId, linkId));
        }

        if (callFromCurrent) {
            emit Unlinked(id, childId, linkId);
        }
        return true;

    }

    // for demo only
    function addLinkSignature(uint256 id, uint256 childId, uint256 linkId, bytes32 r, bytes32 s, uint8 v) public returns (bool){
        require(_ipMapping[id].id != 0, "parent id dos not exists.");
        isOwnerOrOperator(_ipMapping[id]);
        require(_ipMapping[id].child[childId][linkId].targetId == childId, "link info not made.");
        require(_ipMapping[id].child[childId][linkId].isSigned == true, "not linked yet.");

        _ipMapping[id].child[childId][linkId].signature.r = r;
        _ipMapping[id].child[childId][linkId].signature.s = s;
        _ipMapping[id].child[childId][linkId].signature.v = v;
        _ipMapping[id].child[childId][linkId].signature.singer = msg.sender;
        _ipMapping[id].child[childId][linkId].signature.func = "link";

        emit LinkSignatureAdded(id, childId, linkId);
        return true;
    }

    function addRequestSignature(uint256 id, uint256 parentId, uint256 linkId, bytes32 r, bytes32 s, uint8 v) public returns (bool){
        require(_ipMapping[id].id != 0, "child id dos not exists.");
        isOwnerOrOperator(_ipMapping[id]);
        require(_ipMapping[id].parent[parentId][linkId].targetId == parentId, "link info not made.");
        require(_ipMapping[id].parent[parentId][linkId].isRequested == true, "not request yet.");

        _ipMapping[id].parent[parentId][linkId].signature.r = r;
        _ipMapping[id].parent[parentId][linkId].signature.s = s;
        _ipMapping[id].parent[parentId][linkId].signature.v = v;
        _ipMapping[id].parent[parentId][linkId].signature.singer = msg.sender;
        _ipMapping[id].parent[parentId][linkId].signature.func = "request";

        emit RequestSignatureAdded(id, parentId, linkId);
        return true;
    }

    function getNFTKeyHash(uint256 _chainid, address _address, uint256 _nftId ) public pure returns(bytes32) {
        return keccak256(abi.encodePacked(_chainid.toString(), "-", abi.encodePacked(_address).toLiteralString(), "-", _nftId.toString()));
    }

    function getNFTAuthenticateCount(uint256 _chainId, address _nftContract, uint256 _nftId) public view returns (uint){
        return _nftAuthenticationMapping[getNFTKeyHash(_chainId,_nftContract, _nftId)].ips.length;
    }

    function getNFTAuthenticateIp(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _index) public view returns (uint256){
        return _nftAuthenticationMapping[getNFTKeyHash(_chainId,_nftContract, _nftId)].ips[_index];
    }

    function getNFTAuthenticateInfo(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public view returns (address, uint256, NFTAuthenticationType){
        NFTAuthenticationUnit storage authenticationUnit = _nftAuthenticationMapping[getNFTKeyHash(_chainId,_nftContract, _nftId)].ipAuthenticatedMapping[_ip];
        return (authenticationUnit.applicant,
                authenticationUnit.fee,
                authenticationUnit.authenticationType);
    }

    function isNFTAuthenticated(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public view returns (bool){
        NFTAuthenticationUnit storage authenticationUnit = _nftAuthenticationMapping[getNFTKeyHash(_chainId,_nftContract, _nftId)].ipAuthenticatedMapping[_ip];
        return (authenticationUnit.authenticationType == NFTAuthenticationType.LINK);
    }

    // request the Authenticate from a ip for NFT.
    function requestNFTAuthenticate(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public payable hasIp(_ip) {
        bytes32 nftAuthenticateKey = getNFTKeyHash(_chainId,_nftContract, _nftId);
        NFTAuthentication storage nftAuthenticationInfo = _nftAuthenticationMapping[nftAuthenticateKey];
        NFTAuthenticationUnit storage authenticationUnit = nftAuthenticationInfo.ipAuthenticatedMapping[_ip];
        NFTAuthenticationType authenticationType = authenticationUnit.authenticationType;
        
        require((authenticationType != NFTAuthenticationType.LINK), "this NFT is authenticated.");
        require((authenticationType != NFTAuthenticationType.REQUEST), "this NFT is requesting the authenticate.");

        if (authenticationType == NFTAuthenticationType.NONE){
            nftAuthenticationInfo.ips.push(_ip);
        }

        authenticationUnit.applicant = msg.sender;
        authenticationUnit.fee = msg.value;
        authenticationUnit.authenticationType = NFTAuthenticationType.REQUEST;
        
        emit NFTAuthenticate(_chainId, _nftContract, _nftId, _ip, 1);
    }
    function requestNFTAuthenticates(uint256[] memory _chainId, address[] memory _nftContract, uint256[] memory _nftId, uint256[] memory _ip) public payable {
        require(_chainId.length == _nftContract.length && _chainId.length == _nftId.length && _chainId.length == _ip.length, "input length must be same.");
        for (uint256 i = 0; i < _chainId.length; i++) {
            requestNFTAuthenticate(_chainId[i], _nftContract[i], _nftId[i], _ip[i]);
        }
    }

    // cancel the Authenticate request.
    function cancelNFTAuthenticate(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public payable hasIp(_ip) {
        bytes32 nftAuthenticateKey = getNFTKeyHash(_chainId,_nftContract, _nftId);
        NFTAuthentication storage nftAuthenticationInfo = _nftAuthenticationMapping[nftAuthenticateKey];
        NFTAuthenticationUnit storage authenticationUnit = nftAuthenticationInfo.ipAuthenticatedMapping[_ip];
        NFTAuthenticationType authenticationType = authenticationUnit.authenticationType;
        
        require((authenticationUnit.applicant == msg.sender), "only applicant can cancel the request.");
        require((authenticationType == NFTAuthenticationType.REQUEST), "this NFT authenticate is not requesting.");

        authenticationUnit.authenticationType = NFTAuthenticationType.CANCEL;
        uint256 fee = authenticationUnit.fee;
        if (fee > 0) {
            authenticationUnit.fee = 0;
            require(payable(authenticationUnit.applicant).send(fee));
        }

        emit NFTAuthenticate(_chainId, _nftContract, _nftId, _ip, 5);
    }
    function cancelNFTAuthenticates(uint256[] memory _chainId, address[] memory _nftContract, uint256[] memory _nftId, uint256[] memory _ip) public payable {
        require(_chainId.length == _nftContract.length && _chainId.length == _nftId.length && _chainId.length == _ip.length, "input length must be same.");
        for (uint256 i = 0; i < _chainId.length; i++) {
            cancelNFTAuthenticate(_chainId[i], _nftContract[i], _nftId[i], _ip[i]);
        }
    }

    // accept the Authenticate request.
    function acceptNFTAuthenticate(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public payable hasIp(_ip) {
        bytes32 nftAuthenticateKey = getNFTKeyHash(_chainId,_nftContract, _nftId);
        NFTAuthentication storage nftAuthenticationInfo = _nftAuthenticationMapping[nftAuthenticateKey];
        NFTAuthenticationUnit storage authenticationUnit = nftAuthenticationInfo.ipAuthenticatedMapping[_ip];
        NFTAuthenticationType authenticationType = authenticationUnit.authenticationType;
        
        isOwnerOrOperator(_ipMapping[_ip]);
        require((authenticationType == NFTAuthenticationType.REQUEST), "this NFT authenticate is not requesting.");

        authenticationUnit.authenticationType = NFTAuthenticationType.LINK;
        uint256 fee = authenticationUnit.fee;
        if (fee > 0) {
            authenticationUnit.fee = 0;
            require(payable(_ipMapping[_ip].owner).send(fee));
        }
        
        emit NFTAuthenticate(_chainId, _nftContract, _nftId, _ip, 2);
    }
    function acceptNFTAuthenticates(uint256[] memory _chainId, address[] memory _nftContract, uint256[] memory _nftId, uint256[] memory _ip) public payable {
        require(_chainId.length == _nftContract.length && _chainId.length == _nftId.length && _chainId.length == _ip.length, "input length must be same.");
        for (uint256 i = 0; i < _chainId.length; i++) {
            acceptNFTAuthenticate(_chainId[i], _nftContract[i], _nftId[i], _ip[i]);
        }
    }

    // reject the Authenticate request.
    function rejectNFTAuthenticate(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public payable hasIp(_ip) {
        bytes32 nftAuthenticateKey = getNFTKeyHash(_chainId,_nftContract, _nftId);
        NFTAuthentication storage nftAuthenticationInfo = _nftAuthenticationMapping[nftAuthenticateKey];
        NFTAuthenticationUnit storage authenticationUnit = nftAuthenticationInfo.ipAuthenticatedMapping[_ip];
        NFTAuthenticationType authenticationType = authenticationUnit.authenticationType;
        
        isOwnerOrOperator(_ipMapping[_ip]);
        require((authenticationType == NFTAuthenticationType.REQUEST), "this NFT authenticate is not requesting.");

        authenticationUnit.authenticationType = NFTAuthenticationType.REJECT;
        uint256 fee = authenticationUnit.fee;
        if (fee > 0) {
            authenticationUnit.fee = 0;
            require(payable(authenticationUnit.applicant).send(fee));
        }
        
        emit NFTAuthenticate(_chainId, _nftContract, _nftId, _ip, 3);
    }
    function rejectNFTAuthenticates(uint256[] memory _chainId, address[] memory _nftContract, uint256[] memory _nftId, uint256[] memory _ip) public payable {
        require(_chainId.length == _nftContract.length && _chainId.length == _nftId.length && _chainId.length == _ip.length, "input length must be same.");
        for (uint256 i = 0; i < _chainId.length; i++) {
            rejectNFTAuthenticate(_chainId[i], _nftContract[i], _nftId[i], _ip[i]);
        }
    }

    // unlink the Authenticate request.
    function unlinkNFTAuthenticate(uint256 _chainId, address _nftContract, uint256 _nftId, uint256 _ip) public payable hasIp(_ip) {
        bytes32 nftAuthenticateKey = getNFTKeyHash(_chainId,_nftContract, _nftId);
        NFTAuthentication storage nftAuthenticationInfo = _nftAuthenticationMapping[nftAuthenticateKey];
        NFTAuthenticationUnit storage authenticationUnit = nftAuthenticationInfo.ipAuthenticatedMapping[_ip];
        NFTAuthenticationType authenticationType = authenticationUnit.authenticationType;
        
        isOwnerOrOperator(_ipMapping[_ip]);
        require((authenticationType == NFTAuthenticationType.LINK), "this NFT authenticate is not linked.");

        authenticationUnit.authenticationType = NFTAuthenticationType.UNLINK;
        
        emit NFTAuthenticate(_chainId, _nftContract, _nftId, _ip, 4);
    }
    function unlinkNFTAuthenticates(uint256[] memory _chainId, address[] memory _nftContract, uint256[] memory _nftId, uint256[] memory _ip) public payable {
        require(_chainId.length == _nftContract.length && _chainId.length == _nftId.length && _chainId.length == _ip.length, "input length must be same.");
        for (uint256 i = 0; i < _chainId.length; i++) {
            unlinkNFTAuthenticate(_chainId[i], _nftContract[i], _nftId[i], _ip[i]);
        }
    }
}