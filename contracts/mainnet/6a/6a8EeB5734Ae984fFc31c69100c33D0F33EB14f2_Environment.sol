// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./GridHelper.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library Environment {
  uint internal constant TOTAL_BASIC_COLOURS = 5;
  uint internal constant TOTAL_EMBELLISHED_COLOURS = 6;
  uint internal constant TOTAL_DEGRADED_COLOURS = 8; // includes grey

  // LW, RW, FLOOR
  string internal constant EXECUTIVE_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant LAB_COLOUR_PERCENTAGES = "040020025000070000";
  string internal constant FACTORY_COLOUR_PERCENTAGES = "040020025000070000";

  // Darker Gray, Orange, Dark Gray, Red, Light Gray, Orange, Lightest Gray, Red
  string internal constant EXECUTIVE_DEGRADED_HSL = "120001015120001035120001061120002088019068078019032045019058048002047049";
  string internal constant LAB_DEGRADED_HSL = "120001015120001035120001061120002088156015049050047054276021058155037049";
  string internal constant FACTORY_DEGRADED_HSL = "120001015120001035120001061120002088021042074203032059319029046243031039";

  // EXECUTIVE
  // Combined without shades
  string internal constant EXECUTIVE_COLOURS_BASIC = "000000069240003029000000069240003029000000069000000069240003013000000069354100060240003013000000069240003013240003029047100050240003013240003029240003013240003029121082050240003013240003029240003013240003029221082050240003013354100060000100004000100004022100050041100050047100050021081004021081004030100013022100045221081088194090077200075078195086089200084076";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED = "121082050093090004099074009095085054099075072093090004221082050194089004199074009195085054199075080194089004339082050314089004317074009313085054318075084314089004357061040040091044040091062040091044040091062040091044137093049197100052287100053347100053047100052287100053259100052184100052083100052050100050000100050083100052093063053082084048066100048053100050036100050066100048060087053061100042070100040101055042165100025070100040";
  // Combined with shades
  string internal constant EXECUTIVE_COLOURS_BASIC_SHADE = "000000050240003029000000050240003029000000050000000050240003029000000050000086027240003029000000050240003029240003013047100032240003029240003013240003029240003013104079046240003029240003013240003029240003013204079046240003029000086027000061010000100007013091043041100045047100032022080008022081012030100015022100040204079087196071077180054080195093089195095092";
  string internal constant EXECUTIVE_COLOURS_EMBELLISHED_SHADE = "104079046096071004080054015095093054095096068096071004204079046196071004180054015195093054195096068196071004322079046316071004299054015313093054313096068316071004357078056040091062040091044040091062040091044040091062168100054257100053317100053017100052047100056317100053284100052212092052155100052068100052032100050155100052093063057093068048075100048058100050047100050075100048060100062061100044065100041081077041137055037065100041";

  // LAB
  // Combined without shades
  string internal constant LAB_COLOURS_BASIC = "185053039180055056185053039180095040181066049231095074252070052231095074210049067030100050168056095228081062168056095051093072182081087240060097253081078240060097224062081245080083352033081165032066027028078027033080037031079143014078000000100143014078237045053183099034207099060207099060040090096239066051176077048221081088194090077200075078195086089200084076";
  string internal constant LAB_COLOURS_EMBELLISHED = "158100077228081062168056095051093072182081087168056095238100086253081078240060097224062081245080083253081078190054036252070052231095074210049067030100050252070052144090033040091044040091062040091044040091062040091044287100053047100052137093049347100053197100052287100053000100050050100050083100052184100052259100052083100052036100050053100050066100048082084048093063053082084048165100025101055042070100040061100042060087053070100040";
  // Combined with shades
  string internal constant LAB_COLOURS_BASIC_SHADE = "181085042184045075181085042180059062181062052251085079251073027251085079211053076030100050182081087229047032182081087051090084180064063242083093252047060242083093224058089244079072004029080164031070021030079022034081023028075143014068183100080143014068237045048183099028239066051207099060041090092238072019176077048204079087196071077180054080195093089195095092";
  string internal constant LAB_COLOURS_EMBELLISHED_SHADE = "169048056229047032182081087051090084180064063182081087241047074252047060242083093224058089244079072252047060184021040251073027251085079211053076030100050251073027147089054040091062040091044040091062040091044040091062317100053047100056168100054017100052257100053317100053032100050068100052155100052212092052284100052155100052047100050058100050075100048093068048093063057093068048137055037081077041065100041061100044060100062065100041";

  // FACTORY
  // Combined without shades
  string internal constant FACTORY_COLOURS_BASIC = "232053033232052058232054032232051037232058059196085079193083063193048054193064047193089055231032035196085079231032035300085082000000085249069060196085079231032035300085082000000085266083081162085079197031035266083081000000085033098060196085068231032035196085068000000085300085082196085079231032035033100052000000085221081088194090077200075078195086089200084076";
  string internal constant FACTORY_COLOURS_EMBELLISHED = "160073059280078043280077074340097062160071039280078043280094041340086057280084075340084055340087027340086057162085079266083081266083081197031035000000085266083081220067026040091044040091072040091044040091072040091044197100052287100053137093049347100053047100052287100053083100052050100050000100050259100052184100052050100050082084048066100048036100050053100050093063053082084048101055042070100040165100025060087053061100042070100040";
  // Combined with shades
  string internal constant FACTORY_COLOURS_BASIC_SHADE = "232066056233054034232066067232071029232091066196084068193045040193073053193067051193070044229034024193083063229034024033098060000000052243039046193083063229034024033098060000000052359097059159084063195034025266086072000000052033098044193083052229034024193083052000000052321076067193083063229034024033098060000000052204079087196071077180054080195093089195095092";
  string internal constant FACTORY_COLOURS_EMBELLISHED_SHADE = "243039046300085082193083063229034024000000052300085082249069060033098060196085079231032035000000085033098060159084063359097059266086072195034025000000052359097059220096052040091072040091044040091072040091044220087032257100053317100053168100054017100052047100056317100053155100052068100052032100050284100052212092052068100052093068048075100048047100050058100050093063057093068048081077041065100041137055037060100062061100044065100041";

  string internal constant DEGRADED_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant BASIC_COLOUR_PERCENTAGES = "064115153191217237251256";
  string internal constant EMBELLISHED_COLOUR_PERCENTAGES = "064115153191217237251256";

  function increaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns(uint) {
    uint value = baseLightness + (baseLightness * percentage / 100);
    if (value > 100) {
      value = 100;
    }
    return value;
  }

  function decreaseValueByPercentage(uint baseLightness, uint percentage) internal pure returns (uint) {
    return baseLightness - (baseLightness * percentage / 100);
  }

  function getColours(string memory machine, uint baseValue) external pure returns (uint[] memory) {
    uint[] memory colourArray = new uint[](36); // 6 colours, 3*2 values each

    uint colourIndex = getColourIndex(baseValue);

    if (colourIndex < 8) { // degraded
      colourArray = getDegradedShell(colourArray, machine, baseValue);
    } else { // basic or embellished
      colourArray = getBasicEmbelishedShell(colourArray, machine, baseValue);
    }
    return colourArray;
  }

  function getColourIndex(uint baseValue) internal pure returns(uint) {
    uint[] memory colourProbabilitiesArray = GridHelper.createEqualProbabilityArray(24);

    uint index = 100;
    for (uint i = 0; i < colourProbabilitiesArray.length; ++i) {
      if (baseValue < colourProbabilitiesArray[i]) {
        index = i;
        break;
      }
    }
    if (index == 100) {
      index = 23;
    }

    return index;
  }

  function selectBasicEmbellishedPalette(string memory machine, uint baseValue) internal pure returns (string[] memory) {
    string[] memory basicPalette = new string[](2);
    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    index = index % 8;

    uint size;
    if (state == 1) {
      size = TOTAL_BASIC_COLOURS * 9;
    } else {
      size = TOTAL_EMBELLISHED_COLOURS * 9;
    }

    // could be simplified by storing every colour in a single string but this is more readable and easier to change
    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(EXECUTIVE_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(LAB_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    } else { // factory
      if (state == 1) {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_BASIC_SHADE), index * size, size));
      } else {
        basicPalette[0] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED), index * size, size));
        basicPalette[1] = string(GridHelper.slice(bytes(FACTORY_COLOURS_EMBELLISHED_SHADE), index * size, size));
      }
    }

    return basicPalette;
  }

  function getDegradedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    string memory degradedHsl;
    string memory degradedPercentages;

    if (keccak256(bytes(machine)) == keccak256(bytes("Altar"))) { // executive
      degradedHsl = EXECUTIVE_DEGRADED_HSL;
      degradedPercentages = EXECUTIVE_COLOUR_PERCENTAGES;
    } else if (keccak256(bytes(machine)) == keccak256(bytes("Apparatus")) || keccak256(bytes(machine)) == keccak256(bytes("Cells"))) { // lab
      degradedHsl = LAB_DEGRADED_HSL;
      degradedPercentages = LAB_COLOUR_PERCENTAGES;
    } else { // factory
      degradedHsl = FACTORY_DEGRADED_HSL;
      degradedPercentages = FACTORY_COLOUR_PERCENTAGES;
    }

    uint index = getColourIndex(baseValue);
    uint[] memory singleColour = new uint[](3); // h, s, l
    for (uint i = 0; i < 3; ++i) {
      singleColour[i] = GridHelper.stringToUint(string(GridHelper.slice(bytes(degradedHsl), (index)*9 + 3*i, 3))); // 9 = h,s,l to 3 significant digits
    }
    uint[] memory colourPercentages = GridHelper.setUintArrayFromString(degradedPercentages, 6, 3);
    
    for (uint i = 0; i < 12; ++i) { // 12 = 6 colours, 2 values each
      colourArray[i*3] = singleColour[0];
      colourArray[i*3+1] = singleColour[1];
      colourArray[i*3+2] = increaseValueByPercentage(singleColour[2], colourPercentages[i%6]);
    }

    return colourArray;
  }

  function getBasicEmbelishedShell(uint[] memory colourArray, string memory machine, uint baseValue) internal pure returns (uint[] memory) {

    uint index = getColourIndex(baseValue);

    uint state = 2;
    if (index < 16) {
      state = 1;
    }

    uint numColours;
    if (state == 1) {
      numColours = TOTAL_BASIC_COLOURS;
    } else {
      numColours = TOTAL_EMBELLISHED_COLOURS;
    }

    string[] memory colourAvailableStrings = selectBasicEmbellishedPalette(machine, baseValue);
    uint[] memory coloursAvailable = GridHelper.setUintArrayFromString(colourAvailableStrings[0], numColours*3, 3);
    uint[] memory coloursAvailableShade = GridHelper.setUintArrayFromString(colourAvailableStrings[1], numColours*3, 3);

    for (uint i = 0; i < 6; ++i) {
      for (uint j = 0; j < 3; ++j) { // j = h, s, l
        // Duplicate colours for linear gradient
        colourArray[2*i*3+j] = coloursAvailable[3*(i % numColours) + j];
        colourArray[(2*i+1)*3+j] = coloursAvailableShade[3*(i % numColours) + j];
      }
    }

    return colourArray;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;
import "@openzeppelin/contracts/utils/Strings.sol";

library GridHelper {
  uint256 public constant MAX_GRID_INDEX = 8;

  /**
    * @dev slice array of bytes
    * @param data The array of bytes to slice
    * @param start The start index
    * @param len The length of the slice
    * @return The sliced array of bytes
   */

  function slice(bytes memory data, uint256 start, uint256 len) internal pure returns (bytes memory) {
      bytes memory b = new bytes(len);
      for (uint256 i = 0; i < len; i++) {
        b[i] = data[i + start];
      }
      return b;
  }

  /**
    * @dev combine two arrays of strings
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineStringArrays(string[] memory a, string[] memory b) public pure returns (string[] memory) {
    string[] memory c = new string[](a.length + b.length);
    for (uint256 i = 0; i < a.length; i++) {
        c[i] = a[i];
    }
    for (uint256 i = 0; i < b.length; i++) {
        c[i + a.length] = b[i];
    }
    return c;
  }

  /**
    * @dev combine two arrays of uints
    * @param a The first array
    * @param b The second array
    * @return The combined array
   */

  function combineUintArrays(uint256[] memory a, uint256[] memory b) public pure returns (uint256[] memory) {
      uint256[] memory c = new uint256[](a.length + b.length);
      for (uint256 i = 0; i < a.length; i++) {
          c[i] = a[i];
      }
      for (uint256 i = 0; i < b.length; i++) {
          c[i + a.length] = b[i];
      }
      return c;
  }

  /**
    * @dev wrap a string in a transform group
    * @param x The x position
    * @param y The y position
    * @param data The data to wrap
    * @return The wrapped string
   */

  function groupTransform(string memory x, string memory y, string memory data) internal pure returns (string memory) {
    return string.concat("<g transform='translate(", x, ",", y, ")'>", data, "</g>");
  }

  /**
    * @dev convert a uint to bytes
    * @param x The uint to convert
    * @return b The bytes
   */

  function uintToBytes(uint256 x) internal pure returns (bytes memory b) {
      b = new bytes(32);
      assembly {
          mstore(add(b, 32), x)
      } //  first 32 bytes = length of the bytes value
  }

  /**
    * @dev convert bytes with length equal to bytes32 to uint
    * @param value The bytes to convert
    * @return The uint
   */

  function bytesToUint(bytes memory value) internal pure returns(uint) {
    uint256 num = uint256(bytes32(value));
    return num;
  }

  /**
    * @dev convert bytes with length less than bytes32 to uint
    * @param a The bytes to convert
    * @return The uint
   */

  function byteSliceToUint (bytes memory a) internal pure returns(uint) {
    bytes32 padding = bytes32(0);
    bytes memory formattedSlice = slice(bytes.concat(padding, a), 1, 32);

    return bytesToUint(formattedSlice);
  }

  /**
    * @dev get a byte from a random number at a given position
    * @param rand The random number
    * @param slicePosition The position of the byte to slice
    * @return The random byte
   */

  function getRandByte(uint rand, uint slicePosition) internal pure returns(uint) {
    bytes memory bytesRand = uintToBytes(rand);
    bytes memory part = slice(bytesRand, slicePosition, 1);
    return byteSliceToUint(part);
  }

  /**
    * @dev convert a string to a uint
    * @param s The string to convert
    * @return The uint
   */

  function stringToUint(string memory s) internal pure returns (uint) {
      bytes memory b = bytes(s);
      uint result = 0;
      for (uint256 i = 0; i < b.length; i++) {
          uint256 c = uint256(uint8(b[i]));
          if (c >= 48 && c <= 57) {
              result = result * 10 + (c - 48);
          }
      }
      return result;
  }

  /**
    * @dev repeat an object a given number of times with given offsets
    * @param object The object to repeat
    * @param times The number of times to repeat
    * @param offsetBytes The offsets to use
    * @return The repeated object
   */

  function repeatGivenObject(string memory object, uint times, bytes memory offsetBytes) internal pure returns (string memory) {
    // uint sliceSize = offsetBytes.length / (times * 2); // /2 for x and y
    require(offsetBytes.length % (times * 2) == 0, "offsetBytes length must be divisible by times * 2");
    string memory output = "";
    for (uint256 i = 0; i < times; i++) {
      string memory xOffset = string(slice(offsetBytes, 2*i * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      string memory yOffset = string(slice(offsetBytes, (2*i + 1) * offsetBytes.length / (times * 2), offsetBytes.length / (times * 2)));
      output = string.concat(
        output,
        groupTransform(xOffset, yOffset, object)
      );
    }
    return output;
  }

  /**
    * @dev convert a single string to an array of uints
    * @param values The string to convert
    * @param numOfValues The number of values in the string
    * @param lengthOfValue The length of each value in the string
    * @return The array of uints
   */

  function setUintArrayFromString(string memory values, uint numOfValues, uint lengthOfValue) internal pure returns (uint[] memory) {
    uint[] memory output = new uint[](numOfValues);
    for (uint256 i = 0; i < numOfValues; i++) {
      output[i] = stringToUint(string(slice(bytes(values), i*lengthOfValue, lengthOfValue)));
    }
    return output;
  }

  /**
    * @dev get the sum of an array of uints
    * @param arr The array to sum
    * @return The sum
   */

  function getSumOfUintArray(uint[] memory arr) internal pure returns (uint) {
    uint sum = 0;
    for (uint i = 0; i < arr.length; i++) {
      sum += arr[i];
    }
    return sum;
  }

  /**
    * @dev constrain a value to the range 0-255, must be between -255 and 510
    * @param value The value to constrain
    * @return The constrained value
   */

  function constrainToHex(int value) internal pure returns (uint) {
    require(value >= -255 && value <= 510, "Value out of bounds.");
    if (value < 0) { // if negative, make positive
      return uint(0 - value);
    }
    else if (value > 255) { // if greater than 255, count back from 255
      return uint(255 - (value - 255));
    } else {
      return uint(value);
    }
  }

  /**
    * @dev create an array of equal probabilities for a given number of values
    * @param numOfValues The number of values
    * @return The array of probabilities
   */

  function createEqualProbabilityArray(uint numOfValues) internal pure returns (uint[] memory) {
    uint oneLess = numOfValues - 1;
    uint[] memory probabilities = new uint[](oneLess);
    for (uint256 i = 0; i < oneLess; ++i) {
      probabilities[i] = 256 * (i + 1) / numOfValues;
    }
    return probabilities;
  }

  /**
    * @dev get a single object from a string of object numbers
    * @param objectNumbers The string of objects
    * @param channelValue The hex value of the channel
    * @param numOfValues The number of values in the string
    * @param valueLength The length of each value in the string
    * @return The object
   */

  function getSingleObject(string memory objectNumbers, uint channelValue, uint numOfValues, uint valueLength) internal pure returns (uint) {
    
    // create probability array assuming all objects have equal probability
    uint[] memory probabilities = createEqualProbabilityArray(numOfValues);

    uint[] memory objectNumbersArray = setUintArrayFromString(objectNumbers, numOfValues, valueLength);

    uint oneLess = numOfValues - 1;

    for (uint256 i = 0; i < oneLess; ++i) {
      if (channelValue < probabilities[i]) {
        return objectNumbersArray[i];
      }
    }
    return objectNumbersArray[oneLess];
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
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
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}