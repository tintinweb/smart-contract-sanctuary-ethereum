/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

//SPDX-License-Identifier: UNLICENSED 
pragma solidity ^0.8.0;

// Abstract contract for the full ERC 20 Token standard
interface   ERC20 {
    
    function balanceOf(address _address) external view returns (uint256 balance);
    
    function transfer(address _to, uint256 _value) external returns (bool success);
    
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    
    function approve(address _spender, uint256 _value) external returns (bool success);
    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


contract TransferTool {
    address public owner;
      // 交易
    bytes4 private constant TRANSFER = bytes4(
        keccak256(bytes("transfer(address,uint256)"))
    );
    // 授权交易
    bytes4 private constant TRANSFERFROM = bytes4(
        keccak256(bytes("transferFrom(address,address,uint256)"))
    );

    constructor(){
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }
  
    /**
     * @dev See {设置新的管理员}.
     */
    function setOwner(address _owner) public onlyOwner   {
        require(_owner != address(0), "zero address");
        owner = _owner;
    }

    /**
     * @dev See {直接向多个地址转账eth,平分所有金额}.
     */
    function transferEthAvg(address[] memory _tos) payable public   { 
        require(_tos.length > 0);
        uint256 vv = msg.value /_tos.length;
        for(uint32 i=0;i<_tos.length;i++){
           payable( _tos[i]).transfer(vv);
        }
    }
    /**
     * @dev See {直接向多个地址转账eth,指定金额}.
     */
    function transferEths(address[] memory _tos,uint256[] memory _values) payable public  onlyOwner {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
        require(_tos.length > 0,"_address");
        for(uint32 i=0;i<_tos.length;i++){
            payable(_tos[i]).transfer(_values[i]);
        } 
    }
 
    //
    /**
     * @dev See {直接向地址转账eth}.
     */
    function transferEth(address _to) payable public onlyOwner {
        require(_to != address(0),"address");
        payable(_to).transfer(msg.value);
    }

    function checkBalance() public view returns (uint) {
        return address(this).balance;
    }
    
 
    /**
     * @dev See {回收 eth平台币}.
     */
    function withdraw() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }
    
    /**
     * @dev See {回收ERC20代币}.
     */
    function withdrawErc20(ERC20 _erc20Address) public onlyOwner returns (bool  ) {
        uint256 _value = _erc20Address.balanceOf(address(this));
        (bool success, ) = address(_erc20Address).call(
            abi.encodeWithSelector(TRANSFER, msg.sender, _value)
        );
        if(!success) {
            revert("transfer fail");
        }
        return true;
    }

    /**
     * @dev See {从调用地址转移erc20代码,想同的values}.
     */
    function transferTokens(address _tokenAddress,address[] memory _tos,uint _v)public returns (bool){
        require(_tos.length > 0);
       // bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
        for(uint i=0;i<_tos.length;i++){
            //caddress.call(id,from,_tos[i],v);
             (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, _tos[i], _v)
            );
            if(!success) {
                revert("transfer fail");
            }
        }
        return true;
    }


    /**
     * @dev See {从调用地址转移erc20代码,不同的values}.
     */
    function transferTokensDifferent(address _tokenAddress,address[] memory _tos,uint[] memory _values)public returns (bool){
        require(_tos.length > 0);
        require(_values.length == _tos.length); 

        for(uint i=0;i<_tos.length;i++){ 
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFERFROM, msg.sender, _tos[i], _values[i])
            );
            if(!success) {
                revert("transfer fail");
            }
        }
        return true;
    }

 
    /**
     * @dev See {从当前合约地址转移erc20代码,不同的values}.
     */
    function transferTokensFromSelfDifferent(address _tokenAddress, address[] memory _tos, uint256[] memory _value) public onlyOwner returns (bool success2) {
        require(_tos.length > 0);
        require(_tos.length == _value.length, "length Unlike");
        for(uint256 i = 0; i < _tos.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFER, _tos[i], _value[i])
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
    /**
     * @dev See {从当前合约地址转移erc20代码,相同的values}.
     */
    function transferTokensFromSelf(address _tokenAddress, address[] memory _tos, uint256  _value) public onlyOwner returns (bool success2) {
        require(_tos.length > 0); 
        for(uint256 i = 0; i < _tos.length; i++) {
            (bool success, ) = _tokenAddress.call(
                abi.encodeWithSelector(TRANSFER, _tos[i], _value)
            );
            if(!success) {
                revert("transfer fail");
                
            }
        }
        success2 = true;
    }
}