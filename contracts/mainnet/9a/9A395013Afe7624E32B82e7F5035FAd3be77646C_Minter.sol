// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

// Local
import { IAbNFT } from "./interfaces/IAbNFT.sol";
import { Configurable } from "./utils/Configurable.sol";

/**************************************

    Minter for AB NFT

 **************************************/

contract Minter is Ownable, Configurable {

    // using
    using Address for address payable;

    // enum
    enum RevealAction {
        FOLLOW, // pass unsold nfts to next batch
        CLAIM // mint not sold NFTs in batch to owner
    }
    enum BatchState {
        BLIND,
        REVEALED
    }

    // constants
    uint256 public constant TOTAL_SUPPLY_LIMIT = 6900;
    uint256 public constant INITIAL_MINT = 50;
    uint256 public constant MIN_BATCH_PRICE = 0.001 ether;

    // structs
    struct MintingBatch {
        uint256 mintingDate;
        uint256 mintingCap;
        uint256 mintingPrice;
        RevealAction actionWhenReveal;
        BatchState state;
    }

    // contracts
    IAbNFT public immutable nftContract;
    address public vesting;

    // storage
    uint256 public mintLimitPerWallet;
    uint256 public immutable totalBatches;
    MintingBatch[] public mintingBatches;
    mapping (address => uint256) public minted;

    // errors
    error MintingLimitReached(uint256 alreadyMinted, uint256 toMint, uint256 mintLimit);
    error MintingNotStarted(uint256 mintingBatch);
    error MintingAboveSupply(uint256 nftSupply, uint256 toMint, uint256 supplyLimit);
    error BatchLimitReached(uint256 totalBatches);
    error NotEnoughNFTAvailableToMint(uint256 toMint, uint256 available);
    error AlreadyInitialised();
    error InvalidPayment(address owner, uint256 value, uint256 numberToMint);
    error AlreadyRevealed(uint256 batchNo);
    error NotYetRevealed();
    error NothingToWithdraw();
    error MintingDateNotInFuture(uint256 mintingDate, uint256 timeNow);
    error InvalidMintingCap();
    error BatchNotStarted(uint256 batchNo);
    error InvalidPriceForBatch(uint256 price);

    // events
    event NewBatchAdded(MintingBatch batch);
    event RevealActionPerformed(uint256 batchNo, RevealAction action);
    event Withdrawal(address owner, uint256 amount);

    /**************************************
    
        Constructor

     **************************************/

    constructor(
        address _abNFT,
        address _vesting,
        uint256 _mintLimitPerWallet,
        uint256 _totalBatches,
        MintingBatch memory _firstBatch
    )
    Ownable() {
        
        // nft contract
        nftContract = IAbNFT(_abNFT);

        // vesting
        vesting = _vesting;

        // mint limit per wallet
        mintLimitPerWallet = _mintLimitPerWallet;

        // batch size
        totalBatches = _totalBatches;

        // batch
        mintingBatches.push(_firstBatch);

        // event
        emit Initialised(abi.encode(
            _abNFT,
            _vesting,
            _mintLimitPerWallet,
            _totalBatches,
            _firstBatch
        ));

    }

    /**************************************

        Set as configured

     **************************************/

    function setConfigured() public virtual override
    onlyInState(State.UNCONFIGURED)
    onlyOwner {

        // tx.members
        address owner_ = msg.sender;

        // batch mint
        nftContract.mint(_prepMint(INITIAL_MINT), owner_);

        // super
        super.setConfigured();

        // event
        emit Configured(abi.encode(
            msg.sender,
            INITIAL_MINT
        ));

    }

    /**************************************

        Add new batch

     **************************************/

    function addNewBatch(MintingBatch calldata _batch) external
    onlyOwner {

        // tx.members
        uint256 now_ = block.timestamp;

        // check if under limit
        if (mintingBatches.length + 1 > totalBatches) {
            revert BatchLimitReached(totalBatches);
        }

        // check if date in future
        if (_batch.mintingDate <= now_) {
            revert MintingDateNotInFuture(_batch.mintingDate, now_);
        }

        // check minting size
        if (_batch.mintingCap == 0) {
            revert InvalidMintingCap();
        }

        // check minting price
        if (_batch.mintingPrice < MIN_BATCH_PRICE) {
            revert InvalidPriceForBatch(_batch.mintingPrice);
        }

        // storage
        mintingBatches.push(_batch);

        // event
        emit NewBatchAdded(_batch);

    }

    /**************************************

        Get batch count

     **************************************/

    function getActiveBatchCount() external view
    returns (uint256) {

        // return
        return mintingBatches.length;

    }

    /**************************************

        Get latest batch

     **************************************/

    function getLatestBatch() public view
    returns (int256) {

        // tx.members
        uint256 now_ = block.timestamp;

        // loop through batches from end
        for (uint256 i = mintingBatches.length; i > 0; i--) {

            // return if already started
            if (now_ >= mintingBatches[i - 1].mintingDate) return int256(i - 1);

        }

        // no active batch yet
        return -1;

    }

    /**************************************

        Get latest active batch

     **************************************/

    function getLatestActiveBatch() public view
    returns (uint256) {

        // get latest batch
        int256 batchNo_ = getLatestBatch();

        // check latest batch number
        if (batchNo_ < 0) revert MintingNotStarted(0);

        // return
        return uint256(batchNo_);

    }

    /**************************************
    
        Get time left to next batch

     **************************************/

    function getTimeLeft() external view
    returns (uint256) {

        // tx.members
        uint256 now_ = block.timestamp;

        // length
        uint256 length_ = mintingBatches.length;

        // loop through batches
        for (uint256 i = 0; i < length_; i++) {

            // batch from start
            MintingBatch memory batch_ = mintingBatches[i];
            if (batch_.mintingDate > now_) return batch_.mintingDate - now_;

        }

        // return
        return 0;

    }

    /**************************************

        Get tokens left in current batch

     **************************************/

    function getTokensLeftInLatestBatch() public view
    returns (uint256) {

        // batch number
        int256 batchNo_ = getLatestBatch();

        // check batch number
        if (batchNo_ >= 0) {

            return getTokensLeftInBatch(uint256(batchNo_));

        }

        // return
        return 0;

    }

    /**************************************

        Get tokens left in specified batch

     **************************************/

    function getTokensLeftInBatch(uint256 _batchNo) public view
    returns (uint256) {

        // batch
        MintingBatch memory batch_ = mintingBatches[_batchNo];

        // supply
        uint256 currentSupply_ = nftContract.totalSupply();

        // return tokens left
        if (currentSupply_ >= batch_.mintingCap) return 0;
        else return batch_.mintingCap - currentSupply_;

    }

    /**************************************

        Get tokens left to mint

     **************************************/

    function getTokensLeft() external view
    returns (uint256) {

        // return
        return TOTAL_SUPPLY_LIMIT - nftContract.totalSupply();

    }

    /**************************************
    
        Mint new NFT

     **************************************/

    function mint(uint256 _numberToMint) external payable
    onlyInState(State.CONFIGURED) {

        // tx.members
        address owner_ = msg.sender;

        // assert
        _assertMint(_numberToMint);

        // storage
        minted[owner_] += _numberToMint;

        // mint
        nftContract.mint(_prepMint(_numberToMint), owner_);

    }

    /**************************************

        Internal: assert for public mint

     **************************************/

    function _assertMint(uint256 _numberToMint) internal view {

        // tx.members
        address owner_ = msg.sender;
        uint256 value_ = msg.value;

        // get latest batch
        uint256 batchNo_ = getLatestActiveBatch();
        
        // batch
        MintingBatch memory batch_ = mintingBatches[batchNo_];

        // check if batch not revealed
        if (batch_.state == BatchState.REVEALED) {
            revert AlreadyRevealed(batchNo_);
        }

        // check if tokens can be minted
        uint256 availableToMint_ = getTokensLeftInBatch(batchNo_);
        if (_numberToMint > availableToMint_) {
            revert NotEnoughNFTAvailableToMint(
                _numberToMint,
                availableToMint_
            );
        }

        // check funds
        if (value_ != _numberToMint * batch_.mintingPrice) {
            revert InvalidPayment(
                owner_,
                value_,
                _numberToMint
            );
        }

        // check nft supply
        uint256 nftSupply_ = nftContract.totalSupply();
        if (nftSupply_ + _numberToMint > TOTAL_SUPPLY_LIMIT) {
            revert MintingAboveSupply(
                nftSupply_,
                _numberToMint,
                TOTAL_SUPPLY_LIMIT
            );
        }

        // check limit for minting
        if (minted[owner_] + _numberToMint > mintLimitPerWallet) {
            revert MintingLimitReached(
                minted[owner_],
                _numberToMint,
                mintLimitPerWallet
            );
        }

    }

    /**************************************

        Internal: prep mint

     **************************************/

    function _prepMint(uint256 _numberToMint) internal view returns (uint256[] memory) {

        // alloc
        uint256[] memory toBeMinted_ = new uint256[](_numberToMint);

        // supply
        uint256 totalSupply_ = nftContract.totalSupply();

        // populate
        for (uint256 i = 0; i < _numberToMint; i++) {
            toBeMinted_[i] = totalSupply_ + i;
        }

        // return
        return toBeMinted_;

    }

    /**************************************

        Reveal

     **************************************/

    function reveal(
        uint256 _batchNo,
        string memory _revealedURI
    ) external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // get latest batch
        uint256 batchNo_ = getLatestActiveBatch();

        // check if batch started
        if (batchNo_ < _batchNo) revert BatchNotStarted(_batchNo);

        // batch
        MintingBatch storage batch_ = mintingBatches[_batchNo];

        // check if not revealed
        if (batch_.state == BatchState.REVEALED) {
            revert AlreadyRevealed(_batchNo);
        }

        // claim
        uint256 toVest_ = 0;

        // check if there are tokens in batch
        uint256 tokensLeft_ = getTokensLeftInBatch(_batchNo);

        // check if there are remaining NFTs
        if (tokensLeft_ > 0) {

            // decrease available tokens for mint
            batch_.mintingCap -= tokensLeft_;

            // check action on reveal
            if (batch_.actionWhenReveal == RevealAction.CLAIM) {

                // move tokens to vesting
                toVest_ += tokensLeft_;

            }

        }

        // storage
        batch_.state = BatchState.REVEALED;

        // fallback to total supply if latest batch
        uint256 cap_ = batch_.mintingCap;
        if (_batchNo == totalBatches - 1) {
            cap_ = TOTAL_SUPPLY_LIMIT;
        }

        // reveal
        nftContract.reveal(
            cap_,
            _revealedURI,
            toVest_
        );

        // event
        emit RevealActionPerformed(
            batchNo_,
            batch_.actionWhenReveal
        );

    }

    /**************************************

        Vested claim NFT

     **************************************/

    function vestedClaim(uint256 _numberToMint) external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // claim
        nftContract.vestedClaim(_prepMint(_numberToMint), vesting);

    }

    /**************************************

        Withdraw

     **************************************/

    function withdraw() external
    onlyInState(State.CONFIGURED)
    onlyOwner {

        // tx.members
        address sender_ = msg.sender;
        uint256 balance_ = address(this).balance;

        // check balance
        if (balance_ == 0) {
            revert NothingToWithdraw();
        }

        // withdraw
        payable(sender_).sendValue(balance_);

        // event
        emit Withdrawal(sender_, balance_);

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
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

// OpenZeppelin
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**************************************

    Minter interface

 **************************************/

interface IAbNFT is IERC721Enumerable {

    // external functions
    function mint(uint256[] calldata _nftIds, address _owner) external;
    function reveal(uint256 _range, string memory _revealedURI, uint256 _toClaim) external;
    function vestedClaim(uint256[] calldata _nftIds, address _owner) external;

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

/**************************************

    security-contact:
    - [email protected]
    - [email protected]
    - [email protected]

**************************************/

/**************************************

    Configurable

    ------------

    Base contract that should be inherited
    and setConfigured function should be overridden

 **************************************/

abstract contract Configurable {

    // enum
    enum State {
        UNCONFIGURED,
        CONFIGURED
    }

    // storage
    State public state; // default -> State.UNCONFIGURED;

    // events
    event Initialised(bytes);
    event Configured(bytes);

    // errors
    error InvalidState(State current, State expected);

    // modifier
    modifier onlyInState(State _state) {

        // check state
        if (state != _state) revert InvalidState(state, _state);
        _;

    }

    /**************************************

        Configuration

        -------------

        Should be overridden with
        proper access control

     **************************************/

    function setConfigured() public virtual
    onlyInState(State.UNCONFIGURED) {

        // set as configured
        state = State.CONFIGURED;

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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