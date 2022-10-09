/**
 *Submitted for verification at Etherscan.io on 2022-10-09
*/

pragma solidity ^0.8.14;

interface ERC20 {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract Merchant {

    struct Info {
        address platform;
        address merchant;

        mapping(string => uint256) fees;
    }

    address owner;
    Info info;

    constructor() {
        init();
    }

    modifier onlyOwner () {
        require(
            msg.sender == owner,
            "Only own can call this."
        );
        _;
    }

    event Withdraw(uint256 amount, address token);
    event Destroy(address merchant, address sender);
    event Received(address, uint);

    // When there is no matching function to call in the contract, call the fallback function
    fallback() external payable {}
    // Receive and forward ether via contracts
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    // Initialize internal variables
    function init() internal {
        info.platform = 0x82fC0c4a8071fc75497B7f47f1d8B8053251a29c;
        info.merchant = 0x82fC0c4a8071fc75497B7f47f1d8B8053251a29c;

        info.fees["USDT"] = 800;
        info.fees["USDC"] = 800;
        info.fees["DAI"] = 800;
        info.fees["ETH"] = 800;

        owner = msg.sender;
    }

    // destroy this contract.
    function destroy(address payable _to) public onlyOwner {
        selfdestruct(_to);
        emit Destroy(info.merchant, msg.sender);
    }

    // withdraw currencies
    function withdraw(uint256 amount, string memory currency, address _tokenContract) public onlyOwner payable {
        require(amount > 0, "Balance is not enough.");
        uint256 fee = amount * info.fees[currency] / 100000;
        uint256 available = amount - fee;
        require((available > 0 && fee > 0), "Balance is not enough.");

        if (_tokenContract == address(0)) {
            payable(info.platform).transfer(fee);
            payable(info.merchant).transfer(available);
        } else {
            ERC20(_tokenContract).transfer(info.platform, fee);
            ERC20(_tokenContract).transfer(info.merchant, available);
        }
        emit Withdraw((fee + available), info.merchant);
    }

    struct MyToken {
        string currency;
        uint256 amount;
        address _tokenContract;
    }

    // Allot all tokens.
    function withdrawAllTokens (uint256 _ethAmount, uint256 _usdcAmount, uint256 _usdtAmount, uint256 _daiAmount) public onlyOwner {
        MyToken[4] memory _tokens;
        _tokens[0] = MyToken("ETH", _ethAmount, address(0));
        _tokens[1] = MyToken("USDC", _usdcAmount, 0x07865c6E87B9F70255377e024ace6630C1Eaa37F);
        _tokens[2] = MyToken("USDT", _usdtAmount, 0xbF14b63FF0DD15aDe35C3A1b70412EB92A81769C);
        _tokens[3] = MyToken("DAI", _daiAmount, 0xdc31Ee1784292379Fbb2964b3B9C4124D8F89C60);
        uint8 i = 0;
        for (i; i < _tokens.length; i++) {
            if (_tokens[i].amount == 0) continue;

            withdraw(_tokens[i].amount, _tokens[i].currency, _tokens[i]._tokenContract);
        }
    }
}