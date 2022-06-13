// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BridgeAssist {
    IERC20 public erc20;

    struct Lock {
        uint256 amount;
        string targetAddr;
    }

    address public mainBackend;
    address public feeAddress;
    mapping(address => bool) public isBackend;

    mapping(address => Lock) locks;

    event Upload(address indexed account, uint256 indexed amount, string indexed target);
    event Dispense(address indexed account, uint256 indexed amount, uint256 indexed fee);

    modifier onlyBackend() {
        require(
            isBackend[msg.sender],
            "This function is restricted to backend"
        );
        _;
    }

    modifier onlyMainBackend() {
        require(
            msg.sender == mainBackend,
            "This function is restricted to the main backend"
        );
        _;
    }

    /**
     * @param _erc20 ERC-20/BEP-20 token
     * @param _feeAddress ETH/BSC fee wallet address
     * @param _mainBackend Main backend ETH/BSC wallet address
     */
    constructor(IERC20 _erc20, address _feeAddress, address _mainBackend) {
        erc20 = _erc20;
        feeAddress = _feeAddress;
        mainBackend = _mainBackend;
        isBackend[_mainBackend] = true;
    }

    /**
     * @notice Locking tokens on the bridge to swap in the direction of ETH/BSC->Solana
     * @dev Creating lock structure and transferring the number of tokens to the bridge address
     * @param _amount Number of tokens to swap
     * @param _target Solana wallet address
     */
    function upload(uint256 _amount, string memory _target) external {
        require(_amount > 0, "Amount should be more than 0");
        require(
            locks[msg.sender].amount == 0,
            "Your current lock is not equal to 0"
        );

        erc20.transferFrom(msg.sender, address(this), _amount);
        locks[msg.sender].amount = _amount;
        locks[msg.sender].targetAddr = _target;
        emit Upload(msg.sender, _amount, _target);
    }

    /**
     * @notice Dispensing tokens from the bridge by the backend to swap in the direction of Solana->ETH/BSC
     * @param _account ETH/BSC wallet address
     * @param _amount Number of tokens to dispense
     * @param _fee Fee amount
     */
    function dispense(address _account, uint256 _amount, uint256 _fee) external onlyBackend {
        erc20.transfer(_account, _amount);
        erc20.transfer(feeAddress, _fee);
        emit Dispense(_account, _amount, _fee);
    }

    /**
     * @notice Backend function to clear user lock in the swap token process
     * @param _account ETH/BSC wallet address
     */
    function clearLock(address _account) external onlyBackend {
        locks[_account].amount = 0;
        locks[_account].targetAddr = "";
    }

    /**
     * @notice Adding new backend addresses
     * @param _backend Backend ETH/BSC wallet addresses
     */
    function addBackend(address[] calldata _backend) external onlyMainBackend {
        require(_backend.length <= 100, "Array size should be less than or equal to 100");
        for (uint256 i = 0; i < _backend.length; ++i) {
            isBackend[_backend[i]] = true;
        }
    }

    /**
     * @notice Removing backend addresses
     * @param _backend Backend ETH/BSC wallet addresses
     */
    function removeBackend(address[] calldata _backend) external onlyMainBackend {
        require(_backend.length <= 100, "Array size should be less than or equal to 100");
        for (uint256 i = 0; i < _backend.length; ++i) {
            isBackend[_backend[i]] = false;
        }
    }

    /**
     * @notice Changing fee address
     * @param _feeAddress ETH/BSC fee wallet address
     */
    function changeFeeAddress(address _feeAddress) external onlyMainBackend {
        feeAddress = _feeAddress;
    }

    /**
     * @notice Viewing the lock structure for the user
     * @dev This function is used for the verfication of uploading tokens
     * @param _account BSC wallet address
     * @return userLock Lock structure for the user
     */
    function checkUserLock(address _account)
        external
        view
        returns (Lock memory userLock)
    {
        userLock.amount = locks[_account].amount;
        userLock.targetAddr = locks[_account].targetAddr;
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