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

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Web3Jobs {
    enum Stage {
        SCREENING,
        FIRST_INTERVIEW,
        TECHNICAL_TEST,
        FINAL_INTERVIEW,
        HIRED,
        REJECTED
    }

    struct Bounty {
        IERC20 token;
        uint256 amount;
    }

    struct Job {
        bytes32 jobId;
        address employer;
        address[] applicants;
        Bounty bounty;
    }

    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;

    mapping(bytes32 => Job) public Jobs;
    mapping(address => mapping(bytes32 => Stage[2])) public Applicants;
    mapping(address => bytes32[]) public Employers;
    mapping(address => mapping(IERC20 => uint256)) public ERC20BountyBalances;

    event JobPublished(
        bytes32 indexed jobId,
        address indexed employer,
        uint256 indexed bountyAmount
    );
    event JobUnpublished(bytes32 indexed jobId, address indexed employer);

    function publishJob(
        bytes32 jobId,
        uint256 bountyAmount,
        IERC20 token
    ) external payable {
        uint256 amount;

        if (msg.value != 0) {
            require(
                bountyAmount == 0 && token == IERC20(address(0)),
                "Only a single currency can be used for bounty"
            );
            amount = msg.value;
        } else {
            require(
                bountyAmount != 0 && token != IERC20(address(0)),
                "Wrong amount or token provided for bounty"
            );

            amount = bountyAmount;
            require(
                token.transfer(address(this), bountyAmount),
                "Failed to send ERC20 bounty to contract for custody"
            );
            ERC20BountyBalances[msg.sender][token] += bountyAmount;
        }

        address[] memory applicants;
        Bounty memory bounty = Bounty(token, amount);
        Jobs[jobId] = Job(jobId, msg.sender, applicants, bounty);

        Employers[msg.sender].push(jobId);

        emit JobPublished(jobId, msg.sender, amount);
    }

    function unpublishJob(bytes32 jobId) external {
        require(
            Jobs[jobId].employer == msg.sender,
            "Offer doesn't exist or you're not the employer"
        );
        delete Jobs[jobId];

        Bounty memory bounty = Jobs[jobId].bounty;
        ERC20BountyBalances[msg.sender][bounty.token] -= bounty.amount;
        require(
            (bounty.token).transfer(msg.sender, bounty.amount),
            "Failed to send ERC20 bounty to employer"
        );

        emit JobUnpublished(jobId, msg.sender);
    }

    event BountyClaimed(
        bytes32 indexed jobId,
        address indexed applicant,
        uint256 indexed amount,
        bool isEther
    );

    function newApplication(bytes32 jobId) public {
        require(
            !applicantExists(jobId),
            "You have already made an application"
        );
        Jobs[jobId].applicants.push(msg.sender);

        Stage[2] memory stage;
        stage[0] = Stage.SCREENING;
        Applicants[msg.sender][jobId] = stage;
    }

    function getMyApplicants(bytes32 jobId)
        external
        view
        returns (address[] memory)
    {
        return Jobs[jobId].applicants;
    }

    function changeApplicationStatus(
        address applicant,
        bytes32 jobId,
        uint8 status
    ) external {
        require(
            Jobs[jobId].employer == msg.sender,
            "Offer doesn't exist or you're not the employer"
        );
        (Applicants[applicant][jobId])[1] = (Applicants[applicant][jobId])[0];
        (Applicants[applicant][jobId])[0] = Stage(status);
    }

    function claimBounty(bytes32 jobId) external {
        require(
            (Applicants[msg.sender][jobId])[0] == Stage.REJECTED &&
                (Applicants[msg.sender][jobId])[1] == Stage.FINAL_INTERVIEW,
            "Not eligible for claiming bounty"
        );

        // TODO: Bounty can only be claimed upon employer approval

        bool isEther;
        Bounty memory bounty = Jobs[jobId].bounty;

        uint256 numberOfEligible = getEligible(jobId);
        uint256 bountySlice = bounty.amount / numberOfEligible;

        if (bounty.token == IERC20(address(0))) {
            (bool success, ) = address(this).call{value: bountySlice}("");
            require(success, "Failed to send Ether");
            isEther = true;
        } else {
            address employer = Jobs[jobId].employer;
            ERC20BountyBalances[employer][bounty.token] -= bountySlice;
            require(
                (bounty.token).transfer(msg.sender, bountySlice),
                "Failed to send ERC20 bounty to applicant"
            );
        }

        emit BountyClaimed(jobId, msg.sender, bountySlice, isEther);
    }

    function applicantExists(bytes32 jobId) internal view returns (bool) {
        address[] memory applicants = Jobs[jobId].applicants;
        for (uint256 i; i < applicants.length; i++) {
            if (applicants[i] == msg.sender) return true;
        }
        return false;
    }

    function getEligible(bytes32 jobId) internal view returns (uint256) {
        address[] memory applicants = (Jobs[jobId].applicants);

        uint256 eligible;
        for (uint256 i; i < applicants.length; i++) {
            if (
                (Applicants[applicants[i]][jobId])[0] == Stage.REJECTED &&
                (Applicants[applicants[i]][jobId])[1] == Stage.FINAL_INTERVIEW
            ) eligible += 1;
        }

        return eligible;
    }
}