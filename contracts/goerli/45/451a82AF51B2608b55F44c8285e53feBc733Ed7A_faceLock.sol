/**
 *Submitted for verification at Etherscan.io on 2023-02-25
*/

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface ChainfacesArenaInterface {
  function safeTransferFrom(address,address,uint) external;
  function roundsSurvived(uint) external view returns (uint);
  function assembleFace(uint) external view returns (string memory);
}

interface ChainfacesRendererInterface {
  function calculateGolfScore(uint,uint) external view returns (uint);
}

pragma solidity 0.8.17;

error alreadyStarted();
error windowClosed();
error invalidGridSize();
error invalidFaceCount();
error maxTwos();
error maxThrees();
error maxFours();
error maxFives();

contract faceLock is Ownable {
    constructor() {
        setAddresses(chainfacesArenaAddress, chainfacesRendererAddress);
    }

    address public chainfacesArenaAddress = 0x2B73Eb9cF8Cb24881B8FF2333514ae6ef66b851b; //mainnet 0x93a796B1E846567Fe3577af7B7BB89F71680173a
    address public chainfacesRendererAddress = 0x4f5C322593b7EfcfE67882CFbBeF182d4Da97Fc0;//mainnet 0x18c4a85E52c23675F0a57Cfa9a55e4d407654017
    address public happyFacePlaceAddress = 0x7039D65E346FDEEBbc72514D718C88699c74ba4b;

    ChainfacesArenaInterface cfa;
    ChainfacesRendererInterface cfr;

    function setAddresses(address cfaAddress, address cfrAddress) public onlyOwner {
        chainfacesArenaAddress = cfaAddress;
        chainfacesRendererAddress = cfrAddress;
        cfa = ChainfacesArenaInterface(chainfacesArenaAddress);
        cfr = ChainfacesRendererInterface(chainfacesRendererAddress);
    }

    uint256 constant CFA_SECRET = 0xfaee60aba1de90b136af0df52ad776bd1bfae4448b5bcfe4cca7bbba461448fe;

    using Strings for uint256;

    uint public facesLocked;
    uint public totalOrdinals;

    mapping (address => uint) public ordinalCount;
    mapping (uint => uint[]) indexToFaceIds;
    mapping (uint => address) indexToAddress;
    mapping (uint => uint) indexToGridSize;
    mapping (uint => string) indexToBitcoinAddress;

    uint public lockStartTimer;

    function openWindow() public onlyOwner {
        if (lockStartTimer > 0) revert alreadyStarted();
        lockStartTimer = block.timestamp;
    }

    function lockFaces(uint[] memory _faces, uint gridSize, string memory bitcoinAddress) public {
        if (block.timestamp >= lockStartTimer + 1209600) revert windowClosed(); //2 weeks
        if (gridSize < 2 || gridSize > 5) revert invalidGridSize();
        if (_faces.length != gridSize*gridSize) revert invalidFaceCount();

        updateCaps(gridSize);

        totalOrdinals = totalOrdinals + 1;
        ordinalCount[msg.sender] = ordinalCount[msg.sender] + 1;

        indexToFaceIds[totalOrdinals] = _faces;
        indexToAddress[totalOrdinals] = msg.sender; 
        indexToGridSize[totalOrdinals] = gridSize;
        indexToBitcoinAddress[totalOrdinals] = bitcoinAddress;

        for (uint i = 0; i < _faces.length; i++) {
            cfa.safeTransferFrom(msg.sender,happyFacePlaceAddress,_faces[i]);
        }

        facesLocked = facesLocked + _faces.length;
    }

    uint public currentTwoByTwos;
    uint public currentThreeByThrees;
    uint public currentFourByFours;
    uint public currentFiveByFives;

    uint public maxTwoByTwos = 250;
    uint public maxThreeByThrees = 120;
    uint public maxFourByFours = 40;
    uint public maxFiveByFives = 10;

    function updateCaps(uint gridSize) internal {
        if (gridSize == 2) {
            if (currentTwoByTwos >= maxTwoByTwos) revert maxTwos();
            currentTwoByTwos = currentTwoByTwos + 1;
        }
        else if (gridSize == 3) {
            if (currentThreeByThrees >= maxThreeByThrees) revert maxThrees();
            currentThreeByThrees = currentThreeByThrees + 1;
        }
        else if (gridSize == 4) {
            if (currentFourByFours >= maxFourByFours) revert maxFours();
            currentFourByFours = currentFourByFours + 1;
        }
        else if (gridSize == 5) {
            if (currentFiveByFives >= maxFiveByFives) revert maxFives();
            currentFiveByFives = currentFiveByFives + 1;
        }
    }

    function getTotalDeposits(address faceLocker) public view returns (uint totalDeposits) {
        totalDeposits = ordinalCount[faceLocker];
    }

    function getAverageGolf(uint index) internal view returns (uint averageGolf) {
        uint gridSize = indexToGridSize[index];  
        uint totalGolfScore;
        uint totalFaces = gridSize*gridSize;

        for (uint i = 0; i < totalFaces; i++) {
            uint _id = indexToFaceIds[index][i];
            uint256 seed = uint256(keccak256(abi.encodePacked(CFA_SECRET, _id)));
            totalGolfScore = totalGolfScore + cfr.calculateGolfScore(_id,seed);
        }
        
        averageGolf = totalGolfScore/totalFaces;
    }

    function getBackgroundColor(uint index) internal view returns (uint256 red, uint256 green, uint256 blue){
        uint256 golf = getAverageGolf(index);

        if (golf >= 56) {
            red = 255;
            green = 255;
            blue = 255 - (golf - 56) * 4;
        }
        else {
            red = 255 - (56 - golf) * 4;
            green = 255 - (56 - golf) * 4;
            blue = 255;
        }
    }    

    function getAverageArenaScore(uint index) internal view returns (uint averageArenaScore) {
        uint totalArenaScore;
        uint gridSize = indexToGridSize[index];
        uint totalFaces = gridSize*gridSize;

        for (uint i = 0; i < totalFaces; i++) {
            uint _id = indexToFaceIds[index][i];
            totalArenaScore = totalArenaScore + cfa.roundsSurvived(_id);
        }
        
        averageArenaScore = totalArenaScore/totalFaces;
    }

    uint256 constant SCAR_TEMPLATE_LENGTH = 81;

    function generateScars(uint256 ptr, uint256 count, uint256 index, uint gridSize) private view {

        string memory scarTemplate = "<g transform='translate(       ) scale( . ) rotate(    )'><use href='#scar'/></g>";

        for (uint256 i = 0; i < count; i++) {
            uint256 scarPtr = ptr + i * SCAR_TEMPLATE_LENGTH;

            uint256 scarSeed = uint256(keccak256(abi.encodePacked(index, i)));

            uint256 scale1 = scarSeed % 2;
            uint256 scale2 = scarSeed % 5;
            if (scale1 == 0) {
                scale2 += 5;
            }

            uint256 xShift = scarSeed % ((gridSize*200+100)-68);
            uint256 yShift = scarSeed % ((gridSize*200+100)-46);
 
            int256 rotate = int256(scarSeed % 91) - 45;

            assembly {
                pop(staticcall(gas(), 0x04, add(scarTemplate, 0x20), SCAR_TEMPLATE_LENGTH, add(ptr, mul(i, SCAR_TEMPLATE_LENGTH)), SCAR_TEMPLATE_LENGTH))
            }

            numToString(scarPtr + 24, xShift, 3);
            numToString(scarPtr + 28, yShift, 3);
            numToString(scarPtr + 39, scale1, 1);
            numToString(scarPtr + 41, scale2, 1);

            if (rotate < 0) {
                assembly {
                    mstore8(add(add(ptr, mul(i, SCAR_TEMPLATE_LENGTH)), 51), 45) // 45 is '-'
                }
                numToString(scarPtr + 52, uint256(-rotate), 3);
            } else {
                assembly {
                    mstore8(add(add(ptr, mul(i, SCAR_TEMPLATE_LENGTH)), 51), 43) // 43 is '+'
                }
                numToString(scarPtr + 52, uint256(rotate), 3);
            }
        }
    }

    uint256 constant BORDER_SIZE = 50;
    uint256 constant FACE_SIZE = 200;
    uint256 constant INTRO_LENGTH = 110;
    uint256 constant SCAR_SYMBOL_LENGTH = 207;
    uint256 constant FACE_LENGTH = 135;
    uint256 constant OUTRO_LENGTH = 6;

    function faceGridSVG(uint index) public view returns (string memory) {

        uint gridSize = indexToGridSize[index];
        uint256 scarCount = getAverageArenaScore(index) / 40; 

        if (scarCount > 70) {
            scarCount = 70;
        }     

        uint256 ptr;
        uint256 totalFaceLength = gridSize*gridSize*FACE_LENGTH;
        uint256 imageSize = INTRO_LENGTH + totalFaceLength + (scarCount*SCAR_TEMPLATE_LENGTH) + SCAR_SYMBOL_LENGTH + OUTRO_LENGTH;
        uint256 returnDataSize = (imageSize + 0x20 - 1) / 0x20 * 0x20;

        // Setup memory and return data
        assembly {
             // Load free storage pointer
            ptr := mload(0x40)
            mstore(0x40, add(add(ptr, returnDataSize), 0x40))
            // Prepare return data
            mstore(ptr, 0x20)
            mstore(add(ptr, 0x20), imageSize)
            // Move ptr to actual data position
            ptr := add(ptr, 0x40)
        }

        // Write the SVG header
        {
            string memory svg1 = "<svg xmlns='http://www.w3.org/2000/svg' width='    ' height='    ' style='background-color:RGBA(   ,   ,   )'>";
            assembly {
                let from := add(svg1, 0x20)
                let to := ptr
                let len := INTRO_LENGTH
                pop(staticcall(gas(), 0x04, from, len, to, len))
            }
        }

        // Fill in width and height
        {
            numToString(ptr + 47, gridSize*FACE_SIZE+(BORDER_SIZE*2), 4);
            numToString(ptr + 61, gridSize*FACE_SIZE+(BORDER_SIZE*2), 4);
        }

        // Fill in bg color
        {
            (uint256 red, uint256 green, uint256 blue) = getBackgroundColor(index);

            numToString(ptr + 96, red, 3);
            numToString(ptr + 100, green, 3);
            numToString(ptr + 104, blue, 3);
        }

        // Loop over faces and draw them
        {
            string memory svg = "<text transform='translate(    ,    )' dominant-baseline='middle' text-anchor='middle' font-size='37px'>                        </text>";

            for (uint i = 0; i < gridSize*gridSize; i++) {
                uint _faceId = indexToFaceIds[index][i];
                
                assembly {
                    let from := add(svg, 0x20)
                    let to := add(add(ptr, INTRO_LENGTH), mul(i, FACE_LENGTH))
                    let len := FACE_LENGTH
                    pop(staticcall(gas(), 0x04, from, len, to, len))
                }

                {
                    uint256 y = BORDER_SIZE + (i % gridSize) * FACE_SIZE + FACE_SIZE/2;
                    uint256 x = BORDER_SIZE + (i / gridSize) * FACE_SIZE + FACE_SIZE/2;

                    numToString(ptr + INTRO_LENGTH + (i * FACE_LENGTH) + 27, x, 4);
                    numToString(ptr + INTRO_LENGTH + (i * FACE_LENGTH) + 32, y, 4);
                }

                string memory face = cfa.assembleFace(_faceId);

                assembly {
                    let from := add(face, 0x20)
                    let to := add(add(ptr, add(INTRO_LENGTH, 104)), mul(i, FACE_LENGTH))
                    let len := mload(face)
                    pop(staticcall(gas(), 0x04, from, len, to, len))
                }
            }
        }

        // Add the scar symbol
        {
            string memory svg = "<symbol id='scar'><g stroke='RGBA(200,40,40,.35)'><text x='40' y='40' dominant-baseline='middle' text-anchor='middle' font-weight='bold' font-size='22px' fill='RGBA(200,40,40,.45)'>++++++</text></g></symbol>";
            uint256 offset = INTRO_LENGTH + totalFaceLength;
            assembly {
                let from := add(svg, 0x20)
                let to := add(ptr, offset)
                let len := SCAR_SYMBOL_LENGTH
                pop(staticcall(gas(), 0x04, from, len, to, len))
            }
        }

        // Generate all the scars
        generateScars(ptr + INTRO_LENGTH + totalFaceLength + SCAR_SYMBOL_LENGTH, scarCount, index, gridSize);

        // Add the closing tag
        {
            string memory svg = "</svg>";
            uint256 offset = INTRO_LENGTH + totalFaceLength + SCAR_SYMBOL_LENGTH + (scarCount*SCAR_TEMPLATE_LENGTH);
            assembly {
                let from := add(svg, 0x20)
                let to := add(ptr, offset)
                let len := OUTRO_LENGTH
                pop(staticcall(gas(), 0x04, from, len, to, len))
            }
        }

        // Return
        assembly {
            return(sub(ptr, 0x40), add(returnDataSize, 0x40))
        }
    }   

    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    function numToString(uint256 ptr, uint256 value, uint256 len) internal pure {
        unchecked {
            for (uint256 i = ptr + len - 1; i >= ptr; i--) {
                uint256 decVal = value % 10;
                assembly {
                    mstore8(i, byte(decVal, _SYMBOLS))
                }
                value /= 10;
            }
        }
    }

    mapping (uint => string) indexToInscription;

    function addInscription(uint[] memory index, string[] memory inscription) public onlyOwner {
        for(uint i = 0; i < index.length; i++) {
            indexToInscription[index[i]] = inscription[i];
        }
    }

    function indexInfo(uint index) external view returns (address faceLocker, string memory inscription, uint gridSize, uint golfScore, uint arenaScore, string memory bitcoinAddress, uint[] memory tokenIds) {
        faceLocker = indexToAddress[index];
        inscription = indexToInscription[index];
        gridSize = indexToGridSize[index];
        golfScore = getAverageGolf(index);
        arenaScore = getAverageArenaScore(index);
        bitcoinAddress = indexToBitcoinAddress[index];
        tokenIds = indexToFaceIds[index];
    } 
}