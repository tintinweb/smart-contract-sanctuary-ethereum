// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interfaces/IDAO.sol";
import "./interfaces/IStaking.sol";

contract DAO is IDAO {
    uint128 immutable minimumQuorum;
    uint128 immutable debatingPeriodDuration;

    address chairPerson;
    uint128 count;

    IStaking staking;

    mapping(address => uint256) participations;

    struct Proposal {
        uint256 trueVotes;
        uint256 falseVotes;
        uint256 endAt;
        bool inProgress;
        address recipient;
        bytes signature;
        string description;
        address[] members;
        mapping(address => bool) voted;
        mapping(address => uint256) delegatedTokens;
    }

    mapping(uint256 => Proposal) proposals;

    event AddProposal(uint128 indexed proposalId);
    event CallStatus(uint128 indexed proposalId, bool status);
    event ProposalRejected(uint128 indexed proposalId);
    event MinimumQuorumNotReached(uint128 indexed proposalId);

    constructor(address _chairPerson, address _staking,
                uint128 _minimumQuorum, uint128 _debatingPeriodDuration) {
        chairPerson = _chairPerson;
        staking = IStaking(_staking);
        minimumQuorum = _minimumQuorum;
        debatingPeriodDuration = _debatingPeriodDuration;
    }

    function delegate(uint128 _id, address _to) external override isExist(_id) {
        require(!proposals[_id].voted[msg.sender], "already voted or delegated");
        require(!proposals[_id].voted[_to], "delegation to voted");
        uint256 balance = staking.getBalance(msg.sender);
        require(balance > 0, "deposite is 0");

        proposals[_id].delegatedTokens[_to] += balance;
        proposals[_id].members.push(msg.sender);
        participations[msg.sender]++;
        proposals[_id].voted[msg.sender] = true;
    }

    function addProposal(address _recipient, bytes calldata _signature, string calldata _description) 
        external override onlyChairPerson {
        proposals[count].signature = _signature;
        proposals[count].description = _description;
        proposals[count].recipient = _recipient;
        proposals[count].endAt = block.timestamp + debatingPeriodDuration;
        proposals[count].inProgress = true;
        emit AddProposal(count++);
    }

    function vote(uint128 _id, bool _choice) external override isExist(_id) {
        require(proposals[_id].endAt > block.timestamp,
                "voting is over");
        require(!proposals[_id].voted[msg.sender], "already voted or delegated");
        uint256 tokens = staking.getBalance(msg.sender) + proposals[_id].delegatedTokens[msg.sender];
        require(tokens > 0, "voting tokens are 0");

        proposals[_id].voted[msg.sender] = true;
        if (_choice) {
            proposals[_id].trueVotes += tokens;
        } else {
            proposals[_id].falseVotes += tokens;
        }
        proposals[_id].members.push(msg.sender);
        participations[msg.sender]++;
    }

    function finishProposal(uint128 _id) external override isExist(_id) {
        require(proposals[_id].endAt < block.timestamp,
                "voting in progress");
        require(proposals[_id].inProgress, "voting is finished");
        proposals[_id].inProgress = false;
        if (proposals[_id].trueVotes + proposals[_id].falseVotes >= minimumQuorum) {
            if (proposals[_id].trueVotes > proposals[_id].falseVotes) {
                (bool success, ) = proposals[_id].recipient
                                        .call{value: 0}(proposals[_id].signature);
                emit CallStatus(_id, success);
            } else {
                emit ProposalRejected(_id);
            }
        } else {
            emit MinimumQuorumNotReached(_id);
        }

        address[] memory members = proposals[_id].members;
        for (uint256 i = 0; i < members.length; i++) {
            participations[members[i]]--;
        }
    }

    function getSignature(uint128 _proposalId) external override view isExist(_proposalId) 
        returns (bytes memory) {
        return proposals[_proposalId].signature;
    }

    function getDescription(uint128 _proposalId) external override view isExist(_proposalId) 
        returns (string memory) {
        return proposals[_proposalId].description;
    }

    function getVotes(uint128 _proposalId, bool _val) external override view isExist(_proposalId) 
        returns (uint256) {
        if (_val) {
            return proposals[_proposalId].trueVotes;
        } else {
            return proposals[_proposalId].falseVotes;
        }
    }

    function getRecipient(uint128 _proposalId) external override view isExist(_proposalId) 
        returns (address) {
        return proposals[_proposalId].recipient;
    }

    function getParticipationsCount(address _user) external override view returns (uint256) {
        return participations[_user];
    }

    modifier onlyChairPerson() {
        require(msg.sender == chairPerson, "not a chair person");
        _;
    }

    modifier isExist(uint256 _proposalId) {
        require(_proposalId < count, "not exist");
        _;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IDAO {
    function delegate(uint128 _proposalId, address _to) external;
    function addProposal(address _recipient, 
                        bytes calldata _signature, string calldata _description) external;
    function vote(uint128 _proposalId, bool _choice) external;
    function finishProposal(uint128 _proposalId) external;

    function getSignature(uint128 _proposalId) external returns (bytes memory);
    function getDescription(uint128 _proposalId) external returns (string memory);
    function getVotes(uint128 _proposalId, bool _val) external returns (uint256);
    function getRecipient(uint128 _proposalId) external returns (address);
    function getParticipationsCount(address _user) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

interface IStaking {
    function stake(uint256 _amount) external;
    function claim(uint64 _id) external;
    function unstake(uint64 _id) external;
    function getBalance(address _user) external view returns (uint256);
    function setTimeToUnstake(uint64 _timeToUnstake) external;
    function setDao(address _dao) external;
    function getDao() external view returns(address);
    function getTimeToUnstake() external view returns (uint64);
}