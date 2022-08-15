// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./TokenTimeLockedWallet.sol";

contract TimeLockedWalletFactory {
    mapping(address => address[]) wallets;

    function getWallets(address _user) public view returns (address[] memory) {
        return wallets[_user];
    }

    function newTimeLockedWallet(
        address _owner,
        uint256[] memory _lockTimeFrames,
        uint256[] memory _lockAmounts
    ) public returns (address wallet) {
        // Create new wallet.
        wallet = address(
            new TokenTimeLockedWallet(
                msg.sender,
                _owner,
                _lockTimeFrames,
                _lockAmounts
            )
        );

        // Add wallet to sender's wallets.
        wallets[msg.sender].push(wallet);

        // If owner is the same as sender then add wallet to sender's wallets too.
        if (msg.sender != _owner) {
            wallets[_owner].push(wallet);
        }

        // Emit event.
        emit Created(
            wallet,
            msg.sender,
            _owner,
            block.timestamp,
            _lockTimeFrames,
            _lockAmounts
        );
    }

    // Prevents accidental sending of ether to the factory
    fallback() external payable {
        revert("Could not send eth to contract");
    }

    receive() external payable {
        revert("Could not send eth to contract");
    }

    event Created(
        address wallet,
        address from,
        address to,
        uint256 createdAt,
        uint256[] lockTimeFrames,
        uint256[] lockAmounts
    );
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenTimeLockedWallet {
    struct LockLevel {
        uint256 unlockTime;
        uint256 amount;
        bool isWithdraw;
    }

    address public creator;
    address public owner; //beneficiary
    uint256 public createdAt;

    LockLevel[] internal locks;

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Caller is not creator");
        _;
    }

    constructor(
        address _creator,
        address _owner,
        uint256[] memory _lockTimeFrames,
        uint256[] memory _lockAmounts
    ) {
        // verify unlock time
        require(_lockTimeFrames.length > 0, "Invalid lock periods");
        require(
            _lockTimeFrames.length == _lockAmounts.length,
            "Unlock period and amount defined is not the same"
        );

        creator = _creator;
        owner = _owner;
        createdAt = block.timestamp;

        for (uint256 idx = 0; idx < _lockTimeFrames.length; idx++)
            locks.push(
                LockLevel(_lockTimeFrames[idx], _lockAmounts[idx], false)
            );
    }

    function addNewLock(uint256 _lockTimeFrame, uint256 _unlockAmount)
        public
        onlyCreator
        returns (bool)
    {
        locks.push(LockLevel(_lockTimeFrame, _unlockAmount, false));

        return true;
    }

    // callable by owner only, after specified time, only for Tokens implementing ERC20
    function withdrawTokens(address _tokenContract)
        public
        onlyOwner
        returns (bool)
    {
        require(_tokenContract != address(0), "Invalid token contract");

        // calculate amount token can withdraw
        IERC20 token = IERC20(_tokenContract);
        uint256 currentTime = block.timestamp;
        for (uint256 idx; idx < locks.length; idx++) {
            if (
                locks[idx].unlockTime <= currentTime && !locks[idx].isWithdraw
            ) {
                //now send all the token balance
                uint256 tokenBalance = token.balanceOf(address(this));
                uint256 desiredAmount = locks[idx].amount;
                uint256 withdrawToken = desiredAmount > tokenBalance
                    ? tokenBalance
                    : desiredAmount;

                if (withdrawToken != 0) {
                    locks[idx].isWithdraw = true;
                    token.transfer(owner, withdrawToken);
                    emit WithdrewTokens(
                        _tokenContract,
                        msg.sender,
                        withdrawToken
                    );
                }
            }
        }

        return true;
    }

    function info()
        public
        view
        returns (
            address,
            address,
            uint256,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        uint256 len = locks.length;
        uint256[] memory unlockTimeFrames = new uint256[](len);
        uint256[] memory unLockAmounts = new uint256[](len);
        bool[] memory isWithdraw = new bool[](len);
        for (uint256 idx = 0; idx < len; idx++) {
            unlockTimeFrames[idx] = locks[idx].unlockTime;
            unLockAmounts[idx] = locks[idx].amount;
            isWithdraw[idx] = locks[idx].isWithdraw;
        }

        return (
            creator,
            owner,
            createdAt,
            unlockTimeFrames,
            unLockAmounts,
            isWithdraw
        );
    }

    event WithdrewTokens(address tokenContract, address to, uint256 amount);
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