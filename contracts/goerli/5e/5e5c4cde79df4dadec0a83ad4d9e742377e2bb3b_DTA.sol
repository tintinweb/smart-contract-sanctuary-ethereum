/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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

// File: HellsDao/IHellsDao.sol


pragma solidity >=0.8.0 <0.9.0;



interface IHD is IERC721 {

    function totalLevels() external view returns (uint256 totalLevels);

    function rank(uint256 _tokenId) external view returns(uint8 ranks, uint256 passLevel, uint256 toplevel, uint8 house);
}
// File: HellsDao/HellBallots.sol


pragma solidity >=0.8.0 <0.9.0;


contract HellBallots{

    event voteCast(uint256 indexed voteNumber, uint256 indexed doaID, bool indexed cast);
    event ballotCreated(address creator, bool created, uint256 indexed ballotIndex);

    IHD ihd;
    //maps doaIds to vote index and tracks if they have voted yet
    mapping(uint256 => mapping(uint256 => bool)) passToVote;

    uint8 vP;
    //current vote activity
    uint256 public voteIndex;
    //tracks pauses inbetween votes
    uint256 public reccess;

    string contractName;
    address __ihd;
    //tracks ballots
    Ballot[] public voteRecord;

    uint256 public delayTimer = 30 days;


    struct Ballot{

        uint256 votesToPass; // votes needed to pass
        uint256 votesToFail; // votes needed to fail
        uint256[2] votes; //current votes index 0 pass index 1 fail
        uint256 timeToFinish; // if time runs out vote fails
        bool finished; // active?
        bool votePass; // pass?
    }

    constructor(string memory _name, address _hellDao, uint8 _votePercentage){
        if(_hellDao != address(0)){
            ihd = IHD(_hellDao);
        }
        __ihd = _hellDao;
        uint256[2] memory a;
        voteRecord.push(Ballot(0,0, a ,0,true, false));
        reccess = block.timestamp + delayTimer;
        contractName = _name;
        if(_votePercentage <=1){
            vP = 4;
        }

    }

    /**
     * @dev checks to see if pass can vote.
     */

    modifier canVote(uint _doaId){

        require(!voteRecord[voteIndex].finished && !passToVote[_doaId][voteIndex], "Error with voting");
        _;
    }

    modifier ownsDao(uint256 _tokenId){

        require(ihd.ownerOf(_tokenId)==msg.sender, "Error: Not owner of this Pass");
        _;
    }

    /**
     * @dev used to setVote of caller and new ballots
     * @param _doaId, the multipass being used to set up new ballot
     */
    function _setVote(uint256 _doaId)internal returns(uint256){

        Ballot memory a;
        uint256 tl = ihd.totalLevels();
        ( ,uint256 pL, ,) = ihd.rank(_doaId);
        passToVote[_doaId][voteIndex+1] = true;
        a.votesToPass = (tl*(vP-1))/vP;
        a.votesToFail = tl/vP;
        a.votes[0] += pL;
        a.timeToFinish = block.timestamp + delayTimer;
        voteRecord.push(a);
        voteIndex +=1;

        emit voteCast(pL, _doaId, true);

        return voteIndex -1;
    }

    /**
     * @dev function for multipass holders to vote on the new base for maxVidya
     * @param _doaId the multipass the holder owns and is voting with
     * @param _for true for yes false for no, sihdle right? 
     */

    function _vote(uint256 _doaId, bool _for)internal virtual returns(bool, bool){
        
        Ballot storage a = voteRecord[voteIndex];
        bool voteFinished = a.timeToFinish > block.timestamp;
        if(!voteFinished){
            passToVote[_doaId][voteIndex] = true;
            ( ,uint256 pL, ,) = ihd.rank(_doaId);
            if(_for){
                a.votes[0] += pL;
                voteFinished = a.votes[0] >= a.votesToPass;
                a.finished = voteFinished;
                a.votePass = voteFinished;
            }else{
                a.votes[1] += pL;
                voteFinished = a.votes[1] >= a.votesToFail;
                a.finished = voteFinished;
            }
            emit voteCast(pL, _doaId, _for);
        }
        if(voteFinished){
            reccess = block.timestamp + delayTimer;
        }
        return (voteFinished, a.votePass);
    }

    /**
     * @dev internal function used to start a new ballot callable by any contract using the multipass as it's base.
     * @param doaId the pass calling the vote to order
     * @return bool did a ballot get created
     */

    function _startABallot(uint256 doaId)internal virtual returns(bool, uint256){

        require(block.timestamp >= reccess, "Hold your horses.");
        Ballot storage lastVote = voteRecord[voteIndex];
        require(lastVote.finished || lastVote.timeToFinish < block.timestamp, "One vote at a time.");
        if(!lastVote.finished){
            lastVote.finished = true;
            reccess = block.timestamp + delayTimer;
            emit ballotCreated(address(this), false, 0); 
            return (false, 0);
        }else{
            uint256 a = _setVote(doaId);
            emit ballotCreated(ihd.ownerOf(doaId),true, voteIndex);
            return (true, a);
        }
    }

    function setDaoForTeam()external view returns(Ballot memory, string memory){

        return (voteRecord[0], contractName);
    }

    function lastBallot()external view returns(Ballot memory, uint256, string memory){

        return (voteRecord[voteIndex], reccess ,contractName);

    }
    
    function _setAddress(address _ihd)internal{

        if(__ihd == address(0) && _ihd != address(0) ){
            __ihd = _ihd;
            ihd =IHD(_ihd);
        }

    }

}
// File: IRouter.sol


pragma solidity >=0.8.0 <0.9.0;

interface IRouter{

    function createLP( address tokenB, uint amountADesired, uint amountBDesired)external;
    function createLPETH(uint256 amountTokenDesired)external payable;

}
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// File: @openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// File: @openzeppelin/contracts/utils/Address.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: @openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;




/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
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
        IERC20 token,
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
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
abstract contract ReentrancyGuard {
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

    constructor() {
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
}

// File: DTA.sol


pragma solidity >=0.8.0 <0.9.0;








interface IMinter{
    function mint(address receiver, uint256 toMint, address router)external;
    function getBurnedCount()external view returns(uint256);
}

contract DTA is ReentrancyGuard, Ownable, HellBallots{

    using Address for address;
    using SafeERC20 for IERC20;

    event RouterToggled(address indexed router, string indexed dex, bool active);
    event TokenSwap(address indexed user, address indexed token, uint256 amountSpent, uint256 indexed LAZRReceived);
    event TokenToggled(address indexed token, bool active);
    event ballotCreated(bool created, uint256 indexed ballotIndex, address token);


    IMinter public minter = IMinter(0x021Bd951d06Fd3A63AE9a08cD6d48CBD405ff314 );

    mapping(address => bool) public approvedTokens;
    uint256 public triSumOfTokens = 1;

    mapping(uint256 => uint256) public unlock;
    mapping(address=> Data) public mintInformation;
    mapping(address => uint256) _tokenIndex;
    address[] public tokens;

    struct Data{
        uint256 initailTokenA;
        uint256 initailPrimary;
        uint256 tokenASpent;
        uint256 primaryBurned;
    }

    address[] public routers;
    string[] public exchange;
    uint8 public routerCount;
    uint8 routerIndex;

    Data public currentVoteToAdd;
    mapping(uint256 => address) public indexToToken;
    mapping(uint256 => bool) public indexToRA;

    constructor()HellBallots("Dynamic Token Allocation", 0x899BF84CeA7A2c6a335f6ce8050eBe6ae292409A, 10){

        mintInformation[address(this)] = Data (1 ether, 1000 ether, 0, 0); //Set For Matic or other blockchain gas
        approvedTokens[address(this)] = true;
        tokens.push(address(this));
    }

    modifier canCreate(uint256 tokenId, address token){
        require(ihd.ownerOf(tokenId) == msg.sender && approvedTokens[token]);
        require(unlockTime(tokenId) <= block.timestamp, "Need to wait to mint more");
        _;
    }

    function swapTokenETH(uint256 minAmount, uint256 daoId)external payable canCreate(daoId, address(this)) nonReentrant{
        
        uint256 _mintAmount = _ImintAmount(address(this), msg.value);
        require(minAmount <= _mintAmount, "DTA: Not within minting standards");
        swapInternalEth( _mintAmount, msg.sender);
        unlock[daoId] = block.timestamp + delayTimer;
    }

    function swapToken(uint256 minAmount, uint256 amountTokenA, address tokenA, uint256 daoId)external canCreate(daoId, tokenA) nonReentrant{

        uint256 _mintAmount = _ImintAmount( tokenA, amountTokenA);
        require(minAmount <= _mintAmount, "DTA: Not within minting standards");
        swapInternal( _mintAmount, amountTokenA, tokenA,  msg.sender);
        unlock[daoId] = block.timestamp + delayTimer;

    }


    function pickRouter()internal returns(address){
        address _router = routers[routerIndex];
        routerIndex = (routerIndex + 1)%routerCount;
        return _router;
    }

    function swapInternalEth(uint256 _mintAmount, address receiver)internal{
        address _router = pickRouter();
        uint256 amount = msg.value;
        minter.mint(receiver, _mintAmount, _router);
        IRouter(_router).createLPETH{value: amount}(_mintAmount/2);
        mintInformation[address(this)].tokenASpent += amount;

        emit TokenSwap(receiver, address(this), amount, _mintAmount);
    }

    function swapInternal(uint256 _mintAmount, uint256 amountTokenA, address tokenA, address receiver) internal{
        
        address _router = pickRouter();
        IERC20 _tokenA = IERC20(tokenA);    
        _tokenA.safeTransferFrom(receiver, _router, amountTokenA);
        minter.mint(receiver, _mintAmount, _router);
        IRouter(_router).createLP(tokenA, _mintAmount/2, amountTokenA);
        mintInformation[tokenA].tokenASpent += amountTokenA;
        emit TokenSwap(receiver, tokenA, amountTokenA, _mintAmount);
    }

    function _ImintAmount(address token, uint256 amount)internal view returns(uint256){

        Data memory data = mintInformation[token];
        if(data.initailTokenA != 0){
            uint256 a;
            uint256 b = data.tokenASpent + data.initailTokenA;
            uint256 burn = minter.getBurnedCount() - data.primaryBurned;
            a = amount * (data.initailPrimary + (burn/triSumOfTokens));
            return a/b;
        }else{
            return 0;
        }
    }

    function mintAmount(address token, uint256 tokenAmount)public view returns(uint256){
        return _ImintAmount(token, tokenAmount);
    }

    function requestToChangeToken(uint256 id, address tokenA, bool removeFalseAddTrue,uint256 initailTokenA, 
                                    uint256 initailPrimary)external ownsDao(id) returns(bool){
                    //LAZR amount greater than 0 and tokenA amount greater then 0, 
        bool stuff = ((initailPrimary > 0 && initailTokenA > 0) //Also requires that you only remove tokens already approved and add tokens not approved
                        && approvedTokens[tokenA] != removeFalseAddTrue);
        require(stuff, "Requires: Conditional to be met");
        (bool set, uint256 i) = _startABallot(id);
        if(set){
            indexToToken[i] = tokenA;
            indexToRA[i] = removeFalseAddTrue;
            setData(initailTokenA, initailPrimary);
            emit ballotCreated(set, i, tokenA);
        }

        return set;

    }

    function setData(uint256 initailTokenA, uint256 initailPrimary)internal{
        currentVoteToAdd = Data(initailTokenA, initailPrimary, 0, 0);
    }

    function vote(uint256 daoId, bool _for)external ownsDao(daoId) canVote(daoId){
        (bool completed, bool passed) = _vote(daoId, _for);
        if(completed){
            reccess = block.timestamp + delayTimer;
            if(passed){
                if(indexToRA[voteIndex]){
                    addToken(indexToToken[voteIndex]);
                }else{
                    removeToken(indexToToken[voteIndex]);
                }
            }
        }
    }

    function removeToken(address token)internal{
        approvedTokens[token] = false;
        mintInformation[token] = Data(0,0,0,0);
        uint a = _tokenIndex[token];
        if(tokens[a] == token){
            address t = tokens[tokens.length -1];
            tokens[a] = t;
            tokens.pop();
            _tokenIndex[t] = a;
        }
        uint256 n = tokens.length;
        triSumOfTokens = ((n+1) * n)/2;

        emit TokenToggled(token, false);
    }

    function addToken(address token)internal{

        currentVoteToAdd.primaryBurned = minter.getBurnedCount();
        approvedTokens[token] = true;
        mintInformation[token] = currentVoteToAdd;
        currentVoteToAdd = Data(0,0,0,0);
        uint256 n = tokens.length;
        _tokenIndex[token] = n;
        tokens.push(token);
        n++;
        triSumOfTokens = ((n+1) * n)/2;  

        emit TokenToggled(token, true);
    }

    function ownerAddToken(address tokenA,uint256 initailTokenA, uint256 initailPrimary)external onlyOwner{
        require(tokens.length < 7 && !approvedTokens[tokenA], "No, no");
        setData(initailTokenA, initailPrimary);
        addToken(tokenA);
    }

    function unlockTime(uint256 id)public view returns(uint256){
        (,uint power, uint topPower,) = ihd.rank(id);
        uint256 time = unlock[id];
        if(time > delayTimer){
            return time - ((delayTimer * power)/(power)); //mainnet topPower+power for denomiator need little time on test net. 
        }else{
            return time;
        }
    }

    function addRouter(address router, string memory name)external onlyOwner{
        routers.push(router);
        exchange.push(name);
        routerCount++;
        emit RouterToggled(router, name, true);
    }

    function removeRouter(uint8 index)external onlyOwner{

        require(routerCount > index, "Error: Index out of bounds");
        address router = routers[index];
        string memory name = exchange[index];
        routers[index] = routers[routerCount-1];
        routers.pop();
        exchange[index] = exchange[routerCount - 1];
        exchange.pop();
        routerCount--;
        emit RouterToggled(router, name, false);

    }



    function uiHelper()external view returns(address[] memory, Data[] memory){
        uint256 l = tokens.length;
        Data[] memory d = new Data[](l);
        for(uint i = 0; i < l; i++){
            address a = tokens[i];
            d[i] = mintInformation[a];    

        }
        return (tokens,d);
    }
}