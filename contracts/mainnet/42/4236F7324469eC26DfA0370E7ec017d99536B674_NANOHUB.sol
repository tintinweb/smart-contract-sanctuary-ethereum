//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./Ownable.sol";

interface i0N1 {
    function ownerOf(uint256 tokenId) external view returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

interface iFRAME {
    function mintFRAME(address to, uint tokenId) external;
    function exist(uint tokenId) external view returns (bool);
    function ownerOf(uint tokenId) external view returns (address);
    function transferFrom(address from, address to, uint id) external;
}

/// @author jolan.eth
contract NANOHUB is Ownable {
    i0N1 _0N1;
    iFRAME _FRAME;

    bool public MINT = false;

    constructor(address ONI, address FRAME) {
        _0N1 = i0N1(ONI);
        _FRAME = iFRAME(FRAME);
    }

    function setMint()
    public onlyOwner {
        MINT = !MINT;
    }

    function mintFRAME(uint tokenId)
    public {
        require(MINT, "error MINT");
        require(!_FRAME.exist(tokenId), "error FRAME.exist");
        require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
        _FRAME.mintFRAME(msg.sender, tokenId);
    }

    function batchMintFRAME()
    public {
        require(MINT, "error MINT");
        uint i = 0;
        uint balance = _0N1.balanceOf(msg.sender);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(msg.sender, i);
            if (!_FRAME.exist(tokenId)) {
                require(!_FRAME.exist(tokenId), "error FRAME.exist");
                require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
                _FRAME.mintFRAME(msg.sender, tokenId);
            }
            i++;
        }
    }

    function recallFRAME(uint tokenId)
    public {
        require(_FRAME.exist(tokenId), "error FRAME.exist");
        require(msg.sender != _FRAME.ownerOf(tokenId), "error FRAME.owner");
        require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");

        address frameOwner = _FRAME.ownerOf(tokenId);
        _FRAME.transferFrom(frameOwner, msg.sender, tokenId);
    }

    function batchRecallFRAME()
    public {
        uint i = 0;
        uint balance = _0N1.balanceOf(msg.sender);
        while (i < balance) {
            uint tokenId = _0N1.tokenOfOwnerByIndex(msg.sender, i);
            require(msg.sender == _0N1.ownerOf(tokenId), "error 0N1.owner");
            require(_FRAME.exist(tokenId), "error FRAME.exist");
            if (msg.sender != _FRAME.ownerOf(tokenId)) {
                address frameOwner = _FRAME.ownerOf(tokenId);
                _FRAME.transferFrom(frameOwner, msg.sender, tokenId);
            }
            i++;
        }
    }

    function transferFRAME(address to, uint tokenId)
    public {
        require(msg.sender == _FRAME.ownerOf(tokenId), "error FRAME.owner");
        require(_FRAME.exist(tokenId), "error FRAME.exist");

        _FRAME.transferFrom(msg.sender, to, tokenId);
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8;

abstract contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(owner() == msg.sender, "error owner()");
        _;
    }

    constructor() { _transferOwnership(msg.sender); }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "error newOwner");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}