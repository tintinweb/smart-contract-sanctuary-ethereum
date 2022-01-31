/**
 *Submitted for verification at Etherscan.io on 2022-01-31
*/

// File: @openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: @openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol


// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;


/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
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

// File: @openzeppelin/contracts-upgradeable/token/ERC721/utils/ERC721HolderUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;



/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721HolderUpgradeable is Initializable, IERC721ReceiverUpgradeable {
    function __ERC721Holder_init() internal onlyInitializing {
        __ERC721Holder_init_unchained();
    }

    function __ERC721Holder_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol


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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// File: @openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;



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
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}

// File: contracts/AdminManager.sol



pragma solidity ^0.8.0;



interface IMintable {
    // Required read methods
    function getApproved(uint256 tokenId) external returns (address operator);

    function tokenURI(uint256 tokenId) external returns (string memory);

    // Required write methods
    function approve(address _to, uint256 _tokenId) external;

    function transfer(address _to, uint256 _tokenId) external;

    function burn(uint256 tokenId) external;

    function mint(string calldata _tokenURI, uint256 _royality) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

interface IBrokerV2 {
    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    ) external payable;

    function collect(uint256 tokenID, address _mintableToken) external;

    function buy(uint256 tokenID, address _mintableToken) external payable;

    function makeAnOffer(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    ) external payable;

    function AccpetOffer(uint256 tokenID, address _mintableToken)
        external
        payable;

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _startingTime,
        uint256 _closingTime,
        address _mintableToken,
        address _erc20Token
    ) external;

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    ) external;

    function putSaleOff(uint256 tokenID, address _mintableToken) external;
}

interface IERC20 {
    function approve(address spender, uint256 value) external;

    function decreaseApproval(address _spender, uint256 _subtractedValue)
        external;

    function increaseApproval(address spender, uint256 addedValue) external;

    function transfer(address to, uint256 value) external;

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external;

    function increaseAllowance(address spender, uint256 addedValue) external;

    function decreaseAllowance(address spender, uint256 subtractedValue)
        external;

    function balanceOf(address who) external view returns (uint256);
}

/**
 * @title AdminManager
 * @author Yogesh Singh
 * @notice You can use this contract to execute function on behalf of superUser
 * @dev Mediator contract to allow muliple user to perform ERC721 action using contracts address only
 */
contract AdminManagerUpgradeable is
    OwnableUpgradeable,
    ERC721HolderUpgradeable
{
    address[] public admins;

    struct FunctionNames {
        string approve;
        string transfer;
        string burn;
        string mint;
        string safeTransferFrom;
        string transferFrom;
        string putOnSale;
        string makeAnOffer;
        string AccpetOffer;
        string buy;
        string bid;
        string collect;
        string updatePrice;
        string putSaleOff;
        string erc20Approve;
        string erc20DecreaseApproval;
        string erc20IncreaseApproval;
        string erc20Transfer;
        string erc20TransferFrom;
        string erc20IncreaseAllowance;
        string erc20DecreaseAllowance;
    }

    FunctionNames functionNames =
        FunctionNames(
            "ERC721:approve",
            "ERC721:transfer",
            "ERC721:burn",
            "ERC721:mint",
            "ERC721:safeTransferFrom",
            "ERC721:transferFrom",
            "Broker:putOnSale",
            "Broker:makeAnOffer",
            "Broker:AccpetOffer",
            "Broker:buy",
            "Broker:bid",
            "Broker:collect",
            "Broker:updatePrice",
            "Broker:putSaleOff",
            "ERC20:approve",
            "ERC20:decreaseApproval",
            "ERC20:increaseApproval",
            "ERC20:transfer",
            "ERC20:transferFrom",
            "ERC20:increaseAllowance",
            "ERC20:decreaseAllowance"
        );

    IBrokerV2 broker;

    event NFTBurned(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed admin,
        uint256 time,
        string tokenURI
    );
    event AdminRemoved(address admin, uint256 time);
    event AdminAdded(address admin, uint256 time);

    event AdminActionPerformed(
        address indexed admin,
        address indexed contractAddress,
        string indexed functionName,
        address collectionAddress,
        uint256 tokenId
    );

    // constructor(address _broker) {
    //     transferOwnership(msg.sender);
    //     broker = IBrokerV2(_broker);
    // }

    function initialize(address _broker) public initializer {
        OwnableUpgradeable.__Ownable_init();
        broker = IBrokerV2(_broker);
        transferOwnership(msg.sender);
    }

    function isOwner() public view returns (bool) {
        if (msg.sender == owner()) {
            return true;
        }
        return false;
    }

    /**
     * @notice This function is used to check address of admin exist or not in list of admin
     * @dev Fuction take address type argument
     * @param _sender The account address of _sender or admin
     */
    function adminExist(address _sender) public view returns (bool) {
        for (uint256 i = 0; i < admins.length; i++) {
            if (_sender == admins[i]) {
                return true;
            }
        }
        return false;
    }

    modifier adminOnly() {
        require(adminExist(msg.sender), "AdminManager: admin only.");
        _;
    }

    modifier adminAndOwnerOnly() {
        require(
            adminExist(msg.sender) || isOwner(),
            "AdminManager: admin and owner only."
        );
        _;
    }

    /**
     * @notice This function is used to add address of admins
     * @dev Fuction take address type argument
     * @param admin The account address of admin
     */
    function addAdmin(address admin) public onlyOwner {
        if (!adminExist(admin)) {
            admins.push(admin);
        } else {
            revert("admin already in list");
        }

        emit AdminAdded(admin, block.timestamp);
    }

    /**
     * @notice This function is used to get list of all address of admins
     * @dev This Fuction is not take any argument
     * @return This Fuction return list of address[]
     */
    function getAdmins() public view returns (address[] memory) {
        return admins;
    }

    /**
     * @notice This function is used to get list of all address of admins
     * @dev This Fuction is not take any argument
     * @param admin The account address of admin
     */
    function removeAdmin(address admin) public onlyOwner {
        for (uint256 i = 0; i < admins.length; i++) {
            if (admins[i] == admin) {
                admins[admins.length - 1] = admins[i];
                admins.pop();
                break;
            }
        }
        emit AdminRemoved(admin, block.timestamp);
    }

    /**
     * @notice This function is used to burn the apporved NFTToken to certain admin address which was allowed by super admin the owner of Admin Manager
     * @dev This Fuction is take two arguments address of contract and tokenId of NFT
     * @param collection tokenId The contract address of NFT contract and tokenId of NFT
     */
    function burnNFT(address collection, uint256 tokenId)
        public
        adminAndOwnerOnly
    {
        IMintable NFTToken = IMintable(collection);

        string memory tokenURI = NFTToken.tokenURI(tokenId);
        require(
            NFTToken.getApproved(tokenId) == address(this),
            "Token not apporove for burn"
        );
        NFTToken.burn(tokenId);
        emit NFTBurned(
            collection,
            tokenId,
            msg.sender,
            block.timestamp,
            tokenURI
        );
    }

    // NFT methods for admin to manage by this contract URL
    function erc721Approve(
        address _ERC721Address,
        address _to,
        uint256 _tokenId
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.approve,
            _ERC721Address,
            _tokenId
        );
        return erc721.approve(_to, _tokenId);
    }

    function erc721Transfer(
        address _ERC721Address,
        address _to,
        uint256 _tokenId
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.transfer,
            _ERC721Address,
            _tokenId
        );
        return erc721.transfer(_to, _tokenId);
    }

    function erc721Burn(address _ERC721Address, uint256 tokenId)
        public
        adminAndOwnerOnly
    {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.burn,
            _ERC721Address,
            tokenId
        );
        return erc721.burn(tokenId);
    }

    function erc721Mint(
        address _ERC721Address,
        string memory tokenURI,
        uint256 _royality
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.mint,
            _ERC721Address,
            0
        );
        return erc721.mint(tokenURI, _royality);
    }

    function erc721SafeTransferFrom(
        address _ERC721Address,
        address from,
        address to,
        uint256 tokenId
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.safeTransferFrom,
            _ERC721Address,
            tokenId
        );
        return erc721.safeTransferFrom(from, to, tokenId);
    }

    function erc721SafeTransferFrom(
        address _ERC721Address,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.safeTransferFrom,
            _ERC721Address,
            tokenId
        );
        return erc721.safeTransferFrom(from, to, tokenId, _data);
    }

    function erc721TransferFrom(
        address _ERC721Address,
        address from,
        address to,
        uint256 tokenId
    ) public adminAndOwnerOnly {
        IMintable erc721 = IMintable(_ERC721Address);
        emit AdminActionPerformed(
            msg.sender,
            _ERC721Address,
            functionNames.transferFrom,
            _ERC721Address,
            tokenId
        );
        return erc721.transferFrom(from, to, tokenId);
    }

    // Broker functions
    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    ) public payable adminAndOwnerOnly {
        broker.bid(tokenID, _mintableToken, amount);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.bid,
            _mintableToken,
            tokenID
        );
    }

    function collect(uint256 tokenID, address _mintableToken)
        public
        adminAndOwnerOnly
    {
        broker.collect(tokenID, _mintableToken);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.collect,
            _mintableToken,
            tokenID
        );
    }

    function buy(uint256 tokenID, address _mintableToken)
        public
        payable
        adminAndOwnerOnly
    {
        broker.buy(tokenID, _mintableToken);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.buy,
            _mintableToken,
            tokenID
        );
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _startingTime,
        uint256 _closingTime,
        address _mintableToken,
        address _erc20Token
    ) public adminAndOwnerOnly {
        broker.putOnSale(
            _tokenID,
            _startingPrice,
            _auctionType,
            _buyPrice,
            _startingTime,
            _closingTime,
            _mintableToken,
            _erc20Token
        );
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.putOnSale,
            _mintableToken,
            _tokenID
        );
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    ) public adminAndOwnerOnly {
        broker.updatePrice(tokenID, _mintableToken, _newPrice, _erc20Token);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.updatePrice,
            _mintableToken,
            tokenID
        );
    }

    function putSaleOff(uint256 tokenID, address _mintableToken)
        public
        adminAndOwnerOnly
    {
        broker.putSaleOff(tokenID, _mintableToken);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.putSaleOff,
            _mintableToken,
            tokenID
        );
    }

    function makeAnOffer(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    ) public payable adminAndOwnerOnly {
        broker.makeAnOffer(tokenID, _mintableToken, amount);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.putSaleOff,
            _mintableToken,
            tokenID
        );
    }

    function AccpetOffer(uint256 tokenID, address _mintableToken)
        public
        payable
        adminAndOwnerOnly
    {
        broker.AccpetOffer(tokenID, _mintableToken);
        emit AdminActionPerformed(
            msg.sender,
            address(broker),
            functionNames.putSaleOff,
            _mintableToken,
            tokenID
        );
    }

    // ERC20 methods
    function erc20Approve(
        address _erc20,
        address spender,
        uint256 value
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.approve(spender, value);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20Approve,
            spender,
            value
        );
    }

    function erc20DecreaseApproval(
        address _erc20,
        address _spender,
        uint256 _subtractedValue
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.decreaseApproval(_spender, _subtractedValue);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20DecreaseAllowance,
            _spender,
            _subtractedValue
        );
    }

    function erc20IncreaseApproval(
        address _erc20,
        address spender,
        uint256 addedValue
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.increaseApproval(spender, addedValue);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20IncreaseApproval,
            spender,
            addedValue
        );
    }

    function erc20Transfer(
        address _erc20,
        address to,
        uint256 value
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transfer(to, value);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20Transfer,
            to,
            value
        );
    }

    function erc20TransferFrom(
        address _erc20,
        address from,
        address to,
        uint256 value
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.transferFrom(from, to, value);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20TransferFrom,
            to,
            value
        );
    }

    function erc20IncreaseAllowance(
        address _erc20,
        address spender,
        uint256 addedValue
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.increaseAllowance(spender, addedValue);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20IncreaseAllowance,
            spender,
            addedValue
        );
    }

    function erc20DecreaseAllowance(
        address _erc20,
        address spender,
        uint256 subtractedValue
    ) public adminAndOwnerOnly {
        IERC20 erc20 = IERC20(_erc20);
        erc20.decreaseAllowance(spender, subtractedValue);
        emit AdminActionPerformed(
            msg.sender,
            _erc20,
            functionNames.erc20DecreaseAllowance,
            spender,
            subtractedValue
        );
    }

    // Fallback function
    fallback() external payable {}

    receive() external payable {
        // custom function code
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }
}