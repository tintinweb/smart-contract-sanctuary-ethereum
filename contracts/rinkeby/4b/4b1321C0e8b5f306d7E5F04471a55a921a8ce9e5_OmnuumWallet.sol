// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

import '@openzeppelin/contracts/utils/Address.sol';

contract OmnuumWallet {
    using Address for address;
    using Address for address payable;

    // =========== EVENTs =========== //
    event FeeReceived(address indexed nftContract, address indexed sender, uint256 value);
    event Requested(uint256 indexed reqId, address indexed requester);
    event Approved(uint256 indexed reqId, address indexed owner);
    event Revoked(uint256 indexed reqId, address indexed owner);
    event Withdrawn(uint256 indexed reqId, address indexed receiver, uint256 value);

    // =========== STORAGEs =========== //
    address[] public owners;
    mapping(address => bool) public isOwner; //owner address => true/false
    mapping(uint256 => mapping(address => bool)) approvals; //reqId => address => approval
    struct Request {
        address destination;
        uint256 value;
        bool withdrawn;
    } // withdrawal destination address, amount of withdrawal, tag for withdrawn
    Request[] public requests;

    // =========== MODIFIERs =========== //
    modifier onlyOwners() {
        require(isOwner[msg.sender], 'only owner');
        _;
    }
    modifier reqExists(uint256 _id) {
        require(_id < requests.length, 'request not exist');
        _;
    }
    modifier notApproved(uint256 _id) {
        require(!approvals[_id][msg.sender], 'already approved');
        _;
    }
    modifier isApproved(uint256 _id) {
        require(approvals[_id][msg.sender], 'not approved');
        _;
    }
    modifier notWithdrawn(uint256 _id) {
        require(!requests[_id].withdrawn, 'already withdrawn');
        _;
    }
    modifier isAllAgreed(uint256 _id) {
        require(getApprovalCount(_id) == owners.length, 'consensus not reached');
        _;
    }

    // =========== CONSTRUCTOR =========== //
    constructor(address[] memory _owners) {
        //minimum 2 owners are required for multi sig wallet
        require(_owners.length > 1, 'single owner');

        //Register owners
        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];
            require(!isOwner[owner], 'Owner exists');
            require(!owner.isContract(), 'not EOA');
            require(owner != address(0), 'Invalid address');

            isOwner[owner] = true;
            owners.push(owner);
        }
    }

    // =========== FEE RECEIVER =========== //
    fallback() external payable {
        // msg.data will be address for NFT proxy contract
        address nftContract;
        bytes memory _data = msg.data;
        assembly {
            nftContract := mload(add(_data, 20))
        }
        emit FeeReceived(nftContract, msg.sender, msg.value);
    }

    // =========== WALLET LOGICs =========== //
    function approvalRequest(uint256 _withdrawalValue) external onlyOwners returns (uint256) {
        require(_withdrawalValue <= address(this).balance, 'request value exceeds balance');

        requests.push(Request({ destination: msg.sender, value: _withdrawalValue, withdrawn: false }));

        uint256 reqId = requests.length - 1;

        approve(reqId);

        emit Requested(reqId, msg.sender);
        return (reqId);
    }

    function approve(uint256 _reqId) public onlyOwners reqExists(_reqId) notApproved(_reqId) notWithdrawn(_reqId) {
        approvals[_reqId][msg.sender] = true;
        emit Approved(_reqId, msg.sender);
    }

    function checkApproval(uint256 _reqId, address _approver) public view returns (bool) {
        return approvals[_reqId][_approver];
    }

    function getApprovalCount(uint256 _reqId) public view returns (uint256) {
        uint256 count;
        for (uint256 i; i < owners.length; i++) {
            if (checkApproval(_reqId, owners[i])) {
                count++;
            }
        }
        return count;
    }

    function revokeApproval(uint256 _reqId) external onlyOwners reqExists(_reqId) isApproved(_reqId) notWithdrawn(_reqId) {
        approvals[_reqId][msg.sender] = false;
        emit Revoked(_reqId, msg.sender);
    }

    function withdrawal(uint256 _reqId) external onlyOwners reqExists(_reqId) notWithdrawn(_reqId) isAllAgreed(_reqId) {
        Request storage request = requests[_reqId];
        require(msg.sender == request.destination, 'withdrawer must be the requester');

        request.withdrawn = true;
        payable(request.destination).sendValue(request.value);
        emit Withdrawn(_reqId, request.destination, request.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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