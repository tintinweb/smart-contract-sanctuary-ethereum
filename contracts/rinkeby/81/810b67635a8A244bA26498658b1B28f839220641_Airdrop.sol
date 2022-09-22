// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./IERC721.sol";
import "./IERC1155.sol";
import "./Ownable.sol";
import "./MerkleProof.sol";

contract Airdrop is Ownable {

    mapping(address => mapping(address => uint)) public externalAmount;
    mapping(address => uint) public max;
    mapping(address => bytes32) public roots;

    event LaunchAirdrop(address player,bytes32 root,uint max);
    event External(address player,address to,uint total);

    constructor (address owner_){
        _transferOwnership(owner_);
    }
    // 设置用户最大提取多少,以及白名单的root
    function setAirdrop(
      address _airdroper,
      uint _max,
      bytes32 _root
    ) public onlyOwner {
      max[_airdroper] = _max;
      roots[_airdroper] = _root;
      emit LaunchAirdrop(_airdroper,_root,_max);
    }

    function merkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }

    // 判断用户在白名单中 空投者地址 默克尔树proof
    function exitWhite(address _airdroper,bytes32[] memory proof) internal view returns (bool) {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return merkleProof(proof,roots[_airdroper], leaf);
    }
    
    function onERC1155Received(
      address, 
      address, 
      uint256, 
      uint256, 
      bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
      address, 
      address, 
      uint256[] memory, 
      uint256[] memory, 
      bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
      address, 
      address, 
      uint256, 
      bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function _nftSend(
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas,
        address from,
        address to
    ) private {
        for(uint i = 0; i < _nfts.length; i++){
            if(_types[i] == 721){
                IERC721 nft721 = IERC721(_nfts[i]);
                nft721.transferFrom(from,to,_ids[i]);
            }else if(_types[i] == 1155){
                IERC1155 nft1155 = IERC1155(_nfts[i]);
                nft1155.safeTransferFrom(from,to,_ids[i],_amounts[i],_datas[i]);
            }else{
                revert("I won't support it");
            }
        }
    }
    // 所有者 批量提取
    function externalBatch(
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas,
        address to
    ) public onlyOwner {
      _nftSend(_types,_nfts,_ids,_amounts,_datas,address(this),to);
    }

    // 用户提取
    function externalToken(
        uint[] memory _types,
        address[] memory _nfts,
        uint[] memory _ids,
        uint[] memory _amounts,
        bytes[] memory _datas,
        address _airdroper,
        bytes32[] memory proof
    ) public {
        // 检查当前用户是否存在于_airdroper的白名单下
        require(exitWhite(_airdroper,proof),"You are not qualified for airdrop");
        // 计算当前总提取数
        uint sum = 0;
        for(uint i = 0; i < _amounts.length; i++) {
            sum += _amounts[i];
        }
        // 检查当前用户提取数是否大于 空投方设置的提取数
        require(externalAmount[_airdroper][msg.sender] + sum <= max[_airdroper],"> Airdrop Max");
        // 从空投方转移NFT到当前用户地址下
        _nftSend(_types,_nfts,_ids,_amounts,_datas,_airdroper,msg.sender);
        // 记录当前用户的提取数
        externalAmount[_airdroper][msg.sender] += sum;

        emit External(_airdroper,msg.sender,externalAmount[_airdroper][msg.sender]);
    }
}