/**
 *Submitted for verification at Etherscan.io on 2022-04-28
*/

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


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// File: Staker.sol



pragma solidity ^0.8.0;





contract MineBaronsStaking is IERC721Receiver, Ownable {

    struct NftInfo {
        bool isStaked;
        address owner;
        address nftAddress;
        uint256 tokenId;
        uint256 timeOfDeposit;
    }

    struct UserInfo {
        bool inGame;
        uint256 amount;
        mapping (uint256 => NftInfo) stakedTokens;
    }

    mapping(address => mapping (uint256 => NftInfo)) public nftInfo;

    mapping (address => UserInfo) public userInfo;

    mapping (address => bool) public projectNFTs;
    address[] private projectNFTsArray;

    address private system;

    bool public depositsEnabled = true;

    event DepositSuccessfull(address nftAddress, uint256 tokenId, address user);
    event WithdrawalSuccessfull(address nftAddress, uint256 tokenId, address user);

    constructor(address _system) {
        system = _system;
    }

    /// @dev View functions 

    function play(address user, uint256 i) external view returns (address) {
        return userInfo[user].stakedTokens[i].nftAddress;
    }

    function getAllTokensStakedByUser(address user) external view returns (address[] memory nftAddress, uint256[] memory tokenIds) {
        nftAddress = new address[](userInfo[user].amount);
        tokenIds = new uint256[](userInfo[user].amount);
        uint256 counter;
        for (uint256 i; i < userInfo[user].amount; i++) {
            nftAddress[counter] = userInfo[user].stakedTokens[i].nftAddress;
            tokenIds[counter] = userInfo[user].stakedTokens[i].tokenId;
            counter ++;
        }
    }


    /// @dev Public functions
    //function stake(address nftAddress, uint256 tokenId, uint256 signedTimestamp, bytes memory sig) external {

    function stake(address nftAddress, uint256 tokenId) external {
        require(depositsEnabled, "Deposits are currently disabled");
        // require(verify(true, _msgSender(), nftAddress, tokenId, signedTimestamp, sig), "Invalid call");
        require(projectNFTs[nftAddress], "Invalid NFT Address");

        IERC721(nftAddress).safeTransferFrom(_msgSender(), address(this), tokenId);

        nftInfo[nftAddress][tokenId].isStaked = true;
        nftInfo[nftAddress][tokenId].owner = _msgSender();
        nftInfo[nftAddress][tokenId].nftAddress = nftAddress;
        nftInfo[nftAddress][tokenId].tokenId = tokenId;
        nftInfo[nftAddress][tokenId].timeOfDeposit = block.timestamp;

        if (!userInfo[_msgSender()].inGame) {
            userInfo[_msgSender()].inGame = true;
        }
        userInfo[_msgSender()].stakedTokens[userInfo[_msgSender()].amount] = nftInfo[nftAddress][tokenId];
        userInfo[_msgSender()].amount ++;

        emit DepositSuccessfull(nftAddress, tokenId, _msgSender());
    } 

    //function withdraw(address nftAddress, uint256 tokenId, uint256 signedTimestamp, bytes memory sig) external {

    function withdraw(address nftAddress, uint256 tokenId) external {
        // require(verify(false, _msgSender(), nftAddress, tokenId, signedTimestamp, sig), "Invalid call");
        require(nftInfo[nftAddress][tokenId].isStaked, "NFT is not staked");
        require(projectNFTs[nftAddress], "Invalid NFT Address");
        require(nftInfo[nftAddress][tokenId].owner == _msgSender(), "Caller is not the owner of this nft");

        nftInfo[nftAddress][tokenId].isStaked = false;
        nftInfo[nftAddress][tokenId].owner = address(0);
        nftInfo[nftAddress][tokenId].timeOfDeposit = 0;

        for (uint256 i; i < userInfo[_msgSender()].amount; i ++) {
            if (userInfo[_msgSender()].stakedTokens[i].nftAddress == nftAddress && userInfo[_msgSender()].stakedTokens[i].tokenId == tokenId ) {
                for (uint256 x = i; x < userInfo[_msgSender()].amount; x++) {
                    userInfo[_msgSender()].stakedTokens[x] = userInfo[_msgSender()].stakedTokens[x+1];
                }
                userInfo[_msgSender()].stakedTokens[userInfo[_msgSender()].amount] = nftInfo[address(0)][0];
                break;
            }
        }
        userInfo[_msgSender()].amount --;
        IERC721(nftAddress).safeTransferFrom(address(this), _msgSender(), tokenId);
    }


    /// @dev OnlyOwner

    function setProjectNFTs(address nft, bool value) external onlyOwner {
        projectNFTs[nft] = value;
        if (value == true) {
            projectNFTsArray.push(nft);
        } else {
            for (uint256 i; i < projectNFTsArray.length; i ++) {
                if (projectNFTsArray[i] == nft) {
                    for (uint256 x = i; x < projectNFTsArray.length-1; x++) {
                        projectNFTsArray[x] = projectNFTsArray[x+1];
                    }
                    projectNFTsArray.pop();
                    break;
                }
            }
        }
    }

    function setDepositStatus(bool value) external onlyOwner {
        depositsEnabled = value;
    }



    /// @dev Internal Functions

    function verify(bool _stake, address user, address nftAddress, uint256 tokenId, uint256 timestamp, bytes memory sig) internal view returns (bool) {
        bytes32 messageHash;
        if (_stake) {
            messageHash = getMessageHashStake(user, nftAddress, tokenId, timestamp);
        } else {
            messageHash = getMessageHashWithdraw(user, nftAddress, tokenId, timestamp);
        }
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);
        return recoverSigner(ethSignedMessageHash, sig) == system;
    }

    function getMessageHashStake(address user, address nftAddress, uint256 tokenId, uint256 timeStamp) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("Stake", user, nftAddress, tokenId, timeStamp));
    }

    function getMessageHashWithdraw(address user, address nftAddress, uint256 tokenId, uint256 timestamp) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("Withdraw", user, nftAddress, tokenId, timestamp));
    }

    function getEthSignedMessageHash(bytes32 _messageHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _messageHash));
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    event Received();

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    )
        external
        override
        returns(bytes4)
    {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
    }
}