// SPDX-License-Identifier: MIT

// Vote Box
// @Creator: Sharkz
// @Author: Jason Hoi

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../lib/EIP712VoteAllowlist.sol";
import "./IVoteBox.sol";

error NonExistPoll();
error CreatePollWithEmptyTopic();
error CreatePollWithInvalidOptionCount();
error CreatePollWithInvalidAllowlistSwitch();
error CreatePollWithInvalidNftHolderSwitch();
error GetVoteNonExistVote();
error VoteForNonStartedPoll();
error VoteForInvalidValue();
error VoteForDisallowedPoll();
error VoteForDisallowedNftHolder();

contract VoteBox is IVoteBox, Ownable, EIP712VoteAllowlist, ReentrancyGuard {
    using ECDSA for bytes32;

    enum VoteResult { Unknown, OptionA, OptionB, OptionC, OptionD, OptionE }

    // poll object
    struct Poll{
        string topic;
        string content;
        // packing first 8 unit32 into one uint256 space
        uint32 optionCount;
        uint32 startTime;
        uint32 endTime;
        uint32 optionA;
        uint32 optionB;
        uint32 optionC;
        uint32 optionD;
        uint32 optionE;
        uint8 onlyAllowlist;
        uint8 onlyNftHolder;
        // keep track of each voter address
        mapping(uint256 => address) addresses;
        // keep track of address => vote
        mapping(address => uint256) addressVote;
    }
    // Total poll count, also the last poll id (poll id starts at 1)
    uint256 public pollCount;
    // All vote polls
    mapping(uint256 => Poll) public polls;
    // NFT contract
    IERC721 public nftContract;


    constructor (address _signer, address _nftContract) EIP712VoteAllowlist() {
        // signer create allowlist for voter address, allowlist can be enabled by individual poll
        setSigner(_signer);

        // target NFT contract for NFT holder check
        nftContract = IERC721(_nftContract);
    }

    ////////// For admins
    // update linking ERC721 contract address
    function setNFTContract(address _addr) external onlyOwner {
        nftContract = IERC721(_addr);
    }

    // create new poll by contract owner
    function createPoll(
        string calldata _topic, 
        string calldata _content, 
        uint32 _optionCount, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint8 _onlyAllowlist, 
        uint8 _onlyNftHolder
    ) 
        external 
        onlyOwner 
    {
        if (bytes(_topic).length < 0) revert CreatePollWithEmptyTopic();
        if (_optionCount < 1 || _optionCount > 5) revert CreatePollWithInvalidOptionCount();
        if (!(_onlyAllowlist == 0 || _onlyAllowlist == 1)) revert CreatePollWithInvalidAllowlistSwitch();
        if (!(_onlyNftHolder == 0 || _onlyNftHolder == 1)) revert CreatePollWithInvalidNftHolderSwitch();
        
        uint256 _pindex = pollCount;
        polls[_pindex].topic = _topic;
        polls[_pindex].startTime = _startTime;
        polls[_pindex].endTime = _endTime;
        polls[_pindex].optionCount = _optionCount;
        polls[_pindex].onlyAllowlist = _onlyAllowlist;
        polls[_pindex].onlyNftHolder = _onlyNftHolder;
        polls[_pindex].content = _content;
        pollCount++;

        emit PollCreated(_pindex, _topic, _startTime, _endTime, _optionCount);
    }

    // update poll content
    function setPollContent(uint256 _pid, string calldata _content) external onlyOwner {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        polls[_pid].content = _content;
    }

    // change / disable poll by changing poll time
    function setPollStartTime(uint256 _pid, uint32 _time) external onlyOwner {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        polls[_pid].startTime = _time;

        emit PollChangedStartTime(_pid, _time);
    }
    function setPollEndTime(uint256 _pid, uint32 _time) external onlyOwner {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        polls[_pid].endTime = _time;

        emit PollChangedEndTime(_pid, _time);
    }

    ////////// For voters
    // do not allow contract to call
    modifier callerIsUser() {
        require(tx.origin == msg.sender, "The caller is another contract");
        _;
    }

    // submit vote or change existing vote
    function vote(uint256 _pid, uint256 _value, bytes calldata _signature) callerIsUser external {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        if (!_existVoteValue(_pid, _value)) revert VoteForInvalidValue();
        if (!_isPollStarted(_pid)) revert VoteForNonStartedPoll();
        if (!_isVoterAllowed(_signature, _pid)) revert VoteForDisallowedPoll();
        if (polls[_pid].onlyNftHolder == 1) {
            // call external NFT contract function
            if (!_isNftHolder(msg.sender)) revert VoteForDisallowedNftHolder();
        }

        // current voter index
        uint256 voterIndex = _getPollVoteCount(_pid);
        
        unchecked {
            if (!_existsVote(_pid, msg.sender)) {
                // record new voter address only once
                polls[_pid].addresses[voterIndex] = msg.sender;

                if (uint256(VoteResult.OptionA) == _value) {
                    polls[_pid].optionA++;

                } else if (uint256(VoteResult.OptionB) == _value) {
                    polls[_pid].optionB++;

                } else if (uint256(VoteResult.OptionC) == _value) {
                    polls[_pid].optionC++;

                } else if (uint256(VoteResult.OptionD) == _value) {
                    polls[_pid].optionD++;

                } else if (uint256(VoteResult.OptionE) == _value) {
                    polls[_pid].optionE++;
                }
            } else {
                uint256 previousVote = _getAddressVote(_pid, msg.sender);

                if (previousVote != _value) {
                    // change to Option A
                    if (uint256(VoteResult.OptionA) == _value) {
                        polls[_pid].optionA++;

                        if (uint256(VoteResult.OptionB) == previousVote) {
                            polls[_pid].optionB--;
                        } else if (uint256(VoteResult.OptionC) == previousVote) {
                            polls[_pid].optionC--;
                        } else if (uint256(VoteResult.OptionD) == previousVote) {
                            polls[_pid].optionD--;
                        } else if (uint256(VoteResult.OptionE) == previousVote) {
                            polls[_pid].optionE--;
                        }
                    }

                    // change to Option B
                    if (uint256(VoteResult.OptionB) == _value) {
                        polls[_pid].optionB++;

                        if (uint256(VoteResult.OptionA) == previousVote) {
                            polls[_pid].optionA--;
                        } else if (uint256(VoteResult.OptionC) == previousVote) {
                            polls[_pid].optionC--;
                        } else if (uint256(VoteResult.OptionD) == previousVote) {
                            polls[_pid].optionD--;
                        } else if (uint256(VoteResult.OptionE) == previousVote) {
                            polls[_pid].optionE--;
                        }
                    }

                    // change to Option C
                    if (uint256(VoteResult.OptionC) == _value) {
                        polls[_pid].optionC++;

                        if (uint256(VoteResult.OptionA) == previousVote) {
                            polls[_pid].optionA--;
                        } else if (uint256(VoteResult.OptionB) == previousVote) {
                            polls[_pid].optionB--;
                        } else if (uint256(VoteResult.OptionD) == previousVote) {
                            polls[_pid].optionD--;
                        } else if (uint256(VoteResult.OptionE) == previousVote) {
                            polls[_pid].optionE--;
                        }
                    }

                    // change to Option D
                    if (uint256(VoteResult.OptionD) == _value) {
                        polls[_pid].optionD++;

                        if (uint256(VoteResult.OptionA) == previousVote) {
                            polls[_pid].optionA--;
                        } else if (uint256(VoteResult.OptionB) == previousVote) {
                            polls[_pid].optionB--;
                        } else if (uint256(VoteResult.OptionC) == previousVote) {
                            polls[_pid].optionC--;
                        } else if (uint256(VoteResult.OptionE) == previousVote) {
                            polls[_pid].optionE--;
                        }
                    }

                    // change to Option E
                    if (uint256(VoteResult.OptionE) == _value) {
                        polls[_pid].optionE++;

                        if (uint256(VoteResult.OptionA) == previousVote) {
                            polls[_pid].optionA--;
                        } else if (uint256(VoteResult.OptionB) == previousVote) {
                            polls[_pid].optionB--;
                        } else if (uint256(VoteResult.OptionC) == previousVote) {
                            polls[_pid].optionC--;
                        } else if (uint256(VoteResult.OptionD) == previousVote) {
                            polls[_pid].optionD--;
                        }
                    }
                }
            }
        }

        // keep track of address -> VoteResult
        polls[_pid].addressVote[msg.sender] = _value;

        emit Voted(msg.sender, _pid, _value);
    }
    
    ////////// External functions
    // Get poll content url
    function totalPoll() external view override returns (uint256) {
        return pollCount;
    }

    // Get poll total options available (A - E options)
    function getPollOptionCount(uint256 _pid) external view override returns (uint256) {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        return polls[_pid].optionCount;
    }

    // Get poll content url
    function getPollContent(uint256 _pid) external view override returns (string memory) {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        return polls[_pid].content;
    }

    // Get poll total vote counts
    function getPollVoteCount(uint256 _pid) external view override returns (uint256) {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        return _getPollVoteCount(_pid);
    }

    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view override returns (uint256) {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        
        uint256 value = _getAddressVote(_pid, _addr);
        require(value != 0, "Vote not found");

        return value;
    }

    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view override returns (address) {
        if (!_existsPoll(_pid)) revert NonExistPoll();

        address voterAddr = polls[_pid].addresses[_voterIndex];
        require(voterAddr != address(0), "Voter not found");

        return voterAddr;
    }

    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view override returns (bool) {
        if (!_existsPoll(_pid)) revert NonExistPoll();
        return _isPollStarted(_pid);
    }

    // Check voter is on poll allowlist
    function isVoterAllowed(bytes calldata _signature, uint256 _pid) external view override returns (bool) {
        return _isVoterAllowed(_signature, _pid);
    }

    // Check if voter is currently holder target NFT
    function isNftHolder(address _addr) external view override returns(bool) {
         return nftContract.balanceOf(_addr) > 0;
    }

    ////////// Others
    /**
     * @dev Returns whether poll started
     */
    function _isPollStarted(uint256 _pid) internal view returns (bool) {
        uint256 startTime = polls[_pid].startTime;
        uint256 endTime = polls[_pid].endTime;
        uint256 blockTime = block.timestamp;

        return startTime > 0 && blockTime >= startTime 
                && blockTime < endTime;
    }

    /**
     * @dev Returns whether voter submitted data passed poll allowlist checking
     */
    function _isVoterAllowed(bytes calldata _signature, uint256 _pid) internal view returns (bool) {
        // by default, allowlist checking is disabled
        if (polls[_pid].onlyAllowlist == 0) {
            return true;
        }
        return verifySignature(_signature, _pid);
    }

    /**
     * @dev Returns if the address is currently a nft holder
     */
     function _isNftHolder(address _addr) internal nonReentrant returns(bool) {
         return nftContract.balanceOf(_addr) > 0;
     }

    /**
     * @dev Returns whether poll id exists.
     */
    function _existsPoll(uint256 _pid) internal view returns(bool) {
        return _pid < pollCount;
    }

    /**
     * @dev Returns whether address has existing vote
     */
    function _existsVote(uint256 _pid, address _addr) internal view returns(bool) {
        return uint256(polls[_pid].addressVote[_addr]) != 0;
    }

    /**
     * @dev Returns whether vote value is valid
     */
    function _existVoteValue(uint256 _pid, uint256 _value) internal view returns(bool) {
        return _value > 0 && _value <= polls[_pid].optionCount;
    }

    /**
     * @dev Returns the vote value for a wallet
     */
    function _getAddressVote(uint256 _pid, address _addr) internal view returns(uint256) {
        return uint256(polls[_pid].addressVote[_addr]);
    }

    /**
     * @dev Returns the vote count for a poll
     */
    function _getPollVoteCount(uint256 _pid) internal view returns(uint256) {
        return polls[_pid].optionA + polls[_pid].optionB + polls[_pid].optionC + polls[_pid].optionD + polls[_pid].optionE;
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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EIP712VoteAllowlist is Ownable {
    using ECDSA for bytes32;

    // Verify signature with this signer address
    address eip712Signer = address(0);

    // Domain separator is EIP-712 defined struct to make sure 
    // signature is coming from the this contract in same ETH newtork.
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-domainseparator
    // @MATCHING cliend-side code
    bytes32 public DOMAIN_SEPARATOR;

    // HASH_STRUCT should not contain unnecessary whitespace between each parameters
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md#definition-of-encodetype
    // @MATCHING cliend-side code
    bytes32 public constant HASH_STRUCT = keccak256("Minter(address wallet,uint256 pollId)");

    constructor() {
        // @MATCHING cliend-side code
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                // @MATCHING cliend-side code
                keccak256(bytes("WhitelistToken")),
                keccak256(bytes("1")),
                block.chainid,
                address(this)
            )
        );
    }

    function setSigner(address _addr) public onlyOwner {
        eip712Signer = _addr;
    }

    modifier checkWhitelist(bytes calldata _signature, uint256 _pid) {
        require(eip712Signer == _recoverSigner(_signature, _pid), "Invalid Signature");
        _;
    }

    // Verify signature (relating to msg.sender) comes by correct signer
    function verifySignature(bytes calldata _signature, uint256 _pid) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature, _pid);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature, uint256 _pid) internal view returns (address) {
        require(eip712Signer != address(0), "whitelist not enabled");

        // Verify EIP-712 signature by recreating the data structure
        // that we signed on the client side, and then using that to recover
        // the address that signed the signature for this data.
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(HASH_STRUCT, msg.sender, _pid))
            )
        );
        return digest.recover(_signature);
    }
}

// SPDX-License-Identifier: MIT
// VoteBox interface
// @Creator: Sharkz
// @Author: Jason Hoi

pragma solidity ^0.8.0;

interface IVoteBox {
    event PollCreated(uint256 pollId, string topic, uint256 startTime, uint256 endTime, uint optionCount);
    event PollChangedStartTime(uint256 pollId, uint256 time);
    event PollChangedEndTime(uint256 pollId, uint256 time);
    event Voted(address indexed sender, uint256 pollId, uint value);

    // Get total poll count
    function totalPoll() external view returns (uint256);
    // Get poll total options available
    function getPollOptionCount(uint256 _pid) external view returns (uint256);
    // Get poll content
    function getPollContent(uint256 _pid) external view returns (string memory);
    // Get poll total vote counts
    function getPollVoteCount(uint256 _pid) external view returns (uint256);
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view returns (address);
    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view returns (bool);
    // Check voter is on poll allowlist
    function isVoterAllowed(bytes calldata _signature, uint256 _pid) external view returns (bool);
    // Check if voter is currently holder target NFT
    function isNftHolder(address _addr) external view returns(bool);
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