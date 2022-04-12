/**
 *Submitted for verification at Etherscan.io on 2022-04-11
*/

// File: IChubbyKaijuDAOGEN2.sol

pragma solidity ^0.8.10;

/***************************************************************************************************
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------://:-----------------------------------------------------
------------------------------:/osys+-----smddddo:--------------------------------------------------
-----------------------------ommhysymm+--oMy/:/sNm/-------------------------------------------------
----------------------------oMy/::::/hNy:Nm:::::/mN/------------------------------------------------
----------------------------dM/:::::::oNNMs:::::/+Nm++++/::-----------------------------------------
----------------------------dM/::::::::+NM+::+shdmmmddddmNmdy+:-------------------------------------
----------------------------yM+:::::::::hMoymNdyo+////////+symNho-----------------------------------
----------------------------+My:::::::::dMNho/////////////////+yNNs---------------------------------
-----------------------:+sso+Mm:::::::yNmy+//////////////////////sNNo-------------------------------
----------------------yNdyyhdMMo::::omNs+/////////////////////////+hMh------------------------------
---------------------/Md:::::+Nm::/hMh+/////////////////////////////sNd:----------------------------
---------------------+My::::::yMs/dNs+///////////////////////////////oNd----------------------------
---------------------:Md:::::::dNmNo/////////+++////////////////shmdhosMy---------------------------
----------------------dM+::::::/NMs////////+hmdmdo/////////////yNy-:dNodM/--------------------------
----------------------:Nm/:::::sMy////////+mN:`-Nm+///////////+Mh   :MhsMy--------------------------
-----------------------sMm+::::NN+////////sMs   sMs///////////oMs   -Md+Md--------------------------
----------------------sNdmNo::sMm+////////sMo   -Mh///////++oosMm-..sMs/Mm:-------------------------
----------------------mM:/ym+sNmy+////////+Md```+My///+oydmmmmmddmmmNMhshNm+------------------------
----------------------oMy:::hMh+///////////yMddmNN++sdmmdys+///////shhhNmhmM/-----------------------
-----------------------yMh:yMy////////////+mNyo+++smNhoodhh+///////shy/+smMMh-----/+osoo+:----------
------------------------oNmMN//////////////++////hMy+///+Mh////////dM+///+hMy---odMmdhhdmNNdo-------
-------------------------:hMd/////////////////sd+++/////+dy////////os/////+NN-/m++Mh+/oo+/oymNs-----
---------------------------Mm///////////++///+NMy/////////////////////////+NN-+m-hMsoo/ooo++ohMy----
---------------------------yMy//////////////smNdMms+/////////+ossyso+////odMosdddNhoooooooosyyNM:---
----------------------------hMy+///////+s+//yy++NMmNdhyssyhdNNNmmmmNNdhhmmh+yhyMmddhhhhhymNdddmNd+--
------------------------:::--sNms+//////+///++//sMd+oyhhhyssdMmhhhhdMmhMd/odMNMNmdmhhddhMNs+//+oyNh:
----------------------+dddddh+oMNs//////////++///sNd+:::::::/dMdhhdNNooMy/MNyyyhhhhdddmMNmmmmdo//sMh
---------------------oNh+//+hMNdo/////////////////omNy+::::::+MNhmMmo/hM+-hMmddhhds/:/NNo++oos+///dM
--------------------:Nm::::+mNs+///////////////////+sdmdyo+++oMMNmy++yMMs-/MmhhdddmmdhMNhhyso+////hM
----------------::::oMs:::sNd+////////////////////////oshdmmmmdyo++odNhyNd/mmddhyyyyhmMdyyhmms////dM
--------------/hmmmdmMo::hMh+////++osssso++///////////////++++++oydNdo//omN+/+oyhdmNNNMy////+////+NN
-------------/Nm+::/sMh:hMy///+sdmNmdddmNmds+////////////oddddmNmhyo/////+dNo-----/MmodNhs+//////sMs
-------------dM/:::::ssdMs//+yNNho+o++oooshNNy+//////////+ssso++//////////+dM+---+mNo//shmm+////oNm-
-------------Mm:::::::hMy//+dMh/+ooo/oo/+ooohMd+////////+++////////////////+mN/yNNy+//////////+yNm:-
-------------NN::::::sMh///dMyo+oooooooooooooyMd//+shmmmdddmmdho////////////oMMms//////////+dNNh+---
-------------hM+::::+Mm+//+MmooooooooooooosyhhmMmhNhs/::---::/sdNh+////+yo//+MN+////////////dM+-----
-------------/Mh::::dMo///+MNyyyyyyhhhhhddhdmddmMd::-----------:/hNy+//+Mm//yMs////////////oMd------
--------------hM+::oMh////+MNhdhhdddmddmmmNNddddMN:---------------+mmo//dMo/+o+////////////dM+------
------------:ohMm::mM+//+hNMNmmNNmdddhhyhdhhhddhNM/----------------:dNo/sMy///////////////oMd-------
-----------+NmsyMs+Md///hMymMmMNNmooo//hmddddddmMh------------------:mm++Mm///////////////dM/-------
-----------dM/::hhyMs///dMoyMNs+hMNddmNNdddhssshMy-------------------+My/mM+/////////////sMh--------
-----------dM/::::mM+///sMhyMh/oNmo//oMNmmmmmmmmy:--------------------mN/hMs////////////+NN:--------
-----------sMs::::NN////+dMNM+/mMo///+NNy+/oNN/:----------------------sMoyMy///////////+dN+---------
------------mN/::/Mm/////+yMN+oMd///+mNo///+NN------------------------+MsoMh//////////omN+----------
------------/Nd/:/Md/////+hMNddMm+/+dMs///+hMs------------------------/My+Md////////+yNm/-----------
-------------+Md//Mm////+mNsosyyNNhmMMs++odMs-------------------------:Mh+MNhso++oydNdo-------------
--------------+Nm/NN///+mMo/////+ossodNNNmy/--------------------------:Mh/MNsdmmmdyo:---------------
***************************************************************************************************/

interface IChubbyKaijuDAOGEN2 {
  function ownerOf(uint256) external view returns (address owner);
  function transferFrom(address, address, uint256) external;
  function safeTransferFrom(address, address, uint256, bytes memory) external;
  function burn(uint16) external;
  function traits(uint256) external returns (uint16);
}
// File: IChubbyKaijuDAOCrunch.sol


pragma solidity ^0.8.10;

/***************************************************************************************************
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
-------------------------------------------://:-----------------------------------------------------
------------------------------:/osys+-----smddddo:--------------------------------------------------
-----------------------------ommhysymm+--oMy/:/sNm/-------------------------------------------------
----------------------------oMy/::::/hNy:Nm:::::/mN/------------------------------------------------
----------------------------dM/:::::::oNNMs:::::/+Nm++++/::-----------------------------------------
----------------------------dM/::::::::+NM+::+shdmmmddddmNmdy+:-------------------------------------
----------------------------yM+:::::::::hMoymNdyo+////////+symNho-----------------------------------
----------------------------+My:::::::::dMNho/////////////////+yNNs---------------------------------
-----------------------:+sso+Mm:::::::yNmy+//////////////////////sNNo-------------------------------
----------------------yNdyyhdMMo::::omNs+/////////////////////////+hMh------------------------------
---------------------/Md:::::+Nm::/hMh+/////////////////////////////sNd:----------------------------
---------------------+My::::::yMs/dNs+///////////////////////////////oNd----------------------------
---------------------:Md:::::::dNmNo/////////+++////////////////shmdhosMy---------------------------
----------------------dM+::::::/NMs////////+hmdmdo/////////////yNy-:dNodM/--------------------------
----------------------:Nm/:::::sMy////////+mN:`-Nm+///////////+Mh   :MhsMy--------------------------
-----------------------sMm+::::NN+////////sMs   sMs///////////oMs   -Md+Md--------------------------
----------------------sNdmNo::sMm+////////sMo   -Mh///////++oosMm-..sMs/Mm:-------------------------
----------------------mM:/ym+sNmy+////////+Md```+My///+oydmmmmmddmmmNMhshNm+------------------------
----------------------oMy:::hMh+///////////yMddmNN++sdmmdys+///////shhhNmhmM/-----------------------
-----------------------yMh:yMy////////////+mNyo+++smNhoodhh+///////shy/+smMMh-----/+osoo+:----------
------------------------oNmMN//////////////++////hMy+///+Mh////////dM+///+hMy---odMmdhhdmNNdo-------
-------------------------:hMd/////////////////sd+++/////+dy////////os/////+NN-/m++Mh+/oo+/oymNs-----
---------------------------Mm///////////++///+NMy/////////////////////////+NN-+m-hMsoo/ooo++ohMy----
---------------------------yMy//////////////smNdMms+/////////+ossyso+////odMosdddNhoooooooosyyNM:---
----------------------------hMy+///////+s+//yy++NMmNdhyssyhdNNNmmmmNNdhhmmh+yhyMmddhhhhhymNdddmNd+--
------------------------:::--sNms+//////+///++//sMd+oyhhhyssdMmhhhhdMmhMd/odMNMNmdmhhddhMNs+//+oyNh:
----------------------+dddddh+oMNs//////////++///sNd+:::::::/dMdhhdNNooMy/MNyyyhhhhdddmMNmmmmdo//sMh
---------------------oNh+//+hMNdo/////////////////omNy+::::::+MNhmMmo/hM+-hMmddhhds/:/NNo++oos+///dM
--------------------:Nm::::+mNs+///////////////////+sdmdyo+++oMMNmy++yMMs-/MmhhdddmmdhMNhhyso+////hM
----------------::::oMs:::sNd+////////////////////////oshdmmmmdyo++odNhyNd/mmddhyyyyhmMdyyhmms////dM
--------------/hmmmdmMo::hMh+////++osssso++///////////////++++++oydNdo//omN+/+oyhdmNNNMy////+////+NN
-------------/Nm+::/sMh:hMy///+sdmNmdddmNmds+////////////oddddmNmhyo/////+dNo-----/MmodNhs+//////sMs
-------------dM/:::::ssdMs//+yNNho+o++oooshNNy+//////////+ssso++//////////+dM+---+mNo//shmm+////oNm-
-------------Mm:::::::hMy//+dMh/+ooo/oo/+ooohMd+////////+++////////////////+mN/yNNy+//////////+yNm:-
-------------NN::::::sMh///dMyo+oooooooooooooyMd//+shmmmdddmmdho////////////oMMms//////////+dNNh+---
-------------hM+::::+Mm+//+MmooooooooooooosyhhmMmhNhs/::---::/sdNh+////+yo//+MN+////////////dM+-----
-------------/Mh::::dMo///+MNyyyyyyhhhhhddhdmddmMd::-----------:/hNy+//+Mm//yMs////////////oMd------
--------------hM+::oMh////+MNhdhhdddmddmmmNNddddMN:---------------+mmo//dMo/+o+////////////dM+------
------------:ohMm::mM+//+hNMNmmNNmdddhhyhdhhhddhNM/----------------:dNo/sMy///////////////oMd-------
-----------+NmsyMs+Md///hMymMmMNNmooo//hmddddddmMh------------------:mm++Mm///////////////dM/-------
-----------dM/::hhyMs///dMoyMNs+hMNddmNNdddhssshMy-------------------+My/mM+/////////////sMh--------
-----------dM/::::mM+///sMhyMh/oNmo//oMNmmmmmmmmy:--------------------mN/hMs////////////+NN:--------
-----------sMs::::NN////+dMNM+/mMo///+NNy+/oNN/:----------------------sMoyMy///////////+dN+---------
------------mN/::/Mm/////+yMN+oMd///+mNo///+NN------------------------+MsoMh//////////omN+----------
------------/Nd/:/Md/////+hMNddMm+/+dMs///+hMs------------------------/My+Md////////+yNm/-----------
-------------+Md//Mm////+mNsosyyNNhmMMs++odMs-------------------------:Mh+MNhso++oydNdo-------------
--------------+Nm/NN///+mMo/////+ossodNNNmy/--------------------------:Mh/MNsdmmmdyo:---------------
***************************************************************************************************/

interface IChubbyKaijuDAOCrunch {
  function mint(address to, uint256 amount) external;
  function burn(address from, uint256 amount) external;
  function balanceOf(address owner) external view returns(uint256);
  function transferFrom(address, address, uint256) external;
  function allowance(address owner, address spender) external view returns(uint256);
  function approve(address spender, uint256 amount) external returns(bool);
}
// File: IChubbyKaijuDAOStakingV2.sol


pragma solidity ^0.8.10;

interface IChubbyKaijuDAOStakingV2 {
  function stakeTokens(uint256[] calldata) external;
}
// File: IChubbyKaijuDAOStakingV2_Old.sol


pragma solidity ^0.8.10;

interface IChubbyKaijuDAOStakingV2_Old {
  struct TimeStake { uint256 tokenId; uint48 time; address owner; uint16 trait; uint16 reward_type;}
  function gen2StakeByToken() external view returns (TimeStake[] memory);
}
// File: Strings.sol



pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (bytes memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return buffer;
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}
// File: EnumerableSetUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSetUpgradeable {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}
// File: ECDSAUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}
// File: IERC721ReceiverUpgradeable.sol



pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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
// File: Initializable.sol



pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}
// File: ContextUpgradeable.sol



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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}
// File: PausableUpgradeable.sol



pragma solidity ^0.8.0;



/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
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
    uint256[49] private __gap;
}
// File: OwnableUpgradeable.sol



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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
    uint256[49] private __gap;
}
// File: ChubbyKaijuDAOStakingV2.sol

pragma solidity ^0.8.10;











/***************************************************************************************************
kkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkkxxddddddddddddddxxxxxdd
kkkkkkkkkkkkkkkkkkkkkkkxxkkkkkkkkkkkkkkkkkkkkkkkkkkxxxxxkxkkkkkkkkkkkkkkkkkkkkkxxddddddddddddxxkkkxx
kkkkkkkkkkkkkkkkkkkkkkkkkkkxxxkkkkkkkkkkkkkkkkkkkkkkxxdddddxxxxxkkkkkkkkkkkkkkkkxxddddddddddddxxkxkk
kkkkkkkkkkkkkkkkkkkkxxxxxddddxxkxxkkxxkkkkkkkxxkkxxkkkxxddddddddxxxxkkkkkkkkxxkkkxxddddddddddddxxkkk
kkkkkkkkkkkkkkkxxxxddddddddxxxxkxxoooodxkkkkkxxdooddxkxxkkkxxxxdddddxxxkkkkkkkkkkkxxdddddddddddddxkk
kkkkkkkkkkkkxxxdddddoddxxxxkkkxl,.',,''.',::;'.''','',lxxxkkkkxxddddddxxxkkkxxxxxkkxddddddddddddddxk
kkkkkkkkxxxdddddddddddxxxxdddo,.,d0XXK0kdl;,:ok0KKK0x;.'lxxxxxxxxddddddddxxkkxxxxxxddodddddddddddddx
kkkkkxxxddddddddddddddddddddl'.:KMMMMMMMMNKXWMMMWWMMWXc..';;;:cloddddddddddxkkxxdddddodddddddddddddd
kkxxxddddddddddddddddddddddc..c0WMMMMMMMMWXNMMMMMMMWk;,',;::;,'..':oxxxxddodxxxkxxdddddxdddddddddddd
kxxdddddddddddddddddddddoc'.'d0XWMMMMMMMMMWMMMMMMMMWXOKNWWMMMWX0kl,.'cdkkxxxddddxdddxxkkkxxxdddddddd
xddddxxxxxxdddddddddddl:'.,xXNKKNMMMMMMMMMMMMMMMMMMMWMMMMMMMMMMMMMNk:..cxkkxxxddddddxkkkkkkkxddddddd
xxxxxkkkxxxdddddddddo;..ckNMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNk,.,dxxkkxxxdddxkkkkkxkkxdddddd
kkkkxxxxdddddddoddo:..c0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXo..cxkkkkkxxxxkkkkkkkkkxddddd
kkkxxxddoddddddddd:..xNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNXNWWMMMMMMMMMMWNO,.;dkkkkkxkkxxkkkkkkkxxdddd
kxxxdddddo:'',;:c;. lNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWNNWMMMMMWMMMWMMMXc.'okxkkkkkkkkkkkkkkkxdddd
xxdddddodo' .;,',,,:ONWMMMMMMMMMMMMMMMMMMMMMMMMMMMMXxc;;:xXMMMMMMMMMMMWNNNXd..lkkkkkkkkkxkkkkkkkxddd
ddddddddddc..oKKXWWWWWWMMMMMMMMMMMMMMMMMMMMMMMMMWkc'      ,0MMMMMMMMMWNNNXNWx..okkkkkkkkkkkkkkkkxdod
dddddddddddl..l0XNNWWWMMWXNMMMMMMMMMMMMMMMMMMMMNd.   ....  :XMMMMMMWWW0l,,;d0l.,xkkkxkkkkkkkkkkkxddd
ddddddddddxko'.,lxO0KXNNO;cXMMMMMMMMMMMMMMMMMMMk.  ....... .kMMMMMMMWk.     :x'.lkkkkkkkkkkkkkkkkxdd
ddddddddxxxkkxl;'.'',:cl:..dWMMMMMMMMMMMMMMMMMWl  ........ .kMMMMMMMNc  ... .c, :xxkkkkkkkkkkkkkkxdd
dddddddxkkkkkkkkxdoc:;,''. ;KMMMMMMMMMMMMMMMMMWl  .......  ,KWWMWX0Ox'       '..cxxkkkkkkkkkkkkkkxdd
dddddxxkkkkkkkkxxkkxkkkkxo'.oWMMMMMMMMMMMMMMMMMO'    ...  .xKkoc;,,,;,.   ,:;,...:dkxkkxkkkkkkkkkxdd
ddddxxkkkkkkkkkkkkkxkkxxddc..kWMMMMMMMMMMMMMMMMMXdc:.. ..;:;...'oOXNWO:colkWMWXk;.,xkxkkkkkkkkkkkxdd
ddxxkkxxkkkkkkkkkkkkxxddddo;.;KMMMMMMMMMMMMMMMMMMMMWX0O0XXxcod;cKMMMMWKl:OMMMMMM0,.lkxkkkkkkkkkkkxdd
dxxkkkkkkkkkkkkxxkkxxddddddo,.:XMMMMMMMMMMMMMMMMMMMMMMMMMMMWMKc:KMMMMMNxoKMMWMMM0,.lkxxxkkkkkkkkxxdd
xxkkkkkkkkkkkkkkkkxxddddddddl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNNWMWMMMMWWMMMWMMNl.,dkkkxkkkkkkkkxddd
xkkkkkkkkkkkkkkkkxdddddddddodl'.cXMMMMMMMMMMMMMMMMMMMMMMMMMMKdOWNxo0WNxlOWKcoXNo..okxxkkkkkkkkkkxddd
kkkkkkkkkkkkkkkkkxddodddddddddo'.,OWMMMMMMMMMMMMMMMMMMMMMN0Oc .lc. .l:. .;. .,, .lkxxkkkkkkkkkkxxddd
kkkkkkkkkkkkkkkkxddddddddddddddo' cNMMMMMMMMMMMMMMMMMMMMMKl,;'. .,,. .'. .,. '' 'xkkxkkkkkkkkkkxdddd
kkkkkkkkkkkkkkkkxddoddddl:,'..';. :NMMMMMMMMMMMMMMMMMMMMMWWWWKlc0WNd,xNx;kWx;xl ,xkkkkxxkkxxkkxxdddd
kkkkkkkkkkkkkkkkxdddddo:..:dxdl'  ,0MMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMWWWMWWMMWWK; :kkkkkkkkkkxkkxddddd
kkkkkkkkkxkkkkkxxdoddo; 'kNMWMNl.'kNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWMMMK:.'dkkkkkxkkkkkkxdddddd
kkkkkkkkkkkxkkkxxddddo' lXNMMWo.:KMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMN0o' 'dkkkkxxkkkkkkxxdddddd
kkkkkkkxkkkkkkkxdc;,,'.,kXNMMWK0NMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWNNXXO:,,..ckkkkxkkkxkkxxddddddd
kkkkkkkkkxxkxkxc..;loox0KKNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNNNNNXXXXXXXXXXXKXXk'.cxkxkkxkkkxxdddddddd
kkkkkkkkkkkkxkl..xNMMMMWNXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWNNWWWWWMMMMMMWO'.ckxkkxkxxxdoddddddx
kkkkkkkkkkkkkx, cNMMMMMMMWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWx..okkkkxddddddddddxx
kkkkkkkkkkkkkx, cNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo.'dkxxddddddddddxkk
kkkkkkkkkxkxxx: ,0WMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWWWWWWWMMMMMMMMMMMMMX; :ddddddddoddxxkkx
kkkkkkkkxxkkxko..dNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNNNNXXXXXXXNNWMMMMMMMMMWk..cdddddddddxxkxxd
kkkkkkkxxkkxkkx, cXWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNNWWMMMMMMMWWWNNNNWMMMMMMMMN: ,oddddddxxxkxxdd
kkkkkkkkkkkxkko..oXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWNNWMMMMMMMMMMMMMMMMWWWMMMMMMMMWk..ldddddxkkxkkxxx
xkkkkkkkkkkxkd,.lXWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMX; ;dddxxkkkkxxkkk
xxkkkkkkkxkkk: :XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWo 'dxxkkkkkkkkkkk
dxkkkkkkkkxkx, dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMO..okxkkkkkkkkkkx
ddxkkxkkkkxkd'.dMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWWWMMMMX; ckkkkkkkkkkxxd
dodxxkkkkxkkx; cWMMMMWNWMMMMMMMMMMMWWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWNNWMMMWc ;xkkkxkkkxxddd
dddddxxkkkkxkl..OWMMWNXWMMMMMMMMMMMNNWMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMNXNMMMMd.'dkkkkxxdddddd
ddddddxxkkkkkx; :KWWN0KWMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMMk..okxxxdddddddd
ddddddddxxkkkkl..xXX0ccKMMMMMMMMMMWXNMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWXXWMMM0'.lxddddddddddd
***************************************************************************************************/

contract ChubbyKaijuDAOStakingV2 is IChubbyKaijuDAOStakingV2, OwnableUpgradeable, IERC721ReceiverUpgradeable, PausableUpgradeable {
  using ECDSAUpgradeable for bytes32;
  using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

  using Strings for uint128;

  uint32 public totalZombieStaked; // trait 0
  uint32 public totalAlienStaked; // trait 1
  uint32 public totalUndeadStaked; // trait 2

  uint48 public lastClaimTimestamp;

  uint48 public constant MINIMUM_TO_EXIT = 1 days;

  uint128 public constant MAXIMUM_CRUNCH = 18000000 ether; 
  uint128 public remaining_crunch = 17999872 ether;  // for 10 halvings
  uint128 public halving_phase = 0;

  uint128 public totalCrunchEarned;

  uint128 public CRUNCH_EARNING_RATE = 1024; //40; //74074074; // 1 crunch per day; H
  mapping(uint16=>uint128) public species_rate; 
  uint128 public constant TIME_BASE_RATE = 100000000;

  event TokenStaked(string kind, uint256 tokenId, address owner);
  event TokenUnstaked(string kind, uint256 tokenId, address owner, uint128 earnings);

  IChubbyKaijuDAOGEN2 private chubbykaijuGen2;
  IChubbyKaijuDAOCrunch private chubbykaijuDAOCrunch;
  IChubbyKaijuDAOStakingV2_Old private chubbykaijuGen2StakingOld;

  mapping(address => EnumerableSetUpgradeable.UintSet) private _gen2StakedTokens;
  mapping(address => mapping(uint256 => uint48)) private _gen2StakedTimes;

  mapping(uint256 => uint16) public gen2RewardTypes; 

  struct rewardTypeStaked{
    uint32  common_gen2; // reward_type: 0 -> 1*1*(1+Time weight)
    uint32  uncommon_gen2; // reward_type: 1 -> 1*1*(1+Time weight)
    uint32  rare_gen2; // reward_type: 2 -> 2*1*(1+Time weight)
    uint32  epic_gen2; // reward_type: 3 -> -> 3*1*(1+Time weight)
    uint32  legendary_gen2; // reward_type: 4 -> 5*1*(1+Time weight)
    uint32  one_gen2; // reward_type: 5 -> 15*1*(1+Time weight)
  }

  rewardTypeStaked private rewardtypeStaked;

  function initialize() public initializer {
    __Ownable_init();
    __Pausable_init();
    _pause();
  }

  function setSpeciesRate() public onlyOwner{
    species_rate[0] = 125;
    species_rate[1] = 150;
    species_rate[2] = 200;
  }

  function setRewardTypes(uint256[] calldata tokenIds, uint16 rewardType) public onlyOwner{
    for (uint16 i = 0; i < tokenIds.length; i++) {
      gen2RewardTypes[tokenIds[i]] = rewardType;
    }
  }

  function migrateFromOldContract() external onlyOwner {
    IChubbyKaijuDAOStakingV2_Old.TimeStake[] memory tokens = chubbykaijuGen2StakingOld.gen2StakeByToken();

    for (uint16 i = 0; i < tokens.length; i++) {
       _stakeGEN2(tokens[i].owner, tokens[i].tokenId, tokens[i].time);
    }
  }

  function stakeTokens(uint256[] calldata tokenIds) external whenNotPaused _updateEarnings {
    
    for (uint16 i = 0; i < tokenIds.length; i++) {
      _stakeGEN2(msg.sender, tokenIds[i], uint48(block.timestamp));
      chubbykaijuGen2.safeTransferFrom(msg.sender, address(this), tokenIds[i], '');
    }
  
  }

  function _stakeGEN2(address account, uint256 tokenId, uint48 time) internal {

    uint16 trait = (tokenId <= 6666 ? 1 : tokenId <= 9999 ? 1 : 2);

    if(trait == 0){
      totalZombieStaked += 1;
    }else if(trait == 1){
      totalAlienStaked += 1;
    }else if(trait == 2){
      totalUndeadStaked += 1;
    }

    uint16 reward_type = gen2RewardTypes[tokenId];

    if(reward_type == 0){
      rewardtypeStaked.common_gen2 +=1;
    }else if(reward_type == 1){
      rewardtypeStaked.uncommon_gen2 +=1;
    }else if(reward_type == 2){
      rewardtypeStaked.rare_gen2 +=1;
    }else if (reward_type == 3){
      reward_type = 3;
      rewardtypeStaked.epic_gen2 +=1;
    }else if(reward_type == 4){
      rewardtypeStaked.legendary_gen2 +=1;
    }else if(reward_type == 5){
      rewardtypeStaked.one_gen2 +=1;
    }

    _gen2StakedTokens[account].add(tokenId);
    _gen2StakedTimes[account][tokenId] = time;

    emit TokenStaked("CHUBBYKAIJUGen2", tokenId, account);
  }

  function claimRewardsAndUnstake(uint256[] calldata tokenIds, bool unstake) external whenNotPaused _updateEarnings {
    require(tx.origin == msg.sender, "eos only");

    uint128 reward;
    uint48 time = uint48(block.timestamp);

    for (uint8 i = 0; i < tokenIds.length; i++) {
      reward += _claimGen2(tokenIds[i], unstake, time);
    }

    if (reward != 0) {
      chubbykaijuDAOCrunch.mint(msg.sender, reward);
    }
  }


  function _claimGen2(uint256 tokenId, bool unstake, uint48 time) internal returns (uint128 reward) {
    require(_gen2StakedTokens[msg.sender].contains(tokenId), "only owners can unstake");
    
    uint16 trait = (tokenId <= 6666 ? 1 : tokenId <= 9999 ? 1 : 2);
    uint16 reward_type = gen2RewardTypes[tokenId];
    uint48 stake_time = _gen2StakedTimes[msg.sender][tokenId];

    require(!(unstake && block.timestamp - stake_time < MINIMUM_TO_EXIT), "need 1 day to unstake");

    reward = _calculateGEN2Rewards(tokenId);

    if (unstake) {

      if(trait == 0){
        totalZombieStaked -= 1;
      }else if(trait == 1){
        totalAlienStaked -= 1;
      }else if(trait == 2){
        totalUndeadStaked -= 1;
      }

      if(reward_type == 0){
        rewardtypeStaked.common_gen2 -=1;
      }else if(reward_type == 1){
        rewardtypeStaked.uncommon_gen2 -= 1;
      }else if(reward_type == 2){
        rewardtypeStaked.rare_gen2 -= 1;
      }else if(reward_type == 3){
        rewardtypeStaked.epic_gen2 -= 1;
      }else if(reward_type == 4){
        rewardtypeStaked.legendary_gen2 -= 1;
      }else if(reward_type == 5){
        rewardtypeStaked.one_gen2 -= 1;
      }
      _gen2StakedTokens[msg.sender].remove(tokenId); 
      delete _gen2StakedTimes[msg.sender][tokenId];

      chubbykaijuGen2.safeTransferFrom(address(this), msg.sender, tokenId, '');

      emit TokenUnstaked("CHUBBYKAIJUGen2", tokenId, msg.sender, reward);
    } else {

      _gen2StakedTimes[msg.sender][tokenId] = time;

    }
    
  }


  function _calculateGEN2Rewards(uint256  tokenId) internal view returns (uint128 reward) {
    require(tx.origin == msg.sender, "eos only");

    uint48 time = uint48(block.timestamp);

    uint16 trait = (tokenId <= 6666 ? 1 : tokenId <= 9999 ? 1 : 2);
    uint16 reward_type = gen2RewardTypes[tokenId];
    uint48 stake_time = _gen2StakedTimes[msg.sender][tokenId];

    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint128 time_weight = time-stake_time > 3600*24*120? 2*TIME_BASE_RATE: 20*(time-stake_time);
      if(reward_type == 0){
        reward = 1*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(time-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    } 
    else if (stake_time <= lastClaimTimestamp) {
      uint128 time_weight = lastClaimTimestamp-stake_time > 3600*24*120? 2*TIME_BASE_RATE: 20*(lastClaimTimestamp-stake_time);
      if(reward_type == 0){
        reward = 1*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 1){
        reward = 1*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 2){
        reward = 2*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 3){
        reward = 3*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 4){
        reward = 5*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }else if(reward_type == 5){
        reward = 15*1*(lastClaimTimestamp-stake_time)*CRUNCH_EARNING_RATE;
        reward *= (TIME_BASE_RATE+time_weight);
      }
    }
    reward *= species_rate[trait];
  }

  function calculateGEN2Rewards(uint256  tokenId) external view returns (uint128) {
    return _calculateGEN2Rewards(tokenId);
  }

  modifier _updateEarnings() {
    if (totalCrunchEarned < MAXIMUM_CRUNCH) {
      uint48 time = uint48(block.timestamp);
      uint128 temp = (1*1*(time - lastClaimTimestamp)*CRUNCH_EARNING_RATE*rewardtypeStaked.common_gen2);
      uint128 temp2 = (100000000+20*(time - lastClaimTimestamp))*150;
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (1*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.uncommon_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (2*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.rare_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (3*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.epic_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (5*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.legendary_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;

      temp = (15*1*(time - lastClaimTimestamp)*(CRUNCH_EARNING_RATE)*rewardtypeStaked.one_gen2);
      temp *= temp2;
      totalCrunchEarned += temp;
      
      lastClaimTimestamp = time;
    }
    if(MAXIMUM_CRUNCH-totalCrunchEarned < remaining_crunch/2 && halving_phase < 10){
      CRUNCH_EARNING_RATE /= 2;
      remaining_crunch /= 2;
      halving_phase += 1;
    }
    _;
  }

  function GEN2depositsOf(address account) external view returns (uint256[] memory) {
    EnumerableSetUpgradeable.UintSet storage depositSet = _gen2StakedTokens[account];
    uint256[] memory tokenIds = new uint256[] (depositSet.length());

    for (uint16 i; i < depositSet.length(); i++) {
      tokenIds[i] = uint256(depositSet.at(i));
    }

    return tokenIds;
  }

  function togglePaused() external onlyOwner {
    if (paused()) {
      _unpause();
    } else {
      _pause();
    }
  }

  function setGen2Contract(address _address) external onlyOwner {
    chubbykaijuGen2 = IChubbyKaijuDAOGEN2(_address);
  }

  function setCrunchContract(address _address) external onlyOwner {
    chubbykaijuDAOCrunch = IChubbyKaijuDAOCrunch(_address);
  }

  function setOldContract(address _address) external onlyOwner {
    chubbykaijuGen2StakingOld = IChubbyKaijuDAOStakingV2_Old(_address);
  }

  function onERC721Received(address, address, uint256, bytes calldata) external pure override returns (bytes4) {    
    //require(from == address(0x0), "only allow directly from mint");
    return IERC721ReceiverUpgradeable.onERC721Received.selector;
  }
}