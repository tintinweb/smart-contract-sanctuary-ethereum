// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "Base64.sol";
import "Strings.sol";
import "IStakefishValidator.sol";
import "Utils.sol";

library NFTRenderer {
    struct RenderParams {
        uint256 tokenId;
        string nftArtURL;
        address nftManager;
        address walletAddress;
        uint256 validatorIndex;
        bytes validatorPubkey;
        uint256 earlyAccessDiscount;
        uint256 volumeDiscount;
        IStakefishValidator.StateChange state;
    }

    function render(RenderParams memory params) public pure returns (string memory) {
        string memory description = renderDescription(params);
        string memory name = string.concat("stakefish validator #", Strings.toString(params.tokenId));
        string memory json = string.concat(
            '{"name":"', name,'",',
                '"description":"',description,'",',
                '"image": "', params.nftArtURL, Strings.toString(params.tokenId),'",',
                '"attributes":[', renderAttributes(params),']}'
        );

        return string.concat(
            "data:application/json;base64,",
            Base64.encode(bytes(json))
        );
    }

    function renderAttributes(RenderParams memory params) internal pure returns (string memory attributes) {
        if(params.earlyAccessDiscount > 0) {
            attributes = string.concat('{"trait_type": "Early Access Discount", "value": "', Strings.toString(params.earlyAccessDiscount/100), '"}');
        }
        if(params.volumeDiscount > 0) {
            if(params.earlyAccessDiscount > 0) {
                attributes = string.concat(attributes, ',');
            }
            attributes = string.concat(attributes, '{"trait_type": "Volume Discount", "value": "', Strings.toString(params.volumeDiscount/100), '"}');
        }
    }

    function renderDescription(RenderParams memory params) internal pure returns (string memory description) {
        description = string.concat(
            "This NFT represents a stakefish Ethereum validator minted with 32 ETH. ",
            "Owner of this NFT controls the withdrawal credentials, receives protocol rewards, and receives fee/mev rewards.\\n",
            "More stats at: https://stake.fish/ethereum/nft/", Strings.toString(params.tokenId),
            "\\n\\nNFT Manager: ", Strings.toHexString(uint256(uint160(params.nftManager)), 20),
            "\\nValidator Index: ", Strings.toString(params.validatorIndex),
            "\\n\\nDISCLAIMER: Due diligence is important when evaluating this NFT. Make sure issuer/nft manager match the official nft manager on stake.fish, as token symbols may be imitated."
        );
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
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
        return string(buffer);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/// @title The interface for StakefishValidator
/// @notice Defines implementation of the wallet (deposit, withdraw, collect fees)
interface IStakefishValidator {

    event StakefishValidatorDeposited(bytes validatorPubKey);
    event StakefishValidatorExitRequest(bytes validatorPubKey);
    event StakefishValidatorStarted(bytes validatorPubKey, uint256 startTimestamp);
    event StakefishValidatorExited(bytes validatorPubKey, uint256 stopTimestamp);
    event StakefishValidatorWithdrawn(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorCommissionTransferred(bytes validatorPubKey, uint256 amount);
    event StakefishValidatorFeePoolChanged(bytes validatorPubKey, address feePoolAddress);

    enum State { PreDeposit, PostDeposit, Active, ExitRequested, Exited, Withdrawn, Burnable }

    /// @dev aligns into 32 byte
    struct StateChange {
        State state;            // 1 byte
        bytes15 userData;       // 15 byte (future use)
        uint128 changedAt;      // 16 byte
    }

    /// @notice initializer
    function setup() external;

    function validatorIndex() external view returns (uint256);
    function pubkey() external view returns (bytes memory);

    /// @notice Inspect state of the change
    function lastStateChange() external view returns (StateChange memory);

    /// @notice Submits a Phase 0 DepositData to the eth2 deposit contract.
    /// @dev https://github.com/ethereum/consensus-specs/blob/master/solidity_deposit_contract/deposit_contract.sol#L33
    /// @param validatorPubKey A BLS12-381 public key.
    /// @param depositSignature A BLS12-381 signature.
    /// @param depositDataRoot The SHA-256 hash of the SSZ-encoded DepositData object.
    function makeEth2Deposit(
        bytes calldata validatorPubKey, // 48 bytes
        bytes calldata depositSignature, // 96 bytes
        bytes32 depositDataRoot
    ) external;

    /// @notice Operator updates the start state of the validator
    /// Updates validator state to running
    /// State.PostDeposit -> State.Running
    function validatorStarted(
        uint256 _startTimestamp,
        uint256 _validatorIndex,
        address _feePoolAddress) external;

    /// @notice Operator updates the exited from beaconchain.
    /// State.ExitRequested -> State.Exited
    /// emit ValidatorExited(pubkey, stopTimestamp);
    function validatorExited(uint256 _stopTimestamp) external;

    /// @notice NFT Owner requests a validator exit
    /// State.Running -> State.ExitRequested
    /// emit ValidatorExitRequest(pubkey)
    function requestExit() external;

    /// @notice user withdraw balance and charge a fee
    function withdraw() external;

    /// @notice ability to change fee pool
    function validatorFeePoolChange(address _feePoolAddress) external;

    /// @notice get pending fee pool rewards
    function pendingFeePoolReward() external view returns (uint256, uint256);

    /// @notice claim fee pool and forward to nft owner
    function claimFeePool(uint256 amountRequested) external;

    /// @notice get early access discount
    function earlyAccessDiscount() external view returns (uint);

    /// @notice volume discount
    function volumeDiscount() external view returns (uint);

    /// @notice calculates effect fee after discounts
    function effectiveFee() external view returns (uint256);

    /// @notice computes commission, useful for showing on UI
    function computeCommission(uint256 amount) external view returns (uint256);

    function render() external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

library Utils {
    bytes16 internal constant ALPHABET = '0123456789abcdef';

    function toHexStringNoPrefix(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length);
        for (uint256 i = buffer.length; i > 0; i--) {
            buffer[i - 1] = ALPHABET[value & 0xf];
            value >>= 4;
        }
        return string(buffer);
    }

    /* @notice              Slice the _bytes from _start index till the result has length of _length
                            Refer from https://github.com/summa-tx/bitcoin-spv/blob/master/solidity/contracts/BytesLib.sol#L246
    *  @param _bytes        The original bytes needs to be sliced
    *  @param _start        The index of _bytes for the start of sliced bytes
    *  @param _length       The index of _bytes for the end of sliced bytes
    *  @return              The sliced bytes
    */
    function slice(
        bytes memory _bytes,
        uint _start,
        uint _length
    )
        internal
        pure
        returns (bytes memory)
    {
        require(_bytes.length >= (_start + _length));

        bytes memory tempBytes;

        assembly {
            switch iszero(_length)
            case 0 {
                // Get a location of some free memory and store it in tempBytes as
                // Solidity does for memory variables.
                tempBytes := mload(0x40)

                // The first word of the slice result is potentially a partial
                // word read from the original array. To read it, we calculate
                // the length of that partial word and start copying that many
                // bytes into the array. The first word we copy will start with
                // data we don't care about, but the last `lengthmod` bytes will
                // land at the beginning of the contents of the new array. When
                // we're done copying, we overwrite the full first word with
                // the actual length of the slice.
                // lengthmod <= _length % 32
                let lengthmod := and(_length, 31)

                // The multiplication in the next line is necessary
                // because when slicing multiples of 32 bytes (lengthmod == 0)
                // the following copy loop was copying the origin's length
                // and then ending prematurely not copying everything it should.
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)

                for {
                    // The multiplication in the next line has the same exact purpose
                    // as the one above.
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)

                //update free-memory pointer
                //allocating the array padded to 32 bytes like the compiler does now
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            //if we want a zero-length slice let's just return a zero-length array
            default {
                tempBytes := mload(0x40)

                mstore(0x40, add(tempBytes, 0x20))
            }
        }

        return tempBytes;
    }
}