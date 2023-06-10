// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.17;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(
        address owner,
        address spender
    ) external view returns (uint256);

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

// File: contracts/KRKite_PreLaunchSale.sol

contract KRKite_PresaleOne {
    //Administration Details
    address public admin;
    address payable public KRKiteDevWallet;

    //Token
    IERC20 public token;

    //Presale Details
    uint public tokenPrice = 0.000000001 ether;
    uint public hardCap = 5000000 ether;
    uint public raisedAmount;
    uint public minInvestment = 0.000000001 ether;
    uint public maxInvestment = 5000000 ether;
    uint public presaleStartTime;
    uint public presaleEndTime;

    //Investor
    mapping(address => uint) public investedAmountOf;

    //Presale State
    enum State {
        PENDING,
        INPROGRESS,
        FINISHED,
        HALTED
    }
    State public PresaleState;

    //Events
    event Invest(
        address indexed from,
        address indexed to,
        uint value,
        uint tokens
    );
    event TokenBurn(address to, uint amount, uint time);

    //Initialize Variables
    // constructor(address tokenAddress) {
    //     address payable kRKiteDevWallet = payable(
    //         msg.sender //NTC //need to make it dynamic
    //     );
    //     KRKiteDevWallet = kRKiteDevWallet;
    //     admin = 0xB9FDf25E7f1762aBB48c7feD7C289237015c6FC5; //NTC
    //     token = IERC20(tokenAddress); //NTC
    // }
    constructor(address tokenAddress) {
        address payable kRKiteDevWallet = payable(
            msg.sender //NTC //need to make it dynamic
        );
        KRKiteDevWallet = kRKiteDevWallet;
        admin = 0xB9FDf25E7f1762aBB48c7feD7C289237015c6FC5; //NTC
        token = IERC20(tokenAddress); //NTC
        presaleStartTime = block.timestamp;
        presaleEndTime = presaleStartTime + (86400 * 7);
        PresaleState = State.INPROGRESS;
    }

    //Access Control
    modifier onlyAdmin() {
        require(msg.sender == admin, "Admin Only function");
        _;
    }

    //Receive Ether Directly
    receive() external payable {
        invest();
    }

    fallback() external payable {
        invest();
    }

    /* Functions */

    //Get Presale State
    function getPresaleState() external view returns (string memory) {
        if (PresaleState == State.PENDING) {
            return "Not Started";
        } else if (PresaleState == State.INPROGRESS) {
            return "Running";
        } else if (PresaleState == State.FINISHED) {
            return "End";
        } else {
            return "Halted";
        }
    }

    //Get Presale End Date
    function getPresaleEndDate() public view returns (uint) {
        require(
            PresaleState == State.INPROGRESS,
            "Presale isn't in running state"
        );
        return presaleEndTime;
    }

    /* Admin Functions */
    //Set End Date Presale
    function extendEndDatePresale(uint daysToExtend) external onlyAdmin {
        require(
            PresaleState == State.INPROGRESS,
            "Presale isn't in running state"
        );
        presaleEndTime = presaleEndTime + daysToExtend;
        PresaleState = State.INPROGRESS;
    }

    //Start, Halt and End Presale
    function startPresale() external onlyAdmin {
        require(
            PresaleState == State.PENDING,
            "Presale isn't in pending state"
        );

        presaleStartTime = block.timestamp;
        presaleEndTime = presaleStartTime + (86400 * 7);
        PresaleState = State.INPROGRESS;
    }

    function haltPresale() external onlyAdmin {
        require(PresaleState == State.INPROGRESS, "Presale isn't running yet");
        PresaleState = State.HALTED;
    }

    function resumePresale() external onlyAdmin {
        require(PresaleState == State.HALTED, "Presale State isn't halted yet");
        PresaleState = State.INPROGRESS;
    }

    //Change Presale Wallet
    function changePresaleWallet(
        address payable _newPresaleWallet
    ) external onlyAdmin {
        KRKiteDevWallet = _newPresaleWallet;
    }

    //Change Admin
    function changeAdmin(address _newAdmin) external onlyAdmin {
        admin = _newAdmin;
    }

    /* User Function */
    //Invest
    function invest() public payable returns (bool) {
        require(PresaleState == State.INPROGRESS, "Presale isn't open yet");
        require(
            msg.value >= minInvestment && msg.value <= maxInvestment,
            "Check Min and Max Investment"
        );
        require(
            investedAmountOf[msg.sender] + msg.value <= maxInvestment,
            "Investor reached maximum Investment Amount"
        );

        require(raisedAmount + msg.value <= hardCap, "Send within range");
        require(
            block.timestamp <= presaleEndTime,
            "Presale already Reached Maximum time limit"
        );

        raisedAmount += msg.value;
        investedAmountOf[msg.sender] += msg.value;

        (bool transferSuccess, ) = KRKiteDevWallet.call{value: msg.value}("");
        require(transferSuccess, "Failed to Invest");

        uint tokens = (msg.value / tokenPrice) ;//* 1e18; 
        bool saleSuccess = token.transfer(msg.sender, tokens);
        // bool saleSuccess = IERC20(token).transferFrom(
        //     msg.sender,
        //     address(KRKiteDevWallet),
        //     tokens
        // );
        require(saleSuccess, "Failed to Invest");

        emit Invest(address(this), msg.sender, msg.value, tokens);
        return true;
    }

    //Burn Tokens
    function burn() external returns (bool) {
        require(PresaleState == State.FINISHED, "Presale isn't over yet");

        uint remainingTokens = token.balanceOf(address(this));
        bool success = token.transfer(address(0), remainingTokens);
        require(success, "Failed to burn remaining tokens");

        emit TokenBurn(address(0), remainingTokens, block.timestamp);
        return true;
    }

    //End Presale After reaching Hardcap or Presale Timelimit
    function endPresale() public {
        require(
            PresaleState == State.INPROGRESS,
            "Presale Should be in Running State"
        );
        require(
            block.timestamp > presaleEndTime || raisedAmount >= hardCap,
            "Presale Hardcap or time limit not reached"
        );
        PresaleState = State.FINISHED;
    }

    //Check Presale Contract Token Balance
    function getPresaleTokenBalance() external view returns (uint) {
        return token.balanceOf(address(this));
    }

    //Check Presale Contract Investor Token Balance
    function investorBalanceOf(address _investor) external view returns (uint) {
        return token.balanceOf(_investor);
    }
}