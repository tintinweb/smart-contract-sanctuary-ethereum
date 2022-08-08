pragma solidity >=0.5.0 < 0.9.0;

import './KnightAttack.sol';
import './IERC721.sol';

contract KnightOwnerShip is KnightAttack, IERC721 {

    mapping(uint256 => address) private knightApprovals;
    
    function balanceOf(address _owner) public view virtual override returns (uint256) {
        require(_owner != address(0), "ERC721: address zero is not a valid owner");
        return countKnightToOwner[_owner];
    }

    function ownerOf(uint256 _knightID) public view virtual override returns (address) {
        address owner = knightToOwner[_knightID];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function _transferKnight(
        address _from,
        address _to,
        uint256 _knightID
    ) internal  {
        // require(this.ownerOf(_knightID) == _from, "ERC721: transfer from incorrect owner"); // valid ->this can acccess public fn 
        // require(this._isApprovedOrOwner(_from, _knightID)); // invalid this can't acccess internal fn, private 
        require(KnightOwnerShip.ownerOf(_knightID) == _from, "ERC721: transfer from incorrect owner");
        require(_to != address(0), "ERC721: transfer to the zero address");
        delete knightApprovals[_knightID];
        unchecked {
            countKnightToOwner[_from] -= 1;
            countKnightToOwner[_to] += 1;
        }
        knightToOwner[_knightID] = _to;

        emit Transfer(_from, _to, _knightID);
    }

    function _approve(address _to, uint256 _knightID) internal virtual {
        knightApprovals[_knightID] = _to;
        emit Approval(KnightOwnerShip.ownerOf(_knightID), _to, _knightID);
    }

    function _isApprovedOrOwner(address _spender, uint256 _knightID) internal view virtual returns (bool) {
        address owner = KnightOwnerShip.ownerOf(_knightID);
        return (_spender == owner  || getApproved(_knightID) == _spender);
    }

    function getApproved(uint256 _knightID) public view virtual override returns (address) {
        return knightApprovals[_knightID];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _knightID
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), _knightID), "ERC721: caller is not token owner or approved");
        _transferKnight(_from, _to, _knightID);
    }

    function approve(address _to, uint256 _knightID) external override  onlyOwnerOfKnight(_knightID){
        _approve(_to, _knightID);
    }

}

pragma solidity >=0.5.0 <0.9.0;

import './KnightHelper.sol';

contract KnightAttack is KnightHelper {

    uint randNonce = 0;
    uint victoryProbability = 50;

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function attack(uint _attackknightID, uint _defenseKnightID) external onlyOwnerOfKnight(_attackknightID) {
        Knight storage myKnight = listOfKnight[_attackknightID];
        Knight storage enemyKnight = listOfKnight[_defenseKnightID];
        uint luckyNumber = randMod(100);
        // luckyNumber nhỏ hơn xác xuất chiến thắng cộng với điểm phấn khích của hiệp sĩ
        // VD: điểm may mắn random là 30 , điểm xác suất chiến thắng là 50  + điểm phân khích cảu hiệp sĩ tối đa là 20 = 70 
        //  30 < 70 nên  _attackknightID  sẽ thắng
        if(luckyNumber <= victoryProbability + myKnight.excitementPoint) {
            unchecked {
                myKnight.winCount++;
                myKnight.level++;
                enemyKnight.lostCount++;
            }
            feedAndMultiply(_attackknightID, enemyKnight.dna);
        } else {
            unchecked {
                enemyKnight.winCount++;
                myKnight.lostCount++;
            }
            _triggerCoolDown(myKnight);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity <0.9.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    
    function getApproved(uint256 tokenId) external view returns (address operator);

}

pragma solidity >= 0.5.0 <0.9.0;  

import './KnightFeeding.sol';

contract KnightHelper is KnightFeeding {

    uint payTolevelUp = 0.001 ether;

    modifier aboveLevel(uint _level, uint _knightID) {
        require(listOfKnight[_knightID].level >= _level);
        _;
    }

    function changeName(uint _knightID, string calldata _newnName) external aboveLevel(2, _knightID) onlyOwnerOfKnight(_knightID) {
        // require(knightToOwner[_knightID] == msg.sender);
        Knight storage myKnight =  listOfKnight[_knightID];
        myKnight.name = _newnName;
        // listOfKnight[_knightID].name = _newnName;
    }

    function changeDna(uint _knightID, uint _newDna) external aboveLevel(20, _knightID) onlyOwnerOfKnight(_knightID) {
        // require(knightToOwner[_knightID] == msg.sender);
        Knight storage myKnight =  listOfKnight[_knightID];
        myKnight.dna = _newDna;
        // listOfKnight[_knightID].dna = _newnDna;
    }

    function getKnightsByOwner(address _owner) external view returns(uint[] memory){
        uint[] memory listKnight = new uint[]( countKnightToOwner[_owner]);
        uint counter = 0;
        for (uint i = 0; i < listOfKnight.length; i++) {
            if(knightToOwner[i] == _owner){
                listKnight[counter] = i;
                counter++;
            }
        }
        return listKnight;
    }
    function levelUp(uint _knightID) external payable {
        require(msg.value == payTolevelUp);
        Knight storage myKnight =  listOfKnight[_knightID];
        myKnight.level++;
        // listOfKnight[_knightID].level++;
    }

    // chức năng mới xây dựng 26/7
    function knightGoMassage(uint _knightID) external payable {
        require(msg.value == payTolevelUp);
        Knight storage myKnight =  listOfKnight[_knightID];
        require(myKnight.excitementPoint < 20,"Knight has maxed out excitement points");
        myKnight.excitementPoint += 2;
    }

    function withdraw() external onlyOwner {
        //  address payable _owner = address(uint160(owner()));
        // _owner.transfer(address(this).balance);
        payable(owner()).transfer(address(this).balance);
    }

    function setPaytoLevelUp(uint _newPrice) external onlyOwner {
        payTolevelUp = _newPrice;
    }
}

pragma solidity >= 0.5.0 < 0.9.0;
import './KnightFactory.sol';

contract KnightFeeding is KnightFactory {

    modifier onlyOwnerOfKnight(uint _knightID) {
        require(knightToOwner[_knightID] == msg.sender,"Invalid owner of the Knight");
        _;
    }

    function feedAndMultiply(uint _knightID, uint _targetDna) internal onlyOwnerOfKnight(_knightID) {
        // require(knightToOwner[_knightID] == msg.sender);
        Knight storage myknight = listOfKnight[_knightID];
        require(_isReady(myknight));
        _targetDna = _targetDna % dnaModulus;
        uint newDna = (myknight.dna + _targetDna) / 2;
        _createKnight("NoName", newDna);
        _triggerCoolDown(myknight);
    } 

    function _triggerCoolDown(Knight storage _knight) internal {
        _knight.readyTime = uint32(block.timestamp + coolDownTime);
    }
    function _isReady(Knight storage _knight) internal view returns(bool) {
        return _knight.readyTime <= block.timestamp;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >= 0.5.0 <0.9.0;

import './Ownable.sol';

contract KnightFactory is Ownable {
    uint dnaKnight = 16;
    uint dnaModulus = 10 ** dnaKnight;
    uint coolDownTime = 1 days;

    event NewKnight(uint knightID, string name,uint dna);

    struct Knight {
       string  name;
       uint dna;
       uint32 level;
       uint32 readyTime;
       uint16 winCount;
       uint16 lostCount;
       uint8 excitementPoint;
    }
    Knight[] public listOfKnight;

    mapping(uint => address) public knightToOwner;
    mapping(address => uint) public countKnightToOwner;

    function _createKnight(string memory _name, uint _dna) internal {
        listOfKnight.push(Knight(_name, _dna,1, uint32(block.timestamp + coolDownTime), 0, 0, 0));
        uint knightID = listOfKnight.length - 1;
        knightToOwner[knightID] = msg.sender;
        countKnightToOwner[msg.sender]++;
        emit NewKnight(knightID, _name, _dna);
    }

    function _generateRandomDan(string memory _str) private view returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createKnight(string memory _name) public {
        require(countKnightToOwner[msg.sender] == 0, "Create a knight only for the first time");
        uint dnaRand = _generateRandomDan(_name);
        _createKnight(_name, dnaRand);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity >= 0.5.0 < 0.9.0;

import "./Context.sol";

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