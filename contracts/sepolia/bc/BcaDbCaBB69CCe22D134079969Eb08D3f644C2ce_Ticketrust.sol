// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Ticketrust main contract.
 * @author Yoel Zerbib
 * Date created: 24.2.22.
 * Github
 **/

import "@openzeppelin/contracts-upgradeable/token/ERC1155/ERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../utils/Strings.sol";
import "../interfaces/ITokenSwapHandler.sol";
import "../interfaces/ITicketrustMiddleware.sol";
import "./EventManager.sol";

contract Ticketrust is
    Initializable,
    OwnableUpgradeable,
    ERC1155Upgradeable,
    EventManager
{
    ITicketrustMiddleware public ticketrustMiddleware;
    ITokenSwapHandler public tokenSwapHandler;

    // Contract name
    string public name;
    // Contract symbol
    string public symbol;

    /************
        Structs
    *************/

    struct TicketData {
        address owner;
        uint256 ticketID;
        uint256 lastUpdated;
        bytes32 secretKey;
    }

    /*************
        Mappings 
     *************/

    // Ticket Data (used for authorization)
    mapping(uint256 => TicketData) private ticketData;

    // Contract URI
    string public s_contractURI;

    // Handle grey market price
    modifier greyMaketHandler(uint256 _id) {
        require(
            eventGreyMarketAllowed[_id],
            "Grey market is disallowed for this event."
        );
        _;
    }

    // Only operator modifier
    modifier onlyOperator {
        require(ticketrustMiddleware.isOperator(msg.sender), "Restricted only to operator");
        _;
    }

    // Only committee modifier
    modifier onlyCommittee {
        require(ticketrustMiddleware.isCommittee(msg.sender) , "Restricted only to committee");
        _;
    }
    
    function initialize(
        address _ticketrustMiddleware,
        address _tokenSwapHandler
    ) public initializer {
        __Ownable_init();
        __ERC1155_init("");
        baseOptionFees = 4;
        name = "Tcktrst";
        symbol = "TCKTST";

        ticketrustMiddleware = ITicketrustMiddleware(_ticketrustMiddleware);
        tokenSwapHandler = ITokenSwapHandler(_tokenSwapHandler);
    }


    function mintWithETH(
        uint256 _id,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external payable {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");

        require(
            referenceTokenAddress[_id] == address(0),
            "Event price is not in ETH"
        );

        uint256 exactETHAmount = eventPrice[_id] * _amount;

        require(
            msg.value >= exactETHAmount,
            "Not enough ETH sent to buy tickets"
        );

        // Mint tickets
        _mint(_to, _id, _amount, _data);

        // Update event data
        eventRevenue[_id] += (eventPrice[_id] * _amount);
        eventSupply[_id] -= _amount;

        // Refund if needed
        if (msg.value > exactETHAmount) {
            payable(msg.sender).transfer(msg.value - exactETHAmount);
        }
    }

    function mintWithToken(
        address _tokenAddress,
        uint256 _id,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");

        require(
            referenceTokenAddress[_id] != address(0),
            "Event price is in ETH"
        );

        require(
            referenceTokenAddress[_id] == _tokenAddress,
            "Event price is not in the sent token"
        );

        uint256 exactTokenAmount = eventPrice[_id] * _amount;

        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= exactTokenAmount,
            "Not enough tokens sent to buy tickets"
        );

        require(
            IERC20(_tokenAddress).allowance(msg.sender, address(this)) >=
                exactTokenAmount,
            "Not enough allowance to buy tickets"
        );

        // Transfer tokens to this contract
        IERC20(_tokenAddress).transferFrom(
            msg.sender,
            address(this),
            exactTokenAmount
        );

        // Mint tickets
        _mint(_to, _id, _amount, _data);

        // Update event data
        eventRevenue[_id] += (eventPrice[_id] * _amount);
        eventSupply[_id] -= _amount;
    }

    /**
     * @dev Swap the tokens to ETH in case `referenceTokenAddress` of the event is in ETH - address(0).
     *   `_maxTokenAmount`: Maximum token you are willing to send.
     *   `_tokenAddress`: Token address that will be swap to ETH.
     *   `_id`: Event ID.
     *   `_to`: Ticket recipient address.
     *   `_amount` : Ticket amount.
     *   `data` : data.
     */
    function mintWithTokenForExactETH(
        uint256 _maxTokenAmount,
        address _tokenAddress,
        uint256 _id,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");

        require(
            referenceTokenAddress[_id] == address(0),
            "Event price is not in ETH"
        );

        uint256 exactETHAmount = eventPrice[_id];
        uint256 deadline = block.timestamp + 300;

        // Swap user's tokens for the exact amount of ETH required
        tokenSwapHandler.swapTokensForExactETH(
            exactETHAmount,
            _maxTokenAmount,
            _tokenAddress,
            address(this),
            deadline
        );

        // Mint the ticket to the user
        _mint(_to, _id, _amount, _data);

        eventRevenue[_id] += (eventPrice[_id] * _amount);
        eventSupply[_id] -= _amount;
    }

    /**
     * @dev Swap the ETH of msg.value to `referenceTokenAddress`.
     *   `_id`: Event ID.
     *   `_to`: Ticket recipient address.
     *   `_amount` : Ticket amount.
     *   `data` : data.
     *
     *   Requires:
     *   - `msg.value` is the maximum ETH that caller is willing to send.
     */
    function mintWithETHForExactTokens(
        uint256 _id,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external payable {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");
        
        require(
            referenceTokenAddress[_id] != address(0),
            "Event price is in ETH"
        );

        address eventTokenAddress = referenceTokenAddress[_id];
        uint256 exactTokenAmount = eventPrice[_id];
        uint256 deadline = block.timestamp + 300;

        // Swap user's ETH for the exact amount of the required token
        tokenSwapHandler.swapETHForExactTokens{value: msg.value}(
            msg.sender,
            exactTokenAmount,
            eventTokenAddress,
            address(this),
            deadline
        );

        // Mint the ticket to the user
        _mint(_to, _id, _amount, _data);

        eventRevenue[_id] += (eventPrice[_id] * _amount);
        eventSupply[_id] -= _amount;
    }

    /**
     * @dev Swap the tokens to exact amount of `referenceTokenAddress`.
     *   `_maxTokenAmount`: Maximum token you are willing to send.
     *   `_tokenAddress`: Token address that will be swap to ETH.
     *   `_id`: Event ID.
     *   `_to`: Ticket recipient address.
     *   `_amount` : Ticket amount.
     *   `data` : data.
     *
     *   Requires:
     *   - `msg.value` is the maximum ETH that caller is willing to send.
     */
    function mintWithTokensForExactTokens(
        uint256 _maxTokenAmount,
        address _tokenAddress,
        uint256 _id,
        address _to,
        uint256 _amount,
        bytes memory _data
    ) external {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");

        require(
            referenceTokenAddress[_id] != address(0),
            "Event price is in ETH"
        );

        address eventTokenAddress = referenceTokenAddress[_id];
        uint256 exactTokenAmount = eventPrice[_id];
        uint256 deadline = block.timestamp + 300;

        require(IERC20(_tokenAddress).allowance(msg.sender, address(this)) >= _maxTokenAmount, "Not enough allowance to buy tickets");
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _maxTokenAmount);
        IERC20(_tokenAddress).approve(address(tokenSwapHandler), _maxTokenAmount);

        // Swap user's tokens for the exact amount of the required token
        tokenSwapHandler.swapTokensForExactTokens(
            msg.sender,
            exactTokenAmount,
            _maxTokenAmount,
            _tokenAddress,
            eventTokenAddress,
            address(this),
            deadline
        );

        // Mint the ticket to the user
        _mint(_to, _id, _amount, _data);

        eventRevenue[_id] += (eventPrice[_id] * _amount);
        eventSupply[_id] -= _amount;
    }

    function mintWithFiat(
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public onlyOperator {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventSupply[_id] >= _amount, "No supply for event");
        require(block.timestamp <= eventDate[_id], "Event date is passed");

        // Mint a new ticket for this event
        _mint(_to, _id, _amount, _data);

        // Update general event data
        eventSupply[_id] -= _amount;
    }

    function mintBatchWithFiat(
        address _to,
        uint256[] memory _ids,
        uint256[] memory _amounts,
        bytes memory _data
    ) public onlyOperator {
        require(_ids.length == _amounts.length, "Mismatch in ids and amounts");

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            uint256 _amount = _amounts[i];

            require(_id < totalEvents, "Event doesn't exist");
            require(eventSupply[_id] >= _amount, "No supply for event");
            require(block.timestamp <= eventDate[_id], "Event date is passed");

            // Update general event data
            eventSupply[_id] -= _amount;
        }

        // Mint a new batch of tickets for the given events
        _mintBatch(_to, _ids, _amounts, _data);
    }

    function optionTicket(
        uint256 _id,
        uint256 _amount,
        uint256 _optionDuration
    ) public payable {
        require(_id < totalEvents, "Event doesn't exist");

        // Timestamp for the option from the moment the user call the function
        uint256 optionTimestamp = block.timestamp + (60 * 60 * _optionDuration);
        require(optionTimestamp <= eventDate[_id], "Event date is passed");

        // Get option fee price for this event
        uint256 optionFees = eventOptionFees[_id];
        uint256 optionPrice = (eventPrice[_id] *
            optionFees *
            _optionDuration *
            _amount) / 100;

        require(msg.value == optionPrice, "Incorrect ETH amount");
        require(
            eventSupply[_id] >= _amount,
            "Amount would exceed ticket supply !"
        );

        // Update option data for this event
        eventOptionAmount[_id][msg.sender] += _amount;
        eventOptionTime[_id][msg.sender] = optionTimestamp;
        eventOptionCount[_id] += _amount;

        // Update general event data
        eventSupply[_id] -= _amount;
        // ownerRevenue += msg.value;

        emit OptionAdded(msg.sender, _id, _amount, optionTimestamp);
    }

    function removeOption(
        uint256 _id,
        address _to,
        uint256 _amount
    ) public onlyOperator {
        require(_id < totalEvents, "Event doesn't exist");
        require(eventOptionAmount[_id][_to] >= _amount, "No option to remove");

        eventSupply[_id] += _amount;
        eventOptionAmount[_id][_to] -= _amount;
        eventOptionCount[_id] -= _amount;

        emit OptionRemoved(_to, _id, _amount);
    }


    function ownerRevenue(address _creator) public view returns (uint256) {
        require(creatorTotalEvents[_creator] > 0, "No event for this address");

        uint256 totalRevenue = 0;
        uint256 _creatorTotalEvents = creatorTotalEvents[_creator];

        for (uint256 i; i < _creatorTotalEvents; i++) {
            uint256 revenue = eventRevenue[i];
            totalRevenue += revenue;
        }

        return totalRevenue;
    }

    function uri(uint256 _id) public view override returns (string memory) {
        require(totalEvents >= _id, "NONEXISTENT_TOKEN");

        string memory tokenUri = eventOffchainData[_id];

        return tokenUri;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _amount,
        bytes memory _data
    ) public override greyMaketHandler(_id) {
        require(
            _from == _msgSender() || isApprovedForAll(_from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );

        _safeTransferFrom(_from, _to, _id, _amount, _data);
    }

    function updateTicketData(uint256 eventID) public onlyOperator {
        TicketData storage data = ticketData[eventID];
        uint256 timestamp = block.timestamp;
        data.lastUpdated = timestamp;
        data.secretKey = sha256(abi.encodePacked(data.secretKey, timestamp));
    }

    function contractURI() public view returns (string memory) {
        return s_contractURI;
    }

    function setContractURI(string calldata _uri) public onlyCommittee {
        s_contractURI = _uri;
    }

    function recoverSignerFromSignature(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 hash
    ) external pure returns (address) {
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");
        return signer;
    }

    function getAdditionalETHBalance() public view returns (uint256) {
        uint256 totalETHRevenue = 0;

        // Loop through all events
        for (uint256 i = 0; i < totalEvents; i++) {
            // Check if the referenceTokenAddress is the address(0), meaning the eventRevenue is in ETH
            if (referenceTokenAddress[i] == address(0)) {
                totalETHRevenue += eventRevenue[i];
            }
        }

        // Calculate the additional ETH balance by subtracting the totalETHRevenue from the contract balance
        uint256 additionalETHBalance = address(this).balance - totalETHRevenue;

        return additionalETHBalance;
    }
    
    function withdrawTicketrustETH(address _committee) public {
        bool isCommittee = ticketrustMiddleware.isCommittee(_committee);
        require(isCommittee, "withdrawTicketrustETH: Only committee can withdraw ETH");

        uint256 additionalETHBalance = getAdditionalETHBalance();
        payable(_committee).transfer(additionalETHBalance);
    }

    // fallback() external payable {
    //     revert("fallback: No ETH accepted");
    // }

    receive() external payable {
        // revert("receive: No ETH accepted");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
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
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/ERC1155.sol)

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
        require(account != address(0), "ERC1155: address zero is not a valid owner");
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
            "ERC1155: caller is not token owner nor approved"
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
            "ERC1155: caller is not token owner nor approved"
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
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
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
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

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
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
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
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

    /**
     * @dev Hook that is called after any token transfer. This includes minting
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
    function _afterTokenTransfer(
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

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
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * ITicketrustMiddleware contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

interface ITicketrustMiddleware {
    function isOperator(address _address) external view returns (bool);
    function isCommittee(address _address) external view returns (bool);
    
    function addOperator(address _address) external;
    function removeOperator(address _operator) external;
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * ITokenSwapHandler contract.
 * @author Yoel Zerbib
 * Date created: 4.6.22.
 * Github
**/

interface ITokenSwapHandler {
    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address token,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amount);

    function swapETHForExactTokens(
        address paybackAddress,
        uint256 amountOut,
        address token,
        address to,
        uint256 deadline
    ) external payable returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        address paybackAddress,
        uint256 amountOut,
        uint256 amountInMax,
        address inputToken,
        address outputToken,
        address to,
        uint256 deadline
    ) external returns (uint[] memory amounts);
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Virtual EventManager contract.
 * @author Yoel Zerbib
 * Date created: 24.2.22.
 * Github
 **/

import "./RevenueManager.sol";

contract EventManager is RevenueManager {
    // Global variables
    uint256 public totalEvents;
    uint256 public baseOptionFees;


    struct EventInfo {
        address eventCreator;
        uint256 eventDate;
        address referenceTokenAddress;
        uint256 eventPrice;
        uint256 optionFees;
        uint256 eventInitialSupply;
        uint256 currentSupply;
        string offchainData;
    }


    // Event ID to event offchain data
    mapping(uint256 => string) eventOffchainData;
    // Event ID to initial event supply
    mapping(uint256 => uint256) eventInitialSupply;
    // Event ID to event supply
    mapping(uint256 => uint256) eventSupply;
    // Event ID to event price
    mapping(uint256 => uint256) eventPrice;
    // Event ID to event reference token address (address(0) if ETH)
    mapping(uint256 => address) referenceTokenAddress;
    // Event ID to event date
    mapping(uint256 => uint256) eventDate;
    // Event ID to event grey market price
    mapping(uint256 => bool) eventGreyMarketAllowed;

    // Creator to his total events
    mapping(address => uint256) public creatorTotalEvents;

    // Event Options //
    // Event ID to event option fees
    mapping(uint256 => uint256) eventOptionFees;
    // Event ID to event total option count
    mapping(uint256 => uint256) eventOptionCount;

    // Options
    // Event ID to event option count for specific buyer
    mapping(uint256 => mapping(address => uint256)) public eventOptionAmount;
    // Event ID to event option duration for specific buyer
    mapping(uint256 => mapping(address => uint256)) public eventOptionTime;

    // Events
    // Emitted when new event is created
    event EventCreated(
        uint256 id,
        address indexed owner,
        uint256 initialSupply,
        uint256 eventDate,
        uint256 optionFees,
        address referenceTokenAddress,
        uint256 eventPrice,
        bool greyMarketAllowed
    );

    // Emitted when offchain data is updated
    event OffchainDataUpdated(
        uint256 indexed eventId,
        uint256 timestamp,
        string url
    );
    // Emitted when new option is added to an event
    event OptionAdded(
        address indexed optionOwner,
        uint256 indexed eventId,
        uint256 amount,
        uint256 duration
    );
    // Emitted when new option is removed from an event
    event OptionRemoved(
        address indexed optionOwner,
        uint256 indexed eventId,
        uint256 amount
    );

    /***********/
    /* Methods */
    /***********/

    function createTicketing(
        uint256[] memory _eventSupply_Date_optionFees,
        address _referenceTokenAddress,
        uint256 _eventPrice,
        bool _greyMarketAllowed,
        string memory _offchainData,
        address[] memory _payees,
        uint256[] memory _shares
    ) public {
        require(
            _eventSupply_Date_optionFees.length == 3,
            "Mismatch in _eventSupply_Date_optionFees"
        );

        uint256 newEventID = totalEvents;

        _processCreateTicketing(
            newEventID,
            _eventSupply_Date_optionFees,
            _referenceTokenAddress,
            _eventPrice,
            _greyMarketAllowed,
            _payees,
            _shares
        );

        creatorTotalEvents[msg.sender] += 1;
        totalEvents += 1;

        saveOffchainData(newEventID, _offchainData);
    }

    function _processCreateTicketing(
        uint256 _newEventID,
        uint256[] memory _eventSupply_Date_optionFees,
        address _referenceTokenAddress,
        uint256 _eventPrice,
        bool _greyMarketAllowed,
        address[] memory _payees,
        uint256[] memory _shares
    ) private {
        _updateEventCreator(_newEventID);
        setEventTokenAndPrice(_newEventID, _referenceTokenAddress, _eventPrice);
        _addPayeesAndShares(_newEventID, _payees, _shares);
        _updateEventData(
            _newEventID,
            _eventSupply_Date_optionFees,
            _greyMarketAllowed
        );

        emit EventCreated(
            _newEventID,
            msg.sender,
            _eventSupply_Date_optionFees[0],
            _eventSupply_Date_optionFees[1],
            _eventSupply_Date_optionFees[2],
            _referenceTokenAddress,
            _eventPrice,
            _greyMarketAllowed
        );
    }

    function _updateEventCreator(uint256 newEventID) private {
        creatorOfEvent[newEventID] = msg.sender;
    }

    function setEventTokenAndPrice(
        uint256 _eventId,
        address _referenceTokenAddress,
        uint256 _eventPrice
    ) public onlyCreator(_eventId) {
        referenceTokenAddress[_eventId] = _referenceTokenAddress;
        eventPrice[_eventId] = _eventPrice;
    }

    function _addPayeesAndShares(
        uint256 newEventID,
        address[] memory _payees,
        uint256[] memory _shares
    ) private {
        addPayees(newEventID, _payees, _shares);
    }

    function _updateEventData(
        uint256 newEventID,
        uint256[] memory _eventSupply_Date_optionFees,
        bool _greyMarketAllowed
    ) private {
        eventInitialSupply[newEventID] = _eventSupply_Date_optionFees[0];
        eventSupply[newEventID] = _eventSupply_Date_optionFees[0];
        eventDate[newEventID] = _eventSupply_Date_optionFees[1];

        if (_eventSupply_Date_optionFees[2] > 0) {
            eventOptionFees[newEventID] = _eventSupply_Date_optionFees[2];
        } else {
            eventOptionFees[newEventID] = baseOptionFees;
        }

        eventGreyMarketAllowed[newEventID] = _greyMarketAllowed;
    }

    function saveOffchainData(
        uint256 _id,
        string memory _offchainData
    ) public onlyCreator(_id) {
        require(totalEvents >= _id, "Event doesn't exist");

        if (bytes(_offchainData).length > 0) {
            // Update IPFS data for this event
            eventOffchainData[_id] = _offchainData;

            emit OffchainDataUpdated(_id, block.timestamp, _offchainData);
        }
    }


    function getEventPrice(uint256 eventId) public view returns (uint256) {
        return eventPrice[eventId];
    }

    function eventInfo(uint256 _id) public view returns (EventInfo memory) {
        require(totalEvents >= _id, "Event doesn't exist");

        EventInfo memory info;
        info.eventCreator = creatorOfEvent[_id];
        info.eventDate = eventDate[_id];
        info.referenceTokenAddress = referenceTokenAddress[_id];
        info.eventPrice = eventPrice[_id];
        info.optionFees = eventOptionFees[_id];
        info.eventInitialSupply = eventInitialSupply[_id];
        info.currentSupply = eventSupply[_id];
        info.offchainData = eventOffchainData[_id];

        return info;
    }
}

// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.4;

/**
 * Virtual RevenueManager contract.
 * @author Yoel Zerbib
 * Date created: 24.2.22.
 * Github
 **/

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract RevenueManager {

    mapping(uint => mapping(address => uint)) public shares;
    mapping(uint => mapping(address => bool)) public isPayee;
    mapping(uint => uint) public totalShare;

    mapping(uint => address[]) public payees;

    mapping(uint => mapping(address => uint)) public released;

    // Event ID to his creator address
    mapping(uint => address) public creatorOfEvent;

    // Mapping of eventID => eventRevenue
    mapping(uint => uint) public eventRevenue;

    modifier onlyCreator(uint _id) {
        require(msg.sender == creatorOfEvent[_id], "Caller is not the creator");
        _;
    }

    function addPayee(
        uint _id,
        address _payee,
        uint _share
    ) public onlyCreator(_id) {
        require(!isPayee[_id][_payee], "Payee already exist");
        require(totalShare[_id] + _share <= 100, "Share must not exceed 100%");

        isPayee[_id][_payee] = true;
        shares[_id][_payee] = _share;
        payees[_id].push(_payee);
        totalShare[_id] += _share;
    }

    function addPayees(
        uint _id,
        address[] memory _payees,
        uint[] memory _shares
    ) public onlyCreator(_id) {
        require(
            _payees.length == _shares.length,
            "Error: Array size mismatched"
        );

        for (uint i; i < _payees.length; i++) {
            addPayee(_id, _payees[i], _shares[i]);
        }
    }

    function getPayees(
        uint _id
    ) public view returns (address[] memory, uint[] memory) {
        require(
            payees[_id].length > 0,
            "No payee found. Event doesn't exist or payees haven't been set"
        );

        uint _length = payees[_id].length;

        uint[] memory allshares = new uint[](_length);

        for (uint i = 0; i < _length; i++) {
            allshares[i] = shares[_id][payees[_id][i]];
        }

        return (payees[_id], allshares);
    }

    function releasable(
        uint _id,
        address _payee
    ) public view returns (uint) {
        require(isPayee[_id][_payee], "Address is not payee");

        uint payeeRevenue;
        uint payeeReleased;

        payeeRevenue = (eventRevenue[_id] * shares[_id][_payee]) / 100;
        payeeReleased = released[_id][_payee];
    

        return payeeRevenue - payeeReleased;
    }

    function release(uint _id, address _payee, address _tokenAddress) public {
        require(
            isPayee[_id][msg.sender] || msg.sender == creatorOfEvent[_id],
            "You are not a payee nor the owner of the event"
        );
        uint amount = releasable(_id, _payee);
        require(
            amount > 0,
            "No funds to withdraw"
        );


        // If the token is ETH, use the native transfer function
        if (_tokenAddress == address(0)) {
            (bool sent, ) = (_payee).call{value: amount}("");
            require(sent, "Oops, withdrawal failed!");
        } else {
            // Otherwise, transfer the ERC-20 token
            bool sent = IERC20(_tokenAddress).transfer(_payee, amount);
            require(sent, "Oops, withdrawal failed!");
            released[_id][_payee] += amount;
        }
    }

    // function withdrawERC20Token(
    //     address tokenAddress,
    //     uint256 amount,
    //     address recipient
    // ) external onlyOperator {
    //     IERC20 token = IERC20(tokenAddress);
    //     uint256 contractBalance = token.balanceOf(address(this));
    //     require(contractBalance >= amount, "Not enough tokens in the contract");

    //     uint256 allowance = token.allowance(address(this), recipient);
    //     require(allowance >= amount, "Allowance not sufficient");

    //     token.transfer(recipient, amount);
    // }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.4;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}