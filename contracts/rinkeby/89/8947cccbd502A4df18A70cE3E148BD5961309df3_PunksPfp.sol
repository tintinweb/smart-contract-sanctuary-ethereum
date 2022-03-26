// SPDX-License-Identifier: UNLICENSED
/// @title PunksPfp
/// @notice Punks Pfp
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.9;

import "@cyberpnk/solidity-library/contracts/IStringUtilsV1.sol";
import "@cyberpnk/solidity-library/contracts/FeeLockable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoPunksData.sol";
import "./ICryptoPunksMarket.sol";
// import "hardhat/console.sol";

contract PunksPfp is Ownable, FeeLockable {
    IStringUtilsV1 stringUtils;
    ICryptoPunksData cryptoPunksData;
    ICryptoPunksMarket cryptoPunksMarket;

    struct Background {
        string color;
        string svg;
        string image;
    }

    mapping (address => Background) public addressToBackground;

    function setColor(string memory color) external {
        require(bytes(color).length <= 6, "Length");
        addressToBackground[msg.sender].color = color;
    }

    function setSvg(string memory svg) external payable {
        require(msg.value == feeAmount, "Value");
        addressToBackground[msg.sender].svg = svg;
    }

    function setImage(string memory image) external payable {
        require(msg.value == feeAmount, "Value");
        addressToBackground[msg.sender].image = image;
    }

    constructor(address stringUtilsContract, address cryptoPunksMarketContract, address cryptoPunksDataContract) {
        stringUtils = IStringUtilsV1(stringUtilsContract);
        cryptoPunksMarket = ICryptoPunksMarket(cryptoPunksMarketContract);
        cryptoPunksData = ICryptoPunksData(cryptoPunksDataContract);
    }

    function getImage(uint16 punkId) public view returns(bytes memory) {
        string memory punkSvg = cryptoPunksData.punkImageSvg(punkId);
        address punkOwner = cryptoPunksMarket.punkIndexToAddress(punkId);

        Background memory background = addressToBackground[punkOwner];
        
        bytes memory color = bytes(background.color).length > 0 ? abi.encodePacked('<rect y="0" height="640" x="0" width="640" fill="#', background.color, '"/>') : abi.encodePacked("");
        bytes memory image = bytes(background.image).length > 0 ? abi.encodePacked('<image y="0" height="640" x="0" width="640" href="', background.image, '"/>') : abi.encodePacked("");
        string memory svg = bytes(background.svg).length > 0 ? background.svg : "";

        return abi.encodePacked(
'<svg width="640" height="640" version="1.1" viewBox="0 0 640 640" xmlns="http://www.w3.org/2000/svg">',
  color,
  image,
  svg,
  punkSvg,
'</svg>'
        );
    }


    function getTokenURI(uint256 punkId) external view returns (string memory) {
        string memory strPunkId = stringUtils.numberToString(punkId);

        bytes memory imageBytes = getImage(uint16(punkId));

        string memory image = stringUtils.base64EncodeSvg(abi.encodePacked(imageBytes));

        bytes memory json = abi.encodePacked(string(abi.encodePacked(
            '{'
                '"title": "Punk Pfp #', strPunkId, '",'
                '"name": "Punk Pfp #', strPunkId, '",'
                '"image": "', image, '",'
                '"traits": [ ',
                    '{"trait_type":"Punk Pfp","value":"Yes"}'
                '],'
                '"description": "Punk Pfp #', strPunkId,'."'
            '}'
        )));

        return stringUtils.base64EncodeJson(json);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return cryptoPunksMarket.punkIndexToAddress(uint16(_tokenId));
    }

    function withdraw() external {
        payable(feePayee).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
/// [MIT License]
/// @title StringUtilsV1

pragma solidity ^0.8.9;

interface IStringUtilsV1 {
    function base64Encode(bytes memory data) external pure returns (string memory);

    function base64EncodeJson(bytes memory data) external pure returns (string memory);

    function base64EncodeSvg(bytes memory data) external pure returns (string memory);

    function numberToString(uint256 value) external pure returns (string memory);

    function addressToString(address account) external pure returns(string memory);

    function split(string calldata str, string calldata delim) external pure returns(string[] memory);
}

// SPDX-License-Identifier: UNLICENSED
/// @title FeeLockable
/// @notice stores the fee payee and amount, letting the owner only change it, and alows to lock them for changes
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____
//  __________________/\/\/\/\________________________________________________________________________________
// __________________________________________________________________________________________________________

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract FeeLockable is Ownable {
    uint public feeAmount = 0;
    address public feePayee;
    bool public isChangeFeeAmountDisabled = false;
    bool public isChangeFeePayeeDisabled = false;

    // Irreversible.
    function disableChangeFeeAmount() public onlyOwner {
        isChangeFeeAmountDisabled = true;
    }

    // Irreversible.
    function disableChangeFeePayee() public onlyOwner {
        isChangeFeePayeeDisabled = true;
    }

    function setFeeAmount(uint _feeAmount) public onlyOwner {
        require(!isChangeFeeAmountDisabled, "Disabled");
        feeAmount = _feeAmount;
    }

    function setFeePayee(address _feePayee) public onlyOwner {
        require(!isChangeFeePayeeDisabled, "Disabled");
        feePayee = _feePayee;
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
/// @title ICryptoPunksData
/// @notice ICryptoPunksData
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     


pragma solidity ^0.8.9;

interface ICryptoPunksData {
    function punkImageSvg(uint16 punkId) external view returns (string memory);
    function punkAttributes(uint16 punkId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
/// @title ICryptoPunksMarket
/// @notice ICryptoPunksMarket
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.9;

// import "hardhat/console.sol";

interface ICryptoPunksMarket {
    function punkIndexToAddress(uint) external view returns(address);
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