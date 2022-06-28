/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

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

interface iOKey {
    function ownerOf(uint256 tokenId) external view returns (address);
    function mintOkey(address to, uint tokenId) external;
    function exist(uint tokenId) external view returns (bool);
     function transferFrom(address from, address to, uint id) external;
}

interface iBlueCheck {
    function mintBC(address to, uint tokenId) external;
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function transferFrom(address from, address to, uint id) external;
}

// @author doubleweb3
contract DoubleHub is Ownable {
    iOKey _OKEY;
    iBlueCheck _BC;

    mapping (uint => string) tokenId2identity; 
    mapping (string => uint) identity2TokenId; 
    uint256 mintedIndex;

    constructor(address okey, address blueCheck) {
        _OKEY = iOKey(okey);
        _BC = iBlueCheck(blueCheck);
    }

    function mintKeyPair(address target, string memory identityHash)
    public onlyOwner {        
        require(!_BC.exist(mintedIndex), "BlueCheck ID already exist");
        require(_BC.balanceOf(target) == 0, "target address already has BlueCheck");

        _BC.mintBC(target, mintedIndex);
        _OKEY.mintOkey(target, mintedIndex);

        tokenId2identity[mintedIndex] = identityHash;
        identity2TokenId[identityHash] = mintedIndex;
        mintedIndex++;
    }


    function hardRevoke(string memory identityHash) 
    public onlyOwner {
        uint tokenId = identity2TokenId[identityHash];
        require(strCompare(tokenId2identity[tokenId], identityHash), "identityHash not exist");
        require(_BC.exist(tokenId), "BlueCheck not exist");

        _BC.transferFrom(_BC.ownerOf(tokenId), address(0), tokenId);
        _OKEY.transferFrom(_OKEY.ownerOf(tokenId), address(0), tokenId);
    }

    function revoke(uint tokenId)
    public {
        require(_BC.exist(tokenId), "BlueCheck not exist");
        require(msg.sender == _OKEY.ownerOf(tokenId), "require Okey to proceed");

        _BC.transferFrom(_BC.ownerOf(tokenId), address(0), tokenId);
        _OKEY.transferFrom(_OKEY.ownerOf(tokenId), address(0), tokenId);
    }


    function transferOKEY(address to, uint tokenId)
    public {
        require(msg.sender == _OKEY.ownerOf(tokenId), "not OKEY owner");
        require(_OKEY.exist(tokenId), "OKEY not exist");

        _OKEY.transferFrom(msg.sender, to, tokenId);
    }

    function memCompare(bytes memory a, bytes memory b) internal pure returns(bool){
        return (a.length == b.length) && (keccak256(a) == keccak256(b));
    }

    function strCompare(string memory a, string memory b) internal pure returns(bool){
        return memCompare(bytes(a), bytes(b));
    }
}