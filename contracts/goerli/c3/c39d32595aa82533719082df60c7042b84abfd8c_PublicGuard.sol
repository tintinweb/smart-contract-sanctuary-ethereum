// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./Enum.sol";

interface Guard {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

contract PublicGuard is Enum, Guard {

    address constant ETH = address(0);
    address public masterCopy;
    address internal Creater;
    mapping(address => mapping(address => bool)) whitelist; //白名单.
    mapping(address => mapping(address => uint256)) tokenEveryTimeTransferNumberLimit; //(特定类型Token)每笔转账金额限制.
    mapping(address => mapping(address => EveryDayTokenLimit)) tokenEveryDayTransferLimit; //(特定类型Token)每日转账限制.

    constructor(address masterCopy_) {
        masterCopy = masterCopy_;
        Creater = msg.sender;
    }

    modifier OnlyWhallet(address safe) {
        require(msg.sender == safe, "ER001");
        _;
    }
    
    struct EveryDayTokenLimit {
        //设定每天允许的转账次数.
        uint8 frequency;
        //"今日"已经转账次数.
        uint8 implemented;
        //设定媒体允许转账额度.
        uint256 number;
        //"今日"已经转账额度.
        uint256 spend;
        //"本日(周期)开始时间".
        uint256 resetTime;
    }

    //设置白名单成员.
    function setWhitelist(address safe, address[] memory to, bool on) public OnlyWhallet(safe) {
        for(uint i=0; i<to.length; i++) {
            whitelist[safe][to[i]] = on;
        }
    } 

    //设置每笔转账Token限额.
    function setTokenTransferNumberLimit(address safe, address token, uint256 number) public OnlyWhallet(safe) {
        tokenEveryTimeTransferNumberLimit[safe][token] = number;
    }
    //设置Token每天限制转账次数.
    function setEveryDayTransferFrequency(address safe, address token, uint8 frequency) public OnlyWhallet(safe) {
        tokenEveryDayTransferLimit[safe][token].frequency = frequency;
    }
    //设置Token每天限制转账额度.
    function setEveryDayTransferNumber(address safe, address token, uint256 number) public OnlyWhallet(safe) {
        //正常来说, 每天限制转账 = 每天限制转账次数 * 每笔转账限额
        require(number <= tokenEveryDayTransferLimit[safe][token].frequency * tokenEveryTimeTransferNumberLimit[safe][token]);
        tokenEveryDayTransferLimit[safe][token].number = number;
    }
    //更改masterCopy合约.
    function setMasterCopy(address newMasterCopy) public {
        require(msg.sender == Creater);
        masterCopy = newMasterCopy;
    }

    //查询是否为白名单成员.
    function isInWhitelist(address safe, address addr) public view returns(bool) {
        return whitelist[safe][addr];
    }

    //查询Token每笔转账额度限制.
    function getEveryimeTransferNumberLimit(address safe, address token) public view returns(uint256) {
        return tokenEveryTimeTransferNumberLimit[safe][token];
    }
    //查询Token 每日转账次数, 额度限制.
    function getEveryDayTransferLimit(address safe, address token) public view returns(uint8, uint256) {
        return (tokenEveryDayTransferLimit[safe][token].frequency, tokenEveryDayTransferLimit[safe][token].number);
    }
    //查询Token 当前周期(1天)已转账次数, 已使用额度, 本周期开始时间.
    function getDayUseInfo(address safe, address token) public view returns(uint8, uint256, uint256) {
        return (tokenEveryDayTransferLimit[safe][token].implemented, tokenEveryDayTransferLimit[safe][token].spend, tokenEveryDayTransferLimit[safe][token].resetTime);
    }
    //辅助功能.
    function slice(bytes memory _bytes, uint256 _start, uint256 _length) internal pure returns (bytes memory) {
        require(_length + 31 >= _length, "slice_overflow");
        require(_bytes.length >= _start + _length, "slice_outOfBounds");
        
        bytes memory tempBytes;
        assembly {
            switch iszero(_length)
            case 0 {
                tempBytes := mload(0x40)
                let lengthmod := and(_length, 31)
                let mc := add(add(tempBytes, lengthmod), mul(0x20, iszero(lengthmod)))
                let end := add(mc, _length)
                for {
                    let cc := add(add(add(_bytes, lengthmod), mul(0x20, iszero(lengthmod))), _start)
                } lt(mc, end) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    mstore(mc, mload(cc))
                }

                mstore(tempBytes, _length)
                mstore(0x40, and(add(mc, 31), not(31)))
            }
            default {
                tempBytes := mload(0x40)
                mstore(tempBytes, 0)
                mstore(0x40, add(tempBytes, 0x20))
            }
        }
        return tempBytes;
    }

    fallback() external {
        // We don't revert on fallback to avoid issues in case of a Safe upgrade
        // E.g. The expected check method might change and then the Safe would be locked.
    }

    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation,
        uint256,
        uint256,
        uint256,
        address,
        address payable,
        bytes memory,
        address
    ) external override{
        //目标地址是白名单且非黑名单.
        require(whitelist[msg.sender][to] == true || to == address(this) || to == msg.sender || to == masterCopy, "ER002");
        
        bool transfer_;
        uint256 amount_;
        //可能是ERC20转账功能.
        if(data.length > 0) {
            //获取函数选择器.
            bytes4 magic = bytes4(slice(data, 0, 4));
            //确定执行功能为转移ERC20代币.
            if(magic == bytes4(keccak256("transfer(address,uint256)"))) {
                uint256 length = data.length-4;
                bytes memory meta = slice(data, 4, length);
                //获取转移代币数.
                (, amount_) = abi.decode(meta, (address, uint256));
                transfer_ = true;
            } 
        }
        address to_ = to;
        //转移ETH.
        if(value > 0) {
            to_ = ETH;
            amount_ = value;
        }
        //确定涉及到转账(无论是ETH还是ERC20).
        if(value > 0 || transfer_ == true) {
            //转移Token数应小于等于设定的该类型Token每次最多转移数.
            require(amount_ <= tokenEveryTimeTransferNumberLimit[msg.sender][to_], "ER003");
            EveryDayTokenLimit memory limit = tokenEveryDayTransferLimit[msg.sender][to_];
            //更新记录.
            if(limit.resetTime + 1 days > block.timestamp) {
                //1天之内, 加上原有的频率和额度应小于设定值.
                require(limit.implemented +1 <= limit.frequency, "ER004");
                require(limit.spend + amount_ <= limit.number, "ER005");
                tokenEveryDayTransferLimit[msg.sender][to_].implemented += 1;
                tokenEveryDayTransferLimit[msg.sender][to_].spend += amount_;
            } else {
                //1天之外, 此次执行的频率和额度应小于设定值.
                require(0 < limit.frequency, "ER104");
                require(amount_ <= limit.number, "ER105");
                tokenEveryDayTransferLimit[msg.sender][to_].implemented = 1;
                tokenEveryDayTransferLimit[msg.sender][to_].spend = amount_;
                //根据使用情况(时间)动态确保周期设定.
                tokenEveryDayTransferLimit[msg.sender][to_].resetTime = block.timestamp;
            }
        }
    }

    function checkAfterExecution(bytes32, bool) external view override{}
}