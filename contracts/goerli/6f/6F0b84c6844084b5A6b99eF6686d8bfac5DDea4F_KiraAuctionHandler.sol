// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.17;

import "openzeppelin-solidity/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";
// import "openzeppelin-solidity/contracts/utils/cryptography/ECDSA.sol";
import "./_ecdsa.sol";
// import ecdsa from solady library
interface INft {
    function mint(address to, uint8 amount) external;
}

contract KiraAuctionHandler is Ownable {
    mapping(address => uint8) alreadyPledgedMercenary;
    mapping(address => uint8) alreadyPledgedEnlisted;
    mapping(address => uint8) alreadyPledgedLastPhase;

    mapping(address => Bid) bids;
    mapping(address => bool) public alreadyBid;
    mapping(address => bool) public refunded;
    mapping(address => bool) public bidWinner;
    mapping(address => bool) public bidWhitelist;
    address public kiraTreasury;
    address public card;

    uint256 cutoffValue;
    uint256 minBid;
    uint256 maxBid;

    uint16 numberOfNfts;
    uint8 state;
    uint8 maxAmountBidPhase;

    bool paused;

    struct Phase {
        uint8 maxAmountPerUser;
        bool isOpen;
        uint16 pledgedTotalAmount;
        uint16 supplyAllocated;
        address signer;
        uint256 pledgedTotalEth;
        uint256 price;
    }

    struct Bid {
        uint256 amount;
        uint256 value;
    }

    Phase public mercenary;
    Phase public enlisted;
    Phase public lastPhase;

    event UserBid(address indexed bidder, uint256 amount, uint256 value);
    event userPledge(address indexed user, uint256 amount);
    modifier state1() {
        require(state == 1, "Bidding hasn't started yet");
        _;
    }

    modifier state2() {
        require(state == 2, "Refunds haven't started yet");
        _;
    }

    bool locked;
    modifier nonReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        kiraTreasury = 0x6aD9356B3d0eEE5cA31DD757c95fB5AB67b01c33;
        minBid = 0.069 ether;
        maxBid = 0.099 ether;
        maxAmountBidPhase = 3;
        mercenary = Phase(
            2,
            false,
            0,
            1000,
            0xEAf4E461348Dd23928Bf77F0a3d3E55ea19D335E,
            0,
            0.069 ether
        );
        enlisted = Phase(
            1,
            false,
            0,
            3500,
            0xe9f5ea1Ff626d13cFBE1A7Dc47f40b9443EF2cCC,
            0,
            0.069 ether
        );
        lastPhase = Phase(
            1,
            false,
            0,
            0,
            0x3FB476663d8247ACDAAA9C220D91089ed04144b2,
            0,
            0.069 ether
        );
    }

    function newBid(uint8 amount) external payable state1 {
        require(!paused, "Paused");
        require(msg.sender == tx.origin, "No Smart Contracts!");
        require(!alreadyBid[msg.sender], "You have a bid already");
        require(amount > 0, "Amount must be greater than 0");
        uint256 value = msg.value / amount;
        if (!bidWhitelist[msg.sender]) {
            require(value >= minBid, "Bid amount is too low");
            require(value <= maxBid, "Bid amount is too high");
            require(amount <= maxAmountBidPhase, "Too many bids");
        }
        alreadyBid[msg.sender] = true;
        bids[msg.sender] = Bid(amount, value);
        emit UserBid(msg.sender, amount, value);
    }

    function processUserBid() public nonReentrant {
        require(state >= 2, "Not in the right state for this action");
        require(!refunded[msg.sender], "Refund already claimed");
        refunded[msg.sender] = true;
        uint256 refundAmount;
        Bid memory userBids = bids[msg.sender];
        require(userBids.amount > 0, "No bid found");
        if (!bidWinner[msg.sender]) {
            refundAmount = userBids.amount * userBids.value;
        } else {
            refundAmount = userBids.amount * (userBids.value - cutoffValue);
            INft(card).mint(msg.sender, 1);
        }
        (bool success, ) = payable(msg.sender).call{
            value: refundAmount,
            gas: 30000
        }("");
        require(success, "Refund failed");
    }

    function pledgeMercenary(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory m = mercenary;
        require(m.isOpen, "Not open");
        require(amount > 0, "Amount must be greater than 0");
        uint8 numPledged = alreadyPledgedMercenary[msg.sender] + amount;
        require(
            numPledged <= m.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * m.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, m.signer));
        require(
            m.pledgedTotalAmount + amount <= m.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedMercenary[msg.sender] = numPledged;
        mercenary.pledgedTotalEth += msg.value;
        mercenary.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function pledgeEnlisted(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory e = enlisted;
        require(amount > 0, "Amount must be greater than 0");
        require(e.isOpen, "Not open");
        uint8 numPledged = alreadyPledgedEnlisted[msg.sender] + amount;
        require(
            numPledged <= e.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * e.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, e.signer));
        require(
            e.pledgedTotalAmount + amount <= e.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedEnlisted[msg.sender] = numPledged;
        enlisted.pledgedTotalEth += msg.value;
        enlisted.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function pledgeLastPhase(
        uint8 amount,
        bytes calldata signature
    ) external payable {
        INft(card).mint(msg.sender, 1);
        Phase memory l = lastPhase;
        require(amount > 0, "Amount must be greater than 0");
        require(l.isOpen, "Not open");
        uint8 numPledged = alreadyPledgedLastPhase[msg.sender] + amount;
        require(
            numPledged <= l.maxAmountPerUser,
            "You would exceed the max amount per user"
        );
        require(msg.value == amount * l.price, "Incorrect amount of ETH sent");
        require(_validateData(msg.sender, signature, l.signer));
        require(
            l.pledgedTotalAmount + amount <= l.supplyAllocated,
            "Not enough supply left"
        );
        alreadyPledgedLastPhase[msg.sender] = numPledged;
        lastPhase.pledgedTotalEth += msg.value;
        lastPhase.pledgedTotalAmount += amount;
        emit userPledge(msg.sender, amount);
    }

    function setCard(address _card) external onlyOwner {
        card = _card;
    }

    function setKiraTreasury(address _kiraTreasury) external onlyOwner {
        require(
            _kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        kiraTreasury = _kiraTreasury;
    }

    function openBids() external onlyOwner {
        state = 1;
    }

    function resumeBidPhase() external onlyOwner {
        cutoffValue = 0;
        numberOfNfts = 0;
        state = 1;
    }

    function finalizeBidPhase(
        uint256 _cutoffValue,
        uint16 _numberOfNfts
    ) external onlyOwner {
        cutoffValue = _cutoffValue;
        numberOfNfts = _numberOfNfts;
        state = 2;
    }

    function flipPaused() external onlyOwner {
        paused = !paused;
    }

    function setState(uint8 _state) external onlyOwner {
        state = _state;
    }

    function setMinMaxBid(uint256 _minBid, uint256 _maxBid) external onlyOwner {
        minBid = _minBid;
        maxBid = _maxBid;
    }

    function openPhase(uint8 i) external onlyOwner {
        if (i == 1) {
            mercenary.isOpen = true;
        } else if (i == 2) {
            enlisted.isOpen = true;
        } else if (i == 3) {
            lastPhase.isOpen = true;
        } else {
            revert("Invalid phase");
        }
    }

    function editSupplyAllocated(uint8 i, uint16 newSupply) external onlyOwner {
        if (i == 1) {
            mercenary.supplyAllocated = newSupply;
        } else if (i == 2) {
            enlisted.supplyAllocated = newSupply;
        } else if (i == 3) {
            lastPhase.supplyAllocated = newSupply;
        } else {
            revert("Invalid phase");
        }
    }

    function editPrice(uint8 i, uint256 newPrice) external onlyOwner {
        if (i == 1) {
            mercenary.price = newPrice;
        } else if (i == 2) {
            enlisted.price = newPrice;
        } else if (i == 3) {
            lastPhase.price = newPrice;
        } else {
            revert("Invalid phase");
        }
    }

    function editSigner(uint8 i, address newSigner) external onlyOwner {
        if (i == 1) {
            mercenary.signer = newSigner;
        } else if (i == 2) {
            enlisted.signer = newSigner;
        } else if (i == 3) {
            lastPhase.signer = newSigner;
        } else {
            revert("Invalid phase");
        }
    }

    function editMaxAmountPerUser(uint8 i, uint8 newMaxAmount)
        external
        onlyOwner
    {
        if (i == 1) {
            mercenary.maxAmountPerUser = newMaxAmount;
        } else if (i == 2) {
            enlisted.maxAmountPerUser = newMaxAmount;
        } else if (i == 3) {
            lastPhase.maxAmountPerUser = newMaxAmount;
        } else {
            revert("Invalid phase");
        }
    }

    function closePhase(uint8 i) external onlyOwner {
        if (i == 1) {
            mercenary.isOpen = false;
        } else if (i == 2) {
            enlisted.isOpen = false;
        } else if (i == 3) {
            lastPhase.isOpen = false;
        } else {
            revert("Invalid phase");
        }
    }

    function addWinners(address[] calldata winners) external onlyOwner {
        for (uint256 i; i < winners.length;) {
            bidWinner[winners[i]] = true;
            unchecked { ++i; }
        }
    }

    function removeWinners(address[] calldata winners) external onlyOwner {
        for (uint256 i; i < winners.length;) {
            bidWinner[winners[i]] = false;
            unchecked { ++i; }
        }
    }

    function addBidWhitelist(address[] calldata whitelist) external onlyOwner {
        for (uint256 i; i < whitelist.length;) {
            bidWhitelist[whitelist[i]] = true;
            unchecked { ++i; }
        }
    }

    function removeBidWhitelist(address[] calldata whitelist)
        external
        onlyOwner
    {
        for (uint256 i; i < whitelist.length;) {
            bidWhitelist[whitelist[i]] = false;
            unchecked { ++i; }
        }
    }

    // eth/token withdrawal
    function saveTokens(
        IERC20 tokenAddress,
        address walletAddress,
        uint256 amount
    ) external onlyOwner {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        SafeERC20.safeTransfer(
            tokenAddress,
            walletAddress,
            amount == 0 ? tokenAddress.balanceOf(address(this)) : amount
        );
    }

    // for emergency
    function saveETH() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: address(this).balance,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    function withdrawETHFromBids() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        require(
            cutoffValue > 0 && numberOfNfts > 0,
            "Some values are not set."
        );
        uint256 collectedAmount = numberOfNfts * cutoffValue;
        (bool success, ) = payable(kiraTreasury).call{
            value: collectedAmount,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    function withdrawETHFromMercenary() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: mercenary.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        mercenary.pledgedTotalEth = 0;
    }

    function withdrawETHFromEnlisted() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: enlisted.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        enlisted.pledgedTotalEth = 0;
    }

    function withdrawETHFromLastPhase() external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: lastPhase.pledgedTotalEth,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
        lastPhase.pledgedTotalEth = 0;
    }

    // views
    function getBid(address user) external view returns (Bid memory) {
        return bids[user];
    }

    function getPledgedMercenary(address user) external view returns (uint256) {
        return alreadyPledgedMercenary[user];
    }

    function getPledgedEnlisted(address user) external view returns (uint256) {
        return alreadyPledgedEnlisted[user];
    }

    function phaseDetails() external view returns (Phase memory, Phase memory, Phase memory) {
        return (mercenary, enlisted, lastPhase);
    }

    function bidDetails()
        external
        view
        returns (uint8, uint256, uint256, uint256, uint8, uint16)
    {
        return (maxAmountBidPhase, minBid, maxBid, cutoffValue, state, numberOfNfts);
    }

    function _validateData(
        address _user,
        bytes calldata signature,
        address signer
    ) internal view returns (bool) {
        bytes32 dataHash = keccak256(abi.encodePacked(_user));
        bytes32 message = ECDSA.toEthSignedMessageHash(dataHash);

        address receivedAddress = ECDSA.recover(message, signature);
        return (receivedAddress != address(0) && receivedAddress == signer);
    }

    function saveAmountOfETH(uint256 val) external onlyOwner {
        require(
            kiraTreasury != address(0),
            "Kira treasury address cannot be 0"
        );
        (bool success, ) = payable(kiraTreasury).call{
            value: val,
            gas: 50000
        }("");
        require(success, "Withdrawal failed");
    }

    receive() external payable {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @notice Gas optimized ECDSA wrapper.
/// @author Solady (https://github.com/vectorized/solady/blob/main/src/utils/ECDSA.sol)
/// @author Modified from Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/ECDSA.sol)
/// @author Modified from OpenZeppelin (https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/cryptography/ECDSA.sol)
library ECDSA {
    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                        CUSTOM ERRORS                       */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The signature is invalid.
    error InvalidSignature();

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                         CONSTANTS                          */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev The number which `s` must not exceed in order for
    /// the signature to be non-malleable.
    bytes32 private constant _MALLEABILITY_THRESHOLD =
        0x7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0;

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                    RECOVERY OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // Note: as of the Solady version v0.0.68, these functions will
    // revert upon recovery failure for more safety.

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the `signature`.
    ///
    /// This function does NOT accept EIP-2098 short form signatures.
    /// Use `recover(bytes32 hash, bytes32 r, bytes32 vs)` for EIP-2098
    /// short form signatures instead.
    function recover(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // Directly copy `r` and `s` from the calldata.
            calldatacopy(0x40, signature.offset, 0x40)
            // Store the `hash` in the scratch space.
            mstore(0x00, hash)
            // Compute `v` and store it in the scratch space.
            mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    and(
                        // If the signature is exactly 65 bytes in length.
                        eq(signature.length, 65),
                        // If `s` in lower half order, such that the signature is not malleable.
                        lt(mload(0x60), add(_MALLEABILITY_THRESHOLD, 1))
                    ), // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x00, // Start of output.
                    0x20 // Size of output.
                )
            )
            result := mload(0x00)
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                // Store the function selector of `InvalidSignature()`.
                mstore(0x00, 0x8baa579f)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the zero slot.
            mstore(0x60, 0)
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    ///
    /// This function only accepts EIP-2098 short form signatures.
    /// See: https://eips.ethereum.org/EIPS/eip-2098
    ///
    /// To be honest, I do not recommend using EIP-2098 signatures
    /// for simplicity, performance, and security reasons. Most if not
    /// all clients support traditional non EIP-2098 signatures by default.
    /// As such, this method is intentionally not fully inlined.
    /// It is merely included for completeness.
    function recover(bytes32 hash, bytes32 r, bytes32 vs) internal view returns (address result) {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        result = recover(hash, v, r, s);
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            mstore(0x00, hash)
            mstore(0x20, and(v, 0xff))
            mstore(0x40, r)
            mstore(0x60, s)
            pop(
                staticcall(
                    gas(), // Amount of gas left for the transaction.
                    // If `s` in lower half order, such that the signature is not malleable.
                    lt(s, add(_MALLEABILITY_THRESHOLD, 1)), // Address of `ecrecover`.
                    0x00, // Start of input.
                    0x80, // Size of input.
                    0x00, // Start of output.
                    0x20 // Size of output.
                )
            )
            result := mload(0x00)
            // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
            if iszero(returndatasize()) {
                // Store the function selector of `InvalidSignature()`.
                mstore(0x00, 0x8baa579f)
                // Revert with (offset, size).
                revert(0x1c, 0x04)
            }
            // Restore the zero slot.
            mstore(0x60, 0)
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                   TRY-RECOVER OPERATIONS                   */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    // WARNING!
    // These functions will NOT revert upon recovery failure.
    // Instead, they will return the zero address upon recovery failure.
    // It is critical that the returned address is NEVER compared against
    // a zero address (e.g. an uninitialized address variable).

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the `signature`.
    ///
    /// This function does NOT accept EIP-2098 short form signatures.
    /// Use `recover(bytes32 hash, bytes32 r, bytes32 vs)` for EIP-2098
    /// short form signatures instead.
    function tryRecover(bytes32 hash, bytes calldata signature)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            if iszero(xor(signature.length, 65)) {
                // Copy the free memory pointer so that we can restore it later.
                let m := mload(0x40)
                // Directly copy `r` and `s` from the calldata.
                calldatacopy(0x40, signature.offset, 0x40)
                // If `s` in lower half order, such that the signature is not malleable.
                if iszero(gt(mload(0x60), _MALLEABILITY_THRESHOLD)) {
                    // Store the `hash` in the scratch space.
                    mstore(0x00, hash)
                    // Compute `v` and store it in the scratch space.
                    mstore(0x20, byte(0, calldataload(add(signature.offset, 0x40))))
                    pop(
                        staticcall(
                            gas(), // Amount of gas left for the transaction.
                            0x01, // Address of `ecrecover`.
                            0x00, // Start of input.
                            0x80, // Size of input.
                            0x40, // Start of output.
                            0x20 // Size of output.
                        )
                    )
                    // Restore the zero slot.
                    mstore(0x60, 0)
                    // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                    result := mload(xor(0x60, returndatasize()))
                }
                // Restore the free memory pointer.
                mstore(0x40, m)
            }
        }
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the EIP-2098 short form signature defined by `r` and `vs`.
    ///
    /// This function only accepts EIP-2098 short form signatures.
    /// See: https://eips.ethereum.org/EIPS/eip-2098
    ///
    /// To be honest, I do not recommend using EIP-2098 signatures
    /// for simplicity, performance, and security reasons. Most if not
    /// all clients support traditional non EIP-2098 signatures by default.
    /// As such, this method is intentionally not fully inlined.
    /// It is merely included for completeness.
    function tryRecover(bytes32 hash, bytes32 r, bytes32 vs)
        internal
        view
        returns (address result)
    {
        uint8 v;
        bytes32 s;
        /// @solidity memory-safe-assembly
        assembly {
            s := shr(1, shl(1, vs))
            v := add(shr(255, vs), 27)
        }
        result = tryRecover(hash, v, r, s);
    }

    /// @dev Recovers the signer's address from a message digest `hash`,
    /// and the signature defined by `v`, `r`, `s`.
    function tryRecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
        internal
        view
        returns (address result)
    {
        /// @solidity memory-safe-assembly
        assembly {
            // Copy the free memory pointer so that we can restore it later.
            let m := mload(0x40)
            // If `s` in lower half order, such that the signature is not malleable.
            if iszero(gt(s, _MALLEABILITY_THRESHOLD)) {
                // Store the `hash`, `v`, `r`, `s` in the scratch space.
                mstore(0x00, hash)
                mstore(0x20, and(v, 0xff))
                mstore(0x40, r)
                mstore(0x60, s)
                pop(
                    staticcall(
                        gas(), // Amount of gas left for the transaction.
                        0x01, // Address of `ecrecover`.
                        0x00, // Start of input.
                        0x80, // Size of input.
                        0x40, // Start of output.
                        0x20 // Size of output.
                    )
                )
                // Restore the zero slot.
                mstore(0x60, 0)
                // `returndatasize()` will be `0x20` upon success, and `0x00` otherwise.
                result := mload(xor(0x60, returndatasize()))
            }
            // Restore the free memory pointer.
            mstore(0x40, m)
        }
    }

    /*´:°•.°+.*•´.*:˚.°*.˚•´.°:°•.°•.*•´.*:˚.°*.˚•´.°:°•.°+.*•´.*:*/
    /*                     HASHING OPERATIONS                     */
    /*.•°:°.´+˚.*°.˚:*.´•*.+°.•°:´*.´•*.•°.•°:°.´:•˚°.*°.˚:*.´+°.•*/

    /// @dev Returns an Ethereum Signed Message, created from a `hash`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32 result) {
        /// @solidity memory-safe-assembly
        assembly {
            // Store into scratch space for keccak256.
            mstore(0x20, hash)
            mstore(0x00, "\x00\x00\x00\x00\x19Ethereum Signed Message:\n32")
            // 0x40 - 0x04 = 0x3c
            result := keccak256(0x04, 0x3c)
        }
    }

    /// @dev Returns an Ethereum Signed Message, created from `s`.
    /// This produces a hash corresponding to the one signed with the
    /// [`eth_sign`](https://eth.wiki/json-rpc/API#eth_sign)
    /// JSON-RPC method as part of EIP-191.
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32 result) {
        assembly {
            // The length of "\x19Ethereum Signed Message:\n" is 26 bytes (i.e. 0x1a).
            // If we reserve 2 words, we'll have 64 - 26 = 38 bytes to store the
            // ASCII decimal representation of the length of `s` up to about 2 ** 126.

            // Instead of allocating, we temporarily copy the 64 bytes before the
            // start of `s` data to some variables.
            let m1 := mload(sub(s, 0x20))
            // The length of `s` is in bytes.
            let sLength := mload(s)
            let ptr := add(s, 0x20)
            let w := not(0)
            // `end` marks the end of the memory which we will compute the keccak256 of.
            let end := add(ptr, sLength)
            // Convert the length of the bytes to ASCII decimal representation
            // and store it into the memory.
            for { let temp := sLength } 1 {} {
                ptr := add(ptr, w) // `sub(ptr, 1)`.
                mstore8(ptr, add(48, mod(temp, 10)))
                temp := div(temp, 10)
                if iszero(temp) { break }
            }
            // Copy the header over to the memory.
            mstore(sub(ptr, 0x20), "\x00\x00\x00\x00\x00\x00\x19Ethereum Signed Message:\n")
            // Compute the keccak256 of the memory.
            result := keccak256(sub(ptr, 0x1a), sub(end, sub(ptr, 0x1a)))
            // Restore the previous memory.
            mstore(s, sLength)
            mstore(sub(s, 0x20), m1)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}