/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

pragma solidity 0.7.6;

library TransferHelper {

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function burn(uint256 amt) external returns (bool);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

contract DistributionETHToken{
    // using SafeMath for uint256;
    address public administrator;
    address public USDTToken;
    address public USDCToken;
    
    constructor() public {
        administrator = msg.sender;
    }   

    function setAdministrator(address _administrator) public{
        require(msg.sender==administrator, "forbident");
        administrator = _administrator;
    }

    function setUSDTToken(address _USDT) public{
        require(msg.sender==administrator, "forbident");
        USDTToken = _USDT;
    }

    function setUSDCToken(address _USDC) public{
        require(msg.sender==administrator, "forbident");
        USDCToken = _USDC;
    }
    
    function paybackToken(address _token) public{
        require(msg.sender==administrator, "forbident");
        if( IERC20(_token).balanceOf(address(this))>0 ){
            TransferHelper.safeTransfer(_token, administrator, IERC20(_token).balanceOf(address(this)));
        }
    }    

    function paybackETH() public payable{
        require(msg.sender==administrator, "forbident");
        msg.sender.transfer(address(this).balance);
    }    
    
    function getETHbalance() external view returns(uint balance){
        balance = address(this).balance;
    }

    function getTokenBalance(address _token) external view returns(uint balance){
        balance = IERC20(_token).balanceOf(address(this));
    }    

    address public T_msg_sender;
    address public T_tx_origin;
    uint8 public T_flag;
    address public T_administrator;
    function T_set_Msg_seder(uint8 _flag)public{
        T_msg_sender = msg.sender;
        T_tx_origin = tx.origin;
        T_flag = _flag;
        T_administrator = administrator;
    }
    
    function distributeETH(address[] memory _addrList, uint _amt) public payable{
        require(tx.origin==administrator, "forbident");
        address payable sendTo;
        for(uint16 i; i<_addrList.length; i++){
            sendTo = address(uint160(_addrList[i]));
            sendTo.transfer(_amt);
        }
    }

    function distributeUSDT(address[] memory _addrList, uint _amt) public{
        require(msg.sender==administrator, "forbident");
        require(IERC20(USDTToken).balanceOf(address(this))>(_addrList.length*_amt), "insufficient");
        for(uint16 i; i<_addrList.length; i++){
            TransferHelper.safeTransfer(USDTToken, _addrList[i], _amt);
        }
    }    
    
    function distributeUSDC(address[] memory _addrList, uint _amt) public{
        require(msg.sender==administrator, "forbident");
        require(IERC20(USDCToken).balanceOf(address(this))>(_addrList.length*_amt), "insufficient");
        for(uint16 i; i<_addrList.length; i++){
            TransferHelper.safeTransfer(USDCToken, _addrList[i], _amt);
        }
    }    
}