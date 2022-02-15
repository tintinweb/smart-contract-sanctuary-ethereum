// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/Address.sol";

/*
  This fundraising has the following features:
    - Anyone can setup a fundraising, for themselves or for others
    - The beneficiary can be set only once
    - There's a minimum contribution set by the deployer
    - There's a target funding set by the deployer
    - You can donate in your name, or in the name of others
    - You can repent and get back your collaboration, for a fee
    - The beneficiary can withdraw the funds:
        - Anytime, if the funding goal has been met
        - 30 days from the start of the fundraising otherwise
    - Anyone can start the funding anytime
    - The beneficiary can end the funding by withdrawing the funds
*/

contract Fundraising {

    struct Collaboration {
        uint256 amount;
        uint256 timestamp;
    }

    uint256 immutable _minCollab;
    uint256 immutable _targetFunds;
    uint256 fundingEndDate;
    bool fundraisingOpened;

    address public beneficiary; 
    mapping (address => Collaboration) public collaborations;
    
   
    modifier onlyBeneficiary() {
        require (beneficiary == msg.sender, "Not the beneficiary");
        _;
    }

    function getBalance() public view returns(uint256) {
        return address(this).balance;
    }
    
    constructor (uint256 minCollab, uint256 targetFunds) {
        _minCollab = minCollab;
        _targetFunds = targetFunds;
    }

    // You can make anyone the beneficiary of your fundraising, 
    // but you can't change it once it was set
    function setBeneficiary(address newBeneficiary) public {
        // The beneficiary can only be set once
        require(beneficiary == address(0), "You can't change the beneficiary anymore");

        // Since the beneficiary needs to retrieve the funds, it can't be a contract
        bool isContract = Address.isContract(newBeneficiary);
        require(isContract == false, "The new owner is not valid.");

        beneficiary = newBeneficiary;
    }

    // You need to start the fundraising to begin receiving funds
    function startFundraising() public {
        require(beneficiary != address(0), "Set the beneficiary first");
        fundingEndDate = block.timestamp + 30 days;
        fundraisingOpened = true;
    }

    // Contribute to the fundraising with your own account
    function fund() public payable {
        require(msg.value > 0, "You have to contribute something");
        require(fundraisingOpened, "The fundraising is closed");
        require(checkAmount(msg.sender, msg.value), "You can't contribute less than minimum");

        // You can fund as many times as you want, as long it's more than the minimum
        collaborations[msg.sender].amount += msg.value;
        collaborations[msg.sender].timestamp = block.timestamp;
    }

    // Contribute to the fundraising in the name of someone else's account
    function fundAs(address donor) public payable {
        require(msg.value > 0, "You have to contribute something");
        require(fundraisingOpened, "The fundraising is closed");
        require(checkAmount(msg.sender, msg.value), "You can't contribute less than minimum");

        // You can fund for others as many times as you want, as long it's more than the minimum
        collaborations[donor].amount += msg.value;
        collaborations[donor].timestamp = block.timestamp;
    }

    function checkAmount(address user, uint256 amount) internal view returns(bool v){
        v = (collaborations[user].amount + amount >= _minCollab);
    }    


    // Withdraw your funds before the end of the fundraising. 
    // This means you no longer want to contribute anything to the beneficiary.
    // However, to prevent abuse, a penalty of 10% of your contribution will be burned.
    function repent() public {
        require(fundraisingOpened, "The fundraising is closed");
        require(collaborations[msg.sender].amount >= _minCollab, "Your collaboration is unable to be refunded");

        uint256 available = (collaborations[msg.sender].amount * 90) / 100;
        uint256 penalty = collaborations[msg.sender].amount - available;

        // To prevent new repentance, set collaboration to 0
        collaborations[msg.sender].amount = 0;
        collaborations[msg.sender].timestamp = 0;

        payable(msg.sender).transfer(available);
        payable(0x000000000000000000000000000000000000dEaD).transfer(penalty);
    }

    // Get the results of the fundraising
    function retrieveFunds() public onlyBeneficiary {
        // The beneficiary can only retrieve the funds if 30 days have passed, or if the funding target is met
        require(block.timestamp > fundingEndDate || address(this).balance >= _targetFunds, "The fundraising hasn't finished yet");

        fundraisingOpened = false;

        payable(beneficiary).transfer( address(this).balance );
    }

    // If for some weird reason an account's contribution is invalid, anyone can send the funds back to the account
    // The caller gets an incentive of 50% of the returned funds
    function refundInvalid(address user) public {
        require(collaborations[user].amount < _minCollab && collaborations[user].amount > 0, "Not an invalid amount");

        // Calculate refund and incentives
        uint256 toReturn =  collaborations[user].amount / 2;
        uint256 incentive = collaborations[user].amount - toReturn;

        // Update internal accounting
        collaborations[user].amount = 0;
        collaborations[user].timestamp = 0;
        collaborations[msg.sender].amount += incentive;
        collaborations[msg.sender].timestamp = block.timestamp;

        // Move the funds
        payable(user).transfer(toReturn);
        payable(msg.sender).transfer(incentive);
    }

    receive() external payable {
        revert();
    }
    
    fallback() external {
        revert();
    }

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