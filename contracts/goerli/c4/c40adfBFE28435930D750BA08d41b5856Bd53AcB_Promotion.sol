// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IDAO} from '../DAO/interfaces/IDAO.sol';
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Pausable} from "../../Pausable.sol";

contract Promotion is Pausable {
    enum ProposalType { change_value, destroy }
    struct Budget { uint256 uid; string object_id_; uint256 amount; uint256 post_price; uint256 start_time; uint256 end_time; bool resolved; }
    struct Voice { address eth_address; bool voice; }
    struct Proposal { uint256 coeficient; uint256 start_time; bool resolved; ProposalType proposal_type; }

    Proposal[] private _proposals;
    
    mapping(uint256 => mapping(address => bool)) private _is_voted;
    mapping(uint256 => Voice[]) private _voices;

    address private _lexor_address;
    address private _crystal_address;
    uint256 private _crystal_check_period;
    address private _dao_factory_address;
    uint256 private _price_coef;
    Budget[] private _budgets;

    constructor (address crystal_address_, address lexor_address_,  address owner_of_, address dao_factory_address_) Pausable(owner_of_) {
        _lexor_address = lexor_address_;
        _crystal_address = crystal_address_;
        _crystal_check_period = block.timestamp + 182 days;
        _dao_factory_address = dao_factory_address_;
        _price_coef = 1000000;
    }

    event proposalCreated(uint256 uid, uint256 price, uint256 start_time, uint256 end_time, ProposalType proposal_type);
    event voiceSubmited(address eth_address, bool voice);
    event proposalResolved(uint256 uid, bool submited);
    event created(uint256 uid, string object_id, uint256 budget, uint256 post_price, uint256 start_time, uint256 end_time, bool resolved);
    event resolved(uint256 uid, address[] dao_addresses, uint256[] percentages, string object_id, uint256 dao_value, address[] receivers, uint256 watcher_value, uint256 return_value);


    function createProposal(uint256 price_, ProposalType proposal_type_) public {
        uint256 newProposalUid = _proposals.length;
        _proposals.push(Proposal(price_, block.timestamp, false, proposal_type_));
        emit proposalCreated(newProposalUid, price_, block.timestamp, block.timestamp + 5 days, proposal_type_);
    }

    function vote(uint256 uid_, bool voice_) public {
        require(!_is_voted[uid_][msg.sender], "You vote has been submited already");
        Proposal memory proposal = _proposals[uid_];
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        require(IERC721(_crystal_address).balanceOf(msg.sender) > 0, "Not enough metaunits for voting");
        _voices[uid_].push(Voice(msg.sender, voice_));
        emit voiceSubmited(msg.sender, voice_);
        _is_voted[uid_][msg.sender] = true;
    }

    function resolveProposal(uint256 uid_) public {
        Proposal memory proposal = _proposals[uid_];
        require(!proposal.resolved, "Already resolved");
        require(block.timestamp < proposal.start_time + 5 days, "Governance finished");
        uint256 voices_for = 0;
        uint256 voices_against = 0;
        for (uint256 i = 0; i < _voices[uid_].length; i++) {
            Voice memory voice = _voices[uid_][i];
            uint256 balance = IERC721(_crystal_address).balanceOf(voice.eth_address);
            if (voice.voice) voices_for += balance;
            else voices_against += balance;
        }
        bool submited = voices_for > voices_against;
        if (submited) {
            if (proposal.proposal_type == ProposalType.change_value) {
                _price_coef = proposal.coeficient;
            }
            else if (proposal.proposal_type == ProposalType.destroy) {
                IERC20(_lexor_address).transfer(_owner_of, IERC20(_lexor_address).balanceOf(address(this)));
                selfdestruct(payable(_owner_of));
            }
        }
        emit proposalResolved(uid_, submited);
        _proposals[uid_].resolved = true;
        
    }

    function getPrice() public view returns(uint256) {
        return IERC20(_lexor_address).totalSupply() / _price_coef;
    } 

    function create(string memory object_id_, uint256 amount_, uint256 start_time_, uint256 period_) public notPaused {
        require(amount_ >= 10 ether, "Not enough Lexor");
        if (_crystal_check_period > block.timestamp) require(IERC721(_crystal_address).balanceOf(msg.sender) >= 1, "You need to have Shard Crystal in your wallet");
        IERC20(_lexor_address).transferFrom(msg.sender, address(this), amount_);
        uint256 newBudgetUid = _budgets.length;
        _budgets.push(Budget(newBudgetUid, object_id_, amount_, getPrice(),  start_time_, start_time_ + period_, false));
        emit created(newBudgetUid, object_id_, amount_, getPrice(), start_time_, start_time_ + period_, false);
    }

    function resolve(uint256 uid, address[] memory dao_addresses_, uint256[] memory percentages_, address[] memory receivers_) public notPaused {
        require(msg.sender == _owner_of, "Permission denied");
        Budget memory budget = _budgets[uid];
        require(budget.end_time < block.timestamp, "Not finished yet");
        require(!budget.resolved, "Already resolved");
        IERC20 lexor = IERC20(_lexor_address);
        uint256 dao_value = budget.amount / 2;
        uint256 sum = 0;
        for (uint256 i = 0; i < dao_addresses_.length; i++) {
            uint256 value = dao_value * percentages_[i] / 100;
            lexor.transfer(dao_addresses_[i], value);
            sum += value;
        }
        uint256 receiver_len = receivers_.length;
        for (uint256 i = 0; i < receiver_len; i++) {
            lexor.transfer(receivers_[i], budget.post_price);
            sum += budget.post_price;
        }
        uint256 return_value = budget.amount - sum;
        lexor.transfer(msg.sender, return_value);
        _budgets[uid].resolved = true;
        emit resolved(uid, dao_addresses_, percentages_, budget.object_id_, dao_value, receivers_, budget.post_price, return_value);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDAO {
    function getDaosByOwner(address owner_of)
        external
        returns (address[] memory);

    function getDaoOwner(address dao_address)
        external
        returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author MetaPlayerOne DAO
 * @title Pausable
 * @notice Contract which manages allocations in MetaPlayerOne.
 */
contract Pausable {
    address internal _owner_of;
    bool internal _paused = false;

    /**
    * @dev setup owner of this contract with paused off state.
    */
    constructor(address owner_of_) {
        _owner_of = owner_of_;
        _paused = false;
    }

    /**
    * @dev modifier which can be used on child contract for checking if contract services are paused.
    */
    modifier notPaused() {
        require(!_paused, "Contract is paused");
        _;
    }

    /**
    * @dev function which setup paused variable.
    * @param paused_ new boolean value of paused condition.
    */
    function setPaused(bool paused_) external {
        require(_paused == paused_, "Param has been asigned already");
        require(_owner_of == msg.sender, "Permission address");
        _paused = paused_;
    }

    /**
    * @dev function which setup owner variable.
    * @param owner_of_ new owner of contract.
    */
    function setOwner(address owner_of_) external {
        require(_owner_of == msg.sender, "Permission address");
        _owner_of = owner_of_;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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