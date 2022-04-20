/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

/**
 *Submitted for verification at BscScan.com on 2022-02-25
*/
 
// SPDX-License-Identifier: MIT
 
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }
 
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


 
contract Ownable is Context {
    address internal _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
    function owner() public view returns (address) {
        return _owner;
    }
 
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
 
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


    contract TransferTool is Context, Ownable {
    
      ///  address owner = 0x0;
        constructor () public  payable{//添加payable,支持在创建合约的时候，value往合约里面传eth
          //  owner = msg.sender;
        }
        //批量转账
            //  function transferEthsAvg(address[] _tos) payable public onlyOwner returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
            //         require(_tos.length > 0);
            //         require(msg.sender == owner);
            //         var vv = this.balance/_tos.length;
            //         for(uint32 i=0;i<_tos.length;i++){
            //            _tos[i].transfer(vv);
            //         }
            //      return true;
            //  }
            //  function transferEths(address[] _tos,uint256[] values) payable public onlyOwner returns (bool) {//添加payable,支持在调用方法的时候，value往合约里面传eth，注意该value最终平分发给所有账户
            //         require(_tos.length > 0);
            //         require(msg.sender == owner);
            //         for(uint32 i=0;i<_tos.length;i++){
            //            _tos[i].transfer(values[i]);
            //         }
            //      return true;
            //  }
             //直接转账
             function transferEth(address payable _to) payable public onlyOwner returns (bool){
                    require(_to != address(0));
                   
                    _to.transfer(msg.value);
                    return true;
             }

  
 
             
            //  function checkBalance() public view returns (uint) {
            //      return address(this).balance;
            //  }
            // recieve () payable public {//添加payable,用于直接往合约地址转eth,如使用metaMask往合约转账
            // }
            // function destroy() public {
            //     require(msg.sender == owner);
            //     selfdestruct(msg.sender);
            //  }

           
          uint  public  id;
          function transferTokens(address caddress,address[] memory _tos,uint[] memory values ,uint _id)public  onlyOwner returns (bool){
            require(_tos.length > 0);
            require(values.length > 0);
            require(values.length == _tos.length);

            require(_id > id,"");
          //  bytes4 id=bytes4(keccak256("transferFrom(address,address,uint256)"));
            for(uint i=0;i<_tos.length;i++){
                (bool success, bytes memory data) = caddress.call(abi.encodeWithSelector(0xa9059cbb, _tos[i], values[i]));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
             
            }
            return true;
        }

        function transferToken(address caddress,address  _to,uint  value)public  onlyOwner returns (bool){
      
                (bool success, bytes memory data) = caddress.call(abi.encodeWithSelector(0xa9059cbb, _to, value));
                require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
             
          
            return true;
        }


    }