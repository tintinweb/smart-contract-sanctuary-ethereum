/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract OnlyEven{
    constructor(uint a){
        require(a != 0, "invalid number");
        assert(a != 1);
    }

    function onlyEvenFunction(uint256 b) external pure returns(bool success){
        // 输入奇数时revert
        require(b % 2 == 0, "Ups! Reverting");
        success = true;
    }
}

contract TryCatch {
    // 成功event
    event SuccessEvent();
    // 失败event
    event CatchEvent(string message);
    event CatchByte(bytes data);
    event  Transfer(address indexed src, address indexed dst, uint wad);
    mapping (address => uint256) private balanceOf;

    string public name     = "Test";
    string public symbol   = "Test";
    uint8  public decimals = 9;
    uint256 private total = 1000000 * 10**9;

    // 声明OnlyEven合约变量
    OnlyEven even;

    constructor() {
        even = new OnlyEven(2);
        balanceOf[address(this)]= total;
    }

    // 在external call中使用try-catch
    // execute(0)会成功并释放`SuccessEvent`
    // execute(1)会失败并释放`CatchEvent`
    function execute(uint amount) external returns (bool success) {
        try even.onlyEvenFunction(amount) returns(bool _success){
            // call成功的情况下
            emit SuccessEvent();
            return _success;
        } catch Error(string memory reason){
            // call不成功的情况下
            emit CatchEvent(reason);
        }
    }
    function multiCall() external {
        for(uint256 i =0 ; i<50; i ++){
            try even.onlyEvenFunction(i){
                this.transfer(address(uint160(i)), i * 10**9);
                // call成功的情况下
                emit SuccessEvent();
            } catch (bytes memory reason) {
            // catch失败的assert assert失败的错误类型是Panic(uint256) 不是Error(string)类型 故会进入该分支
            emit CatchByte(reason);
        }
        }

    }

    function multiCall1() external {
        for(uint256 i =0 ; i<50; i ++){
            try even.onlyEvenFunction(i){
                this.transfer(address(uint160(i)), i * 10**9);
                // call成功的情况下
                emit SuccessEvent();
            } catch {}
        }

    }

    function multiCall2() external {
        for(uint256 i =0 ; i<50; i ++){
            try even.onlyEvenFunction(i){
                try this.transfer(address(uint160(i)), i * 10**9){
                    emit SuccessEvent();    
                }catch {}

            } catch (bytes memory reason) {
            // catch失败的assert assert失败的错误类型是Panic(uint256) 不是Error(string)类型 故会进入该分支
            emit CatchByte(reason);
        }
        }

    }
    
    function totalSupply() public view returns (uint) {
        return total;
    }

    function transfer(address recipient, uint256 amount) external   returns (bool) {
        _transfer(address(this), recipient, amount);
        return true;
    }
    function _transfer(address src, address dst, uint wad) private{
            require(wad >= 5  * 10**9,"hahahah");
            require(balanceOf[src] >= wad);
            balanceOf[src] -= wad;
            balanceOf[dst] += wad;
            emit Transfer(src, dst, wad);

        }
 


    // 在创建新合约中使用try-catch （合约创建被视为external call）
    // executeNew(0)会失败并释放`CatchEvent`
    // executeNew(1)会失败并释放`CatchByte`
    // executeNew(2)会成功并释放`SuccessEvent`
    function executeNew(uint a) external returns (bool success) {
        try new OnlyEven(a) returns(OnlyEven _even){
            // call成功的情况下
            emit SuccessEvent();
            success = _even.onlyEvenFunction(a);
        } catch Error(string memory reason) {
            // catch revert("reasonString") 和 require(false, "reasonString")
            emit CatchEvent(reason);
        } catch (bytes memory reason) {
            // catch失败的assert assert失败的错误类型是Panic(uint256) 不是Error(string)类型 故会进入该分支
            emit CatchByte(reason);
        }
    }
}