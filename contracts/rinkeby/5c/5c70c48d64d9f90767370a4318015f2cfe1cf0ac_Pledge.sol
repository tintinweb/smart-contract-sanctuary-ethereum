// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
import "./PlErc721.sol";
import "./PlErc20.sol";


contract Pledge  {
    uint256 public _amount= 10000*10**18;
    uint8 public Ready=1;
    uint8 public Backed=2;
    uint8 public Finished=3;
    mapping(address=>address) public lpMap;
    mapping(address=>address) public erc20Map;
    mapping(address=>uint256[]) public nftArrMap;
    mapping(address =>mapping(uint256=>Order)) public nftOrderMap;
    mapping(address =>mapping(address=>uint256)) public nextUserOrderIdMap;
    mapping(address=>uint256) public orderMap;
    mapping(address=>uint256) public indexMap;
    mapping(address=>mapping(uint256=>Index)) public indexActMap;
    bytes32 constant public MINT_CALL_HASH_TYPE = keccak256("mint(address receiver,uint256 amount)");
    address private _insureContractAddr; 
    address public cSigner;
    struct Index{
        uint8 actType;
        uint256 lpToken;
        uint256 orderId;
    }
    struct Order {
        uint256 orderBlock;
        uint256 drawNum;
        uint256[] tokenIds;
        address buyer;
        uint8 status;
    }
    constructor() {
        cSigner = msg.sender; 
        _insureContractAddr=msg.sender;
    }
    function initNft(address nftContract_) private{
        PlErc721 nft=PlErc721(nftContract_);
        if(lpMap[nftContract_] == address(0)){
               lpMap[nftContract_]=address(new PlErc721(strConcat(nft.name()," lp"),strConcat(nft.symbol(),"_lp")));
        }
         if(erc20Map[nftContract_] == address(0)){
               erc20Map[nftContract_]=address(new PlErc20(nft.name(),nft.symbol()));
        }
    }
    function pledge(address nftContract_, uint256 tokenId) external{
        require(msg.sender==tx.origin,"Contract invocation is not allowed");
        initNft(nftContract_);
        IERC721(nftContract_).transferFrom(msg.sender, address(this), tokenId);	
        nftArrMap[nftContract_].push(tokenId);
        PlErc20(erc20Map[nftContract_]).mint(msg.sender,_amount);
		uint256 lpId=PlErc721(lpMap[nftContract_]).mint(msg.sender);
        indexMap[nftContract_]++;
        indexActMap[nftContract_][indexMap[nftContract_]]=Index({
            actType:1,
            lpToken:lpId,
            orderId:0
        });
    }
    function getDraw(address nftContract_) public view returns(uint256) {
        uint256 orderId= nextUserOrderIdMap[nftContract_][msg.sender];
        Order storage order=nftOrderMap[nftContract_][orderId];
        if(order.status==Ready){
            (bool IsTimeOut,bytes32 randomHash)=timeOut(order.orderBlock+1);
            if(!IsTimeOut){
                uint256 index = _random(randomHash,0) % nftArrMap[nftContract_].length;
                return nftArrMap[nftContract_][index];
            } 
        }
        return 0;
    }
    function getOrderDrawIds(address nftContract_,uint256 orderId) public view returns(uint256[] memory) {
         Order storage order=nftOrderMap[nftContract_][orderId];
         return order.tokenIds;
    }
	function draw(address nftContract_,uint256 orderId) external{  
        require(msg.sender==tx.origin,"Contract invocation is not allowed");
        Order storage order=nftOrderMap[nftContract_][orderId];
        require(order.status ==Ready && order.buyer==msg.sender," no prizes to draw ");
        require((order.orderBlock+2)<=block.number,"It's not drawing time yet");
        (bool IsTimeOut,bytes32 randomHash)=timeOut(order.orderBlock+1);
        if(!IsTimeOut){
            order.status=Finished;
            for(uint8 i=0;i<order.drawNum;i++){
            uint256 index = _random(randomHash,i) % nftArrMap[nftContract_].length;
            order.tokenIds.push(nftArrMap[nftContract_][index]);
            IERC721(nftContract_).transferFrom(address(this), msg.sender, nftArrMap[nftContract_][index]);
            _remove(nftContract_,index); 
          }
        } else{
            order.status=Backed;
            PlErc20 plErc20=PlErc20(erc20Map[nftContract_]);
            plErc20.platTransferFrom(address(this),msg.sender,500*10**18*order.drawNum);
            plErc20.mint(msg.sender,_amount*order.drawNum);
        }
        insertIndex( nftContract_,4,0,orderId);
    }
    function timeOut(uint256 blockHeight) public view returns(bool,bytes32 randomHash){
        randomHash=blockhash(blockHeight);
        if(block.number-blockHeight>150){
             return (true,randomHash);
        }
        if(randomHash==0x0000000000000000000000000000000000000000000000000000000000000000){
            return (true,randomHash);
        }
        return (false,randomHash);
    }
    function checkDrawStatus(address nftContract_) public view returns(bool,uint256){
      uint256 orderId= nextUserOrderIdMap[nftContract_][msg.sender];
      Order storage order=nftOrderMap[nftContract_][orderId];
      if(order.status ==Ready){
         return (true,orderId);
      }else{
        return (false,orderId);
      }
    }
    function payDrawAndredeem(address nftContract_,uint256 tokenId,uint256 drawNum,uint256 amountV, bytes32 r, bytes32 s) external {
        (bool flag,) =checkDrawStatus( nftContract_);
        require(!flag," There are still prizes to be drawn ");
        require(msg.sender==tx.origin,"Contract invocation is not allowed");
        require(erc20Map[nftContract_] != address(0),"nft not exits pool");
        require(nftArrMap[nftContract_].length>0,"");
        require(PlErc721(lpMap[nftContract_]).ownerOf(tokenId)==msg.sender,"token don't belong to you ");
        require(drawNum>=1,"wrong drawNum !");
        
        uint256 amount = uint248(amountV);
        uint8 v = uint8(amountV >> 248);
        bytes32 digest = keccak256(abi.encode(MINT_CALL_HASH_TYPE, msg.sender, amount));
        require(ecrecover(digest, v, r, s) == cSigner, " Invalid signer");
        PlErc20 plErc20=PlErc20(erc20Map[nftContract_]);
        plErc20.burn(msg.sender,_amount*drawNum);
        plErc20.platTransferFrom(msg.sender,address(this),500*10**18*drawNum);
        uint256 orderId=insertOrder( nftContract_, drawNum);
        PlErc721(lpMap[nftContract_]).burn(tokenId);
        plErc20.platTransferFrom(address(this),msg.sender,amount);
        insertIndex( nftContract_,2,tokenId,orderId);
		
    }
	
    function payDraw(address nftContract_,uint256 drawNum) external {
        (bool flag,)=checkDrawStatus( nftContract_);
        require(!flag," There are still prizes to be drawn ");
        require(erc20Map[nftContract_] != address(0),"nft not exits pool");
        require(nftArrMap[nftContract_].length>0,"");
         PlErc20 plErc20=PlErc20(erc20Map[nftContract_]);
        plErc20.burn(msg.sender,_amount*drawNum);
        plErc20.platTransferFrom(msg.sender,address(this),500*10**18*drawNum);
        uint256 orderId=insertOrder( nftContract_, drawNum);
        insertIndex( nftContract_,3,0,orderId);
    }
    function insertIndex(address nftContract_,uint8 actType,uint256 lpToken,uint256 orderId) private{
            indexMap[nftContract_]++;
            indexActMap[nftContract_][indexMap[nftContract_]]=Index({
            actType:actType,
            lpToken:lpToken,
            orderId:orderId
        });
    }
    function insertOrder(address nftContract_,uint256 drawNum) private returns(uint256){
       
        orderMap[nftContract_]++;
        uint256 nextId=orderMap[nftContract_];
        Order storage order=nftOrderMap[nftContract_][nextId];
        order.orderBlock=block.number;
        order.drawNum=drawNum;
        order.buyer=msg.sender;
        order.status=Ready;
         nextUserOrderIdMap[nftContract_][msg.sender] = orderMap[nftContract_];
         return orderMap[nftContract_];
    }
    function _random(bytes32 seed,uint8 index) internal view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        tx.origin,
                        blockhash(block.number - 1),
                        block.timestamp,
                        seed,
                        index
                    )
                )
            );
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        string memory ret = new string(_ba.length + _bb.length );
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (uint i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
   }  
    function _remove(address nftContract_,uint256 index) internal returns (bool) {
        uint256[] storage _tokens=nftArrMap[nftContract_];
        if ( _tokens.length - 1 != index) {
            uint256 lastToken = _tokens[_tokens.length -1];
            _tokens[_tokens.length -1] = _tokens[index];
            _tokens[index] = lastToken;
        }
        _tokens.pop();
        return true;
    }
    function mint(address contractAddr,address toAddress_,uint256 value_)external {
        require(msg.sender==cSigner);
        PlErc20(contractAddr).mint(toAddress_,value_);
    }
}