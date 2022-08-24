pragma solidity ^0.8.0;

import "./EternalStorage.sol";
import "@openzeppelin/contracts/token/ERC777/IERC777Recipient.sol";

contract HelloWorld is EternalStorage, IERC777Recipient {
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external override {

    }
}

// This code has not been professionally audited, therefore I cannot make any promises about
// safety or correctness. Use at own risk.

/**
 * @title EternalStorage
 * @author Praktikanti Moonstruck-a
 * @dev Baza podataka za implementacije proxija koji radimo praksi.
 *
 * gbugfbvajksnfjkdasnfjkdasnvjkadnvjkdan
 * dsaffkjdbsfkjadnsljfnasljfxnadskjfnsdlaj
 */
contract EternalStorage {
    mapping(bytes32 => uint) internal uIntStorage;
    mapping(bytes32 => address) internal addressStorage;

    // *** Getter Methods ***

    /**
     * @dev Function to retrieve uint value from store.
     * @param _key An bytes32 value, which is hash of value to be retreivd from the store.
     * @return An uint value of the provided key.
     */
    function getUint(bytes32 _key) external view returns(uint) {
        return uIntStorage[_key];
    }

    function getAddress(bytes32 _key) external view returns(address) {
        return addressStorage[_key];
    }

    // *** Setter Methods ***

    /**
     * @dev Function to retrieve uint value from store.
     * @param _key An bytes32 key, which is hash of key to be retreivd from the store.
     * @param _value A value to be stored, with uint type.
     */
    function setUint(bytes32 _key, uint _value) external {
        uIntStorage[_key] = _value;
    }

    function setAddress(bytes32 _key, address _value) external {
        addressStorage[_key] = _value;
    }

    // *** Delete Methods ***
    function deleteUint(bytes32 _key) external {
        delete uIntStorage[_key];
    }

    function deleteAddress(bytes32 _key) external {
        delete addressStorage[_key];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}