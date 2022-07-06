// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../../utils/math/SafeMath.sol";
abstract contract Factory {
  function unBox(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) virtual external;
  function balanceOfItem(uint256 _optionId) virtual public view returns (uint256);
}

library BoxRandomness {
  using SafeMath for uint256;

  struct OptionSettings {
    uint256 maxQuantityPerOpen;
    uint256[] classProbabilities;
    uint16[] guarantees;
    bool hasGuaranteedClasses;          
  }

  struct BoxRandomnessState {
    address factoryAddress;
    uint256 numOptions;
    uint256 numClasses;
    uint256 seed;
    mapping(uint256 => OptionSettings) optionToSettings;
    mapping(uint256 => uint256[]) classToTokenIds;
  }

  uint256 constant INVERSE_BASIS_POINT = 9999999;

  event BoxOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);
  event Warning(string message, address account);

  function initState(
    BoxRandomnessState storage _state,
    address _factoryAddress,
    uint256 _numOptions,
    uint256 _numClasses,
    uint256 _seed
  ) public {
    _state.factoryAddress = _factoryAddress;
    _state.numOptions = _numOptions;
    _state.numClasses = _numClasses;
    _state.seed = _seed;
  }

  function setClassForTokenId(
    BoxRandomnessState storage _state,
    uint256 _tokenId,
    uint256 _classId
  ) public {
    require(_classId < _state.numClasses, "BR: class out of range");
    _addTokenIdToClass(_state, _classId, _tokenId);
  }

  function setTokenIdsForClass(
    BoxRandomnessState storage _state,
    uint256 _classId,
    uint256[] memory _tokenIds
  ) public {
    require(_classId < _state.numClasses, "BR: class out of range");
    _state.classToTokenIds[_classId] = _tokenIds;
  }

  function resetClass(BoxRandomnessState storage _state, uint256 _classId) public {
    require(_classId < _state.numClasses, "BR: class out of range");
    delete _state.classToTokenIds[_classId];
  }

  function setOptionSettings(
    BoxRandomnessState storage _state,
    uint256 _option,
    uint256 _maxQuantityPerOpen,
    uint256[] memory _classProbabilities,
    uint16[] memory _guarantees
  ) public {
    require(_option < _state.numOptions, "BR: option out of range");
    bool hasGuaranteedClasses = false;
    for (uint256 i = 0; i < _guarantees.length; i++) {
      if (_guarantees[i] > 0) {
        hasGuaranteedClasses = true;
      }
    }

    OptionSettings memory settings = OptionSettings({
      maxQuantityPerOpen: _maxQuantityPerOpen,
      classProbabilities: _classProbabilities,
      guarantees: _guarantees,
      hasGuaranteedClasses: hasGuaranteedClasses
    });

    _state.optionToSettings[uint256(_option)] = settings;
  }

  function setSeed(BoxRandomnessState storage _state, uint256 _newSeed) public {
    _state.seed = _newSeed;
  }

  function _mint(
    BoxRandomnessState storage _state,
    uint256 _optionId,
    address _toAddress,
    uint256 _amount,
    bytes memory
  ) internal {
    require(_optionId < _state.numOptions, "BR: option out of range");
    OptionSettings memory settings = _state.optionToSettings[_optionId];
    require(settings.maxQuantityPerOpen > 0, "BR: option not supported");

    uint256 totalMinted = 0;
    for (uint256 i = 0; i < _amount; i++) {
      uint256 quantitySent = 0;
      if (settings.hasGuaranteedClasses) {
        for (uint256 classId = 0; classId < settings.guarantees.length; classId++) 
        {
          uint256 quantityOfGuaranteed = settings.guarantees[classId];
          if (quantityOfGuaranteed > 0) {
            _sendTokenWithClass(_state, classId, _toAddress, quantityOfGuaranteed);
            quantitySent += quantityOfGuaranteed;
          }
        }
      }   

      // non-guaranteed ids
      while (quantitySent < settings.maxQuantityPerOpen) {
        uint256 quantityOfRandomized = 1;
        uint256 class = _pickRandomClass(_state, settings.classProbabilities);
        _sendTokenWithClass(_state, class, _toAddress, quantityOfRandomized);
        quantitySent += quantityOfRandomized;
      }

      totalMinted += quantitySent;
    }

    emit BoxOpened(_optionId, _toAddress, _amount, totalMinted);
  }

  function _sendTokenWithClass(
    BoxRandomnessState storage _state,
    uint256 _classId,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
    require(_classId < _state.numClasses, "BR: class out of range");
    Factory factory = Factory(_state.factoryAddress);
    uint256 tokenId = _pickRandomAvailableTokenIdForClass(_state, _classId, _amount);
    factory.unBox(tokenId, _toAddress, _amount, "");
    return tokenId;
  }

  function _pickRandomClass(BoxRandomnessState storage _state, uint256[] memory _classProbabilities) internal returns (uint256) {
    uint256 value = uint256(_random(_state).mod(INVERSE_BASIS_POINT));
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint256 probability = _classProbabilities[i];
      if (value < probability) {
        return i;
      } else {
        value = value - probability;
      }
    }

    return 0;
  }

  function _pickRandomAvailableTokenIdForClass(
    BoxRandomnessState storage _state,
    uint256 _classId,
    uint256 _minAmount
  ) internal returns (uint256) {
    require(_classId < _state.numClasses, "BR: class out of range");
    uint256[] memory tokenIds = _state.classToTokenIds[_classId];
    require(tokenIds.length > 0, "BR: no tokenId in this class");
    uint256 randIndex = _random(_state).mod(tokenIds.length);
    Factory factory = Factory(_state.factoryAddress);
    for (uint256 i = randIndex; i < randIndex + tokenIds.length; i++) {
      uint256 tokenId = tokenIds[i % tokenIds.length];
      if (factory.balanceOfItem(tokenId) >= _minAmount) {
        return tokenId;
      }
    }
    revert("BR: not enough tokens for this class");
  }

  function _random(BoxRandomnessState storage _state) internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _state.seed)));
    _state.seed = randomNumber;
    return randomNumber;
  }

  function _addTokenIdToClass(
    BoxRandomnessState storage _state,
    uint256 _classId,
    uint256 _tokenId
  ) internal {
    _state.classToTokenIds[_classId].push(_tokenId);
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
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
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
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