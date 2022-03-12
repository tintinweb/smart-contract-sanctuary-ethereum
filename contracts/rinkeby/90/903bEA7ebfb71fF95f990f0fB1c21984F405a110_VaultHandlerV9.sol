//     ______          __    __                          
//    / ____/___ ___  / /_  / /__  ____ ___              
//   / __/ / __ `__ \/ __ \/ / _ \/ __ `__ \             
//  / /___/ / / / / / /_/ / /  __/ / / / / /             
// /_____/_/ /_/ /_/_.___/_/\___/_/ /_/ /_/              
// | |  / /___ ___  __/ / /_                             
// | | / / __ `/ / / / / __/                             
// | |/ / /_/ / /_/ / / /_                               
// |___/\__,_/\__,_/_/\__/                               
//     __  __                ____                   ____ 
//    / / / /___ _____  ____/ / /__  _____   _   __( __ )
//   / /_/ / __ `/ __ \/ __  / / _ \/ ___/  | | / / __  |
//  / __  / /_/ / / / / /_/ / /  __/ /      | |/ / /_/ / 
// /_/ /_/\__,_/_/ /_/\__,_/_/\___/_/       |___/\____/  

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;


// import "./Callback.sol";
import "./BasicERC20.sol";
// import "./EmblemVault.sol";
// import "./ConfigurableERC20.sol";
import "./ERC1155.sol";
import "./SafeMath.sol";
import "./IERC721.sol";
import "./Storage.sol";
import "./BalanceStorage.sol";
import "./Claimed.sol";
// import "./Balance.sol";
import "./NFTrade_v2.sol";
import "./NFTrade_v3.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./HasCallbacks.sol";
import "./IHandlerCallback.sol";
// import "./TokenStaking.sol";

contract VaultHandlerV9 is ReentrancyGuard, HasRegistration, ERC165 {
    
    using SafeMath for uint256;
    string public metadataBaseUri = "https://api.emblemvault.io/s:evmetadata/meta/";
    address public recipientAddress;
    address CallbackAddress;

    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bool public shouldBurn = false;
    
    mapping(address => bool) public witnesses;
    mapping(uint256 => bool) usedNonces;
    
    constructor(address _callbackAddress) {
        owner = _msgSender();
        addWitness(owner);
        recipientAddress = _msgSender();
        updateStorage(_callbackAddress);
    }

    function updateStorage(address storageContract) public onlyOwner {
        CallbackAddress = storageContract;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }

    function claim(address _nftAddress, uint256 tokenId) public nonReentrant isRegisteredContract(_nftAddress) {
        Claimed claimer = Claimed(registeredOfType[6][0]);
        bytes32[] memory proof;
        
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IIsSerialized serialized = IIsSerialized(_nftAddress);
            uint256 serialNumber = serialized.getFirstSerialByOwner(_msgSender(), tokenId);
            require(serialized.getTokenIdForSerialNumber(serialNumber) == tokenId, "Invalid tokenId serialnumber combination");
            require(serialized.getOwnerOfSerial(serialNumber) == _msgSender(), "Not owner of serial number");
            require(!claimer.isClaimed(_nftAddress, serialNumber, proof), "Already Claimed");
            IERC1155(_nftAddress).burn(_msgSender(), tokenId, 1);
            claimer.claim(_nftAddress, serialNumber, _msgSender());
        } else {            
            require(!claimer.isClaimed(_nftAddress, tokenId, proof), "Already Claimed");
            IERC721 token = IERC721(_nftAddress);
            require(token.ownerOf(tokenId) == _msgSender(), "Not Token Owner");
            token.burn(tokenId);
            claimer.claim(_nftAddress, tokenId, _msgSender());
        }
        IHandlerCallback(CallbackAddress).executeStoredCallbacksInternal(_nftAddress, _msgSender(), address(0), tokenId, IHandlerCallback.CallbackType.CLAIM);
    }

    function executeCallbacks(address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) public isRegisteredContract(_msgSender()) {
        IHandlerCallback(CallbackAddress).executeCallbacks(_from, _to, tokenId, _type);
    }

    function buyWithSignedPrice(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, string calldata _payload, uint256 _nonce, bytes calldata _signature) public nonReentrant {
        IERC20Token paymentToken = IERC20Token(_payment);
        if (shouldBurn) {
            require(paymentToken.transferFrom(msg.sender, address(this), _price), 'Transfer ERROR'); // Payment sent to recipient
            BasicERC20(_payment).burn(_price);
        } else {
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), _price), 'Transfer ERROR'); // Payment sent to recipient
        }
        address signer = getAddressFromSignature(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _payload, _signature);
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[_nonce] = true;
        string memory _uri = concat(metadataBaseUri, uintToStr(_tokenId));
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).mint(_to, _tokenId, 1);
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
        }
    }

    function mint(address _nftAddress, address _to, uint256 _tokenId, string calldata _uri, string calldata _payload, uint256 amount) external onlyOwner {
        if (checkInterface(_nftAddress, _INTERFACE_ID_ERC1155)) {
            IERC1155(_nftAddress).mint(_to, _tokenId, amount);
        } else {
            IERC721(_nftAddress).mint(_to, _tokenId, _uri, _payload);
        }        
    }

    function moveVault(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 nonce, bytes calldata signature) external nonReentrant isRegisteredContract(_from) isRegisteredContract(_to)  {
        require(_from != _to, 'Cannot move vault to same address');
        address signer = getAddressFromSignatureMove(_from, _to, tokenId, newTokenId, nonce, signature);
        require(witnesses[signer], 'Not Witnessed');
        usedNonces[nonce] = true;
        if (checkInterface(_from, _INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'from: TokenIds must be different for ERC1155');
            uint256 currentBalance = IERC1155(_from).balanceOf(_msgSender(), tokenId);
            require(currentBalance > 0, 'from: Not owner of vault');
            IERC1155(_from).burn(_msgSender(), tokenId, 1);
            uint256 newBalance = IERC1155(_from).balanceOf(_msgSender(), tokenId);
            require(newBalance == currentBalance.sub(1), 'from: Not Burnt');
        } else {
            require(IERC721(_from).ownerOf(tokenId) == _msgSender(), 'from: Not owner of vault');
            IERC721(_from).burn(tokenId);
            tryERC721BalanceCheck(_from, tokenId, 'Not Burnt');
        }
        if (checkInterface(_to, _INTERFACE_ID_ERC1155)) {
            require(tokenId != newTokenId, 'to: TokenIds must be different for ERC1155');            
            IERC1155(_to).mint(_msgSender(), newTokenId, 1);
        } else {
            tryERC721BalanceCheck(_to, newTokenId, 'NFT Already Exists');
            string memory _uri = concat(metadataBaseUri, uintToStr(newTokenId));
            IERC721(_to).mint(_msgSender(), newTokenId, _uri, "");
        }
    }

    function tryERC721BalanceCheck(address _from, uint256 tokenId, string memory reason) public returns(uint256 returnedAmount){
        (bool success, bytes memory returnData) =
            address(_from).call( // This creates a low level call to the token
                abi.encodePacked( // This encodes the function to call and the parameters to pass to that function
                    IERC721(_from).ownerOf.selector, // This is the function identifier of the function we want to call
                    abi.encode(tokenId) // This encodes the parameter we want to pass to the function
                )
            );
        if (success) { 
            revert(reason);                
        } else { 
            (returnedAmount) = abi.decode(returnData, (uint256));
        }
    }    
    
    function toggleShouldBurn() public onlyOwner {
        shouldBurn = !shouldBurn;
    }
    
    function addWitness(address _witness) public onlyOwner {
        witnesses[_witness] = true;
    }

    function removeWitness(address _witness) public onlyOwner {
        witnesses[_witness] = false;
    }

    function getAddressFromSignatureHash(bytes32 _hash, bytes calldata signature) public pure returns (address) {
        address addressFromSig = recoverSigner(_hash, signature);
        return addressFromSig;
    }

    function getAddressFromSignature(address _nftAddress, address _payment, uint _price, address _to, uint256 _tokenId, uint256 _nonce, string calldata _payload, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        bytes32 _hash = keccak256(abi.encodePacked(_nftAddress, _payment, _price, _to, _tokenId, _nonce, _payload));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignature(address _to, uint256 _tokenId, uint256 _nonce, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce], 'Nonce already used');
        bytes32 _hash = keccak256(abi.encodePacked(_to, _tokenId, _nonce));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignatureMint(address _nftAddress, address _to, uint256 _tokenId, uint256 _nonce, string calldata payload, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        bytes32 _hash = keccak256(abi.encodePacked(_nftAddress, _to, _tokenId, _nonce, payload));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function getAddressFromSignatureMove(address _from, address _to, uint256 tokenId, uint256 newTokenId, uint256 _nonce, bytes calldata signature) public view returns (address) {
        require(!usedNonces[_nonce]);
        bytes32 _hash = keccak256(abi.encodePacked(_from, _to, tokenId, newTokenId, _nonce));
        return getAddressFromSignatureHash(_hash, signature);
    }

    function isWitnessed(bytes32 _hash, bytes calldata signature) public view returns (bool) {
        address addressFromSig = recoverSigner(_hash, signature);
        return witnesses[addressFromSig];
    }
    
    function changeMetadataBaseUri(string calldata _uri) public onlyOwner {
        metadataBaseUri = _uri;
    }

    function transferNftOwnership(address _nftAddress, address newOwner) external onlyOwner {
        Ownable nftToken = Ownable(_nftAddress);
        nftToken.transferOwnership(newOwner);
    }
    
    function changeName(address _nftAddress, string calldata name, string calldata symbol) external onlyOwner {
        IERC721 nftToken = IERC721(_nftAddress);
        nftToken.changeName(name, symbol);
    }
    
    function updateTokenUri(address _nftAddress, uint256 _tokenId,string memory _uri) external onlyOwner {
        IERC721 nftToken = IERC721(_nftAddress);
        nftToken.updateTokenUri(_tokenId, _uri);
    }

    function changeRecipient(address _recipient) public onlyOwner {
       recipientAddress = _recipient;
    }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }
    
    function concat(string memory a, string memory b) internal pure returns (string memory) {
        return string(abi.encodePacked(a, b));
    }

    function recoverSigner(bytes32 hash, bytes memory sig) public pure returns (address) {
        require(sig.length == 65, "Require correct length");

        bytes32 r;
        bytes32 s;
        uint8 v;

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        require(v == 27 || v == 28, "Signature version not match");

        return recoverSigner2(hash, v, r, s);
    }
    function recoverSigner2(bytes32 h, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, h));
        address addr = ecrecover(prefixedHash, v, r, s);

        return addr;
    }
    function uintToStr(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    function toString(address account) public pure returns(string memory) {
        return toString(abi.encodePacked(account));
    }    
    function toString(uint256 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }    
    function toString(bytes32 value) public pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }    
    function toString(bytes memory data) public pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
    
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

pragma solidity 0.8.4;
interface BasicERC20 {
    function burn(uint256 value) external;
    function mint(address account, uint256 amount) external;
    function decimals() external view returns (uint8);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
}
interface IERC20Token {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: Address.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
import "@openzeppelin/contracts/utils/Strings.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IERC1155.sol";
import "./HasRegistration.sol";
import "./IHandlerCallback.sol";
import "./IsSerialized.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */

contract ERC1155 is ERC165, IERC1155, IERC1155MetadataURI, HasRegistration, IsSerialized {
    using SafeMath for uint256;
    using Address for address;

    // Mapping from token ID to account balances
    mapping (uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping (address => mapping(address => bool)) private _operatorApprovals;

    bool initialized = false;
    string private _uri;
    
    constructor () {
        init(_msgSender());
    }

    function init(address _owner) public {
        require(!initialized, "Already Initialized");
        owner = _owner;
        _registerInterface(0xd9b67a26); //_INTERFACE_ID_ERC1155
        _registerInterface(0x0e89341c); //_INTERFACE_ID_ERC1155_METADATA_URI
        _uri = "https://api.emblemvault.io/s:evmetadata/meta/";
        serialized = true;
        initialized = true;
    }

    function mint(address _to, uint256 _tokenId, uint256 _amount) public override onlyOwner {
        _mint(_to, _tokenId, _amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

    function burn(address _from, uint256 _tokenId, uint256 _amount) public override {
        require(_from == _msgSender() || isApprovedForAll(_from, _msgSender()), 'Not Approved to burn');
        _burn(_from, _tokenId, _amount);
    }

    function burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) public {
        require(account == _msgSender() || isApprovedForAll(account, _msgSender()), 'Not Approved to burn');
        _burnBatch(account, ids, amounts);
    }

    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256 _tokenId) external view override returns (string memory) {
        return string(abi.encodePacked(_uri, Strings.toString(_tokenId)));
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    )
        public
        view
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            require(accounts[i] != address(0), "ERC1155: batch balance query for the zero address");
            batchBalances[i] = _balances[ids[i]][accounts[i]];
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(_msgSender() != operator, "ERC1155: setting approval status for self");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][from] = _balances[id][from].sub(amount, "ERC1155: insufficient balance for transfer");
        _balances[id][to] = _balances[id][to].add(amount);

        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {            
                uint256 serialNumber = getFirstSerialByOwner(from, id);
                if (serialNumber != 0 ) {
                    transferSerial(serialNumber, from, to);
                }
            }
        }

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] != address(0)) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            }
        }
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        public
        virtual
        override
    {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            // _balances[id][from] = _balances[id][from].sub(
            //     amount,
            //     "ERC1155: insufficient balance for transfer"
            // );
            // _balances[id][to] = _balances[id][to].add(amount);
            // if (registeredOfType[3][0] != address(0)) {
            //     IHandlerCallback(registeredOfType[3][0]).executeCallbacks(from, to, id, IHandlerCallback.CallbackType.TRANSFER);
            // }
            safeTransferFrom(from, to, id, amount, data);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address account, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(account != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), account, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][account] = _balances[id][account].add(amount);
        if (isSerialized()) {
            for (uint i = 0; i < amount; i++) {
                mintSerial(id, account);
            }            
        }
        if (registeredOfType[3].length > 0 && registeredOfType[3][0] == _msgSender()) {
            for (uint i = 0; i < amount; i++) {
                IHandlerCallback(_msgSender()).executeCallbacks(address(0), account, id, IHandlerCallback.CallbackType.MINT);
            }
        }
        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), account, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint i = 0; i < ids.length; i++) {
            // _balances[ids[i]][to] = amounts[i].add(_balances[ids[i]][to]);
            _mint(to, ids[i], amounts[i], data);
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address account, uint256 id, uint256 amount) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "ERC1155: burn amount exceeds balance"
        );

        if (isSerialized()) {            
            uint256 serialNumber = getFirstSerialByOwner(account, id);
            if (serialNumber != 0 ) {
                transferSerial(serialNumber, account, address(0));
            }            
        }

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(account != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, account, address(0), ids, amounts, "");

        for (uint i = 0; i < ids.length; i++) {
            _burn(account, ids[i], amounts[i]);
            // _balances[ids[i]][account] = _balances[ids[i]][account].sub(
            //     amounts[i],
            //     "ERC1155: burn amount exceeds balance"
            // );
        }

        emit TransferBatch(operator, account, address(0), ids, amounts);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        internal virtual
    { }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    )
        private
    {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (bytes4 response) {
                if (response != IERC1155Receiver(to).onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

pragma solidity 0.8.4;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}

pragma solidity 0.8.4;
interface IERC721 {
    function burn(uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
    function mint( address _to, uint256 _tokenId, string calldata _uri, string calldata _payload) external;
    function changeName(string calldata name, string calldata symbol) external;
    function updateTokenUri(uint256 _tokenId,string memory _uri) external;
    function tokenPayload(uint256 _tokenId) external view returns (string memory);
    function ownerOf(uint256 _tokenId) external view returns (address _owner);
    function getApproved(uint256 _tokenId) external returns (address);
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external;
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
    function tokenByIndex(uint256 _index) external view returns (uint256);
    function balanceOf(address account, uint256 id) external view returns (uint256);
    function isApprovedForAll(address _owner, address _operator) external returns (bool);
    function setApprovalForAll( address _operator, bool _approved) external;
}

pragma solidity 0.8.4;
import "./Ownable.sol";

contract Storage is Ownable {

    address public latestVersion;
    
    address DEADADDRESS = 0x000000000000000000000000000000000000dEaD;
    address BURNADDRESS = 0x5D152dd902CC9198B97E5b6Cf5fc23a8e4330180;
    
    mapping(address => bytes32) LegacyClaims;
    mapping(address => bytes32) LegacyClaimsBy;
    mapping(address => mapping(uint => address)) Claims;
    mapping(address => uint256[]) ClaimsFor;
    address[] BurnAddresses;
    
    constructor() {
        BurnAddresses.push(DEADADDRESS);
        BurnAddresses.push(BURNADDRESS);
    }
    
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion, 'Not latest version');
        _;
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner || msg.sender == _newVersion, 'Only owner can upgrade');
        latestVersion = _newVersion;
    }
    
    function getDead() external view returns(address) {
        return DEADADDRESS;
    }
    
    function getBurnAddresses() external view returns (address[] memory){
        return BurnAddresses;
    }
    
    function getLegacyClaims(address nftAddress) external view returns(bytes32) {
        return LegacyClaims[nftAddress];
    }
    function getLegacyClaimsBy(address nftAddress) external view returns(bytes32) {
        return LegacyClaimsBy[nftAddress];
    }
    
    function getClaims(address nftAddress, uint tokenId) external view returns (address) {
        return Claims[nftAddress][tokenId];
    }
    
    function getClaimsFor(address _owner) external view returns (uint256[] memory) {
        return ClaimsFor[_owner];
    }

    /* ADD : Protected by only current version */
    
    function addToBurnAddresses(address burnAddress) external onlyLatestVersion() {
         BurnAddresses.push(burnAddress);
    }
    
    function addToLegacy(address nftAddress, bytes32 root) external onlyLatestVersion() {
        LegacyClaims[nftAddress] = root;
    }
    function addToLegacyClaimedBy(address nftAddress, bytes32 root) external onlyLatestVersion() {
        LegacyClaimsBy[nftAddress] = root;
    }
    
    function addToClaims(address nftAddress, uint tokenId, address _owner) external onlyLatestVersion() {
        Claims[nftAddress][tokenId] = _owner;
        ClaimsFor[_owner].push(tokenId);
    }
}

pragma solidity 0.8.4;
import "./Ownable.sol";

contract BalanceStorage is Ownable {
    
    address public latestVersion = address(0x0);
    mapping(uint256 => bool) public usedNonces;

    struct BalanceObject {
        uint balance;
        uint blockchain;
        string name;
        string symbol;
        uint256 tokenId;
        address _address;
        uint256 _type;
    }

    struct Balances {
        BalanceObject[] balances;
    }

    mapping(address => mapping(uint256 => Balances)) internal balances;
    mapping(address => uint256[]) contractTokenIds;
    mapping(address=> mapping(address => bool)) public witnesses;
    mapping(bytes32 => mapping(address => uint256[])) public tokensToContractMap;

    constructor() {
        
    }
    
    modifier onlyLatestVersion() {
       require(msg.sender == latestVersion || msg.sender == owner, 'Not Owner or Latest version');
        _;
    }

    function addWitness(address nftAddress, address _witness) public onlyLatestVersion {
        witnesses[nftAddress][_witness] = true;
    }

    function removeWitness(address nftAddress, address _witness) public onlyLatestVersion {
        witnesses[nftAddress][_witness] = false;
    }

    function isWitness(address nftAddress, address witness) public view onlyLatestVersion returns (bool) {
        return witnesses[nftAddress][witness];
    }

    function upgradeVersion(address _newVersion) public {
        require(msg.sender == owner || (msg.sender == _newVersion && latestVersion == address(0x0) || msg.sender == latestVersion), 'Only owner can upgrade');
        latestVersion = _newVersion;
    }

    function getBalance(address nftAddress, uint256 tokenId) public view onlyLatestVersion returns (Balances memory) {
        return balances[nftAddress][tokenId];
    } 

    function getAssetsForContract(address nftAddress) public view onlyLatestVersion returns (uint256[] memory) {
        return contractTokenIds[nftAddress];
    }

    function getAssetsForContractAtIndex(address nftAddress, uint256 index) public view onlyLatestVersion returns (uint256) {
        return contractTokenIds[nftAddress][index];
    }

    function usedNonce(uint256 nonce) public view onlyLatestVersion returns (bool) {
        return usedNonces[nonce];
    }

    function getTokensFromMap(address nftAddress, bytes32 token) public view onlyLatestVersion returns(uint256[] memory) {
        return tokensToContractMap[token][nftAddress];
    }

    function addBalanceToAsset(address nftAddress, uint256 tokenId, Balances calldata balance) public onlyLatestVersion {
         balances[nftAddress][tokenId] = balance;
         contractTokenIds[nftAddress].push(tokenId);
    }

    function addTokenToMap(address nftAddress, bytes32 token, uint256 tokenId) public onlyLatestVersion {
        tokensToContractMap[token][nftAddress].push(tokenId);
    }

    function addNonce(uint256 nonce) public onlyLatestVersion returns (bool) {
        require(!usedNonces[nonce], 'Nonce already used');
        return usedNonces[nonce] = true;
    }
    
}

pragma solidity 0.8.4;
import "./IERC721.sol";
import "./Ownable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";
import "./HasRegistration.sol";

interface IStorage {
    function getDead() external view returns(address);
    function addToLegacy(address nftAddress, bytes32 root) external;
    function addToLegacyClaimedBy(address nftAddress, bytes32 root) external;
    function getLegacyClaims(address nftAddress) external view returns (bytes32);
    function getLegacyClaimsBy(address nftAddress) external view returns (bytes32);
    function addToClaims(address nftAddress, uint tokenId, address _owner) external;
    function getClaims(address nftAddress, uint tokenId) external view returns (address);
    function getClaimsFor(address _owner) external view returns (uint256[] memory);
    function getBurnAddresses() external view returns (address[] memory);
    function addToBurnAddresses(address burnAddress) external;
    function upgradeVersion(address _newVersion) external;
}

contract Claimed is ReentrancyGuard, HasRegistration {
    
    address StorageAddress;
    bool initialized = false;
    bool canClaim = true;
    
    constructor(address storageContract) {
        StorageAddress = storageContract;
        initialize();
    }
    
    function initialize() public {
        require(!initialized, 'already initialized');
        IStorage _storage = IStorage(StorageAddress);
        _storage.upgradeVersion(address(this));
        initialized = true;
    }
    
    function isBurnAddress(address needle) public view returns (bool) {
        address[] memory BurnAddresses = IStorage(StorageAddress).getBurnAddresses();
        for (uint i=0; i < BurnAddresses.length; i++) {
            if (BurnAddresses[i] == needle) {
                return true;
            }
        }
        return false;
    }

    function toggleCanClaim() public onlyOwner {
        canClaim = !canClaim;
    }
    
    function claim(address nftAddress, uint tokenId, address _claimedBy) public nonReentrant isRegisteredContract(_msgSender()) {        
        if (canClaim) {
            IStorage(StorageAddress).addToClaims(nftAddress, tokenId, _claimedBy);
        } else { 
            revert("Claiming is turned off");
        }
    }
    
    function isClaimed(address nftAddress, uint tokenId, bytes32[] calldata proof ) public view returns(bool) {
        bytes32 _hash = keccak256(abi.encodePacked(tokenId));
        IERC721 token = IERC721(nftAddress);        
        if (proof.length == 0) {
            bool claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId) != address(0);
            bool addressClaimed = false;
            try token.ownerOf(tokenId) returns (address _owner) {
                if (isBurnAddress(_owner)) {
                    addressClaimed = true;
                }
            } catch {}
            return addressClaimed || claimed;
        } else {
            bytes32 root = IStorage(StorageAddress).getLegacyClaims(nftAddress);
            return verifyScript(root, _hash, proof);
        }
    }

    function getClaimsFor(address _owner) public view returns (uint256[] memory) {
        return IStorage(StorageAddress).getClaimsFor(_owner);
    }

    function getLegacyClaims(address nftAddress) external view returns(bytes32) {
        return IStorage(StorageAddress).getLegacyClaims(nftAddress);
    }
    
    function claimedBy(address nftAddress, uint tokenId) public view returns (address _owner, string memory _type) {
        address claimed = IStorage(StorageAddress).getClaims(nftAddress, tokenId);
        if (claimed != address(0)) {
            return (claimed, "record");
        } else {
            return (address(0), "unknown");
        }
    }

    function legacyClaimedBy(address nftAddress, address claimant, uint tokenId, bytes32[] calldata proof) public view returns (address _owner, string memory _type) {
        bytes32 root = IStorage(StorageAddress).getLegacyClaimsBy(nftAddress);
        bytes32 _hash = keccak256(abi.encodePacked(claimant, tokenId));
        require(verifyScript(root, _hash, proof), "invalid proof");
        return (claimant, 'legacy');
    }

    function addLegacy(address nftAddress, bytes32 root) onlyOwner public {
        IStorage(StorageAddress).addToLegacy(nftAddress, root);        
    }

    function addLegacyClaimedBy(address nftAddress, bytes32 root) onlyOwner public {
        IStorage(StorageAddress).addToLegacyClaimedBy(nftAddress, root);        
    }

    function verifyScript(bytes32 root, bytes32 _hash, bytes32[] calldata proof) public pure returns (bool) {
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (_hash <= proofElement) {
                _hash = optihash(_hash, proofElement);
            } else {
                _hash = optihash(proofElement, _hash);
            }
        }
        return _hash == root;
    }
    // memory optimization from: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/3039
    function optihash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        assembly {
        mstore(0x00, a)
        mstore(0x20, b)
        value := keccak256(0x00, 0x40)
        }
    }

}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.8.4;
import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./BasicERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";

contract NFTrade_v2 is Context, Ownable, ReentrancyGuard {
    
    address resolver;
    bool public initialized;
    address public paymentAddress = address(this);
    address public recipientAddress;
    uint256 public makeOfferPrice = 0;
    uint256 public acceptOfferPrice = 0;
    uint public percentageFee = 0;
    bool public payToAcceptOffer = false;
    bool public payToMakeOffer = false;
    bool public canOfferERC20 = false;
    bool public takePercentageOfERC20 = false;
    bool public locked = false;
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    using SafeMath for uint;

    struct Offer {
        uint tokenId;
        address _from;
        address token;
        uint amount;
    }
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    mapping(address => mapping(uint => Offer[])) offers;
    mapping(address => mapping(uint => Offer[])) rejected;
    mapping(address => mapping(address => mapping(uint => Offer[]))) offered;
    mapping(address => mapping(uint => Offer[])) accepted;
    
    modifier notLocked() {
        require(!locked, "Contract is locked");
        _;
    }
    
    constructor(address _paymentAddress, address _recipientAddress) {
        init(_paymentAddress, _recipientAddress);
    }
    
    function init(address _paymentAddress, address _recipientAddress) public {
        require(!initialized, 'Already initialized');
        initialized = true;
        owner = payable(msg.sender); // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
        paymentAddress = _paymentAddress;
        recipientAddress = _recipientAddress;
    }
    
    function getVersion() public pure returns (uint) {
        return 1;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    event OfferAccepted(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 _amount);
    function acceptOffer(address token, uint _tokenId, uint index) public notLocked nonReentrant {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken1 = IERC721(token);
        IERC721 nftToken2 = IERC721(_offer.token);

        require(!checkInterface(token, _INTERFACE_ID_ERC20), 'not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'Sender is not owner of NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');
        }

        require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');

        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            require(IERC20Token(_offer.token).balanceOf(_offer._from) >= _offer.amount, 'Not Enough Offer Balance');
            require(IERC20Token(_offer.token).allowance(_offer._from, address(this)) >= _offer.amount, 'Not Enough Offer Allowance');
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            require(nftToken2.balanceOf(_offer._from, _offer.tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        } else {
            require(nftToken2.ownerOf(_offer.tokenId) == _offer._from, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        }        
        if (acceptOfferPrice > 0 && payToAcceptOffer) {
            IERC20Token paymentToken = IERC20Token(paymentAddress);
            require(paymentToken.allowance(msg.sender, address(this)) >= acceptOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= acceptOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), acceptOfferPrice), 'Payment error');
        }
        
        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            if (takePercentageOfERC20 && percentageFee > 0) {
                uint fee = fromPercent(_offer.amount, percentageFee);
                uint value = _offer.amount.sub(fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, address(recipientAddress), fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, value);
            } else {
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, _offer.amount);
            }
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            IERC1155(_offer.token).safeTransferFrom(_offer._from, msg.sender, _offer.tokenId, _offer.amount, "");
        } else {
            nftToken2.safeTransferFrom(_offer._from, msg.sender, _offer.tokenId);
        }

        if (checkInterface(token, _INTERFACE_ID_ERC20)) {
            // IERC20Token(token).transferFrom(msg.sender,  _offer._from, _offer.amount);
            revert('not allowed to make offers for erc20');
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            IERC1155(token).safeTransferFrom(msg.sender, _offer._from, _tokenId, _offer.amount, "");
        } else {
            nftToken1.safeTransferFrom(msg.sender, _offer._from, _tokenId);
        }
        
        delete offers[token][_tokenId];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
        accepted[token][_tokenId].push(_offer);
        emit OfferAccepted(_offer.token, _offer.tokenId, token, _tokenId, _offer.amount);
    }
    
    event OfferAdded(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount);
    function addOffer(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount) public notLocked nonReentrant {
        IERC721 nftToken1 = IERC721(token);
        IERC20Token paymentToken = IERC20Token(paymentAddress);

        // require(!checkInterface(_forNft, _INTERFACE_ID_ERC20), 'Not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC20) && canOfferERC20) {            
            require(IERC20Token(token).balanceOf(msg.sender) >= amount, 'Not Enough Balance');
            require(IERC20Token(token).allowance(msg.sender, address(this)) >= amount, 'Not Enough Allowance');
        } else if(checkInterface(token, _INTERFACE_ID_ERC20) && !canOfferERC20) {
            revert("Not allowed to make offers of erc20");
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender, 'Sender not owner of NFT');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        }

        if (makeOfferPrice > 0 && payToMakeOffer) {
            require(paymentToken.allowance(msg.sender, address(this)) >= makeOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= makeOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(recipientAddress), makeOfferPrice), 'Payment error');
        }
        offers[_forNft][_for].push(Offer(_tokenId, msg.sender, token, amount));
        offered[token][msg.sender][_tokenId].push(Offer(_for, msg.sender, _forNft, amount));
        emit OfferAdded(token, _tokenId, _forNft, _for, amount);
    }
    
    function rejectOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken = IERC721(token);

        require(nftToken.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');

        rejected[token][_tokenId].push(_offer);
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function withdrawOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        
        require(_offer._from == msg.sender, 'Not senders offer to withdraw');
        
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function togglePayToMakeOffer() public onlyOwner {
        payToMakeOffer = !payToMakeOffer;
    }
    function togglePayToAcceptOffer() public onlyOwner {
        payToAcceptOffer = !payToAcceptOffer;
    }
    
    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    function toggleCanOfferERC20() public onlyOwner {
        canOfferERC20 = !canOfferERC20;
    }

    function toggleTakePercentageOfERC20() public onlyOwner {
        takePercentageOfERC20 = !takePercentageOfERC20;
    }
    
    function getOffer(address token, uint256 _tokenId, uint index) public view returns (Offer memory) {
        return offers[token][_tokenId][index];
    }
    
    function getOffered(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return offered[token][msg.sender][_tokenId];
    }
    
    function getOfferCount(address token, uint256 _tokenId) public view returns (uint) {
        return offers[token][_tokenId].length;
    }
    
    function getAcceptedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return accepted[token][_tokenId];
    }
    
    function getRejectedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return rejected[token][_tokenId];
    }
    
    function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee) public onlyOwner {
        makeOfferPrice = _makeOfferPrice;
        acceptOfferPrice = _acceptOfferPrice;
        percentageFee = _percentageFee;
    }
    
    function changeRecipientAddress(address _recipientAddress) public onlyOwner {
       recipientAddress = _recipientAddress;
    }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    function fromPercent(uint total, uint percent) public pure returns (uint) {
        return total.mul(percent).div(100);
    }

    function toPercent(uint amount, uint total) public pure returns (uint) {
        return amount.mul(100).div(total);
    }
}

// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.8.4;

import "./IERC721.sol";
import "./IERC1155.sol";
import "./SafeMath.sol";
import "./BasicERC20.sol";
import "./ReentrancyGuard.sol";
import "./Context.sol";
import "./Ownable.sol";



contract NFTrade_v3 is Context, Ownable, ReentrancyGuard {
    
    address resolver;
    bool public initialized;
    bool public locked = false;
    
    bytes4 private constant _INTERFACE_ID_ERC1155 = 0xd9b67a26;
    bytes4 private constant _INTERFACE_ID_ERC20 = 0x74a1476f;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    using SafeMath for uint;

    struct Offer {
        uint tokenId;
        address _from;
        address token;
        uint amount;
    }
    
    struct Config {
        address recipientAddress;
        address paymentAddress;
        uint256 makeOfferPrice;
        uint256 acceptOfferPrice;
        uint percentageFee;
        bool payToAcceptOffer;
        bool payToMakeOffer;
        bool canOfferERC20;
        bool takePercentageOfERC20;
        bool Active;
        bytes32 Parent;
        uint ParentPercentage;
    }
    
    // event for EVM logging
    mapping(uint256 => Config) configs;
    mapping(address => mapping(uint => Offer[])) offers;
    mapping(address => mapping(uint => Offer[])) rejected;
    mapping(address => mapping(address => mapping(uint => Offer[]))) offered;
    mapping(address => mapping(uint => Offer[])) accepted;
    
    modifier notLocked() {
        require(!locked, "Contract is locked");
        _;
    }
    
    constructor(address _paymentAddress, address _recipientAddress) {
        init(_paymentAddress, _recipientAddress);
    }
    
    function init(address _paymentAddress, address _recipientAddress) public {
        require(!initialized, 'Already initialized');
        initialized = true;
        configs[1337] = Config(_recipientAddress, _paymentAddress, 0, 0, 0, false, false, false, false, true, 0, 0);
    }
    
    function getVersion() public pure returns (uint) {
        return 1;
    }
    
    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
    event OfferAccepted(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 _amount);
    function acceptOffer(address token, uint _tokenId, uint index, uint apikey) public notLocked nonReentrant {
        Config memory _config = configs[apikey];
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken1 = IERC721(token);
        IERC721 nftToken2 = IERC721(_offer.token);

        require(!checkInterface(token, _INTERFACE_ID_ERC20), 'not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'Sender is not owner of NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');
        }

        require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');

        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            require(IERC20Token(_offer.token).balanceOf(_offer._from) >= _offer.amount, 'Not Enough Offer Balance');
            require(IERC20Token(_offer.token).allowance(_offer._from, address(this)) >= _offer.amount, 'Not Enough Offer Allowance');
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            require(nftToken2.balanceOf(_offer._from, _offer.tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        } else {
            require(nftToken2.ownerOf(_offer.tokenId) == _offer._from, 'NFT not owned by offerer');
            require(nftToken2.isApprovedForAll(_offer._from, address(this)), 'Handler unable to transfer offer NFT');
        }        
        if (_config.acceptOfferPrice > 0 && _config.payToAcceptOffer) {
            IERC20Token paymentToken = IERC20Token(_config.paymentAddress);
            require(paymentToken.allowance(msg.sender, address(this)) >= _config.acceptOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= _config.acceptOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(_config.recipientAddress), _config.acceptOfferPrice), 'Payment error');
        }
        
        if (checkInterface(_offer.token, _INTERFACE_ID_ERC20)) {
            if (_config.takePercentageOfERC20 && _config.percentageFee > 0) {
                uint fee = fromPercent(_offer.amount, _config.percentageFee);
                uint value = _offer.amount.sub(fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, address(_config.recipientAddress), fee);
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, value);
            } else {
                IERC20Token(_offer.token).transferFrom(_offer._from, msg.sender, _offer.amount);
            }
        } else if (checkInterface(_offer.token, _INTERFACE_ID_ERC1155)){
            IERC1155(_offer.token).safeTransferFrom(_offer._from, msg.sender, _offer.tokenId, _offer.amount, "");
        } else {
            nftToken2.safeTransferFrom(_offer._from, msg.sender, _offer.tokenId);
        }

        if (checkInterface(token, _INTERFACE_ID_ERC20)) {
            // IERC20Token(token).transferFrom(msg.sender,  _offer._from, _offer.amount);
            revert('not allowed to make offers for erc20');
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            IERC1155(token).safeTransferFrom(msg.sender, _offer._from, _tokenId, _offer.amount, "");
        } else {
            nftToken1.safeTransferFrom(msg.sender, _offer._from, _tokenId);
        }
        
        delete offers[token][_tokenId];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
        accepted[token][_tokenId].push(_offer);
        emit OfferAccepted(_offer.token, _offer.tokenId, token, _tokenId, _offer.amount);
    }
    
    event OfferAdded(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount);
    function addOffer(address token, uint256 _tokenId, address _forNft, uint256 _for, uint256 amount, uint256 apikey) public notLocked nonReentrant {
        Config memory _config = configs[apikey];
        IERC721 nftToken1 = IERC721(token);
        IERC20Token paymentToken = IERC20Token(_config.paymentAddress);

        // require(!checkInterface(_forNft, _INTERFACE_ID_ERC20), 'Not allowed to make offers for erc20');

        if (checkInterface(token, _INTERFACE_ID_ERC20) && _config.canOfferERC20) {
            require(IERC20Token(token).balanceOf(msg.sender) >= amount, 'Not Enough Balance');
            require(IERC20Token(token).allowance(msg.sender, address(this)) >= amount, 'Not Enough Allowance');
        } else if(checkInterface(token, _INTERFACE_ID_ERC20) && !_config.canOfferERC20) {
            revert("Not allowed to make offers of erc20");
        } else if (checkInterface(token, _INTERFACE_ID_ERC1155)){
            require(nftToken1.balanceOf(msg.sender, _tokenId) > 0, 'NFT not owned by offerer');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        } else {
            require(nftToken1.ownerOf(_tokenId) == msg.sender, 'Sender not owner of NFT');
            require(nftToken1.isApprovedForAll(msg.sender, address(this)), 'Handler unable to transfer NFT');
        }

        if (_config.makeOfferPrice > 0 && _config.payToMakeOffer) {
            require(paymentToken.allowance(msg.sender, address(this)) >= _config.makeOfferPrice, 'Handler unable take payment for offer');
            require(paymentToken.balanceOf(msg.sender) >= _config.makeOfferPrice, 'Insufficient Balance for payment');
            require(paymentToken.transferFrom(msg.sender, address(_config.recipientAddress), _config.makeOfferPrice), 'Payment error');
        }
        offers[_forNft][_for].push(Offer(_tokenId, msg.sender, token, amount));
        offered[token][msg.sender][_tokenId].push(Offer(_for, msg.sender, _forNft, amount));
        emit OfferAdded(token, _tokenId, _forNft, _for, amount);
    }
    
    function rejectOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        IERC721 nftToken = IERC721(token);

        require(nftToken.ownerOf(_tokenId) == msg.sender,'Sender is not owner of NFT');

        rejected[token][_tokenId].push(_offer);
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    function withdrawOffer(address token, uint256 _tokenId, uint index) public notLocked {
        Offer memory _offer = offers[token][_tokenId][index];
        
        require(_offer._from == msg.sender, 'Not senders offer to withdraw');
        
        delete offers[token][_tokenId][index];
        delete offered[_offer.token][_offer._from][_offer.tokenId];
    }
    
    // function togglePayToMakeOffer() public onlyOwner {
    //     togglePayToMakeOffer(1337);
    // }
    
    function togglePayToMakeOffer(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.payToMakeOffer = !_config.payToMakeOffer;
    }
    
    // function togglePayToAcceptOffer() public onlyOwner {
    //     togglePayToAcceptOffer(1337);
    // }
    
    function togglePayToAcceptOffer(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.payToAcceptOffer = !_config.payToAcceptOffer;
    }
    
    function toggleLocked() public onlyOwner {
        locked = !locked;
    }

    // function toggleCanOfferERC20() public onlyOwner {
    //     toggleCanOfferERC20(1337);
    // }
    
    function toggleCanOfferERC20(uint256 apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.canOfferERC20 = !_config.canOfferERC20;
    }

    // function toggleTakePercentageOfERC20() public onlyOwner {
    //     toggleTakePercentageOfERC20(1337);
    // }
    
    function toggleTakePercentageOfERC20(uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.takePercentageOfERC20 = !_config.takePercentageOfERC20;
    }
    
    function getOffer(address token, uint256 _tokenId, uint index) public view returns (Offer memory) {
        return offers[token][_tokenId][index];
    }

    function getConfig(uint256 apikey) public view returns (Config memory) {
        return configs[apikey]; 
    }
    
    function getOffered(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return offered[token][msg.sender][_tokenId];
    }
    
    function getOfferCount(address token, uint256 _tokenId) public view returns (uint) {
        return offers[token][_tokenId].length;
    }
    
    function getAcceptedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return accepted[token][_tokenId];
    }
    
    function getRejectedOffers(address token, uint256 _tokenId) public view returns (Offer[] memory) {
        return rejected[token][_tokenId];
    }
    
    // function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee) public onlyOwner {
    //     changeOfferPrices(_makeOfferPrice, _acceptOfferPrice, _percentageFee, 1337);
    // }
    function changeOfferPrices(uint256 _makeOfferPrice, uint256 _acceptOfferPrice, uint _percentageFee, uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.makeOfferPrice = _makeOfferPrice;
        _config.acceptOfferPrice = _acceptOfferPrice;
        _config.percentageFee = _percentageFee;
    }
    
    // function changeRecipientAddress(address _recipientAddress) public onlyOwner {
    //     changeRecipientAddress(_recipientAddress, 1337);
    // }
    
    function changeRecipientAddress(address _recipientAddress, uint apikey) public onlyOwner {
        Config storage _config = configs[apikey];
        _config.recipientAddress = _recipientAddress;
    }

    function checkInterface(address token, bytes4 _interface) public view returns (bool) {
        IERC165 nftToken = IERC165(token);
        bool supportsInterface = false;
        try  nftToken.supportsInterface(_interface) returns (bool _supports) {
            supportsInterface = _supports;
        } catch {
            if (_interface == 0x74a1476f) {
                supportsInterface = true;
            }
        }
        return supportsInterface;
    }

    function fromPercent(uint total, uint percent) public pure returns (uint) {
        return total.mul(percent).div(100);
    }

    function toPercent(uint amount, uint total) public pure returns (uint) {
        return amount.mul(100).div(total);
    }
}

pragma solidity 0.8.4;
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
contract ReentrancyGuard {
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

    constructor ()  {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
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

pragma solidity 0.8.4;
/**
 * @dev The contract has an owner address, and provides basic authorization control whitch
 * simplifies the implementation of user permissions. This contract is based on the source code at:
 * https://github.com/OpenZeppelin/openzeppelin-solidity/blob/master/contracts/ownership/Ownable.sol
 */
contract Ownable {

  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor()
  {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() virtual
  {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(
    address _newOwner
  )
    virtual
    public
    onlyOwner
  {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

pragma solidity 0.8.4;
import "./HasRegistration.sol";
import "./IHandlerCallback.sol";
import "./ERC165.sol";

contract HasCallbacks is HasRegistration {

    bool allowCallbacks = true;
    
    event CallbackExecuted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type, bytes returnData);
    event CallbackReverted(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    event CallbackFailed(address _from, address _to, address target, uint256 tokenId, bytes4 targetFunction, IHandlerCallback.CallbackType _type);
    
    mapping(address => mapping(uint256 => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[]))) public registeredCallbacks;
    mapping(address => mapping(IHandlerCallback.CallbackType => IHandlerCallback.Callback[])) public registeredWildcardCallbacks;    

    modifier isOwnerOrCallbackRegistrant(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) {
        bool registrant = false;
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            registrant = registeredCallbacks[_contract][tokenId][_type][index].registrant == _msgSender();
        } else if(hasWildcardCallback(_contract, target, _type)) {
           registrant = registeredWildcardCallbacks[_contract][_type][index].registrant == _msgSender();
        }        
        require(_msgSender() == owner || registrant, "Not owner or Callback registrant");
        _;
    }

    function executeCallbacks(address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) public isRegisteredContract(_msgSender()) {
        if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_msgSender()][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_msgSender()][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
        }        
    }

    function executeCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal isRegisteredContract(_nftAddress) {
         if (allowCallbacks) {
            IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_nftAddress][tokenId][_type];
            if (callbacks.length > 0) executeCallbackLoop(callbacks, _from, _to, tokenId, _type);
            IHandlerCallback.Callback[] memory wildCardCallbacks = registeredWildcardCallbacks[_nftAddress][_type];
            if (wildCardCallbacks.length > 0) executeCallbackLoop(wildCardCallbacks, _from, _to, tokenId, _type);
         }
    }

    function executeCallbackLoop(IHandlerCallback.Callback[] memory callbacks, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) internal {
        bool canRevert = false;  
        for (uint256 i = 0; i < callbacks.length; ++i) {            
            IHandlerCallback.Callback memory cb = callbacks[i];    
            canRevert = cb.canRevert;
            if (cb.target != address(0)){
                (bool success, bytes memory returnData) =
                    address(cb.target).call(
                        abi.encodePacked(
                            cb.targetFunction,
                            abi.encode(_from),
                            abi.encode(_to),
                            abi.encode(tokenId)
                        )
                    );
                if (success) {
                    emit CallbackExecuted(_from, _to, cb.target, tokenId, cb.targetFunction, _type, returnData);
                } else if (canRevert) {
                    emit CallbackReverted(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                    revert("Callback Reverted");
                } else {
                    emit CallbackFailed(_from, _to, cb.target, tokenId, cb.targetFunction, _type);
                }
            }
        }
    }

    function toggleAllowCallbacks() public onlyOwner {
        allowCallbacks = !allowCallbacks;
    }

    function registerCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredCallbacks[_contract][tokenId][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function registerWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type, bytes4 _function, bool allowRevert) isRegisteredContract(_contract) onlyOwner public {
        registeredWildcardCallbacks[_contract][_type].push(IHandlerCallback.Callback(_contract, _msgSender(), target, _function, allowRevert ));
    }

    function hasCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) public view returns (bool ) {
        bool found = hasTokenIdCallback(_contract, target, tokenId, _type);
        if (found) return true;
        return hasWildcardCallback(_contract, target, _type);
    }

    function hasTokenIdCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredCallbacks[_contract][tokenId][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function hasWildcardCallback(address _contract, address target, IHandlerCallback.CallbackType _type) internal view returns(bool) {
        bool found = false;
        IHandlerCallback.Callback[] memory callbacks = registeredWildcardCallbacks[_contract][_type];
        for (uint256 i = 0; i < callbacks.length; ++i) {
            if (callbacks[i].target == target) {
                found = true;
            }
        }
        return found;
    }

    function unregisterCallback(address _contract, address target, uint256 tokenId, IHandlerCallback.CallbackType _type, uint256 index) public isOwnerOrCallbackRegistrant(_contract, target, tokenId, _type, index){
        if (hasTokenIdCallback(_contract, target, tokenId, _type)) {
            delete registeredCallbacks[_contract][tokenId][_type][index];
        }
        else if(hasWildcardCallback(_contract, target, _type)) {
            delete registeredWildcardCallbacks[_contract][_type][index];
        }
    }

    uint256 public ticks = 0;
    uint256 public lastTokenId = 0;
    address public lastTo;
    address public lastFrom;
    address public lastContract;

    function testCallback(address _from, address _to, uint256 tokenId) public {
        ticks++;
        lastTokenId = tokenId;
        lastTo = _to;
        lastFrom = _from;  
        lastContract = _msgSender();
    }

    function testRevertCallback(address _from, address _to, uint256 tokenId) public pure {
        _from = address(0);
        _to = address(0);
        tokenId = 0;
        revert("reverted by design");
    }

    function getTestSelector() public view returns (bytes4) {
        return HasCallbacks(this).testCallback.selector;
    }

    function getTestRevertSelector() public view returns (bytes4) {
        return HasCallbacks(this).testRevertCallback.selector;
    }
}

pragma solidity 0.8.4;

interface IHandlerCallback {
    enum CallbackType {
        MINT, TRANSFER, CLAIM
    }

    struct Callback {
        address vault;
        address registrant;
        address target;
        bytes4 targetFunction;
        bool canRevert;
    }
    function executeCallbacksInternal(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeCallbacks(address _from, address _to, uint256 tokenId, CallbackType _type) external;
    function executeStoredCallbacksInternal(address _nftAddress, address _from, address _to, uint256 tokenId, IHandlerCallback.CallbackType _type) external;
    
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
        assembly {
            size := extcodesize(account)
        }
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

pragma solidity 0.8.4;
import "./ERC165.sol";
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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
    function mint(address _to, uint256 _tokenId, uint256 _amount) external;
    function burn(address _from, uint256 _tokenId, uint256 _amount) external;
}

pragma solidity 0.8.4;
import "./Context.sol";
import "./Ownable.sol";

interface IRegistrationStorage {
    function upgradeVersion(address _newVersion) external;
}

contract HasRegistration is Context, Ownable {

    // address StorageAddress;
    // bool initialized = false;

    mapping(address => uint256) public registeredContracts; // 0 EMPTY, 1 ERC1155, 2 ERC721, 3 HANDLER, 4 ERC20, 5 BALANCE, 6 CLAIM, 7 UNKNOWN, 8 FACTORY, 9 STAKING
    mapping(uint256 => address[]) public registeredOfType;
    
    uint256 public contractCount = 0;

    modifier isRegisteredContract(address _contract) {
        require(registeredContracts[_contract] > 0, "Contract is not registered");
        _;
    }

    modifier isRegisteredContractOrOwner(address _contract) {
        require(registeredContracts[_contract] > 0 || owner == _msgSender(), "Contract is not registered nor Owner");
        _;
    }

    // constructor(address storageContract) {
    //     StorageAddress = storageContract;
    // }

    // function initialize() public {
    //     require(!initialized, 'already initialized');
    //     IRegistrationStorage _storage = IRegistrationStorage(StorageAddress);
    //     _storage.upgradeVersion(address(this));
    //     initialized = true;
    // }

    function registerContract(address _contract, uint _type) public isRegisteredContractOrOwner(_msgSender()) {
        contractCount++;
        registeredContracts[_contract] = _type;
        registeredOfType[_type].push(_contract);
    }

    function unregisterContract(address _contract, uint256 index) public onlyOwner isRegisteredContract(_contract) {
        require(contractCount > 0, 'No vault contracts to remove');
        delete registeredOfType[registeredContracts[_contract]][index];
        delete registeredContracts[_contract];
        contractCount--;
    }

    function isRegistered(address _contract, uint256 _type) public view returns (bool) {
        return registeredContracts[_contract] == _type;
    }
}

pragma solidity 0.8.4;
import "./Context.sol";
import "./Ownable.sol";

interface IIsSerialized {
    function isSerialized() external view returns (bool);
    function getSerial(uint256 tokenId, uint256 index) external view returns (uint256);
    function getFirstSerialByOwner(address owner, uint256 tokenId) external view returns (uint256);
    function getOwnerOfSerial(uint256 serialNumber) external view returns (address);
    function getTokenIdForSerialNumber(uint256 serialNumber) external view returns (uint256);
}

contract IsSerialized is Context, Ownable {
    bool internal serialized;
    bool internal hasSerialized = false;
    mapping(uint256 => uint256[]) internal tokenIdToSerials;
    mapping(uint256 => uint256) internal serialToTokenId;
    mapping(uint256 => address) internal serialToOwner;
    mapping(address => uint256) public ownerSerialCount;

    function isSerialized() public view returns (bool) {
        return serialized;
    }

    function toggleSerialization() public onlyOwner {
        require(!hasSerialized, "Already has serialized items");
        serialized = !serialized;
    }

    function mintSerial(uint256 tokenId, address owner) public onlyOwner {
        uint256 serialNumber = uint256(keccak256(abi.encode(tokenId, owner, ownerSerialCount[owner])));
        tokenIdToSerials[tokenId].push(serialNumber);
        serialToTokenId[serialNumber] = tokenId;
        serialToOwner[serialNumber] = owner;
        ownerSerialCount[owner]++;
        if (!hasSerialized) {
            hasSerialized = true;
        }
    }

    function transferSerial(uint256 serialNumber, address from, address to) internal {
        require(serialToOwner[serialNumber] == from, 'Not correct owner of serialnumber');
        serialToOwner[serialNumber] = to;
        ownerSerialCount[to]++;
        ownerSerialCount[from]--;
    }

    function getSerial(uint256 tokenId, uint256 index) public view returns (uint256) {
        if(tokenIdToSerials[tokenId].length == 0) {
            return 0;
        } else {
            return tokenIdToSerials[tokenId][index];
        }
    }

    function getFirstSerialByOwner(address owner, uint256 tokenId) public view returns (uint256) {
        for (uint256 i = 0; i < tokenIdToSerials[tokenId].length; ++i) {
           uint256 serialNumber = tokenIdToSerials[tokenId][i];
           if (serialToOwner[serialNumber] == owner) {
               return serialNumber;
           }
        }
        return 0;
    }

    function getOwnerOfSerial(uint256 serialNumber) public view returns (address) {
        return serialToOwner[serialNumber];
    }

    function getTokenIdForSerialNumber(uint256 serialNumber) public view returns (uint256) {
        return serialToTokenId[serialNumber];
    }
    
}

pragma solidity 0.8.4;
// import "./IERC1155.sol";
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

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        supportedInterfaces[interfaceId] = true;
    }
}

// File: IERC1155Receiver.sol



/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI  {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

pragma solidity 0.8.4;
contract Context {
    constructor() {}

    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }
}