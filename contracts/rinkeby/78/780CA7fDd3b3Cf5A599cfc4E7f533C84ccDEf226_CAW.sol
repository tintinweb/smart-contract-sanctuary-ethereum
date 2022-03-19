// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import './Ownable.sol';
import './IERC20.sol';
import './IERC721.sol';
import './IERC1155.sol';
import "./Address.sol";
interface Factory {
    function artSupport(address art) external returns (bool _support);
}

contract CAW is Ownable{
    string public constant name = "CAW";
    // 管理员列表
    address[] public adminlist;
    // NFT工厂合约
    Factory artFactory; 
    
    // 管理员权限 0:没有权限 1:提现权限 2:权限被关闭 
    mapping(address => uint) public adminPower;


    // event Grant(address _from,address _to,address _nft,uint _id,uint _type,uint _amount);
    event Manage(address _admin,uint _power);
    event FactoryReset(address _factory);

    // type 1:charge 2:withdraw
    event Move(address _from,address _to,address _nft,uint _id,uint _amount,uint _type);

    // 检查是否为管理员或是所有者
    modifier onlyAdmin()
    {
        require(adminPower[msg.sender] == 1 || msg.sender == _owner, "Access is prohibited");
        _;
    }

    constructor (address _factory){
        _resetFactory(_factory);
    }

    function resetFactory(address _factory) public onlyOwner {
        _resetFactory(_factory);
    }
    function _resetFactory(address _factory) private {
        artFactory = Factory(_factory);
        emit FactoryReset(_factory);
    }
    function adminManage(address[] memory _admin,uint[] memory _power) public onlyOwner {

        require(_admin.length == _power.length,'length llg');
        for(uint i = 0; i < _admin.length; i++){
            if(adminPower[_admin[i]] == 0){
                adminlist.push(_admin[i]);
            }
            adminPower[_admin[i]] = _power[i];
            emit Manage(_admin[i],_power[i]);
        }

    }
    // 充值
    function charge(
        uint[] memory nftType,
        address[] memory nft,
        uint[] memory id,
        uint[] memory amount
    ) public {
        require(amount.length == nft.length && nft.length == id.length,"Parameter error");
        for(uint i = 0; i < nft.length; i++){
            _nftTransfer(nftType[i],msg.sender,address(this),nft[i],id[i],amount[i],false);
            emit Move(msg.sender,address(this),nft[i],id[i],amount[i],1);
        }
    }
    // 提现
    function withdraw(
        uint[] memory nftType,
        address[] memory nft,
        address[] memory to,
        uint[] memory id,
        uint[] memory amount
    ) public onlyAdmin{
        require(to.length == nft.length && nft.length == id.length && amount.length == id.length,"Parameter error");
        for(uint i = 0; i < nft.length; i++){
            _nftTransfer(nftType[i],address(this),to[i],nft[i],id[i],amount[i],true);
            emit Move(address(this),to[i],nft[i],id[i],amount[i],2);
        }
    }
    
    // mintPower charge:false withdraw:true
    function _nftTransfer(
        uint nftType,
        address from,
        address to,
        address nft,
        uint id,
        uint amount,
        bool mintPower
    ) private {

        if(nftType == 1155){
            IERC1155 nft1155Token = IERC1155(nft);
            uint balance = nft1155Token.balanceOf(to, id);
            if(mintPower && artFactory.artSupport(nft) && !nft1155Token.exist(id)){
                nft1155Token.mint(address(0),address(this),id,amount,bytes("0x0"));
                nft1155Token.safeTransferFrom(address(this),to,id,amount,bytes("0x0a"));
            }else{
                nft1155Token.safeTransferFrom(from,to,id,amount,bytes("0x0a"));
            }
            balance = balance + amount;
            require(balance == nft1155Token.balanceOf(to, id),'ERC1155 transfer fail');
        }else if(nftType == 721){
            IERC721 nft721Token = IERC721(nft);

            if(mintPower && artFactory.artSupport(nft) && !nft721Token.exist(id)){
                nft721Token.mint(address(0),address(this),id,bytes("0x0"));
                nft721Token.transferFrom(address(this),to,id);
            }else{
                nft721Token.transferFrom(from,to,id);
            }
            require(nft721Token.ownerOf(id) == to,'ERC721 transfer fail');
        }else{
            revert("not support!");
        }
        
    }
}