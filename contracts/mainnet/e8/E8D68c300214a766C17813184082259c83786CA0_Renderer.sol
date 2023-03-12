// SPDX-License-Identifier: MIT

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

contract Renderer is Ownable {
 
  //opening and closing for SVG file
  string internal openingSVG = "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' image-rendering='pixelated' viewBox='0 0 800 800'>";
  string internal endingSVG ="<style> .effect { animation: 0.75s effect infinite alternate ease-in-out; } @keyframes effect { from { transform: translateY(0px); } to { transform: translateY(2.5%); } }.effect2 { animation: 0.75s effect2 infinite alternate ease-in-out; } @keyframes effect2 { from { transform: translateY(0px); } to { transform: translateY(1.5%); } } </style> </svg>";
  
  //opening and closing for images
  string internal openingIMG ="<foreignObject x='0' y='0' width='800' height='800'><img xmlns='http://www.w3.org/1999/xhtml' height='800' width='800' src='data:image/png;base64,";
  string internal endingIMG = "'/></foreignObject>";

  //constant parts that are not randomized
  string internal fixedTrait1 = "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAG1BMVEUAAAAnDQislnWTg2q9qIhZVlLLtaE7NzLezLzZuBaIAAAAAXRSTlMAQObYZgAAAHtJREFUKM9jGAWDEYhiEWMsDcAiGGyOKShurKReXi6AZqSRSpqTKqogY7GSi1uasiCqYJGyiluGk6gAqqCwiktak6giFkFBVMFikKCSgCCKoGAwUFAZ3UnGRm5JphiCQBCIHh6mgYLBAujeDBdgLEUXFBQUYBQECtIZAADsZxPbfZk9RAAAAABJRU5ErkJggg==";
  string internal fixedTrait2 = "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAJ1BMVEUAAAAnDQich2aslnW9qIiTg2o7NzLezLxZVlIAAADsmJnNd3jDXV6RqQwDAAAAAXRSTlMAQObYZgAAAFNJREFUKM9jGAWMgggKIbhaEASkF6IolelQcS931hFA1Z9kbOJipIYuaBrsYhqGKeiOKaga7FKkiOamDGVjo5mNaC4VbFLSnAnTjRAFAoZRMLAAAEOoDnwejNL6AAAAAElFTkSuQmCC";
  string internal fixedTrait3 = "iVBORw0KGgoAAAANSUhEUgAAACgAAAAoBAMAAAB+0KVeAAAAIVBMVEUAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABt0UjBAAAAC3RSTlMAYEJYVDQnGBNOTJeVFx8AAAAzSURBVCjPYxgFo2BIAvZULRdDYZdFYQUIsSZBONCACxoiBIVxqESYqeksKGgyCWgmiQAAX5gI535S03cAAAAASUVORK5CYII=";

  string[] internal trait0;
  string[] internal trait1;
  string[] internal trait2;
  string[] internal trait3;
  string[] internal trait4;  
  string[] internal trait5;
  string[] internal trait6;
  string[] internal trait7;

  function _addTrait0(string calldata _trait) internal {trait0.push(_trait);}
  function _addTrait1(string calldata _trait) internal {trait1.push(_trait);}
  function _addTrait2(string calldata _trait) internal {trait2.push(_trait);}
  function _addTrait3(string calldata _trait) internal {trait3.push(_trait);}
  function _addTrait4(string calldata _trait) internal {trait4.push(_trait);}
  function _addTrait5(string calldata _trait) internal {trait5.push(_trait);}
  function _addTrait6(string calldata _trait) internal {trait6.push(_trait);}
  function _addTrait7(string calldata _trait) internal {trait7.push(_trait);}

  function updateOpeningSVG(string calldata _openingSVG) external onlyOwner {openingSVG = _openingSVG;}
  function updateEndingSVG(string calldata _endingSVG) external onlyOwner {endingSVG = _endingSVG;}
  function updateOeningIMG(string calldata _openingIMG) external onlyOwner {openingIMG = _openingIMG;}
  function updateEndingIMG(string calldata _endingIMG) external onlyOwner {endingIMG = _endingIMG;}

  function updateFixedTrait1(string calldata _fixedTrait1) external onlyOwner {fixedTrait1 = _fixedTrait1;}
  function updateFixedTrait2(string calldata _fixedTrait2) external onlyOwner {fixedTrait2 = _fixedTrait2;}
  function updateFixedTrait3(string calldata _fixedTrait3) external onlyOwner {fixedTrait3 = _fixedTrait3;}

  // calldata input format: ["trait1","trait2","trait3",...]
  function addTrait0(string[] calldata _traits) external onlyOwner {clearTrait0(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait0(_traits[i]);}}
  function addTrait1(string[] calldata _traits) external onlyOwner {clearTrait1(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait1(_traits[i]);}}
  function addTrait2(string[] calldata _traits) external onlyOwner {clearTrait2(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait2(_traits[i]);}}
  function addTrait3(string[] calldata _traits) external onlyOwner {clearTrait3(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait3(_traits[i]);}}
  function addTrait4(string[] calldata _traits) external onlyOwner {clearTrait4(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait4(_traits[i]);}}
  function addTrait5(string[] calldata _traits) external onlyOwner {clearTrait5(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait5(_traits[i]);}}
  function addTrait6(string[] calldata _traits) external onlyOwner {clearTrait6(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait6(_traits[i]);}}
  function addTrait7(string[] calldata _traits) external onlyOwner {clearTrait7(); for (uint256 i = 0; i < _traits.length; i++) {_addTrait7(_traits[i]);}}

  function clearTrait0() internal onlyOwner {delete trait0;}
  function clearTrait1() internal onlyOwner {delete trait1;}
  function clearTrait2() internal onlyOwner {delete trait2;}
  function clearTrait3() internal onlyOwner {delete trait3;}
  function clearTrait4() internal onlyOwner {delete trait4;}
  function clearTrait5() internal onlyOwner {delete trait5;}
  function clearTrait6() internal onlyOwner {delete trait6;}
  function clearTrait7() internal onlyOwner {delete trait7;}
 
  function renderTrait0(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked(openingIMG, trait0[_trait], endingIMG);}
  function renderTrait1(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked("<g class='effect2'>", openingIMG, trait1[_trait], endingIMG,"</g>");}
  function renderTrait2(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked(openingIMG, trait2[_trait], endingIMG);}
  function renderTrait3(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked(openingIMG, trait3[_trait], endingIMG);}
  function renderTrait4(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked("<g class='effect'>", openingIMG, trait4[_trait], endingIMG,"</g>");}
  function renderTrait5(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked(openingIMG, trait5[_trait], endingIMG);}
  function renderTrait6(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked(openingIMG, trait6[_trait], endingIMG);}
  function renderTrait7(uint256 _trait) internal view returns (bytes memory) {return abi.encodePacked("<g class='effect2'>", openingIMG, trait7[_trait], endingIMG,"</g>");}

  function renderFixedTrait1() internal view returns (bytes memory) {return abi.encodePacked(openingIMG, fixedTrait1, endingIMG);}                                //Body
  function renderFixedTrait2() internal view returns (bytes memory) {return abi.encodePacked("<g class='effect'>", openingIMG, fixedTrait2, endingIMG,"</g>");}   //Head
  function renderFixedTrait3() internal view returns (bytes memory) {return abi.encodePacked(openingIMG, fixedTrait3, endingIMG);}                                //Shadow

  function renderOpeningSVG() internal view returns (bytes memory) {return abi.encodePacked(openingSVG);}
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