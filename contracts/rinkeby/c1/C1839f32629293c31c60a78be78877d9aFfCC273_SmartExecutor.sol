/**
 *Submitted for verification at Etherscan.io on 2022-02-18
*/

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
  /**
   * @dev Returns true if this contract implements the interface defined by
   * `interfaceId`. See the corresponding
   * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
   * to learn more about how these ids are created.
   *
   * This function call must use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return interfaceId == type(IERC165).interfaceId;
  }
}
// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

  /**
   * @dev Returns the number of tokens in ``owner``'s account.
   */
  function balanceOf(address owner) external view returns (uint256 balance);

  /**
   * @dev Returns the owner of the `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function ownerOf(uint256 tokenId) external view returns (address owner);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   *
   * Emits a {Transfer} event.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the token or be an approved operator.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approve(address to, uint256 tokenId) external;

  /**
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

  /**
   * @dev Approve or remove `operator` as an operator for the caller.
   * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   *
   * Emits an {ApprovalForAll} event.
   */
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
  /**
   * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
   * by `operator` from `from`, this function is called.
   *
   * It must return its Solidity selector to confirm the token transfer.
   * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
   *
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
  /**
   * @dev Returns the token collection name.
   */
  function name() external view returns (string memory);

  /**
   * @dev Returns the token collection symbol.
   */
  function symbol() external view returns (string memory);

  /**
   * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
   */
  function tokenURI(uint256 tokenId) external view returns (string memory);
}

// File: @openzeppelin/contracts/utils/Address.sol

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

    (bool success, ) = recipient.call{ value: amount }("");
    require(
      success,
      "Address: unable to send value, recipient may have reverted"
    );
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
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        "Address: low-level call with value failed"
      );
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
    require(
      address(this).balance >= value,
      "Address: insufficient balance for call"
    );
    require(isContract(target), "Address: call to non-contract");

    (bool success, bytes memory returndata) = target.call{ value: value }(data);
    return verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, "Address: low-level static call failed");
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
  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        "Address: low-level delegate call failed"
      );
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


pragma solidity ^0.8.9;

contract ProxyReader {
    error IncorrectDataTypeError();
    error ReadingContractError();

    function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    	if(bytes(a).length != bytes(b).length) {
        	return false;
	    } else {
	        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
	    }
	}

	function toLower(string memory str) internal pure returns (string memory) {
        bytes memory bStr = bytes(str);
        bytes memory bLower = new bytes(bStr.length);
        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
                // So we add 32 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 32);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }

	function contains(string memory where, string memory what) internal pure returns (bool) {
    	bytes memory whatBytes = bytes (toLower(what));
    	bytes memory whereBytes = bytes (toLower(where));

    	if (whatBytes.length > whereBytes.length) {
    		return false;
    	}

	    bool found = false;

	    for (uint i = 0; i <= whereBytes.length - whatBytes.length; i++) {
	        bool flag = true;

	        for (uint j = 0; j < whatBytes.length; j++) {
	        	if (whereBytes [i + j] != whatBytes [j]) {
	                flag = false;
	                break;
	            }
	        }
	            
	        if (flag) {
	            found = true;
	            break;
	        }
	    }

    	return found;
	}
	
	function readFromContract(address contractAddress, string memory getFunctionSignature) internal returns(bytes memory) {
		if (contractAddress == 0x0000000000000000000000000000000000000000) {
			contractAddress = address(this);
		}

		(bool success, bytes memory data) = contractAddress.call(
            abi.encodeWithSelector(bytes4(keccak256(abi.encodePacked(getFunctionSignature))))
        );

        if (success) {
        	return data;
    	} else {
    		revert ReadingContractError();
    	}
	}

    function readUint256FromContract(address contractAddress, string memory getFunctionSignature) internal returns(uint256) {
    	return abi.decode(readFromContract(contractAddress, getFunctionSignature),(uint256));
	}

    function readBoolFromContract(address contractAddress, string memory getFunctionSignature) internal returns(bool) {
    	return abi.decode(readFromContract(contractAddress, getFunctionSignature),(bool));
	}

    function readAddressFromContract(address contractAddress, string memory getFunctionSignature) internal returns(address) {
    	return abi.decode(readFromContract(contractAddress, getFunctionSignature),(address));
	}

    function readBytes32FromContract(address contractAddress, string memory getFunctionSignature) internal returns(bytes32) {
    	return abi.decode(readFromContract(contractAddress, getFunctionSignature),(bytes32));
	}

    function readStringFromContract(address contractAddress, string memory getFunctionSignature) internal returns(string memory) {
    	return abi.decode(readFromContract(contractAddress, getFunctionSignature),(string));
	}
}

contract ConditionChecker is ProxyReader {
 	error ComparisonTypeError();
    
	enum SourceType {
		CONSTANT_VALUE,
		READ_CONTRACT
	}

	enum UInt256Comparator { 
		EQUALS, 
		GREATER_THAN, 
		GREATER_THAN_OR_EQUALS, 
		LESS_THAN,
		LESS_THAN_OR_EQUALS
	}

	enum BoolComparator { 
		EQUALS,
		NOT
	}

	enum AddressComparator { 
		EQUALS
	}

	enum Bytes32Comparator { 
		EQUALS
	}

	enum StringComparator { 
		EQUALS,
		CONTAINS
	}

	struct UInt256Condition {
		UInt256Comparator comparator;
        SourceType p1_type;
        uint256 p1_value;
        address p1_address;
        string  p1_function;
        SourceType p2_type;
        uint256 p2_value;
        address p2_address;
        string  p2_function;
        string errMsg;
    }

	struct BoolCondition {
		BoolComparator comparator;
        SourceType p1_type;
        bool p1_value;
        address p1_address;
        string  p1_function;
        SourceType p2_type;
        bool p2_value;
        address p2_address;
        string  p2_function;
        string errMsg;
    }

	struct AddressCondition {
		AddressComparator comparator;
        SourceType p1_type;
        address p1_value;
        address p1_address;
        string  p1_function;
        SourceType p2_type;
        address p2_value;
        address p2_address;
        string  p2_function;
        string errMsg;
    }

	struct Bytes32Condition {
		Bytes32Comparator comparator;
        SourceType p1_type;
        bytes32 p1_value;
        address p1_address;
        string  p1_function;
        SourceType p2_type;
        bytes32 p2_value;
        address p2_address;
        string  p2_function;
        string errMsg;
    }

	struct StringCondition {
		StringComparator comparator;
        SourceType p1_type;
        string p1_value;
        address p1_address;
        string  p1_function;
        SourceType p2_type;
        string p2_value;
        address p2_address;
        string  p2_function;
        string errMsg;
    }

    struct Conditions {
		UInt256Condition[] uint256Conditions;
		BoolCondition[] boolConditions;
		AddressCondition[] addressConditions;
		Bytes32Condition[] bytes32Conditions;
		StringCondition[] stringConditions;
    }
    
	function validateCondition(UInt256Condition memory data) internal returns(bool valid, string memory message) {
		uint256 v1;
		uint256 v2;

		valid = true;

		if (data.p1_type == SourceType.CONSTANT_VALUE) {
			v1 = data.p1_value;
		} else if (data.p1_type == SourceType.READ_CONTRACT) {
			v1 = readUint256FromContract(data.p1_address, data.p1_function);
		}

		if (data.p2_type == SourceType.CONSTANT_VALUE) {
			v2 = data.p2_value;
		} else if (data.p2_type == SourceType.READ_CONTRACT) {
			v2 = readUint256FromContract(data.p2_address, data.p2_function);
		}

		if (data.comparator == UInt256Comparator.EQUALS) {
			if (v1 != v2) {
				valid = false;
				message = 'Not equals';
			}
		} else if (data.comparator == UInt256Comparator.GREATER_THAN) {
			if (!(v1 > v2)) {
				valid = false;
				message = 'Not gt';
			}
		} else if (data.comparator == UInt256Comparator.GREATER_THAN_OR_EQUALS) {
			if (!(v1 >= v2)) {
				valid = false;
				message = 'Not gte';
			}
		} else if (data.comparator == UInt256Comparator.LESS_THAN) {
			if (!(v1 < v2)) {
				valid = false;
				message = 'Not lt';
			}
		} else if (data.comparator == UInt256Comparator.LESS_THAN_OR_EQUALS) {
			if (!(v1 <= v2)) {
				valid = false;
				message = 'Not lte';
			}
		} else {
			valid = false;
		}
	} 

	function validateCondition(BoolCondition memory data) internal returns(bool valid, string memory message) {
		bool v1;
		bool v2;

		valid = true;

		if (data.p1_type == SourceType.CONSTANT_VALUE) {
			v1 = data.p1_value;
		} else if (data.p1_type == SourceType.READ_CONTRACT) {
			v1 = readBoolFromContract(data.p1_address, data.p1_function);
		}

		if (data.p2_type == SourceType.CONSTANT_VALUE) {
			v2 = data.p2_value;
		} else if (data.p2_type == SourceType.READ_CONTRACT) {
			v2 = readBoolFromContract(data.p2_address, data.p2_function);
		}

		if (data.comparator == BoolComparator.EQUALS) {
			if (v1 != v2) {
				valid = false;
				message = 'Not equals';
			}
		} else if (data.comparator == BoolComparator.NOT) {
			if (v1 == true) {
				valid = false;
				message = 'Condition is true';
			}
		} else {
			valid = false;
			message = 'Comparator invalid';
		}
	} 

	function validateCondition(AddressCondition memory data) internal returns(bool valid, string memory message) {
		address v1;
		address v2;

		valid = true;

		if (data.p1_type == SourceType.CONSTANT_VALUE) {
			v1 = data.p1_value;
		} else if (data.p1_type == SourceType.READ_CONTRACT) {
			v1 = readAddressFromContract(data.p1_address, data.p1_function);
		}

		if (data.p2_type == SourceType.CONSTANT_VALUE) {
			v2 = data.p2_value;
		} else if (data.p2_type == SourceType.READ_CONTRACT) {
			v2 = readAddressFromContract(data.p2_address, data.p2_function);
		}

		if (data.comparator == AddressComparator.EQUALS) {
			if (v1 != v2) {
				valid = false;
				message = 'Not equals';
			}
		} else {
			valid = false;
			message = 'Comparator invalid';
		}
	} 

	function validateCondition(Bytes32Condition memory data) internal returns(bool valid, string memory message) {
		bytes32 v1;
		bytes32 v2;

		valid = true;

		if (data.p1_type == SourceType.CONSTANT_VALUE) {
			v1 = data.p1_value;
		} else if (data.p1_type == SourceType.READ_CONTRACT) {
			v1 = readBytes32FromContract(data.p1_address, data.p1_function);
		}

		if (data.p2_type == SourceType.CONSTANT_VALUE) {
			v2 = data.p2_value;
		} else if (data.p2_type == SourceType.READ_CONTRACT) {
			v2 = readBytes32FromContract(data.p2_address, data.p2_function);
		}

		if (data.comparator == Bytes32Comparator.EQUALS) {
			if (v1 != v2) {
				valid = false;
				message = 'Not equals';
			}
		} else {
			valid = false;
			message = 'Comparator invalid';
		}
	} 

	function validateCondition(StringCondition memory data) internal returns(bool valid, string memory message) {
		string memory v1;
		string memory v2;

		valid = true;

		if (data.p1_type == SourceType.CONSTANT_VALUE) {
			v1 = data.p1_value;
		} else if (data.p1_type == SourceType.READ_CONTRACT) {
			v1 = readStringFromContract(data.p1_address, data.p1_function);
		}

		if (data.p2_type == SourceType.CONSTANT_VALUE) {
			v2 = data.p2_value;
		} else if (data.p2_type == SourceType.READ_CONTRACT) {
			v2 = readStringFromContract(data.p2_address, data.p2_function);
		}

		if (data.comparator == StringComparator.EQUALS) {
			if (!compareStrings(v1, v2)) {
				valid = false; 
				message = 'Not equals';
			}
		} else if (data.comparator == StringComparator.CONTAINS) {
			if (!contains(v1, v2)) {
				valid = false;
				message = 'Not contains';
			}
		} else {
			valid = false;
			message = 'Comparator invalid';
		}
	} 
	
	function validateConditions(Conditions memory conditions) internal returns(bool valid, string memory message) {
		valid = true;
		
		for (uint256 i = 0; i < conditions.uint256Conditions.length; i++) {
			(bool _valid, string memory _message) = validateCondition(conditions.uint256Conditions[i]);

			if (!_valid) {
				valid = _valid;
				message = conditions.uint256Conditions[i].errMsg;

				if (compareStrings(message, 'generic error') && compareStrings(_message, '')) {
					message = _message;
				}
				break;
			}
		}

		if (valid) {
			for (uint256 i = 0; i < conditions.boolConditions.length; i++) {
				(bool _valid, string memory _message) = validateCondition(conditions.boolConditions[i]);

				if (!_valid) {
					valid = _valid;
					message = conditions.boolConditions[i].errMsg;

					if (compareStrings(message, 'generic error') && compareStrings(_message, '')) {
						message = _message;
					}
					break;
				}
			}

			if (valid) {
				for (uint256 i = 0; i < conditions.addressConditions.length; i++) {
					(bool _valid, string memory _message) = validateCondition(conditions.addressConditions[i]);

					if (!_valid) {
						valid = _valid;
						message = conditions.addressConditions[i].errMsg;

						if (compareStrings(message, 'generic error') && compareStrings(_message, '')) {
							message = _message;
						}
						break;
					}
				}

				if (valid) {
					for (uint256 i = 0; i < conditions.bytes32Conditions.length; i++) {
						(bool _valid, string memory _message) = validateCondition(conditions.bytes32Conditions[i]);

						if (!_valid) {
							valid = _valid;
							message = conditions.bytes32Conditions[i].errMsg;

							if (compareStrings(message, 'generic error') && compareStrings(_message, '')) {
								message = _message;
							}
							break;
						}
					}

					if (valid) {
						for (uint256 i = 0; i < conditions.stringConditions.length; i++) {
							(bool _valid, string memory _message) = validateCondition(conditions.stringConditions[i]);

							if (!_valid) {
								valid = _valid;
								message = conditions.stringConditions[i].errMsg;

								if (compareStrings(message, 'generic error') && compareStrings(_message, '')) {
									message = _message;
								}
								break;
							}
						}
					}
				}
			}
		}
	}
}

contract ActionDoer is ConditionChecker {
	struct Action {
		Conditions conditions;
		address contractAddress;
		string functionSignature;
		bytes parameters;
		uint256 value;
    }

	struct ActionWithouConditions {
		address contractAddress;
		string functionSignature;
		bytes parameters;
		uint256 value;
    }
	
	function doActions(Action[] memory actions, bool createNewContractsPerTx) internal {
		ProxyContract proxyContract;

		if (createNewContractsPerTx) {
			proxyContract = new ProxyContract();
		}

		for (uint256 i = 0; i < actions.length; i++) {
			Action memory action = actions[i];
			
			(bool valid, ) = validateConditions(action.conditions);

			if (valid) {
				if (createNewContractsPerTx) {
					ActionWithouConditions memory _action = ActionWithouConditions(
						action.contractAddress,
						action.functionSignature,
						action.parameters,
						action.value
					);

					proxyContract.doAction{value: action.value}(_action);
				} else {
					address _contract = action.contractAddress;

					if (_contract == 0x0000000000000000000000000000000000000000) {
						_contract = address(this);
					}

					(bool success, bytes memory data) = _contract.call{value: action.value}(
						abi.encodePacked(
							abi.encodeWithSelector(bytes4(keccak256(abi.encodePacked(action.functionSignature)))),
			            	action.parameters
						)
			        );
				}
			}
		}
	}
}

contract ProxyContract is IERC721Receiver, ERC165 {
  address public creator;
	
  constructor() {
  	creator = msg.sender;
  }

  function onERC721Received(address a1, address a2, uint256 t1, bytes memory b) public returns(bytes4) {
    return this.onERC721Received.selector;
  }

  function doAction(ActionDoer.ActionWithouConditions memory action) external payable {
    	address _contract = action.contractAddress;

		if (_contract == 0x0000000000000000000000000000000000000000) {
			_contract = address(this);
		}

        (bool success, bytes memory data) = _contract.call{value: action.value}(
			abi.encodePacked(
				abi.encodeWithSelector(bytes4(keccak256(abi.encodePacked(action.functionSignature)))),
            	action.parameters
			)
        );
   }

   function getBlockTimestamp() external view returns(uint256 blockTimestamp) {
        blockTimestamp = block.timestamp;
   }

   function getBalance() external view returns(uint256 balance) {
        balance = address(this).balance;
   }

   function withdrawAll() external {
    	payable(creator).transfer(address(this).balance);
   }

   fallback() external payable {
   }
}

contract SmartExecutor is ActionDoer, IERC721Receiver, ERC165 {
	address public creator;
	uint256 public current;

	constructor() {
		creator = msg.sender;
	}

	function onERC721Received(address a1, address a2, uint256 t1, bytes memory b) public returns(bytes4) {
    	return this.onERC721Received.selector;
  	}

	function increment(uint256 number) external {
		current += number;
	}

    function getBalance() external view returns(uint256 balance) {
        balance = address(this).balance;
    }

    function getBlockTimestamp() external view returns(uint256 blockTimestamp) {
        blockTimestamp = block.timestamp;
    }

    function withdrawAll() external {
    	payable(creator).transfer(address(this).balance);
    }

    function execActions(Action[] memory actions) external payable {
    	doActions(actions, false);
    }

	function exec(
		Action[] memory preActions,
		Conditions memory mainConditions,
		uint256 loopCount,
		Action[] memory actions,
		bool createNewContractsPerTx
	) external payable {
		doActions(preActions, false);

		(bool valid, string memory message) = validateConditions(mainConditions);

		require (valid, message);

		for (uint256 i = 0; i < loopCount; i++) {
			doActions(actions, createNewContractsPerTx);
		}
	}

	fallback() external payable {
    }
}