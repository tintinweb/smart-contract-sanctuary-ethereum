pragma solidity ^0.8.0;

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.)
     */
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract OptionChest {
    uint256 public totalPayment;
    address public recipient;
    uint256 public timelockStart;
    address public optionAddress;
    uint256 public timestampCliff;
    uint256 public timestampDuration;
    uint256 public timestampStart;
    IERC20 public optionToken;
    uint256 public lastWithdraw;
    uint256 public payment;
    address public ownerAddress;

    constructor(
        uint256 _totalPayment,
        address _recipient,
        uint256 _timelockStart,
        address _optionAddress,
        uint256 _timestampCliff,
        uint256 _timestampDuration,
        address _ownerAddress
    ) {
        totalPayment = _totalPayment;
        recipient = _recipient;
        timelockStart = _timelockStart;
        optionAddress = _optionAddress;
        timestampCliff = _timestampCliff;
        timestampDuration = _timestampDuration;
        payment = totalPayment;
        ownerAddress = _ownerAddress;
        timestampStart = block.timestamp;
    }

    event funded(address funded, uint256 amount, address token);
    event withdrawn(address funded, address token);
    event terminated(address funded, address token);
    event newrecipient_(address _address);
    event newowner_(address _address);

    function fund(uint256 amount) public {
        require(msg.sender == ownerAddress, "Not owner");
        optionToken.transferFrom(msg.sender, address(this), amount);
        totalPayment += amount;
        emit funded(recipient, amount, address(optionToken));
    }

    function terminate() public {
        require(msg.sender == ownerAddress, "Not owner");
        if (block.timestamp <= timestampDuration) {
            optionToken.transfer(
                msg.sender,
                (totalPayment * (block.timestamp - timestampStart)) /
                    (timestampDuration - timestampStart) -
                    payment
            );
            lastWithdraw = block.timestamp;
            payment +=
                (totalPayment * (block.timestamp - timestampStart)) /
                (timestampDuration - timestampStart) -
                payment;
        } else {
            optionToken.transfer(msg.sender, totalPayment - payment);

            totalPayment = payment;
        }
        emit terminated(recipient, address(optionToken));
    }

    function newrecipient(address addrs) public {
        require(msg.sender == recipient, "Not recipient");
        recipient = addrs;
        emit newrecipient_(addrs);
    }

    function newowner(address addrs) public {
        require(msg.sender == ownerAddress, "Not owner");
        ownerAddress = addrs;
        emit newowner_(addrs);
    }

    function amountowed() public view returns (uint256) {
        return ((totalPayment * (block.timestamp - timestampStart)) /
            (timestampDuration - timestampStart) -
            payment);
    }

    function withdraw() public {
        require(msg.sender == recipient, "Not recipient");
        require(block.timestamp >= timestampCliff, "Not ready");
        if (block.timestamp <= timestampDuration) {
            optionToken.transfer(
                msg.sender,
                (totalPayment * (block.timestamp - timestampStart)) /
                    (timestampDuration - timestampStart) -
                    payment
            );
            payment +=
                (totalPayment * (block.timestamp - timestampStart)) /
                (timestampDuration - timestampStart) -
                payment;
        } else {
            optionToken.transfer(msg.sender, (totalPayment - payment));
            payment += totalPayment;
        }
        lastWithdraw = block.timestamp;
        emit withdrawn(msg.sender, address(optionToken));
    }
}