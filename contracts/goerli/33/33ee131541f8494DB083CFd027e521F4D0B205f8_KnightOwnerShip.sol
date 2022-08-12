//SPDX-License-Identifier: MIT
pragma solidity >=0.5.0 < 0.9.0;

import './KnightAttack.sol';
import './IERC721.sol';

//complite code with v0.8.12  -> version support concat string
contract KnightOwnerShip is KnightAttack, IERC721{

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

    function _burn(uint256 _knightID) internal virtual {
        address owner = KnightOwnerShip.ownerOf(_knightID);
        // Clear approvals
        _approve(address(0), _knightID);
        countKnightToOwner[owner] -= 1;
        delete knightToOwner[_knightID];
        if (bytes(_tokenURIs[_knightID]).length != 0) {
            delete _tokenURIs[_knightID];
        }
        emit Transfer(owner, address(0), _knightID);
    }

}

pragma solidity >=0.5.0 <0.9.0;

import './KnightHelper.sol';

contract KnightAttack is KnightHelper {

    uint victoryProbability = 70;

    event battleResults(bool,uint _luckyNumber, uint _victoryNumber);

    function attack(uint _attackknightID, uint _defenseKnightID) external  onlyOwnerOfKnight(_attackknightID) returns(bool) {
        Knight storage myKnight = listOfKnight[_attackknightID];
        require(_isReady(myKnight),"Knight can't fight yet");
        require(msg.sender != knightToOwner[_defenseKnightID],"You can't attack your knight, you're a traitor blabla... Knight said :) ");
        Knight storage enemyKnight = listOfKnight[_defenseKnightID];
        uint luckyNumber = randMod(100);
        // luckyNumber nhỏ hơn xác xuất chiến thắng cộng với điểm phấn khích của hiệp sĩ
        // VD: điểm may mắn random là 30 , điểm xác suất chiến thắng là 50  + điểm phân khích cảu hiệp sĩ tối đa là 20 = 70 
        //  30 < 70 nên  _attackknightID  sẽ thắng
        if(myKnight.winCount == 0) 
        {
            unchecked {
                myKnight.winCount++;
                myKnight.level++;
                enemyKnight.lostCount++;
            }
            feedAndMultiply(_attackknightID, enemyKnight.dna);
            return true;
        } else if(luckyNumber <= victoryProbability + myKnight.excitementPoint) {
            unchecked {
                myKnight.winCount++;
                myKnight.level++;
                enemyKnight.lostCount++;
            }
            feedAndMultiply(_attackknightID, enemyKnight.dna);
            emit battleResults(true,luckyNumber, uint(victoryProbability + myKnight.excitementPoint));
            return true;
        } else {
            unchecked {
                enemyKnight.winCount++;
                myKnight.lostCount++;
            }
            _triggerCoolDown(myKnight);
            emit battleResults(false,luckyNumber, uint(victoryProbability + myKnight.excitementPoint));
            return false;
        }
        
    }
}

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

    mapping(uint => mapping(uint => bool)) public registerMarry;
    mapping(uint => bool) public knightMarried;
    mapping(address => mapping(address => uint)) public amountGift;

    event RequestMarry(uint _knightFatherID, uint _knightMotherID, address _from, address _to, uint amountGift);
    event ApprovalMarry(uint _knightFatherID, uint _knightMotherID, bool _resoult);
    
    modifier aboveLevel(uint _level, uint _knightID) {
        // require(listOfKnight[_knightID].level >= _level, string.concat("Knight can't use this skill yet, Upgrade the knight to level ",Strings.toString(_level)));
        require(listOfKnight[_knightID].level >= _level, string(abi.encodePacked("Knight can't use this skill yet, Upgrade the knight to level ", Strings.toString(_level))));
        _;
    }
    
    modifier acceptedMarry(uint _knightFatherID, uint _knightMotherID) {
        require(registerMarry[_knightFatherID][_knightMotherID], "Invalid marriage consent");
        _;
    }

    receive() external payable {}

    fallback() external payable {}

    function approveMarry(uint _knightFatherID, uint _knightMotherID, bool _resoult) external onlyOwnerOfKnight(_knightMotherID) {

        if(_resoult) {
            registerMarry[_knightFatherID][_knightMotherID] = true;
            registerMarry[_knightMotherID][_knightFatherID] = true;
            knightMarried[_knightFatherID] = true;
            knightMarried[_knightMotherID] = true;
            address ownerKnightFather = knightToOwner[_knightFatherID];
            address ownerKnightMother = knightToOwner[_knightMotherID];
            payable(ownerKnightMother).transfer(amountGift[ownerKnightFather][ownerKnightMother]);
            delete amountGift[ownerKnightFather][ownerKnightMother];
        } else {
            _destroyMarry(_knightFatherID, _knightMotherID, true);
        }
        emit ApprovalMarry(_knightFatherID, _knightMotherID, _resoult);
    }

    function destroyMarry(uint _knightFatherID, uint _knightMotherID) external  {
        require(knightToOwner[_knightFatherID] == msg.sender || knightToOwner[_knightMotherID] == msg.sender,"Invalid owner of knight");
        _destroyMarry(_knightFatherID, _knightMotherID, false);
    }

    function _destroyMarry(uint _knightFatherID, uint _knightMotherID, bool _repay) internal  {
        address ownerKnightFather = knightToOwner[_knightFatherID];
        address ownerKnightMother = knightToOwner[_knightMotherID];

        delete registerMarry[_knightFatherID][_knightMotherID];
        delete registerMarry[_knightMotherID][_knightFatherID];    
        delete knightMarried[_knightFatherID];
        delete knightMarried[_knightMotherID];  

        if (_repay) {
            payable(ownerKnightFather).transfer(amountGift[ownerKnightFather][ownerKnightMother]);
        }
    }

    function requestMarry(uint _knightFatherID, uint _knightMotherID) external payable onlyOwnerOfKnight(_knightFatherID) {
        require(!knightMarried[_knightFatherID] && !knightMarried[_knightMotherID], "Knight is married!");
        registerMarry[_knightFatherID][_knightMotherID] = false;
        address from = knightToOwner[_knightFatherID];
        address to = knightToOwner[_knightMotherID];
        amountGift[from][to] = msg.value;
        emit RequestMarry(_knightFatherID, _knightMotherID, from, to,  msg.value);
    }

    function changeName(uint _knightID, string calldata _newnName) external aboveLevel(2, _knightID) onlyOwnerOfKnight(_knightID) {
        listOfKnight[_knightID].name = _newnName;
    }

    function changeDna(uint _knightID, uint _newDna) external aboveLevel(20, _knightID) onlyOwnerOfKnight(_knightID) {
        listOfKnight[_knightID].dna = _newDna;
    }
    
    // function interCourseKnight(uint _knightFatherID, uint _knightMotherID) 
    //     external 
    //     aboveLevel(20, _knightFatherID) 
    //     aboveLevel(18, _knightMotherID) 
    //     acceptedMarry(_knightFatherID, _knightMotherID) 
    // {
    //     Knight storage myKnight = listOfKnight[_knightFatherID];
    //     Knight storage loverKnight = listOfKnight[_knightMotherID];
    //     require(_isReadySex(myKnight) && _isReadySex(loverKnight) ,"Knight can't fight yet");
    //     _reproductionKnight(_knightFatherID, _knightMotherID);
    // }
    function interCourseKnight(uint _knightFatherID, uint _knightMotherID) 
        external 
        acceptedMarry(_knightFatherID, _knightMotherID) 
    {
        Knight storage myKnight = listOfKnight[_knightFatherID];
        Knight storage loverKnight = listOfKnight[_knightMotherID];
        require(_isReadySex(myKnight) && _isReadySex(loverKnight) ,"Knight can't fight yet");
        _reproductionKnight(_knightFatherID, _knightMotherID);
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
        listOfKnight[_knightID].level++;
    }

    function knightGoMassage(uint _knightID) external payable {
        require(msg.value == payTolevelUp);
        Knight storage myKnight =  listOfKnight[_knightID];
        require(myKnight.excitementPoint < 20,"Knight has maxed out excitement points");
        myKnight.excitementPoint += 2;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setPaytoLevelUp(uint _newPrice) external onlyOwner {
        payTolevelUp = _newPrice;
    }

    function _isReadySex(Knight storage _knight) internal view returns(bool) {
        return _knight.sexTime <= block.timestamp;
    }

    function _reproductionKnight(uint _knightFatherID, uint _knightMotherID) internal {
        Knight storage knightFather = listOfKnight[ _knightFatherID];
        Knight storage knightMother = listOfKnight[ _knightMotherID];

        uint uniqueDna = randMod(dnaModulus);
        uint newDna = (knightFather.dna + knightMother.dna + uniqueDna) / 3;
        uint randGender = randMod(1);
        uint randWhoParent = randMod(100);
        uint32 avgLevel = _floorLevel(knightFather.level, knightMother.level);

        if(randWhoParent <= 50) 
        {
            _createKnight("BabyKnight", newDna, uint8(randGender), avgLevel, knightToOwner[_knightFatherID]);
        } else  {
            _createKnight("BabyKnight", newDna, uint8(randGender), avgLevel, knightToOwner[_knightMotherID]);
        }

        _triggerTired(knightFather);
        _triggerTired(knightMother);
    }
    function _triggerTired(Knight storage _knight) internal {
        _knight.sexTime = uint32(block.timestamp + coolDownSex);
    }

    function _floorLevel(uint32 _levelFather, uint32 _levelMother) internal pure returns (uint32) {
        return uint32(_levelFather + _levelMother) / 4;
    }
}

pragma solidity >= 0.5.0 < 0.9.0;

import './KnightFactory.sol';

contract KnightFeeding is KnightFactory {

    modifier onlyOwnerOfKnight(uint _knightID) {
        require(knightToOwner[_knightID] == msg.sender,"Invalid owner of the Knight");
        _;
    }

    function randMod(uint _modulus) internal returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp,msg.sender,randNonce))) % _modulus;
    }

    function feedAndMultiply(uint _knightID, uint _targetDna) internal onlyOwnerOfKnight(_knightID) {
        // require(knightToOwner[_knightID] == msg.sender);
        Knight storage myknight = listOfKnight[_knightID];
        require(_isReady(myknight));
        _targetDna = _targetDna % dnaModulus;
        uint uniqueDna = randMod(dnaModulus);
        uint newDna = (myknight.dna + _targetDna + uniqueDna) / 3;
        uint randGender = randMod(1);
        _createKnight("NoName", newDna, uint8(randGender), 1, msg.sender);
        _triggerCoolDown(myknight);
    } 

    function _triggerCoolDown(Knight storage _knight) internal {
        _knight.readyTime = uint32(block.timestamp + coolDownTime);
    }
    function _isReady(Knight storage _knight) internal view returns(bool) {
        return _knight.readyTime <= block.timestamp;
    }
}

pragma solidity >= 0.5.0 <0.9.0;

import './Ownable.sol';
import "./Strings.sol";
contract KnightFactory is Ownable {
    using Strings for uint256;
    string baseURIKnight = "ipfs://QmUKzLnChwZBD1SJfxL98qCLEpCEA8n98uWhXCc4eJtxh2/";
    uint dnaKnight = 16;
    uint dnaModulus = 10 ** dnaKnight;
    uint coolDownTime = 1 minutes;
    uint randNonce = 0;
    uint coolDownSex = 1 minutes;
    uint public amountOfpage = 20;
    event NewKnight(uint knightID, string name,uint dna);

    struct Knight {
       string  name;
       uint dna;
       uint32 level;
       uint32 readyTime;
       uint32 sexTime;
       uint16 winCount;
       uint16 lostCount;
       uint8 excitementPoint;
       uint8 gender;
    }
    Knight[] public listOfKnight;

    mapping(uint256 => string) internal _tokenURIs;
    mapping(uint => address) public knightToOwner;
    mapping(address => uint) public countKnightToOwner;

    function _createKnight(string memory _name, uint _dna, uint8 _gender, uint32 _level, address _owner) internal {
        listOfKnight.push(Knight(_name, _dna, _level, uint32(block.timestamp + coolDownTime), uint32(block.timestamp + coolDownSex), 0, 0, 0, _gender));
        uint knightID = listOfKnight.length - 1;
        knightToOwner[knightID] = _owner;
        countKnightToOwner[_owner]++;
        uint randUri = randTokenUri(amountOfpage, knightID);
        _setTokenURI(knightID, randUri);
        emit NewKnight(knightID, _name, _dna);
    }

    function _generateRandomDan(string memory _str) private view returns(uint) {
        uint rand = uint(keccak256(abi.encodePacked(_str)));
        return rand % dnaModulus;
    }

    function createKnight(string memory _name, uint8 _gender) public {
        require(countKnightToOwner[msg.sender] == 0, "Create a knight only for the first time");
        uint dnaRand = _generateRandomDan(_name);
        _createKnight(_name, dnaRand, _gender, 1, msg.sender);
    }
    // ERC721URIStorage
    function setAmountOfPage(uint _newNumber) public onlyOwner {
        amountOfpage = _newNumber;
    }
     function randTokenUri(uint _modulus, uint knightID) internal  returns(uint) {
        randNonce++;
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, knightID, randNonce))) % _modulus;
    }

    function tokenURI(uint256 _knightID) public view virtual returns (string memory) {
        _requireMinted(_knightID);
        string memory _tokenURI = _tokenURIs[_knightID];
        string memory base = _baseURI();
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        } else {
            return "";
        }
    }

    function setBaseUri(string memory _newURI) external onlyOwner {
        baseURIKnight = _newURI;
    }

    function _baseURI() internal view virtual returns (string memory) {
        return  "";
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return knightToOwner[tokenId] != address(0);
    }

    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }
    
    function _setTokenURI(uint256 _knightID, uint  _randTokenUri) internal virtual {
        // _tokenURIs[_knightID] = string.concat(baseURIKnight, Strings.toString(_randTokenUri), ".json");
        _tokenURIs[_knightID] = string(abi.encodePacked(baseURIKnight, Strings.toString(_randTokenUri), ".json"));
    }
}

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

pragma solidity <0.9.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

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