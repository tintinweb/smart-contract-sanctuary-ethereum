// SPDX-License-Identifier: MIT
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract LinearVesting {
    IERC20 public token;
    uint256 public start;
    uint256 public duration;
    uint256 public totalVested;
    address public presale;
    event TokensReleased(address indexed beneficiary, uint256 amount);

    mapping(address => uint256) public vested;
    mapping(address => uint256) public released;

    constructor(IERC20 _token, address _presale, uint256 _start, uint256 _duration) {
        token = _token;
        presale = _presale;
        start = _start;
        duration = _duration;
    }

     function emergencyRelease() external {
        require(msg.sender == presale, "Only the Presale contract can call this function");
        uint256 remainingTokens = token.balanceOf(address(this));
        require(remainingTokens > 0, "No tokens to release");
        token.transfer(presale, remainingTokens);
    }

function release() public {
    address beneficiary = msg.sender;
    require(beneficiary != address(0), "No zero address");
    require(vested[beneficiary] > 0, "No vested tokens found for the address");

    uint256 elapsedDays = (block.timestamp - start) / 1 days;
    require(elapsedDays > 14, "Cliff period is not over");

    uint256 totalAvailablePercentage;

    if (elapsedDays <= 120) {
        totalAvailablePercentage = ((elapsedDays - 14) * 100) / 106;
    } else {
        totalAvailablePercentage = 100;
    }

    uint256 totalAvailableAmount = (vested[beneficiary] * totalAvailablePercentage) / 100;
    uint256 amount = totalAvailableAmount - released[beneficiary];

    require(amount > 0, "No tokens to release");

    released[beneficiary] += amount;

    // Emit an event here
    emit TokensReleased(beneficiary, amount);

    // Ensure state changes are completed before external call
    token.transfer(beneficiary, amount);
}



    function addVested(address beneficiary, uint256 amount) external {
        vested[beneficiary] += amount;
        totalVested += amount;
    }
}

contract Presale {
    address payable public owner;
    IERC20 public token;
    uint256 public minContribution;
    uint256 public maxContribution;
    uint256 public softCap;
    uint256 public hardCap;
    uint256 public totalRaised;
    uint256 public tokensPerEth = 10000;
    uint256 public vestingDuration;
    LinearVesting public vesting;
    mapping(address => LinearVesting) public vestingContracts;
    mapping(address => uint256) public contributions;

    event Contribution(address indexed contributor, uint256 amount, uint256 tokens);

    constructor(IERC20 _token, uint256 _tokensPerEth) {
        owner = payable(msg.sender);
        token = _token;
        tokensPerEth = _tokensPerEth;
        vestingDuration = 10 days;

        minContribution = 0 ether;
        maxContribution = 5 ether;
        softCap = 50 ether;
        hardCap = 100 ether;
        vesting = new LinearVesting(token, address(this), block.timestamp, vestingDuration);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    function contribute() external payable {
        require(totalRaised < hardCap, "Presale has reached the hard cap");
        uint256 contribution = msg.value;
        uint256 remainingCap = hardCap - totalRaised;
        if (contribution > remainingCap) {
            contribution = remainingCap;
        }

        require(contribution >= minContribution, "Contribution is below the minimum limit");
        require(contributions[msg.sender] + contribution <= maxContribution, "Contribution exceeds the maximum limit");

        uint256 tokens = (contribution * tokensPerEth) / (10**18);
        require(token.balanceOf(address(this)) >= tokens, "Not enough tokens left");

        contributions[msg.sender] += contribution;
        totalRaised += contribution;

        vesting.addVested(msg.sender, tokens);
        token.transfer(address(vesting), tokens);
        owner.transfer(contribution);

        if (msg.value > contribution) {
            uint256 refund = msg.value - contribution;
            payable(msg.sender).transfer(refund);
        }

        emit Contribution(msg.sender, contribution, tokens);
    }

    function withdrawTokens(uint256 _amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= _amount, "Not enough tokens left");
        token.transfer(owner, _amount);
    }

    function setTokensPerEth(uint256 _tokensPerEth) external onlyOwner {
        tokensPerEth = _tokensPerEth;
    }

    function emergencyRecoverTokens() external onlyOwner {
        vesting.emergencyRelease();
    }

    function releaseTokens() external {
    require(vesting.vested(msg.sender) > 0, "No vested tokens found");
    vesting.release();
}

   
}