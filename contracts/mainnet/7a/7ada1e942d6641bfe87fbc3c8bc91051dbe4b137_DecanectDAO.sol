/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

}

interface IERC1155 {
    function balanceOf(address, uint256) external view returns (uint256);
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function setBurnerAddresses(address [] memory _addresses, bool _status) external;
    function burnFrom(address _address, uint256 amount) external;
}

library Address {

    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

}

library SafeERC20 {

    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract Ownable {

    address internal _owner;
    address internal _newOwner;

    event OwnershipPushed(address indexed previousOwner, address indexed newOwner);
    event OwnershipPulled(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipPushed( address(0), _owner );
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require( _owner == msg.sender, "Ownable: caller is not the owner" );
        _;
    }

    function renounceManagement() public onlyOwner() {
        emit OwnershipPushed( _owner, address(0) );
        _owner = address(0);
        _newOwner = address(0);
    }

    function pushManagement( address newOwner_ ) public onlyOwner() {
        require( newOwner_ != address(0), "Ownable: new owner is the zero address");
        emit OwnershipPushed( _owner, newOwner_ );
        _newOwner = newOwner_;
    }

    function pullManagement() public {
        require( msg.sender == _newOwner, "Ownable: must be new owner to pull");
        emit OwnershipPulled( _owner, _newOwner );
        _owner = _newOwner;
        _newOwner = address(0);
    }
}

contract DecanectDAO is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public nextProposalID = 1;
    uint256 public deadlineBlocks = 100;
    uint256 public voteReward = 5 * 10**6;
    uint256 public DCNTBalanceNeeded = 10000 * 10**9;
    uint256 public constant voteRewardDistributionThreshold = 50 * 10**6;
    IERC20 public rewardToken = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public DCNT = IERC20(0x4Ce4C025692B3142dbdE1cd432ef55b9A8D18701);
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public accumulatedRewards;

    struct Proposal {
        uint256 id;
        string description;
        uint deadline;
        uint256 votesUp;
        uint256 votesDown;
        mapping(address => bool) voteStatus;
        bool countConducted;
        bool passed;
    }

    event ProposalCreated(
        uint256 id,
        string description,
        address proposer
    );

    event NewVote(
        uint256 votesUp,
        uint256 votesDown,
        address voter,
        uint256 proposalID,
        bool votedFor
    );

    event ProposalCounted(
        uint256 id,
        bool passed
    );

    function createProposal(string memory _description) onlyOwner() public {
        Proposal storage newProposal = proposals[nextProposalID];
        newProposal.id = nextProposalID;
        newProposal.description = _description;
        newProposal.deadline = block.number + deadlineBlocks;
        emit ProposalCreated(nextProposalID, _description, msg.sender);
        nextProposalID++;
    }

    function voteOnProposal(uint256 _id, bool _vote) public {
        require(proposals[_id].deadline > 0, "This proposal does not exist");
        require(block.number <= proposals[_id].deadline, "The deadline to vote has passed for this proposal");
        checkVoteEligibility(_id, msg.sender);

        if (_vote) {
            proposals[_id].votesUp = proposals[_id].votesUp.add(1);
        }
        else {
            proposals[_id].votesDown = proposals[_id].votesDown.add(1);
        }

        proposals[_id].voteStatus[msg.sender] = true;
        accumulatedRewards[msg.sender] = accumulatedRewards[msg.sender].add(voteReward);
        if (accumulatedRewards[msg.sender] >= voteRewardDistributionThreshold) {
            uint256 reward = accumulatedRewards[msg.sender];
            accumulatedRewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
        }

        emit NewVote(proposals[_id].votesUp, proposals[_id].votesDown, msg.sender, _id, _vote);

    }

    function countVotes(uint256 _id) public onlyOwner()  {
        require(proposals[_id].deadline > 0, "This proposal does not exist");
        require(block.number > proposals[_id].deadline, "Voting has not concluded");
        require(!proposals[_id].countConducted, "Count already conducted");

        if (proposals[_id].votesDown < proposals[_id].votesUp) {
            proposals[_id].passed = true;
        }

        proposals[_id].countConducted = true;

        emit ProposalCounted(_id, proposals[_id].passed);
    }

    function setDeadlinePeriod(uint256 _deadlineBlocks) public onlyOwner()  {
        deadlineBlocks = _deadlineBlocks;
    }

    function setReward(uint256 _reward) public onlyOwner()  {
        voteReward = _reward;
    }

    function setDCNTBalanceNeeded(uint256 _balance) public onlyOwner()  {
        DCNTBalanceNeeded = _balance;
    }

    function withdrawTokens(address _token, uint256 _amount) public onlyOwner() {
        IERC20(_token).safeTransfer(msg.sender, _amount);
    }

    function checkVoteEligibility(uint256 _id, address _voter) internal view {
        bool isVotedAlready = proposals[_id].voteStatus[_voter];
        bool isDCNTOwned = DCNT.balanceOf(_voter) >= DCNTBalanceNeeded;
        require(!isVotedAlready, "You cannot vote because you voted on this proposal already");
        require(isDCNTOwned, "You cannot vote because the quantity of DCNT you own is not sufficient");
    }

}