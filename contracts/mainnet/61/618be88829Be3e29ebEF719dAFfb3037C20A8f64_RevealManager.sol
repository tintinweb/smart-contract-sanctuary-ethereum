// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import './OmnuumNFT1155.sol';
import './OmnuumVRFManager.sol';
import './OmnuumCAManager.sol';

/// @title RevealManager - simple proxy for reveal call
/// @author Omnuum Dev Team - <[email protected]>
/// @notice prevent direct call to VRF manager. separate concern from NFT contract and VRF contract
contract RevealManager {
    OmnuumCAManager private caManager;

    constructor(OmnuumCAManager _caManager) {
        caManager = _caManager;
    }

    /// @notice vrf request proxy function
    /// @dev check that msg.sender is owner of nft contract and nft is revealed or not
    /// @param _nftContract nft contract address
    function vrfRequest(OmnuumNFT1155 _nftContract) external payable {
        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(_nftContract.owner() == msg.sender, 'OO1');

        /// @custom:error (SE6) - NFT already revealed
        require(!_nftContract.isRevealed(), 'SE6');

        OmnuumVRFManager(caManager.getContract('VRF')).requestVRFOnce{ value: msg.value }(address(_nftContract), 'REVEAL_PFP');
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol';
import '../utils/OwnableUpgradeable.sol';
import './SenderVerifier.sol';
import './OmnuumMintManager.sol';
import './OmnuumCAManager.sol';
import './TicketManager.sol';
import './OmnuumWallet.sol';

/// @title OmnuumNFT1155 - nft contract written based on ERC1155
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Omnuum specific nft contract which pays mint fee to omnuum but can utilize omnuum protocol
contract OmnuumNFT1155 is ERC1155Upgradeable, ReentrancyGuardUpgradeable, OwnableUpgradeable {
    using AddressUpgradeable for address;
    using AddressUpgradeable for address payable;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private _tokenIdCounter;

    OmnuumCAManager private caManager;
    OmnuumMintManager private mintManager;

    /// @notice max amount can be minted
    uint32 public maxSupply;

    /// @notice whether revealed or not
    bool public isRevealed;
    string private coverUri;
    address private omA;

    event Uri(address indexed nftContract, string uri);
    event FeePaid(address indexed payer, uint256 amount);
    event TransferBalance(uint256 value, address indexed receiver);
    event EtherReceived(address indexed sender);

    /// @notice constructor function for upgradeable
    /// @param _caManagerAddress ca manager address
    /// @param _omA omnuum company address
    /// @param _maxSupply max amount can be minted
    /// @param _coverUri metadata uri for before reveal
    /// @param _prjOwner project owner address to transfer ownership
    function initialize(
        address _caManagerAddress,
        address _omA, // omnuum deployer
        uint32 _maxSupply,
        string calldata _coverUri,
        address _prjOwner
    ) public initializer {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_caManagerAddress != address(0), 'AE1');
        require(_prjOwner != address(0), 'AE1');

        __ERC1155_init('');
        __ReentrancyGuard_init();
        __Ownable_init();

        maxSupply = _maxSupply;
        omA = _omA;

        caManager = OmnuumCAManager(_caManagerAddress);
        mintManager = OmnuumMintManager(caManager.getContract('MINTMANAGER'));
        coverUri = _coverUri;
    }

    /// @dev send fee to omnuum wallet
    function sendFee(uint32 _quantity) internal {
        uint8 rateDecimal = mintManager.rateDecimal();
        uint256 minFee = mintManager.minFee();
        uint256 feeRate = mintManager.getFeeRate(address(this));
        uint256 calculatedFee = (msg.value * feeRate) / 10**rateDecimal;
        uint256 minimumFee = _quantity * minFee;

        uint256 feePayment = calculatedFee > minimumFee ? calculatedFee : minimumFee;

        OmnuumWallet(payable(caManager.getContract('WALLET'))).makePayment{ value: feePayment }('MINT_FEE', '');

        emit FeePaid(msg.sender, feePayment);
    }

    /// @notice public minting function
    /// @param _quantity minting quantity
    /// @param _groupId public minting schedule id
    /// @param _payload payload for authenticate that mint call happen through omnuum server to guarantee exact schedule time
    function publicMint(
        uint32 _quantity,
        uint16 _groupId,
        SenderVerifier.Payload calldata _payload
    ) external payable nonReentrant {
        /// @custom:error (MT9) - Minter cannot be CA
        require(!msg.sender.isContract(), 'MT9');

        SenderVerifier(caManager.getContract('VERIFIER')).verify(omA, msg.sender, 'MINT', _groupId, _payload);
        mintManager.preparePublicMint(_groupId, _quantity, msg.value, msg.sender);

        mintLoop(msg.sender, _quantity);
        sendFee(_quantity);
    }

    /// @notice ticket minting function
    /// @param _quantity minting quantity
    /// @param _ticket ticket struct which proves authority to mint
    /// @param _payload payload for authenticate that mint call happen through omnuum server to guarantee exact schedule time
    function ticketMint(
        uint32 _quantity,
        TicketManager.Ticket calldata _ticket,
        SenderVerifier.Payload calldata _payload
    ) external payable nonReentrant {
        /// @custom:error (MT9) - Minter cannot be CA
        require(!msg.sender.isContract(), 'MT9');

        /// @custom:error (MT5) - Not enough money
        require(_ticket.price * _quantity <= msg.value, 'MT5');

        SenderVerifier(caManager.getContract('VERIFIER')).verify(omA, msg.sender, 'TICKET', _ticket.groupId, _payload);
        TicketManager(caManager.getContract('TICKET')).useTicket(omA, msg.sender, _quantity, _ticket);

        mintLoop(msg.sender, _quantity);
        sendFee(_quantity);
    }

    /// @notice direct mint, neither public nor ticket
    /// @param _to mint destination address
    /// @param _quantity minting quantity
    function mintDirect(address _to, uint32 _quantity) external payable {
        /// @custom:error (OO3) - Only Omnuum or owner can change
        require(msg.sender == address(mintManager), 'OO3');
        mintLoop(_to, _quantity);

        sendFee(_quantity);
    }

    /// @dev minting utility function, manage token id
    /// @param _to mint destination address
    /// @param _quantity minting quantity
    function mintLoop(address _to, uint32 _quantity) internal {
        /// @custom:error (MT3) - Remaining token count is not enough
        require(_tokenIdCounter.current() + _quantity <= maxSupply, 'MT3');
        for (uint32 i = 0; i < _quantity; i++) {
            _tokenIdCounter.increment();
            _mint(_to, _tokenIdCounter.current(), 1, '');
        }
    }

    /// @notice set uri for reveal
    /// @param __uri uri of revealed metadata
    function setUri(string memory __uri) external onlyOwner {
        _setURI(__uri);
        isRevealed = true;
        emit Uri(address(this), __uri);
    }

    /// @notice get current metadata uri
    function uri(uint256) public view override returns (string memory) {
        return !isRevealed ? coverUri : super.uri(1);
    }

    /// @notice transfer balance of the contract to someone (maybe the project team member), including project owner him or herself
    /// @param _value - the amount of value to transfer
    /// @param _to - receiver
    function transferBalance(uint256 _value, address _to) external onlyOwner nonReentrant {
        /// @custom:error (NE4) - Insufficient balance
        require(_value <= address(this).balance, 'NE4');
        (bool withdrawn, ) = payable(_to).call{ value: _value }('');

        /// @custom:error (SE5) - Address: unable to send value, recipient may have reverted
        require(withdrawn, 'SE5');

        emit TransferBalance(_value, _to);
    }

    /// @notice a function to donate to support the project owner. Hooray~!
    receive() external payable {
        emit EtherReceived(msg.sender);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@chainlink/contracts/src/v0.8/VRFConsumerBase.sol';
import '../utils/Ownable.sol';
import './OmnuumCAManager.sol';
import './OmnuumExchange.sol';
import '../library/RevertMessage.sol';

/// @title OmnuumVRFManager - Manage VRF logic for omnuum
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Use only purpose for Omnuum
contract OmnuumVRFManager is Ownable, VRFConsumerBase {
    address private s_LINK;
    uint256 private fee;
    bytes32 private s_key_hash;
    address private omA;

    OmnuumCAManager private caManager;

    /// @notice safety margin ratio of LINK/ETH exchange rate to prevent risk of price volatility
    /// @dev 2 decimals (150 == 1.5)
    uint16 public safetyRatio = 150;

    constructor(
        address _LINK,
        address _vrf_coord,
        bytes32 _key_hash,
        uint256 _fee,
        address _omnuumCA
    ) VRFConsumerBase(_vrf_coord, _LINK) {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_LINK != address(0), 'AE1');
        require(_vrf_coord != address(0), 'AE1');
        require(_omnuumCA != address(0), 'AE1');

        s_LINK = _LINK;
        s_key_hash = _key_hash;
        fee = _fee;
        caManager = OmnuumCAManager(_omnuumCA);
    }

    /// @notice request address to request ID
    mapping(address => bytes32) public aToId;

    /// @notice request ID to request address
    mapping(bytes32 => address) public idToA;

    /// @notice request ID to topic
    mapping(bytes32 => string) public idToTopic;

    /// @dev actionType: fee, safetyRatio
    event Updated(uint256 value, string actionType);
    event RequestVRF(address indexed roller, bytes32 indexed requestId, string topic);
    event ResponseVRF(bytes32 indexed requestId, uint256 randomness, string topic, bool success, string reason);

    /// @notice request vrf call
    /// @dev only allowed contract which has VRF role
    /// @param _topic contract which will use this vrf result
    function requestVRF(string calldata _topic) external payable {
        address exchangeAddress = caManager.getContract('EXCHANGE');

        // @custom:error (OO7) - Only role owner can access
        require(caManager.hasRole(msg.sender, 'VRF'), 'OO7');

        // @custom:error (SE7) - Not enough LINK at exchange contract
        require(LINK.balanceOf(exchangeAddress) >= fee, 'SE7');

        /// @custom:dev receive link from exchange, send all balance because there isn't any withdraw feature
        OmnuumExchange(exchangeAddress).exchangeToken{ value: address(this).balance }(s_LINK, fee, address(this));

        bytes32 requestId = requestRandomness(s_key_hash, fee);
        idToA[requestId] = msg.sender;
        idToTopic[requestId] = _topic;

        emit RequestVRF(msg.sender, requestId, _topic);
    }

    /// @notice request vrf call
    /// @dev only allowed contract which has VRF role
    /// @dev Can use this function only once per target address
    /// @param _targetAddress contract which will use this vrf result
    /// @param _topic contract which will use this vrf result
    function requestVRFOnce(address _targetAddress, string calldata _topic) external payable {
        /// @custom:error (SE8) - Already used address
        require(aToId[_targetAddress] == '', 'SE8');

        address exchangeAddress = caManager.getContract('EXCHANGE');

        // @custom:error (OO7) - Only role owner can access
        require(caManager.hasRole(msg.sender, 'VRF'), 'OO7');

        /// @custom:error (SE7) - Not enough LINK at exchange contract
        require(LINK.balanceOf(exchangeAddress) >= fee, 'SE7');

        uint256 required_amount = OmnuumExchange(exchangeAddress).getExchangeAmount(address(0), s_LINK, fee);

        /// @custom:error (ARG3) - Not enough ether sent
        require(msg.value >= (required_amount * safetyRatio) / 100, 'ARG3');

        /// @custom:dev receive link from exchange, send all balance because there isn't any withdraw feature
        OmnuumExchange(exchangeAddress).exchangeToken{ value: address(this).balance }(s_LINK, fee, address(this));

        bytes32 requestId = requestRandomness(s_key_hash, fee);
        idToA[requestId] = _targetAddress;
        idToTopic[requestId] = _topic;

        emit RequestVRF(_targetAddress, requestId, _topic);
    }

    /// @notice hook function which called when vrf response received
    /// @param _requestId used to find request history and emit event for matching info
    /// @param _randomness result number of VRF
    function fulfillRandomness(bytes32 _requestId, uint256 _randomness) internal override {
        address requestAddress = idToA[_requestId];
        /// @custom:dev Not required to implement, but if developer wants to do specific action at response time, he/she should implement vrfResponse method at target contract
        bytes memory payload = abi.encodeWithSignature('vrfResponse(uint256)', _randomness);
        (bool success, bytes memory returnData) = address(requestAddress).call(payload);

        string memory reason = success ? '' : RevertMessage.parse(returnData);

        aToId[requestAddress] = _requestId;
        delete idToA[_requestId];

        emit ResponseVRF(_requestId, _randomness, idToTopic[_requestId], success, reason);
    }

    /// @notice update ChainLink VRF fee
    /// @param _fee fee of ChainLink VRF
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
        emit Updated(_fee, 'vrfFee');
    }

    /// @notice update safety ratio
    /// @param _safetyRatio  safety margin ratio of LINK/ETH exchange rate to prevent risk of price volatility
    function updateSafetyRatio(uint16 _safetyRatio) external onlyOwner {
        /// @custom:error (NE6) - Margin rate should above or equal 100
        require(_safetyRatio >= 100, 'NE6');
        safetyRatio = _safetyRatio;
        emit Updated(_safetyRatio, 'safetyRatio');
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol';
import '../utils/OwnableUpgradeable.sol';

/// @title OmnuumCAManager - Contract Manager for Omnuum Protocol
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Use only purpose for Omnuum
contract OmnuumCAManager is OwnableUpgradeable {
    using AddressUpgradeable for address;

    struct Contract {
        string topic;
        bool active;
    }

    /// @notice (omnuum contract address => (bytes32 topic => hasRole))
    mapping(address => mapping(string => bool)) public roles;

    /// @notice (omnuum contract address => (topic, active))
    mapping(address => Contract) public managerContracts;

    // @notice topic indexed mapping, (string topic => omnuum contract address)
    mapping(string => address) public indexedContracts;

    event ContractRegistered(address indexed managerContract, string topic);
    event ContractRemoved(address indexed managerContract, string topic);
    event RoleAdded(address indexed ca, string role);
    event RoleRemoved(address indexed ca, string role);

    function initialize() public initializer {
        __Ownable_init();
    }

    /// @notice Add role to multiple addresses
    /// @param _CAs list of contract address which will have specified role
    /// @param _role role name to grant permission
    function addRole(address[] calldata _CAs, string calldata _role) external onlyOwner {
        uint256 len = _CAs.length;

        for (uint256 i = 0; i < len; i++) {
            /// @custom:error (AE2) - Contract address not acceptable
            require(_CAs[i].isContract(), 'AE2');
        }

        for (uint256 i = 0; i < len; i++) {
            roles[_CAs[i]][_role] = true;
            emit RoleAdded(_CAs[i], _role);
        }
    }

    /// @notice Remove role to multiple addresses
    /// @param _CAs list of contract address which will be deprived specified role
    /// @param _role role name to be removed
    function removeRole(address[] calldata _CAs, string calldata _role) external onlyOwner {
        uint256 len = _CAs.length;
        for (uint256 i = 0; i < len; i++) {
            /// @custom:error (NX4) - Non-existent role to CA
            require(roles[_CAs[i]][_role], 'NX4');
            roles[_CAs[i]][_role] = false;
            emit RoleRemoved(_CAs[i], _role);
        }
    }

    /// @notice Check whether target address has role or not
    /// @param _target address to be checked
    /// @param _role role name to be checked with
    /// @return whether target address has specified role or not
    function hasRole(address _target, string calldata _role) public view returns (bool) {
        return roles[_target][_role];
    }

    /// @notice Register multiple addresses at once
    /// @param _CAs list of contract address which will be registered
    /// @param _topics topic list for each contract address
    function registerContractMultiple(address[] calldata _CAs, string[] calldata _topics) external onlyOwner {
        uint256 len = _CAs.length;
        /// @custom:error (ARG1) - Arguments length should be same
        require(_CAs.length == _topics.length, 'ARG1');
        for (uint256 i = 0; i < len; i++) {
            registerContract(_CAs[i], _topics[i]);
        }
    }

    /// @notice Register contract address with topic
    /// @param _CA contract address
    /// @param _topic topic for address
    function registerContract(address _CA, string calldata _topic) public onlyOwner {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_CA != address(0), 'AE1');

        /// @custom:error (AE2) - Contract address not acceptable
        require(_CA.isContract(), 'AE2');

        managerContracts[_CA] = Contract(_topic, true);
        indexedContracts[_topic] = _CA;
        emit ContractRegistered(_CA, _topic);
    }

    /// @notice Check whether contract address is registered
    /// @param _CA contract address
    /// @return isRegistered - boolean
    function checkRegistration(address _CA) public view returns (bool isRegistered) {
        return managerContracts[_CA].active;
    }

    /// @notice Remove contract address
    /// @param _CA contract address which will be removed
    function removeContract(address _CA) external onlyOwner {
        string memory topic = managerContracts[_CA].topic;
        delete managerContracts[_CA];

        if (indexedContracts[topic] == _CA) {
            delete indexedContracts[topic];
        }

        emit ContractRemoved(_CA, topic);
    }

    /// @notice Get contract address for specified topic
    /// @param _topic topic for address
    /// @return address which is registered with topic
    function getContract(string calldata _topic) public view returns (address) {
        return indexedContracts[_topic];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155Upgradeable.sol";
import "./IERC1155ReceiverUpgradeable.sol";
import "./extensions/IERC1155MetadataURIUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC1155Upgradeable, IERC1155MetadataURIUpgradeable {
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_) internal onlyInitializing {
        __ERC1155_init_unchained(uri_);
    }

    function __ERC1155_init_unchained(string memory uri_) internal onlyInitializing {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            interfaceId == type(IERC1155MetadataURIUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
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
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
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
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
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
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
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
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
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
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
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
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155Received.selector) {
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
    ) private {
        if (to.isContract()) {
            try IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155ReceiverUpgradeable.onERC1155BatchReceived.selector) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(tx.origin);
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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

    uint256[49] private __gap;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';

/// @title SenderVerifier - verifier contract that payload is signed by omnuum or not
/// @author Omnuum Dev Team - <[email protected]>
contract SenderVerifier is EIP712 {
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    string private constant SIGNING_DOMAIN = 'Omnuum';
    string private constant SIGNATURE_VERSION = '1';

    struct Payload {
        address sender; // sender or address who received this payload
        string topic; // topic of payload
        uint256 nonce; // separate same topic payload for multiple steps or checks
        bytes signature; // signature of this payload
    }

    /// @notice verify function
    /// @param _owner address who is believed to be signer of payload signature
    /// @param _sender address who is believed to be target of payload signature
    /// @param _topic topic of payload
    /// @param _nonce nonce of payload
    /// @param _payload payload struct
    function verify(
        address _owner,
        address _sender,
        string calldata _topic,
        uint256 _nonce,
        Payload calldata _payload
    ) public view {
        address signer = recoverSigner(_payload);

        /// @custom:error (VR1) - False Signer
        require(_owner == signer, 'VR1');

        /// @custom:error (VR2) - False Nonce
        require(_nonce == _payload.nonce, 'VR2');

        /// @custom:error (VR3) - False Topic
        require(keccak256(abi.encodePacked(_payload.topic)) == keccak256(abi.encodePacked(_topic)), 'VR3');

        /// @custom:error (VR4) - False Sender
        require(_payload.sender == _sender, 'VR4');
    }

    /// @dev recover signer from payload hash
    /// @param _payload payload struct
    function recoverSigner(Payload calldata _payload) internal view returns (address) {
        bytes32 digest = _hash(_payload);
        return ECDSA.recover(digest, _payload.signature);
    }

    /// @dev hash payload
    /// @param _payload payload struct
    function _hash(Payload calldata _payload) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256('Payload(address sender,string topic,uint256 nonce)'),
                        _payload.sender,
                        keccak256(bytes(_payload.topic)),
                        _payload.nonce
                    )
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '../utils/OwnableUpgradeable.sol';
import './OmnuumNFT1155.sol';

/// @title OmnuumMintManager - Manage mint data and logics except ticket minting
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Use only purpose for Omnuum
contract OmnuumMintManager is OwnableUpgradeable {
    uint8 public constant rateDecimal = 5;

    /// @notice minting fee rate
    uint256 public feeRate;

    /// @notice minimum fee (ether)
    uint256 public minFee;

    /// @notice special fee rates for exceptional contracts
    mapping(address => uint256) public specialFeeRates;

    /// @notice nft => groupId => PublicMintSchedule
    mapping(address => mapping(uint256 => PublicMintSchedule)) public publicMintSchedules;

    event ChangeFeeRate(uint256 feeRate);
    event SetSpecialFeeRate(address indexed nftContract, uint256 discountFeeRate);
    event SetMinFee(uint256 minFee);
    event Airdrop(address indexed nftContract, address indexed receiver, uint256 quantity);
    event SetPublicSchedule(
        address indexed nftContract,
        uint256 indexed groupId,
        uint256 endDate,
        uint256 basePrice,
        uint32 supply,
        uint32 maxMintAtAddress
    );
    event PublicMint(
        address indexed nftContract,
        address indexed minter,
        uint256 indexed groupId,
        uint32 quantity,
        uint32 maxQuantity,
        uint256 price
    );

    struct PublicMintSchedule {
        uint32 supply; // max possible minting amount
        uint32 mintedTotal; // total minted amount
        uint32 maxMintAtAddress; // max possible minting amount per address
        mapping(address => uint32) minted; // minting count per address
        uint256 endDate; // minting schedule end date timestamp
        uint256 basePrice; // minting price
    }

    function initialize(uint256 _feeRate) public initializer {
        __Ownable_init();
        feeRate = _feeRate;
        minFee = 0.0005 ether;
    }

    /// @notice get fee rate of given nft contract
    /// @param _nftContract address of nft contract
    function getFeeRate(address _nftContract) public view returns (uint256) {
        return specialFeeRates[_nftContract] == 0 ? feeRate : specialFeeRates[_nftContract];
    }

    /// @notice change fee rate
    /// @param _newFeeRate new fee rate
    function changeFeeRate(uint256 _newFeeRate) external onlyOwner {
        /// @custom:error (NE1) - Fee rate should be lower than 100%
        require(_newFeeRate <= 100000, 'NE1');
        feeRate = _newFeeRate;
        emit ChangeFeeRate(_newFeeRate);
    }

    /// @notice set special fee rate for exceptional case
    /// @param _nftContract address of nft
    /// @param _feeRate fee rate only for nft contract
    function setSpecialFeeRate(address _nftContract, uint256 _feeRate) external onlyOwner {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_nftContract != address(0), 'AE1');

        /// @custom:error (NE1) - Fee rate should be lower than 100%
        require(_feeRate <= 100000, 'NE1');
        specialFeeRates[_nftContract] = _feeRate;
        emit SetSpecialFeeRate(_nftContract, _feeRate);
    }

    function setMinFee(uint256 _minFee) external onlyOwner {
        minFee = _minFee;
        emit SetMinFee(_minFee);
    }

    /// @notice add public mint schedule
    /// @dev only nft contract owner can add mint schedule
    /// @param _nft nft contract address
    /// @param _groupId id of mint schedule
    /// @param _endDate end date of schedule
    /// @param _basePrice mint price of schedule
    /// @param _supply max possible minting amount
    /// @param _maxMintAtAddress max possible minting amount per address
    function setPublicMintSchedule(
        address _nft,
        uint256 _groupId,
        uint256 _endDate,
        uint256 _basePrice,
        uint32 _supply,
        uint32 _maxMintAtAddress
    ) external {
        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(OwnableUpgradeable(_nft).owner() == msg.sender, 'OO1');

        PublicMintSchedule storage schedule = publicMintSchedules[_nft][_groupId];

        schedule.supply = _supply;
        schedule.endDate = _endDate;
        schedule.basePrice = _basePrice;
        schedule.maxMintAtAddress = _maxMintAtAddress;

        emit SetPublicSchedule(_nft, _groupId, _endDate, _basePrice, _supply, _maxMintAtAddress);
    }

    /// @notice before nft mint, check whether mint is possible and count new mint at mint schedule
    /// @dev only nft contract itself can access and use its mint schedule
    /// @param _groupId id of schedule
    /// @param _quantity quantity to mint
    /// @param _value value sent to mint at NFT contract, used for checking whether value is enough or not to mint
    /// @param _minter msg.sender at NFT contract who are trying to mint
    function preparePublicMint(
        uint16 _groupId,
        uint32 _quantity,
        uint256 _value,
        address _minter
    ) external {
        PublicMintSchedule storage schedule = publicMintSchedules[msg.sender][_groupId];

        /// @custom:error (MT8) - Minting period is ended
        require(block.timestamp <= schedule.endDate, 'MT8');

        /// @custom:error (MT5) - Not enough money
        require(schedule.basePrice * _quantity <= _value, 'MT5');

        /// @custom:error (MT2) - Cannot mint more than possible amount per address
        require(schedule.minted[_minter] + _quantity <= schedule.maxMintAtAddress, 'MT2');

        /// @custom:error (MT3) - Remaining token count is not enough
        require(schedule.mintedTotal + _quantity <= schedule.supply, 'MT3');

        schedule.minted[_minter] += _quantity;
        schedule.mintedTotal += _quantity;

        emit PublicMint(msg.sender, _minter, _groupId, _quantity, schedule.supply, schedule.basePrice);
    }

    /// @notice minting multiple nfts, can be used for airdrop
    /// @dev only nft owner can use this function
    /// @param _nftContract address of nft contract
    /// @param _tos list of minting target address
    /// @param _quantitys list of minting quantity which is paired with _tos
    function mintMultiple(
        address payable _nftContract,
        address[] calldata _tos,
        uint16[] calldata _quantitys
    ) external payable {
        OmnuumNFT1155 targetContract = OmnuumNFT1155(_nftContract);

        uint256 len = _tos.length;

        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(targetContract.owner() == msg.sender, 'OO1');

        /// @custom:error (ARG1) - Arguments length should be same
        require(len == _quantitys.length, 'ARG1');

        uint256 totalQuantity;
        for (uint256 i = 0; i < len; i++) {
            totalQuantity += _quantitys[i];
        }

        /// @custom:error (ARG3) - Not enough ether sent
        require(msg.value >= totalQuantity * minFee, 'ARG3');

        for (uint256 i = 0; i < len; i++) {
            address to = _tos[i];
            uint16 quantity = _quantitys[i];
            targetContract.mintDirect{ value: minFee * _quantitys[i] }(to, quantity);
            emit Airdrop(_nftContract, to, quantity);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol';
import '../utils/Ownable.sol';

/// @title TicketManager - manage ticket and verify ticket signature
/// @author Omnuum Dev Team - <[email protected]>
contract TicketManager is EIP712 {
    constructor() EIP712(SIGNING_DOMAIN, SIGNATURE_VERSION) {}

    struct Ticket {
        address user; // owner of this ticket
        address nft; // ticket nft contract
        uint256 price; // price of mint with this ticket
        uint32 quantity; // possible mint quantity
        uint256 groupId; // ticket's group id
        bytes signature; // ticket's signature
    }

    /// @dev nft => groupId => end date
    mapping(address => mapping(uint256 => uint256)) public endDates;

    /// @dev nft => groupId => ticket owner => use count
    mapping(address => mapping(uint256 => mapping(address => uint32))) public ticketUsed;

    string private constant SIGNING_DOMAIN = 'OmnuumTicket';
    string private constant SIGNATURE_VERSION = '1';

    event SetTicketSchedule(address indexed nftContract, uint256 indexed groupId, uint256 endDate);

    event TicketMint(
        address indexed nftContract,
        address indexed minter,
        uint256 indexed groupId,
        uint32 quantity,
        uint32 maxQuantity,
        uint256 price
    );

    /// @notice set end date for ticket group
    /// @param _nft nft contract
    /// @param _groupId id of ticket group
    /// @param _endDate end date timestamp
    function setEndDate(
        address _nft,
        uint256 _groupId,
        uint256 _endDate
    ) external {
        /// @custom:error (OO1) - Ownable: Caller is not the collection owner
        require(Ownable(_nft).owner() == msg.sender, 'OO1');
        endDates[_nft][_groupId] = _endDate;

        emit SetTicketSchedule(_nft, _groupId, _endDate);
    }

    /// @notice use ticket for minting
    /// @param _signer address who is believed to be signer of ticket
    /// @param _minter address who is believed to be owner of ticket
    /// @param _quantity quantity of which minter is willing to mint
    /// @param _ticket ticket
    function useTicket(
        address _signer,
        address _minter,
        uint32 _quantity,
        Ticket calldata _ticket
    ) external {
        verify(_signer, msg.sender, _minter, _quantity, _ticket);

        ticketUsed[msg.sender][_ticket.groupId][_minter] += _quantity;
        emit TicketMint(msg.sender, _minter, _ticket.groupId, _quantity, _ticket.quantity, _ticket.price);
    }

    /// @notice verify ticket
    /// @param _signer address who is believed to be signer of ticket
    /// @param _nft nft contract address
    /// @param _minter address who is believed to be owner of ticket
    /// @param _quantity quantity of which minter is willing to mint
    /// @param _ticket ticket
    function verify(
        address _signer,
        address _nft,
        address _minter,
        uint32 _quantity,
        Ticket calldata _ticket
    ) public view {
        /// @custom:error (MT8) - Minting period is ended
        require(block.timestamp <= endDates[_nft][_ticket.groupId], 'MT8');

        /// @custom:error (VR1) - False Signer
        require(_signer == recoverSigner(_ticket), 'VR1');

        /// @custom:error (VR5) - False NFT
        require(_ticket.nft == _nft, 'VR5');

        /// @custom:error (VR6) - False Minter
        require(_minter == _ticket.user, 'VR6');

        /// @custom:error (MT3) - Remaining token count is not enough
        require(ticketUsed[_nft][_ticket.groupId][_minter] + _quantity <= _ticket.quantity, 'MT3');
    }

    /// @dev recover signer from payload hash
    /// @param _ticket payload struct
    function recoverSigner(Ticket calldata _ticket) internal view returns (address) {
        bytes32 digest = _hash(_ticket);
        return ECDSA.recover(digest, _ticket.signature);
    }

    /// @dev hash payload
    /// @param _ticket payload struct
    function _hash(Ticket calldata _ticket) internal view returns (bytes32) {
        return
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        keccak256('Ticket(address user,address nft,uint256 price,uint32 quantity,uint256 groupId)'),
                        _ticket.user,
                        _ticket.nft,
                        _ticket.price,
                        _ticket.quantity,
                        _ticket.groupId
                    )
                )
            );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

/// @title OmnuumWallet Allows multiple owners to agree to withdraw money, add/remove/change owners before execution
/// @notice This contract is not managed by Omnuum admin, but for owners
/// @author Omnuum Dev Team <[email protected]>

import '@openzeppelin/contracts/utils/math/Math.sol';

contract OmnuumWallet {
    /// @notice consensusRatio Ratio of votes to reach consensus as a percentage of total votes
    uint256 public immutable consensusRatio;

    /// @notice Minimum limit of required number of votes for consensus
    uint8 public immutable minLimitForConsensus;

    /// @notice Withdraw = 0
    /// @notice Add = 1
    /// @notice Remove = 2
    /// @notice Change = 3
    /// @notice Cancel = 4
    enum RequestTypes {
        Withdraw,
        Add,
        Remove,
        Change,
        Cancel
    }

    /// @notice F = 0 (F-Level Not owner)
    /// @notice D = 1 (D-Level own 1 vote)
    /// @notice C = 2 (C-Level own 2 votes)
    enum OwnerVotes {
        F,
        D,
        C
    }
    struct OwnerAccount {
        address addr;
        OwnerVotes vote;
    }
    struct Request {
        address requester;
        RequestTypes requestType;
        OwnerAccount currentOwner;
        OwnerAccount newOwner;
        uint256 withdrawalAmount;
        mapping(address => bool) voters;
        uint256 votes;
        bool isExecute;
    }

    /* *****************************************************************************
     *   Storages
     * *****************************************************************************/
    Request[] public requests;
    mapping(OwnerVotes => uint8) public ownerCounter;
    mapping(address => OwnerVotes) public ownerVote;

    /* *****************************************************************************
     *   Constructor
     * - set consensus ratio, minimum votes limit for consensus, and initial accounts
     * *****************************************************************************/
    constructor(
        uint256 _consensusRatio,
        uint8 _minLimitForConsensus,
        OwnerAccount[] memory _initialOwnerAccounts
    ) {
        consensusRatio = _consensusRatio;
        minLimitForConsensus = _minLimitForConsensus;
        for (uint256 i; i < _initialOwnerAccounts.length; i++) {
            OwnerVotes vote = _initialOwnerAccounts[i].vote;
            ownerVote[_initialOwnerAccounts[i].addr] = vote;
            ownerCounter[vote]++;
        }

        _checkMinConsensus();
    }

    /* *****************************************************************************
     *   Events
     * *****************************************************************************/
    event PaymentReceived(address indexed sender, string topic, string description);
    event EtherReceived(address indexed sender);
    event Requested(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);
    event Approved(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Revoked(address indexed owner, uint256 indexed requestId, OwnerVotes votes);
    event Canceled(address indexed owner, uint256 indexed requestId);
    event Executed(address indexed owner, uint256 indexed requestId, RequestTypes indexed requestType);

    /* *****************************************************************************
     *   Modifiers
     * *****************************************************************************/
    modifier onlyOwner(address _address) {
        /// @custom:error (004) - Only the owner of the wallet is allowed
        require(isOwner(_address), 'OO4');
        _;
    }

    modifier notOwner(address _address) {
        /// @custom:error (005) - Already the owner of the wallet
        require(!isOwner(_address), 'OO5');
        _;
    }

    modifier isOwnerAccount(OwnerAccount memory _ownerAccount) {
        /// @custom:error (NX2) - Non-existent wallet account
        address _addr = _ownerAccount.addr;
        require(isOwner(_addr) && uint8(ownerVote[_addr]) == uint8(_ownerAccount.vote), 'NX2');
        _;
    }

    modifier onlyRequester(uint256 _reqId) {
        /// @custom:error (OO6) - Only the requester is allowed
        require(requests[_reqId].requester == msg.sender, 'OO6');
        _;
    }

    modifier reachConsensus(uint256 _reqId) {
        /// @custom:error (NE2) - Not reach consensus
        require(requests[_reqId].votes >= requiredVotesForConsensus(), 'NE2');
        _;
    }

    modifier reqExists(uint256 _reqId) {
        /// @custom:error (NX3) - Non-existent owner request
        require(_reqId < requests.length, 'NX3');
        _;
    }

    modifier notExecutedOrCanceled(uint256 _reqId) {
        /// @custom:error (SE1) - Already executed
        require(!requests[_reqId].isExecute, 'SE1');

        /// @custom:error (SE2) - Request canceled
        require(requests[_reqId].requestType != RequestTypes.Cancel, 'SE2');
        _;
    }

    modifier notVoted(address _owner, uint256 _reqId) {
        /// @custom:error (SE3) - Already voted
        require(!isOwnerVoted(_owner, _reqId), 'SE3');
        _;
    }

    modifier voted(address _owner, uint256 _reqId) {
        /// @custom:error (SE4) - Not voted
        require(isOwnerVoted(_owner, _reqId), 'SE4');
        _;
    }

    modifier isValidAddress(address _address) {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_address != address(0), 'AE1');
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(_address)
        }

        /// @notice It's not perfect filtering against CA, but the owners can handle it cautiously.
        /// @custom:error (AE2) - Contract address not acceptable
        require(codeSize == 0, 'AE2');
        _;
    }

    /* *****************************************************************************
     *   Methods - Public, External
     * *****************************************************************************/

    function makePayment(string calldata _topic, string calldata _description) external payable {
        /// @custom:error (NE3) - A zero payment is not acceptable
        require(msg.value > 0, 'NE3');
        emit PaymentReceived(msg.sender, _topic, _description);
    }

    receive() external payable {
        emit EtherReceived(msg.sender);
    }

    /// @notice request
    /// @dev Allows an owner to request for an agenda that wants to proceed
    /// @dev The owner can make multiple requests even if the previous one is unresolved
    /// @dev The requester is automatically voted for the request
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _currentAccount Tuple[address, OwnerVotes] for current exist owner account (use for Request Type as Remove or Change)
    /// @param _newAccount Tuple[address, OwnerVotes] for new owner account (use for Request Type as Add or Change)
    /// @param _withdrawalAmount Amount of Ether to be withdrawal (use for Request Type as Withdrawal)

    function request(
        RequestTypes _requestType,
        OwnerAccount calldata _currentAccount,
        OwnerAccount calldata _newAccount,
        uint256 _withdrawalAmount
    ) external onlyOwner(msg.sender) {
        address requester = msg.sender;

        Request storage request_ = requests.push();
        request_.requester = requester;
        request_.requestType = _requestType;
        request_.currentOwner = OwnerAccount({ addr: _currentAccount.addr, vote: _currentAccount.vote });
        request_.newOwner = OwnerAccount({ addr: _newAccount.addr, vote: _newAccount.vote });
        request_.withdrawalAmount = _withdrawalAmount;
        request_.voters[requester] = true;
        request_.votes = uint8(ownerVote[requester]);

        emit Requested(msg.sender, requests.length - 1, _requestType);
    }

    /// @notice approve
    /// @dev Allows owners to approve the request
    /// @dev The owner can revoke the approval whenever the request is still in progress (not executed or canceled)
    /// @param _reqId Request id that the owner wants to approve

    function approve(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        notVoted(msg.sender, _reqId)
    {
        OwnerVotes _vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        request_.voters[msg.sender] = true;
        request_.votes += uint8(_vote);

        emit Approved(msg.sender, _reqId, _vote);
    }

    /// @notice revoke
    /// @dev Allow an approver(owner) to revoke the approval
    /// @param _reqId Request id that the owner wants to revoke

    function revoke(uint256 _reqId)
        external
        onlyOwner(msg.sender)
        reqExists(_reqId)
        notExecutedOrCanceled(_reqId)
        voted(msg.sender, _reqId)
    {
        OwnerVotes vote = ownerVote[msg.sender];
        Request storage request_ = requests[_reqId];
        delete request_.voters[msg.sender];
        request_.votes -= uint8(vote);

        emit Revoked(msg.sender, _reqId, vote);
    }

    /// @notice cancel
    /// @dev Allows a requester(owner) to cancel the own request
    /// @dev After proceeding, it cannot revert the cancellation. Be cautious
    /// @param _reqId Request id requested by the requester

    function cancel(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) {
        requests[_reqId].requestType = RequestTypes.Cancel;

        emit Canceled(msg.sender, _reqId);
    }

    /// @notice execute
    /// @dev Allow an requester(owner) to execute the request
    /// @dev After proceeding, it cannot revert the execution. Be cautious
    /// @param _reqId Request id that the requester wants to execute

    function execute(uint256 _reqId) external reqExists(_reqId) notExecutedOrCanceled(_reqId) onlyRequester(_reqId) reachConsensus(_reqId) {
        Request storage request_ = requests[_reqId];
        uint8 type_ = uint8(request_.requestType);
        request_.isExecute = true;

        if (type_ == uint8(RequestTypes.Withdraw)) {
            _withdraw(request_.withdrawalAmount, request_.requester);
        } else if (type_ == uint8(RequestTypes.Add)) {
            _addOwner(request_.newOwner);
        } else if (type_ == uint8(RequestTypes.Remove)) {
            _removeOwner(request_.currentOwner);
        } else if (type_ == uint8(RequestTypes.Change)) {
            _changeOwner(request_.currentOwner, request_.newOwner);
        }
        emit Executed(msg.sender, _reqId, request_.requestType);
    }

    /// @notice totalVotes
    /// @dev Allows users to see how many total votes the wallet currently have
    /// @return votes The total number of voting rights the owners have

    function totalVotes() public view returns (uint256 votes) {
        return ownerCounter[OwnerVotes.D] + 2 * ownerCounter[OwnerVotes.C];
    }

    /// @notice isOwner
    /// @dev Allows users to verify registered owners in the wallet
    /// @param _owner Address of the owner that you want to verify
    /// @return isVerified Verification result of whether the owner is correct

    function isOwner(address _owner) public view returns (bool isVerified) {
        return uint8(ownerVote[_owner]) > 0;
    }

    /// @notice isOwnerVoted
    /// @dev Allows users to check which owner voted
    /// @param _owner Address of the owner
    /// @param _reqId Request id that you want to check
    /// @return isVoted Whether the owner voted

    function isOwnerVoted(address _owner, uint256 _reqId) public view returns (bool isVoted) {
        return requests[_reqId].voters[_owner];
    }

    /// @notice requiredVotesForConsensus
    /// @dev Allows users to see how many votes are needed to reach consensus.
    /// @return votesForConsensus The number of votes required to reach a consensus

    function requiredVotesForConsensus() public view returns (uint256 votesForConsensus) {
        return Math.ceilDiv((totalVotes() * consensusRatio), 100);
    }

    /// @notice getRequestIdsByExecution
    /// @dev Allows users to see the array of request ids filtered by execution
    /// @param _isExecuted Whether the request was executed or not
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByExecution(
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if (requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if (!requests[i].isExecute) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByOwner
    /// @dev Allows users to see the array of request ids filtered by owner address
    /// @param _owner The address of owner
    /// @param _isExecuted If you want to see only for that have not been executed, input this argument into true
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByOwner(
        address _owner,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requester == _owner) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requester == _owner) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getRequestIdsByType
    /// @dev Allows users to see the array of request ids filtered by request type
    /// @param _requestType Withdraw(0) / Add(1) / Remove(2) / Change(3) / Cancel(4)
    /// @param _cursorIndex A pointer to a specific request ID that starts in the data list
    /// @param _length The amount of request ids you want to query from the _cursorIndex (not always mean the amount of data you can retrieve)
    /// @return requestIds Array of request ids (if the boundary of search pointer exceeds the length of requests list, it always checks the last request id only, then returns the result)

    function getRequestIdsByType(
        RequestTypes _requestType,
        bool _isExecuted,
        uint256 _cursorIndex,
        uint256 _length
    ) public view returns (uint256[] memory requestIds) {
        uint256[] memory filteredArray = new uint256[](requests.length);
        uint256 counter = 0;
        uint256 lastReqIdx = getLastRequestNo();
        for (uint256 i = Math.min(_cursorIndex, lastReqIdx); i < Math.min(_cursorIndex + _length, lastReqIdx + 1); i++) {
            if (_isExecuted) {
                if ((requests[i].requestType == _requestType) && (requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            } else {
                if ((requests[i].requestType == _requestType) && (!requests[i].isExecute)) {
                    filteredArray[counter] = i;
                    counter++;
                }
            }
        }
        return _compactUintArray(filteredArray, counter);
    }

    /// @notice getLastRequestNo
    /// @dev Allows users to get the last request number
    /// @return requestNo The last request number

    function getLastRequestNo() public view returns (uint256 requestNo) {
        return requests.length - 1;
    }

    /* *****************************************************************************
     *   Functions - Internal, Private
     * *****************************************************************************/

    /// @notice _withdraw
    /// @dev Withdraw Ethers from the wallet
    /// @param _value Withdraw amount
    /// @param _to Withdrawal recipient

    function _withdraw(uint256 _value, address _to) private {
        /// @custom:error (NE4) - Insufficient balance
        require(_value <= address(this).balance, 'NE4');
        (bool withdrawn, ) = payable(_to).call{ value: _value }('');

        /// @custom:error (SE5) - Address: unable to send value, recipient may have reverted
        require(withdrawn, 'SE5');
    }

    /// @notice _addOwner
    /// @dev Add a new Owner to the wallet
    /// @param _newAccount New owner account to be added

    function _addOwner(OwnerAccount memory _newAccount) private notOwner(_newAccount.addr) isValidAddress(_newAccount.addr) {
        OwnerVotes vote = _newAccount.vote;
        ownerVote[_newAccount.addr] = vote;
        ownerCounter[vote]++;
    }

    /// @notice _removeOwner
    /// @dev Remove existing owner form the wallet
    /// @param _removalAccount Current owner account to be removed

    function _removeOwner(OwnerAccount memory _removalAccount) private isOwnerAccount(_removalAccount) {
        ownerCounter[_removalAccount.vote]--;
        _checkMinConsensus();
        delete ownerVote[_removalAccount.addr];
    }

    /// @notice _changeOwner
    /// @dev Allows changing the existing owner to the new one. It also includes the functionality to change the existing owner's level
    /// @param _currentAccount Current owner account to be changed
    /// @param _newAccount New owner account to be applied

    function _changeOwner(OwnerAccount memory _currentAccount, OwnerAccount memory _newAccount) private {
        OwnerVotes _currentVote = _currentAccount.vote;
        OwnerVotes _newVote = _newAccount.vote;
        ownerCounter[_currentVote]--;
        ownerCounter[_newVote]++;
        _checkMinConsensus();

        if (_currentAccount.addr != _newAccount.addr) {
            delete ownerVote[_currentAccount.addr];
        }
        ownerVote[_newAccount.addr] = _newVote;
    }

    /// @notice _checkMinConsensus
    /// @dev It is the verification function to prevent a dangerous situation in which the number of votes that an owner has
    /// @dev is equal to or greater than the number of votes required for reaching consensus so that the owner achieves consensus by himself or herself.

    function _checkMinConsensus() private view {
        /// @custom:error (NE5) - Violate min limit for consensus
        require(requiredVotesForConsensus() >= minLimitForConsensus, 'NE5');
    }

    function _compactUintArray(uint256[] memory targetArray, uint256 length) internal pure returns (uint256[] memory array) {
        uint256[] memory compactArray = new uint256[](length);
        for (uint256 i = 0; i < length; i++) {
            compactArray[i] = targetArray[i];
        }
        return compactArray;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

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
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155Upgradeable.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURIUpgradeable is IERC1155Upgradeable {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
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
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

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

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
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
pragma solidity 0.8.10;

import '@openzeppelin/contracts/utils/Context.sol';

contract Ownable is Context {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a / b + (a % b == 0 ? 0 : 1);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/LinkTokenInterface.sol";

import "./VRFRequestIDBase.sol";

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator, _link) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash), and have told you the minimum LINK
 * @dev price for VRF service. Make sure your contract has sufficient LINK, and
 * @dev call requestRandomness(keyHash, fee, seed), where seed is the input you
 * @dev want to generate randomness from.
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomness method.
 *
 * @dev The randomness argument to fulfillRandomness is the actual random value
 * @dev generated from your seed.
 *
 * @dev The requestId argument is generated from the keyHash and the seed by
 * @dev makeRequestId(keyHash, seed). If your contract could have concurrent
 * @dev requests open, you can use the requestId to track which seed is
 * @dev associated with which randomness. See VRFRequestIDBase.sol for more
 * @dev details. (See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.)
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ. (Which is critical to making unpredictable randomness! See the
 * @dev next section.)
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the ultimate input to the VRF is mixed with the block hash of the
 * @dev block in which the request is made, user-provided seeds have no impact
 * @dev on its economic security properties. They are only included for API
 * @dev compatability with previous versions of this contract.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request.
 */
abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

import '@openzeppelin/contracts-upgradeable/interfaces/IERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol';
import '../utils/OwnableUpgradeable.sol';
import './OmnuumCAManager.sol';

/// @title OmnuumExchange - Omnuum internal exchange contract to use token freely by other omnuum contracts
/// @author Omnuum Dev Team - <[email protected]>
/// @notice Use only purpose for Omnuum
/// @dev Warning:: This contract is for temporary use and will be upgraded to version 2 which use dex to exchange token,
/// @dev Until version 2, LINK token will be deposited this contract directly and send LINK to omnuum contracts whenever they want
contract OmnuumExchange is OwnableUpgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;

    OmnuumCAManager private caManager;

    /// @notice temporary use purpose of LINK/ETH exchange rate
    uint256 public tmpLinkExRate;

    event Exchange(address indexed baseToken, address indexed targetToken, uint256 amount, address user, address indexed receipient);

    function initialize(address _caManagerA) public initializer {
        /// @custom:error (AE1) - Zero address not acceptable
        require(_caManagerA != address(0), 'AE1');

        __Ownable_init();

        caManager = OmnuumCAManager(_caManagerA);

        tmpLinkExRate = 0.01466666666 ether;
    }

    /// @notice calculate amount when given amount of token is swapped to target token
    /// @param _fromToken 'from' token for swapping
    /// @param _toToken 'to' token for swapping
    /// @param _amount 'from' token's amount for swapping
    /// @return amount 'to' token's expected amount after swapping
    function getExchangeAmount(
        address _fromToken,
        address _toToken,
        uint256 _amount
    ) public view returns (uint256 amount) {
        return (tmpLinkExRate * _amount) / 1 ether;
    }

    /// @notice update temporary exchange rate which is used for LINK/ETH
    /// @param _newRate new exchange rate (LINK/ETH)
    function updateTmpExchangeRate(uint256 _newRate) external onlyOwner {
        tmpLinkExRate = _newRate;
    }

    /// @notice give requested token to omnuum contract
    /// @param _token request token address
    /// @param _amount amount of token requested
    /// @param _to address where specified token and amount should delivered to
    function exchangeToken(
        address _token,
        uint256 _amount,
        address _to
    ) external payable {
        /// @custom:error (OO7) - Only role owner can access
        require(caManager.hasRole(msg.sender, 'EXCHANGE'), 'OO7');

        IERC20Upgradeable(_token).safeTransfer(msg.sender, _amount);

        emit Exchange(address(0), _token, _amount, msg.sender, _to);
    }

    /// @notice withdraw specific amount to omnuum wallet contract
    /// @param _amount amount of ether to be withdrawn
    function withdraw(uint256 _amount) external onlyOwner {
        /// @custom:error (ARG2) - Arguments are not correct
        require(_amount <= address(this).balance, 'ARG2');
        payable(caManager.getContract('WALLET')).transfer(_amount);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.10;

// https://ethereum.stackexchange.com/questions/83528/how-can-i-get-the-revert-reason-of-a-call-in-solidity-so-that-i-can-use-it-in-th
library RevertMessage {
    function parse(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return 'Transaction reverted silently';

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20Upgradeable.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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