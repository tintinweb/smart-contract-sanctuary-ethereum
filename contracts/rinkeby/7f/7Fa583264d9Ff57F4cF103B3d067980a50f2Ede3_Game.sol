/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// File: contracts/Game.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;


contract Game is Ownable {

    uint public fightPrice = 0.01 ether;

    uint[] commonProbability;  
    uint[] rareProbability;
    uint[] legendProbability;
    uint[] commonReward;
    uint[] rareReward;
    uint[] legendReward;
    
    event FightLog(address fightAddress, uint reward);
    event AddPool(uint money);
 
    RedCat redcatsContract = RedCat(0x5694259FEaE74d8275244e45bC179E795B73b144);

    //預設開啟要有機率和多少獎池
    constructor(uint[] memory _commonProbability, uint[] memory _commonReward, uint[] memory _rareProbability, uint[] memory _rareReward, uint[] memory _legendProbability, uint[] memory _legendReward) payable {
        commonProbability = _commonProbability;
        commonReward = _commonReward;
        rareProbability = _rareProbability;
        rareReward = _rareReward;
        legendProbability = _legendProbability;
        legendReward = _legendReward;
    }

    //玩
    function play(uint _tokenId) public payable {
        require(msg.value == fightPrice, "money sent is not correct");
        require(msg.sender == tx.origin, "contract don't play");  
        require(isNFTOwner(_tokenId), "cat isn't your");

        (, uint rarity) = getRarity(_tokenId);
        if(rarity == 0 || rarity == 1) {
            for (uint i = 0; i < rareProbability.length; i++) {
                if (random() % (rareProbability[rareProbability.length - 1]) < rareProbability[i]) {
                    uint reward = rareReward[i] * 1 gwei;
                    payable(msg.sender).transfer(reward);
                    emit FightLog(msg.sender, reward);
                    break;
                }
            }
        } else {
            for (uint i = 0; i < legendProbability.length; i++) {
                if (random() % (legendProbability[legendProbability.length - 1]) < legendProbability[i]) {
                    uint reward = legendReward[i] * 1 gwei;
                    payable(msg.sender).transfer(reward);
                    emit FightLog(msg.sender, reward);
                    break;
                }
            }    
        }
    }

    //沒貓還要玩
    function noCatPlay() public payable {
        require(msg.value == fightPrice, "money sent is not correct");
        require(msg.sender == tx.origin, "contract don't play");
        require(getPool() - msg.value > 0, "no money for pool");

        for (uint i = 0; i < commonProbability.length; i++) {
            if (random() % (commonProbability[commonProbability.length - 1]) < commonProbability[i]) {
                uint reward = commonReward[i] * 1 gwei;
                payable(msg.sender).transfer(reward);
                emit FightLog(msg.sender, reward);
                break;
            }
        }
    }

    //添加獎池 大家都可
    function addPoolMoney() public payable {
       emit AddPool(msg.value);
    }

    function setFightPrice(uint _fightPrice) public onlyOwner {
       fightPrice = _fightPrice;
    }

    function setCommonProbability(uint[] calldata _commonProbability) public onlyOwner {
        commonProbability = _commonProbability;
    }

    function setRareProbability(uint[] calldata _rareProbability) public onlyOwner {
        rareProbability = _rareProbability;
    }

    function setLegendProbability(uint[] calldata _legendProbability) public onlyOwner {
        legendProbability = _legendProbability;
    }
  
    function setCommonReward(uint[] calldata _commonReward) public onlyOwner {
        commonReward = _commonReward;
    }

    function setRareReward(uint[] calldata _rareReward) public onlyOwner {
        rareReward = _rareReward;
    }

    function setLegendReward(uint[] calldata _legendReward) public onlyOwner {
        legendReward = _legendReward;
    }

    function withdraw() public onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //取得機率 
    function getCommonProbability() public view returns (uint[] memory) {
        return commonProbability;
    }

    function getRareProbability() public view returns (uint[] memory) {
        return rareProbability;
    }

    function getLegendProbability() public view returns (uint[] memory) {
        return legendProbability;
    }

    //取得獎勵       
    function getCommonReward() public view returns (uint[] memory) {
        return commonReward;
    }

    function getRareReward() public view returns (uint[] memory) {
        return rareReward;
    }

    function getLegendReward() public view returns (uint[] memory) {
        return legendReward;
    }

    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(blockhash(block.number), msg.sender, block.number, block.timestamp, msg.value)));
    }

    function getPool() public view returns (uint) {
        return address(this).balance;
    }

    function getRarity(uint _tokenId) private view returns (uint, uint) {
      return redcatsContract.getRarity(_tokenId);
    }

    function isNFTOwner(uint _tokenId) private view returns (bool) { 
        if(msg.sender == redcatsContract.ownerOf(_tokenId)) {
            return true;
        } else {
            return false;
        }
    }
}

interface RedCat  {
    function getRarity(uint _tokenId) external view returns (uint, uint);
    function ownerOf(uint _tokenId) external view returns (address);
}