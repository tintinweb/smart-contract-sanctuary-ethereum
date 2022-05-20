/**
 *Submitted for verification at Etherscan.io on 2022-05-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;



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
    uint256[49] private __gap;
}

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

interface IHACK is IERC20Upgradeable{
    function earnTokens(address to, uint256 amount) external; 
    function lostTokens(address from, uint256 amount) external; 
}
interface ISKILL is IERC20Upgradeable{
    function earnTokens(address to, uint256 amount) external; 
    function lostTokens(address from, uint256 amount) external; 
}
/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

contract GAME is OwnableUpgradeable, ReentrancyGuardUpgradeable{

    struct StakeNFT{
        uint256 cube_id;
        uint date_start;
        uint8 active;
    }
    struct StakeToken{
        uint date_start;
        uint8 active;
        uint256 amount;
    }
    uint8 constant WALLS = 0;
    uint8 constant FLOOR = 1;
    uint8 constant PC = 2;
    uint8 constant TABLE = 3;
    uint8 constant CONSOLE =4;

    address private _token; 
    uint256 private _price;
    uint256 private _skills_reward;
    uint256 private _stake_pool;
    uint256 private _liquidity_pool;
    uint256 private _levelUpPrice;   
    IERC721 private _hacker_nft;
    IERC721 private _cube_nft;
    ISKILL private _skills;
    IHACK private _hack;
    uint256 private _hacker_base_rewards;
    mapping(address => mapping(uint256 => StakeNFT)) private _nft_stakes;
    mapping(address => StakeToken) private _token_stakes;
    mapping(uint256 => uint8) private _hacker_levels;
    mapping(uint256 => mapping(uint8 => uint8)) private _cube_levels;
    mapping(uint8 => mapping(uint8 => uint256)) private _cube_rewards;
    mapping(uint8 => mapping(uint8 => uint256)) private _cube_upgrade_price;


    event NFTStaked(address indexed sender, uint256 indexed hacker_id, uint256 indexed cube_id);
    event NFTUnStaked(address indexed sender, uint256 indexed hacker_id, uint256 indexed cube_id);
    event TokenStaked(address indexed sender, uint256 amount);
    event TokenUnStaked(address indexed sender, uint256 amount);
    

    function initialize() initializer public {
        __Ownable_init();
        __ReentrancyGuard_init();
        _price = 0.03 ether;
        _cube_rewards[WALLS][0] = 100; // x1.0
        _cube_rewards[WALLS][1] = 110; // x1.1
        _cube_rewards[WALLS][2] = 130; // x1.3
        _cube_rewards[WALLS][3] = 150; // x1.5
        _cube_rewards[WALLS][4] = 200; // x2
        
        _cube_rewards[FLOOR][0] = 100; 
        _cube_rewards[FLOOR][1] = 110; 
        _cube_rewards[FLOOR][2] = 130; 
        _cube_rewards[FLOOR][3] = 150; 
        _cube_rewards[FLOOR][4] = 200; 
        
        _cube_rewards[PC][0] = 0.5 ether;
        _cube_rewards[PC][1] = 1.5 ether;
        _cube_rewards[PC][2] = 3 ether; 
        _cube_rewards[PC][3] = 10 ether;
        _cube_rewards[PC][4] = 25 ether;
        
        _cube_rewards[TABLE][0] = 0.3 ether;
        _cube_rewards[TABLE][1] = 1 ether;
        _cube_rewards[TABLE][2] = 3 ether;
        _cube_rewards[TABLE][3] = 8 ether;
        _cube_rewards[TABLE][4] = 20 ether; 
        
        _cube_rewards[CONSOLE][0] = 0.2 ether; // 1%
        _cube_rewards[CONSOLE][1] = 1 ether; // 1%
        _cube_rewards[CONSOLE][2] = 2 ether; // 1%
        _cube_rewards[CONSOLE][3] = 5 ether; // 1%
        _cube_rewards[CONSOLE][4] = 15 ether; // 1%

        _cube_upgrade_price[WALLS][0] = 0; // x1.0
        _cube_upgrade_price[WALLS][1] = 100 ether; // x1.1
        _cube_upgrade_price[WALLS][2] = 500 ether; // x1.3
        _cube_upgrade_price[WALLS][3] = 1000 ether; // x1.5
        _cube_upgrade_price[WALLS][4] = 3000 ether; // x2
        
        _cube_upgrade_price[FLOOR][0] = 0; 
        _cube_upgrade_price[FLOOR][1] = 100 ether; 
        _cube_upgrade_price[FLOOR][2] = 500 ether; 
        _cube_upgrade_price[FLOOR][3] = 1000 ether; 
        _cube_upgrade_price[FLOOR][4] = 3000 ether; 
        
        _cube_upgrade_price[PC][0] = 0;
        _cube_upgrade_price[PC][1] = 150 ether;
        _cube_upgrade_price[PC][2] = 270 ether; 
        _cube_upgrade_price[PC][3] = 700 ether;
        _cube_upgrade_price[PC][4] = 1750 ether;
        
        _cube_upgrade_price[TABLE][0] = 0 ether;
        _cube_upgrade_price[TABLE][1] = 100 ether;
        _cube_upgrade_price[TABLE][2] = 270 ether;
        _cube_upgrade_price[TABLE][3] = 700 ether;
        _cube_upgrade_price[TABLE][4] = 1500 ether; 
        
        _cube_upgrade_price[CONSOLE][0] = 0 ether; // 1%
        _cube_upgrade_price[CONSOLE][1] = 100 ether; // 1%
        _cube_upgrade_price[CONSOLE][2] = 180 ether; // 1%
        _cube_upgrade_price[CONSOLE][3] = 450 ether; // 1%
        _cube_upgrade_price[CONSOLE][4] = 1200 ether; // 1%

        _hacker_base_rewards = 0.05 ether;
        _skills_reward = 0.001 ether;
        //_levelUpPrice = 0.01 ether;
        
        
    }
    
    function updateHackerLevels( uint256[] memory ids, uint8[] memory levels ) external onlyOwner{
        require( levels.length == ids.length,"Error in length");
        for(uint i=0;i<ids.length;i++){
            _hacker_levels[ids[i]]=levels[i];

        }
    }




    function updateHackerLevel( uint256 id) external nonReentrant{
        uint256 need_hack = (1 + _hacker_levels[id] * 5 / 100) * ( 2 +  _hacker_levels[id] / 100 );
        uint256 need_skill =10 * (1 + _hacker_levels[id] * 5 / 100) * ( 2 +  _hacker_levels[id] / 100 );
        require(_hack.allowance(msg.sender, address(this) ) >= need_hack, "Not enough $HACK");
        require(_skills.allowance(msg.sender, address(this) ) >= need_skill, "Not enough $SKILL");
        require( _hacker_nft.ownerOf(id) == msg.sender ,"Not owner of the NFT");
        _hacker_levels[id] +=1;
        _hack.transferFrom(msg.sender, address(this), need_hack );
        _skills.transferFrom(msg.sender, address(this), need_skill );
    }

    function updateCubeLevel( uint256 id, uint8 upgrade) external nonReentrant{
        uint256 need_hack = _cube_upgrade_price[upgrade][_cube_levels[id][upgrade]];
        require(upgrade >=0 && upgrade <5, "Illegal upgrade type");
        require(_hack.allowance(msg.sender, address(this) ) >= need_hack, "Not enough $HACK");
        
        require( _hacker_nft.ownerOf(id) == msg.sender ,"Not owner of the NFT");
        _cube_levels[id][upgrade] +=1;
        _hack.transferFrom(msg.sender, address(this), need_hack );
        
    }


    function updateSkillContract( address token ) external onlyOwner{
        _skills = ISKILL( token );
    }

    function updateHackerNTFContract( address nft ) external onlyOwner{
        _hacker_nft = IERC721( nft );
    }

    function updateCubeNTFContract( address nft ) external onlyOwner{
        _cube_nft = IERC721( nft );
    }

    function updateHackContract( address token ) external onlyOwner{
        _hack = IHACK( token );
    }
    

    function stakeHack(uint256 amount ) external nonReentrant{
        require(_hack.balanceOf(msg.sender) >= amount, "Amount is more than balance" );
        (msg.sender, address(this), amount);
        _token_stakes[msg.sender].date_start=block.timestamp;
        _token_stakes[msg.sender].active=1;
        _token_stakes[msg.sender].amount=amount;
        emit TokenStaked(msg.sender, amount);
    }
    
    function unstakeHack() external nonReentrant{
        require( address(_skills) != address(0x0), "Skills not activated");
        require(_token_stakes[msg.sender].active == 1, "Stake is not active" );
        _hack.earnTokens( msg.sender, _token_stakes[msg.sender].amount);
        uint256 days_past = (block.timestamp - _token_stakes[msg.sender].date_start) / 86400;
        _token_stakes[msg.sender].active=0;
        emit TokenStaked(msg.sender, _token_stakes[msg.sender].amount);
        uint256 reward = days_past * _skills_reward;
        _stake_pool-=_token_stakes[msg.sender].amount;
        _token_stakes[msg.sender].amount=0;

        if (days_past == 0){
            _hack.lostTokens(msg.sender, _hack.balanceOf(msg.sender) * 75 / 100);
        }else{
            if (_skills.balanceOf(address(this)) >= reward){
                _skills.transfer(msg.sender, reward);
            }else{
                _skills.transfer(msg.sender, _skills.balanceOf(address(this)));
            }
        }

        
    }

    function stakeHacker(uint256 hacker_id ) external nonReentrant{
        require(_hacker_nft.ownerOf(hacker_id) == msg.sender, "Not owner of token" );
        _hacker_nft.transferFrom(msg.sender, address(this), hacker_id);
        _nft_stakes[msg.sender][hacker_id].date_start=block.timestamp;
        _nft_stakes[msg.sender][hacker_id].active=1;
        _nft_stakes[msg.sender][hacker_id].cube_id=0x0;
        emit NFTStaked(msg.sender, hacker_id,0x0);
    }
    function stakeHackerAndCube(uint256 hacker_id, uint256 cube_id ) external nonReentrant{
        require(_hacker_nft.ownerOf(hacker_id) == msg.sender, "Not owner of HACKER token" );
        require(_cube_nft.ownerOf(cube_id) == msg.sender, "Not owner of CUBE token" );
        _hacker_nft.transferFrom(msg.sender, address(this), hacker_id);
        _cube_nft.transferFrom(msg.sender, address(this), cube_id);
        _nft_stakes[msg.sender][hacker_id].date_start=block.timestamp;
        _nft_stakes[msg.sender][cube_id].active=1;
        emit NFTStaked(msg.sender, hacker_id,cube_id);
    }


    function unstakeHacker(uint256 hacker_id)external nonReentrant{
        uint256 hack_reward = 0;
        uint256 skill_reward = 0;
        require(_nft_stakes[msg.sender][hacker_id].active == 1, "Token is not staked" );
        _nft_stakes[msg.sender][hacker_id].active = 0;
        _hacker_nft.transferFrom(address(this), msg.sender, hacker_id);
        
        uint256 days_past = (block.timestamp - _nft_stakes[msg.sender][hacker_id].date_start) / 86400;
        hack_reward = days_past * _hacker_base_rewards;

        if (_nft_stakes[msg.sender][hacker_id].cube_id != 0x0){
            uint256 cube_id = _nft_stakes[msg.sender][hacker_id].cube_id;
            _cube_nft.transferFrom(address(this), msg.sender, cube_id);
            hack_reward += _cube_rewards[WALLS][_cube_levels[cube_id][WALLS]];
            hack_reward += _cube_rewards[FLOOR][_cube_levels[cube_id][FLOOR]];
            hack_reward += _cube_rewards[PC][_cube_levels[cube_id][PC]];
            hack_reward += _cube_rewards[TABLE][_cube_levels[cube_id][TABLE]];
            hack_reward += _cube_rewards[CONSOLE][_cube_levels[cube_id][CONSOLE]];
        }

        if (days_past == 0){
            _hack.lostTokens(msg.sender, _hack.balanceOf(msg.sender) * 75 / 100);
        }else{
            _hack.earnTokens(msg.sender, hack_reward);
            _skills.earnTokens(msg.sender, skill_reward);
        }
        
        emit NFTUnStaked(msg.sender, hacker_id,_nft_stakes[msg.sender][hacker_id].cube_id);
    }

}