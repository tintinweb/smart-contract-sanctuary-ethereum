// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

abstract contract Factory {
    function mint(uint256 _optionId, address _toAddress) virtual external returns (uint256);
    function mintBatch(uint256[] memory _ids, address _toAddress) virtual external returns (uint256[] memory, uint256[] memory);
    function balanceOf(address _owner, uint256 _optionId) virtual public view returns (uint256);
}


/**
 * @title LootBoxRandomness
 * LootBoxRandomness- support for a randomized and openable lootbox.
 */
library LootBoxRandomness {
  using SafeMath for uint256;

  // Event for logging lootbox opens
  event LootBoxOpened(uint256 optionId, address indexed buyer, uint256 itemsMinted, uint256 tokenId, uint256 itemsCount);
  event LootBoxBatchOpened(uint256[] _optionIds, address indexed buyer, uint256[] tokens, uint256[] amounts);
  event Warning(string message, address account);

  uint256 constant INVERSE_BASIS_POINT = 25000;
  uint256 constant GUARANTEE_COUNT = 1;
  // NOTE: Price of the lootbox is set via sell orders on OpenSea
  struct OptionSettings {
    // Probability in basis points (out of 10,000) of receiving each class (descending)
    uint256[] classProbabilities;
    // Probability class
    uint256[] classtoken;
    // is valid
    bool valid;
  }

  struct LootBoxRandomnessState {
      address factoryAddress;
      uint256 numOptions;
      mapping (uint256 => OptionSettings) optionToSettings;
      uint256 seed;
  }

  //////
  // INITIALIZATION FUNCTIONS FOR OWNER
  //////

  /**
   * @dev Set up the fields of the state that should have initial values.
   */
  function initState(
    LootBoxRandomnessState storage _state,
    address _factoryAddress,
    uint256 _seed
  ) public {
      _state.factoryAddress = _factoryAddress;
      _state.seed = _seed;
  }

  /**
   * @dev Set token IDs for each rarity class. Bulk version of `setTokenIdForClass`
   * @param _tokenIds List of token IDs to set for each class, specified above in order
   */
  //Requires ABIEncoderV2
  /*function setTokenIdsForClasses(
    LootBoxRandomnessState storage _state,
    uint256[][] memory _tokenIds
  ) public {
    require(_tokenIds.length == _state.numClasses, "wrong _tokenIds length");
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      setTokenIdsForClass(_state, i, _tokenIds[i]);
    }
    }*/

  /**
   * @dev Set the settings for a particular lootbox option
   * @param _boxId The Option to set settings for
   * @param _classProbabilities Array of probabilities (basis points, so integers out of 10,000)
   *                            of receiving each class (the index in the array).
   *                            Should add up to 10k and be descending in value.
   */
  function setOptionSettings(
    LootBoxRandomnessState storage _state,
    uint256 _boxId,
    uint256[] memory _classProbabilities,
    uint256[] memory _classtoken
  ) public {
    // Allow us to skip guarantees and save gas at mint time
    // if there are no classes with guarantees


    OptionSettings memory settings = OptionSettings({
      classProbabilities: _classProbabilities,
      classtoken: _classtoken,
      valid: true
    });

    _state.optionToSettings[uint256(_boxId)] = settings;

    _state.numOptions++;
  }

  /**
   * @dev Improve pseudorandom number generator by letting the owner set the seed manually,
   * making attacks more difficult
   * @param _newSeed The new seed to use for the next transaction
   */
  function setSeed(
    LootBoxRandomnessState storage _state,
    uint256 _newSeed
  ) public {
    _state.seed = _newSeed;
  }

  ///////
  // MAIN FUNCTIONS
  //////

  /**
   * @dev Main minting logic for lootboxes
   * This is called via safeTransferFrom when CreatureAccessoryLootBox extends
   * CreatureAccessoryFactory.
   * NOTE: prices and fees are determined by the sell order on OpenSea.
   * WARNING: Make sure msg.sender can mint!
   */
  function _mint(
    LootBoxRandomnessState storage _state,
    uint256 _tableId,
    uint256 _option,
    address _toAddress,
    bytes memory /* _data */
  ) internal returns (uint256) {
    // Load settings for this box option
    OptionSettings memory settings = _state.optionToSettings[_option];
    require(settings.valid, "LootBoxRandomness#_mint: invalid _optionId");

    
    // Process non-guaranteed ids
    uint256 index = _pickRandomClass(_state, settings.classProbabilities);

    uint256 tokenId = _sendToken(_state, settings.classtoken[index], _toAddress);

    // Event emissions
    emit LootBoxOpened(_tableId, _toAddress, settings.classtoken[index], tokenId, 1);

    return tokenId;
  }

  /////
  // HELPER FUNCTIONS
  /////

  // Returns the tokenId sent to _toAddress
  function _sendToken(
    LootBoxRandomnessState storage _state,
    uint256 _tableId,
    address _toAddress
  ) internal returns (uint256) {
    Factory factory = Factory(_state.factoryAddress);
    // This may mint, create or transfer. We don't handle that here.
    // We use tokenId as an option ID here.
    return factory.mint(_tableId, _toAddress);
  }

  // Returns the tokenId sent to _toAddress
  function _sendBatchToken(
    LootBoxRandomnessState storage _state,
    uint256[] memory _tokenIds,
    address _toAddress
  ) internal returns (uint256[] memory, uint256[] memory) {
    Factory factory = Factory(_state.factoryAddress);
    // This may mint, create or transfer. We don't handle that here.
    // We use tokenId as an option ID here.
    return factory.mintBatch(_tokenIds, _toAddress);
  }

  function _pickRandomClass(
    LootBoxRandomnessState storage _state,
    uint256[] memory _classProbabilities
  ) internal returns (uint256) {
    uint256 value = uint256(_random(_state).mod(INVERSE_BASIS_POINT));
    // Start at top class (length - 1)
    // skip common (0), we default to it
    for (uint256 i = 0; i < _classProbabilities.length; i++) {
      uint256 probability = _classProbabilities[i];
      if (value <= probability) {
        return i;
      }
    }
    //FIXME: assumes zero is common!
    return 0;
  }

  /**
   * @dev Pseudo-random number generator
   * NOTE: to improve randomness, generate it with an oracle
   */
  function _random(LootBoxRandomnessState storage _state) internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.timestamp.add(block.number - 1)), msg.sender, _state.seed)));
    _state.seed = randomNumber;
    return randomNumber;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}