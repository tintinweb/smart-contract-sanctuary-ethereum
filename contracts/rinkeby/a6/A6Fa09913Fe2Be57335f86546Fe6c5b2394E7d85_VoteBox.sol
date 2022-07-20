// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * VoteBox - Genesis voting system
 * *****************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-02
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../lib/712/EIP712VoteAllowlist.sol";
import "../lib/Adminable.sol";
import "./IVoteBox.sol";

contract VoteBox is Adminable, IVoteBox, EIP712VoteAllowlist {
    // poll option
    struct PollOption {
        string name;
        uint256 vote;
    }

    // poll object
    struct Poll {
        string topic;
        string content;
        uint32 optionCount;
        uint32 startTime;
        uint32 endTime;
        uint8 disableChange;
        uint8 onlyAllowlist;
        uint8 onlyNftHolder;
        address nftContract;
        // keep track of each vote option data
        mapping(uint256 => PollOption) options;
        // keep track of each voter address
        mapping(uint256 => address) addresses;
        // keep track of each vote value for each address
        mapping(address => uint256) addressVote;
    }

    // poll count, also represent next poll id
    uint256 public pollCount;

    // all polls
    mapping(uint256 => Poll) public polls;

    constructor () EIP712VoteAllowlist() {}

    ////////// For admins
    // create new poll by contract owner
    function createPoll(
        string calldata _topic, 
        string calldata _content, 
        uint32 _optionCount, 
        uint32 _startTime, 
        uint32 _endTime, 
        uint8 _disableChange,
        uint8 _onlyAllowlist, 
        uint8 _onlyNftHolder,
        address _nftContract
    ) 
        external 
        onlyAdmin 
    {
        require(bytes(_topic).length > 0, "CreatePollWithEmptyTopic()");
        require(_optionCount > 0, "CreatePollWithInvalidOptionCount()");
        require(_disableChange == 0 || _disableChange == 1, "CreatePollWithInvalidDisableChange()");
        require(_onlyAllowlist == 0 || _onlyAllowlist == 1, "CreatePollWithInvalidAllowlistSwitch()");
        require(_onlyNftHolder == 0 || _onlyNftHolder == 1, "CreatePollWithInvalidNftHolderSwitch()");
        
        uint256 _pindex = pollCount;
        polls[_pindex].topic = _topic;
        polls[_pindex].content = _content;
        polls[_pindex].startTime = _startTime;
        polls[_pindex].endTime = _endTime;
        polls[_pindex].optionCount = _optionCount;
        polls[_pindex].disableChange = _disableChange;
        polls[_pindex].onlyAllowlist = _onlyAllowlist;
        polls[_pindex].onlyNftHolder = _onlyNftHolder;
        polls[_pindex].nftContract = _nftContract;
        pollCount ++;

        emit PollCreated(_pindex, _topic, _startTime, _endTime, _optionCount);
    }
    

    modifier existsPoll(uint256 _pid) {
        require(_existsPoll(_pid), "NonExistPoll()");
        _;
    }

    // update poll content
    function setPollContent(uint256 _pid, string calldata _content) external onlyAdmin existsPoll(_pid) {
        polls[_pid].content = _content;
    }

    // update poll option name
    function setPollOptionName(uint256 _pid, uint256 _option, string calldata _name) external onlyAdmin existsPoll(_pid) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        polls[_pid].options[_option].name = _name;
    }

    // schedule poll with start time
    function setPollStartTime(uint256 _pid, uint32 _time) external onlyAdmin existsPoll(_pid) {
        polls[_pid].startTime = _time;

        emit PollChangedStartTime(_pid, _time);
    }

    // schedule poll ending time
    function setPollEndTime(uint256 _pid, uint32 _time) external onlyAdmin existsPoll(_pid) {
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
    function vote(uint256 _pid, uint256 _value, bytes calldata _signature) external callerIsUser existsPoll(_pid) {
        // poll option starts from 1 ~ n (poll optionCount)
        require(_existsPollOption(_pid, _value), "NonExistPollOption()");
        require(_isPollStarted(_pid), "VoteForNonStartedPoll()");
        require(isVoterAllowed(_pid, _signature), "VoterDisallowed()");
        require(isVoterNftHolder(_pid), "VoterIsNotNFTHolder()");

        // voter index starts at 0, next voter index will be the current vote count
        uint256 voterIndex = _getPollVoteCount(_pid);

        unchecked {
            if (!_existsVote(_pid, msg.sender)) {
                // first-time record new voter address and vote value
                polls[_pid].addresses[voterIndex] = msg.sender;
                polls[_pid].options[_value].vote ++;
            } else {
                require(polls[_pid].disableChange == 0, "VoteChangeDisabled()");
                uint256 previousVote = _getAddressVote(_pid, msg.sender);
                if (_value != previousVote) {
                    // changing previous vote
                    polls[_pid].options[previousVote].vote --;
                    polls[_pid].options[_value].vote ++;
                }
            }
        }        
        // keep track of last address vote
        polls[_pid].addressVote[msg.sender] = _value;

        emit Voted(msg.sender, _pid, _value);
    }
    
    ////////// External functions
    // Get poll content url
    function totalPoll() external view override returns (uint256) {
        return pollCount;
    }

    // Get poll available option count
    function getPollOptionCount(uint256 _pid) external view override existsPoll(_pid) returns (uint256) {
        return polls[_pid].optionCount;
    }

    // Get poll content url
    function getPollContent(uint256 _pid) external view override existsPoll(_pid) returns (string memory) {
        return polls[_pid].content;
    }

    // Get poll option name
    function getPollOptionName(uint256 _pid, uint256 _option) external view override existsPoll(_pid) returns (string memory) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        return polls[_pid].options[_option].name;
    }

    // Get poll total vote counts
    function getPollVoteCount(uint256 _pid) external view override existsPoll(_pid) returns (uint256) {
        return _getPollVoteCount(_pid);
    }

    // Get poll total vote count for an option
    function getPollOptionVoteCount(uint256 _pid, uint256 _option) external view override existsPoll(_pid) returns (uint256) {
        require(_existsPollOption(_pid, _option), "NonExistPollOption()");
        return _getPollOptionVoteCount(_pid, _option);
    }

    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view override existsPoll(_pid) returns (uint256) {        
        uint256 value = _getAddressVote(_pid, _addr);
        require(value != 0, "Vote not found");

        return value;
    }

    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view override existsPoll(_pid) returns (address) {
        address voterAddr = polls[_pid].addresses[_voterIndex];
        require(voterAddr != address(0), "Voter not found");

        return voterAddr;
    }

    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view override existsPoll(_pid) returns (bool) {
        return _isPollStarted(_pid);
    }

    // Check voter is on poll allowlist
    function isVoterAllowed(uint256 _pid, bytes calldata _signature) public view override returns (bool) {
        // by default, this will return true when unset or 0 value
        if (polls[_pid].onlyAllowlist == 0) {
            return true;
        }
        return verifySignature(_signature, _pid);
    }

    // Check if voter is currently owner of required NFT
    function isVoterNftHolder(uint256 _pid) public view override returns (bool) {
        // when poll onlyNftHolder is disabled, skipping nft holder checking
        if (polls[_pid].onlyNftHolder == 0) return true;

        address nftContract = polls[_pid].nftContract;
        require(nftContract != address(0), "NonExistNftContract()");

        try IERC721(nftContract).balanceOf(msg.sender) returns (uint256 balance) {
            return balance > 0;
        } catch (bytes memory) {
            return false;
        }
    }

    ////////// Internal functions
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
     * @dev Returns whether poll id exists.
     */
    function _existsPoll(uint256 _pid) internal view returns(bool) {
        return _pid < pollCount;
    }

    /**
     * @dev Returns whether poll option exists.
     */
    function _existsPollOption(uint256 _pid, uint256 _option) internal view returns(bool) {
        return _option > 0 && _option <= polls[_pid].optionCount;
    }

    /**
     * @dev Returns whether address has existing vote
     */
    function _existsVote(uint256 _pid, address _addr) internal view returns(bool) {
        return uint256(polls[_pid].addressVote[_addr]) != 0;
    }

    /**
     * @dev Returns the vote value for a wallet
     */
    function _getAddressVote(uint256 _pid, address _addr) internal view returns(uint256) {
        return uint256(polls[_pid].addressVote[_addr]);
    }

    /**
     * @dev Returns the total vote count for a poll
     */
    function _getPollVoteCount(uint256 _pid) internal view returns(uint256) {
        // optionCount must be larger than 0
        uint256 optionCount = polls[_pid].optionCount;

        uint256 index = 1;
        uint256 count = 0;
        do {
            count += polls[_pid].options[index].vote;
            index ++;
        }
        while (index <= optionCount);

        return count;
    }

    /**
     * @dev Returns the total vote count for a poll option
     */
    function _getPollOptionVoteCount(uint256 _pid, uint256 _option) internal view returns(uint256) {
        return polls[_pid].options[_option].vote;
    }
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

/**
 *******************************************************************************
 * EIP 721 whitelist with only msg.sender
 *******************************************************************************
 * Author: Jason Hoi
 * Date: 2022-05-09
 *
 */

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "../Adminable.sol";

contract EIP712VoteAllowlist is Adminable {
    using ECDSA for bytes32;

    // Verify signature with this signer address
    address public eip712Signer = address(0);

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

    function setSigner(address _addr) public onlyAdmin {
        eip712Signer = _addr;
    }

    modifier checkWhitelist(bytes calldata _signature, uint256 _pid) {
        require(eip712Signer == _recoverSigner(_signature, _pid), "EIP712: Invalid Signature");
        _;
    }

    // Verify signature (relating to msg.sender) comes by correct signer
    function verifySignature(bytes calldata _signature, uint256 _pid) public view returns (bool) {
        return eip712Signer == _recoverSigner(_signature, _pid);
    }

    // Recover the signer address
    function _recoverSigner(bytes calldata _signature, uint256 _pid) internal view returns (address) {
        require(eip712Signer != address(0), "EIP712: Whitelist not enabled");

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

/**
 *******************************************************************************
 * Adminable access control
 *******************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-19
 *
 */
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides basic access control mechanism, multiple 
 * admins can be added or removed from the contract, admins are granted 
 * exclusive access to specific functions with the provided modifier.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {setAdmin}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the owner.
 */
contract Adminable is Context {
    event AdminCreated(address indexed addr);
    event AdminRemoved(address indexed addr);

    // Array of admin addresses
    address[] private _admins;

    // add the first admin with contract creator
    constructor() {
        _createAdmin(_msgSender());
    }

    function isAdmin(address addr) public view virtual returns (bool) {
        if (addr == address(0)) {
          return false;
        }
        for (uint256 i = 0; i < _admins.length; i++) {
          if (addr == _admins[i])
          {
            return true;
          }
        }
        return false;
    }

    modifier onlyAdmin() {
        require(isAdmin(_msgSender()), "Adminable: caller is not admin");
        _;
    }

    function setAdmin(address to, bool approved) public virtual onlyAdmin {
        if (approved) {
            // add new admin when `to` address is not existing admin
            require(!isAdmin(to), "Adminable: add admin for existing admin");
            _createAdmin(to);

        } else {
            // for safety, specifically prevent removing initial admin
            require(to != _admins[0], "Adminable: can not remove initial admin with setAdmin");

            // remove existing admin
            require(isAdmin(to), "Adminable: remove non-existent admin");
            uint256 total = _admins.length;

            // replace current array element with last element, and pop() remove last element
            if (to != _admins[total - 1]) {
                _admins[_adminIndex(to)] = _admins[total - 1];
                _admins.pop();
            } else {
                _admins.pop();
            }

            emit AdminRemoved(to);
        }
    }

    function _adminIndex(address addr) internal view virtual returns (uint256) {
        for (uint256 i = 0; i < _admins.length; i++) {
            if (addr == _admins[i]) {
                return i;
            }
        }
        revert("Adminable: admin index not found");
    }

    function _createAdmin(address addr) internal virtual {
        _admins.push(addr);
        emit AdminCreated(addr);
    }

    /**
     * @dev Leaves the contract without admin.
     *
     * NOTE: Renouncing the last admin will leave the contract without any admins,
     * thereby removing any functionality that is only available to admins.
     */
    function renounceLastAdmin() public virtual onlyAdmin {
        require(_admins.length == 1, "Adminable: can not renounce admin when there are more than one admins");
        delete _admins;
        emit AdminRemoved(_msgSender());
    }
}

// SPDX-License-Identifier: MIT

/**
       █                                                                        
▐█████▄█ ▀████ █████  ▐████    ████████    ███████████  ████▌  ▄████ ███████████
▐██████ █▄ ▀██ █████  ▐████   ██████████   ████   ████▌ ████▌ ████▀       ████▀ 
  ▀████ ███▄ ▀ █████▄▄▐████  ████ ▐██████  ████▄▄▄████  █████████        ████▀  
▐▄  ▀██ █████▄ █████▀▀▐████ ▄████   ██████ █████████    █████████      ▄████    
▐██▄  █ ██████ █████  ▐█████████▀    ▐█████████ ▀████▄  █████ ▀███▄   █████     
▐████  █▀█████ █████  ▐████████▀        ███████   █████ █████   ████ ███████████
       █                                                                        
                                                                       
 *******************************************************************************
 * VoteBox interface
 * *****************************************************************************
 * Creator: Sharkz
 * Author: Jason Hoi
 * Date: 2022-07-02
 *
 */

pragma solidity ^0.8.7;

interface IVoteBox {
    event PollCreated(uint256 indexed pollId, string topic, uint256 indexed startTime, uint256 indexed endTime, uint optionCount);
    event PollChangedStartTime(uint256 indexed pollId, uint256 indexed time);
    event PollChangedEndTime(uint256 indexed pollId, uint256 indexed time);
    event Voted(address indexed sender, uint256 indexed pollId, uint256 value);

    // Get total poll count
    function totalPoll() external view returns (uint256);
    // Get poll total options available
    function getPollOptionCount(uint256 _pid) external view returns (uint256);
    // Get poll content
    function getPollContent(uint256 _pid) external view returns (string memory);
    // Get poll option name
    function getPollOptionName(uint256 _pid, uint256 _option) external view returns (string memory);
    // Get poll total vote counts
    function getPollVoteCount(uint256 _pid) external view returns (uint256);
    // Get poll total vote count for an option
    function getPollOptionVoteCount(uint256 _pid, uint256 _option) external view returns (uint256);
    // Get voter vote value for a poll
    function getAddressVote(uint256 _pid, address _addr) external view returns (uint256);
    // Get voter address by poll id and voter index
    function getVoterAddress(uint256 _pid, uint256 _voterIndex) external view returns (address);
    // Check if a poll is started and not ended
    function isPollStarted(uint256 _pid) external view returns (bool);
    // Check voter is on poll allowlist
    function isVoterAllowed(uint256 _pid, bytes calldata _signature) external view returns (bool);
    // Check voter is poll targeted nft holder
    function isVoterNftHolder(uint256 _pid) external returns(bool);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

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