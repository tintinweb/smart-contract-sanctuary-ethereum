/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// Sources flattened with hardhat v2.9.0 https://hardhat.org

    // File @openzeppelin/contracts/utils/[email protected]

    // SPDX-License-Identifier: MIT
    // OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Provides a set of functions to operate with Base64 strings.
    *
    * _Available since v4.5._
    */
    library Base64 {
        /**
        * @dev Base64 Encoding/Decoding Table
        */
        string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        /**
        * @dev Converts a `bytes` to its Bytes64 `string` representation.
        */
        function encode(bytes memory data) internal pure returns (string memory) {
            /**
            * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
            * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
            */
            if (data.length == 0) return "";

            // Loads the table into memory
            string memory table = _TABLE;

            // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
            // and split into 4 numbers of 6 bits.
            // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
            // - `data.length + 2`  -> Round up
            // - `/ 3`              -> Number of 3-bytes chunks
            // - `4 *`              -> 4 characters for each chunk
            string memory result = new string(4 * ((data.length + 2) / 3));

            assembly {
                // Prepare the lookup table (skip the first "length" byte)
                let tablePtr := add(table, 1)

                // Prepare result pointer, jump over length
                let resultPtr := add(result, 32)

                // Run over the input, 3 bytes at a time
                for {
                    let dataPtr := data
                    let endPtr := add(data, mload(data))
                } lt(dataPtr, endPtr) {

                } {
                    // Advance 3 bytes
                    dataPtr := add(dataPtr, 3)
                    let input := mload(dataPtr)

                    // To write each character, shift the 3 bytes (18 bits) chunk
                    // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                    // and apply logical AND with 0x3F which is the number of
                    // the previous character in the ASCII table prior to the Base64 Table
                    // The result is then added to the table to get the character to write,
                    // and finally write it in the result pointer but with a left shift
                    // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                    mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                    resultPtr := add(resultPtr, 1) // Advance

                    mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                    resultPtr := add(resultPtr, 1) // Advance

                    mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                    resultPtr := add(resultPtr, 1) // Advance

                    mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                    resultPtr := add(resultPtr, 1) // Advance
                }

                // When data `bytes` is not exactly 3 bytes long
                // it is padded with `=` characters at the end
                switch mod(mload(data), 3)
                case 1 {
                    mstore8(sub(resultPtr, 1), 0x3d)
                    mstore8(sub(resultPtr, 2), 0x3d)
                }
                case 2 {
                    mstore8(sub(resultPtr, 1), 0x3d)
                }
            }

            return result;
        }
    }

    // File @openzeppelin/contracts/utils/introspection/[email protected]

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

    // File @openzeppelin/contracts/token/ERC721/[email protected]

    // OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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

    // File @openzeppelin/contracts/token/ERC721/[email protected]

    // OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

    pragma solidity ^0.8.0;

    /**
    * @title ERC721 token receiver interface
    * @dev Interface for any contract that wants to support safeTransfers
    * from ERC721 asset contracts.
    */
    interface IERC721Receiver {
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

    // File @openzeppelin/contracts/token/ERC20/[email protected]

    // OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

    pragma solidity ^0.8.0;

    /**
    * @dev Interface of the ERC20 standard as defined in the EIP.
    */
    interface IERC20 {
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

    // File @openzeppelin/contracts/token/ERC721/extensions/[email protected]

    // OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

    pragma solidity ^0.8.0;

    /**
    * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
    * @dev See https://eips.ethereum.org/EIPS/eip-721
    */
    interface IERC721Metadata is IERC721 {
        /**
        * @dev Returns the token collection name.
        */
        function name() external view returns (string memory);

        /**
        * @dev Returns the token collection symbol.
        */
        function symbol() external view returns (string memory);

        /**
        * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
        */
        function tokenURI(uint256 tokenId) external view returns (string memory);
    }

    // File @openzeppelin/contracts/security/[email protected]

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

    // File @openzeppelin/contracts/utils/[email protected]

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

    // File @openzeppelin/contracts/access/[email protected]

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

    // File contracts/interface/ICheckPermission.sol

    pragma solidity =0.8.10;

    interface ICheckPermission {
        function operator() external view returns (address);

        function owner() external view returns (address);

        function check(address _target) external view returns (bool);
    }

    // File contracts/tools/Operatable.sol

    pragma solidity =0.8.10;

    // seperate owner and operator, operator is for daily devops, only owner can update operator
    contract Operatable is Ownable {
        event SetOperator(address indexed oldOperator, address indexed newOperator);

        address public operator;

        mapping(address => bool) public contractWhiteList;

        constructor() {
            operator = msg.sender;
            emit SetOperator(address(0), operator);
        }

        modifier onlyOperator() {
            require(msg.sender == operator, "not operator");
            _;
        }

        function setOperator(address newOperator) public onlyOwner {
            require(newOperator != address(0), "bad new operator");
            address oldOperator = operator;
            operator = newOperator;
            emit SetOperator(oldOperator, newOperator);
        }

        // File: @openzeppelin/contracts/utils/Address.sol
        function isContract(address account) public view returns (bool) {
            // This method relies in extcodesize, which returns 0 for contracts in
            // construction, since the code is only stored at the end of the
            // constructor execution.

            // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
            // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
            // for accounts without code, i.e. `keccak256('')`
            bytes32 codehash;
            bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
            // solhint-disable-next-line no-inline-assembly
            assembly {
                codehash := extcodehash(account)
            }
            return (codehash != 0x0 && codehash != accountHash);
        }

        function addContract(address _target) public onlyOperator {
            contractWhiteList[_target] = true;
        }

        function removeContract(address _target) public onlyOperator {
            contractWhiteList[_target] = false;
        }

        //Do not ban access to the user, need to be in the whitelist contract address to be able to access
        function check(address _target) public view returns (bool) {
            if (isContract(_target)) {
                return contractWhiteList[_target];
            }
            return true;
        }
    }

    // File contracts/tools/CheckPermission.sol

    pragma solidity =0.8.10;

    // seperate owner and operator, operator is for daily devops, only owner can update operator
    contract CheckPermission is ICheckPermission {
        Operatable public operatable;

        event SetOperatorContract(address indexed oldOperator, address indexed newOperator);

        constructor(address _oper) {
            operatable = Operatable(_oper);
            emit SetOperatorContract(address(0), _oper);
        }

        modifier onlyOwner() {
            require(operatable.owner() == msg.sender, "Ownable: caller is not the owner");
            _;
        }

        modifier onlyOperator() {
            require(operatable.operator() == msg.sender, "not operator");
            _;
        }

        modifier onlyAEOWhiteList() {
            require(check(msg.sender), "aeo or whitelist");
            _;
        }

        function operator() public view override returns (address) {
            return operatable.operator();
        }

        function owner() public view override returns (address) {
            return operatable.owner();
        }

        function setOperContract(address _oper) public onlyOwner {
            require(_oper != address(0), "bad new operator");
            address oldOperator = address(operatable);
            operatable = Operatable(_oper);
            emit SetOperatorContract(oldOperator, _oper);
        }

        function check(address _target) public view override returns (bool) {
            return operatable.check(_target);
        }
    }

    // File contracts/dao/Locker.sol

    pragma solidity 0.8.10;

    //@title Voting Escrow
    //@author Curve Finance
    //@license MIT
    //@notice Votes have a weight depending on time, so that users are
    //committed to the future of (whatever they are voting for)
    //@dev Vote weight decays linearly over time. Lock time cannot be
    //more than `MAXTIME` (4 years).
    //
    //# Voting escrow to have time-weighted votes
    //# Votes have a weight depending on time, so that users are committed
    //# to the future of (whatever they are voting for).
    //# The weight in this implementation is linear, and lock cannot be more than maxtime:
    //# w ^
    //# 1 +        /
    //#   |      /
    //#   |    /
    //#   |  /
    //#   |/
    //# 0 +--------+------> time
    //#       maxtime (4 years?)

    contract Locker is IERC721, IERC721Metadata, ReentrancyGuard, CheckPermission {
        event Withdraw(address indexed provider, uint256 tokenId, uint256 value, uint256 ts);
        event Supply(uint256 prevSupply, uint256 supply);
        event BoostAdded(address _address);
        event BoostRemoved(address _address);

        struct Point {
            int128 bias;
            int128 slope; // # -dweight / dt
            uint256 ts;
            uint256 blk; // block
        }

        struct LockedBalance {
            int128 amount;
            uint256 end;
        }
        enum DepositType {
            DEPOSIT_FOR_TYPE,
            CREATE_LOCK_TYPE,
            INCREASE_LOCK_AMOUNT,
            INCREASE_UNLOCK_TIME,
            MERGE_TYPE
        }
        event Deposit(
            address indexed provider,
            uint256 tokenId,
            uint256 value,
            uint256 indexed locktime,
            DepositType depositType,
            uint256 ts
        );

        uint256 public constant MAXTIME = 4 * 365 * 86400;
        int128 public constant I_MAXTIME = 4 * 365 * 86400;
        uint256 public constant MULTIPLIER = 1 ether;

        uint256 public immutable duration;
        address public immutable token;

        uint256 public supply;
        mapping(uint256 => LockedBalance) public locked;

        mapping(uint256 => uint256) public ownershipChange;

        uint256 public epoch;
        mapping(uint256 => Point) public pointHistory; // epoch -> unsigned point
        mapping(uint256 => Point[1000000000]) public userPointHistory; // user -> Point[user_epoch]

        mapping(uint256 => uint256) public userPointEpoch;
        mapping(uint256 => int128) public slopeChanges; // time -> signed slope change

        mapping(uint256 => bool) public voted;
        mapping(address => bool) public boosts;

        /* solhint-disable */
        string public constant name = "veNFT";
        string public constant symbol = "veNFT";
        string public constant version = "1.0.0";
        uint8 public constant decimals = 18;
        bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

        bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

        bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

        /* solhint-enable */
        uint256 public tokenId;

        mapping(uint256 => address) internal _idToOwner;

        mapping(uint256 => address) internal _idToApprovals;

        mapping(address => uint256) internal _ownerToNFTokenCount;

        mapping(address => mapping(uint256 => uint256)) internal _ownerToNFTokenIdList;

        mapping(uint256 => uint256) internal _tokenToOwnerIndex;

        mapping(address => mapping(address => bool)) internal _ownerToOperators;

        mapping(bytes4 => bool) internal _supportedInterfaces;

        constructor(
            address _operatorMsg,
            address tokenAddr,
            uint256 _duration
        ) CheckPermission(_operatorMsg) {
            token = tokenAddr;
            pointHistory[0].blk = block.number;
            pointHistory[0].ts = block.timestamp;

            duration = _duration;
            _supportedInterfaces[ERC165_INTERFACE_ID] = true;
            _supportedInterfaces[ERC721_INTERFACE_ID] = true;
            _supportedInterfaces[ERC721_METADATA_INTERFACE_ID] = true;
            // mint-ish
            emit Transfer(address(0), address(this), tokenId);
            // burn-ish
            emit Transfer(address(this), address(0), tokenId);
        }

        modifier onlyBoost() {
            require(boosts[msg.sender], "only voter");
            _;
        }

        function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
            return _supportedInterfaces[_interfaceID];
        }

        function getLastUserSlope(uint256 _tokenId) external view returns (int128) {
            uint256 uepoch = userPointEpoch[_tokenId];
            return userPointHistory[_tokenId][uepoch].slope;
        }

        function userPointHistoryTs(uint256 _tokenId, uint256 _idx) external view returns (uint256) {
            return userPointHistory[_tokenId][_idx].ts;
        }

        function lockedEnd(uint256 _tokenId) external view returns (uint256) {
            return locked[_tokenId].end;
        }

        function _balance(address _owner) internal view returns (uint256) {
            return _ownerToNFTokenCount[_owner];
        }

        function balanceOf(address _owner) public view returns (uint256) {
            return _balance(_owner);
        }

        function ownerOf(uint256 _tokenId) public view returns (address) {
            return _idToOwner[_tokenId];
        }

        function getApproved(uint256 _tokenId) external view returns (address) {
            return _idToApprovals[_tokenId];
        }

        function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
            return (_ownerToOperators[_owner])[_operator];
        }

        function tokenOfOwnerByIndex(address _owner, uint256 _tokenIndex) external view returns (uint256) {
            return _ownerToNFTokenIdList[_owner][_tokenIndex];
        }

        function _isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
            address owner = _idToOwner[_tokenId];
            bool spenderIsOwner = owner == _spender;
            bool spenderIsApproved = _spender == _idToApprovals[_tokenId];
            bool spenderIsApprovedForAll = (_ownerToOperators[owner])[_spender];
            return spenderIsOwner || spenderIsApproved || spenderIsApprovedForAll;
        }

        function isApprovedOrOwner(address _spender, uint256 _tokenId) external view returns (bool) {
            return _isApprovedOrOwner(_spender, _tokenId);
        }

        function _addTokenToOwnerList(address _to, uint256 _tokenId) internal {
            uint256 currentCount = _balance(_to);

            _ownerToNFTokenIdList[_to][currentCount] = _tokenId;
            _tokenToOwnerIndex[_tokenId] = currentCount;
        }

        function _removeTokenFromOwnerList(address _from, uint256 _tokenId) internal {
            // Delete
            uint256 currentCount = _balance(_from) - 1;
            uint256 currentIndex = _tokenToOwnerIndex[_tokenId];

            if (currentCount == currentIndex) {
                // update ownerToNFTokenIdList
                _ownerToNFTokenIdList[_from][currentCount] = 0;
                // update tokenToOwnerIndex
                _tokenToOwnerIndex[_tokenId] = 0;
            } else {
                uint256 lastTokenId = _ownerToNFTokenIdList[_from][currentCount];

                // Add
                // update ownerToNFTokenIdList
                _ownerToNFTokenIdList[_from][currentIndex] = lastTokenId;
                // update tokenToOwnerIndex
                _tokenToOwnerIndex[lastTokenId] = currentIndex;

                // Delete
                // update ownerToNFTokenIdList
                _ownerToNFTokenIdList[_from][currentCount] = 0;
                // update tokenToOwnerIndex
                _tokenToOwnerIndex[_tokenId] = 0;
            }
        }

        function _addTokenTo(address _to, uint256 _tokenId) internal {
            // Throws if `_tokenId` is owned by someone
            assert(_idToOwner[_tokenId] == address(0));
            // Change the owner
            _idToOwner[_tokenId] = _to;
            // Update owner token index tracking
            _addTokenToOwnerList(_to, _tokenId);
            // Change count tracking
            _ownerToNFTokenCount[_to] += 1;
        }

        function _removeTokenFrom(address _from, uint256 _tokenId) internal {
            // Throws if `_from` is not the current owner
            assert(_idToOwner[_tokenId] == _from);
            // Change the owner
            _idToOwner[_tokenId] = address(0);
            // Update owner token index tracking
            _removeTokenFromOwnerList(_from, _tokenId);
            // Change count tracking
            _ownerToNFTokenCount[_from] -= 1;
        }

        function _clearApproval(address _owner, uint256 _tokenId) internal {
            // Throws if `_owner` is not the current owner
            assert(_idToOwner[_tokenId] == _owner);
            if (_idToApprovals[_tokenId] != address(0)) {
                // Reset approvals
                _idToApprovals[_tokenId] = address(0);
            }
        }

        function _transferFrom(
            address _from,
            address _to,
            uint256 _tokenId,
            address _sender
        ) internal {
            require(!voted[_tokenId], "attached");
            // Check requirements
            require(_isApprovedOrOwner(_sender, _tokenId), "no owner");
            // Clear approval. Throws if `_from` is not the current owner
            _clearApproval(_from, _tokenId);
            // Remove NFT. Throws if `_tokenId` is not a valid NFT
            _removeTokenFrom(_from, _tokenId);
            // Add NFT
            _addTokenTo(_to, _tokenId);
            // Set the block of ownership transfer (for Flash NFT protection)
            ownershipChange[_tokenId] = block.number;
            // Log the transfer
            emit Transfer(_from, _to, _tokenId);
        }

        function transferFrom(
            address _from,
            address _to,
            uint256 _tokenId
        ) external {
            _transferFrom(_from, _to, _tokenId, msg.sender);
        }

        function _isContract(address account) internal view returns (bool) {
            // This method relies on extcodesize, which returns 0 for contracts in
            // construction, since the code is only stored at the end of the
            // constructor execution.
            uint256 size;
            assembly {
                size := extcodesize(account)
            }
            return size > 0;
        }

        function safeTransferFrom(
            address _from,
            address _to,
            uint256 _tokenId,
            bytes memory _data
        ) public {
            _transferFrom(_from, _to, _tokenId, msg.sender);

            if (_isContract(_to)) {
                // Throws if transfer destination is a contract which does not implement 'onERC721Received'
                try IERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data) returns (bytes4) {} catch (
                    bytes memory reason
                ) {
                    if (reason.length == 0) {
                        revert("ERC721: transfer to non ERC721Receiver implementer");
                    } else {
                        assembly {
                            revert(add(32, reason), mload(reason))
                        }
                    }
                }
            }
        }

        function safeTransferFrom(
            address _from,
            address _to,
            uint256 _tokenId
        ) external {
            safeTransferFrom(_from, _to, _tokenId, "");
        }

        function approve(address _approved, uint256 _tokenId) public {
            address owner = _idToOwner[_tokenId];
            // Throws if `_tokenId` is not a valid NFT
            require(owner != address(0));
            // Throws if `_approved` is the current owner
            require(_approved != owner);
            // Check requirements
            bool senderIsOwner = (_idToOwner[_tokenId] == msg.sender);
            bool senderIsApprovedForAll = (_ownerToOperators[owner])[msg.sender];
            require(senderIsOwner || senderIsApprovedForAll);
            // Set the approval
            _idToApprovals[_tokenId] = _approved;
            emit Approval(owner, _approved, _tokenId);
        }

        function setApprovalForAll(address _operator, bool _approved) external {
            // Throws if `_operator` is the `msg.sender`
            assert(_operator != msg.sender);
            _ownerToOperators[msg.sender][_operator] = _approved;
            emit ApprovalForAll(msg.sender, _operator, _approved);
        }

        function _mint(address _to, uint256 _tokenId) internal returns (bool) {
            // Throws if `_to` is zero address
            assert(_to != address(0));
            // Add NFT. Throws if `_tokenId` is owned by someone
            _addTokenTo(_to, _tokenId);
            emit Transfer(address(0), _to, _tokenId);
            return true;
        }

        function _checkpoint(
            uint256 _tokenId,
            LockedBalance memory oldLocked,
            LockedBalance memory newLocked
        ) internal {
            Point memory uOld;
            Point memory uNew;
            int128 oldDslope = 0;
            int128 newDslope = 0;
            uint256 _epoch = epoch;

            if (_tokenId != 0) {
                // Calculate slopes and biases
                // Kept at zero when they have to
                if (oldLocked.end > block.timestamp && oldLocked.amount > 0) {
                    uOld.slope = oldLocked.amount / I_MAXTIME;
                    uOld.bias = uOld.slope * int128(int256(oldLocked.end - block.timestamp));
                }
                if (newLocked.end > block.timestamp && newLocked.amount > 0) {
                    uNew.slope = newLocked.amount / I_MAXTIME;
                    uNew.bias = uNew.slope * int128(int256(newLocked.end - block.timestamp));
                }

                // Read values of scheduled changes in the slope
                // old_locked.end can be in the past and in the future
                // new_locked.end can ONLY by in the FUTURE unless everything expired: than zeros
                oldDslope = slopeChanges[oldLocked.end];
                if (newLocked.end != 0) {
                    if (newLocked.end == oldLocked.end) {
                        newDslope = oldDslope;
                    } else {
                        newDslope = slopeChanges[newLocked.end];
                    }
                }
            }

            Point memory lastPoint = Point({bias: 0, slope: 0, ts: block.timestamp, blk: block.number});
            if (_epoch > 0) {
                lastPoint = pointHistory[_epoch];
            }
            uint256 lastCheckpoint = lastPoint.ts;
            // initial_last_point is used for extrapolation to calculate block number
            // (approximately, for *At methods) and save them
            // as we cannot figure that out exactly from inside the contract
            Point memory initialLastPoint = lastPoint;
            uint256 blockSlope = 0;
            // dblock/dt
            if (block.timestamp > lastPoint.ts) {
                blockSlope = (MULTIPLIER * (block.number - lastPoint.blk)) / (block.timestamp - lastPoint.ts);
            }
            // If last point is already recorded in this block, slope=0
            // But that's ok b/c we know the block in such case

            // Go over weeks to fill history and calculate what the current point is
            {
                uint256 ti = (lastCheckpoint / duration) * duration;
                for (uint256 i = 0; i < 255; ++i) {
                    // Hopefully it won't happen that this won't get used in 5 years!
                    // If it does, users will be able to withdraw but vote weight will be broken
                    ti += duration;
                    int128 dSlope = 0;
                    if (ti > block.timestamp) {
                        ti = block.timestamp;
                    } else {
                        dSlope = slopeChanges[ti];
                    }
                    lastPoint.bias -= lastPoint.slope * int128(int256(ti - lastCheckpoint));
                    lastPoint.slope += dSlope;
                    if (lastPoint.bias < 0) {
                        // This can happen
                        lastPoint.bias = 0;
                    }
                    if (lastPoint.slope < 0) {
                        // This cannot happen - just in case
                        lastPoint.slope = 0;
                    }
                    lastCheckpoint = ti;
                    lastPoint.ts = ti;
                    lastPoint.blk = initialLastPoint.blk + (blockSlope * (ti - initialLastPoint.ts)) / MULTIPLIER;
                    _epoch += 1;
                    if (ti == block.timestamp) {
                        lastPoint.blk = block.number;
                        break;
                    } else {
                        pointHistory[_epoch] = lastPoint;
                    }
                }
            }

            epoch = _epoch;
            // Now pointHistory is filled until t=now

            if (_tokenId != 0) {
                // If last point was in this block, the slope change has been applied already
                // But in such case we have 0 slope(s)
                lastPoint.slope += (uNew.slope - uOld.slope);
                lastPoint.bias += (uNew.bias - uOld.bias);
                if (lastPoint.slope < 0) {
                    lastPoint.slope = 0;
                }
                if (lastPoint.bias < 0) {
                    lastPoint.bias = 0;
                }
            }

            // Record the changed point into history
            pointHistory[_epoch] = lastPoint;

            if (_tokenId != 0) {
                // Schedule the slope changes (slope is going down)
                // We subtract new_user_slope from [new_locked.end]
                // and add old_user_slope to [old_locked.end]
                if (oldLocked.end > block.timestamp) {
                    // old_dslope was <something> - u_old.slope, so we cancel that
                    oldDslope += uOld.slope;
                    if (newLocked.end == oldLocked.end) {
                        oldDslope -= uNew.slope;
                        // It was a new deposit, not extension
                    }
                    slopeChanges[oldLocked.end] = oldDslope;
                }

                if (newLocked.end > block.timestamp) {
                    if (newLocked.end > oldLocked.end) {
                        newDslope -= uNew.slope;
                        // old slope disappeared at this point
                        slopeChanges[newLocked.end] = newDslope;
                    }
                    // else: we recorded it already in old_dslope
                }
                // Now handle user history
                uint256 userEpoch = userPointEpoch[_tokenId] + 1;

                userPointEpoch[_tokenId] = userEpoch;
                uNew.ts = block.timestamp;
                uNew.blk = block.number;
                userPointHistory[_tokenId][userEpoch] = uNew;
            }
        }

        function _depositFor(
            uint256 _tokenId,
            uint256 _value,
            uint256 unlockTime,
            LockedBalance memory lockedBalance,
            DepositType depositType
        ) internal {
            LockedBalance memory _locked = lockedBalance;
            uint256 supplyBefore = supply;

            supply = supplyBefore + _value;
            LockedBalance memory oldLocked;
            (oldLocked.amount, oldLocked.end) = (_locked.amount, _locked.end);
            // Adding to existing lock, or if a lock is expired - creating a new one
            _locked.amount += int128(int256(_value));
            if (unlockTime != 0) {
                _locked.end = unlockTime;
            }
            locked[_tokenId] = _locked;

            // Possibilities:
            // Both old_locked.end could be current or expired (>/< block.timestamp)
            // value == 0 (extend lock) or value > 0 (add to lock or extend lock)
            // _locked.end > block.timestamp (always)
            _checkpoint(_tokenId, oldLocked, _locked);

            address from = msg.sender;
            if (_value != 0 && depositType != DepositType.MERGE_TYPE) {
                assert(IERC20(token).transferFrom(from, address(this), _value));
            }

            emit Deposit(from, _tokenId, _value, _locked.end, depositType, block.timestamp);
            emit Supply(supplyBefore, supplyBefore + _value);
        }

        function addBoosts(address _address) external onlyOperator {
            require(_address != address(0), "0 address");
            require(boosts[_address] == false, "Address already exists");
            boosts[_address] = true;
            emit BoostAdded(_address);
        }

        function removeBoosts(address _address) external onlyOperator {
            require(boosts[_address] == true, "Address no exist");
            delete boosts[_address];
            emit BoostRemoved(_address);
        }

        function voting(uint256 _tokenId) external onlyBoost {
            require(voted[_tokenId] == false, "tokenId voted");
            voted[_tokenId] = true;
        }

        function abstain(uint256 _tokenId) external onlyBoost {
            voted[_tokenId] = false;
        }

        function merge(uint256 _from, uint256 _to) external {
            require(!voted[_from], "attached");
            require(_from != _to);
            require(_isApprovedOrOwner(msg.sender, _from), "no owner");
            require(_isApprovedOrOwner(msg.sender, _to), "no owner");

            LockedBalance memory _locked0 = locked[_from];
            LockedBalance memory _locked1 = locked[_to];
            uint256 value0 = uint256(int256(_locked0.amount));
            uint256 end = _locked0.end >= _locked1.end ? _locked0.end : _locked1.end;

            locked[_from] = LockedBalance(0, 0);
            _checkpoint(_from, _locked0, LockedBalance(0, 0));
            _burn(_from);
            _depositFor(_to, value0, end, _locked1, DepositType.MERGE_TYPE);
        }

        function checkpoint() external {
            _checkpoint(0, LockedBalance(0, 0), LockedBalance(0, 0));
        }

        function depositFor(uint256 _tokenId, uint256 _value) external nonReentrant {
            LockedBalance memory _locked = locked[_tokenId];

            require(_value > 0);
            // dev: need non-zero value
            require(_locked.amount > 0, "No existing lock found");
            require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");
            _depositFor(_tokenId, _value, 0, _locked, DepositType.DEPOSIT_FOR_TYPE);
        }

        function _createLock(
            uint256 _value,
            uint256 _lockDuration,
            address _to
        ) internal returns (uint256) {
            uint256 unlockTime = ((block.timestamp + _lockDuration) / duration) * duration;
            // Locktime is rounded down to weeks

            require(_value > 0, "v >0");
            require(balanceOf(_to) == 0, "less than 1 nft");
            // dev: need non-zero value
            require(unlockTime > block.timestamp, "Can only lock until time in the future");
            require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

            ++tokenId;
            uint256 _tokenId = tokenId;
            _mint(_to, _tokenId);

            _depositFor(_tokenId, _value, unlockTime, locked[_tokenId], DepositType.CREATE_LOCK_TYPE);
            return _tokenId;
        }

        function createLockFor(
            uint256 _value,
            uint256 _lockDuration,
            address _to
        ) external nonReentrant returns (uint256) {
            return _createLock(_value, _lockDuration, _to);
        }

        function createLock(uint256 _value, uint256 _lockDuration) external nonReentrant returns (uint256) {
            return _createLock(_value, _lockDuration, msg.sender);
        }

        function increaseAmount(uint256 _tokenId, uint256 _value) external nonReentrant {
            require(_isApprovedOrOwner(msg.sender, _tokenId), "no owner");

            LockedBalance memory _locked = locked[_tokenId];

            assert(_value > 0);
            // dev: need non-zero value
            require(_locked.amount > 0, "No existing lock found");
            require(_locked.end > block.timestamp, "Cannot add to expired lock. Withdraw");

            _depositFor(_tokenId, _value, 0, _locked, DepositType.INCREASE_LOCK_AMOUNT);
        }

        function increaseUnlockTime(uint256 _tokenId, uint256 _lockDuration) external nonReentrant {
            require(_isApprovedOrOwner(msg.sender, _tokenId), "no owner");

            LockedBalance memory _locked = locked[_tokenId];
            uint256 unlockTime = ((block.timestamp + _lockDuration) / duration) * duration;
            // Locktime is rounded down to weeks

            require(_locked.end > block.timestamp, "Lock expired");
            require(_locked.amount > 0, "Nothing is locked");
            require(unlockTime > _locked.end, "Can only increase lock duration");
            require(unlockTime <= block.timestamp + MAXTIME, "Voting lock can be 4 years max");

            _depositFor(_tokenId, 0, unlockTime, _locked, DepositType.INCREASE_UNLOCK_TIME);
        }

        function withdraw(uint256 _tokenId) external nonReentrant {
            require(_isApprovedOrOwner(msg.sender, _tokenId), "no owner");
            require(!voted[_tokenId], "attached");

            LockedBalance memory _locked = locked[_tokenId];
            require(block.timestamp >= _locked.end, "The lock didn't expire");
            uint256 value = uint256(int256(_locked.amount));

            locked[_tokenId] = LockedBalance(0, 0);
            uint256 supplyBefore = supply;
            supply = supplyBefore - value;

            // old_locked can have either expired <= timestamp or zero end
            // _locked has only 0 end
            // Both can have >= 0 amount
            _checkpoint(_tokenId, _locked, LockedBalance(0, 0));

            assert(IERC20(token).transfer(msg.sender, value));

            // Burn the NFT
            _burn(_tokenId);

            emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
            emit Supply(supplyBefore, supplyBefore - value);
        }

        function emergencyWithdraw(uint256 _tokenId) public nonReentrant {
            require(_isApprovedOrOwner(msg.sender, _tokenId), "no owner");
            voted[_tokenId] = false;
            LockedBalance memory _locked = locked[_tokenId];
            require(block.timestamp >= _locked.end, "The lock didn't expire");
            uint256 value = uint256(int256(_locked.amount));

            locked[_tokenId] = LockedBalance(0, 0);
            uint256 supplyBefore = supply;
            supply = supplyBefore - value;

            assert(IERC20(token).transfer(msg.sender, value));

            // Burn the NFT
            _burn(_tokenId);

            emit Withdraw(msg.sender, _tokenId, value, block.timestamp);
            emit Supply(supplyBefore, supplyBefore - value);
        }

        function _findBlockEpoch(uint256 _block, uint256 maxEpoch) internal view returns (uint256) {
            // Binary search
            uint256 _min = 0;
            uint256 _max = maxEpoch;
            for (uint256 i = 0; i < 128; ++i) {
                // Will be always enough for 128-bit numbers
                if (_min >= _max) {
                    break;
                }
                uint256 _mid = (_min + _max + 1) / 2;
                if (pointHistory[_mid].blk <= _block) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }
            return _min;
        }

        function _balanceOfNFT(uint256 _tokenId, uint256 _t) internal view returns (uint256) {
            uint256 _epoch = userPointEpoch[_tokenId];
            if (_epoch == 0) {
                return 0;
            } else {
                Point memory lastPoint = userPointHistory[_tokenId][_epoch];
                lastPoint.bias -= lastPoint.slope * int128(int256(_t) - int256(lastPoint.ts));
                if (lastPoint.bias < 0) {
                    lastPoint.bias = 0;
                }
                return uint256(int256(lastPoint.bias));
            }
        }

        function tokenURI(uint256 _tokenId) external view returns (string memory) {
            require(_idToOwner[_tokenId] != address(0), "Query for nonexistent token");
            LockedBalance memory _locked = locked[_tokenId];
            return
                _tokenURI(_tokenId, _balanceOfNFT(_tokenId, block.timestamp), _locked.end, uint256(int256(_locked.amount)));
        }

        function balanceOfNFT(uint256 _tokenId) external view returns (uint256) {
            if (ownershipChange[_tokenId] == block.number) return 0;
            return _balanceOfNFT(_tokenId, block.timestamp);
        }

        function balanceOfNFTAt(uint256 _tokenId, uint256 _t) external view returns (uint256) {
            return _balanceOfNFT(_tokenId, _t);
        }

        function _balanceOfAtNFT(uint256 _tokenId, uint256 _block) internal view returns (uint256) {
            // Copying and pasting totalSupply code because Vyper cannot pass by
            // reference yet
            assert(_block <= block.number);

            // Binary search
            uint256 _min = 0;
            uint256 _max = userPointEpoch[_tokenId];
            for (uint256 i = 0; i < 128; ++i) {
                // Will be always enough for 128-bit numbers
                if (_min >= _max) {
                    break;
                }
                uint256 _mid = (_min + _max + 1) / 2;
                if (userPointHistory[_tokenId][_mid].blk <= _block) {
                    _min = _mid;
                } else {
                    _max = _mid - 1;
                }
            }

            Point memory upoint = userPointHistory[_tokenId][_min];

            uint256 maxEpoch = epoch;
            uint256 _epoch = _findBlockEpoch(_block, maxEpoch);
            Point memory point0 = pointHistory[_epoch];
            uint256 dBlock = 0;
            uint256 dt = 0;
            if (_epoch < maxEpoch) {
                Point memory point1 = pointHistory[_epoch + 1];
                dBlock = point1.blk - point0.blk;
                dt = point1.ts - point0.ts;
            } else {
                dBlock = block.number - point0.blk;
                dt = block.timestamp - point0.ts;
            }
            uint256 blockTime = point0.ts;
            if (dBlock != 0) {
                blockTime += (dt * (_block - point0.blk)) / dBlock;
            }

            upoint.bias -= upoint.slope * int128(int256(blockTime - upoint.ts));
            if (upoint.bias >= 0) {
                return uint256(uint128(upoint.bias));
            } else {
                return 0;
            }
        }

        function balanceOfAtNFT(uint256 _tokenId, uint256 _block) external view returns (uint256) {
            return _balanceOfAtNFT(_tokenId, _block);
        }

        function _supplyAt(Point memory point, uint256 t) internal view returns (uint256) {
            Point memory lastPoint = point;
            uint256 ti = (lastPoint.ts / duration) * duration;
            for (uint256 i = 0; i < 255; ++i) {
                ti += duration;
                int128 dSlope = 0;
                if (ti > t) {
                    ti = t;
                } else {
                    dSlope = slopeChanges[ti];
                }
                lastPoint.bias -= lastPoint.slope * int128(int256(ti - lastPoint.ts));
                if (ti == t) {
                    break;
                }
                lastPoint.slope += dSlope;
                lastPoint.ts = ti;
            }

            if (lastPoint.bias < 0) {
                lastPoint.bias = 0;
            }
            return uint256(uint128(lastPoint.bias));
        }

        function totalSupplyAtT(uint256 t) public view returns (uint256) {
            uint256 _epoch = epoch;
            Point memory lastPoint = pointHistory[_epoch];
            return _supplyAt(lastPoint, t);
        }

        function totalSupply() external view returns (uint256) {
            return totalSupplyAtT(block.timestamp);
        }

        function totalSupplyAt(uint256 _block) external view returns (uint256) {
            assert(_block <= block.number);
            uint256 _epoch = epoch;
            uint256 targetEpoch = _findBlockEpoch(_block, _epoch);

            Point memory point = pointHistory[targetEpoch];
            uint256 dt = 0;
            if (targetEpoch < _epoch) {
                Point memory pointNext = pointHistory[targetEpoch + 1];
                if (point.blk != pointNext.blk) {
                    dt = ((_block - point.blk) * (pointNext.ts - point.ts)) / (pointNext.blk - point.blk);
                }
            } else {
                if (point.blk != block.number) {
                    dt = ((_block - point.blk) * (block.timestamp - point.ts)) / (block.number - point.blk);
                }
            }
            // Now dt contains info on how far are we beyond point
            return _supplyAt(point, point.ts + dt);
        }

        function _tokenURI(
            uint256 _tokenId,
            uint256 _balanceOf,
            uint256 _lockedEnd,
            uint256 _value
        ) internal pure returns (string memory output) {
            output = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
            output = string(
                abi.encodePacked(output, "token ", _toString(_tokenId), '</text><text x="10" y="40" class="base">')
            );
            output = string(
                abi.encodePacked(output, "balanceOf ", _toString(_balanceOf), '</text><text x="10" y="60" class="base">')
            );
            output = string(
                abi.encodePacked(output, "locked_end ", _toString(_lockedEnd), '</text><text x="10" y="80" class="base">')
            );
            output = string(abi.encodePacked(output, "value ", _toString(_value), "</text></svg>"));

            string memory json = Base64.encode(
                bytes(
                    string(
                        abi.encodePacked(
                            '{"name": "lock #',
                            _toString(_tokenId),
                            '", "description": "Solidly locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                            Base64.encode(bytes(output)),
                            '"}'
                        )
                    )
                )
            );
            output = string(abi.encodePacked("data:application/json;base64,", json));
        }

        function _toString(uint256 value) internal pure returns (string memory) {
            // Inspired by OraclizeAPI's implementation - MIT license
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

        function _burn(uint256 _tokenId) internal {
            require(_isApprovedOrOwner(msg.sender, _tokenId), "caller is not owner nor approved");

            address owner = ownerOf(_tokenId);

            // Clear approval
            approve(address(0), _tokenId);
            // Remove token
            _removeTokenFrom(msg.sender, _tokenId);
            emit Transfer(owner, address(0), _tokenId);
        }
    }