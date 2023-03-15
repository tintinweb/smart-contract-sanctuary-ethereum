/**
 *Submitted for verification at Etherscan.io on 2023-03-15
*/

// pragma solidity 0.6.12;
pragma solidity >0.8.0;
contract contractDbg {
        uint256 public number;
        bool public    paused = false;

    function pause() external {
        paused = true;
        emit Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() external {
        paused = false;
        emit Unpause();
    }

    /**
     * @dev Store value in variable
     * @param num value to store
     */
    function store(uint256 num) public {
        number = num;
    }

    /**
     * @dev Return value 
     * @return value of 'number'
     */
    function retrieve() public view returns (uint256){
        return number;
    }

    event Pause();
    event Unpause();
    event FunctionCalldata(bytes);
    event helloMsg(string, uint256);
    
    function testCallData(bytes20 fiatContract) public {
    
        bytes memory functionCalldata = abi.encodeWithSignature("mint(address,uint256)", 0x99CF4c4CAE3bA61754Abd22A8de7e8c7ba3C196d, 100);
        emit FunctionCalldata(functionCalldata);
        address(fiatContract).call(functionCalldata);
    }

/**
* 这个方法竟然不能直接通过calldata调用，很烦。
*/
    function sayHello(uint256 num) public returns(uint result){
        emit helloMsg("abcdefg", num+1);
        result = num + 1;
    }

    function sayHello1() public returns(uint result){
        uint256 num = 2;
        emit helloMsg("abcdefg", num+1);
        result = num + 1;
    }
}