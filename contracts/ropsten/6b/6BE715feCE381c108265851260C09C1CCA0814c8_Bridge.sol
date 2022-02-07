/**
 *Submitted for verification at Etherscan.io on 2022-02-07
*/

pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

library SafeMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, 'math_add_over');
    }

    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, 'math_sub_over');
    }
    function sub128(uint x , uint y) internal pure returns (uint128 z){
        return uint128(sub(x , y));
    }

    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, 'math_mul_over');
    }

    function div(uint x, uint y) internal pure returns (uint z){
        require(y > 0, 'math_div_0');
        z = x / y;
    }

    function mod(uint x, uint y) internal pure returns (uint z){
        require(y != 0, 'math_mod_0');
        z = x % y;
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        z = x < y ? x : y;
    }

    function sqrt(uint y) internal pure returns (uint z) {
        if (y > 3) {
            z = y;
            uint x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
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

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}
contract Manager is Ownable {
    
    address[] managers;

    modifier onlyManagers() {
        bool exist = false;
        if(owner == msg.sender) {
            exist = true;
        } else {
            uint index = 0;
            (exist, index) = existManager(msg.sender);
        }
        require(exist);
        _;
    }
    
    function getManagers() public view returns (address[] memory){
        return managers;
    }
    
    function existManager(address _to) private view returns (bool, uint) {
        for (uint i = 0 ; i < managers.length; i++) {
            if (managers[i] == _to) {
                return (true, i);
            }
        }
        return (false, 0);
    }
    function addManager(address _to) onlyOwner public {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        
        require(!exist);
        
        managers.push(_to);
    }
    function deleteManager(address _to) onlyOwner public {
        bool exist = false;
        uint index = 0;
        (exist, index) = existManager(_to);
        
        require(exist);
   
        uint lastElementIndex = managers.length - 1; 
        managers[index] = managers[lastElementIndex];
        managers.pop();
    }

}
contract Bridge is Manager {
    using SafeMath for *;
    uint public immutable startNumber;
    uint public immutable RATE100 = 10 ** 8;
    address public immutable ETH = address(0);
    //1=ETH, 2=BSC
//  0x0000000000000000000000000000000000000000
    struct ChainInfo {
        uint256 chainID;
        uint256 gasFee;
        uint256 gasOutFee;
        uint256 taxFeeRate;
    }

    struct Whitelist {
        uint256 chainID;
        address fromToken;
        string toToken;
    }

    struct AllowedWhiteList {
        address fromToken;
        uint256 allowed;
        uint256 balance;
    }
    event Convert (
        address indexed sender,
        address indexed fromToken,
        uint256 indexed chainID,
        string toToken,
        string recipient,
        uint256 amount,
        uint256 conversionAmount
    );

    event Pay (
        address indexed recipient,
        address indexed token,
        uint256 indexed chainID,
        uint256 amount,
        uint256 txhash
    );

    ChainInfo[] _chainInfo;
    Whitelist[] _whitelist;
    
    mapping(uint256 => bool) public receipt;

    uint256 public convertCount;
    uint256 public cumulativeGasFee;
    mapping(address => uint256) public cumulativeTax;


    constructor(address manager) public{
        startNumber = block.number;
        addManager(manager);
    }
    receive() payable external{}


    function setChainInfo(uint256 chainID,uint256 gasFee, uint256 gasOutFee, uint256 taxFeeRate) public onlyManagers {
        require(chainID > 0);
        require(taxFeeRate < RATE100);

        for(uint i = 0 ; i < _chainInfo.length; i++) {
            if(_chainInfo[i].chainID == chainID) {
                _chainInfo[i].gasFee = gasFee;
                _chainInfo[i].gasOutFee = gasOutFee;
                _chainInfo[i].taxFeeRate = taxFeeRate;
                return;
            }
        }
        _chainInfo.push(ChainInfo({
            chainID: chainID,
            gasFee: gasFee,
            gasOutFee: gasOutFee,
            taxFeeRate: taxFeeRate
        }));
    }
    function removeChainInfo(uint256 chainID) public onlyManagers {
        for(uint i = 0 ; i < _chainInfo.length; i++) {
            if(_chainInfo[i].chainID == chainID) {
                uint256 lastIdx = _chainInfo.length - 1;
                if(i != lastIdx) {
                    _chainInfo[i].chainID = _chainInfo[lastIdx].chainID;
                    _chainInfo[i].gasFee = _chainInfo[lastIdx].gasFee;
                    _chainInfo[i].gasOutFee = _chainInfo[lastIdx].gasOutFee;
                    _chainInfo[i].taxFeeRate = _chainInfo[lastIdx].taxFeeRate;
                }
                _chainInfo.pop();
                return;
            }
        }
        require(false, 'there is nothing to delete.');
    }
    function chainInfo(uint256 chainID) public view returns (ChainInfo memory) {
        for(uint i = 0 ; i < _chainInfo.length; i++) {
            if(_chainInfo[i].chainID == chainID) {
                return _chainInfo[i];
            }
        }
        require(false, 'chain not found.');
    }
    function chainInfos() public view returns (ChainInfo[] memory) {
        return _chainInfo;
    }
    function chainInfoLength() public view returns (uint256) {
        return _chainInfo.length;
    }
   

    function setWhitelist(uint256 chainID,address fromToken,string memory toToken) public onlyManagers {
        for(uint i = 0 ; i < _whitelist.length; i++) {
            if(_whitelist[i].chainID == chainID && _whitelist[i].fromToken == fromToken) {
                _whitelist[i].toToken = toToken;
                return;
            }
        }
        _whitelist.push(Whitelist({
            chainID: chainID,
            fromToken: fromToken,
            toToken: toToken
        }));
    }
    function setWhitelistMulti(uint256 chainID, address[] memory fromTokens, string[] memory toTokens) public onlyManagers {
        require(fromTokens.length == toTokens.length);
        for(uint i = 0 ; i < fromTokens.length; i++) {
            setWhitelist(chainID, fromTokens[i], toTokens[i]);
        }
    }
    function removeWhitelist(uint256 chainID, address fromToken) public onlyManagers {
        for(uint i = 0 ; i < _whitelist.length; i++) {
            if(_whitelist[i].chainID == chainID && _whitelist[i].fromToken == fromToken) {
                uint256 lastIdx = _whitelist.length - 1;
                if(i != lastIdx) {
                    _whitelist[i].chainID = _whitelist[lastIdx].chainID;
                    _whitelist[i].fromToken = _whitelist[lastIdx].fromToken;
                    _whitelist[i].toToken = _whitelist[lastIdx].toToken;
                }
                _whitelist.pop();
                return;
            }
        }
        require(false, 'there is nothing to delete.');
    }
    function removeWhitelistMulti(uint256 chainID, address[] memory fromTokens) public onlyManagers {
        for(uint i = 0 ; i < fromTokens.length; i++) {
            removeWhitelist(chainID, fromTokens[i]);
        }
    }
    function whitelist(uint256 chainID, address fromToken) public view returns (Whitelist memory) {
        for(uint i = 0 ; i < _whitelist.length; i++) {
            if(_whitelist[i].chainID == chainID && _whitelist[i].fromToken == fromToken) {
                return _whitelist[i];
            }
        }
        require(false, 'whitelist not found.');
    }
    function whitelistChain(uint256 chainID) public view returns (Whitelist[] memory) {
        uint256 size = 0;
        for(uint i = 0 ; i < _whitelist.length; i++) {
            if(_whitelist[i].chainID == chainID) {
                size++;
            }
        }
        
        Whitelist[] memory ret = new Whitelist[](size);
        uint256 idx = 0;
        for(uint i = 0 ; i < _whitelist.length; i++) {
            if(_whitelist[i].chainID == chainID) {
                ret[idx].chainID = _whitelist[i].chainID;
                ret[idx].fromToken = _whitelist[i].fromToken;
                ret[idx].toToken = _whitelist[i].toToken;
                idx++;
            }
        }
        return ret;
    }
    function whitelistPage(uint256 startIdx, uint256 endIdx) public view returns (Whitelist[] memory) {
        uint256 maxIdx = endIdx;

        if(endIdx >= _whitelist.length) {
            maxIdx = _whitelist.length - 1;
        }
        
        uint256 size = maxIdx - startIdx + 1;
        Whitelist[] memory ret = new Whitelist[](size);
        uint256 idx = 0;
        for(uint i = startIdx ; i <= maxIdx; i++) {
            ret[idx].chainID = _whitelist[i].chainID;
            ret[idx].fromToken = _whitelist[i].fromToken;
            ret[idx].toToken = _whitelist[i].toToken;
            idx++;
        }
        return ret;
    }
    function whitelistLength() public view returns (uint256) {
        return _whitelist.length;
    }
    function whitelistAll() public view returns (Whitelist[] memory) {
        return _whitelist;
    }


    function gasFee(uint256 chainID) public view returns(uint256) {
        ChainInfo memory targetChainInfo = chainInfo(chainID);
        return targetChainInfo.gasFee;
    }
    function taxFee(uint256 chainID, uint256 amount) public view returns(uint256) {
        require(amount > 0);
        ChainInfo memory targetChainInfo = chainInfo(chainID);
        if(targetChainInfo.taxFeeRate > 0) {
            return amount.mul(targetChainInfo.taxFeeRate).div(RATE100);
        }
        return 0;
    }
  


    function convert(uint256 chainID, address fromToken, string memory recipient, uint256 amount) public payable  {
        require(amount > 0);

        Whitelist memory targetWhiteInfo = whitelist(chainID, fromToken);

        uint256 gas = gasFee(chainID);
        uint256 tax = taxFee(chainID, amount);
        

        if(fromToken == ETH) {
            require(amount.add(gas) == msg.value);
        } else {
            require(gas == msg.value);
            uint256 beforeBridgeBalance = IERC20(fromToken).balanceOf(address(this));
            TransferHelper.safeTransferFrom(fromToken, msg.sender, address(this), amount);
            uint256 afterBridgeBalance = IERC20(fromToken).balanceOf(address(this));
            require(beforeBridgeBalance.add(amount) == afterBridgeBalance);
        }

        
        uint256 conversionAmount = amount.sub(tax);
        
        cumulativeGasFee = cumulativeGasFee.add(gas);
        cumulativeTax[fromToken] = cumulativeTax[fromToken].add(tax);
        convertCount = convertCount.add(1);

        emit Convert(
            msg.sender,
            fromToken,
            chainID,
            targetWhiteInfo.toToken,
            recipient,
            amount,
            conversionAmount
        );
        
    }
    
    function pay(uint256 chainID, address token, address recipient, uint256 amount, uint256 txhash) public onlyManagers {
        require(amount > 0);
        require(!receipt[txhash]);
        
        if(token == ETH) {
            TransferHelper.safeTransferETH(recipient, amount);
        } else {
            TransferHelper.safeTransfer(token, recipient, amount);
        }
        receipt[txhash] = true;

        emit Pay(
            recipient,
            token,
            chainID,
            amount,
            txhash
        );
        
    }

    function withdraw(address token, address to, uint256 amount) public onlyOwner {
        require(amount > 0);

        if(token == ETH) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
  
    }

    function withdrawGasFee(address to, uint256 amount) public onlyOwner {
        require(amount > 0);
        require(cumulativeGasFee >= amount);
        cumulativeGasFee = cumulativeGasFee.sub(amount);
        TransferHelper.safeTransferETH(to, amount);
    }
    function withdrawTax(address token, address to, uint256 amount) public onlyOwner {
        require(amount > 0);
        require(cumulativeTax[token] >= amount);

        cumulativeTax[token] = cumulativeTax[token].sub(amount);

        if(token == ETH) {
            TransferHelper.safeTransferETH(to, amount);
        } else {
            TransferHelper.safeTransfer(token, to, amount);
        }
  
    }

    function allowedBalanceOf(address owner) public view returns(AllowedWhiteList[] memory) {
        AllowedWhiteList[] memory ret = new AllowedWhiteList[](whitelistLength());
        
        for(uint i = 0 ; i < whitelistLength(); i++) {
            if(_whitelist[i].fromToken == ETH) {
                ret[i].fromToken = ETH;
                ret[i].allowed = 100000000000000000000000000000000;
                ret[i].balance = owner.balance; 
            } else {
                ret[i].fromToken = _whitelist[i].fromToken;
                ret[i].allowed = IERC20(_whitelist[i].fromToken).allowance(owner, address(this));
                ret[i].balance = IERC20(_whitelist[i].fromToken).balanceOf(owner);
            }
           
        }

        return ret;

    }


}