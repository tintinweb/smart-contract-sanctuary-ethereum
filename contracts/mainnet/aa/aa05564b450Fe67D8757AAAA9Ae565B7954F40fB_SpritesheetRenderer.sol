// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    function toString(uint256 value) internal pure returns (string memory) {

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

    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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


pragma solidity 0.8.19;

contract SpritesheetRenderer is Ownable {
  using Strings for uint256;

  //opening and closing for SVG file
  string internal openingSVG = "<svg class='edgehog' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 40 40' height='100%' width='100%'><defs><image height='1320' width='120' image-rendering='pixelated' id='s'  href='";
  string internal endingSVG ="</g> <style> .effect { animation: 0.75s effect infinite alternate ease-in-out; } @keyframes effect { from { transform: translateY(0px); transfom: scale(2); zoom: 0.5; } to { transform: translateY(2%); transfom: scale(2); zoom: 0.5; } } .effect2 { animation: 0.75s effect2 infinite alternate ease-in-out; } @keyframes effect2 { from { transform: translateY(0px); transfom: scale(2); zoom: 0.5; } to { transform: translateY(1.5%); transfom: scale(2); zoom: 0.5; } } .edgehog { width: 100%; height: auto; }  .popup-link { display: flex; position: absolute; top: 1vw; left: 1vw; flex-wrap: wrap; } .popup-link a { color: #fff; width: 5vw; height: 5vw; padding: 0.2vw; text-align: center; text-justify:auto; border-radius: 50%; font-size: 4vw; cursor: pointer; border: 1vw solid rgba(247,147,26,0.7); text-decoration: none; } .popup-container { visibility: hidden; opacity: 0; transition: all 0.3s ease-in-out; transform: scale(1.3); position: fixed; z-index: 1; left: 0; top: 0; width: 100%; height: 100%; background-color: rgba(21, 17, 17, 0.61); display: flex; align-items: center; } .popup-content { background-color: #e6dcfa; margin: auto; padding: 20px; border: 5px solid #8945ff; border-radius: 20px; width: 70%; } .popup-content p { font-size: 3vw; padding: 10px; } .popup-content a.close { color: #aaaaaa; float: right; font-size: 28px; font-weight: bold; background: none; padding: 0; margin: 0; text-decoration: none; } .popup-content a.close:hover { color: #333; } .popup-content span:hover, .popup-content span:focus { color: #000; text-decoration: none; cursor: pointer; } .popup-container:target { visibility: visible; opacity: 1; transform: scale(1); } .popup-container h3 { margin: 4px; font-size: 4vw; } </style> </svg> <div class='popup-link'> <a href='#popup1'>&#8383;</a> </div> <div id='popup1' class='popup-container'> <div class='popup-content'> <a href='#' class='close'>&times;</a> <h3>Ordinal Edgehogs</h3> <p>This Edgehog is 200% on-chain: it is generated on Ethereum blockchain and rendered on both Ethereum and Bitcoin: its graphics are both encoded on Ethereum and inscribed on Bitcoin and served simultaneously from both chains. <br></br> It also is claimable as a standalone Ordinal. </p> </div> </div>";

  string internal spritesheet;

  string internal fixedTrait1 = _getPart(0); //body is tile 0 
  string internal fixedTrait2 = _getPart(1); //head is tile 1
  string internal fixedTrait3 = _getPart(97); //shadow is tile 97

  //mapping of trait numbers to spritesheet tiles; tile 96 is empty 
  uint256[] internal trait0 = [96,18,19,20,21,22];
  uint256[] internal trait1 = [96,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17];
  uint256[] internal trait2 = [96,76,77,78,79,80,81,82,83,84,85];
  uint256[] internal trait3 = [96,23,24,25,26,27,28,29,30,31,32];
  uint256[] internal trait4 = [96,96,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62];
  uint256[] internal trait5 = [96,86,87,88,89,90,91,92,93,94,95];
  uint256[] internal trait6 = [96,96,63,64,65,66,67,68,69,70,71,72,73,74,75];
  uint256[] internal trait7 = [96,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47];

  function getTileTrait0(uint256 i) internal view returns (uint256 ) {return trait0[i];}
  function getTileTrait1(uint256 i) internal view returns (uint256 ) {return trait1[i];}
  function getTileTrait2(uint256 i) internal view returns (uint256 ) {return trait2[i];}
  function getTileTrait3(uint256 i) internal view returns (uint256 ) {return trait3[i];}
  function getTileTrait4(uint256 i) internal view returns (uint256 ) {return trait4[i];}
  function getTileTrait5(uint256 i) internal view returns (uint256 ) {return trait5[i];}
  function getTileTrait6(uint256 i) internal view returns (uint256 ) {return trait6[i];}
  function getTileTrait7(uint256 i) internal view returns (uint256 ) {return trait7[i];}

  function updateSpritesheet(string calldata _spritesheet) external onlyOwner {spritesheet = _spritesheet;}

  function updateOpeningSVG(string calldata _openingSVG) external onlyOwner {openingSVG = _openingSVG;}
  function updateEndingSVG(string calldata _endingSVG) external onlyOwner {endingSVG = _endingSVG;}

  function _svgStart() internal view returns (string memory) {
        return
            string(
                abi.encodePacked(
                    openingSVG,
                    spritesheet,
                    "' /><clipPath id='c'><rect width='100%' height='100%' /></clipPath></defs><g clip-path='url(#c)'>"
                )
            );
    }

  function _getUseString(uint256 col, uint256 row)
        internal
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "<use href='#s' x='-",
                    col.toString(),
                    "' y='-",
                    row.toString(),
                    "' />"
                )
            );
    }

  function _getPart(uint256 tile) internal pure returns (string memory) {
        uint256 col = (tile % 3) * 40;
        uint256 row = (tile / 3) * 40;
        return _getUseString(col, row);
    }
 
  function renderTrait0(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait0(_trait); return abi.encodePacked(_getPart(tileNumber));}
  function renderTrait1(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait1(_trait); return abi.encodePacked("<g class='effect2'>", _getPart(tileNumber), "</g>");}
  function renderTrait2(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait2(_trait); return abi.encodePacked(_getPart(tileNumber));}
  function renderTrait3(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait3(_trait); return abi.encodePacked(_getPart(tileNumber));}
  function renderTrait4(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait4(_trait); return abi.encodePacked("<g class='effect'>", _getPart(tileNumber), "</g>");}
  function renderTrait5(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait5(_trait); return abi.encodePacked(_getPart(tileNumber));}
  function renderTrait6(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait6(_trait); return abi.encodePacked(_getPart(tileNumber));}
  function renderTrait7(uint256 _trait) internal view returns (bytes memory) { uint256 tileNumber = getTileTrait7(_trait); return abi.encodePacked("<g class='effect2'>", _getPart(tileNumber), "</g>");}

  function renderFixedTrait1() internal view returns (bytes memory) {return abi.encodePacked(fixedTrait1);}      //Body
  function renderFixedTrait2() internal view returns (bytes memory) {return abi.encodePacked("<g class='effect'>", fixedTrait2, "</g>");} //Head
  function renderFixedTrait3() internal view returns (bytes memory) {return abi.encodePacked(fixedTrait3);}      //Shadow

  function renderOpeningSVG() internal view returns (bytes memory) {return abi.encodePacked(_svgStart());}
  function renderEndingSVG() internal view returns (bytes memory) {return abi.encodePacked(endingSVG);}

  //Get attribute svg for each different property of the token, separated in parts to avoid 'stack too deep' error
  function renderSVG(
      uint16 _trait0,
      uint16 _trait1,
      uint16 _trait2,
      uint16 _trait3,
      uint16 _trait4,
      uint16 _trait5,
      uint16 _trait6,
      uint16 _trait7
    ) public view returns (bytes memory) {
      bytes memory part1 = abi.encodePacked(
        renderOpeningSVG(),    //opening code
        renderTrait0(_trait0), //background
        renderFixedTrait3(),   //shadow
        renderTrait1(_trait1), //back
        renderFixedTrait1()    //body
      );
      bytes memory part2 = abi.encodePacked(
        part1,
        renderTrait2(_trait2), //pants
        renderTrait3(_trait3), //clothes   
        renderFixedTrait2()    //head
      );
      return abi.encodePacked(
        part2,
        renderTrait4(_trait4), //headgear 
        renderTrait5(_trait5), //shoes
        renderTrait6(_trait6), //item 
        renderTrait7(_trait7), //eyes
        renderEndingSVG()      //ending code
      );
    }


}