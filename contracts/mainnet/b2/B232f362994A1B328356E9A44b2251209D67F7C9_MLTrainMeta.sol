// SPDX-License-Identifier: MIT

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

//------------------------------------------------------------------------------
// geneticchain.io - NextGen Generative NFT Platform
//------------------------------------------------------------------------------
//    _______                   __   __        ______ __          __
//   |     __|-----.-----.-----|  |_|__|----. |      |  |--.---.-|__|-----.
//   |    |  |  -__|     |  -__|   _|  |  __| |   ---|     |  _  |  |     |
//   |_______|_____|__|__|_____|____|__|____| |______|__|__|___._|__|__|__|
//
//------------------------------------------------------------------------------
// Genetic Chain: Member Lounde: Train Meta
//------------------------------------------------------------------------------
// Author: papaver (@tronicdreams)
//------------------------------------------------------------------------------

import "openzeppelin-solidity/contracts/access/Ownable.sol";

//------------------------------------------------------------------------------
// interfaces
//------------------------------------------------------------------------------

/**
 * Lounge interface.
 */
interface ILounge {

  function mint(address to, uint256 id, uint256 amount)
    external;

  function burn(address to, uint256 id, uint256 amount)
    external;

  function balanceOf(address account, uint256 id)
    external view returns (uint256);

  function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
    external view returns (uint256[] memory);

  function uri(uint256 tokenId)
    external view returns (string memory);

}

//------------------------------------------------------------------------------
// Member Lounge: Train Meta
//------------------------------------------------------------------------------

/**
 * @title Member Lounge: Train Meta
 */
contract MLTrainMeta is Ownable
{

    //-------------------------------------------------------------------------
    // events
    //-------------------------------------------------------------------------

    /**
     * Emited when train hop attempted.
     */
    event TrainHop(address indexed owner, uint256 current, uint256 next, bool success);

    //-------------------------------------------------------------------------
    // fields
    //-------------------------------------------------------------------------

    // member lounge contract
    ILounge private immutable _lounge;

    // train tokens
    uint256[] private _trains;

    //-------------------------------------------------------------------------
    // modifiers
    //-------------------------------------------------------------------------

    modifier validTokenId(uint256 tokenId) {
        require(bytes(_lounge.uri(tokenId)).length != 0, "invalid token");
        _;
    }

    //-------------------------------------------------------------------------

    modifier hasBalance(address owner, uint256 trainIdx) {
        require(_lounge.balanceOf(owner, _trains[trainIdx]) > 0, "invalid balance");
        _;
    }

    //-------------------------------------------------------------------------

    modifier canHop(uint256 trainIdx) {
        require(trainIdx + 1 < _trains.length , "invalid hop");
        _;
    }

    //-------------------------------------------------------------------------
    // ctor
    //-------------------------------------------------------------------------

    constructor(address lounge, uint256[] memory trains)
    {
        _lounge = ILounge(lounge);
        _trains = trains;
    }

    //-------------------------------------------------------------------------
    // admin
    //-------------------------------------------------------------------------

    function pushTrain(uint tokenId)
        public
        onlyOwner
        validTokenId(tokenId)
    {
        _trains.push(tokenId);
    }

    //-------------------------------------------------------------------------

    function popTrain()
        public
        onlyOwner
    {
        _trains.pop();
    }

    //-------------------------------------------------------------------------
    // helper functions
    //-------------------------------------------------------------------------

    /**
     * @dev Create a Pseudo-random number using block info.
     */
    function _random(uint256 tokenId)
        internal
        view
        returns (uint256)
    {
      return uint256(keccak256(
          abi.encodePacked(
              address(this),
              block.difficulty,
              blockhash(block.number),
              block.timestamp,
              msg.sender,
              tokenId)));
    }

    //-------------------------------------------------------------------------
    // methods
    //-------------------------------------------------------------------------

    /**
     * @dev Return list of passes staked by staker.
     */
    function getTrains()
        public
        view
        returns (uint256[] memory)
    {
        return _trains;
    }

    //-------------------------------------------------------------------------

    /**
     * @dev Returns users train balances.
     */
    function balances(address user)
        public
        view
        returns (uint256[] memory)
    {
        address[] memory addresses = new address[](_trains.length);
        for (uint256 i = 0; i < addresses.length; ++i) {
            addresses[i] = user;
        }
        return _lounge.balanceOfBatch(addresses, _trains);
    }

    //-------------------------------------------------------------------------

    /**
     * Hop to next tain, 50% chance of making it.
     */
    function hopTrain(uint256 trainIdx)
        external
        hasBalance(msg.sender, trainIdx)
        canHop(trainIdx)
    {
        uint256 current = _trains[trainIdx];
        uint256 next    = _trains[trainIdx + 1];

        // current always gets burned
        _lounge.burn(msg.sender, current, 1);

        // 50% chance they make it to the next train
        uint256 random = _random(current);
        bool madeIt    = random & 0x1 == 0x1;
        if (madeIt) {
            _lounge.mint(msg.sender, next, 1);
        }

        // track hops
        emit TrainHop(msg.sender, current, next, madeIt);
    }

}