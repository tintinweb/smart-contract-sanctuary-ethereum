// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

import "./interfaces/IERC20.sol";
import "./interfaces/INFTHolder.sol";


contract DepositToken is IERC20 {

    string public name;
    string public symbol;
    uint8 public constant decimals = 18;

    mapping(address => mapping(address => uint256)) public override allowance;

    ILpDepositor public depositor;
    address public pool;

    constructor() {
        // set to prevent the implementation contract from being initialized
        pool = address(0xdead);
    }

    /**
        @dev Initializes the contract after deployment via a minimal proxy
     */
    function initialize(address _pool) external returns (bool) {
        require(pool == address(0));
        pool = _pool;
        depositor = ILpDepositor(msg.sender);
        string memory _symbol = IERC20(pool).symbol();
        name = string(abi.encodePacked("Monolith ", _symbol, " Deposit"));
        symbol = string(abi.encodePacked("mo-", _symbol));
        return true;
    }

    function balanceOf(address account) external view returns (uint256) {
        return depositor.userBalances(account, pool);
    }

    function totalSupply() external view returns (uint256) {
        return depositor.totalBalances(pool);
    }

    function approve(address _spender, uint256 _value) external override returns (bool) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /** shared logic for transfer and transferFrom */
    function _transfer(address _from, address _to, uint256 _value) internal {
        if (_value > 0) {
            depositor.transferDeposit(pool, _from, _to, _value);
        }
        emit Transfer(_from, _to, _value);
    }

    /**
        @notice Transfer tokens to a specified address
        @param _to The address to transfer to
        @param _value The amount to be transferred
        @return Success boolean
     */
    function transfer(address _to, uint256 _value) public override returns (bool) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @notice Transfer tokens from one address to another
        @param _from The address which you want to send tokens from
        @param _to The address which you want to transfer to
        @param _value The amount of tokens to be transferred
        @return Success boolean
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        override
        returns (bool)
    {
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance");
        if (allowance[_from][msg.sender] != type(uint).max) {
            allowance[_from][msg.sender] -= _value;
        }
        _transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev Only callable ty `LpDepositor`. Used to trigger a `Transfer` event
             upon deposit of LP tokens, to aid accounting in block explorers.
     */
    function mint(address _to, uint256 _value) external returns (bool) {
        require(msg.sender == address(depositor));
        emit Transfer(address(0), _to, _value);
        return true;
    }

    /**
        @dev Only callable ty `LpDepositor`. Used to trigger a `Transfer` event
             upon withdrawal of LP tokens, to aid accounting in block explorers.
     */
    function burn(address _from, uint256 _value) external returns (bool) {
        require(msg.sender == address(depositor));
        emit Transfer(_from, address(0), _value);
        return true;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
 *
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
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

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

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

    function mint(address _to, uint256 _value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

interface ILpDepositor {
    function tokenID() external view returns (uint256);

    function setTokenID(uint256 tokenID) external returns (bool);

    function userBalances(address user, address pool)
        external
        view
        returns (uint256);

    function totalBalances(address pool) external view returns (uint256);

    function transferDeposit(
        address pool,
        address from,
        address to,
        uint256 amount
    ) external returns (bool);

    function votingWindow() external returns (uint256);

    function enterSplitMode(uint256 workTimeLimit) external;

    function detachGauges(address[] memory gaugeAddresses) external;

    function reattachGauges(address[] memory gaugeAddresses) external;
}