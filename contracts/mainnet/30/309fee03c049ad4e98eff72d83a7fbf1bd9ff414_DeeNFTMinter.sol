/**
 *Submitted for verification at Etherscan.io on 2022-08-27
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-11
*/

// SPDX-License-Identifier: MIT

/**
 *Submitted for verification at BscScan.com on 2021-10-14
*/

pragma solidity ^0.6.0;

interface ERC721Interface {
  function transferFrom(address _from, address _to, uint256 _tokenId) external ;
  function ownerOf(uint256 _tokenId) external view returns (address);
  function approve(address _to, uint256 _tokenId) external;
  function mint(address player,uint256 tokenId) external returns (uint256);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Minters is Ownable{

    mapping(address => bool) private _minters;

    event MinterAdded(address indexed minter);

    event MinterRemoved(address indexed minter);

    modifier onlyMinter() {
        require(_minters[_msgSender()], "ERC721: caller is not the owner");
        _;
    }


    function addMinter(address minter) external onlyOwner {
        _minters[minter] = true;
        MinterAdded(minter);
    }

    function removeMinter(address minter) external onlyOwner {
        _minters[minter] = false;
        MinterRemoved(minter);
    }

    function isMinter(address minter) external view returns(bool) {
        return _minters[minter];
    }
}

contract DeeNFTMinter is Minters {
    
    // dee nft contract
    address public nftContract;

    //This pool stores the amount of NFTs generated for each role and level
    mapping (uint => uint) public pool;

    mapping (uint256=>address) public tokenIdHolders;

    event CreateNFT(
        uint indexed _character,
        uint indexed _level,
        uint _amount,
        address _toAddress
    );

    constructor(address _nftContract) public{
        nftContract = _nftContract;
    }

    function initPoolStartIndex(uint character, uint level, uint amount) public onlyOwner{
        uint key = 10000 + character * 100 + level;
        pool[key] = amount;
    }

    function mintNFT(uint character, uint level, uint amount,address toAddress) public onlyMinter {

        for(uint i=0;i<amount;i++){

            uint key = 10000 + character * 100 + level;
            uint amountIdx = pool[key];

            // 30102090100000004 
            uint256 nftId = 30100000000000000 + 1000000000000 * character + 10000000000 * level + amountIdx;
            ERC721Interface(nftContract).mint(toAddress,nftId);

            //modify storage
            pool[key] = amountIdx + 1;

            emit CreateNFT(character,level,amount,toAddress);
        }
    }
}