/**
 *Submitted for verification at Etherscan.io on 2022-12-10
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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

// File: contracts/BaseledgerUBTSplitter.sol


// OpenZeppelin Contracts v4.4.1 (finance/BaseledgerUBTSplitter .sol)

pragma solidity ^0.8.0;





/**
 * @title BaseledgerUBTSplitter
 * @dev This contract allows to split UBT payments among a group of accounts. The sender does not need to be aware
 * that the UBT will be split in this way, since it is handled transparently by the contract.
 * Contract is based on PaymentSplitter, but difference is that in PaymentSplitter payees are added only once in constructor,
 * but here can be added and updated later. Because of this, contract needs to track release amount since the last payee update.
 * Offchain solution should take care of notifying payees to pull their funds before payees are added or updated.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the UBT that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `BaseledgerUBTSplitter ` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 */
contract BaseledgerUBTSplitter is Context, Ownable {
    event PayeeUpdated(
        address indexed token,
        address indexed revenueAddress,
        string baseledgerValidatorAddress,
        uint256 shares,
        uint256 lastEventNonce
    );

    event UbtPaymentReleased(
        IERC20 indexed token,
        address revenueAddress,
        address stakingAddress,
        uint256 amount
    );

    event UbtDeposited(
        address indexed token,
        address indexed sender,
        string baseledgerDestinationAddress,
        uint256 tokenAmount,
        uint256 lastEventNonce
    );

    uint256 public totalShares;
    uint256 public lastEventNonce = 0;

    mapping(address => uint256) public shares;
    mapping(address => address) public stakingAddresses;
    mapping(address => uint256) public ubtReleased;

    mapping(address => bool) public payees;

    uint256 public ubtTotalReleased;
    mapping(uint256 => mapping(address => uint256))
        public ubtReleasedPerRecipientInPeriods;

    uint256 public ubtToBeReleasedInPeriod;
    uint256 public ubtNotReleasedInPreviousPeriods;
    uint256 public ubtCurrentPeriod;

    address public ubtTokenContractAddress;

    address public powerChanger;

    uint256 public minDeposit = 100000000;

    constructor(address token) {
        ubtTokenContractAddress = token;
        setPowerChanger(msg.sender);

        addPayee(0x5631ec4eA40E82263df542c7E5570Fe4710A769a, 0x5631ec4eA40E82263df542c7E5570Fe4710A769a, 5000000000000, "baseledgervaloper1qdtta8nt2j7jfkdyvqkcut03c7xaqx3v7h0cyl");
        addPayee(0x3F1256aFBfAE473f17F07c17b1EC0c9f0326fb49, 0x3F1256aFBfAE473f17F07c17b1EC0c9f0326fb49, 100000000000000, "baseledgervaloper19nekz80crxl9k89akf7h5hvhkq7337ynrq94r6");
        addPayee(0xbC13D54136B77A16D458365bc8c4F51e2944D7f8, 0x77D3732e665dCe89317d60EdE899ad7eeb709898, 50170764736102, "baseledgervaloper195h89jxeu6f53rcclavjng3p0fuj0rh2uh6mrf");
        addPayee(0xE5608E6FAE911f7588Ff536094c36f66c87Fd367, 0xE5608E6FAE911f7588Ff536094c36f66c87Fd367, 37071630882739, "baseledgervaloper19c383dcy7rrtt3q6mdxt8erja8jdvxen9h98th");
        addPayee(0xE69fFcC62262e66cAEE8E07DeAC524Efc56433B5, 0xE69fFcC62262e66cAEE8E07DeAC524Efc56433B5, 90000000000000, "baseledgervaloper1xjz08pu2vc6gqzjcpaux4mpvxfr3uuzzm08ath");
        addPayee(0xd39f523EE00AEf6B75B76fecCE36A8C09EE77B88, 0xd39f523EE00AEf6B75B76fecCE36A8C09EE77B88, 280848891659, "baseledgervaloper1f9tgkttrac95crk8862f646ckyvqcryfgl5rnj");
        addPayee(0xb494c12DEE7BD77f27Ad476F9709E54f1b410450, 0xb494c12DEE7BD77f27Ad476F9709E54f1b410450, 100000000000000, "baseledgervaloper1f2t2g0tqkqpn7kwwp55v0cf4s3xgvgn8f2cghy");
        addPayee(0x9dd38419901Ac280050f44e64dB88c48C4e648B2, 0xAF8412fcfd3A9399f66E60894c1c8A20054d3D55, 59097961870848, "baseledgervaloper1fe2t344tl0s6ry4n8p0clmupee36smyhuvtjrp");
        addPayee(0xfea3D58AAc874DB1A1eD02841Aaf79c3b782eF68, 0xA246D8ef0504edc5510402Af70479F06DBcaE259, 45000000000000, "baseledgervaloper1d3cfq2ljs6cn3hlzddg2lds6vhd8v7jna7d2xg");
        addPayee(0x76f7d49D357b9079e7dF54324EA238aAc046Dc55, 0x01C292aB90019cAc6565328E2E2849EEb759c7d3, 66666700000000, "baseledgervaloper13usvszvszfsys48wg8kl829rwzs2zz5j42fqux");
        addPayee(0x0747503FA065b05753a7c175E2207942923C09b6, 0xe534BBF23afEE1392AE655e1B60469995e1cD6FF, 100000000000000, "baseledgervaloper1nay8g0a3harhuud03t9rce9kmxg3kkl7kxyyq4");
        addPayee(0x88e7e1b3ec590512DCD8C8dBC1B8BD4CB15f1eE8, 0x88e7e1b3ec590512DCD8C8dBC1B8BD4CB15f1eE8, 61737353202085, "baseledgervaloper15p4mfuwjsfzu5k79r2uculhsm5g89w62yz3due");
        addPayee(0xc88C9FA0651a348f6eAA13aE3Ef95977b30A5B98, 0xc88C9FA0651a348f6eAA13aE3Ef95977b30A5B98, 25487999775696, "baseledgervaloper1ke6hr0cwczzpuu77hwckgcjtmya8698dl8jx2u");
        addPayee(0x126f1Df65B437C7a8c49c8650a7b678Cd0964E62, 0x89aDCd843A3B400c5a22a914dA7CbB49B81354a6, 22669077895881, "baseledgervaloper1hjrt343ydffs22t92ld0zgl7d4yp7f8f09lj0w");
        addPayee(0x996467eC5615f79De3364fb4FEa7CF3828B5dA81, 0xFaf957614daDAc83363C097AA52c320CF4a75445, 100000000000000, "baseledgervaloper1ert9qr8aksxutgh0el44dq534vxmrp2lgj7jrs");
        addPayee(0x0bD951F60C80fA3ee7d7EcA8955daACe10c51FFA, 0xcaD420ed10737A170e47c785E3a7aA4a726DB7A1, 100000000000000, "baseledgervaloper1ehm6d95zd3fmzztyne3z9638uf9kuj44jygpkt");
        addPayee(0x37EB4737517C4Ef2dE3550dFCFC441A89119D005, 0x37EB4737517C4Ef2dE3550dFCFC441A89119D005, 5000000000000, "baseledgervaloper1m7frxlv4hlm4atgtpgyda47r4r0hyzdjpdcect");
        addPayee(0x723C3C0cC7E9E93a2E4e6ff363C13CBA2497f1C3, 0x723C3C0cC7E9E93a2E4e6ff363C13CBA2497f1C3, 5040700000000, "baseledgervaloper17hje63hk303cevu5caj5lpjtrvfpt5c3wvs823");
        addPayee(0x4aa87C578864bA15c78d889206C4cd46e2FD07f3, 0x4aa87C578864bA15c78d889206C4cd46e2FD07f3, 98335150487112, "baseledgervaloper12067jlfhj6ugnkyydmmrwpnd37q5xkqwsajnq5");
        addPayee(0xc41ddd0233775c86F57f7B514594dd3334F4913e, 0xc41ddd0233775c86F57f7B514594dd3334F4913e, 100000000000000, "baseledgervaloper13szpuhvl5kvpe2x8znynf00eflg5kws738e39j");
        addPayee(0xD5F911A64156e5B79239d8ef76Baa1c2f1991526, 0xD5F911A64156e5B79239d8ef76Baa1c2f1991526, 100000000000000, "baseledgervaloper1u345rkefwu7ael45d4ws93jrquf04zk3fn8era");
        addPayee(0xDad41ecdbFd1eB70b95E62EfE172A6230f8fa7Db, 0xDad41ecdbFd1eB70b95E62EfE172A6230f8fa7Db, 30664300000000, "baseledgervaloper1wuj5td4ejd92aydq25vgnkgm9zmamujfyxdwd0");
        addPayee(0x67686E74e5256652E0AB0a9f5c1e61D11a66CaCe, 0x67686E74e5256652E0AB0a9f5c1e61D11a66CaCe, 75000000000000, "baseledgervaloper1f7wjdqtgu43zem9tzmpj3y8c70dd0rywzgl8s4");
        addPayee(0xc3a201C73a6bFd6d392B1F35c93E85EF89f5e564, 0xc3a201C73a6bFd6d392B1F35c93E85EF89f5e564, 65000000000000, "baseledgervaloper13fjtsxtee5u0q2nvgthuw6qlf6z3h8zfwmwypm");
        addPayee(0x80FDc30D21A672EeF723b809Ed4ba7c91728D421, 0x9E7a3140B330ed448B222E2bD2425b0F64f44f06, 11317400000000, "baseledgervaloper17lckhf2a82tjzy5af6z9at88xw524zeplkemra");
    }

    /**
     * @dev Modifier for checking for zero address
     */
    modifier zeroAddress(address address_) {
        require(address_ != address(0), "address is zero address");
        _;
    }

    /**
     * @dev Modifier for checking for empty string
     */
    modifier emptyString(string memory str) {
        bytes memory tempEmptyStringTest = bytes(str);
        require(tempEmptyStringTest.length != 0, "string is empty");
        _;
    }

    /**
     * @dev Modifier for checking for power changer
     */
    modifier onlyPowerChanger() {
        require(msg.sender == powerChanger, "caller should be power changer");
        _;
    }

    /**
     * @dev Function to override last event nonce
     */
    function setLastEventNonce(uint256 newEventNonce) public onlyOwner {
        lastEventNonce = newEventNonce;
    }

    /**
     * @dev Function to override power changer
     */
    function setPowerChanger(address newPowerChanger) public onlyOwner {
        powerChanger = newPowerChanger;
    }

    /**
     * @dev Add token deposit to the contract and emit event.
     * @param amount The amount of the token.
     * @param baseledgerDestinationAddress The baseledger destination address.
     */
    function deposit(uint256 amount, string memory baseledgerDestinationAddress)
        public
        emptyString(baseledgerDestinationAddress)
    {
        require(amount >= minDeposit, "amount should be above min deposit");
        lastEventNonce += 1;
        ubtToBeReleasedInPeriod += amount;

        bool transferFromReturn = IERC20(ubtTokenContractAddress).transferFrom(
            msg.sender,
            address(this),
            amount
        );

        require(
            transferFromReturn == true,
            "transferFrom fail, check allowance"
        );
        emit UbtDeposited(
            ubtTokenContractAddress,
            msg.sender,
            baseledgerDestinationAddress,
            amount,
            lastEventNonce
        );
    }

    /**
     * @dev Triggers a transfer to `msg.sender` of the amount of UBT tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals in current period since last payee update.
     */
    function release() public virtual {
        require(payees[msg.sender] == true, "msg.sender is not payee");
        require(shares[msg.sender] > 0, "msg.sender has no shares");

        uint256 alreadyReceivedSinceLastPayeeUpdate = ubtReleasedPerRecipientInPeriods[
                ubtCurrentPeriod
            ][msg.sender];
        uint256 toBeReleased = ubtToBeReleasedInPeriod +
            ubtNotReleasedInPreviousPeriods;
        uint256 payment = (shares[msg.sender] * toBeReleased) /
            totalShares -
            alreadyReceivedSinceLastPayeeUpdate;

        ubtReleased[msg.sender] += payment;
        ubtTotalReleased += payment;
        ubtReleasedPerRecipientInPeriods[ubtCurrentPeriod][
            msg.sender
        ] += payment;

        require(payment != 0, "msg.sender is not due payment");
        IERC20(ubtTokenContractAddress).transfer(msg.sender, payment);

        emit UbtPaymentReleased(
            IERC20(ubtTokenContractAddress),
            msg.sender,
            stakingAddresses[msg.sender],
            payment
        );
    }

    /**
     * @dev Add a new payee to the contract.
     * @param revenueAddress The revenue address.
     * @param stakingAddress The staking address.
     * @param shares_ The number of shares owned by the payee.
     * @param baseledgerValidatorAddress Identifier for the node within baseledger.
     */
    function addPayee(
        address revenueAddress,
        address stakingAddress,
        uint256 shares_,
        string memory baseledgerValidatorAddress
    )
        public
        onlyPowerChanger
        zeroAddress(revenueAddress)
        zeroAddress(stakingAddress)
        emptyString(baseledgerValidatorAddress)
    {
        require(payees[revenueAddress] == false, "payee already exists");
        require(shares_ > 0, "shares are 0");

        payees[revenueAddress] = true;

        _updatePayeeSharesAndCurrentPeriod(
            revenueAddress,
            stakingAddress,
            shares_
        );

        emit PayeeUpdated(
            ubtTokenContractAddress,
            revenueAddress,
            baseledgerValidatorAddress,
            shares_,
            lastEventNonce
        );
    }

    /**
     * @dev Updates existing payee.
     * @param revenueAddress The revenue address.
     * @param stakingAddress The staking address.
     * @param shares_ The number of shares owned by the payee.
     * @param baseledgerValidatorAddress Identifier for the node within baseledger.
     */
    function updatePayee(
        address revenueAddress,
        address stakingAddress,
        uint256 shares_,
        string memory baseledgerValidatorAddress
    )
        public
        onlyPowerChanger
        zeroAddress(revenueAddress)
        zeroAddress(stakingAddress)
        emptyString(baseledgerValidatorAddress)
    {
        require(payees[revenueAddress] == true, "payee does not exist");
        totalShares = totalShares - shares[revenueAddress]; // remove the current share of the account from total shares.

        _updatePayeeSharesAndCurrentPeriod(
            revenueAddress,
            stakingAddress,
            shares_
        );

        emit PayeeUpdated(
            ubtTokenContractAddress,
            revenueAddress,
            baseledgerValidatorAddress,
            shares_,
            lastEventNonce
        );
    }

    /**
     * @dev Change the minimum required UBT deposit.
     * @param minDeposit_ The new amount of minimum deposit
     */
    function changeMinDeposit(uint256 minDeposit_) public onlyOwner {
        require(minDeposit_ > 0, "min deposit must be > 0");

        minDeposit = minDeposit_;
    }

    function _updatePayeeSharesAndCurrentPeriod(
        address revenueAddress,
        address stakingAddress,
        uint256 shares_
    ) private {
        stakingAddresses[revenueAddress] = stakingAddress;
        shares[revenueAddress] = shares_;
        totalShares = totalShares + shares_;
        lastEventNonce = lastEventNonce + 1;

        ubtToBeReleasedInPeriod = 0;
        ubtCurrentPeriod += 1;
        ubtNotReleasedInPreviousPeriods = IERC20(ubtTokenContractAddress)
            .balanceOf(address(this));
    }
}