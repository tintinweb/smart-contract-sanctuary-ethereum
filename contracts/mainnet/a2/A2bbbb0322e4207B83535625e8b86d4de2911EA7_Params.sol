// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function encode(string memory _data) internal pure returns (string memory) {
        return encode(bytes(_data));
    }

    function encode(bytes memory _data) internal pure returns (string memory) {
        if (_data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((_data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := _data
            let endPtr := add(dataPtr, mload(_data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                dataPtr := add(dataPtr, 3)

                // read 3 bytes
                let input := mload(dataPtr)

                // write 4 characters
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
                resultPtr := add(resultPtr, 1)
                mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(_data), 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./library/Base64.sol";

contract Params is Ownable {
    /* 
    ⌐◨—————————————————————————————————————————————————————————————◨
                                set state
    ⌐◨—————————————————————————————————————————————————————————————◨ */

    string[] public checkPosititions = ['M100 60h10v10h-10z','M100 70h10v10h-10z','M110 60h10v10h-10z','M110 70h10v10h-10z','M130 60h10v10h-10z','M130 70h10v10h-10z','M140 60h10v10h-10z','M140 70h10v10h-10z','M160 60h10v10h-10z','M160 70h10v10h-10z','M170 60h10v10h-10z','M170 70h10v10h-10z','M190 60h10v10h-10z','M190 70h10v10h-10z','M200 60h10v10h-10z','M200 70h10v10h-10z','M220 60h10v10h-10z','M220 70h10v10h-10z','M230 60h10v10h-10z','M230 70h10v10h-10z','M100 90h10v10h-10z','M100 100h10v10h-10z','M110 90h10v10h-10z','M110 100h10v10h-10z','M130 90h10v10h-10z','M130 100h10v10h-10z','M140 90h10v10h-10z','M140 100h10v10h-10z','M160 90h10v10h-10z','M160 100h10v10h-10z','M170 90h10v10h-10z','M170 100h10v10h-10z','M190 90h10v10h-10z','M190 100h10v10h-10z','M200 90h10v10h-10z','M200 100h10v10h-10z','M220 90h10v10h-10z','M220 100h10v10h-10z','M230 90h10v10h-10z','M230 100h10v10h-10z','M160 120h10v10h-10z','M230 120h10v10h-10z','M230 130h10v10h-10z','M160 150h10v10h-10z','M160 160h10v10h-10z','M230 150h10v10h-10z','M230 160h10v10h-10z','M100 180h10v10h-10z','M100 190h10v10h-10z','M110 180h10v10h-10z','M110 190h10v10h-10z','M130 180h10v10h-10z','M130 190h10v10h-10z','M140 180h10v10h-10z','M140 190h10v10h-10z','M160 180h10v10h-10z','M160 190h10v10h-10z','M170 180h10v10h-10z','M170 190h10v10h-10z','M190 180h10v10h-10z','M190 190h10v10h-10z','M200 180h10v10h-10z','M200 190h10v10h-10z','M220 180h10v10h-10z','M220 190h10v10h-10z','M230 180h10v10h-10z','M230 190h10v10h-10z'];
    string[] public checkColors = ['E84AA9','F2399D','DB2F96','E73E85','FF7F8E','FA5B67','E8424E','D5332F','C23532','F2281C','D41515','9D262F','DE3237','DA3321','EA3A2D','EB4429','EC7368','FF8079','FF9193','EA5B33','EB5A2A','ED7C30','EF9933','EF8C37','F18930','F09837','F9A45C','F2A43A','F2A840','F2A93C','FFB340','F2B341','FAD064','F7CA57','F6CB45','FFAB00','F4C44A','FCDE5B','F9DA4D','F9DA4A','FAE272','F9DB49','FAE663','FBEA5B','E2F24A','B5F13B','94E337','63C23C','86E48E','77E39F','83F1AE','5FCD8C','9DEFBF','2E9D9A','3EB8A1','5FC9BF','77D3DE','6AD1DE','5ABAD3','4291A8','45B2D3','81D1EC','33758D','A7DDF9','9AD9FB','2480BD','60B1F4','A4C8EE','4576D0','2E4985','3263D0','25438C','525EAA','3D43B3','322F92','4A2387','371471','3B088C','9741DA','6C31D7', '000000', '367A8F','4581EE','49788D','49A25E','7DE778','9CCF48','A0B3B7','AA2C5C','BB2891','C99C5F','D6D3CE','D97661','D97760','E04639','EB5D2D','ED6D8E','FCF153'];
    string[] public bodyColors = ['1F1D28','343235','3D8748','5AAA83','5C65F1','7DE778','847C30','88A643','922D9B','A03C1C','B75640','C13620','C46A57','D63C5E','EAD94B','EB5D2D','EB9447','EE9165'];
    string[] public bodyColorNames = ['#1F1D28','#343235','#3D8748','#5AAA83','#5C65F1','#7DE778','#847C30','#88A643','#922D9B','#A03C1C','#B75640','#C13620','#C46A57','#D63C5E','#EAD94B','#EB5D2D','#EB9447','#EE9165'];    
    string[] public frameColors = ['EBEBEB', '000000'];
    string[] public matteColors = ['FFFFFF', '2E2E2E'];
    string[] public bgColors = ['E1D7D5', 'D5D7E1'];   
    string[] public themes = ['Light', 'Dark'];
    string[] public noggleType = ['Normal', 'Full', 'Hip'];
    string[] public checkType = ['Pixel', 'Circle'];
    string[] public checkPaths = ['<path class="check" d="M150 260h10v10h-10v-10Zm10 10h10v10h-10v-10Zm10-10h10v10h-10v-10Zm10-10h10v10h-10v-10Z"/>','<path class="check" shape-rendering="geometricPrecision" d="M200 276.191c0-3.762-2.083-7.024-5.114-8.572a9.97 9.97 0 0 0 .567-3.333c0-5.262-4.072-9.519-9.091-9.519-1.118 0-2.19.199-3.18.595-1.472-3.184-4.586-5.362-8.181-5.362-3.595 0-6.704 2.184-8.182 5.357a8.604 8.604 0 0 0-3.182-.595c-5.023 0-9.09 4.262-9.09 9.524 0 1.176.198 2.295.565 3.333-3.028 1.548-5.112 4.805-5.112 8.572 0 3.559 1.862 6.661 4.624 8.299-.048.405-.077.81-.077 1.225 0 5.262 4.067 9.523 9.09 9.523 1.12 0 2.191-.204 3.179-.594 1.476 3.175 4.586 5.356 8.183 5.356 3.6 0 6.71-2.181 8.183-5.356.988.387 2.059.59 3.18.59 5.024 0 9.091-4.263 9.091-9.525 0-.413-.029-.818-.079-1.22 2.757-1.637 4.626-4.739 4.626-8.296v-.002Z" /><path fill="#fff" d="m184.249 268.252-10.319 15.476a1.785 1.785 0 0 1-2.478.496l-.274-.224-5.75-5.75a1.784 1.784 0 1 1 2.524-2.524l4.214 4.207 9.106-13.666a1.787 1.787 0 0 1 2.476-.493 1.784 1.784 0 0 1 .501 2.476v.002Z"/>'];

    constructor() {}

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           utility functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function setCheckPositions(string[] memory _checkPosititions) external onlyOwner {
        checkPosititions = _checkPosititions;
    }

    function setCheckColors(string[] memory _checkColors) external onlyOwner {
        checkColors = _checkColors;
    }

    function setBodyColors(string[] memory _bodyColors) external onlyOwner {
        bodyColors = _bodyColors;
    }

    function setFrameColors(string[] memory _frameColors) external onlyOwner {
        frameColors = _frameColors;
    }

    function setMatteColors(string[] memory _matteColors) external onlyOwner {
        matteColors = _matteColors;
    }

    function setbgColors(string[] memory _bgColors) external onlyOwner {
        bgColors = _bgColors;
    }

    function setThemes(string[] memory _themes) external onlyOwner {
        themes = _themes;
    }

    function setCheckType(string[] memory _checkType) external onlyOwner {
        checkType = _checkType;
    }

    function setCheckPaths(string[] memory _checkPaths) external onlyOwner {
        checkPaths = _checkPaths;
    }

    /*
    ⌐◨—————————————————————————————————————————————————————————————◨
                           getter functions
    ⌐◨—————————————————————————————————————————————————————————————◨ 
    */

    function getCheckPositions() external view returns (string[] memory) {
        return checkPosititions;
    }

    function getCheckPositionsLength() external view returns (uint256) {
        return checkPosititions.length;
    }

    function getCheckColors() external view returns (string[] memory) {
        return checkColors;
    }

    function getCheckColorLength() external view returns (uint256) {
        return checkColors.length;
    }

    function getBodyColors() external view returns (string[] memory) {
        return bodyColors;
    }

    function getBodyColorNames() external view returns (string[] memory) {
        return bodyColorNames;
    }

    function getFrameColors() external view returns (string[] memory) {
        return frameColors;
    }

    function getMatteColors() external view returns (string[] memory) {
        return matteColors;
    }

    function getBgColors() external view returns (string[] memory) {
        return bgColors;
    }

    function getThemes() external view returns (string[] memory) {
        return themes;
    }

    function getNoggleType() external view returns (string[] memory) {
        return noggleType;
    }

    function getCheckType() external view returns (string[] memory) {
        return checkType;
    }

    function getCheckPaths() external view returns (string[] memory) {
        return checkPaths;
    }
    
}