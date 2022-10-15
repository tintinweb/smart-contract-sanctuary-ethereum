// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// LIBRARIES
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Address.sol";
// INTERFACES
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// ABSTRACT CONTRACTS
import "@openzeppelin/contracts/utils/Context.sol";
import "solmate/src/tokens/ERC1155.sol";
import "solmate/src/auth/Owned.sol";

/// @title Token contract implementing ERC1155.
/// @author Ahmed Ali <github.com/ahmedali8>
contract Token is Context, Owned, ERC1155 {
    using Counters for Counters.Counter;

    /*//////////////////////////////////////////////////////////////
                                VARIABLES
    //////////////////////////////////////////////////////////////*/

    Counters.Counter private _tokenIdTracker;

    enum NFTType {
        ERC721,
        ERC1155
    }

    struct Own {
        NFTType nftType;
        address nftAddress;
        uint256 tokenId;
        uint256 amount;
    }

    struct Burn {
        uint256 tokenId;
        uint256 amount;
    }

    struct InitializeTokenIdParams {
        uint32 startTime;
        uint32 endTime; // 0 means it's unlimited
        uint256 price; // 0 means it's free
        uint256 maxSupply; // 0 means it's unlimited
        uint256 amountPerAccount; // 0 means it's unlimited mints per account
        string metadata;
        Burn[] burnInfos;
        Own[] ownInfos;
    }

    struct TokenInfo {
        bool exists;
        bool isBurningRequired;
        bool isOwningRequired;
        uint32 startTime;
        uint32 endTime; // endTime 0 means it's unlimited
        uint256 price; // price 0 means it's free
        uint256 totalSupply;
        uint256 maxSupply; // maxSupply 0 means it's unlimited
        uint256 amountPerAccount; // amountPerAccount 0 means it's unlimited mints per account
        string metadata;
        Burn[] burnInfos;
        Own[] ownInfos;
    }

    /// @dev Mapping to track TokenInfo of each tokenId.
    /// id -> TokenInfo
    mapping(uint256 => TokenInfo) private p_tokenInfo;
    // solhint-disable-previous-line var-name-mixedcase

    /// @dev Mapping to track burn balance of each account's tokenId.
    /// address -> id -> amountBurned
    mapping(address => mapping(uint256 => uint256)) private p_burnBalanceOf;
    // solhint-disable-previous-line var-name-mixedcase

    /// @dev Split contract address or any valid address to receive ethers.
    address public split;

    /*//////////////////////////////////////////////////////////////
                                EVENTS
    //////////////////////////////////////////////////////////////*/

    event TokenInitialized(uint256 tokenId, InitializeTokenIdParams initializeTokenIdParams);
    event NFTMinted(uint256 tokenId, uint256 amount, address beneficiary);
    event NFTBurned(uint256 tokenId, address beneficiary, uint256 amount);
    event NFTBatchMinted(uint256[] tokenIds, uint256[] amounts, address beneficiary);
    event NFTBatchBurned(address beneficiary, uint256[] tokenIds, uint256[] amounts);
    event SetSplit(address prevSplit, address newSplit);

    /*//////////////////////////////////////////////////////////////
                                CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    /// @dev Sets `owner_` as {owner} of contract and `split_` as {split}.
    ///
    /// @param _owner addres - address of owner for contract.
    /// @param _split addres - address of split contract or any valid address.
    ///
    /// Note - `_split` address must be valid as it will receive all ethers of this contract.
    constructor(address _owner, address _split) Owned(_owner) ERC1155() {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_split != address(0), "ZERO_ADDRESS");
        split = _split;
    }

    /*//////////////////////////////////////////////////////////////
                        NON-VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Mint a new NFT of a tokenId.
    ///
    /// @dev Add checks and inherits _mint of ERC1155 to mint new NFT of tokenId to caller.
    ///
    /// @param _id tokenId.
    /// @param _amount amount of tokenId.
    function mint(uint256 _id, uint256 _amount) external payable {
        uint256 _value = msg.value;

        require(tokenExists(_id), "INVALID_TOKENID");
        require(_value == tokenPrice(_id, _amount), "INVALID_PRICE");

        _supplyValidator(_id);
        _tokenAmountPerAccountValidator(_id, _amount);
        _timeValidator(_id);
        _ownValidator(_id);
        _burnValidator(_id);

        p_tokenInfo[_id].totalSupply += _amount;

        emit NFTMinted(_id, _amount, _msgSender());

        _mint(_msgSender(), _id, _amount, "");

        if (_value != 0) {
            Address.sendValue(payable(split), _value);
        }
    }

    /// @notice Batch mint new NFTs of tokenIds.
    ///
    /// @dev Add checks and inherits _batchMint of ERC1155 to mint new NFTs of tokenIds to caller.
    ///
    /// @param _ids tokenIds.
    /// @param _amounts amounts of tokenIds.
    function batchMint(uint256[] memory _ids, uint256[] memory _amounts) external payable {
        uint256 idsLength = _ids.length; // Saves MLOADs.
        uint256 amountsLength = _amounts.length; // Saves MLOADs.

        require(idsLength != 0 && idsLength == amountsLength, "LENGTH_MISMATCH");

        uint256 _value = msg.value;
        uint256 _totalPrice;

        uint256 _id;
        uint256 _amount;
        for (uint256 i; i < idsLength; ) {
            _id = _ids[i];
            _amount = _amounts[i];

            require(tokenExists(_id), "INVALID_TOKENID");

            _supplyValidator(_id);
            _tokenAmountPerAccountValidator(_id, _amount);
            _timeValidator(_id);
            _ownValidator(_id);
            _burnValidator(_id);

            _totalPrice += tokenPrice(_id, _amount);
            p_tokenInfo[_id].totalSupply += _amount;

            unchecked {
                ++i;
            }
        }

        require(_value == _totalPrice, "INVALID_PRICE");
        emit NFTBatchMinted(_ids, _amounts, _msgSender());

        _batchMint(_msgSender(), _ids, _amounts, "");

        if (_value != 0) {
            Address.sendValue(payable(split), _value);
        }
    }

    /// @notice Set new split contract address or any valid address to receive ethers.
    ///
    /// @param _split address - valid address to receive ethers.
    function setSplit(address _split) external onlyOwner {
        require(_split != address(0), "ZERO_ADDRESS");
        emit SetSplit(split, _split);
        split = _split;
    }

    /// @notice Owner creates new tokenId to sell NFT. If metadata is of ipfs then pattern should be "ipfs://{hash}".
    ///
    /// @dev Updates p_tokenInfo struct mapping and increments tokenId each time.
    ///
    /// @param _params InitializeTokenIdParams -
    /// _params.startTime        uint32   - startTime.
    /// _params.endTime          uint32   - endTime, 0 means it's unlimited.
    /// _params.price            uint256  - price, 0 means it's free.
    /// _params.maxSupply        uint256  - maxSupply, 0 means it's unlimited.
    /// _params.amountPerAccount uint256  - amountPerAccount, 0 means it's unlimited mints per account.
    /// _params.metadata         string   - metadata.
    /// _params.burnInfos        Burn[]   - burnInfos.
    /// _params.ownInfos         Own[]    - ownInfos.
    function initializeTokenId(InitializeTokenIdParams calldata _params) external onlyOwner {
        require(_params.startTime >= uint32(block.timestamp), "INVALID_START_TIME");
        require(bytes(_params.metadata).length > 0, "INVALID_URI");

        // incrementing tokenId
        _tokenIdTracker.increment();
        uint256 _id = _tokenIdTracker.current();

        emit TokenInitialized(_id, _params);

        p_tokenInfo[_id].exists = true;
        p_tokenInfo[_id].startTime = _params.startTime;
        p_tokenInfo[_id].metadata = _params.metadata;

        // endTime is 0 it means it's unlimited
        p_tokenInfo[_id].endTime = _params.endTime;
        // the price is 0 then means it's free
        p_tokenInfo[_id].price = _params.price;
        // maxSupply is 0 it means it's unlimited
        p_tokenInfo[_id].maxSupply = _params.maxSupply;
        // amountPerAccount is 0 it means it's unlimited mints per account
        p_tokenInfo[_id].amountPerAccount = _params.amountPerAccount;

        if (_params.burnInfos.length != 0) {
            p_tokenInfo[_id].isBurningRequired = true;

            for (uint256 i; i < _params.burnInfos.length; ) {
                p_tokenInfo[_id].burnInfos.push(_params.burnInfos[i]);

                unchecked {
                    ++i;
                }
            }
        }

        if (_params.ownInfos.length != 0) {
            p_tokenInfo[_id].isOwningRequired = true;

            for (uint256 i; i < _params.ownInfos.length; ) {
                p_tokenInfo[_id].ownInfos.push(_params.ownInfos[i]);

                unchecked {
                    ++i;
                }
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW/PURE FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @notice Getter for tokenId exists.
    ///
    /// @dev Get exists flag from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId
    /// @return tokenId exists or not
    function tokenExists(uint256 _id) public view returns (bool) {
        return p_tokenInfo[_id].exists;
    }

    /// @notice Getter for price of a tokenId.
    ///
    /// @dev Gets price from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    /// @return price of tokenId.
    function tokenPrice(uint256 _id, uint256 _amount) public view returns (uint256) {
        require(_amount != 0, "INVALID_AMOUNT");
        return p_tokenInfo[_id].price * _amount;
    }

    /// @notice Getter for uri metadata of a tokenId.
    ///
    /// @dev Gets uri from p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    /// @return uri of a tokenId.
    function uri(uint256 _id) public view virtual override returns (string memory) {
        require(tokenExists(_id), "INVALID_TOKENID");
        return p_tokenInfo[_id].metadata;
    }

    /// @notice Getter for the amount of tokens burned of token type `_id` owned by `_owner`.
    ///
    /// @param _owner address.
    /// @param _id tokenId.
    /// @return balance of `_owner`.
    function burnBalanceOf(address _owner, uint256 _id) external view returns (uint256 balance) {
        return p_burnBalanceOf[_owner][_id];
    }

    /// @notice Getter for the amounts of tokens burned of token type `ids` owned by `owners`.
    ///
    /// @param owners addresses.
    /// @param ids tokenIds.
    /// @return balances of `owners`.
    function burnBalanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i; i < owners.length; ++i) {
                balances[i] = p_burnBalanceOf[owners[i]][ids[i]];
            }
        }
    }

    /// @notice Getter for the tokenInfo of token type `_id`.
    ///
    /// @dev Gets the p_tokenInfo struct mapping.
    ///
    /// @param _id tokenId.
    function tokenInfo(uint256 _id)
        external
        view
        returns (
            bool exists,
            bool isBurningRequired,
            bool isOwningRequired,
            uint32 startTime,
            uint32 endTime,
            uint256 price,
            uint256 totalSupply,
            uint256 maxSupply,
            uint256 amountPerAccount,
            string memory metadata,
            Burn[] memory burnInfos,
            Own[] memory ownInfos
        )
    {
        TokenInfo memory _ti = p_tokenInfo[_id];

        exists = _ti.exists;
        isBurningRequired = _ti.isBurningRequired;
        isOwningRequired = _ti.isOwningRequired;
        startTime = _ti.startTime;
        endTime = _ti.endTime;
        price = _ti.price;
        totalSupply = _ti.totalSupply;
        maxSupply = _ti.maxSupply;
        amountPerAccount = _ti.amountPerAccount;
        metadata = _ti.metadata;
        burnInfos = _ti.burnInfos;
        ownInfos = _ti.ownInfos;
    }

    /// @notice returns total number of tokenIds in the token contract.
    ///
    /// @dev gets current number of tokenids from _tokenidTracker Counter library.
    ///
    /// @return number of tokenIds.
    function totalTokenIds() external view returns (uint256) {
        return _tokenIdTracker.current();
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Validates that totalSupply does not exceed maxSupply of a tokenId.
    ///
    /// @param _id tokenId.
    function _supplyValidator(uint256 _id) internal view {
        TokenInfo memory _t = p_tokenInfo[_id];
        if (_t.maxSupply > 0) {
            require(_t.totalSupply + 1 <= _t.maxSupply, "MAXSUPPLY_REACHED");
        }
    }

    /// @dev Validates that time is within start and/or end.
    ///
    /// @param _id tokenId.
    function _timeValidator(uint256 _id) internal view {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        require(uint32(block.timestamp) >= _tokenInfo.startTime, "MINTING_NOT_STARTED");

        // if end time is not zero it means it's limited time minting
        if (_tokenInfo.endTime != 0) {
            require(uint32(block.timestamp) < _tokenInfo.endTime, "MINTING_ENDED");
        }
    }

    /// @dev Validates that amount is less than tokenAmountPerAccount.
    ///
    /// @param _id tokenId.
    /// @param _amount amount of tokenId.
    function _tokenAmountPerAccountValidator(uint256 _id, uint256 _amount) internal view {
        uint256 _tokenAmountPerAccount = p_tokenInfo[_id].amountPerAccount;
        if (_tokenAmountPerAccount != 0) {
            require(
                _amount <= _tokenAmountPerAccount &&
                    balanceOf[_msgSender()][_id] < _tokenAmountPerAccount,
                "AMOUNT_PER_ACCOUNT_EXCEED"
            );
        }
    }

    /// @dev Validates that own info.
    ///
    /// @param _id tokenId.
    function _ownValidator(uint256 _id) internal view {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        // if owning is required
        if (_tokenInfo.isOwningRequired) {
            uint256 len = _tokenInfo.ownInfos.length;

            for (uint256 i; i < len; ) {
                if (_tokenInfo.ownInfos[i].nftType == NFTType.ERC721) {
                    // if ERC721, tokenId would not be used.
                    require(
                        IERC721(_tokenInfo.ownInfos[i].nftAddress).balanceOf(_msgSender()) >=
                            _tokenInfo.ownInfos[i].amount,
                        "INELIGIBLE"
                    );
                } else {
                    // if ERC1155
                    require(
                        IERC1155(_tokenInfo.ownInfos[i].nftAddress).balanceOf(
                            _msgSender(),
                            _tokenInfo.ownInfos[i].tokenId
                        ) >= _tokenInfo.ownInfos[i].amount,
                        "INELIGIBLE"
                    );
                }

                unchecked {
                    ++i;
                }
            }
        }
    }

    /// @dev Validates that burn info.
    ///
    /// @param _id tokenId.
    ///
    // Note - if burning is required then user must give approval to this contract to allow to burn their token
    function _burnValidator(uint256 _id) internal {
        TokenInfo memory _tokenInfo = p_tokenInfo[_id];

        // if burning is required
        if (_tokenInfo.isBurningRequired) {
            require(isApprovedForAll[_msgSender()][address(this)], "NOT_AUTHORIZED");

            uint256 len = _tokenInfo.burnInfos.length;

            if (len == 1) {
                // if length is 1
                // we use burn
                Burn memory _burnInfo = _tokenInfo.burnInfos[0];
                _burnToken(_burnInfo.tokenId, _burnInfo.amount);
            } else {
                // if length is more than 1
                // we use burn batch
                uint256[] memory _ids = new uint256[](len);
                uint256[] memory _amounts = new uint256[](len);

                for (uint256 i; i < len; ) {
                    _ids[i] = _tokenInfo.burnInfos[i].tokenId;
                    _amounts[i] = _tokenInfo.burnInfos[i].amount;

                    unchecked {
                        ++i;
                    }
                }

                _batchBurnToken(_ids, _amounts);
            }
        }
    }

    /// @dev Burn a single token.
    ///
    /// @param _id tokenId.
    /// @param _amount amount.
    function _burnToken(uint256 _id, uint256 _amount) internal {
        require(tokenExists(_id), "INVALID_TOKENID");

        // update state
        p_burnBalanceOf[_msgSender()][_id] += _amount;

        p_tokenInfo[_id].totalSupply -= _amount;
        // should maxSupply be reduced?

        emit NFTBurned(_id, _msgSender(), _amount);


        _burn(_msgSender(), _id, _amount);
    }

    /// @dev Burn multiple tokens.
    ///
    /// @param _ids tokenIds.
    /// @param _amounts amounts.
    function _batchBurnToken(uint256[] memory _ids, uint256[] memory _amounts) internal {
        uint256 idsLength = _ids.length;

        uint256 _id;
        uint256 _amount;
        for (uint256 i; i < idsLength; ) {
            _id = _ids[i];
            _amount = _amounts[i];

            require(tokenExists(_id), "INVALID_TOKENID");

            // update state
            p_burnBalanceOf[_msgSender()][_id] += _amount;
            p_tokenInfo[_id].totalSupply -= _amount;




            unchecked {
                ++i;
            }
        }

        emit NFTBatchBurned(_msgSender(), _ids, _amounts);

        _batchBurn(_msgSender(), _ids, _amounts);
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
library Counters {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Minimalist and gas efficient standard ERC1155 implementation.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event TransferSingle(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256 id,
        uint256 amount
    );

    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] amounts
    );

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    event URI(string value, uint256 indexed id);

    /*//////////////////////////////////////////////////////////////
                             ERC1155 STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address => mapping(uint256 => uint256)) public balanceOf;

    mapping(address => mapping(address => bool)) public isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                             METADATA LOGIC
    //////////////////////////////////////////////////////////////*/

    function uri(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                              ERC1155 LOGIC
    //////////////////////////////////////////////////////////////*/

    function setApprovalForAll(address operator, bool approved) public virtual {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) public virtual {
        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        balanceOf[from][id] -= amount;
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, from, to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) public virtual {
        require(ids.length == amounts.length, "LENGTH_MISMATCH");

        require(msg.sender == from || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED");

        // Storing these outside the loop saves ~15 gas per iteration.
        uint256 id;
        uint256 amount;

        for (uint256 i = 0; i < ids.length; ) {
            id = ids[i];
            amount = amounts[i];

            balanceOf[from][id] -= amount;
            balanceOf[to][id] += amount;

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids)
        public
        view
        virtual
        returns (uint256[] memory balances)
    {
        require(owners.length == ids.length, "LENGTH_MISMATCH");

        balances = new uint256[](owners.length);

        // Unchecked because the only math done is incrementing
        // the array index counter which cannot possibly overflow.
        unchecked {
            for (uint256 i = 0; i < owners.length; ++i) {
                balances[i] = balanceOf[owners[i]][ids[i]];
            }
        }
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0xd9b67a26 || // ERC165 Interface ID for ERC1155
            interfaceId == 0x0e89341c; // ERC165 Interface ID for ERC1155MetadataURI
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        balanceOf[to][id] += amount;

        emit TransferSingle(msg.sender, address(0), to, id, amount);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155Received(msg.sender, address(0), id, amount, data) ==
                    ERC1155TokenReceiver.onERC1155Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchMint(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[to][ids[i]] += amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, address(0), to, ids, amounts);

        require(
            to.code.length == 0
                ? to != address(0)
                : ERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, address(0), ids, amounts, data) ==
                    ERC1155TokenReceiver.onERC1155BatchReceived.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _batchBurn(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        uint256 idsLength = ids.length; // Saves MLOADs.

        require(idsLength == amounts.length, "LENGTH_MISMATCH");

        for (uint256 i = 0; i < idsLength; ) {
            balanceOf[from][ids[i]] -= amounts[i];

            // An array can't have a total length
            // larger than the max uint256 value.
            unchecked {
                ++i;
            }
        }

        emit TransferBatch(msg.sender, from, address(0), ids, amounts);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        balanceOf[from][id] -= amount;

        emit TransferSingle(msg.sender, from, address(0), id, amount);
    }
}

/// @notice A generic interface for a contract which properly accepts ERC1155 tokens.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/tokens/ERC1155.sol)
abstract contract ERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnerUpdated(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnerUpdated(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function setOwner(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnerUpdated(msg.sender, newOwner);
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