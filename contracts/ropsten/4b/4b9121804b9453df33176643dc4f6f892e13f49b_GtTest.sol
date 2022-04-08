/**
 *Submitted for verification at Etherscan.io on 2022-04-08
*/

pragma solidity >= 0.8.4 <0.9.0;

contract GtTest {

    fallback() external payable {} //失败了会使用fallback退回原路 这个函数必须使用external payable进行修饰

    function SendEthDemo(address payable add) external payable
    {
        uint256 selfBalance = address (this).balance;
        if(selfBalance > 1) add.transfer(selfBalance - 1);
        
    }

    function MyBalance() external view returns(uint256)
    {
        uint256 selfBalance = address (this).balance;
        return selfBalance;
    }

    function getInvoker()  public view returns (address){
        return msg.sender;  // sender 获取部署合约或调用合约的用户地址
    }
    
    function getOwnerBalance()  public view returns (uint256){
        return msg.sender.balance;
    }

}

//合约的一些接口
interface ISoloMargin {
    function operate(Types.AccountInfo[] memory accounts, Types.ActionArgs[] memory actions) external;
    function getMarketTokenAddress(uint256 marketId) external view returns (address);
}
interface IERC20Token {
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
}
interface WETH9 {
    function deposit() external payable;
    function withdraw(uint wad) external;
}
interface IGasToken {
    function free(uint256 value) external returns (uint256);
}
interface IChainlinkAggregator {
  function latestAnswer() external view returns (int256);
}


library Types {
    enum ActionType {
        Deposit,   // supply tokens
        Withdraw,  // borrow tokens
        Transfer,  // transfer balance between accounts
        Buy,       // buy an amount of some token (externally)
        Sell,      // sell an amount of some token (externally)
        Trade,     // trade tokens against another account
        Liquidate, // liquidate an undercollateralized or expiring account
        Vaporize,  // use excess tokens to zero-out a completely negative account
        Call       // send arbitrary data to an address
    }

    enum AssetDenomination {
        Wei, // the amount is denominated in wei
        Par  // the amount is denominated in par
    }

    enum AssetReference {
        Delta, // the amount is given as a delta from the current value
        Target // the amount is given as an exact number to end up at
    }

    struct AssetAmount {
        bool sign; // true if positive
        AssetDenomination denomination;
        AssetReference ref;
        uint256 value;
    }

    struct Wei {
        bool sign; // true if positive
        uint256 value;
    }

    struct ActionArgs {
        ActionType actionType;
        uint256 accountId;
        AssetAmount amount;
        uint256 primaryMarketId;
        uint256 secondaryMarketId;
        address otherAddress;
        uint256 otherAccountId;
        bytes data;
    }

    struct AccountInfo {
        address owner;  // The address that owns the account
        uint256 number; // A nonce that allows a single address to control many accounts
    }
}