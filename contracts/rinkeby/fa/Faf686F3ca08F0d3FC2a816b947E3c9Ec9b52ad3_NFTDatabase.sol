/**
 *Submitted for verification at Etherscan.io on 2022-02-17
*/

// SPDX-License-Identifier: MIT
// File: contracts/NFT Contract/DatabaseContext.sol



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
abstract contract DatabaseContext {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
// File: contracts/NFT Contract/Membership.sol



pragma solidity ^0.8.0;


abstract contract Membership is DatabaseContext {
    address private _owner;
    mapping(address => bool) public moduleMembers;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AddModuleMember(address indexed moduleAddressIsAdded);
    event RemoveModuleMember(address indexed moduleAddressIsRemoved);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyMember() {
        require(moduleMembers[_msgSender()], "Ownable: caller is not the member");
        _;
    }

    function addModuleMember(address newModuleAddress) public virtual onlyOwner {
        moduleMembers[newModuleAddress] = true;
        emit AddModuleMember(newModuleAddress);
    }

    function removeModuleMember(address moduleAddress) public virtual onlyOwner {
        delete moduleMembers[moduleAddress];
        emit RemoveModuleMember(moduleAddress);
    }

    function isMember(address moduleAddress) public view virtual onlyOwner returns (bool){
        return moduleMembers[moduleAddress];
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
// File: contracts/NFT Contract/INFTDatabase.sol


pragma solidity ^0.8.0;

interface INFTDatabase {
    function AddNFT(string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress) external returns (bool);

    function ReOwnerNFT(uint256 _nftId, address _newOwner) external returns (bool);

    function BurnNFT(uint _nftId) external returns (bool);

    function GetNFTsByOwner(address _owner) external view returns (uint[] memory);

    function GetNFTByID(uint _nftID) external view returns (string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress);
}

// File: contracts/NFT Contract/NFTDatabase.sol



pragma solidity ^0.8.0;




contract NFTDatabase is INFTDatabase, Membership {

    mapping(uint => address) private nftToOwner;
    mapping(address => uint256) private ownerNFTCount;

    struct NFT {
        string name;
        uint dna;
        uint32 level;
        uint16 winCount;
        uint16 lossCount;
    }

    NFT[] private nfts;

    event NewNFT(uint nftID, string name, uint dna);

    function AddNFT(string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address ownerAddress) external onlyMember override returns (bool){
        nfts.push(NFT(_name, _dna, _level, _winCount, _lossCount));
        uint newId = nfts.length - 1;
        nftToOwner[newId] = ownerAddress;
        ownerNFTCount[ownerAddress]++;
        NewNFT(newId, _name, _dna);
        return true;
    }


    function ReOwnerNFT(uint256 _nftId, address _newOwner) external onlyMember override returns (bool){
        nftToOwner[_nftId] = _newOwner;
        return true;
    }

    function BurnNFT(uint _nftId) external onlyMember override returns (bool){
        ownerNFTCount[nftToOwner[_nftId]]--;
        nftToOwner[_nftId] = address(0);
        return true;
    }

    function GetNFTsByOwner(address _owner) external onlyMember override view returns (uint[] memory) {
        uint[] memory result = new uint[](ownerNFTCount[_owner]);
        uint counter = 0;
        for (uint i = 0; i < nfts.length; i++) {
            if (nftToOwner[i] == _owner) {
                result[counter] = i;
                counter++;
            }
        }
        return result;
    }

    function GetNFTByID(uint _nftID) external onlyMember override view returns (string memory _name, uint _dna, uint32 _level, uint16 _winCount, uint16 _lossCount, address _ownerAddress){
        require(nftToOwner[_nftID] != address(0), "This NFT does not exist !");
        return (nfts[_nftID].name, nfts[_nftID].dna, nfts[_nftID].level, nfts[_nftID].winCount, nfts[_nftID].lossCount, nftToOwner[_nftID]);
    }

}