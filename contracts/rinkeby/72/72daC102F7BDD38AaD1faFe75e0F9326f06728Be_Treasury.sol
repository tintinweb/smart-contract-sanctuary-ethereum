// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";


interface FrogInterface {
  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Returns true if frog is king
   */
  function isKing(uint256 _frogId) external view returns (bool);
}


contract Treasury {
  event Received(address, uint);
  event NewSpendProposal(address indexed to, uint256 amount, string note, uint256 proposalId);
  event Vote(address indexed kingOwner, uint256 kingId, uint256 proposalId);
  event Transfer(address indexed to, uint256 amount, string note, uint256 proposalId);

  struct SpendProposal {
    address to;
    uint256 amount;
    string note;
    mapping(uint256 => bool) voted;  // king id to vote status
    uint64 createAt;
    bool isExpired;
    uint8 voteCount;
    uint256 proposalId;
  }

  mapping(uint256 => SpendProposal) spendProposals;
  uint256 public numberOfSpendProposal;

  FrogInterface Frogsylvania;
  uint256 public NumberOfKings;

  constructor(uint256 _numberOfKings, address _frogsylvaniaContract) {
    NumberOfKings = _numberOfKings;
    Frogsylvania = FrogInterface(_frogsylvaniaContract);
  }

  modifier onlyTreasurer {
    require(msg.sender == Frogsylvania.ownerOf(0), "sender is not treasurer");  // Treasurer King ID is zero
    _;
  }

  modifier onlyKings(uint256 _kingId) {
    require(msg.sender == Frogsylvania.ownerOf(_kingId), "sender is not king owner");  // Treasurer King ID is zero
    require(Frogsylvania.isKing(_kingId), "frog is not king");
    _;
  }

  /**
   * @dev for receive ether
   */
  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  /**
   * @dev add new spend proposal
   * @param _to finally send amount to this address
   * @param _amount proposal amount
   * @param _note a note about spend proposal
   */
  function addSpendProposal(address _to, uint256 _amount, string memory _note) onlyTreasurer external {
    SpendProposal storage s = spendProposals[numberOfSpendProposal];
    s.to = _to;
    s.amount = _amount;
    s.note = _note;
    s.createAt = uint64(block.timestamp);
    s.isExpired = false;
    s.voteCount = 0;
    s.proposalId = numberOfSpendProposal;

    emit NewSpendProposal(_to, _amount, _note, numberOfSpendProposal);
    numberOfSpendProposal += 1;
  }

  /**
   * @dev voting to a proposal
   * @param _kingId sender king id
   * @param _proposalId spend proposal id
   */
  function voteToSpend(uint256 _kingId, uint256 _proposalId) onlyKings(_kingId) external {
    require(_proposalId < numberOfSpendProposal, "spend proposal doesn't existed");
    SpendProposal storage s = spendProposals[_proposalId];

    require(s.voted[_kingId] == false, "can't vote twice");
    require(s.isExpired == false, "spend proposal is expired");

    s.voteCount += 1;
    s.voted[_kingId] = true;

    emit Vote(msg.sender, _kingId, _proposalId);
  }

  /**
   * @dev execute proposal votes and send
   * @param _proposalId proposal id
   */
  function executeSpendProposal(uint256 _proposalId) external {
    require(_proposalId < numberOfSpendProposal, "spend proposal doesn't existed");

    SpendProposal storage s = spendProposals[_proposalId];
    require(s.isExpired == false, "spend proposal is expired");
    require(s.voteCount > (NumberOfKings / 2), "the number of votes for execute spend proposal is not enough");

    Address.sendValue(payable(s.to), s.amount);
    s.isExpired = true;
    emit Transfer(s.to, s.amount, s.note, _proposalId);
  }


  /**
   * @dev treasurer can expire a proposal
   * @param _proposalId proposal id
   */
  function expireProposal(uint256 _proposalId) onlyTreasurer external {
    require(_proposalId < numberOfSpendProposal, "spend proposal doesn't existed");

    SpendProposal storage s = spendProposals[_proposalId];
    s.isExpired = true;
  }


  /**
   * @dev get proposal details
   * @param _proposalId proposal id
   */
  function getProposal(uint256 _proposalId) external view returns (
    address to,
    uint256 amount,
    string memory note,
    uint64 createAt,
    bool isExpired,
    uint8 voteCount,
    uint256 proposalId
  )
  {
    require(_proposalId < numberOfSpendProposal, "spend proposal doesn't existed");
    SpendProposal storage s = spendProposals[_proposalId];

    to = s.to;
    amount = s.amount;
    note = s.note;
    createAt = s.createAt;
    isExpired = s.isExpired;
    voteCount = s.voteCount;
    proposalId = s.proposalId;
  }

  /**
   * @dev return kings vote
   * @param _kingId king id
   * @param _proposalId proposal id
   */
  function kingVote(uint256 _kingId, uint256 _proposalId) external view returns (bool) {
    require(_proposalId < numberOfSpendProposal, "spend proposal doesn't existed");
    SpendProposal storage s = spendProposals[_proposalId];
    return s.voted[_kingId];
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