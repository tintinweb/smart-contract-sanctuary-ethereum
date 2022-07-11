/**
 *Submitted for verification at Etherscan.io on 2022-07-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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
}

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

interface IDicewar {
    function balanceOfToken(address _userAddr) external returns(uint256);
    function burn(address _userAddr, uint amount) external;
}

interface IDiceWarNft {
    function upgradeMint(address _userAddr, uint8 level) external;
    function burn(address _userAddr, uint tokenId, uint256 amount) external;
    function balanceOfNft(address account, uint id) external returns(uint256);
    function getLvList (uint tokenId) external  returns(address[] memory _addresses);
}

contract House is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    bool public houseLive = true;
    uint public lockedInBets;
    uint public lockedInRewards;
    uint public projectRewards;
    uint public treasurePool;
    uint public prizePool;
    uint public nftHoldersRewardsToDistribute;
    uint public balanceMaxProfitRatio = 1;
    uint public lv1Weight = 10;
    uint public lv2Weight = 20;
    uint public lv3Weight = 40;
    uint public lv4Weight = 80;
    uint public houseEdgeBP = 400;
    uint public userSum = 0;
    uint public lev1Token = 0 ether;
    uint public lev2Token = 0 ether;
    uint public lev3Token = 0 ether;
    uint public nftHoldersRewardsBP = 200;
    uint public projectRewardsBP = 80;
    uint public treasurePoolBP = 20;
    uint public prizePoolsBP = 80;
    uint public refBP = 20;
    IDiceWarNft dicewarNft;
    IDicewar dicewar;
    address public diceWarAddress;
    address public DiceWarNFTAddress;

    mapping(address => bool) private addressAdmin;
    mapping(address => uint) public playerBalance;

    // Events
    event Donation(address indexed player, uint amount);
    event BalanceClaimed(address indexed player, uint amount);
    event RewardsDistributed(uint nPlayers, uint amount);
    event upgradeNftE(address userAddress, uint8 levelBefore);


    fallback() external payable { emit Donation(msg.sender, msg.value); }
    receive() external payable { emit Donation(msg.sender, msg.value); }

    modifier admin {
        require(addressAdmin[msg.sender] == true, "You are not an admin");
        _;
    }

    modifier isHouseLive {
        require(houseLive == true, "House not live");
        _;
    }

    // Getter
    function balance() public view returns (uint) {
        return address(this).balance;
    }

    function dicewarBalance() public view returns (uint) {
        return IERC20(diceWarAddress).balanceOf(address(this));
    }

    // Setter
        /**
     *Update upgrade's token amount
     */
     function updateUpgradeToken(uint[] memory _data) external onlyOwner{
        lev1Token = _data[0];
        lev2Token = _data[1];
        lev3Token = _data[2];
     }
    function initializeWeight(uint _lv1Weight, uint _lv2Weight, uint _lv3Weight, uint _lv4Weight) external onlyOwner{
        lv1Weight = _lv1Weight;
        lv2Weight = _lv2Weight;
        lv3Weight = _lv3Weight;
        lv4Weight = _lv4Weight;
    }

    function initializeDiceWar(address _address) external onlyOwner {
        dicewar = IDicewar(_address);
        diceWarAddress = _address;
    }

    function initializeDiceWarNft(address _address) external onlyOwner {
        dicewarNft = IDiceWarNft(_address);
        DiceWarNFTAddress = _address;
    }

    function toggleHouseLive() external onlyOwner {
        houseLive = !houseLive;
    }

    function setBalanceMaxProfitRatio(uint _balanceMaxProfitRatio) external onlyOwner {
        balanceMaxProfitRatio = _balanceMaxProfitRatio;
    }

    function setdicewarAddress(address _dicewarAddress) external onlyOwner {
        diceWarAddress = _dicewarAddress;
    }

    function setHouseEdgeBP(uint _houseEdgeBP) external onlyOwner {
        require(houseLive == false, "Bets in pending");
        houseEdgeBP = _houseEdgeBP;
    }

    function setNftHoldersRewardsBP(uint _nftHoldersRewardsBP) external onlyOwner {
        nftHoldersRewardsBP = _nftHoldersRewardsBP;
    }
    // Converters
    function amountToWinnableAmount(uint _amount, uint rollUnder, uint MODULO) external view returns (uint) {
        require(0 < rollUnder && rollUnder <= MODULO, "Win probability out of range");
        uint bettableAmount = this.amountToBettableAmountConverter(_amount);
        return bettableAmount * MODULO / rollUnder;
    }

    function amountToBettableAmountConverter(uint amount) external view returns(uint) {
        return amount / (1 + houseEdgeBP/10000);
    }
    function amountToNftHoldersRewardsConverter(uint _amount) internal view returns (uint) {
        return _amount * nftHoldersRewardsBP / houseEdgeBP;
    }

    function amountToProjectRewardsConverter(uint _amount) internal view returns (uint) {
        return _amount * projectRewardsBP / houseEdgeBP;
    }

    function amountToPrizePoolConverter(uint _amount) internal view returns (uint) {
        return _amount * prizePoolsBP / houseEdgeBP;
    }

    function amountToTreasurePoolConverter(uint _amount) internal view returns (uint) {
        return _amount * treasurePoolBP / houseEdgeBP;
    }

    function amountToRefConverter(uint _amount) internal view returns (uint) {
        return _amount * refBP / houseEdgeBP;
    }

    // Methods
    function addAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = false;
    }

    // Game methods
    function balanceAvailableForBet() public view returns (uint) {
        return balance() - lockedInBets - lockedInRewards;
    }

    function maxProfit() public view returns (uint) {
        return balanceAvailableForBet() / balanceMaxProfitRatio;
    }

    function placeBet(address player, uint amount, bool isBonus,uint rollUnder, uint MODULO) payable external isHouseLive admin nonReentrant {
        uint bettableAmount = this.amountToBettableAmountConverter(amount);
        uint[] memory amountArray = new uint[](6);
        amountArray[0] = amountToNftHoldersRewardsConverter(amount - bettableAmount);
        amountArray[1] = amountToProjectRewardsConverter(amount - bettableAmount);
        amountArray[2] = amountToTreasurePoolConverter(amount - bettableAmount);
        amountArray[3] = amountToPrizePoolConverter(amount - bettableAmount);
        amountArray[4] = this.amountToWinnableAmount(amount, rollUnder,MODULO);
        amountArray[5] = amountToRefConverter(amount - bettableAmount);
        require(amountArray[4] <= maxProfit(), "MaxProfit violation");
        uint dicewarRewards = amount * 5;
        require(dicewarRewards <= dicewarBalance(), "Not enough dicewar tokens");
        if (isBonus == true) {
            require(playerBalance[player] >= amount, "Not enough bonus");
            playerBalance[player] -= amount;
            lockedInRewards -= amount;
        }
        else {
            require(amount == msg.value, "Not right amount sent");
        }
        lockedInBets += amountArray[4];
        nftHoldersRewardsToDistribute += amountArray[0];
        lockedInRewards += amountArray[0] + amountArray[1] + amountArray[2] + amountArray[3];
        projectRewards += amountArray[1];
        treasurePool += amountArray[2];
        prizePool += amountArray[3];
        IERC20(diceWarAddress).safeTransfer(player, dicewarRewards);
        if(user[player].refAddr != address(0)){
            user[user[player].refAddr].balance += amountArray[5];
        }else{
            projectRewards += amountArray[5];
        }
    }

    function settleBet(address player, uint winnableAmount, bool win) external isHouseLive admin nonReentrant {
        lockedInBets -= winnableAmount;
        if (win == true) {
            payable(player).transfer(winnableAmount);
        }
    }

    function payPlayer(address player, uint amount) external isHouseLive admin nonReentrant {
        require(amount <= maxProfit(), "MaxProfit violation");
        payable(player).transfer(amount);
    }

    function senddicewarTokens(address player, uint amount) external isHouseLive admin nonReentrant {
        require(amount <= dicewarBalance(), "Not enough dicewar tokens");
        IERC20(diceWarAddress).safeTransfer(player, amount);
    }

    function refundBet(address player, uint amount, uint winnableAmount) external isHouseLive admin nonReentrant {
        lockedInBets -= winnableAmount;
        payable(player).transfer(amount);
    }

    function claimBalance() external isHouseLive nonReentrant {
        uint gBalance = playerBalance[msg.sender];
        require(gBalance > 0, "No funds to claim");
        payable(msg.sender).transfer(gBalance);
        playerBalance[msg.sender] = 0;
        lockedInRewards -= gBalance;
        emit BalanceClaimed(msg.sender, gBalance);
    }

    function claimProjectRewards() external isHouseLive nonReentrant onlyOwner {
        require(projectRewards > 0, "No funds to claim");
        payable(msg.sender).transfer(projectRewards);
        projectRewards = 0;
        lockedInRewards -= projectRewards;
        emit BalanceClaimed(msg.sender, projectRewards);
    }

    function claimTreasurePool() external isHouseLive nonReentrant onlyOwner {
        require(treasurePool > 0, "No funds to claim");
        payable(msg.sender).transfer(treasurePool);
        treasurePool = 0;
        lockedInRewards -= treasurePool;
        emit BalanceClaimed(msg.sender, treasurePool);
    }

    function claimPrizePool() external isHouseLive nonReentrant onlyOwner {
        require(prizePool > 0, "No funds to claim");
        payable(msg.sender).transfer(prizePool);
        prizePool = 0;
        lockedInRewards -= prizePool;
        emit BalanceClaimed(msg.sender, prizePool);
    }

    function distributeNftHoldersRewards() external onlyOwner {
        require(nftHoldersRewardsToDistribute > 0, "No rewards to distribute");
        address[] memory lv1Addr = dicewarNft.getLvList(1);
        address[] memory lv2Addr = dicewarNft.getLvList(2);
        address[] memory lv3Addr = dicewarNft.getLvList(3);
        address[] memory lv4Addr = dicewarNft.getLvList(4);
        uint sumAddr = lv1Addr.length +lv2Addr.length +lv3Addr.length +lv4Addr.length;
        uint sumWeight = lv1Weight * lv1Addr.length + lv2Weight * lv2Addr.length + lv3Weight * lv3Addr.length + lv4Weight * lv4Addr.length;
        uint sigLv1Reward = nftHoldersRewardsToDistribute * (lv1Weight/sumWeight);
        uint sigLv2Reward = nftHoldersRewardsToDistribute * (lv2Weight/sumWeight);
        uint sigLv3Reward = nftHoldersRewardsToDistribute * (lv3Weight/sumWeight);
        uint sigLv4Reward = nftHoldersRewardsToDistribute * (lv4Weight/sumWeight);
        for (uint i = 0; i < lv1Addr.length; i++) {
            playerBalance[lv1Addr[i]] += sigLv1Reward;
        }
        for (uint i = 0; i < lv2Addr.length; i++) {
            playerBalance[lv2Addr[i]] += sigLv2Reward;
        }
        for (uint i = 0; i < lv3Addr.length; i++) {
            playerBalance[lv3Addr[i]] += sigLv3Reward;
        }
        for (uint i = 0; i < lv4Addr.length; i++) {
            playerBalance[lv4Addr[i]] += sigLv4Reward;
        }
        emit RewardsDistributed(sumAddr, nftHoldersRewardsToDistribute);
        nftHoldersRewardsToDistribute = 0;
    }

    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= balanceAvailableForBet(), "Withdrawal exceeds limit");
        beneficiary.transfer(withdrawAmount);
    }

    function withdrawdicewarFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= dicewarBalance(), "dicewar token withdrawal exceeds limit");
        IERC20(diceWarAddress).safeTransfer(beneficiary, withdrawAmount);
    }

    function withdrawCustomTokenFunds(address beneficiary, uint withdrawAmount, address token) external onlyOwner {
        require(withdrawAmount <= IERC20(token).balanceOf(address(this)), "Withdrawal exceeds limit");
        IERC20(token).safeTransfer(beneficiary, withdrawAmount);
    }

        /**
     *Upgrade user's NFT
     */
    function upgradeNft(address _addr, uint8 level) external {
        require(level == 1 || level == 2 || level == 3, "Can not upgrade this level");
        require(dicewarNft.balanceOfNft(_addr, level) >= 1, "You do not have NFT to upgrade");
        if(level == 1){
            require(dicewar.balanceOfToken(msg.sender) >= lev1Token);
            dicewar.burn(_addr, lev1Token);
        }
        if(level == 2){
            require(dicewar.balanceOfToken(msg.sender) >= lev2Token);  
            dicewar.burn(_addr, lev2Token);

        }
        if(level == 3){
            require(dicewar.balanceOfToken(msg.sender) >= lev3Token);
            dicewar.burn(_addr, lev3Token);
        }
        dicewarNft.burn(_addr, level, 1);
        dicewarNft.upgradeMint(_addr, level);
        emit upgradeNftE(_addr, level);
    }

    struct userDetail {
        uint256 id;
        address addr;
        address refAddr;
        uint256 balance;
        uint256 dicewarToken;
        string profileName;
        string profileLink;
        
    }
    mapping(address => userDetail) public user;
    event UserRegister (address addr,address refAddr,uint userId);

    function isNew (address _addr) external view returns(bool){
        return (user[_addr].id == 0 ? true: false);
    }

    function register (address _addr, address _refAddr, string memory _profileName, string memory _profileLink) external returns(bool){
        require(user[_addr].id == 0, "You have registered before");
        require(_addr == msg.sender, "Please register with your own wallet");
        _refAddr = _addr == _refAddr ? address(0) : _refAddr;
        user[_addr] = userDetail(userSum+1,_addr,_refAddr,0,0, _profileName, _profileLink);
        userSum ++;
        emit UserRegister(msg.sender, _refAddr, userSum + 1);
        return true;
    }


     function updateProfile (string memory _profileName , string memory _profileLink) external returns(bool){
        require(user[msg.sender].id != 0, "You need registered first");
        user[msg.sender].profileName = _profileName;
        user[msg.sender].profileLink = _profileLink;
        return true;
     }

     function updateRef (address _refAddr ) external returns(bool){
        require(user[msg.sender].id != 0, "You need registered first");
        require(user[msg.sender].refAddr == address(0), "Refferal Address can not be updated if exist");
        user[msg.sender].refAddr = _refAddr;
        return true;
     }
}