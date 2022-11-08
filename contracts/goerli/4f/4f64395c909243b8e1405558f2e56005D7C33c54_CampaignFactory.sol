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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.15;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CampaignFactory {
    struct CreateNewCampaign {
        address addressOfNewCampaign;
        string name;
        uint256 goal;
        uint256 minimumContribution;
        string shortDescription;
        uint32 startAt;
        uint32 endtAt;
    }

    CreateNewCampaign[] public deployedCampaigns;

    function createCampaign(
        uint256 minimum,
        string memory _name,
        uint256 _goal,
        string memory _shortDescription,
        uint32 _startAt,
        uint32 _endAt
    ) public {
        Campaign newCampaign = new Campaign(
            minimum,
            msg.sender,
            _goal,
            _shortDescription,
            _startAt,
            _endAt
        );
        deployedCampaigns.push(
            CreateNewCampaign(
                address(newCampaign),
                _name,
                _goal,
                minimum,
                _shortDescription,
                _startAt,
                _endAt
            )
        );
    }

    function getDeployedCampaigns()
        public
        view
        returns (CreateNewCampaign[] memory)
    {
        return deployedCampaigns;
    }
}

contract Campaign {
    IERC20 public immutable daiToken;

    struct Request {
        string description;
        uint256 value;
        address recipient;
        bool complete;
        uint256 approvalCount;
    }

    mapping(address => mapping(uint256 => bool)) approvals;

    Request[] public requests;
    address public manager;
    uint256 public minimumContribution;
    uint256 public goal;
    uint256 public pledged;
    mapping(address => uint256) public approvers; //contributers of the campaign become approvers
    uint256 public approversCount;
    string public shortDescription;
    uint32 public startAt;
    uint32 public endAt;

    modifier restricted() {
        require(msg.sender == manager);
        _;
    }

    constructor(
        uint256 minimum,
        address creator,
        uint256 _goal,
        string memory _shortDescription,
        uint32 _startAt,
        uint32 _endAt
    ) {
        manager = creator;
        minimumContribution = minimum;
        goal = _goal;
        shortDescription = _shortDescription;
        startAt = _startAt;
        endAt = _endAt;
        daiToken = IERC20(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
    }

    function contribute(uint256 _amount) public {
        require(
            _amount > minimumContribution,
            "amount should be > minimum contribution"
        );
        require(block.timestamp >= startAt, "not started");
        require(block.timestamp <= endAt, "ended");

        // transfer Dai to this contract for the crowdfunding
        daiToken.transferFrom(msg.sender, address(this), _amount);

        // update contributers balance
        approvers[msg.sender] = _amount;
        approversCount++;
        pledged += _amount;
    }

    function refund() external {
        require(block.timestamp > endAt, "not ended");
        require(pledged < goal, "pledged >= goal");
        require(approvers[msg.sender] > 0);

        uint256 bal = approvers[msg.sender];
        approvers[msg.sender] = 0;
        daiToken.transfer(msg.sender, bal);

        //emit Refund(_id, msg.sender, bal);
    }

    function createRequest(
        string memory description,
        uint256 value,
        address recipient
    ) public restricted {
        Request memory newRequest = Request({
            description: description,
            value: value,
            recipient: recipient,
            complete: false,
            approvalCount: 0
        });

        requests.push(newRequest);
    }

    function approveRequest(uint256 index) public {
        Request storage request = requests[index];

        require(approvers[msg.sender] > 0);
        require(approvals[msg.sender][index] == false);

        approvals[msg.sender][index] = true;
        request.approvalCount++;
    }

    function finalizeRequest(uint256 index) public restricted {
        Request storage request = requests[index];

        require(request.approvalCount > (approversCount / 2));
        require(!request.complete);

        payable(request.recipient).transfer(request.value);

        request.complete = true;
    }

    function getSummary()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            address
        )
    {
        return (
            minimumContribution,
            address(this).balance,
            requests.length,
            approversCount,
            manager
        );
    }

    function getRequestsCount() public view returns (uint256) {
        return requests.length;
    }

    function getRequests() public view returns (Request[] memory) {
        return requests;
    }
}