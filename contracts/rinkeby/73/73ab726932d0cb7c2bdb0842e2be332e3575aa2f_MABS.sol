pragma solidity >0.6.0 <0.9.0;

import "./ku_MABS.sol";
import "./IERC20_MABS.sol";
import "./IBOX_MABS.sol";
contract MABS is IERC20,IboxMABS {
    using SafeMath for uint256;
    string public name;           //返回string类型的ERC20代币的名字
    string public symbol;         //返回string类型的ERC20代币的符号，也就是代币的简称，例如：SNT。
    uint8 public  decimals;       //支持几位小数点后几位。如果设置为3。也就是支持0.001表示
    uint public override totalSupply;  //总数
    //mapping(address =>uint256) public balanceOfi;
    mapping(address =>mapping(address => uint256)) internal appa;
    constructor()public {
        name = "Marbles";
        symbol = "MABSt";
        decimals = 18;
        totalSupply = 100000000 * manjingdu;
        wMABS = totalSupply * 2 / 10;
        boxmabs =  totalSupply / 10;
        KTmabs = totalSupply / 10;
        balanceOfi[msg.sender] = totalSupply - wMABS - boxmabs - KTmabs;
        WMABS = 0x5699b0858EaffFe4b911a27C9A38D5efc33Be8C6;
        MABS = 0xBfdE8C297e1A2F15bDFBc7508dc798B508754600;
        kMABS= 0x360c3Ea4a78Fb155963510e661b5F78ac026eCd2;
        balanceOfi[WMABS] = wMABS;
        balanceOfi[MABS] = boxmabs;
        balanceOfi[kMABS] = KTmabs;
        xzy = msg.sender;
    }
    function totalSupply1() external view returns (uint256){
        return totalSupply;
    }
    function balanceOf(address account) external override view returns (uint256){
        return balanceOfi[account];
    }
    function transfer(address to, uint256 amount) external  override returns (bool){
        require(to != address(0)); //地址不能为空
        require(balanceOfi[msg.sender] >= amount); //转账用户余额必须大于转账数
        require(balanceOfi[to]+amount >= balanceOfi[to]); //检查是否溢出

        balanceOfi[msg.sender] = balanceOfi[msg.sender].sub(amount); //发送者减去数额
        balanceOfi[to] = balanceOfi[to].add(amount); //接收者增加数额
        emit Transfer(msg.sender, to, amount);

        return true;
    }

    function allowance(address owner, address spender) external override view returns (uint256) {
        return appa[owner][spender];//查看剩余能调用多少代币
    }

    function approve(address spender, uint256 amount) external override returns (bool){
        appa[msg.sender][spender] = amount; //映射可操作的代币，由调用者（msg.sender）指定_spender操作_value数额
        emit Approval(msg.sender,spender,amount); //触发事件
         return true; //返回为真
    }

    function transferFrom(address from,address to,uint256 amount) external override returns (bool){
        require(to != address(0)); //地址不能为空
        require(balanceOfi[from] >= amount); //转账用户余额必须大于转账数
        require(appa[from][msg.sender] >= amount); //检查委托人的可操作的金额是否大于转账金额
        require(balanceOfi[to]+amount >= balanceOfi[to]); //检查是否溢出

        balanceOfi[from] = balanceOfi[from].sub(amount);//发送者减去数额
        balanceOfi[to] = balanceOfi[to].add(amount);//接收者增加数额
        emit Transfer(from, to, amount);
        return true; //返回为真
    }
    //合约提现
    function wit1(uint am) public  {
        payable(msg.sender).transfer(am);
        // emit b(am,address(this).balance);//触发事件
    }
    //转入合约中
    function depos() public payable {
    //    emit a(msg.sender,msg.value ,address(this).balance); //触发事件
    }
    function _kMABS(address wo)external returns(bool) {
        require(kt == true);
        if(kmabs[wo]== false && cmabs <= 500) {
            uint k = balanceOfi[kMABS].mul(5).div(10000);
            balanceOfi[kMABS] = balanceOfi[kMABS].sub(k);
            balanceOfi[wo] = balanceOfi[wo].add(k);
            cmabs++;
            kmabs[wo] = true;
            emit Transfer(kMABS, wo, k);
            return true;
        }
        if(kmabs[wo]== false && cmabs <= 1000) {
            uint k = balanceOfi[kMABS].mul(3).div(10000);
            balanceOfi[kMABS] = balanceOfi[kMABS].sub(k);
            balanceOfi[wo] = balanceOfi[wo].add(k);
            cmabs++;
            kmabs[wo] = true;
            emit Transfer(kMABS, wo, k);
            return true;
        } 
        if(kmabs[wo]== false) {
            uint k = balanceOfi[kMABS].div(10000);
            balanceOfi[kMABS] = balanceOfi[kMABS].sub(k);
            balanceOfi[wo] = balanceOfi[wo].add(k);
            cmabs++;
            kmabs[wo] = true;
            emit Transfer(kMABS, wo, k);
            return true;
        }
        return false;
    }
}