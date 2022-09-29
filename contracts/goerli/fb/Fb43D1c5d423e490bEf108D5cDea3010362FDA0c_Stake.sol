//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./interfaces/IERC20.sol";
import "./Pausable.sol";

contract Stake is Pausable {
    address kol = 0x303f5C384610A1750007C7910F28731d4A9f031c; //0x73e023dE4ce3647c89E977D19a6bd521706ac23f;
    address owner = 0xB4eA3D4F74520Fc11fF14810D8219FE309a0c265;

    constructor() {
        emit cycleStarted(block.timestamp);
    }

    mapping(address => uint256) public _balances;
    mapping(bytes32 => bool) public isUnique;
    event tokenStaked(address staker, uint256 amount, uint256 totStaked, uint256 stakedAt);
    event withDrawn(address withDrawer, uint256 amount, uint256 remainingAmount, uint256 withdrawnAt);
    event claimedReward(address[] tokens, bytes32[] amounts, address recever, uint256 claimedAt, bytes sig);
    event cycleStarted(uint256 cycleStartedAt);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function addKolToken(address _kol) public onlyOwner {
        kol = _kol;
    }

    function updateOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    /**
     * @notice Stake KOL tokens.
     * @dev  transfer KOL tokens from msg.sender to this contract
     * @param token - kol token address
     * @param amount - number of tokens to stake
     * Emits a {tokenStaked} event.
     */

    function stakeTokens(address token, uint256 amount) external whenNotPaused {
        require(token == kol, "Not KOL Token");
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        _balances[msg.sender] += amount;
        emit tokenStaked(msg.sender, amount, _balances[msg.sender], block.timestamp);
    }

    /**
     * @notice withdraw staked KOL tokens.
     * @dev  transfer KOL tokens from this contract to msg.sender
     * checks amount <= staked tokens
     * @param token - kol token address
     * @param amount - number of tokens to stake
     * Emits a {withDrawn} event.
     */

    function unstake(address token, uint256 amount) external {
        require(token == kol, "Not KOL TOKEN");
        require(amount > 0 && amount <= _balances[msg.sender], "Invalid Amount");
        _balances[msg.sender] -= amount;
        IERC20(token).transfer(msg.sender, amount);
        emit withDrawn(msg.sender, amount, _balances[msg.sender], block.timestamp);
    }

    /**
     * @notice Staker claim reward tokens.
     * @dev  encodePacked the tokens, amounts & recever address
     * verify that encoded data against claimed signature
     * if claimed signature matches the actual signer
     * reward will be claimed else revert the transaction
     * each time claimed signature must be unique
     * @param tokens - reward token addresses
     * @param amounts - amount array for reward
     * @param rcv - reward reciever address
     * @param claimedSig - signature for claiming reward
     * Emits a {tokenStaked} event.
     */

    function claimReward(
        address[] calldata tokens,
        bytes32[] calldata amounts,
        address rcv,
        bytes calldata claimedSig
    ) external {
        bytes memory encodedData = encodeTightlyPacked(tokens, amounts, block.chainid, rcv);
        bytes32 datahash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(encodedData)));
        if (isUnique[datahash]) {
            revert("Invalid claim");
        }
        address signer = recoverSigner(claimedSig, datahash);

        if (signer == owner) {
            isUnique[datahash] = true;
            for (uint256 i; i < tokens.length; i++) {
                _safeTransfer(tokens[i], rcv, (uint256(amounts[i]) * 10**IERC20(tokens[i]).decimals()) / 10**18);
            }
        } else {
            revert("Invalid signature");
        }

        emit claimedReward(tokens, amounts, rcv, block.timestamp, claimedSig);
    }

    function encodeTightlyPacked(
        address[] calldata _token,
        bytes32[] calldata _amount,
        uint256 chainId,
        address _rcv
    ) internal pure returns (bytes memory encodedData) {
        require(_token.length == _amount.length, "In-valid length");
        for (uint256 i = 0; i < _token.length; i++) {
            encodedData = abi.encodePacked(encodedData, _amount[i], _token[i]);
        }
        encodedData = abi.encodePacked(chainId, _rcv, encodedData);
        return (encodedData);
    }

    function recoverSigner(
        bytes memory sig,
        bytes32 _hash //signature, hash
    ) public pure returns (address) {
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sig);

        return ecrecover(bytes32(_hash), v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        require(sig.length == 65);

        assembly {
            // first 32 bytes, after the length prefix.
            r := mload(add(sig, 32))
            // second 32 bytes.
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 byt (es).
            v := byte(0, mload(add(sig, 96)))
        }

        return (v, r, s);
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function _safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "ST");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function decimals() external view returns (uint256);
}