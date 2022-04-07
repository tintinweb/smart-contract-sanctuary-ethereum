// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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

contract Trust {
    struct Beneficiary {
        address grantor;
        uint256 beneficiaryIndex;
        uint256 balanceToRecieve;
        uint256 timeUntilRelease;
        bool tokensPaid;
    }

    struct Grantor {
        address beneficiary;
        uint256 grantorIndex;
        uint256 balanceToGive;
        uint256 timeUntilRelease;
        bool beneficiaryPaid;
    }
    mapping(address => Beneficiary) public beneficiaries;
    mapping(address => Grantor) public grantors;

    event AddedBeneficiary(
        address beneficiary,
        uint256 timeUntilRelease,
        uint256 amount
    );
    event WithdrewFunds(address beneficiary, uint256 amount);

    uint256 public fundCount;
    address public manager;
    IERC20 public wethToken;

    constructor(address _wethToken) {
        manager = msg.sender;
        fundCount = 1;
        wethToken = IERC20(_wethToken);
    }

    modifier onlyManager() {
        require(msg.sender == manager);
        _;
    }

    function addBeneficiary(
        address _beneficiary,
        uint256 _timeUntilRelease,
        uint256 _balanceToGive
    ) public {
        require(
            _beneficiary != address(0),
            "Beneficiary address cannot be a zero address."
        );
        require(
            _timeUntilRelease > 0,
            "Time until fund release must be more than zero."
        );
        require(
            _balanceToGive > 0,
            "The amount you're locking up for the beneficiary must be more than zero."
        );

        grantors[msg.sender] = Grantor(
            _beneficiary,
            fundCount,
            _balanceToGive,
            _timeUntilRelease,
            false
        );
        beneficiaries[_beneficiary] = Beneficiary(
            msg.sender,
            fundCount,
            _balanceToGive,
            _timeUntilRelease,
            false
        );

        wethToken.transferFrom(msg.sender, address(this), _balanceToGive);
        emit AddedBeneficiary(_beneficiary, _timeUntilRelease, _balanceToGive);
    }

    function withdrawFunds() external {
        for (uint256 index = 1; index <= fundCount; index++) {
            if (beneficiaries[msg.sender].beneficiaryIndex == index) {
                uint256 _amountToRecieve = beneficiaries[msg.sender]
                    .balanceToRecieve;
                uint256 _timeUntilRelease = beneficiaries[msg.sender]
                    .timeUntilRelease;

                require(
                    _timeUntilRelease < block.timestamp,
                    "It's not time to release your funds."
                );

                require(_amountToRecieve > 0, "There are no funds to recieve.");

                beneficiaries[msg.sender].tokensPaid = true;
                beneficiaries[msg.sender].balanceToRecieve = 0;
                address grantorAddress = beneficiaries[msg.sender].grantor;
                grantors[grantorAddress].beneficiaryPaid = true;
                grantors[grantorAddress].balanceToGive = 0;
                wethToken.transferFrom(
                    address(this),
                    msg.sender,
                    _amountToRecieve
                );
                emit WithdrewFunds(msg.sender, _amountToRecieve);
            }
        }
    }
}