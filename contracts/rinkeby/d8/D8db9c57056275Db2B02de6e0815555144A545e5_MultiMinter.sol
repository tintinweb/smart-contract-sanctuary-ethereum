// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
// import "hardhat/console.sol";

interface NFT {
    // function mint(uint256 _amount) external payable;

    function setApprovalForAll(address operator, bool approved) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    // function NFT_PRICE() external view returns (uint256);

    // function MAX_SUPPLY() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    // function mintStartTime() external view returns (uint256);

    function ownerOf(uint256 tokenID) external view returns (address);

    function balanceOf(address proxy) external view returns (uint256);
}

struct WithdrawData {
    address payable cloneAddress;
    uint256[] tokenIds;
}

contract MultiMinter is Ownable {
    address payable[] public clones;

    bool initialized;
    address public _owner;

    constructor(
    ) {
        _owner = msg.sender;
    }

    function newClone() internal returns (address payable result) {
        bytes20 targetBytes = bytes20(address(this));

        assembly {
            let clone := mload(0x40)
            mstore(
                clone,
                0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000
            )
            mstore(add(clone, 0x14), targetBytes)
            mstore(
                add(clone, 0x28),
                0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000
            )
            result := create(0, clone, 0x37)
        }

        return result;
    }

    function setOwner(address owner) external {
        require(!initialized, "already set");
        _owner = owner;
        initialized = true;
    }

    function clonesCreate(uint256 quantity) public {
        for (uint256 i; i < quantity; i++) {
            address payable clone = newClone();
            clones.push(clone);
            // clone.transfer(nftPrice);
            MultiMinter(clone).setOwner(address(this));
        }
    }

    function clonesDeposit(
        uint256 amount, 
        uint256 nftNumberPerClone,
        uint256 nftPrice
    )
        public
        payable
    {

        require(clones.length >= amount, "Not enough clones");
        for (uint256 i; i < amount; i++) {
            clones[i].transfer(nftPrice * nftNumberPerClone);
        }
    }

    function ethBack(address payable owner) public {
        require(msg.sender == _owner, "Not owner");
        owner.transfer(address(this).balance);
    }

    function ethBackFromClones(address payable owner) public onlyOwner {
        for (uint256 i; i < clones.length; i++) {
            MultiMinter(clones[i]).ethBack(owner);
        }
    }

    function deployedClonesMint(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public onlyOwner {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();

        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
        }

        for (uint256 i; i < clonesAmount; i++) {
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
    }

    function deployedClonesMintPayable(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public payable {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();

        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
        }

        for (uint256 i; i < clonesAmount; i++) {
            clones[i].transfer(nftPrice * txPerClone * mintPerCall);
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
        }
        
    }

    function mintNoClones(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 _numberOfTokens,
        uint256 _txCount,
        bytes calldata datacall
    ) public payable {
        uint256 totalMint = _numberOfTokens * _txCount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();
        uint256 startGas = gasleft();
        uint256 gasPerEach = 0;

        if (totalMint > remaining) {
            _txCount = remaining / _numberOfTokens;
        }


        for (uint256 i; i < _txCount; i++) {

            if (gasleft() > gasPerEach) {
                (bool success, bytes memory data) = saleAddress.call{
                    value: nftPrice * _numberOfTokens
                }(datacall);

                
                require(success, "Reverted from sale");
                if(gasPerEach == 0){ //If gasPerEach is not set
                    gasPerEach = startGas - gasleft();
                }

            }
        }
    }

    function createClonesInTx(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes calldata datacall
    ) public payable {

        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();

        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
        }

        for (uint256 i; i < clonesAmount; i++) {
            address payable clone = newClone();

            clone.transfer(nftPrice * txPerClone * mintPerCall);
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clone).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall
                );
                MultiMinter(clone).setOwner(address(this));
        }
    }

    function deployedClonesMintDiffData(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes[] calldata datacall
    ) public onlyOwner {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();

        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
        }

        for (uint256 i; i < clonesAmount; i++) {
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall[i]
                );
        }
    }

    function deployedClonesMintDiffDataPayable(
        address saleAddress,
        uint256 nftPrice,
        uint256 maxSupply,

        uint256 clonesAmount,
        uint8 txPerClone,
        uint8 mintPerCall,
        bytes[] calldata datacall
    ) public payable {
        require(clonesAmount <= clones.length, "Too much clones");
        uint256 totalMint = mintPerCall * txPerClone * clonesAmount;
        uint256 remaining = maxSupply - NFT(saleAddress).totalSupply();

        if (totalMint > remaining) {
            clonesAmount = remaining / (mintPerCall * txPerClone);
        }

        for (uint256 i; i < clonesAmount; i++) {
            clones[i].transfer(nftPrice * txPerClone * mintPerCall);
            for (uint256 j; j < txPerClone; j++)
                MultiMinter(clones[i]).mintClone(
                    saleAddress,
                    mintPerCall,
                    nftPrice,
                    datacall[i]
                );
        }
    }

    function mintClone (
        address sale,
        uint256 _mintPerClone,
        uint256 _nftPrice,
        bytes calldata datacall
    ) public {
        (bool success, bytes memory data) = sale.call{
            value: _nftPrice * _mintPerClone
        }(datacall);
        require(success, "Reverted from Sale");
    }

    function getArrayNft(
        WithdrawData[] memory withdrawData,
        address nftContract,
        address to
    ) public onlyOwner {
        for (uint256 i; i < withdrawData.length; i++) {
            MultiMinter(withdrawData[i].cloneAddress).getNft(
                withdrawData[i].tokenIds,
                nftContract,
                to
            );
        }
    }

    function getNft(
        uint256[] memory tokenIds,
        address sale,
        address to
    ) public {
        require(msg.sender == _owner, "Not owner");

        // NFT(sale).setApprovalForAll(to, true);
        for (uint256 i; i < tokenIds.length; i++) {
            NFT(sale).transferFrom(address(this), to, tokenIds[i]);
        }
    }

    receive() external payable {}

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        // return this.onERC721Received.selector;
        return 0x150b7a02;
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