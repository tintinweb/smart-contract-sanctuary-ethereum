/**
 *Submitted for verification at Etherscan.io on 2022-08-19
*/

pragma solidity >=0.6.6;
pragma experimental ABIEncoderV2;



interface IERC20 {
    function balanceOf(address owner) external view returns (uint);
}


interface oracle{

    function submitValue(
        bytes32 _queryId,
        bytes calldata _value,
        uint256 _nonce,
        bytes memory _queryData
    ) external;  


    function getTimeOfLastNewValue() external view returns (uint256);

    function depositStake() external;

}


contract tellorsubmit {
    
    address payable public owner;
    

    constructor() public {
        owner = payable(msg.sender);

    }
    
    
    modifier onlyowner{
        require(msg.sender == owner);
        _;
    }



    receive() external payable {}


    function deposit() payable external{
    }


    function _safeTransfer(address token, address to, uint value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(bytes4(keccak256(bytes('transfer(address,uint256)'))), to, value));
    }
    
    function withdrawtoken(address tokenaddr, uint amount) external onlyowner{
        _safeTransfer(tokenaddr, owner, amount);
    }


    function withdrawethall() external onlyowner {
        payable(msg.sender).transfer(address(this).balance);
    }
    

    function depositStake() external onlyowner{
        oracle(address(0x88dF592F8eb5D7Bd38bFeF7dEb0fBc02cf3778a0)).depositStake();
    }

    function submitoraclevalue(uint256 lastvalue, bytes32 _queryId, bytes calldata _value, uint256 _nonce, bytes memory _queryData) external payable onlyowner{

       uint256 timeOfLastNewValue = oracle(address(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)).getTimeOfLastNewValue();

       require(timeOfLastNewValue == lastvalue, "fuck");

       oracle(address(0xe8218cACb0a5421BC6409e498d9f8CC8869945ea)).submitValue(_queryId, _value, _nonce, _queryData);

    }


}